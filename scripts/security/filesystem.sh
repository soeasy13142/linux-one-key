#!/usr/bin/env bash
# ============================================================================
# filesystem.sh - 文件系统安全模块
# 关键目录权限检查、SUID/SGID 审计、无主文件检查
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before filesystem.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================

# 关键文件权限定义：路径:期望权限（八进制）
readonly CRITICAL_FILES=(
    "/etc/passwd:644"
    "/etc/shadow:640"
    "/etc/group:644"
    "/etc/gshadow:640"
    "/etc/ssh/sshd_config:600"
    "/root:700"
    "/tmp:1777"
)

# 标准 SUID 文件列表（这些是已知安全的）
readonly KNOWN_SUID_FILES=(
    "/usr/bin/passwd"
    "/usr/bin/sudo"
    "/usr/bin/su"
    "/usr/bin/newgrp"
    "/usr/bin/chsh"
    "/usr/bin/chfn"
    "/usr/bin/gpasswd"
    "/usr/bin/mount"
    "/usr/bin/umount"
    "/usr/bin/crontab"
    "/usr/bin/pkexec"
    "/usr/lib/openssh/ssh-keysign"
    "/usr/lib/dbus-1.0/dbus-daemon-launch-helper"
    "/usr/libexec/dbus-1/dbus-daemon-launch-helper"
    "/usr/libexec/openssh/ssh-keysign"
    "/snap/snapd/*/usr/lib/snapd/snap-confine"
)

# ============================================================================
# 内部函数
# ============================================================================

# 获取文件的八进制权限
_get_file_mode() {
    local file="$1"
    if [[ -e "${file}" ]]; then
        stat -c '%a' "${file}" 2>/dev/null || stat -f '%Lp' "${file}" 2>/dev/null || echo "000"
    else
        echo "NOT_FOUND"
    fi
}

# 检查是否为已知的 SUID 文件
_is_known_suid_file() {
    local file="$1"
    for known in "${KNOWN_SUID_FILES[@]}"; do
        # 支持通配符匹配（如 /snap/snapd/*/...）
        # shellcheck disable=SC2254
        case "${file}" in
            ${known}) return 0 ;;
        esac
    done
    return 1
}

# ============================================================================
# 公共函数
# ============================================================================

# 检查关键目录权限
check_critical_permissions() {
    log_title "${MSG_FS_PERM_TITLE}"

    local issues=0
    local checked=0

    for entry in "${CRITICAL_FILES[@]}"; do
        local file="${entry%%:*}"
        local expected="${entry##*:}"

        if [[ ! -e "${file}" ]]; then
            log_debug "${MSG_FS_PERM_NOT_FOUND}: ${file}"
            continue
        fi

        checked=$((checked + 1))
        local actual
        actual=$(_get_file_mode "${file}")

        if [[ "${actual}" != "${expected}" ]]; then
            log_warn "${MSG_FS_PERM_MISMATCH}: ${file} (expected: ${expected}, actual: ${actual})"
            issues=$((issues + 1))
        else
            log_debug "${MSG_FS_PERM_OK}: ${file} (${actual})"
        fi
    done

    echo ""
    if [[ ${issues} -eq 0 ]]; then
        log_success "${MSG_FS_PERM_ALL_OK}: ${checked} ${MSG_FS_PERM_CHECKED}"
    else
        log_warn "${MSG_FS_PERM_ISSUES}: ${issues}/${checked} ${MSG_FS_PERM_MISMATCH}"
    fi

    # 通过全局变量返回结果（避免脆弱的 stdout 解析）
    _FS_PERM_ISSUE_COUNT=${issues}
    return 0
}

# 修复单个文件权限
_fix_single_permission() {
    local file="$1"
    local expected="$2"

    if [[ ! -e "${file}" ]]; then
        log_warn "${MSG_FS_PERM_NOT_FOUND}: ${file}"
        return 1
    fi

    local actual
    actual=$(_get_file_mode "${file}")

    if [[ "${actual}" == "${expected}" ]]; then
        log_info "${MSG_FS_PERM_ALREADY_OK}: ${file}"
        return 0
    fi

    log_step "${MSG_FS_PERM_FIXING}: ${file} (${actual} → ${expected})..."

    # 备份当前权限（记录到日志）
    log_debug "Changing ${file} permission from ${actual} to ${expected}"

    if ! chmod "${expected}" "${file}" >> "${LOG_FILE}" 2>&1; then
        log_error "${MSG_FS_PERM_FIX_FAILED}: ${file}"
        return 1
    fi

    # 写后验证：回读权限确认已生效
    local new_actual
    new_actual=$(_get_file_mode "${file}")
    if [[ "${new_actual}" != "${expected}" ]]; then
        log_error "${MSG_FS_PERM_FIX_FAILED}: ${file} (expected ${expected}, got ${new_actual})"
        return 1
    fi

    log_success "${MSG_FS_PERM_FIXED}: ${file} (${expected})"
    return 0
}

# 交互式修复权限不正确的关键文件
fix_critical_permissions() {
    log_title "${MSG_FS_PERM_FIX_TITLE}"

    local fixed=0
    local skipped=0

    for entry in "${CRITICAL_FILES[@]}"; do
        local file="${entry%%:*}"
        local expected="${entry##*:}"

        if [[ ! -e "${file}" ]]; then
            continue
        fi

        local actual
        actual=$(_get_file_mode "${file}")

        if [[ "${actual}" != "${expected}" ]]; then
            echo ""
            log_warn "${MSG_FS_PERM_MISMATCH}: ${file}"
            echo -e "  ${MSG_FS_PERM_CURRENT}: ${actual}"
            echo -e "  ${MSG_FS_PERM_EXPECTED}: ${expected}"

            if confirm "${MSG_FS_PERM_CONFIRM_FIX}" "y"; then
                if _fix_single_permission "${file}" "${expected}"; then
                    fixed=$((fixed + 1))
                fi
            else
                log_info "${MSG_FS_PERM_FIX_SKIPPED}: ${file}"
                skipped=$((skipped + 1))
            fi
        fi
    done

    echo ""
    log_success "${MSG_FS_PERM_FIX_DONE}: ${fixed} ${MSG_FS_PERM_FIXED}, ${skipped} ${MSG_FS_PERM_FIX_SKIPPED_COUNT}"
}

# SUID/SGID 审计（仅报告，不修改）
audit_suid_sgid() {
    log_title "${MSG_FS_SUID_TITLE}"

    log_step "${MSG_FS_SUID_SCANNING}..."

    # 查找 SUID 和 SGID 文件（排除虚拟/网络文件系统）
    local suid_files
    suid_files=$(find / -xdev -not -path '/proc/*' -not -path '/sys/*' -perm -4000 -type f 2>/dev/null || true)
    local sgid_files
    sgid_files=$(find / -xdev -not -path '/proc/*' -not -path '/sys/*' -perm -2000 -type f 2>/dev/null || true)

    local suid_count=0
    local sgid_count=0
    local suspicious_count=0
    local suspicious_files=()

    echo ""
    echo -e "${BOLD}${MSG_FS_SUID_RESULTS_TITLE}${NC}"
    echo ""

    # 列出 SUID 文件
    if [[ -n "${suid_files}" ]]; then
        echo -e "${GREEN}[SUID]${NC}"
        while IFS= read -r file; do
            suid_count=$((suid_count + 1))
            if _is_known_suid_file "${file}"; then
                echo -e "  ${GREEN}[✓]${NC} ${file}"
            else
                echo -e "  ${YELLOW}[!]${NC} ${file} ${MSG_FS_SUID_SUSPICIOUS}"
                suspicious_files+=("${file}")
                suspicious_count=$((suspicious_count + 1))
            fi
        done <<< "${suid_files}"
    fi

    # 列出 SGID 文件
    if [[ -n "${sgid_files}" ]]; then
        echo ""
        echo -e "${GREEN}[SGID]${NC}"
        while IFS= read -r file; do
            sgid_count=$((sgid_count + 1))
            echo -e "  ${BLUE}[i]${NC} ${file}"
        done <<< "${sgid_files}"
    fi

    # 摘要
    echo ""
    echo -e "${BOLD}${MSG_FS_SUID_SUMMARY_TITLE}${NC}"
    echo -e "  ${MSG_FS_SUID_TOTAL}: ${suid_count}"
    echo -e "  ${MSG_FS_SGID_TOTAL}: ${sgid_count}"
    echo -e "  ${MSG_FS_SUID_SUSPICIOUS_COUNT}: ${suspicious_count}"

    if [[ ${suspicious_count} -gt 0 ]]; then
        echo ""
        log_warn "${MSG_FS_SUID_SUSPICIOUS_HINT}"
        echo -e "${MSG_FS_SUID_REMOVE_CMD}"
        for file in "${suspicious_files[@]}"; do
            echo -e "  sudo chmod u-s ${file}"
        done
    else
        echo ""
        log_success "${MSG_FS_SUID_ALL_KNOWN}"
    fi
}

# 查找没有属主的文件
check_orphan_files() {
    log_title "${MSG_FS_ORPHAN_TITLE}"

    log_step "${MSG_FS_ORPHAN_SCANNING}..."

    local orphan_files
    orphan_files=$(find / -xdev -not -path '/proc/*' -not -path '/sys/*' \( -nouser -o -nogroup \) 2>/dev/null | head -50 || true)

    if [[ -z "${orphan_files}" ]]; then
        log_success "${MSG_FS_ORPHAN_NONE}"
        return 0
    fi

    local orphan_count
    orphan_count=$(echo "${orphan_files}" | wc -l | tr -d ' ')

    echo ""
    echo -e "${BOLD}${MSG_FS_ORPHAN_RESULTS_TITLE}${NC}"

    # 提示结果可能被截断
    if [[ ${orphan_count} -ge 50 ]]; then
        log_warn "${MSG_FS_ORPHAN_TRUNCATED}"
    fi
    echo ""
    echo "${orphan_files}" | while IFS= read -r file; do
        local owner
        owner=$(stat -c '%U:%G' "${file}" 2>/dev/null || stat -f '%Su:%Sg' "${file}" 2>/dev/null || echo "unknown")
        echo -e "  ${YELLOW}[!]${NC} ${file} (${owner})"
    done

    echo ""
    log_warn "${MSG_FS_ORPHAN_HINT}: ${orphan_count} ${MSG_FS_ORPHAN_FOUND}"
    echo -e "${MSG_FS_ORPHAN_FIX_CMD}"
}

# ============================================================================
# 文件系统安全向导
# ============================================================================

run_filesystem_wizard() {
    log_title "${MSG_FS_WIZARD_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_FS_WIZARD_DESC}${NC}"
    echo ""

    # 确认开始
    if ! confirm "${MSG_FS_WIZARD_START}" "y"; then
        log_info "${MSG_FS_WIZARD_SKIPPED}"
        return 0
    fi

    local wizard_rc=0

    # ── Step 1: 关键目录权限检查 ──
    echo ""
    log_title "${MSG_FS_STEP_PERM}"

    _FS_PERM_ISSUE_COUNT=0
    check_critical_permissions
    local issue_count=${_FS_PERM_ISSUE_COUNT}

    if [[ "${issue_count}" -gt 0 ]]; then
        echo ""
        if confirm "${MSG_FS_PERM_ISSUES_FOUND}" "y"; then
            fix_critical_permissions || wizard_rc=1
        else
            log_info "${MSG_FS_STEP_SKIPPED}"
        fi
    fi

    # ── Step 2: SUID/SGID 审计 ──
    echo ""
    log_title "${MSG_FS_STEP_SUID}"

    if confirm "${MSG_FS_STEP_SUID_CONFIRM}" "y"; then
        audit_suid_sgid || wizard_rc=1
    else
        log_info "${MSG_FS_STEP_SKIPPED}"
    fi

    # ── Step 3: 无主文件检查 ──
    echo ""
    log_title "${MSG_FS_STEP_ORPHAN}"

    if confirm "${MSG_FS_STEP_ORPHAN_CONFIRM}" "y"; then
        check_orphan_files || wizard_rc=1
    else
        log_info "${MSG_FS_STEP_SKIPPED}"
    fi

    # ── Summary ──
    echo ""
    log_title "${MSG_FS_SUMMARY}"
    echo -e "  ${MSG_FS_SUMMARY_PERM_CHECK}: ${MSG_FS_SUMMARY_DONE}"
    echo -e "  ${MSG_FS_SUMMARY_SUID_CHECK}: ${MSG_FS_SUMMARY_DONE}"
    echo -e "  ${MSG_FS_SUMMARY_ORPHAN_CHECK}: ${MSG_FS_SUMMARY_DONE}"

    log_success "${MSG_FS_WIZARD_DONE}"

    return ${wizard_rc}
}

# 检查文件系统安全状态（用于系统状态检测）
check_filesystem_status() {
    local suid_count=0

    # 快速统计 SUID 文件数（与 audit_suid_sgid 保持一致的扫描范围）
    suid_count=$(find / -xdev -not -path '/proc/*' -not -path '/sys/*' -perm -4000 -type f 2>/dev/null | wc -l | tr -d ' ')

    echo "fs_suid_count=${suid_count}"
}

# 标记 filesystem.sh 已加载
readonly _FILESYSTEM_LOADED=1

log_debug "filesystem.sh loaded successfully"

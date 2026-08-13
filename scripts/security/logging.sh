#!/usr/bin/env bash
# ============================================================================
# logging.sh - 日志安全加固模块
# journald 持久化 + 大小限制、logrotate 安全配置、/var/log 关键日志权限修复
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before logging.sh"
    exit 1
fi

# ============================================================================
# 配置常量（允许测试通过环境变量覆盖路径）
# ============================================================================

# journald 加固 drop-in
JOURNALD_DROPIN="${JOURNALD_DROPIN:-/etc/systemd/journald.conf.d/99-linux-one-key.conf}"
# logrotate 安全配置 drop-in
LOGROTATE_CONF="${LOGROTATE_CONF:-/etc/logrotate.d/linux-one-key-logrotate}"
# journald 大小/保留时间
JOURNALD_SYSTEM_MAX_USE="${JOURNALD_SYSTEM_MAX_USE:-500M}"
JOURNALD_MAX_RETENTION_SEC="${JOURNALD_MAX_RETENTION_SEC:-30d}"

# 关键日志文件：路径:期望权限（八进制）
# 测试可通过重新赋值覆盖此数组
CRITICAL_LOG_FILES=(
    "/var/log/syslog:640"
    "/var/log/messages:640"
    "/var/log/auth.log:640"
    "/var/log/secure:640"
    "/var/log/kern.log:640"
    "/var/log/sudo.log:640"
)

# ============================================================================
# 内部函数
# ============================================================================

# 获取文件八进制权限（跨平台：GNU stat / BSD stat）
_get_file_mode() {
    local file="$1"
    if [[ -e "${file}" ]]; then
        stat -c '%a' "${file}" 2>/dev/null || stat -f '%Lp' "${file}" 2>/dev/null || echo "000"
    else
        echo "NOT_FOUND"
    fi
}

# 获取文件属主（跨平台）
_get_file_owner() {
    local file="$1"
    stat -c '%U' "${file}" 2>/dev/null || stat -f '%Su' "${file}" 2>/dev/null || echo "unknown"
}

# journald drop-in 是否已包含全部加固项（幂等判断）
_journald_already_hardened() {
    [[ -f "${JOURNALD_DROPIN}" ]] || return 1
    grep -q '^Storage[[:space:]]*=' "${JOURNALD_DROPIN}" 2>/dev/null || return 1
    grep -q '^SystemMaxUse[[:space:]]*=' "${JOURNALD_DROPIN}" 2>/dev/null || return 1
    grep -q '^MaxRetentionSec[[:space:]]*=' "${JOURNALD_DROPIN}" 2>/dev/null || return 1
    return 0
}

# 配置 journald 持久化 + 大小限制
_configure_journald() {
    if _journald_already_hardened; then
        log_info "${MSG_LOG_JOURNALD_EXISTS}"
        return 0
    fi

    local dir
    dir="$(dirname "${JOURNALD_DROPIN}")"
    mkdir -p "${dir}" 2>/dev/null || true

    if [[ -f "${JOURNALD_DROPIN}" ]]; then
        backup_file "${JOURNALD_DROPIN}" "${MSG_LOG_BACKUP_CONF}" || true
    fi

    cat > "${JOURNALD_DROPIN}" << EOF
[Journal]
Storage=persistent
SystemMaxUse=${JOURNALD_SYSTEM_MAX_USE}
MaxRetentionSec=${JOURNALD_MAX_RETENTION_SEC}
EOF

    log_success "${MSG_LOG_JOURNALD_DONE}"
}

# 重启 journald 使配置生效（失败仅 warn，容器/受限环境常见）
_restart_journald() {
    if systemctl try-restart systemd-journald >/dev/null 2>&1; then
        log_success "${MSG_LOG_JOURNALD_RESTART_DONE}"
    else
        log_warn "${MSG_LOG_JOURNALD_RESTART_WARN}"
    fi
    return 0
}

# logrotate drop-in 是否已包含安全选项（幂等判断）
_logrotate_already_hardened() {
    [[ -f "${LOGROTATE_CONF}" ]] || return 1
    grep -q 'su[[:space:]]*root' "${LOGROTATE_CONF}" 2>/dev/null || return 1
    grep -q 'compress' "${LOGROTATE_CONF}" 2>/dev/null || return 1
    grep -q 'dateext' "${LOGROTATE_CONF}" 2>/dev/null || return 1
    return 0
}

# 配置 logrotate 安全默认（权限 0640 / su root / compress / dateext）
_configure_logrotate() {
    if _logrotate_already_hardened; then
        log_info "${MSG_LOG_LOGROTATE_EXISTS}"
        return 0
    fi

    local dir
    dir="$(dirname "${LOGROTATE_CONF}")"
    mkdir -p "${dir}" 2>/dev/null || true

    if [[ -f "${LOGROTATE_CONF}" ]]; then
        backup_file "${LOGROTATE_CONF}" "${MSG_LOG_BACKUP_CONF}" || true
    fi

    cat > "${LOGROTATE_CONF}" << 'EOF'
# linux-one-key logrotate safety hardening
# 安全默认：权限 0640 / su root root / compress / dateext
/var/log/linux-one-key/*.log {
    weekly
    rotate 12
    compress
    dateext
    missingok
    notifempty
    su root root
    create 0640 root root
}
EOF

    log_success "${MSG_LOG_LOGROTATE_DONE}"
}

# 修复单个日志文件权限（owner root + 期望 mode，异常则修复）
_fix_single_log_perm() {
    local file="$1"
    local expected="$2"

    if [[ ! -e "${file}" ]]; then
        log_debug "Skip missing log file: ${file}"
        return 0
    fi

    local actual
    actual=$(_get_file_mode "${file}")

    if [[ "${actual}" == "${expected}" ]]; then
        local owner
        owner=$(_get_file_owner "${file}")
        if [[ "${owner}" != "root" ]]; then
            # 属主异常：尽力修复（非 root 环境下可能失败，仅 warn 不阻断）
            chown root:root "${file}" 2>/dev/null || log_warn "${MSG_LOG_CHOWN_FAILED}: ${file}"
        fi
        return 0
    fi

    log_step "${MSG_LOG_PERM_FIXING}: ${file} (${actual} → ${expected})"

    if chmod "${expected}" "${file}" 2>/dev/null; then
        local new_actual
        new_actual=$(_get_file_mode "${file}")
        if [[ "${new_actual}" == "${expected}" ]]; then
            chown root:root "${file}" 2>/dev/null || true
            log_success "${MSG_LOG_PERM_FIXED}: ${file}"
            return 0
        fi
    fi

    log_warn "${MSG_LOG_PERM_FIX_FAILED}: ${file}"
    return 1
}

# 检查并修复关键日志文件权限
_fix_log_file_perms() {
    local issues=0
    for entry in "${CRITICAL_LOG_FILES[@]}"; do
        local file="${entry%%:*}"
        local expected="${entry##*:}"
        _fix_single_log_perm "${file}" "${expected}" || issues=$((issues + 1))
    done

    if [[ ${issues} -eq 0 ]]; then
        log_success "${MSG_LOG_PERM_ALL_OK}"
    else
        log_warn "${MSG_LOG_PERM_ISSUES}: ${issues}"
    fi
    return 0
}

# ============================================================================
# 公共函数
# ============================================================================

# 应用日志安全加固
apply_logging_hardening() {
    log_title "${MSG_LOG_TITLE}"

    _configure_journald
    _restart_journald
    _configure_logrotate
    _fix_log_file_perms

    log_success "${MSG_LOG_DONE}"
    return 0
}

# ============================================================================
# 日志加固向导
# ============================================================================

run_logging_wizard() {
    log_title "${MSG_LOG_WIZARD_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_LOG_WIZARD_DESC}${NC}"
    echo ""

    if ! confirm "${MSG_LOG_WIZARD_START}" "y"; then
        log_info "${MSG_LOG_WIZARD_SKIPPED}"
        return 0
    fi

    local wizard_rc=0
    apply_logging_hardening || wizard_rc=1

    if [[ ${wizard_rc} -eq 0 ]]; then
        log_success "${MSG_LOG_WIZARD_DONE}"
    else
        log_warn "${MSG_LOG_WIZARD_DONE} ${MSG_WIZARD_ERR_HINT}"
    fi

    return ${wizard_rc}
}

# 标记 logging.sh 已加载
readonly _LOGGING_LOADED=1

log_debug "logging.sh loaded successfully"

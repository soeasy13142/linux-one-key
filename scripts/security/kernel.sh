#!/usr/bin/env bash
# ============================================================================
# kernel.sh - 内核安全加固模块
# sysctl 安全参数配置、内核模块限制
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before kernel.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================
readonly SYSCTL_HARDENING_CONF="/etc/sysctl.d/99-hardening.conf"
readonly SYSCTL_TEMPLATE="${SCRIPT_DIR:-}/config/sysctl/hardening.conf"

# 要禁用的内核模块列表
readonly DISABLED_MODULES=(
    "cramfs"       # 不需要的压缩文件系统
    "freevxfs"     # 不需要的文件系统
    "hfs"          # macOS 文件系统，Linux 不需要
    "hfsplus"      # macOS 文件系统，Linux 不需要
    "udf"          # 通用磁盘格式，云服务器不需要
    "usb-storage"  # USB 存储，云服务器不需要
)

# ============================================================================
# 内部函数
# ============================================================================

# 备份现有 sysctl 配置
_backup_sysctl_config() {
    if [[ -f "${SYSCTL_HARDENING_CONF}" ]]; then
        backup_file "${SYSCTL_HARDENING_CONF}" "${MSG_KERNEL_BACKUP_CONF}"
    fi
}

# ============================================================================
# 公共函数
# ============================================================================

# 应用 sysctl 安全参数
apply_sysctl_params() {
    log_title "${MSG_KERNEL_SYSCTL_TITLE}"

    # 备份现有配置
    _backup_sysctl_config

    log_step "${MSG_KERNEL_SYSCTL_APPLYING}..."

    # 检查模板文件是否存在
    if [[ -f "${SYSCTL_TEMPLATE}" ]]; then
        # 使用模板文件生成配置
        mkdir -p "$(dirname "${SYSCTL_HARDENING_CONF}")"
        cp -a "${SYSCTL_TEMPLATE}" "${SYSCTL_HARDENING_CONF}"
    else
        # 模板不存在，直接生成
        log_warn "${MSG_KERNEL_TEMPLATE_NOT_FOUND}"
        _generate_sysctl_config
    fi

    # 应用 sysctl 配置
    local apply_errors=0
    if sysctl --system >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_KERNEL_SYSCTL_DONE}"
    else
        log_warn "${MSG_KERNEL_SYSCTL_PARTIAL}"
        apply_errors=1
    fi

    # 验证关键参数
    _verify_sysctl_params

    return ${apply_errors}
}

# 生成 sysctl 配置（当模板不存在时的 fallback）
_generate_sysctl_config() {
    cat > "${SYSCTL_HARDENING_CONF}" << 'SYSCTL'
## 内核安全参数 - linux-one-key 自动生成
## 参考: CIS Benchmarks

# SYN Flood 防护
net.ipv4.tcp_syncookies = 1

# 反向路径过滤
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 禁止 ICMP 重定向
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0

# 禁止源路由
net.ipv4.conf.all.accept_source_route = 0
net.ipv4.conf.default.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0
net.ipv6.conf.default.accept_source_route = 0

# 记录可疑数据包
net.ipv4.conf.all.log_martians = 1
net.ipv4.conf.default.log_martians = 1

# 忽略广播 ICMP
net.ipv4.icmp_echo_ignore_broadcasts = 1

# 禁止 IP 转发
net.ipv4.ip_forward = 0

# 忽略虚假 ICMP 响应
net.ipv4.icmp_ignore_bogus_error_responses = 1

# ASLR 地址随机化
kernel.randomize_va_space = 2

# 禁止 SUID 核心转储
fs.suid_dumpable = 0

# 限制 dmesg 访问
kernel.dmesg_restrict = 1

# 限制内核指针泄露
kernel.kptr_restrict = 2
SYSCTL
}

# 验证关键 sysctl 参数
_verify_sysctl_params() {
    log_step "${MSG_KERNEL_VERIFYING}..."

    local failed=0
    local params=(
        "net.ipv4.tcp_syncookies:1"
        "net.ipv4.conf.all.accept_redirects:0"
        "net.ipv4.ip_forward:0"
        "kernel.randomize_va_space:2"
    )

    for entry in "${params[@]}"; do
        local key="${entry%%:*}"
        local expected="${entry##*:}"
        local actual
        actual=$(sysctl -n "${key}" 2>/dev/null || echo "unknown")

        if [[ "${actual}" != "${expected}" ]]; then
            log_warn "${MSG_KERNEL_VERIFY_FAILED}: ${key} (expected: ${expected}, got: ${actual})"
            failed=$((failed + 1))
        fi
    done

    if [[ ${failed} -eq 0 ]]; then
        log_success "${MSG_KERNEL_VERIFY_DONE}"
    else
        log_warn "${MSG_KERNEL_VERIFY_PARTIAL}: ${failed} ${MSG_KERNEL_VERIFY_PARAMS_FAILED}"
    fi
}

# 禁用不需要的内核模块
disable_kernel_modules() {
    log_title "${MSG_KERNEL_MODULES_TITLE}"

    local disabled_count=0
    local skipped_count=0

    for module in "${DISABLED_MODULES[@]}"; do
        log_step "${MSG_KERNEL_MODULE_DISABLE}: ${module}..."

        # 检查模块是否已加载
        if lsmod 2>/dev/null | grep -q "^${module} "; then
            if modprobe -r "${module}" >> "${LOG_FILE}" 2>&1; then
                log_success "${MSG_KERNEL_MODULE_DISABLED}: ${module}"
                disabled_count=$((disabled_count + 1))
            else
                log_warn "${MSG_KERNEL_MODULE_CANNOT_DISABLE}: ${module}"
                skipped_count=$((skipped_count + 1))
            fi
        else
            log_debug "${MSG_KERNEL_MODULE_NOT_LOADED}: ${module}"
        fi

        # 写入黑名单（防止自动加载）
        local blacklist_file="/etc/modprobe.d/${module}-blacklist.conf"
        if [[ ! -f "${blacklist_file}" ]] || ! grep -q "blacklist ${module}" "${blacklist_file}" 2>/dev/null; then
            echo "install ${module} /bin/true" > "${blacklist_file}" 2>/dev/null || true
            echo "blacklist ${module}" >> "${blacklist_file}" 2>/dev/null || true
            log_debug "Blacklisted module: ${module}"
        fi
    done

    log_success "${MSG_KERNEL_MODULES_DONE}: ${disabled_count} ${MSG_KERNEL_MODULES_DISABLED}, ${skipped_count} ${MSG_KERNEL_MODULES_SKIPPED}"
}

# 回滚 sysctl 配置
restore_sysctl_backup() {
    log_title "${MSG_KERNEL_RESTORE_TITLE}"

    if [[ ! -f "${SYSCTL_HARDENING_CONF}" ]]; then
        log_info "${MSG_KERNEL_NO_CONF_TO_RESTORE}"
        return 0
    fi

    # 找到最新的备份
    local latest_backup
    latest_backup=$(ls -t "${BACKUP_DIR}"/99-hardening.conf.bak.* 2>/dev/null | head -1)

    if [[ -z "${latest_backup}" ]]; then
        log_warn "${MSG_KERNEL_NO_BACKUP_FOUND}"
        # 直接删除加固配置
        rm -f "${SYSCTL_HARDENING_CONF}"
        sysctl --system >> "${LOG_FILE}" 2>&1 || true
        log_success "${MSG_KERNEL_RESTORE_DONE}"
        return 0
    fi

    if restore_file "${latest_backup}" "${SYSCTL_HARDENING_CONF}" "${MSG_KERNEL_RESTORE_CONF}"; then
        sysctl --system >> "${LOG_FILE}" 2>&1 || true
        log_success "${MSG_KERNEL_RESTORE_DONE}"
    else
        log_error "${MSG_KERNEL_RESTORE_FAILED}"
        return 1
    fi
}

# ============================================================================
# 内核加固向导
# ============================================================================

run_kernel_wizard() {
    log_title "${MSG_KERNEL_WIZARD_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_KERNEL_WIZARD_DESC}${NC}"
    echo ""

    # 确认开始
    if ! confirm "${MSG_KERNEL_WIZARD_START}" "y"; then
        log_info "${MSG_KERNEL_WIZARD_SKIPPED}"
        return 0
    fi

    local wizard_rc=0

    # ── Step 1: sysctl 参数 ──
    echo ""
    log_title "${MSG_KERNEL_STEP_SYSCTL}"

    echo -e "${MSG_KERNEL_SYSCTL_SUMMARY_TITLE}:"
    echo -e "  - ${MSG_KERNEL_SYSCTL_SUMMARY_SYN}"
    echo -e "  - ${MSG_KERNEL_SYSCTL_SUMMARY_REDIRECT}"
    echo -e "  - ${MSG_KERNEL_SYSCTL_SUMMARY_ROUTE}"
    echo -e "  - ${MSG_KERNEL_SYSCTL_SUMMARY_FORWARD}"
    echo -e "  - ${MSG_KERNEL_SYSCTL_SUMMARY_ASLR}"
    echo ""

    if confirm "${MSG_KERNEL_STEP_SYSCTL_CONFIRM}" "y"; then
        apply_sysctl_params || wizard_rc=1
    else
        log_info "${MSG_KERNEL_STEP_SKIPPED}"
    fi

    # ── Step 2: 内核模块 ──
    echo ""
    log_title "${MSG_KERNEL_STEP_MODULES}"

    echo -e "${MSG_KERNEL_MODULES_SUMMARY_TITLE}:"
    for module in "${DISABLED_MODULES[@]}"; do
        echo -e "  - ${module}"
    done
    echo ""

    if confirm "${MSG_KERNEL_STEP_MODULES_CONFIRM}" "y"; then
        disable_kernel_modules || wizard_rc=1
    else
        log_info "${MSG_KERNEL_STEP_SKIPPED}"
    fi

    # ── Summary ──
    echo ""
    log_title "${MSG_KERNEL_SUMMARY}"

    if [[ -f "${SYSCTL_HARDENING_CONF}" ]]; then
        echo -e "  ${MSG_KERNEL_SUMMARY_CONF}: ${SYSCTL_HARDENING_CONF}"
        local param_count
        param_count=$(grep -cE "^[^#]" "${SYSCTL_HARDENING_CONF}" 2>/dev/null || echo "0")
        echo -e "  ${MSG_KERNEL_SUMMARY_PARAMS}: ${param_count}"
    else
        echo -e "  ${MSG_KERNEL_SUMMARY_NO_CONF}"
    fi

    if [[ ${wizard_rc} -eq 0 ]]; then
        log_success "${MSG_KERNEL_WIZARD_DONE}"
    else
        log_warn "${MSG_KERNEL_WIZARD_DONE} ${MSG_WIZARD_ERR_HINT}"
    fi

    return ${wizard_rc}
}

# 检查内核加固状态（用于系统状态检测）
check_kernel_status() {
    local conf_exists="no"
    local param_count=0
    local modules_disabled=0

    if [[ -f "${SYSCTL_HARDENING_CONF}" ]]; then
        conf_exists="yes"
        param_count=$(grep -cE "^[^#]" "${SYSCTL_HARDENING_CONF}" 2>/dev/null || echo "0")
    fi

    # 检查黑名单中的模块数
    for module in "${DISABLED_MODULES[@]}"; do
        local blacklist_file="/etc/modprobe.d/${module}-blacklist.conf"
        if [[ -f "${blacklist_file}" ]]; then
            modules_disabled=$((modules_disabled + 1))
        fi
    done

    echo "kernel_conf=${conf_exists}"
    echo "kernel_params=${param_count}"
    echo "kernel_modules_disabled=${modules_disabled}"
}

# 标记 kernel.sh 已加载
readonly _KERNEL_LOADED=1

log_debug "kernel.sh loaded successfully"

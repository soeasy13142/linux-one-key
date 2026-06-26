#!/usr/bin/env bash
# ============================================================================
# 防火墙配置模块
# 支持 UFW (Ubuntu/Debian) 和 firewalld (CentOS/RHEL)
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before firewall.sh"
    exit 1
fi

# ============================================================================
# 内部函数
# ============================================================================

# 安装防火墙工具
_install_firewall() {
    log_step "${MSG_FIREWALL_INSTALL}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            if command_exists ufw; then
                log_info "${MSG_FIREWALL_ALREADY_INSTALLED} (UFW)"
                return 0
            fi
            apt-get install -y ufw >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            if command_exists firewall-cmd; then
                log_info "${MSG_FIREWALL_ALREADY_INSTALLED} (firewalld)"
                return 0
            fi
            # CentOS 8+/RHEL 8+ 使用 dnf，旧版本使用 yum
            if command_exists dnf; then
                dnf install -y firewalld >> "${LOG_FILE}" 2>&1
            else
                yum install -y firewalld >> "${LOG_FILE}" 2>&1
            fi
            # 安装后启动 firewalld 服务
            if ! systemctl enable --now firewalld >> "${LOG_FILE}" 2>&1; then
                log_warn "Failed to enable firewalld service"
            fi
            ;;
        fedora)
            if command_exists firewall-cmd; then
                log_info "${MSG_FIREWALL_ALREADY_INSTALLED} (firewalld)"
                return 0
            fi
            dnf install -y firewalld >> "${LOG_FILE}" 2>&1
            if ! systemctl enable --now firewalld >> "${LOG_FILE}" 2>&1; then
                log_warn "Failed to enable firewalld service"
            fi
            ;;
        *)
            log_error "${MSG_FIREWALL_UNSUPPORTED_OS}"
            return 1
            ;;
    esac

    log_success "${MSG_FIREWALL_INSTALL_DONE}"
}

# 获取防火墙类型
_get_firewall_type() {
    case "${DETECTED_OS}" in
        ubuntu|debian)                          echo "ufw" ;;
        centos|rhel|rocky|almalinux|fedora)     echo "firewalld" ;;
        *)                                      echo "unknown" ;;
    esac
}

# ============================================================================
# UFW 相关函数
# ============================================================================

# 重置 UFW 规则（可选）
_ufw_reset() {
    log_step "${MSG_FIREWALL_RESET}"
    ufw --force reset >> "${LOG_FILE}" 2>&1
    log_success "${MSG_FIREWALL_RESET_DONE}"
}

# 配置 UFW 默认策略
_ufw_set_defaults() {
    log_step "${MSG_FIREWALL_DEFAULT_POLICY}"
    ufw default deny incoming >> "${LOG_FILE}" 2>&1
    ufw default allow outgoing >> "${LOG_FILE}" 2>&1
    log_success "${MSG_FIREWALL_DEFAULT_POLICY_DONE}"
}

# UFW 开放端口
_ufw_allow_port() {
    local port="$1"
    local proto="${2:-tcp}"
    local comment="${3:-}"

    if [[ -n "$comment" ]]; then
        ufw allow "${port}/${proto}" comment "$comment" >> "${LOG_FILE}" 2>&1
    else
        ufw allow "${port}/${proto}" >> "${LOG_FILE}" 2>&1
    fi
    log_info "${MSG_FIREWALL_PORT_OPENED}: $port/$proto"
}

# UFW 关闭端口
_ufw_deny_port() {
    local port="$1"
    local proto="${2:-tcp}"
    ufw deny "${port}/${proto}" >> "${LOG_FILE}" 2>&1
    log_info "${MSG_FIREWALL_PORT_CLOSED}: $port/$proto"
}

# UFW 允许 ICMP (ping)
_ufw_allow_icmp() {
    # UFW 默认允许 ICMP，需要手动禁止才需配置
    log_info "${MSG_FIREWALL_ICMP_DEFAULT}"
}

# 启用 UFW
_ufw_enable() {
    log_step "${MSG_FIREWALL_ENABLE}"
    if ufw --force enable >> "${LOG_FILE}" 2>&1 && ufw status 2>/dev/null | grep -q "Status: active"; then
        log_success "${MSG_FIREWALL_ENABLE_DONE}"
    else
        log_error "Failed to enable UFW"
        return 1
    fi
}

# 显示 UFW 状态
_ufw_show_status() {
    echo ""
    log_step "${MSG_FIREWALL_STATUS}"
    ufw status verbose
    echo ""
}

# ============================================================================
# firewalld 相关函数
# ============================================================================

# 启动 firewalld 服务
_firewalld_start() {
    log_step "${MSG_FIREWALL_INSTALL}"
    systemctl start firewalld >> "${LOG_FILE}" 2>&1
    systemctl enable firewalld >> "${LOG_FILE}" 2>&1
    log_success "${MSG_FIREWALL_INSTALL_DONE}"
}

# 配置 firewalld 默认策略
_firewalld_set_defaults() {
    log_step "${MSG_FIREWALL_DEFAULT_POLICY}"
    # firewalld 默认 zone 就是 drop，已经是拒绝入站
    firewall-cmd --set-default-zone=drop >> "${LOG_FILE}" 2>&1
    firewall-cmd --zone=drop --set-target=DROP >> "${LOG_FILE}" 2>&1
    log_success "${MSG_FIREWALL_DEFAULT_POLICY_DONE}"
}

# firewalld 开放端口
_firewalld_allow_port() {
    local port="$1"
    local proto="${2:-tcp}"
    local comment="${3:-}"

    firewall-cmd --permanent --zone=drop --add-port="${port}/${proto}" >> "${LOG_FILE}" 2>&1
    log_info "${MSG_FIREWALL_PORT_OPENED}: $port/$proto"
}

# firewalld 关闭端口
_firewalld_deny_port() {
    local port="$1"
    local proto="${2:-tcp}"
    firewall-cmd --permanent --zone=drop --remove-port="${port}/${proto}" >> "${LOG_FILE}" 2>&1
    log_info "${MSG_FIREWALL_PORT_CLOSED}: $port/$proto"
}

# firewalld 允许 ICMP (ping)
_firewalld_allow_icmp() {
    firewall-cmd --permanent --zone=drop --add-protocol=icmp >> "${LOG_FILE}" 2>&1
    log_info "${MSG_FIREWALL_ICMP_ALLOWED}"
}

# firewalld 禁止 ICMP
_firewalld_deny_icmp() {
    firewall-cmd --permanent --zone=drop --remove-protocol=icmp >> "${LOG_FILE}" 2>&1
    log_info "${MSG_FIREWALL_ICMP_DENIED}"
}

# 重新加载 firewalld 规则
_firewalld_reload() {
    if firewall-cmd --reload >> "${LOG_FILE}" 2>&1; then
        log_debug "firewalld rules reloaded"
    else
        log_warn "Failed to reload firewalld rules"
        return 1
    fi
}

# 显示 firewalld 状态
_firewalld_show_status() {
    echo ""
    log_step "${MSG_FIREWALL_STATUS}"
    firewall-cmd --list-all
    echo ""
}

# ============================================================================
# 公共接口函数
# ============================================================================

# 显示防火墙当前状态
show_firewall_status() {
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            _ufw_show_status
            ;;
        firewalld)
            _firewalld_show_status
            ;;
        *)
            log_warn "${MSG_FIREWALL_UNSUPPORTED_OS}"
            ;;
    esac
}

# 开放端口（根据防火墙类型调用对应函数）
open_port() {
    local port="$1"
    local proto="${2:-tcp}"
    local comment="${3:-}"
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            _ufw_allow_port "$port" "$proto" "$comment"
            ;;
        firewalld)
            _firewalld_allow_port "$port" "$proto" "$comment"
            ;;
    esac
}

# 关闭端口
close_port() {
    local port="$1"
    local proto="${2:-tcp}"
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            _ufw_deny_port "$port" "$proto"
            ;;
        firewalld)
            _firewalld_deny_port "$port" "$proto"
            ;;
    esac
}

# 允许 ICMP
allow_icmp() {
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            _ufw_allow_icmp
            ;;
        firewalld)
            _firewalld_allow_icmp
            ;;
    esac
}

# 禁止 ICMP
deny_icmp() {
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            # UFW 默认允许，需要修改 /etc/ufw/before.rules
            log_warn "${MSG_FIREWALL_ICMP_UFW_NOTE}"
            ;;
        firewalld)
            _firewalld_deny_icmp
            ;;
    esac
}

# 配置防火墙默认策略
setup_firewall_defaults() {
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            _ufw_set_defaults
            ;;
        firewalld)
            _firewalld_set_defaults
            ;;
    esac
}

# 启用防火墙
enable_firewall() {
    local fw_type
    fw_type=$(_get_firewall_type)

    case "$fw_type" in
        ufw)
            _ufw_enable
            ;;
        firewalld)
            if _firewalld_reload; then
                log_success "${MSG_FIREWALL_ENABLE_DONE}"
            else
                log_error "Failed to enable firewalld"
                return 1
            fi
            ;;
    esac
}

# ============================================================================
# 快速开始模式
# ============================================================================

# 一键配置防火墙（使用推荐配置）
run_firewall_wizard() {
    log_step "${MSG_FIREWALL_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查系统兼容性
    local fw_type
    fw_type=$(_get_firewall_type)
    if [[ "$fw_type" == "unknown" ]]; then
        log_warn "${MSG_FIREWALL_UNSUPPORTED_OS}"
        return 1
    fi

    # 安装防火墙
    _install_firewall

    # 获取 SSH 端口
    local ssh_port
    ssh_port=$(get_ssh_port)

    # 显示当前状态
    show_firewall_status

    # 配置默认策略
    setup_firewall_defaults

    # 开放 SSH 端口
    log_step "${MSG_FIREWALL_CONFIG_SSH}"
    # 始终放通 22 端口（安全兜底，防止端口变更后锁死）
    open_port "22" "tcp" "SSH-default"
    log_info "${MSG_FIREWALL_SSH_PORT22}"
    # 如果 SSH 端口不是 22，也开放新端口
    if [[ "$ssh_port" != "22" ]]; then
        open_port "$ssh_port" "tcp" "SSH-custom"
    fi

    # 询问是否开放 HTTP/HTTPS
    echo ""
    log_info "${MSG_FIREWALL_HTTP_PROMPT}"
    if confirm "${MSG_FIREWALL_HTTP_CONFIRM}" "y"; then
        open_port "80" "tcp" "HTTP"
        open_port "443" "tcp" "HTTPS"
    fi

    # 询问是否允许 ping
    echo ""
    log_info "${MSG_FIREWALL_ICMP_PROMPT}"
    if confirm "${MSG_FIREWALL_ICMP_CONFIRM}" "y"; then
        allow_icmp
    fi

    # 启用防火墙
    enable_firewall

    # 显示最终状态
    show_firewall_status

    # 显示管理命令提示
    _show_firewall_tips "$fw_type"

    log_success "${MSG_FIREWALL_DONE}"
}

# 显示防火墙管理命令提示
_show_firewall_tips() {
    local fw_type="$1"

    echo ""
    echo -e "${BOLD}${MSG_FIREWALL_TIPS_TITLE}${NC}"
    echo ""

    case "$fw_type" in
        ufw)
            echo -e "  ${MSG_FIREWALL_TIPS_UFW_1}"
            echo -e "  ${MSG_FIREWALL_TIPS_UFW_2}"
            echo -e "  ${MSG_FIREWALL_TIPS_UFW_3}"
            echo -e "  ${MSG_FIREWALL_TIPS_UFW_4}"
            ;;
        firewalld)
            echo -e "  ${MSG_FIREWALL_TIPS_FIREWALLD_1}"
            echo -e "  ${MSG_FIREWALL_TIPS_FIREWALLD_2}"
            echo -e "  ${MSG_FIREWALL_TIPS_FIREWALLD_3}"
            echo -e "  ${MSG_FIREWALL_TIPS_FIREWALLD_4}"
            ;;
    esac
    echo ""
}

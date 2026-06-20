#!/usr/bin/env bash
# ============================================================================
# Fail2Ban 入侵防护配置模块
# 自动安装并配置 SSH 防护 jail
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before fail2ban.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================

FAIL2BAN_JAIL_LOCAL="/etc/fail2ban/jail.local"

# ============================================================================
# 内部函数
# ============================================================================

# 安装 Fail2Ban
_install_fail2ban() {
    log_step "$MSG_FAIL2BAN_INSTALL"

    if command_exists fail2ban-client; then
        log_info "$MSG_FAIL2BAN_ALREADY_INSTALLED"
        return 0
    fi

    case "$DETECTED_OS" in
        ubuntu|debian)
            apt-get install -y fail2ban >> "$LOG_FILE" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            # CentOS/RHEL 需要 EPEL 源
            yum install -y epel-release >> "$LOG_FILE" 2>&1
            yum install -y fail2ban >> "$LOG_FILE" 2>&1
            ;;
        fedora)
            dnf install -y fail2ban >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_error "$MSG_FAIL2BAN_UNSUPPORTED_OS"
            return 1
            ;;
    esac

    log_success "$MSG_FAIL2BAN_INSTALL_DONE"
}

# 获取认证日志路径
_get_auth_log_path() {
    local auth_log
    case "${DETECTED_OS}" in
        ubuntu|debian)
            auth_log="/var/log/auth.log"
            ;;
        centos|rhel|rocky|almalinux)
            auth_log="/var/log/secure"
            ;;
        *)
            auth_log="/var/log/auth.log"
            ;;
    esac

    # 检查日志文件是否存在（部分系统仅使用 journald）
    if [[ ! -f "${auth_log}" ]]; then
        log_warn "认证日志文件未找到: ${auth_log}，fail2ban 可能需要 journald backend"
    fi

    echo "${auth_log}"
}

# 获取 SSH 服务名称
_get_ssh_service_name() {
    echo "sshd"
}

# 备份现有 Fail2Ban 配置
_backup_fail2ban_config() {
    if [[ -f "$FAIL2BAN_JAIL_LOCAL" ]]; then
        backup_file "$FAIL2BAN_JAIL_LOCAL"
    fi
}

# 配置 Fail2Ban jail
_configure_fail2ban_jail() {
    local ssh_port="$1"
    local auth_log="$2"
    local bantime="${3:-3600}"
    local findtime="${4:-600}"
    local maxretry="${5:-5}"

    log_step "$MSG_FAIL2BAN_CONFIGURE"

    # 备份现有配置
    _backup_fail2ban_config

    # 根据操作系统选择 banaction
    local banaction
    case "${DETECTED_OS}" in
        ubuntu|debian)           banaction="ufw" ;;
        centos|rhel|rocky|almalinux|fedora) banaction="firewallcmd-ipset" ;;
        *)                       banaction="iptables-multiport" ;;
    esac

    # 生成 jail.local 配置
    cat > "$FAIL2BAN_JAIL_LOCAL" << EOF
# ============================================================================
# Fail2Ban jail 配置
# 由 linux-one-key 自动生成
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# ============================================================================

[DEFAULT]
# 封禁时间（秒）
bantime = ${bantime}

# 检测时间窗口（秒）
findtime = ${findtime}

# 最大失败次数
maxretry = ${maxretry}

# 封禁动作（根据操作系统自动选择）
banaction = ${banaction}

# 忽略本地回环
ignoreip = 127.0.0.1/8

# ============================================================================
# SSH 防护
# ============================================================================

[sshd]
enabled = true
port = ${ssh_port}
filter = sshd
logpath = ${auth_log}
maxretry = ${maxretry}
bantime = ${bantime}
findtime = ${findtime}
EOF

    log_success "$MSG_FAIL2BAN_CONFIGURE_DONE"
}

# 启动 Fail2Ban 服务
_enable_fail2ban_service() {
    log_step "$MSG_FAIL2BAN_ENABLE"

    systemctl enable fail2ban >> "$LOG_FILE" 2>&1
    systemctl restart fail2ban >> "$LOG_FILE" 2>&1

    # 等待服务启动
    sleep 2

    # 检查服务状态
    if systemctl is-active --quiet fail2ban; then
        log_success "$MSG_FAIL2BAN_ENABLE_DONE"
    else
        log_error "$MSG_FAIL2BAN_ENABLE_FAILED"
        systemctl status fail2ban --no-pager
        return 1
    fi
}

# 显示 Fail2Ban 状态
_show_fail2ban_status() {
    echo ""
    log_step "$MSG_FAIL2BAN_STATUS"
    echo ""

    # 服务状态
    echo -e "${BOLD}${MSG_FAIL2BAN_SERVICE_STATUS}${NC}"
    systemctl status fail2ban --no-pager | head -5
    echo ""

    # jail 状态
    echo -e "${BOLD}${MSG_FAIL2BAN_JAIL_STATUS}${NC}"
    fail2ban-client status sshd 2>/dev/null || log_warn "$MSG_FAIL2BAN_JAIL_NOT_FOUND"
    echo ""

    # 封禁列表
    echo -e "${BOLD}${MSG_FAIL2BAN_BANNED_LIST}${NC}"
    fail2ban-client get sshd banned 2>/dev/null || echo "  (无)"
    echo ""
}

# ============================================================================
# 公共接口函数
# ============================================================================

# 显示 Fail2Ban 状态
show_fail2ban_status() {
    if ! command_exists fail2ban-client; then
        log_warn "$MSG_FAIL2BAN_NOT_INSTALLED"
        return 1
    fi
    _show_fail2ban_status
}

# 获取 Fail2Ban 配置信息
get_fail2ban_info() {
    local ssh_port
    ssh_port=$(get_ssh_port)
    local auth_log
    auth_log=$(_get_auth_log_path)

    echo "SSH 端口: $ssh_port"
    echo "认证日志: $auth_log"
    echo "配置文件: $FAIL2BAN_JAIL_LOCAL"
}

# 手动封禁 IP
ban_ip() {
    local ip="$1"
    local jail="${2:-sshd}"

    if ! command_exists fail2ban-client; then
        log_error "$MSG_FAIL2BAN_NOT_INSTALLED"
        return 1
    fi

    fail2ban-client set "$jail" banip "$ip" >> "$LOG_FILE" 2>&1
    log_success "$MSG_FAIL2BAN_IP_BANNED: $ip"
}

# 手动解封 IP
unban_ip() {
    local ip="$1"
    local jail="${2:-sshd}"

    if ! command_exists fail2ban-client; then
        log_error "$MSG_FAIL2BAN_NOT_INSTALLED"
        return 1
    fi

    fail2ban-client set "$jail" unbanip "$ip" >> "$LOG_FILE" 2>&1
    log_success "$MSG_FAIL2BAN_IP_UNBANNED: $ip"
}

# ============================================================================
# 交互式配置模式
# ============================================================================

# Interactive Fail2Ban configuration with customizable parameters
run_fail2ban_wizard() {
    log_step "${MSG_FAIL2BAN_TITLE}"

    # Check root
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # Install Fail2Ban
    _install_fail2ban

    # Gather config info
    local ssh_port
    ssh_port=$(get_ssh_port)
    local auth_log
    auth_log=$(_get_auth_log_path)

    # Show current info
    echo ""
    log_info "${MSG_FAIL2BAN_CONFIG_INFO}"
    echo "  SSH 端口: ${ssh_port}"
    echo "  认证日志: ${auth_log}"
    echo ""

    # Prompt for customizable parameters
    echo -e "${BOLD}${MSG_FAIL2BAN_CUSTOM_TITLE}${NC}"
    echo -e "${BLUE}${MSG_FAIL2BAN_CUSTOM_PROMPT}${NC}"
    echo ""

    local bantime
    bantime=$(prompt_input "${MSG_FAIL2BAN_BANTIME_PROMPT}" "3600")

    local findtime
    findtime=$(prompt_input "${MSG_FAIL2BAN_FINDTIME_PROMPT}" "600")

    local maxretry
    maxretry=$(prompt_input "${MSG_FAIL2BAN_MAXRETRY_PROMPT}" "5")

    # Validate bantime
    if [[ ! "${bantime}" =~ ^[0-9]+$ ]] || [[ "${bantime}" -lt 1 ]]; then
        log_error "bantime must be a positive integer"
        bantime="3600"
    fi
    # Validate findtime
    if [[ ! "${findtime}" =~ ^[0-9]+$ ]] || [[ "${findtime}" -lt 1 ]]; then
        log_error "findtime must be a positive integer"
        findtime="600"
    fi
    # Validate maxretry
    if [[ ! "${maxretry}" =~ ^[0-9]+$ ]] || [[ "${maxretry}" -lt 1 ]]; then
        log_error "maxretry must be a positive integer"
        maxretry="5"
    fi

    echo ""

    # Configure jail with user-provided values
    _configure_fail2ban_jail "${ssh_port}" "${auth_log}" "${bantime}" "${findtime}" "${maxretry}"

    # Start service
    _enable_fail2ban_service || {
        log_error "${MSG_FAIL2BAN_ENABLE_FAILED}"
        return 1
    }

    # Show status
    _show_fail2ban_status

    # Show tips
    _show_fail2ban_tips

    log_success "${MSG_FAIL2BAN_DONE}"
}

# 显示 Fail2Ban 管理命令提示
_show_fail2ban_tips() {
    echo ""
    echo -e "${BOLD}${MSG_FAIL2BAN_TIPS_TITLE}${NC}"
    echo ""
    echo -e "  ${MSG_FAIL2BAN_TIPS_1}"
    echo -e "  ${MSG_FAIL2BAN_TIPS_2}"
    echo -e "  ${MSG_FAIL2BAN_TIPS_3}"
    echo -e "  ${MSG_FAIL2BAN_TIPS_4}"
    echo -e "  ${MSG_FAIL2BAN_TIPS_5}"
    echo ""
}

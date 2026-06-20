#!/usr/bin/env bash
# ============================================================================
# Fail2Ban 入侵防护配置模块
# 自动安装并配置 SSH 防护 jail
# ============================================================================
set -euo pipefail

# 获取本脚本所在目录（不覆盖外部 SCRIPT_DIR）
_FAIL2BAN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    source "${_FAIL2BAN_DIR}/../base/utils.sh"
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
        centos)
            # CentOS 需要 EPEL 源
            yum install -y epel-release >> "$LOG_FILE" 2>&1
            yum install -y fail2ban >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_error "$MSG_FAIL2BAN_UNSUPPORTED_OS"
            return 1
            ;;
    esac

    log_success "$MSG_FAIL2BAN_INSTALL_DONE"
}

# 获取当前 SSH 端口
_get_ssh_port() {
    local port
    port=$(grep -E "^Port\s+" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
    echo "${port:-22}"
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
        centos|rhel|rocky|almalinux) banaction="firewallcmd-ipset" ;;
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
    ssh_port=$(_get_ssh_port)
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
# 快速开始模式
# ============================================================================

# 一键配置 Fail2Ban（使用推荐配置）
run_fail2ban_hardening() {
    log_step "$MSG_FAIL2BAN_TITLE"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 安装 Fail2Ban
    _install_fail2ban

    # 获取配置参数
    local ssh_port
    ssh_port=$(_get_ssh_port)
    local auth_log
    auth_log=$(_get_auth_log_path)

    # 显示配置信息
    echo ""
    log_info "$MSG_FAIL2BAN_CONFIG_INFO"
    echo "  SSH 端口: $ssh_port"
    echo "  认证日志: $auth_log"
    echo "  封禁时间: 3600 秒 (1 小时)"
    echo "  检测窗口: 600 秒 (10 分钟)"
    echo "  最大重试: 5 次"
    echo ""

    # 配置 jail
    _configure_fail2ban_jail "$ssh_port" "$auth_log"

    # 启动服务
    _enable_fail2ban_service

    # 显示状态
    _show_fail2ban_status

    # 显示管理命令提示
    _show_fail2ban_tips

    log_success "$MSG_FAIL2BAN_DONE"
}

# ============================================================================
# 自定义配置模式
# ============================================================================

# 自定义 Fail2Ban 配置
run_fail2ban_hardening_custom() {
    local bantime="${1:-3600}"
    local findtime="${2:-600}"
    local maxretry="${3:-5}"

    log_step "$MSG_FAIL2BAN_TITLE"

    # 安装 Fail2Ban
    _install_fail2ban

    # 获取配置参数
    local ssh_port
    ssh_port=$(_get_ssh_port)
    local auth_log
    auth_log=$(_get_auth_log_path)

    # 使用自定义参数配置 jail
    _configure_fail2ban_jail "$ssh_port" "$auth_log" "$bantime" "$findtime" "$maxretry"

    # 启动服务
    _enable_fail2ban_service

    # 显示状态
    _show_fail2ban_status

    # 显示管理命令提示
    _show_fail2ban_tips

    log_success "$MSG_FAIL2BAN_DONE"
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

# 允许脚本被直接执行或被 source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_fail2ban_hardening
fi

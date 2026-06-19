#!/usr/bin/env bash
# ============================================================================
# 防火墙配置模块
# 支持 UFW (Ubuntu/Debian) 和 firewalld (CentOS/RHEL)
# ============================================================================
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../base/utils.sh"

# ============================================================================
# 内部函数
# ============================================================================

# 安装防火墙工具
_install_firewall() {
    log_step "$MSG_FIREWALL_INSTALL"

    case "$DETECT_OS" in
        ubuntu|debian)
            if command_exists ufw; then
                log_info "$MSG_FIREWALL_ALREADY_INSTALLED (UFW)"
                return 0
            fi
            apt-get install -y ufw >> "$LOG_FILE" 2>&1
            ;;
        centos)
            if command_exists firewall-cmd; then
                log_info "$MSG_FIREWALL_ALREADY_INSTALLED (firewalld)"
                return 0
            fi
            yum install -y firewalld >> "$LOG_FILE" 2>&1
            ;;
        *)
            log_error "$MSG_FIREWALL_UNSUPPORTED_OS"
            return 1
            ;;
    esac

    log_success "$MSG_FIREWALL_INSTALL_DONE"
}

# 获取防火墙类型
_get_firewall_type() {
    case "$DETECT_OS" in
        ubuntu|debian) echo "ufw" ;;
        centos)        echo "firewalld" ;;
        *)             echo "unknown" ;;
    esac
}

# 获取当前 SSH 端口
_get_current_ssh_port() {
    local port
    port=$(grep -E "^Port\s+" /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' | head -1)
    echo "${port:-22}"
}

# ============================================================================
# UFW 相关函数
# ============================================================================

# 重置 UFW 规则（可选）
_ufw_reset() {
    log_step "$MSG_FIREWALL_RESET"
    ufw --force reset >> "$LOG_FILE" 2>&1
    log_success "$MSG_FIREWALL_RESET_DONE"
}

# 配置 UFW 默认策略
_ufw_set_defaults() {
    log_step "$MSG_FIREWALL_DEFAULT_POLICY"
    ufw default deny incoming >> "$LOG_FILE" 2>&1
    ufw default allow outgoing >> "$LOG_FILE" 2>&1
    log_success "$MSG_FIREWALL_DEFAULT_POLICY_DONE"
}

# UFW 开放端口
_ufw_allow_port() {
    local port="$1"
    local proto="${2:-tcp}"
    local comment="${3:-}"

    if [[ -n "$comment" ]]; then
        ufw allow "${port}/${proto}" comment "$comment" >> "$LOG_FILE" 2>&1
    else
        ufw allow "${port}/${proto}" >> "$LOG_FILE" 2>&1
    fi
    log_info "$MSG_FIREWALL_PORT_OPENED: $port/$proto"
}

# UFW 关闭端口
_ufw_deny_port() {
    local port="$1"
    local proto="${2:-tcp}"
    ufw deny "${port}/${proto}" >> "$LOG_FILE" 2>&1
    log_info "$MSG_FIREWALL_PORT_CLOSED: $port/$proto"
}

# UFW 允许 ICMP (ping)
_ufw_allow_icmp() {
    # UFW 默认允许 ICMP，需要手动禁止才需配置
    log_info "$MSG_FIREWALL_ICMP_DEFAULT"
}

# 启用 UFW
_ufw_enable() {
    log_step "$MSG_FIREWALL_ENABLE"
    ufw --force enable >> "$LOG_FILE" 2>&1
    log_success "$MSG_FIREWALL_ENABLE_DONE"
}

# 显示 UFW 状态
_ufw_show_status() {
    echo ""
    log_step "$MSG_FIREWALL_STATUS"
    ufw status verbose
    echo ""
}

# ============================================================================
# firewalld 相关函数
# ============================================================================

# 启动 firewalld 服务
_firewalld_start() {
    log_step "$MSG_FIREWALL_INSTALL"
    systemctl start firewalld >> "$LOG_FILE" 2>&1
    systemctl enable firewalld >> "$LOG_FILE" 2>&1
    log_success "$MSG_FIREWALL_INSTALL_DONE"
}

# 配置 firewalld 默认策略
_firewalld_set_defaults() {
    log_step "$MSG_FIREWALL_DEFAULT_POLICY"
    # firewalld 默认 zone 就是 drop，已经是拒绝入站
    firewall-cmd --set-default-zone=drop >> "$LOG_FILE" 2>&1
    firewall-cmd --zone=drop --set-target=DROP >> "$LOG_FILE" 2>&1
    log_success "$MSG_FIREWALL_DEFAULT_POLICY_DONE"
}

# firewalld 开放端口
_firewalld_allow_port() {
    local port="$1"
    local proto="${2:-tcp}"
    local comment="${3:-}"

    firewall-cmd --permanent --zone=drop --add-port="${port}/${proto}" >> "$LOG_FILE" 2>&1
    log_info "$MSG_FIREWALL_PORT_OPENED: $port/$proto"
}

# firewalld 关闭端口
_firewalld_deny_port() {
    local port="$1"
    local proto="${2:-tcp}"
    firewall-cmd --permanent --zone=drop --remove-port="${port}/${proto}" >> "$LOG_FILE" 2>&1
    log_info "$MSG_FIREWALL_PORT_CLOSED: $port/$proto"
}

# firewalld 允许 ICMP (ping)
_firewalld_allow_icmp() {
    firewall-cmd --permanent --zone=drop --add-protocol=icmp >> "$LOG_FILE" 2>&1
    log_info "$MSG_FIREWALL_ICMP_ALLOWED"
}

# firewalld 禁止 ICMP
_firewalld_deny_icmp() {
    firewall-cmd --permanent --zone=drop --remove-protocol=icmp >> "$LOG_FILE" 2>&1
    log_info "$MSG_FIREWALL_ICMP_DENIED"
}

# 重新加载 firewalld 规则
_firewalld_reload() {
    firewall-cmd --reload >> "$LOG_FILE" 2>&1
}

# 显示 firewalld 状态
_firewalld_show_status() {
    echo ""
    log_step "$MSG_FIREWALL_STATUS"
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
            log_warn "$MSG_FIREWALL_UNSUPPORTED_OS"
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
            log_warn "$MSG_FIREWALL_ICMP_UFW_NOTE"
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
            _firewalld_reload
            log_success "$MSG_FIREWALL_ENABLE_DONE"
            ;;
    esac
}

# ============================================================================
# 快速开始模式
# ============================================================================

# 一键配置防火墙（使用推荐配置）
run_firewall_hardening() {
    log_step "$MSG_FIREWALL_TITLE"

    # 检查系统兼容性
    local fw_type
    fw_type=$(_get_firewall_type)
    if [[ "$fw_type" == "unknown" ]]; then
        log_warn "$MSG_FIREWALL_UNSUPPORTED_OS"
        return 1
    fi

    # 安装防火墙
    _install_firewall

    # 获取 SSH 端口
    local ssh_port
    ssh_port=$(_get_current_ssh_port)

    # 显示当前状态
    show_firewall_status

    # 配置默认策略
    setup_firewall_defaults

    # 开放 SSH 端口
    log_step "$MSG_FIREWALL_CONFIG_SSH"
    open_port "$ssh_port" "tcp" "SSH"

    # 询问是否开放 HTTP/HTTPS
    echo ""
    log_info "$MSG_FIREWALL_HTTP_PROMPT"
    if confirm "$MSG_FIREWALL_HTTP_CONFIRM" "y"; then
        open_port "80" "tcp" "HTTP"
        open_port "443" "tcp" "HTTPS"
    fi

    # 询问是否允许 ping
    echo ""
    log_info "$MSG_FIREWALL_ICMP_PROMPT"
    if confirm "$MSG_FIREWALL_ICMP_CONFIRM" "y"; then
        allow_icmp
    fi

    # 启用防火墙
    enable_firewall

    # 显示最终状态
    show_firewall_status

    # 显示管理命令提示
    _show_firewall_tips "$fw_type"

    log_success "$MSG_FIREWALL_DONE"
}

# ============================================================================
# 自定义配置模式
# ============================================================================

# 自定义防火墙配置
run_firewall_hardening_custom() {
    local do_http="${1:-n}"
    local do_icmp="${2:-n}"

    log_step "$MSG_FIREWALL_TITLE"

    # 检查系统兼容性
    local fw_type
    fw_type=$(_get_firewall_type)
    if [[ "$fw_type" == "unknown" ]]; then
        log_warn "$MSG_FIREWALL_UNSUPPORTED_OS"
        return 1
    fi

    # 安装防火墙
    _install_firewall

    # 获取 SSH 端口
    local ssh_port
    ssh_port=$(_get_current_ssh_port)

    # 配置默认策略
    setup_firewall_defaults

    # 开放 SSH 端口（必须）
    log_step "$MSG_FIREWALL_CONFIG_SSH"
    open_port "$ssh_port" "tcp" "SSH"

    # 根据参数决定是否开放 HTTP/HTTPS
    if [[ "$do_http" == "y" ]]; then
        open_port "80" "tcp" "HTTP"
        open_port "443" "tcp" "HTTPS"
    fi

    # 根据参数决定是否允许 ICMP
    if [[ "$do_icmp" == "y" ]]; then
        allow_icmp
    fi

    # 询问是否开放其他端口
    echo ""
    log_info "$MSG_FIREWALL_CUSTOM_PORTS"
    while true; do
        read -r -p "  > " extra_port
        if [[ -z "$extra_port" ]]; then
            break
        fi
        # 验证端口号
        if [[ "$extra_port" =~ ^[0-9]+$ ]] && (( extra_port >= 1 && extra_port <= 65535 )); then
            open_port "$extra_port" "tcp"
        else
            log_warn "$MSG_FIREWALL_INVALID_PORT"
        fi
    done

    # 启用防火墙
    enable_firewall

    # 显示最终状态
    show_firewall_status

    # 显示管理命令提示
    _show_firewall_tips "$fw_type"

    log_success "$MSG_FIREWALL_DONE"
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

# 允许脚本被直接执行或被 source
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_firewall_hardening
fi

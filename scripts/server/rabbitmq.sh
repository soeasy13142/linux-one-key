#!/usr/bin/env bash
# rabbitmq.sh - RabbitMQ 安装与安全加固模块
# 安装 RabbitMQ 消息队列，并应用安全基线（删除默认 guest 账号）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before rabbitmq.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly RABBITMQ_SERVICE="rabbitmq-server"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 RabbitMQ 是否已安装（rabbitmqctl 或 rabbitmq-server 命令任一存在）
check_rabbitmq_installed() {
    command_exists rabbitmqctl || command_exists rabbitmq-server
}

# 检查 RabbitMQ 服务是否在运行
check_rabbitmq_running() {
    systemctl is-active "${RABBITMQ_SERVICE}" &>/dev/null
}

# 安装 RabbitMQ 包（按发行版）
_install_rabbitmq_pkg() {
    log_step "${MSG_RABBITMQ_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y rabbitmq-server >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            # CentOS 7/RHEL 7 使用 yum，CentOS 8+ 使用 dnf；先安装 EPEL 源（幂等，失败不阻断）
            local pkg_mgr
            if command_exists dnf; then
                pkg_mgr="dnf"
            else
                pkg_mgr="yum"
            fi
            "${pkg_mgr}" install -y epel-release >> "${LOG_FILE}" 2>&1 || true
            "${pkg_mgr}" install -y rabbitmq-server >> "${LOG_FILE}" 2>&1
            ;;
        fedora)
            dnf install -y rabbitmq-server >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}: ${DETECTED_OS}"
            return 1
            ;;
    esac
}

# 安全加固：删除默认 guest 账号（幂等）
# 必须在服务启动后调用；这是运行时状态变更，无需备份配置文件
_secure_rabbitmq() {
    if ! command_exists rabbitmqctl; then
        log_warn "${MSG_RABBITMQ_NOT_INSTALLED}"
        return 1
    fi

    # 幂等检查：guest 账号已删除则跳过
    if ! rabbitmqctl list_users 2>/dev/null | grep -qE '^guest[[:space:]]'; then
        log_info "${MSG_RABBITMQ_CONFIG_EXISTS}"
        return 0
    fi

    # 删除默认 guest 账号
    if rabbitmqctl delete_user guest >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_RABBITMQ_CONFIG_WRITTEN}"
        return 0
    else
        log_warn "${MSG_RABBITMQ_CONFIG_MISSING}"
        return 1
    fi
}

# ═══════════════════════════════════════════
# 安装 RabbitMQ
# ═══════════════════════════════════════════

install_rabbitmq() {
    log_title "${MSG_RABBITMQ_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_rabbitmq_installed; then
        log_info "${MSG_RABBITMQ_ALREADY}"
        check_rabbitmq_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_RABBITMQ_CONFIRM}" "y"; then
        log_info "${MSG_RABBITMQ_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_rabbitmq_pkg; then
        log_error "${MSG_RABBITMQ_FAILED}"
        return 1
    fi

    # 启用并启动服务
    if systemctl enable --now "${RABBITMQ_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_RABBITMQ_INSTALLED}"
    else
        log_warn "${MSG_RABBITMQ_ENABLE_FAILED}"
    fi

    # 安全加固：删除默认 guest 账号（须在服务启动后运行）
    _secure_rabbitmq || log_warn "${MSG_RABBITMQ_CONFIG_MISSING}"

    # 可选激进项 opt-in：启用管理插件（默认监听所有网卡，需配合防火墙限制访问）
    echo ""
    log_warn "RabbitMQ management plugin listens on all interfaces by default; restrict access via firewall"
    if confirm "Enable RabbitMQ management plugin (rabbitmq_management)?" "n"; then
        if rabbitmq-plugins enable rabbitmq_management >> "${LOG_FILE}" 2>&1; then
            log_success "RabbitMQ management plugin enabled"
        else
            log_warn "${MSG_RABBITMQ_ENABLE_FAILED}"
        fi
    fi

    # 验证服务运行
    if check_rabbitmq_running; then
        log_success "${MSG_RABBITMQ_STATUS_RUNNING}"
    else
        log_warn "${MSG_RABBITMQ_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 RabbitMQ
# ═══════════════════════════════════════════

uninstall_rabbitmq() {
    log_title "${MSG_RABBITMQ_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_rabbitmq_installed; then
        log_warn "${MSG_RABBITMQ_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_RABBITMQ_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_RABBITMQ_CANCELLED}"
        return 0
    fi

    log_step "${MSG_RABBITMQ_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${RABBITMQ_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y rabbitmq-server >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y rabbitmq-server >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y rabbitmq-server >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    log_success "${MSG_RABBITMQ_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_rabbitmq_status() {
    log_title "${MSG_RABBITMQ_STATUS_CHECKING}"

    if ! check_rabbitmq_installed; then
        log_warn "${MSG_RABBITMQ_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(rabbitmqctl version 2>/dev/null || echo unknown)"

    if check_rabbitmq_running; then
        log_success "${MSG_RABBITMQ_STATUS_RUNNING}"
    else
        log_error "${MSG_RABBITMQ_STATUS_NOT_RUNNING}"
    fi

    # 展示安全基线状态（默认 guest 账号是否已删除）
    if rabbitmqctl list_users 2>/dev/null | grep -qE '^guest[[:space:]]'; then
        log_warn "${MSG_RABBITMQ_CONFIG_MISSING}"
    else
        log_info "${MSG_RABBITMQ_CONFIG_WRITTEN}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_rabbitmq_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_RABBITMQ_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BLUE}${MSG_MENU_STATE_LABEL}: $(render_service_state_label check_rabbitmq_installed check_rabbitmq_running)${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_RABBITMQ_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_RABBITMQ_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_RABBITMQ_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_RABBITMQ_MENU_BACK}${NC}"
    echo ""
}

run_rabbitmq_submenu_loop() {
    while true; do
        show_rabbitmq_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_rabbitmq || log_error "${MSG_RABBITMQ_FAILED}"
                press_enter
                ;;
            2)
                uninstall_rabbitmq || log_error "${MSG_RABBITMQ_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_rabbitmq_status || log_error "${MSG_RABBITMQ_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 rabbitmq.sh 已加载
readonly _RABBITMQ_LOADED=1

log_debug "rabbitmq.sh loaded successfully"

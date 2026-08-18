#!/usr/bin/env bash
# nginx.sh - Nginx 安装与安全基线模块
# 安装 Nginx 并应用安全响应头 / 隐藏版本号等基线加固
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before nginx.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly NGINX_SERVICE="nginx"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
NGINX_SECURITY_CONF="${NGINX_SECURITY_CONF:-/etc/nginx/conf.d/security-headers.conf}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Nginx 是否已安装
check_nginx_installed() {
    command_exists nginx
}

# 检查 Nginx 服务是否在运行
check_nginx_running() {
    systemctl is-active "${NGINX_SERVICE}" &>/dev/null
}

# 写入安全响应头 drop-in 配置（保守默认；已存在则备份后保留不覆盖）
# $1: enable_hsts (0/1) — 是否启用 HSTS 强安全头（激进项，默认关闭）
_write_security_headers() {
    local enable_hsts="${1:-0}"

    mkdir -p "$(dirname "${NGINX_SECURITY_CONF}")" 2>/dev/null || true

    # 已有配置：备份后保留，不覆盖用户自定义（幂等 + 安全）
    if [[ -f "${NGINX_SECURITY_CONF}" ]]; then
        backup_file "${NGINX_SECURITY_CONF}" "${MSG_NGINX_BACKUP_HEADERS}" || true
        log_warn "${MSG_NGINX_SECURITY_HEADERS_EXISTS}"
        return 0
    fi

    # 保守基线：隐藏版本号 + 基础安全头 + 请求体限制
    {
        printf 'server_tokens off;\n'
        printf 'add_header X-Frame-Options "SAMEORIGIN" always;\n'
        printf 'add_header X-Content-Type-Options "nosniff" always;\n'
        printf 'add_header Referrer-Policy "strict-origin-when-cross-origin" always;\n'
        printf 'client_body_buffer_size 16k;\n'
        printf 'client_max_body_size 10m;\n'
        if [[ "${enable_hsts}" == "1" ]]; then
            printf 'add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;\n'
        fi
    } > "${NGINX_SECURITY_CONF}"

    log_success "${MSG_NGINX_SECURITY_HEADERS_WRITTEN}"
}

# 安装 Nginx 包（按发行版）
_install_nginx_pkg() {
    log_step "${MSG_NGINX_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y nginx >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf install -y nginx >> "${LOG_FILE}" 2>&1
            else
                yum install -y nginx >> "${LOG_FILE}" 2>&1
            fi
            ;;
        *)
            log_error "${MSG_NGINX_UNSUPPORTED_OS}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装 Nginx
# ═══════════════════════════════════════════

install_nginx() {
    log_title "${MSG_NGINX_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_nginx_installed; then
        log_info "${MSG_NGINX_ALREADY}"
        check_nginx_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_NGINX_CONFIRM}" "y"; then
        log_info "${MSG_NGINX_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_nginx_pkg; then
        log_error "${MSG_NGINX_FAILED}"
        return 1
    fi

    # 激进加固项 opt-in：HSTS（要求站点已启用 HTTPS，否则会破坏 HTTP 访问）
    local enable_hsts=0
    echo ""
    if confirm "${MSG_NGINX_HSTS_PROMPT}" "n"; then
        enable_hsts=1
        log_info "${MSG_NGINX_HSTS_ENABLED}"
    fi

    # 写入安全响应头基线
    _write_security_headers "${enable_hsts}"

    # 启用并启动服务
    if systemctl enable --now "${NGINX_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_NGINX_INSTALLED}"
    else
        log_warn "${MSG_NGINX_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_nginx_running; then
        log_success "${MSG_NGINX_STATUS_RUNNING}"
    else
        log_warn "${MSG_NGINX_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Nginx
# ═══════════════════════════════════════════

uninstall_nginx() {
    log_title "${MSG_NGINX_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_nginx_installed; then
        log_warn "${MSG_NGINX_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_NGINX_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_NGINX_CANCELLED}"
        return 0
    fi

    log_step "${MSG_NGINX_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${NGINX_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y nginx >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y nginx >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y nginx >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除安全头配置文件及其备份
    rm -f "${NGINX_SECURITY_CONF}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/security-headers.conf.bak."* 2>/dev/null || true

    log_success "${MSG_NGINX_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_nginx_status() {
    log_title "${MSG_NGINX_STATUS_CHECKING}"

    if ! check_nginx_installed; then
        log_warn "${MSG_NGINX_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(nginx -v 2>&1 || echo unknown)"

    if check_nginx_running; then
        log_success "${MSG_NGINX_STATUS_RUNNING}"
    else
        log_error "${MSG_NGINX_STATUS_NOT_RUNNING}"
    fi

    # 展示安全头加固状态
    if [[ -f "${NGINX_SECURITY_CONF}" ]]; then
        log_info "${MSG_NGINX_SECURITY_HEADERS_WRITTEN}"
    else
        log_warn "${MSG_NGINX_SECURITY_HEADERS_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_nginx_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_NGINX_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BLUE}${MSG_MENU_STATE_LABEL}: $(render_service_state_label check_nginx_installed check_nginx_running)${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_NGINX_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_NGINX_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_NGINX_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_NGINX_MENU_BACK}${NC}"
    echo ""
}

run_nginx_submenu_loop() {
    while true; do
        show_nginx_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_nginx || log_error "${MSG_NGINX_FAILED}"
                press_enter
                ;;
            2)
                uninstall_nginx || log_error "${MSG_NGINX_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_nginx_status || log_error "${MSG_NGINX_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 nginx.sh 已加载
readonly _NGINX_LOADED=1

log_debug "nginx.sh loaded successfully"

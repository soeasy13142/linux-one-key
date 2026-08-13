#!/usr/bin/env bash
# prometheus.sh - Prometheus 安装与安全加固模块
# 安装 Prometheus 并应用 localhost 绑定安全基线（systemd drop-in）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before prometheus.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly PROMETHEUS_SERVICE="prometheus"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
PROMETHEUS_DROPIN="${PROMETHEUS_DROPIN:-/etc/systemd/system/prometheus.service.d/listen.conf}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Prometheus 是否已安装
check_prometheus_installed() {
    command_exists prometheus
}

# 检查 Prometheus 服务是否在运行
check_prometheus_running() {
    systemctl is-active "${PROMETHEUS_SERVICE}" &>/dev/null
}

# 写入 localhost 绑定安全基线 drop-in（保守默认；已存在则备份后保留不覆盖）
_write_prometheus_hardening() {
    mkdir -p "$(dirname "${PROMETHEUS_DROPIN}")" 2>/dev/null || true

    # 已有 drop-in：备份后保留，不覆盖用户自定义（幂等 + 安全）
    if [[ -f "${PROMETHEUS_DROPIN}" ]]; then
        backup_file "${PROMETHEUS_DROPIN}" "${MSG_PROMETHEUS_BACKUP_CONFIG}" || true
        log_warn "${MSG_PROMETHEUS_CONFIG_EXISTS}"
        return 0
    fi

    # 保守基线：覆盖 ExecStart，仅绑定 localhost，避免暴露到公网
    {
        printf '[Service]\n'
        printf '# 安全加固：仅绑定 localhost，防止 Prometheus 直接暴露到公网\n'
        printf 'ExecStart=\n'
        printf 'ExecStart=/usr/bin/prometheus --config.file=/etc/prometheus/prometheus.yml --storage.tsdb.path=/var/lib/prometheus/metrics2 --web.listen-address=127.0.0.1:9090\n'
    } > "${PROMETHEUS_DROPIN}"

    log_success "${MSG_PROMETHEUS_CONFIG_WRITTEN}"
}

# 安装 Prometheus 包（按发行版）
_install_prometheus_pkg() {
    log_step "${MSG_PROMETHEUS_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y prometheus >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            # Prometheus 位于 EPEL 仓库，需先启用 epel-release
            if command_exists dnf; then
                dnf install -y epel-release >> "${LOG_FILE}" 2>&1
                dnf install -y prometheus >> "${LOG_FILE}" 2>&1
            else
                yum install -y epel-release >> "${LOG_FILE}" 2>&1
                yum install -y prometheus >> "${LOG_FILE}" 2>&1
            fi
            ;;
        fedora)
            # Fedora 主仓库已包含 prometheus，无需 EPEL
            dnf install -y prometheus >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}: ${DETECTED_OS}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装 Prometheus
# ═══════════════════════════════════════════

install_prometheus() {
    log_title "${MSG_PROMETHEUS_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_prometheus_installed; then
        log_info "${MSG_PROMETHEUS_ALREADY}"
        check_prometheus_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_PROMETHEUS_CONFIRM}" "y"; then
        log_info "${MSG_PROMETHEUS_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_prometheus_pkg; then
        log_error "${MSG_PROMETHEUS_FAILED}"
        return 1
    fi

    # 写入 localhost 绑定安全基线
    _write_prometheus_hardening

    # 使 drop-in 生效并启用/启动服务
    systemctl daemon-reload >> "${LOG_FILE}" 2>&1 || true
    if systemctl enable --now "${PROMETHEUS_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_PROMETHEUS_INSTALLED}"
    else
        log_warn "${MSG_PROMETHEUS_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_prometheus_running; then
        log_success "${MSG_PROMETHEUS_STATUS_RUNNING}"
    else
        log_warn "${MSG_PROMETHEUS_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Prometheus
# ═══════════════════════════════════════════

uninstall_prometheus() {
    log_title "${MSG_PROMETHEUS_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_prometheus_installed; then
        log_warn "${MSG_PROMETHEUS_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_PROMETHEUS_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_PROMETHEUS_CANCELLED}"
        return 0
    fi

    log_step "${MSG_PROMETHEUS_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${PROMETHEUS_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y prometheus >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y prometheus >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y prometheus >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除 drop-in 及其备份
    rm -f "${PROMETHEUS_DROPIN}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/listen.conf.bak."* 2>/dev/null || true

    log_success "${MSG_PROMETHEUS_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_prometheus_status() {
    log_title "${MSG_PROMETHEUS_STATUS_CHECKING}"

    if ! check_prometheus_installed; then
        log_warn "${MSG_PROMETHEUS_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(prometheus --version 2>&1 | head -n 1 || echo unknown)"

    if check_prometheus_running; then
        log_success "${MSG_PROMETHEUS_STATUS_RUNNING}"
    else
        log_error "${MSG_PROMETHEUS_STATUS_NOT_RUNNING}"
    fi

    # 展示 localhost 绑定加固状态
    if [[ -f "${PROMETHEUS_DROPIN}" ]]; then
        log_info "${MSG_PROMETHEUS_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_PROMETHEUS_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_prometheus_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_PROMETHEUS_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_PROMETHEUS_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_PROMETHEUS_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_PROMETHEUS_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_PROMETHEUS_MENU_BACK}${NC}"
    echo ""
}

run_prometheus_submenu_loop() {
    while true; do
        show_prometheus_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_prometheus || log_error "${MSG_PROMETHEUS_FAILED}"
                press_enter
                ;;
            2)
                uninstall_prometheus || log_error "${MSG_PROMETHEUS_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_prometheus_status || log_error "${MSG_PROMETHEUS_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 prometheus.sh 已加载
readonly _PROMETHEUS_LOADED=1

log_debug "prometheus.sh loaded successfully"

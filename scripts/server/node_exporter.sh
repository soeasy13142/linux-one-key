#!/usr/bin/env bash
# node_exporter.sh - Node Exporter 安装与安全加固模块
# 安装 Prometheus Node Exporter 并通过 systemd drop-in 应用安全加固基线
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before node_exporter.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly NODE_EXPORTER_SERVICE="node_exporter"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
# 默认路径按发行版的服务名解析（Debian/Ubuntu 为 prometheus-node-exporter）
if [[ -z "${NODE_EXPORTER_DROPIN:-}" ]]; then
    case "${DETECTED_OS}" in
        ubuntu|debian) NODE_EXPORTER_DROPIN="/etc/systemd/system/prometheus-node-exporter.service.d/hardening.conf" ;;
        *) NODE_EXPORTER_DROPIN="/etc/systemd/system/node_exporter.service.d/hardening.conf" ;;
    esac
fi

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 返回实际的二进制名（Debian/Ubuntu 为 prometheus-node-exporter，RHEL 族为 node_exporter）
_node_exporter_bin() {
    case "${DETECTED_OS}" in
        ubuntu|debian) echo "prometheus-node-exporter" ;;
        *) echo "node_exporter" ;;
    esac
}

# 返回实际的 systemd 服务名
_node_exporter_service() {
    case "${DETECTED_OS}" in
        ubuntu|debian) echo "prometheus-node-exporter" ;;
        *) echo "node_exporter" ;;
    esac
}

# 检查 Node Exporter 是否已安装（两种二进制名都尝试）
check_node_exporter_installed() {
    command_exists node_exporter || command_exists prometheus-node-exporter
}

# 检查 Node Exporter 服务是否在运行（两种服务名都尝试）
check_node_exporter_running() {
    systemctl is-active "${NODE_EXPORTER_SERVICE}" &>/dev/null || \
        systemctl is-active prometheus-node-exporter &>/dev/null
}

# 写入 systemd 加固 drop-in（保守默认；已含基线则幂等跳过，不覆盖）
_write_node_exporter_hardening() {
    mkdir -p "$(dirname "${NODE_EXPORTER_DROPIN}")" 2>/dev/null || true

    # 已存在且已含加固基线：幂等跳过，保留现有配置（安全 + 不覆盖用户自定义）
    if [[ -f "${NODE_EXPORTER_DROPIN}" ]] && grep -q "NoNewPrivileges" "${NODE_EXPORTER_DROPIN}" 2>/dev/null; then
        log_info "${MSG_NODE_EXPORTER_CONFIG_EXISTS}"
        return 0
    fi

    # 已存在但不含基线：先备份，再覆盖为保守基线
    if [[ -f "${NODE_EXPORTER_DROPIN}" ]]; then
        backup_file "${NODE_EXPORTER_DROPIN}" "${MSG_NODE_EXPORTER_BACKUP_CONFIG}" || true
    fi

    # 保守基线：禁提权 + 文件系统/家目录只读 + 私有 tmp + 禁 SUID/SGID
    {
        printf '[Service]\n'
        printf 'NoNewPrivileges=yes\n'
        printf 'ProtectSystem=full\n'
        printf 'ProtectHome=yes\n'
        printf 'PrivateTmp=yes\n'
        printf 'RestrictSUIDSGID=yes\n'
    } > "${NODE_EXPORTER_DROPIN}"

    log_success "${MSG_NODE_EXPORTER_CONFIG_WRITTEN}"
}

# 安装 Node Exporter 包（按发行版）
_install_node_exporter_pkg() {
    log_step "${MSG_NODE_EXPORTER_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y prometheus-node-exporter >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            # CentOS/RHEL 系的 node_exporter 包位于 EPEL 源；CentOS 7 使用 yum，CentOS 8+ 使用 dnf
            local pkg_mgr
            if command_exists dnf; then
                pkg_mgr="dnf"
            else
                pkg_mgr="yum"
            fi
            # 安装 EPEL 源（可能已安装或不可用，失败则静默继续）
            "${pkg_mgr}" install -y epel-release >> "${LOG_FILE}" 2>&1 || true
            "${pkg_mgr}" install -y node_exporter >> "${LOG_FILE}" 2>&1
            ;;
        fedora)
            dnf install -y node_exporter >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}: ${DETECTED_OS}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装 Node Exporter
# ═══════════════════════════════════════════

install_node_exporter() {
    log_title "${MSG_NODE_EXPORTER_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_node_exporter_installed; then
        log_info "${MSG_NODE_EXPORTER_ALREADY}"
        check_node_exporter_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_NODE_EXPORTER_CONFIRM}" "y"; then
        log_info "${MSG_NODE_EXPORTER_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_node_exporter_pkg; then
        log_error "${MSG_NODE_EXPORTER_FAILED}"
        return 1
    fi

    # 写入 systemd 加固 drop-in（在启动服务前生效）
    _write_node_exporter_hardening
    systemctl daemon-reload >> "${LOG_FILE}" 2>&1 || true

    # 启用并启动服务（按发行版使用实际服务名）
    if systemctl enable --now "$(_node_exporter_service)" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_NODE_EXPORTER_INSTALLED}"
    else
        log_warn "${MSG_NODE_EXPORTER_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_node_exporter_running; then
        log_success "${MSG_NODE_EXPORTER_STATUS_RUNNING}"
    else
        log_warn "${MSG_NODE_EXPORTER_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Node Exporter
# ═══════════════════════════════════════════

uninstall_node_exporter() {
    log_title "${MSG_NODE_EXPORTER_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_node_exporter_installed; then
        log_warn "${MSG_NODE_EXPORTER_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_NODE_EXPORTER_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_NODE_EXPORTER_CANCELLED}"
        return 0
    fi

    log_step "${MSG_NODE_EXPORTER_UNINSTALLING}"

    # 停止并禁用服务（按发行版使用实际服务名）
    systemctl disable --now "$(_node_exporter_service)" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y prometheus-node-exporter >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y node_exporter >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y node_exporter >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除 systemd drop-in 及其备份
    rm -f "${NODE_EXPORTER_DROPIN}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/hardening.conf.bak."* 2>/dev/null || true

    log_success "${MSG_NODE_EXPORTER_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_node_exporter_status() {
    log_title "${MSG_NODE_EXPORTER_STATUS_CHECKING}"

    if ! check_node_exporter_installed; then
        log_warn "${MSG_NODE_EXPORTER_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$("$(_node_exporter_bin)" --version 2>/dev/null | head -1 || echo unknown)"

    if check_node_exporter_running; then
        log_success "${MSG_NODE_EXPORTER_STATUS_RUNNING}"
    else
        log_error "${MSG_NODE_EXPORTER_STATUS_NOT_RUNNING}"
    fi

    # 展示 systemd 加固状态
    if [[ -f "${NODE_EXPORTER_DROPIN}" ]]; then
        log_info "${MSG_NODE_EXPORTER_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_NODE_EXPORTER_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_node_exporter_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_NODE_EXPORTER_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_NODE_EXPORTER_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_NODE_EXPORTER_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_NODE_EXPORTER_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_NODE_EXPORTER_MENU_BACK}${NC}"
    echo ""
}

run_node_exporter_submenu_loop() {
    while true; do
        show_node_exporter_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_node_exporter || log_error "${MSG_NODE_EXPORTER_FAILED}"
                press_enter
                ;;
            2)
                uninstall_node_exporter || log_error "${MSG_NODE_EXPORTER_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_node_exporter_status || log_error "${MSG_NODE_EXPORTER_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 node_exporter.sh 已加载
readonly _NODE_EXPORTER_LOADED=1

log_debug "node_exporter.sh loaded successfully"

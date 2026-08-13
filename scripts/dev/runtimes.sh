#!/usr/bin/env bash
# runtimes.sh - 编程语言运行时安装模块（Node.js / Python / Go）
# 通过发行版官方软件源安装（保守方案，不使用 nvm/nodesource/版本管理器）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before runtimes.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

# 各发行版官方源中可用的运行时包名
readonly RUNTIMES_PACKAGES=(nodejs npm python3 python3-pip golang)

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查语言运行时是否已安装（任一存在即视为已安装）
check_runtimes_installed() {
    command_exists node || command_exists python3 || command_exists go
}

# 安装运行时包（按发行版；best-effort，单个包失败不影响其他包）
_install_runtimes_pkg() {
    local pkg
    local installer

    case "${DETECTED_OS}" in
        ubuntu|debian)
            installer="apt-get"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                installer="dnf"
            else
                # CentOS 7 官方源缺少部分包（如 golang），非阻塞安装 EPEL 源
                yum install -y epel-release >> "${LOG_FILE}" 2>&1 || true
                installer="yum"
            fi
            ;;
        *)
            log_error "${MSG_RUNTIMES_FAILED}"
            return 1
            ;;
    esac

    for pkg in "${RUNTIMES_PACKAGES[@]}"; do
        if "${installer}" install -y "${pkg}" >> "${LOG_FILE}" 2>&1; then
            log_success "${MSG_RUNTIMES_INSTALLED}: ${pkg}"
        else
            log_warn "${MSG_RUNTIMES_FAILED}: ${pkg}"
        fi
    done

    return 0
}

# ═══════════════════════════════════════════
# 安装运行时
# ═══════════════════════════════════════════

install_runtimes() {
    log_title "${MSG_RUNTIMES_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_runtimes_installed; then
        log_info "${MSG_RUNTIMES_ALREADY}"
        check_runtimes_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_RUNTIMES_CONFIRM}" "y"; then
        log_info "${MSG_RUNTIMES_CANCELLED}"
        return 0
    fi

    log_step "${MSG_RUNTIMES_INSTALLING}"

    # 按发行版安装包（best-effort）
    if ! _install_runtimes_pkg; then
        log_error "${MSG_RUNTIMES_FAILED}"
        return 1
    fi

    log_success "${MSG_RUNTIMES_INSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 卸载运行时
# ═══════════════════════════════════════════

uninstall_runtimes() {
    log_title "${MSG_RUNTIMES_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_runtimes_installed; then
        log_warn "${MSG_RUNTIMES_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_RUNTIMES_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_RUNTIMES_CANCELLED}"
        return 0
    fi

    log_step "${MSG_RUNTIMES_UNINSTALLING}"

    # 按发行版移除包（best-effort，不因单个失败中断）
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y "${RUNTIMES_PACKAGES[@]}" >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y "${RUNTIMES_PACKAGES[@]}" >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y "${RUNTIMES_PACKAGES[@]}" >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
        *)
            log_error "${MSG_RUNTIMES_UNINSTALL_FAILED}"
            return 1
            ;;
    esac

    log_success "${MSG_RUNTIMES_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_runtimes_status() {
    log_title "${MSG_RUNTIMES_STATUS_CHECKING}"

    if ! check_runtimes_installed; then
        log_warn "${MSG_RUNTIMES_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "Node.js: $(node --version 2>/dev/null || echo unknown)"
    log_info "Python:  $(python3 --version 2>/dev/null || echo unknown)"
    log_info "Go:      $(go version 2>/dev/null || echo unknown)"

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_runtimes_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_RUNTIMES_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_RUNTIMES_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_RUNTIMES_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_RUNTIMES_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_RUNTIMES_MENU_BACK}${NC}"
    echo ""
}

run_runtimes_submenu_loop() {
    while true; do
        show_runtimes_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_runtimes || log_error "${MSG_RUNTIMES_FAILED}"
                press_enter
                ;;
            2)
                uninstall_runtimes || log_error "${MSG_RUNTIMES_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_runtimes_status || log_error "${MSG_RUNTIMES_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 runtimes.sh 已加载
readonly _RUNTIMES_LOADED=1

log_debug "runtimes.sh loaded successfully"

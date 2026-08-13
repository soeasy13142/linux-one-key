#!/usr/bin/env bash
# build_toolchain.sh - 编译工具链安装模块 (gcc/make/cmake)
# 提供编译工具链的安装、卸载、状态检查与子菜单
# 支持 Ubuntu/Debian (build-essential) 与 CentOS/RHEL/Rocky/Alma/Fedora (gcc gcc-c++ make cmake)

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before build_toolchain.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查编译工具链是否已安装（gcc 或 make 任一存在即视为已安装）
check_build_toolchain_installed() {
    command_exists gcc || command_exists make
}

# 按发行版安装编译工具链包
_install_build_toolchain_pkg() {
    log_step "${MSG_BUILD_TOOLCHAIN_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y build-essential cmake >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf install -y gcc gcc-c++ make cmake >> "${LOG_FILE}" 2>&1
            else
                yum install -y gcc gcc-c++ make cmake >> "${LOG_FILE}" 2>&1
            fi
            ;;
        *)
            log_error "${MSG_BUILD_TOOLCHAIN_FAILED}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装编译工具链
# ═══════════════════════════════════════════

install_build_toolchain() {
    log_title "${MSG_BUILD_TOOLCHAIN_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_build_toolchain_installed; then
        log_info "${MSG_BUILD_TOOLCHAIN_ALREADY}"
        check_build_toolchain_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_BUILD_TOOLCHAIN_CONFIRM}" "y"; then
        log_info "${MSG_BUILD_TOOLCHAIN_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_build_toolchain_pkg; then
        log_error "${MSG_BUILD_TOOLCHAIN_FAILED}"
        return 1
    fi

    log_success "${MSG_BUILD_TOOLCHAIN_INSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 卸载编译工具链
# ═══════════════════════════════════════════

uninstall_build_toolchain() {
    log_title "${MSG_BUILD_TOOLCHAIN_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_build_toolchain_installed; then
        log_warn "${MSG_BUILD_TOOLCHAIN_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_BUILD_TOOLCHAIN_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_BUILD_TOOLCHAIN_CANCELLED}"
        return 0
    fi

    log_step "${MSG_BUILD_TOOLCHAIN_UNINSTALLING}"

    # 注意：卸载 build-essential 可能影响依赖它的其他软件包，仅做 best-effort 移除
    log_warn "${MSG_BUILD_TOOLCHAIN_UNINSTALL_WARN}"

    # 按发行版移除包（best-effort，失败不中断）
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y build-essential cmake >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y gcc gcc-c++ make cmake >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y gcc gcc-c++ make cmake >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    log_success "${MSG_BUILD_TOOLCHAIN_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_build_toolchain_status() {
    log_title "${MSG_BUILD_TOOLCHAIN_STATUS_CHECKING}"

    if ! check_build_toolchain_installed; then
        log_warn "${MSG_BUILD_TOOLCHAIN_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(gcc --version 2>/dev/null | head -1 || echo unknown)"
    log_info "$(make --version 2>/dev/null | head -1 || echo unknown)"
    log_info "$(cmake --version 2>/dev/null | head -1 || echo unknown)"

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_build_toolchain_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_BUILD_TOOLCHAIN_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_BUILD_TOOLCHAIN_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_BUILD_TOOLCHAIN_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_BUILD_TOOLCHAIN_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_BUILD_TOOLCHAIN_MENU_BACK}${NC}"
    echo ""
}

run_build_toolchain_submenu_loop() {
    while true; do
        show_build_toolchain_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_build_toolchain || log_error "${MSG_BUILD_TOOLCHAIN_FAILED}"
                press_enter
                ;;
            2)
                uninstall_build_toolchain || log_error "${MSG_BUILD_TOOLCHAIN_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_build_toolchain_status || log_error "${MSG_BUILD_TOOLCHAIN_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 build_toolchain.sh 已加载
readonly _BUILD_TOOLCHAIN_LOADED=1

log_debug "build_toolchain.sh loaded successfully"

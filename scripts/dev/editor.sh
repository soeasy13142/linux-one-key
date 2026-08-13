#!/usr/bin/env bash
# editor.sh - 编辑器（Vim/Nano）安装与配置模块
# 安装 vim/nano 并写入 ~/.vimrc / ~/.config/nano/nanorc 基础配置
# dev 变体：无 systemd 服务，无 check_editor_running（编辑器不是守护进程）

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before editor.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
EDITOR_VIMRC="${EDITOR_VIMRC:-${HOME}/.vimrc}"
EDITOR_NANORC="${EDITOR_NANORC:-${HOME}/.config/nano/nanorc}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查是否已安装任一编辑器（vim 或 nano）
check_editor_installed() {
    command_exists vim || command_exists nano
}

# 安装 vim / nano 包（按发行版；幂等：已安装的包会被包管理器跳过）
_install_editor_pkg() {
    # 只要 vim 或 nano 有缺失就尝试安装（两者一并安装，缺失的判断交给包管理器幂等处理）
    if command_exists vim && command_exists nano; then
        return 0
    fi

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y vim nano >> "${LOG_FILE}" 2>&1 || return 1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf install -y vim nano >> "${LOG_FILE}" 2>&1 || return 1
            else
                yum install -y vim nano >> "${LOG_FILE}" 2>&1 || return 1
            fi
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}"
            return 1
            ;;
    esac
}

# 写入 ~/.vimrc 基础配置（已存在则备份后保留，不覆盖用户自定义）
_write_vimrc() {
    mkdir -p "$(dirname "${EDITOR_VIMRC}")" 2>/dev/null || true

    if [[ -f "${EDITOR_VIMRC}" ]]; then
        backup_file "${EDITOR_VIMRC}" "${MSG_LOG_BACKUP}" || true
        log_info "${MSG_EDITOR_ALREADY}: ${EDITOR_VIMRC}"
        return 0
    fi

    {
        printf 'set number\n'
        printf 'syntax on\n'
        printf 'set autoindent\n'
        printf 'set expandtab\n'
        printf 'set shiftwidth=4\n'
        printf 'set tabstop=4\n'
    } > "${EDITOR_VIMRC}"

    log_debug "Written ${EDITOR_VIMRC}"
}

# 写入 ~/.config/nano/nanorc 基础配置（已存在则备份后保留，不覆盖用户自定义）
_write_nanorc() {
    mkdir -p "$(dirname "${EDITOR_NANORC}")" 2>/dev/null || true

    if [[ -f "${EDITOR_NANORC}" ]]; then
        backup_file "${EDITOR_NANORC}" "${MSG_LOG_BACKUP}" || true
        log_info "${MSG_EDITOR_ALREADY}: ${EDITOR_NANORC}"
        return 0
    fi

    {
        printf 'set autoindent\n'
        printf 'set tabsize 4\n'
        printf 'set linenumbers\n'
        printf 'set softwrap\n'
    } > "${EDITOR_NANORC}"

    log_debug "Written ${EDITOR_NANORC}"
}

# 移除单个 dotfile：有备份则优先恢复原文件，无备份则直接删除
_remove_dotfile() {
    local file="$1"
    local name latest

    name="$(basename "${file}")"
    latest="$(find "${BACKUP_DIR}" -maxdepth 1 -name "${name}.bak.*" -type f 2>/dev/null | sort -r | head -1 || true)"

    if [[ -n "${latest}" ]] && [[ -f "${latest}" ]]; then
        if ! restore_file "${latest}" "${file}"; then
            rm -f "${file}" 2>/dev/null || true
        fi
    else
        rm -f "${file}" 2>/dev/null || true
    fi
}

# ═══════════════════════════════════════════
# 安装编辑器
# ═══════════════════════════════════════════

install_editor() {
    log_title "${MSG_EDITOR_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 确认安装（默认 y）
    if ! confirm "${MSG_EDITOR_CONFIRM}" "y"; then
        log_info "${MSG_EDITOR_CANCELLED}"
        return 0
    fi

    log_step "${MSG_EDITOR_INSTALLING}"

    # 安装 vim/nano 包
    if ! _install_editor_pkg; then
        log_error "${MSG_EDITOR_FAILED}"
        return 1
    fi

    # 写入编辑器 dotfiles（幂等：已存在则备份后跳过）
    _write_vimrc
    _write_nanorc

    log_success "${MSG_EDITOR_INSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 卸载编辑器配置
# ═══════════════════════════════════════════

uninstall_editor() {
    log_title "${MSG_EDITOR_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_editor_installed; then
        log_warn "${MSG_EDITOR_NOT_INSTALLED}"
        return 0
    fi

    # 确认撤销（默认 n）
    if ! confirm "${MSG_EDITOR_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_EDITOR_CANCELLED}"
        return 0
    fi

    log_step "${MSG_EDITOR_UNINSTALLING}"

    # 移除 dotfile（不卸载 vim/nano 本身；有备份则恢复原文件）
    _remove_dotfile "${EDITOR_VIMRC}"
    _remove_dotfile "${EDITOR_NANORC}"

    log_success "${MSG_EDITOR_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_editor_status() {
    log_title "${MSG_EDITOR_STATUS_CHECKING}"

    if ! check_editor_installed; then
        log_warn "${MSG_EDITOR_NOT_INSTALLED}"
        return 1
    fi

    echo ""

    if command_exists vim; then
        log_info "$(vim --version 2>/dev/null | head -1 || echo unknown)"
    else
        log_warn "vim: ${MSG_EDITOR_NOT_INSTALLED}"
    fi

    if command_exists nano; then
        log_info "$(nano --version 2>/dev/null | head -1 || echo unknown)"
    else
        log_warn "nano: ${MSG_EDITOR_NOT_INSTALLED}"
    fi

    # 配置文件存在性
    if [[ -f "${EDITOR_VIMRC}" ]]; then
        log_info "vimrc (${EDITOR_VIMRC}): ${MSG_STATUS_INSTALLED}"
    else
        log_warn "vimrc (${EDITOR_VIMRC}): ${MSG_STATUS_NOT_INSTALLED}"
    fi

    if [[ -f "${EDITOR_NANORC}" ]]; then
        log_info "nanorc (${EDITOR_NANORC}): ${MSG_STATUS_INSTALLED}"
    else
        log_warn "nanorc (${EDITOR_NANORC}): ${MSG_STATUS_NOT_INSTALLED}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_editor_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_EDITOR_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_EDITOR_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_EDITOR_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_EDITOR_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_EDITOR_MENU_BACK}${NC}"
    echo ""
}

run_editor_submenu_loop() {
    while true; do
        show_editor_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_editor || log_error "${MSG_EDITOR_FAILED}"
                press_enter
                ;;
            2)
                uninstall_editor || log_error "${MSG_EDITOR_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_editor_status || log_error "${MSG_EDITOR_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 editor.sh 已加载
readonly _EDITOR_LOADED=1

log_debug "editor.sh loaded successfully"

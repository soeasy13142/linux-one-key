#!/usr/bin/env bash
# git.sh - Git 安装与配置模块（开发工具）
# 安装 Git 并写入 ~/.gitconfig 基线配置（默认分支、编辑器、常用别名、用户身份）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before git.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
GIT_CONFIG="${GIT_CONFIG:-${HOME}/.gitconfig}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Git 是否已安装
check_git_installed() {
    command_exists git
}

# 检查 .gitconfig 是否已配置基线（幂等判断：init.defaultBranch 是否存在）
_git_configured() {
    [[ -f "${GIT_CONFIG}" ]] && grep -qi "defaultBranch" "${GIT_CONFIG}" 2>/dev/null
}

# 安装 Git 包（按发行版）
_install_git_pkg() {
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y git >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf install -y git >> "${LOG_FILE}" 2>&1
            else
                yum install -y git >> "${LOG_FILE}" 2>&1
            fi
            ;;
        *)
            # 未知发行版：默认尝试 apt-get
            apt-get install -y git >> "${LOG_FILE}" 2>&1
            ;;
    esac
}

# 写入 .gitconfig 基线配置（幂等；已存在则备份后原地更新，不覆盖用户自定义）
_write_gitconfig() {
    # 备份已有 .gitconfig（存在时）
    if [[ -f "${GIT_CONFIG}" ]]; then
        backup_file "${GIT_CONFIG}" >/dev/null 2>&1 || true
    fi

    mkdir -p "$(dirname "${GIT_CONFIG}")" 2>/dev/null || true

    # 用户身份：仅当已有配置中不存在时才提示输入（已存在则跳过）
    local git_name=""
    local git_email=""
    git_name="$(git config --file "${GIT_CONFIG}" --get user.name 2>/dev/null || true)"
    git_email="$(git config --file "${GIT_CONFIG}" --get user.email 2>/dev/null || true)"

    if [[ -z "${git_name}" ]]; then
        git_name="$(prompt_input "${MSG_GIT_NAME_PROMPT}" "")"
    fi
    if [[ -z "${git_email}" ]]; then
        git_email="$(prompt_input "${MSG_GIT_EMAIL_PROMPT}" "")"
    fi

    # 基线配置
    git config --file "${GIT_CONFIG}" init.defaultBranch main
    git config --file "${GIT_CONFIG}" core.editor vim
    git config --file "${GIT_CONFIG}" alias.st status
    git config --file "${GIT_CONFIG}" alias.co checkout
    git config --file "${GIT_CONFIG}" alias.br branch
    git config --file "${GIT_CONFIG}" alias.lg "log --oneline --graph"

    # 仅在提示输入后写入用户身份（空值跳过）
    if [[ -n "${git_name}" ]]; then
        git config --file "${GIT_CONFIG}" user.name "${git_name}"
    fi
    if [[ -n "${git_email}" ]]; then
        git config --file "${GIT_CONFIG}" user.email "${git_email}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 安装 Git
# ═══════════════════════════════════════════

install_git() {
    log_title "${MSG_GIT_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 已配置则跳过（幂等）
    if _git_configured; then
        log_info "${MSG_GIT_ALREADY}"
        check_git_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_GIT_CONFIRM}" "y"; then
        log_info "${MSG_GIT_CANCELLED}"
        return 0
    fi

    log_step "${MSG_GIT_INSTALLING}"

    # 安装 Git 包（缺失时）
    if ! check_git_installed; then
        if ! _install_git_pkg; then
            log_error "${MSG_GIT_FAILED}"
            return 1
        fi
    fi

    # 写入 .gitconfig 基线配置
    if ! _write_gitconfig; then
        log_error "${MSG_GIT_FAILED}"
        return 1
    fi

    log_success "${MSG_GIT_INSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 撤销 Git 配置
# ═══════════════════════════════════════════

uninstall_git() {
    log_title "${MSG_GIT_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 确认撤销
    if ! confirm "${MSG_GIT_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_GIT_CANCELLED}"
        return 0
    fi

    log_step "${MSG_GIT_UNINSTALLING}"

    # 优先恢复备份（排除 .meta sidecar）
    local latest_backup
    latest_backup="$(find "${BACKUP_DIR}" -name '.gitconfig.bak.*' ! -name '*.meta' -print 2>/dev/null | sort | tail -1)"

    if [[ -n "${latest_backup}" && -f "${latest_backup}" ]]; then
        if ! restore_file "${latest_backup}" "${GIT_CONFIG}" >/dev/null 2>&1; then
            log_error "${MSG_GIT_UNINSTALL_FAILED}"
            return 1
        fi
        log_success "${MSG_GIT_UNINSTALLED}"
    else
        # 无备份：直接删除我们创建的 .gitconfig（不卸载 git 二进制，风险过高）
        rm -f "${GIT_CONFIG}" 2>/dev/null || true
        log_success "${MSG_GIT_UNINSTALLED}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_git_status() {
    log_title "${MSG_GIT_STATUS_CHECKING}"

    if ! check_git_installed; then
        log_warn "${MSG_GIT_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(git --version 2>/dev/null || echo unknown)"
    log_info "$(git config --list 2>/dev/null || true)"

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_git_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_GIT_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_GIT_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_GIT_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_GIT_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_GIT_MENU_BACK}${NC}"
    echo ""
}

run_git_submenu_loop() {
    while true; do
        show_git_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_git || log_error "${MSG_GIT_FAILED}"
                press_enter
                ;;
            2)
                uninstall_git || log_error "${MSG_GIT_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_git_status || log_error "${MSG_GIT_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 git.sh 已加载
readonly _GIT_LOADED=1

log_debug "git.sh loaded successfully"

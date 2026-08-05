#!/usr/bin/env bash
# mirror.sh - 更换系统软件源模块
# 交互式更换 / 恢复官方 / 查看当前系统软件源（apt / yum / dnf）
#
# 核心换源逻辑 vendored 自 SuperManito/LinuxMirrors（MIT License）
#   GitHub: https://github.com/SuperManito/LinuxMirrors
#   Website: https://linuxmirrors.cn
# 许可证全文与出处详见 THIRD_PARTY_NOTICES.md。
#
# 注意：本模块的换源核心位于 scripts/server/mirrors/lm_core.sh（约 8800 行），
#       文件体积超出项目"文件 <800 行"规范，属第三方 vendored 代码的有意例外。
#       集成模块本文件保持项目风格（约 200 行）。

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before mirror.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly MIRROR_CORE_PATH="${SCRIPT_DIR}/scripts/server/mirrors/lm_core.sh"

# ═══════════════════════════════════════════
# 核心换源流程（subshell 隔离）
# ═══════════════════════════════════════════

# 在 subshell 内隔离运行 LinuxMirrors 换源核心
# - 必须在 ( ... ) 内先 set +e +u +o pipefail：vendored 代码依赖 $? 显式判断、写法不兼容 set -e
# - source 只发生在 subshell 内，vendored 的全部全局变量 / 函数 / trap / exit 不进入宿主作用域（零命名冲突）
# - 无参 = LinuxMirrors 完整交互换源；--use-official-source = 恢复官方源
run_mirror_flow() {
    # root 检查（换源会修改 /etc/apt/sources.list、/etc/yum.repos.d/* 等系统文件）
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    local -a lm_args=("$@")
    (
        set +e +u +o pipefail

        if [[ ! -f "${MIRROR_CORE_PATH}" ]]; then
            # vendored 环境内应急报错（subshell 内不依赖项目 log_*，避免变量未定义）
            printf '%s\n' "Error: ${MIRROR_CORE_PATH} not found" >&2
            return 1
        fi

        # shellcheck disable=SC1090 # MIRROR_CORE_PATH 为变量路径，无法静态追踪（vendored 核心只在 subshell 内 source）
        source "${MIRROR_CORE_PATH}"
        lm_main "${lm_args[@]}"
    )
}

# ═══════════════════════════════════════════
# 查看当前软件源
# ═══════════════════════════════════════════

# 打印单个软件源文件（路径 + 缩进内容）
_print_source_file() {
    local file="$1"
    [[ -f "${file}" ]] || return 0
    log_info "  ${file}"
    sed 's/^/    /' "${file}" 2>/dev/null || true
}

# 按包管理器打印当前软件源
# apt → /etc/apt/sources.list 与 /etc/apt/sources.list.d/；yum/dnf → /etc/yum.repos.d/*.repo
show_current_sources() {
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    local pkg_manager
    pkg_manager="$(get_detected_pkg_manager 2>/dev/null || true)"
    if [[ -z "${pkg_manager}" || "${pkg_manager}" == "unknown" ]]; then
        pkg_manager="$(get_package_manager 2>/dev/null || true)"
    fi

    case "${pkg_manager}" in
        apt)
            log_info "${MSG_MIRROR_VIEW_TITLE}"
            _print_source_file "/etc/apt/sources.list"
            if [[ -d /etc/apt/sources.list.d/ ]]; then
                local src_file
                for src_file in /etc/apt/sources.list.d/*; do
                    [[ -f "${src_file}" ]] || continue
                    _print_source_file "${src_file}"
                done
            fi
            ;;
        yum|dnf)
            log_info "${MSG_MIRROR_VIEW_TITLE}"
            if [[ -d /etc/yum.repos.d/ ]]; then
                local repo_file
                for repo_file in /etc/yum.repos.d/*.repo; do
                    [[ -f "${repo_file}" ]] || continue
                    _print_source_file "${repo_file}"
                done
            fi
            ;;
        *)
            log_warn "${MSG_MIRROR_UNSUPPORTED}"
            ;;
    esac
    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

# 显示更换软件源子菜单
show_mirror_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_MIRROR_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MIRROR_MENU_CHANGE_SOURCE}${NC}"
    echo -e "  ${GREEN}${MSG_MIRROR_MENU_RESTORE_OFFICIAL}${NC}"
    echo -e "  ${GREEN}${MSG_MIRROR_MENU_VIEW_SOURCE}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_MIRROR_MENU_BACK}${NC}"
    echo ""
}

# 运行更换软件源子菜单循环
run_mirror_submenu_loop() {
    while true; do
        show_mirror_submenu
        local choice
        choice=$(prompt_input "${MSG_MIRROR_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                log_warn "${MSG_MIRROR_CONFIRM_CHANGE}"
                if confirm "${MSG_MIRROR_CONFIRM_CHANGE}" "y"; then
                    run_mirror_flow || log_error "${MSG_MIRROR_ERROR_CHANGE}"
                fi
                press_enter
                ;;
            2)
                log_warn "${MSG_MIRROR_CONFIRM_RESTORE}"
                if confirm "${MSG_MIRROR_CONFIRM_RESTORE}" "y"; then
                    run_mirror_flow --use-official-source || log_error "${MSG_MIRROR_ERROR_RESTORE}"
                fi
                press_enter
                ;;
            3)
                show_current_sources || log_error "${MSG_MIRROR_ERROR_VIEW}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_warn "${MSG_MIRROR_MENU_INVALID}" ;;
        esac
    done
}

# 标记 mirror.sh 已加载
readonly _MIRROR_LOADED=1

log_debug "mirror.sh loaded successfully"

#!/usr/bin/env bash
# ============================================================================
# install.sh - Linux 安全加固脚本主入口
# 支持多种执行方式：
#   1. curl 管道: curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash
#   2. 下载执行:  wget -qO- https://github.com/soeasy13142/linux-one-key/archive/main.tar.gz | tar xz && cd linux-one-key-main && sudo bash install.sh
#   3. 克隆执行:  git clone https://github.com/soeasy13142/linux-one-key && cd linux-one-key && sudo bash install.sh
# ============================================================================

set -eo pipefail
# 注意: 不使用 -u (nounset)，因为 curl 管道模式下 BASH_SOURCE 可能未绑定

# ═══════════════════════════════════════════
# 常量
# ═══════════════════════════════════════════

GITHUB_REPO="soeasy13142/linux-one-key"
GITHUB_BRANCH="main"
GITHUB_TARBALL_URL="https://github.com/${GITHUB_REPO}/archive/refs/heads/${GITHUB_BRANCH}.tar.gz"

# 运行模式：lite（精简版）或 full（完整版，默认）
INSTALL_MODE="${INSTALL_MODE:-full}"

# ═══════════════════════════════════════════
# Bootstrap: curl 管道模式自动下载完整仓库并 re-exec
# ═══════════════════════════════════════════

_bootstrap_and_reexec() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    # 信号处理：INT/TERM 时清理临时目录，防止 /tmp 残留
    trap 'rm -rf "${tmp_dir}"; exit 1' INT TERM

    echo "正在从 GitHub 下载 linux-one-key..."
    echo "  仓库: https://github.com/${GITHUB_REPO}"
    echo ""

    # 下载 tarball 并解压
    if ! curl -fsSL --connect-timeout 15 --max-time 120 "${GITHUB_TARBALL_URL}" | tar xz -C "${tmp_dir}"; then
        echo "错误: 下载或解压失败"
        echo "请检查网络连接，或手动克隆仓库:"
        echo "  git clone https://github.com/${GITHUB_REPO}"
        rm -rf "${tmp_dir}"
        exit 1
    fi

    # 找到解压后的目录 (linux-one-key-main)
    local extracted_dir
    extracted_dir=$(find "${tmp_dir}" -maxdepth 1 -type d -name "linux-one-key-*" | head -1)

    if [[ -z "${extracted_dir}" ]] || [[ ! -f "${extracted_dir}/install.sh" ]]; then
        echo "错误: 解压后找不到 install.sh"
        rm -rf "${tmp_dir}"
        exit 1
    fi

    # 基本完整性校验：文件存在、非空、合法 shebang
    if [[ ! -s "${extracted_dir}/install.sh" ]]; then
        echo "错误: install.sh 为空或不存在"
        rm -rf "${tmp_dir}"
        exit 1
    fi
    local first_line
    first_line=$(head -1 "${extracted_dir}/install.sh")
    if [[ "${first_line}" != "#!/usr/bin/env bash" ]]; then
        echo "错误: install.sh 格式异常（shebang 不匹配）"
        echo "  首行: ${first_line}"
        rm -rf "${tmp_dir}"
        exit 1
    fi

    echo "下载完成，正在启动安装脚本..."
    echo ""

    # 传递临时目录路径，让 re-exec 后的脚本负责清理
    export _CLEANUP_DIR="${tmp_dir}"

    # 从解压目录 re-exec 自身，传递所有参数
    # 使用 exec 替换当前进程，临时目录在脚本退出后自动清理
    # curl 管道模式下 stdin 是管道，exec 后已关闭（EOF），
    # 需要重新打开 stdin 以支持交互式输入
    # 注意: "$@" 包含原始参数（如 --yes），会传递给 re-exec 的脚本
    local args=("$@")
    chmod +x "${extracted_dir}/install.sh"
    # curl 管道下 stdin 是管道，但控制终端 /dev/tty 仍然存在
    # 尝试打开控制终端；-c 只检查设备节点存在，需实际打开才能确认可用
    if ( : < /dev/tty ) 2>/dev/null; then
        exec bash "${extracted_dir}/install.sh" "${args[@]}" < /dev/tty
    else
        echo "错误: 未检测到交互式终端"
        echo "非交互环境请使用 --status 模式:"
        echo "  curl -fsSL .../install.sh | bash -s -- --status"
        rm -rf "${tmp_dir}"
        exit 1
    fi
}

# ═══════════════════════════════════════════
# 参数解析
# ═══════════════════════════════════════════

# Parse command line arguments
_parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --lite)
                export INSTALL_MODE="lite"
                ;;
            --status)
                export TARGET_MODULE="status"
                ;;
            --help|-h)
                echo "${MSG_HELP_USAGE}"
                echo ""
                echo "${MSG_HELP_OPTIONS}"
                echo "${MSG_HELP_LITE}"
                echo "${MSG_HELP_STATUS}"
                echo "${MSG_HELP_HELP}"
                echo ""
                echo "${MSG_HELP_NO_ARGS}"
                echo ""
                echo "${MSG_HELP_EXAMPLES}"
                echo "${MSG_HELP_EXAMPLE_INTERACTIVE}"
                echo "${MSG_HELP_EXAMPLE_STATUS}"
                echo "${MSG_HELP_EXAMPLE_CURL}"
                exit 0
                ;;
            --yes|-y|--quick|--ssh|--firewall|--fail2ban)
                local removed_arg="${arg#--}"
                removed_arg="${removed_arg#-}"
                echo ""
                # shellcheck disable=SC2059
                log_error "$(printf "${MSG_ERROR_REMOVED_ARG}" "${removed_arg}")"
                log_info "${MSG_ERROR_REMOVED_HINT}"
                echo ""
                exit 1
                ;;
            *)
                # shellcheck disable=SC2059
                echo -e "${RED}$(printf "${MSG_ERROR_UNKNOWN_ARG}" "${arg}")${NC}"
                echo "${MSG_ERROR_USE_HELP}"
                exit 1
                ;;
        esac
    done
}

# 检测是否通过 curl 管道执行
# 注意: BASH_SOURCE[0] 在函数内外行为不同（管道模式下函数内返回 "main"），
#       因此必须在顶层捕获，不能在函数内读取
_SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
_is_curl_pipe() {
    [[ -z "${_SCRIPT_SOURCE}" ]] || [[ "${_SCRIPT_SOURCE}" == "bash" ]] || [[ "${_SCRIPT_SOURCE}" == "/dev/stdin" ]]
}

# 如果是 curl 管道模式，先下载完整仓库再 re-exec
if _is_curl_pipe; then
    _bootstrap_and_reexec "$@"
    # exec 会替换进程，不会执行到这里
    exit 1
fi

# ═══════════════════════════════════════════
# 以下是正常的本地执行流程
# ═══════════════════════════════════════════

# 获取脚本真实路径
_get_script_dir() {
    local source="${BASH_SOURCE[0]}"

    # 处理符号链接
    while [[ -L "${source}" ]]; do
        local dir
        dir="$(cd -P "$(dirname "${source}")" && pwd)"
        source="$(readlink "${source}")"
        [[ "${source}" != /* ]] && source="${dir}/${source}"
    done

    cd -P "$(dirname "${source}")" && pwd
}

# 设置 SCRIPT_DIR
SCRIPT_DIR="$(_get_script_dir)"
export SCRIPT_DIR

# 在 curl 管道检测和脚本目录检查完成后启用 nounset，
# 此后脚本定义的所有变量必须有初始值，变量名拼写错误将立即报错而非静默展开为空。
# 对有意可选的变量请使用 ${VAR:-} 模式。
set -u

# 检查 scripts 目录是否存在
if [[ ! -d "${SCRIPT_DIR}/scripts" ]]; then
    echo "错误: 未找到 scripts 目录"
    echo ""
    echo "请使用以下方式之一运行此脚本:"
    echo "  1. curl 管道执行 (推荐):"
    echo "     curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/install.sh | sudo bash"
    echo ""
    echo "  2. 克隆仓库后执行:"
    echo "     git clone https://github.com/${GITHUB_REPO}.git"
    echo "     cd linux-one-key && sudo bash install.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 加载依赖模块
# ═══════════════════════════════════════════

# 加载工具函数
load_dependencies() {
    local base_dir="${SCRIPT_DIR}/scripts/base"

    # 加载 utils.sh
    if [[ ! -f "${base_dir}/utils.sh" ]]; then
        echo "Error: Cannot find utils.sh at ${base_dir}/utils.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${base_dir}/utils.sh"

    # 加载语言文件
    load_lang "${SCRIPT_DIR}"

    # 加载 detect.sh
    if [[ ! -f "${base_dir}/detect.sh" ]]; then
        echo "Error: Cannot find detect.sh at ${base_dir}/detect.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${base_dir}/detect.sh"

    # 加载 init.sh
    if [[ ! -f "${base_dir}/init.sh" ]]; then
        echo "Error: Cannot find init.sh at ${base_dir}/init.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${base_dir}/init.sh"

    # 加载 mode.sh（Lite/Full 模式注册表）
    if [[ ! -f "${base_dir}/mode.sh" ]]; then
        echo "Error: Cannot find mode.sh at ${base_dir}/mode.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${base_dir}/mode.sh"

    # 加载 swap.sh（仅 Full 模式）
    if is_mode_full; then
        if [[ ! -f "${base_dir}/swap.sh" ]]; then
            echo "Error: Cannot find swap.sh at ${base_dir}/swap.sh"
            exit 1
        fi
        # shellcheck source=/dev/null
        source "${base_dir}/swap.sh"
    fi

    # 加载 ssh.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/ssh.sh" ]]; then
        echo "Error: Cannot find ssh.sh at ${SCRIPT_DIR}/scripts/security/ssh.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/ssh.sh"

    # 加载 firewall.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/firewall.sh" ]]; then
        echo "Error: Cannot find firewall.sh at ${SCRIPT_DIR}/scripts/security/firewall.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/firewall.sh"

    # 加载 fail2ban.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/fail2ban.sh" ]]; then
        echo "Error: Cannot find fail2ban.sh at ${SCRIPT_DIR}/scripts/security/fail2ban.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/fail2ban.sh"

    # 加载 audit.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/audit.sh" ]]; then
        echo "Error: Cannot find audit.sh at ${SCRIPT_DIR}/scripts/security/audit.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/audit.sh"

    # 加载 users.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/users.sh" ]]; then
        echo "Error: Cannot find users.sh at ${SCRIPT_DIR}/scripts/security/users.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/users.sh"

    # 加载 kernel.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/kernel.sh" ]]; then
        echo "Error: Cannot find kernel.sh at ${SCRIPT_DIR}/scripts/security/kernel.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/kernel.sh"

    # 加载 filesystem.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/filesystem.sh" ]]; then
        echo "Error: Cannot find filesystem.sh at ${SCRIPT_DIR}/scripts/security/filesystem.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/filesystem.sh"

    # 加载 services.sh
    if [[ ! -f "${SCRIPT_DIR}/scripts/security/services.sh" ]]; then
        echo "Error: Cannot find services.sh at ${SCRIPT_DIR}/scripts/security/services.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/security/services.sh"

    # 加载 autoupdate.sh (仅 Full 模式)
    if is_mode_full; then
        if [[ ! -f "${SCRIPT_DIR}/scripts/security/autoupdate.sh" ]]; then
            echo "Error: Cannot find autoupdate.sh at ${SCRIPT_DIR}/scripts/security/autoupdate.sh"
            exit 1
        fi
        # shellcheck source=/dev/null
        source "${SCRIPT_DIR}/scripts/security/autoupdate.sh"
    fi

    # 加载 aide.sh / clamav.sh / rootkit.sh (仅 Full 模式)
    if is_mode_full; then
        for _mod in aide clamav rootkit; do
            _f="${SCRIPT_DIR}/scripts/security/${_mod}.sh"
            if [[ ! -f "${_f}" ]]; then
                echo "Error: Cannot find ${_mod}.sh at ${_f}"
                exit 1
            fi
            # shellcheck source=/dev/null
            source "${_f}"
        done
        unset _mod _f
    fi

    # 加载 report.sh (generate_report 函数)
    if [[ ! -f "${SCRIPT_DIR}/scripts/base/report.sh" ]]; then
        echo "Error: Cannot find report.sh at ${SCRIPT_DIR}/scripts/base/report.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/base/report.sh"

    # 加载 k3s.sh (服务器软件模块)
    if [[ ! -f "${SCRIPT_DIR}/scripts/server/k3s.sh" ]]; then
        echo "Error: Cannot find k3s.sh at ${SCRIPT_DIR}/scripts/server/k3s.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/server/k3s.sh"

    # 加载 docker.sh (Docker 容器引擎模块)
    if [[ ! -f "${SCRIPT_DIR}/scripts/server/docker.sh" ]]; then
        echo "Error: Cannot find docker.sh at ${SCRIPT_DIR}/scripts/server/docker.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/server/docker.sh"

    # 加载 nginx.sh (Nginx Web 服务器模块)
    if [[ ! -f "${SCRIPT_DIR}/scripts/server/nginx.sh" ]]; then
        echo "Error: Cannot find nginx.sh at ${SCRIPT_DIR}/scripts/server/nginx.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/server/nginx.sh"

    # 加载数据库/缓存/监控模块
    for _mod in redis postgresql mysql memcached node_exporter prometheus grafana; do
        _f="${SCRIPT_DIR}/scripts/server/${_mod}.sh"
        if [[ ! -f "${_f}" ]]; then
            echo "Error: Cannot find ${_mod}.sh at ${_f}"
            exit 1
        fi
        # shellcheck source=/dev/null
        source "${_f}"
    done
    unset _mod _f

    # 加载开发工具模块 (git / editor / runtimes / build_toolchain)
    for _mod in git editor runtimes build_toolchain; do
        _f="${SCRIPT_DIR}/scripts/dev/${_mod}.sh"
        if [[ ! -f "${_f}" ]]; then
            echo "Error: Cannot find ${_mod}.sh at ${_f}"
            exit 1
        fi
        # shellcheck source=/dev/null
        source "${_f}"
    done
    unset _mod _f

    # 加载 mirror.sh (更换软件源模块)
    if [[ ! -f "${SCRIPT_DIR}/scripts/server/mirror.sh" ]]; then
        echo "Error: Cannot find mirror.sh at ${SCRIPT_DIR}/scripts/server/mirror.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/server/mirror.sh"

    # 加载 backup_center.sh / dashboard.sh（Batch 5a 编排与呈现层）
    if [[ ! -f "${SCRIPT_DIR}/scripts/base/backup_center.sh" ]]; then
        echo "Error: Cannot find backup_center.sh at ${SCRIPT_DIR}/scripts/base/backup_center.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/base/backup_center.sh"

    if [[ ! -f "${SCRIPT_DIR}/scripts/base/dashboard.sh" ]]; then
        echo "Error: Cannot find dashboard.sh at ${SCRIPT_DIR}/scripts/base/dashboard.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/base/dashboard.sh"
}

# ═══════════════════════════════════════════
# 欢迎信息
# ═══════════════════════════════════════════

# show_welcome 已合并到 show_main_menu

# ═══════════════════════════════════════════
# 系统状态检测（只读，不修改系统）
# ═══════════════════════════════════════════

# 显示系统安全状态
# 打印一行加固状态：图标 + 颜色 + 标签 + 详情（对齐布局）
# 参数: $1=label $2=status(已加固/部分/未加固) $3=color $4=detail $5=icon
_print_status_row() {
    local label="$1"
    local status="$2"
    local color="$3"
    local detail="$4"
    local icon="$5"
    printf "  %-16s ${color}${icon} %s${NC}  %s\n" "${label}" "${status}" "${detail}"
}

# 显示系统安全状态：评分 + 颜色 + 表格 + 建议下一步（spec §3.3 GAP-4/5/6）
show_system_status() {
    log_title "${MSG_STATUS_TITLE}"

    local passed=0 partial=0 failed=0
    local -a recommend_items=()  # "menu_num|label"

    # ─── SSH ────────────────────────────────────────────────────────────
    local ssh_port ssh_root ssh_passwd ssh_pubkey ssh_ok=0 ssh_total=4
    ssh_port=$(get_ssh_port 2>/dev/null || echo "22")
    ssh_root=$(get_ssh_config "PermitRootLogin" 2>/dev/null || echo "unknown")
    ssh_passwd=$(get_ssh_config "PasswordAuthentication" 2>/dev/null || echo "unknown")
    ssh_pubkey=$(get_ssh_config "PubkeyAuthentication" 2>/dev/null || echo "unknown")
    [[ "${ssh_port}" != "22" ]] && ssh_ok=$((ssh_ok + 1))
    [[ "${ssh_root}" == "no" ]] && ssh_ok=$((ssh_ok + 1))
    [[ "${ssh_passwd}" == "no" ]] && ssh_ok=$((ssh_ok + 1))
    if [[ "${ssh_pubkey}" == "yes" ]] || [[ "${ssh_pubkey}" == "unknown" ]]; then
        ssh_ok=$((ssh_ok + 1))
    fi
    if [[ "${ssh_ok}" -eq "${ssh_total}" ]]; then
        _print_status_row "${MSG_MAIN_MENU_SSH}" "${MSG_STATUS_HARDENED}" "${GREEN}" "端口 ${ssh_port}" "✅"
        passed=$((passed + 1))
    elif [[ "${ssh_ok}" -eq 0 ]]; then
        _print_status_row "${MSG_MAIN_MENU_SSH}" "${MSG_STATUS_NOT_HARDENED}" "${RED}" "端口 ${ssh_port}, 0/${ssh_total}" "❌"
        failed=$((failed + 1))
        recommend_items+=("2|${MSG_MAIN_MENU_SSH}")
    else
        _print_status_row "${MSG_MAIN_MENU_SSH}" "${MSG_STATUS_PARTIAL}" "${YELLOW}" "端口 ${ssh_port}, ${ssh_ok}/${ssh_total}" "⚠️"
        partial=$((partial + 1))
        recommend_items+=("2|${MSG_MAIN_MENU_SSH}")
    fi

    # ─── 防火墙 ─────────────────────────────────────────────────────────
    local fw_status="${MSG_STATUS_DISABLED}" fw_color="${RED}" fw_icon="❌" fw_detail
    if command -v ufw &>/dev/null; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            fw_status="${MSG_STATUS_ENABLED}"; fw_color="${GREEN}"; fw_icon="✅"
        fi
    elif command -v firewall-cmd &>/dev/null; then
        if firewall-cmd --state &>/dev/null; then
            fw_status="${MSG_STATUS_ENABLED}"; fw_color="${GREEN}"; fw_icon="✅"
        fi
    fi
    fw_detail="${fw_status}"
    if [[ "${fw_color}" == "${GREEN}" ]]; then
        _print_status_row "${MSG_STATUS_FIREWALL}" "${MSG_STATUS_HARDENED}" "${fw_color}" "${fw_detail}" "${fw_icon}"
        passed=$((passed + 1))
    else
        _print_status_row "${MSG_STATUS_FIREWALL}" "${MSG_STATUS_NOT_HARDENED}" "${fw_color}" "${fw_detail}" "${fw_icon}"
        failed=$((failed + 1))
        recommend_items+=("3|${MSG_STATUS_FIREWALL}")
    fi

    # ─── Fail2Ban ───────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_FAIL2BAN}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local f2b_status="${MSG_STATUS_NOT_INSTALLED}" f2b_color="${RED}" f2b_icon="❌"
        if command -v fail2ban-client &>/dev/null; then
            f2b_status="${MSG_STATUS_INSTALLED}"
            if systemctl is-active fail2ban &>/dev/null; then
                f2b_color="${GREEN}"; f2b_icon="✅"
            else
                f2b_color="${YELLOW}"; f2b_icon="⚠️"
            fi
        fi
        if [[ "${f2b_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_FAIL2BAN}" "${MSG_STATUS_HARDENED}" "${f2b_color}" "${f2b_status}" "${f2b_icon}"
            passed=$((passed + 1))
        elif [[ "${f2b_color}" == "${YELLOW}" ]]; then
            _print_status_row "${MSG_STATUS_FAIL2BAN}" "${MSG_STATUS_PARTIAL}" "${f2b_color}" "${f2b_status}" "${f2b_icon}"
            partial=$((partial + 1))
            recommend_items+=("4|${MSG_STATUS_FAIL2BAN}")
        else
            _print_status_row "${MSG_STATUS_FAIL2BAN}" "${MSG_STATUS_NOT_HARDENED}" "${f2b_color}" "${f2b_status}" "${f2b_icon}"
            failed=$((failed + 1))
            recommend_items+=("4|${MSG_STATUS_FAIL2BAN}")
        fi
    fi

    # ─── 审计日志 ───────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_AUDIT}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local audit_status="${MSG_STATUS_NOT_INSTALLED}" audit_color="${RED}" audit_icon="❌"
        if command -v auditctl &>/dev/null; then
            audit_status="${MSG_STATUS_INSTALLED}"
            if systemctl is-active auditd &>/dev/null; then
                audit_color="${GREEN}"; audit_icon="✅"
            else
                audit_color="${YELLOW}"; audit_icon="⚠️"
            fi
        fi
        if [[ "${audit_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_AUDIT}" "${MSG_STATUS_HARDENED}" "${audit_color}" "${audit_status}" "${audit_icon}"
            passed=$((passed + 1))
        elif [[ "${audit_color}" == "${YELLOW}" ]]; then
            _print_status_row "${MSG_STATUS_AUDIT}" "${MSG_STATUS_PARTIAL}" "${audit_color}" "${audit_status}" "${audit_icon}"
            partial=$((partial + 1))
            recommend_items+=("5|${MSG_STATUS_AUDIT}")
        else
            _print_status_row "${MSG_STATUS_AUDIT}" "${MSG_STATUS_NOT_HARDENED}" "${audit_color}" "${audit_status}" "${audit_icon}"
            failed=$((failed + 1))
            recommend_items+=("5|${MSG_STATUS_AUDIT}")
        fi
    fi

    # ─── 用户管理 ───────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_USERS}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local users_color="${RED}" users_icon="❌" users_detail="${MSG_STATUS_NOT_CONFIGURED}"
        if type check_users_status &>/dev/null; then
            local users_status custom_users
            users_status=$(check_users_status 2>/dev/null)
            custom_users=$(echo "${users_status}" | grep '^users_custom=' | cut -d= -f2)
            if [[ "${custom_users}" =~ ^[1-9][0-9]*$ ]]; then
                users_color="${GREEN}"; users_icon="✅"
                users_detail="${MSG_STATUS_USERS_COUNT}: ${custom_users}"
            fi
        fi
        if [[ "${users_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_USERS}" "${MSG_STATUS_HARDENED}" "${users_color}" "${users_detail}" "${users_icon}"
            passed=$((passed + 1))
        else
            _print_status_row "${MSG_STATUS_USERS}" "${MSG_STATUS_NOT_HARDENED}" "${users_color}" "${users_detail}" "${users_icon}"
            failed=$((failed + 1))
            recommend_items+=("6|${MSG_STATUS_USERS}")
        fi
    fi

    # ─── 内核加固 ───────────────────────────────────────────────────────
    local kernel_color="${RED}" kernel_icon="❌" kernel_detail="${MSG_STATUS_NOT_HARDENED}"
    if type check_kernel_status &>/dev/null; then
        local kernel_status kernel_conf
        kernel_status=$(check_kernel_status 2>/dev/null)
        kernel_conf=$(echo "${kernel_status}" | grep '^kernel_conf=' | cut -d= -f2)
        if [[ "${kernel_conf}" == "yes" ]]; then
            kernel_color="${GREEN}"; kernel_icon="✅"
            kernel_detail="${MSG_STATUS_KERNEL_CONF}: ${MSG_STATUS_INSTALLED}"
        fi
    fi
    if [[ "${kernel_color}" == "${GREEN}" ]]; then
        _print_status_row "${MSG_STATUS_KERNEL}" "${MSG_STATUS_HARDENED}" "${kernel_color}" "${kernel_detail}" "${kernel_icon}"
        passed=$((passed + 1))
    else
        _print_status_row "${MSG_STATUS_KERNEL}" "${MSG_STATUS_NOT_HARDENED}" "${kernel_color}" "${kernel_detail}" "${kernel_icon}"
        failed=$((failed + 1))
        recommend_items+=("7|${MSG_STATUS_KERNEL}")
    fi

    # ─── 文件系统 ───────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_FILESYSTEM}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local fs_color="${RED}" fs_icon="❌" fs_detail="${MSG_STATUS_NOT_HARDENED}"
        if type check_filesystem_status &>/dev/null; then
            local fs_status suid_count
            fs_status=$(check_filesystem_status 2>/dev/null)
            suid_count=$(echo "${fs_status}" | grep '^fs_suid_count=' | cut -d= -f2)
            if [[ "${suid_count}" =~ ^[0-9]+$ ]] && [[ "${suid_count}" -gt 0 ]]; then
                # 已扫描，发现 SUID 问题
                fs_color="${YELLOW}"; fs_icon="⚠️"
                fs_detail="${MSG_STATUS_FS_SUID}: ${suid_count}"
            elif [[ "${suid_count}" =~ ^[0-9]+$ ]] && [[ "${suid_count}" -eq 0 ]]; then
                # 已扫描，无 SUID 问题
                fs_color="${GREEN}"; fs_icon="✅"
                fs_detail="${MSG_STATUS_FS_SUID}: 0"
            fi
        fi
        if [[ "${fs_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_FILESYSTEM}" "${MSG_STATUS_HARDENED}" "${fs_color}" "${fs_detail}" "${fs_icon}"
            passed=$((passed + 1))
        elif [[ "${fs_color}" == "${YELLOW}" ]]; then
            _print_status_row "${MSG_STATUS_FILESYSTEM}" "${MSG_STATUS_PARTIAL}" "${fs_color}" "${fs_detail}" "${fs_icon}"
            partial=$((partial + 1))
        else
            _print_status_row "${MSG_STATUS_FILESYSTEM}" "${MSG_STATUS_NOT_HARDENED}" "${fs_color}" "${fs_detail}" "${fs_icon}"
            failed=$((failed + 1))
            recommend_items+=("8|${MSG_STATUS_FILESYSTEM}")
        fi
    fi

    # ─── 服务管理 ───────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_SERVICES}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local svc_color="${RED}" svc_icon="❌" svc_detail="${MSG_STATUS_NOT_HARDENED}"
        if type check_services_status &>/dev/null; then
            local svc_status svc_running svc_unnecessary
            svc_status=$(check_services_status 2>/dev/null)
            svc_running=$(echo "${svc_status}" | grep '^services_running=' | cut -d= -f2)
            svc_unnecessary=$(echo "${svc_status}" | grep '^services_unnecessary=' | cut -d= -f2)
            if [[ "${svc_running}" =~ ^[0-9]+$ ]] && [[ "${svc_unnecessary}" =~ ^[0-9]+$ ]]; then
                if [[ "${svc_unnecessary}" -eq 0 ]]; then
                    svc_color="${GREEN}"; svc_icon="✅"
                else
                    svc_color="${YELLOW}"; svc_icon="⚠️"
                fi
                svc_detail="${MSG_STATUS_SERVICES_RUNNING}: ${svc_running}, ${MSG_STATUS_SERVICES_UNNECESSARY}: ${svc_unnecessary}"
            fi
        fi
        if [[ "${svc_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_SERVICES}" "${MSG_STATUS_HARDENED}" "${svc_color}" "${svc_detail}" "${svc_icon}"
            passed=$((passed + 1))
        elif [[ "${svc_color}" == "${YELLOW}" ]]; then
            _print_status_row "${MSG_STATUS_SERVICES}" "${MSG_STATUS_PARTIAL}" "${svc_color}" "${svc_detail}" "${svc_icon}"
            partial=$((partial + 1))
            recommend_items+=("9|${MSG_STATUS_SERVICES}")
        else
            _print_status_row "${MSG_STATUS_SERVICES}" "${MSG_STATUS_NOT_HARDENED}" "${svc_color}" "${svc_detail}" "${svc_icon}"
            failed=$((failed + 1))
            recommend_items+=("9|${MSG_STATUS_SERVICES}")
        fi
    fi

    # ─── 自动安全更新 ────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_AUTOUPDATE_TITLE}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local au_color="${YELLOW}" au_icon="⚠️" au_detail="${MSG_STATUS_NOT_HARDENED}"
        if type check_autoupdate_status &>/dev/null; then
            local au_status
            au_status=$(check_autoupdate_status 2>/dev/null)
            local au_installed au_enabled
            au_installed=$(echo "${au_status}" | grep '^autoupdate_installed=' | cut -d= -f2)
            au_enabled=$(echo "${au_status}" | grep '^autoupdate_enabled=' | cut -d= -f2)
            if [[ "${au_enabled}" == "yes" ]]; then
                au_color="${GREEN}"; au_icon="✅"
                au_detail="${MSG_STATUS_HARDENED}"
            elif [[ "${au_installed}" == "yes" ]]; then
                au_color="${YELLOW}"; au_icon="⚠️"
                au_detail="${MSG_STATUS_PARTIAL}"
            fi
        fi
        _print_status_row "${MSG_AUTOUPDATE_TITLE}" "${au_detail}" "${au_color}" "" "${au_icon}"
        if [[ "${au_color}" == "${GREEN}" ]]; then
            passed=$((passed + 1))
        elif [[ "${au_color}" == "${YELLOW}" ]]; then
            partial=$((partial + 1))
        fi
    fi

    # ─── AIDE ───────────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_AIDE}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local aide_color="${RED}" aide_icon="❌" aide_detail="${MSG_STATUS_NOT_CONFIGURED}"
        if type check_aide_status &>/dev/null; then
            local aide_status aide_db_exists aide_cron
            aide_status=$(check_aide_status 2>/dev/null)
            aide_db_exists=$(echo "${aide_status}" | grep '^aide_db_exists=' | cut -d= -f2)
            aide_cron=$(echo "${aide_status}" | grep '^aide_cron=' | cut -d= -f2)
            if [[ "${aide_db_exists}" == "yes" ]]; then
                aide_color="${GREEN}"; aide_icon="✅"
                aide_detail="DB: OK, Cron: ${aide_cron}"
            fi
        fi
        if [[ "${aide_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_AIDE}" "${MSG_STATUS_HARDENED}" "${aide_color}" "${aide_detail}" "${aide_icon}"
            passed=$((passed + 1))
        else
            _print_status_row "${MSG_STATUS_AIDE}" "${MSG_STATUS_NOT_HARDENED}" "${aide_color}" "${aide_detail}" "${aide_icon}"
            failed=$((failed + 1))
            recommend_items+=("14|${MSG_STATUS_AIDE}")
        fi
    fi

    # ─── ClamAV ─────────────────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_CLAMAV}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local clamav_color="${RED}" clamav_icon="❌" clamav_detail="${MSG_STATUS_NOT_CONFIGURED}"
        if type check_clamav_status &>/dev/null; then
            local clamav_status clamav_db_uptodate clamav_cron
            clamav_status=$(check_clamav_status 2>/dev/null)
            clamav_db_uptodate=$(echo "${clamav_status}" | grep '^clamav_db_uptodate=' | cut -d= -f2)
            clamav_cron=$(echo "${clamav_status}" | grep '^clamav_cron_enabled=' | cut -d= -f2)
            if [[ "${clamav_db_uptodate}" == "yes" ]]; then
                clamav_color="${GREEN}"; clamav_icon="✅"
                clamav_detail="DB: OK, Cron: ${clamav_cron}"
            fi
        fi
        if [[ "${clamav_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_CLAMAV}" "${MSG_STATUS_HARDENED}" "${clamav_color}" "${clamav_detail}" "${clamav_icon}"
            passed=$((passed + 1))
        else
            _print_status_row "${MSG_STATUS_CLAMAV}" "${MSG_STATUS_NOT_HARDENED}" "${clamav_color}" "${clamav_detail}" "${clamav_icon}"
            failed=$((failed + 1))
            recommend_items+=("15|${MSG_STATUS_CLAMAV}")
        fi
    fi

    # ─── Rootkit Detection ─────────────────────────────────────────────
    if is_mode_lite; then
        _print_status_row "${MSG_STATUS_ROOTKIT}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
    else
        local rootkit_color="${RED}" rootkit_icon="❌" rootkit_detail="${MSG_STATUS_NOT_CONFIGURED}"
        if type check_rootkit_status &>/dev/null; then
            local rootkit_status rkhunter_installed chkrootkit_installed rootkit_cron
            rootkit_status=$(check_rootkit_status 2>/dev/null)
            rkhunter_installed=$(echo "${rootkit_status}" | grep '^rkhunter_installed=' | cut -d= -f2)
            chkrootkit_installed=$(echo "${rootkit_status}" | grep '^chkrootkit_installed=' | cut -d= -f2)
            rootkit_cron=$(echo "${rootkit_status}" | grep '^cron_enabled=' | cut -d= -f2)
            if [[ "${rkhunter_installed}" == "yes" ]]; then
                rootkit_color="${GREEN}"; rootkit_icon="✅"
                rootkit_detail="rkhunter: OK, chkrootkit: ${chkrootkit_installed}, Cron: ${rootkit_cron}"
            fi
        fi
        if [[ "${rootkit_color}" == "${GREEN}" ]]; then
            _print_status_row "${MSG_STATUS_ROOTKIT}" "${MSG_STATUS_HARDENED}" "${rootkit_color}" "${rootkit_detail}" "${rootkit_icon}"
            passed=$((passed + 1))
        else
            _print_status_row "${MSG_STATUS_ROOTKIT}" "${MSG_STATUS_NOT_HARDENED}" "${rootkit_color}" "${rootkit_detail}" "${rootkit_icon}"
            failed=$((failed + 1))
            recommend_items+=("16|${MSG_STATUS_ROOTKIT}")
        fi
    fi

    # ─── 顶部评分 + 建议下一步 ──────────────────────────────────────────
    echo ""
    local total=$((passed + partial + failed))
    log_info "${MSG_DETECTION_SUMMARY}: ${passed}/${total} ${MSG_STATUS_HARDENED} (${partial} ${MSG_STATUS_PARTIAL}, ${failed} ${MSG_STATUS_NOT_HARDENED})"

    if [[ "${#recommend_items[@]}" -gt 0 ]]; then
        echo ""
        echo -e "  ${BOLD}${MSG_STATUS_RECOMMENDATION}:${NC}"
        local item num name
        for item in "${recommend_items[@]}"; do
            num="${item%%|*}"
            name="${item#*|}"
            echo -e "    ${YELLOW}[${num}]${NC} ${name}"
        done
    fi

    echo ""
    press_enter
}

# ═══════════════════════════════════════════
# 主菜单
# ═══════════════════════════════════════════

# 显示主菜单
show_main_menu() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${BOLD}  _____ _     _       _     ${NC}"
    echo -e "${BOLD} / ____| |   (_)     | |    ${NC}"
    echo -e "${BOLD}| |    | |__  _ _ __ | |__  ${NC}"
    echo -e "${BOLD}| |    | '_ \| | '_ \| '_ \ ${NC}"
    echo -e "${BOLD}| |____| | | | | | | | | | |${NC}"
    echo -e "${BOLD} \_____|_| |_|_|_| |_|_| |_|${NC}"
    echo ""
    echo -e "  ${BOLD}Linux Server Security Hardening ${SCRIPT_VERSION}${NC}"
    echo -e "  ${BLUE}${MSG_WELCOME}${NC}"

    # 显示当前模式（Lite/Full）
    if is_mode_lite; then
        echo -e "  ${YELLOW}${MSG_MODE_LITE_TAG} ${MSG_MODE_LITE_DESC}${NC}"
    else
        echo -e "  ${GREEN}${MSG_MODE_FULL_TAG} ${MSG_MODE_FULL_DESC}${NC}"
    fi
    echo ""

    # 顶部状态摘要行（spec §3.1 GAP-2）
    local ssh_port ssh_status_label
    ssh_port=$(get_ssh_port 2>/dev/null || echo "22")
    if [[ "${ssh_port}" == "22" ]]; then
        ssh_status_label="${MSG_STATUS_SSH_PORT_DEFAULT}"
    else
        ssh_status_label="${MSG_STATUS_SSH_PORT_HARDENED}"
    fi
    echo -e "  ${MSG_MAIN_MENU_SYSTEM_INFO}: $(get_detected_os) $(get_detected_os_version) | $(get_detected_arch) | $(whoami) | SSH ${ssh_port} (${ssh_status_label})"
    echo ""

    # 分组 1：状态（spec §3.1 GAP-1）
    echo -e "${BOLD}${MSG_SECTION_STATUS}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_STATUS}${NC}"
    echo -e "      ${MSG_MAIN_MENU_STATUS_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_REPORT}${NC}"
    echo -e "      ${MSG_MAIN_MENU_REPORT_DESC}"
    echo ""

    # 分组 2：加固
    echo -e "${BOLD}${MSG_SECTION_HARDENING}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_SSH}${NC}"
    echo -e "      ${MSG_MAIN_MENU_SSH_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FIREWALL}${NC}"
    echo -e "      ${MSG_MAIN_MENU_FIREWALL_DESC}"
    echo ""
    # Fail2Ban（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FAIL2BAN}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_FAIL2BAN_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_FAIL2BAN_DESC}"
    fi
    echo ""
    # Audit（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_AUDIT}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_AUDIT_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_AUDIT_DESC}"
    fi
    echo ""
    # Users（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_USERS}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_USERS_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_USERS_DESC}"
    fi
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_KERNEL}${NC}"
    echo -e "      ${MSG_MAIN_MENU_KERNEL_DESC}"
    echo ""
    # Filesystem（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FILESYSTEM}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_FILESYSTEM_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_FILESYSTEM_DESC}"
    fi
    echo ""
    # Services（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_SERVICES}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_SERVICES_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_SERVICES_DESC}"
    fi
    echo ""
    # 自动安全更新（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_AUTOUPDATE}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_AUTOUPDATE_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_AUTOUPDATE_DESC}"
    fi
    echo ""

    # 分组 3：一键
    echo -e "${BOLD}${MSG_SECTION_QUICK}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_QUICK}${NC}"
    echo -e "      ${MSG_MAIN_MENU_QUICK_DESC}"
    echo ""

    # 分组 4：服务器软件
    echo -e "${BOLD}${MSG_SECTION_SERVER}${NC}"
    echo ""
    # K3s（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_K3S}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_K3S_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_K3S_DESC}"
    fi
    echo ""
    # 服务器软件（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_SERVER}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_SERVER_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_SERVER_DESC}"
    fi
    echo ""
    # 开发工具（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_DEV}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_DEV_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_DEV_DESC}"
    fi
    echo ""

    # 分组 5：增强安全工具
    echo -e "${BOLD}────── Security Plus ──────${NC}"
    echo ""
    # AIDE（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_AIDE}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_AIDE_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_AIDE_DESC}"
    fi
    echo ""
    # ClamAV（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_CLAMAV}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_CLAMAV_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_CLAMAV_DESC}"
    fi
    echo ""
    # Rootkit（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_ROOTKIT}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_ROOTKIT_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_ROOTKIT_DESC}"
    fi
    echo ""

    # 分组 6：运维工具（完整版专用）
    echo -e "${BOLD}${MSG_SECTION_OPS}${NC}"
    echo ""
    # 备份/回滚中心（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_BACKUP_CENTER}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_BACKUP_CENTER_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_BACKUP_CENTER_DESC}"
    fi
    echo ""
    # 安全仪表盘（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_DASHBOARD}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_DASHBOARD_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_DASHBOARD_DESC}"
    fi
    echo ""
    # 更换软件源（Lite/Full 全模式可用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_MIRROR}${NC}"
    echo -e "      ${MSG_MAIN_MENU_MIRROR_DESC}"
    echo ""

    echo -e "  ${RED}${MSG_MAIN_MENU_EXIT}${NC}"
    echo ""
}

# 获取主菜单选择
get_main_menu_choice() {
    local choice
    while true; do
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-21]" "")
        # EOF / non-interactive stdin: exit gracefully
        if [[ -z "${choice}" ]]; then
            echo ""
            log_error "${MSG_ERROR_NO_INPUT}"
            exit 1
        fi
        case "${choice}" in
            [0-9]|1[0-9]|2[0-1])
                echo "${choice}"
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# SSH 子菜单
# ═══════════════════════════════════════════

show_ssh_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_SSH_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_SSH_MENU_PORT}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_MENU_KEY}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_MENU_ROOT}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_MENU_PASSWD}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_MENU_PARAMS}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_MENU_ALL}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_SSH_MENU_BACK}${NC}"
    echo ""
}

run_ssh_submenu_loop() {
    while true; do
        show_ssh_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-6]" "")

        case "${choice}" in
            1)
                change_ssh_port || log_error "SSH port change failed"
                press_enter
                ;;
            2)
                generate_ssh_key || log_error "SSH key generation failed"
                press_enter
                ;;
            3)
                disable_root_login || log_error "Disable root login failed"
                press_enter
                ;;
            4)
                disable_password_auth || log_error "Disable password login failed"
                press_enter
                ;;
            5)
                configure_ssh_params || log_error "SSH params config failed"
                press_enter
                ;;
            6)
                run_ssh_wizard || log_error "SSH wizard failed"
                press_enter
                ;;
            0)
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 防火墙子菜单
# ═══════════════════════════════════════════

show_firewall_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_FIREWALL_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_FIREWALL_MENU_ENABLE}${NC}"
    echo -e "  ${GREEN}${MSG_FIREWALL_MENU_HTTP}${NC}"
    echo -e "  ${GREEN}${MSG_FIREWALL_MENU_ICMP}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_FIREWALL_MENU_BACK}${NC}"
    echo ""
}

run_firewall_submenu_loop() {
    while true; do
        show_firewall_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")

        case "${choice}" in
            1)
                run_firewall_wizard || log_error "Firewall config failed"
                press_enter
                ;;
            2)
                if confirm "${MSG_CONFIRM_FIREWALL_HTTP}" "y"; then
                    _install_firewall
                    setup_firewall_defaults
                    open_port "80" "tcp" "HTTP"
                    open_port "443" "tcp" "HTTPS"
                    enable_firewall
                    log_success "HTTP/HTTPS ports opened"
                fi
                press_enter
                ;;
            3)
                allow_icmp
                press_enter
                ;;
            0)
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 模块 4-9 子菜单壳（spec §3.2 / GAP-3）
# ═══════════════════════════════════════════

# Fail2Ban 子菜单
show_fail2ban_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_FAIL2BAN_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_FAIL2BAN_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_FAIL2BAN_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_FAIL2BAN_MENU_BACK}${NC}"
    echo ""
}

run_fail2ban_submenu_loop() {
    while true; do
        show_fail2ban_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_fail2ban_wizard || log_error "Fail2Ban config failed"
                press_enter
                ;;
            2)
                if type check_fail2ban_status &>/dev/null; then
                    check_fail2ban_status
                else
                    log_info "${MSG_HINT_STATUS_FAIL2BAN}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Audit 子菜单
show_audit_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_AUDIT_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_AUDIT_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_AUDIT_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_AUDIT_MENU_BACK}${NC}"
    echo ""
}

run_audit_submenu_loop() {
    while true; do
        show_audit_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_audit_wizard || log_error "Audit config failed"
                press_enter
                ;;
            2)
                if type check_audit_status &>/dev/null; then
                    check_audit_status
                else
                    log_info "${MSG_HINT_STATUS_AUDIT}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Users 子菜单
show_users_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_USERS_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_USERS_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_USERS_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_USERS_MENU_BACK}${NC}"
    echo ""
}

run_users_submenu_loop() {
    while true; do
        show_users_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_users_wizard || log_error "User management failed"
                press_enter
                ;;
            2)
                if type check_users_status &>/dev/null; then
                    check_users_status
                else
                    log_info "${MSG_HINT_STATUS_USERS}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Kernel 子菜单
show_kernel_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_KERNEL_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_KERNEL_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_KERNEL_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_KERNEL_MENU_BACK}${NC}"
    echo ""
}

run_kernel_submenu_loop() {
    while true; do
        show_kernel_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_kernel_wizard || log_error "Kernel hardening failed"
                press_enter
                ;;
            2)
                if type check_kernel_status &>/dev/null; then
                    check_kernel_status
                else
                    log_info "${MSG_HINT_STATUS_KERNEL}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Filesystem 子菜单
show_filesystem_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_FILESYSTEM_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_FILESYSTEM_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_FILESYSTEM_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_FILESYSTEM_MENU_BACK}${NC}"
    echo ""
}

run_filesystem_submenu_loop() {
    while true; do
        show_filesystem_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_filesystem_wizard || log_error "Filesystem check failed"
                press_enter
                ;;
            2)
                if type check_filesystem_status &>/dev/null; then
                    check_filesystem_status
                else
                    log_info "${MSG_HINT_STATUS_FILESYSTEM}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Services 子菜单
show_services_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_SERVICES_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_SERVICES_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_SERVICES_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_SERVICES_MENU_BACK}${NC}"
    echo ""
}

run_services_submenu_loop() {
    while true; do
        show_services_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_services_wizard || log_error "Service management failed"
                press_enter
                ;;
            2)
                if type check_services_status &>/dev/null; then
                    check_services_status
                else
                    log_info "${MSG_HINT_STATUS_SERVICES}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Autoupdate 子菜单
show_autoupdate_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_AUTOUPDATE_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_AUTOUPDATE_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_AUTOUPDATE_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_AUTOUPDATE_MENU_BACK}${NC}"
    echo ""
}

run_autoupdate_submenu_loop() {
    while true; do
        show_autoupdate_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_autoupdate_wizard || log_error "Auto update configuration failed"
                press_enter
                ;;
            2)
                if type show_autoupdate_info &>/dev/null; then
                    show_autoupdate_info
                else
                    log_info "${MSG_HINT_STATUS_AUTOUPDATE}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# AIDE 子菜单
show_aide_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_AIDE_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_AIDE_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_AIDE_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_AIDE_MENU_BACK}${NC}"
    echo ""
}

run_aide_submenu_loop() {
    while true; do
        show_aide_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_aide_wizard || log_error "AIDE configuration failed"
                press_enter
                ;;
            2)
                if type check_aide_status &>/dev/null; then
                    check_aide_status
                else
                    log_info "${MSG_HINT_STATUS_AIDE}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# ClamAV 子菜单
show_clamav_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_CLAMAV_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_CLAMAV_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_CLAMAV_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_CLAMAV_MENU_BACK}${NC}"
    echo ""
}

run_clamav_submenu_loop() {
    while true; do
        show_clamav_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_clamav_wizard || log_error "ClamAV configuration failed"
                press_enter
                ;;
            2)
                if type check_clamav_status &>/dev/null; then
                    check_clamav_status
                else
                    log_info "${MSG_HINT_STATUS_CLAMAV}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Rootkit 子菜单
show_rootkit_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_ROOTKIT_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_ROOTKIT_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_ROOTKIT_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_ROOTKIT_MENU_BACK}${NC}"
    echo ""
}

run_rootkit_submenu_loop() {
    while true; do
        show_rootkit_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_rootkit_wizard || log_error "Rootkit detection failed"
                press_enter
                ;;
            2)
                if type check_rootkit_status &>/dev/null; then
                    check_rootkit_status
                else
                    log_info "${MSG_HINT_STATUS_ROOTKIT}"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 查看报告（spec §3.4 GAP-7：历史报告列表）
# ═══════════════════════════════════════════

# 把秒数格式化为相对时间字符串（i18n）
_format_relative_time() {
    local secs=$1
    if [[ "${secs}" -lt 60 ]]; then
        printf "%s" "${MSG_TIME_JUST_NOW}"
    elif [[ "${secs}" -lt 3600 ]]; then
        # shellcheck disable=SC2059  # i18n format string intentionally contains %d
        printf "${MSG_TIME_MINUTES_AGO}" "$((secs / 60))"
    elif [[ "${secs}" -lt 86400 ]]; then
        # shellcheck disable=SC2059  # i18n format string intentionally contains %d
        printf "${MSG_TIME_HOURS_AGO}" "$((secs / 3600))"
    else
        # shellcheck disable=SC2059  # i18n format string intentionally contains %d
        printf "${MSG_TIME_DAYS_AGO}" "$((secs / 86400))"
    fi
}

view_report() {
    local report_dir="${REPORT_DIR:-/var/log/linux-one-key}"
    local max_reports="${REPORT_HISTORY_LIMIT:-5}"

    while true; do
        log_title "${MSG_REPORT_HISTORY_TITLE}"

        # 收集最近 N 份报告（按 mtime 倒序）
        local -a reports=()
        if [[ -d "${report_dir}" ]]; then
            while IFS= read -r f; do
                [[ -n "${f}" ]] && reports+=("${f}")
            done < <(find "${report_dir}" -maxdepth 1 -name 'report_*.txt' -printf '%T@\t%p\n' 2>/dev/null | sort -rn | head -n "${max_reports}" | cut -f2-)
        fi

        if [[ "${#reports[@]}" -eq 0 ]]; then
            log_warn "${MSG_REPORT_NO_FILES}"
            press_enter
            return 0
        fi

        # 列表展示（带相对时间）
        local now
        now=$(date +%s)
        local i=1 f mtime rel
        for f in "${reports[@]}"; do
            mtime=$(date -r "${f}" +%s 2>/dev/null || echo "${now}")
            rel=$(_format_relative_time $((now - mtime)))
            printf "  ${CYAN}[%d]${NC} %s ${GRAY}(%s)${NC}\n" "${i}" "$(basename "${f}")" "${rel}"
            i=$((i + 1))
        done
        echo ""
        echo -e "  ${RED}[0] ${MSG_BACK}${NC}"
        echo ""

        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-${#reports[@]}]" "")
        if [[ "${choice}" == "0" ]]; then
            return 0
        elif [[ "${choice}" =~ ^[1-9][0-9]*$ ]] && [[ "${choice}" -le "${#reports[@]}" ]]; then
            echo ""
            cat "${reports[$((choice - 1))]}"
            echo ""
            press_enter
        else
            log_error "${MSG_MENU_INVALID}"
        fi
    done
}

# ═══════════════════════════════════════════
# Full Security Configuration Wizard
# ═══════════════════════════════════════════

run_full_wizard() {
    # Refactored: delegate to run_mode_wizard with appropriate module list
    local -a modules
    if is_mode_lite; then
        modules=("init" "ssh" "firewall" "kernel")
    else
        modules=("${MODE_ADVANCED_MODULES[@]}")
    fi
    run_mode_wizard "${modules[*]}" "${MSG_WIZARD_TITLE}"
}

# ═══════════════════════════════════════════
# 加固模式选择屏幕（Batch 4）
# ═══════════════════════════════════════════

# 显示加固模式选择界面
# 仅 Full 模式调用，Lite 模式直接进入主菜单
# 用法: show_hardening_mode_screen
show_hardening_mode_screen() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_MODE_SELECT_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${MSG_MODE_SELECT_DESC}"
    echo ""

    # Option 1: Basic
    echo -e "  ${GREEN}[1] ${MSG_MODE_BASIC}${NC}"
    echo -e "      ${MSG_MODE_BASIC_DESC}"
    echo -e "      ${MSG_MODE_BASIC_TIP}"
    echo ""

    # Option 2: Standard
    echo -e "  ${GREEN}[2] ${MSG_MODE_STANDARD}${NC}"
    echo -e "      ${MSG_MODE_STANDARD_DESC}"
    echo -e "      ${MSG_MODE_STANDARD_TIP}"
    echo ""

    # Option 3: Advanced
    echo -e "  ${GREEN}[3] ${MSG_MODE_ADVANCED}${NC}"
    echo -e "      ${MSG_MODE_ADVANCED_DESC}"
    echo -e "      ${MSG_MODE_ADVANCED_TIP}"
    echo ""

    # Option 4: Custom
    echo -e "  ${GREEN}[4] ${MSG_MODE_CUSTOM}${NC}"
    echo -e "      ${MSG_MODE_CUSTOM_DESC}"
    echo -e "      ${MSG_MODE_CUSTOM_TIP}"
    echo ""

    local choice
    while true; do
        choice=$(prompt_input "${MSG_MODE_SELECT_PROMPT}" "4")

        if [[ -z "${choice}" ]]; then
            log_error "${MSG_ERROR_NO_INPUT}"
            return 1
        fi

        case "${choice}" in
            1)
                run_mode_wizard "${MODE_BASIC_MODULES[*]}" "${MSG_MODE_WIZARD_BASIC}"
                return 0
                ;;
            2)
                run_mode_wizard "${MODE_STANDARD_MODULES[*]}" "${MSG_MODE_WIZARD_STANDARD}"
                return 0
                ;;
            3)
                run_mode_wizard "${MODE_ADVANCED_MODULES[*]}" "${MSG_MODE_WIZARD_ADVANCED}"
                return 0
                ;;
            4)
                return 0  # Custom: enter main menu
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 加固向导执行器（Batch 4）
# ═══════════════════════════════════════════

# 运行加固向导，按模块列表顺序执行
# 参数: $1 空格分隔的模块名列表, $2 向导标题
# 用法: run_mode_wizard "init ssh firewall kernel" "Basic Hardening Wizard"
run_mode_wizard() {
    set -f
    # shellcheck disable=SC2206
    local -a modules=($1)
    set +f
    local wizard_title="$2"

    log_title "${wizard_title}"

    echo ""
    echo -e "${BOLD}${MSG_WIZARD_DESC}${NC}"
    echo ""
    press_enter

    local wizard_rc=0

    # Track which modules were executed
    export _WIZARD_INIT_DONE=0
    export _WIZARD_SSH_DONE=0
    export _WIZARD_FIREWALL_DONE=0
    export _WIZARD_FAIL2BAN_DONE=0
    export _WIZARD_AUDIT_DONE=0
    export _WIZARD_USERS_DONE=0
    export _WIZARD_KERNEL_DONE=0
    export _WIZARD_FS_DONE=0
    export _WIZARD_SERVICES_DONE=0
    export _WIZARD_AUTOUPDATE_DONE=0
    export _WIZARD_AIDE_DONE=0
    export _WIZARD_CLAMAV_DONE=0
    export _WIZARD_ROOTKIT_DONE=0

    local module
    for module in "${modules[@]}"; do
        case "${module}" in
            init)
                echo ""
                log_title "${MSG_WIZARD_STEP_INIT}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_INIT}"
                else
                    if run_init; then
                        _WIZARD_INIT_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_INIT}"
                        log_warn "${MSG_WIZARD_ERR_INIT_DETAIL}"
                        if ! confirm "${MSG_WIZARD_ERR_INIT_PROMPT}" "n"; then
                            log_error "${MSG_WIZARD_ERR_INIT_ABORT}"
                            return 1
                        fi
                        wizard_rc=1
                    fi
                fi
                ;;
            ssh)
                echo ""
                log_title "${MSG_WIZARD_STEP_SSH}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_SSH}"
                else
                    if run_ssh_wizard; then
                        _WIZARD_SSH_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_SSH}"
                        wizard_rc=1
                    fi
                fi
                ;;
            firewall)
                echo ""
                log_title "${MSG_WIZARD_STEP_FIREWALL}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_FIREWALL}"
                else
                    if run_firewall_wizard; then
                        _WIZARD_FIREWALL_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_FIREWALL}"
                        wizard_rc=1
                    fi
                fi
                ;;
            fail2ban)
                echo ""
                log_title "${MSG_WIZARD_STEP_FAIL2BAN}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_FAIL2BAN}"
                else
                    if run_fail2ban_wizard; then
                        _WIZARD_FAIL2BAN_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_FAIL2BAN}"
                        wizard_rc=1
                    fi
                fi
                ;;
            audit)
                echo ""
                log_title "${MSG_WIZARD_STEP_AUDIT}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_AUDIT}"
                else
                    if run_audit_wizard; then
                        _WIZARD_AUDIT_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_AUDIT}"
                        wizard_rc=1
                    fi
                fi
                ;;
            users)
                echo ""
                log_title "${MSG_WIZARD_STEP_USERS}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_USERS}"
                else
                    if run_users_wizard; then
                        _WIZARD_USERS_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_USERS}"
                        wizard_rc=1
                    fi
                fi
                ;;
            kernel)
                echo ""
                log_title "${MSG_WIZARD_STEP_KERNEL}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_KERNEL}"
                else
                    if run_kernel_wizard; then
                        _WIZARD_KERNEL_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_KERNEL}"
                        wizard_rc=1
                    fi
                fi
                ;;
            filesystem)
                echo ""
                log_title "${MSG_WIZARD_STEP_FILESYSTEM}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_FILESYSTEM}"
                else
                    if run_filesystem_wizard; then
                        _WIZARD_FS_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_FILESYSTEM}"
                        wizard_rc=1
                    fi
                fi
                ;;
            services)
                echo ""
                log_title "${MSG_WIZARD_STEP_SERVICES}"
                if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
                    log_info "${MSG_WIZARD_SKIPPED_SERVICES}"
                else
                    if run_services_wizard; then
                        _WIZARD_SERVICES_DONE=1
                    else
                        log_warn "${MSG_WIZARD_ERR_SERVICES}"
                        wizard_rc=1
                    fi
                fi
                ;;
        esac
    done

    # ── Summary ──
    echo ""
    log_title "${MSG_WIZARD_STEP_SUMMARY}"

    generate_report

    if [[ ${wizard_rc} -eq 0 ]]; then
        log_success "${MSG_WIZARD_COMPLETE}"
    else
        log_warn "${MSG_WIZARD_COMPLETE} ${MSG_WIZARD_ERR_HINT}"
    fi

    press_enter
    return ${wizard_rc}
}

# ═══════════════════════════════════════════
# 清理并退出
# ═══════════════════════════════════════════

cleanup_and_exit() {
    # 清理 bootstrap 临时目录
    if [[ -n "${_CLEANUP_DIR:-}" ]] && [[ -d "${_CLEANUP_DIR}" ]]; then
        rm -rf "${_CLEANUP_DIR}" 2>/dev/null || true
    fi
    echo ""
    log_info "${MSG_GOODBYE}"
    echo ""
    exit 0
}

# ═══════════════════════════════════════════
# 备份/回滚中心 子菜单
# ═══════════════════════════════════════════
show_backup_center_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_BACKUP_CENTER_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_LIST}${NC}"
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_RESTORE}${NC}"
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_ROLLBACK}${NC}"
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_CLEAN}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_BACKUP_CENTER_MENU_BACK}${NC}"
    echo ""
}

run_backup_center_menu() {
    while true; do
        show_backup_center_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-4]" "")
        case "${choice}" in
            1) backup_center_show_history; press_enter ;;
            2) backup_center_interactive_restore ;;
            3) backup_center_interactive_rollback ;;
            4) backup_center_interactive_clean ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 查看备份历史（只读）
backup_center_show_history() {
    local modules
    modules="$(backup_center_list_modules)"
    if [[ -z "${modules}" ]]; then
        log_info "${MSG_BACKUP_CENTER_NO_BACKUPS}"
        return 0
    fi
    log_title "${MSG_BACKUP_CENTER_HISTORY_TITLE}"
    local backup_path meta module
    while IFS= read -r backup_path; do
        [[ -f "${backup_path}" ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        module="other"
        [[ -n "${meta}" ]] && module="$(backup_center_module_of_path "${meta}")"
        printf "  [%-10s] %s\n" "${module}" "$(basename "${backup_path}")"
    done < <(list_backups)
}

# 一键恢复（带双重确认）
backup_center_interactive_restore() {
    local modules
    modules="$(backup_center_list_modules)"
    if [[ -z "${modules}" ]]; then
        log_info "${MSG_BACKUP_CENTER_NO_BACKUPS}"
        press_enter
        return 0
    fi
    log_title "${MSG_BACKUP_CENTER_SELECT_MODULE}"
    local module
    printf '%s\n' "${modules}" | sed 's/^/  - /'
    local target_module
    target_module=$(prompt_input "${MSG_BACKUP_CENTER_MODULE_PROMPT}" "")
    if [[ -z "${target_module}" ]]; then
        return 0
    fi

    # 列出该模块将恢复的文件（按目标路径去重）
    local backup_path meta files=() seen=()
    while IFS= read -r backup_path; do
        [[ -f "${backup_path}" ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        if [[ -n "${meta}" ]] && [[ "$(backup_center_module_of_path "${meta}")" == "${target_module}" ]] && ! printf '%s\n' "${seen[@]}" | grep -qx "${meta}"; then
            files+=("${meta}")
            seen+=("${meta}")
        fi
    done < <(list_backups)
    if [[ ${#files[@]} -eq 0 ]]; then
        log_info "${MSG_BACKUP_CENTER_NO_RESTORABLE}"
        press_enter
        return 0
    fi

    log_warn "${MSG_BACKUP_CENTER_CONFIRM_RESTORE}"
    printf '  %s\n' "${files[@]}" | sed 's/^/    - /'
    local ans
    ans=$(prompt_input "${MSG_BACKUP_CENTER_CONFIRM_PROMPT}" "n")
    if [[ "${ans}" != "y" ]] && [[ "${ans}" != "Y" ]]; then
        log_info "${MSG_BACKUP_CENTER_RESTORE_ABORTED}"
        press_enter
        return 0
    fi

    if backup_center_restore_module "${target_module}"; then
        log_success "${MSG_BACKUP_CENTER_RESTORED}: ${target_module}"
        # 对最近恢复的备份执行钩子
        local latest
        for backup_path in "${files[@]}"; do
            meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
            if latest="$(backup_center_latest_for_target "${meta}")"; then
                backup_center_post_restore "${latest}"
            fi
        done
    else
        # shellcheck disable=SC2059
        log_error "$(printf "${MSG_BACKUP_CENTER_RESTORE_FAILED}" "${target_module}")"
    fi
    press_enter
}

# SSH 回滚定时器管理
backup_center_interactive_rollback() {
    local status
    if status="$(rollback_timer_status)"; then
        # shellcheck disable=SC2059
        log_info "$(printf "${MSG_BACKUP_CENTER_ROLLBACK_PENDING}" "${status}")"
        local ans
        ans=$(prompt_input "${MSG_BACKUP_CENTER_ROLLBACK_CANCEL_CONFIRM}" "n")
        if [[ "${ans}" == "y" ]] || [[ "${ans}" == "Y" ]]; then
            if cancel_rollback_timer 2>/dev/null || cancel_scheduled_task "${status}" 2>/dev/null; then
                log_success "${MSG_BACKUP_CENTER_ROLLBACK_CANCEL}"
            else
                log_error "${MSG_BACKUP_CENTER_ROLLBACK_NO_PID}"
            fi
        fi
    else
        log_info "${MSG_BACKUP_CENTER_ROLLBACK_NONE}"
    fi
    press_enter
}

# 清理旧备份
backup_center_interactive_clean() {
    local ans
    ans=$(prompt_input "${MSG_BACKUP_CENTER_CLEAN_CONFIRM}" "n")
    if [[ "${ans}" != "y" ]] && [[ "${ans}" != "Y" ]]; then
        return 0
    fi
    if clean_old_backups 5; then
        log_success "${MSG_BACKUP_CENTER_CLEAN_DONE}"
    else
        log_info "${MSG_BACKUP_CENTER_CLEAN_EMPTY}"
    fi
    press_enter
}

# ═══════════════════════════════════════════
# 安全仪表盘
# ═══════════════════════════════════════════
run_dashboard_menu() {
    dashboard_render
    press_enter
}

# ═══════════════════════════════════════════
# 主菜单循环
# ═══════════════════════════════════════════

show_server_menu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_SERVER_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_SERVER_MENU_DOCKER}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_NGINX}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_REDIS}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_POSTGRES}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_MYSQL}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_MEMCACHED}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_NODE_EXPORTER}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_PROMETHEUS}${NC}"
    echo -e "  ${GREEN}${MSG_SERVER_MENU_GRAFANA}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_SERVER_MENU_BACK}${NC}"
    echo ""
}

run_server_menu_loop() {
    while true; do
        show_server_menu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-9]" "")
        case "${choice}" in
            1) run_docker_submenu_loop ;;
            2) run_nginx_submenu_loop ;;
            3) run_redis_submenu_loop ;;
            4) run_postgres_submenu_loop ;;
            5) run_mysql_submenu_loop ;;
            6) run_memcached_submenu_loop ;;
            7) run_node_exporter_submenu_loop ;;
            8) run_prometheus_submenu_loop ;;
            9) run_grafana_submenu_loop ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

show_dev_menu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_DEV_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_DEV_MENU_GIT}${NC}"
    echo -e "  ${GREEN}${MSG_DEV_MENU_EDITOR}${NC}"
    echo -e "  ${GREEN}${MSG_DEV_MENU_RUNTIMES}${NC}"
    echo -e "  ${GREEN}${MSG_DEV_MENU_BUILD_TOOLCHAIN}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_DEV_MENU_BACK}${NC}"
    echo ""
}

run_dev_menu_loop() {
    while true; do
        show_dev_menu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-4]" "")
        case "${choice}" in
            1) run_git_submenu_loop ;;
            2) run_editor_submenu_loop ;;
            3) run_runtimes_submenu_loop ;;
            4) run_build_toolchain_submenu_loop ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

run_main_menu_loop() {
    while true; do
        show_main_menu
        local choice
        choice=$(get_main_menu_choice)

        case "${choice}" in
            1) show_system_status ;;
            2) run_ssh_submenu_loop ;;
            3) run_firewall_submenu_loop ;;
            4|5|6|8|9|10|13|14|15|16)
                if is_mode_lite; then
                    log_error "${MSG_ERROR_LITE_MODE}"
                    press_enter
                    continue
                fi
                case "${choice}" in
                    4) run_fail2ban_submenu_loop ;;
                    5) run_audit_submenu_loop ;;
                    6) run_users_submenu_loop ;;
                    8) run_filesystem_submenu_loop ;;
                    9) run_services_submenu_loop ;;
                    10) run_autoupdate_submenu_loop ;;
                    13) run_k3s_submenu_loop ;;
                    14) run_aide_submenu_loop ;;
                    15) run_clamav_submenu_loop ;;
                    16) run_rootkit_submenu_loop ;;
                esac
                ;;
            7) run_kernel_submenu_loop ;;
            11)
                run_full_wizard
                press_enter
                ;;
            12) view_report ;;
            17|18)
                if is_mode_lite; then
                    log_error "${MSG_ERROR_LITE_MODE}"
                    press_enter
                    continue
                fi
                case "${choice}" in
                    17) run_backup_center_menu ;;
                    18) run_dashboard_menu ;;
                esac
                ;;
            19) run_mirror_submenu_loop ;;
            20)
                if is_mode_lite; then
                    log_error "${MSG_ERROR_LITE_MODE}"
                    press_enter
                    continue
                fi
                run_server_menu_loop
                ;;
            21)
                if is_mode_lite; then
                    log_error "${MSG_ERROR_LITE_MODE}"
                    press_enter
                    continue
                fi
                run_dev_menu_loop
                ;;
            0) cleanup_and_exit ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                press_enter
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 主流程
# ═══════════════════════════════════════════

main() {
    # 加载依赖
    load_dependencies

    # 解析参数（需要在 load_dependencies 之后，因为引用了颜色变量）
    _parse_args "$@"

    # 初始化日志
    init_logging

    # 设置错误陷阱
    setup_error_trap

    # EXIT trap 已在 setup_error_trap() 中通过 _cleanup_on_exit() 统一处理
    # （清理 _CLEANUP_DIR 和 _SCHEDULED_PID）

    # --status mode: read-only detection, no system modification
    if [[ "${TARGET_MODULE:-}" == "status" ]]; then
        run_detection || true
        print_detection_summary
        # Clean up bootstrap temp dir
        if [[ -n "${_CLEANUP_DIR:-}" ]] && [[ -d "${_CLEANUP_DIR}" ]]; then
            rm -rf "${_CLEANUP_DIR}" 2>/dev/null || true
        fi
        exit 0
    fi

    # 交互模式：系统检测 → 主菜单循环
    run_detection || {
        log_warn "System detection completed with warnings"
        log_warn "Some features may not work correctly on this system"
    }

    print_detection_summary

    # Show hardening mode selection (Full mode only)
    if is_mode_full; then
        show_hardening_mode_screen
    fi

    # 进入主菜单循环
    run_main_menu_loop
}

# ═══════════════════════════════════════════
# 脚本入口
# ═══════════════════════════════════════════

# 执行主流程
main "$@"

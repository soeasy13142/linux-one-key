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

# ═══════════════════════════════════════════
# Bootstrap: curl 管道模式自动下载完整仓库并 re-exec
# ═══════════════════════════════════════════

_bootstrap_and_reexec() {
    local tmp_dir
    tmp_dir=$(mktemp -d)

    echo "正在从 GitHub 下载 linux-one-key..."
    echo "  仓库: https://github.com/${GITHUB_REPO}"
    echo ""

    # 下载 tarball 并解压
    if ! curl -fsSL "${GITHUB_TARBALL_URL}" | tar xz -C "${tmp_dir}"; then
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

    # 完整性校验：对比 SHA256SUMS 文件
    local checksum_url="https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/SHA256SUMS"
    local checksum_file="${tmp_dir}/SHA256SUMS"
    if curl -fsSL "${checksum_url}" -o "${checksum_file}" 2>/dev/null; then
        local expected_hash actual_hash
        expected_hash=$(grep "install.sh" "${checksum_file}" | awk '{print $1}' || true)
        actual_hash=$(sha256sum "${extracted_dir}/install.sh" | awk '{print $1}')
        if [[ -n "${expected_hash}" ]] && [[ "${expected_hash}" != "${actual_hash}" ]]; then
            echo "错误: install.sh 完整性校验失败！"
            echo "  期待: ${expected_hash}"
            echo "  实际: ${actual_hash}"
            echo "  可能原因：下载不完整、网络问题或文件被篡改"
            rm -rf "${tmp_dir}"
            exit 1
        fi
    else
        echo "警告: 无法下载校验文件，跳过完整性验证"
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
    # curl pipe mode: just re-exec, user gets interactive menu
    :
    chmod +x "${extracted_dir}/install.sh"
    if tty &>/dev/null; then
        exec bash "${extracted_dir}/install.sh" "${args[@]}" < /dev/tty
    else
        exec bash "${extracted_dir}/install.sh" "${args[@]}" < /dev/null
    fi
}

# ═══════════════════════════════════════════
# 参数解析
# ═══════════════════════════════════════════

# Parse command line arguments
_parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --status)
                export TARGET_MODULE="status"
                ;;
            --help|-h)
                echo "Usage: bash install.sh [options]"
                echo ""
                echo "Options:"
                echo "  --status       Show system security status (read-only)"
                echo "  --help, -h     Show this help"
                echo ""
                echo "No arguments: interactive menu."
                echo ""
                echo "Examples:"
                echo "  bash install.sh                      # Interactive menu"
                echo "  bash install.sh --status             # Status check only"
                echo "  curl -fsSL .../install.sh | sudo bash"
                exit 0
                ;;
            --yes|-y|--quick|--ssh|--firewall|--fail2ban)
                local removed_arg="${arg#--}"
                removed_arg="${removed_arg#-}"
                echo ""
                echo -e "${RED}Error: --${removed_arg} has been removed.${NC}"
                echo -e "${YELLOW}This script is now fully interactive:${NC}"
                echo -e "${YELLOW}  sudo bash install.sh${NC}"
                echo -e "${BLUE}Tip: --status still works for read-only:${NC}"
                echo -e "${BLUE}  sudo bash install.sh --status${NC}"
                echo ""
                exit 1
                ;;
            *)
                echo -e "${RED}Unknown argument: ${arg}${NC}"
                echo "Use --help for available options"
                exit 1
                ;;
        esac
    done
}

_parse_args "$@"

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
}

# ═══════════════════════════════════════════
# 欢迎信息
# ═══════════════════════════════════════════

show_welcome() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║                                                           ║${NC}"
    echo -e "${BOLD}║       Linux 云服务器安全加固脚本                          ║${NC}"
    echo -e "${BOLD}║       Linux Server Security Hardening Script              ║${NC}"
    echo -e "${BOLD}║                                                           ║${NC}"
    echo -e "${BOLD}║       ${MSG_VERSION}: ${SCRIPT_VERSION}                                        ║${NC}"
    echo -e "${BOLD}║                                                           ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}${MSG_WELCOME}${NC}"
    echo -e "${BLUE}${MSG_DESCRIPTION}${NC}"
    echo ""
}

# ═══════════════════════════════════════════
# 系统状态检测（只读，不修改系统）
# ═══════════════════════════════════════════

# 显示系统安全状态
show_system_status() {
    log_title "${MSG_STATUS_TITLE}"

    # SSH 状态
    echo -e "${GREEN}[SSH]${NC}"
    local ssh_port
    ssh_port=$(get_ssh_port 2>/dev/null || echo "22")
    if [[ "${ssh_port}" == "22" ]]; then
        echo -e "  ${MSG_STATUS_SSH_PORT}: ${ssh_port} (${MSG_STATUS_DEFAULT_PORT})"
    else
        echo -e "  ${MSG_STATUS_SSH_PORT}: ${ssh_port} (${MSG_STATUS_CONFIGURED})"
    fi

    local root_login
    root_login=$(get_ssh_config "PermitRootLogin" 2>/dev/null || echo "unknown")
    if [[ "${root_login}" == "no" ]]; then
        echo -e "  ${MSG_STATUS_SSH_ROOT}: ${MSG_STATUS_NOT_ALLOWED}"
    else
        echo -e "  ${MSG_STATUS_SSH_ROOT}: ${MSG_STATUS_ALLOWED}"
    fi

    local pass_auth
    pass_auth=$(get_ssh_config "PasswordAuthentication" 2>/dev/null || echo "unknown")
    if [[ "${pass_auth}" == "no" ]]; then
        echo -e "  ${MSG_STATUS_SSH_PASSWD}: ${MSG_STATUS_NOT_ALLOWED}"
    else
        echo -e "  ${MSG_STATUS_SSH_PASSWD}: ${MSG_STATUS_ALLOWED}"
    fi

    local pubkey_auth
    pubkey_auth=$(get_ssh_config "PubkeyAuthentication" 2>/dev/null || echo "unknown")
    if [[ "${pubkey_auth}" == "yes" ]] || [[ "${pubkey_auth}" == "unknown" ]]; then
        echo -e "  ${MSG_STATUS_SSH_KEY}: ${MSG_STATUS_ENABLED}"
    else
        echo -e "  ${MSG_STATUS_SSH_KEY}: ${MSG_STATUS_DISABLED}"
    fi

    echo ""

    # 防火墙状态
    echo -e "${GREEN}[${MSG_STATUS_FIREWALL}]${NC}"
    local fw_status="${MSG_STATUS_DISABLED}"
    if command -v ufw &>/dev/null; then
        if ufw status 2>/dev/null | grep -q "Status: active"; then
            fw_status="${MSG_STATUS_ENABLED}"
        fi
    elif command -v firewall-cmd &>/dev/null; then
        if firewall-cmd --state &>/dev/null; then
            fw_status="${MSG_STATUS_ENABLED}"
        fi
    fi
    echo -e "  ${MSG_STATUS_FIREWALL}: ${fw_status}"

    echo ""

    # Fail2Ban 状态
    echo -e "${GREEN}[${MSG_STATUS_FAIL2BAN}]${NC}"
    local f2b_status="${MSG_STATUS_NOT_INSTALLED}"
    if command -v fail2ban-client &>/dev/null; then
        if systemctl is-active fail2ban &>/dev/null; then
            f2b_status="${MSG_STATUS_INSTALLED} (${MSG_STATUS_ENABLED})"
        else
            f2b_status="${MSG_STATUS_INSTALLED} (${MSG_STATUS_DISABLED})"
        fi
    fi
    echo -e "  ${MSG_STATUS_FAIL2BAN}: ${f2b_status}"

    echo ""
    press_enter
}

# ═══════════════════════════════════════════
# 主菜单
# ═══════════════════════════════════════════

# 显示主菜单
show_main_menu() {
    echo ""
    echo -e "${BOLD}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}║       Linux 云服务器安全加固脚本 ${SCRIPT_VERSION}                    ║${NC}"
    echo -e "${BOLD}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${MSG_MAIN_MENU_SYSTEM_INFO}: $(get_detected_os) $(get_detected_os_version) | $(get_detected_arch) | $(whoami)"
    echo ""
    echo -e "${BOLD}${MSG_MAIN_MENU_CHOICE}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_STATUS}${NC}"
    echo -e "      ${MSG_MAIN_MENU_STATUS_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_SSH}${NC}"
    echo -e "      ${MSG_MAIN_MENU_SSH_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FIREWALL}${NC}"
    echo -e "      ${MSG_MAIN_MENU_FIREWALL_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FAIL2BAN}${NC}"
    echo -e "      ${MSG_MAIN_MENU_FAIL2BAN_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_QUICK}${NC}"
    echo -e "      ${MSG_MAIN_MENU_QUICK_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_REPORT}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_MAIN_MENU_EXIT}${NC}"
    echo ""
}

# 获取主菜单选择
get_main_menu_choice() {
    local choice
    while true; do
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-6]" "")
        case "${choice}" in
            [0-6])
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
# 查看报告
# ═══════════════════════════════════════════

view_report() {
    local report_dir="/var/log/linux-one-key"
    local latest_report

    if [[ -d "${report_dir}" ]]; then
        latest_report=$(ls -t "${report_dir}"/report_*.txt 2>/dev/null | head -1)
    fi

    if [[ -n "${latest_report}" ]] && [[ -f "${latest_report}" ]]; then
        echo ""
        cat "${latest_report}"
        echo ""
    else
        log_warn "${MSG_REPORT_NOT_FOUND}"
    fi

    press_enter
}

# ═══════════════════════════════════════════
# Full Security Configuration Wizard
# ═══════════════════════════════════════════

run_full_wizard() {
    log_title "${MSG_WIZARD_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_WIZARD_DESC}${NC}"
    echo ""
    press_enter

    local wizard_rc=0

    # Track which modules were executed (not skipped)
    export _WIZARD_SSH_DONE=0
    export _WIZARD_FIREWALL_DONE=0
    export _WIZARD_FAIL2BAN_DONE=0

    # ── Step 1: SSH ──
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

    # ── Step 2: Firewall ──
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

    # ── Step 3: Fail2Ban ──
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

    # ── Step 4: Summary ──
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
# 主菜单循环
# ═══════════════════════════════════════════

run_main_menu_loop() {
    while true; do
        show_main_menu
        local choice
        choice=$(get_main_menu_choice)

        case "${choice}" in
            1) show_system_status ;;
            2) run_ssh_submenu_loop ;;
            3) run_firewall_submenu_loop ;;
            4)
                run_fail2ban_wizard || log_error "Fail2Ban config failed"
                press_enter
                ;;
            5)
                run_full_wizard
                press_enter
                ;;
            6) view_report ;;
            0) cleanup_and_exit ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 生成报告
# ═══════════════════════════════════════════

generate_report() {
    local report_path
    report_path=$(get_report_path)

    log_step "Generating report..."

    # Helper: format a task line with done/skipped/failed status
    _report_task_line() {
        local done_flag="${1:-0}"
        local task_name="${2}"
        if [[ "${done_flag}" == "1" ]]; then
            echo "[✓] ${task_name}"
        else
            echo "[⊘] ${task_name} — ${MSG_WIZARD_SKIPPED}"
        fi
    }

    # Build report
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "                ${MSG_REPORT_TITLE}"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "${MSG_REPORT_SYSTEM}:"
        echo "  - ${MSG_DETECT_OS}: $(get_detected_os) $(get_detected_os_version)"
        echo "  - ${MSG_DETECT_ARCH}: $(get_detected_arch)"
        echo "  - ${MSG_DETECT_USER}: $(whoami)"
        echo "  - Hostname: $(get_hostname)"
        echo ""

        # ── Tasks section — dynamic per module ──
        echo "${MSG_REPORT_TASKS}:"

        # SSH
        _report_task_line "${_WIZARD_SSH_DONE:-0}" "${MSG_TASK_SSH}"
        if [[ "${_WIZARD_SSH_DONE:-0}" == "1" ]]; then
            echo "    - Port: $(get_ssh_port)"
            local root_login
            root_login=$(get_ssh_config "PermitRootLogin" 2>/dev/null || echo "unknown")
            echo "    - Root login: ${root_login}"
            local pass_auth
            pass_auth=$(get_ssh_config "PasswordAuthentication" 2>/dev/null || echo "unknown")
            echo "    - Password auth: ${pass_auth}"
            local pubkey_auth
            pubkey_auth=$(get_ssh_config "PubkeyAuthentication" 2>/dev/null || echo "unknown")
            echo "    - Key authentication: ${pubkey_auth}"
        fi

        # Firewall
        _report_task_line "${_WIZARD_FIREWALL_DONE:-0}" "${MSG_TASK_FIREWALL}"
        if [[ "${_WIZARD_FIREWALL_DONE:-0}" == "1" ]]; then
            local fw_status="${MSG_STATUS_DISABLED}"
            if command -v ufw &>/dev/null; then
                if ufw status 2>/dev/null | grep -q "Status: active"; then
                    fw_status="${MSG_STATUS_ENABLED}"
                fi
            elif command -v firewall-cmd &>/dev/null; then
                if firewall-cmd --state &>/dev/null; then
                    fw_status="${MSG_STATUS_ENABLED}"
                fi
            fi
            echo "    - ${MSG_STATUS_FIREWALL}: ${fw_status}"
        fi

        # Fail2Ban
        _report_task_line "${_WIZARD_FAIL2BAN_DONE:-0}" "${MSG_TASK_FAIL2BAN}"
        if [[ "${_WIZARD_FAIL2BAN_DONE:-0}" == "1" ]]; then
            local f2b_status="${MSG_STATUS_NOT_INSTALLED}"
            if command -v fail2ban-client &>/dev/null; then
                if systemctl is-active fail2ban &>/dev/null; then
                    f2b_status="${MSG_STATUS_ENABLED}"
                else
                    f2b_status="${MSG_STATUS_DISABLED}"
                fi
            fi
            echo "    - ${MSG_STATUS_FAIL2BAN}: ${f2b_status}"
        fi

        echo ""

        # ── Config files modified ──
        echo "${MSG_REPORT_CONFIGS}:"
        if [[ "${_WIZARD_SSH_DONE:-0}" == "1" ]]; then
            local latest_ssh_backup
            latest_ssh_backup=$(find "${BACKUP_DIR}" -name "sshd_config.bak.*" -type f 2>/dev/null | sort -r | head -1)
            echo "  - ${SSH_CONFIG}"
            if [[ -n "${latest_ssh_backup}" ]]; then
                echo "    Backup: ${latest_ssh_backup}"
            fi
        fi
        if [[ "${_WIZARD_FAIL2BAN_DONE:-0}" == "1" ]]; then
            if [[ -n "${FAIL2BAN_JAIL_LOCAL:-}" ]]; then
                echo "  - ${FAIL2BAN_JAIL_LOCAL}"
            fi
        fi
        echo ""

        # ── Warnings — only for executed modules ──
        echo "${MSG_REPORT_WARNINGS}:"
        if [[ "${_WIZARD_SSH_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_WARN_CONNECTION}"
            echo "  ⚠ ${MSG_WARN_SAVE_KEY}"
            echo "  ⚠ ${MSG_WARN_TEST_FIRST}"
            local final_port
            final_port=$(get_ssh_port)
            if [[ "${final_port}" != "22" ]]; then
                echo "  ⚠ 防火墙已保留放通 22 端口，确认新 SSH 端口可用后请手动关闭: sudo ufw deny 22/tcp"
            fi
        fi
        if [[ "${_WIZARD_FIREWALL_DONE:-0}" == "1" ]]; then
            echo "  ⚠ 防火墙已启用，请确保已正确放通所需端口"
        fi
        if [[ "${_WIZARD_FAIL2BAN_DONE:-0}" == "1" ]]; then
            echo "  ⚠ 请定期检查 Fail2Ban 日志: sudo tail -f /var/log/fail2ban.log"
        fi

        echo ""
        echo "${MSG_REPORT_SAVED}: ${report_path}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
    } > "${report_path}"

    log_success "${MSG_REPORT_SAVED}: ${report_path}"
}

# ═══════════════════════════════════════════
# 主流程
# ═══════════════════════════════════════════

main() {
    # 加载依赖
    load_dependencies

    # 初始化日志
    init_logging

    # 设置错误陷阱
    setup_error_trap

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

    # 交互模式：显示欢迎 → 系统检测 → 主菜单循环
    show_welcome

    run_detection || {
        log_warn "System detection completed with warnings"
        log_warn "Some features may not work correctly on this system"
    }

    print_detection_summary

    # 进入主菜单循环
    run_main_menu_loop
}

# ═══════════════════════════════════════════
# 脚本入口
# ═══════════════════════════════════════════

# 执行主流程
main "$@"

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
    # curl 管道模式下如果没有任何参数且 stdin 非终端，自动启用非交互模式
    if [[ ${#args[@]} -eq 0 ]] && [[ ! -t 0 ]]; then
        args=("--yes")
    fi
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

# 解析命令行参数
_parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --yes|-y)
                export AUTO_ACCEPT="yes"
                export TARGET_MODULE="all"
                ;;
            --quick)
                export AUTO_ACCEPT="yes"
                export TARGET_MODULE="all"
                ;;
            --ssh)
                export AUTO_ACCEPT="yes"
                export TARGET_MODULE="ssh"
                ;;
            --firewall)
                export AUTO_ACCEPT="yes"
                export TARGET_MODULE="firewall"
                ;;
            --fail2ban)
                export AUTO_ACCEPT="yes"
                export TARGET_MODULE="fail2ban"
                ;;
            --status)
                export AUTO_ACCEPT="yes"
                export TARGET_MODULE="status"
                ;;
            --help|-h)
                echo "用法: bash install.sh [选项]"
                echo ""
                echo "选项:"
                echo "  --ssh          仅执行 SSH 安全加固"
                echo "  --firewall     仅执行防火墙配置"
                echo "  --fail2ban     仅执行 Fail2Ban 入侵防护"
                echo "  --status       仅显示系统安全状态"
                echo "  --quick        一键快速加固（全部执行）"
                echo "  --yes, -y      等同于 --quick（向后兼容）"
                echo "  --help, -h     显示帮助信息"
                echo ""
                echo "无参数运行进入交互式菜单。"
                echo ""
                echo "示例:"
                echo "  bash install.sh                      # 交互式菜单"
                echo "  bash install.sh --ssh                # 仅 SSH 加固"
                echo "  bash install.sh --quick              # 一键全部加固"
                echo "  curl -fsSL .../install.sh | sudo bash -s -- --yes"
                exit 0
                ;;
        esac
    done
}

_parse_args "$@"

# 自动检测非交互模式：如果没有 TTY 且未显式设置 --yes，自动启用 AUTO_ACCEPT
# curl 管道模式下 stdin 是管道（非终端），需要自动使用默认值
if [[ ! -t 0 ]] && [[ "${AUTO_ACCEPT}" != "yes" ]]; then
    export AUTO_ACCEPT="yes"
fi

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
                if confirm "${MSG_CONFIRM_SSH_PORT}" "y"; then
                    run_ssh_hardening_custom "y" "n" "n" "n" "n" || log_error "SSH 端口修改失败"
                fi
                press_enter
                ;;
            2)
                if confirm "${MSG_CONFIRM_SSH_KEY}" "y"; then
                    run_ssh_hardening_custom "n" "y" "n" "n" "n" || log_error "SSH 密钥生成失败"
                fi
                press_enter
                ;;
            3)
                if confirm "${MSG_CONFIRM_SSH_ROOT}" "y"; then
                    run_ssh_hardening_custom "n" "n" "y" "n" "n" || log_error "禁止 root 登录失败"
                fi
                press_enter
                ;;
            4)
                if confirm "${MSG_CONFIRM_SSH_PASSWD}" "y"; then
                    run_ssh_hardening_custom "n" "n" "n" "y" "n" || log_error "禁止密码登录失败"
                fi
                press_enter
                ;;
            5)
                if confirm "${MSG_CONFIRM_SSH_PARAMS}" "y"; then
                    run_ssh_hardening_custom "n" "n" "n" "n" "y" || log_error "SSH 参数配置失败"
                fi
                press_enter
                ;;
            6)
                if confirm "${MSG_CONFIRM_SSH_ALL}" "y"; then
                    run_ssh_hardening_custom "y" "y" "y" "y" "y" || log_error "SSH 加固失败"
                fi
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
                if confirm "${MSG_CONFIRM_FIREWALL_ENABLE}" "y"; then
                    run_firewall_hardening_custom "n" "n" || log_error "防火墙配置失败"
                fi
                press_enter
                ;;
            2)
                if confirm "${MSG_CONFIRM_FIREWALL_HTTP}" "y"; then
                    run_firewall_hardening_custom "y" "n" || log_error "HTTP/HTTPS 端口开放失败"
                fi
                press_enter
                ;;
            3)
                if confirm "${MSG_CONFIRM_FIREWALL_ICMP}" "y"; then
                    run_firewall_hardening_custom "n" "y" || log_error "ICMP 配置失败"
                fi
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
# 一键快速加固
# ═══════════════════════════════════════════

run_quick_hardening() {
    log_title "${MSG_QUICK_TITLE}"

    # 显示任务列表
    echo ""
    echo -e "${BOLD}即将执行以下安全配置：${NC}"
    echo ""
    echo -e "  ${GREEN}[SSH 安全]${NC}"
    echo -e "  1. SSH 端口修改 (22 → 2222)"
    echo -e "  2. SSH 密钥生成 (Ed25519)"
    echo -e "  3. 禁止 root 远程登录"
    echo -e "  4. 禁止密码登录"
    echo -e "  5. SSH 安全参数配置"
    echo ""
    echo -e "  ${GREEN}[防火墙]${NC}"
    echo -e "  6. 防火墙配置 (UFW/firewalld)"
    echo -e "     ⚠ 22 端口始终放通（防锁死），请在确认新端口后手动关闭"
    echo ""
    echo -e "  ${GREEN}[入侵防护]${NC}"
    echo -e "  7. Fail2Ban 安装与配置"
    echo ""

    # 确认执行
    if ! confirm "确认执行？" "y"; then
        log_info "已取消"
        return 0
    fi

    # 执行 SSH 加固
    run_ssh_hardening || {
        log_error "SSH 加固失败"
        return 1
    }

    # 执行防火墙配置
    run_firewall_hardening || {
        log_error "防火墙配置失败"
        return 1
    }

    # 执行 Fail2Ban 配置
    run_fail2ban_hardening || {
        log_error "Fail2Ban 配置失败"
        return 1
    }

    return 0
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
                if confirm "${MSG_CONFIRM_FAIL2BAN}" "y"; then
                    run_fail2ban_hardening || log_error "Fail2Ban 配置失败"
                fi
                press_enter
                ;;
            5)
                run_quick_hardening
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

    cat > "${report_path}" << EOF
═══════════════════════════════════════════════════════════════
                ${MSG_REPORT_TITLE}
═══════════════════════════════════════════════════════════════

${MSG_REPORT_SYSTEM}:
  - ${MSG_DETECT_OS}: $(get_detected_os) $(get_detected_os_version)
  - ${MSG_DETECT_ARCH}: $(get_detected_arch)
  - ${MSG_DETECT_USER}: $(whoami)
  - Hostname: $(get_hostname)

${MSG_REPORT_TASKS}:
  [✓] ${MSG_TASK_SSH}
    - Port: $(get_ssh_port)
    - Key authentication: enabled
    - Root login: disabled
    - Password auth: disabled

${MSG_REPORT_CONFIGS}:
  - ${SSH_CONFIG}
    Backup: ${BACKUP_DIR}/sshd_config.bak.${TIMESTAMP}

${MSG_REPORT_WARNINGS}:
  ⚠ ${MSG_WARN_CONNECTION}
  ⚠ ${MSG_WARN_SAVE_KEY}
  ⚠ ${MSG_WARN_TEST_FIRST}
  ⚠ 防火墙已保留放通 22 端口，确认新 SSH 端口可用后请手动关闭: sudo ufw deny 22/tcp

${MSG_REPORT_SAVED}: ${report_path}

═══════════════════════════════════════════════════════════════
EOF

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

    # 非交互模式：根据 TARGET_MODULE 直接执行（不显示菜单）
    if [[ "${AUTO_ACCEPT}" == "yes" ]]; then
        local rc=0
        case "${TARGET_MODULE:-all}" in
            status)
                run_detection || true
                print_detection_summary
                exit 0
                ;;
            ssh)
                run_detection || true
                run_ssh_hardening || rc=$?
                ;;
            firewall)
                run_detection || true
                run_firewall_hardening || rc=$?
                ;;
            fail2ban)
                run_detection || true
                run_fail2ban_hardening || rc=$?
                ;;
            all|"")
                run_detection || true
                run_quick_hardening || rc=$?
                ;;
            *)
                log_error "未知模块: ${TARGET_MODULE}"
                exit 1
                ;;
        esac

        if [[ ${rc} -eq 0 ]]; then
            generate_report
        else
            log_error "任务执行失败（exit code: ${rc}），跳过报告生成"
        fi

        # 清理 bootstrap 临时目录
        if [[ -n "${_CLEANUP_DIR:-}" ]] && [[ -d "${_CLEANUP_DIR}" ]]; then
            rm -rf "${_CLEANUP_DIR}" 2>/dev/null || true
        fi

        echo ""
        log_title "${MSG_FINISH}"
        log_info "${MSG_FINISH_HINT}"
        echo ""
        exit "${rc}"
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

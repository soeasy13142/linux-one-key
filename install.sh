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
        expected_hash=$(grep "install.sh" "${checksum_file}" | awk '{print $1}')
        actual_hash=$(sha256sum "${extracted_dir}/install.sh" | awk '{print $1}')
        if [[ -n "${expected_hash}" ]] && [[ "${expected_hash}" != "${actual_hash}" ]]; then
            echo "错误: install.sh 完整性校验失败！"
            echo "  期待: ${expected_hash}"
            echo "  实际: ${actual_hash}"
            echo "  可能原因：下载不完整、网络问题或文件被篡改"
            rm -rf "${tmp_dir}"
            exit 1
        fi
        log_debug "Integrity check passed for install.sh" 2>/dev/null || true
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
    chmod +x "${extracted_dir}/install.sh"
    if tty &>/dev/null; then
        exec bash "${extracted_dir}/install.sh" "$@" < /dev/tty
    else
        exec bash "${extracted_dir}/install.sh" "$@" < /dev/null
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
                ;;
            --help|-h)
                echo "用法: bash install.sh [选项]"
                echo ""
                echo "选项:"
                echo "  --yes, -y    非交互模式，自动使用默认值"
                echo "  --help, -h   显示帮助信息"
                echo ""
                echo "示例:"
                echo "  curl -fsSL https://raw.githubusercontent.com/${GITHUB_REPO}/${GITHUB_BRANCH}/install.sh | sudo bash -s -- --yes"
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
# 执行方式选择
# ═══════════════════════════════════════════

# 显示执行方式菜单
show_execution_mode_menu() {
    echo -e "${BOLD}请选择执行方式：${NC}"
    echo ""
    echo -e "  ${GREEN}[1] 快速开始（推荐）${NC}"
    echo -e "      使用默认安全配置，逐项确认后执行"
    echo ""
    echo -e "  ${GREEN}[2] 自定义配置${NC}"
    echo -e "      逐项选择需要执行的任务"
    echo ""
}

# 获取执行方式选择
get_execution_mode() {
    local choice

    while true; do
        choice=$(prompt_input "请输入选项" "1")

        case "${choice}" in
            1)
                echo "quick"
                return 0
                ;;
            2)
                echo "custom"
                return 0
                ;;
            *)
                log_error "无效选项，请输入 1 或 2"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 快速开始模式
# ═══════════════════════════════════════════

# 显示快速开始任务列表
show_quick_start_tasks() {
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
    echo ""
    echo -e "  ${GREEN}[入侵防护]${NC}"
    echo -e "  7. Fail2Ban 安装与配置"
    echo ""
}

# 快速开始模式执行
run_quick_start() {
    log_title "快速开始"

    # 显示任务列表
    show_quick_start_tasks

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
# 自定义配置模式
# ═══════════════════════════════════════════

# 自定义配置模式执行
run_custom_config() {
    log_title "自定义配置"

    echo -e "${BOLD}请选择需要执行的任务：${NC}"
    echo ""

    # ═══════════════════════════════════════════
    # SSH 安全配置
    # ═══════════════════════════════════════════

    echo -e "${GREEN}[SSH 安全]${NC}"

    # SSH 端口修改
    local do_ssh_port
    if confirm "1. SSH 端口修改 (22 → 2222)？"; then
        do_ssh_port="y"
    else
        do_ssh_port="n"
    fi

    # SSH 密钥生成
    local do_ssh_key
    if confirm "2. SSH 密钥生成 (Ed25519)？"; then
        do_ssh_key="y"
    else
        do_ssh_key="n"
    fi

    # 禁止 root 登录
    local do_disable_root
    if confirm "3. 禁止 root 远程登录？"; then
        do_disable_root="y"
    else
        do_disable_root="n"
    fi

    # 禁止密码登录
    local do_disable_passwd
    if confirm "4. 禁止密码登录？"; then
        do_disable_passwd="y"
    else
        do_disable_passwd="n"
    fi

    # SSH 安全参数
    local do_ssh_params
    if confirm "5. SSH 安全参数配置？"; then
        do_ssh_params="y"
    else
        do_ssh_params="n"
    fi

    echo ""

    # ═══════════════════════════════════════════
    # 防火墙配置
    # ═══════════════════════════════════════════

    echo -e "${GREEN}[防火墙]${NC}"

    # 防火墙配置
    local do_firewall="y"
    if confirm "6. 防火墙配置 (UFW/firewalld)？"; then
        do_firewall="y"
    else
        do_firewall="n"
    fi

    # HTTP/HTTPS 端口
    local do_http="n"
    if [[ "$do_firewall" == "y" ]]; then
        if confirm "   开放 HTTP/HTTPS (80/443) 端口？"; then
            do_http="y"
        fi
    fi

    # ICMP ping
    local do_icmp="n"
    if [[ "$do_firewall" == "y" ]]; then
        if confirm "   允许 ping (ICMP)？"; then
            do_icmp="y"
        fi
    fi

    echo ""

    # ═══════════════════════════════════════════
    # Fail2Ban 配置
    # ═══════════════════════════════════════════

    echo -e "${GREEN}[入侵防护]${NC}"

    # Fail2Ban 配置
    local do_fail2ban="y"
    if confirm "7. Fail2Ban 安装与配置？"; then
        do_fail2ban="y"
    else
        do_fail2ban="n"
    fi

    echo ""

    # 检查是否至少选择了一项
    if [[ "${do_ssh_port}" == "n" && "${do_ssh_key}" == "n" && "${do_disable_root}" == "n" && "${do_disable_passwd}" == "n" && "${do_ssh_params}" == "n" && "${do_firewall}" == "n" && "${do_fail2ban}" == "n" ]]; then
        log_warn "未选择任何任务"
        return 0
    fi

    # 执行选中的 SSH 任务
    if [[ "${do_ssh_port}" == "y" || "${do_ssh_key}" == "y" || "${do_disable_root}" == "y" || "${do_disable_passwd}" == "y" || "${do_ssh_params}" == "y" ]]; then
        run_ssh_hardening_custom "${do_ssh_port}" "${do_ssh_key}" "${do_disable_root}" "${do_disable_passwd}" "${do_ssh_params}" || {
            log_error "SSH 加固失败"
            return 1
        }
    fi

    # 执行防火墙配置
    if [[ "${do_firewall}" == "y" ]]; then
        run_firewall_hardening_custom "${do_http}" "${do_icmp}" || {
            log_error "防火墙配置失败"
            return 1
        }
    fi

    # 执行 Fail2Ban 配置
    if [[ "${do_fail2ban}" == "y" ]]; then
        run_fail2ban_hardening || {
            log_error "Fail2Ban 配置失败"
            return 1
        }
    fi

    return 0
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

    # 显示欢迎信息
    show_welcome

    # 系统检测
    run_detection || {
        log_warn "System detection completed with warnings"
        log_warn "Some features may not work correctly on this system"
    }

    # 显示检测摘要
    print_detection_summary

    # 显示执行方式菜单
    show_execution_mode_menu

    # 获取执行方式
    local mode
    mode=$(get_execution_mode)

    log_info "Selected mode: ${mode}"

    # 执行任务
    local rc=0
    case "${mode}" in
        "quick")  run_quick_start  || rc=$? ;;
        "custom") run_custom_config || rc=$? ;;
        *)        log_error "未知的执行模式: ${mode}" ; rc=1 ;;
    esac

    # 仅在成功时生成报告，失败时跳过
    if [[ ${rc} -eq 0 ]]; then
        generate_report
    else
        log_error "任务执行失败（exit code: ${rc}），跳过报告生成"
    fi

    # 清理 bootstrap 临时目录（如果存在）
    if [[ -n "${_CLEANUP_DIR:-}" ]] && [[ -d "${_CLEANUP_DIR}" ]]; then
        rm -rf "${_CLEANUP_DIR}" 2>/dev/null || true
        log_debug "Cleaned up bootstrap temp directory: ${_CLEANUP_DIR}"
    fi

    # 完成
    echo ""
    log_title "${MSG_FINISH}"
    log_info "${MSG_FINISH_HINT}"
    echo ""

    exit "${rc}"
}

# ═══════════════════════════════════════════
# 脚本入口
# ═══════════════════════════════════════════

# 执行主流程
main "$@"

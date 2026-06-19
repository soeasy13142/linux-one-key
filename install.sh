#!/usr/bin/env bash
# install.sh - Linux 安全加固脚本主入口
# 支持 curl 管道执行：curl -fsSL https://xxx/install.sh | bash

set -eo pipefail
# 注意: 不使用 -u (nounset)，因为 curl 管道模式下 BASH_SOURCE 未绑定

# ═══════════════════════════════════════════
# GitHub 仓库配置
# ═══════════════════════════════════════════

GITHUB_REPO="soeasy13142/linux-one-key"
GITHUB_BRANCH="main"
# 使用 API URL 避免 CDN 缓存问题
GITHUB_API_URL="https://api.github.com/repos/${GITHUB_REPO}/contents"

# ═══════════════════════════════════════════
# 脚本目录解析 (支持 curl 管道执行)
# ═══════════════════════════════════════════

# 检测是否通过 curl 管道执行
is_curl_pipe() {
    # BASH_SOURCE 为空或者是 bash 时，说明是通过管道执行
    local first_source="${BASH_SOURCE[0]:-}"
    [[ -z "$first_source" ]] || [[ "$first_source" == "bash" ]] || [[ "$first_source" == "/dev/stdin" ]]
}

# 检测是否需要下载依赖文件
needs_download() {
    # 如果 scripts 目录不存在，需要下载
    [[ ! -d "${SCRIPT_DIR}/scripts" ]]
}

# 从 GitHub 下载单个文件（使用 API 避免 CDN 缓存）
download_file() {
    local api_url="$1"
    local output_file="$2"

    # 使用 API 获取文件内容，解码 base64
    local content
    content=$(curl -fsSL "${api_url}" | python3 -c "import sys,json,base64; d=json.load(sys.stdin); print(base64.b64decode(d['content']).decode())" 2>/dev/null)

    if [[ -n "$content" ]]; then
        echo "$content" > "${output_file}"
        return 0
    else
        return 1
    fi
}

# 从 GitHub 下载文件到临时目录
download_from_github() {
    local tmp_dir="$1"
    local api_url="${GITHUB_API_URL}"

    echo "正在从 GitHub 下载脚本文件..."

    # 创建目录结构
    mkdir -p "${tmp_dir}/scripts/base"
    mkdir -p "${tmp_dir}/scripts/security"
    mkdir -p "${tmp_dir}/scripts/lang"
    mkdir -p "${tmp_dir}/config/fail2ban"

    # 下载文件列表
    local files=(
        "scripts/base/utils.sh"
        "scripts/base/detect.sh"
        "scripts/base/init.sh"
        "scripts/security/ssh.sh"
        "scripts/security/firewall.sh"
        "scripts/security/fail2ban.sh"
        "scripts/lang/zh.sh"
        "scripts/lang/en.sh"
        "config/fail2ban/jail.local"
    )

    for file in "${files[@]}"; do
        echo "  下载: ${file}"
        if ! download_file "${api_url}/${file}?ref=${GITHUB_BRANCH}" "${tmp_dir}/${file}"; then
            echo "  警告: 下载 ${file} 失败，跳过"
        fi
    done

    echo "下载完成"
}

# 获取脚本真实路径
get_script_dir() {
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
if is_curl_pipe; then
    # 通过 curl 管道执行，下载所有文件到临时目录
    SCRIPT_DIR=$(mktemp -d)
    export SCRIPT_DIR
    download_from_github "${SCRIPT_DIR}"
    # 注册退出时清理临时目录
    trap 'rm -rf "${SCRIPT_DIR}"' EXIT
else
    # 本地执行，获取脚本所在目录
    SCRIPT_DIR="$(get_script_dir)"
    export SCRIPT_DIR

    # 如果 scripts 目录不存在，尝试下载
    if needs_download; then
        echo "scripts 目录不存在，正在从 GitHub 下载..."
        download_from_github "${SCRIPT_DIR}"
    fi
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
    if ! confirm "确认执行？"; then
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
    local do_ssh_port="y"
    if confirm "1. SSH 端口修改 (22 → 2222)？"; then
        do_ssh_port="y"
    else
        do_ssh_port="n"
    fi

    # SSH 密钥生成
    local do_ssh_key="y"
    if confirm "2. SSH 密钥生成 (Ed25519)？"; then
        do_ssh_key="y"
    else
        do_ssh_key="n"
    fi

    # 禁止 root 登录
    local do_disable_root="y"
    if confirm "3. 禁止 root 远程登录？"; then
        do_disable_root="y"
    else
        do_disable_root="n"
    fi

    # 禁止密码登录
    local do_disable_passwd="y"
    if confirm "4. 禁止密码登录？"; then
        do_disable_passwd="y"
    else
        do_disable_passwd="n"
    fi

    # SSH 安全参数
    local do_ssh_params="y"
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
    case "${mode}" in
        "quick")
            run_quick_start
            ;;
        "custom")
            run_custom_config
            ;;
    esac

    # 生成报告
    generate_report

    # 完成
    echo ""
    log_title "${MSG_FINISH}"
    log_info "${MSG_FINISH_HINT}"
    echo ""
}

# ═══════════════════════════════════════════
# 脚本入口
# ═══════════════════════════════════════════

# 执行主流程
main "$@"

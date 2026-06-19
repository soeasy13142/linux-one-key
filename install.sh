#!/usr/bin/env bash
# install.sh - Linux 安全加固脚本主入口
# 支持 curl 管道执行：curl -fsSL https://xxx/install.sh | bash

set -euo pipefail

# ═══════════════════════════════════════════
# 脚本目录解析 (支持 curl 管道执行)
# ═══════════════════════════════════════════

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
SCRIPT_DIR="$(get_script_dir)"
export SCRIPT_DIR

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
    echo -e "  1. SSH 端口修改 (22 → 2222)"
    echo -e "  2. SSH 密钥生成 (Ed25519)"
    echo -e "  3. 禁止 root 远程登录"
    echo -e "  4. 禁止密码登录"
    echo -e "  5. SSH 安全参数配置"
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

    # 检查是否至少选择了一项
    if [[ "${do_ssh_port}" == "n" && "${do_ssh_key}" == "n" && "${do_disable_root}" == "n" && "${do_disable_passwd}" == "n" && "${do_ssh_params}" == "n" ]]; then
        log_warn "未选择任何任务"
        return 0
    fi

    # 执行选中的任务
    run_ssh_hardening_custom "${do_ssh_port}" "${do_ssh_key}" "${do_disable_root}" "${do_disable_passwd}" "${do_ssh_params}" || {
        log_error "SSH 加固失败"
        return 1
    }

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

# 如果是通过 curl 管道执行，需要下载完整仓库
if [[ ! -d "${SCRIPT_DIR}/scripts" ]]; then
    echo "Error: scripts directory not found"
    echo "Please clone the full repository or download all files"
    exit 1
fi

# 执行主流程
main "$@"

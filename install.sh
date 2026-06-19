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
# 菜单系统
# ═══════════════════════════════════════════

# 显示主菜单
show_menu() {
    echo -e "${BOLD}${MSG_MENU_TITLE}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MENU_BASIC}${NC}"
    echo -e "  ${GREEN}${MSG_MENU_STANDARD}${NC}"
    echo -e "  ${GREEN}${MSG_MENU_ADVANCED}${NC}"
    echo -e "  ${GREEN}${MSG_MENU_CUSTOM}${NC}"
    echo ""
}

# 获取用户选择
get_user_choice() {
    local choice

    while true; do
        choice=$(prompt_input "${MSG_MENU_CHOICE}" "2")

        case "${choice}" in
            1)
                echo "basic"
                return 0
                ;;
            2)
                echo "standard"
                return 0
                ;;
            3)
                echo "advanced"
                return 0
                ;;
            4)
                echo "custom"
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}

# ═══════════════════════════════════════════
# 任务执行
# ═══════════════════════════════════════════

# 显示任务列表 (带状态)
show_task_list() {
    local mode="$1"

    echo ""
    echo -e "${BOLD}Tasks for ${mode}:${NC}"
    echo ""

    case "${mode}" in
        "basic")
            echo -e "  ${GREEN}[✓]${NC} ${MSG_TASK_SSH}"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FIREWALL} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FAIL2BAN} (${MSG_TASK_DEV_COMING_SOON})"
            ;;
        "standard")
            echo -e "  ${GREEN}[✓]${NC} ${MSG_TASK_SSH}"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FIREWALL} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FAIL2BAN} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_USER_MGMT} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_KERNEL} (${MSG_TASK_DEV_COMING_SOON})"
            ;;
        "advanced")
            echo -e "  ${GREEN}[✓]${NC} ${MSG_TASK_SSH}"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FIREWALL} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FAIL2BAN} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_USER_MGMT} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_KERNEL} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_FILESYSTEM} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_AUDIT} (${MSG_TASK_DEV_COMING_SOON})"
            echo -e "  ${YELLOW}[~]${NC} ${MSG_TASK_SERVICES} (${MSG_TASK_DEV_COMING_SOON})"
            ;;
    esac

    echo ""
}

# 执行选定的任务
execute_tasks() {
    local mode="$1"

    log_title "Executing ${mode} hardening tasks"

    # 显示任务列表
    show_task_list "${mode}"

    # 确认执行
    if ! confirm "Start hardening?"; then
        log_info "Cancelled by user"
        return 0
    fi

    # 执行 SSH 加固 (所有模式都包含)
    run_ssh_hardening || {
        log_error "SSH hardening failed"
        return 1
    }

    # TODO: v0.2 - 添加防火墙和 Fail2Ban
    # TODO: v0.3 - 添加用户管理和内核加固

    return 0
}

# ═══════════════════════════════════════════
# 自定义模式
# ═══════════════════════════════════════════

# 自定义任务选择
custom_task_selection() {
    log_title "${MSG_MODE_CUSTOM}"

    echo "Available tasks:"
    echo ""
    echo -e "  ${GREEN}[1]${NC} ${MSG_TASK_SSH}"
    echo -e "  ${YELLOW}[2]${NC} ${MSG_TASK_FIREWALL} (${MSG_TASK_DEV_COMING_SOON})"
    echo -e "  ${YELLOW}[3]${NC} ${MSG_TASK_FAIL2BAN} (${MSG_TASK_DEV_COMING_SOON})"
    echo -e "  ${YELLOW}[4]${NC} ${MSG_TASK_USER_MGMT} (${MSG_TASK_DEV_COMING_SOON})"
    echo -e "  ${YELLOW}[5]${NC} ${MSG_TASK_KERNEL} (${MSG_TASK_DEV_COMING_SOON})"
    echo ""

    local choice
    choice=$(prompt_input "Select task" "1")

    case "${choice}" in
        1)
            run_ssh_hardening
            ;;
        *)
            log_warn "${MSG_TASK_DEV_COMING_SOON}"
            ;;
    esac
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

    # 等待用户确认
    press_enter

    # 显示菜单
    show_menu

    # 获取用户选择
    local mode
    mode=$(get_user_choice)

    log_info "Selected mode: ${mode}"

    # 执行任务
    case "${mode}" in
        "basic"|"standard"|"advanced")
            execute_tasks "${mode}"
            ;;
        "custom")
            custom_task_selection
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

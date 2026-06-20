#!/usr/bin/env bash
# ssh.sh - SSH 安全加固模块
# 修改端口、生成密钥、禁止 root/密码登录、安全参数配置

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before ssh.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly SSH_CONFIG="/etc/ssh/sshd_config"
readonly DEFAULT_SSH_PORT=2222
readonly ROLLBACK_DELAY=300  # 5 分钟

# 回滚定时器 PID 和 at job ID
ROLLBACK_PID=""
ROLLBACK_AT_JOB=""

# ═══════════════════════════════════════════
# SSH 配置备份
# ═══════════════════════════════════════════

# 备份 SSH 配置
backup_ssh_config() {
    log_step "${MSG_SSH_BACKUP}..."

    if [[ ! -f "${SSH_CONFIG}" ]]; then
        log_error "${MSG_ERROR_FILE_NOT_FOUND}: ${SSH_CONFIG}"
        return 1
    fi

    backup_file "${SSH_CONFIG}" "${MSG_SSH_BACKUP}"
}

# ═══════════════════════════════════════════
# SSH 端口修改
# ═══════════════════════════════════════════

# 验证端口号
validate_port() {
    local port="$1"

    if [[ ! "${port}" =~ ^[0-9]+$ ]]; then
        return 1
    fi

    # 使用 $((10#...)) 强制十进制，防止前导零被解释为八进制（如 022 → 18）
    local port_num=$((10#${port}))
    if [[ "${port_num}" -lt 1 || "${port_num}" -gt 65535 ]]; then
        return 1
    fi

    return 0
}

# Modify SSH port with interactive options (custom / random / skip)
change_ssh_port() {
    log_title "${MSG_SSH_PORT_TITLE}"

    local current_port
    current_port=$(get_ssh_port)
    log_info "${MSG_SSH_PORT_CURRENT}: ${current_port}"

    local new_port=""

    # Show options
    echo ""
    echo -e "${BOLD}${MSG_SSH_PORT_OPTION_TITLE}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_SSH_PORT_OPTION_CUSTOM}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_PORT_OPTION_RANDOM}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_PORT_OPTION_KEEP}${NC}"
    echo ""

    local choice
    while [[ -z "${new_port}" ]]; do
        choice=$(prompt_input "${MSG_SSH_PORT_OPTION_PROMPT}" "1")

        case "${choice}" in
            1)
                # Custom port
                while true; do
                    new_port=$(prompt_input "${MSG_SSH_PORT_PROMPT}" "${DEFAULT_SSH_PORT}")

                    if ! validate_port "${new_port}"; then
                        log_error "${MSG_SSH_PORT_INVALID}"
                        continue
                    fi

                    if [[ "${new_port}" == "${current_port}" ]]; then
                        log_info "Port unchanged, skipping"
                        return 0
                    fi

                    if check_port_in_use "${new_port}"; then
                        log_error "${MSG_SSH_PORT_IN_USE}: ${new_port}"
                        continue
                    fi

                    break
                done
                ;;
            2)
                # Random port
                while true; do
                    new_port=$(generate_random_port)
                    echo ""
                    echo -e "${GREEN}${MSG_SSH_PORT_RANDOM_GEN}${BOLD}${new_port}${NC}"
                    echo ""

                    local rand_choice
                    rand_choice=$(prompt_input "${MSG_SSH_PORT_RANDOM_ACCEPT}" "y")

                    case "${rand_choice}" in
                        y|Y|yes|YES)
                            if validate_port "${new_port}" && ! check_port_in_use "${new_port}"; then
                                break
                            else
                                log_error "${MSG_SSH_PORT_IN_USE}: ${new_port}"
                                new_port=""
                                continue
                            fi
                            ;;
                        n|N|no|NO)
                            new_port=""
                            continue
                            ;;
                        *)
                            # User typed a number — treat as custom
                            if validate_port "${rand_choice}"; then
                                if ! check_port_in_use "${rand_choice}"; then
                                    new_port="${rand_choice}"
                                    break
                                else
                                    log_error "${MSG_SSH_PORT_IN_USE}: ${rand_choice}"
                                    new_port=""
                                    continue
                                fi
                            fi
                            log_error "${MSG_SSH_PORT_INVALID}"
                            new_port=""
                            ;;
                    esac
                done
                ;;
            3)
                log_info "${MSG_SSH_PORT_SKIP}"
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done

    # Confirm the change
    local confirm_msg="${MSG_SSH_PORT_CONFIRM//\{current\}/${current_port}}"
    confirm_msg="${confirm_msg//\{new\}/${new_port}}"
    if ! confirm "${confirm_msg}" "y"; then
        log_info "Cancelled"
        return 0
    fi

    # Apply
    set_ssh_config "Port" "${new_port}"

    log_success "${MSG_SSH_PORT_SUCCESS}: ${current_port} → ${new_port}"
    echo -e "${MSG_SSH_PORT_HINT//\{port\}/${new_port}}"

    return 0
}

# ═══════════════════════════════════════════
# SSH 密钥生成
# ═══════════════════════════════════════════

# 生成 SSH 密钥对
generate_ssh_key() {
    log_title "${MSG_SSH_KEY_TITLE}"

    local key_path
    local passphrase

    # 获取密钥路径
    key_path=$(prompt_input "${MSG_SSH_KEY_PROMPT_PATH}" "$HOME/.ssh/id_ed25519")

    # 检查是否已存在
    if [[ -f "${key_path}" ]]; then
        log_warn "Key already exists: ${key_path}"
        if ! confirm "Overwrite existing key?" "n"; then
            log_info "Skipping key generation"
            return 0
        fi
    fi

    # 获取密码短语
    passphrase=$(prompt_password "${MSG_SSH_KEY_PROMPT_PASSPHRASE}")

    # 创建 .ssh 目录
    mkdir -p "$(dirname "${key_path}")"
    chmod 700 "$(dirname "${key_path}")"

    # 生成密钥
    log_step "Generating Ed25519 key pair..."

    if [[ -z "${passphrase}" ]]; then
        ssh-keygen -t ed25519 -f "${key_path}" -N "" -C "$(whoami)@$(hostname)"
    else
        ssh-keygen -t ed25519 -f "${key_path}" -N "${passphrase}" -C "$(whoami)@$(hostname)"
    fi

    log_success "${MSG_SSH_KEY_SUCCESS}: ${key_path}"

    # 添加到 authorized_keys（检查重复，避免幂等问题）
    local auth_keys="$HOME/.ssh/authorized_keys"
    if [[ -f "${key_path}.pub" ]]; then
        if grep -qF "$(cat "${key_path}.pub")" "${auth_keys}" 2>/dev/null; then
            log_info "Key already in authorized_keys, skipping"
        else
            cat "${key_path}.pub" >> "${auth_keys}"
            chmod 600 "${auth_keys}"
            log_success "${MSG_SSH_KEY_AUTHORIZED}"
        fi
    fi

    log_success "${MSG_SSH_KEY_PERMS}"

    return 0
}

# ═══════════════════════════════════════════
# 禁止 root 远程登录
# ═══════════════════════════════════════════

# 检查是否有其他可登录用户
check_other_users() {
    local current_user
    current_user=$(whoami)

    # 获取有登录 shell 的用户（排除 nologin/false/sync/shutdown/halt）
    local users
    users=$(awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ && $1 != "root" && $1 != "'"${current_user}"'" {print $1}' /etc/passwd 2>/dev/null || true)

    if [[ -z "${users}" ]]; then
        return 1  # 没有其他用户
    fi

    return 0  # 有其他用户
}

# 禁止 root 远程登录
disable_root_login() {
    log_title "${MSG_SSH_ROOT_TITLE}"

    log_info "${MSG_SSH_ROOT_DESC}"

    # 检查是否有其他用户
    if ! check_other_users; then
        log_warn "${MSG_SSH_ROOT_NO_USER}"
        log_warn "${MSG_SSH_ROOT_CREATE_USER}"
        log_info "Skipping root login disable"
        return 0
    fi

    # 风险提示
    log_warn "${MSG_SSH_ROOT_RISK}"

    # 确认
    if ! confirm "${MSG_SSH_ROOT_CONFIRM}" "y"; then
        log_info "Skipped"
        return 0
    fi

    # 修改配置
    set_ssh_config "PermitRootLogin" "no"

    log_success "${MSG_SSH_ROOT_SUCCESS}"

    return 0
}

# ═══════════════════════════════════════════
# 禁止密码登录
# ═══════════════════════════════════════════

# 检查是否有有效的 SSH 密钥
check_ssh_keys() {
    local auth_keys="$HOME/.ssh/authorized_keys"

    if [[ ! -f "${auth_keys}" ]]; then
        return 1
    fi

    if [[ ! -s "${auth_keys}" ]]; then
        return 1
    fi

    # 检查是否有有效的密钥行
    if grep -qE '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2|sk-ssh-)' "${auth_keys}"; then
        return 0
    fi

    return 1
}

# 禁止密码登录
disable_password_auth() {
    log_title "${MSG_SSH_PASSWD_TITLE}"

    log_info "${MSG_SSH_PASSWD_DESC}"

    # 检查是否有 SSH 密钥
    if ! check_ssh_keys; then
        log_warn "${MSG_SSH_PASSWD_NO_KEY}"
        log_warn "Please configure SSH keys first"
        log_info "Skipping password auth disable"
        return 0
    fi

    # 风险提示
    log_warn "${MSG_SSH_PASSWD_RISK}"

    # 确认
    if ! confirm "${MSG_SSH_PASSWD_CONFIRM}" "y"; then
        log_info "Skipped"
        return 0
    fi

    # 修改配置
    set_ssh_config "PasswordAuthentication" "no"
    set_ssh_config "PubkeyAuthentication" "yes"
    set_ssh_config "ChallengeResponseAuthentication" "no"

    # 验证配置已正确写入（防止部分失败锁住用户）
    local pass_auth
    pass_auth=$(get_ssh_config "PasswordAuthentication")
    if [[ "${pass_auth}" != "no" ]]; then
        log_error "PasswordAuthentication 配置验证失败，当前值: ${pass_auth:-未设置}"
        return 1
    fi

    log_success "${MSG_SSH_PASSWD_SUCCESS}"

    return 0
}

# ═══════════════════════════════════════════
# 其他安全参数
# ═══════════════════════════════════════════

# Configure SSH security parameters interactively
configure_ssh_params() {
    log_title "${MSG_SSH_PARAMS_TITLE}"

    echo ""
    echo -e "${BLUE}${MSG_SSH_PARAMS_CUSTOM_PROMPT}${NC}"
    echo ""

    local val

    val=$(prompt_input "${MSG_SSH_PARAMS_MAXAUTHTRIES}" "3")
    set_ssh_config "MaxAuthTries" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_LOGINGRACETIME}" "60")
    set_ssh_config "LoginGraceTime" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_CLIENTALIVEINTERVAL}" "300")
    set_ssh_config "ClientAliveInterval" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX}" "2")
    set_ssh_config "ClientAliveCountMax" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_MAXSESSIONS}" "2")
    set_ssh_config "MaxSessions" "${val}"

    # X11Forwarding always disabled (no need to ask)
    set_ssh_config "X11Forwarding" "no"

    log_success "${MSG_SSH_PARAMS_SUCCESS}"
    return 0
}

# ═══════════════════════════════════════════
# 配置验证
# ═══════════════════════════════════════════

# 验证 SSH 配置
validate_ssh_config() {
    log_step "${MSG_SSH_VALIDATE}"

    if sshd -t 2>/dev/null; then
        log_success "${MSG_SSH_VALIDATE_SUCCESS}"
        return 0
    else
        log_error "${MSG_SSH_VALIDATE_FAIL}"
        return 1
    fi
}

# 重启 SSH 服务
restart_ssh() {
    log_step "${MSG_SSH_RESTART}"

    # 检测正确的 SSH 服务名 — Ubuntu/Debian 使用 "ssh"，CentOS/RHEL 使用 "sshd"
    local ssh_service="ssh"
    if systemctl list-units --type=service 2>/dev/null | grep -q "^sshd\."; then
        ssh_service="sshd"
    fi

    if restart_service "${ssh_service}"; then
        log_success "${MSG_SSH_RESTART_SUCCESS}"
        return 0
    else
        log_error "${MSG_SSH_RESTART_FAIL}"
        return 1
    fi
}

# ═══════════════════════════════════════════
# 回滚保护
# ═══════════════════════════════════════════

# 回滚 SSH 配置
rollback_ssh() {
    log_warn "${MSG_SSH_ROLLBACK_EXEC}"

    # 查找最新的备份
    local latest_backup
    latest_backup=$(find "${BACKUP_DIR}" -name "sshd_config.bak.*" -type f 2>/dev/null | sort -r | head -1)

    if [[ -z "${latest_backup}" ]]; then
        log_error "No backup found for rollback"
        return 1
    fi

    # 恢复配置
    restore_file "${latest_backup}" "${SSH_CONFIG}" "Rolling back SSH config"

    # 重启服务
    restart_ssh

    log_success "${MSG_SSH_ROLLBACK_SUCCESS}"
}

# 设置回滚定时器
setup_rollback_timer() {
    log_step "${MSG_SSH_ROLLBACK_TIMER}"
    log_info "${MSG_SSH_ROLLBACK_HINT}"

    # 使用 at 命令设置定时任务
    if command_exists at; then
        local at_output
        at_output=$(echo "bash -c 'source ${SCRIPT_DIR}/scripts/base/utils.sh && source ${SCRIPT_DIR}/scripts/security/ssh.sh && rollback_ssh'" | at now + 5 minutes 2>&1)
        # 提取 at job ID（兼容不同系统的输出格式）
        ROLLBACK_AT_JOB=$(echo "${at_output}" | awk '{for(i=1;i<=NF;i++) if($i=="job") print $(i+1); exit}')
        log_success "${MSG_SSH_ROLLBACK_CRON} (at job: ${ROLLBACK_AT_JOB:-unknown})"
    else
        # 如果 at 不可用，使用后台进程
        # 注意：不使用命令替换捕获 PID（避免子 shell 竞态），通过全局变量 _SCHEDULED_PID 传递
        schedule_rollback "${ROLLBACK_DELAY}" "rollback_ssh" "${MSG_SSH_ROLLBACK_TIMER}"
        ROLLBACK_PID="${_SCHEDULED_PID:-}"
        log_success "${MSG_SSH_ROLLBACK_CRON} (PID: ${ROLLBACK_PID})"
    fi
}

# 取消回滚定时器
cancel_rollback_timer() {
    if [[ -n "${ROLLBACK_PID:-}" ]]; then
        cancel_scheduled_task "${ROLLBACK_PID}"
        log_success "${MSG_SSH_ROLLBACK_CANCEL}"
    fi
    if [[ -n "${ROLLBACK_AT_JOB:-}" ]]; then
        atrm "${ROLLBACK_AT_JOB}" 2>/dev/null || true
        log_success "${MSG_SSH_ROLLBACK_CANCEL} (at job: ${ROLLBACK_AT_JOB})"
    fi
}

# ═══════════════════════════════════════════
# 主 SSH 加固流程
# ═══════════════════════════════════════════

# 执行 SSH 安全加固 (向导模式 - 执行所有任务)
run_ssh_wizard() {
    log_title "${MSG_SSH_START}"

    # 检查是否为 root
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 备份配置
    backup_ssh_config || return 1

    # 修改 SSH 端口
    change_ssh_port || return 1

    # 生成 SSH 密钥
    generate_ssh_key || return 1

    # 禁止 root 远程登录
    disable_root_login || return 1

    # 禁止密码登录
    disable_password_auth || return 1

    # 配置其他安全参数
    configure_ssh_params || return 1

    # 验证配置
    validate_ssh_config || return 1

    # 设置回滚保护
    setup_rollback_timer

    # 重启 SSH 服务
    if restart_ssh; then
        # SSH 重启成功，取消回滚定时器
        cancel_rollback_timer
    else
        # SSH 重启失败，取消回滚定时器（避免无意义的二次回滚）
        cancel_rollback_timer
        return 1
    fi

    log_separator
    log_success "${MSG_SSH_COMPLETE}"

    # 提示用户
    log_warn "${MSG_WARN_CONNECTION}"
    log_warn "${MSG_WARN_SAVE_KEY}"
    log_warn "${MSG_WARN_TEST_FIRST}"

    # 提示手动关闭 22 端口
    local final_port
    final_port=$(get_ssh_port)
    if [[ "${final_port}" != "22" ]]; then
        echo ""
        log_warn "${MSG_FIREWALL_SSH_PORT22_WARN}"
        log_warn "${MSG_FIREWALL_SSH_PORT22_CLOSE}"
    fi

    return 0
}

# 标记 ssh.sh 已加载
readonly _SSH_LOADED=1

log_debug "ssh.sh loaded successfully"

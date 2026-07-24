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
readonly ROLLBACK_DELAY=300  # 5 分钟（PRD §6.3），为管理员在修改 SSH 后验证连接提供 5 分钟窗口期

# 回滚定时器 PID 和 at job ID
ROLLBACK_PID=""
ROLLBACK_AT_JOB=""
ROLLBACK_SENTINEL=""
ROLLBACK_MONITOR_PID=""

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
                        log_info "${MSG_SSH_PORT_UNCHANGED}"
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
        log_info "${MSG_SSH_PORT_CANCELLED}"
        return 0
    fi

    # Apply
    if ! set_ssh_config "Port" "${new_port}"; then
        log_error "${MSG_SSH_PORT_FAIL}"
        return 1
    fi

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
        local _key_exists_msg="${MSG_SSH_KEY_EXISTS//\{path\}/${key_path}}"
        log_warn "${_key_exists_msg}"
        if ! confirm "${MSG_SSH_KEY_OVERWRITE}" "n"; then
            log_info "${MSG_SSH_KEY_SKIP}"
            return 0
        fi
    fi

    # 获取密码短语（通过 _PROMPT_RESULT 全局变量传递，避免 stdout 泄露）
    prompt_password "${MSG_SSH_KEY_PROMPT_PASSPHRASE}"
    passphrase="${_PROMPT_RESULT}"

    # 创建 .ssh 目录
    mkdir -p "$(dirname "${key_path}")"
    chmod 700 "$(dirname "${key_path}")"

    # 生成密钥
    log_step "${MSG_SSH_KEY_GENERATING}"

    if [[ -z "${passphrase}" ]]; then
        ssh-keygen -t ed25519 -f "${key_path}" -N "" -C "$(whoami)@$(hostname)"
    else
        # 通过 SSH_ASKPASS 传递密码，避免 -N 参数在进程列表（/proc/pid/cmdline）中可见
        local _askpass_script
        _askpass_script=$(mktemp /tmp/.ssh-askpass-XXXXXX)
        printf '#!/bin/sh\necho %q\n' "${passphrase}" > "${_askpass_script}"
        chmod 700 "${_askpass_script}"
        if SSH_ASKPASS="${_askpass_script}" SSH_ASKPASS_REQUIRE=force \
            ssh-keygen -t ed25519 -f "${key_path}" -N "" -C "$(whoami)@$(hostname)" < /dev/null; then
            rm -f "${_askpass_script}"
        else
            rm -f "${_askpass_script}"
            # 回退：不使用 SSH_ASKPASS_REQUIRE（兼容旧版 OpenSSH < 8.4）
            # 避免使用 -N 参数（passphrase 会暴露在 /proc/pid/cmdline 中）
            _askpass_script=$(mktemp /tmp/.ssh-askpass-XXXXXX)
            printf '#!/bin/sh\necho %q\n' "${passphrase}" > "${_askpass_script}"
            chmod 700 "${_askpass_script}"
            if SSH_ASKPASS="${_askpass_script}" \
                ssh-keygen -t ed25519 -f "${key_path}" -N "" -C "$(whoami)@$(hostname)" < /dev/null; then
                rm -f "${_askpass_script}"
            else
                rm -f "${_askpass_script}"
                # 最终回退：交互式提示（避免 -N 参数泄露到 /proc/pid/cmdline）
                log_warn "SSH_ASKPASS 不可用，请手动输入密码短语..."
                ssh-keygen -t ed25519 -f "${key_path}" -C "$(whoami)@$(hostname)"
            fi
        fi
    fi

    log_success "${MSG_SSH_KEY_SUCCESS}: ${key_path}"

    # 添加到 authorized_keys（检查重复，避免幂等问题）
    local auth_keys="$HOME/.ssh/authorized_keys"
    local auth_ok=true
    if [[ -f "${key_path}.pub" ]]; then
        if grep -qF "$(cat "${key_path}.pub")" "${auth_keys}" 2>/dev/null; then
            log_info "${MSG_SSH_KEY_ALREADY_AUTHORIZED}"
        else
            if cat "${key_path}.pub" >> "${auth_keys}" 2>/dev/null && chmod 600 "${auth_keys}" 2>/dev/null; then
                log_success "${MSG_SSH_KEY_AUTHORIZED}"
            else
                log_warn "${MSG_SSH_KEY_AUTHORIZED_FAIL}"
                auth_ok=false
            fi
        fi
    fi

    if [[ "${auth_ok}" == true ]]; then
        log_success "${MSG_SSH_KEY_PERMS}"
    fi

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

    # 检查这些用户是否有 SSH 密钥（无密钥用户在禁用密码登录后将无法登录）
    local users_without_keys
    users_without_keys=$(_check_all_users_ssh_keys) || true
    if [[ -n "${users_without_keys}" ]]; then
        log_warn "${MSG_SSH_USERS_NO_KEYS}"
        while IFS= read -r user; do
            [[ -z "${user}" ]] && continue
            log_warn "  - ${user}"
        done <<< "${users_without_keys}"
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
        log_info "${MSG_SSH_ROOT_SKIP}"
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
    if ! set_ssh_config "PermitRootLogin" "no"; then
        log_error "${MSG_SSH_ROOT_FAIL}"
        return 1
    fi

    log_success "${MSG_SSH_ROOT_SUCCESS}"

    return 0
}

# ═══════════════════════════════════════════
# 禁止密码登录
# ═══════════════════════════════════════════

# 检查单个用户的 authorized_keys 是否有有效密钥
# 参数: $1 = authorized_keys 文件路径
# 返回: 0 = 有有效密钥, 1 = 无有效密钥
_has_valid_ssh_key() {
    local auth_keys="$1"

    if [[ ! -f "${auth_keys}" ]] || [[ ! -s "${auth_keys}" ]]; then
        return 1
    fi

    if grep -qE '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2|sk-ssh-)' "${auth_keys}"; then
        return 0
    fi

    return 1
}

# 检查当前用户是否有有效的 SSH 密钥
check_ssh_keys() {
    _has_valid_ssh_key "$HOME/.ssh/authorized_keys"
}

# 检查所有可登录用户是否有 SSH 密钥
# 输出: 无密钥的用户名列表（每行一个）
# 返回: 0 = 所有用户都有密钥, 1 = 存在无密钥用户
_check_all_users_ssh_keys() {
    local current_user
    current_user=$(whoami)
    local users_without_keys=""

    # 获取所有有登录 shell 的用户（排除 nologin/false/sync/shutdown/halt）
    while IFS= read -r user; do
        [[ -z "${user}" ]] && continue

        local user_home
        user_home=$(getent passwd "${user}" 2>/dev/null | cut -d: -f6)
        if [[ -z "${user_home}" ]]; then
            continue
        fi

        local auth_keys="${user_home}/.ssh/authorized_keys"
        if ! _has_valid_ssh_key "${auth_keys}"; then
            users_without_keys="${users_without_keys}${user}\n"
        fi
    done < <(awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ && $1 != "'"${current_user}"'" {print $1}' /etc/passwd 2>/dev/null || true)

    if [[ -n "${users_without_keys}" ]]; then
        echo -e "${users_without_keys}" | sed '/^$/d'
        return 1
    fi

    return 0
}

# 禁止密码登录
disable_password_auth() {
    log_title "${MSG_SSH_PASSWD_TITLE}"

    log_info "${MSG_SSH_PASSWD_DESC}"

    # 检查当前用户是否有 SSH 密钥
    if ! check_ssh_keys; then
        log_warn "${MSG_SSH_PASSWD_NO_KEY}"
        log_warn "${MSG_SSH_PASSWD_CONFIGURE_KEYS}"
        log_info "${MSG_SSH_PASSWD_SKIP}"
        return 0
    fi

    # 检查其他可登录用户是否有 SSH 密钥
    local users_without_keys
    users_without_keys=$(_check_all_users_ssh_keys) || true
    if [[ -n "${users_without_keys}" ]]; then
        log_warn "${MSG_SSH_PASSWD_USERS_NO_KEYS}"
        while IFS= read -r user; do
            [[ -z "${user}" ]] && continue
            log_warn "  - ${user}"
        done <<< "${users_without_keys}"
        log_warn "${MSG_SSH_PASSWD_SETUP_KEYS_HINT}"
        if ! confirm "${MSG_SSH_PASSWD_CONTINUE_ANYWAY}" "n"; then
            log_info "${MSG_SSH_PASSWD_SKIP}"
            return 0
        fi
    fi

    # 风险提示
    log_warn "${MSG_SSH_PASSWD_RISK}"

    # 确认
    if ! confirm "${MSG_SSH_PASSWD_CONFIRM}" "y"; then
        log_info "Skipped"
        return 0
    fi

    # 修改配置（set_ssh_config 内部已有写后验证）
    if ! set_ssh_config "PasswordAuthentication" "no"; then
        log_error "${MSG_SSH_PASSWD_SET_FAIL//\{param\}/PasswordAuthentication}"
        return 1
    fi
    if ! set_ssh_config "PubkeyAuthentication" "yes"; then
        log_error "${MSG_SSH_PASSWD_SET_FAIL//\{param\}/PubkeyAuthentication}"
        return 1
    fi
    if ! set_ssh_config "ChallengeResponseAuthentication" "no"; then
        log_error "${MSG_SSH_PASSWD_SET_FAIL//\{param\}/ChallengeResponseAuthentication}"
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
    local failed=0

    local _param_err

    val=$(prompt_input "${MSG_SSH_PARAMS_MAXAUTHTRIES}" "3")
    if [[ ! "${val}" =~ ^[0-9]+$ ]] || [[ "${val}" -lt 1 ]] || [[ "${val}" -gt 100 ]]; then
        _param_err="${MSG_SSH_PARAMS_INVALID//\{param\}/MaxAuthTries}"
        _param_err="${_param_err//\{range\}/1-100}"
        _param_err="${_param_err//\{default\}/3}"
        log_error "${_param_err}"
        val="3"
    fi
    if ! set_ssh_config "MaxAuthTries" "${val}"; then
        failed=$((failed + 1))
    fi

    val=$(prompt_input "${MSG_SSH_PARAMS_LOGINGRACETIME}" "60")
    if [[ ! "${val}" =~ ^[0-9]+$ ]] || [[ "${val}" -lt 1 ]] || [[ "${val}" -gt 3600 ]]; then
        _param_err="${MSG_SSH_PARAMS_INVALID//\{param\}/LoginGraceTime}"
        _param_err="${_param_err//\{range\}/1-3600}"
        _param_err="${_param_err//\{default\}/60}"
        log_error "${_param_err}"
        val="60"
    fi
    if ! set_ssh_config "LoginGraceTime" "${val}"; then
        failed=$((failed + 1))
    fi

    val=$(prompt_input "${MSG_SSH_PARAMS_CLIENTALIVEINTERVAL}" "300")
    if [[ ! "${val}" =~ ^[0-9]+$ ]] || [[ "${val}" -lt 1 ]] || [[ "${val}" -gt 86400 ]]; then
        _param_err="${MSG_SSH_PARAMS_INVALID//\{param\}/ClientAliveInterval}"
        _param_err="${_param_err//\{range\}/1-86400}"
        _param_err="${_param_err//\{default\}/300}"
        log_error "${_param_err}"
        val="300"
    fi
    if ! set_ssh_config "ClientAliveInterval" "${val}"; then
        failed=$((failed + 1))
    fi

    val=$(prompt_input "${MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX}" "2")
    if [[ ! "${val}" =~ ^[0-9]+$ ]] || [[ "${val}" -lt 1 ]] || [[ "${val}" -gt 100 ]]; then
        _param_err="${MSG_SSH_PARAMS_INVALID//\{param\}/ClientAliveCountMax}"
        _param_err="${_param_err//\{range\}/1-100}"
        _param_err="${_param_err//\{default\}/2}"
        log_error "${_param_err}"
        val="2"
    fi
    if ! set_ssh_config "ClientAliveCountMax" "${val}"; then
        failed=$((failed + 1))
    fi

    val=$(prompt_input "${MSG_SSH_PARAMS_MAXSESSIONS}" "2")
    if [[ ! "${val}" =~ ^[0-9]+$ ]] || [[ "${val}" -lt 1 ]] || [[ "${val}" -gt 100 ]]; then
        _param_err="${MSG_SSH_PARAMS_INVALID//\{param\}/MaxSessions}"
        _param_err="${_param_err//\{range\}/1-100}"
        _param_err="${_param_err//\{default\}/2}"
        log_error "${_param_err}"
        val="2"
    fi
    if ! set_ssh_config "MaxSessions" "${val}"; then
        failed=$((failed + 1))
    fi

    # X11Forwarding always disabled (no need to ask)
    if ! set_ssh_config "X11Forwarding" "no"; then
        failed=$((failed + 1))
    fi

    if [[ "${failed}" -gt 0 ]]; then
        _param_err="${MSG_SSH_PARAMS_FAIL//\{count\}/${failed}}"
        log_error "${_param_err}"
        return 1
    fi

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
# SSH 锁定防护增强（Full 模式专用）
# ═══════════════════════════════════════════

# 重启 SSH 服务并测试新端口是否可用
# 仅在 Full 模式下调用，Lite 模式使用 restart_ssh
_restart_and_test_ssh() {
    restart_ssh || return 1

    # 等待服务就绪
    local port
    port=$(get_ssh_port)
    local max_wait=15
    local waited=0
    while [[ ${waited} -lt ${max_wait} ]]; do
        if ss -tlnp 2>/dev/null | grep -qE ":${port}[[:space:]]"; then
            break
        fi
        sleep 1
        ((waited++))
    done

    # 测试到 localhost 的 SSH 连接
    if ssh -p "${port}" -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
         -o BatchMode=yes localhost true 2>/dev/null; then
        log_success "${MSG_SSH_TEST_PASS//\{port\}/${port}}"
        return 0
    else
        log_warn "${MSG_SSH_TEST_FAIL//\{port\}/${port}}"
        # shellcheck disable=SC2059
        log_warn "$(printf "${MSG_SSH_TEST_INSTRUCTIONS}" "ssh -p ${port} user@host")"
        return 1
    fi
}

# 检查是否有活动的 SSH 会话
check_active_ssh_sessions() {
    local sessions
    sessions=$(ss -tnp 2>/dev/null | grep -c "ESTABLISHED.*:22[[:space:]]" || echo 0)
    if [[ "${sessions}" -gt 0 ]]; then
        log_info "Active SSH sessions detected: ${sessions}"
        return 0
    fi
    return 1
}

# 检查是否有控制台访问权限（物理/VNC）
has_console_access() {
    if [[ -c /dev/tty1 ]] || [[ -c /dev/console ]]; then
        return 0
    fi
    # 检查是否有其他 tty 终端登录
    local console_users
    console_users=$(LC_ALL=C who -a 2>/dev/null | grep -cE '(tty|console|vc/[0-9])' || echo 0)
    [[ "${console_users}" -gt 0 ]]
}

# 监控新 SSH 连接的后台进程
# 检测到新连接时创建 sentinel 文件
# 参数: $1 port 端口号, $2 duration 监控时长（秒）, $3 sentinel_file 哨兵文件路径
_monitor_ssh_connections() {
    local port="$1"
    local duration="$2"
    local sentinel_file="$3"
    local poll_interval=5

    local end_time=$(( $(date +%s) + duration ))
    while [[ $(date +%s) -lt ${end_time} ]]; do
        local count
        if command_exists ss; then
            count=$(ss -tnp 2>/dev/null | grep -cE ":${port}[[:space:]].*ESTABLISHED" || true)
        else
            count=0
        fi
        if [[ "${count}" -gt 0 ]]; then
            touch "${sentinel_file}" 2>/dev/null || true
            return 0
        fi
        sleep "${poll_interval}"
    done
    return 1
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
        log_error "${MSG_SSH_ROLLBACK_NO_BACKUP}"
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
        at_output=$(echo "bash -c 'source ${SCRIPT_DIR}/scripts/base/utils.sh && source ${SCRIPT_DIR}/scripts/security/ssh.sh && rollback_ssh'" | at now + $(( ROLLBACK_DELAY / 60 )) minutes 2>&1)
        # 提取 at job ID（兼容不同系统的输出格式）
        ROLLBACK_AT_JOB=$(echo "${at_output}" | awk '{for(i=1;i<=NF;i++) if($i=="job") print $(i+1); exit}')
        log_success "${MSG_SSH_ROLLBACK_CRON} (at job: ${ROLLBACK_AT_JOB:-unknown})"
    else
        # 如果 at 不可用，使用后台进程 + 连接监控
        # 创建 sentinel 文件用于监控新连接
        local sentinel_file
        sentinel_file=$(mktemp /tmp/.ssh-monitor-XXXXXX 2>/dev/null) || sentinel_file="/tmp/.ssh-monitor-${$}-$(date +%s)"

        # 启动连接监控后台进程
        _monitor_ssh_connections "$(get_ssh_port)" "${ROLLBACK_DELAY}" "${sentinel_file}" &
        local monitor_pid=$!
        disown "${monitor_pid}" 2>/dev/null || true

        # 调度回滚
        (
            trap '' INT TERM
            sleep "${ROLLBACK_DELAY}"
            # 如果 sentinel 文件存在，表示已检测到新连接，不回滚
            if [[ -f "${sentinel_file}" ]]; then
                rm -f "${sentinel_file}"
                exit 0
            fi
            rollback_ssh
        ) &

        _SCHEDULED_PID=$!
        disown "${_SCHEDULED_PID}" 2>/dev/null || true

        ROLLBACK_PID="${_SCHEDULED_PID:-}"
        ROLLBACK_SENTINEL="${sentinel_file}"
        ROLLBACK_MONITOR_PID="${monitor_pid}"
        log_success "${MSG_SSH_ROLLBACK_CRON} (PID: ${ROLLBACK_PID})"
    fi
}

# 取消回滚定时器
cancel_rollback_timer() {
    if [[ -n "${ROLLBACK_PID:-}" ]]; then
        cancel_scheduled_task "${ROLLBACK_PID}"
    fi
    if [[ -n "${ROLLBACK_MONITOR_PID:-}" ]]; then
        kill "${ROLLBACK_MONITOR_PID}" 2>/dev/null || true
    fi
    if [[ -n "${ROLLBACK_SENTINEL:-}" ]] && [[ -f "${ROLLBACK_SENTINEL}" ]]; then
        rm -f "${ROLLBACK_SENTINEL}" 2>/dev/null || true
    fi
    if [[ -n "${ROLLBACK_AT_JOB:-}" ]]; then
        atrm "${ROLLBACK_AT_JOB}" 2>/dev/null || true
    fi
    log_success "${MSG_SSH_ROLLBACK_CANCEL}"
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

    # Full mode: pre-change safety checks
    if is_mode_full; then
        # Check active SSH sessions
        if ! check_active_ssh_sessions; then
            log_warn "${MSG_SSH_SESSION_NONE}"
            if ! confirm "${MSG_SSH_ROLLBACK_CONFIRM_PROMPT}" "n"; then
                log_info "Cancelled SSH hardening"
                return 1
            fi
        else
            log_info "${MSG_SSH_SESSION_ACTIVE}"
        fi

        # Check backup console access
        if ! has_console_access; then
            log_warn "${MSG_SSH_CONSOLE_NONE}"
            if ! confirm "${MSG_SSH_ROLLBACK_CONFIRM_PROMPT}" "n"; then
                log_info "Cancelled SSH hardening"
                return 1
            fi
        else
            log_info "${MSG_SSH_CONSOLE_AVAILABLE}"
        fi
    fi

    # 记录配置文件原始 mtime，用于检测向导期间的外部修改
    local _config_file="/etc/ssh/sshd_config"
    local _original_mtime=""
    if [[ -f "${_config_file}" ]]; then
        _original_mtime=$(stat -c '%Y' "${_config_file}" 2>/dev/null || stat -f '%m' "${_config_file}" 2>/dev/null || echo "")
    fi

    # 备份配置
    backup_ssh_config || return 1

    # 修改 SSH 端口
    change_ssh_port || return 1

    # 生成 SSH 密钥
    generate_ssh_key || return 1

    # 禁止密码登录
    disable_password_auth || return 1

    # 禁止 root 远程登录
    disable_root_login || return 1

    # 配置其他安全参数
    configure_ssh_params || return 1

    # 验证配置
    validate_ssh_config || return 1

    # 检查配置文件是否在向导期间被外部修改
    if [[ -n "${_original_mtime}" ]] && [[ -f "${_config_file}" ]]; then
        local _current_mtime
        _current_mtime=$(stat -c '%Y' "${_config_file}" 2>/dev/null || stat -f '%m' "${_config_file}" 2>/dev/null || echo "")
        if [[ "${_current_mtime}" != "${_original_mtime}" ]]; then
            log_warn "${MSG_SSH_WIZARD_EXTERNAL_MOD}"
            log_warn "${MSG_SSH_WIZARD_ROLLBACK_OVERWRITE}"
        fi
    fi

    # 重启 SSH 服务
    if is_mode_full; then
        # Full 模式：使用增强的连接测试 + 连接监控
        if _restart_and_test_ssh; then
            log_success "${MSG_SSH_TEST_CONNECTION}"
            setup_rollback_timer
            log_info "${MSG_SSH_TEST_CONFIRM}"
        else
            setup_rollback_timer
            log_info "${MSG_SSH_TEST_WAITING}"
        fi
    else
        # Lite 模式：保持原有简化流程
        if restart_ssh; then
            log_success "${MSG_SSH_RESTART_SUCCESS}"
        else
            local _rollback_err="${MSG_SSH_RESTART_FAIL_ROLLBACK//\{delay\}/${ROLLBACK_DELAY}}"
            log_error "${_rollback_err}"
            setup_rollback_timer
            return 1
        fi
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

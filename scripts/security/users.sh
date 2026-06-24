#!/usr/bin/env bash
# ============================================================================
# users.sh - 用户管理模块
# 创建管理员用户、配置密码、SSH密钥、sudo免密
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before users.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================
readonly USER_SUDO_GROUP_DEBIAN="sudo"
readonly USER_SUDO_GROUP_RHEL="wheel"
readonly USER_MIN_NAME_LEN=3
readonly USER_MAX_NAME_LEN=32
readonly USER_MIN_PASS_LEN=8

# ============================================================================
# 内部函数
# ============================================================================

# 检测 sudo/wheel 组名
_check_sudo_group() {
    case "${DETECTED_OS}" in
        ubuntu|debian)
            echo "${USER_SUDO_GROUP_DEBIAN}"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            echo "${USER_SUDO_GROUP_RHEL}"
            ;;
        *)
            echo "${USER_SUDO_GROUP_DEBIAN}"
            ;;
    esac
}

# 验证用户名合法性
# 规则：字母或下划线开头，仅含字母数字下划线，3-32字符
validate_username() {
    local username="$1"

    if [[ ${#username} -lt ${USER_MIN_NAME_LEN} || ${#username} -gt ${USER_MAX_NAME_LEN} ]]; then
        log_error "${MSG_USERS_NAME_TOO_SHORT}"
        return 1
    fi

    if [[ ! "${username}" =~ ^[a-z_][a-z0-9_-]*$ ]]; then
        log_error "${MSG_USERS_NAME_INVALID}"
        return 1
    fi

    return 0
}

# 检查用户是否已存在
_user_exists() {
    local username="$1"
    id "${username}" &>/dev/null
}

# 检查密码强度（基本检查：长度 >= 8）
_validate_password_strength() {
    local password="$1"

    if [[ ${#password} -lt ${USER_MIN_PASS_LEN} ]]; then
        log_error "${MSG_USERS_PASS_TOO_SHORT}"
        return 1
    fi

    return 0
}

# ============================================================================
# 公共函数
# ============================================================================

# 创建管理员用户
create_admin_user() {
    log_title "${MSG_USERS_CREATE_TITLE}"

    local username
    username=$(prompt_input "${MSG_USERS_ENTER_USERNAME}")

    if [[ -z "${username}" ]]; then
        log_error "${MSG_USERS_NAME_EMPTY}"
        return 1
    fi

    if ! validate_username "${username}"; then
        return 1
    fi

    if _user_exists "${username}"; then
        log_warn "${MSG_USERS_ALREADY_EXISTS}: ${username}"
        echo "${username}"
        return 0
    fi

    local sudo_group
    sudo_group=$(_check_sudo_group)

    log_step "${MSG_USERS_CREATING}: ${username} (group: ${sudo_group})..."

    # 创建用户并添加到 sudo 组
    if ! useradd -m -s /bin/bash "${username}" >> "${LOG_FILE}" 2>&1; then
        log_error "${MSG_USERS_CREATE_FAILED}"
        return 1
    fi

    # 添加到 sudo/wheel 组
    if ! usermod -aG "${sudo_group}" "${username}" >> "${LOG_FILE}" 2>&1; then
        log_warn "${MSG_USERS_SUDO_ADD_FAILED}: ${sudo_group}"
    fi

    log_success "${MSG_USERS_CREATE_DONE}: ${username} (${sudo_group})"
    echo "${username}"
    return 0
}

# 设置用户密码
set_user_password() {
    local username="${1:-}"
    local title="${2:-${MSG_USERS_SET_PASS_TITLE}}"

    log_title "${title}"

    if [[ -z "${username}" ]]; then
        username=$(prompt_input "${MSG_USERS_ENTER_USERNAME_PASS}")
    fi

    if ! _user_exists "${username}"; then
        log_error "${MSG_USERS_NOT_FOUND}: ${username}"
        return 1
    fi

    local password
    password=$(prompt_password "${MSG_USERS_ENTER_PASS}")

    if ! _validate_password_strength "${password}"; then
        return 1
    fi

    local password_confirm
    password_confirm=$(prompt_password "${MSG_USERS_CONFIRM_PASS}")

    if [[ "${password}" != "${password_confirm}" ]]; then
        log_error "${MSG_USERS_PASS_MISMATCH}"
        return 1
    fi

    log_step "${MSG_USERS_SETTING_PASS}: ${username}..."

    if echo "${username}:${password}" | chpasswd >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_USERS_PASS_SET_DONE}: ${username}"
        return 0
    else
        log_error "${MSG_USERS_PASS_SET_FAILED}"
        return 1
    fi
}

# 为用户生成 SSH 密钥
setup_user_ssh_key() {
    local username="${1:-}"

    log_title "${MSG_USERS_SSH_KEY_TITLE}"

    if [[ -z "${username}" ]]; then
        username=$(prompt_input "${MSG_USERS_ENTER_USERNAME_SSH}")
    fi

    if ! _user_exists "${username}"; then
        log_error "${MSG_USERS_NOT_FOUND}: ${username}"
        return 1
    fi

    local user_home
    user_home=$(getent passwd "${username}" 2>/dev/null | cut -d: -f6)
    user_home="${user_home:-/home/${username}}"

    local ssh_dir="${user_home}/.ssh"
    local key_file="${ssh_dir}/id_ed25519"
    local auth_file="${ssh_dir}/authorized_keys"

    # 检查是否已存在密钥
    if [[ -f "${key_file}" ]]; then
        log_warn "${MSG_USERS_SSH_KEY_EXISTS}: ${key_file}"
        if ! confirm "${MSG_USERS_SSH_KEY_OVERWRITE}" "n"; then
            log_info "${MSG_USERS_SSH_KEY_SKIPPED}"
            return 0
        fi
    fi

    log_step "${MSG_USERS_SSH_KEY_GENERATING}..."

    # 创建 .ssh 目录
    mkdir -p "${ssh_dir}" >> "${LOG_FILE}" 2>&1

    # 生成 Ed25519 密钥对（无 passphrase，用于服务器登录）
    if ! ssh-keygen -t ed25519 -f "${key_file}" -N "" -C "${username}@$(hostname)" >> "${LOG_FILE}" 2>&1; then
        log_error "${MSG_USERS_SSH_KEY_FAILED}"
        return 1
    fi

    # 添加公钥到 authorized_keys
    cat "${key_file}.pub" >> "${auth_file}" >> "${LOG_FILE}" 2>&1

    # 设置权限
    chmod 700 "${ssh_dir}"
    chmod 600 "${key_file}"
    chmod 600 "${auth_file}"
    chown -R "${username}:${username}" "${ssh_dir}"

    log_success "${MSG_USERS_SSH_KEY_DONE}: ${key_file}"
    log_info "${MSG_USERS_SSH_KEY_HINT}"

    return 0
}

# 配置 sudo NOPASSWD
configure_sudo_nopasswd() {
    local username="${1:-}"

    log_title "${MSG_USERS_SUDO_TITLE}"

    if [[ -z "${username}" ]]; then
        username=$(prompt_input "${MSG_USERS_ENTER_USERNAME_SUDO}")
    fi

    if ! _user_exists "${username}"; then
        log_error "${MSG_USERS_NOT_FOUND}: ${username}"
        return 1
    fi

    local sudo_group
    sudo_group=$(_check_sudo_group)

    # 检查用户是否已在 sudo 组
    if ! id -nG "${username}" 2>/dev/null | grep -qw "${sudo_group}"; then
        log_warn "${MSG_USERS_NOT_IN_SUDO}: ${sudo_group}"
        if confirm "${MSG_USERS_ADD_TO_SUDO}" "y"; then
            usermod -aG "${sudo_group}" "${username}" >> "${LOG_FILE}" 2>&1
            log_success "${MSG_USERS_ADDED_TO_SUDO}: ${sudo_group}"
        fi
    fi

    local sudoers_file="/etc/sudoers.d/${username}"

    # 检查是否已配置
    if [[ -f "${sudoers_file}" ]]; then
        log_warn "${MSG_USERS_SUDO_ALREADY_CONFIGURED}: ${sudoers_file}"
        return 0
    fi

    log_step "${MSG_USERS_SUDO_CONFIGURING}..."

    # 创建 sudoers drop-in 文件
    echo "${username} ALL=(ALL) NOPASSWD: ALL" > "${sudoers_file}"
    chmod 440 "${sudoers_file}"

    # 验证语法
    if ! visudo -cf "${sudoers_file}" >> "${LOG_FILE}" 2>&1; then
        log_error "${MSG_USERS_SUDO_SYNTAX_ERROR}"
        rm -f "${sudoers_file}"
        return 1
    fi

    log_success "${MSG_USERS_SUDO_DONE}: ${username}"
    log_warn "${MSG_USERS_SUDO_SECURITY_HINT}"

    return 0
}

# ============================================================================
# 用户管理向导
# ============================================================================

run_users_wizard() {
    log_title "${MSG_USERS_WIZARD_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_USERS_WIZARD_DESC}${NC}"
    echo ""

    # 确认开始
    if ! confirm "${MSG_USERS_WIZARD_START}" "y"; then
        log_info "${MSG_USERS_WIZARD_SKIPPED}"
        return 0
    fi

    local wizard_rc=0
    local created_user=""

    # ── Step 1: 创建用户 ──
    echo ""
    log_title "${MSG_USERS_STEP_CREATE}"

    if confirm "${MSG_USERS_STEP_CREATE_CONFIRM}" "y"; then
        local username
        username=$(prompt_input "${MSG_USERS_ENTER_USERNAME}")

        if [[ -z "${username}" ]]; then
            log_error "${MSG_USERS_NAME_EMPTY}"
            wizard_rc=1
        elif ! validate_username "${username}"; then
            wizard_rc=1
        else
            local sudo_group
            sudo_group=$(_check_sudo_group)

            if _user_exists "${username}"; then
                log_warn "${MSG_USERS_ALREADY_EXISTS}: ${username}"
                created_user="${username}"
            else
                log_info "${MSG_USERS_WILL_CREATE}: ${username} → ${sudo_group}"
                if confirm "${MSG_USERS_CONFIRM_CREATE}" "y"; then
                    if useradd -m -s /bin/bash "${username}" >> "${LOG_FILE}" 2>&1; then
                        usermod -aG "${sudo_group}" "${username}" >> "${LOG_FILE}" 2>&1 || true
                        log_success "${MSG_USERS_CREATE_DONE}: ${username} (${sudo_group})"
                        created_user="${username}"
                    else
                        log_error "${MSG_USERS_CREATE_FAILED}"
                        wizard_rc=1
                    fi
                else
                    log_info "${MSG_USERS_CREATE_SKIPPED}"
                fi
            fi
        fi
    else
        log_info "${MSG_USERS_STEP_SKIPPED}"
    fi

    # ── Step 2: 设置密码 ──
    if [[ -n "${created_user}" ]]; then
        echo ""
        log_title "${MSG_USERS_STEP_PASS}"

        if confirm "${MSG_USERS_STEP_PASS_CONFIRM}" "y"; then
            set_user_password "${created_user}" || wizard_rc=1
        else
            log_info "${MSG_USERS_STEP_SKIPPED}"
        fi
    fi

    # ── Step 3: SSH 密钥 ──
    if [[ -n "${created_user}" ]]; then
        echo ""
        log_title "${MSG_USERS_STEP_SSH}"

        if confirm "${MSG_USERS_STEP_SSH_CONFIRM}" "y"; then
            setup_user_ssh_key "${created_user}" || wizard_rc=1
        else
            log_info "${MSG_USERS_STEP_SKIPPED}"
        fi
    fi

    # ── Step 4: sudo NOPASSWD ──
    if [[ -n "${created_user}" ]]; then
        echo ""
        log_title "${MSG_USERS_STEP_SUDO}"

        log_warn "${MSG_USERS_SUDO_SECURITY_HINT}"
        if confirm "${MSG_USERS_STEP_SUDO_CONFIRM}" "n"; then
            configure_sudo_nopasswd "${created_user}" || wizard_rc=1
        else
            log_info "${MSG_USERS_STEP_SKIPPED}"
        fi
    fi

    # ── Summary ──
    echo ""
    log_title "${MSG_USERS_SUMMARY}"
    if [[ -n "${created_user}" ]]; then
        echo -e "  ${MSG_USERS_SUMMARY_USER}: ${created_user}"
        echo -e "  ${MSG_USERS_SUMMARY_GROUP}: $(_check_sudo_group)"
        echo -e "  ${MSG_USERS_SUMMARY_HOME}: /home/${created_user}"
    else
        echo -e "  ${MSG_USERS_SUMMARY_NONE}"
    fi

    if [[ ${wizard_rc} -eq 0 ]]; then
        log_success "${MSG_USERS_WIZARD_DONE}"
    else
        log_warn "${MSG_USERS_WIZARD_DONE} ${MSG_WIZARD_ERR_HINT}"
    fi

    return ${wizard_rc}
}

# 检查用户管理状态（用于系统状态检测）
check_users_status() {
    local custom_users=0
    local sudo_users=0
    local sudo_group
    sudo_group=$(_check_sudo_group)

    # 统计非系统用户（UID >= 1000）
    custom_users=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd 2>/dev/null | wc -l | tr -d ' ')

    # 统计 sudo 组用户
    if getent group "${sudo_group}" &>/dev/null; then
        sudo_users=$(getent group "${sudo_group}" 2>/dev/null | cut -d: -f4 | tr ',' '\n' | grep -c . || echo "0")
    fi

    echo "users_custom=${custom_users}"
    echo "users_sudo_group=${sudo_group}"
    echo "users_sudo_count=${sudo_users}"
}

# 标记 users.sh 已加载
readonly _USERS_LOADED=1

log_debug "users.sh loaded successfully"

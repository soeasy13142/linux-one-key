#!/usr/bin/env bats
# sudo.bats - 单元测试 for scripts/security/sudo.sh

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    # 覆盖 sudo 配置路径，避免触碰真实系统
    export SUDOERS_DROPIN="${TEST_DIR}/etc/sudoers.d/99-linux-one-key-sudo"
    export SUDOERS_MAIN="${TEST_DIR}/etc/sudoers"
    export SUDOERS_DIR="${TEST_DIR}/etc/sudoers.d"
    export SUDO_LOG_FILE="${TEST_DIR}/var/log/sudo.log"
    export SUDO_LOGROTATE_CONF="${TEST_DIR}/etc/logrotate.d/linux-one-key-sudo"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_OS="ubuntu"

    source "${SCRIPT_DIR}/scripts/security/sudo.sh"

    export LOG_FILE="${TEST_DIR}/test.log"

    # 默认 mock visudo 成功（各测试可重定义）
    visudo() { return 0; }
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── 通用工具 ──

_get_mode() {
    stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null || echo "000"
}

_count_sudo_backups() {
    find "${BACKUP_DIR}" -maxdepth 1 -name '99-linux-one-key-sudo.bak.*' ! -name '*.meta' 2>/dev/null | wc -l | tr -d ' '
}

# ── 函数存在性 / guard ──

@test "sudo.sh loaded flag is set" {
    [[ "${_SUDO_LOADED:-}" == "1" ]]
}

@test "apply_sudo_hardening function exists" {
    [[ "$(type -t apply_sudo_hardening)" == "function" ]]
}

@test "run_sudo_wizard function exists" {
    [[ "$(type -t run_sudo_wizard)" == "function" ]]
}

@test "_write_sudoers_dropin function exists" {
    [[ "$(type -t _write_sudoers_dropin)" == "function" ]]
}

# ── 常量默认值（通过源文件验证） ──

@test "SUDOERS_DROPIN defaults to /etc/sudoers.d/99-linux-one-key-sudo" {
    grep -q 'SUDOERS_DROPIN="${SUDOERS_DROPIN:-/etc/sudoers.d/99-linux-one-key-sudo}"' \
        "${SCRIPT_DIR}/scripts/security/sudo.sh"
}

@test "SUDO_LOG_FILE defaults to /var/log/sudo.log" {
    grep -q 'SUDO_LOG_FILE="${SUDO_LOG_FILE:-/var/log/sudo.log}"' \
        "${SCRIPT_DIR}/scripts/security/sudo.sh"
}

@test "SUDOERS_TIMESTAMP_TIMEOUT defaults to 5" {
    grep -q 'SUDOERS_TIMESTAMP_TIMEOUT="${SUDOERS_TIMESTAMP_TIMEOUT:-5}"' \
        "${SCRIPT_DIR}/scripts/security/sudo.sh"
}

# ── 加固写入测试 ──

@test "apply_sudo_hardening writes sudoers drop-in with required directives" {
    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${SUDOERS_DROPIN}" ]]
    grep -q '^Defaults[[:space:]]\+requiretty' "${SUDOERS_DROPIN}"
    grep -q '^Defaults[[:space:]]\+secure_path=' "${SUDOERS_DROPIN}"
    grep -q '^Defaults[[:space:]]\+timestamp_timeout=' "${SUDOERS_DROPIN}"
    grep -q '^Defaults[[:space:]]\+logfile=' "${SUDOERS_DROPIN}"
}

@test "sudoers drop-in permission is 0440" {
    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]
    [[ "$(_get_mode "${SUDOERS_DROPIN}")" == "440" ]]
}

@test "apply_sudo_hardening creates sudo log with 0640 permission" {
    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]

    [[ -e "${SUDO_LOG_FILE}" ]]
    [[ "$(_get_mode "${SUDO_LOG_FILE}")" == "640" ]]
}

@test "apply_sudo_hardening writes logrotate drop-in" {
    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${SUDO_LOGROTATE_CONF}" ]]
    grep -q 'su root root' "${SUDO_LOGROTATE_CONF}"
    grep -q 'create 0640 root root' "${SUDO_LOGROTATE_CONF}"
    grep -q "${SUDO_LOG_FILE}" "${SUDO_LOGROTATE_CONF}"
}

# ── 幂等测试 ──

@test "apply_sudo_hardening is idempotent (skips when already hardened)" {
    mkdir -p "$(dirname "${SUDOERS_DROPIN}")"
    echo "# ORIGINAL" > "${SUDOERS_DROPIN}"

    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]
    [[ "$(_count_sudo_backups)" -eq 1 ]]

    # 第二次运行：已加固，跳过写入 → 不再产生新备份
    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]
    [[ "$(_count_sudo_backups)" -eq 1 ]]
}

@test "apply_sudo_hardening skips write when all directives already present" {
    mkdir -p "$(dirname "${SUDOERS_DROPIN}")"
    cat > "${SUDOERS_DROPIN}" << 'EOF'
Defaults requiretty
Defaults secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
Defaults timestamp_timeout=5
Defaults logfile="/var/log/sudo.log"
EOF

    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]
    # 已加固：不产生备份
    [[ "$(_count_sudo_backups)" -eq 0 ]]
}

# ── 备份测试 ──

@test "pre-existing drop-in is backed up before overwrite" {
    mkdir -p "$(dirname "${SUDOERS_DROPIN}")"
    echo "# CUSTOM" > "${SUDOERS_DROPIN}"

    run apply_sudo_hardening
    [[ "${status}" -eq 0 ]]
    [[ "$(_count_sudo_backups)" -eq 1 ]]

    local backup_file
    backup_file=$(find "${BACKUP_DIR}" -maxdepth 1 -name '99-linux-one-key-sudo.bak.*' ! -name '*.meta' -print -quit)
    [[ -n "${backup_file}" ]]
    grep -q '# CUSTOM' "${backup_file}"
}

# ── visudo 校验失败回滚测试 ──

@test "visudo failure rolls back to original content" {
    mkdir -p "$(dirname "${SUDOERS_DROPIN}")"
    echo "# ORIGINAL" > "${SUDOERS_DROPIN}"
    visudo() { return 1; }

    run apply_sudo_hardening
    [[ "${status}" -ne 0 ]]

    # 回滚：内容恢复为原值
    grep -q '# ORIGINAL' "${SUDOERS_DROPIN}"
}

@test "visudo failure with no pre-existing file removes drop-in" {
    visudo() { return 1; }

    run apply_sudo_hardening
    [[ "${status}" -ne 0 ]]
    [[ ! -e "${SUDOERS_DROPIN}" ]]
}

# ── NOPASSWD 白名单检查测试 ──

@test "_check_nopasswd_risk warns when NOPASSWD present" {
    mkdir -p "$(dirname "${SUDOERS_MAIN}")"
    echo "devops ALL=(ALL) NOPASSWD: ALL" > "${SUDOERS_MAIN}"

    run _check_nopasswd_risk
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_SUDO_NOPASSWD_RISK}"* ]]
}

@test "_check_nopasswd_risk silent when no NOPASSWD" {
    mkdir -p "$(dirname "${SUDOERS_MAIN}")"
    echo "root ALL=(ALL) ALL" > "${SUDOERS_MAIN}"

    run _check_nopasswd_risk
    [[ "${status}" -eq 0 ]]
    [[ "${output}" != *"${MSG_SUDO_NOPASSWD_RISK}"* ]]
}

# ── 菜单接入测试 ──

@test "install.sh main menu regex accepts 22" {
    run grep -E '\[0-9\]\|1\[0-9\]\|2\[0-2\]' "${SCRIPT_DIR}/install.sh"
    [[ "${status}" -eq 0 ]]
}

@test "install.sh main menu prompt lists [0-22]" {
    run grep -F '[0-22]' "${SCRIPT_DIR}/install.sh"
    [[ "${status}" -eq 0 ]]
}

@test "install.sh wires [22] to run_sudo_log_menu_loop with Full-only gate" {
    run grep -nE '22\)[[:space:]]*$' "${SCRIPT_DIR}/install.sh"
    [[ "${status}" -eq 0 ]]
    run bash -c "sed -n '/22)/,/run_sudo_log_menu_loop/p' '${SCRIPT_DIR}/install.sh' | grep -q is_mode_lite"
    [[ "${status}" -eq 0 ]]
}

@test "install.sh sources sudo.sh in load_dependencies" {
    run grep -E 'for _mod in sudo logging' "${SCRIPT_DIR}/install.sh"
    [[ "${status}" -eq 0 ]]
}

# ── i18n 键测试 ──

@test "sudo Chinese i18n keys are loaded" {
    [[ -n "${MSG_SUDO_TITLE}" ]]
    [[ -n "${MSG_SUDO_WIZARD_TITLE}" ]]
    [[ -n "${MSG_SUDO_WIZARD_DESC}" ]]
    [[ -n "${MSG_SUDO_ALREADY_HARDENED}" ]]
    [[ -n "${MSG_SUDO_VISUDO_FAILED}" ]]
    [[ -n "${MSG_SUDO_NOPASSWD_RISK}" ]]
    [[ -n "${MSG_SUDO_DONE}" ]]
}

@test "sudo log hardening Chinese i18n keys are loaded" {
    [[ -n "${MSG_MAIN_MENU_SUDO_LOG}" ]]
    [[ -n "${MSG_MAIN_MENU_SUDO_LOG_DESC}" ]]
    [[ -n "${MSG_SUDO_LOG_MENU_TITLE}" ]]
    [[ -n "${MSG_SUDO_LOG_MENU_SUDO}" ]]
    [[ -n "${MSG_SUDO_LOG_MENU_LOGGING}" ]]
    [[ -n "${MSG_SUDO_LOG_MENU_BACK}" ]]
}

@test "English sudo i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_SUDO_TITLE}" ]]
    [[ -n "${MSG_SUDO_WIZARD_TITLE}" ]]
    [[ -n "${MSG_SUDO_NOPASSWD_RISK}" ]]
    [[ -n "${MSG_MAIN_MENU_SUDO_LOG}" ]]
    [[ -n "${MSG_SUDO_LOG_MENU_SUDO}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

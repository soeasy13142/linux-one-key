#!/usr/bin/env bats
# logging.bats - 单元测试 for scripts/security/logging.sh

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    # 覆盖配置路径，避免触碰真实系统
    export JOURNALD_DROPIN="${TEST_DIR}/etc/systemd/journald.conf.d/99-linux-one-key.conf"
    export LOGROTATE_CONF="${TEST_DIR}/etc/logrotate.d/linux-one-key-logrotate"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_OS="ubuntu"

    source "${SCRIPT_DIR}/scripts/security/logging.sh"

    export LOG_FILE="${TEST_DIR}/test.log"

    # 覆盖关键日志文件列表，指向测试目录
    CRITICAL_LOG_FILES=(
        "${TEST_DIR}/var/log/syslog:640"
        "${TEST_DIR}/var/log/sudo.log:640"
    )
}

teardown() {
    rm -rf "${TEST_DIR}"
}

_get_mode() {
    stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null || echo "000"
}

_count_journald_backups() {
    find "${BACKUP_DIR}" -maxdepth 1 -name '99-linux-one-key.conf.bak.*' ! -name '*.meta' 2>/dev/null | wc -l | tr -d ' '
}

# ── 函数存在性 / guard ──

@test "logging.sh loaded flag is set" {
    [[ "${_LOGGING_LOADED:-}" == "1" ]]
}

@test "apply_logging_hardening function exists" {
    [[ "$(type -t apply_logging_hardening)" == "function" ]]
}

@test "run_logging_wizard function exists" {
    [[ "$(type -t run_logging_wizard)" == "function" ]]
}

# ── 常量默认值（通过源文件验证） ──

@test "JOURNALD_DROPIN defaults to /etc/systemd/journald.conf.d/99-linux-one-key.conf" {
    grep -q 'JOURNALD_DROPIN="${JOURNALD_DROPIN:-/etc/systemd/journald.conf.d/99-linux-one-key.conf}"' \
        "${SCRIPT_DIR}/scripts/security/logging.sh"
}

@test "LOGROTATE_CONF defaults to /etc/logrotate.d/linux-one-key-logrotate" {
    grep -q 'LOGROTATE_CONF="${LOGROTATE_CONF:-/etc/logrotate.d/linux-one-key-logrotate}"' \
        "${SCRIPT_DIR}/scripts/security/logging.sh"
}

# ── journald 加固测试 ──

@test "apply_logging_hardening writes journald drop-in" {
    systemctl() { return 0; }

    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${JOURNALD_DROPIN}" ]]
    grep -q '^Storage=persistent' "${JOURNALD_DROPIN}"
    grep -q '^SystemMaxUse=' "${JOURNALD_DROPIN}"
    grep -q '^MaxRetentionSec=' "${JOURNALD_DROPIN}"
}

@test "apply_logging_hardening calls systemctl try-restart systemd-journald" {
    systemctl() { echo "$*" >> "${TEST_DIR}/systemctl.calls"; return 0; }

    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]
    grep -q 'try-restart systemd-journald' "${TEST_DIR}/systemctl.calls"
}

@test "journald restart failure is warning-only (idempotent, non-blocking)" {
    systemctl() { return 1; }

    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_LOG_JOURNALD_RESTART_WARN}"* ]]
}

# ── logrotate 安全配置测试 ──

@test "apply_logging_hardening writes logrotate safety drop-in" {
    systemctl() { return 0; }

    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${LOGROTATE_CONF}" ]]
    grep -q 'su[[:space:]]*root' "${LOGROTATE_CONF}"
    grep -q 'compress' "${LOGROTATE_CONF}"
    grep -q 'dateext' "${LOGROTATE_CONF}"
    grep -q 'create 0640 root root' "${LOGROTATE_CONF}"
}

# ── 幂等测试 ──

@test "journald config is idempotent (skips when already hardened)" {
    mkdir -p "$(dirname "${JOURNALD_DROPIN}")"
    cat > "${JOURNALD_DROPIN}" << 'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
MaxRetentionSec=30d
EOF
    systemctl() { return 0; }

    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]
    # 已加固：不产生备份
    [[ "$(_count_journald_backups)" -eq 0 ]]
}

@test "pre-existing journald drop-in is backed up once" {
    mkdir -p "$(dirname "${JOURNALD_DROPIN}")"
    echo "# CUSTOM" > "${JOURNALD_DROPIN}"
    systemctl() { return 0; }

    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]
    [[ "$(_count_journald_backups)" -eq 1 ]]

    # 第二次运行：已加固，跳过 → 备份数不变
    run apply_logging_hardening
    [[ "${status}" -eq 0 ]]
    [[ "$(_count_journald_backups)" -eq 1 ]]
}

# ── 关键日志文件权限修复测试 ──

@test "_fix_log_file_perms fixes wrong permission to 0640" {
    mkdir -p "${TEST_DIR}/var/log"
    echo "log" > "${TEST_DIR}/var/log/syslog"
    chmod 644 "${TEST_DIR}/var/log/syslog"

    run _fix_log_file_perms
    [[ "${status}" -eq 0 ]]
    [[ "$(_get_mode "${TEST_DIR}/var/log/syslog")" == "640" ]]
}

@test "_fix_log_file_perms leaves already-correct permission untouched" {
    mkdir -p "${TEST_DIR}/var/log"
    echo "log" > "${TEST_DIR}/var/log/sudo.log"
    chmod 640 "${TEST_DIR}/var/log/sudo.log"

    run _fix_log_file_perms
    [[ "${status}" -eq 0 ]]
    [[ "$(_get_mode "${TEST_DIR}/var/log/sudo.log")" == "640" ]]
}

@test "_fix_log_file_perms tolerates missing files" {
    run _fix_log_file_perms
    [[ "${status}" -eq 0 ]]
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

@test "install.sh wires [22] to run_sudo_log_menu_loop" {
    run grep -nE '22\)[[:space:]]*$' "${SCRIPT_DIR}/install.sh"
    [[ "${status}" -eq 0 ]]
}

@test "install.sh sources logging.sh in load_dependencies" {
    run grep -E 'for _mod in sudo logging' "${SCRIPT_DIR}/install.sh"
    [[ "${status}" -eq 0 ]]
}

# ── i18n 键测试 ──

@test "logging Chinese i18n keys are loaded" {
    [[ -n "${MSG_LOG_TITLE}" ]]
    [[ -n "${MSG_LOG_WIZARD_TITLE}" ]]
    [[ -n "${MSG_LOG_JOURNALD_DONE}" ]]
    [[ -n "${MSG_LOG_JOURNALD_RESTART_WARN}" ]]
    [[ -n "${MSG_LOG_LOGROTATE_DONE}" ]]
    [[ -n "${MSG_LOG_PERM_ALL_OK}" ]]
    [[ -n "${MSG_LOG_DONE}" ]]
}

@test "English logging i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_LOG_TITLE}" ]]
    [[ -n "${MSG_LOG_JOURNALD_RESTART_WARN}" ]]
    [[ -n "${MSG_LOG_LOGROTATE_DONE}" ]]
    [[ -n "${MSG_LOG_DONE}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

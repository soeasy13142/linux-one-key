#!/usr/bin/env bats
# memcached.bats - unit tests for scripts/server/memcached.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖配置文件路径，避免测试写 /etc/memcached.conf
    export MEMCACHED_CONFIG="${TEST_DIR}/etc/memcached.conf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/memcached.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "memcached basic functions are defined" {
    type check_memcached_installed
    type check_memcached_running
    type install_memcached
    type uninstall_memcached
    type check_memcached_status
    type show_memcached_submenu
    type run_memcached_submenu_loop
    type _write_memcached_hardening
    type _install_memcached_pkg
}

# ── i18n key tests (Chinese) ──

@test "Memcached Chinese i18n keys are loaded" {
    [[ -n "${MSG_MEMCACHED_TITLE}" ]]
    [[ -n "${MSG_MEMCACHED_INSTALLING}" ]]
    [[ -n "${MSG_MEMCACHED_INSTALLED}" ]]
    [[ -n "${MSG_MEMCACHED_ALREADY}" ]]
    [[ -n "${MSG_MEMCACHED_FAILED}" ]]
    [[ -n "${MSG_MEMCACHED_CANCELLED}" ]]
    [[ -n "${MSG_MEMCACHED_CONFIRM}" ]]
    [[ -n "${MSG_MEMCACHED_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_MEMCACHED_UNINSTALLING}" ]]
    [[ -n "${MSG_MEMCACHED_UNINSTALLED}" ]]
    [[ -n "${MSG_MEMCACHED_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_MEMCACHED_NOT_INSTALLED}" ]]
    [[ -n "${MSG_MEMCACHED_STATUS_CHECKING}" ]]
    [[ -n "${MSG_MEMCACHED_STATUS_RUNNING}" ]]
    [[ -n "${MSG_MEMCACHED_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_MEMCACHED_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_MEMCACHED_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_MEMCACHED_CONFIG_MISSING}" ]]
    [[ -n "${MSG_MEMCACHED_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_MEMCACHED_ENABLE_FAILED}" ]]
}

@test "Memcached submenu i18n keys are loaded" {
    [[ -n "${MSG_MEMCACHED_MENU_TITLE}" ]]
    [[ -n "${MSG_MEMCACHED_MENU_INSTALL}" ]]
    [[ -n "${MSG_MEMCACHED_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_MEMCACHED_MENU_STATUS}" ]]
    [[ -n "${MSG_MEMCACHED_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Memcached constants are defined correctly" {
    [[ -n "${MEMCACHED_SERVICE}" ]]
    [[ "${MEMCACHED_SERVICE}" == "memcached" ]]
    [[ -n "${MEMCACHED_CONFIG}" ]]
}

# ── check_memcached_installed tests ──

@test "check_memcached_installed returns 1 when memcached not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_memcached_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_memcached_running tests ──

@test "check_memcached_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_memcached_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_memcached rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_memcached
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_memcached rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_memcached
    [[ "${status}" -ne 0 ]]
}

# ── check_memcached_status tests ──

@test "check_memcached_status returns 1 when memcached not installed" {
    check_memcached_installed() { return 1; }

    run check_memcached_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_memcached_hardening tests ──

@test "_write_memcached_hardening writes conservative baseline when absent" {
    run _write_memcached_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${MEMCACHED_CONFIG}" ]]
    grep -q -- '-l 127.0.0.1' "${MEMCACHED_CONFIG}"
    grep -q -- '-U 0' "${MEMCACHED_CONFIG}"
    grep -q -- '-m 64' "${MEMCACHED_CONFIG}"
}

@test "_write_memcached_hardening preserves existing settings and applies hardening" {
    mkdir -p "$(dirname "${MEMCACHED_CONFIG}")"
    printf '%s\n' '# custom comment' '-p 11211' > "${MEMCACHED_CONFIG}"

    run _write_memcached_hardening
    [[ "${status}" -eq 0 ]]

    # 保留原有设置
    grep -q -- '# custom comment' "${MEMCACHED_CONFIG}"
    grep -q -- '-p 11211' "${MEMCACHED_CONFIG}"
    # 追加加固项
    grep -q -- '-l 127.0.0.1' "${MEMCACHED_CONFIG}"
    grep -q -- '-U 0' "${MEMCACHED_CONFIG}"
    grep -q -- '-m 64' "${MEMCACHED_CONFIG}"
    # 已生成备份
    [[ -n "$(find "${BACKUP_DIR}" -name 'memcached.conf.bak.*' -print -quit)" ]]
}

@test "_write_memcached_hardening replaces existing hardening flags idempotently" {
    mkdir -p "$(dirname "${MEMCACHED_CONFIG}")"
    printf '%s\n' '-l 0.0.0.0' '-U 11211' '-m 128' > "${MEMCACHED_CONFIG}"

    run _write_memcached_hardening
    [[ "${status}" -eq 0 ]]

    grep -q -- '-l 127.0.0.1' "${MEMCACHED_CONFIG}"
    grep -q -- '-U 0' "${MEMCACHED_CONFIG}"
    grep -q -- '-m 64' "${MEMCACHED_CONFIG}"
    # 旧值已被替换，不留残余
    ! grep -q -- '-l 0.0.0.0' "${MEMCACHED_CONFIG}"
    ! grep -q -- '-U 11211' "${MEMCACHED_CONFIG}"
    ! grep -q -- '-m 128' "${MEMCACHED_CONFIG}"
}

# ── Submenu display tests ──

@test "show_memcached_submenu output contains menu title" {
    run show_memcached_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_MEMCACHED_MENU_TITLE}"* ]]
}

@test "show_memcached_submenu output contains install/uninstall/status options" {
    run show_memcached_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_MEMCACHED_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_MEMCACHED_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_MEMCACHED_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_MEMCACHED_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "memcached.sh loaded flag is set" {
    [[ "${_MEMCACHED_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Memcached i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_MEMCACHED_TITLE}" ]]
    [[ -n "${MSG_MEMCACHED_INSTALLING}" ]]
    [[ -n "${MSG_MEMCACHED_INSTALLED}" ]]
    [[ -n "${MSG_MEMCACHED_STATUS_RUNNING}" ]]
    [[ -n "${MSG_MEMCACHED_CONFIRM}" ]]
    [[ -n "${MSG_MEMCACHED_MENU_INSTALL}" ]]
    [[ -n "${MSG_MEMCACHED_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

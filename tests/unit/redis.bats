#!/usr/bin/env bats
# redis.bats - unit tests for scripts/server/redis.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 redis.conf 路径，避免测试写 /etc/redis
    export REDIS_CONFIG="${TEST_DIR}/etc/redis/redis.conf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/redis.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "redis basic functions are defined" {
    type check_redis_installed
    type check_redis_running
    type install_redis
    type uninstall_redis
    type check_redis_status
    type show_redis_submenu
    type run_redis_submenu_loop
    type _write_redis_hardening
    type _install_redis_pkg
    type _set_redis_line
}

# ── i18n key tests (Chinese) ──

@test "Redis Chinese i18n keys are loaded" {
    [[ -n "${MSG_REDIS_TITLE}" ]]
    [[ -n "${MSG_REDIS_INSTALLING}" ]]
    [[ -n "${MSG_REDIS_INSTALLED}" ]]
    [[ -n "${MSG_REDIS_ALREADY}" ]]
    [[ -n "${MSG_REDIS_FAILED}" ]]
    [[ -n "${MSG_REDIS_CANCELLED}" ]]
    [[ -n "${MSG_REDIS_CONFIRM}" ]]
    [[ -n "${MSG_REDIS_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_REDIS_UNINSTALLING}" ]]
    [[ -n "${MSG_REDIS_UNINSTALLED}" ]]
    [[ -n "${MSG_REDIS_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_REDIS_NOT_INSTALLED}" ]]
    [[ -n "${MSG_REDIS_STATUS_CHECKING}" ]]
    [[ -n "${MSG_REDIS_STATUS_RUNNING}" ]]
    [[ -n "${MSG_REDIS_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_REDIS_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_REDIS_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_REDIS_CONFIG_MISSING}" ]]
    [[ -n "${MSG_REDIS_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_REDIS_ENABLE_FAILED}" ]]
}

@test "Redis submenu i18n keys are loaded" {
    [[ -n "${MSG_REDIS_MENU_TITLE}" ]]
    [[ -n "${MSG_REDIS_MENU_INSTALL}" ]]
    [[ -n "${MSG_REDIS_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_REDIS_MENU_STATUS}" ]]
    [[ -n "${MSG_REDIS_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Redis constants are defined correctly" {
    [[ -n "${REDIS_SERVICE}" ]]
    [[ "${REDIS_SERVICE}" == "redis" ]]
    [[ -n "${REDIS_CONFIG}" ]]
    # 测试环境覆盖的路径应生效
    [[ "${REDIS_CONFIG}" == "${TEST_DIR}/etc/redis/redis.conf" ]]
}

# ── check_redis_installed tests ──

@test "check_redis_installed returns 1 when redis not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_redis_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_redis_running tests ──

@test "check_redis_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_redis_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_redis rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_redis
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_redis rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_redis
    [[ "${status}" -ne 0 ]]
}

# ── check_redis_status tests ──

@test "check_redis_status returns 1 when redis not installed" {
    check_redis_installed() { return 1; }

    run check_redis_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_redis_hardening tests ──

@test "_write_redis_hardening writes baseline when absent" {
    run _write_redis_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${REDIS_CONFIG}" ]]
    grep -q 'bind 127.0.0.1' "${REDIS_CONFIG}"
    grep -q 'protected-mode yes' "${REDIS_CONFIG}"
    grep -q 'rename-command FLUSHALL ""' "${REDIS_CONFIG}"
    grep -q 'rename-command FLUSHDB ""' "${REDIS_CONFIG}"
    grep -q 'rename-command CONFIG ""' "${REDIS_CONFIG}"
    grep -q 'rename-command EVAL ""' "${REDIS_CONFIG}"
}

@test "_write_redis_hardening preserves existing config and backs it up" {
    mkdir -p "$(dirname "${REDIS_CONFIG}")"
    printf '# custom\n' > "${REDIS_CONFIG}"

    run _write_redis_hardening
    [[ "${status}" -eq 0 ]]

    # 原内容不被覆盖
    grep -q '# custom' "${REDIS_CONFIG}"
    # 加固键已补充
    grep -q 'bind 127.0.0.1' "${REDIS_CONFIG}"
    grep -q 'protected-mode yes' "${REDIS_CONFIG}"
    grep -q 'rename-command FLUSHALL ""' "${REDIS_CONFIG}"
    # 已生成备份
    [[ -n "$(find "${BACKUP_DIR}" -name 'redis.conf.bak.*' -print -quit)" ]]
}

@test "_write_redis_hardening is idempotent (no duplicate keys)" {
    run _write_redis_hardening
    [[ "${status}" -eq 0 ]]
    run _write_redis_hardening
    [[ "${status}" -eq 0 ]]

    local bind_count protected_count rename_count
    bind_count=$(grep -c '^bind ' "${REDIS_CONFIG}" 2>/dev/null || true)
    protected_count=$(grep -c '^protected-mode ' "${REDIS_CONFIG}" 2>/dev/null || true)
    rename_count=$(grep -c '^rename-command FLUSHALL ' "${REDIS_CONFIG}" 2>/dev/null || true)

    [[ "${bind_count}" -eq 1 ]]
    [[ "${protected_count}" -eq 1 ]]
    [[ "${rename_count}" -eq 1 ]]
}

# ── Submenu display tests ──

@test "show_redis_submenu output contains menu title" {
    run show_redis_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_REDIS_MENU_TITLE}"* ]]
}

@test "show_redis_submenu output contains install/uninstall/status options" {
    run show_redis_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_REDIS_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_REDIS_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_REDIS_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_REDIS_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "redis.sh loaded flag is set" {
    [[ "${_REDIS_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Redis i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_REDIS_TITLE}" ]]
    [[ -n "${MSG_REDIS_INSTALLING}" ]]
    [[ -n "${MSG_REDIS_INSTALLED}" ]]
    [[ -n "${MSG_REDIS_STATUS_RUNNING}" ]]
    [[ -n "${MSG_REDIS_CONFIRM}" ]]
    [[ -n "${MSG_REDIS_MENU_INSTALL}" ]]
    [[ -n "${MSG_REDIS_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

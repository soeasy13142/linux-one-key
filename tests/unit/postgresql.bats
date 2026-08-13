#!/usr/bin/env bats
# postgresql.bats - unit tests for scripts/server/postgresql.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 pg_hba.conf / postgresql.conf 路径，避免测试写 /etc 或 /var/lib/pgsql
    export POSTGRES_HBA="${TEST_DIR}/etc/postgresql/14/main/pg_hba.conf"
    export POSTGRES_CONF="${TEST_DIR}/etc/postgresql/14/main/postgresql.conf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/postgresql.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "postgresql basic functions are defined" {
    type check_postgres_installed
    type check_postgres_running
    type install_postgres
    type uninstall_postgres
    type check_postgres_status
    type show_postgres_submenu
    type run_postgres_submenu_loop
    type _write_pg_hardening
    type _install_postgres_pkg
    type _pg_hba_path
    type _pg_conf_path
}

# ── i18n key tests (Chinese) ──

@test "PostgreSQL Chinese i18n keys are loaded" {
    [[ -n "${MSG_POSTGRES_TITLE}" ]]
    [[ -n "${MSG_POSTGRES_INSTALLING}" ]]
    [[ -n "${MSG_POSTGRES_INSTALLED}" ]]
    [[ -n "${MSG_POSTGRES_ALREADY}" ]]
    [[ -n "${MSG_POSTGRES_FAILED}" ]]
    [[ -n "${MSG_POSTGRES_CANCELLED}" ]]
    [[ -n "${MSG_POSTGRES_CONFIRM}" ]]
    [[ -n "${MSG_POSTGRES_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_POSTGRES_UNINSTALLING}" ]]
    [[ -n "${MSG_POSTGRES_UNINSTALLED}" ]]
    [[ -n "${MSG_POSTGRES_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_POSTGRES_NOT_INSTALLED}" ]]
    [[ -n "${MSG_POSTGRES_STATUS_CHECKING}" ]]
    [[ -n "${MSG_POSTGRES_STATUS_RUNNING}" ]]
    [[ -n "${MSG_POSTGRES_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_POSTGRES_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_POSTGRES_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_POSTGRES_CONFIG_MISSING}" ]]
    [[ -n "${MSG_POSTGRES_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_POSTGRES_ENABLE_FAILED}" ]]
}

@test "PostgreSQL submenu i18n keys are loaded" {
    [[ -n "${MSG_POSTGRES_MENU_TITLE}" ]]
    [[ -n "${MSG_POSTGRES_MENU_INSTALL}" ]]
    [[ -n "${MSG_POSTGRES_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_POSTGRES_MENU_STATUS}" ]]
    [[ -n "${MSG_POSTGRES_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "PostgreSQL constants are defined correctly" {
    [[ -n "${POSTGRES_SERVICE}" ]]
    [[ "${POSTGRES_SERVICE}" == "postgresql" ]]
}

# ── _pg_hba_path / _pg_conf_path override tests ──

@test "_pg_hba_path respects POSTGRES_HBA override" {
    run _pg_hba_path
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${POSTGRES_HBA}" ]]
}

@test "_pg_conf_path respects POSTGRES_CONF override" {
    run _pg_conf_path
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${POSTGRES_CONF}" ]]
}

# ── check_postgres_installed tests ──

@test "check_postgres_installed returns 1 when postgresql not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_postgres_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_postgres_running tests ──

@test "check_postgres_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_postgres_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_postgres rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_postgres
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_postgres rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_postgres
    [[ "${status}" -ne 0 ]]
}

# ── check_postgres_status tests ──

@test "check_postgres_status returns 1 when postgresql not installed" {
    check_postgres_installed() { return 1; }

    run check_postgres_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_pg_hardening tests ──

@test "_write_pg_hardening writes conservative baseline when absent" {
    run _write_pg_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${POSTGRES_HBA}" ]]
    [[ -f "${POSTGRES_CONF}" ]]
    grep -q 'scram-sha-256' "${POSTGRES_HBA}"
    grep -q "listen_addresses = 'localhost'" "${POSTGRES_CONF}"
}

@test "_write_pg_hardening rewrites weak methods and preserves custom lines" {
    mkdir -p "$(dirname "${POSTGRES_HBA}")"
    {
        printf '# custom rule\n'
        printf 'local   all   all   peer\n'
        printf 'host    all   all   127.0.0.1/32   md5\n'
    } > "${POSTGRES_HBA}"

    run _write_pg_hardening
    [[ "${status}" -eq 0 ]]

    # 自定义行原样保留
    grep -q '# custom rule' "${POSTGRES_HBA}"
    # 弱方法被改写为 scram-sha-256
    grep -q 'scram-sha-256' "${POSTGRES_HBA}"
    ! grep -qE '(peer|md5)[[:space:]]*$' "${POSTGRES_HBA}"
    # 已生成备份
    [[ -n "$(find "${BACKUP_DIR}" -name 'pg_hba.conf.bak.*' -print -quit)" ]]
}

@test "_write_pg_hardening is idempotent (skips when already hardened)" {
    run _write_pg_hardening
    [[ "${status}" -eq 0 ]]

    local backups_before
    backups_before="$(find "${BACKUP_DIR}" -name 'pg_hba.conf.bak.*' -print | wc -l | tr -d ' ')"

    run _write_pg_hardening
    [[ "${status}" -eq 0 ]]

    local backups_after
    backups_after="$(find "${BACKUP_DIR}" -name 'pg_hba.conf.bak.*' -print | wc -l | tr -d ' ')"

    [[ "${backups_after}" == "${backups_before}" ]]
    grep -q 'scram-sha-256' "${POSTGRES_HBA}"
}

# ── Submenu display tests ──

@test "show_postgres_submenu output contains menu title" {
    run show_postgres_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_POSTGRES_MENU_TITLE}"* ]]
}

@test "show_postgres_submenu output contains install/uninstall/status options" {
    run show_postgres_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_POSTGRES_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_POSTGRES_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_POSTGRES_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_POSTGRES_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "postgresql.sh loaded flag is set" {
    [[ "${_POSTGRES_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English PostgreSQL i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_POSTGRES_TITLE}" ]]
    [[ -n "${MSG_POSTGRES_INSTALLING}" ]]
    [[ -n "${MSG_POSTGRES_INSTALLED}" ]]
    [[ -n "${MSG_POSTGRES_STATUS_RUNNING}" ]]
    [[ -n "${MSG_POSTGRES_CONFIRM}" ]]
    [[ -n "${MSG_POSTGRES_MENU_INSTALL}" ]]
    [[ -n "${MSG_POSTGRES_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

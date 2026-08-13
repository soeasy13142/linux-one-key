#!/usr/bin/env bats
# mysql.bats - unit tests for scripts/server/mysql.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    export DETECTED_OS="ubuntu"
    # 覆盖配置文件路径，避免测试写 /etc/mysql
    export MYSQL_CONFIG_FILE="${TEST_DIR}/etc/mysql/mysql.conf.d/mysqld.cnf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/mysql.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "mysql basic functions are defined" {
    type check_mysql_installed
    type check_mysql_running
    type install_mysql
    type uninstall_mysql
    type check_mysql_status
    type show_mysql_submenu
    type run_mysql_submenu_loop
    type _secure_mysql
    type _install_mysql_pkg
    type _mysql_service
    type _mysql_config_file
    type _write_mysql_bind_address
}

# ── i18n key tests (Chinese) ──

@test "MySQL Chinese i18n keys are loaded" {
    [[ -n "${MSG_MYSQL_TITLE}" ]]
    [[ -n "${MSG_MYSQL_INSTALLING}" ]]
    [[ -n "${MSG_MYSQL_INSTALLED}" ]]
    [[ -n "${MSG_MYSQL_ALREADY}" ]]
    [[ -n "${MSG_MYSQL_FAILED}" ]]
    [[ -n "${MSG_MYSQL_CANCELLED}" ]]
    [[ -n "${MSG_MYSQL_CONFIRM}" ]]
    [[ -n "${MSG_MYSQL_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_MYSQL_UNINSTALLING}" ]]
    [[ -n "${MSG_MYSQL_UNINSTALLED}" ]]
    [[ -n "${MSG_MYSQL_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_MYSQL_NOT_INSTALLED}" ]]
    [[ -n "${MSG_MYSQL_STATUS_CHECKING}" ]]
    [[ -n "${MSG_MYSQL_STATUS_RUNNING}" ]]
    [[ -n "${MSG_MYSQL_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_MYSQL_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_MYSQL_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_MYSQL_CONFIG_MISSING}" ]]
    [[ -n "${MSG_MYSQL_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_MYSQL_ENABLE_FAILED}" ]]
}

@test "MySQL submenu i18n keys are loaded" {
    [[ -n "${MSG_MYSQL_MENU_TITLE}" ]]
    [[ -n "${MSG_MYSQL_MENU_INSTALL}" ]]
    [[ -n "${MSG_MYSQL_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_MYSQL_MENU_STATUS}" ]]
    [[ -n "${MSG_MYSQL_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "MySQL constants are defined correctly" {
    [[ -n "${MYSQL_SERVICE}" ]]
    [[ "${MYSQL_SERVICE}" == "mysql" ]]
}

# ── check_mysql_installed tests ──

@test "check_mysql_installed returns 1 when mysql not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_mysql_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_mysql_running tests ──

@test "check_mysql_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_mysql_running
    [[ "${status}" -ne 0 ]]
}

# ── _mysql_service tests ──

@test "_mysql_service falls back to MYSQL_SERVICE when no unit found" {
    systemctl() { return 1; }

    run _mysql_service
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "mysql" ]]
}

@test "_mysql_service picks mariadb when its unit exists" {
    systemctl() {
        if [[ "$1" == "cat" && "$2" == "mariadb.service" ]]; then
            return 0
        fi
        return 1
    }

    run _mysql_service
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "mariadb" ]]
}

# ── is_root tests ──

@test "install_mysql rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_mysql
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_mysql rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_mysql
    [[ "${status}" -ne 0 ]]
}

# ── check_mysql_status tests ──

@test "check_mysql_status returns 1 when mysql not installed" {
    check_mysql_installed() { return 1; }

    run check_mysql_status
    [[ "${status}" -ne 0 ]]
}

# ── _secure_mysql tests ──

@test "_secure_mysql runs hardening SQL via mysql and writes bind-address" {
    mysql() {
        if [[ "$*" == *"-e"* ]]; then
            echo "1"
            return 0
        fi
        cat >> "${TEST_DIR}/mysql-commands.sql"
        return 0
    }

    run _secure_mysql
    [[ "${status}" -eq 0 ]]

    grep -q "DELETE FROM mysql.user WHERE User='';" "${TEST_DIR}/mysql-commands.sql"
    grep -q "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN" "${TEST_DIR}/mysql-commands.sql"
    grep -q "DROP DATABASE IF EXISTS test;" "${TEST_DIR}/mysql-commands.sql"
    grep -q "FLUSH PRIVILEGES;" "${TEST_DIR}/mysql-commands.sql"

    [[ -f "${MYSQL_CONFIG_FILE}" ]]
    grep -q 'bind-address = 127.0.0.1' "${MYSQL_CONFIG_FILE}"
}

@test "_secure_mysql skips when already secured (no anonymous user)" {
    mysql() {
        if [[ "$*" == *"-e"* ]]; then
            echo "0"
            return 0
        fi
        cat >> "${TEST_DIR}/mysql-commands.sql"
        return 0
    }

    run _secure_mysql
    [[ "${status}" -eq 0 ]]

    [[ ! -f "${TEST_DIR}/mysql-commands.sql" ]]
    [[ ! -f "${MYSQL_CONFIG_FILE}" ]]
}

@test "_secure_mysql returns 1 when mysql command is unavailable" {
    run _secure_mysql
    [[ "${status}" -ne 0 ]]
}

# ── Submenu display tests ──

@test "show_mysql_submenu output contains menu title" {
    run show_mysql_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_MYSQL_MENU_TITLE}"* ]]
}

@test "show_mysql_submenu output contains install/uninstall/status options" {
    run show_mysql_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_MYSQL_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_MYSQL_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_MYSQL_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_MYSQL_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "mysql.sh loaded flag is set" {
    [[ "${_MYSQL_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English MySQL i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_MYSQL_TITLE}" ]]
    [[ -n "${MSG_MYSQL_INSTALLING}" ]]
    [[ -n "${MSG_MYSQL_INSTALLED}" ]]
    [[ -n "${MSG_MYSQL_STATUS_RUNNING}" ]]
    [[ -n "${MSG_MYSQL_CONFIRM}" ]]
    [[ -n "${MSG_MYSQL_MENU_INSTALL}" ]]
    [[ -n "${MSG_MYSQL_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

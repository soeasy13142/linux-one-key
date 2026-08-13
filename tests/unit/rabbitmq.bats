#!/usr/bin/env bats
# rabbitmq.bats - unit tests for scripts/server/rabbitmq.sh

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

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/rabbitmq.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "rabbitmq basic functions are defined" {
    type check_rabbitmq_installed
    type check_rabbitmq_running
    type install_rabbitmq
    type uninstall_rabbitmq
    type check_rabbitmq_status
    type show_rabbitmq_submenu
    type run_rabbitmq_submenu_loop
    type _secure_rabbitmq
    type _install_rabbitmq_pkg
}

# ── i18n key tests (Chinese) ──

@test "RabbitMQ Chinese i18n keys are loaded" {
    [[ -n "${MSG_RABBITMQ_TITLE}" ]]
    [[ -n "${MSG_RABBITMQ_INSTALLING}" ]]
    [[ -n "${MSG_RABBITMQ_INSTALLED}" ]]
    [[ -n "${MSG_RABBITMQ_ALREADY}" ]]
    [[ -n "${MSG_RABBITMQ_FAILED}" ]]
    [[ -n "${MSG_RABBITMQ_CANCELLED}" ]]
    [[ -n "${MSG_RABBITMQ_CONFIRM}" ]]
    [[ -n "${MSG_RABBITMQ_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_RABBITMQ_UNINSTALLING}" ]]
    [[ -n "${MSG_RABBITMQ_UNINSTALLED}" ]]
    [[ -n "${MSG_RABBITMQ_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_RABBITMQ_NOT_INSTALLED}" ]]
    [[ -n "${MSG_RABBITMQ_STATUS_CHECKING}" ]]
    [[ -n "${MSG_RABBITMQ_STATUS_RUNNING}" ]]
    [[ -n "${MSG_RABBITMQ_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_RABBITMQ_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_RABBITMQ_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_RABBITMQ_CONFIG_MISSING}" ]]
    [[ -n "${MSG_RABBITMQ_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_RABBITMQ_ENABLE_FAILED}" ]]
}

@test "RabbitMQ submenu i18n keys are loaded" {
    [[ -n "${MSG_RABBITMQ_MENU_TITLE}" ]]
    [[ -n "${MSG_RABBITMQ_MENU_INSTALL}" ]]
    [[ -n "${MSG_RABBITMQ_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_RABBITMQ_MENU_STATUS}" ]]
    [[ -n "${MSG_RABBITMQ_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "RabbitMQ constants are defined correctly" {
    [[ -n "${RABBITMQ_SERVICE}" ]]
    [[ "${RABBITMQ_SERVICE}" == "rabbitmq-server" ]]
}

# ── check_rabbitmq_installed tests ──

@test "check_rabbitmq_installed returns 1 when rabbitmq not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_rabbitmq_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_rabbitmq_running tests ──

@test "check_rabbitmq_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_rabbitmq_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_rabbitmq rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_rabbitmq
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_rabbitmq rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_rabbitmq
    [[ "${status}" -ne 0 ]]
}

# ── check_rabbitmq_status tests ──

@test "check_rabbitmq_status returns 1 when rabbitmq not installed" {
    check_rabbitmq_installed() { return 1; }

    run check_rabbitmq_status
    [[ "${status}" -ne 0 ]]
}

# ── _secure_rabbitmq tests ──

@test "_secure_rabbitmq deletes default guest user" {
    rabbitmqctl() {
        if [[ "$1" == "list_users" ]]; then
            echo "guest	[administrator]"
            return 0
        fi
        if [[ "$1" == "delete_user" ]]; then
            echo "delete_user guest" >> "${TEST_DIR}/rabbitmqctl-calls.log"
            return 0
        fi
        return 1
    }

    run _secure_rabbitmq
    [[ "${status}" -eq 0 ]]

    grep -q "delete_user guest" "${TEST_DIR}/rabbitmqctl-calls.log"
}

@test "_secure_rabbitmq skips when guest user already removed" {
    rabbitmqctl() {
        if [[ "$1" == "list_users" ]]; then
            echo ""
            return 0
        fi
        echo "delete_user guest" >> "${TEST_DIR}/rabbitmqctl-calls.log"
        return 0
    }

    run _secure_rabbitmq
    [[ "${status}" -eq 0 ]]

    [[ ! -f "${TEST_DIR}/rabbitmqctl-calls.log" ]]
}

# ── Submenu display tests ──

@test "show_rabbitmq_submenu output contains menu title" {
    run show_rabbitmq_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_RABBITMQ_MENU_TITLE}"* ]]
}

@test "show_rabbitmq_submenu output contains install/uninstall/status options" {
    run show_rabbitmq_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_RABBITMQ_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_RABBITMQ_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_RABBITMQ_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_RABBITMQ_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "rabbitmq.sh loaded flag is set" {
    [[ "${_RABBITMQ_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English RabbitMQ i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_RABBITMQ_TITLE}" ]]
    [[ -n "${MSG_RABBITMQ_INSTALLING}" ]]
    [[ -n "${MSG_RABBITMQ_INSTALLED}" ]]
    [[ -n "${MSG_RABBITMQ_STATUS_RUNNING}" ]]
    [[ -n "${MSG_RABBITMQ_CONFIRM}" ]]
    [[ -n "${MSG_RABBITMQ_MENU_INSTALL}" ]]
    [[ -n "${MSG_RABBITMQ_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

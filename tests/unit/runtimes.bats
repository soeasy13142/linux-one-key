#!/usr/bin/env bats
# runtimes.bats - unit tests for scripts/dev/runtimes.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/dev/runtimes.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "runtimes basic functions are defined" {
    type check_runtimes_installed
    type install_runtimes
    type uninstall_runtimes
    type check_runtimes_status
    type show_runtimes_submenu
    type run_runtimes_submenu_loop
}

# ── i18n key tests (Chinese) ──

@test "runtimes Chinese i18n keys are loaded" {
    [[ -n "${MSG_RUNTIMES_TITLE}" ]]
    [[ -n "${MSG_RUNTIMES_INSTALLING}" ]]
    [[ -n "${MSG_RUNTIMES_INSTALLED}" ]]
    [[ -n "${MSG_RUNTIMES_ALREADY}" ]]
    [[ -n "${MSG_RUNTIMES_FAILED}" ]]
    [[ -n "${MSG_RUNTIMES_CANCELLED}" ]]
    [[ -n "${MSG_RUNTIMES_CONFIRM}" ]]
    [[ -n "${MSG_RUNTIMES_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_RUNTIMES_UNINSTALLING}" ]]
    [[ -n "${MSG_RUNTIMES_UNINSTALLED}" ]]
    [[ -n "${MSG_RUNTIMES_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_RUNTIMES_NOT_INSTALLED}" ]]
    [[ -n "${MSG_RUNTIMES_STATUS_CHECKING}" ]]
}

@test "runtimes submenu i18n keys are loaded" {
    [[ -n "${MSG_RUNTIMES_MENU_TITLE}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_INSTALL}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_STATUS}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_BACK}" ]]
}

# ── check_runtimes_installed tests ──

@test "check_runtimes_installed returns 1 when no runtimes present" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_runtimes_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── is_root tests ──

@test "install_runtimes rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_runtimes
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_runtimes rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_runtimes
    [[ "${status}" -ne 0 ]]
}

# ── check_runtimes_status tests ──

@test "check_runtimes_status returns 1 when runtimes not installed" {
    check_runtimes_installed() { return 1; }

    run check_runtimes_status
    [[ "${status}" -ne 0 ]]
}

# ── Submenu display tests ──

@test "show_runtimes_submenu output contains menu title" {
    run show_runtimes_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_RUNTIMES_MENU_TITLE}"* ]]
}

@test "show_runtimes_submenu output contains install/uninstall/status/back options" {
    run show_runtimes_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_RUNTIMES_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_RUNTIMES_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_RUNTIMES_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_RUNTIMES_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "runtimes.sh loaded flag is set" {
    [[ "${_RUNTIMES_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English runtimes i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_RUNTIMES_TITLE}" ]]
    [[ -n "${MSG_RUNTIMES_INSTALLING}" ]]
    [[ -n "${MSG_RUNTIMES_INSTALLED}" ]]
    [[ -n "${MSG_RUNTIMES_CONFIRM}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_TITLE}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_INSTALL}" ]]
    [[ -n "${MSG_RUNTIMES_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

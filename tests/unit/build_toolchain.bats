#!/usr/bin/env bats
# build_toolchain.bats - unit tests for scripts/dev/build_toolchain.sh

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

    source "${SCRIPT_DIR}/scripts/dev/build_toolchain.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "build_toolchain basic functions are defined" {
    type check_build_toolchain_installed
    type install_build_toolchain
    type uninstall_build_toolchain
    type check_build_toolchain_status
    type show_build_toolchain_submenu
    type run_build_toolchain_submenu_loop
}

# ── i18n key tests (Chinese) ──

@test "build_toolchain Chinese i18n keys are loaded" {
    [[ -n "${MSG_BUILD_TOOLCHAIN_TITLE}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_INSTALLING}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_INSTALLED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_ALREADY}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_FAILED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_CANCELLED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_CONFIRM}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_UNINSTALLING}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_UNINSTALLED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_NOT_INSTALLED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_STATUS_CHECKING}" ]]
}

@test "build_toolchain submenu i18n keys are loaded" {
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_TITLE}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_INSTALL}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_STATUS}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_BACK}" ]]
}

# ── check_build_toolchain_installed tests ──

@test "check_build_toolchain_installed returns 1 when gcc and make missing" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_build_toolchain_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── is_root tests ──

@test "install_build_toolchain rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_build_toolchain
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_build_toolchain rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_build_toolchain
    [[ "${status}" -ne 0 ]]
}

# ── check_build_toolchain_status tests ──

@test "check_build_toolchain_status returns 1 when not installed" {
    check_build_toolchain_installed() { return 1; }

    run check_build_toolchain_status
    [[ "${status}" -ne 0 ]]
}

# ── Submenu display tests ──

@test "show_build_toolchain_submenu output contains menu title" {
    run show_build_toolchain_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_BUILD_TOOLCHAIN_MENU_TITLE}"* ]]
}

@test "show_build_toolchain_submenu output contains install/uninstall/status options" {
    run show_build_toolchain_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_BUILD_TOOLCHAIN_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_BUILD_TOOLCHAIN_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_BUILD_TOOLCHAIN_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_BUILD_TOOLCHAIN_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "build_toolchain.sh loaded flag is set" {
    [[ "${_BUILD_TOOLCHAIN_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English build_toolchain i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_BUILD_TOOLCHAIN_TITLE}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_INSTALLING}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_INSTALLED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_NOT_INSTALLED}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_CONFIRM}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_INSTALL}" ]]
    [[ -n "${MSG_BUILD_TOOLCHAIN_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

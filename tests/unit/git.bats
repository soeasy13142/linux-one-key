#!/usr/bin/env bats
# git.bats - unit tests for scripts/dev/git.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 HOME 与 .gitconfig 路径，避免测试写真实用户目录
    export HOME="${TEST_DIR}"
    export GIT_CONFIG="${TEST_DIR}/.gitconfig"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/dev/git.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "git basic functions are defined" {
    type check_git_installed
    type install_git
    type uninstall_git
    type check_git_status
    type show_git_submenu
    type run_git_submenu_loop
}

# ── i18n key tests (Chinese) ──

@test "Git Chinese i18n keys are loaded" {
    [[ -n "${MSG_GIT_TITLE}" ]]
    [[ -n "${MSG_GIT_INSTALLING}" ]]
    [[ -n "${MSG_GIT_INSTALLED}" ]]
    [[ -n "${MSG_GIT_ALREADY}" ]]
    [[ -n "${MSG_GIT_FAILED}" ]]
    [[ -n "${MSG_GIT_CANCELLED}" ]]
    [[ -n "${MSG_GIT_CONFIRM}" ]]
    [[ -n "${MSG_GIT_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_GIT_UNINSTALLING}" ]]
    [[ -n "${MSG_GIT_UNINSTALLED}" ]]
    [[ -n "${MSG_GIT_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_GIT_NOT_INSTALLED}" ]]
    [[ -n "${MSG_GIT_STATUS_CHECKING}" ]]
}

@test "Git submenu i18n keys are loaded" {
    [[ -n "${MSG_GIT_MENU_TITLE}" ]]
    [[ -n "${MSG_GIT_MENU_INSTALL}" ]]
    [[ -n "${MSG_GIT_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_GIT_MENU_STATUS}" ]]
    [[ -n "${MSG_GIT_MENU_BACK}" ]]
}

# ── check_git_installed tests ──

@test "check_git_installed returns 1 when git not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_git_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── is_root tests ──

@test "install_git rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_git
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_git rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_git
    [[ "${status}" -ne 0 ]]
}

# ── check_git_status tests ──

@test "check_git_status returns 1 when git not installed" {
    check_git_installed() { return 1; }

    run check_git_status
    [[ "${status}" -ne 0 ]]
}

# ── Submenu display tests ──

@test "show_git_submenu output contains menu title" {
    run show_git_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_GIT_MENU_TITLE}"* ]]
}

@test "show_git_submenu output contains install/uninstall/status options" {
    run show_git_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_GIT_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_GIT_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_GIT_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_GIT_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "git.sh loaded flag is set" {
    [[ "${_GIT_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Git i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_GIT_TITLE}" ]]
    [[ -n "${MSG_GIT_INSTALLING}" ]]
    [[ -n "${MSG_GIT_INSTALLED}" ]]
    [[ -n "${MSG_GIT_CONFIRM}" ]]
    [[ -n "${MSG_GIT_MENU_INSTALL}" ]]
    [[ -n "${MSG_GIT_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

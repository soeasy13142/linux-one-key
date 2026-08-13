#!/usr/bin/env bats
# editor.bats - unit tests for scripts/dev/editor.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 HOME 与编辑器配置路径，避免测试写入真实用户目录
    export HOME="${TEST_DIR}/home"
    export EDITOR_VIMRC="${TEST_DIR}/home/.vimrc"
    export EDITOR_NANORC="${TEST_DIR}/home/.config/nano/nanorc"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}" "${HOME}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/dev/editor.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "editor basic functions are defined" {
    type check_editor_installed
    type install_editor
    type uninstall_editor
    type check_editor_status
    type show_editor_submenu
    type run_editor_submenu_loop
}

# ── i18n key tests (Chinese) ──

@test "Editor Chinese i18n keys are loaded" {
    [[ -n "${MSG_EDITOR_TITLE}" ]]
    [[ -n "${MSG_EDITOR_INSTALLING}" ]]
    [[ -n "${MSG_EDITOR_INSTALLED}" ]]
    [[ -n "${MSG_EDITOR_ALREADY}" ]]
    [[ -n "${MSG_EDITOR_FAILED}" ]]
    [[ -n "${MSG_EDITOR_CANCELLED}" ]]
    [[ -n "${MSG_EDITOR_CONFIRM}" ]]
    [[ -n "${MSG_EDITOR_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_EDITOR_UNINSTALLING}" ]]
    [[ -n "${MSG_EDITOR_UNINSTALLED}" ]]
    [[ -n "${MSG_EDITOR_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_EDITOR_NOT_INSTALLED}" ]]
    [[ -n "${MSG_EDITOR_STATUS_CHECKING}" ]]
    [[ -n "${MSG_STATUS_INSTALLED}" ]]
    [[ -n "${MSG_STATUS_NOT_INSTALLED}" ]]
}

@test "Editor submenu i18n keys are loaded" {
    [[ -n "${MSG_EDITOR_MENU_TITLE}" ]]
    [[ -n "${MSG_EDITOR_MENU_INSTALL}" ]]
    [[ -n "${MSG_EDITOR_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_EDITOR_MENU_STATUS}" ]]
    [[ -n "${MSG_EDITOR_MENU_BACK}" ]]
}

# ── Config path tests ──

@test "editor config paths are overridable" {
    [[ "${EDITOR_VIMRC}" == "${TEST_DIR}/home/.vimrc" ]]
    [[ "${EDITOR_NANORC}" == "${TEST_DIR}/home/.config/nano/nanorc" ]]
}

# ── check_editor_installed tests ──

@test "check_editor_installed returns 1 when vim and nano not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_editor_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── is_root tests ──

@test "install_editor rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_editor
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_editor rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_editor
    [[ "${status}" -ne 0 ]]
}

# ── check_editor_status tests ──

@test "check_editor_status returns 1 when editor not installed" {
    check_editor_installed() { return 1; }

    run check_editor_status
    [[ "${status}" -ne 0 ]]
}

# ── Submenu display tests ──

@test "show_editor_submenu output contains menu title" {
    run show_editor_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_EDITOR_MENU_TITLE}"* ]]
}

@test "show_editor_submenu output contains install/uninstall/status options" {
    run show_editor_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_EDITOR_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_EDITOR_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_EDITOR_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_EDITOR_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "editor.sh loaded flag is set" {
    [[ "${_EDITOR_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Editor i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_EDITOR_TITLE}" ]]
    [[ -n "${MSG_EDITOR_INSTALLING}" ]]
    [[ -n "${MSG_EDITOR_INSTALLED}" ]]
    [[ -n "${MSG_EDITOR_STATUS_CHECKING}" ]]
    [[ -n "${MSG_EDITOR_CONFIRM}" ]]
    [[ -n "${MSG_EDITOR_MENU_INSTALL}" ]]
    [[ -n "${MSG_EDITOR_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

#!/usr/bin/env bats
# grafana.bats - unit tests for scripts/server/grafana.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 grafana.ini 路径，避免测试写 /etc/grafana
    export GRAFANA_INI="${TEST_DIR}/etc/grafana/grafana.ini"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/grafana.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "grafana basic functions are defined" {
    type check_grafana_installed
    type check_grafana_running
    type install_grafana
    type uninstall_grafana
    type check_grafana_status
    type show_grafana_submenu
    type run_grafana_submenu_loop
    type _write_grafana_hardening
    type _install_grafana_pkg
}

# ── i18n key tests (Chinese) ──

@test "Grafana Chinese i18n keys are loaded" {
    [[ -n "${MSG_GRAFANA_TITLE}" ]]
    [[ -n "${MSG_GRAFANA_INSTALLING}" ]]
    [[ -n "${MSG_GRAFANA_INSTALLED}" ]]
    [[ -n "${MSG_GRAFANA_ALREADY}" ]]
    [[ -n "${MSG_GRAFANA_FAILED}" ]]
    [[ -n "${MSG_GRAFANA_CANCELLED}" ]]
    [[ -n "${MSG_GRAFANA_CONFIRM}" ]]
    [[ -n "${MSG_GRAFANA_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_GRAFANA_UNINSTALLING}" ]]
    [[ -n "${MSG_GRAFANA_UNINSTALLED}" ]]
    [[ -n "${MSG_GRAFANA_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_GRAFANA_NOT_INSTALLED}" ]]
    [[ -n "${MSG_GRAFANA_STATUS_CHECKING}" ]]
    [[ -n "${MSG_GRAFANA_STATUS_RUNNING}" ]]
    [[ -n "${MSG_GRAFANA_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_GRAFANA_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_GRAFANA_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_GRAFANA_CONFIG_MISSING}" ]]
    [[ -n "${MSG_GRAFANA_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_GRAFANA_ENABLE_FAILED}" ]]
}

@test "Grafana submenu i18n keys are loaded" {
    [[ -n "${MSG_GRAFANA_MENU_TITLE}" ]]
    [[ -n "${MSG_GRAFANA_MENU_INSTALL}" ]]
    [[ -n "${MSG_GRAFANA_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_GRAFANA_MENU_STATUS}" ]]
    [[ -n "${MSG_GRAFANA_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Grafana constants are defined correctly" {
    [[ -n "${GRAFANA_SERVICE}" ]]
    [[ "${GRAFANA_SERVICE}" == "grafana-server" ]]
    [[ -n "${GRAFANA_INI}" ]]
    [[ "${GRAFANA_INI}" == "${TEST_DIR}/etc/grafana/grafana.ini" ]]
}

# ── check_grafana_installed tests ──

@test "check_grafana_installed returns 1 when grafana not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_grafana_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_grafana_running tests ──

@test "check_grafana_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_grafana_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_grafana rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_grafana
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_grafana rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_grafana
    [[ "${status}" -ne 0 ]]
}

# ── check_grafana_status tests ──

@test "check_grafana_status returns 1 when grafana not installed" {
    check_grafana_installed() { return 1; }

    run check_grafana_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_grafana_hardening tests ──

@test "_write_grafana_hardening writes hardening keys when ini absent" {
    run _write_grafana_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${GRAFANA_INI}" ]]
    grep -q '^http_addr = 127.0.0.1' "${GRAFANA_INI}"
    grep -q '^enabled = false' "${GRAFANA_INI}"
}

@test "_write_grafana_hardening is idempotent (no duplicate keys)" {
    run _write_grafana_hardening
    run _write_grafana_hardening
    [[ "${status}" -eq 0 ]]

    grep -q '^http_addr = 127.0.0.1' "${GRAFANA_INI}"
    grep -q '^enabled = false' "${GRAFANA_INI}"
    [[ "$(grep -c '^http_addr = ' "${GRAFANA_INI}")" -eq 1 ]]
    [[ "$(grep -c '^enabled = ' "${GRAFANA_INI}")" -eq 1 ]]
}

@test "_write_grafana_hardening preserves existing config and backs it up" {
    mkdir -p "$(dirname "${GRAFANA_INI}")"
    cat > "${GRAFANA_INI}" <<'EOF'
[server]
# custom server setting
custom_server = keep-me

[auth.anonymous]
enabled = true
EOF

    run _write_grafana_hardening
    [[ "${status}" -eq 0 ]]

    grep -q '^custom_server = keep-me' "${GRAFANA_INI}"
    grep -q '^http_addr = 127.0.0.1' "${GRAFANA_INI}"
    grep -q '^enabled = false' "${GRAFANA_INI}"
    [[ -n "$(find "${BACKUP_DIR}" -name 'grafana.ini.bak.*' -print -quit)" ]]
}

# ── Submenu display tests ──

@test "show_grafana_submenu output contains menu title" {
    run show_grafana_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_GRAFANA_MENU_TITLE}"* ]]
}

@test "show_grafana_submenu output contains install/uninstall/status options" {
    run show_grafana_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_GRAFANA_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_GRAFANA_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_GRAFANA_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_GRAFANA_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "grafana.sh loaded flag is set" {
    [[ "${_GRAFANA_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Grafana i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_GRAFANA_TITLE}" ]]
    [[ -n "${MSG_GRAFANA_INSTALLING}" ]]
    [[ -n "${MSG_GRAFANA_INSTALLED}" ]]
    [[ -n "${MSG_GRAFANA_STATUS_RUNNING}" ]]
    [[ -n "${MSG_GRAFANA_CONFIRM}" ]]
    [[ -n "${MSG_GRAFANA_MENU_INSTALL}" ]]
    [[ -n "${MSG_GRAFANA_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

#!/usr/bin/env bats
# nginx.bats - unit tests for scripts/server/nginx.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖安全头配置文件路径，避免测试写 /etc/nginx
    export NGINX_SECURITY_CONF="${TEST_DIR}/etc/nginx/conf.d/security-headers.conf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/nginx.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "nginx basic functions are defined" {
    type check_nginx_installed
    type check_nginx_running
    type install_nginx
    type uninstall_nginx
    type check_nginx_status
    type show_nginx_submenu
    type run_nginx_submenu_loop
    type _write_security_headers
    type _install_nginx_pkg
}

# ── i18n key tests (Chinese) ──

@test "Nginx Chinese i18n keys are loaded" {
    [[ -n "${MSG_NGINX_TITLE}" ]]
    [[ -n "${MSG_NGINX_INSTALLING}" ]]
    [[ -n "${MSG_NGINX_INSTALLED}" ]]
    [[ -n "${MSG_NGINX_ALREADY}" ]]
    [[ -n "${MSG_NGINX_FAILED}" ]]
    [[ -n "${MSG_NGINX_CONFIRM}" ]]
    [[ -n "${MSG_NGINX_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_NGINX_UNINSTALLED}" ]]
    [[ -n "${MSG_NGINX_NOT_INSTALLED}" ]]
    [[ -n "${MSG_NGINX_STATUS_RUNNING}" ]]
    [[ -n "${MSG_NGINX_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_NGINX_SECURITY_HEADERS_WRITTEN}" ]]
    [[ -n "${MSG_NGINX_SECURITY_HEADERS_MISSING}" ]]
    [[ -n "${MSG_NGINX_HSTS_PROMPT}" ]]
}

@test "Nginx submenu i18n keys are loaded" {
    [[ -n "${MSG_NGINX_MENU_TITLE}" ]]
    [[ -n "${MSG_NGINX_MENU_INSTALL}" ]]
    [[ -n "${MSG_NGINX_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_NGINX_MENU_STATUS}" ]]
    [[ -n "${MSG_NGINX_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Nginx constants are defined correctly" {
    [[ -n "${NGINX_SERVICE}" ]]
    [[ "${NGINX_SERVICE}" == "nginx" ]]
}

# ── check_nginx_installed tests ──

@test "check_nginx_installed returns 1 when nginx not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_nginx_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_nginx_running tests ──

@test "check_nginx_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_nginx_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_nginx rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_nginx
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_nginx rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_nginx
    [[ "${status}" -ne 0 ]]
}

# ── check_nginx_status tests ──

@test "check_nginx_status returns 1 when nginx not installed" {
    check_nginx_installed() { return 1; }

    run check_nginx_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_security_headers tests ──

@test "_write_security_headers writes conservative baseline when absent" {
    run _write_security_headers 0
    [[ "${status}" -eq 0 ]]

    [[ -f "${NGINX_SECURITY_CONF}" ]]
    grep -q 'server_tokens off;' "${NGINX_SECURITY_CONF}"
    grep -q 'X-Frame-Options' "${NGINX_SECURITY_CONF}"
    grep -q 'X-Content-Type-Options' "${NGINX_SECURITY_CONF}"
    ! grep -q 'Strict-Transport-Security' "${NGINX_SECURITY_CONF}"
}

@test "_write_security_headers adds HSTS when enable_hsts=1" {
    run _write_security_headers 1
    [[ "${status}" -eq 0 ]]

    grep -q 'Strict-Transport-Security' "${NGINX_SECURITY_CONF}"
}

@test "_write_security_headers preserves existing config and backs it up" {
    mkdir -p "$(dirname "${NGINX_SECURITY_CONF}")"
    printf '# custom\n' > "${NGINX_SECURITY_CONF}"

    run _write_security_headers 0
    [[ "${status}" -eq 0 ]]

    grep -q '# custom' "${NGINX_SECURITY_CONF}"
    ! grep -q 'server_tokens off;' "${NGINX_SECURITY_CONF}"
    [[ -n "$(find "${BACKUP_DIR}" -name 'security-headers.conf.bak.*' -print -quit)" ]]
}

# ── Submenu display tests ──

@test "show_nginx_submenu output contains menu title" {
    run show_nginx_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_NGINX_MENU_TITLE}"* ]]
}

@test "show_nginx_submenu output contains install/uninstall/status options" {
    run show_nginx_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_NGINX_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_NGINX_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_NGINX_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_NGINX_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "nginx.sh loaded flag is set" {
    [[ "${_NGINX_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Nginx i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_NGINX_TITLE}" ]]
    [[ -n "${MSG_NGINX_INSTALLING}" ]]
    [[ -n "${MSG_NGINX_INSTALLED}" ]]
    [[ -n "${MSG_NGINX_STATUS_RUNNING}" ]]
    [[ -n "${MSG_NGINX_CONFIRM}" ]]
    [[ -n "${MSG_NGINX_MENU_INSTALL}" ]]
    [[ -n "${MSG_NGINX_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

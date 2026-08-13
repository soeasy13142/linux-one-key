#!/usr/bin/env bats
# prometheus.bats - unit tests for scripts/server/prometheus.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 drop-in 路径，避免测试写 /etc/systemd/system
    export PROMETHEUS_DROPIN="${TEST_DIR}/etc/systemd/system/prometheus.service.d/listen.conf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/prometheus.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "prometheus basic functions are defined" {
    type check_prometheus_installed
    type check_prometheus_running
    type install_prometheus
    type uninstall_prometheus
    type check_prometheus_status
    type show_prometheus_submenu
    type run_prometheus_submenu_loop
    type _write_prometheus_hardening
    type _install_prometheus_pkg
}

# ── i18n key tests (Chinese) ──

@test "Prometheus Chinese i18n keys are loaded" {
    [[ -n "${MSG_PROMETHEUS_TITLE}" ]]
    [[ -n "${MSG_PROMETHEUS_INSTALLING}" ]]
    [[ -n "${MSG_PROMETHEUS_INSTALLED}" ]]
    [[ -n "${MSG_PROMETHEUS_ALREADY}" ]]
    [[ -n "${MSG_PROMETHEUS_FAILED}" ]]
    [[ -n "${MSG_PROMETHEUS_CANCELLED}" ]]
    [[ -n "${MSG_PROMETHEUS_CONFIRM}" ]]
    [[ -n "${MSG_PROMETHEUS_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_PROMETHEUS_UNINSTALLING}" ]]
    [[ -n "${MSG_PROMETHEUS_UNINSTALLED}" ]]
    [[ -n "${MSG_PROMETHEUS_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_PROMETHEUS_NOT_INSTALLED}" ]]
    [[ -n "${MSG_PROMETHEUS_STATUS_CHECKING}" ]]
    [[ -n "${MSG_PROMETHEUS_STATUS_RUNNING}" ]]
    [[ -n "${MSG_PROMETHEUS_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_PROMETHEUS_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_PROMETHEUS_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_PROMETHEUS_CONFIG_MISSING}" ]]
    [[ -n "${MSG_PROMETHEUS_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_PROMETHEUS_ENABLE_FAILED}" ]]
}

@test "Prometheus submenu i18n keys are loaded" {
    [[ -n "${MSG_PROMETHEUS_MENU_TITLE}" ]]
    [[ -n "${MSG_PROMETHEUS_MENU_INSTALL}" ]]
    [[ -n "${MSG_PROMETHEUS_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_PROMETHEUS_MENU_STATUS}" ]]
    [[ -n "${MSG_PROMETHEUS_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Prometheus constants are defined correctly" {
    [[ -n "${PROMETHEUS_SERVICE}" ]]
    [[ "${PROMETHEUS_SERVICE}" == "prometheus" ]]
    [[ -n "${PROMETHEUS_DROPIN}" ]]
    [[ "${PROMETHEUS_DROPIN}" == "${TEST_DIR}/etc/systemd/system/prometheus.service.d/listen.conf" ]]
}

# ── check_prometheus_installed tests ──

@test "check_prometheus_installed returns 1 when prometheus not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_prometheus_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_prometheus_running tests ──

@test "check_prometheus_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_prometheus_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_prometheus rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_prometheus
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_prometheus rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_prometheus
    [[ "${status}" -ne 0 ]]
}

# ── check_prometheus_status tests ──

@test "check_prometheus_status returns 1 when prometheus not installed" {
    check_prometheus_installed() { return 1; }

    run check_prometheus_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_prometheus_hardening tests ──

@test "_write_prometheus_hardening writes localhost bind baseline when absent" {
    run _write_prometheus_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${PROMETHEUS_DROPIN}" ]]
    grep -q '\[Service\]' "${PROMETHEUS_DROPIN}"
    grep -q '127.0.0.1' "${PROMETHEUS_DROPIN}"
    grep -q -- '--web.listen-address=127.0.0.1:9090' "${PROMETHEUS_DROPIN}"
}

@test "_write_prometheus_hardening preserves existing drop-in and backs it up" {
    mkdir -p "$(dirname "${PROMETHEUS_DROPIN}")"
    printf '# custom listen\n' > "${PROMETHEUS_DROPIN}"

    run _write_prometheus_hardening
    [[ "${status}" -eq 0 ]]

    # 原内容不被覆盖
    grep -q '# custom listen' "${PROMETHEUS_DROPIN}"
    ! grep -q '127.0.0.1' "${PROMETHEUS_DROPIN}"
    # 已生成备份
    [[ -n "$(find "${BACKUP_DIR}" -name 'listen.conf.bak.*' -print -quit)" ]]
}

# ── Submenu display tests ──

@test "show_prometheus_submenu output contains menu title" {
    run show_prometheus_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_PROMETHEUS_MENU_TITLE}"* ]]
}

@test "show_prometheus_submenu output contains install/uninstall/status options" {
    run show_prometheus_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_PROMETHEUS_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_PROMETHEUS_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_PROMETHEUS_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_PROMETHEUS_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "prometheus.sh loaded flag is set" {
    [[ "${_PROMETHEUS_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Prometheus i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_PROMETHEUS_TITLE}" ]]
    [[ -n "${MSG_PROMETHEUS_INSTALLING}" ]]
    [[ -n "${MSG_PROMETHEUS_INSTALLED}" ]]
    [[ -n "${MSG_PROMETHEUS_STATUS_RUNNING}" ]]
    [[ -n "${MSG_PROMETHEUS_CONFIRM}" ]]
    [[ -n "${MSG_PROMETHEUS_MENU_INSTALL}" ]]
    [[ -n "${MSG_PROMETHEUS_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

#!/usr/bin/env bats
# node_exporter.bats - unit tests for scripts/server/node_exporter.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 systemd drop-in 路径，避免测试写 /etc/systemd
    export NODE_EXPORTER_DROPIN="${TEST_DIR}/etc/systemd/system/node_exporter.service.d/hardening.conf"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/node_exporter.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "node_exporter basic functions are defined" {
    type check_node_exporter_installed
    type check_node_exporter_running
    type install_node_exporter
    type uninstall_node_exporter
    type check_node_exporter_status
    type show_node_exporter_submenu
    type run_node_exporter_submenu_loop
    type _write_node_exporter_hardening
    type _install_node_exporter_pkg
}

# ── i18n key tests (Chinese) ──

@test "Node Exporter Chinese i18n keys are loaded" {
    [[ -n "${MSG_NODE_EXPORTER_TITLE}" ]]
    [[ -n "${MSG_NODE_EXPORTER_INSTALLING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_INSTALLED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_ALREADY}" ]]
    [[ -n "${MSG_NODE_EXPORTER_FAILED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CANCELLED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CONFIRM}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_NODE_EXPORTER_UNINSTALLING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_UNINSTALLED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_NOT_INSTALLED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_STATUS_CHECKING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_STATUS_RUNNING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CONFIG_WRITTEN}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CONFIG_EXISTS}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CONFIG_MISSING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_BACKUP_CONFIG}" ]]
    [[ -n "${MSG_NODE_EXPORTER_ENABLE_FAILED}" ]]
}

@test "Node Exporter submenu i18n keys are loaded" {
    [[ -n "${MSG_NODE_EXPORTER_MENU_TITLE}" ]]
    [[ -n "${MSG_NODE_EXPORTER_MENU_INSTALL}" ]]
    [[ -n "${MSG_NODE_EXPORTER_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_NODE_EXPORTER_MENU_STATUS}" ]]
    [[ -n "${MSG_NODE_EXPORTER_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Node Exporter constants are defined correctly" {
    [[ -n "${NODE_EXPORTER_SERVICE}" ]]
    [[ "${NODE_EXPORTER_SERVICE}" == "node_exporter" ]]
    [[ -n "${NODE_EXPORTER_DROPIN}" ]]
    [[ "${NODE_EXPORTER_DROPIN}" == "${TEST_DIR}"* ]]
}

# ── check_node_exporter_installed tests ──

@test "check_node_exporter_installed returns 1 when node_exporter not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_node_exporter_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_node_exporter_running tests ──

@test "check_node_exporter_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_node_exporter_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_node_exporter rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_node_exporter
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_node_exporter rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_node_exporter
    [[ "${status}" -ne 0 ]]
}

# ── check_node_exporter_status tests ──

@test "check_node_exporter_status returns 1 when node_exporter not installed" {
    check_node_exporter_installed() { return 1; }

    run check_node_exporter_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_node_exporter_hardening tests ──

@test "_write_node_exporter_hardening writes baseline when absent" {
    run _write_node_exporter_hardening
    [[ "${status}" -eq 0 ]]

    [[ -f "${NODE_EXPORTER_DROPIN}" ]]
    grep -q '^NoNewPrivileges=yes$' "${NODE_EXPORTER_DROPIN}"
    grep -q '^ProtectSystem=full$' "${NODE_EXPORTER_DROPIN}"
    grep -q '^ProtectHome=yes$' "${NODE_EXPORTER_DROPIN}"
    grep -q '^PrivateTmp=yes$' "${NODE_EXPORTER_DROPIN}"
    grep -q '^RestrictSUIDSGID=yes$' "${NODE_EXPORTER_DROPIN}"
}

@test "_write_node_exporter_hardening preserves existing hardening and is idempotent" {
    mkdir -p "$(dirname "${NODE_EXPORTER_DROPIN}")"
    printf '[Service]\nNoNewPrivileges=yes\n# custom\n' > "${NODE_EXPORTER_DROPIN}"

    run _write_node_exporter_hardening
    [[ "${status}" -eq 0 ]]

    # 原内容不被覆盖，且不重复写入 NoNewPrivileges
    grep -q '# custom' "${NODE_EXPORTER_DROPIN}"
    [[ "$(grep -c 'NoNewPrivileges' "${NODE_EXPORTER_DROPIN}")" -eq 1 ]]
}

# ── Submenu display tests ──

@test "show_node_exporter_submenu output contains menu title" {
    run show_node_exporter_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_NODE_EXPORTER_MENU_TITLE}"* ]]
}

@test "show_node_exporter_submenu output contains install/uninstall/status options" {
    run show_node_exporter_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_NODE_EXPORTER_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_NODE_EXPORTER_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_NODE_EXPORTER_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_NODE_EXPORTER_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "node_exporter.sh loaded flag is set" {
    [[ "${_NODE_EXPORTER_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Node Exporter i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_NODE_EXPORTER_TITLE}" ]]
    [[ -n "${MSG_NODE_EXPORTER_INSTALLING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_INSTALLED}" ]]
    [[ -n "${MSG_NODE_EXPORTER_STATUS_RUNNING}" ]]
    [[ -n "${MSG_NODE_EXPORTER_CONFIRM}" ]]
    [[ -n "${MSG_NODE_EXPORTER_MENU_INSTALL}" ]]
    [[ -n "${MSG_NODE_EXPORTER_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

# ── Distro-aware name helpers ──

@test "_node_exporter_bin returns prometheus-node-exporter on Debian/Ubuntu" {
    DETECTED_OS="ubuntu"
    run _node_exporter_bin
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "prometheus-node-exporter" ]]
}

@test "_node_exporter_service returns node_exporter on RHEL family" {
    DETECTED_OS="rocky"
    run _node_exporter_service
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "node_exporter" ]]
}

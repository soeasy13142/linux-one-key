#!/usr/bin/env bats
# k3s.bats - unit tests for scripts/server/k3s.sh

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

    source "${SCRIPT_DIR}/scripts/server/k3s.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "k3s basic functions are defined" {
    type check_k3s_installed
    type check_k3s_running
    type install_k3s
    type uninstall_k3s
    type check_k3s_status
    type show_k3s_submenu
    type run_k3s_submenu_loop
}

@test "k3s internal functions are defined" {
    type _setup_kubectl_access
    type _show_k3s_cluster_info
}

# ── i18n key tests (Chinese) ──

@test "K3s Chinese i18n keys are loaded" {
    [[ -n "${MSG_K3S_TITLE}" ]]
    [[ -n "${MSG_K3S_INSTALLING}" ]]
    [[ -n "${MSG_K3S_INSTALLED}" ]]
    [[ -n "${MSG_K3S_ALREADY}" ]]
    [[ -n "${MSG_K3S_FAILED}" ]]
    [[ -n "${MSG_K3S_UNINSTALLING}" ]]
    [[ -n "${MSG_K3S_UNINSTALLED}" ]]
    [[ -n "${MSG_K3S_STATUS_CHECKING}" ]]
    [[ -n "${MSG_K3S_STATUS_RUNNING}" ]]
    [[ -n "${MSG_K3S_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_K3S_CONFIRM}" ]]
    [[ -n "${MSG_K3S_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_K3S_KUBECONFIG}" ]]
    [[ -n "${MSG_K3S_KUBECONFIG_EXISTS}" ]]
    [[ -n "${MSG_K3S_NODE_READY}" ]]
    [[ -n "${MSG_K3S_DISABLE_TRAEFIK}" ]]
    [[ -n "${MSG_K3S_DISABLE_TRAEFIK_PROMPT}" ]]
    [[ -n "${MSG_K3S_VERSION}" ]]
    [[ -n "${MSG_K3S_NOT_INSTALLED}" ]]
    [[ -n "${MSG_K3S_CURL_REQUIRED}" ]]
    [[ -n "${MSG_K3S_DOWNLOADING}" ]]
    [[ -n "${MSG_K3S_CANCELLED}" ]]
    [[ -n "${MSG_K3S_UNINSTALL_FAILED}" ]]
    [[ -n "${MSG_K3S_UNINSTALL_SCRIPT_NOT_FOUND}" ]]
    [[ -n "${MSG_K3S_CONFIGURING}" ]]
    [[ -n "${MSG_K3S_NODES_UNAVAILABLE}" ]]
    [[ -n "${MSG_K3S_BINARY}" ]]
}

@test "K3s submenu i18n keys are loaded" {
    [[ -n "${MSG_K3S_MENU_TITLE}" ]]
    [[ -n "${MSG_K3S_MENU_INSTALL}" ]]
    [[ -n "${MSG_K3S_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_K3S_MENU_STATUS}" ]]
    [[ -n "${MSG_K3S_MENU_BACK}" ]]
}

@test "K3s main menu i18n keys are loaded" {
    [[ -n "${MSG_MAIN_MENU_K3S}" ]]
    [[ -n "${MSG_MAIN_MENU_K3S_DESC}" ]]
    [[ -n "${MSG_SECTION_SERVER}" ]]
}

# ── Constant tests ──

@test "K3s constants are defined correctly" {
    [[ -n "${K3S_INSTALL_URL}" ]]
    [[ -n "${K3S_UNINSTALL_SCRIPT}" ]]
    [[ -n "${K3S_BIN}" ]]
    [[ -n "${K3S_KUBECONFIG}" ]]
    [[ -n "${K3S_SERVICE}" ]]

    [[ "${K3S_INSTALL_URL}" == "https://get.k3s.io" ]]
    [[ "${K3S_UNINSTALL_SCRIPT}" == "/usr/local/bin/k3s-uninstall.sh" ]]
    [[ "${K3S_BIN}" == "/usr/local/bin/k3s" ]]
    [[ "${K3S_SERVICE}" == "k3s" ]]
}

# ── check_k3s_installed tests ──

@test "check_k3s_installed returns 1 when k3s not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_k3s_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

@test "check_k3s_installed returns 1 when K3S_BIN does not exist" {
    command() {
        [[ "$1" == "-v" ]] && [[ "$2" == "k3s" ]] && return 1
        return 1
    }

    run check_k3s_installed
    [[ "${status}" -ne 0 ]]
}

# ── check_k3s_running tests ──

@test "check_k3s_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_k3s_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_k3s rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_k3s
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_k3s rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_k3s
    [[ "${status}" -ne 0 ]]
}

# ── check_k3s_status tests ──

@test "check_k3s_status returns 1 when k3s not installed" {
    run check_k3s_status
    [[ "${status}" -ne 0 ]]
}

# ── _setup_kubectl_access tests ──

@test "_setup_kubectl_access skips when kubeconfig does not exist" {
    [[ ! -f "${K3S_KUBECONFIG}" ]] || skip "K3S_KUBECONFIG exists on this system"

    run _setup_kubectl_access
    [[ "${status}" -eq 0 ]]
}

# ── Submenu display tests ──

@test "show_k3s_submenu output contains menu title" {
    run show_k3s_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_K3S_MENU_TITLE}"* ]]
}

@test "show_k3s_submenu output contains install/uninstall/status options" {
    run show_k3s_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_K3S_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_K3S_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_K3S_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_K3S_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "k3s.sh loaded flag is set" {
    [[ "${_K3S_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English K3s i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_K3S_TITLE}" ]]
    [[ -n "${MSG_K3S_INSTALLING}" ]]
    [[ -n "${MSG_K3S_INSTALLED}" ]]
    [[ -n "${MSG_K3S_STATUS_RUNNING}" ]]
    [[ -n "${MSG_K3S_CONFIRM}" ]]
    [[ -n "${MSG_K3S_MENU_INSTALL}" ]]
    [[ -n "${MSG_K3S_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

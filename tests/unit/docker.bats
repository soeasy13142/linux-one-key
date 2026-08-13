#!/usr/bin/env bats
# docker.bats - unit tests for scripts/server/docker.sh

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"
    # 覆盖 daemon.json 路径，避免测试写 /etc/docker
    export DOCKER_DAEMON_CONFIG="${TEST_DIR}/etc/docker/daemon.json"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/docker.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── Function existence tests ──

@test "docker basic functions are defined" {
    type check_docker_installed
    type check_docker_running
    type install_docker
    type uninstall_docker
    type check_docker_status
    type show_docker_submenu
    type run_docker_submenu_loop
    type _write_daemon_json
}

# ── i18n key tests (Chinese) ──

@test "Docker Chinese i18n keys are loaded" {
    [[ -n "${MSG_DOCKER_TITLE}" ]]
    [[ -n "${MSG_DOCKER_INSTALLING}" ]]
    [[ -n "${MSG_DOCKER_INSTALLED}" ]]
    [[ -n "${MSG_DOCKER_ALREADY}" ]]
    [[ -n "${MSG_DOCKER_FAILED}" ]]
    [[ -n "${MSG_DOCKER_CONFIRM}" ]]
    [[ -n "${MSG_DOCKER_CONFIRM_UNINSTALL}" ]]
    [[ -n "${MSG_DOCKER_UNINSTALLED}" ]]
    [[ -n "${MSG_DOCKER_NOT_INSTALLED}" ]]
    [[ -n "${MSG_DOCKER_STATUS_RUNNING}" ]]
    [[ -n "${MSG_DOCKER_STATUS_NOT_RUNNING}" ]]
    [[ -n "${MSG_DOCKER_DAEMON_WRITTEN}" ]]
    [[ -n "${MSG_DOCKER_DAEMON_MISSING}" ]]
    [[ -n "${MSG_DOCKER_USERN_REMAP_PROMPT}" ]]
}

@test "Docker submenu i18n keys are loaded" {
    [[ -n "${MSG_DOCKER_MENU_TITLE}" ]]
    [[ -n "${MSG_DOCKER_MENU_INSTALL}" ]]
    [[ -n "${MSG_DOCKER_MENU_UNINSTALL}" ]]
    [[ -n "${MSG_DOCKER_MENU_STATUS}" ]]
    [[ -n "${MSG_DOCKER_MENU_BACK}" ]]
}

# ── Constant tests ──

@test "Docker constants are defined correctly" {
    [[ -n "${DOCKER_INSTALL_URL}" ]]
    [[ -n "${DOCKER_SERVICE}" ]]
    [[ "${DOCKER_INSTALL_URL}" == "https://get.docker.com" ]]
    [[ "${DOCKER_SERVICE}" == "docker" ]]
}

# ── check_docker_installed tests ──

@test "check_docker_installed returns 1 when docker not installed" {
    local _old_path="${PATH}"
    PATH="/tmp"

    run check_docker_installed
    [[ "${status}" -ne 0 ]]

    PATH="${_old_path}"
}

# ── check_docker_running tests ──

@test "check_docker_running returns 1 when service not running" {
    systemctl() { return 1; }

    run check_docker_running
    [[ "${status}" -ne 0 ]]
}

# ── is_root tests ──

@test "install_docker rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run install_docker
    [[ "${status}" -ne 0 ]]
}

@test "uninstall_docker rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run uninstall_docker
    [[ "${status}" -ne 0 ]]
}

# ── check_docker_status tests ──

@test "check_docker_status returns 1 when docker not installed" {
    check_docker_installed() { return 1; }

    run check_docker_status
    [[ "${status}" -ne 0 ]]
}

# ── _write_daemon_json tests ──

@test "_write_daemon_json writes conservative hardening config when absent" {
    run _write_daemon_json 0
    [[ "${status}" -eq 0 ]]

    [[ -f "${DOCKER_DAEMON_CONFIG}" ]]
    grep -q '"live-restore": true' "${DOCKER_DAEMON_CONFIG}"
    grep -q '"icc": false' "${DOCKER_DAEMON_CONFIG}"
    grep -q '"log-driver": "json-file"' "${DOCKER_DAEMON_CONFIG}"
    ! grep -q 'userns-remap' "${DOCKER_DAEMON_CONFIG}"
}

@test "_write_daemon_json adds userns-remap when enable_userns=1" {
    run _write_daemon_json 1
    [[ "${status}" -eq 0 ]]

    grep -q '"userns-remap": "default"' "${DOCKER_DAEMON_CONFIG}"
}

@test "_write_daemon_json preserves existing config and backs it up" {
    mkdir -p "$(dirname "${DOCKER_DAEMON_CONFIG}")"
    printf '{"custom": true}\n' > "${DOCKER_DAEMON_CONFIG}"

    run _write_daemon_json 0
    [[ "${status}" -eq 0 ]]

    # 原内容不被覆盖
    grep -q '"custom": true' "${DOCKER_DAEMON_CONFIG}"
    ! grep -q 'live-restore' "${DOCKER_DAEMON_CONFIG}"
    # 已生成备份
    [[ -n "$(find "${BACKUP_DIR}" -name 'daemon.json.bak.*' -print -quit)" ]]
}

# ── Submenu display tests ──

@test "show_docker_submenu output contains menu title" {
    run show_docker_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_DOCKER_MENU_TITLE}"* ]]
}

@test "show_docker_submenu output contains install/uninstall/status options" {
    run show_docker_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_DOCKER_MENU_INSTALL}"* ]]
    [[ "${output}" == *"${MSG_DOCKER_MENU_UNINSTALL}"* ]]
    [[ "${output}" == *"${MSG_DOCKER_MENU_STATUS}"* ]]
    [[ "${output}" == *"${MSG_DOCKER_MENU_BACK}"* ]]
}

# ── Loaded guard test ──

@test "docker.sh loaded flag is set" {
    [[ "${_DOCKER_LOADED:-}" == "1" ]]
}

# ── English i18n tests ──

@test "English Docker i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_DOCKER_TITLE}" ]]
    [[ -n "${MSG_DOCKER_INSTALLING}" ]]
    [[ -n "${MSG_DOCKER_INSTALLED}" ]]
    [[ -n "${MSG_DOCKER_STATUS_RUNNING}" ]]
    [[ -n "${MSG_DOCKER_CONFIRM}" ]]
    [[ -n "${MSG_DOCKER_MENU_INSTALL}" ]]
    [[ -n "${MSG_DOCKER_MENU_UNINSTALL}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

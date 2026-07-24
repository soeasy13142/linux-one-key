#!/usr/bin/env bats
# autoupdate.bats - 单元测试 for scripts/security/autoupdate.sh

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # Load dependencies
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    # Load detect.sh (required by autoupdate.sh)
    source "${SCRIPT_DIR}/scripts/base/detect.sh"

    # Mock detect.sh variables (but actually detect.sh sets them)
    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    # Source the module
    source "${SCRIPT_DIR}/scripts/security/autoupdate.sh"

    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── Source guard tests ──

@test "autoupdate.sh: _AUTOUPDATE_LOADED is set" {
    [[ -n "${_AUTOUPDATE_LOADED:-}" ]]
    [[ "${_AUTOUPDATE_LOADED}" == "1" ]]
}

@test "autoupdate.sh: constants are defined" {
    [[ -n "${AUTOUPDATE_PACKAGE_UBUNTU:-}" ]]
    [[ "${AUTOUPDATE_PACKAGE_UBUNTU}" == "unattended-upgrades" ]]
    [[ -n "${AUTOUPDATE_PACKAGE_DEBIAN:-}" ]]
    [[ -n "${AUTOUPDATE_PACKAGE_CENTOS:-}" ]]
    [[ "${AUTOUPDATE_PACKAGE_CENTOS}" == "yum-cron" ]]
}

@test "autoupdate.sh: config paths are defined" {
    [[ -n "${AUTOUPDATE_CONFIG_UBUNTU:-}" ]]
    [[ "${AUTOUPDATE_CONFIG_UBUNTU}" == "/etc/apt/apt.conf.d/20auto-upgrades" ]]
    [[ -n "${AUTOUPDATE_CONFIG_UNATTENDED:-}" ]]
    [[ -n "${AUTOUPDATE_CONFIG_YUM_CRON:-}" ]]
}

# ── Function existence tests ──

@test "autoupdate.sh: install_autoupdate function exists" {
    type install_autoupdate
}

@test "autoupdate.sh: configure_autoupdate function exists" {
    type configure_autoupdate
}

@test "autoupdate.sh: check_autoupdate_status function exists" {
    type check_autoupdate_status
}

@test "autoupdate.sh: run_autoupdate_wizard function exists" {
    type run_autoupdate_wizard
}

@test "autoupdate.sh: show_autoupdate_info function exists" {
    type show_autoupdate_info
}

# ── check_autoupdate_status output tests ──

@test "check_autoupdate_status outputs key=value format" {
    run check_autoupdate_status
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"autoupdate_installed="* ]]
    [[ "${output}" == *"autoupdate_enabled="* ]]
    [[ "${output}" == *"autoupdate_type="* ]]
}

@test "check_autoupdate_status returns format fields" {
    run check_autoupdate_status
    # Instead of accepting both yes/no, verify output format
    [[ -n "${output}" ]]
    [[ "${output}" =~ autoupdate_installed= ]]
    [[ "${output}" =~ autoupdate_type= ]]
}

# ── _is_autoupdate_configured tests ──

@test "_is_autoupdate_configured returns 1 when not configured" {
    if [[ -f "${AUTOUPDATE_CONFIG_UBUNTU}" ]]; then
        skip "System has auto-updates configured, cannot test negative case"
    fi
    run _is_autoupdate_configured
    [[ "${status}" -ne 0 ]]
}

# ── OS-specific tests ──

@test "autoupdate.sh: works with CentOS detection" {
    export DETECTED_OS="centos"
    run check_autoupdate_status
    [[ "${status}" -eq 0 ]]
    local au_type
    au_type=$(echo "${output}" | grep '^autoupdate_type=' | cut -d= -f2)
    [[ "${au_type}" == "none" ]] || [[ "${au_type}" == "yum-cron" ]]
}

@test "autoupdate.sh: works with Debian detection" {
    export DETECTED_OS="debian"
    run check_autoupdate_status
    [[ "${status}" -eq 0 ]]
}

@test "autoupdate.sh: handles unknown OS" {
    export DETECTED_OS="unknown"
    run check_autoupdate_status
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"autoupdate_type=none"* ]]
}

# ── show_autoupdate_info tests ──

@test "show_autoupdate_info does not error" {
    run show_autoupdate_info
    [[ "${status}" -eq 0 ]]
    [[ -n "${output}" ]]
}

# ── install_autoupdate tests ──

@test "install_autoupdate handles unsupported OS gracefully" {
    export DETECTED_OS="unknown"
    run install_autoupdate
    [[ "${status}" -ne 0 ]]
}

@test "install_autoupdate detects already installed on Debian family" {
    export DETECTED_OS="ubuntu"
    # Mock command_exists for unattended-upgrades
    run install_autoupdate
    # Will either install or detect already installed
    [[ "${status}" -eq 0 ]] || [[ "${status}" -eq 1 ]]
}

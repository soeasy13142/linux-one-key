#!/usr/bin/env bats
# users.bats - 单元测试 for scripts/security/users.sh

# 测试前设置
setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # 先加载依赖模块，再 source 被测模块
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    # 模拟 detect.sh 的变量
    export DETECTED_OS="ubuntu"
    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    source "${SCRIPT_DIR}/scripts/security/users.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── validate_username 测试 ──

@test "validate_username accepts valid username 'admin'" {
    run validate_username "admin"
    [[ "${status}" -eq 0 ]]
}

@test "validate_username accepts valid username 'test_user'" {
    run validate_username "test_user"
    [[ "${status}" -eq 0 ]]
}

@test "validate_username accepts valid username 'dev-01'" {
    run validate_username "dev-01"
    [[ "${status}" -eq 0 ]]
}

@test "validate_username accepts minimum length username 'abc'" {
    run validate_username "abc"
    [[ "${status}" -eq 0 ]]
}

@test "validate_username rejects empty username" {
    run validate_username ""
    [[ "${status}" -ne 0 ]]
}

@test "validate_username rejects too short username 'ab'" {
    run validate_username "ab"
    [[ "${status}" -ne 0 ]]
}

@test "validate_username rejects username starting with number" {
    run validate_username "1admin"
    [[ "${status}" -ne 0 ]]
}

@test "validate_username rejects username with special chars" {
    run validate_username "admin@host"
    [[ "${status}" -ne 0 ]]
}

@test "validate_username rejects username with spaces" {
    run validate_username "admin user"
    [[ "${status}" -ne 0 ]]
}

@test "validate_username accepts maximum length username (32 chars)" {
    local long_name
    long_name=$(printf 'a%.0s' {1..32})
    run validate_username "${long_name}"
    [[ "${status}" -eq 0 ]]
}

@test "validate_username rejects too long username (33 chars)" {
    local long_name
    long_name=$(printf 'a%.0s' {1..33})
    run validate_username "${long_name}"
    [[ "${status}" -ne 0 ]]
}

# ── _check_sudo_group 测试 ──

@test "_check_sudo_group returns 'sudo' for ubuntu" {
    DETECTED_OS="ubuntu"
    run _check_sudo_group
    [[ "${output}" == "sudo" ]]
}

@test "_check_sudo_group returns 'sudo' for debian" {
    DETECTED_OS="debian"
    run _check_sudo_group
    [[ "${output}" == "sudo" ]]
}

@test "_check_sudo_group returns 'wheel' for centos" {
    DETECTED_OS="centos"
    run _check_sudo_group
    [[ "${output}" == "wheel" ]]
}

@test "_check_sudo_group returns 'wheel' for rocky" {
    DETECTED_OS="rocky"
    run _check_sudo_group
    [[ "${output}" == "wheel" ]]
}

@test "_check_sudo_group returns 'wheel' for fedora" {
    DETECTED_OS="fedora"
    run _check_sudo_group
    [[ "${output}" == "wheel" ]]
}

@test "_check_sudo_group returns 'sudo' for unknown OS" {
    DETECTED_OS="unknown"
    run _check_sudo_group
    [[ "${output}" == "sudo" ]]
}

# ── _user_exists 测试 ──

@test "_user_exists returns true for root" {
    run _user_exists "root"
    [[ "${status}" -eq 0 ]]
}

@test "_user_exists returns false for nonexistent user" {
    run _user_exists "nonexistent_user_xyz_12345"
    [[ "${status}" -ne 0 ]]
}

# ── _validate_password_strength 测试 ──

@test "_validate_password_strength accepts strong password" {
    run _validate_password_strength "MyStr0ngPass!"
    [[ "${status}" -eq 0 ]]
}

@test "_validate_password_strength rejects short password" {
    run _validate_password_strength "short"
    [[ "${status}" -ne 0 ]]
}

@test "_validate_password_strength accepts minimum length password" {
    run _validate_password_strength "12345678"
    [[ "${status}" -eq 0 ]]
}

# ── 函数存在性测试 ──

@test "create_admin_user function exists" {
    type -t create_admin_user
    [[ "$(type -t create_admin_user)" == "function" ]]
}

@test "set_user_password function exists" {
    type -t set_user_password
    [[ "$(type -t set_user_password)" == "function" ]]
}

@test "setup_user_ssh_key function exists" {
    type -t setup_user_ssh_key
    [[ "$(type -t setup_user_ssh_key)" == "function" ]]
}

@test "configure_sudo_nopasswd function exists" {
    type -t configure_sudo_nopasswd
    [[ "$(type -t configure_sudo_nopasswd)" == "function" ]]
}

@test "run_users_wizard function exists" {
    type -t run_users_wizard
    [[ "$(type -t run_users_wizard)" == "function" ]]
}

@test "check_users_status function exists" {
    type -t check_users_status
    [[ "$(type -t check_users_status)" == "function" ]]
}

# ── 常量测试 ──

@test "USER_SUDO_GROUP_DEBIAN is 'sudo'" {
    [[ "${USER_SUDO_GROUP_DEBIAN}" == "sudo" ]]
}

@test "USER_SUDO_GROUP_RHEL is 'wheel'" {
    [[ "${USER_SUDO_GROUP_RHEL}" == "wheel" ]]
}

@test "USER_MIN_NAME_LEN is 3" {
    [[ "${USER_MIN_NAME_LEN}" -eq 3 ]]
}

@test "USER_MAX_NAME_LEN is 32" {
    [[ "${USER_MAX_NAME_LEN}" -eq 32 ]]
}

@test "USER_MIN_PASS_LEN is 8" {
    [[ "${USER_MIN_PASS_LEN}" -eq 8 ]]
}

#!/usr/bin/env bats
# utils.bats - 单元测试 for scripts/base/utils.sh

# 测试前设置
setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# 输出函数测试
@test "log_info outputs INFO message" {
    run log_info "Test message"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"[INFO]"*"Test message"* ]]
}

@test "log_success outputs SUCCESS message" {
    run log_success "Success message"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"[✓]"*"Success message"* ]]
}

@test "log_warn outputs WARN message" {
    run log_warn "Warning message"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"[!]"*"Warning message"* ]]
}

@test "log_error outputs ERROR message" {
    run log_error "Error message"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"[✗]"*"Error message"* ]]
}

@test "log_step outputs STEP message" {
    run log_step "Step message"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"[→]"*"Step message"* ]]
}

@test "log_title outputs title with borders" {
    run log_title "Test Title"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"═══"* ]]
    [[ "${output}" == *"Test Title"* ]]
}

# 日志文件测试
@test "log_info writes to log file" {
    log_info "Test log entry"
    [[ -f "${LOG_FILE}" ]]
    grep -q "Test log entry" "${LOG_FILE}"
}

@test "log_debug only writes to log file" {
    run log_debug "Debug message"
    [[ "${output}" == "" ]]
    grep -q "Debug message" "${LOG_FILE}"
}

# 备份函数测试
@test "backup_file creates backup" {
    local test_file="${TEST_DIR}/test.conf"
    echo "test content" > "${test_file}"

    run backup_file "${test_file}" "Test backup"
    [[ "${status}" -eq 0 ]]

    local backup_count
    backup_count=$(ls "${BACKUP_DIR}"/test.conf.bak.* 2>/dev/null | wc -l)
    [[ "${backup_count}" -eq 1 ]]
}

@test "backup_file returns error for missing file" {
    run backup_file "/nonexistent/file"
    [[ "${status}" -ne 0 ]]
}

@test "restore_file restores from backup" {
    local test_file="${TEST_DIR}/test.conf"
    local backup="${TEST_DIR}/backup.conf"
    echo "backup content" > "${backup}"

    run restore_file "${backup}" "${test_file}" "Test restore"
    [[ "${status}" -eq 0 ]]
    [[ -f "${test_file}" ]]
    [[ "$(cat "${test_file}")" == "backup content" ]]
}

# SSH 配置辅助函数测试
@test "set_ssh_config adds new config" {
    local config_file="${TEST_DIR}/sshd_config"
    touch "${config_file}"

    set_ssh_config "Port" "2222" "${config_file}"
    grep -q "^Port 2222$" "${config_file}"
}

@test "set_ssh_config updates existing config" {
    local config_file="${TEST_DIR}/sshd_config"
    echo "Port 22" > "${config_file}"

    set_ssh_config "Port" "2222" "${config_file}"
    grep -q "^Port 2222$" "${config_file}"
    ! grep -q "^Port 22$" "${config_file}"
}

@test "get_ssh_config reads config value" {
    local config_file="${TEST_DIR}/sshd_config"
    echo "Port 2222" > "${config_file}"

    result=$(get_ssh_config "Port" "${config_file}")
    [[ "${result}" == "2222" ]]
}

# 系统函数测试
@test "command_exists finds existing command" {
    run command_exists "bash"
    [[ "${status}" -eq 0 ]]
}

@test "command_exists fails for missing command" {
    run command_exists "nonexistent_command_xyz"
    [[ "${status}" -ne 0 ]]
}

@test "get_os_type returns valid OS" {
    run get_os_type
    [[ "${status}" -eq 0 ]]
    [[ -n "${output}" ]]
}

# 工具函数测试
@test "SCRIPT_VERSION is set" {
    [[ -n "${SCRIPT_VERSION}" ]]
    [[ "${SCRIPT_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

@test "TIMESTAMP is set" {
    [[ -n "${TIMESTAMP}" ]]
    [[ "${TIMESTAMP}" =~ ^[0-9]{8}_[0-9]{6}$ ]]
}

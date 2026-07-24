#!/usr/bin/env bats
# ssh.bats - 单元测试 for scripts/security/ssh.sh

# 测试前设置
setup() {
    export TEST_DIR="$(mktemp -d)"
    export _ORIG_HOME="${HOME}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # 先加载依赖模块，再 source 被测模块
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    # 模拟 detect.sh 的变量和函数（ssh.sh 不直接依赖 detect.sh，但部分函数需要）
    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    source "${SCRIPT_DIR}/scripts/security/ssh.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ── validate_port 测试 ──

@test "validate_port accepts valid port 22" {
    run validate_port "22"
    [[ "${status}" -eq 0 ]]
}

@test "validate_port accepts valid port 65535" {
    run validate_port "65535"
    [[ "${status}" -eq 0 ]]
}

@test "validate_port accepts valid port 1024" {
    run validate_port "1024"
    [[ "${status}" -eq 0 ]]
}

@test "validate_port rejects port 0" {
    run validate_port "0"
    [[ "${status}" -ne 0 ]]
}

@test "validate_port rejects port 65536" {
    run validate_port "65536"
    [[ "${status}" -ne 0 ]]
}

@test "validate_port rejects negative number" {
    run validate_port "-1"
    [[ "${status}" -ne 0 ]]
}

@test "validate_port rejects non-numeric input" {
    run validate_port "abc"
    [[ "${status}" -ne 0 ]]
}

@test "validate_port handles octal-looking input 022" {
    # 022 should be treated as decimal 22, not octal 18
    run validate_port "022"
    [[ "${status}" -eq 0 ]]
}

@test "validate_port rejects empty string" {
    run validate_port ""
    [[ "${status}" -ne 0 ]]
}

@test "validate_port rejects port with spaces" {
    run validate_port "22 22"
    [[ "${status}" -ne 0 ]]
}

# ── check_other_users 测试 ──

@test "check_other_users returns 0 when other users exist" {
    # /etc/passwd 应该有非 root、非当前用户的可登录用户
    # 在大多数系统上至少有 daemon 或 nobody
    # 如果没有其他用户，测试会跳过
    if awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ && $1 != "root" {print $1}' /etc/passwd 2>/dev/null | grep -q .; then
        run check_other_users
        [[ "${status}" -eq 0 ]]
    else
        skip "No other login users found on this system"
    fi
}

# ── check_ssh_keys 测试 ──

@test "check_ssh_keys returns 1 for missing authorized_keys" {
    export HOME="${TEST_DIR}/home"
    mkdir -p "${HOME}"
    # 确保 authorized_keys 不存在
    rm -f "${HOME}/.ssh/authorized_keys"

    run check_ssh_keys
    [[ "${status}" -ne 0 ]]
}

@test "check_ssh_keys returns 1 for empty authorized_keys" {
    export HOME="${TEST_DIR}/home"
    mkdir -p "${HOME}/.ssh"
    touch "${HOME}/.ssh/authorized_keys"

    run check_ssh_keys
    [[ "${status}" -ne 0 ]]
}

@test "check_ssh_keys returns 0 for valid ed25519 key" {
    export HOME="${TEST_DIR}/home"
    mkdir -p "${HOME}/.ssh"
    echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl test@example" > "${HOME}/.ssh/authorized_keys"

    run check_ssh_keys
    [[ "${status}" -eq 0 ]]
}

@test "check_ssh_keys returns 0 for valid rsa key" {
    export HOME="${TEST_DIR}/home"
    mkdir -p "${HOME}/.ssh"
    echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC7FBmMSVTjkMYK6U/testkey test@example" > "${HOME}/.ssh/authorized_keys"

    run check_ssh_keys
    [[ "${status}" -eq 0 ]]
}

@test "check_ssh_keys returns 1 for invalid key format" {
    export HOME="${TEST_DIR}/home"
    mkdir -p "${HOME}/.ssh"
    echo "not-a-valid-key" > "${HOME}/.ssh/authorized_keys"

    run check_ssh_keys
    [[ "${status}" -ne 0 ]]
}

@test "check_ssh_keys returns 1 for comment-only file" {
    export HOME="${TEST_DIR}/home"
    mkdir -p "${HOME}/.ssh"
    echo "# this is just a comment" > "${HOME}/.ssh/authorized_keys"

    run check_ssh_keys
    [[ "${status}" -ne 0 ]]
}

# ── SSH Lockout Protection Enhancement Tests ──

@test "_restart_and_test_ssh function exists" {
    type _restart_and_test_ssh
}

@test "_start_connection_watch function exists" {
    type _start_connection_watch
}

@test "check_active_ssh_sessions function exists" {
    type check_active_ssh_sessions
}

@test "has_console_access function exists" {
    type has_console_access
}

@test "check_active_ssh_sessions returns 0 or 1" {
    run check_active_ssh_sessions
    # May or may not have active sessions in test environment
    [[ "${status}" -eq 0 ]] || [[ "${status}" -eq 1 ]]
}

@test "has_console_access returns 0 or 1" {
    run has_console_access
    # May or may not have console access in test environment
    [[ "${status}" -eq 0 ]] || [[ "${status}" -eq 1 ]]
}

@test "cancel_rollback_timer function still exists" {
    type cancel_rollback_timer
}

@test "setup_rollback_timer function still exists" {
    type setup_rollback_timer
}

@test "ROLLBACK_DELAY is 300 (5 minutes per PRD §6.3)" {
    [[ "${ROLLBACK_DELAY}" -eq 300 ]]
}

@test "_is_ssh_port_listening function exists" {
    type _is_ssh_port_listening
}

@test "_monitor_ssh_connections function exists" {
    type _monitor_ssh_connections
}

@test "ROLLBACK_SENTINEL is empty string by default" {
    [[ -z "${ROLLBACK_SENTINEL:-}" ]]
}

@test "ROLLBACK_MONITOR_PID is empty string by default" {
    [[ -z "${ROLLBACK_MONITOR_PID:-}" ]]
}

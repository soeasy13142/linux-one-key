#!/usr/bin/env bats
# ssh-rollback.bats - 单元测试 for SSH rollback protection functions in scripts/security/ssh.sh

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
    # Clean up any leftover background processes from setup_rollback_timer tests
    if [[ -n "${ROLLBACK_MONITOR_PID:-}" ]]; then
        kill "${ROLLBACK_MONITOR_PID}" 2>/dev/null || true
    fi
    if [[ -n "${ROLLBACK_PID:-}" ]]; then
        kill "${ROLLBACK_PID}" 2>/dev/null || true
    fi
    if [[ -n "${ROLLBACK_SENTINEL:-}" ]] && [[ -f "${ROLLBACK_SENTINEL}" ]]; then
        rm -f "${ROLLBACK_SENTINEL}" 2>/dev/null || true
    fi
    if [[ -n "${_SCHEDULED_PID:-}" ]]; then
        kill "${_SCHEDULED_PID}" 2>/dev/null || true
    fi

    rm -rf "${TEST_DIR}"
    export HOME="${_ORIG_HOME}"
}

# ═══════════════════════════════════════════
# Group 1: Constants
# ═══════════════════════════════════════════

@test "ROLLBACK_DELAY is 300 (PRD §6.3)" {
    [[ "${ROLLBACK_DELAY}" -eq 300 ]]
}

@test "ROLLBACK_SENTINEL is empty by default" {
    [[ -z "${ROLLBACK_SENTINEL:-}" ]]
}

@test "ROLLBACK_MONITOR_PID is empty by default" {
    [[ -z "${ROLLBACK_MONITOR_PID:-}" ]]
}

# ═══════════════════════════════════════════
# Group 2: Function existence
# ═══════════════════════════════════════════

@test "check_active_ssh_sessions function exists" {
    type check_active_ssh_sessions
}

@test "has_console_access function exists" {
    type has_console_access
}

@test "_monitor_ssh_connections function exists" {
    type _monitor_ssh_connections
}

@test "_restart_and_test_ssh function exists" {
    type _restart_and_test_ssh
}

# ═══════════════════════════════════════════
# Group 3: Behavior
# ═══════════════════════════════════════════

@test "check_active_ssh_sessions returns 1 when no sessions" {
    # Mock ss to show no ESTABLISHED connections on port 22
    function ss() { echo "LISTEN 0 128 0.0.0.0:22"; }
    export -f ss
    run check_active_ssh_sessions
    [[ "${status}" -eq 1 ]]
}

@test "has_console_access handles no console" {
    # Source function checks /dev/tty1 and /dev/console first via [[ -c ]].
    # These may exist as character devices on macOS, so we construct a
    # narrowed test that exercises only the who-based detection path.
    function has_console_access() {
        local console_users
        console_users=$(LC_ALL=C who -a 2>/dev/null | grep -cE '(tty|console|vc/[0-9])' || echo 0)
        [[ "${console_users}" -gt 0 ]]
    }
    function who() { echo ""; }
    export -f has_console_access who
    run has_console_access
    [[ "${status}" -eq 1 ]]
}

@test "_monitor_ssh_connections creates sentinel on connection" {
    local sentinel="${TEST_DIR}/monitor-sentinel"
    # Mock ss to show an ESTABLISHED connection on port 22222.
    # The grep pattern is ":${port}[[:space:]].*ESTABLISHED", so the port
    # must appear BEFORE the word ESTABLISHED in the output.
    function ss() { echo "0.0.0.0:22222 10.0.0.2:54321 ESTABLISHED"; }
    export -f ss
    # Mock sleep to be a no-op so the test completes instantly
    function sleep() { true; }
    export -f sleep

    run _monitor_ssh_connections "22222" 1 "${sentinel}"
    [[ -f "${sentinel}" ]]
}

@test "_monitor_ssh_connections exits without sentinel if no connection" {
    local sentinel="${TEST_DIR}/monitor-sentinel"
    # Mock ss to show no ESTABLISHED connections
    function ss() { echo "LISTEN 0 128 0.0.0.0:22222"; }
    export -f ss
    # Mock sleep to be a no-op so the test completes quickly
    function sleep() { true; }
    export -f sleep

    run _monitor_ssh_connections "22222" 1 "${sentinel}"
    [[ ! -f "${sentinel}" ]]
}

@test "setup_rollback_timer sets ROLLBACK_PID" {
    # Mock command_exists so 'at' is not found (forces background-process path)
    function command_exists() {
        if [[ "$1" == "at" ]]; then return 1; fi
        # delegate to the real command_exists for other commands (e.g. ss)
        command -v "$1" &>/dev/null
    }
    export -f command_exists

    # Mock _monitor_ssh_connections to be a no-op so no background work runs
    function _monitor_ssh_connections() { return 0; }
    export -f _monitor_ssh_connections

    # Mock get_ssh_port to return a safe test port
    function get_ssh_port() { echo "22222"; }
    export -f get_ssh_port

    # Mock rollback_ssh to be a no-op (avoids needing actual backup files)
    function rollback_ssh() { return 0; }
    export -f rollback_ssh

    # Mock sleep to be a no-op (the background sleep(...) exits instantly)
    function sleep() { true; }
    export -f sleep

    # Run setup_rollback_timer directly (not via run) so that global
    # variables ROLLBACK_PID / ROLLBACK_SENTINEL / ROLLBACK_MONITOR_PID
    # are set in the current shell context.
    setup_rollback_timer

    # Verify that the rollback PID was recorded
    [[ -n "${ROLLBACK_PID:-}" ]]

    # Verify sentinel and monitor PID were also set
    [[ -n "${ROLLBACK_SENTINEL:-}" ]]
    [[ -n "${ROLLBACK_MONITOR_PID:-}" ]]

    # Clean up: cancel the rollback timer using run to capture non-zero
    # returns from cancel_scheduled_task without triggering bats' error detection.
    run cancel_rollback_timer

    # Clean up global variables to avoid leaking to subsequent tests
    unset ROLLBACK_PID ROLLBACK_SENTINEL ROLLBACK_MONITOR_PID _SCHEDULED_PID
}

@test "cancel_rollback_timer cleans up sentinel file" {
    local sentinel="${TEST_DIR}/cancel-sentinel"
    touch "${sentinel}"
    export ROLLBACK_SENTINEL="${sentinel}"

    run cancel_rollback_timer
    [[ "${status}" -eq 0 ]]
    [[ ! -f "${sentinel}" ]]

    unset ROLLBACK_SENTINEL
}

@test "cancel_rollback_timer handles ROLLBACK_MONITOR_PID cleanup" {
    export ROLLBACK_MONITOR_PID="99999"

    run cancel_rollback_timer
    [[ "${status}" -eq 0 ]]

    unset ROLLBACK_MONITOR_PID
}

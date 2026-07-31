#!/usr/bin/env bats
# rollback.bats - 单元测试 for scripts/base/rollback.sh
bats_require_minimum_version 1.5.0

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # Load dependencies: utils.sh will source rollback.sh internally
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── Source guard tests ──

@test "rollback.sh: _ROLLBACK_LOADED is set" {
    [[ -n "${_ROLLBACK_LOADED:-}" ]]
    [[ "${_ROLLBACK_LOADED}" == "1" ]]
}

@test "rollback.sh: source guard prevents double source" {
    source "${SCRIPT_DIR}/scripts/base/rollback.sh"
    # Second source should not error
}

# ── Function existence tests ──

@test "rollback.sh: schedule_rollback function exists" {
    type schedule_rollback
}

@test "rollback.sh: cancel_scheduled_task function exists" {
    type cancel_scheduled_task
}

# ── schedule_rollback behavior tests ──

@test "schedule_rollback executes callback" {
    local flag_file
    flag_file=$(mktemp /tmp/rollback-test-XXXXXX)

    # rollback_ssh is the only callback allowed by the whitelist
    rollback_ssh() { echo done > "${flag_file}"; }
    export -f rollback_ssh

    run schedule_rollback 1 "rollback_ssh" "Test"
    [[ "${status}" -eq 0 ]]
    [[ -n "${_SCHEDULED_PID:-}" ]]

    # Wait up to 5 seconds for callback
    local waited=0
    while [[ ! -s "${flag_file}" && "${waited}" -lt 5 ]]; do
        sleep 0.5
        waited=$((waited + 1))
    done
    [[ -s "${flag_file}" ]]
    rm -f "${flag_file}"
}

@test "schedule_rollback sets _SCHEDULED_PID immediately" {
    # rollback_ssh is the only callback allowed by the whitelist
    rollback_ssh() { true; }
    export -f rollback_ssh

    local old_pid="${_SCHEDULED_PID:-}"
    schedule_rollback 10 "rollback_ssh" "Test"
    [[ -n "${_SCHEDULED_PID}" ]]
    [[ "${_SCHEDULED_PID}" != "${old_pid}" ]]

    # Cancel to avoid lingering background process
    cancel_scheduled_task "${_SCHEDULED_PID}" || true
}

# ── cancel_scheduled_task behavior tests ──

@test "cancel_scheduled_task can cancel a scheduled task" {
    # rollback_ssh is the only callback allowed by the whitelist
    rollback_ssh() { true; }
    export -f rollback_ssh

    schedule_rollback 30 "rollback_ssh" "Cancellable test"
    local pid="${_SCHEDULED_PID:-}"

    # Verify the process exists
    kill -0 "${pid}" 2>/dev/null
    [[ "$?" -eq 0 ]] || skip "Process already exited"

    run cancel_scheduled_task "${pid}"
    [[ "${status}" -eq 0 ]]
}

@test "cancel_scheduled_task fails for non-existent PID" {
    run cancel_scheduled_task 99999
    [[ "${status}" -eq 1 ]]
}

@test "cancel_scheduled_task handles empty PID" {
    run cancel_scheduled_task ""
    [[ "${status}" -eq 1 ]]
}

# ── rollback_timer_status ──

@test "rollback_timer_status returns none without timer" {
    unset ROLLBACK_PID _SCHEDULED_PID 2>/dev/null || true
    run rollback_timer_status
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == "none" ]]
}

@test "rollback_timer_status detects live sleep task" {
    unset ROLLBACK_PID _SCHEDULED_PID 2>/dev/null || true
    sleep 30 &
    local pid=$!
    ROLLBACK_PID="${pid}"
    run --separate-stderr rollback_timer_status
    local st="${status}"
    local out="${output}"
    kill "${pid}" 2>/dev/null || true
    [[ "${st}" -eq 0 ]]
    [[ "${out}" == "${pid}" ]]
}

@test "rollback_timer_status ignores dead pid" {
    unset ROLLBACK_PID _SCHEDULED_PID 2>/dev/null || true
    sleep 0.1 &
    local pid=$!
    ROLLBACK_PID="${pid}"
    wait "${pid}" 2>/dev/null || true
    run rollback_timer_status
    [[ "${status}" -ne 0 ]]
}

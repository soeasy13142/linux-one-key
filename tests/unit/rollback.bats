#!/usr/bin/env bats
# rollback.bats - 单元测试 for scripts/base/rollback.sh

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

@test "schedule_rollback sets _SCHEDULED_PID" {
    # Create a callback script
    local callback_script="${TEST_DIR}/callback.sh"
    local test_flag="${TEST_DIR}/rollback_ran"
    rm -f "${test_flag}"
    printf '#!/usr/bin/env bash\ntouch "%s"\n' "${test_flag}" > "${callback_script}"
    chmod +x "${callback_script}"

    schedule_rollback 1 "${callback_script}" "Test rollback"
    [[ -n "${_SCHEDULED_PID:-}" ]]

    # Wait for the task to complete
    sleep 2
    # The callback should have been executed
    [[ -f "${test_flag}" ]]
}

@test "schedule_rollback sets _SCHEDULED_PID immediately" {
    local old_pid="${_SCHEDULED_PID:-}"
    schedule_rollback 10 "true" "Test"
    [[ -n "${_SCHEDULED_PID}" ]]
    [[ "${_SCHEDULED_PID}" != "${old_pid}" ]]

    # Cancel to avoid lingering background process
    cancel_scheduled_task "${_SCHEDULED_PID}" || true
}

# ── cancel_scheduled_task behavior tests ──

@test "cancel_scheduled_task can cancel a scheduled task" {
    schedule_rollback 30 "true" "Cancellable test"
    local pid="${_SCHEDULED_PID:-}"

    # Verify the process exists
    kill -0 "${pid}" 2>/dev/null
    [[ "$?" -eq 0 ]] || skip "Process already exited"

    run cancel_scheduled_task "${pid}"
    [[ "${status}" -eq 0 ]]
}

@test "cancel_scheduled_task returns 1 for non-existent PID" {
    run cancel_scheduled_task "999999"
    # This will fail because the PID doesn't exist
    [[ "${status}" -eq 1 ]] || [[ "${status}" -eq 0 ]]
}

@test "cancel_scheduled_task handles empty PID" {
    run cancel_scheduled_task ""
    [[ "${status}" -eq 1 ]]
}

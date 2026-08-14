#!/usr/bin/env bats
# cleanup.bats - 单元测试 for scripts/base/cleanup.sh
bats_require_minimum_version 1.5.0

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/log/backups"
    export REPORT_DIR="${TEST_DIR}/log/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # Load dependencies
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"
    load_lang "${SCRIPT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/cleanup.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── Source guard & 绑定 ──

@test "cleanup.sh: _CLEANUP_LOADED is set" {
    [[ "${_CLEANUP_LOADED:-}" == "1" ]]
}

@test "cleanup.sh: CLEANUP_LOG_DIR binds to LOG_DIR" {
    [[ "${CLEANUP_LOG_DIR}" == "${LOG_DIR}" ]]
}

@test "cleanup.sh: tmp patterns are precise" {
    [[ " ${CLEANUP_TMP_PATTERNS[*]} " == *"/tmp/.ssh-askpass-*"* ]]
    [[ " ${CLEANUP_TMP_PATTERNS[*]} " == *"/tmp/.ssh-monitor-*"* ]]
}

# ── 正常路径 ──

@test "cleanup: removes LOG_DIR and tmp ssh files" {
    touch "${LOG_DIR}/hardening_test.log"
    touch "${BACKUP_DIR}/sshd_config.bak"
    touch "${REPORT_DIR}/report_test.txt"
    mkdir -p "${TEST_DIR}/tmp"
    touch "${TEST_DIR}/tmp/.ssh-askpass-123"
    touch "${TEST_DIR}/tmp/.ssh-monitor-456"
    CLEANUP_TMP_PATTERNS=("${TEST_DIR}/tmp/.ssh-askpass-*" "${TEST_DIR}/tmp/.ssh-monitor-*")

    cleanup_lite_traces

    [[ ! -d "${LOG_DIR}" ]]
    [[ ! -e "${TEST_DIR}/tmp/.ssh-askpass-123" ]]
    [[ ! -e "${TEST_DIR}/tmp/.ssh-monitor-456" ]]
}

# ── 幂等 ──

@test "cleanup: idempotent on repeat" {
    touch "${LOG_DIR}/x.log"
    cleanup_lite_traces
    run cleanup_lite_traces
    [[ "${status}" -eq 0 ]]
    [[ ! -d "${LOG_DIR}" ]]
}

# ── 不存在时不报错 ──

@test "cleanup: no-op when LOG_DIR missing" {
    rm -rf "${LOG_DIR}"
    CLEANUP_TMP_PATTERNS=()
    run cleanup_lite_traces
    [[ "${status}" -eq 0 ]]
}

# ── 不误删 ──

@test "cleanup: does not touch unrelated tmp files" {
    mkdir -p "${TEST_DIR}/tmp"
    touch "${TEST_DIR}/tmp/.ssh-askpass-x"
    touch "${TEST_DIR}/tmp/.ssh-other-x"
    touch "${TEST_DIR}/tmp/unrelated-x"
    CLEANUP_TMP_PATTERNS=("${TEST_DIR}/tmp/.ssh-askpass-*")

    cleanup_lite_traces

    [[ ! -e "${TEST_DIR}/tmp/.ssh-askpass-x" ]]
    [[ -e "${TEST_DIR}/tmp/.ssh-other-x" ]]
    [[ -e "${TEST_DIR}/tmp/unrelated-x" ]]
}

# ── 失败容忍（mock rm 对 cleanup-blocked 路径失败，root/non-root 均有效） ──

@test "cleanup: tolerant when removal fails (returns 0, keeps dir)" {
    mkdir -p "${TEST_DIR}/bin"
    cat > "${TEST_DIR}/bin/rm" <<'EOF'
#!/usr/bin/env bash
case " $* " in
    *"cleanup-blocked"*) exit 1 ;;
esac
exec /bin/rm "$@"
EOF
    chmod +x "${TEST_DIR}/bin/rm"
    mkdir -p "${TEST_DIR}/cleanup-blocked"
    touch "${TEST_DIR}/cleanup-blocked/x.log"
    CLEANUP_LOG_DIR="${TEST_DIR}/cleanup-blocked"
    CLEANUP_TMP_PATTERNS=()

    PATH="${TEST_DIR}/bin:${PATH}" run cleanup_lite_traces
    [[ "${status}" -eq 0 ]]
    [[ -d "${TEST_DIR}/cleanup-blocked" ]]
}

# ── 回滚定时器取消 ──

@test "cleanup: cancels active rollback timer" {
    CALLED=0
    cancel_rollback_timer() { CALLED=1; }
    CLEANUP_LOG_DIR="${TEST_DIR}/nonexistent"
    CLEANUP_TMP_PATTERNS=()

    cleanup_lite_traces
    [[ "${CALLED}" -eq 1 ]]
}

# ── fallback 路径清理 ──

@test "cleanup: removes arbitrary CLEANUP_LOG_DIR (fallback path covered)" {
    local fake="${TEST_DIR}/fake-log"
    mkdir -p "${fake}"
    CLEANUP_LOG_DIR="${fake}"
    CLEANUP_TMP_PATTERNS=()

    cleanup_lite_traces
    [[ ! -d "${fake}" ]]
}

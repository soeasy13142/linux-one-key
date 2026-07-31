#!/usr/bin/env bats
# backup.bats - 单元测试 for scripts/base/backup.sh
bats_require_minimum_version 1.5.0

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # Load dependencies: utils.sh will source backup.sh internally
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"

    # Verify backup.sh functions are available via utils.sh
    if ! type backup_file &>/dev/null; then
        # Fallback: load directly
        source "${SCRIPT_DIR}/scripts/base/backup.sh"
    fi
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── Source guard tests ──

@test "backup.sh: _BACKUP_LOADED is set" {
    [[ -n "${_BACKUP_LOADED:-}" ]]
    [[ "${_BACKUP_LOADED}" == "1" ]]
}

@test "backup.sh: source guard prevents double source" {
    source "${SCRIPT_DIR}/scripts/base/backup.sh"
    # Second source should not error
}

# ── Function existence tests ──

@test "backup.sh: backup_file function exists" {
    type backup_file
}

@test "backup.sh: restore_file function exists" {
    type restore_file
}

# ── backup_file behavior tests ──

@test "backup_file creates backup in BACKUP_DIR" {
    local test_file="${TEST_DIR}/test.conf"
    echo "test content" > "${test_file}"

    run backup_file "${test_file}" "Test backup"
    [[ "${status}" -eq 0 ]]

    local backup_count
    # 排除 .meta sidecar（备份元数据，非备份文件本身）
    backup_count=$(find "${BACKUP_DIR}" -maxdepth 1 -name 'test.conf.bak.*' ! -name '*.meta' | wc -l)
    [[ "${backup_count}" -eq 1 ]]
}

@test "backup_file returns error for missing file" {
    run backup_file "/nonexistent/file"
    [[ "${status}" -ne 0 ]]
}

@test "backup_file returns backup path on success" {
    local test_file="${TEST_DIR}/test.conf"
    echo "content" > "${test_file}"

    run backup_file "${test_file}"
    [[ "${status}" -eq 0 ]]
    [[ -n "${output}" ]]
    [[ "${output}" == *"test.conf.bak."* ]]
}

@test "backup_file creates backup with unique timestamp" {
    local test_file="${TEST_DIR}/test.conf"
    echo "content" > "${test_file}"

    run backup_file "${test_file}"
    [[ "${status}" -eq 0 ]]

    # Backup path should contain the TIMESTAMP
    local backup_path="${output}"
    [[ "${backup_path}" == *"${TIMESTAMP}"* ]]
}

@test "backup_file preserves original file" {
    local test_file="${TEST_DIR}/test.conf"
    echo "original content" > "${test_file}"

    run backup_file "${test_file}"

    # Original file should still exist with original content
    [[ -f "${test_file}" ]]
    [[ "$(cat "${test_file}")" == "original content" ]]
}

# ── restore_file behavior tests ──

@test "restore_file restores from backup" {
    local test_file="${TEST_DIR}/test.conf"
    local backup="${TEST_DIR}/backup.conf"
    echo "backup content" > "${backup}"

    run restore_file "${backup}" "${test_file}" "Test restore"
    [[ "${status}" -eq 0 ]]
    [[ -f "${test_file}" ]]
    [[ "$(cat "${test_file}")" == "backup content" ]]
}

@test "restore_file returns error for missing backup" {
    run restore_file "/nonexistent/backup" "${TEST_DIR}/test.conf"
    [[ "${status}" -ne 0 ]]
}

@test "restore_file preserves backup file" {
    local test_file="${TEST_DIR}/test.conf"
    local backup="${TEST_DIR}/backup.conf"
    echo "backup content" > "${backup}"

    run restore_file "${backup}" "${test_file}"

    # Backup file should still exist
    [[ -f "${backup}" ]]
    [[ "$(cat "${backup}")" == "backup content" ]]
}

@test "restore_file overwrites existing file correctly" {
    local test_file="${TEST_DIR}/test.conf"
    local backup="${TEST_DIR}/backup.conf"
    echo "new content" > "${backup}"
    echo "old content" > "${test_file}"

    run restore_file "${backup}" "${test_file}"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${test_file}")" == "new content" ]]
}

@test "backup_file handles files with spaces in name" {
    local test_file="${TEST_DIR}/test config.conf"
    echo "content" > "${test_file}"

    run backup_file "${test_file}"
    [[ "${status}" -eq 0 ]]
}

@test "restore_file handles multiple backups correctly" {
    local test_file="${TEST_DIR}/test.conf"
    local backup1="${TEST_DIR}/backup.v1"
    local backup2="${TEST_DIR}/backup.v2"
    echo "version 1" > "${backup1}"
    echo "version 2" > "${backup2}"

    # Restore v1
    run restore_file "${backup1}" "${test_file}" "Restore v1"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${test_file}")" == "version 1" ]]

    # Then restore v2 (should overwrite)
    run restore_file "${backup2}" "${test_file}" "Restore v2"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${test_file}")" == "version 2" ]]
}

# ── .meta sidecar & restore target resolution ──

@test "backup_file writes .meta sidecar with original path" {
    local test_file="${TEST_DIR}/test.conf"
    echo "content" > "${test_file}"

    run --separate-stderr backup_file "${test_file}"
    [[ "${status}" -eq 0 ]]

    local backup_path="${output}"
    [[ -f "${backup_path}.meta" ]]
    [[ "$(cat "${backup_path}.meta")" == "${test_file}" ]]
}

@test "restore_file restores via .meta when target omitted" {
    local test_file="${TEST_DIR}/test.conf"
    echo "original" > "${test_file}"

    run --separate-stderr backup_file "${test_file}"
    local backup_path="${output}"

    echo "modified" > "${test_file}"

    run restore_file "${backup_path}"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${test_file}")" == "original" ]]
}

@test "restore_file rejects relative path from .meta" {
    local test_file="${TEST_DIR}/test.conf"
    echo "content" > "${test_file}"

    run --separate-stderr backup_file "${test_file}"
    local backup_path="${output}"

    echo "relative/path" > "${backup_path}.meta"

    run restore_file "${backup_path}"
    [[ "${status}" -ne 0 ]]
}

@test "restore_file errors when no meta and no explicit target" {
    local backup="${TEST_DIR}/orphan.conf"
    echo "content" > "${backup}"

    run restore_file "${backup}"
    [[ "${status}" -ne 0 ]]
}

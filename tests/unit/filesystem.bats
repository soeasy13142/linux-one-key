#!/usr/bin/env bats
# filesystem.bats - 单元测试 for scripts/security/filesystem.sh

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

    source "${SCRIPT_DIR}/scripts/security/filesystem.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── 常量测试 (通过源文件验证，因为 readonly 数组在 bats 子 shell 中不可用) ──

@test "CRITICAL_FILES contains /etc/passwd" {
    grep -q '"/etc/passwd:644"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "CRITICAL_FILES contains /etc/shadow" {
    grep -q '"/etc/shadow:640"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "CRITICAL_FILES contains /etc/ssh/sshd_config" {
    grep -q '"/etc/ssh/sshd_config:600"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "CRITICAL_FILES contains 7 entries" {
    local count
    count=$(sed -n '/readonly CRITICAL_FILES/,/)/p' "${SCRIPT_DIR}/scripts/security/filesystem.sh" | grep -c '"/')
    [[ ${count} -eq 7 ]]
}

@test "KNOWN_SUID_FILES contains /usr/bin/passwd" {
    grep -q '"/usr/bin/passwd"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "KNOWN_SUID_FILES contains /usr/bin/sudo" {
    grep -q '"/usr/bin/sudo"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

# ── 函数存在性测试 ──

@test "check_critical_permissions function exists" {
    [[ "$(type -t check_critical_permissions)" == "function" ]]
}

@test "audit_suid_sgid function exists" {
    [[ "$(type -t audit_suid_sgid)" == "function" ]]
}

@test "check_orphan_files function exists" {
    [[ "$(type -t check_orphan_files)" == "function" ]]
}

@test "fix_critical_permissions function exists" {
    [[ "$(type -t fix_critical_permissions)" == "function" ]]
}

@test "run_filesystem_wizard function exists" {
    [[ "$(type -t run_filesystem_wizard)" == "function" ]]
}

@test "check_filesystem_status function exists" {
    [[ "$(type -t check_filesystem_status)" == "function" ]]
}

# ── _get_file_mode 测试 ──

@test "_get_file_mode returns correct mode for /etc/passwd" {
    if [[ -f /etc/passwd ]]; then
        run _get_file_mode "/etc/passwd"
        [[ "${output}" =~ ^[0-9]+$ ]]
    else
        skip "/etc/passwd not found"
    fi
}

@test "_get_file_mode returns NOT_FOUND for missing file" {
    run _get_file_mode "/nonexistent/file/path"
    [[ "${output}" == "NOT_FOUND" ]]
}

# ── _is_known_suid_file 测试 ──
# 注意: KNOWN_SUID_FILES 是 readonly 数组，_is_known_suid_file 在 bats run 子 shell 中无法访问
# 改为直接调用（不使用 run）或检查源文件

@test "_is_known_suid_file rejects unknown file" {
    # 直接调用（非 run 子 shell），readonly 变量在当前 shell 可用
    ! _is_known_suid_file "/usr/local/bin/suspicious_file_xyz"
}

@test "_is_known_suid_file rejects empty string" {
    ! _is_known_suid_file ""
}

# ── check_filesystem_status 测试 ──

@test "check_filesystem_status outputs fs_suid_count key" {
    run check_filesystem_status
    echo "${output}" | grep -q "fs_suid_count="
}

@test "check_filesystem_status returns numeric suid count" {
    run check_filesystem_status
    local count_line
    count_line=$(echo "${output}" | grep "fs_suid_count=")
    local count="${count_line#fs_suid_count=}"
    [[ "${count}" =~ ^[0-9]+$ ]]
}

# ── CRITICAL_FILES 权限值测试（通过源文件验证） ──

@test "/etc/passwd expected permission is 644" {
    grep -q '"/etc/passwd:644"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "/etc/shadow expected permission is 640" {
    grep -q '"/etc/shadow:640"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "/etc/ssh/sshd_config expected permission is 600" {
    grep -q '"/etc/ssh/sshd_config:600"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "/root expected permission is 700" {
    grep -q '"/root:700"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

@test "/tmp expected permission is 1777" {
    grep -q '"/tmp:1777"' "${SCRIPT_DIR}/scripts/security/filesystem.sh"
}

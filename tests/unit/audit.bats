#!/usr/bin/env bats
# audit.bats - 单元测试 for scripts/security/audit.sh

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
    source "${SCRIPT_DIR}/scripts/security/audit.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # Mock system commands
    export DETECTED_OS="ubuntu"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# 测试常量定义
@test "AUDIT_RULES_DIR is set correctly" {
    [[ "${AUDIT_RULES_DIR}" == "/etc/audit/rules.d" ]]
}

@test "AUDIT_RULES_FILE is set correctly" {
    [[ "${AUDIT_RULES_FILE}" == "/etc/audit/rules.d/audit.rules" ]]
}

@test "AUDITD_CONF is set correctly" {
    [[ "${AUDITD_CONF}" == "/etc/audit/auditd.conf" ]]
}

@test "AUDIT_LEVEL_BASIC is set correctly" {
    [[ "${AUDIT_LEVEL_BASIC}" == "basic" ]]
}

@test "AUDIT_LEVEL_STANDARD is set correctly" {
    [[ "${AUDIT_LEVEL_STANDARD}" == "standard" ]]
}

@test "AUDIT_LEVEL_FULL is set correctly" {
    [[ "${AUDIT_LEVEL_FULL}" == "full" ]]
}

# 测试 source guard
@test "audit.sh sets _AUDIT_LOADED guard" {
    [[ "${_AUDIT_LOADED}" == "1" ]]
}

# 测试 _generate_basic_rules 函数
@test "_generate_basic_rules contains identity key" {
    result=$(_generate_basic_rules)
    [[ "${result}" == *"identity"* ]]
}

@test "_generate_basic_rules contains sshd_config key" {
    result=$(_generate_basic_rules)
    [[ "${result}" == *"sshd_config"* ]]
}

@test "_generate_basic_rules contains sudo_cmd key" {
    result=$(_generate_basic_rules)
    [[ "${result}" == *"sudo_cmd"* ]]
}

@test "_generate_basic_rules contains /etc/passwd" {
    result=$(_generate_basic_rules)
    [[ "${result}" == *"/etc/passwd"* ]]
}

@test "_generate_basic_rules contains /etc/shadow" {
    result=$(_generate_basic_rules)
    [[ "${result}" == *"/etc/shadow"* ]]
}

# 测试 _generate_standard_rules 函数
@test "_generate_standard_rules contains network key" {
    result=$(_generate_standard_rules)
    [[ "${result}" == *"network"* ]]
}

@test "_generate_standard_rules contains cron key" {
    result=$(_generate_standard_rules)
    [[ "${result}" == *"cron"* ]]
}

@test "_generate_standard_rules contains log_tamper key" {
    result=$(_generate_standard_rules)
    [[ "${result}" == *"log_tamper"* ]]
}

@test "_generate_standard_rules contains boot_script key" {
    result=$(_generate_standard_rules)
    [[ "${result}" == *"boot_script"* ]]
}

@test "_generate_standard_rules includes basic rules" {
    result=$(_generate_standard_rules)
    [[ "${result}" == *"identity"* ]]
    [[ "${result}" == *"sshd_config"* ]]
}

@test "_generate_standard_rules excludes modules key" {
    result=$(_generate_standard_rules)
    [[ "${result}" != *"modules"* ]]
}

# 测试 _generate_full_rules 函数
@test "_generate_full_rules contains perm_change key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"perm_change"* ]]
}

@test "_generate_full_rules contains owner_change key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"owner_change"* ]]
}

@test "_generate_full_rules contains exec key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"-k exec"* ]]
}

@test "_generate_full_rules contains modules key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"modules"* ]]
}

@test "_generate_full_rules contains time_change key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"time_change"* ]]
}

@test "_generate_full_rules contains mount key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"mount"* ]]
}

@test "_generate_full_rules contains file_delete key" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"file_delete"* ]]
}

@test "_generate_full_rules includes standard rules" {
    result=$(_generate_full_rules)
    [[ "${result}" == *"identity"* ]]
    [[ "${result}" == *"network"* ]]
    [[ "${result}" == *"cron"* ]]
}

# 测试 _generate_audit_rules 函数
@test "_generate_audit_rules creates rules file" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    # Mock log functions
    log_step() { echo "[STEP] $1"; }
    log_success() { echo "[OK] $1"; }

    _generate_audit_rules "standard"

    [[ -f "${test_rules_dir}/audit.rules" ]]
}

@test "_generate_audit_rules standard level includes identity" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    log_step() { :; }
    log_success() { :; }

    _generate_audit_rules "standard"

    grep -q "identity" "${test_rules_dir}/audit.rules"
}

@test "_generate_audit_rules basic level excludes modules" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    log_step() { :; }
    log_success() { :; }

    _generate_audit_rules "basic"

    ! grep -q "modules" "${test_rules_dir}/audit.rules"
}

@test "_generate_audit_rules full level includes modules" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    log_step() { :; }
    log_success() { :; }

    _generate_audit_rules "full"

    grep -q "modules" "${test_rules_dir}/audit.rules"
}

@test "_generate_audit_rules includes -e 2 immutable flag" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    log_step() { :; }
    log_success() { :; }

    _generate_audit_rules "standard"

    grep -q "^-e 2$" "${test_rules_dir}/audit.rules"
}

@test "_generate_audit_rules includes -D clear flag" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    log_step() { :; }
    log_success() { :; }

    _generate_audit_rules "standard"

    grep -q "^-D$" "${test_rules_dir}/audit.rules"
}

@test "_generate_audit_rules uses standard as default level" {
    local test_rules_dir="${TEST_DIR}/rules.d"
    mkdir -p "${test_rules_dir}"
    AUDIT_RULES_DIR="${test_rules_dir}"
    AUDIT_RULES_FILE="${test_rules_dir}/audit.rules"

    log_step() { :; }
    log_success() { :; }

    _generate_audit_rules

    grep -q "network" "${test_rules_dir}/audit.rules"
}

# 测试 _configure_auditd_conf 函数
@test "_configure_auditd_conf creates config file" {
    local test_conf="${TEST_DIR}/auditd.conf"
    AUDITD_CONF="${test_conf}"

    log_step() { :; }
    log_success() { :; }

    _configure_auditd_conf "50" "10" "ROTATE"

    [[ -f "${test_conf}" ]]
}

@test "_configure_auditd_conf sets max_log_file" {
    local test_conf="${TEST_DIR}/auditd.conf"
    AUDITD_CONF="${test_conf}"

    log_step() { :; }
    log_success() { :; }

    _configure_auditd_conf "100" "10" "ROTATE"

    grep -q "max_log_file = 100" "${test_conf}"
}

@test "_configure_auditd_conf sets num_logs" {
    local test_conf="${TEST_DIR}/auditd.conf"
    AUDITD_CONF="${test_conf}"

    log_step() { :; }
    log_success() { :; }

    _configure_auditd_conf "50" "20" "ROTATE"

    grep -q "num_logs = 20" "${test_conf}"
}

@test "_configure_auditd_conf sets max_log_file_action" {
    local test_conf="${TEST_DIR}/auditd.conf"
    AUDITD_CONF="${test_conf}"

    log_step() { :; }
    log_success() { :; }

    _configure_auditd_conf "50" "10" "IGNORE"

    grep -q "max_log_file_action = IGNORE" "${test_conf}"
}

@test "_configure_auditd_conf uses default values" {
    local test_conf="${TEST_DIR}/auditd.conf"
    AUDITD_CONF="${test_conf}"

    log_step() { :; }
    log_success() { :; }

    _configure_auditd_conf

    grep -q "max_log_file = 50" "${test_conf}"
    grep -q "num_logs = 10" "${test_conf}"
    grep -q "max_log_file_action = ROTATE" "${test_conf}"
}

# 测试 get_audit_info 函数
@test "get_audit_info shows rules file path" {
    # Mock auditctl
    auditctl() { echo "No rules"; }

    run get_audit_info
    [[ "${output}" == *"/etc/audit/rules.d/audit.rules"* ]]
}

@test "get_audit_info shows conf file path" {
    auditctl() { echo "No rules"; }

    run get_audit_info
    [[ "${output}" == *"/etc/audit/auditd.conf"* ]]
}

# 测试函数存在性
@test "run_audit_wizard exists and is callable" {
    type run_audit_wizard | grep -q "function"
}

@test "show_audit_status exists and is callable" {
    type show_audit_status | grep -q "function"
}

@test "get_audit_info exists and is callable" {
    type get_audit_info | grep -q "function"
}

@test "search_audit_log exists and is callable" {
    type search_audit_log | grep -q "function"
}

@test "show_audit_report exists and is callable" {
    type show_audit_report | grep -q "function"
}

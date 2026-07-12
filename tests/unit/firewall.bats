#!/usr/bin/env bats
# firewall.bats - 单元测试 for scripts/security/firewall.sh

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
    source "${SCRIPT_DIR}/scripts/security/firewall.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # Mock system commands
    export DETECTED_OS="ubuntu"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# 测试 _get_firewall_type 函数
@test "_get_firewall_type returns ufw for ubuntu" {
    export DETECTED_OS="ubuntu"
    result=$(_get_firewall_type)
    [[ "${result}" == "ufw" ]]
}

@test "_get_firewall_type returns ufw for debian" {
    export DETECTED_OS="debian"
    result=$(_get_firewall_type)
    [[ "${result}" == "ufw" ]]
}

@test "_get_firewall_type returns firewalld for centos" {
    export DETECTED_OS="centos"
    result=$(_get_firewall_type)
    [[ "${result}" == "firewalld" ]]
}

@test "_get_firewall_type returns unknown for unsupported OS" {
    export DETECTED_OS="unsupported"
    result=$(_get_firewall_type)
    [[ "${result}" == "unknown" ]]
}

# 测试 deny_icmp 函数
@test "deny_icmp warns for ubuntu" {
    export DETECTED_OS="ubuntu"

    run deny_icmp
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"UFW"* ]]
}


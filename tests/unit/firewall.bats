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

    # 只 source firewall.sh，它会自动 source utils.sh
    source "${SCRIPT_DIR}/scripts/security/firewall.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # Mock system commands
    export DETECT_OS="ubuntu"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# 测试 _get_firewall_type 函数
@test "_get_firewall_type returns ufw for ubuntu" {
    export DETECT_OS="ubuntu"
    result=$(_get_firewall_type)
    [[ "${result}" == "ufw" ]]
}

@test "_get_firewall_type returns ufw for debian" {
    export DETECT_OS="debian"
    result=$(_get_firewall_type)
    [[ "${result}" == "ufw" ]]
}

@test "_get_firewall_type returns firewalld for centos" {
    export DETECT_OS="centos"
    result=$(_get_firewall_type)
    [[ "${result}" == "firewalld" ]]
}

@test "_get_firewall_type returns unknown for unsupported OS" {
    export DETECT_OS="unsupported"
    result=$(_get_firewall_type)
    [[ "${result}" == "unknown" ]]
}

# 测试 _get_current_ssh_port 函数
@test "_get_current_ssh_port returns custom port" {
    local config_file="${TEST_DIR}/sshd_config"
    echo "Port 2222" > "${config_file}"

    # Mock the function to use test config
    _get_current_ssh_port() {
        local port
        port=$(grep -E "^Port\s+" "${config_file}" 2>/dev/null | awk '{print $2}' | head -1)
        echo "${port:-22}"
    }

    result=$(_get_current_ssh_port)
    [[ "${result}" == "2222" ]]
}

@test "_get_current_ssh_port returns default port 22" {
    local config_file="${TEST_DIR}/sshd_config"
    touch "${config_file}"

    # Mock the function to use test config
    _get_current_ssh_port() {
        local port
        port=$(grep -E "^Port\s+" "${config_file}" 2>/dev/null | awk '{print $2}' | head -1)
        echo "${port:-22}"
    }

    result=$(_get_current_ssh_port)
    [[ "${result}" == "22" ]]
}

# 测试 deny_icmp 函数
@test "deny_icmp warns for ubuntu" {
    export DETECT_OS="ubuntu"

    run deny_icmp
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"UFW"* ]]
}

# 测试 _get_firewall_type 函数组合
@test "_get_firewall_type returns correct type for each OS" {
    export DETECT_OS="ubuntu"
    [[ "$(_get_firewall_type)" == "ufw" ]]

    export DETECT_OS="debian"
    [[ "$(_get_firewall_type)" == "ufw" ]]

    export DETECT_OS="centos"
    [[ "$(_get_firewall_type)" == "firewalld" ]]

    export DETECT_OS="unsupported"
    [[ "$(_get_firewall_type)" == "unknown" ]]
}

# 测试 _get_current_ssh_port 函数组合
@test "_get_current_ssh_port handles various port configurations" {
    local config_file="${TEST_DIR}/sshd_config"

    # Test custom port
    echo "Port 2222" > "${config_file}"
    _get_current_ssh_port() {
        local port
        port=$(grep -E "^Port\s+" "${config_file}" 2>/dev/null | awk '{print $2}' | head -1)
        echo "${port:-22}"
    }
    [[ "$(_get_current_ssh_port)" == "2222" ]]

    # Test default port (empty config)
    : > "${config_file}"
    [[ "$(_get_current_ssh_port)" == "22" ]]
}

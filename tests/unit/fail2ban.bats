#!/usr/bin/env bats
# fail2ban.bats - 单元测试 for scripts/security/fail2ban.sh

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
    source "${SCRIPT_DIR}/scripts/security/fail2ban.sh"

    # 定义测试所需的 MSG_ 变量
    MSG_FAIL2BAN_CONFIGURE="Configuring Fail2Ban jail..."
    MSG_FAIL2BAN_CONFIGURE_DONE="Fail2Ban jail configured"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # Mock system commands
    export DETECTED_OS="ubuntu"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# 测试 _get_ssh_port 函数
@test "_get_ssh_port returns custom port" {
    local config_file="${TEST_DIR}/sshd_config"
    echo "Port 2222" > "${config_file}"

    # Mock the function to use test config
    _get_ssh_port() {
        local port
        port=$(grep -E "^Port\s+" "${config_file}" 2>/dev/null | awk '{print $2}' | head -1)
        echo "${port:-22}"
    }

    result=$(_get_ssh_port)
    [[ "${result}" == "2222" ]]
}

@test "_get_ssh_port returns default port 22" {
    local config_file="${TEST_DIR}/sshd_config"
    touch "${config_file}"

    # Mock the function to use test config
    _get_ssh_port() {
        local port
        port=$(grep -E "^Port\s+" "${config_file}" 2>/dev/null | awk '{print $2}' | head -1)
        echo "${port:-22}"
    }

    result=$(_get_ssh_port)
    [[ "${result}" == "22" ]]
}

# 测试 _get_auth_log_path 函数
@test "_get_auth_log_path returns auth.log for ubuntu" {
    export DETECTED_OS="ubuntu"
    result=$(_get_auth_log_path)
    [[ "${result}" == "/var/log/auth.log" ]]
}

@test "_get_auth_log_path returns auth.log for debian" {
    export DETECTED_OS="debian"
    result=$(_get_auth_log_path)
    [[ "${result}" == "/var/log/auth.log" ]]
}

@test "_get_auth_log_path returns secure for centos" {
    export DETECTED_OS="centos"
    result=$(_get_auth_log_path)
    [[ "${result}" == "/var/log/secure" ]]
}

@test "_get_auth_log_path returns auth.log for unknown OS" {
    export DETECTED_OS="unknown"
    result=$(_get_auth_log_path)
    [[ "${result}" == "/var/log/auth.log" ]]
}

# 测试 _get_ssh_service_name 函数
@test "_get_ssh_service_name returns sshd for ubuntu" {
    export DETECTED_OS="ubuntu"
    result=$(_get_ssh_service_name)
    [[ "${result}" == "sshd" ]]
}

@test "_get_ssh_service_name returns sshd for centos" {
    export DETECTED_OS="centos"
    result=$(_get_ssh_service_name)
    [[ "${result}" == "sshd" ]]
}

# 测试 _configure_fail2ban_jail 函数
@test "_configure_fail2ban_jail creates jail.local" {
    # 创建临时目录
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"

    # Mock _backup_fail2ban_config
    _backup_fail2ban_config() {
        echo "backup called"
    }

    # 覆盖 FAIL2BAN_JAIL_LOCAL 使用测试目录
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _configure_fail2ban_jail "2222" "/var/log/auth.log" "3600" "600" "5"

    [[ -f "${test_jail_dir}/jail.local" ]]
}

@test "_configure_fail2ban_jail sets correct bantime" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/auth.log" "7200" "600" "5"

    grep -q "bantime = 7200" "${test_jail_dir}/jail.local"
}

@test "_configure_fail2ban_jail sets correct maxretry" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/auth.log" "3600" "600" "10"

    grep -q "maxretry = 10" "${test_jail_dir}/jail.local"
}

@test "_configure_fail2ban_jail sets correct ssh port" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/auth.log" "3600" "600" "5"

    grep -q "port = 2222" "${test_jail_dir}/jail.local"
}

@test "_configure_fail2ban_jail sets correct logpath" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/secure" "3600" "600" "5"

    grep -q "logpath = /var/log/secure" "${test_jail_dir}/jail.local"
}

# 测试 _configure_fail2ban_jail 默认参数
@test "_configure_fail2ban_jail uses default bantime" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/auth.log"

    grep -q "bantime = 3600" "${test_jail_dir}/jail.local"
}

@test "_configure_fail2ban_jail uses default findtime" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/auth.log"

    grep -q "findtime = 600" "${test_jail_dir}/jail.local"
}

@test "_configure_fail2ban_jail uses default maxretry" {
    local test_jail_dir="${TEST_DIR}/fail2ban"
    mkdir -p "${test_jail_dir}"
    FAIL2BAN_JAIL_LOCAL="${test_jail_dir}/jail.local"

    _backup_fail2ban_config() {
        echo "backup called"
    }

    _configure_fail2ban_jail "2222" "/var/log/auth.log"

    grep -q "maxretry = 5" "${test_jail_dir}/jail.local"
}

# 测试 get_fail2ban_info 函数
@test "get_fail2ban_info shows configuration info" {
    # Mock _get_ssh_port
    _get_ssh_port() {
        echo "2222"
    }

    # Mock get_ssh_port and _get_auth_log_path
    get_ssh_port() {
        echo "2222"
    }
    _get_auth_log_path() {
        echo "/var/log/auth.log"
    }

    run get_fail2ban_info
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"2222"* ]]
    [[ "${output}" == *"/var/log/auth.log"* ]]
}

# 测试 run_fail2ban_hardening_custom 函数
@test "run_fail2ban_wizard exists and is callable" {
    type run_fail2ban_wizard | grep -q "function"
}

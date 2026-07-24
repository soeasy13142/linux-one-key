#!/usr/bin/env bats
# rootkit.bats - 单元测试 for scripts/security/rootkit.sh

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
    source "${SCRIPT_DIR}/scripts/security/rootkit.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # 覆盖 Rootkit 常量使用测试目录（避免操作真实系统路径）
    RKHUNTER_CONF="${TEST_DIR}/rkhunter/rkhunter.conf"
    RKHUNTER_LOG_DIR="${TEST_DIR}/rkhunter/log"
    RKHUNTER_CRON="${TEST_DIR}/rkhunter/cron"
    CHKROOTKIT_LOG_DIR="${TEST_DIR}/chkrootkit/log"
    RKHUNTER_PROP_FILE="${TEST_DIR}/rkhunter/rkhunter.dat"

    # Mock system commands
    export DETECTED_OS="ubuntu"

    # Mock command_exists
    command_exists() {
        case "$1" in
            rkhunter) return 1 ;;
            chkrootkit) return 1 ;;
            systemctl) return 1 ;;
            *) return 1 ;;
        esac
    }

    # Mock is_root
    is_root() { return 0; }

    # Mock confirm
    confirm() { return 0; }

    # Mock backup_file
    backup_file() { return 0; }
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ═══════════════════════════════════════════
# 常量测试
# ═══════════════════════════════════════════

@test "_ROOTKIT_LOADED is set" {
    [[ "${_ROOTKIT_LOADED}" == "1" ]]
}

@test "ROOTKIT_CONSTANTS are defined" {
    [[ -n "${RKHUNTER_CONF}" ]]
    [[ -n "${RKHUNTER_LOG_DIR}" ]]
    [[ -n "${RKHUNTER_CRON}" ]]
    [[ -n "${CHKROOTKIT_LOG_DIR}" ]]
    [[ -n "${RKHUNTER_PROP_FILE}" ]]
}

@test "ROOTKIT constants are defined and non-empty" {
    [[ -n "${RKHUNTER_CONF}" ]]
    [[ -n "${RKHUNTER_CRON}" ]]
    [[ -n "${RKHUNTER_LOG_DIR}" ]]
}

# ═══════════════════════════════════════════
# 函数存在性测试
# ═══════════════════════════════════════════

@test "_install_rkhunter function exists" {
    type _install_rkhunter
}

@test "_install_chkrootkit function exists" {
    type _install_chkrootkit
}

@test "_configure_rkhunter function exists" {
    type _configure_rkhunter
}

@test "_update_rkhunter_props function exists" {
    type _update_rkhunter_props
}

@test "_setup_rkhunter_cron function exists" {
    type _setup_rkhunter_cron
}

@test "_run_rkhunter_scan function exists" {
    type _run_rkhunter_scan
}

@test "run_rootkit_wizard function exists" {
    type run_rootkit_wizard
}

@test "check_rootkit_status function exists" {
    type check_rootkit_status
}

@test "_show_rootkit_status function exists" {
    type _show_rootkit_status
}

# ═══════════════════════════════════════════
# 输出格式测试
# ═══════════════════════════════════════════

@test "check_rootkit_status returns key=value format" {
    local output
    output=$(check_rootkit_status)
    echo "${output}" | grep -q '^rkhunter_installed='
    echo "${output}" | grep -q '^chkrootkit_installed='
    echo "${output}" | grep -q '^cron_enabled='
}

@test "check_rootkit_status reports not installed by default" {
    run check_rootkit_status
    [[ "${output}" =~ rkhunter_installed=no ]]
    [[ "${output}" =~ chkrootkit_installed=no ]]
    [[ "${output}" =~ cron_enabled=no ]]
}

@test "check_rootkit_status reports rkhunter_installed=yes when installed" {
    command_exists() {
        case "$1" in
            rkhunter) return 0 ;;
            *) return 1 ;;
        esac
    }
    run check_rootkit_status
    [[ "${output}" =~ rkhunter_installed=yes ]]
}

@test "check_rootkit_status reports chkrootkit_installed=yes when installed" {
    command_exists() {
        case "$1" in
            chkrootkit) return 0 ;;
            *) return 1 ;;
        esac
    }
    run check_rootkit_status
    [[ "${output}" =~ chkrootkit_installed=yes ]]
}

@test "check_rootkit_status reports cron_enabled=yes when cron exists" {
    mkdir -p "$(dirname "${RKHUNTER_CRON}")"
    touch "${RKHUNTER_CRON}"
    run check_rootkit_status
    [[ "${output}" =~ cron_enabled=yes ]]
}

# ═══════════════════════════════════════════
# _install_rkhunter 测试
# ═══════════════════════════════════════════

@test "_install_rkhunter detects already installed" {
    command_exists() {
        case "$1" in
            rkhunter) return 0 ;;
            *) return 1 ;;
        esac
    }
    run _install_rkhunter
    [[ "${status}" -eq 0 ]]
}

@test "_install_rkhunter handles unsupported OS" {
    DETECTED_OS="unknown"
    run _install_rkhunter
    [[ "${status}" -eq 1 ]]
}

# ═══════════════════════════════════════════
# _install_chkrootkit 测试
# ═══════════════════════════════════════════

@test "_install_chkrootkit detects already installed" {
    command_exists() {
        case "$1" in
            chkrootkit) return 0 ;;
            *) return 1 ;;
        esac
    }
    run _install_chkrootkit
    [[ "${status}" -eq 0 ]]
}

@test "_install_chkrootkit handles RHEL gracefully" {
    DETECTED_OS="centos"
    run _install_chkrootkit
    [[ "${status}" -eq 1 ]]
}

@test "_install_chkrootkit handles ubuntu" {
    DETECTED_OS="ubuntu"
    run _install_chkrootkit
    [[ "${status}" -eq 1 ]]  # fails because apt-get mock not available
}

# ═══════════════════════════════════════════
# _configure_rkhunter 测试
# ═══════════════════════════════════════════

@test "_configure_rkhunter creates config file" {
    run _configure_rkhunter
    [[ -f "${RKHUNTER_CONF}" ]]
}

@test "_configure_rkhunter produces valid content" {
    _configure_rkhunter
    grep -q "MAILTO=root" "${RKHUNTER_CONF}"
    grep -q "REPORT_METHOD=stdout" "${RKHUNTER_CONF}"
    grep -q "ENABLE_TESTS=all" "${RKHUNTER_CONF}"
}

# ═══════════════════════════════════════════
# _setup_rkhunter_cron 测试
# ═══════════════════════════════════════════

@test "_setup_rkhunter_cron creates cron file" {
    run _setup_rkhunter_cron
    [[ -f "${RKHUNTER_CRON}" ]]
}

@test "_setup_rkhunter_cron produces valid cron content" {
    _setup_rkhunter_cron
    grep -q "rkhunter" "${RKHUNTER_CRON}"
}

# ═══════════════════════════════════════════
# run_rootkit_wizard 测试
# ═══════════════════════════════════════════

@test "run_rootkit_wizard returns 0 when skipped" {
    confirm() { return 1; }
    run run_rootkit_wizard
    [[ "${status}" -eq 0 ]]
}

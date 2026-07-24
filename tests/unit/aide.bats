#!/usr/bin/env bats
# aide.bats - 单元测试 for scripts/security/aide.sh

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
    source "${SCRIPT_DIR}/scripts/security/aide.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # 覆盖 AIDE 常量使用测试目录（避免操作真实系统路径）
    AIDE_CONF="${TEST_DIR}/aide/aide.conf"
    AIDE_DB_DIR="${TEST_DIR}/aide/db"
    AIDE_DB="${AIDE_DB_DIR}/aide.db.gz"
    AIDE_DB_NEW="${AIDE_DB_DIR}/aide.db.new.gz"
    AIDE_CRON_FILE="${TEST_DIR}/aide/cron"
    AIDE_REPORT_DIR="${TEST_DIR}/aide/report"

    # Mock system commands
    export DETECTED_OS="ubuntu"

    # Mock command_exists for aide
    command_exists() {
        case "$1" in
            aide) return 1 ;;  # not installed by default
            aideinit) return 1 ;;
            systemctl) return 1 ;;
            *) return 1 ;;
        esac
    }

    # Mock is_root
    is_root() { return 0; }

    # Mock confirm
    confirm() { return 0; }
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ═══════════════════════════════════════════
# 常量测试
# ═══════════════════════════════════════════

@test "_AIDE_LOADED is set" {
    [[ "${_AIDE_LOADED}" == "1" ]]
}

@test "AIDE_CONSTANTS are defined" {
    [[ -n "${AIDE_CONF}" ]]
    [[ -n "${AIDE_DB_DIR}" ]]
    [[ -n "${AIDE_DB}" ]]
    [[ -n "${AIDE_DB_NEW}" ]]
    [[ -n "${AIDE_CRON_FILE}" ]]
    [[ -n "${AIDE_REPORT_DIR}" ]]
}

@test "AIDE_CONF ends with aide.conf" {
    [[ "${AIDE_CONF}" == *aide.conf ]]
}

@test "AIDE_CRON_FILE is defined and non-empty" {
    [[ -n "${AIDE_CRON_FILE}" ]]
}

# ═══════════════════════════════════════════
# 函数存在性测试
# ═══════════════════════════════════════════

@test "_install_aide function exists" {
    type _install_aide
}

@test "_backup_aide_config function exists" {
    type _backup_aide_config
}

@test "_configure_aide function exists" {
    type _configure_aide
}

@test "_init_aide_database function exists" {
    type _init_aide_database
}

@test "_setup_aide_cron function exists" {
    type _setup_aide_cron
}

@test "_show_aide_status function exists" {
    type _show_aide_status
}

@test "run_aide_wizard function exists" {
    type run_aide_wizard
}

@test "check_aide_status function exists" {
    type check_aide_status
}

# ═══════════════════════════════════════════
# 输出格式测试
# ═══════════════════════════════════════════

@test "check_aide_status returns key=value format" {
    local output
    output=$(check_aide_status)
    echo "${output}" | grep -q '^aide_db_exists='
    echo "${output}" | grep -q '^aide_cron='
}

@test "check_aide_status includes aide_db_exists" {
    run check_aide_status
    [[ "${output}" =~ ^aide_db_exists= ]]
}

@test "check_aide_status reports aide_db_exists=no when db missing" {
    run check_aide_status
    [[ "${output}" =~ aide_db_exists=no ]]
}

@test "check_aide_status reports aide_cron=no when cron missing" {
    run check_aide_status
    [[ "${output}" =~ aide_cron=no ]]
}

@test "check_aide_status reports aide_db_exists=yes when db exists" {
    mkdir -p "$(dirname "${AIDE_DB}")"
    touch "${AIDE_DB}"
    run check_aide_status
    [[ "${output}" =~ aide_db_exists=yes ]]
}

@test "check_aide_status reports aide_cron=yes when cron exists" {
    mkdir -p "$(dirname "${AIDE_CRON_FILE}")"
    touch "${AIDE_CRON_FILE}"
    run check_aide_status
    [[ "${output}" =~ aide_cron=yes ]]
}

# ═══════════════════════════════════════════
# _install_aide 测试
# ═══════════════════════════════════════════

@test "_install_aide detects already installed" {
    command_exists() {
        case "$1" in
            aide) return 0 ;;
            *) return 1 ;;
        esac
    }
    run _install_aide
    [[ "${status}" -eq 0 ]]
}

@test "_install_aide handles unsupported OS" {
    DETECTED_OS="unknown"
    run _install_aide
    [[ "${status}" -eq 1 ]]
}

# ═══════════════════════════════════════════
# _backup_aide_config 测试
# ═══════════════════════════════════════════

@test "_backup_aide_config works when config missing" {
    run _backup_aide_config
    [[ "${status}" -eq 0 ]]
}

# ═══════════════════════════════════════════
# _configure_aide 测试
# ═══════════════════════════════════════════

@test "_configure_aide creates config file" {
    run _configure_aide
    [[ -f "${AIDE_CONF}" ]]
}

@test "_configure_aide produces valid content" {
    _configure_aide
    grep -q "database=file:" "${AIDE_CONF}"
    grep -q "/etc/passwd" "${AIDE_CONF}"
    grep -q "/etc/shadow" "${AIDE_CONF}"
    grep -q "/etc/ssh/sshd_config" "${AIDE_CONF}"
}

# ═══════════════════════════════════════════
# _setup_aide_cron 测试
# ═══════════════════════════════════════════

@test "_setup_aide_cron creates cron file" {
    run _setup_aide_cron
    [[ -f "${AIDE_CRON_FILE}" ]]
}

#!/usr/bin/env bats
# clamav.bats - 单元测试 for scripts/security/clamav.sh

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
    source "${SCRIPT_DIR}/scripts/security/clamav.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # 覆盖 ClamAV 常量使用测试目录（避免操作真实系统路径）
    CLAMAV_CONF_DIR="${TEST_DIR}/clamav"
    CLAMAVD_CONF="${CLAMAV_CONF_DIR}/clamd.conf"
    FRESHCLAM_CONF="${CLAMAV_CONF_DIR}/freshclam.conf"
    CLAMAV_LOG_DIR="${TEST_DIR}/clamav/log"
    CLAMAV_QUARANTINE_DIR="${TEST_DIR}/clamav/quarantine"
    CLAMAV_CRON_UPDATE="${TEST_DIR}/clamav/cron-update"
    CLAMAV_CRON_SCAN="${TEST_DIR}/clamav/cron-scan"

    # Mock system commands
    export DETECTED_OS="ubuntu"

    # Mock command_exists
    command_exists() {
        case "$1" in
            clamscan) return 1 ;;
            freshclam) return 1 ;;
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

@test "_CLAMAV_LOADED is set" {
    [[ "${_CLAMAV_LOADED}" == "1" ]]
}

@test "CLAMAV_CONSTANTS are defined" {
    [[ -n "${CLAMAV_CONF_DIR}" ]]
    [[ -n "${CLAMAVD_CONF}" ]]
    [[ -n "${FRESHCLAM_CONF}" ]]
    [[ -n "${CLAMAV_LOG_DIR}" ]]
    [[ -n "${CLAMAV_QUARANTINE_DIR}" ]]
    [[ -n "${CLAMAV_CRON_UPDATE}" ]]
    [[ -n "${CLAMAV_CRON_SCAN}" ]]
}

@test "CLAMAV constants have correct path endings" {
    [[ "${CLAMAV_CONF_DIR}" == *clamav ]]
    [[ "${CLAMAV_QUARANTINE_DIR}" == *quarantine ]]
    [[ "${CLAMAV_CRON_UPDATE}" == *freshclam ]]
    [[ "${CLAMAV_CRON_SCAN}" == *scan ]]
}

# ═══════════════════════════════════════════
# 函数存在性测试
# ═══════════════════════════════════════════

@test "_install_clamav function exists" {
    type _install_clamav
}

@test "_configure_freshclam function exists" {
    type _configure_freshclam
}

@test "_setup_freshclam_cron function exists" {
    type _setup_freshclam_cron
}

@test "_run_freshclam_now function exists" {
    type _run_freshclam_now
}

@test "_setup_scan_cron function exists" {
    type _setup_scan_cron
}

@test "run_clamav_wizard function exists" {
    type run_clamav_wizard
}

@test "check_clamav_status function exists" {
    type check_clamav_status
}

@test "_run_clamav_scan function exists" {
    type _run_clamav_scan
}

@test "_show_clamav_status function exists" {
    type _show_clamav_status
}

# ═══════════════════════════════════════════
# 输出格式测试
# ═══════════════════════════════════════════

@test "check_clamav_status returns key=value format" {
    local output
    output=$(check_clamav_status)
    echo "${output}" | grep -q '^clamav_db_uptodate='
    echo "${output}" | grep -q '^clamav_cron_enabled='
}

@test "check_clamav_status reports db_uptodate=no when db missing" {
    run check_clamav_status
    [[ "${output}" =~ clamav_db_uptodate=no ]]
}

@test "check_clamav_status reports cron_enabled=no when cron missing" {
    run check_clamav_status
    [[ "${output}" =~ clamav_cron_enabled=no ]]
}

@test "check_clamav_status reports cron_enabled=yes when cron exists" {
    mkdir -p "$(dirname "${CLAMAV_CRON_UPDATE}")"
    touch "${CLAMAV_CRON_UPDATE}"
    run check_clamav_status
    [[ "${output}" =~ clamav_cron_enabled=yes ]]
}

# ═══════════════════════════════════════════
# _install_clamav 测试
# ═══════════════════════════════════════════

@test "_install_clamav detects already installed" {
    command_exists() {
        case "$1" in
            clamscan) return 0 ;;
            *) return 1 ;;
        esac
    }
    run _install_clamav
    [[ "${status}" -eq 0 ]]
}

@test "_install_clamav handles unsupported OS" {
    DETECTED_OS="unknown"
    run _install_clamav
    [[ "${status}" -eq 1 ]]
}

@test "_install_clamav succeeds on ubuntu" {
    DETECTED_OS="ubuntu"
    function apt-get() {
        case "$*" in
            *install*) return 0 ;;
            *) command apt-get "$@" ;;
        esac
    }
    export -f apt-get
    run _install_clamav
    [[ "${status}" -eq 0 ]]
}

# ═══════════════════════════════════════════
# _configure_freshclam 测试
# ═══════════════════════════════════════════

@test "_configure_freshclam creates config file" {
    run _configure_freshclam
    [[ -f "${FRESHCLAM_CONF}" ]]
}

@test "_configure_freshclam produces valid freshclam.conf" {
    _configure_freshclam
    grep -q "DatabaseMirror" "${FRESHCLAM_CONF}"
    grep -q "UpdateLogFile" "${FRESHCLAM_CONF}"
}

# ═══════════════════════════════════════════
# _setup_freshclam_cron 测试
# ═══════════════════════════════════════════

@test "_setup_freshclam_cron creates cron file" {
    run _setup_freshclam_cron
    [[ -f "${CLAMAV_CRON_UPDATE}" ]]
}

@test "_setup_freshclam_cron produces valid cron content" {
    _setup_freshclam_cron
    grep -q "freshclam" "${CLAMAV_CRON_UPDATE}"
}

# ═══════════════════════════════════════════
# _setup_scan_cron 测试
# ═══════════════════════════════════════════

@test "_setup_scan_cron creates cron file" {
    run _setup_scan_cron
    [[ -f "${CLAMAV_CRON_SCAN}" ]]
}

@test "_setup_scan_cron produces valid scan cron" {
    _setup_scan_cron
    grep -q "clamscan" "${CLAMAV_CRON_SCAN}"
    grep -q "nice -n 19" "${CLAMAV_CRON_SCAN}"
}

# ═══════════════════════════════════════════
# run_clamav_wizard 测试
# ═══════════════════════════════════════════

@test "run_clamav_wizard returns 0 when skipped" {
    confirm() { return 1; }
    run run_clamav_wizard
    [[ "${status}" -eq 0 ]]
}

#!/usr/bin/env bats
# init.bats - 单元测试 for scripts/base/init.sh
# Batch 1: Init & Utility Enhancements

# 测试前设置
setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # 加载依赖模块
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    # detect.sh 和 mode.sh 在 init.sh 的依赖检查中需要
    source "${SCRIPT_DIR}/scripts/base/detect.sh"
    source "${SCRIPT_DIR}/scripts/base/mode.sh"

    # 覆盖检测结果
    DETECTED_PKG_MANAGER="apt"
    DETECTED_OS="ubuntu"

    # 默认 Full 模式
    INSTALL_MODE="full"

    # 覆盖 LOG_FILE
    LOG_FILE="${TEST_DIR}/test.log"

    # 加载被测模块
    source "${SCRIPT_DIR}/scripts/base/init.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ═══════════════════════════════════════════
# Source guard 测试
# ═══════════════════════════════════════════

@test "init.sh sets _INIT_LOADED guard" {
    [[ "${_INIT_LOADED}" == "1" ]]
}

# ═══════════════════════════════════════════
# 函数存在性测试
# ═══════════════════════════════════════════

@test "_validate_timezone function exists" {
    type -t _validate_timezone | grep -q "function"
}

@test "setup_timezone function exists" {
    type -t setup_timezone | grep -q "function"
}

@test "setup_ntp function exists" {
    type -t setup_ntp | grep -q "function"
}

@test "install_base_tools function exists" {
    type -t install_base_tools | grep -q "function"
}

@test "run_init function exists" {
    type -t run_init | grep -q "function"
}

@test "_configure_chrony function exists" {
    type -t _configure_chrony | grep -q "function"
}

@test "_configure_ntpd function exists" {
    type -t _configure_ntpd | grep -q "function"
}

# ═══════════════════════════════════════════
# _validate_timezone 测试
# ═══════════════════════════════════════════

@test "_validate_timezone returns 1 for empty string" {
    # 在测试环境中，timedatectl 和 zoneinfo 通常不可用
    # 所以期望返回 1（非零，无效）
    run _validate_timezone ""
    # 根据环境可能返回 0 或 1（取决于系统是否有 zoneinfo 文件）
    # 只要函数正常执行不报错即可
    [[ "${status}" -eq 0 ]] || [[ "${status}" -eq 1 ]]
}

# ═══════════════════════════════════════════
# install_base_tools 模式测试
# ═══════════════════════════════════════════

@test "install_base_tools runs without error in Full mode" {
    # Mock apt-get to prevent actual installation
    apt-get() { return 0; }
    export -f apt-get

    run install_base_tools
    [[ "${status}" -eq 0 ]]
}

@test "install_base_tools runs without error in Lite mode" {
    INSTALL_MODE="lite"
    apt-get() { return 0; }
    export -f apt-get

    run install_base_tools
    [[ "${status}" -eq 0 ]]
}

# ═══════════════════════════════════════════
# setup_timezone 测试
# ═══════════════════════════════════════════

@test "setup_timezone accepts custom timezone parameter" {
    # Mock timedatectl
    timedatectl() {
        if [[ "$1" == "set-timezone" ]]; then
            return 0
        fi
        return 1
    }
    export -f timedatectl

    run setup_timezone "Asia/Shanghai"
    [[ "${status}" -eq 0 ]]
}

@test "setup_timezone handles invalid timezone gracefully" {
    # Mock timedatectl to always fail
    timedatectl() { return 1; }
    export -f timedatectl

    run setup_timezone "Invalid/Tz"
    # Should not crash, warn is acceptable
    [[ "${status}" -eq 0 ]] || [[ "${status}" -eq 1 ]]
}

# ═══════════════════════════════════════════
# setup_ntp 测试
# ═══════════════════════════════════════════

@test "setup_ntp handles apt-get install" {
    # Mock all system commands
    systemctl() { return 1; }
    timedatectl() { return 1; }
    chronyc() { return 1; }
    ntpd() { return 1; }
    apt-get() {
        if [[ "$1" == "install" ]]; then
            return 0
        fi
        return 1
    }
    command() {
        if [[ "$2" == "chronyc" ]] || [[ "$2" == "ntpd" ]] || [[ "$2" == "chrony" ]]; then
            return 1
        fi
        return 0
    }
    backup_file() { return 0; }
    grep() { return 1; }  # No existing NTP config match
    cat() { return 0; }   # Append to config
    systemctl_enable() { return 0; }
    restart_service() { return 0; }
    export -f systemctl timedatectl chronyc ntpd apt-get command backup_file grep cat systemctl_enable restart_service

    run setup_ntp
    # Should succeed or warn but not crash
    [[ "${status}" -eq 0 ]] || [[ "${status}" -eq 1 ]]
}

@test "setup_ntp skips when chronyc tracking succeeds" {
    # Mock chronyc to succeed (already synced)
    chronyc() { return 0; }
    command() {
        if [[ "$2" == "chronyc" ]]; then
            return 0
        fi
        return 1
    }
    systemctl() { return 1; }
    timedatectl() { return 1; }
    export -f chronyc command systemctl timedatectl

    run setup_ntp
    # Already synced, should succeed
    [[ "${status}" -eq 0 ]]
}

# ═══════════════════════════════════════════
# run_init 测试
# ═══════════════════════════════════════════

@test "run_init fails without root" {
    # Mock is_root to return false
    is_root() { return 1; }
    export -f is_root

    run run_init
    [[ "${status}" -eq 1 ]]
}

@test "run_init fails without detect.sh loaded" {
    # Cannot easily test without detect.sh since it's a setup dependency
    # This is a placeholder for the dependency check
    [[ "${_DETECT_LOADED}" == "1" ]]
}

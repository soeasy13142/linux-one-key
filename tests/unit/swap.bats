#!/usr/bin/env bats
# swap.bats - 单元测试 for scripts/base/swap.sh
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

    LOG_FILE="${TEST_DIR}/test.log"

    # 加载被测模块
    source "${SCRIPT_DIR}/scripts/base/swap.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ═══════════════════════════════════════════
# 常量测试
# ═══════════════════════════════════════════

@test "SWAP_FILE_PATH is /swapfile" {
    [[ "${SWAP_FILE_PATH}" == "/swapfile" ]]
}

@test "SWAP_RAM_LOW_THRESHOLD is 2048" {
    [[ "${SWAP_RAM_LOW_THRESHOLD}" -eq 2048 ]]
}

@test "SWAP_RAM_MED_THRESHOLD is 8192" {
    [[ "${SWAP_RAM_MED_THRESHOLD}" -eq 8192 ]]
}

@test "SWAP_SIZE_MED_VALUE is 4096" {
    [[ "${SWAP_SIZE_MED_VALUE}" -eq 4096 ]]
}

@test "SWAP_SIZE_HIGH_DEFAULT is 4096" {
    [[ "${SWAP_SIZE_HIGH_DEFAULT}" -eq 4096 ]]
}

@test "SWAP_SIZE_HIGH_MAX is 8192" {
    [[ "${SWAP_SIZE_HIGH_MAX}" -eq 8192 ]]
}

@test "SWAPPINESS_VALUE is 10" {
    [[ "${SWAPPINESS_VALUE}" -eq 10 ]]
}

# ═══════════════════════════════════════════
# Source guard 测试
# ═══════════════════════════════════════════

@test "swap.sh sets _SWAP_LOADED guard" {
    [[ "${_SWAP_LOADED}" == "1" ]]
}

# ═══════════════════════════════════════════
# 函数存在性测试
# ═══════════════════════════════════════════

@test "_get_total_ram_mb function exists" {
    type -t _get_total_ram_mb | grep -q "function"
}

@test "_calculate_swap_size_mb function exists" {
    type -t _calculate_swap_size_mb | grep -q "function"
}

@test "_get_current_swap_info function exists" {
    type -t _get_current_swap_info | grep -q "function"
}

@test "check_swap_status function exists" {
    type -t check_swap_status | grep -q "function"
}

@test "setup_swap function exists" {
    type -t setup_swap | grep -q "function"
}

@test "run_swap_wizard function exists" {
    type -t run_swap_wizard | grep -q "function"
}

# ═══════════════════════════════════════════
# _calculate_swap_size_mb 逻辑测试
# ═══════════════════════════════════════════

@test "_calculate_swap_size_mb returns RAM for RAM < 2G (1024MB)" {
    run _calculate_swap_size_mb 1024
    [[ "${status}" -eq 0 ]]
    [[ "${output}" -eq 1024 ]]
}

@test "_calculate_swap_size_mb returns RAM for RAM < 2G (512MB)" {
    run _calculate_swap_size_mb 512
    [[ "${status}" -eq 0 ]]
    [[ "${output}" -eq 512 ]]
}

@test "_calculate_swap_size_mb returns 4096 for RAM 2-8G (2048MB)" {
    run _calculate_swap_size_mb 2048
    [[ "${status}" -eq 0 ]]
    [[ "${output}" -eq 4096 ]]
}

@test "_calculate_swap_size_mb returns 4096 for RAM 2-8G (4096MB)" {
    run _calculate_swap_size_mb 4096
    [[ "${status}" -eq 0 ]]
    [[ "${output}" -eq 4096 ]]
}

@test "_calculate_swap_size_mb returns 4096 for RAM 2-8G (8192MB)" {
    run _calculate_swap_size_mb 8192
    [[ "${status}" -eq 0 ]]
    [[ "${output}" -eq 4096 ]]
}

@test "_calculate_swap_size_mb returns 4096 for RAM > 8G (16384MB)" {
    run _calculate_swap_size_mb 16384
    [[ "${status}" -eq 0 ]]
    [[ "${output}" -eq 4096 ]]
}

@test "_calculate_swap_size_mb returns 0 for invalid input" {
    run _calculate_swap_size_mb 0
    [[ "${status}" -eq 1 ]]
    [[ "${output}" -eq 0 ]]
}

# ═══════════════════════════════════════════
# check_swap_status 输出格式测试
# ═══════════════════════════════════════════

@test "check_swap_status outputs swap_exists key" {
    local output
    output=$(check_swap_status)
    echo "${output}" | grep -q "^swap_exists="
}

@test "check_swap_status outputs swap_size_mb key" {
    local output
    output=$(check_swap_status)
    echo "${output}" | grep -q "^swap_size_mb="
}

@test "check_swap_status outputs swap_file key" {
    local output
    output=$(check_swap_status)
    echo "${output}" | grep -q "^swap_file="
}

@test "check_swap_status outputs swappiness key" {
    local output
    output=$(check_swap_status)
    echo "${output}" | grep -q "^swappiness="
}

@test "check_swap_status outputs 4 lines" {
    local output
    output=$(check_swap_status)
    local line_count
    line_count=$(echo "${output}" | grep -c "^" )
    [[ "${line_count}" -eq 4 ]]
}

#!/usr/bin/env bats
# services.bats - 单元测试 for scripts/security/services.sh

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
    source "${SCRIPT_DIR}/scripts/security/services.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"

    # Mock system commands
    export DETECTED_OS="ubuntu"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ═══════════════════════════════════════════
# 常量测试
# ═══════════════════════════════════════════

@test "UNNECESSARY_SERVICES array is defined" {
    [[ "${#UNNECESSARY_SERVICES[@]}" -gt 0 ]]
}

@test "UNNECESSARY_SERVICES contains telnet.socket" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "telnet.socket" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES contains rsh.socket" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "rsh.socket" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES contains rlogin.socket" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "rlogin.socket" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES contains vsftpd" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "vsftpd" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES contains avahi-daemon" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "avahi-daemon" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES contains cups" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "cups" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES contains rpcbind" {
    local found=0
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        if [[ "${entry%%:*}" == "rpcbind" ]]; then
            found=1
            break
        fi
    done
    [[ "${found}" -eq 1 ]]
}

@test "UNNECESSARY_SERVICES has 7 entries" {
    [[ "${#UNNECESSARY_SERVICES[@]}" -eq 7 ]]
}

@test "SAFE_PORTS contains port 22" {
    echo "${SAFE_PORTS}" | grep -qw "22"
}

@test "SAFE_PORTS contains port 80" {
    echo "${SAFE_PORTS}" | grep -qw "80"
}

@test "SAFE_PORTS contains port 443" {
    echo "${SAFE_PORTS}" | grep -qw "443"
}

# ═══════════════════════════════════════════
# Source guard 测试
# ═══════════════════════════════════════════

@test "services.sh sets _SERVICES_LOADED guard" {
    [[ "${_SERVICES_LOADED}" == "1" ]]
}

# ═══════════════════════════════════════════
# 函数存在性测试
# ═══════════════════════════════════════════

@test "_list_running_services function exists" {
    type -t _list_running_services | grep -q "function"
}

@test "_check_unnecessary_services function exists" {
    type -t _check_unnecessary_services | grep -q "function"
}

@test "_disable_service function exists" {
    type -t _disable_service | grep -q "function"
}

@test "_scan_listening_ports function exists" {
    type -t _scan_listening_ports | grep -q "function"
}

@test "_is_safe_port function exists" {
    type -t _is_safe_port | grep -q "function"
}

@test "audit_services function exists" {
    type -t audit_services | grep -q "function"
}

@test "disable_unnecessary_services function exists" {
    type -t disable_unnecessary_services | grep -q "function"
}

@test "scan_open_ports function exists" {
    type -t scan_open_ports | grep -q "function"
}

@test "check_services_status function exists" {
    type -t check_services_status | grep -q "function"
}

@test "run_services_wizard function exists" {
    type -t run_services_wizard | grep -q "function"
}

# ═══════════════════════════════════════════
# _is_safe_port 测试
# ═══════════════════════════════════════════

@test "_is_safe_port returns 0 for port 22" {
    _is_safe_port "22"
}

@test "_is_safe_port returns 0 for port 80" {
    _is_safe_port "80"
}

@test "_is_safe_port returns 0 for port 443" {
    _is_safe_port "443"
}

@test "_is_safe_port returns 1 for port 8080" {
    run _is_safe_port "8080"
    [[ "${status}" -eq 1 ]]
}

@test "_is_safe_port returns 1 for port 3306" {
    run _is_safe_port "3306"
    [[ "${status}" -eq 1 ]]
}

# ═══════════════════════════════════════════
# _check_unnecessary_services 输出格式测试
# ═══════════════════════════════════════════

@test "_check_unnecessary_services output contains colon separators" {
    local output
    output=$(_check_unnecessary_services)
    local first_line
    first_line=$(echo "${output}" | head -1)
    # 格式: service_name:description:status
    local colon_count
    colon_count=$(echo "${first_line}" | tr -cd ':' | wc -c | tr -d ' ')
    [[ "${colon_count}" -ge 2 ]]
}

@test "_check_unnecessary_services first entry is telnet.socket" {
    local output
    output=$(_check_unnecessary_services)
    local first_line
    first_line=$(echo "${output}" | head -1)
    [[ "${first_line%%:*}" == "telnet.socket" ]]
}

@test "_check_unnecessary_services status is active or inactive" {
    local output
    output=$(_check_unnecessary_services)
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        local status="${line##*:}"
        [[ "${status}" == "active" ]] || [[ "${status}" == "inactive" ]]
    done <<< "${output}"
}

# ═══════════════════════════════════════════
# check_services_status 输出格式测试
# ═══════════════════════════════════════════

@test "check_services_status outputs services_running key" {
    local output
    output=$(check_services_status)
    echo "${output}" | grep -q "^services_running="
}

@test "check_services_status outputs services_unnecessary key" {
    local output
    output=$(check_services_status)
    echo "${output}" | grep -q "^services_unnecessary="
}

@test "check_services_status services_running is a number" {
    local output
    output=$(check_services_status)
    local running
    running=$(echo "${output}" | grep '^services_running=' | cut -d= -f2)
    [[ "${running}" =~ ^[0-9]+$ ]]
}

@test "check_services_status services_unnecessary is a number" {
    local output
    output=$(check_services_status)
    local unnecessary
    unnecessary=$(echo "${output}" | grep '^services_unnecessary=' | cut -d= -f2)
    [[ "${unnecessary}" =~ ^[0-9]+$ ]]
}

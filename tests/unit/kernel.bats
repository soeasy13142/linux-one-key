#!/usr/bin/env bats
# kernel.bats - 单元测试 for scripts/security/kernel.sh

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

    # 模拟 detect.sh 的变量
    export DETECTED_OS="ubuntu"

    source "${SCRIPT_DIR}/scripts/security/kernel.sh"

    # 覆盖 LOG_FILE 使用测试目录
    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── 常量测试 ──

@test "SYSCTL_HARDENING_CONF is set to correct path" {
    # 直接检查源文件中的定义
    grep -q 'readonly SYSCTL_HARDENING_CONF="/etc/sysctl.d/99-hardening.conf"' \
        "${SCRIPT_DIR}/scripts/security/kernel.sh"
}

@test "DISABLED_MODULES contains cramfs" {
    grep -q '"cramfs"' "${SCRIPT_DIR}/scripts/security/kernel.sh"
}

@test "DISABLED_MODULES contains usb-storage" {
    grep -q '"usb-storage"' "${SCRIPT_DIR}/scripts/security/kernel.sh"
}

@test "DISABLED_MODULES contains 6 modules" {
    local count
    count=$(sed -n '/readonly DISABLED_MODULES/,/)/p' "${SCRIPT_DIR}/scripts/security/kernel.sh" | grep -c '^\s*"')
    [[ ${count} -eq 6 ]]
}

# ── 函数存在性测试 ──

@test "apply_sysctl_params function exists" {
    [[ "$(type -t apply_sysctl_params)" == "function" ]]
}

@test "disable_kernel_modules function exists" {
    [[ "$(type -t disable_kernel_modules)" == "function" ]]
}

@test "restore_sysctl_backup function exists" {
    [[ "$(type -t restore_sysctl_backup)" == "function" ]]
}

@test "run_kernel_wizard function exists" {
    [[ "$(type -t run_kernel_wizard)" == "function" ]]
}

@test "check_kernel_status function exists" {
    [[ "$(type -t check_kernel_status)" == "function" ]]
}

# ── _generate_sysctl_config 测试 ──
# 注意: SYSCTL_HARDENING_CONF 是 readonly，无法在测试中覆盖
# 改为直接检查模板文件和内嵌配置的内容

@test "template file contains tcp_syncookies = 1" {
    grep -q "net.ipv4.tcp_syncookies = 1" "${SYSCTL_TEMPLATE}"
}

@test "template file disables ICMP redirects" {
    grep -q "net.ipv4.conf.all.accept_redirects = 0" "${SYSCTL_TEMPLATE}"
}

@test "template file disables IP forwarding" {
    grep -q "net.ipv4.ip_forward = 0" "${SYSCTL_TEMPLATE}"
}

@test "template file enables ASLR" {
    grep -q "kernel.randomize_va_space = 2" "${SYSCTL_TEMPLATE}"
}

@test "template file disables SUID core dumps" {
    grep -q "fs.suid_dumpable = 0" "${SYSCTL_TEMPLATE}"
}

@test "template file restricts dmesg" {
    grep -q "kernel.dmesg_restrict = 1" "${SYSCTL_TEMPLATE}"
}

# ── SYSCTL_TEMPLATE 测试 ──

@test "SYSCTL_TEMPLATE points to existing template file" {
    [[ -f "${SYSCTL_TEMPLATE}" ]]
}

@test "template file contains sysctl parameters" {
    grep -q "net.ipv4.tcp_syncookies" "${SYSCTL_TEMPLATE}"
    grep -q "kernel.randomize_va_space" "${SYSCTL_TEMPLATE}"
}

# ── check_kernel_status 测试 ──

@test "check_kernel_status outputs kernel_conf key" {
    run check_kernel_status
    echo "${output}" | grep -q "kernel_conf="
}

@test "check_kernel_status outputs kernel_params key" {
    run check_kernel_status
    echo "${output}" | grep -q "kernel_params="
}

@test "check_kernel_status outputs kernel_modules_disabled key" {
    run check_kernel_status
    echo "${output}" | grep -q "kernel_modules_disabled="
}

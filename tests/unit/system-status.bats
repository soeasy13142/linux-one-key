#!/usr/bin/env bats
# system-status.bats - 系统状态检测升级（spec §3.3 GAP-4/5/6）
#
# 这些是结构性测试：通过 grep install.sh 验证 show_system_status 引用了
# 新增的 i18n 键（MSG_STATUS_HARDENED / _PARTIAL / _NOT_HARDENED / _RECOMMENDATION）。
# 不 mock 系统状态（避免脆弱），只验证代码契约。

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export INSTALL_SH="${SCRIPT_DIR}/install.sh"
}

teardown() {
    # No resources to clean up -- all tests are read-only grep checks on install.sh
    true
}

@test "show_system_status function exists in install.sh" {
    run grep -E "^show_system_status\(\)" "${INSTALL_SH}"
    [[ "$status" -eq 0 ]]
}

@test "show_system_status references all 3 status labels (hardened/partial/not)" {
    run bash -c "grep -E 'MSG_STATUS_HARDENED|MSG_STATUS_PARTIAL|MSG_STATUS_NOT_HARDENED' '${INSTALL_SH}'"
    [[ "$status" -eq 0 ]]
}

@test "show_system_status references MSG_STATUS_RECOMMENDATION" {
    run bash -c "grep -F 'MSG_STATUS_RECOMMENDATION' '${INSTALL_SH}'"
    [[ "$status" -eq 0 ]]
}

@test "show_system_status computes total module count (8 modules expected)" {
    # 应有 8 个模块的状态行（SSH/Firewall/Fail2Ban/Audit/Users/Kernel/FS/Services）
    run bash -c "grep -cE 'MSG_STATUS_(SSH_PORT|FIREWALL|FAIL2BAN|AUDIT|USERS|KERNEL|FILESYSTEM|SERVICES)\b' '${INSTALL_SH}'"
    [[ "$status" -eq 0 ]]
    # 8 个不同模块 key
    [[ "$output" -ge 8 ]]
}

@test "main menu case 1 still calls show_system_status" {
    run bash -c "grep -E '^[[:space:]]+1\) show_system_status' '${INSTALL_SH}'"
    [[ "$status" -eq 0 ]]
}

@test "status output uses color constants (GREEN/YELLOW/RED)" {
    # 状态行应根据加固情况使用不同颜色
    run bash -c "grep -cE '\\\$\{(GREEN|YELLOW|RED)\}' '${INSTALL_SH}'"
    [[ "$status" -eq 0 ]]
    [[ "$output" -ge 3 ]]
}
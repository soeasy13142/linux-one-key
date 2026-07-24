#!/usr/bin/env bats
# mode.bats - Lite/Full 模式模块测试

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."

    source "${SCRIPT_DIR}/scripts/base/mode.sh"

    # 默认取消模式设置
    unset INSTALL_MODE
}

teardown() {
    rm -rf "${TEST_DIR}"
    unset INSTALL_MODE
}

@test "mode: MODE_LITE_MODULES contains core modules" {
    [[ " ${MODE_LITE_MODULES[*]} " == *" ssh "* ]]
    [[ " ${MODE_LITE_MODULES[*]} " == *" firewall "* ]]
    [[ " ${MODE_LITE_MODULES[*]} " == *" kernel "* ]]
}

@test "mode: MODE_FULL_MODULES contains full-only modules" {
    [[ " ${MODE_FULL_MODULES[*]} " == *" fail2ban "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" audit "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" users "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" filesystem "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" services "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" k3s "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" swap "* ]]
    [[ " ${MODE_FULL_MODULES[*]} " == *" autoupdate "* ]]
}

@test "mode: MODE_ALL_MODULES contains all modules" {
    local count=0
    for m in "${MODE_ALL_MODULES[@]}"; do
        case "${m}" in
            ssh|firewall|kernel|fail2ban|audit|users|filesystem|services|k3s|swap|autoupdate) count=$((count + 1)) ;;
        esac
    done
    [[ "${count}" -eq 11 ]]
}

@test "mode: is_mode_full returns true by default" {
    unset INSTALL_MODE
    is_mode_full
}

@test "mode: is_mode_lite returns true when INSTALL_MODE=lite" {
    INSTALL_MODE="lite"
    is_mode_lite
}

@test "mode: is_mode_lite returns false when INSTALL_MODE=full" {
    INSTALL_MODE="full"
    ! is_mode_lite
}

@test "mode: is_module_lite returns true for ssh" {
    is_module_lite "ssh"
}

@test "mode: is_module_lite returns false for fail2ban" {
    ! is_module_lite "fail2ban"
}

@test "mode: is_module_available returns true for lite modules in full mode" {
    INSTALL_MODE="full"
    is_module_available "ssh"
}

@test "mode: is_module_available returns true for full modules in full mode" {
    INSTALL_MODE="full"
    is_module_available "fail2ban"
}

@test "mode: is_module_available returns false for full modules in lite mode" {
    INSTALL_MODE="lite"
    ! is_module_available "fail2ban"
}

@test "mode: is_module_available returns true for lite modules in lite mode" {
    INSTALL_MODE="lite"
    is_module_available "ssh"
}

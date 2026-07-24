#!/usr/bin/env bats
# mode-selection.bats - 加固模式选择单元测试（Batch 4）

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    source "${SCRIPT_DIR}/scripts/base/mode.sh"

    # 默认取消模式设置
    unset INSTALL_MODE
}

teardown() {
    rm -rf "${TEST_DIR}"
    unset INSTALL_MODE
}

# ── MODE_BASIC_MODULES tests ──

@test "mode-selection: MODE_BASIC_MODULES is defined" {
    [[ ${#MODE_BASIC_MODULES[@]} -eq 4 ]]
    [[ " ${MODE_BASIC_MODULES[*]} " == *" init "* ]]
    [[ " ${MODE_BASIC_MODULES[*]} " == *" ssh "* ]]
    [[ " ${MODE_BASIC_MODULES[*]} " == *" firewall "* ]]
    [[ " ${MODE_BASIC_MODULES[*]} " == *" kernel "* ]]
}

@test "mode-selection: MODE_STANDARD_MODULES is defined" {
    [[ ${#MODE_STANDARD_MODULES[@]} -eq 6 ]]
    [[ " ${MODE_STANDARD_MODULES[*]} " == *" init "* ]]
    [[ " ${MODE_STANDARD_MODULES[*]} " == *" ssh "* ]]
    [[ " ${MODE_STANDARD_MODULES[*]} " == *" firewall "* ]]
    [[ " ${MODE_STANDARD_MODULES[*]} " == *" fail2ban "* ]]
    [[ " ${MODE_STANDARD_MODULES[*]} " == *" users "* ]]
    [[ " ${MODE_STANDARD_MODULES[*]} " == *" kernel "* ]]
}

@test "mode-selection: MODE_ADVANCED_MODULES is defined" {
    [[ ${#MODE_ADVANCED_MODULES[@]} -eq 9 ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" init "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" ssh "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" firewall "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" fail2ban "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" audit "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" users "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" services "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" filesystem "* ]]
    [[ " ${MODE_ADVANCED_MODULES[*]} " == *" kernel "* ]]
}

# ── get_mode_modules tests ──

@test "mode-selection: get_mode_modules returns basic modules" {
    run get_mode_modules "basic"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "init ssh firewall kernel" ]]
}

@test "mode-selection: get_mode_modules returns standard modules" {
    run get_mode_modules "standard"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "init ssh firewall fail2ban users kernel" ]]
}

@test "mode-selection: get_mode_modules returns advanced modules" {
    run get_mode_modules "advanced"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "init ssh firewall fail2ban users audit services filesystem kernel" ]]
}

@test "mode-selection: get_mode_modules returns empty for unknown mode" {
    run get_mode_modules "unknown"
    [[ "${output}" == "" ]]
}

# ── is_mode_compatible tests ──

@test "mode-selection: is_mode_compatible with full + basic returns 0" {
    INSTALL_MODE="full"
    run is_mode_compatible "basic"
    [[ "${status}" -eq 0 ]]
}

@test "mode-selection: is_mode_compatible with full + standard returns 0" {
    INSTALL_MODE="full"
    run is_mode_compatible "standard"
    [[ "${status}" -eq 0 ]]
}

@test "mode-selection: is_mode_compatible with full + advanced returns 0" {
    INSTALL_MODE="full"
    run is_mode_compatible "advanced"
    [[ "${status}" -eq 0 ]]
}

@test "mode-selection: is_mode_compatible with full + custom returns 0" {
    INSTALL_MODE="full"
    run is_mode_compatible "custom"
    [[ "${status}" -eq 0 ]]
}

@test "mode-selection: is_mode_compatible with lite + basic returns 0" {
    INSTALL_MODE="lite"
    run is_mode_compatible "basic"
    [[ "${status}" -eq 0 ]]
}

@test "mode-selection: is_mode_compatible with lite + custom returns 0" {
    INSTALL_MODE="lite"
    run is_mode_compatible "custom"
    [[ "${status}" -eq 0 ]]
}

@test "mode-selection: is_mode_compatible with lite + standard returns 1" {
    INSTALL_MODE="lite"
    run is_mode_compatible "standard"
    [[ "${status}" -eq 1 ]]
}

@test "mode-selection: is_mode_compatible with lite + advanced returns 1" {
    INSTALL_MODE="lite"
    run is_mode_compatible "advanced"
    [[ "${status}" -eq 1 ]]
}

#!/usr/bin/env bats
# menu.bats - 主菜单 / 子菜单壳 / i18n 键 测试

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LANG_CODE="zh"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
}

teardown() {
    # No resources to clean up -- all tests are read-only i18n key checks
    true
}

@test "zh.sh has all new module submenu keys (fail2ban)" {
    [[ -n "${MSG_FAIL2BAN_MENU_TITLE:-}" ]]
    [[ -n "${MSG_FAIL2BAN_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_FAIL2BAN_MENU_STATUS:-}" ]]
    [[ -n "${MSG_FAIL2BAN_MENU_BACK:-}" ]]
}

@test "zh.sh has all new module submenu keys (audit/users/kernel/fs/services)" {
    [[ -n "${MSG_AUDIT_MENU_TITLE:-}" ]]
    [[ -n "${MSG_AUDIT_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_AUDIT_MENU_STATUS:-}" ]]
    [[ -n "${MSG_AUDIT_MENU_BACK:-}" ]]
    [[ -n "${MSG_USERS_MENU_TITLE:-}" ]]
    [[ -n "${MSG_USERS_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_USERS_MENU_STATUS:-}" ]]
    [[ -n "${MSG_USERS_MENU_BACK:-}" ]]
    [[ -n "${MSG_KERNEL_MENU_TITLE:-}" ]]
    [[ -n "${MSG_KERNEL_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_KERNEL_MENU_STATUS:-}" ]]
    [[ -n "${MSG_KERNEL_MENU_BACK:-}" ]]
    [[ -n "${MSG_FILESYSTEM_MENU_TITLE:-}" ]]
    [[ -n "${MSG_FILESYSTEM_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_FILESYSTEM_MENU_STATUS:-}" ]]
    [[ -n "${MSG_FILESYSTEM_MENU_BACK:-}" ]]
    [[ -n "${MSG_SERVICES_MENU_TITLE:-}" ]]
    [[ -n "${MSG_SERVICES_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_SERVICES_MENU_STATUS:-}" ]]
    [[ -n "${MSG_SERVICES_MENU_BACK:-}" ]]
}

@test "zh.sh has status section header keys" {
    [[ -n "${MSG_SECTION_STATUS:-}" ]]
    [[ -n "${MSG_SECTION_HARDENING:-}" ]]
    [[ -n "${MSG_SECTION_QUICK:-}" ]]
    [[ -n "${MSG_STATUS_SSH_PORT_HARDENED:-}" ]]
    [[ -n "${MSG_STATUS_SSH_PORT_DEFAULT:-}" ]]
}

@test "zh.sh has status detection color/score keys" {
    [[ -n "${MSG_STATUS_HARDENED:-}" ]]
    [[ -n "${MSG_STATUS_PARTIAL:-}" ]]
    [[ -n "${MSG_STATUS_NOT_HARDENED:-}" ]]
    [[ -n "${MSG_STATUS_NOT_CONFIGURED:-}" ]]
    [[ -n "${MSG_STATUS_RECOMMENDATION:-}" ]]
}

@test "install.sh has no MSG_ variable with :- fallback (GAP-8)" {
    run bash -c "grep -cE '\$\{MSG_[A-Z_]+:-' '${SCRIPT_DIR}/install.sh'"
    [[ "$output" -eq 0 ]]
}

@test "zh.sh has view_report history keys" {
    [[ -n "${MSG_REPORT_HISTORY_TITLE:-}" ]]
    [[ -n "${MSG_REPORT_NO_FILES:-}" ]]
}

@test "zh.sh has parse_args error keys" {
    [[ -n "${MSG_ERROR_REMOVED_ARG:-}" ]]
    [[ -n "${MSG_ERROR_REMOVED_HINT:-}" ]]
}

@test "all 6 module submenu titles are distinct from their BACK labels" {
    [[ -n "${MSG_FAIL2BAN_MENU_TITLE}" ]]
    [[ "${MSG_FAIL2BAN_MENU_TITLE}" != "${MSG_FAIL2BAN_MENU_BACK}" ]]
    [[ -n "${MSG_AUDIT_MENU_TITLE}" ]]
    [[ "${MSG_AUDIT_MENU_TITLE}" != "${MSG_AUDIT_MENU_BACK}" ]]
    [[ -n "${MSG_USERS_MENU_TITLE}" ]]
    [[ "${MSG_USERS_MENU_TITLE}" != "${MSG_USERS_MENU_BACK}" ]]
    [[ -n "${MSG_KERNEL_MENU_TITLE}" ]]
    [[ "${MSG_KERNEL_MENU_TITLE}" != "${MSG_KERNEL_MENU_BACK}" ]]
    [[ -n "${MSG_FILESYSTEM_MENU_TITLE}" ]]
    [[ "${MSG_FILESYSTEM_MENU_TITLE}" != "${MSG_FILESYSTEM_MENU_BACK}" ]]
    [[ -n "${MSG_SERVICES_MENU_TITLE}" ]]
    [[ "${MSG_SERVICES_MENU_TITLE}" != "${MSG_SERVICES_MENU_BACK}" ]]
}

@test "module submenu items contain expected numbers [1][2][0]" {
    [[ "${MSG_FAIL2BAN_MENU_WIZARD}" =~ "1" ]]
    [[ "${MSG_FAIL2BAN_MENU_STATUS}" =~ "2" ]]
    [[ "${MSG_FAIL2BAN_MENU_BACK}" =~ "0" ]]
    [[ "${MSG_AUDIT_MENU_WIZARD}" =~ "1" ]]
    [[ "${MSG_USERS_MENU_WIZARD}" =~ "1" ]]
    [[ "${MSG_KERNEL_MENU_WIZARD}" =~ "1" ]]
    [[ "${MSG_FILESYSTEM_MENU_WIZARD}" =~ "1" ]]
    [[ "${MSG_SERVICES_MENU_WIZARD}" =~ "1" ]]
}

@test "main menu section labels are defined" {
    [[ -n "${MSG_SECTION_STATUS}" ]]
    [[ -n "${MSG_SECTION_HARDENING}" ]]
    [[ -n "${MSG_SECTION_QUICK}" ]]
}

@test "SSH port hardened/default labels are distinct" {
    [[ -n "${MSG_STATUS_SSH_PORT_HARDENED}" ]]
    [[ -n "${MSG_STATUS_SSH_PORT_DEFAULT}" ]]
    [[ "${MSG_STATUS_SSH_PORT_HARDENED}" != "${MSG_STATUS_SSH_PORT_DEFAULT}" ]]
}
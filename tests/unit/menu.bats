#!/usr/bin/env bats
# menu.bats - 主菜单 / 子菜单壳 / i18n 键 测试

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LANG_CODE="zh"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
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
    [[ -n "${MSG_STATUS_RECOMMENDATION:-}" ]]
}

@test "zh.sh has view_report history keys" {
    [[ -n "${MSG_REPORT_HISTORY_TITLE:-}" ]]
    [[ -n "${MSG_REPORT_NO_FILES:-}" ]]
}

@test "zh.sh has parse_args error keys" {
    [[ -n "${MSG_ERROR_REMOVED_ARG:-}" ]]
    [[ -n "${MSG_ERROR_REMOVED_HINT:-}" ]]
}
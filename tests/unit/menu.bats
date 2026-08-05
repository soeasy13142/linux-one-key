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

@test "zh.sh has Batch 5a menu + backup center keys" {
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    [[ -n "${MSG_MAIN_MENU_BACKUP_CENTER:-}" ]]
    [[ -n "${MSG_MAIN_MENU_DASHBOARD:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_TITLE:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_MENU_LIST:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_MENU_BACK:-}" ]]
    [[ -n "${MSG_ERROR_RESTORE_TARGET_REQUIRED:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_RESTORE_SYSCTL_SUCCESS:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_RESTORE_SYSCTL_FAILED:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_RESTORE_MODULE:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_MODULE_PROMPT:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_RESTORE_FAILED:-}" ]]
}

@test "zh.sh has dashboard keys" {
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    [[ -n "${MSG_DASHBOARD_TITLE:-}" ]]
    [[ -n "${MSG_DASHBOARD_RISK_LOW:-}" ]]
    [[ -n "${MSG_DASHBOARD_RISK_CRITICAL:-}" ]]
}

@test "install.sh menu defines [17]/[18] and gates with is_mode_full" {
    run grep -E 'MSG_MAIN_MENU_BACKUP_CENTER' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
    run grep -E 'MSG_MAIN_MENU_DASHBOARD' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
    run bash -c "grep -nE '17\) run_backup_center_menu|18\) run_dashboard_menu' '${SCRIPT_DIR}/install.sh'"
    [[ "$status" -eq 0 ]]
    run bash -c "sed -n '/17|18/,/esac/p' '${SCRIPT_DIR}/install.sh' | grep -q is_mode_lite"
    [[ "$status" -eq 0 ]]
}

@test "install.sh sources backup_center.sh and dashboard.sh in load_dependencies" {
    run grep -F 'scripts/base/backup_center.sh' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
    run grep -F 'scripts/base/dashboard.sh' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
}

@test "get_main_menu_choice accepts 17-19" {
    run grep -E '\[0-9\]\|1\[0-9\]' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
}

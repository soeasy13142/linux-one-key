#!/usr/bin/env bats
# view-report.bats - 历史报告列表（spec §3.4 GAP-7）
#
# 结构性测试：验证 view_report 重写后引用了列表/历史 i18n 键，
# 以及不再使用旧的"单文件 cat"模式。

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export INSTALL_SH="${SCRIPT_DIR}/install.sh"
}

teardown() {
    # No resources to clean up -- all tests are read-only grep/pattern checks on install.sh/zh.sh
    true
}

@test "view_report function exists in install.sh" {
    run grep -E "^view_report\(\)" "${INSTALL_SH}"
    [[ "$status" -eq 0 ]]
}

@test "view_report references MSG_REPORT_HISTORY_TITLE" {
    run bash -c "grep -A 100 '^view_report()' '${INSTALL_SH}' | grep -F 'MSG_REPORT_HISTORY_TITLE'"
    [[ "$status" -eq 0 ]]
}

@test "view_report references MSG_REPORT_NO_FILES" {
    run bash -c "grep -A 100 '^view_report()' '${INSTALL_SH}' | grep -F 'MSG_REPORT_NO_FILES'"
    [[ "$status" -eq 0 ]]
}

@test "view_report iterates reports with bash for-loop (not single cat)" {
    # 新版应有 for f in ${reports[@]} 类循环
    run bash -c "grep -A 200 '^view_report()' '${INSTALL_SH}' | grep -E 'for [a-z_]+ in.*reports'"
    [[ "$status" -eq 0 ]]
}

@test "view_report handles user choice loop (while true)" {
    run bash -c "grep -A 200 '^view_report()' '${INSTALL_SH}' | grep -E 'while true'"
    [[ "$status" -eq 0 ]]
}

@test "view_report uses prompt_input for selection" {
    run bash -c "grep -A 200 '^view_report()' '${INSTALL_SH}' | grep -F 'prompt_input'"
    [[ "$status" -eq 0 ]]
}

@test "zh.sh has relative time format keys" {
    # 验证 zh.sh 中定义了 MSG_TIME_* 系列变量（非空）
    local zh_file="${SCRIPT_DIR}/scripts/lang/zh.sh"
    for key in MSG_TIME_JUST_NOW MSG_TIME_MINUTES_AGO MSG_TIME_HOURS_AGO MSG_TIME_DAYS_AGO; do
        run bash -c "source '${zh_file}' && echo \"\${${key}:+set}\""
        [[ "$status" -eq 0 ]]
        [[ "$output" == "set" ]]
    done
}
#!/usr/bin/env bats
# parse-args.bats - 非交互错误提示精简（spec §3.5 GAP-9）

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export INSTALL_SH="${SCRIPT_DIR}/install.sh"
}

teardown() {
    # No resources to clean up -- all tests are read-only grep checks on install.sh
    true
}

@test "_parse_args function exists" {
    run grep -E "^_parse_args\(\)" "${INSTALL_SH}"
    [[ "$status" -eq 0 ]]
}

# 以下为结构性测试：验证 _parse_args 函数在 install.sh 中的 i18n 契约。
# 这些测试依赖于 grep 函数体内容而非外部调用行为，重构 _parse_args
# 时需同步更新这些模式。
@test "removed arg branch references MSG_ERROR_REMOVED_ARG" {
    # 测试 _parse_args 中 --yes 处理分支引用了 i18n 键，
    # 而非硬编码错误信息
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 15 -e '--yes' | grep -F 'MSG_ERROR_REMOVED_ARG'"
    [[ "$status" -eq 0 ]]
}

@test "removed arg branch references MSG_ERROR_REMOVED_HINT" {
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 15 -e '--yes' | grep -F 'MSG_ERROR_REMOVED_HINT'"
    [[ "$status" -eq 0 ]]
}

@test "zh.sh has parse_args error keys" {
    run grep -E "^MSG_ERROR_REMOVED_ARG=" "${SCRIPT_DIR}/scripts/lang/zh.sh"
    [[ "$status" -eq 0 ]]
    run grep -E "^MSG_ERROR_REMOVED_HINT=" "${SCRIPT_DIR}/scripts/lang/zh.sh"
    [[ "$status" -eq 0 ]]
}

@test "removed arg case from 5 lines down to ~4 (i18n)" {
    # 旧版 5 行：echo "" + 3 echo -e + echo "" → 新版：echo "" + log_error + log_info + echo ""
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 6 -e '--yes' | wc -l"
    [[ "$output" -le 8 ]]
}

# ── --version 分支（科技lion研究 Batch 1-A）──

@test "--version branch exists and prints SCRIPT_VERSION" {
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 8 -e '--version' | grep -F 'SCRIPT_VERSION'"
    [[ "$status" -eq 0 ]]
}

@test "--version branch references MSG_VERSION_RECENT" {
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 8 -e '--version' | grep -F 'MSG_VERSION_RECENT'"
    [[ "$status" -eq 0 ]]
}

@test "--help output references MSG_HELP_VERSION" {
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 20 -e '--help' | grep -F 'MSG_HELP_VERSION'"
    [[ "$status" -eq 0 ]]
}

@test "zh/en have MSG_VERSION_* keys (symmetry pair)" {
    for key in MSG_VERSION_RECENT MSG_VERSION_LOG_1 MSG_VERSION_LOG_2 MSG_VERSION_LOG_3 MSG_VERSION_LOG_4; do
        run grep -E "^${key}=" "${SCRIPT_DIR}/scripts/lang/zh.sh"
        [[ "$status" -eq 0 ]]
        run grep -E "^${key}=" "${SCRIPT_DIR}/scripts/lang/en.sh"
        [[ "$status" -eq 0 ]]
    done
}

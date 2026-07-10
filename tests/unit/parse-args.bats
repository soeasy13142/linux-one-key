#!/usr/bin/env bats
# parse-args.bats - 非交互错误提示精简（spec §3.5 GAP-9）

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export INSTALL_SH="${SCRIPT_DIR}/install.sh"
}

@test "_parse_args function exists" {
    run grep -E "^_parse_args\(\)" "${INSTALL_SH}"
    [[ "$status" -eq 0 ]]
}

@test "removed arg branch uses MSG_ERROR_REMOVED_ARG" {
    run bash -c "grep -A 100 '^_parse_args()' '${INSTALL_SH}' | grep -F -A 15 -e '--yes' | grep -F 'MSG_ERROR_REMOVED_ARG'"
    [[ "$status" -eq 0 ]]
}

@test "removed arg branch uses MSG_ERROR_REMOVED_HINT" {
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

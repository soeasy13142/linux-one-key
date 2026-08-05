#!/usr/bin/env bats
# mirror.bats - unit tests for scripts/server/mirror.sh
#
# 注意：不 source scripts/server/mirrors/lm_core.sh（8094 行 vendored 核心，太重）。
# run_mirror_flow 内部才在 subshell 里 source 它；测试用 mock core 代替真实核心。

# Test setup
setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    export LOG_FILE="${TEST_DIR}/test.log"
    touch "${LOG_FILE}"

    source "${SCRIPT_DIR}/scripts/server/mirror.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── Function existence tests ──

@test "mirror public functions are defined" {
    type run_mirror_flow
    type show_current_sources
    type show_mirror_submenu
    type run_mirror_submenu_loop
}

@test "mirror.sh loaded flag is set" {
    [[ "${_MIRROR_LOADED:-}" == "1" ]]
}

# ── i18n key tests (Chinese) ──

@test "mirror Chinese i18n keys are loaded" {
    [[ -n "${MSG_MAIN_MENU_MIRROR}" ]]
    [[ -n "${MSG_MAIN_MENU_MIRROR_DESC}" ]]
    [[ -n "${MSG_MIRROR_MENU_TITLE}" ]]
    [[ -n "${MSG_MIRROR_MENU_CHANGE_SOURCE}" ]]
    [[ -n "${MSG_MIRROR_MENU_RESTORE_OFFICIAL}" ]]
    [[ -n "${MSG_MIRROR_MENU_VIEW_SOURCE}" ]]
    [[ -n "${MSG_MIRROR_MENU_BACK}" ]]
    [[ -n "${MSG_MIRROR_MENU_PROMPT}" ]]
    [[ -n "${MSG_MIRROR_MENU_INVALID}" ]]
    [[ -n "${MSG_MIRROR_CONFIRM_CHANGE}" ]]
    [[ -n "${MSG_MIRROR_CONFIRM_RESTORE}" ]]
    [[ -n "${MSG_MIRROR_VIEW_TITLE}" ]]
    [[ -n "${MSG_MIRROR_UNSUPPORTED}" ]]
    [[ -n "${MSG_MIRROR_ERROR_CHANGE}" ]]
    [[ -n "${MSG_MIRROR_ERROR_RESTORE}" ]]
    [[ -n "${MSG_MIRROR_ERROR_VIEW}" ]]
}

# ── i18n key tests (English) ──

@test "mirror English i18n keys are loadable" {
    local _old_lang="${LANG_CODE}"
    LANG_CODE="en"
    load_lang "${SCRIPT_DIR}"

    [[ -n "${MSG_MAIN_MENU_MIRROR}" ]]
    [[ -n "${MSG_MAIN_MENU_MIRROR_DESC}" ]]
    [[ -n "${MSG_MIRROR_MENU_TITLE}" ]]
    [[ -n "${MSG_MIRROR_MENU_CHANGE_SOURCE}" ]]
    [[ -n "${MSG_MIRROR_MENU_RESTORE_OFFICIAL}" ]]
    [[ -n "${MSG_MIRROR_MENU_VIEW_SOURCE}" ]]
    [[ -n "${MSG_MIRROR_MENU_BACK}" ]]
    [[ -n "${MSG_MIRROR_MENU_PROMPT}" ]]
    [[ -n "${MSG_MIRROR_MENU_INVALID}" ]]
    [[ -n "${MSG_MIRROR_CONFIRM_CHANGE}" ]]
    [[ -n "${MSG_MIRROR_CONFIRM_RESTORE}" ]]
    [[ -n "${MSG_MIRROR_VIEW_TITLE}" ]]
    [[ -n "${MSG_MIRROR_UNSUPPORTED}" ]]
    [[ -n "${MSG_MIRROR_ERROR_CHANGE}" ]]
    [[ -n "${MSG_MIRROR_ERROR_RESTORE}" ]]
    [[ -n "${MSG_MIRROR_ERROR_VIEW}" ]]

    LANG_CODE="${_old_lang}"
    load_lang "${SCRIPT_DIR}"
}

# ── i18n completeness: every msg "KEY" in lm_core.sh must have a MSG_MIRROR_* translation (zh) ──

@test "every lm_core msg key has a non-empty MSG_MIRROR_* translation (zh)" {
    local key var value missing=0
    while IFS= read -r key; do
        # ${label_msg_index} 是变量插值，foo.bar-baz 是注释里的文档示例，均非真实键
        case "${key}" in
            '${label_msg_index}'|'foo.bar-baz') continue ;;
        esac
        var="MSG_MIRROR_${key//./_}"
        var="${var//-/_}"
        var="$(printf '%s' "${var}" | tr '[:lower:]' '[:upper:]')"
        value="$(eval "printf '%s' \"\${${var}:-}\"")"
        if [[ -z "${value}" ]]; then
            echo "missing or empty i18n key: ${var} (from msg \"${key}\")" >&2
            missing=1
        fi
    done < <(grep -oE 'msg "[^"]+"' "${SCRIPT_DIR}/scripts/server/mirrors/lm_core.sh" | sed -E 's/msg "([^"]+)"/\1/' | sort -u)
    [[ "${missing}" -eq 0 ]]
}

# ── Non-root rejection ──

@test "run_mirror_flow rejects non-root user" {
    DETECTED_IS_ROOT="no"

    run run_mirror_flow
    [[ "${status}" -ne 0 ]]
}

# ── Submenu display ──

@test "show_mirror_submenu output contains menu title and options" {
    run show_mirror_submenu
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"${MSG_MIRROR_MENU_TITLE}"* ]]
    [[ "${output}" == *"${MSG_MIRROR_MENU_CHANGE_SOURCE}"* ]]
    [[ "${output}" == *"${MSG_MIRROR_MENU_RESTORE_OFFICIAL}"* ]]
    [[ "${output}" == *"${MSG_MIRROR_MENU_VIEW_SOURCE}"* ]]
    [[ "${output}" == *"${MSG_MIRROR_MENU_BACK}"* ]]
}

# ── Subshell isolation with a mock core ──
# MIRROR_CORE_PATH 在 mirror.sh 里是 readonly，setup 已用真实路径 source，
# 无法在当前 shell 覆写；因此在独立 bash 进程里用临时 mock 目录重跑 source + 调用。

@test "run_mirror_flow sources mock core in subshell and isolates globals" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "${mock_dir}/scripts/server/mirrors"
    cat > "${mock_dir}/scripts/server/mirrors/lm_core.sh" <<'EOF'
MIRROR_LEAK="leaked"
lm_main() { echo "LM_OK"; }
EOF

    run env REAL_SCRIPT_DIR="${SCRIPT_DIR}" MOCK_DIR="${mock_dir}" bash -c '
        source "${REAL_SCRIPT_DIR}/scripts/base/utils.sh"
        load_lang "${REAL_SCRIPT_DIR}"
        is_root() { return 0; }
        SCRIPT_DIR="${MOCK_DIR}"
        source "${REAL_SCRIPT_DIR}/scripts/server/mirror.sh"
        run_mirror_flow --use-official-source
        flow_status=$?
        printf "LEAK_CHECK=%s\n" "${MIRROR_LEAK:-unset}"
        exit "${flow_status}"
    '
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"LM_OK"* ]]
    [[ "${output}" == *"LEAK_CHECK=unset"* ]]
    rm -rf "${mock_dir}"
}

@test "run_mirror_flow returns 1 when core file is missing" {
    local mock_dir
    mock_dir="$(mktemp -d)"
    mkdir -p "${mock_dir}/scripts/server/mirrors"

    run env REAL_SCRIPT_DIR="${SCRIPT_DIR}" MOCK_DIR="${mock_dir}" bash -c '
        source "${REAL_SCRIPT_DIR}/scripts/base/utils.sh"
        load_lang "${REAL_SCRIPT_DIR}"
        is_root() { return 0; }
        SCRIPT_DIR="${MOCK_DIR}"
        source "${REAL_SCRIPT_DIR}/scripts/server/mirror.sh"
        run_mirror_flow
    '
    [[ "${status}" -eq 1 ]]
    rm -rf "${mock_dir}"
}

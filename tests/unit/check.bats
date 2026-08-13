#!/usr/bin/env bats
# check.bats - 单元测试 for scripts/utils/check.sh（CIS/STIG 合规扫描器）

# 提取指定 (section,id) 的检查状态（PASS/FAIL）
_item_status() {
    local entry rest
    for entry in "${CHECK_RESULTS[@]}"; do
        if [[ "${entry}" == "$1"$'\t'"$2"$'\t'* ]]; then
            rest="${entry#*$'\t'}"
            rest="${rest#*$'\t'}"
            echo "${rest%%$'\t'*}"
            return 0
        fi
    done
    return 1
}

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"

    # mock 配置文件路径（环境变量覆盖）
    export CHECK_SSH_CONFIG="${TEST_DIR}/sshd_config"
    export CHECK_SUDOERS_DIR="${TEST_DIR}/sudoers.d"
    export CHECK_SUDOERS_DROPIN="${CHECK_SUDOERS_DIR}/99-linux-one-key-sudo"
    export CHECK_JOURNALD_DROPIN="${TEST_DIR}/journald.conf"
    export CHECK_SUDO_LOG="${TEST_DIR}/sudo.log"
    export CHECK_SYSCTL_CONF="${TEST_DIR}/99-hardening.conf"

    # 默认全部 PASS 的配置
    mkdir -p "${CHECK_SUDOERS_DIR}"
    cat > "${CHECK_SSH_CONFIG}" <<'EOF'
Port 2222
PermitRootLogin no
PasswordAuthentication no
EOF
    cat > "${CHECK_SUDOERS_DROPIN}" <<'EOF'
Defaults requiretty
EOF
    chmod 0440 "${CHECK_SUDOERS_DROPIN}"
    cat > "${CHECK_JOURNALD_DROPIN}" <<'EOF'
[Journal]
Storage=persistent
SystemMaxUse=500M
EOF
    touch "${CHECK_SUDO_LOG}"
    chmod 0640 "${CHECK_SUDO_LOG}"
    # 属主：可 chown root 则期望 root，否则期望当前用户（非 root 测试环境）
    export CHECK_SUDO_LOG_OWNER="root"
    if ! chown root:root "${CHECK_SUDO_LOG}" 2>/dev/null; then
        chown "$(id -un)" "${CHECK_SUDO_LOG}" 2>/dev/null || true
        export CHECK_SUDO_LOG_OWNER="$(id -un)"
    fi
    : > "${CHECK_SYSCTL_CONF}"

    if ! type check_parse_args &>/dev/null; then
        source "${SCRIPT_DIR}/scripts/utils/check.sh"
    fi
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ──────────────────────────────────────────────
# 参数解析
# ──────────────────────────────────────────────

@test "check_parse_args: --help exits 0" {
    run check_parse_args --help
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"用法"* ]]
    [[ "${output}" == *"--section"* ]]
}

@test "check_parse_args: unknown arg exits 2" {
    run check_parse_args --bogus
    [[ "${status}" -eq 2 ]]
}

@test "check_parse_args: --section without value exits 2" {
    run check_parse_args --section
    [[ "${status}" -eq 2 ]]
}

@test "check_parse_args: invalid section exits 2" {
    run check_parse_args --section bogus
    [[ "${status}" -eq 2 ]]
}

@test "check_parse_args parses --json and repeated --section" {
    check_parse_args --json --section ssh --section log
    [[ "${CHECK_JSON}" -eq 1 ]]
    [[ "${#CHECK_SECTIONS[@]}" -eq 2 ]]
    [[ "${CHECK_SECTIONS[0]}" == "ssh" ]]
    [[ "${CHECK_SECTIONS[1]}" == "log" ]]
}

@test "check_parse_args: --section=ssh equals form" {
    check_parse_args --section=ssh
    [[ "${#CHECK_SECTIONS[@]}" -eq 1 ]]
    [[ "${CHECK_SECTIONS[0]}" == "ssh" ]]
}

# ──────────────────────────────────────────────
# 各节检查（函数级）
# ──────────────────────────────────────────────

@test "check_section_ssh all PASS with compliant config" {
    check_section_ssh
    [[ "${#CHECK_RESULTS[@]}" -eq 3 ]]
    [[ "$(_item_status ssh port)" == "PASS" ]]
    [[ "$(_item_status ssh root)" == "PASS" ]]
    [[ "$(_item_status ssh passwd)" == "PASS" ]]
}

@test "check_section_ssh flags default port and root login" {
    cat > "${CHECK_SSH_CONFIG}" <<'EOF'
Port 22
PermitRootLogin yes
EOF
    check_section_ssh
    [[ "$(_item_status ssh port)" == "FAIL" ]]
    [[ "$(_item_status ssh root)" == "FAIL" ]]
    [[ "$(_item_status ssh passwd)" == "FAIL" ]]
}

@test "check_section_sudo all PASS with compliant config" {
    check_section_sudo
    [[ "${#CHECK_RESULTS[@]}" -eq 3 ]]
    [[ "$(_item_status sudo nopasswd)" == "PASS" ]]
    [[ "$(_item_status sudo perms)" == "PASS" ]]
    [[ "$(_item_status sudo dropin)" == "PASS" ]]
}

@test "check_section_sudo flags NOPASSWD file" {
    echo "user ALL=(ALL) NOPASSWD:ALL" > "${CHECK_SUDOERS_DIR}/nopasswd"
    chmod 0440 "${CHECK_SUDOERS_DIR}/nopasswd"
    check_section_sudo
    [[ "$(_item_status sudo nopasswd)" == "FAIL" ]]
    [[ "$(_item_status sudo perms)" == "PASS" ]]
}

@test "check_section_sudo flags over-permissive file" {
    chmod 0644 "${CHECK_SUDOERS_DROPIN}"
    check_section_sudo
    [[ "$(_item_status sudo perms)" == "FAIL" ]]
}

@test "check_section_sudo flags missing drop-in" {
    rm -f "${CHECK_SUDOERS_DROPIN}"
    check_section_sudo
    [[ "$(_item_status sudo dropin)" == "FAIL" ]]
}

@test "check_section_log all PASS with compliant config" {
    check_section_log
    [[ "${#CHECK_RESULTS[@]}" -eq 3 ]]
    [[ "$(_item_status log storage)" == "PASS" ]]
    [[ "$(_item_status log systemmaxuse)" == "PASS" ]]
    [[ "$(_item_status log sudo_perms)" == "PASS" ]]
}

@test "check_section_log flags missing Storage" {
    cat > "${CHECK_JOURNALD_DROPIN}" <<'EOF'
[Journal]
SystemMaxUse=500M
EOF
    check_section_log
    [[ "$(_item_status log storage)" == "FAIL" ]]
    [[ "$(_item_status log systemmaxuse)" == "PASS" ]]
}

@test "check_section_log flags missing SystemMaxUse" {
    cat > "${CHECK_JOURNALD_DROPIN}" <<'EOF'
[Journal]
Storage=persistent
EOF
    check_section_log
    [[ "$(_item_status log storage)" == "PASS" ]]
    [[ "$(_item_status log systemmaxuse)" == "FAIL" ]]
}

@test "check_section_log flags wrong sudo log perms" {
    chmod 0644 "${CHECK_SUDO_LOG}"
    check_section_log
    [[ "$(_item_status log sudo_perms)" == "FAIL" ]]
}

@test "check_section_kernel PASS when sysctl conf present" {
    check_section_kernel
    [[ "$(_item_status kernel conf)" == "PASS" ]]
}

@test "check_section_kernel flags missing sysctl conf" {
    rm -f "${CHECK_SYSCTL_CONF}"
    check_section_kernel
    [[ "$(_item_status kernel conf)" == "FAIL" ]]
}

# ──────────────────────────────────────────────
# 聚合
# ──────────────────────────────────────────────

@test "check_run_all scans all 10 items by default" {
    check_run_all
    [[ "${#CHECK_RESULTS[@]}" -eq 10 ]]
    run _check_has_fail
    [[ "${status}" -eq 1 ]]
}

@test "check_run_all respects --section" {
    check_parse_args --section ssh
    check_run_all
    [[ "${#CHECK_RESULTS[@]}" -eq 3 ]]
    local entry
    for entry in "${CHECK_RESULTS[@]}"; do
        [[ "${entry}" == "ssh"$'\t'* ]]
    done
}

# ──────────────────────────────────────────────
# 渲染
# ──────────────────────────────────────────────

@test "check_render_text prints PASS rows" {
    check_run_all
    run check_render_text
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"PASS"* ]]
    [[ "${output}" != *"FAIL"* ]]
}

@test "check_render_json emits array with section/id/status/detail" {
    check_run_all
    run check_render_json
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "["* ]]
    [[ "${output}" == *"]" ]]
    [[ "${output}" == *'"section":"ssh"'* ]]
    [[ "${output}" == *'"id":"port"'* ]]
    [[ "${output}" == *'"status":"PASS"'* ]]
    [[ "${output}" == *'"detail":"'* ]]
}

# ──────────────────────────────────────────────
# 独立 CLI（standalone）
# ──────────────────────────────────────────────

@test "check.sh standalone: all pass exits 0" {
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"PASS"* ]]
    [[ "${output}" != *"FAIL"* ]]
}

@test "check.sh standalone: FAIL exits 1" {
    cat > "${CHECK_SSH_CONFIG}" <<'EOF'
Port 22
EOF
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh"
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *"FAIL"* ]]
}

@test "check.sh standalone: --json emits pure JSON array" {
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh" --json
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "["* ]]
    [[ "${output}" == *"]" ]]
    [[ "${output}" == *'"section":"ssh"'* ]]
    [[ "${output}" == *'"section":"kernel"'* ]]
    [[ "${output}" == *'"status":"PASS"'* ]]
    [[ "${output}" != *'"status":"FAIL"'* ]]
    # stdout 必须纯净：无 log 行/无彩色符号
    [[ "${output}" != *"[INFO]"* ]]
    [[ "${output}" != *"[✓]"* ]]
}

@test "check.sh standalone: --json FAIL emits status FAIL" {
    rm -f "${CHECK_SYSCTL_CONF}"
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh" --json
    [[ "${status}" -eq 1 ]]
    [[ "${output}" == *'"status":"FAIL"'* ]]
}

@test "check.sh standalone: --section ssh scans only ssh (json)" {
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh" --section ssh --json
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *'"section":"ssh"'* ]]
    [[ "${output}" != *'"section":"sudo"'* ]]
    [[ "${output}" != *'"section":"log"'* ]]
    [[ "${output}" != *'"section":"kernel"'* ]]
}

@test "check.sh standalone: --help exits 0" {
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh" --help
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == *"用法"* ]]
}

@test "check.sh standalone: unknown arg exits 2" {
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh" --bogus
    [[ "${status}" -eq 2 ]]
}

@test "check.sh standalone: invalid section exits 2" {
    run bash "${SCRIPT_DIR}/scripts/utils/check.sh" --section bogus
    [[ "${status}" -eq 2 ]]
}

#!/usr/bin/env bats
# dashboard.bats - 单元测试 for scripts/base/dashboard.sh

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

    export DASH_SSH_CONFIG="${TEST_DIR}/sshd_config"
    export DASH_SYSCTL_CONF="${TEST_DIR}/99-hardening.conf"
    cat > "${DASH_SSH_CONFIG}" <<'EOF'
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KexAlgorithms curve25519-sha256
EOF
    if ! type dashboard_module_items &>/dev/null; then
        source "${SCRIPT_DIR}/scripts/base/dashboard.sh"
    fi
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "dashboard_module_items defines item ids per module" {
    run dashboard_module_items "ssh"
    [[ "${output}" == "port root passwd pubkey algorithms" ]]
    run dashboard_module_items "firewall"
    [[ "${output}" == "enabled ssh_port default_deny" ]]
    run dashboard_module_items "rootkit"
    [[ "${output}" == "rkhunter chkrootkit cron_configured" ]]
    run dashboard_module_items "unknown"
    [[ -z "${output}" ]]
}

@test "dashboard_risk_level boundaries" {
    run dashboard_risk_level 95
    [[ "${output}" == "low" ]]
    run dashboard_risk_level 89
    [[ "${output}" == "medium" ]]
    run dashboard_risk_level 75
    [[ "${output}" == "medium" ]]
    run dashboard_risk_level 74
    [[ "${output}" == "high" ]]
    run dashboard_risk_level 60
    [[ "${output}" == "high" ]]
    run dashboard_risk_level 59
    [[ "${output}" == "critical" ]]
}

@test "dashboard_check_item ssh checks read DASH_SSH_CONFIG" {
    dashboard_check_item "ssh" "port"
    dashboard_check_item "ssh" "root"
    dashboard_check_item "ssh" "passwd"
    dashboard_check_item "ssh" "pubkey"
    dashboard_check_item "ssh" "algorithms"

    # 反向：默认端口 → port 不通过
    cat > "${DASH_SSH_CONFIG}" <<'EOF'
Port 22
PermitRootLogin yes
EOF
    ! dashboard_check_item "ssh" "port"
    ! dashboard_check_item "ssh" "root"
}

@test "dashboard_total_score aggregates via stub eval" {
    dashboard_eval_module() { case "$1" in ssh) echo "4 5";; firewall) echo "0 3";; *) echo "0 0";; esac; }
    run dashboard_total_score
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "4 8" ]]
}

@test "dashboard_item_symbols renders per-item checkmarks" {
    dashboard_check_item() { return 0; }
    run dashboard_item_symbols "ssh"
    [[ "${output}" == "✅✅✅✅✅" ]]
}

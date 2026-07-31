#!/usr/bin/env bats
# backup-center.bats - 单元测试 for scripts/base/backup_center.sh
bats_require_minimum_version 1.5.0

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
    if ! type backup_center_module_of_path &>/dev/null; then
        source "${SCRIPT_DIR}/scripts/base/backup_center.sh"
    fi
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "backup_center_module_of_path groups by path prefix" {
    [[ "$(backup_center_module_of_path "/etc/ssh/sshd_config")" == "ssh" ]]
    [[ "$(backup_center_module_of_path "/etc/sysctl.d/99-hardening.conf")" == "kernel" ]]
    [[ "$(backup_center_module_of_path "/etc/ufw/user.rules")" == "firewall" ]]
    [[ "$(backup_center_module_of_path "/etc/fail2ban/jail.local")" == "fail2ban" ]]
    [[ "$(backup_center_module_of_path "/etc/unknown.conf")" == "other" ]]
}

@test "backup_center_list_modules dedups and lists groups" {
    local f1="${BACKUP_DIR}/sshd_config.bak.20260101000000.1.1"
    local f2="${BACKUP_DIR}/sshd_config.bak.20260102000000.2.2"
    local f3="${BACKUP_DIR}/99-hardening.conf.bak.20260101000000.3.3"
    echo "a" > "${f1}"; echo "/etc/ssh/sshd_config" > "${f1}.meta"
    echo "b" > "${f2}"; echo "/etc/ssh/sshd_config" > "${f2}.meta"
    echo "c" > "${f3}"; echo "/etc/sysctl.d/99-hardening.conf" > "${f3}.meta"

    run backup_center_list_modules
    [[ "${status}" -eq 0 ]]
    [[ "$(echo "${output}" | sort | tr '\n' ' ')" == "kernel ssh " ]]
}

@test "backup_center_list_modules empty without backups" {
    run backup_center_list_modules
    [[ "${status}" -eq 0 ]]
    [[ -z "${output}" ]]
}

@test "backup_center_latest_for_target returns newest backup" {
    local f1="${BACKUP_DIR}/sshd_config.bak.20260101000000.1.1"
    local f2="${BACKUP_DIR}/sshd_config.bak.20260102000000.2.2"
    echo "a" > "${f1}"; echo "/etc/ssh/sshd_config" > "${f1}.meta"
    echo "b" > "${f2}"; echo "/etc/ssh/sshd_config" > "${f2}.meta"

    run backup_center_latest_for_target "/etc/ssh/sshd_config"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${f2}" ]]
}

@test "backup_center_restore_module restores each target from latest backup" {
    local ssh1="${BACKUP_DIR}/sshd_config.bak.20260101000000.1.1"
    local ssh2="${BACKUP_DIR}/sshd_config.bak.20260102000000.2.2"
    local kern="${BACKUP_DIR}/99-hardening.conf.bak.20260101000000.3.3"
    mkdir -p "${TEST_DIR}/etc/ssh"
    echo "old" > "${ssh1}"; echo "${TEST_DIR}/etc/ssh/sshd_config" > "${ssh1}.meta"
    echo "newest" > "${ssh2}"; echo "${TEST_DIR}/etc/ssh/sshd_config" > "${ssh2}.meta"
    echo "sysctl" > "${kern}"; echo "/etc/sysctl.d/99-hardening.conf" > "${kern}.meta"
    echo "broken" > "${TEST_DIR}/etc/ssh/sshd_config"

    # 两个 ssh 备份的 meta 都指向 TEST_DIR 内路径，确保恢复只写临时目录、绝不触碰真实 /etc
    run backup_center_restore_module "ssh"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${TEST_DIR}/etc/ssh/sshd_config")" == "newest" ]]
}

@test "backup_center_restore_module returns 1 when no restorable backups" {
    run backup_center_restore_module "swap"
    [[ "${status}" -ne 0 ]]
}

@test "backup_center_restore_module rejects relative meta restore target" {
    # 相对路径 meta（非绝对路径）：模块恢复必须被拒绝，绝不写入进程 CWD
    local rel_base="${TEST_DIR}/cwd"
    mkdir -p "${rel_base}/sub/etc/ssh"
    local bak="${BACKUP_DIR}/sshd_config.bak.20260103000000.9.9"
    echo "content" > "${bak}"
    echo "sub/etc/ssh/sshd_config" > "${bak}.meta"

    cd "${rel_base}"
    run backup_center_restore_module "ssh"

    [[ "${status}" -ne 0 ]]
    [[ ! -f "${rel_base}/sub/etc/ssh/sshd_config" ]]
}

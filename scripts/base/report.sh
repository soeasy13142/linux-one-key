#!/usr/bin/env bash
# report.sh - 安全加固报告生成模块
# 动态生成报告，根据实际执行的模块输出对应内容

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# Source guard: prevent double-source crash under set -eo pipefail
[ -n "${_REPORT_LOADED:-}" ] && return 0
readonly _REPORT_LOADED=1

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before report.sh"
    exit 1
fi

if [[ "${_DETECT_LOADED:-}" != "1" ]]; then
    echo "Error: detect.sh must be loaded before report.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 报告生成
# ═══════════════════════════════════════════

# Helper: format a task line with done/skipped/failed status
_report_task_line() {
    local done_flag="${1:-0}"
    local task_name="${2}"
    if [[ "${done_flag}" == "1" ]]; then
        echo "[✓] ${task_name}"
    else
        echo "[⊘] ${task_name} — ${MSG_WIZARD_SKIPPED}"
    fi
}

# 生成安全加固报告，包含系统信息、任务完成状态、配置备份、安全建议
generate_report() {
    local report_path
    report_path=$(get_report_path)

    log_step "Generating report..."

    # Build report
    {
        echo "═══════════════════════════════════════════════════════════════"
        echo "                ${MSG_REPORT_TITLE}"
        echo "═══════════════════════════════════════════════════════════════"
        echo ""
        echo "${MSG_REPORT_SYSTEM}:"
        echo "  - ${MSG_DETECT_OS}: $(get_detected_os) $(get_detected_os_version)"
        echo "  - ${MSG_DETECT_ARCH}: $(get_detected_arch)"
        echo "  - ${MSG_DETECT_USER}: $(whoami)"
        echo "  - Hostname: $(get_hostname)"

        # NTP status
        if command -v timedatectl &>/dev/null; then
            local ntp_sync_status
            ntp_sync_status=$(timedatectl show 2>/dev/null | grep "NTPSynchronized=" | cut -d= -f2 || echo "")
            if [[ -n "${ntp_sync_status}" ]]; then
                if [[ "${ntp_sync_status}" == "yes" ]]; then
                    echo "  - ${MSG_NTP_STATUS}: ${MSG_NTP_STATUS_SYNCED}"
                else
                    echo "  - ${MSG_NTP_STATUS}: ${MSG_NTP_STATUS_UNSYNCED}"
                fi
            fi
        elif command -v chronyc &>/dev/null; then
            local ntp_ok
            ntp_ok=$(LC_ALL=C chronyc tracking 2>/dev/null | grep -c "Leap.*Normal" || echo "0")
            if [[ "${ntp_ok}" -gt 0 ]]; then
                echo "  - ${MSG_NTP_STATUS}: ${MSG_NTP_STATUS_SYNCED}"
            else
                echo "  - ${MSG_NTP_STATUS}: ${MSG_NTP_STATUS_UNSYNCED}"
            fi
        fi

        # Swap status
        local swap_size
        swap_size=$(free -m 2>/dev/null | awk '/Swap:/{print $2}' || echo "")
        if [[ -n "${swap_size}" ]] && [[ "${swap_size}" -gt 0 ]]; then
            echo "  - ${MSG_SWAP_TITLE}: ${swap_size} MB"
        else
            echo "  - ${MSG_SWAP_TITLE}: ${MSG_SWAP_NO_SWAP}"
        fi

        echo ""

        # ── Tasks section — dynamic per module ──
        echo "${MSG_REPORT_TASKS}:"

        # SSH
        _report_task_line "${_WIZARD_SSH_DONE:-0}" "${MSG_TASK_SSH}"
        if [[ "${_WIZARD_SSH_DONE:-0}" == "1" ]]; then
            echo "    - Port: $(get_ssh_port)"
            local root_login
            root_login=$(get_ssh_config "PermitRootLogin" 2>/dev/null || echo "unknown")
            echo "    - Root login: ${root_login}"
            local pass_auth
            pass_auth=$(get_ssh_config "PasswordAuthentication" 2>/dev/null || echo "unknown")
            echo "    - Password auth: ${pass_auth}"
            local pubkey_auth
            pubkey_auth=$(get_ssh_config "PubkeyAuthentication" 2>/dev/null || echo "unknown")
            echo "    - Key authentication: ${pubkey_auth}"
        fi

        # Firewall
        _report_task_line "${_WIZARD_FIREWALL_DONE:-0}" "${MSG_TASK_FIREWALL}"
        if [[ "${_WIZARD_FIREWALL_DONE:-0}" == "1" ]]; then
            local fw_status="${MSG_STATUS_DISABLED}"
            if command -v ufw &>/dev/null; then
                if ufw status 2>/dev/null | grep -q "Status: active"; then
                    fw_status="${MSG_STATUS_ENABLED}"
                fi
            elif command -v firewall-cmd &>/dev/null; then
                if firewall-cmd --state &>/dev/null; then
                    fw_status="${MSG_STATUS_ENABLED}"
                fi
            fi
            echo "    - ${MSG_STATUS_FIREWALL}: ${fw_status}"
        fi

        # Fail2Ban
        _report_task_line "${_WIZARD_FAIL2BAN_DONE:-0}" "${MSG_TASK_FAIL2BAN}"
        if [[ "${_WIZARD_FAIL2BAN_DONE:-0}" == "1" ]]; then
            local f2b_status="${MSG_STATUS_NOT_INSTALLED}"
            if command -v fail2ban-client &>/dev/null; then
                if systemctl is-active fail2ban &>/dev/null; then
                    f2b_status="${MSG_STATUS_ENABLED}"
                else
                    f2b_status="${MSG_STATUS_DISABLED}"
                fi
            fi
            echo "    - ${MSG_STATUS_FAIL2BAN}: ${f2b_status}"
        fi

        # Audit
        _report_task_line "${_WIZARD_AUDIT_DONE:-0}" "${MSG_TASK_AUDIT}"
        if [[ "${_WIZARD_AUDIT_DONE:-0}" == "1" ]]; then
            local audit_status="${MSG_STATUS_NOT_INSTALLED}"
            if command -v auditctl &>/dev/null; then
                if systemctl is-active auditd &>/dev/null; then
                    audit_status="${MSG_STATUS_ENABLED}"
                else
                    audit_status="${MSG_STATUS_DISABLED}"
                fi
            fi
            echo "    - ${MSG_STATUS_AUDIT}: ${audit_status}"
            if command -v auditctl &>/dev/null; then
                local rule_count
                rule_count=$(auditctl -l 2>/dev/null | wc -l | tr -d ' ')
                echo "    - ${MSG_AUDIT_RULES_COUNT}: ${rule_count}"
            fi
        fi

        # Users
        _report_task_line "${_WIZARD_USERS_DONE:-0}" "${MSG_TASK_USER_MGMT}"
        if [[ "${_WIZARD_USERS_DONE:-0}" == "1" ]]; then
            local custom_users
            custom_users=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd 2>/dev/null | wc -l | tr -d ' ')
            echo "    - ${MSG_STATUS_USERS_COUNT}: ${custom_users}"
        fi

        # Kernel
        _report_task_line "${_WIZARD_KERNEL_DONE:-0}" "${MSG_TASK_KERNEL}"
        if [[ "${_WIZARD_KERNEL_DONE:-0}" == "1" ]]; then
            local kernel_conf_status="${MSG_STATUS_DISABLED}"
            if [[ -f "/etc/sysctl.d/99-hardening.conf" ]]; then
                kernel_conf_status="${MSG_STATUS_ENABLED}"
            fi
            echo "    - ${MSG_STATUS_KERNEL_CONF}: ${kernel_conf_status}"
            if [[ -f "/etc/sysctl.d/99-hardening.conf" ]]; then
                local kernel_param_count
                kernel_param_count=$(grep -cE "^[^#]" "/etc/sysctl.d/99-hardening.conf" 2>/dev/null || echo "0")
                echo "    - ${MSG_KERNEL_SUMMARY_PARAMS}: ${kernel_param_count}"
            fi
        fi

        # Filesystem
        _report_task_line "${_WIZARD_FS_DONE:-0}" "${MSG_TASK_FILESYSTEM}"
        if [[ "${_WIZARD_FS_DONE:-0}" == "1" ]]; then
            local fs_suid_count
            fs_suid_count=$(find / -xdev -not -path '/proc/*' -not -path '/sys/*' -perm -4000 -type f 2>/dev/null | wc -l | tr -d ' ')
            echo "    - ${MSG_STATUS_FS_SUID}: ${fs_suid_count}"
        fi

        # Services
        _report_task_line "${_WIZARD_SERVICES_DONE:-0}" "${MSG_TASK_SERVICES}"
        if [[ "${_WIZARD_SERVICES_DONE:-0}" == "1" ]]; then
            if type check_services_status &>/dev/null; then
                local svc_status
                svc_status=$(check_services_status 2>/dev/null)
                local svc_running
                svc_running=$(echo "${svc_status}" | grep '^services_running=' | cut -d= -f2)
                local svc_unnecessary
                svc_unnecessary=$(echo "${svc_status}" | grep '^services_unnecessary=' | cut -d= -f2)
                echo "    - ${MSG_STATUS_SERVICES_RUNNING}: ${svc_running}"
                echo "    - ${MSG_STATUS_SERVICES_UNNECESSARY}: ${svc_unnecessary}"
            fi
        fi

        # Auto Security Updates
        _report_task_line "${_WIZARD_AUTOUPDATE_DONE:-0}" "${MSG_TASK_AUTOUPDATE}"
        if [[ "${_WIZARD_AUTOUPDATE_DONE:-0}" == "1" ]]; then
            if type check_autoupdate_status &>/dev/null; then
                local au_status
                au_status=$(check_autoupdate_status 2>/dev/null)
                local au_type
                au_type=$(echo "${au_status}" | grep '^autoupdate_type=' | cut -d= -f2)
                echo "    - ${MSG_AUTOUPDATE_TYPE}: ${au_type:-unknown}"
            fi
        fi

        # AIDE
        _report_task_line "${_WIZARD_AIDE_DONE:-0}" "${MSG_TASK_AIDE}"
        if [[ "${_WIZARD_AIDE_DONE:-0}" == "1" ]]; then
            if type check_aide_status &>/dev/null; then
                local aide_status
                aide_status=$(check_aide_status 2>/dev/null)
                echo "    - DB initialized: $(echo "${aide_status}" | grep '^aide_db_exists=' | cut -d= -f2)"
                echo "    - Cron: $(echo "${aide_status}" | grep '^aide_cron=' | cut -d= -f2)"
            fi
        fi

        # ClamAV
        _report_task_line "${_WIZARD_CLAMAV_DONE:-0}" "${MSG_TASK_CLAMAV}"
        if [[ "${_WIZARD_CLAMAV_DONE:-0}" == "1" ]]; then
            if type check_clamav_status &>/dev/null; then
                local clamav_status
                clamav_status=$(check_clamav_status 2>/dev/null)
                echo "    - DB up-to-date: $(echo "${clamav_status}" | grep '^clamav_db_uptodate=' | cut -d= -f2)"
                echo "    - Cron: $(echo "${clamav_status}" | grep '^clamav_cron_enabled=' | cut -d= -f2)"
                echo "    - ${MSG_STATUS_CLAMD}: $(echo "${clamav_status}" | grep '^clamav_clamd_enabled=' | cut -d= -f2)"
            fi
        fi

        # Rootkit Detection
        _report_task_line "${_WIZARD_ROOTKIT_DONE:-0}" "${MSG_TASK_ROOTKIT}"
        if [[ "${_WIZARD_ROOTKIT_DONE:-0}" == "1" ]]; then
            if type check_rootkit_status &>/dev/null; then
                local rootkit_status
                rootkit_status=$(check_rootkit_status 2>/dev/null)
                echo "    - rkhunter: $(echo "${rootkit_status}" | grep '^rkhunter_installed=' | cut -d= -f2)"
                echo "    - chkrootkit: $(echo "${rootkit_status}" | grep '^chkrootkit_installed=' | cut -d= -f2)"
                echo "    - Cron: $(echo "${rootkit_status}" | grep '^cron_enabled=' | cut -d= -f2)"
            fi
        fi

        echo ""

        # ── Config files modified ──
        echo "${MSG_REPORT_CONFIGS}:"
        if [[ "${_WIZARD_SSH_DONE:-0}" == "1" ]]; then
            local latest_ssh_backup
            latest_ssh_backup=$(find "${BACKUP_DIR}" -name "sshd_config.bak.*" -type f 2>/dev/null | sort -r | head -1)
            echo "  - ${SSH_CONFIG}"
            if [[ -n "${latest_ssh_backup}" ]]; then
                echo "    Backup: ${latest_ssh_backup}"
            fi
        fi
        if [[ "${_WIZARD_FAIL2BAN_DONE:-0}" == "1" ]]; then
            if [[ -n "${FAIL2BAN_JAIL_LOCAL:-}" ]]; then
                echo "  - ${FAIL2BAN_JAIL_LOCAL}"
            fi
        fi
        if [[ "${_WIZARD_AUDIT_DONE:-0}" == "1" ]]; then
            echo "  - ${AUDIT_RULES_FILE:-/etc/audit/rules.d/audit.rules}"
            echo "  - ${AUDITD_CONF:-/etc/audit/auditd.conf}"
        fi
        if [[ "${_WIZARD_KERNEL_DONE:-0}" == "1" ]]; then
            echo "  - /etc/sysctl.d/99-hardening.conf"
        fi
        echo ""

        # ── Warnings — only for executed modules ──
        echo "${MSG_REPORT_WARNINGS}:"
        if [[ "${_WIZARD_SSH_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_WARN_CONNECTION}"
            echo "  ⚠ ${MSG_WARN_SAVE_KEY}"
            echo "  ⚠ ${MSG_WARN_TEST_FIRST}"
            local final_port
            final_port=$(get_ssh_port)
            if [[ "${final_port}" != "22" ]]; then
                echo "  ⚠ ${MSG_REPORT_WARN_SSH_PORT22}"
            fi
        fi
        if [[ "${_WIZARD_FIREWALL_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_FIREWALL}"
        fi
        if [[ "${_WIZARD_FAIL2BAN_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_FAIL2BAN}"
        fi
        if [[ "${_WIZARD_AUDIT_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_AUDIT}"
        fi
        if [[ "${_WIZARD_KERNEL_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_KERNEL}"
        fi
        if [[ "${_WIZARD_USERS_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_USERS}"
        fi
        if [[ "${_WIZARD_FS_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_FS}"
        fi
        if [[ "${_WIZARD_SERVICES_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_SERVICES}"
        fi
        if [[ "${_WIZARD_AIDE_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_AIDE}"
        fi
        if [[ "${_WIZARD_CLAMAV_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_CLAMAV}"
        fi
        if [[ "${_WIZARD_ROOTKIT_DONE:-0}" == "1" ]]; then
            echo "  ⚠ ${MSG_REPORT_WARN_ROOTKIT}"
        fi

        echo ""
        echo "${MSG_REPORT_SAVED}: ${report_path}"
        echo ""
        echo "═══════════════════════════════════════════════════════════════"
    } > "${report_path}"

    log_success "${MSG_REPORT_SAVED}: ${report_path}"
}

log_debug "report.sh loaded successfully"

#!/usr/bin/env bash
# dashboard.sh - 安全仪表盘：多模块评分 + 终端渲染（只读，可测试）
# 依赖: utils.sh (log_*, get_ssh_config), lang (MSG_DASHBOARD_*)
set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

[ -n "${_DASHBOARD_LOADED:-}" ] && return 0
readonly _DASHBOARD_LOADED=1

# 测试可覆盖的路径（默认生产路径）
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${DASH_SSH_CONFIG:=/etc/ssh/sshd_config}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${DASH_SYSCTL_CONF:=/etc/sysctl.d/99-hardening.conf}"

# 安全模块（不含 k3s/swap）
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
DASHBOARD_MODULES=("ssh" "firewall" "fail2ban" "audit" "users" "kernel" "filesystem" "services" "autoupdate" "aide" "clamav" "rootkit")

# 各模块检查项 id 列表
dashboard_module_items() {
    local module="$1"
    case "${module}" in
        ssh) echo "port root passwd pubkey algorithms" ;;
        firewall) echo "enabled ssh_port default_deny" ;;
        fail2ban) echo "installed active jail" ;;
        audit) echo "installed active rules" ;;
        users) echo "custom_user sudo" ;;
        kernel) echo "conf_present params_count" ;;
        filesystem) echo "suid_scanned sticky_bit" ;;
        services) echo "audited ports_recorded" ;;
        autoupdate) echo "enabled timer_active" ;;
        aide) echo "db_initialized cron_configured" ;;
        clamav) echo "db_updated cron_configured" ;;
        rootkit) echo "rkhunter chkrootkit cron_configured" ;;
        *) echo "" ;;
    esac
}

# 单项判定（只读；返回 0=通过 1=不通过）
dashboard_check_item() {
    local module="$1" item="$2"
    case "${module}_${item}" in
        ssh_port)
            [[ "$(get_ssh_config "Port" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "22")" != "22" ]] ;;
        ssh_root)
            [[ "$(get_ssh_config "PermitRootLogin" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "unknown")" == "no" ]] ;;
        ssh_passwd)
            [[ "$(get_ssh_config "PasswordAuthentication" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "unknown")" == "no" ]] ;;
        ssh_pubkey)
            local v
            v="$(get_ssh_config "PubkeyAuthentication" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "yes")"
            [[ "${v}" == "yes" || -z "${v}" ]] ;;
        ssh_algorithms)
            grep -qE '^(KexAlgorithms|Ciphers|MACs)' "${DASH_SSH_CONFIG}" 2>/dev/null ;;
        firewall_enabled)
            if command -v ufw &>/dev/null; then
                ufw status 2>/dev/null | grep -q "Status: active"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --state &>/dev/null
            else
                return 1
            fi ;;
        firewall_ssh_port)
            local port
            port="$(get_ssh_config "Port" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "22")"
            if command -v ufw &>/dev/null; then
                ufw status 2>/dev/null | grep -qE "${port}/tcp"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --list-ports 2>/dev/null | grep -qE "^${port}/tcp"
            else
                return 1
            fi ;;
        firewall_default_deny)
            if command -v ufw &>/dev/null; then
                ufw status verbose 2>/dev/null | grep -qE "^Default: deny"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --get-default-zone 2>/dev/null | grep -qi "drop"
            else
                return 1
            fi ;;
        fail2ban_installed)
            command -v fail2ban-client &>/dev/null ;;
        fail2ban_active)
            systemctl is-active fail2ban 2>/dev/null | grep -q active ;;
        fail2ban_jail)
            [[ -f /etc/fail2ban/jail.local ]] ;;
        audit_installed)
            command -v auditctl &>/dev/null ;;
        audit_active)
            systemctl is-active auditd 2>/dev/null | grep -q active ;;
        audit_rules)
            auditctl -l 2>/dev/null | grep -q . ;;
        users_custom_user)
            if type check_users_status &>/dev/null; then
                check_users_status 2>/dev/null | grep -qE '^users_custom=[1-9][0-9]*$'
            else
                return 1
            fi ;;
        users_sudo)
            grep -qiE '^%?(sudo|wheel)[[:space:]]' /etc/sudoers 2>/dev/null ;;
        kernel_conf_present)
            [[ -f "${DASH_SYSCTL_CONF}" ]] ;;
        kernel_params_count)
            [[ -f "${DASH_SYSCTL_CONF}" ]] && [[ "$(grep -cE '^[a-z].*=' "${DASH_SYSCTL_CONF}" 2>/dev/null)" -ge 5 ]] ;;
        filesystem_suid_scanned)
            ls /var/log/linux-one-key/report_*.txt &>/dev/null ;;
        filesystem_sticky_bit)
            local perms
            perms="$(stat -c '%a' /tmp 2>/dev/null || stat -f '%Lp' /tmp 2>/dev/null || echo "")"
            [[ -n "${perms}" ]] && [[ "${perms: -1}" =~ [1357] ]] ;;
        services_audited)
            ls /var/log/linux-one-key/report_*.txt &>/dev/null ;;
        services_ports_recorded)
            grep -l "LISTEN\|开放端口\|Open ports" /var/log/linux-one-key/report_*.txt &>/dev/null ;;
        autoupdate_enabled)
            [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]] || command -v yum-cron &>/dev/null || command -v dnf-automatic &>/dev/null ;;
        autoupdate_timer_active)
            systemctl is-active unattended-upgrades 2>/dev/null | grep -q active || \
                systemctl is-active yum-cron 2>/dev/null | grep -q active || \
                systemctl is-active dnf-automatic 2>/dev/null | grep -q active ;;
        aide_db_initialized)
            [[ -f /var/lib/aide/aide.db.gz ]] ;;
        aide_cron_configured)
            crontab -l 2>/dev/null | grep -q aide || ls /etc/cron.d/aide* &>/dev/null ;;
        clamav_db_updated)
            # shellcheck disable=SC2010 # ls|grep glob match — behavior-preserving, avoids find/glob divergence
            command -v clamscan &>/dev/null && [[ -n "$(ls /var/lib/clamav 2>/dev/null | grep -E '\.cvd$|\.cld$' | head -1)" ]] ;;
        clamav_cron_configured)
            crontab -l 2>/dev/null | grep -qiE 'clamscan|freshclam' || ls /etc/cron.d/*clam* &>/dev/null ;;
        rootkit_rkhunter)
            command -v rkhunter &>/dev/null ;;
        rootkit_chkrootkit)
            command -v chkrootkit &>/dev/null ;;
        rootkit_cron_configured)
            crontab -l 2>/dev/null | grep -qiE 'rkhunter|chkrootkit' ;;
        *)
            return 1 ;;
    esac
}

# 模块得分：输出 "pass total"
dashboard_eval_module() {
    local module="$1"
    local items item pass=0 total=0
    items="$(dashboard_module_items "${module}")"
    for item in ${items}; do
        total=$((total + 1))
        if dashboard_check_item "${module}" "${item}"; then
            pass=$((pass + 1))
        fi
    done
    echo "${pass} ${total}"
}

# 总分：输出 "pass total"
dashboard_total_score() {
    local module result p t pass=0 total=0
    for module in "${DASHBOARD_MODULES[@]}"; do
        result="$(dashboard_eval_module "${module}")"
        p="${result%% *}"
        t="${result##* }"
        pass=$((pass + p))
        total=$((total + t))
    done
    echo "${pass} ${total}"
}

# 风险等级（整数百分比）
dashboard_risk_level() {
    local pct="$1"
    if [[ "${pct}" -ge 90 ]]; then
        echo "low"
    elif [[ "${pct}" -ge 75 ]]; then
        echo "medium"
    elif [[ "${pct}" -ge 60 ]]; then
        echo "high"
    else
        echo "critical"
    fi
}

# 逐项符号串（如 ✅❌✅✅✅）
dashboard_item_symbols() {
    local module="$1"
    local items item out=""
    items="$(dashboard_module_items "${module}")"
    for item in ${items}; do
        if dashboard_check_item "${module}" "${item}"; then
            out+="✅"
        else
            out+="❌"
        fi
    done
    [[ -n "${out}" ]] && echo "${out}"
}

# 渲染：每模块一行 + 总分/风险等级
dashboard_render() {
    local module result pass total pct level label color symbols
    local total_pass=0 total_all=0
    log_title "${MSG_DASHBOARD_TITLE}"
    for module in "${DASHBOARD_MODULES[@]}"; do
        result="$(dashboard_eval_module "${module}")"
        pass="${result%% *}"
        total="${result##* }"
        total_pass=$((total_pass + pass))
        total_all=$((total_all + total))
        symbols="$(dashboard_item_symbols "${module}")"
        if [[ "${total}" -eq 0 ]]; then
            label="N/A"; color="${YELLOW}"
        elif [[ "${pass}" -eq "${total}" ]]; then
            label="✅ ${pass}/${total}"; color="${GREEN}"
        elif [[ "${pass}" -eq 0 ]]; then
            label="❌ 0/${total}"; color="${RED}"
        else
            label="⚠️ ${pass}/${total}"; color="${YELLOW}"
        fi
        # shellcheck disable=SC2059 # color escape codes in format string
        printf "${color}  %-12s %-10s %s${NC}\n" "${module}" "${label}" "${symbols}"
    done
    if [[ "${total_all}" -gt 0 ]]; then
        pct=$(( total_pass * 100 / total_all ))
        level="$(dashboard_risk_level "${pct}")"
        # i18n: 把内部 low/medium/high/critical 映射到 MSG_DASHBOARD_RISK_* 翻译
        case "${level}" in
            low)      level="${MSG_DASHBOARD_RISK_LOW}" ;;
            medium)   level="${MSG_DASHBOARD_RISK_MEDIUM}" ;;
            high)     level="${MSG_DASHBOARD_RISK_HIGH}" ;;
            critical) level="${MSG_DASHBOARD_RISK_CRITICAL}" ;;
        esac
        log_info "${MSG_DASHBOARD_TOTAL}: ${total_pass}/${total_all} (${pct}%)"
        log_info "${MSG_DASHBOARD_RISK}: ${level}"
    fi
}

log_debug "dashboard.sh loaded successfully"

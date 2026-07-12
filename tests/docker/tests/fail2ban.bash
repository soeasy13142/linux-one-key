#!/usr/bin/env bash
# Test: fail2ban - Fail2Ban configuration validation
# Runs all steps in a single container to preserve filesystem state.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing fail2ban configuration on ${distro}:${version}..."

    # Determine expected banaction based on distro
    local expected_banaction
    case "$distro" in
        ubuntu|debian)  expected_banaction="ufw" ;;
        centos|rhel|rocky|almalinux|fedora) expected_banaction="firewallcmd-ipset" ;;
        *) expected_banaction="iptables-multiport" ;;
    esac

    # Single container: install, configure, then verify with sentinel markers
    local result
    result=$(run_in_container "$distro" "$version" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\"\${LOG_DIR}/backups\" && \
         mkdir -p \"\${BACKUP_DIR}\" && \
         export DETECTED_OS=\"${distro}\" && \
         export NONINTERACTIVE=1 && \
         source /opt/linux-one-key/scripts/base/utils.sh && \
         load_lang /opt/linux-one-key && \
         source /opt/linux-one-key/scripts/security/fail2ban.sh && \
         (apt-get update -qq 2>/dev/null || true) && \
         (_install_fail2ban 2>/dev/null || true) && \
         mkdir -p /etc/fail2ban && \
         _configure_fail2ban_jail 22 /var/log/auth.log 3600 600 5 2>/dev/null && \
         echo 'CONFIG_DONE' && \
         if grep -q '\[sshd\]' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_JAIL=OK'; else echo 'CHECK_JAIL=FAIL'; fi && \
         if grep -q '^bantime = 3600' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_BANTIME=OK'; else echo 'CHECK_BANTIME=FAIL'; fi && \
         if grep -q '^maxretry = 5' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_MAXRETRY=OK'; else echo 'CHECK_MAXRETRY=FAIL'; fi && \
         if grep -q '^findtime = 600' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_FINDTIME=OK'; else echo 'CHECK_FINDTIME=FAIL'; fi && \
         if grep -q 'port = 22' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_PORT=OK'; else echo 'CHECK_PORT=FAIL'; fi && \
         if grep -q 'banaction = ${expected_banaction}' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_BANACTION=OK'; else echo 'CHECK_BANACTION=FAIL'; fi && \
         if grep -q 'enabled = true' /etc/fail2ban/jail.local 2>/dev/null; then echo 'CHECK_ENABLED=OK'; else echo 'CHECK_ENABLED=FAIL'; fi")

    # Parse sentinel markers
    # Config done
    if echo "$result" | grep -q "CONFIG_DONE"; then
        assert_pass "fail2ban: configured successfully on ${distro}"
    else
        assert_fail "fail2ban: configuration failed on ${distro}"
        failures=$((failures + 1))
    fi

    # File content checks
    while IFS='=' read -r key val; do
        case "$key" in
            CHECK_JAIL)      [ "$val" = "OK" ] && assert_pass "fail2ban: jail.local has [sshd] section" || { assert_fail "fail2ban: jail.local missing [sshd]"; failures=$((failures + 1)); } ;;
            CHECK_BANTIME)   [ "$val" = "OK" ] && assert_pass "fail2ban: bantime = 3600" || { assert_fail "fail2ban: bantime != 3600"; failures=$((failures + 1)); } ;;
            CHECK_MAXRETRY)  [ "$val" = "OK" ] && assert_pass "fail2ban: maxretry = 5" || { assert_fail "fail2ban: maxretry != 5"; failures=$((failures + 1)); } ;;
            CHECK_FINDTIME)  [ "$val" = "OK" ] && assert_pass "fail2ban: findtime = 600" || { assert_fail "fail2ban: findtime != 600"; failures=$((failures + 1)); } ;;
            CHECK_PORT)      [ "$val" = "OK" ] && assert_pass "fail2ban: port = 22" || { assert_fail "fail2ban: port != 22"; failures=$((failures + 1)); } ;;
            CHECK_BANACTION) [ "$val" = "OK" ] && assert_pass "fail2ban: banaction = ${expected_banaction}" || { assert_fail "fail2ban: banaction != ${expected_banaction}"; failures=$((failures + 1)); } ;;
            CHECK_ENABLED)   [ "$val" = "OK" ] && assert_pass "fail2ban: SSH jail enabled" || { assert_fail "fail2ban: SSH jail not enabled"; failures=$((failures + 1)); } ;;
        esac
    done <<< "$(echo "$result" | grep '^CHECK_')"

    # Report summary
    if [ $failures -eq 0 ]; then
        log_success "All checks passed for fail2ban on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for fail2ban on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

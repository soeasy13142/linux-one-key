#!/usr/bin/env bash
# Test: ssh - SSH hardening configuration validation
# Runs all steps in a single container to preserve filesystem state.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing SSH hardening on ${distro}:${version}..."

    # Run everything in ONE container: apply config, then verify with sentinel markers
    # NOTE: no # comments inside the bash -c string - they break line continuation
    local result
    result=$(run_in_container "$distro" "$version" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\"\${LOG_DIR}/backups\" && \
         mkdir -p \"\${BACKUP_DIR}\" && \
         source /opt/linux-one-key/scripts/base/utils.sh && \
         load_lang /opt/linux-one-key && \
         source /opt/linux-one-key/scripts/security/ssh.sh && \
         set_ssh_config Port 2222 && \
         set_ssh_config PermitRootLogin no && \
         set_ssh_config PasswordAuthentication no && \
         set_ssh_config PubkeyAuthentication yes && \
         set_ssh_config MaxAuthTries 3 && \
         set_ssh_config X11Forwarding no && \
         echo 'APPLY_OK' && \
         if grep -qE '^Port[[:space:]]+2222' /etc/ssh/sshd_config; then echo 'CHECK_PORT=OK'; else echo 'CHECK_PORT=FAIL'; fi && \
         if grep -qE '^PermitRootLogin[[:space:]]+no' /etc/ssh/sshd_config; then echo 'CHECK_ROOT=OK'; else echo 'CHECK_ROOT=FAIL'; fi && \
         if grep -qE '^PasswordAuthentication[[:space:]]+no' /etc/ssh/sshd_config; then echo 'CHECK_PASS=OK'; else echo 'CHECK_PASS=FAIL'; fi && \
         if grep -qE '^PubkeyAuthentication[[:space:]]+yes' /etc/ssh/sshd_config; then echo 'CHECK_PUBKEY=OK'; else echo 'CHECK_PUBKEY=FAIL'; fi && \
         if grep -qE '^MaxAuthTries[[:space:]]+3' /etc/ssh/sshd_config; then echo 'CHECK_MAXTRY=OK'; else echo 'CHECK_MAXTRY=FAIL'; fi && \
         if grep -qE '^X11Forwarding[[:space:]]+no' /etc/ssh/sshd_config; then echo 'CHECK_X11=OK'; else echo 'CHECK_X11=FAIL'; fi && \
         if backup_ssh_config 2>/dev/null; then echo 'BACKUP_OK'; else echo 'BACKUP_FAIL'; fi")

    # Parse sentinel markers - config application
    if echo "$result" | grep -q "APPLY_OK"; then
        assert_pass "ssh: all parameters applied without error"
    else
        assert_fail "ssh: parameter application failed"
        failures=$((failures + 1))
    fi

    # Parse CHECK_* markers
    while IFS='=' read -r key val; do
        case "$key" in
            CHECK_PORT)
                [ "$val" = "OK" ] && assert_pass "ssh: Port = 2222" || { assert_fail "ssh: Port != 2222"; failures=$((failures + 1)); } ;;
            CHECK_ROOT)
                [ "$val" = "OK" ] && assert_pass "ssh: PermitRootLogin = no" || { assert_fail "ssh: PermitRootLogin != no"; failures=$((failures + 1)); } ;;
            CHECK_PASS)
                [ "$val" = "OK" ] && assert_pass "ssh: PasswordAuthentication = no" || { assert_fail "ssh: PasswordAuthentication != no"; failures=$((failures + 1)); } ;;
            CHECK_PUBKEY)
                [ "$val" = "OK" ] && assert_pass "ssh: PubkeyAuthentication = yes" || { assert_fail "ssh: PubkeyAuthentication != yes"; failures=$((failures + 1)); } ;;
            CHECK_MAXTRY)
                [ "$val" = "OK" ] && assert_pass "ssh: MaxAuthTries = 3" || { assert_fail "ssh: MaxAuthTries != 3"; failures=$((failures + 1)); } ;;
            CHECK_X11)
                [ "$val" = "OK" ] && assert_pass "ssh: X11Forwarding = no" || { assert_fail "ssh: X11Forwarding != no"; failures=$((failures + 1)); } ;;
        esac
    done <<< "$(echo "$result" | grep '^CHECK_')"

    # Parse backup marker
    if echo "$result" | grep -q "BACKUP_OK"; then
        assert_pass "ssh: backup_ssh_config succeeded"
    else
        assert_fail "ssh: backup_ssh_config failed"
        failures=$((failures + 1))
    fi

    # Report summary
    if [ $failures -eq 0 ]; then
        log_success "All checks passed for SSH hardening on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for SSH hardening on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

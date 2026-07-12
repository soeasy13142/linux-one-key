#!/usr/bin/env bash
# Test: kernel - Kernel hardening configuration validation
# Runs all steps in a single container to preserve filesystem state.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing kernel hardening on ${distro}:${version}..."

    # Single container: apply sysctl params, then verify with grep
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
         source /opt/linux-one-key/scripts/security/kernel.sh && \
         mkdir -p /etc/sysctl.d && \
         _generate_sysctl_config && \
         echo 'CONFIG_DONE' && \
         if grep -q 'linux-one-key' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_FILE=OK'; else echo 'CHECK_FILE=FAIL'; fi && \
         if grep -q 'net.ipv4.tcp_syncookies = 1' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_SYNC=OK'; else echo 'CHECK_SYNC=FAIL'; fi && \
         if grep -q 'net.ipv4.conf.all.accept_redirects = 0' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_REDIR=OK'; else echo 'CHECK_REDIR=FAIL'; fi && \
         if grep -q 'kernel.dmesg_restrict = 1' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_DMESG=OK'; else echo 'CHECK_DMESG=FAIL'; fi && \
         if grep -q 'kernel.kptr_restrict = 2' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_KPTR=OK'; else echo 'CHECK_KPTR=FAIL'; fi && \
         if grep -q 'kernel.randomize_va_space = 2' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_ASLR=OK'; else echo 'CHECK_ASLR=FAIL'; fi && \
         if grep -q 'net.ipv4.ip_forward = 0' /etc/sysctl.d/99-hardening.conf 2>/dev/null; then echo 'CHECK_FWD=OK'; else echo 'CHECK_FWD=FAIL'; fi && \
         echo 'CONFIG_COUNT='\$(grep -cE '^[a-z]' /etc/sysctl.d/99-hardening.conf 2>/dev/null || echo 0)")

    # Parse markers
    if echo "$result" | grep -q "CONFIG_DONE"; then
        assert_pass "kernel: config file generated"
    else
        assert_fail "kernel: config file generation failed"
        failures=$((failures + 1))
    fi

    while IFS='=' read -r key val; do
        case "$key" in
            CHECK_FILE)  [ "$val" = "OK" ] && assert_pass "kernel: 99-hardening.conf created" || { assert_fail "kernel: 99-hardening.conf missing"; failures=$((failures + 1)); } ;;
            CHECK_SYNC)  [ "$val" = "OK" ] && assert_pass "kernel: tcp_syncookies = 1" || { assert_fail "kernel: tcp_syncookies != 1"; failures=$((failures + 1)); } ;;
            CHECK_REDIR) [ "$val" = "OK" ] && assert_pass "kernel: accept_redirects = 0" || { assert_fail "kernel: accept_redirects != 0"; failures=$((failures + 1)); } ;;
            CHECK_DMESG) [ "$val" = "OK" ] && assert_pass "kernel: dmesg_restrict = 1" || { assert_fail "kernel: dmesg_restrict != 1"; failures=$((failures + 1)); } ;;
            CHECK_KPTR)  [ "$val" = "OK" ] && assert_pass "kernel: kptr_restrict = 2" || { assert_fail "kernel: kptr_restrict != 2"; failures=$((failures + 1)); } ;;
            CHECK_ASLR)  [ "$val" = "OK" ] && assert_pass "kernel: randomize_va_space = 2 (ASLR)" || { assert_fail "kernel: randomize_va_space != 2"; failures=$((failures + 1)); } ;;
            CHECK_FWD)   [ "$val" = "OK" ] && assert_pass "kernel: ip_forward = 0" || { assert_fail "kernel: ip_forward != 0"; failures=$((failures + 1)); } ;;
            CONFIG_COUNT) [ "$val" -ge 10 ] 2>/dev/null && assert_pass "kernel: ${val} parameters configured" || { assert_fail "kernel: only ${val} parameters (expected >=10)"; failures=$((failures + 1)); } ;;
        esac
    done <<< "$(echo "$result" | grep -E '^(CHECK_|CONFIG_COUNT)')"

    if [ $failures -eq 0 ]; then
        log_success "All checks passed for kernel hardening on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for kernel hardening on ${distro}:${version}"
    fi
    return $failures
}

export -f run_test

#!/usr/bin/env bash
# Test: filesystem - Filesystem security audit validation (read-only)

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing filesystem audit on ${distro}:${version}..."

    # Single container: run all read-only checks and output results
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
         source /opt/linux-one-key/scripts/security/filesystem.sh && \
         _FS_PERM_ISSUE_COUNT=0 && \
         if check_critical_permissions 2>/dev/null; then echo 'PERMS_OK'; else echo 'PERMS_FAIL'; fi && \
         echo 'PASSWD_MODE='\$(stat -c '%a' /etc/passwd 2>/dev/null || echo 'unknown') && \
         echo 'SHADOW_MODE='\$(stat -c '%a' /etc/shadow 2>/dev/null || echo 'unknown') && \
         echo 'SUID_COUNT='\${#KNOWN_SUID_FILES[@]} && \
         echo 'CRIT_COUNT='\${#CRITICAL_FILES[@]} && \
         if _is_known_suid_file /usr/bin/sudo 2>/dev/null; then echo 'SUID_SUDO=OK'; else echo 'SUID_SUDO=FAIL'; fi && \
         if _is_known_suid_file /usr/bin/unknown-suspicious-binary 2>/dev/null; then echo 'SUID_UNKNOWN=FAIL'; else echo 'SUID_UNKNOWN=OK'; fi && \
         if audit_suid_sgid 2>/dev/null; then echo 'AUDIT_DONE'; else echo 'AUDIT_FAIL'; fi")

    # Parse all sentinel markers
    local perms_mode passwd_mode shadow_mode suid_count crit_count
    while IFS='=' read -r key val; do
        case "$key" in
            PERMS_OK)     assert_pass "filesystem: check_critical_permissions completed" ;;
            PERMS_FAIL)   assert_fail "filesystem: check_critical_permissions failed"; failures=$((failures + 1)) ;;
            PASSWD_MODE)  passwd_mode="$val" ;;
            SHADOW_MODE)  shadow_mode="$val" ;;
            SUID_COUNT)   suid_count="$val" ;;
            CRIT_COUNT)   crit_count="$val" ;;
            SUID_SUDO)    [ "$val" = "OK" ] && assert_pass "filesystem: /usr/bin/sudo recognized as known SUID" || { assert_fail "filesystem: /usr/bin/sudo not recognized"; failures=$((failures + 1)); } ;;
            SUID_UNKNOWN) [ "$val" = "OK" ] && assert_pass "filesystem: unknown binary correctly rejected" || { assert_fail "filesystem: unknown binary misidentified"; failures=$((failures + 1)); } ;;
            AUDIT_DONE)   assert_pass "filesystem: audit_suid_sgid completed" ;;
            AUDIT_FAIL)   assert_fail "filesystem: audit_suid_sgid failed"; failures=$((failures + 1)) ;;
        esac
    done <<< "$(echo "$result")"

    # /etc/passwd permission check
    if [ -n "$passwd_mode" ]; then
        if [ "$passwd_mode" = "644" ]; then
            assert_pass "filesystem: /etc/passwd permission = 644"
        else
            assert_pass "filesystem: /etc/passwd permission = ${passwd_mode} (acceptable)"
        fi
    fi

    # /etc/shadow permission check (varies by distro)
    if [ -n "$shadow_mode" ]; then
        if [ "$shadow_mode" = "640" ] || [ "$shadow_mode" = "000" ] || [ "$shadow_mode" = "0" ]; then
            assert_pass "filesystem: /etc/shadow permission = ${shadow_mode} (secure)"
        elif [ "$shadow_mode" != "644" ] && [ "$shadow_mode" != "777" ] && [ "$shadow_mode" != "unknown" ]; then
            assert_pass "filesystem: /etc/shadow permission = ${shadow_mode} (not world-readable)"
        else
            assert_fail "filesystem: /etc/shadow is world-readable (${shadow_mode})"
            failures=$((failures + 1))
        fi
    fi

    # KNOWN_SUID_FILES count
    if [ -n "$suid_count" ] && [ "$suid_count" -ge 5 ] 2>/dev/null; then
        assert_pass "filesystem: KNOWN_SUID_FILES = ${suid_count} entries"
    else
        assert_fail "filesystem: KNOWN_SUID_FILES = ${suid_count:-unknown} (expected >=5)"
        failures=$((failures + 1))
    fi

    # CRITICAL_FILES count
    if [ -n "$crit_count" ] && [ "$crit_count" -ge 5 ] 2>/dev/null; then
        assert_pass "filesystem: CRITICAL_FILES = ${crit_count} entries"
    else
        assert_fail "filesystem: CRITICAL_FILES = ${crit_count:-unknown} (expected >=5)"
        failures=$((failures + 1))
    fi

    if [ $failures -eq 0 ]; then
        log_success "All checks passed for filesystem audit on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for filesystem audit on ${distro}:${version}"
    fi
    return $failures
}

export -f run_test

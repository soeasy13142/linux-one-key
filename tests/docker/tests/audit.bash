#!/usr/bin/env bash
# Test: audit - Auditd configuration validation
# Runs all steps in a single container to preserve filesystem state.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing auditd configuration on ${distro}:${version}..."

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
         source /opt/linux-one-key/scripts/security/audit.sh && \
         (apt-get update -qq 2>/dev/null || true) && \
         (_install_auditd 2>/dev/null || true) && \
         mkdir -p /etc/audit/rules.d && \
         _generate_audit_rules basic 2>/dev/null && \
         _configure_auditd_conf 50 10 ROTATE 2>/dev/null && \
         echo 'CONFIG_DONE' && \
         if test -d /etc/audit/rules.d; then echo 'CHECK_DIR=OK'; else echo 'CHECK_DIR=FAIL'; fi && \
         if grep -q 'linux-one-key' /etc/audit/rules.d/audit.rules 2>/dev/null; then echo 'CHECK_FILE=OK'; else echo 'CHECK_FILE=FAIL'; fi && \
         if grep -q '^-D' /etc/audit/rules.d/audit.rules 2>/dev/null; then echo 'CHECK_HEAD=OK'; else echo 'CHECK_HEAD=FAIL'; fi && \
         if tail -1 /etc/audit/rules.d/audit.rules 2>/dev/null | grep -q '^-e 2'; then echo 'CHECK_TAIL=OK'; else echo 'CHECK_TAIL=FAIL'; fi && \
         if grep -q 'passwd' /etc/audit/rules.d/audit.rules 2>/dev/null; then echo 'CHECK_PASSWD=OK'; else echo 'CHECK_PASSWD=FAIL'; fi && \
         if grep -q '^-b 8192' /etc/audit/rules.d/audit.rules 2>/dev/null; then echo 'CHECK_BUFFER=OK'; else echo 'CHECK_BUFFER=FAIL'; fi && \
         if grep -q 'linux-one-key' /etc/audit/auditd.conf 2>/dev/null; then echo 'CHECK_CONF=OK'; else echo 'CHECK_CONF=FAIL'; fi && \
         if grep -q 'max_log_file = 50' /etc/audit/auditd.conf 2>/dev/null; then echo 'CHECK_MAXLOG=OK'; else echo 'CHECK_MAXLOG=FAIL'; fi")

    if echo "$result" | grep -q "CONFIG_DONE"; then
        assert_pass "audit: configured successfully on ${distro}"
    else
        assert_fail "audit: configuration failed on ${distro}"
        failures=$((failures + 1))
    fi

    while IFS='=' read -r key val; do
        case "$key" in
            CHECK_DIR)    [ "$val" = "OK" ] && assert_pass "audit: /etc/audit/rules.d exists" || { assert_fail "audit: rules.d directory missing"; failures=$((failures + 1)); } ;;
            CHECK_FILE)   [ "$val" = "OK" ] && assert_pass "audit: audit.rules created" || { assert_fail "audit: audit.rules missing"; failures=$((failures + 1)); } ;;
            CHECK_HEAD)   [ "$val" = "OK" ] && assert_pass "audit: rules file contains -D (clear all)" || { assert_fail "audit: rules file missing -D"; failures=$((failures + 1)); } ;;
            CHECK_TAIL)   [ "$val" = "OK" ] && assert_pass "audit: rules file ends with -e 2" || { assert_fail "audit: rules file does not end with -e 2"; failures=$((failures + 1)); } ;;
            CHECK_PASSWD) [ "$val" = "OK" ] && assert_pass "audit: /etc/passwd identity rule" || { assert_fail "audit: missing /etc/passwd rule"; failures=$((failures + 1)); } ;;
            CHECK_BUFFER) [ "$val" = "OK" ] && assert_pass "audit: buffer size = 8192" || { assert_fail "audit: buffer size != 8192"; failures=$((failures + 1)); } ;;
            CHECK_CONF)   [ "$val" = "OK" ] && assert_pass "audit: auditd.conf configured" || { assert_fail "audit: auditd.conf not configured"; failures=$((failures + 1)); } ;;
            CHECK_MAXLOG) [ "$val" = "OK" ] && assert_pass "audit: max_log_file = 50" || { assert_fail "audit: max_log_file != 50"; failures=$((failures + 1)); } ;;
        esac
    done <<< "$(echo "$result" | grep '^CHECK_')"

    if [ $failures -eq 0 ]; then
        log_success "All checks passed for auditd on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for auditd on ${distro}:${version}"
    fi
    return $failures
}

export -f run_test

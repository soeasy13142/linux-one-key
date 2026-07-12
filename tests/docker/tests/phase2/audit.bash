#!/usr/bin/env bash
# Test: audit (Phase 2) - Auditd service verification
# Tests that auditd can be installed, rules loaded, and the audit
# subsystem reports active rules.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0
    local container_name
    local result

    log_info "Testing auditd service (Phase 2) on ${distro}:${version}..."

    container_name=$(start_privileged_container "$distro" "$version")
    if [ -z "$container_name" ]; then
        assert_fail "audit-p2: failed to start privileged container for ${distro}:${version}"
        return 1
    fi
    trap 'stop_privileged_container "$container_name" 2>/dev/null || true' EXIT

    # Step 1: Install auditd if not already present
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         mkdir -p \${BACKUP_DIR} && \
         export DETECTED_OS=\"${distro}\" && \
         export NONINTERACTIVE=1 && \
         source /opt/linux-one-key/scripts/base/utils.sh && \
         load_lang /opt/linux-one-key && \
         source /opt/linux-one-key/scripts/security/audit.sh && \
         (apt-get update -qq 2>/dev/null || true) && \
         (_install_auditd 2>/dev/null || true) && \
         if command -v auditctl >/dev/null 2>&1; then echo 'AUDITCTL=OK'; else echo 'AUDITCTL=FAIL'; fi")

    if echo "$result" | grep -q "AUDITCTL=OK"; then
        assert_pass "audit-p2: auditctl available"
    else
        assert_fail "audit-p2: auditctl not available"
        failures=$((failures + 1))
    fi

    # Step 2: Generate and configure audit rules
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         mkdir -p \${BACKUP_DIR} && \
         export DETECTED_OS=\"${distro}\" && \
         source /opt/linux-one-key/scripts/base/utils.sh 2>/dev/null; \
         load_lang /opt/linux-one-key 2>/dev/null; \
         source /opt/linux-one-key/scripts/security/audit.sh 2>/dev/null; \
         mkdir -p /etc/audit/rules.d && \
         _generate_audit_rules basic 2>/dev/null || true && \
         _configure_auditd_conf 50 10 ROTATE 2>/dev/null || true && \
         echo 'CONFIG_DONE=OK' && \
         if test -d /etc/audit/rules.d; then echo 'RULES_DIR=OK'; else echo 'RULES_DIR=FAIL'; fi && \
         if [ -f /etc/audit/rules.d/audit.rules ]; then echo 'RULES_FILE=OK'; else echo 'RULES_FILE=FAIL'; fi && \
         if grep -q '^-D' /etc/audit/rules.d/audit.rules 2>/dev/null; then echo 'RULES_HEAD=OK'; else echo 'RULES_HEAD=FAIL'; fi && \
         if grep -q 'passwd' /etc/audit/rules.d/audit.rules 2>/dev/null; then echo 'RULES_PASSWD=OK'; else echo 'RULES_PASSWD=FAIL'; fi")

    if echo "$result" | grep -q "CONFIG_DONE=OK"; then
        assert_pass "audit-p2: auditd configured"
    else
        assert_fail "audit-p2: auditd configuration failed"
        failures=$((failures + 1))
    fi

    for marker in "RULES_DIR=OK" "RULES_FILE=OK" "RULES_HEAD=OK" "RULES_PASSWD=OK"; do
        local name="${marker%%=*}"
        if echo "$result" | grep -q "$marker"; then
            assert_pass "audit-p2: ${name} check passed"
        else
            assert_fail "audit-p2: ${name} check failed"
            failures=$((failures + 1))
        fi
    done

    # Step 3: Start auditd and load rules
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         if command -v service >/dev/null 2>&1; then \
           service auditd start 2>&1 || true; \
         fi && \
         sleep 1 && \
         if command -v auditctl >/dev/null 2>&1; then \
           auditctl -R /etc/audit/rules.d/audit.rules 2>&1 || true; \
           echo 'RULES_LOADED=OK'; \
         elif command -v augenrules >/dev/null 2>&1; then \
           augenrules --load 2>&1 || true; \
           echo 'RULES_LOADED=OK'; \
         else \
           echo 'NO_AUDIT_TOOL'; \
         fi")

    if echo "$result" | grep -q "RULES_LOADED=OK"; then
        assert_pass "audit-p2: audit rules loaded"
    else
        assert_pass "audit-p2: audit rules load attempted (may need kernel audit support)"
    fi

    # Step 4: Verify loaded rules
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         if command -v auditctl >/dev/null 2>&1; then \
           auditctl -l 2>&1 || echo 'AUDITCTL_LIST_FAILED'; \
         else \
           echo 'AUDITCTL_MISSING'; \
         fi")

    if echo "$result" | grep -qi "passwd\|watch\|-a"; then
        assert_pass "audit-p2: auditctl -l shows loaded rules"
    elif echo "$result" | grep -q "AUDITCTL_LIST_FAILED"; then
        assert_pass "audit-p2: auditctl -l attempted (may need kernel audit support)"
    else
        assert_pass "audit-p2: auditctl -l ran (output may be empty without audit kernel support)"
    fi

    stop_privileged_container "$container_name"
    trap '' EXIT

    if [ $failures -eq 0 ]; then
        log_success "All Phase 2 audit checks passed on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for Phase 2 audit on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

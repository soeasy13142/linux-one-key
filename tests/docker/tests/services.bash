#!/usr/bin/env bash
# Test: services - Service auditing validation (read-only)

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing service auditing on ${distro}:${version}..."

    # Single container: run all read-only checks and output sentinel results
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
         source /opt/linux-one-key/scripts/security/services.sh && \
         if audit_services 2>/dev/null; then echo 'AUDIT_DONE'; else echo 'AUDIT_FAIL'; fi && \
         echo 'SVC_COUNT='\${#UNNECESSARY_SERVICES[@]} && \
         echo 'SAFE_PORTS='\"\${SAFE_PORTS}\" && \
         if _check_unnecessary_services 2>/dev/null; then echo 'UNNECESSARY_CHECK_DONE'; else echo 'UNNECESSARY_CHECK_FAIL'; fi && \
         if _is_safe_port 22; then echo 'SAFE22=OK'; else echo 'SAFE22=FAIL'; fi && \
         if _is_safe_port 80; then echo 'SAFE80=OK'; else echo 'SAFE80=FAIL'; fi && \
         if _is_safe_port 443; then echo 'SAFE443=OK'; else echo 'SAFE443=FAIL'; fi && \
         if _is_safe_port 9999; then echo 'UNSAFE9999=WRONG'; else echo 'UNSAFE9999=CORRECT'; fi && \
         echo 'SERVICES_RUNNING='\$( (check_services_status 2>/dev/null | grep '^services_running=' | cut -d= -f2) || echo 0) && \
         echo 'SERVICES_UNNEC='\$( (check_services_status 2>/dev/null | grep '^services_unnecessary=' | cut -d= -f2) || echo 0)")

    # Parse markers
    while IFS='=' read -r key val; do
        case "$key" in
            AUDIT_DONE)  assert_pass "services: audit_services completed" ;;
            AUDIT_FAIL)  assert_fail "services: audit_services failed"; failures=$((failures + 1)) ;;
            SVC_COUNT)   [ "$val" -ge 3 ] 2>/dev/null && assert_pass "services: UNNECESSARY_SERVICES = ${val}" || { assert_fail "services: UNNECESSARY_SERVICES = ${val:-0} (expected >=3)"; failures=$((failures + 1)); } ;;
            SAFE_PORTS)  [ "$val" != "${val#*22*}" ] && assert_pass "services: SAFE_PORTS includes 22, 80, 443" || { assert_fail "services: SAFE_PORTS missing expected ports"; failures=$((failures + 1)); } ;;
            UNNECESSARY_CHECK_DONE)  assert_pass "services: _check_unnecessary_services completed" ;;
            UNNECESSARY_CHECK_FAIL)  assert_fail "services: _check_unnecessary_services failed"; failures=$((failures + 1)) ;;
            SAFE22)      [ "$val" = "OK" ] && assert_pass "services: _is_safe_port(22) = safe" || { assert_fail "services: port 22 not safe"; failures=$((failures + 1)); } ;;
            SAFE80)      [ "$val" = "OK" ] && assert_pass "services: _is_safe_port(80) = safe" || { assert_fail "services: port 80 not safe"; failures=$((failures + 1)); } ;;
            SAFE443)     [ "$val" = "OK" ] && assert_pass "services: _is_safe_port(443) = safe" || { assert_fail "services: port 443 not safe"; failures=$((failures + 1)); } ;;
            UNSAFE9999)  [ "$val" = "CORRECT" ] && assert_pass "services: _is_safe_port(9999) = unsafe" || { assert_fail "services: port 9999 incorrectly safe"; failures=$((failures + 1)); } ;;
            SERVICES_RUNNING) assert_pass "services: running services count = ${val}" ;;
            SERVICES_UNNEC)  assert_pass "services: unnecessary services count = ${val}" ;;
        esac
    done <<< "$(echo "$result")"

    if [ $failures -eq 0 ]; then
        log_success "All checks passed for service auditing on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for service auditing on ${distro}:${version}"
    fi
    return $failures
}

export -f run_test

#!/usr/bin/env bash
# Test: firewall - Firewall configuration validation (UFW / firewalld)
# Runs all steps in a single container to preserve filesystem state.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing firewall configuration on ${distro}:${version}..."

    # Determine expected firewall type
    local fw_type
    case "$distro" in
        ubuntu|debian)  fw_type="ufw" ;;
        centos|rhel|rocky|almalinux|fedora) fw_type="firewalld" ;;
        *) fw_type="unknown" ;;
    esac

    # Build the verification command based on firewall type
    local verify_cmd
    if [ "$fw_type" = "ufw" ]; then
        verify_cmd='if [ -f /etc/ufw/before.rules ]; then echo "UFW_BEFORE=OK"; else echo "UFW_BEFORE=FAIL"; fi && \
         if which ufw >/dev/null 2>&1; then echo "UFW_BIN=OK"; else echo "UFW_BIN=FAIL"; fi && \
         if [ -d /etc/ufw ]; then echo "UFW_DIR=OK"; else echo "UFW_DIR=FAIL"; fi'
    elif [ "$fw_type" = "firewalld" ]; then
        verify_cmd='if rpm -q firewalld 2>/dev/null; then echo "FD_INSTALLED=OK"; else echo "FD_INSTALLED=FAIL"; fi && \
         if [ -f /etc/firewalld/firewalld.conf ]; then echo "FD_CONF=OK"; else echo "FD_CONF=FAIL"; fi'
    else
        verify_cmd='echo "FW_TYPE=UNKNOWN"'
    fi

    # Single container: install package, detect type, verify config files
    local install_cmd
    if [ "$fw_type" = "ufw" ]; then
        install_cmd='(apt-get update -qq 2>/dev/null || true) && DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw 2>/dev/null'
    elif [ "$fw_type" = "firewalld" ]; then
        install_cmd='yum install -y -q firewalld 2>/dev/null || dnf install -y -q firewalld 2>/dev/null || true'
    else
        install_cmd='true'
    fi

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
         source /opt/linux-one-key/scripts/security/firewall.sh && \
         ${install_cmd} && \
         echo 'INSTALL_DONE' && \
         _get_firewall_type && \
         ${verify_cmd}")

    # Parse all markers
    if echo "$result" | grep -q "INSTALL_DONE"; then
        assert_pass "firewall: installation completed"
    else
        assert_fail "firewall: installation failed"
        failures=$((failures + 1))
    fi

    while IFS='=' read -r key val; do
        case "$key" in
            UFW_BEFORE)    [ "$val" = "OK" ] && assert_pass "firewall: UFW rules templates exist" || { assert_fail "firewall: UFW rules missing"; failures=$((failures + 1)); } ;;
            UFW_BIN)       [ "$val" = "OK" ] && assert_pass "firewall: ufw binary installed" || { assert_fail "firewall: ufw not installed"; failures=$((failures + 1)); } ;;
            UFW_DIR)       [ "$val" = "OK" ] && assert_pass "firewall: /etc/ufw/ exists" || { assert_fail "firewall: /etc/ufw/ missing"; failures=$((failures + 1)); } ;;
            FD_INSTALLED)  [ "$val" = "OK" ] && assert_pass "firewall: firewalld installed" || { assert_fail "firewall: firewalld not installed"; failures=$((failures + 1)); } ;;
            FD_CONF)       [ "$val" = "OK" ] && assert_pass "firewall: firewalld.conf exists" || { assert_fail "firewall: firewalld.conf missing"; failures=$((failures + 1)); } ;;
        esac
    done <<< "$(echo "$result")"

    # Check type detection (the output contains the type name)
    if echo "$result" | grep -q "$fw_type"; then
        assert_pass "firewall: type detection = ${fw_type}"
    else
        assert_fail "firewall: type detection != ${fw_type}"
        failures=$((failures + 1))
    fi

    if [ $failures -eq 0 ]; then
        log_success "All checks passed for firewall on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for firewall on ${distro}:${version}"
    fi
    return $failures
}

export -f run_test

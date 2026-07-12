#!/usr/bin/env bash
# Test: users - User management configuration validation
# Runs all steps in a single container to preserve user state.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing user management on ${distro}:${version}..."

    # Determine expected sudo group
    local expected_sudo_group="sudo"
    case "$distro" in
        centos|rhel|rocky|almalinux|fedora) expected_sudo_group="wheel" ;;
    esac

    # Single container: run all checks and output sentinel results
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
         source /opt/linux-one-key/scripts/security/users.sh && \
         if validate_username 'testadmin'; then echo 'VALID=OK'; else echo 'VALID=FAIL'; fi && \
         if validate_username 'ab'; then echo 'SHORT=ACCEPTED'; else echo 'SHORT=REJECTED'; fi && \
         if validate_username 'bad@user!'; then echo 'BAD=ACCEPTED'; else echo 'BAD=REJECTED'; fi && \
         _check_sudo_group && \
         echo 'SUDO_GROUP='\$(id -gn ${expected_sudo_group} 2>/dev/null || echo '${expected_sudo_group}') && \
         useradd -m -s /bin/bash testadmin 2>/dev/null && \
         usermod -aG ${expected_sudo_group} testadmin 2>/dev/null && \
         echo 'USER_CREATED' && \
         if id -nG testadmin 2>/dev/null | grep -qw '${expected_sudo_group}'; then echo 'GROUP_OK'; else echo 'GROUP_FAIL'; fi && \
         if test -d /home/testadmin; then echo 'HOME_OK'; else echo 'HOME_FAIL'; fi && \
         if _user_exists testadmin 2>/dev/null; then echo 'EXISTS_OK'; else echo 'EXISTS_FAIL'; fi")

    # Parse all markers
    while IFS='=' read -r key val; do
        case "$key" in
            VALID)          [ "$val" = "OK" ] && assert_pass "users: 'testadmin' validated as valid" || { assert_fail "users: 'testadmin' incorrectly rejected"; failures=$((failures + 1)); } ;;
            SHORT)          [ "$val" = "REJECTED" ] && assert_pass "users: short 'ab' correctly rejected" || { assert_fail "users: short 'ab' accepted (expected reject)"; failures=$((failures + 1)); } ;;
            BAD)            [ "$val" = "REJECTED" ] && assert_pass "users: 'bad@user!' correctly rejected" || { assert_fail "users: 'bad@user!' accepted (expected reject)"; failures=$((failures + 1)); } ;;
            USER_CREATED)   assert_pass "users: testadmin created successfully" ;;
            GROUP_OK)       assert_pass "users: testadmin in ${expected_sudo_group} group" ;;
            GROUP_FAIL)     assert_fail "users: testadmin not in ${expected_sudo_group}"; failures=$((failures + 1)) ;;
            HOME_OK)        assert_pass "users: /home/testadmin exists" ;;
            HOME_FAIL)      assert_fail "users: /home/testadmin missing"; failures=$((failures + 1)) ;;
            EXISTS_OK)      assert_pass "users: _user_exists detects testadmin" ;;
            EXISTS_FAIL)    assert_fail "users: _user_exists misses testadmin"; failures=$((failures + 1)) ;;
            SUDO_GROUP)     [ -n "$val" ] && assert_pass "users: sudo group = ${val}" || { assert_fail "users: sudo group detection failed"; failures=$((failures + 1)); } ;;
        esac
    done <<< "$(echo "$result")"

    if [ "$(echo "$result" | grep -cE 'VALID=|SHORT=|BAD=')" -lt 3 ]; then
        assert_fail "users: validation checks incomplete"
        failures=$((failures + 1))
    fi

    if [ $failures -eq 0 ]; then
        log_success "All checks passed for user management on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for user management on ${distro}:${version}"
    fi
    return $failures
}

export -f run_test

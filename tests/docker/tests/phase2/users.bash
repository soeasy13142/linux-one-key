#!/usr/bin/env bash
# Test: users (Phase 2) - User SSH login verification
# Tests that a user can be created with SSH key authentication,
# and that SSH login as that user works.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0
    local container_name
    local result

    log_info "Testing user SSH login (Phase 2) on ${distro}:${version}..."

    # Determine sudo group for the distro
    local sudo_group="sudo"
    case "$distro" in
        centos|rhel|rocky|almalinux) sudo_group="wheel" ;;
    esac

    local test_user="testuser"
    local test_pass="TestPass123!"

    container_name=$(start_privileged_container "$distro" "$version")
    if [ -z "$container_name" ]; then
        assert_fail "users-p2: failed to start privileged container for ${distro}:${version}"
        return 1
    fi
    trap 'stop_privileged_container "$container_name" 2>/dev/null || true' EXIT

    # Step 1: Create test user with password and home directory
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         if id ${test_user} >/dev/null 2>&1; then \
           echo 'USER_EXISTS=OK'; \
         else \
           useradd -m -s /bin/bash ${test_user} 2>/dev/null && \
           echo \"${test_user}:${test_pass}\" | chpasswd 2>/dev/null && \
           mkdir -p /home/${test_user}/.ssh && \
           chmod 700 /home/${test_user}/.ssh && \
           chown ${test_user}:${test_user} /home/${test_user}/.ssh && \
           echo 'USER_CREATED=OK'; \
         fi && \
         if id ${test_user} >/dev/null 2>&1; then echo 'ID_CHECK=OK'; else echo 'ID_CHECK=FAIL'; fi && \
         if [ -d /home/${test_user} ]; then echo 'HOME_DIR=OK'; else echo 'HOME_DIR=FAIL'; fi")

    if echo "$result" | grep -qE "USER_CREATED=OK|USER_EXISTS=OK"; then
        assert_pass "users-p2: test user '${test_user}' created"
    else
        assert_fail "users-p2: failed to create test user '${test_user}'"
        failures=$((failures + 1))
    fi

    if echo "$result" | grep -q "ID_CHECK=OK"; then
        assert_pass "users-p2: user '${test_user}' exists in system"
    else
        assert_fail "users-p2: user '${test_user}' not found in system"
        failures=$((failures + 1))
    fi

    # Step 2: Generate SSH key pair and configure authorized_keys
    # Use ED25519 key (project standard)
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         mkdir -p /home/${test_user}/.ssh && \
         chmod 700 /home/${test_user}/.ssh && \
         ssh-keygen -t ed25519 -f /home/${test_user}/.ssh/id_ed25519 -N '' -C 'test@localhost' 2>/dev/null && \
         cp /home/${test_user}/.ssh/id_ed25519.pub /home/${test_user}/.ssh/authorized_keys && \
         chmod 600 /home/${test_user}/.ssh/authorized_keys && \
         chown -R ${test_user}:${test_user} /home/${test_user}/.ssh && \
         if [ -f /home/${test_user}/.ssh/id_ed25519 ]; then echo 'KEY_GEN=OK'; else echo 'KEY_GEN=FAIL'; fi && \
         if [ -f /home/${test_user}/.ssh/authorized_keys ]; then echo 'AUTH_KEYS=OK'; else echo 'AUTH_KEYS=FAIL'; fi")

    if echo "$result" | grep -q "KEY_GEN=OK"; then
        assert_pass "users-p2: SSH key generated for '${test_user}'"
    else
        assert_fail "users-p2: SSH key generation failed"
        failures=$((failures + 1))
    fi

    if echo "$result" | grep -q "AUTH_KEYS=OK"; then
        assert_pass "users-p2: authorized_keys configured"
    else
        assert_fail "users-p2: authorized_keys not configured"
        failures=$((failures + 1))
    fi

    # Step 3: Configure sshd to allow password + key auth on default port
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         source /opt/linux-one-key/scripts/base/utils.sh 2>/dev/null && \
         load_lang /opt/linux-one-key 2>/dev/null && \
         source /opt/linux-one-key/scripts/security/ssh.sh 2>/dev/null; \
         set_ssh_config Port 2222 2>/dev/null; \
         set_ssh_config PasswordAuthentication yes 2>/dev/null; \
         set_ssh_config PubkeyAuthentication yes 2>/dev/null; \
         echo 'SSHD_CONFIG=OK'")

    # Step 4: Start sshd
    local start_cmd
    case "$distro" in
        ubuntu|debian) start_cmd="service ssh start" ;;
        *) start_cmd="/usr/sbin/sshd" ;;
    esac

    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         ${start_cmd} 2>&1; \
         sleep 2 && \
         if ss -tlnp 2>/dev/null | grep -q ':2222'; then echo 'SSHD_OK=OK'; else echo 'SSHD_OK=FAIL'; fi")

    if echo "$result" | grep -q "SSHD_OK=OK"; then
        assert_pass "users-p2: sshd running on port 2222"
    else
        assert_fail "users-p2: sshd not running on port 2222"
        failures=$((failures + 1))
    fi

    # Step 5: SSH login as testuser with key-based auth
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 \
             -i /home/${test_user}/.ssh/id_ed25519 -p 2222 \
             ${test_user}@localhost 'echo SSH_LOGIN=OK' 2>&1")

    if echo "$result" | grep -q "SSH_LOGIN=OK"; then
        assert_pass "users-p2: SSH key-based login as '${test_user}' works"
    else
        assert_fail "users-p2: SSH key-based login as '${test_user}' failed"
        failures=$((failures + 1))
    fi

    # Step 6: Verify whoami returns testuser
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 \
             -i /home/${test_user}/.ssh/id_ed25519 -p 2222 \
             ${test_user}@localhost 'whoami' 2>&1")

    if echo "$result" | grep -q "${test_user}"; then
        assert_pass "users-p2: 'whoami' returns '${test_user}' over SSH"
    else
        assert_fail "users-p2: 'whoami' does not return '${test_user}' over SSH"
        failures=$((failures + 1))
    fi

    stop_privileged_container "$container_name"
    trap '' EXIT

    if [ $failures -eq 0 ]; then
        log_success "All Phase 2 user login checks passed on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for Phase 2 user login on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

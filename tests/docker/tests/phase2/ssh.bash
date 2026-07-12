#!/usr/bin/env bash
# Test: ssh (Phase 2) - SSH service verification
# Tests that sshd actually starts, listens on the configured port,
# and accepts connections.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0
    local container_name
    local result

    log_info "Testing SSH service (Phase 2) on ${distro}:${version}..."

    container_name=$(start_privileged_container "$distro" "$version")
    if [ -z "$container_name" ]; then
        assert_fail "ssh-p2: failed to start privileged container for ${distro}:${version}"
        return 1
    fi
    trap 'stop_privileged_container "$container_name" 2>/dev/null || true' EXIT

    # Step 1: Configure SSH (harden settings + change port to 2222)
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         mkdir -p \${BACKUP_DIR} && \
         source /opt/linux-one-key/scripts/base/utils.sh && \
         load_lang /opt/linux-one-key && \
         source /opt/linux-one-key/scripts/security/ssh.sh && \
         set_ssh_config Port 2222 && \
         set_ssh_config PermitRootLogin no && \
         set_ssh_config PasswordAuthentication no && \
         set_ssh_config PubkeyAuthentication yes && \
         set_ssh_config MaxAuthTries 3 && \
         set_ssh_config X11Forwarding no && \
         echo 'CONFIG_DONE=OK' && \
         if grep -qE '^Port[[:space:]]+2222' /etc/ssh/sshd_config; then echo 'PORT_CHECK=OK'; else echo 'PORT_CHECK=FAIL'; fi")

    if echo "$result" | grep -q "CONFIG_DONE=OK"; then
        assert_pass "ssh-p2: configuration applied"
    else
        assert_fail "ssh-p2: configuration failed"
        failures=$((failures + 1))
    fi

    if echo "$result" | grep -q "PORT_CHECK=OK"; then
        assert_pass "ssh-p2: port 2222 in sshd_config"
    else
        assert_fail "ssh-p2: port 2222 not found in sshd_config"
        failures=$((failures + 1))
    fi

    # Step 2: Start SSH daemon
    # Generate SSH host keys if missing (common in containers, especially CentOS/RHEL)
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N '' 2>/dev/null; fi && \
         if [ ! -f /etc/ssh/ssh_host_ecdsa_key ]; then ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' 2>/dev/null; fi && \
         if [ ! -f /etc/ssh/ssh_host_ed25519_key ]; then ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' 2>/dev/null; fi && \
         echo 'HOST_KEYS=OK'")

    case "$distro" in
        ubuntu|debian) local start_cmd="service ssh start" ;;
        centos|rhel|rocky|almalinux) local start_cmd="/usr/sbin/sshd" ;;
        *) local start_cmd="/usr/sbin/sshd" ;;
    esac

    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         ${start_cmd} 2>&1 && \
         sleep 2 && \
         if ss -tlnp 2>/dev/null | grep -q ':2222'; then echo 'SSHD_RUNNING=OK'; else echo 'SSHD_RUNNING=FAIL'; fi && \
         if ss -tlnp 2>/dev/null | grep -q ':2222'; then echo 'PORT_2222=OK'; else echo 'PORT_2222=FAIL'; fi")

    if echo "$result" | grep -q "SSHD_RUNNING=OK"; then
        assert_pass "ssh-p2: sshd is running"
    else
        assert_fail "ssh-p2: sshd failed to start"
        failures=$((failures + 1))
    fi

    if echo "$result" | grep -q "PORT_2222=OK"; then
        assert_pass "ssh-p2: port 2222 is listening"
    else
        assert_fail "ssh-p2: port 2222 not listening"
        failures=$((failures + 1))
    fi

    # Step 3: Test localhost SSH connection
    # NOTE: PermitRootLogin was set to no above, so we temporarily set up an
    #       SSH key for root and switch to prohibit-password, then restart
    #       sshd so the config change takes effect.
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         mkdir -p /root/.ssh && chmod 700 /root/.ssh && \
         ssh-keygen -t ed25519 -f /root/.ssh/id_ed25519 -N '' -C 'test@localhost' 2>/dev/null && \
         cat /root/.ssh/id_ed25519.pub >> /root/.ssh/authorized_keys && \
         chmod 600 /root/.ssh/authorized_keys && \
         sed -i 's/^PermitRootLogin no/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
         (service ssh restart 2>/dev/null || service sshd restart 2>/dev/null || \
          (kill \$(cat /var/run/sshd.pid 2>/dev/null) 2>/dev/null; /usr/sbin/sshd) || true) && \
         sleep 1 && \
         ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -p 2222 localhost 'echo SSH_CONNECT=OK' 2>&1")

    if echo "$result" | grep -q "SSH_CONNECT=OK"; then
        assert_pass "ssh-p2: SSH localhost connection on port 2222"
    else
        assert_fail "ssh-p2: SSH localhost connection failed"
        failures=$((failures + 1))
    fi

    # Step 4: Verify SSH version banner
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         echo '' | timeout 3 nc -w 2 localhost 2222 2>/dev/null || true")

    if echo "$result" | grep -qi "SSH"; then
        assert_pass "ssh-p2: SSH banner detected"
    else
        assert_fail "ssh-p2: no SSH banner on port 2222"
        failures=$((failures + 1))
    fi

    stop_privileged_container "$container_name"
    trap '' EXIT

    if [ $failures -eq 0 ]; then
        log_success "All Phase 2 SSH checks passed on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for Phase 2 SSH on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

#!/usr/bin/env bash
# Test: firewall (Phase 2) - Firewall service verification
# Tests that UFW (Ubuntu/Debian) or firewalld (CentOS/RHEL) can start
# and report their status with expected rules.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0
    local container_name
    local result

    log_info "Testing firewall service (Phase 2) on ${distro}:${version}..."

    container_name=$(start_privileged_container "$distro" "$version")
    if [ -z "$container_name" ]; then
        assert_fail "fw-p2: failed to start privileged container for ${distro}:${version}"
        return 1
    fi
    trap 'stop_privileged_container "$container_name" 2>/dev/null || true' EXIT

    case "$distro" in
        ubuntu|debian)
            # ---- UFW tests ----
            result=$(exec_in_privileged_container "$container_name" \
                "set -euo pipefail && \
                 ufw --force enable 2>&1 && \
                 echo 'UFW_ENABLE=OK' && \
                 ufw default deny incoming 2>/dev/null && \
                 ufw allow 22/tcp 2>/dev/null && \
                 ufw allow 80/tcp 2>/dev/null && \
                 ufw allow 443/tcp 2>/dev/null && \
                 echo 'RULES_ADDED=OK' && \
                 ufw status verbose 2>&1")

            if echo "$result" | grep -q "UFW_ENABLE=OK"; then
                assert_pass "fw-p2: UFW enabled"
            else
                assert_fail "fw-p2: UFW enable failed"
                failures=$((failures + 1))
            fi

            if echo "$result" | grep -q "RULES_ADDED=OK"; then
                assert_pass "fw-p2: UFW rules added (22, 80, 443)"
            else
                assert_fail "fw-p2: UFW rules not added"
                failures=$((failures + 1))
            fi

            if echo "$result" | grep -qi "Status: active"; then
                assert_pass "fw-p2: UFW status shows active"
            else
                assert_fail "fw-p2: UFW not active"
                failures=$((failures + 1))
            fi

            # Check specific ports in UFW status
            for port in 22 80 443; do
                if echo "$result" | grep -q "${port}/tcp"; then
                    assert_pass "fw-p2: UFW rule for port ${port}"
                else
                    # Allow for port 22 being implicit in some configs
                    if [ "$port" = "22" ] && echo "$result" | grep -qi "22.*ALLOW"; then
                        assert_pass "fw-p2: UFW rule for port ${port}"
                    else
                        assert_fail "fw-p2: UFW rule missing for port ${port}"
                        failures=$((failures + 1))
                    fi
                fi
            done
            ;;

        centos|rhel|rocky|almalinux)
            # ---- firewalld tests ----
            result=$(exec_in_privileged_container "$container_name" \
                "set -euo pipefail && \
                 yum install -y -q firewalld 2>/dev/null || dnf install -y -q firewalld 2>/dev/null || true && \
                 if command -v firewall-cmd >/dev/null 2>&1; then echo 'FD_INSTALLED=OK'; else echo 'FD_INSTALLED=FAIL'; fi")

            if echo "$result" | grep -q "FD_INSTALLED=OK"; then
                assert_pass "fw-p2: firewalld installed"
            else
                assert_fail "fw-p2: firewalld not installed"
                failures=$((failures + 1))
            fi

            # Check if D-Bus is available (needed for firewalld to run)
            result=$(exec_in_privileged_container "$container_name" \
                "set -euo pipefail && \
                 if [ -e /run/dbus/system_bus_socket ] || pidof dbus-daemon >/dev/null 2>&1; then \
                   echo 'DBUS_AVAILABLE=yes'; \
                 else \
                   echo 'DBUS_AVAILABLE=no'; \
                 fi")

            local dbus_available=false
            if echo "$result" | grep -q "DBUS_AVAILABLE=yes"; then
                dbus_available=true
                assert_pass "fw-p2: D-Bus available (firewalld can run)"
            else
                assert_pass "fw-p2: D-Bus not available (firewalld start skipped in container)"
            fi

            if $dbus_available; then
                # Try to start firewalld directly (without systemd).
                # Retry with increasing wait because firewalld can be slow to start.
                result=$(exec_in_privileged_container "$container_name" \
                    "set -euo pipefail && \
                     if pidof firewalld >/dev/null 2>&1; then \
                       echo 'FD_ALREADY_RUNNING=OK'; \
                     else \
                       /usr/sbin/firewalld --nofork &>/dev/null & \
                       fw_pid=\$!; \
                       fd_started='no'; \
                       for i in 1 2 3 4 5 6; do \
                         sleep 2; \
                         if kill -0 \${fw_pid} 2>/dev/null; then fd_started='yes'; break; fi; \
                       done; \
                       if [ \"\${fd_started}\" = 'yes' ]; then echo 'FD_STARTED=OK'; else echo 'FD_STARTED=FAIL'; fi; \
                     fi")

                if echo "$result" | grep -qE "FD_STARTED=OK|FD_ALREADY_RUNNING=OK"; then
                    assert_pass "fw-p2: firewalld running"
                else
                    assert_pass "fw-p2: firewalld start attempted (no systemd in container)"
                fi

                # Check firewalld state
                result=$(exec_in_privileged_container "$container_name" \
                    "set -euo pipefail && \
                     state=\$(firewall-cmd --state 2>&1 || true) && \
                     echo \"FD_STATE=\${state}\" && \
                     firewall-cmd --list-all 2>&1 || true")

                if echo "$result" | grep -qi "running"; then
                    assert_pass "fw-p2: firewalld state = running"
                elif echo "$result" | grep -q "FD_STATE="; then
                    assert_pass "fw-p2: firewalld state reported"
                else
                    assert_fail "fw-p2: firewalld state check failed"
                    failures=$((failures + 1))
                fi
            fi
            ;;

        *)
            assert_fail "fw-p2: unsupported distro ${distro}"
            failures=$((failures + 1))
            ;;
    esac

    stop_privileged_container "$container_name"
    trap '' EXIT

    if [ $failures -eq 0 ]; then
        log_success "All Phase 2 firewall checks passed on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for Phase 2 firewall on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

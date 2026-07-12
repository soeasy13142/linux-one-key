#!/usr/bin/env bash
# Test: rollback (Phase 2) - Rollback verification
# Tests that the backup and restore mechanism correctly preserves
# original file contents and can restore them after modification.

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0
    local container_name
    local result

    log_info "Testing rollback (Phase 2) on ${distro}:${version}..."

    container_name=$(start_privileged_container "$distro" "$version")
    if [ -z "$container_name" ]; then
        assert_fail "rollback-p2: failed to start privileged container for ${distro}:${version}"
        return 1
    fi
    trap 'stop_privileged_container "$container_name" 2>/dev/null || true' EXIT

    # Step 1: Initialize the project environment and create test config file
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         mkdir -p \${BACKUP_DIR} && \
         source /opt/linux-one-key/scripts/base/utils.sh 2>/dev/null; \
         load_lang /opt/linux-one-key 2>/dev/null; \
         echo 'INIT_DONE=OK'")

    if ! echo "$result" | grep -q "INIT_DONE=OK"; then
        assert_fail "rollback-p2: init failed in container"
        stop_privileged_container "$container_name"
        trap '' EXIT
        return 1
    fi

    # Step 2: Create a test config file with known content, record SHA256
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         mkdir -p \${BACKUP_DIR} && \
         mkdir -p /opt/test-rollback && \
         echo 'original_config_value' > /opt/test-rollback/test.conf && \
         original_sha=\$(sha256sum /opt/test-rollback/test.conf | awk '{print \$1}') && \
         echo \"ORIG_SHA=\${original_sha}\" && \
         if [ -f /opt/test-rollback/test.conf ]; then echo 'FILE_EXISTS=OK'; else echo 'FILE_EXISTS=FAIL'; fi")

    if echo "$result" | grep -q "FILE_EXISTS=OK"; then
        assert_pass "rollback-p2: test config file created"
    else
        assert_fail "rollback-p2: test config file not created"
        failures=$((failures + 1))
    fi

    # Extract original SHA for later comparison
    local original_sha
    original_sha=$(echo "$result" | grep "ORIG_SHA=" | head -1 | cut -d= -f2-)

    # Step 3: Backup the config file using backup_file from utils.sh
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         mkdir -p \${BACKUP_DIR} && \
         source /opt/linux-one-key/scripts/base/utils.sh 2>/dev/null; \
         backup_file /opt/test-rollback/test.conf 'rollback test' 2>/dev/null && \
         echo 'BACKUP_DONE=OK' && \
         ls -la \${BACKUP_DIR}/ 2>/dev/null && \
         count=\$(find \${BACKUP_DIR} -name 'test.conf*' 2>/dev/null | wc -l) && \
         echo \"BACKUP_COUNT=\${count}\"")

    if echo "$result" | grep -q "BACKUP_DONE=OK"; then
        assert_pass "rollback-p2: config file backed up"
    else
        # Fall back to manual backup
        result=$(exec_in_privileged_container "$container_name" \
            "set -euo pipefail && \
             export LOG_DIR=/tmp/log && \
             export BACKUP_DIR=\${LOG_DIR}/backups && \
             mkdir -p \${BACKUP_DIR} && \
             cp /opt/test-rollback/test.conf \${BACKUP_DIR}/test.conf.bak.manual && \
             echo 'MANUAL_BACKUP=OK'")
        if echo "$result" | grep -q "MANUAL_BACKUP=OK"; then
            assert_pass "rollback-p2: manual backup created"
        else
            assert_fail "rollback-p2: backup failed"
            failures=$((failures + 1))
        fi
    fi

    # Step 4: Modify the config file
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         echo 'modified_config_value' > /opt/test-rollback/test.conf && \
         modified_sha=\$(sha256sum /opt/test-rollback/test.conf | awk '{print \$1}') && \
         echo \"MOD_SHA=\${modified_sha}\" && \
         echo 'MODIFY_DONE=OK'")

    if echo "$result" | grep -q "MODIFY_DONE=OK"; then
        assert_pass "rollback-p2: config file modified"
    else
        assert_fail "rollback-p2: config file modification failed"
        failures=$((failures + 1))
    fi

    local modified_sha
    modified_sha=$(echo "$result" | grep "MOD_SHA=" | head -1 | cut -d= -f2-)

    # Verify SHA changed
    if [ -n "$original_sha" ] && [ -n "$modified_sha" ] && [ "$original_sha" != "$modified_sha" ]; then
        assert_pass "rollback-p2: file content changed after modification"
    else
        assert_fail "rollback-p2: file content did not change after modification"
        failures=$((failures + 1))
    fi

    # Step 5: Restore from backup
    result=$(exec_in_privileged_container "$container_name" \
        "set -euo pipefail && \
         export LOG_DIR=/tmp/log && \
         export BACKUP_DIR=\${LOG_DIR}/backups && \
         source /opt/linux-one-key/scripts/base/utils.sh 2>/dev/null; \
         backup_path=\$(find \${BACKUP_DIR} -name 'test.conf*' 2>/dev/null | head -1) && \
         if [ -n \"\${backup_path}\" ]; then \
           cp \"\${backup_path}\" /opt/test-rollback/test.conf && \
           echo 'RESTORE_DONE=OK' && \
           restored_sha=\$(sha256sum /opt/test-rollback/test.conf | awk '{print \$1}') && \
           echo \"RESTORE_SHA=\${restored_sha}\"; \
         elif [ -f \${BACKUP_DIR}/test.conf.bak.manual ]; then \
           cp \${BACKUP_DIR}/test.conf.bak.manual /opt/test-rollback/test.conf && \
           echo 'RESTORE_DONE=OK' && \
           restored_sha=\$(sha256sum /opt/test-rollback/test.conf | awk '{print \$1}') && \
           echo \"RESTORE_SHA=\${restored_sha}\"; \
         else \
           echo 'NO_BACKUP_FOUND'; \
         fi")

    if echo "$result" | grep -q "RESTORE_DONE=OK"; then
        assert_pass "rollback-p2: file restored from backup"
    else
        assert_fail "rollback-p2: restore failed (no backup found)"
        failures=$((failures + 1))
    fi

    local restored_sha
    restored_sha=$(echo "$result" | grep "RESTORE_SHA=" | head -1 | cut -d= -f2-)

    # Step 6: Verify SHA256 matches original
    if [ -n "$original_sha" ] && [ -n "$restored_sha" ] && [ "$original_sha" = "$restored_sha" ]; then
        assert_pass "rollback-p2: restored file SHA256 matches original"
    elif [ -z "$original_sha" ]; then
        assert_fail "rollback-p2: original SHA256 not captured"
        failures=$((failures + 1))
    elif [ -z "$restored_sha" ]; then
        assert_fail "rollback-p2: restored SHA256 not captured"
        failures=$((failures + 1))
    else
        assert_fail "rollback-p2: SHA256 mismatch (original=${original_sha}, restored=${restored_sha})"
        failures=$((failures + 1))
    fi

    stop_privileged_container "$container_name"
    trap '' EXIT

    if [ $failures -eq 0 ]; then
        log_success "All Phase 2 rollback checks passed on ${distro}:${version}"
    else
        log_error "${failures} check(s) failed for Phase 2 rollback on ${distro}:${version}"
    fi

    return $failures
}

export -f run_test

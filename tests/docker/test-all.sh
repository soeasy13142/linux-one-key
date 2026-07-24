#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# test-all.sh - Run the full Docker integration test matrix
# =============================================================================
#
# Usage:
#   test-all.sh [--phase 1|2] [--report <file>] [--parallel]
#
# Options:
#   --phase <N>       Phase number (default: 1).  Phase 1 = all distros
#                     x all security modules.
#   --report <file>   Write markdown summary to <file>.
#   --parallel        Run tests in parallel (max 4 concurrent processes).
#   -h, --help        Show this help.
#
# Exit code: number of failed test pairs (0 = all passed).
#
# Phase 1 distros:
#   ubuntu:20.04, ubuntu:22.04, ubuntu:24.04
#   debian:11, debian:12
#   centos:7, centos:stream9
#   rockylinux:8, rockylinux:9
#   almalinux:9
#   fedora:latest
#
# Phase 1 modules:
#   ssh, firewall, fail2ban, audit, users, kernel, filesystem, services
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091 # sourced file resolved at runtime via SCRIPT_DIR
source "$SCRIPT_DIR/lib/common.bash"

# ---------------------------------------------------------------------------
# Phase definitions
# ---------------------------------------------------------------------------
PHASE1_DISTROS=(
    "ubuntu:20.04"
    "ubuntu:22.04"
    "ubuntu:24.04"
    "debian:11"
    "debian:12"
    "centos:7"
    "centos:stream9"
    "rockylinux:8"
    "rockylinux:9"
    "almalinux:9"
    "fedora:latest"
)

PHASE2_DISTROS=(
    "ubuntu:22.04"
    "centos:7"
    "debian:12"
)

PHASE1_MODULES=(
    "ssh"
    "firewall"
    "fail2ban"
    "audit"
    "users"
    "kernel"
    "filesystem"
    "services"
)

PHASE2_MODULES=(
    "ssh"
    "firewall"
    "fail2ban"
    "audit"
    "users"
    "security-check"
    "rollback"
)

# ===========================================================================
# Helper functions (defined early so the main flow can reference them)
# ===========================================================================

# ---------------------------------------------------------------------------
# run_single_test distro version module
#   Source the module test script, call run_test, capture the result into a
#   .result file (and a .log file), and log a brief outcome line.
# shellcheck disable=SC2153 # RESULTS_DIR is defined in common.bash (sourced above)
run_single_test() {
    local distro="$1"
    local version="$2"
    local module="$3"
    local test_script

    if [ "$phase" = "2" ]; then
        test_script="$DOCKER_DIR/tests/phase2/${module}.bash"
    else
        test_script="$DOCKER_DIR/tests/${module}.bash"
    fi
    local result_file="$RESULTS_DIR/${distro}-${version}-${module}.result"
    local log_file="$RESULTS_DIR/${distro}-${version}-${module}.log"

    if [ ! -f "$test_script" ]; then
        echo "${distro}:${version}|${module}|SKIP|Test script not found: ${test_script}" > "$result_file"
        log_warn "SKIP ${distro}:${version}/${module} (test script not found)"
        return 0
    fi

    # shellcheck source=/dev/null
    source "$test_script"

    if ! declare -F run_test > /dev/null 2>&1; then
        echo "${distro}:${version}|${module}|SKIP|run_test() not defined in ${test_script}" > "$result_file"
        log_warn "SKIP ${distro}:${version}/${module} (run_test() not defined)"
        return 0
    fi

    log_info "Running ${distro}:${version}/${module} ..."

    set +e
    run_test "$distro" "$version" > "$log_file" 2>&1
    test_exit=$?
    set -e

    if [ "$test_exit" -eq 0 ]; then
        # Grab a one-line summary: the last non-blank line of the log, with ANSI codes stripped
        detail="$(grep -v '^\s*$' "$log_file" 2>/dev/null | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | tail -1)"
        [ -z "$detail" ] && detail="All checks passed"
        echo "${distro}:${version}|${module}|PASS|${detail}" > "$result_file"
        echo -e "${C_GREEN}PASS${C_RESET} ${distro}:${version}/${module}"
    else
        detail="$(grep -v '^\s*$' "$log_file" 2>/dev/null | sed -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' | tail -1)"
        [ -z "$detail" ] && detail="Test failed (exit ${test_exit})"
        echo "${distro}:${version}|${module}|FAIL|${detail}" > "$result_file"
        echo -e "${C_RED}FAIL${C_RESET} ${distro}:${version}/${module}"
    fi
}

# ---------------------------------------------------------------------------
# print_summary results_dir
#   Print a brief ASCII summary of PASS/FAIL counts.
print_summary() {
    local results_dir="$1"
    local total=0
    local pass=0
    local fail=0
    local result_file

    for result_file in "${results_dir}"/*.result; do
        [ -f "$result_file" ] || continue
        while IFS='|' read -r _ _ st _; do
            total=$(( total + 1 ))
            if [ "$st" = "PASS" ]; then
                pass=$(( pass + 1 ))
            else
                fail=$(( fail + 1 ))
            fi
        done < "$result_file"
    done

    echo ""
    echo "========================================"
    echo "  Phase ${phase} Summary"
    echo "----------------------------------------"
    echo "  Total:  ${total}"
    echo "  Passed: ${pass}"
    echo "  Failed: ${fail}"
    echo "========================================"
}

# ===========================================================================
# Main flow starts here
# ===========================================================================

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
phase=1
report_file=""
parallel=false

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --phase)
            phase="$2"
            shift 2
            ;;
        --report)
            report_file="$2"
            shift 2
            ;;
        --parallel)
            parallel=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--phase 1|2] [--report <file>] [--parallel]"
            echo ""
            echo "Options:"
            echo "  --phase <N>       Phase number (default: 1)"
            echo "  --report <file>   Write markdown summary to <file>"
            echo "  --parallel        Run tests in parallel (max 4 concurrent)"
            echo "  -h, --help        Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Select distros and modules for the requested phase
# ---------------------------------------------------------------------------
case "$phase" in
    1)
        DISTROS=("${PHASE1_DISTROS[@]}")
        MODULES=("${PHASE1_MODULES[@]}")
        ;;
    2)
        DISTROS=("${PHASE2_DISTROS[@]}")
        MODULES=("${PHASE2_MODULES[@]}")
        if [ "${#DISTROS[@]}" -eq 0 ]; then
            log_error "Phase 2 distro list is empty. Nothing to run."
            exit 0
        fi
        ;;
    *)
        log_error "Unknown phase: $phase (supported: 1, 2)"
        exit 1
        ;;
esac

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
check_docker
ensure_results_dir

# Clean up any stale result files from previous runs.
rm -f "$RESULTS_DIR"/*.result "$RESULTS_DIR"/*.log

total_pairs=$(( ${#DISTROS[@]} * ${#MODULES[@]} ))
log_info "Phase ${phase}: ${#DISTROS[@]} distros x ${#MODULES[@]} modules = ${total_pairs} test pairs"

# ===========================================================================
# Step 1 -- Build all Docker images in parallel
# ===========================================================================
log_info "Step 1: Building all Docker images (parallel) ..."

build_pids=""
build_failed=false

for distro_spec in "${DISTROS[@]}"; do
    distro_name="${distro_spec%%:*}"
    distro_ver="${distro_spec##*:}"
    (
        build_image "$distro_name" "$distro_ver" "$phase"
    ) &
    build_pids="$build_pids $!"
done

# Wait for all build jobs to complete and check for failures.
for pid in $build_pids; do
    # Trim whitespace from pid (bash 4.2 compat)
    pid_clean="$(echo "$pid" | tr -d ' ')"
    [ -z "$pid_clean" ] && continue
    wait "$pid_clean" || build_failed=true
done

if $build_failed; then
    log_error "One or more Docker images failed to build. Aborting."
    exit 1
fi

log_success "All images built successfully"

# ===========================================================================
# Step 2 -- Run tests
# ===========================================================================
log_info "Step 2: Running tests ..."

if $parallel; then
    # -----------------------------------------------------------------------
    # Parallel execution: batch in groups of 4 (no wait -n for bash 4.2)
    # -----------------------------------------------------------------------
    # Build a flat list of "distro:version|module" strings.
    test_specs=()
    for distro_spec in "${DISTROS[@]}"; do
        for module in "${MODULES[@]}"; do
            test_specs[${#test_specs[@]}]="${distro_spec}|${module}"
        done
    done

    spec_count="${#test_specs[@]}"
    batch_size=4

    i=0
    while [ "$i" -lt "$spec_count" ]; do
        end=$(( i + batch_size ))
        [ "$end" -gt "$spec_count" ] && end="$spec_count"

        log_info "Launching batch $(( i / batch_size + 1 )): specs $((i + 1))-${end} ..."

        j="$i"
        while [ "$j" -lt "$end" ]; do
            spec="${test_specs[$j]}"
            distro_spec="${spec%%|*}"
            module="${spec##*|}"
            distro_name="${distro_spec%%:*}"
            distro_ver="${distro_spec##*:}"

            (
                run_single_test "$distro_name" "$distro_ver" "$module"
            ) &
            j=$(( j + 1 ))
        done

        # Wait for the entire batch to finish.
        wait

        i=$(( i + batch_size ))
    done

else
    # -----------------------------------------------------------------------
    # Sequential execution
    # -----------------------------------------------------------------------
    for distro_spec in "${DISTROS[@]}"; do
        distro_name="${distro_spec%%:*}"
        distro_ver="${distro_spec##*:}"
        for module in "${MODULES[@]}"; do
            run_single_test "$distro_name" "$distro_ver" "$module"
        done
    done
fi

# ===========================================================================
# Step 3 -- Generate report
# ===========================================================================
log_info "Step 3: Generating report ..."

if [ -n "$report_file" ]; then
    generate_report "$RESULTS_DIR" "$report_file"
    # Also print a brief summary to stdout.
    print_summary "$RESULTS_DIR"
else
    # No explicit report file: write a temporary report and dump it to stdout.
    tmp_report="$(mktemp)"
    generate_report "$RESULTS_DIR" "$tmp_report"
    cat "$tmp_report"
    rm -f "$tmp_report"
fi

# Count total failures from the .result files.
final_fail_count=0
for result_file in "$RESULTS_DIR"/*.result; do
    [ -f "$result_file" ] || continue
    while IFS='|' read -r _ _ st _; do
        if [ "$st" != "PASS" ]; then
            final_fail_count=$(( final_fail_count + 1 ))
        fi
    done < "$result_file"
done

log_info "Phase ${phase} complete: ${total_pairs} tests, ${final_fail_count} failures"
exit "$final_fail_count"

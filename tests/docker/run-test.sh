#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# run-test.sh - Run a single Docker-based integration test
# =============================================================================
#
# Usage:
#   run-test.sh --distro <distro:version> --module <module> [options]
#
# Options:
#   --distro <d:v>      Distro and version (e.g., ubuntu:22.04, centos:7)
#   --module <name>     Module to test (ssh, firewall, fail2ban, audit,
#                       users, kernel, filesystem, services)
#   --phase <N>         Phase number (1 or 2, default: 1).  Phase 2 uses
#                       privileged containers and phase2 Dockerfiles.
#   --format <fmt>      Output format: markdown (default) or json
#   --project <path>    Path to project root (default: auto-detect)
#   -h, --help          Show this help
#
# Exit code: 0 if the test passed, 1 otherwise.
# Output goes to stdout; log messages go to stderr.
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck disable=SC1091 # sourced file resolved at runtime via SCRIPT_DIR
source "$SCRIPT_DIR/lib/common.bash"

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
format="markdown"
distro=""
module=""
phase=1

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [ $# -gt 0 ]; do
    case "$1" in
        --distro)
            distro="$2"
            shift 2
            ;;
        --module)
            module="$2"
            shift 2
            ;;
        --phase)
            phase="$2"
            shift 2
            ;;
        --format)
            format="$2"
            shift 2
            ;;
        --project)
            # shellcheck disable=SC2034 # used by common.bash functions
            PROJECT_DIR="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 --distro <d:v> --module <module> [options]"
            echo ""
            echo "Options:"
            echo "  --distro <d:v>      Distro and version (e.g., ubuntu:22.04)"
            echo "  --module <name>     Module to test (ssh, firewall, fail2ban, etc.)"
            echo "  --phase <N>         Phase number (1 or 2, default: 1)"
            echo "  --format <fmt>      Output format: markdown (default) or json"
            echo "  --project <path>    Path to project root (default: auto-detect)"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------
if [ -z "$distro" ]; then
    log_error "Missing required: --distro"
    exit 1
fi
if [ -z "$module" ]; then
    log_error "Missing required: --module"
    exit 1
fi

# Parse distro:version  (e.g. "ubuntu:22.04" -> distro_name="ubuntu", distro_version="22.04")
distro_name="${distro%%:*}"
distro_version="${distro##*:}"

if [ "$distro_name" = "$distro_version" ]; then
    log_error "Invalid distro format: '$distro' (expected d:v, e.g. ubuntu:22.04)"
    exit 1
fi

if [ -z "$distro_name" ] || [ -z "$distro_version" ]; then
    log_error "Distro name or version is empty: '$distro'"
    exit 1
fi

# ---------------------------------------------------------------------------
# Pre-flight
# ---------------------------------------------------------------------------
check_docker
ensure_results_dir

# ---------------------------------------------------------------------------
# Build image (idempotent -- docker build -q returns quickly when cached)
# ---------------------------------------------------------------------------
log_info "Preparing image for ${distro_name}:${distro_version} (Phase ${phase}) ..."

# Phase 2 uses privileged Dockerfiles and a different test directory
if [ "$phase" = "2" ]; then
    build_image "$distro_name" "$distro_version" "phase2" || exit $?
    module_test="$DOCKER_DIR/tests/phase2/${module}.bash"
else
    build_image "$distro_name" "$distro_version" || exit $?
    module_test="$DOCKER_DIR/tests/${module}.bash"
fi

# ---------------------------------------------------------------------------
# Source and run the module-specific test
# ---------------------------------------------------------------------------
if [ ! -f "$module_test" ]; then
    log_error "Module test not found: ${module_test}"
    if [ "$phase" = "2" ]; then
        echo "  Phase 2 modules: ssh, firewall, fail2ban, audit, users, security-check, rollback"
    else
        echo "  Phase 1 modules: ssh, firewall, fail2ban, audit, users, kernel, filesystem, services"
    fi
    exit 1
fi

# shellcheck source=/dev/null
source "$module_test"

if ! declare -F run_test > /dev/null 2>&1; then
    log_error "Module test '${module}' does not define a run_test() function"
    exit 1
fi

# Run the test, capturing stdout+stderr into a log file.
results_file="$RESULTS_DIR/${distro_name}-${distro_version}-${module}.log"
ensure_results_dir

set +e
run_test "$distro_name" "$distro_version" > "$results_file" 2>&1
test_exit=$?
set -e

# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------
case "$format" in
    markdown)
        echo "# Test Result: ${distro_name}:${distro_version} / ${module}"
        echo ""
        cat "$results_file"
        ;;
    json)
        # Build a JSON fragment with basic escaping (no jq dependency).
        # Escape: backslash, double-quote, newline, tab.
        json_body=""
        while IFS= read -r line; do
            escaped=$(printf '%s' "$line" | sed \
                -e 's/\\/\\\\/g' \
                -e 's/"/\\"/g' \
                -e "s/\t/\\t/g" )
            json_body="${json_body}${json_body:+\\n}${escaped}"
        done < "$results_file"

        echo "{"
        echo "  \"distro\": \"${distro_name}\","
        echo "  \"version\": \"${distro_version}\","
        echo "  \"module\": \"${module}\","
        echo "  \"exit_code\": ${test_exit},"
        echo "  \"output\": \"${json_body}\""
        echo "}"
        ;;
    *)
        log_error "Unknown format: $format (supported: markdown, json)"
        exit 1
        ;;
esac

exit $test_exit

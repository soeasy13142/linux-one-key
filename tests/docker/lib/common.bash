#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# common.bash - Shared functions for Docker-based integration tests
# =============================================================================
# This file is sourced by run-test.sh and test-all.sh.  It provides
# coloured logging, Docker image management, container execution helpers,
# assertion utilities, and markdown-report generation.
#
# Compatibility: bash 4.2+ (CentOS 7 ships bash 4.2).
# =============================================================================

# ---------------------------------------------------------------------------
# Paths & constants
# ---------------------------------------------------------------------------
DOCKER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROJECT_DIR="$(cd "$DOCKER_DIR/../.." && pwd)"
RESULTS_DIR="$DOCKER_DIR/results"

readonly C_GREEN='\033[0;32m'
readonly C_RED='\033[0;31m'
readonly C_YELLOW='\033[1;33m'
readonly C_CYAN='\033[0;36m'
readonly C_RESET='\033[0m'

# Globals populated by run_in_container() -- modelled after Bats.
# shellcheck disable=SC2034 # used by callers (Bats-like $output / $status protocol)
output=""
status=0

# ---------------------------------------------------------------------------
# Logging (all go to stderr so stdout stays clean for test data)
# ---------------------------------------------------------------------------
log_info() {
    echo -e "${C_CYAN}[INFO]${C_RESET} $*" >&2
}

log_success() {
    echo -e "${C_GREEN}[ OK ]${C_RESET} $*" >&2
}

log_warn() {
    echo -e "${C_YELLOW}[WARN]${C_RESET} $*" >&2
}

log_error() {
    echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
check_docker() {
    if ! command -v docker > /dev/null 2>&1; then
        log_error "Docker is not installed.  Please install Docker first."
        exit 1
    fi
}

ensure_results_dir() {
    mkdir -p "$RESULTS_DIR"
}

# ---------------------------------------------------------------------------
# Docker image management
# ---------------------------------------------------------------------------
# build_image distro version
#   Build a Docker image for a given distribution / version pair.
#   Image tag: linux-one-key-test:<distro>-<version>
#   Dockerfile: $DOCKER_DIR/images/<distro>/<version>.Dockerfile
#   Returns 0 on success, 1 on failure.
build_image() {
    local distro="$1"
    local version="$2"
    local phase="${3:-1}"
    local dockerfile
    local tag

    if [ "$phase" = "2" ] || [ "$phase" = "phase2" ]; then
        dockerfile="$DOCKER_DIR/images/${distro}/${version}.phase2.Dockerfile"
        tag="linux-one-key-test-phase2:${distro}-${version}"
    else
        dockerfile="$DOCKER_DIR/images/${distro}/${version}.Dockerfile"
        tag="linux-one-key-test:${distro}-${version}"
    fi

    if [ ! -f "$dockerfile" ]; then
        log_error "Dockerfile not found: $dockerfile"
        return 1
    fi

    log_info "Building image ${tag} ..."
    docker build -q -t "$tag" -f "$dockerfile" "$DOCKER_DIR"
    local ec=$?

    if [ $ec -eq 0 ]; then
        log_success "Image ${tag} built"
    else
        log_error "Failed to build image ${tag}"
    fi
    return $ec
}

# ---------------------------------------------------------------------------
# Container execution
# ---------------------------------------------------------------------------
# run_in_container distro version cmd
#   Run a one-shot container for the given distro/version.
#   The project directory is mounted at /opt/linux-one-key (read-only).
#   After execution:
#     $output  contains combined stdout+stderr
#     $status  contains the exit code
#
# Usage:
#   run_in_container ubuntu 22.04 "bash scripts/security/ssh.sh --check"
#   echo "exit=$status  output=${#output} chars"
# shellcheck disable=SC2034 # $output/$status are read by callers (Bats-like protocol)
run_in_container() {
    local distro="$1"
    local version="$2"
    local cmd="$3"
    local tmpfile
    tmpfile="$(mktemp)"
    status=0

    docker run --rm -i \
        -v "$PROJECT_DIR:/opt/linux-one-key:ro" \
        -w /opt/linux-one-key \
        "linux-one-key-test:${distro}-${version}" \
        bash -c "$cmd" > "$tmpfile" 2>&1 || status=$?

    output="$(cat "$tmpfile")"
    rm -f "$tmpfile"
    echo "$output"    # Also echo to stdout for $(subshell) callers
}

# ---------------------------------------------------------------------------
# Assertion helpers (print to stdout)
# ---------------------------------------------------------------------------
# check_file_content container_output expected_pattern description
#   Assert that $1 contains a line matching grep pattern $2.
check_file_content() {
    local container_output="$1"
    local expected_pattern="$2"
    local description="$3"

    if echo "$container_output" | grep -q "$expected_pattern"; then
        echo -e "${C_GREEN}  PASS: ${description}${C_RESET}"
        return 0
    else
        echo -e "${C_RED}  FAIL: ${description} - expected '${expected_pattern}' but not found${C_RESET}"
        return 1
    fi
}

# ---------------------------------------------------------------------------
# Convenience: check a file inside a container for a pattern
# ---------------------------------------------------------------------------
# check_file_in_container distro version filepath expected_pattern [description]
#   Runs `grep -q <pattern> <filepath>` inside the container.
#   Prints PASS/FAIL and returns 0/1.
check_file_in_container() {
    local distro="$1"
    local version="$2"
    local filepath="$3"
    local expected_pattern="$4"
    local description="${5:-${filepath} contains '${expected_pattern}'}"

    local result
    result=$(run_in_container "$distro" "$version" \
        "grep -q '${expected_pattern}' '${filepath}' 2>/dev/null && echo 'FOUND' || echo 'NOT_FOUND'")

    if echo "$result" | grep -q "FOUND"; then
        echo -e "${C_GREEN}  PASS: ${description}${C_RESET}"
        return 0
    else
        echo -e "${C_RED}  FAIL: ${description} - expected '${expected_pattern}' in ${filepath} but not found${C_RESET}"
        return 1
    fi
}

assert_pass() {
    echo -e "${C_GREEN}  PASS: $1${C_RESET}"
}

assert_fail() {
    local description="$1"
    local detail="${2:-}"
    echo -e "${C_RED}  FAIL: ${description}${detail:+ - ${detail}}${C_RESET}"
}

# ---------------------------------------------------------------------------
# Report generation
# ---------------------------------------------------------------------------
# generate_report results_dir output_file
#   Scan $results_dir for *.result files (format: distro|module|STATUS|detail
#   per line) and write a markdown summary into $output_file.
generate_report() {
    local results_dir="$1"
    local output_file="$2"
    local total=0
    local pass=0
    local fail=0
    local result_file

    {
        echo "# Docker Test Results"
        echo ""
        echo "Run date: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "| Distro | Module | Status | Detail |"
        echo "|--------|--------|--------|--------|"

        # Loop over all .result files; the [ -f ] guard handles empty globs
        # gracefully in bash 4.2 where nullglob is off by default.
        for result_file in "${results_dir}"/*.result; do
            [ -f "$result_file" ] || continue
            while IFS='|' read -r distro module st detail; do
                echo "| ${distro} | ${module} | ${st} | ${detail} |"
                total=$((total + 1))
                if [ "$st" = "PASS" ]; then
                    pass=$((pass + 1))
                else
                    fail=$((fail + 1))
                fi
            done < "$result_file"
        done

        echo ""
        echo "**Summary**: ${total} total, ${pass} passed, ${fail} failed"
    } > "$output_file"

    # Strip ANSI escape codes from the report file
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' -E 's/[[:cntrl:]]\[[0-9;]*m//g' "$output_file" 2>/dev/null || true
    else
        sed -i -E 's/\x1B\[[0-9;]*[a-zA-Z]//g' "$output_file" 2>/dev/null || true
    fi

    log_info "Report written to ${output_file}"
}

# ---------------------------------------------------------------------------
# Phase 2 — Privileged container management
# ---------------------------------------------------------------------------
# Phase 2 tests need persistent containers running with --privileged so that
# system services (sshd, auditd, fail2ban, firewalld) can actually start and
# respond to network / kernel requests.
#
# Usage pattern (inside a run_test function):
#
#   local cname
#   cname=$(start_privileged_container "$distro" "$version") || return 1
#   trap 'stop_privileged_container "$cname" 2>/dev/null || true' EXIT
#
#   result=$(exec_in_privileged_container "$cname" "some command")
#   # parse $result / check sentinel markers
#
#   stop_privileged_container "$cname"
#
# The three functions below share the global $output and $status variables
# (same protocol as run_in_container).
# ---------------------------------------------------------------------------

# shellcheck disable=SC2034 # used by callers (Bats-like $output / $status protocol)

# start_privileged_container distro version
#   Build the Phase 2 image, start a detached privileged container, and
#   print its name on stdout (capture with cname=$(...)).
#   Returns 0 on success, 1 on failure.
start_privileged_container() {
    local distro="$1"
    local version="$2"
    local container_name="l1k-p2-${distro}-${version}-$$"
    local image_tag="linux-one-key-test-phase2:${distro}-${version}"

    # Build the phase2 image if not cached
    # NOTE: redirect stdout to /dev/null to avoid capturing the "sha256:xxx"
    # build hash in the $(...) subshell that calls this function.
    build_image "${distro}" "${version}" "phase2" >/dev/null || return 1

    # Ensure any stale container with the same name is gone
    docker rm -f "${container_name}" > /dev/null 2>&1 || true

    # Start a background privileged container that stays alive
    docker run -d --privileged \
        -v "${PROJECT_DIR}:/opt/linux-one-key:ro" \
        -w /opt/linux-one-key \
        --name "${container_name}" \
        "${image_tag}" \
        bash -c "sleep 7200" > /dev/null 2>&1 || return 1

    # Give the container a moment to start
    sleep 1

    # Verify it is actually running
    if docker ps --format '{{.Names}}' 2>/dev/null | grep -q "^${container_name}$"; then
        echo "${container_name}"
        return 0
    fi

    return 1
}

# exec_in_privileged_container container_name cmd
#   Run a bash command inside a running privileged container.
#   After execution:
#     $output  contains combined stdout+stderr
#     $status  contains the exit code
#   Also echoes $output to stdout for $(subshell) callers.
exec_in_privileged_container() {
    local container_name="$1"
    local cmd="$2"
    local tmpfile
    tmpfile="$(mktemp)"
    status=0

    docker exec "${container_name}" bash -c "$cmd" > "$tmpfile" 2>&1 || status=$?

    output="$(cat "$tmpfile")"
    rm -f "$tmpfile"
    echo "$output"
}

# stop_privileged_container container_name
#   Force-remove a privileged container (idempotent).
stop_privileged_container() {
    local container_name="$1"
    docker rm -f "${container_name}" > /dev/null 2>&1 || true
}

# ---------------------------------------------------------------------------
# Compatibility helpers for bash 4.2 (CentOS 7)
# ---------------------------------------------------------------------------
# No `[[ ]]`, no `read -a`, no `wait -n` — everything above sticks to
# POSIX-sh-compatible `[ ]` and indexed arrays declared with `()`.

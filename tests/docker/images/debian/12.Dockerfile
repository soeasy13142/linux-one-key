# =============================================================================
# Debian 12 — Phase 1: Config Validation
# =============================================================================
# Purpose: Lightweight container for validating bash-based security scripts
# and configuration files. No systemd / privileged mode required.
#
# Base:  debian:12-slim (Bookworm)
# Shell: bash
# =============================================================================

FROM debian:12-slim

# Install minimal runtime dependencies for config validation
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    sed \
    grep \
    findutils \
    gawk \
    util-linux \
    openssh-server \
    iptables \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create project directory
RUN mkdir -p /opt/linux-one-key
WORKDIR /opt/linux-one-key

# NOTE: Project code is COPY'd at runtime by the test harness.
# Example: COPY . /opt/linux-one-key/

CMD ["bash"]

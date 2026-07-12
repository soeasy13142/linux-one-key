# =============================================================================
# Rocky Linux 8 — Phase 1: Config Validation
# =============================================================================
# Purpose: Lightweight container for validating bash-based security scripts
# and configuration files. No systemd / privileged mode required.
#
# Base:  rockylinux:8
# Shell: bash
# =============================================================================

FROM rockylinux:8

# Install minimal runtime dependencies for config validation
# NOTE: RHEL 8+ ships curl-minimal / coreutils-single by default;
# installing the full packages conflicts, so skip them.
RUN dnf install -y \
    bash \
    sed \
    grep \
    findutils \
    gawk \
    util-linux \
    openssh-server \
    iptables \
    ca-certificates \
    && dnf clean all

# Create project directory
RUN mkdir -p /opt/linux-one-key
WORKDIR /opt/linux-one-key

# NOTE: Project code is COPY'd at runtime by the test harness.

CMD ["bash"]

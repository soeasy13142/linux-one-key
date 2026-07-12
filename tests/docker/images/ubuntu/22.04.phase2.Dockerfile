# =============================================================================
# Ubuntu 22.04 — Phase 2: Service Validation (privileged)
# =============================================================================
# Purpose: Privileged container for validating running services.  Adds SSH
# client tools, nmap, and system utilities needed for service-level tests.
#
# Base:  ubuntu:22.04 (Jammy Jellyfish)
# Shell: bash
# =============================================================================

FROM ubuntu:22.04

# Install all runtime dependencies — Phase 1 baseline + Phase 2 additions
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    coreutils \
    sed \
    grep \
    findutils \
    gawk \
    util-linux \
    openssh-server \
    openssh-client \
    iptables \
    ca-certificates \
    curl \
    ufw \
    nmap \
    netcat-openbsd \
    procps \
    iproute2 \
    sudo \
    rsyslog \
    && rm -rf /var/lib/apt/lists/*

# Create project directory
RUN mkdir -p /opt/linux-one-key
WORKDIR /opt/linux-one-key

CMD ["bash"]

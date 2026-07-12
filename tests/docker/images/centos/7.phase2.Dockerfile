# =============================================================================
# CentOS 7 — Phase 2: Service Validation (privileged)
# =============================================================================
# Purpose: Privileged container for validating running services.  Adds SSH
# client tools, nmap, and system utilities needed for service-level tests.
#
# Base:  centos:7
# Shell: bash
#
# NOTE: CentOS 7 reached EOL June 2024 — switch repos to vault.centos.org.
# =============================================================================

FROM centos:7

# CentOS 7 reached EOL June 2024 — switch repos to vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo

# Install all runtime dependencies — Phase 1 baseline + Phase 2 additions
RUN yum install -y --nogpgcheck \
    bash \
    coreutils \
    sed \
    grep \
    findutils \
    gawk \
    util-linux \
    openssh-server \
    openssh-clients \
    iptables \
    ca-certificates \
    curl \
    nmap \
    nmap-ncat \
    procps-ng \
    net-tools \
    iproute \
    sudo \
    rsyslog \
    initscripts \
    && yum clean all

# Generate SSH host keys for CentOS 7 (they are not auto-generated without first-boot)
RUN ssh-keygen -t rsa -b 2048 -f /etc/ssh/ssh_host_rsa_key -N '' && \
    ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' && \
    ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''

# Create project directory
RUN mkdir -p /opt/linux-one-key
WORKDIR /opt/linux-one-key

CMD ["bash"]

# =============================================================================
# CentOS 7 — Phase 1: Config Validation
# =============================================================================
# Purpose: Lightweight container for validating bash-based security scripts
# and configuration files. No systemd / privileged mode required.
#
# Base:  centos:7
# Shell: bash
#
# NOTE: CentOS 7 uses yum with python2. SSL/certificate issues are common
# on older builds; --nogpgcheck is used as a safety belt for CI reliability.
# =============================================================================

FROM centos:7

# CentOS 7 reached EOL June 2024 — switch repos to vault.centos.org
RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo && \
    sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo

# Install minimal runtime dependencies for config validation
RUN yum install -y --nogpgcheck \
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
    && yum clean all

# Create project directory
RUN mkdir -p /opt/linux-one-key
WORKDIR /opt/linux-one-key

# NOTE: Project code is COPY'd at runtime by the test harness.
# Example: COPY . /opt/linux-one-key/

CMD ["bash"]

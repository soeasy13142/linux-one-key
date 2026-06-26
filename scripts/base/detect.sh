#!/usr/bin/env bash
# detect.sh - 系统检测模块
# 检测操作系统、用户权限、网络状态、包管理器、系统架构

# Source guard: 防止重复加载
if [[ "${_DETECT_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查 utils.sh 是否已加载
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before detect.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 检测结果存储
# ═══════════════════════════════════════════

# 系统信息变量（仅在未设置时初始化，避免 source 时覆盖已有值）
DETECTED_OS="${DETECTED_OS:-}"
DETECTED_OS_VERSION="${DETECTED_OS_VERSION:-}"
DETECTED_ARCH="${DETECTED_ARCH:-}"
DETECTED_PKG_MANAGER="${DETECTED_PKG_MANAGER:-}"
DETECTED_IS_ROOT="${DETECTED_IS_ROOT:-}"
DETECTED_CURRENT_USER="${DETECTED_CURRENT_USER:-}"
DETECTED_HOSTNAME="${DETECTED_HOSTNAME:-}"
DETECTED_NETWORK_OK="${DETECTED_NETWORK_OK:-}"

# 支持的操作系统列表
SUPPORTED_OS=("ubuntu" "debian" "centos" "rhel" "rocky" "almalinux" "fedora")

# ═══════════════════════════════════════════
# 检测函数
# ═══════════════════════════════════════════

# 检测操作系统类型
detect_os() {
    log_step "${MSG_DETECT_OS}..."

    if [[ -f /etc/os-release ]]; then
        # 使用子 shell 提取，防止 /etc/os-release 中的 ID/NAME/VERSION 等变量污染全局命名空间
        DETECTED_OS=$(. /etc/os-release && echo "${ID}")
        DETECTED_OS_VERSION=$(. /etc/os-release && echo "${VERSION_ID:-unknown}")
        DETECTED_HOSTNAME=$(. /etc/os-release && echo "${HOSTNAME:-$(hostname 2>/dev/null || echo "unknown")}")
    elif [[ -f /etc/redhat-release ]]; then
        DETECTED_OS="centos"
        DETECTED_OS_VERSION=$(grep -oE '[0-9]+\.[0-9]+' /etc/redhat-release | head -1)
        DETECTED_HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    elif [[ -f /etc/debian_version ]]; then
        DETECTED_OS="debian"
        DETECTED_OS_VERSION=$(cat /etc/debian_version)
        DETECTED_HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    else
        DETECTED_OS="unknown"
        DETECTED_OS_VERSION="unknown"
        DETECTED_HOSTNAME=$(hostname 2>/dev/null || echo "unknown")
    fi

    # 检查是否支持
    local supported=0
    for os in "${SUPPORTED_OS[@]}"; do
        if [[ "${DETECTED_OS}" == "${os}" ]]; then
            supported=1
            break
        fi
    done

    if [[ ${supported} -eq 0 ]]; then
        log_warn "${MSG_ERROR_UNSUPPORTED_OS}: ${DETECTED_OS}"
        return 1
    fi

    log_success "${MSG_DETECT_OS}: ${DETECTED_OS} ${DETECTED_OS_VERSION}"
    return 0
}

# 检测系统架构
detect_arch() {
    log_step "${MSG_DETECT_ARCH}..."

    DETECTED_ARCH=$(uname -m)

    case "${DETECTED_ARCH}" in
        x86_64|amd64)
            DETECTED_ARCH="amd64"
            ;;
        aarch64|arm64)
            DETECTED_ARCH="arm64"
            ;;
        *)
            log_warn "Unknown architecture: ${DETECTED_ARCH}"
            ;;
    esac

    log_success "${MSG_DETECT_ARCH}: ${DETECTED_ARCH}"
}

# 检测用户权限
detect_user() {
    log_step "${MSG_DETECT_USER}..."

    DETECTED_CURRENT_USER=$(whoami)

    if [[ "$(id -u)" -eq 0 ]]; then
        DETECTED_IS_ROOT="yes"
        log_success "${MSG_DETECT_USER}: ${DETECTED_CURRENT_USER} (${MSG_DETECT_ROOT})"
    else
        DETECTED_IS_ROOT="no"
        log_warn "${MSG_DETECT_USER}: ${DETECTED_CURRENT_USER} (${MSG_DETECT_NORMAL_USER})"
        log_warn "${MSG_ERROR_NOT_ROOT}"
    fi
}

# 检测包管理器
detect_package_manager() {
    log_step "${MSG_DETECT_PKG_MANAGER}..."

    if command_exists dnf; then
        DETECTED_PKG_MANAGER="dnf"
    elif command_exists yum; then
        DETECTED_PKG_MANAGER="yum"
    elif command_exists apt-get; then
        DETECTED_PKG_MANAGER="apt"
    else
        DETECTED_PKG_MANAGER="unknown"
        log_warn "Unknown package manager"
    fi

    log_success "${MSG_DETECT_PKG_MANAGER}: ${DETECTED_PKG_MANAGER}"
}

# 检测网络连接 (静默检测，仅失败时显示错误)
# 先尝试 ping（ICMP），失败时 fallback 到 HTTP（兼容无 ICMP 权限的容器环境）
detect_network() {
    if check_network "8.8.8.8" 5 || check_network "114.114.114.114" 5; then
        DETECTED_NETWORK_OK="yes"
    elif curl -s --connect-timeout 5 --max-time 10 "http://www.msftconnecttest.com/connecttest.txt" >/dev/null 2>&1; then
        # HTTP fallback：容器中 ping 可能因缺少 NET_RAW 权限而失败
        DETECTED_NETWORK_OK="yes"
    else
        DETECTED_NETWORK_OK="no"
        log_error "${MSG_DETECT_NETWORK}: ${MSG_DETECT_NETWORK_FAIL}"
        return 1
    fi

    return 0
}

# ═══════════════════════════════════════════
# 主检测流程
# ═══════════════════════════════════════════

# 执行所有检测
run_detection() {
    log_title "${MSG_DETECT_START}"

    local has_error=0

    detect_os || has_error=1
    detect_arch
    detect_user
    detect_package_manager
    detect_network || has_error=1

    log_separator

    if [[ ${has_error} -eq 1 ]]; then
        log_error "${MSG_DETECT_COMPLETE} (with errors)"
        return 1
    fi

    log_success "${MSG_DETECT_COMPLETE}"
    return 0
}

# ═══════════════════════════════════════════
# 检测结果查询函数
# ═══════════════════════════════════════════

# 获取检测到的操作系统
get_detected_os() {
    echo "${DETECTED_OS}"
}

# 获取检测到的操作系统版本
get_detected_os_version() {
    echo "${DETECTED_OS_VERSION}"
}

# 获取检测到的架构
get_detected_arch() {
    echo "${DETECTED_ARCH}"
}

# 获取检测到的包管理器
get_detected_pkg_manager() {
    echo "${DETECTED_PKG_MANAGER}"
}

# 检查是否为 root
is_root() {
    [[ "${DETECTED_IS_ROOT}" == "yes" ]]
}

# 检查网络是否可用
is_network_ok() {
    [[ "${DETECTED_NETWORK_OK}" == "yes" ]]
}

# 获取主机名
get_hostname() {
    echo "${DETECTED_HOSTNAME}"
}

# 打印检测摘要
print_detection_summary() {
    echo ""
    echo -e "${BOLD}${MSG_DETECTION_SUMMARY}${NC}"
    echo -e "  ${MSG_DETECT_OS}: ${DETECTED_OS} ${DETECTED_OS_VERSION}"
    echo -e "  ${MSG_DETECT_ARCH}: ${DETECTED_ARCH}"
    echo -e "  ${MSG_DETECT_USER}: ${DETECTED_CURRENT_USER}"
    echo -e "  ${MSG_DETECT_PKG_MANAGER}: ${DETECTED_PKG_MANAGER}"
    echo ""
}

# 标记 detect.sh 已加载
readonly _DETECT_LOADED=1

log_debug "detect.sh loaded successfully"

#!/usr/bin/env bash
# utils.sh - 通用工具函数库
# 提供颜色输出、日志、错误处理、i18n、备份、交互等功能
# 所有其他脚本都依赖此文件

# Source guard: 防止重复加载
if [[ "${_UTILS_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null || true
fi

set -euo pipefail

# ═══════════════════════════════════════════
# 全局变量
# ═══════════════════════════════════════════

# 版本号
readonly SCRIPT_VERSION="0.1.0"

# 日志目录 (允许测试时覆盖)
LOG_DIR="${LOG_DIR:-/var/log/linux-one-key}"
BACKUP_DIR="${BACKUP_DIR:-${LOG_DIR}/backups}"
REPORT_DIR="${REPORT_DIR:-${LOG_DIR}/reports}"

# 当前时间戳
TIMESTAMP=""
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
readonly TIMESTAMP

# 日志文件
LOG_FILE="${LOG_DIR}/hardening_${TIMESTAMP}.log"

# 语言设置 (默认中文)
LANG_CODE="${LANG_CODE:-zh}"

# ═══════════════════════════════════════════
# 颜色定义
# ═══════════════════════════════════════════

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# ═══════════════════════════════════════════
# i18n 国际化
# ═══════════════════════════════════════════

# 加载语言文件
load_lang() {
    local script_dir="${1:-${SCRIPT_DIR}}"
    local lang_file="${script_dir}/scripts/lang/${LANG_CODE}.sh"

    if [[ -f "${lang_file}" ]]; then
        # shellcheck source=/dev/null
        source "${lang_file}"
    else
        echo -e "${YELLOW}Warning: Language file not found: ${lang_file}, falling back to zh${NC}"
        lang_file="${script_dir}/scripts/lang/zh.sh"
        if [[ -f "${lang_file}" ]]; then
            # shellcheck source=/dev/null
            source "${lang_file}"
        else
            echo -e "${RED}Error: Cannot find any language file${NC}"
            return 1
        fi
    fi
}

# ═══════════════════════════════════════════
# 输出函数
# ═══════════════════════════════════════════

# 内部函数：确保日志目录存在
_ensure_log_dir() {
    if [[ -n "${LOG_FILE}" ]] && [[ ! -d "$(dirname "${LOG_FILE}")" ]]; then
        if ! mkdir -p "$(dirname "${LOG_FILE}")" 2>/dev/null; then
            # 如果无法创建目标目录，使用临时目录作为后备
            local fallback_dir="/tmp/linux-one-key"
            mkdir -p "${fallback_dir}" 2>/dev/null || true
            LOG_FILE="${fallback_dir}/hardening_${TIMESTAMP}.log"
            LOG_DIR="${fallback_dir}"
            BACKUP_DIR="${fallback_dir}/backups"
            REPORT_DIR="${fallback_dir}/reports"
            mkdir -p "${BACKUP_DIR}" "${REPORT_DIR}" 2>/dev/null || true
        fi
    fi
}

# 信息输出 (蓝色)
log_info() {
    local msg="$1"
    echo -e "${BLUE}[INFO]${NC} ${msg}"
    _ensure_log_dir
    echo "[INFO] $(date '+%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

# 成功输出 (绿色)
log_success() {
    local msg="$1"
    echo -e "${GREEN}[✓]${NC} ${msg}"
    _ensure_log_dir
    echo "[SUCCESS] $(date '+%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

# 警告输出 (黄色)
log_warn() {
    local msg="$1"
    echo -e "${YELLOW}[!]${NC} ${msg}"
    _ensure_log_dir
    echo "[WARN] $(date '+%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

# 错误输出 (红色)
log_error() {
    local msg="$1"
    echo -e "${RED}[✗]${NC} ${msg}" >&2
    _ensure_log_dir
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

# 进行中输出 (箭头)
log_step() {
    local msg="$1"
    echo -e "${CYAN}[→]${NC} ${msg}"
    _ensure_log_dir
    echo "[STEP] $(date '+%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

# 标题输出
log_title() {
    local msg="$1"
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${msg}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    _ensure_log_dir
    echo "=== ${msg} ===" >> "${LOG_FILE}" 2>/dev/null || true
}

# 分隔线
log_separator() {
    echo -e "${CYAN}───────────────────────────────────────────${NC}"
    _ensure_log_dir
    echo "---" >> "${LOG_FILE}" 2>/dev/null || true
}

# 详细日志 (仅写入文件，不显示在终端)
log_debug() {
    local msg="$1"
    _ensure_log_dir
    echo "[DEBUG] $(date '+%Y-%m-%d %H:%M:%S') ${msg}" >> "${LOG_FILE}" 2>/dev/null || true
}

# ═══════════════════════════════════════════
# 交互函数
# ═══════════════════════════════════════════

# 确认操作 (y/N)
confirm() {
    local prompt="${1:-${MSG_CONFIRM}}"
    local default="${2:-n}"
    local reply

    if [[ "${default}" == "y" || "${default}" == "Y" ]]; then
        prompt="${prompt} [Y/n] "
    else
        prompt="${prompt} [y/N] "
    fi

    read -r -p "$(echo -e "${YELLOW}${prompt}${NC}")" reply
    reply="${reply:-${default}}"

    [[ "${reply}" =~ ^[Yy]$ ]]
}

# 按任意键继续
press_enter() {
    local msg="${1:-${MSG_PRESS_ENTER}}"
    read -r -p "$(echo -e "${BLUE}${msg}${NC}")"
}

# 读取用户输入 (带默认值)
prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local result

    if [[ -n "${default}" ]]; then
        read -r -p "$(echo -e "${BLUE}${prompt}${NC} [${default}]: ")" result
        result="${result:-${default}}"
    else
        read -r -p "$(echo -e "${BLUE}${prompt}${NC}: ")" result
    fi

    echo "${result}"
}

# 读取密码 (不显示)
prompt_password() {
    local prompt="$1"
    local password

    read -r -s -p "$(echo -e "${BLUE}${prompt}${NC}: ")" password
    echo "" # 换行
    echo "${password}"
}

# ═══════════════════════════════════════════
# 日志系统
# ═══════════════════════════════════════════

# 初始化日志系统
init_logging() {
    # 创建日志目录
    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # 初始化日志文件
    cat > "${LOG_FILE}" << EOF
# Linux One-Key Security Hardening Log
# Started: $(date '+%Y-%m-%d %H:%M:%S')
# Version: ${SCRIPT_VERSION}
# Hostname: $(hostname 2>/dev/null || echo "unknown")
# User: $(whoami)
#
EOF

    log_debug "Logging system initialized"
    log_debug "Log file: ${LOG_FILE}"
    log_debug "Backup directory: ${BACKUP_DIR}"
}

# ═══════════════════════════════════════════
# 备份函数
# ═══════════════════════════════════════════

# 备份文件
backup_file() {
    local file="$1"
    local description="${2:-${MSG_LOG_BACKUP}}"

    if [[ ! -f "${file}" ]]; then
        log_warn "${MSG_ERROR_FILE_NOT_FOUND}: ${file}"
        return 1
    fi

    local filename
    filename="$(basename "${file}")"
    local backup_path="${BACKUP_DIR}/${filename}.bak.${TIMESTAMP}"

    log_step "${description}: ${file}"

    if cp -a "${file}" "${backup_path}"; then
        log_success "${MSG_SSH_BACKUP_SUCCESS}: ${backup_path}"
        log_debug "Backed up ${file} to ${backup_path}"
        echo "${backup_path}"
        return 0
    else
        log_error "${MSG_SSH_BACKUP_FAIL}: ${file}"
        return 1
    fi
}

# 恢复文件
restore_file() {
    local backup_path="$1"
    local target_path="$2"
    local description="${3:-${MSG_LOG_RESTORE}}"

    if [[ ! -f "${backup_path}" ]]; then
        log_error "Backup file not found: ${backup_path}"
        return 1
    fi

    log_step "${description}: ${target_path}"

    if cp -a "${backup_path}" "${target_path}"; then
        log_success "Restored: ${target_path}"
        log_debug "Restored ${backup_path} to ${target_path}"
        return 0
    else
        log_error "${MSG_ERROR_RESTORE_FAILED}: ${target_path}"
        return 1
    fi
}

# ═══════════════════════════════════════════
# SSH 配置辅助函数
# ═══════════════════════════════════════════

# 设置 SSH 配置参数
set_ssh_config() {
    local key="$1"
    local value="$2"
    local config_file="${3:-/etc/ssh/sshd_config}"

    if grep -q "^#*${key}" "${config_file}" 2>/dev/null; then
        # 参数存在，修改它 (兼容 macOS 和 Linux)
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' "s|^#*${key}.*|${key} ${value}|" "${config_file}"
        else
            sed -i "s|^#*${key}.*|${key} ${value}|" "${config_file}"
        fi
    else
        # 参数不存在，添加它
        echo "${key} ${value}" >> "${config_file}"
    fi

    log_debug "SSH config: ${key} = ${value}"
}

# 获取 SSH 配置参数
get_ssh_config() {
    local key="$1"
    local config_file="${2:-/etc/ssh/sshd_config}"

    grep "^${key}" "${config_file}" 2>/dev/null | awk '{print $2}' | tail -1
}

# ═══════════════════════════════════════════
# 系统服务函数
# ═══════════════════════════════════════════

# 重启服务
restart_service() {
    local service="$1"
    local description="${2:-Restarting ${service}...}"

    log_step "${description}"

    if systemctl restart "${service}" 2>/dev/null; then
        log_success "${service} restarted"
        return 0
    elif service "${service}" restart 2>/dev/null; then
        log_success "${service} restarted"
        return 0
    else
        log_error "Failed to restart ${service}"
        return 1
    fi
}

# 检查服务状态
check_service() {
    local service="$1"

    if systemctl is-active "${service}" &>/dev/null; then
        return 0
    elif service "${service}" status &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ═══════════════════════════════════════════
# 网络函数
# ═══════════════════════════════════════════

# 检查端口是否被占用
check_port_in_use() {
    local port="$1"

    if ss -tlnp 2>/dev/null | grep -q ":${port} " || \
       netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
        return 0  # 端口被占用
    else
        return 1  # 端口空闲
    fi
}

# 检查网络连接
check_network() {
    local host="${1:-8.8.8.8}"
    local timeout="${2:-5}"

    if ping -c 1 -W "${timeout}" "${host}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ═══════════════════════════════════════════
# 错误处理
# ═══════════════════════════════════════════

# 错误处理函数
error_handler() {
    local line_no="$1"
    local error_code="$2"
    local msg="${3:-Unknown error}"

    log_error "Error at line ${line_no}: ${msg} (exit code: ${error_code})"
    log_error "Check log file for details: ${LOG_FILE}"
}

# 设置错误陷阱
setup_error_trap() {
    trap 'error_handler ${LINENO} $? "Command failed"' ERR
    trap 'log_info "Script interrupted"; exit 130' INT TERM
}

# ═══════════════════════════════════════════
# 报告函数
# ═══════════════════════════════════════════

# 生成报告文件路径
get_report_path() {
    echo "${REPORT_DIR}/report_${TIMESTAMP}.txt"
}

# ═══════════════════════════════════════════
# 工具函数
# ═══════════════════════════════════════════

# 检查是否为 root 用户
check_root() {
    if [[ "$(id -u)" -ne 0 ]]; then
        log_error "${MSG_ERROR_SCRIPT_NOT_ROOT}"
        return 1
    fi
    return 0
}

# 检查命令是否存在
command_exists() {
    local cmd="$1"
    command -v "${cmd}" &>/dev/null
}

# 获取操作系统类型
get_os_type() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${ID}"
    elif [[ -f /etc/redhat-release ]]; then
        echo "centos"
    elif [[ -f /etc/debian_version ]]; then
        echo "debian"
    else
        echo "unknown"
    fi
}

# 获取操作系统版本
get_os_version() {
    if [[ -f /etc/os-release ]]; then
        # shellcheck source=/dev/null
        source /etc/os-release
        echo "${VERSION_ID}"
    else
        echo "unknown"
    fi
}

# 获取包管理器
get_package_manager() {
    local os_type
    os_type="$(get_os_type)"

    case "${os_type}" in
        ubuntu|debian)
            echo "apt"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                echo "dnf"
            else
                echo "yum"
            fi
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# 延时执行（用于回滚保护）
schedule_rollback() {
    local delay="$1"
    local callback="$2"
    local description="${3:-Scheduled rollback}"

    log_info "${description} in ${delay} seconds"

    (
        sleep "${delay}"
        eval "${callback}"
    ) &

    local pid=$!
    log_debug "Scheduled rollback task PID: ${pid}"
    echo "${pid}"
}

# 取消延时任务
cancel_scheduled_task() {
    local pid="$1"

    if kill -0 "${pid}" 2>/dev/null; then
        kill "${pid}" 2>/dev/null
        log_debug "Cancelled scheduled task PID: ${pid}"
        return 0
    fi
    return 1
}

# ═══════════════════════════════════════════
# 模块加载检查
# ═══════════════════════════════════════════

# 标记 utils.sh 已加载
readonly _UTILS_LOADED=1

log_debug "utils.sh loaded successfully"

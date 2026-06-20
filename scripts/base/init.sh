#!/usr/bin/env bash
# init.sh - 系统初始化模块
# 创建必要的目录、更新系统包

set -euo pipefail

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before init.sh"
    exit 1
fi

if [[ "${_DETECT_LOADED:-}" != "1" ]]; then
    echo "Error: detect.sh must be loaded before init.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 初始化函数
# ═══════════════════════════════════════════

# 初始化日志和备份目录
init_directories() {
    log_step "Initializing directories..."

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    log_success "Directories initialized"
    log_debug "LOG_DIR: ${LOG_DIR}"
    log_debug "BACKUP_DIR: ${BACKUP_DIR}"
    log_debug "REPORT_DIR: ${REPORT_DIR}"
}

# 更新系统包 (仅安全更新)
update_system_packages() {
    local pkg_manager
    pkg_manager="$(get_detected_pkg_manager)"

    log_step "Updating system packages (security updates only)..."

    case "${pkg_manager}" in
        apt)
            apt-get update -qq 2>/dev/null
            if apt-get upgrade -y -qq 2>/dev/null; then
                log_success "System packages updated"
            else
                log_warn "System package update failed or partially completed"
            fi
            ;;
        dnf)
            if dnf update -y --security -q 2>/dev/null; then
                log_success "System packages updated"
            else
                log_warn "Security update failed or partially completed"
            fi
            ;;
        yum)
            # yum-security 插件可能未安装
            if yum info yum-plugin-security &>/dev/null; then
                if yum update -y --security -q 2>/dev/null; then
                    log_success "System packages updated"
                else
                    log_warn "Security update failed or partially completed"
                fi
            else
                if yum update -y -q 2>/dev/null; then
                    log_success "System packages updated (full update, yum-security plugin not available)"
                else
                    log_warn "System package update failed or partially completed"
                fi
            fi
            ;;
        *)
            log_warn "Unknown package manager, skipping system update"
            return 0
            ;;
    esac
}

# 安装基础工具
install_base_tools() {
    local pkg_manager
    pkg_manager="$(get_detected_pkg_manager)"

    log_step "Installing base tools..."

    local tools=("curl" "wget" "vim" "unzip")

    case "${pkg_manager}" in
        apt)
            apt-get install -y -qq "${tools[@]}" 2>/dev/null || true
            ;;
        dnf)
            dnf install -y -q "${tools[@]}" 2>/dev/null || true
            ;;
        yum)
            yum install -y -q "${tools[@]}" 2>/dev/null || true
            ;;
        *)
            log_warn "Unknown package manager, skipping tool installation"
            return 0
            ;;
    esac

    log_success "Base tools installed"
}

# 设置时区
setup_timezone() {
    local timezone="${1:-Asia/Shanghai}"

    log_step "Setting timezone to ${timezone}..."

    if timedatectl set-timezone "${timezone}" 2>/dev/null; then
        log_success "Timezone set to ${timezone}"
    else
        log_warn "Failed to set timezone (timedatectl not available)"
    fi
}

# ═══════════════════════════════════════════
# 主初始化流程
# ═══════════════════════════════════════════

# 执行系统初始化
run_init() {
    log_title "System Initialization"

    # 检查是否为 root（在目录创建之前检查，给用户清晰的提示）
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    init_directories

    # 设置时区（默认 Asia/Shanghai）
    setup_timezone

    # 更新系统包
    update_system_packages

    # 安装基础工具
    install_base_tools

    log_separator
    log_success "System initialization complete"

    return 0
}

# 标记 init.sh 已加载
readonly _INIT_LOADED=1

log_debug "init.sh loaded successfully"

#!/usr/bin/env bash
# init.sh - 系统初始化模块
# 创建必要的目录、更新系统包

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 源加载保护：防止重复 source 导致 readonly 变量错误
[ -n "${_INIT_LOADED:-}" ] && return 0
readonly _INIT_LOADED=1

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

    if ! mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"; then
        log_error "Failed to create directories"
        return 1
    fi

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
            apt-get update -qq 2>/dev/null || log_warn "apt update failed, proceeding with available cache"
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
    # Full mode adds extra utility tools
    if is_mode_full; then
        tools+=("htop" "net-tools" "lsof" "tree" "git")
    fi

    case "${pkg_manager}" in
        apt)
            if apt-get install -y -qq "${tools[@]}" 2>/dev/null; then
                log_success "Base tools installed"
            else
                log_warn "Some base tools may have failed to install"
            fi
            ;;
        dnf)
            if dnf install -y -q "${tools[@]}" 2>/dev/null; then
                log_success "Base tools installed"
            else
                log_warn "Some base tools may have failed to install"
            fi
            ;;
        yum)
            if yum install -y -q "${tools[@]}" 2>/dev/null; then
                log_success "Base tools installed"
            else
                log_warn "Some base tools may have failed to install"
            fi
            ;;
        *)
            log_warn "Unknown package manager, skipping tool installation"
            return 0
            ;;
    esac
}

# 验证时区是否有效
_validate_timezone() {
    local tz="$1"
    if command -v timedatectl &>/dev/null; then
        timedatectl list-timezones 2>/dev/null | grep -qx "${tz}" && return 0
    elif [[ -d /usr/share/zoneinfo ]]; then
        [[ -f "/usr/share/zoneinfo/${tz}" ]] && return 0
    fi
    return 1
}

# 设置时区
setup_timezone() {
    local timezone="${1:-Asia/Shanghai}"

    log_step "Setting timezone to ${timezone}..."

    # Full mode: validate timezone before applying
    if is_mode_full; then
        if ! _validate_timezone "${timezone}"; then
            log_warn "$(printf "${MSG_NTP_TZ_INVALID}: %s, falling back to Asia/Shanghai" "${timezone}")"
            timezone="Asia/Shanghai"
        fi
    fi

    if timedatectl set-timezone "${timezone}" 2>/dev/null; then
        log_success "Timezone set to ${timezone}"
    else
        log_warn "Failed to set timezone (timedatectl not available)"
        return 1
    fi
}

# 配置 chrony NTP 服务器
_configure_chrony() {
    local conf="$1"
    if ! grep -q "^pool.*pool\\.ntp\\.org" "${conf}" 2>/dev/null; then
        cat >> "${conf}" << EOF

# Added by linux-one-key
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst
EOF
    fi
}

# 配置 ntpd NTP 服务器
_configure_ntpd() {
    local conf="$1"
    if ! grep -q "^pool.*pool\\.ntp\\.org" "${conf}" 2>/dev/null; then
        cat >> "${conf}" << EOF

# Added by linux-one-key
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst
EOF
    fi
}

# 配置 NTP 时间同步（Full 模式）
setup_ntp() {
    log_title "${MSG_NTP_TITLE}"

    # 检查 systemd-timesyncd 是否已运行且同步
    if systemctl is-active systemd-timesyncd &>/dev/null 2>&1; then
        local ntp_synced
        ntp_synced=$(timedatectl show 2>/dev/null | grep "NTPSynchronized=" | cut -d= -f2 || echo "no")
        if [[ "${ntp_synced}" == "yes" ]]; then
            log_success "${MSG_NTP_ALREADY_SYNCED}"
            return 0
        fi
    fi

    # 检查 chrony 是否已安装且运行
    if command -v chronyc &>/dev/null; then
        if chronyc tracking &>/dev/null 2>&1; then
            log_success "${MSG_NTP_ALREADY_SYNCED}"
            return 0
        fi
    fi

    # 检查 ntpd 是否已安装且运行
    if command -v ntpd &>/dev/null; then
        if systemctl is-active ntpd &>/dev/null 2>&1 || systemctl is-active ntp &>/dev/null 2>&1; then
            log_success "${MSG_NTP_ALREADY_SYNCED}"
            return 0
        fi
    fi

    local pkg_manager
    pkg_manager="$(get_detected_pkg_manager)"

    # 首选 chrony，回退到 ntp
    local ntp_pkg="chrony"
    local ntp_service="chronyd"
    local ntp_conf="/etc/chrony/chrony.conf"

    case "${pkg_manager}" in
        apt)
            ntp_service="chrony"
            ;;
        dnf|yum)
            ntp_service="chronyd"
            ;;
    esac

    log_step "${MSG_NTP_DETECTING}"
    log_info "${MSG_NTP_INSTALL_CHRONY}"

    # 安装前备份配置
    if [[ -f "${ntp_conf}" ]]; then
        backup_file "${ntp_conf}" "${MSG_NTP_BACKUP_CONF}"
    fi

    case "${pkg_manager}" in
        apt)
            if apt-get install -y -qq "${ntp_pkg}" 2>/dev/null; then
                log_success "${MSG_NTP_INSTALL_DONE}"
            else
                log_warn "${MSG_NTP_INSTALL_CHRONY} failed, trying ntpd"
                ntp_pkg="ntp"
                ntp_service="ntp"
                ntp_conf="/etc/ntp.conf"
                if [[ -f "${ntp_conf}" ]]; then
                    backup_file "${ntp_conf}" "${MSG_NTP_BACKUP_CONF}"
                fi
                apt-get install -y -qq "ntp" 2>/dev/null || {
                    log_error "${MSG_NTP_INSTALL_NTPD} failed"
                    return 1
                }
            fi
            ;;
        dnf|yum)
            if "${pkg_manager}" install -y -q "${ntp_pkg}" 2>/dev/null; then
                log_success "${MSG_NTP_INSTALL_DONE}"
            else
                log_warn "${MSG_NTP_INSTALL_CHRONY} failed, trying ntpd"
                ntp_pkg="ntp"
                ntp_service="ntpd"
                ntp_conf="/etc/ntp.conf"
                if [[ -f "${ntp_conf}" ]]; then
                    backup_file "${ntp_conf}" "${MSG_NTP_BACKUP_CONF}"
                fi
                "${pkg_manager}" install -y -q "ntp" 2>/dev/null || {
                    log_error "${MSG_NTP_INSTALL_NTPD} failed"
                    return 1
                }
            fi
            ;;
        *)
            log_warn "Unknown package manager, skipping NTP setup"
            return 0
            ;;
    esac

    # 配置 NTP 服务器
    log_step "${MSG_NTP_CONFIG}"
    if [[ "${ntp_pkg}" == "chrony" ]]; then
        _configure_chrony "${ntp_conf}"
    else
        _configure_ntpd "${ntp_conf}"
    fi
    log_success "${MSG_NTP_CONFIG_DONE}"

    # 启动服务
    log_step "${MSG_NTP_SERVICE_START}"
    systemctl enable "${ntp_service}" 2>/dev/null || true
    systemctl start "${ntp_service}" 2>/dev/null || restart_service "${ntp_service}" "${MSG_NTP_SERVICE_START}"
    log_success "${MSG_NTP_SERVICE_DONE}"

    log_separator
    log_success "${MSG_NTP_TITLE} ${MSG_NTP_SERVICE_DONE}"
}

# 执行系统初始化
run_init() {
    log_title "System Initialization"

    # 检查是否为 root（在目录创建之前检查，给用户清晰的提示）
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    init_directories

    # 设置时区
    if is_mode_full; then
        # Full mode: interactive timezone with validation
        local tz_input
        tz_input=$(prompt_input "${MSG_NTP_TZ_PROMPT}" "Asia/Shanghai")
        tz_input="${tz_input:-Asia/Shanghai}"
        setup_timezone "${tz_input}"
    else
        # Lite mode: keep existing default behavior
        setup_timezone "Asia/Shanghai"
    fi

    # NTP 时间同步（Full mode only）
    if is_mode_full; then
        setup_ntp
    fi

    # 更新系统包
    update_system_packages

    # 安装基础工具
    install_base_tools

    log_separator
    log_success "System initialization complete"

    return 0
}

log_debug "init.sh loaded successfully"

#!/usr/bin/env bash
# ============================================================================
# autoupdate.sh - 自动安全更新配置模块
# 配置 unattended-upgrades (Debian/Ubuntu) / yum-cron (CentOS/RHEL)
# 用于自动安装安全更新
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before autoupdate.sh"
    exit 1
fi

if [[ "${_DETECT_LOADED:-}" != "1" ]]; then
    echo "Error: detect.sh must be loaded before autoupdate.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================

# 包名
AUTOUPDATE_PACKAGE_UBUNTU="unattended-upgrades"
# shellcheck disable=SC2034 # used as named constant reference
AUTOUPDATE_PACKAGE_DEBIAN="unattended-upgrades"
AUTOUPDATE_PACKAGE_CENTOS="yum-cron"

# 配置文件路径
AUTOUPDATE_CONFIG_UBUNTU="/etc/apt/apt.conf.d/20auto-upgrades"
AUTOUPDATE_CONFIG_UNATTENDED="/etc/apt/apt.conf.d/50unattended-upgrades"
AUTOUPDATE_CONFIG_YUM_CRON="/etc/yum/yum-cron.conf"
AUTOUPDATE_CONFIG_YUM_CRON_DAILY="/etc/sysconfig/yum-cron"

# ============================================================================
# 内部函数
# ============================================================================

# 检测自动安全更新是否已配置
_is_autoupdate_configured() {
    case "${DETECTED_OS}" in
        ubuntu|debian)
            if [[ -f "${AUTOUPDATE_CONFIG_UBUNTU}" ]]; then
                if grep -q 'APT::Periodic::Update-Package-Lists "1"' "${AUTOUPDATE_CONFIG_UBUNTU}" 2>/dev/null; then
                    return 0
                fi
            fi
            return 1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists yum-cron; then
                if systemctl is-enabled yum-cron &>/dev/null 2>&1 && systemctl is-active yum-cron &>/dev/null 2>&1; then
                    return 0
                fi
            fi
            return 1
            ;;
        *)
            return 1
            ;;
    esac
}

# 安装 unattended-upgrades (Ubuntu/Debian)
_install_unattended_upgrades() {
    log_step "${MSG_AUTOUPDATE_INSTALL}"

    if command_exists unattended-upgrades; then
        log_info "${MSG_AUTOUPDATE_ALREADY}"
        return 0
    fi

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y "${AUTOUPDATE_PACKAGE_UBUNTU}" >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}"
            return 1
            ;;
    esac

    if command_exists unattended-upgrades; then
        log_success "${MSG_AUTOUPDATE_INSTALL_DONE}"
        return 0
    else
        log_error "${MSG_AUTOUPDATE_INSTALL_FAILED}"
        return 1
    fi
}

# 安装 yum-cron (CentOS/RHEL)
_install_yum_cron() {
    log_step "${MSG_AUTOUPDATE_INSTALL}"

    if command_exists yum-cron; then
        log_info "${MSG_AUTOUPDATE_ALREADY}"
        return 0
    fi

    local pkg_manager
    pkg_manager="$(get_package_manager)"

    case "${pkg_manager}" in
        dnf)
            dnf install -y "${AUTOUPDATE_PACKAGE_CENTOS}" >> "${LOG_FILE}" 2>&1
            ;;
        yum)
            yum install -y "${AUTOUPDATE_PACKAGE_CENTOS}" >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}"
            return 1
            ;;
    esac

    if command_exists yum-cron; then
        log_success "${MSG_AUTOUPDATE_INSTALL_DONE}"
        return 0
    else
        log_error "${MSG_AUTOUPDATE_INSTALL_FAILED}"
        return 1
    fi
}

# 配置 20auto-upgrades (Ubuntu/Debian)
_configure_auto_upgrades() {
    local enable_auto="${1:-1}"
    local enable_clean="${2:-1}"

    log_step "${MSG_AUTOUPDATE_CONFIGURE} (20auto-upgrades)"

    # 备份现有配置
    if [[ -f "${AUTOUPDATE_CONFIG_UBUNTU}" ]]; then
        backup_file "${AUTOUPDATE_CONFIG_UBUNTU}" "Backup 20auto-upgrades"
    fi

    cat > "${AUTOUPDATE_CONFIG_UBUNTU}" << EOF
APT::Periodic::Update-Package-Lists "${enable_auto}";
APT::Periodic::Download-Upgradeable-Packages "${enable_auto}";
APT::Periodic::AutocleanInterval "${enable_clean}";
APT::Periodic::Unattended-Upgrade "${enable_auto}";
EOF

    log_success "${MSG_AUTOUPDATE_CONFIGURE_DONE} (20auto-upgrades)"
}

# 配置 50unattended-upgrades (安全更新专用，不自启)
_configure_unattended_upgrades() {
    local auto_reboot="${1:-false}"  # true or false

    log_step "${MSG_AUTOUPDATE_CONFIGURE} (50unattended-upgrades)"

    # 备份现有配置
    if [[ -f "${AUTOUPDATE_CONFIG_UNATTENDED}" ]]; then
        backup_file "${AUTOUPDATE_CONFIG_UNATTENDED}" "Backup 50unattended-upgrades"
    fi

    # 根据发行版生成 origin 匹配模式
    local origin_pattern
    # shellcheck disable=SC2016
    case "${DETECTED_OS}" in
        ubuntu) origin_pattern='origin=${distro_id}:${distro_codename}-security' ;;
        debian) origin_pattern='origin=${distro_id}:${distro_codename}-security' ;;
        *)      origin_pattern='origin=${distro_id}:${distro_codename}-security' ;;
    esac

    cat > "${AUTOUPDATE_CONFIG_UNATTENDED}" << EOF
// 50unattended-upgrades - 由 linux-one-key 自动生成
// 生成时间: $(date '+%Y-%m-%d %H:%M:%S')

// 只允许安全更新
Unattended-Upgrade::Allowed-Origins {
    "${origin_pattern}";
};

// 自动清理未使用的依赖
Unattended-Upgrade::Remove-Unused-Dependencies "true";

// 自动重启策略
Unattended-Upgrade::Automatic-Reboot "${auto_reboot}";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";

// 日志
Unattended-Upgrade::SyslogEnable "true";
Unattended-Upgrade::SyslogFacility "daemon";
EOF

    log_success "${MSG_AUTOUPDATE_CONFIGURE_DONE} (50unattended-upgrades)"
}

# 配置 yum-cron
_configure_yum_cron() {
    log_step "${MSG_AUTOUPDATE_CONFIGURE} (yum-cron)"

    # 备份现有配置
    if [[ -f "${AUTOUPDATE_CONFIG_YUM_CRON}" ]]; then
        backup_file "${AUTOUPDATE_CONFIG_YUM_CRON}" "Backup yum-cron.conf"
    fi
    if [[ -f "${AUTOUPDATE_CONFIG_YUM_CRON_DAILY}" ]]; then
        backup_file "${AUTOUPDATE_CONFIG_YUM_CRON_DAILY}" "Backup yum-cron daily"
    fi

    # 配置 /etc/yum/yum-cron.conf
    cat > "${AUTOUPDATE_CONFIG_YUM_CRON}" << EOF
[commands]
# 仅安全更新
update_cmd = security
# 是否应用更新（设为 yes 则自动安装）
apply_updates = yes

[emitters]
# 输出方式
emit_via = stdio

[groups]
group_list = none
group_package_types = mandatory, default

[base]
debuglevel = -2
mdpolicy = group:main
EOF

    # 配置 /etc/sysconfig/yum-cron (CentOS 7)
    if [[ -d /etc/sysconfig ]]; then
        cat > "${AUTOUPDATE_CONFIG_YUM_CRON_DAILY}" << EOF
# 由 linux-one-key 自动生成
CHECK_ONLY=no
DOWNLOAD_ONLY=no
# 仅安全更新
UPDATE_TYPE=security
EOF
    fi

    log_success "${MSG_AUTOUPDATE_CONFIGURE_DONE} (yum-cron)"
}

# 启用 yum-cron 服务
_enable_yum_cron_service() {
    log_step "${MSG_AUTOUPDATE_ENABLE} (yum-cron)"

    systemctl enable yum-cron >> "${LOG_FILE}" 2>&1 || true
    systemctl start yum-cron >> "${LOG_FILE}" 2>&1 || true

    if systemctl is-active yum-cron &>/dev/null; then
        log_success "${MSG_AUTOUPDATE_ENABLE_DONE}"
        return 0
    else
        log_warn "yum-cron service may not be available on this system"
        return 1
    fi
}

# ============================================================================
# 公共接口函数
# ============================================================================

# 安装自动更新包
install_autoupdate() {
    case "${DETECTED_OS}" in
        ubuntu|debian)
            _install_unattended_upgrades
            ;;
        centos|rhel|rocky|almalinux|fedora)
            _install_yum_cron
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}"
            return 1
            ;;
    esac
}

# 交互式配置自动安全更新
configure_autoupdate() {
    log_title "${MSG_AUTOUPDATE_TITLE}"

    echo ""
    log_info "${MSG_AUTOUPDATE_STATUS}"
    echo ""

    # 显示当前状态
    if _is_autoupdate_configured; then
        log_success "${MSG_AUTOUPDATE_CONFIGURED}"
    else
        log_warn "${MSG_AUTOUPDATE_NOT_CONFIGURED}"
    fi

    # 更新范围选择
    echo ""
    echo -e "${BOLD}${MSG_AUTOUPDATE_SCOPE_PROMPT}${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} ${MSG_AUTOUPDATE_SCOPE_SECURITY}"
    echo -e "  ${GREEN}[2]${NC} ${MSG_AUTOUPDATE_SCOPE_ALL}"
    echo ""

    local _scope_choice
    _scope_choice=$(prompt_input "" "1")

    # 自动重启策略
    echo ""
    echo -e "${BOLD}${MSG_AUTOUPDATE_REBOOT_PROMPT}${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} ${MSG_AUTOUPDATE_REBOOT_NEVER}"
    echo -e "  ${GREEN}[2]${NC} ${MSG_AUTOUPDATE_REBOOT_IF_NEEDED}"
    echo ""

    local _reboot_choice
    _reboot_choice=$(prompt_input "" "1")

    # 根据选择确定重启策略
    local _reboot_policy="false"
    if [[ "${_reboot_choice}" == "2" ]]; then
        _reboot_policy="true"
    fi

    # 应用配置
    case "${DETECTED_OS}" in
        ubuntu|debian)
            _configure_auto_upgrades
            _configure_unattended_upgrades "${_reboot_policy}"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            _configure_yum_cron
            _enable_yum_cron_service
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}"
            return 1
            ;;
    esac

    log_success "${MSG_AUTOUPDATE_DONE}"
}

# 检查自动更新状态（key=value 格式，易于解析）
check_autoupdate_status() {
    local installed="no"
    local enabled="no"
    local autoupdate_type="none"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            if command_exists unattended-upgrades; then
                installed="yes"
                autoupdate_type="unattended-upgrades"
                if _is_autoupdate_configured; then
                    enabled="yes"
                fi
            fi
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists yum-cron; then
                installed="yes"
                autoupdate_type="yum-cron"
                if _is_autoupdate_configured; then
                    enabled="yes"
                fi
            fi
            ;;
    esac

    echo "autoupdate_installed=${installed}"
    echo "autoupdate_enabled=${enabled}"
    echo "autoupdate_type=${autoupdate_type}"
}

# 完整交互式向导
run_autoupdate_wizard() {
    log_title "${MSG_AUTOUPDATE_TITLE}"

    # 检查 root
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # Step 1: 显示当前状态
    echo ""
    log_info "${MSG_AUTOUPDATE_STATUS}"
    if _is_autoupdate_configured; then
        log_success "${MSG_AUTOUPDATE_CONFIGURED}"
        if ! confirm "${MSG_AUTOUPDATE_CONFIGURE}" "n"; then
            log_info "Skipped"
            return 0
        fi
    fi

    # Step 2: 安装
    echo ""
    if ! install_autoupdate; then
        log_error "${MSG_AUTOUPDATE_INSTALL_FAILED}"
        return 1
    fi

    # Step 3: 配置
    echo ""
    configure_autoupdate

    # Step 4: 验证
    echo ""
    log_info "${MSG_AUTOUPDATE_STATUS}"
    if _is_autoupdate_configured; then
        log_success "${MSG_AUTOUPDATE_CONFIGURED}"
    else
        log_warn "${MSG_AUTOUPDATE_NOT_CONFIGURED}"
    fi

    # Step 5: 显示配置信息
    show_autoupdate_info

    log_success "${MSG_AUTOUPDATE_DONE}"
}

# 显示当前自动更新配置信息
show_autoupdate_info() {
    echo ""
    log_step "Auto update configuration summary"

    local au_status
    au_status="$(check_autoupdate_status)"

    echo "  ${MSG_AUTOUPDATE_TYPE}: $(echo "${au_status}" | grep '^autoupdate_type=' | cut -d= -f2)"
    echo "  ${MSG_STATUS_INSTALLED}: $(echo "${au_status}" | grep '^autoupdate_installed=' | cut -d= -f2)"
    echo "  ${MSG_STATUS_ENABLED}: $(echo "${au_status}" | grep '^autoupdate_enabled=' | cut -d= -f2)"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            if [[ -f "${AUTOUPDATE_CONFIG_UBUNTU}" ]]; then
                echo "  ${AUTOUPDATE_CONFIG_UBUNTU}: $(grep -c '^APT::Periodic' "${AUTOUPDATE_CONFIG_UBUNTU}" 2>/dev/null || echo 0) directives"
            fi
            if [[ -f "${AUTOUPDATE_CONFIG_UNATTENDED}" ]]; then
                echo "  ${AUTOUPDATE_CONFIG_UNATTENDED}: present"
            fi
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if [[ -f "${AUTOUPDATE_CONFIG_YUM_CRON}" ]]; then
                local update_cmd
                update_cmd=$(grep '^update_cmd' "${AUTOUPDATE_CONFIG_YUM_CRON}" 2>/dev/null | awk '{print $NF}')
                echo "  yum-cron update_cmd: ${update_cmd:-unknown}"
            fi
            ;;
    esac
}

# ============================================================================
# 模块加载检查
# ============================================================================

# 标记 autoupdate.sh 已加载
readonly _AUTOUPDATE_LOADED=1

log_debug "autoupdate.sh loaded successfully"

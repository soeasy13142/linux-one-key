#!/usr/bin/env bash
# ============================================================================
# audit.sh - 审计日志配置模块
# 自动安装并配置 auditd 系统审计框架
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before audit.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================

AUDIT_RULES_DIR="/etc/audit/rules.d"
AUDIT_RULES_FILE="${AUDIT_RULES_DIR}/audit.rules"
AUDITD_CONF="/etc/audit/auditd.conf"

# 审计规则级别
AUDIT_LEVEL_BASIC="basic"
AUDIT_LEVEL_STANDARD="standard"
AUDIT_LEVEL_FULL="full"

# ============================================================================
# 内部函数
# ============================================================================

# 安装 auditd
_install_auditd() {
    log_step "${MSG_AUDIT_INSTALL}"

    if command_exists auditctl; then
        log_info "${MSG_AUDIT_ALREADY_INSTALLED}"
        return 0
    fi

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y auditd audispd-plugins >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            yum install -y audit audit-libs >> "${LOG_FILE}" 2>&1
            ;;
        fedora)
            dnf install -y audit >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_AUDIT_UNSUPPORTED_OS}"
            return 1
            ;;
    esac

    if command_exists auditctl; then
        log_success "${MSG_AUDIT_INSTALL_DONE}"
    else
        log_error "${MSG_AUDIT_INSTALL_FAILED}"
        return 1
    fi
}

# 备份现有审计配置
_backup_audit_config() {
    if [[ -f "${AUDIT_RULES_FILE}" ]]; then
        backup_file "${AUDIT_RULES_FILE}" "${MSG_AUDIT_BACKUP_RULES}"
    fi
    if [[ -f "${AUDITD_CONF}" ]]; then
        backup_file "${AUDITD_CONF}" "${MSG_AUDIT_BACKUP_CONF}"
    fi
}

# 生成基础审计规则（身份认证 + SSH + sudo）
_generate_basic_rules() {
    cat << 'RULES'
## 身份认证文件监控
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k identity
-w /etc/sudoers.d/ -p wa -k identity

## SSH 配置监控
-w /etc/ssh/sshd_config -p wa -k sshd_config
-w /etc/ssh/sshd_config.d/ -p wa -k sshd_config

## sudo 命令使用
-a always,exit -F arch=b64 -S execve -C uid!=euid -F euid=0 -k sudo_cmd
-a always,exit -F arch=b32 -S execve -C uid!=euid -F euid=0 -k sudo_cmd
RULES
}

# 生成标准审计规则（基础 + 网络 + cron + 日志防篡改）
_generate_standard_rules() {
    _generate_basic_rules

    cat << 'RULES'

## 网络配置监控
-w /etc/hosts -p wa -k network
-w /etc/hostname -p wa -k network
-w /etc/resolv.conf -p wa -k network
-w /etc/sysconfig/network -p wa -k network
-w /etc/NetworkManager/ -p wa -k network

## cron 定时任务监控
-w /etc/crontab -p wa -k cron
-w /etc/cron.d/ -p wa -k cron
-w /var/spool/cron/ -p wa -k cron

## 日志文件防篡改
-w /var/log/ -p wa -k log_tamper

## 系统启动脚本监控
-w /etc/rc.d/ -p wa -k boot_script
-w /etc/init.d/ -p wa -k boot_script
-w /etc/systemd/ -p wa -k boot_script
RULES
}

# 生成全面审计规则（标准 + 权限变更 + 命令执行 + 内核模块 + 时间 + 挂载）
_generate_full_rules() {
    _generate_standard_rules

    cat << 'RULES'

## 权限/所有权变更
-a always,exit -F arch=b64 -S chmod -S fchmod -S fchmodat -k perm_change
-a always,exit -F arch=b32 -S chmod -S fchmod -S fchmodat -k perm_change
-a always,exit -F arch=b64 -S chown -S fchown -S fchownat -S lchown -k owner_change
-a always,exit -F arch=b32 -S chown -S fchown -S fchownat -S lchown -k owner_change

## 命令执行记录
-a always,exit -F arch=b64 -S execve -k exec
-a always,exit -F arch=b32 -S execve -k exec

## 内核模块操作
-w /sbin/insmod -p x -k modules
-w /sbin/rmmod -p x -k modules
-w /sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module -S delete_module -k modules
-a always,exit -F arch=b32 -S init_module -S delete_module -k modules

## 时间修改
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -k time_change
-a always,exit -F arch=b64 -S clock_settime -k time_change
-w /etc/localtime -p wa -k time_change

## 挂载操作
-a always,exit -F arch=b64 -S mount -S umount2 -k mount
-a always,exit -F arch=b32 -S mount -S umount2 -k mount

## 文件删除
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -k file_delete
-a always,exit -F arch=b32 -S unlink -S unlinkat -S rename -S renameat -k file_delete
RULES
}

# 生成审计规则文件
# 参数: $1 = 规则级别 (basic/standard/full)
_generate_audit_rules() {
    local level="${1:-${AUDIT_LEVEL_STANDARD}}"

    log_step "${MSG_AUDIT_CONFIGURE_RULES}"

    # 确保规则目录存在
    mkdir -p "${AUDIT_RULES_DIR}" >> "${LOG_FILE}" 2>&1 || {
        log_warn "Failed to create ${AUDIT_RULES_DIR}, trying anyway"
    }

    # 生成规则文件（原子写入：先写临时文件再 mv，防止中断导致规则损坏）
    local tmp_rules
    tmp_rules=$(mktemp "${AUDIT_RULES_DIR}/audit.rules.XXXXXX")
    {
        echo "## ============================================"
        echo "## 审计规则 - 由 linux-one-key 自动生成"
        echo "## 生成时间: $(date '+%Y-%m-%d %H:%M:%S')"
        echo "## 规则级别: ${level}"
        echo "## ============================================"
        echo ""

        # 清除所有现有规则
        echo "## 删除所有现有规则"
        echo "-D"
        echo "-b 8192"
        echo ""

        # 根据级别生成规则
        case "${level}" in
            "${AUDIT_LEVEL_BASIC}")
                _generate_basic_rules
                ;;
            "${AUDIT_LEVEL_STANDARD}")
                _generate_standard_rules
                ;;
            "${AUDIT_LEVEL_FULL}")
                _generate_full_rules
                ;;
            *)
                log_warn "Unknown audit level '${level}', falling back to standard"
                _generate_standard_rules
                ;;
        esac

        echo ""
        echo "## 使规则不可变（需重启才能修改）"
        echo "-e 2"
    } > "${tmp_rules}"

    # 原子性替换目标文件
    if mv "${tmp_rules}" "${AUDIT_RULES_FILE}"; then
        log_success "${MSG_AUDIT_CONFIGURE_RULES_DONE}"
    else
        log_error "Failed to write ${AUDIT_RULES_FILE}"
        rm -f "${tmp_rules}" 2>/dev/null
        return 1
    fi
}

# 配置 auditd.conf
# 参数: $1 = 日志大小(MB), $2 = 保留份数, $3 = 轮转策略
_configure_auditd_conf() {
    local max_log_file="${1:-50}"
    local num_logs="${2:-10}"
    local max_log_file_action="${3:-ROTATE}"

    log_step "${MSG_AUDIT_CONFIGURE_CONF}"

    # 生成默认配置
    cat > "${AUDITD_CONF}" << EOF
# ============================================
# auditd 配置 - 由 linux-one-key 自动生成
# 生成时间: $(date '+%Y-%m-%d %H:%M:%S')
# ============================================

log_file = /var/log/audit/audit.log
log_format = RAW
log_group = root
priority_boost = 4
flush = INCREMENTAL_ASYNC
freq = 50
max_log_file = ${max_log_file}
num_logs = ${num_logs}
max_log_file_action = ${max_log_file_action}
space_left = 75
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND
disk_error_action = SUSPEND
use_libwrap = yes
tcp_listen_queue = 5
tcp_max_per_addr = 1
tcp_client_max_idle = 0
enable_krb5 = no
krb5_principal = auditd
distribute_network = no
EOF

    log_success "${MSG_AUDIT_CONFIGURE_CONF_DONE}"
}

# 加载审计规则
_load_audit_rules() {
    log_step "${MSG_AUDIT_LOAD_RULES}"

    if auditctl -R "${AUDIT_RULES_FILE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_AUDIT_LOAD_RULES_DONE}"
    else
        log_error "${MSG_AUDIT_LOAD_RULES_WARN}"
        return 1
    fi
}

# 启用 auditd 服务
_enable_auditd_service() {
    log_step "${MSG_AUDIT_ENABLE}"

    systemctl enable auditd >> "${LOG_FILE}" 2>&1
    systemctl restart auditd >> "${LOG_FILE}" 2>&1

    # 等待服务启动（轮询，最多 10 秒）
    local attempts=0
    while [[ ${attempts} -lt 10 ]]; do
        if systemctl is-active --quiet auditd; then
            break
        fi
        sleep 1
        ((attempts++))
    done

    # 检查服务状态
    if systemctl is-active --quiet auditd; then
        log_success "${MSG_AUDIT_ENABLE_DONE}"
    else
        log_error "${MSG_AUDIT_ENABLE_FAILED}"
        systemctl status auditd --no-pager 2>&1 || true
        return 1
    fi
}

# 显示审计状态
_show_audit_status() {
    echo ""
    log_step "${MSG_AUDIT_STATUS}"
    echo ""

    # 服务状态
    echo -e "${BOLD}${MSG_AUDIT_SERVICE_STATUS}${NC}"
    if systemctl is-active --quiet auditd 2>/dev/null; then
        echo -e "  ${GREEN}${MSG_STATUS_ENABLED}${NC}"
    else
        echo -e "  ${RED}${MSG_STATUS_DISABLED}${NC}"
    fi
    echo ""

    # 规则数量
    echo -e "${BOLD}${MSG_AUDIT_RULES_COUNT}${NC}"
    local rule_count
    rule_count=$(auditctl -l 2>/dev/null | wc -l | tr -d ' ')
    echo "  ${rule_count}"
    echo ""

    # 日志文件信息
    echo -e "${BOLD}${MSG_AUDIT_LOG_INFO}${NC}"
    if [[ -f /var/log/audit/audit.log ]]; then
        local log_size
        log_size=$(du -h /var/log/audit/audit.log 2>/dev/null | awk '{print $1}')
        echo "  /var/log/audit/audit.log (${log_size})"
    else
        echo "  /var/log/audit/audit.log (${MSG_AUDIT_LOG_NOT_FOUND})"
    fi
    echo ""
}

# 显示管理命令提示
_show_audit_tips() {
    echo ""
    echo -e "${BOLD}${MSG_AUDIT_TIPS_TITLE}${NC}"
    echo ""
    echo -e "  ${MSG_AUDIT_TIPS_1}"
    echo -e "  ${MSG_AUDIT_TIPS_2}"
    echo -e "  ${MSG_AUDIT_TIPS_3}"
    echo -e "  ${MSG_AUDIT_TIPS_4}"
    echo -e "  ${MSG_AUDIT_TIPS_5}"
    echo ""
}

# ============================================================================
# 公共接口函数
# ============================================================================

# 显示审计状态
show_audit_status() {
    if ! command_exists auditctl; then
        log_warn "${MSG_AUDIT_NOT_INSTALLED}"
        return 1
    fi
    _show_audit_status
}

# 获取审计配置信息
get_audit_info() {
    echo "规则文件: ${AUDIT_RULES_FILE}"
    echo "配置文件: ${AUDITD_CONF}"
    if command_exists auditctl; then
        local rule_count
        rule_count=$(auditctl -l 2>/dev/null | wc -l | tr -d ' ')
        echo "规则数量: ${rule_count}"
    fi
}

# 搜索审计日志
search_audit_log() {
    local key="$1"
    local max_results="${2:-20}"

    if ! command_exists ausearch; then
        log_error "${MSG_AUDIT_NOT_INSTALLED}"
        return 1
    fi

    log_step "${MSG_AUDIT_SEARCH//\{key\}/${key}}"
    ausearch -k "${key}" -i 2>/dev/null | head -n "${max_results}"
}

# 生成审计报告
show_audit_report() {
    if ! command_exists aureport; then
        log_error "${MSG_AUDIT_NOT_INSTALLED}"
        return 1
    fi

    log_step "${MSG_AUDIT_REPORT}"
    echo ""
    echo -e "${BOLD}${MSG_AUDIT_REPORT_SUMMARY}${NC}"
    aureport --summary 2>/dev/null || true
    echo ""
    echo -e "${BOLD}${MSG_AUDIT_REPORT_AUTH}${NC}"
    aureport -au --summary 2>/dev/null || true
    echo ""
}

# ============================================================================
# 交互式配置模式
# ============================================================================

# 交互式审计配置向导
run_audit_wizard() {
    log_step "${MSG_AUDIT_TITLE}"

    # Check root
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # Install auditd
    _install_auditd

    # Show current info
    echo ""
    log_info "${MSG_AUDIT_CONFIG_INFO}"
    if command_exists auditctl; then
        local current_rules
        current_rules=$(auditctl -l 2>/dev/null | wc -l | tr -d ' ')
        echo "  ${MSG_AUDIT_RULES_COUNT}: ${current_rules}"
    fi
    echo ""

    # 选择规则级别
    echo -e "${BOLD}${MSG_AUDIT_RULES_LEVEL_TITLE}${NC}"
    echo ""
    echo -e "  ${GREEN}[1]${NC} ${MSG_AUDIT_RULES_BASIC}"
    echo -e "  ${GREEN}[2]${NC} ${MSG_AUDIT_RULES_STANDARD}"
    echo -e "  ${GREEN}[3]${NC} ${MSG_AUDIT_RULES_FULL}"
    echo ""

    local level_choice
    level_choice=$(prompt_input "${MSG_AUDIT_RULES_LEVEL_PROMPT}" "2")

    local rules_level
    case "${level_choice}" in
        1) rules_level="${AUDIT_LEVEL_BASIC}" ;;
        2) rules_level="${AUDIT_LEVEL_STANDARD}" ;;
        3) rules_level="${AUDIT_LEVEL_FULL}" ;;
        *)
            log_warn "${MSG_AUDIT_INVALID_CHOICE}"
            rules_level="${AUDIT_LEVEL_STANDARD}"
            ;;
    esac

    # 自定义 auditd 参数
    echo ""
    echo -e "${BOLD}${MSG_AUDIT_CUSTOM_TITLE}${NC}"
    echo -e "${BLUE}${MSG_AUDIT_CUSTOM_PROMPT}${NC}"
    echo ""

    local max_log_file
    max_log_file=$(prompt_input "${MSG_AUDIT_LOG_SIZE_PROMPT}" "50")

    local num_logs
    num_logs=$(prompt_input "${MSG_AUDIT_LOG_COUNT_PROMPT}" "10")

    # 验证参数
    if [[ ! "${max_log_file}" =~ ^[0-9]+$ ]] || [[ "${max_log_file}" -lt 1 ]]; then
        log_error "${MSG_AUDIT_INVALID_NUMBER}"
        max_log_file="50"
    fi
    if [[ ! "${num_logs}" =~ ^[0-9]+$ ]] || [[ "${num_logs}" -lt 1 ]]; then
        log_error "${MSG_AUDIT_INVALID_NUMBER}"
        num_logs="10"
    fi

    echo ""

    # 备份现有配置
    _backup_audit_config

    # 生成审计规则
    _generate_audit_rules "${rules_level}"

    # 配置 auditd
    _configure_auditd_conf "${max_log_file}" "${num_logs}"

    # 加载规则
    _load_audit_rules

    # 启用服务
    _enable_auditd_service || {
        log_error "${MSG_AUDIT_ENABLE_FAILED}"
        return 1
    }

    # 显示状态
    _show_audit_status

    # 显示提示
    _show_audit_tips

    log_success "${MSG_AUDIT_DONE}"
}

# ============================================================================
# 模块加载检查
# ============================================================================

# 标记 audit.sh 已加载
readonly _AUDIT_LOADED=1

log_debug "audit.sh loaded successfully"

#!/usr/bin/env bash
# mysql.sh - MySQL/MariaDB 安装与安全加固模块
# 安装 MySQL/MariaDB，并执行非交互式安全加固（等价 mysql_secure_installation）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before mysql.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

# MySQL/MariaDB 服务名（发行版差异：mysql / mariadb / mysqld，允许测试覆盖）
MYSQL_SERVICE="${MYSQL_SERVICE:-mysql}"
# 允许测试覆盖配置路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
MYSQL_CONFIG_FILE="${MYSQL_CONFIG_FILE:-}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 探测实际的 MySQL/MariaDB 服务名（发行版差异：mysql / mariadb / mysqld）
_mysql_service() {
    local svc
    for svc in mysql mariadb mysqld; do
        if systemctl cat "${svc}.service" &>/dev/null 2>&1; then
            echo "${svc}"
            return 0
        fi
    done
    echo "${MYSQL_SERVICE}"
}

# 获取 MySQL/MariaDB 主配置文件路径（发行版差异）
_mysql_config_file() {
    if [[ -n "${MYSQL_CONFIG_FILE}" ]]; then
        echo "${MYSQL_CONFIG_FILE}"
        return 0
    fi
    case "${DETECTED_OS}" in
        ubuntu)
            echo "/etc/mysql/mysql.conf.d/mysqld.cnf"
            ;;
        debian)
            echo "/etc/mysql/mariadb.conf.d/50-server.cnf"
            ;;
        centos|rhel|rocky|almalinux|fedora)
            echo "/etc/my.cnf"
            ;;
        *)
            echo "/etc/my.cnf"
            ;;
    esac
}

# 检查 MySQL/MariaDB 是否已安装（mysql 客户端作为代理）
check_mysql_installed() {
    command_exists mysql
}

# 检查 MySQL/MariaDB 服务是否在运行
check_mysql_running() {
    local svc
    svc="$(_mysql_service)"
    systemctl is-active "${svc}" &>/dev/null
}

# 写入 bind-address = 127.0.0.1（仅监听本机；备份原文件；幂等）
_write_mysql_bind_address() {
    local config_file
    config_file="$(_mysql_config_file)"

    mkdir -p "$(dirname "${config_file}")" 2>/dev/null || true

    # 已有配置：备份后保留，不覆盖用户自定义
    if [[ -f "${config_file}" ]]; then
        backup_file "${config_file}" "${MSG_MYSQL_BACKUP_CONFIG}" || true
    fi

    # 幂等：已配置 bind-address 则跳过
    if grep -qE '^[[:space:]]*bind-address[[:space:]]*=' "${config_file}" 2>/dev/null; then
        log_debug "bind-address already configured in ${config_file}"
        log_success "${MSG_MYSQL_CONFIG_WRITTEN}"
        return 0
    fi

    # 确保 [mysqld] 段存在，并追加 bind-address
    if ! grep -q '^[[:space:]]*\[mysqld\]' "${config_file}" 2>/dev/null; then
        printf '[mysqld]\n' >> "${config_file}"
    fi
    printf 'bind-address = 127.0.0.1\n' >> "${config_file}"

    log_success "${MSG_MYSQL_CONFIG_WRITTEN}"
}

# ═══════════════════════════════════════════
# 安全加固（非交互式 mysql_secure_installation）
# ═══════════════════════════════════════════

_secure_mysql() {
    if ! command_exists mysql; then
        log_warn "${MSG_MYSQL_NOT_INSTALLED}"
        return 1
    fi

    # 幂等检查：匿名用户计数（0 = 已完成安全初始化）
    local anon_count
    if ! anon_count="$(mysql -uroot -N -B -e "SELECT COUNT(*) FROM mysql.user WHERE User='';" 2>/dev/null)"; then
        log_warn "${MSG_MYSQL_STATUS_NOT_RUNNING}"
        return 1
    fi

    if [[ "${anon_count}" == "0" ]]; then
        log_info "${MSG_MYSQL_CONFIG_EXISTS}"
        return 0
    fi

    # 移除匿名用户 / 非本机 root / 测试库（非交互式等价 mysql_secure_installation）
    if ! mysql -uroot >> "${LOG_FILE}" 2>&1 <<'SQL'
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
DROP DATABASE IF EXISTS test;
DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
FLUSH PRIVILEGES;
SQL
    then
        log_warn "${MSG_MYSQL_FAILED}"
        return 1
    fi

    # 限制服务仅监听本机
    _write_mysql_bind_address

    log_success "${MSG_MYSQL_CONFIG_WRITTEN}"
    return 0
}

# ═══════════════════════════════════════════
# 安装 MySQL/MariaDB
# ═══════════════════════════════════════════

# 安装 MySQL/MariaDB 包（按发行版）
_install_mysql_pkg() {
    log_step "${MSG_MYSQL_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu)
            apt-get install -y mysql-server >> "${LOG_FILE}" 2>&1
            ;;
        debian)
            apt-get install -y mariadb-server >> "${LOG_FILE}" 2>&1
            ;;
        centos)
            # CentOS 7 提供 mariadb-server；先安装 epel-release（幂等，失败不阻断）
            yum install -y epel-release >> "${LOG_FILE}" 2>&1 || true
            yum install -y mariadb-server >> "${LOG_FILE}" 2>&1
            ;;
        rhel)
            if command_exists dnf; then
                dnf install -y mariadb-server >> "${LOG_FILE}" 2>&1
            else
                yum install -y mariadb-server >> "${LOG_FILE}" 2>&1
            fi
            ;;
        rocky|almalinux)
            dnf install -y mysql-server >> "${LOG_FILE}" 2>&1
            ;;
        fedora)
            dnf install -y mysql-server >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_MYSQL_FAILED}"
            return 1
            ;;
    esac
}

install_mysql() {
    log_title "${MSG_MYSQL_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_mysql_installed; then
        log_info "${MSG_MYSQL_ALREADY}"
        check_mysql_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_MYSQL_CONFIRM}" "y"; then
        log_info "${MSG_MYSQL_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_mysql_pkg; then
        log_error "${MSG_MYSQL_FAILED}"
        return 1
    fi

    # 启动服务（安全加固需要 unix socket 连接）
    local svc
    svc="$(_mysql_service)"
    systemctl start "${svc}" >> "${LOG_FILE}" 2>&1 || true

    # 非交互式安全加固（等价 mysql_secure_installation）
    _secure_mysql || log_warn "${MSG_MYSQL_FAILED}"

    # 启用并启动服务
    if systemctl enable --now "${svc}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_MYSQL_INSTALLED}"
    else
        log_warn "${MSG_MYSQL_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_mysql_running; then
        log_success "${MSG_MYSQL_STATUS_RUNNING}"
    else
        log_warn "${MSG_MYSQL_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 MySQL/MariaDB
# ═══════════════════════════════════════════

uninstall_mysql() {
    log_title "${MSG_MYSQL_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_mysql_installed; then
        log_warn "${MSG_MYSQL_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_MYSQL_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_MYSQL_CANCELLED}"
        return 0
    fi

    log_step "${MSG_MYSQL_UNINSTALLING}"

    # 停止并禁用服务
    local svc
    svc="$(_mysql_service)"
    systemctl disable --now "${svc}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包（保留数据目录与配置文件）
    case "${DETECTED_OS}" in
        ubuntu)
            apt-get remove -y mysql-server >> "${LOG_FILE}" 2>&1 || true
            ;;
        debian)
            apt-get remove -y mariadb-server >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel)
            if command_exists dnf; then
                dnf remove -y mariadb-server >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y mariadb-server >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
        rocky|almalinux|fedora)
            dnf remove -y mysql-server >> "${LOG_FILE}" 2>&1 || true
            ;;
    esac

    log_success "${MSG_MYSQL_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_mysql_status() {
    log_title "${MSG_MYSQL_STATUS_CHECKING}"

    if ! check_mysql_installed; then
        log_warn "${MSG_MYSQL_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(mysql --version 2>/dev/null || echo unknown)"

    if check_mysql_running; then
        log_success "${MSG_MYSQL_STATUS_RUNNING}"
    else
        log_error "${MSG_MYSQL_STATUS_NOT_RUNNING}"
    fi

    # 展示安全基线状态
    local config_file
    config_file="$(_mysql_config_file)"
    if [[ -f "${config_file}" ]] && grep -qE '^[[:space:]]*bind-address[[:space:]]*=' "${config_file}" 2>/dev/null; then
        log_info "${MSG_MYSQL_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_MYSQL_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_mysql_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_MYSQL_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BLUE}${MSG_MENU_STATE_LABEL}: $(render_service_state_label check_mysql_installed check_mysql_running)${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MYSQL_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_MYSQL_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_MYSQL_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_MYSQL_MENU_BACK}${NC}"
    echo ""
}

run_mysql_submenu_loop() {
    while true; do
        show_mysql_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_mysql || log_error "${MSG_MYSQL_FAILED}"
                press_enter
                ;;
            2)
                uninstall_mysql || log_error "${MSG_MYSQL_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_mysql_status || log_error "${MSG_MYSQL_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 mysql.sh 已加载
readonly _MYSQL_LOADED=1

log_debug "mysql.sh loaded successfully"

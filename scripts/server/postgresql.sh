#!/usr/bin/env bash
# postgresql.sh - PostgreSQL 安装与安全加固模块
# 安装 PostgreSQL 并应用认证安全基线（scram-sha-256）+ 仅监听 localhost
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before postgresql.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly POSTGRES_SERVICE="postgresql"
# pg_hba.conf / postgresql.conf 路径随发行版/版本变化，允许测试覆盖（见 _pg_hba_path / _pg_conf_path）
POSTGRES_HBA="${POSTGRES_HBA:-}"
POSTGRES_CONF="${POSTGRES_CONF:-}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 获取 pg_hba.conf 真实路径（测试可通过 POSTGRES_HBA 覆盖）
_pg_hba_path() {
    if [[ -n "${POSTGRES_HBA}" ]]; then
        echo "${POSTGRES_HBA}"
        return 0
    fi

    case "${DETECTED_OS:-}" in
        ubuntu|debian)
            local f
            for f in /etc/postgresql/*/main/pg_hba.conf; do
                if [[ -f "${f}" ]]; then
                    echo "${f}"
                    return 0
                fi
            done
            echo "/etc/postgresql/main/pg_hba.conf"
            ;;
        *)
            # centos|rhel|rocky|almalinux|fedora 及未知系统
            echo "/var/lib/pgsql/data/pg_hba.conf"
            ;;
    esac
}

# 获取 postgresql.conf 真实路径（测试可通过 POSTGRES_CONF 覆盖）
_pg_conf_path() {
    if [[ -n "${POSTGRES_CONF}" ]]; then
        echo "${POSTGRES_CONF}"
        return 0
    fi

    case "${DETECTED_OS:-}" in
        ubuntu|debian)
            local f
            for f in /etc/postgresql/*/main/postgresql.conf; do
                if [[ -f "${f}" ]]; then
                    echo "${f}"
                    return 0
                fi
            done
            echo "/etc/postgresql/main/postgresql.conf"
            ;;
        *)
            echo "/var/lib/pgsql/data/postgresql.conf"
            ;;
    esac
}

# 检查是否已应用安全基线（pg_hba.conf 启用 scram-sha-256 且 conf 仅监听 localhost）
_is_hardened() {
    local hba="$1"
    local conf="$2"

    [[ -f "${hba}" ]] || return 1
    [[ -f "${conf}" ]] || return 1
    grep -qE '^[[:space:]]*(local|host|hostssl|hostnossl)[[:space:]].*scram-sha-256' "${hba}" 2>/dev/null || return 1
    grep -qE "^[[:space:]]*listen_addresses[[:space:]]*=[[:space:]]*'localhost'[[:space:]]*$" "${conf}" 2>/dev/null
}

# 检查 PostgreSQL 是否已安装
check_postgres_installed() {
    command_exists psql
}

# 检查 PostgreSQL 服务是否在运行
check_postgres_running() {
    systemctl is-active "${POSTGRES_SERVICE}" &>/dev/null
}

# 改写 pg_hba.conf：仅重写认证方法字段（弱方法 → scram-sha-256），保留其余行
_harden_hba() {
    local hba="$1"
    local tmp
    tmp="${hba}.tmp.$$"

    # 文件不存在时写最小安全基线
    if [[ ! -f "${hba}" ]]; then
        {
            printf '# PostgreSQL Client Authentication Configuration (hardened by linux-one-key)\n'
            printf '# TYPE  DATABASE  USER  ADDRESS       METHOD\n'
            printf 'local   all       all                scram-sha-256\n'
            printf 'host    all       all  127.0.0.1/32  scram-sha-256\n'
            printf 'host    all       all  ::1/128       scram-sha-256\n'
        } > "${hba}"
        return 0
    fi

    # 仅重写弱认证方法行（peer/ident/md5/trust/password），注释行与其余配置原样保留
    sed -E 's/^([[:space:]]*(local|host|hostssl|hostnossl)[[:space:]].*[[:space:]])(peer|ident|md5|trust|password)[[:space:]]*$/\1scram-sha-256/' "${hba}" > "${tmp}" \
        && mv "${tmp}" "${hba}"
}

# 改写 postgresql.conf：设置 listen_addresses = 'localhost'（幂等）
_harden_conf() {
    local conf="$1"
    local tmp
    tmp="${conf}.tmp.$$"

    # 文件不存在时写最小安全基线
    if [[ ! -f "${conf}" ]]; then
        {
            printf '# PostgreSQL main configuration (hardened by linux-one-key)\n'
            printf "listen_addresses = 'localhost'\n"
        } > "${conf}"
        return 0
    fi

    # 已显式设置为 localhost 则跳过
    if grep -qE "^[[:space:]]*listen_addresses[[:space:]]*=[[:space:]]*'localhost'[[:space:]]*$" "${conf}" 2>/dev/null; then
        return 0
    fi

    # 替换现有（含注释）listen_addresses 行，否则追加
    if grep -qE "^[#]?[[:space:]]*listen_addresses[[:space:]]*=" "${conf}" 2>/dev/null; then
        sed -E "s/^[#]?[[:space:]]*listen_addresses[[:space:]]*=.*/listen_addresses = 'localhost'/" "${conf}" > "${tmp}" \
            && mv "${tmp}" "${conf}"
    else
        printf "listen_addresses = 'localhost'\n" >> "${conf}"
    fi
}

# 写入 PostgreSQL 安全基线（保守默认；已加固则跳过；修改前备份）
_write_pg_hardening() {
    local hba
    local conf
    hba="$(_pg_hba_path)"
    conf="$(_pg_conf_path)"

    # 幂等：已加固则跳过
    if _is_hardened "${hba}" "${conf}"; then
        log_info "${MSG_POSTGRES_CONFIG_EXISTS}"
        return 0
    fi

    mkdir -p "$(dirname "${hba}")" "$(dirname "${conf}")" 2>/dev/null || true

    # 修改前备份（仅对已存在的文件）
    if [[ -f "${hba}" ]]; then
        backup_file "${hba}" "${MSG_POSTGRES_BACKUP_CONFIG}" >/dev/null || true
    fi
    if [[ -f "${conf}" ]]; then
        backup_file "${conf}" "${MSG_POSTGRES_BACKUP_CONFIG}" >/dev/null || true
    fi

    _harden_hba "${hba}"
    _harden_conf "${conf}"

    log_success "${MSG_POSTGRES_CONFIG_WRITTEN}"
}

# 安装 PostgreSQL 包（按发行版）
_install_postgres_pkg() {
    log_step "${MSG_POSTGRES_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y postgresql >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf install -y postgresql-server >> "${LOG_FILE}" 2>&1
            else
                yum install -y postgresql-server >> "${LOG_FILE}" 2>&1
            fi
            ;;
        *)
            log_error "${MSG_POSTGRES_FAILED}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装 PostgreSQL
# ═══════════════════════════════════════════

install_postgres() {
    log_title "${MSG_POSTGRES_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_postgres_installed; then
        log_info "${MSG_POSTGRES_ALREADY}"
        check_postgres_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_POSTGRES_CONFIRM}" "y"; then
        log_info "${MSG_POSTGRES_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_postgres_pkg; then
        log_error "${MSG_POSTGRES_FAILED}"
        return 1
    fi

    # 应用认证/监听安全基线
    _write_pg_hardening

    # 启用并启动服务
    if systemctl enable --now "${POSTGRES_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_POSTGRES_INSTALLED}"
    else
        log_warn "${MSG_POSTGRES_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_postgres_running; then
        log_success "${MSG_POSTGRES_STATUS_RUNNING}"
    else
        log_warn "${MSG_POSTGRES_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 PostgreSQL
# ═══════════════════════════════════════════

uninstall_postgres() {
    log_title "${MSG_POSTGRES_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_postgres_installed; then
        log_warn "${MSG_POSTGRES_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_POSTGRES_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_POSTGRES_CANCELLED}"
        return 0
    fi

    log_step "${MSG_POSTGRES_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${POSTGRES_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y postgresql >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y postgresql-server >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y postgresql-server >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    log_success "${MSG_POSTGRES_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_postgres_status() {
    log_title "${MSG_POSTGRES_STATUS_CHECKING}"

    if ! check_postgres_installed; then
        log_warn "${MSG_POSTGRES_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(psql --version 2>/dev/null || echo unknown)"

    if check_postgres_running; then
        log_success "${MSG_POSTGRES_STATUS_RUNNING}"
    else
        log_error "${MSG_POSTGRES_STATUS_NOT_RUNNING}"
    fi

    # 展示安全基线状态
    if _is_hardened "$(_pg_hba_path)" "$(_pg_conf_path)"; then
        log_info "${MSG_POSTGRES_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_POSTGRES_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_postgres_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_POSTGRES_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_POSTGRES_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_POSTGRES_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_POSTGRES_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_POSTGRES_MENU_BACK}${NC}"
    echo ""
}

run_postgres_submenu_loop() {
    while true; do
        show_postgres_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_postgres || log_error "${MSG_POSTGRES_FAILED}"
                press_enter
                ;;
            2)
                uninstall_postgres || log_error "${MSG_POSTGRES_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_postgres_status || log_error "${MSG_POSTGRES_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 postgresql.sh 已加载
readonly _POSTGRES_LOADED=1

log_debug "postgresql.sh loaded successfully"

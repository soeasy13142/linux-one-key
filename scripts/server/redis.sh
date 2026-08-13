#!/usr/bin/env bash
# redis.sh - Redis 安装与安全加固模块
# 安装 Redis 并应用 redis.conf 安全基线（绑定 localhost + 禁用危险命令）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before redis.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly REDIS_SERVICE="redis"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
REDIS_CONFIG="${REDIS_CONFIG:-/etc/redis/redis.conf}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Redis 是否已安装
check_redis_installed() {
    command_exists redis-server
}

# 检查 Redis 服务是否在运行（Debian/Ubuntu 服务名为 redis-server，RHEL 系为 redis）
check_redis_running() {
    systemctl is-active "${REDIS_SERVICE}" &>/dev/null || systemctl is-active redis-server &>/dev/null
}

# 幂等地设置 redis.conf 指令（存在则替换整行，不存在则追加；不触碰其他设置）
# $1: 指令名（如 "bind" / "rename-command"）
# $2: 指令值（如 "127.0.0.1" / 'FLUSHALL ""'）
# $3: 匹配片段（默认同指令名；rename-command 需指定具体命令名以精确匹配）
_set_redis_line() {
    local directive="$1"
    local value="$2"
    local match="${3:-${directive}}"
    local config_file="${REDIS_CONFIG}"

    if grep -qE "^[[:space:]]*#?[[:space:]]*${match}[[:space:]]" "${config_file}" 2>/dev/null; then
        # 已存在（含被注释形式）：替换整行，兼容 macOS 与 Linux
        if [[ "$(uname)" == "Darwin" ]]; then
            sed -i '' -E "s|^[[:space:]]*#?[[:space:]]*${match}[[:space:]].*|${directive} ${value}|" "${config_file}"
        else
            sed -i -E "s|^[[:space:]]*#?[[:space:]]*${match}[[:space:]].*|${directive} ${value}|" "${config_file}"
        fi
    else
        printf '%s\n' "${directive} ${value}" >> "${config_file}"
    fi
}

# 写入 redis.conf 安全基线（保守默认：仅确保加固键存在，不覆盖用户其他设置）
_write_redis_hardening() {
    mkdir -p "$(dirname "${REDIS_CONFIG}")" 2>/dev/null || true

    # 已有配置：先备份，保留用户自定义（幂等 + 安全）
    if [[ -f "${REDIS_CONFIG}" ]]; then
        backup_file "${REDIS_CONFIG}" "${MSG_REDIS_BACKUP_CONFIG}" || true
        log_info "${MSG_REDIS_CONFIG_EXISTS}"
    else
        touch "${REDIS_CONFIG}"
    fi

    # 保守基线：绑定 localhost + protected-mode + 禁用危险命令
    _set_redis_line "bind" "127.0.0.1"
    _set_redis_line "protected-mode" "yes"
    _set_redis_line "rename-command" 'FLUSHALL ""' "rename-command FLUSHALL"
    _set_redis_line "rename-command" 'FLUSHDB ""' "rename-command FLUSHDB"
    _set_redis_line "rename-command" 'CONFIG ""' "rename-command CONFIG"
    _set_redis_line "rename-command" 'EVAL ""' "rename-command EVAL"

    log_success "${MSG_REDIS_CONFIG_WRITTEN}"
}

# 安装 Redis 包（按发行版）
_install_redis_pkg() {
    log_step "${MSG_REDIS_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y redis-server >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux)
            # CentOS/RHEL 系的 redis 包位于 EPEL 源；CentOS 7 使用 yum，CentOS 8+ 使用 dnf
            local pkg_mgr
            if command_exists dnf; then
                pkg_mgr="dnf"
            else
                pkg_mgr="yum"
            fi
            # 安装 EPEL 源（可能已安装或不可用，失败则静默继续）
            "${pkg_mgr}" install -y epel-release >> "${LOG_FILE}" 2>&1 || true
            "${pkg_mgr}" install -y redis >> "${LOG_FILE}" 2>&1
            ;;
        fedora)
            dnf install -y redis >> "${LOG_FILE}" 2>&1
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}: ${DETECTED_OS}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装 Redis
# ═══════════════════════════════════════════

install_redis() {
    log_title "${MSG_REDIS_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_redis_installed; then
        log_info "${MSG_REDIS_ALREADY}"
        check_redis_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_REDIS_CONFIRM}" "y"; then
        log_info "${MSG_REDIS_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_redis_pkg; then
        log_error "${MSG_REDIS_FAILED}"
        return 1
    fi

    # 写入 redis.conf 安全基线
    _write_redis_hardening

    # 启用并启动服务（Debian/Ubuntu 用 redis-server，RHEL 系用 redis）
    if systemctl enable --now "${REDIS_SERVICE}" >> "${LOG_FILE}" 2>&1 || \
       systemctl enable --now redis-server >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_REDIS_INSTALLED}"
    else
        log_warn "${MSG_REDIS_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_redis_running; then
        log_success "${MSG_REDIS_STATUS_RUNNING}"
    else
        log_warn "${MSG_REDIS_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Redis
# ═══════════════════════════════════════════

uninstall_redis() {
    log_title "${MSG_REDIS_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_redis_installed; then
        log_warn "${MSG_REDIS_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_REDIS_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_REDIS_CANCELLED}"
        return 0
    fi

    log_step "${MSG_REDIS_UNINSTALLING}"

    # 停止并禁用服务（覆盖 Debian/Ubuntu 与 RHEL 系两种服务名）
    systemctl disable --now "${REDIS_SERVICE}" >> "${LOG_FILE}" 2>&1 || true
    systemctl disable --now redis-server >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y redis-server >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y redis >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y redis >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除配置文件及其备份
    rm -f "${REDIS_CONFIG}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/redis.conf.bak."* 2>/dev/null || true

    log_success "${MSG_REDIS_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_redis_status() {
    log_title "${MSG_REDIS_STATUS_CHECKING}"

    if ! check_redis_installed; then
        log_warn "${MSG_REDIS_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(redis-server --version 2>/dev/null | head -1 || echo unknown)"

    if check_redis_running; then
        log_success "${MSG_REDIS_STATUS_RUNNING}"
    else
        log_error "${MSG_REDIS_STATUS_NOT_RUNNING}"
    fi

    # 展示安全基线加固状态
    if [[ -f "${REDIS_CONFIG}" ]]; then
        log_info "${MSG_REDIS_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_REDIS_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_redis_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_REDIS_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_REDIS_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_REDIS_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_REDIS_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_REDIS_MENU_BACK}${NC}"
    echo ""
}

run_redis_submenu_loop() {
    while true; do
        show_redis_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_redis || log_error "${MSG_REDIS_FAILED}"
                press_enter
                ;;
            2)
                uninstall_redis || log_error "${MSG_REDIS_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_redis_status || log_error "${MSG_REDIS_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 redis.sh 已加载
readonly _REDIS_LOADED=1

log_debug "redis.sh loaded successfully"

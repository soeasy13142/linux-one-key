#!/usr/bin/env bash
# memcached.sh - Memcached 安装与安全加固模块
# 安装 Memcached 并应用保守加固基线（仅监听 localhost + 禁用 UDP + 限制内存）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before memcached.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly MEMCACHED_SERVICE="memcached"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
# 注意：不同发行版配置文件路径不同：
#   Ubuntu/Debian → /etc/memcached.conf（每行一个参数，如 -l 127.0.0.1）
#   RHEL/Rocky/Alma/Fedora → /etc/sysconfig/memcached（OPTIONS="..." 单行）
# 运行时由 _get_memcached_config_format 根据路径/内容自动识别格式
MEMCACHED_CONFIG="${MEMCACHED_CONFIG:-/etc/memcached.conf}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Memcached 是否已安装
check_memcached_installed() {
    command_exists memcached
}

# 检查 Memcached 服务是否在运行
check_memcached_running() {
    systemctl is-active "${MEMCACHED_SERVICE}" &>/dev/null
}

# 就地编辑文件（兼容 macOS BSD sed 与 GNU sed 的 -i 差异）
# $1: sed 表达式  $2: 目标文件
_sed_inplace() {
    local expr="$1"
    local file="$2"
    if [[ "$(uname)" == "Darwin" ]]; then
        sed -i '' "${expr}" "${file}"
    else
        sed -i "${expr}" "${file}"
    fi
}

# 识别配置文件格式
# "sysconfig" → RHEL 系 OPTIONS="..." 单行格式；"conf" → Debian 系每行一个参数
_get_memcached_config_format() {
    if [[ "${MEMCACHED_CONFIG}" == *"/sysconfig/"* ]] || \
       grep -qE '^[[:space:]]*OPTIONS=' "${MEMCACHED_CONFIG}" 2>/dev/null; then
        echo "sysconfig"
    else
        echo "conf"
    fi
}

# 幂等设置「每行一个参数」格式中的某个 flag（不存在则追加，存在则替换该行）
# $1: flag（如 -l）  $2: 值（如 127.0.0.1）
_set_conf_flag() {
    local flag="$1"
    local value="$2"
    local line="${flag} ${value}"

    if grep -qE "^[[:space:]]*${flag}[[:space:]]" "${MEMCACHED_CONFIG}" 2>/dev/null; then
        _sed_inplace "s|^[[:space:]]*${flag}[[:space:]].*|${line}|" "${MEMCACHED_CONFIG}"
    else
        echo "${line}" >> "${MEMCACHED_CONFIG}"
    fi
}

# 在 OPTIONS 字符串中设置/替换一个参数（sysconfig 格式内部使用）
# $1: OPTIONS 值（可能含引号）  $2: flag（如 -l）  $3: 值
_set_options_flag() {
    local options="$1"
    local flag="$2"
    local value="$3"

    # 去除首尾引号
    options="${options#\"}"
    options="${options%\"}"

    if printf '%s' "${options}" | grep -qE "(^|[[:space:]])${flag}[[:space:]]"; then
        printf '%s' "${options}" | sed -E "s|${flag}[[:space:]]+[^[:space:]]*|${flag} ${value}|"
    else
        printf '%s %s %s' "${options}" "${flag}" "${value}"
    fi
}

# 写入 Debian 系格式加固基线（每行一个参数）
_write_conf_hardening() {
    _set_conf_flag "-l" "127.0.0.1"
    _set_conf_flag "-U" "0"
    _set_conf_flag "-m" "64"
}

# 写入 RHEL 系格式加固基线（OPTIONS="..." 单行）
_write_sysconfig_hardening() {
    if grep -qE '^[[:space:]]*OPTIONS=' "${MEMCACHED_CONFIG}" 2>/dev/null; then
        local options
        options=$(grep -E '^[[:space:]]*OPTIONS=' "${MEMCACHED_CONFIG}" | head -1)
        local inner="${options#*\"}"
        inner="${inner%\"*}"
        inner=$(_set_options_flag "${inner}" "-l" "127.0.0.1")
        inner=$(_set_options_flag "${inner}" "-U" "0")
        inner=$(_set_options_flag "${inner}" "-m" "64")
        _sed_inplace "s|^[[:space:]]*OPTIONS=.*|OPTIONS=\"${inner}\"|" "${MEMCACHED_CONFIG}"
    else
        echo 'OPTIONS="-l 127.0.0.1 -U 0 -m 64"' >> "${MEMCACHED_CONFIG}"
    fi
}

# 写入 Memcached 安全基线（保守默认：仅 localhost + 禁用 UDP + 限制 64MB 内存）
# 已存在则备份后幂等编辑（保留其他设置），不存在则创建基线配置
_write_memcached_hardening() {
    mkdir -p "$(dirname "${MEMCACHED_CONFIG}")" 2>/dev/null || true

    # 已有配置：备份后编辑，保留用户自定义（幂等 + 安全）
    if [[ -f "${MEMCACHED_CONFIG}" ]]; then
        backup_file "${MEMCACHED_CONFIG}" "${MSG_MEMCACHED_BACKUP_CONFIG}" || true
        log_info "${MSG_MEMCACHED_CONFIG_EXISTS}"
    fi

    local format
    format="$(_get_memcached_config_format)"

    if [[ "${format}" == "sysconfig" ]]; then
        _write_sysconfig_hardening
    else
        _write_conf_hardening
    fi

    log_success "${MSG_MEMCACHED_CONFIG_WRITTEN}"
}

# ═══════════════════════════════════════════
# 安装 Memcached
# ═══════════════════════════════════════════

# 安装 Memcached 包（所有发行版均为 memcached）
_install_memcached_pkg() {
    log_step "${MSG_MEMCACHED_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get install -y memcached >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf install -y memcached >> "${LOG_FILE}" 2>&1
            else
                yum install -y memcached >> "${LOG_FILE}" 2>&1
            fi
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}: ${DETECTED_OS}"
            return 1
            ;;
    esac
}

install_memcached() {
    log_title "${MSG_MEMCACHED_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_memcached_installed; then
        log_info "${MSG_MEMCACHED_ALREADY}"
        check_memcached_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_MEMCACHED_CONFIRM}" "y"; then
        log_info "${MSG_MEMCACHED_CANCELLED}"
        return 0
    fi

    # 安装包
    if ! _install_memcached_pkg; then
        log_error "${MSG_MEMCACHED_FAILED}"
        return 1
    fi

    # 写入安全基线
    _write_memcached_hardening

    # 启用并启动服务
    if systemctl enable --now "${MEMCACHED_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_MEMCACHED_INSTALLED}"
    else
        log_warn "${MSG_MEMCACHED_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_memcached_running; then
        log_success "${MSG_MEMCACHED_STATUS_RUNNING}"
    else
        log_warn "${MSG_MEMCACHED_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Memcached
# ═══════════════════════════════════════════

uninstall_memcached() {
    log_title "${MSG_MEMCACHED_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_memcached_installed; then
        log_warn "${MSG_MEMCACHED_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_MEMCACHED_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_MEMCACHED_CANCELLED}"
        return 0
    fi

    log_step "${MSG_MEMCACHED_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${MEMCACHED_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包（所有发行版均为 memcached）
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y memcached >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y memcached >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y memcached >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除配置文件及其备份（兼容 /etc/memcached.conf 与 /etc/sysconfig/memcached）
    rm -f "${MEMCACHED_CONFIG}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/$(basename "${MEMCACHED_CONFIG}").bak."* 2>/dev/null || true

    log_success "${MSG_MEMCACHED_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_memcached_status() {
    log_title "${MSG_MEMCACHED_STATUS_CHECKING}"

    if ! check_memcached_installed; then
        log_warn "${MSG_MEMCACHED_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(memcached -h 2>&1 | head -1 || echo unknown)"

    if check_memcached_running; then
        log_success "${MSG_MEMCACHED_STATUS_RUNNING}"
    else
        log_error "${MSG_MEMCACHED_STATUS_NOT_RUNNING}"
    fi

    # 展示安全基线状态
    if [[ -f "${MEMCACHED_CONFIG}" ]]; then
        log_info "${MSG_MEMCACHED_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_MEMCACHED_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_memcached_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_MEMCACHED_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MEMCACHED_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_MEMCACHED_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_MEMCACHED_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_MEMCACHED_MENU_BACK}${NC}"
    echo ""
}

run_memcached_submenu_loop() {
    while true; do
        show_memcached_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_memcached || log_error "${MSG_MEMCACHED_FAILED}"
                press_enter
                ;;
            2)
                uninstall_memcached || log_error "${MSG_MEMCACHED_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_memcached_status || log_error "${MSG_MEMCACHED_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 memcached.sh 已加载
readonly _MEMCACHED_LOADED=1

log_debug "memcached.sh loaded successfully"

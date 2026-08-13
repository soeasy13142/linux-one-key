#!/usr/bin/env bash
# grafana.sh - Grafana 安装与安全基线模块
# 通过官方 Grafana OSS 源安装 Grafana，并应用 grafana.ini 安全基线
# （绑定 localhost + 禁用匿名访问）
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before grafana.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly GRAFANA_SERVICE="grafana-server"
readonly GRAFANA_APT_REPO_URL="https://apt.grafana.com"
readonly GRAFANA_APT_GPG_URL="https://apt.grafana.com/gpg.key"
readonly GRAFANA_RPM_REPO_URL="https://rpm.grafana.com"
readonly GRAFANA_RPM_GPG_URL="https://rpm.grafana.com/gpg.key"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
GRAFANA_INI="${GRAFANA_INI:-/etc/grafana/grafana.ini}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Grafana 是否已安装
check_grafana_installed() {
    command_exists grafana-server || command_exists grafana-cli
}

# 检查 Grafana 服务是否在运行
check_grafana_running() {
    systemctl is-active "${GRAFANA_SERVICE}" &>/dev/null
}

# 在 ini 文件指定 section 下幂等写入 key = value（保留其他所有内容）
# 若该 key 已存在（含注释形式 ;key 或 #key）则原地替换，否则追加到对应 section 下
_set_ini_key() {
    local ini_file="$1"
    local section="$2"
    local key="$3"
    local value="$4"
    local new_line="${key} = ${value}"

    awk -v sec="[${section}]" \
        -v key_pat="^[;#]?[[:space:]]*${key}[[:space:]]*=" \
        -v new_line="${new_line}" '
        $0 == sec {
            in_sec = 1
            seen_sec = 1
            print
            next
        }
        in_sec && /^\[/ {
            if (!inserted) {
                print new_line
                inserted = 1
            }
            in_sec = 0
        }
        in_sec && $0 ~ key_pat {
            print new_line
            inserted = 1
            next
        }
        { print }
        END {
            if (!seen_sec) {
                print ""
                print sec
                print new_line
            } else if (!inserted) {
                print new_line
            }
        }
    ' "${ini_file}" > "${ini_file}.tmp" && mv "${ini_file}.tmp" "${ini_file}"
}

# 写入 grafana.ini 安全基线（保守默认：绑定 localhost + 禁用匿名访问）
# 操作 GRAFANA_INI（可覆盖，便于测试）；仅修改两个 key，保留其余所有配置
_write_grafana_hardening() {
    mkdir -p "$(dirname "${GRAFANA_INI}")" 2>/dev/null || true

    # 已有配置：先备份，再原地修改（幂等 + 保留用户自定义）
    if [[ -f "${GRAFANA_INI}" ]]; then
        log_info "${MSG_GRAFANA_CONFIG_EXISTS}"
        backup_file "${GRAFANA_INI}" "${MSG_GRAFANA_BACKUP_CONFIG}" || true
    else
        # 不存在则创建最小配置（仅含两个目标 section）
        {
            printf '[server]\n'
            printf '[auth.anonymous]\n'
        } > "${GRAFANA_INI}"
    fi

    _set_ini_key "${GRAFANA_INI}" "server" "http_addr" "127.0.0.1"
    _set_ini_key "${GRAFANA_INI}" "auth.anonymous" "enabled" "false"

    log_success "${MSG_GRAFANA_CONFIG_WRITTEN}"
}

# 配置官方 Grafana OSS apt 源（幂等）
_setup_grafana_apt_repo() {
    local keyring="/etc/apt/keyrings/grafana.gpg"
    local source_file="/etc/apt/sources.list.d/grafana.list"

    # 幂等：源文件已存在则跳过
    if [[ -f "${source_file}" ]]; then
        log_debug "Grafana apt repo already configured"
        return 0
    fi

    # 确保依赖工具存在（gpg 用于转换 GPG key）
    if ! command_exists gpg; then
        apt-get install -y gnupg >> "${LOG_FILE}" 2>&1
    fi
    mkdir -p /etc/apt/keyrings 2>/dev/null || true

    # 下载并转换 GPG key（gpg --dearmor 方案，避免弃用的 apt-key）
    curl -fsSL "${GRAFANA_APT_GPG_URL}" 2>> "${LOG_FILE}" \
        | gpg --dearmor --yes -o "${keyring}" >> "${LOG_FILE}" 2>&1

    # 写入 apt 源（signed-by 指定 keyring）
    echo "deb [signed-by=${keyring}] ${GRAFANA_APT_REPO_URL} stable main" > "${source_file}"
}

# 配置官方 Grafana OSS rpm 源（幂等）
_setup_grafana_rpm_repo() {
    local repo_file="/etc/yum.repos.d/grafana.repo"

    # 幂等：repo 文件已存在则跳过
    if [[ -f "${repo_file}" ]]; then
        log_debug "Grafana rpm repo already configured"
        return 0
    fi

    # 导入 GPG key
    curl -fsSL "${GRAFANA_RPM_GPG_URL}" 2>> "${LOG_FILE}" | rpm --import - >> "${LOG_FILE}" 2>&1

    cat > "${repo_file}" << EOF
[grafana]
name=grafana
baseurl=${GRAFANA_RPM_REPO_URL}
repo_gpgcheck=1
enabled=1
gpgcheck=1
gpgkey=${GRAFANA_RPM_GPG_URL}
sslverify=1
sslcacert=/etc/pki/tls/certs/ca-bundle.crt
EOF
}

# 安装 Grafana 包（按发行版配置官方源后安装）
_install_grafana_pkg() {
    log_step "${MSG_GRAFANA_INSTALLING}"

    case "${DETECTED_OS}" in
        ubuntu|debian)
            _setup_grafana_apt_repo || return 1
            apt-get update >> "${LOG_FILE}" 2>&1
            apt-get install -y grafana >> "${LOG_FILE}" 2>&1
            ;;
        centos|rhel|rocky|almalinux|fedora)
            _setup_grafana_rpm_repo || return 1
            if command_exists dnf; then
                dnf install -y grafana >> "${LOG_FILE}" 2>&1
            else
                yum install -y grafana >> "${LOG_FILE}" 2>&1
            fi
            ;;
        *)
            log_error "${MSG_ERROR_UNSUPPORTED_OS}"
            return 1
            ;;
    esac
}

# ═══════════════════════════════════════════
# 安装 Grafana
# ═══════════════════════════════════════════

install_grafana() {
    log_title "${MSG_GRAFANA_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_grafana_installed; then
        log_info "${MSG_GRAFANA_ALREADY}"
        check_grafana_status
        return 0
    fi

    # 确认安装
    if ! confirm "${MSG_GRAFANA_CONFIRM}" "y"; then
        log_info "${MSG_GRAFANA_CANCELLED}"
        return 0
    fi

    # 安装包（配置官方源 + 安装）
    if ! _install_grafana_pkg; then
        log_error "${MSG_GRAFANA_FAILED}"
        return 1
    fi

    # 写入 grafana.ini 安全基线（绑定 localhost + 禁用匿名）
    _write_grafana_hardening

    # 启用并启动服务
    if systemctl enable --now "${GRAFANA_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_GRAFANA_INSTALLED}"
    else
        log_warn "${MSG_GRAFANA_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_grafana_running; then
        log_success "${MSG_GRAFANA_STATUS_RUNNING}"
    else
        log_warn "${MSG_GRAFANA_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Grafana
# ═══════════════════════════════════════════

uninstall_grafana() {
    log_title "${MSG_GRAFANA_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_grafana_installed; then
        log_warn "${MSG_GRAFANA_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_GRAFANA_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_GRAFANA_CANCELLED}"
        return 0
    fi

    log_step "${MSG_GRAFANA_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${GRAFANA_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除包
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y grafana >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y grafana >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y grafana >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除本模块添加的第三方源
    rm -f /etc/apt/sources.list.d/grafana.list 2>/dev/null || true
    rm -f /etc/apt/keyrings/grafana.gpg 2>/dev/null || true
    rm -f /etc/yum.repos.d/grafana.repo 2>/dev/null || true

    # 移除配置及其备份
    rm -f "${GRAFANA_INI}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/grafana.ini.bak."* 2>/dev/null || true

    log_success "${MSG_GRAFANA_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_grafana_status() {
    log_title "${MSG_GRAFANA_STATUS_CHECKING}"

    if ! check_grafana_installed; then
        log_warn "${MSG_GRAFANA_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(grafana-server -v 2>/dev/null || echo unknown)"

    if check_grafana_running; then
        log_success "${MSG_GRAFANA_STATUS_RUNNING}"
    else
        log_error "${MSG_GRAFANA_STATUS_NOT_RUNNING}"
    fi

    # 展示 grafana.ini 加固状态
    if grep -qs '^http_addr = 127.0.0.1' "${GRAFANA_INI}" 2>/dev/null \
        && grep -qs '^enabled = false' "${GRAFANA_INI}" 2>/dev/null; then
        log_info "${MSG_GRAFANA_CONFIG_WRITTEN}"
    else
        log_warn "${MSG_GRAFANA_CONFIG_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_grafana_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_GRAFANA_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_GRAFANA_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_GRAFANA_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_GRAFANA_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_GRAFANA_MENU_BACK}${NC}"
    echo ""
}

run_grafana_submenu_loop() {
    while true; do
        show_grafana_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_grafana || log_error "${MSG_GRAFANA_FAILED}"
                press_enter
                ;;
            2)
                uninstall_grafana || log_error "${MSG_GRAFANA_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_grafana_status || log_error "${MSG_GRAFANA_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 grafana.sh 已加载
readonly _GRAFANA_LOADED=1

log_debug "grafana.sh loaded successfully"

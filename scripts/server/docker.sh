#!/usr/bin/env bash
# docker.sh - Docker 安装与安全加固模块
# 安装 Docker Engine + compose 插件，并应用 daemon.json 安全基线
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before docker.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly DOCKER_INSTALL_URL="https://get.docker.com"
readonly DOCKER_SERVICE="docker"
# 允许测试覆盖路径（与 BACKUP_DIR/LOG_DIR 的覆盖约定一致）
DOCKER_DAEMON_CONFIG="${DOCKER_DAEMON_CONFIG:-/etc/docker/daemon.json}"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 Docker 是否已安装
check_docker_installed() {
    command_exists docker
}

# 检查 Docker 服务是否在运行
check_docker_running() {
    systemctl is-active "${DOCKER_SERVICE}" &>/dev/null
}

# 写入 daemon.json 安全基线（保守默认；已存在则备份后保留不覆盖）
# $1: enable_userns (0/1) — 是否启用 userns-remap（激进项，默认关闭）
_write_daemon_json() {
    local enable_userns="${1:-0}"

    mkdir -p "$(dirname "${DOCKER_DAEMON_CONFIG}")" 2>/dev/null || true

    # 已有配置：备份后保留，不覆盖用户自定义（幂等 + 安全）
    if [[ -f "${DOCKER_DAEMON_CONFIG}" ]]; then
        backup_file "${DOCKER_DAEMON_CONFIG}" "${MSG_DOCKER_BACKUP_DAEMON}" || true
        log_warn "${MSG_DOCKER_DAEMON_EXISTS}"
        return 0
    fi

    # 保守基线：日志限幅 + 禁容器间直连 + live-restore（重启不中断容器）
    {
        printf '{\n'
        printf '  "log-driver": "json-file",\n'
        printf '  "log-opts": {\n'
        printf '    "max-size": "10m",\n'
        printf '    "max-file": "3"\n'
        printf '  },\n'
        printf '  "icc": false,\n'
        printf '  "live-restore": true'
        if [[ "${enable_userns}" == "1" ]]; then
            printf ',\n  "userns-remap": "default"'
        fi
        printf '\n}\n'
    } > "${DOCKER_DAEMON_CONFIG}"

    log_success "${MSG_DOCKER_DAEMON_WRITTEN}"
}

# ═══════════════════════════════════════════
# 安装 Docker
# ═══════════════════════════════════════════

install_docker() {
    log_title "${MSG_DOCKER_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_docker_installed; then
        log_info "${MSG_DOCKER_ALREADY}"
        check_docker_status
        return 0
    fi

    # 检查 curl 是否可用
    if ! command_exists curl; then
        log_error "${MSG_DOCKER_CURL_REQUIRED}"
        return 1
    fi

    # 确认安装
    if ! confirm "${MSG_DOCKER_CONFIRM}" "y"; then
        log_info "${MSG_DOCKER_CANCELLED}"
        return 0
    fi

    log_step "${MSG_DOCKER_INSTALLING}"

    # 使用官方 get.docker.com 脚本安装（自动适配 apt/dnf/yum 及架构）
    log_info "${MSG_DOCKER_DOWNLOADING}"
    if ! curl -fsSL "${DOCKER_INSTALL_URL}" | sh; then
        log_error "${MSG_DOCKER_FAILED}"
        return 1
    fi

    # 激进加固项 opt-in：userns-remap 用户命名空间隔离（可能影响部分镜像兼容）
    local enable_userns=0
    echo ""
    if confirm "${MSG_DOCKER_USERN_REMAP_PROMPT}" "n"; then
        enable_userns=1
        log_info "${MSG_DOCKER_USERN_REMAP_ENABLED}"
    fi

    # 写入 daemon.json 安全基线
    _write_daemon_json "${enable_userns}"

    # 启用并启动服务
    if systemctl enable --now "${DOCKER_SERVICE}" >> "${LOG_FILE}" 2>&1; then
        log_success "${MSG_DOCKER_INSTALLED}"
    else
        log_warn "${MSG_DOCKER_ENABLE_FAILED}"
    fi

    # 验证服务运行
    if check_docker_running; then
        log_success "${MSG_DOCKER_STATUS_RUNNING}"
    else
        log_warn "${MSG_DOCKER_STATUS_NOT_RUNNING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 卸载 Docker
# ═══════════════════════════════════════════

uninstall_docker() {
    log_title "${MSG_DOCKER_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_docker_installed; then
        log_warn "${MSG_DOCKER_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_DOCKER_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_DOCKER_CANCELLED}"
        return 0
    fi

    log_step "${MSG_DOCKER_UNINSTALLING}"

    # 停止并禁用服务
    systemctl disable --now "${DOCKER_SERVICE}" >> "${LOG_FILE}" 2>&1 || true

    # 按发行版移除 docker-ce 相关包（get.docker.com 安装的包名）
    case "${DETECTED_OS}" in
        ubuntu|debian)
            apt-get remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >> "${LOG_FILE}" 2>&1 || true
            ;;
        centos|rhel|rocky|almalinux|fedora)
            if command_exists dnf; then
                dnf remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >> "${LOG_FILE}" 2>&1 || true
            else
                yum remove -y docker-ce docker-ce-cli containerd.io docker-compose-plugin >> "${LOG_FILE}" 2>&1 || true
            fi
            ;;
    esac

    # 移除 daemon.json 及其备份
    rm -f "${DOCKER_DAEMON_CONFIG}" 2>/dev/null || true
    rm -f "${BACKUP_DIR}/daemon.json.bak."* 2>/dev/null || true

    log_success "${MSG_DOCKER_UNINSTALLED}"
    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

check_docker_status() {
    log_title "${MSG_DOCKER_STATUS_CHECKING}"

    if ! check_docker_installed; then
        log_warn "${MSG_DOCKER_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "$(docker --version 2>/dev/null || echo unknown)"

    if check_docker_running; then
        log_success "${MSG_DOCKER_STATUS_RUNNING}"
    else
        log_error "${MSG_DOCKER_STATUS_NOT_RUNNING}"
    fi

    # 展示 daemon.json 加固状态
    if [[ -f "${DOCKER_DAEMON_CONFIG}" ]]; then
        log_info "${MSG_DOCKER_DAEMON_WRITTEN}"
    else
        log_warn "${MSG_DOCKER_DAEMON_MISSING}"
    fi

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

show_docker_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_DOCKER_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BLUE}${MSG_MENU_STATE_LABEL}: $(render_service_state_label check_docker_installed check_docker_running)${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_DOCKER_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_DOCKER_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_DOCKER_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_DOCKER_MENU_BACK}${NC}"
    echo ""
}

run_docker_submenu_loop() {
    while true; do
        show_docker_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_docker || log_error "${MSG_DOCKER_FAILED}"
                press_enter
                ;;
            2)
                uninstall_docker || log_error "${MSG_DOCKER_UNINSTALL_FAILED}"
                press_enter
                ;;
            3)
                check_docker_status || log_error "${MSG_DOCKER_FAILED}"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 docker.sh 已加载
readonly _DOCKER_LOADED=1

log_debug "docker.sh loaded successfully"

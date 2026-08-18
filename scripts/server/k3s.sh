#!/usr/bin/env bash
# k3s.sh - K3s (Lightweight Kubernetes) 安装模块
# 安装、卸载、状态检查 K3s
# 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before k3s.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量定义
# ═══════════════════════════════════════════

readonly K3S_INSTALL_URL="https://get.k3s.io"
readonly K3S_UNINSTALL_SCRIPT="/usr/local/bin/k3s-uninstall.sh"
readonly K3S_BIN="/usr/local/bin/k3s"
readonly K3S_KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
readonly K3S_SERVICE="k3s"

# ═══════════════════════════════════════════
# 辅助函数
# ═══════════════════════════════════════════

# 检查 K3s 是否已安装（bin 文件存在）
check_k3s_installed() {
    command -v k3s &>/dev/null && [[ -x "${K3S_BIN}" ]]
}

# 检查 K3s 服务是否在运行
check_k3s_running() {
    systemctl is-active "${K3S_SERVICE}" &>/dev/null
}

# ═══════════════════════════════════════════
# 安装 K3s
# ═══════════════════════════════════════════

# 设置 kubectl 访问（将 kubeconfig 复制到用户目录）
_setup_kubectl_access() {
    if [[ ! -f "${K3S_KUBECONFIG}" ]]; then
        log_debug "K3S_KUBECONFIG not found at ${K3S_KUBECONFIG}, skipping"
        return 0
    fi

    local user_kube_dir="${HOME}/.kube"
    mkdir -p "${user_kube_dir}"

    if [[ ! -f "${user_kube_dir}/config" ]]; then
        cp "${K3S_KUBECONFIG}" "${user_kube_dir}/config"
        chown "$(id -u):$(id -g)" "${user_kube_dir}/config" 2>/dev/null || true
        chmod 600 "${user_kube_dir}/config"
        log_success "${MSG_K3S_KUBECONFIG}"
    else
        log_info "${MSG_K3S_KUBECONFIG_EXISTS}"
    fi
}

# 显示 K3s 集群节点信息
_show_k3s_cluster_info() {
    if command_exists k3s; then
        local node_info
        node_info=$(k3s kubectl get nodes 2>/dev/null || true)
        if [[ -n "${node_info}" ]]; then
            echo ""
            log_info "${MSG_K3S_NODE_READY}"
            echo ""
            echo "${node_info}"
            echo ""
        else
            log_warn "${MSG_K3S_NODES_UNAVAILABLE}"
        fi
    fi
}

# 安装 K3s
install_k3s() {
    log_title "${MSG_K3S_TITLE}"

    # 检查 root 权限
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # 检查是否已安装
    if check_k3s_installed; then
        log_info "${MSG_K3S_ALREADY}"
        check_k3s_status
        return 0
    fi

    # 检查 curl 是否可用
    if ! command_exists curl; then
        log_error "${MSG_K3S_CURL_REQUIRED}"
        return 1
    fi

    # 确认安装
    if ! confirm "${MSG_K3S_CONFIRM}" "y"; then
        log_info "${MSG_K3S_CANCELLED}"
        return 0
    fi

    log_step "${MSG_K3S_INSTALLING}"

    # 构建安装参数
    local install_opts=""
    install_opts="${install_opts} --write-kubeconfig-mode 644"

    # 询问是否禁用 Traefik（默认禁用）
    echo ""
    if confirm "${MSG_K3S_DISABLE_TRAEFIK_PROMPT}" "y"; then
        install_opts="${install_opts} --disable traefik"
        log_info "${MSG_K3S_DISABLE_TRAEFIK}"
    fi

    # 执行安装（curl 管道到 sh）
    log_info "${MSG_K3S_DOWNLOADING}"
    # shellcheck disable=SC2086 # install_opts is intended to split into multiple args
    if curl -sfL "${K3S_INSTALL_URL}" | sh -s - ${install_opts}; then
        log_success "${MSG_K3S_INSTALLED}"
    else
        log_error "${MSG_K3S_FAILED}"
        return 1
    fi

    # 等待服务启动
    sleep 3

    # 验证服务运行
    if check_k3s_running; then
        log_success "${MSG_K3S_STATUS_RUNNING}"
    else
        log_warn "${MSG_K3S_STATUS_NOT_RUNNING}"
    fi

    # 配置 kubectl 访问
    _setup_kubectl_access

    # 显示集群信息
    _show_k3s_cluster_info

    return 0
}

# ═══════════════════════════════════════════
# 卸载 K3s
# ═══════════════════════════════════════════

# 卸载 K3s
uninstall_k3s() {
    log_title "${MSG_K3S_UNINSTALLING}"

    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    if ! check_k3s_installed; then
        log_warn "${MSG_K3S_NOT_INSTALLED}"
        return 0
    fi

    # 确认卸载
    if ! confirm "${MSG_K3S_CONFIRM_UNINSTALL}" "n"; then
        log_info "${MSG_K3S_CANCELLED}"
        return 0
    fi

    log_step "${MSG_K3S_UNINSTALLING}"

    # 使用官方卸载脚本
    if [[ -f "${K3S_UNINSTALL_SCRIPT}" ]]; then
        if bash "${K3S_UNINSTALL_SCRIPT}"; then
            log_success "${MSG_K3S_UNINSTALLED}"
        else
            log_error "${MSG_K3S_UNINSTALL_FAILED}"
            return 1
        fi
    else
        log_error "${MSG_K3S_UNINSTALL_SCRIPT_NOT_FOUND}"
        return 1
    fi

    # 清理备份文件
    rm -f "${BACKUP_DIR}/k3s.yaml.bak."* 2>/dev/null || true

    return 0
}

# ═══════════════════════════════════════════
# 状态检查
# ═══════════════════════════════════════════

# 检查 K3s 运行状态
check_k3s_status() {
    log_title "${MSG_K3S_STATUS_CHECKING}"

    if ! check_k3s_installed; then
        log_warn "${MSG_K3S_NOT_INSTALLED}"
        return 1
    fi

    echo ""
    log_info "${MSG_K3S_BINARY}: ${K3S_BIN}"

    local k3s_version
    k3s_version=$(k3s --version 2>/dev/null | head -1 || echo "unknown")
    log_info "${MSG_K3S_VERSION}: ${k3s_version}"

    if check_k3s_running; then
        log_success "${MSG_K3S_STATUS_RUNNING}"
    else
        log_error "${MSG_K3S_STATUS_NOT_RUNNING}"
    fi

    echo ""
    _show_k3s_cluster_info

    return 0
}

# ═══════════════════════════════════════════
# 子菜单（供 install.sh 调用）
# ═══════════════════════════════════════════

# 显示 K3s 子菜单
show_k3s_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_K3S_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${BLUE}${MSG_MENU_STATE_LABEL}: $(render_service_state_label check_k3s_installed check_k3s_running)${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_K3S_MENU_INSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_K3S_MENU_UNINSTALL}${NC}"
    echo -e "  ${GREEN}${MSG_K3S_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_K3S_MENU_BACK}${NC}"
    echo ""
}

# 运行 K3s 子菜单循环
run_k3s_submenu_loop() {
    while true; do
        show_k3s_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")
        case "${choice}" in
            1)
                install_k3s || log_error "K3s installation failed"
                press_enter
                ;;
            2)
                uninstall_k3s || log_error "K3s uninstall failed"
                press_enter
                ;;
            3)
                check_k3s_status || log_error "K3s status check failed"
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 标记 k3s.sh 已加载
readonly _K3S_LOADED=1

log_debug "k3s.sh loaded successfully"

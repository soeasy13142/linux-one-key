#!/usr/bin/env bash
# ============================================================================
# services.sh - 服务管理模块
# 审计运行中的服务、禁用不必要的服务、扫描开放端口
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before services.sh"
    exit 1
fi

# ============================================================================
# 配置常量
# ============================================================================

# 不必要服务列表: "service_name:description"
UNNECESSARY_SERVICES=(
    "telnet.socket:${MSG_SERVICES_DESC_TELNET:-telnet — unencrypted remote access}"
    "rsh.socket:${MSG_SERVICES_DESC_RSH:-rsh — unencrypted remote access}"
    "rlogin.socket:${MSG_SERVICES_DESC_RLOGIN:-rlogin — unencrypted remote access}"
    "vsftpd:${MSG_SERVICES_DESC_VSFTPD:-FTP — unencrypted file transfer}"
    "avahi-daemon:${MSG_SERVICES_DESC_AVAHI:-mDNS/DNS-SD — usually not needed on servers}"
    "cups:${MSG_SERVICES_DESC_CUPS:-printing service — usually not needed on servers}"
    "rpcbind:${MSG_SERVICES_DESC_RPCBIND:-RPC port mapper — disable if not needed}"
)

# 标准安全端口（扫描时不标记为警告）
SAFE_PORTS="22 80 443"

# ============================================================================
# 内部函数
# ============================================================================

# 列出所有运行中的 systemd 服务
# 输出: 每行一个服务名
_list_running_services() {
    systemctl list-units --type=service --state=running --no-pager --no-legend 2>/dev/null \
        | awk '{print $1}' \
        | sed 's/\.service$//' \
        || true
}

# 检查不必要服务是否正在运行
# 输出: 每行 "service_name:description:status" (active/inactive)
_check_unnecessary_services() {
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        local svc_name="${entry%%:*}"
        local svc_desc="${entry#*:}"

        # 检查服务是否存在且活跃
        local status="inactive"
        if systemctl is-active --quiet "${svc_name}" 2>/dev/null; then
            status="active"
        fi

        echo "${svc_name}:${svc_desc}:${status}"
    done
}

# 禁用单个服务（stop + disable）
# 参数: $1 = 服务名
_disable_service() {
    local svc_name="$1"

    log_step "${MSG_SERVICES_DISABLING}: ${svc_name}..."

    # 停止服务
    if systemctl is-active --quiet "${svc_name}" 2>/dev/null; then
        if ! systemctl stop "${svc_name}" >> "${LOG_FILE}" 2>&1; then
            log_warn "${MSG_SERVICES_STOP_FAILED}: ${svc_name}"
        fi
    fi

    # 禁用开机自启
    if systemctl is-enabled --quiet "${svc_name}" 2>/dev/null; then
        if ! systemctl disable "${svc_name}" >> "${LOG_FILE}" 2>&1; then
            log_warn "${MSG_SERVICES_DISABLE_FAILED}: ${svc_name}"
        fi
    fi

    # 验证
    if ! systemctl is-active --quiet "${svc_name}" 2>/dev/null; then
        log_success "${MSG_SERVICES_DISABLED}: ${svc_name}"
        return 0
    else
        log_error "${MSG_SERVICES_DISABLE_ERROR}: ${svc_name}"
        return 1
    fi
}

# 扫描监听端口
# 输出: 每行 "protocol:port:address:process"
_scan_listening_ports() {
    if command_exists ss; then
        ss -tlnp 2>/dev/null \
            | tail -n +2 \
            | awk '{
                split($4, a, ":");
                port = a[length(a)];
                proto = "tcp";
                addr = $4;
                proc = $6;
                gsub(/.*users:\(\("/, "", proc);
                gsub(/".*/, "", proc);
                print proto ":" port ":" addr ":" proc
            }' \
            || true
    elif command_exists netstat; then
        netstat -tlnp 2>/dev/null \
            | tail -n +3 \
            | awk '{
                split($4, a, ":");
                port = a[length(a)];
                proto = "tcp";
                addr = $4;
                proc = $7;
                gsub(/\//, ":", proc);
                split(proc, p, ":");
                proc = p[2];
                print proto ":" port ":" addr ":" proc
            }' \
            || true
    else
        # Fallback: /proc/net/tcp
        if [[ -r /proc/net/tcp ]]; then
            awk 'NR > 1 {
                split($2, a, ":");
                port = strtonum("0x" a[2]);
                if (port > 0) print "tcp:" port "::(unknown)"
            }' /proc/net/tcp 2>/dev/null || true
        fi
    fi
}

# 检查端口是否在安全端口列表中
# 参数: $1 = 端口号
# 返回: 0 = 安全端口, 1 = 未知端口
_is_safe_port() {
    local port="$1"
    for safe in ${SAFE_PORTS}; do
        if [[ "${port}" == "${safe}" ]]; then
            return 0
        fi
    done
    return 1
}

# ============================================================================
# 公共接口函数
# ============================================================================

# 审计所有运行中的服务（仅显示，不修改）
audit_services() {
    log_title "${MSG_SERVICES_AUDIT_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_SERVICES_RUNNING_TITLE}${NC}"
    echo ""

    local running_count=0
    while IFS= read -r svc; do
        [[ -z "${svc}" ]] && continue
        echo -e "  ${GREEN}●${NC} ${svc}"
        running_count=$((running_count + 1))
    done < <(_list_running_services)

    echo ""
    echo -e "${MSG_SERVICES_RUNNING_TOTAL}: ${running_count}"
    echo ""
}

# 交互式禁用不必要服务
disable_unnecessary_services() {
    log_title "${MSG_SERVICES_UNNECESSARY_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_SERVICES_UNNECESSARY_DESC}${NC}"
    echo ""

    local found_active=0
    local disabled_count=0

    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue

        local svc_name="${line%%:*}"
        local rest="${line#*:}"
        local svc_desc="${rest%%:*}"
        local svc_status="${rest#*:}"

        if [[ "${svc_status}" == "active" ]]; then
            found_active=1
            echo -e "  ${RED}●${NC} ${svc_name} — ${svc_desc}"

            if confirm "${MSG_SERVICES_CONFIRM_DISABLE} ${svc_name}?" "y"; then
                if _disable_service "${svc_name}"; then
                    disabled_count=$((disabled_count + 1))
                fi
            else
                log_info "${MSG_SERVICES_SKIPPED}: ${svc_name}"
            fi
            echo ""
        fi
    done < <(_check_unnecessary_services)

    if [[ ${found_active} -eq 0 ]]; then
        log_success "${MSG_SERVICES_ALL_CLEAR}"
    else
        log_success "${MSG_SERVICES_DISABLED_COUNT}: ${disabled_count}"
    fi
}

# 扫描并显示开放端口
scan_open_ports() {
    log_title "${MSG_SERVICES_PORTS_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_SERVICES_PORTS_DESC}${NC}"
    echo ""

    local port_count=0
    local unknown_count=0
    local seen_ports=""

    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue

        local proto port proc
        proto=$(echo "${line}" | cut -d: -f1)
        port=$(echo "${line}" | cut -d: -f2)
        proc=$(echo "${line}" | cut -d: -f4)

        # 去重（同端口可能多地址监听）
        if echo "${seen_ports}" | grep -q ":${port}:"; then
            continue
        fi
        seen_ports="${seen_ports}:${port}:"

        port_count=$((port_count + 1))

        if _is_safe_port "${port}"; then
            echo -e "  ${GREEN}●${NC} ${proto}/${port} (${proc:-unknown}) — ${MSG_SERVICES_PORT_STANDARD}"
        else
            echo -e "  ${YELLOW}▲${NC} ${proto}/${port} (${proc:-unknown}) — ${MSG_SERVICES_PORT_NONSTANDARD}"
            unknown_count=$((unknown_count + 1))
        fi
    done < <(_scan_listening_ports)

    echo ""
    echo -e "${MSG_SERVICES_PORTS_TOTAL}: ${port_count}"

    if [[ ${unknown_count} -gt 0 ]]; then
        echo ""
        log_warn "${MSG_SERVICES_PORTS_WARNING}: ${unknown_count} ${MSG_SERVICES_PORTS_UNKNOWN}"
    fi
    echo ""
}

# 检查服务管理状态（用于系统状态检测）
# 输出: key=value 格式
check_services_status() {
    local running_count=0
    local active_unnecessary=0

    # 统计运行中服务数
    running_count=$(_list_running_services | wc -l | tr -d ' ')

    # 统计活跃的不必要服务数
    while IFS= read -r line; do
        [[ -z "${line}" ]] && continue
        local status="${line##*:}"
        if [[ "${status}" == "active" ]]; then
            active_unnecessary=$((active_unnecessary + 1))
        fi
    done < <(_check_unnecessary_services)

    echo "services_running=${running_count}"
    echo "services_unnecessary=${active_unnecessary}"
}

# ============================================================================
# 交互式配置向导
# ============================================================================

run_services_wizard() {
    log_title "${MSG_SERVICES_WIZARD_TITLE}"

    # Check root
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    echo ""
    echo -e "${BOLD}${MSG_SERVICES_WIZARD_DESC}${NC}"
    echo ""

    local wizard_rc=0

    # ── Step 1: 审计运行中的服务 ──
    echo ""
    log_title "${MSG_SERVICES_STEP_AUDIT}"

    if confirm "${MSG_SERVICES_STEP_AUDIT_CONFIRM}" "y"; then
        audit_services
    else
        log_info "${MSG_SERVICES_STEP_SKIPPED}"
    fi

    # ── Step 2: 禁用不必要服务 ──
    echo ""
    log_title "${MSG_SERVICES_STEP_DISABLE}"

    echo -e "${MSG_SERVICES_CHECK_LIST_TITLE}:"
    for entry in "${UNNECESSARY_SERVICES[@]}"; do
        local name="${entry%%:*}"
        echo -e "  - ${name}"
    done
    echo ""

    if confirm "${MSG_SERVICES_STEP_DISABLE_CONFIRM}" "y"; then
        disable_unnecessary_services || wizard_rc=1
    else
        log_info "${MSG_SERVICES_STEP_SKIPPED}"
    fi

    # ── Step 3: 端口扫描 ──
    echo ""
    log_title "${MSG_SERVICES_STEP_PORTS}"

    if confirm "${MSG_SERVICES_STEP_PORTS_CONFIRM}" "y"; then
        scan_open_ports || wizard_rc=1
    else
        log_info "${MSG_SERVICES_STEP_SKIPPED}"
    fi

    # ── Summary ──
    echo ""
    log_title "${MSG_SERVICES_SUMMARY}"

    local status_output
    status_output=$(check_services_status)
    local running
    running=$(echo "${status_output}" | grep '^services_running=' | cut -d= -f2)
    local unnecessary
    unnecessary=$(echo "${status_output}" | grep '^services_unnecessary=' | cut -d= -f2)

    echo -e "  ${MSG_SERVICES_SUMMARY_RUNNING}: ${running}"
    echo -e "  ${MSG_SERVICES_SUMMARY_UNNECESSARY}: ${unnecessary}"

    if [[ ${wizard_rc} -eq 0 ]]; then
        log_success "${MSG_SERVICES_WIZARD_DONE}"
    else
        log_warn "${MSG_SERVICES_WIZARD_DONE} ${MSG_WIZARD_ERR_HINT}"
    fi

    return ${wizard_rc}
}

# ============================================================================
# 模块加载检查
# ============================================================================

# 标记 services.sh 已加载
readonly _SERVICES_LOADED=1

log_debug "services.sh loaded successfully"

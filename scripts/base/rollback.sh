#!/usr/bin/env bash
# rollback.sh - 延时回滚模块
# 提供 schedule_rollback() 和 cancel_scheduled_task() 函数
# 依赖: utils.sh (log_*)

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致

# Source guard: 防止重复加载
# 注意：不检查 _UTILS_LOADED，此模块由 utils.sh 在加载过程中 source，
#        此时 _UTILS_LOADED 尚未设置（在 utils.sh 末尾设置）。
#        log_* 等依赖函数在 source 时已定义，不影响运行。
if [[ "${_ROLLBACK_LOADED:-}" == "1" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || true
fi
readonly _ROLLBACK_LOADED=1

# ═══════════════════════════════════════════
# 延时执行（用于回滚保护）
# ═══════════════════════════════════════════

# 注意：不使用命令替换捕获 PID（命令替换子 shell 中的后台进程
# 会继承子 shell 的 stdout pipe，pipe 关闭后可能导致后台进程异常），
# 而是通过全局变量 _SCHEDULED_PID 传递 PID
#
# 安全约束：callback 参数仅接受本项目内部硬编码的函数名（如 "rollback_ssh"），
# 禁止传入用户输入或外部数据，以防命令注入。
schedule_rollback() {
    local delay="$1"
    local callback="$2"
    local description="${3:-Scheduled rollback}"

    log_info "${description} in ${delay} seconds"

    # Whitelist check: only allow known safe callbacks
    local allowed_callbacks=("rollback_ssh")
    local matched=0
    for cb in "${allowed_callbacks[@]}"; do
        [[ "${callback}" == "${cb}" ]] && { matched=1; break; }
    done
    if [[ ${matched} -eq 0 ]]; then
        log_error "Invalid callback: ${callback}"
        return 1
    fi

    # 在子 shell 中忽略 INT/TERM 信号，防止 sleep 被中断导致 callback 不执行
    (
        trap '' INT TERM
        sleep "${delay}" && "${callback}"
    ) &

    _SCHEDULED_PID=$!
    # disown 从 Shell 任务表中移除，防止父 Shell 退出时发送 SIGHUP
    disown "${_SCHEDULED_PID}" 2>/dev/null || true
    log_debug "Scheduled rollback task PID: ${_SCHEDULED_PID}"
}

# 取消延时任务
cancel_scheduled_task() {
    local pid="$1"

    if kill -0 "${pid}" 2>/dev/null; then
        # 验证进程确实是我们启动的 sleep 任务（防止 PID 复用误杀）
        local cmdline
        cmdline=$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null || echo "")
        if [[ "${cmdline}" == *"sleep"* ]] || [[ -z "${cmdline}" ]]; then
            kill "${pid}" 2>/dev/null
            log_debug "Cancelled scheduled task PID: ${pid}"
            return 0
        else
            log_warn "PID ${pid} does not appear to be a scheduled task, skipping kill"
            return 1
        fi
    fi
    return 1
}

# 只读查询：是否存在待执行的延时回滚任务
# 输出：存活 PID（存在）或 "none"（不存在）；退出码 0=存在 1=不存在
rollback_timer_status() {
    local pid
    pid="${ROLLBACK_PID:-${_SCHEDULED_PID:-}}"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
        local cmdline
        cmdline=$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null || echo "")
        if [[ "${cmdline}" == *"sleep"* ]] || [[ -z "${cmdline}" ]]; then
            echo "${pid}"
            return 0
        fi
    fi
    echo "none"
    return 1
}

log_debug "rollback.sh loaded successfully"

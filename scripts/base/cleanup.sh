#!/usr/bin/env bash
# cleanup.sh - Lite 模式运行痕迹清理模块
# 清理脚本运行产生的日志/备份/报告目录 + /tmp 临时文件，保留加固配置本身。

set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

# 源加载保护：防止重复 source 导致 readonly 变量错误
[ -n "${_CLEANUP_LOADED:-}" ] && return 0
readonly _CLEANUP_LOADED=1

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before cleanup.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 清理清单常量
# ═══════════════════════════════════════════

# 日志/备份/报告目录（绑定 utils.sh 的 LOG_DIR，含 /tmp/linux-one-key fallback）
# shellcheck disable=SC2034 # Public API — 供 Bats 测试覆盖
CLEANUP_LOG_DIR="${LOG_DIR}"
# /tmp 临时文件模式（精确前缀匹配，绝不触碰无关文件）
CLEANUP_TMP_PATTERNS=("/tmp/.ssh-askpass-*" "/tmp/.ssh-monitor-*")

# ═══════════════════════════════════════════
# 清理函数
# ═══════════════════════════════════════════

# 取消活跃的回滚定时器（若存在）
# 不硬依赖 security/ssh.sh（base 层不 import security），用 declare -F 探测
_cancel_active_rollback() {
    if declare -F cancel_rollback_timer &>/dev/null; then
        cancel_rollback_timer 2>/dev/null || true
    fi
}

# 清理 /tmp 临时文件（模式匹配，防空 glob）
# Gotcha: nullglob 使无匹配的 glob 展开为空，避免对不存在的路径执行 rm（无害报错）
# 设计意图：删除失败至少 log_warn，绝不静默吞掉（也不中止，保持失败容忍）
_cleanup_tmp_files() {
    local pattern
    for pattern in "${CLEANUP_TMP_PATTERNS[@]}"; do
        # nullglob：无匹配时 glob 展开为空数组，rm 不会被调用
        shopt -s nullglob
        # shellcheck disable=SC2206,SC2086 # 有意 glob 展开为匹配文件数组
        local files=( ${pattern} )
        shopt -u nullglob
        if [[ ${#files[@]} -gt 0 ]] && ! rm -f "${files[@]}" 2>/dev/null; then
            log_warn "${MSG_CLEANUP_PARTIAL}"
        fi
    done
}

# 清理 Lite 模式运行痕迹（幂等、失败容忍、清理后 LOG_DIR 不残留）
# Gotcha: log_* 内部调用 _ensure_log_dir，删除 LOG_DIR 后再写日志会重建该目录，
#         因此这里在删除成功后做一次兜底删除，保证最终状态无 LOG_DIR。
cleanup_lite_traces() {
    # ① 取消活跃回滚定时器，避免定时器到点找不到备份文件
    _cancel_active_rollback

    # ② 清理 /tmp 临时文件
    _cleanup_tmp_files

    # ③ 清理日志/备份/报告目录
    local cleaned=0
    if [[ -d "${CLEANUP_LOG_DIR}" ]]; then
        if rm -rf "${CLEANUP_LOG_DIR}" 2>/dev/null; then
            cleaned=1
        fi
    else
        cleaned=1
    fi

    if [[ "${cleaned}" -eq 1 ]]; then
        log_success "${MSG_CLEANUP_DONE}"
    else
        log_warn "${MSG_CLEANUP_PARTIAL}"
    fi

    # 兜底：log_* 的 _ensure_log_dir 可能重建 LOG_DIR，确保最终状态为已删除
    if [[ "${cleaned}" -eq 1 ]] && [[ -d "${CLEANUP_LOG_DIR}" ]]; then
        rm -rf "${CLEANUP_LOG_DIR}" 2>/dev/null || true
    fi

    return 0
}

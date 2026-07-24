#!/usr/bin/env bash
# backup.sh - 文件备份与恢复模块
# 提供 backup_file() 和 restore_file() 函数
# 依赖: utils.sh (log_*, BACKUP_DIR, TIMESTAMP)

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致

# Source guard: 防止重复加载
# 注意：不检查 _UTILS_LOADED，此模块由 utils.sh 在加载过程中 source，
#        此时 _UTILS_LOADED 尚未设置（在 utils.sh 末尾设置）。
#        log_* 等依赖函数在 source 时已定义，不影响运行。
if [[ "${_BACKUP_LOADED:-}" == "1" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || true
fi
readonly _BACKUP_LOADED=1

# ═══════════════════════════════════════════
# 备份函数
# ═══════════════════════════════════════════

# 备份文件
backup_file() {
    local file="$1"
    local description="${2:-${MSG_LOG_BACKUP}}"

    if [[ ! -f "${file}" ]]; then
        log_warn "${MSG_ERROR_FILE_NOT_FOUND}: ${file}"
        return 1
    fi

    local filename
    filename="$(basename "${file}")"
    # 使用 TIMESTAMP + PID + RANDOM 确保同一秒内的多次备份不会冲突（$$ 在脚本生命周期内恒定，单独使用不足以保证唯一性）
    local backup_path="${BACKUP_DIR}/${filename}.bak.${TIMESTAMP}.$$.${RANDOM}"

    log_step "${description}: ${file}"

    if cp -a "${file}" "${backup_path}"; then
        # shellcheck disable=SC2059
        log_success "$(printf "${MSG_BACKUP_SUCCESS}" "${backup_path}")"
        log_debug "Backed up ${file} to ${backup_path}"
        echo "${backup_path}"
        return 0
    else
        # shellcheck disable=SC2059
        log_error "$(printf "${MSG_BACKUP_FAIL}" "${file}")"
        return 1
    fi
}

# 恢复文件
restore_file() {
    local backup_path="$1"
    local target_path="$2"
    local description="${3:-${MSG_LOG_RESTORE}}"

    if [[ ! -f "${backup_path}" ]]; then
        log_error "${MSG_ERROR_FILE_NOT_FOUND}: ${backup_path}"
        return 1
    fi

    log_step "${description}: ${target_path}"

    if cp -a "${backup_path}" "${target_path}"; then
        # shellcheck disable=SC2059
        log_success "$(printf "${MSG_RESTORE_SUCCESS}" "${target_path}")"
        log_debug "Restored ${backup_path} to ${target_path}"
        return 0
    else
        log_error "${MSG_ERROR_RESTORE_FAILED}: ${target_path}"
        return 1
    fi
}

log_debug "backup.sh loaded successfully"

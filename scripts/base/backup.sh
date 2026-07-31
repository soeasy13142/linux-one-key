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
        # 记录原始绝对路径到 sidecar，供备份中心按原始路径恢复（写失败不阻断备份）
        echo "${file}" > "${backup_path}.meta" 2>/dev/null || true
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
    local target_path="${2:-}"
    local description="${3:-${MSG_LOG_RESTORE}}"

    if [[ ! -f "${backup_path}" ]]; then
        log_error "${MSG_ERROR_FILE_NOT_FOUND}: ${backup_path}"
        return 1
    fi

    # 目标未显式给出时，从 .meta sidecar 解析原始路径
    if [[ -z "${target_path}" ]]; then
        if [[ -f "${backup_path}.meta" ]]; then
            target_path="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
            # 安全：meta 必须是绝对路径
            if [[ -z "${target_path}" ]] || [[ "${target_path}" != /* ]]; then
                log_error "${MSG_ERROR_RESTORE_TARGET_REQUIRED}"
                return 1
            fi
        else
            log_error "${MSG_ERROR_RESTORE_TARGET_REQUIRED}"
            return 1
        fi
    fi

    # 安全：显式目标路径同样必须是绝对路径（spec §5.5），杜绝相对/空白填充路径写入进程 CWD
    if [[ -n "${target_path}" && "${target_path}" != /* ]]; then
        log_error "${MSG_ERROR_RESTORE_TARGET_NOT_ABSOLUTE}"
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

# 列出备份目录下所有备份文件（排除 .meta），按文件名倒序（TIMESTAMP 主导）
list_backups() {
    local backup_path
    local -a files=()
    [[ -d "${BACKUP_DIR}" ]] || return 0
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        files+=("${backup_path}")
    done
    [[ ${#files[@]} -eq 0 ]] && return 0
    printf '%s\n' "${files[@]}" | sort -r
}

# 读取备份的原始目标路径（.meta sidecar）
get_backup_target() {
    local backup_path="$1"
    if [[ ! -f "${backup_path}.meta" ]]; then
        return 1
    fi
    cat "${backup_path}.meta"
}

# 按 basename 前缀分组清理：每组保留最新 N 份（含 .meta），删除更旧
clean_old_backups() {
    local keep_per_name="${1:-5}"
    local backup_path base name file
    local -a names=() group=()
    [[ -d "${BACKUP_DIR}" ]] || return 0

    # 收集去重的文件名前缀
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        base="$(basename "${backup_path}")"
        name="${base%%.bak.*}"
        if ! printf '%s\n' "${names[@]}" | grep -qx "${name}"; then
            names+=("${name}")
        fi
    done

    for name in "${names[@]}"; do
        group=()
        for file in "${BACKUP_DIR}"/"${name}".bak.*; do
            [[ -f "${file}" ]] || continue
            [[ "${file}" != *.meta ]] || continue
            group+=("${file}")
        done
        local sorted=()
        while IFS= read -r file; do
            sorted+=("${file}")
        done < <(printf '%s\n' "${group[@]}" | sort -r)
        local idx=0
        for file in "${sorted[@]}"; do
            idx=$((idx + 1))
            if [[ "${idx}" -gt "${keep_per_name}" ]]; then
                rm -f "${file}" "${file}.meta"
                log_debug "Cleaned old backup: ${file}"
            fi
        done
    done
    return 0
}

log_debug "backup.sh loaded successfully"

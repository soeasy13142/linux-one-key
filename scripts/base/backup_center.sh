#!/usr/bin/env bash
# backup_center.sh - 备份/回滚中心编排逻辑（无交互，可测试）
# 依赖: utils.sh (log_*, BACKUP_DIR), backup.sh (restore_file)
set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

[ -n "${_BACKUP_CENTER_LOADED:-}" ] && return 0
readonly _BACKUP_CENTER_LOADED=1

# 按路径中的服务片段推导模块分组（兼容测试沙箱路径；仅用于展示/编排，不参与恢复正确性）
backup_center_module_of_path() {
    local path="$1"
    case "${path}" in
        */etc/ssh/*) echo "ssh" ;;
        */etc/sysctl.d/*) echo "kernel" ;;
        */etc/ufw/*|*/etc/firewalld/*) echo "firewall" ;;
        */etc/fail2ban/*) echo "fail2ban" ;;
        */etc/audit/*) echo "audit" ;;
        */etc/clamav/*) echo "clamav" ;;
        */etc/aide/*|*/var/lib/aide/*) echo "aide" ;;
        */etc/apt/*|*/etc/yum/*|*/etc/dnf/*) echo "autoupdate" ;;
        */etc/init.d/*|*/etc/chrony/*|*/etc/ntp*) echo "init" ;;
        */etc/fstab) echo "swap" ;;
        *) echo "other" ;;
    esac
}

# 列出存在备份的模块组（去重，无备份时无输出）
backup_center_list_modules() {
    local backup_path meta module
    local -a seen=()
    [[ -d "${BACKUP_DIR}" ]] || return 0
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        if [[ -n "${meta}" ]]; then
            module="$(backup_center_module_of_path "${meta}")"
        else
            module="other"
        fi
        if ! printf '%s\n' "${seen[@]}" | grep -qx "${module}"; then
            seen+=("${module}")
            echo "${module}"
        fi
    done
}

# 返回某目标路径的最新备份；无则返回 1
backup_center_latest_for_target() {
    local target="$1"
    local backup_path meta latest=""
    [[ -d "${BACKUP_DIR}" ]] || return 1
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        if [[ "${meta}" == "${target}" ]]; then
            if [[ -z "${latest}" ]] || [[ "${backup_path}" > "${latest}" ]]; then
                latest="${backup_path}"
            fi
        fi
    done
    if [[ -n "${latest}" ]]; then
        echo "${latest}"
        return 0
    fi
    return 1
}

# 对模块下每个目标文件，用其最新备份恢复到原始路径
backup_center_restore_module() {
    local module="$1"
    local backup_path meta module_name latest
    local -a restored=()
    local rc=0
    [[ -d "${BACKUP_DIR}" ]] || return 1
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        module_name="other"
        [[ -n "${meta}" ]] && module_name="$(backup_center_module_of_path "${meta}")"
        if [[ "${module_name}" == "${module}" && -n "${meta}" ]]; then
            # 每个目标文件只恢复一次（取最新备份）
            if ! printf '%s\n' "${restored[@]}" | grep -qx "${meta}"; then
                if latest="$(backup_center_latest_for_target "${meta}")"; then
                    # shellcheck disable=SC2059
                    if restore_file "${latest}" "${meta}" "$(printf "${MSG_BACKUP_CENTER_RESTORE_MODULE}" "${module}")"; then
                        restored+=("${meta}")
                    else
                        rc=1
                    fi
                fi
            fi
        fi
    done
    if [[ ${#restored[@]} -eq 0 ]]; then
        return 1
    fi
    return "${rc}"
}

# 恢复后的钩子：按目标路径重载服务 / 提示
backup_center_post_restore() {
    local backup_path="$1"
    local meta
    meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
    case "${meta}" in
        /etc/sysctl.d/*)
            log_info "${MSG_BACKUP_CENTER_RESTORE_SYSCTL}"
            if command -v sysctl &>/dev/null; then
                if sysctl --system 2>/dev/null; then
                    log_success "${MSG_BACKUP_CENTER_RESTORE_SYSCTL_SUCCESS}"
                else
                    log_warn "${MSG_BACKUP_CENTER_RESTORE_SYSCTL_FAILED}"
                fi
            fi
            ;;
        /etc/ssh/*)
            log_warn "${MSG_BACKUP_CENTER_RESTORE_SSH_HINT}"
            ;;
        /etc/ufw/*)
            if command -v ufw &>/dev/null; then
                ufw reload 2>/dev/null || true
            fi
            ;;
        /etc/firewalld/*)
            if command -v firewall-cmd &>/dev/null; then
                firewall-cmd --reload 2>/dev/null || true
            fi
            ;;
    esac
    return 0
}

log_debug "backup_center.sh loaded successfully"

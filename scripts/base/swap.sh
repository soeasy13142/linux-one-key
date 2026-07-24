#!/usr/bin/env bash
# swap.sh - Swap 配置模块
# 检测和创建 swap 文件，配置 swappiness 参数

set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# 源加载保护：防止重复 source 导致 readonly 变量错误
[ -n "${_SWAP_LOADED:-}" ] && return 0
readonly _SWAP_LOADED=1

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before swap.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 常量
# ═══════════════════════════════════════════

readonly SWAP_FILE_PATH="/swapfile"
# Swap size rules (in MB):
#   RAM < 2G  → SWAP = RAM * 1
#   RAM 2-8G  → SWAP = 4096 (fixed)
#   RAM > 8G  → SWAP = 4096 (default, max 8192 interactive)
readonly SWAP_RAM_LOW_THRESHOLD=2048       # MB, < 2G
readonly SWAP_RAM_MED_THRESHOLD=8192       # MB, 2-8G
readonly SWAP_SIZE_LOW_MULTIPLIER=1        # swap = RAM * 1.0
readonly SWAP_SIZE_MED_VALUE=4096          # MB, fixed for 2-8G RAM
readonly SWAP_SIZE_HIGH_DEFAULT=4096       # MB default for >8G RAM
# shellcheck disable=SC2034 # reserved for future interactive >8G RAM handling
readonly SWAP_SIZE_HIGH_MAX=8192           # MB max for >8G RAM
readonly SWAPPINESS_VALUE=10

# ═══════════════════════════════════════════
# 内部函数
# ═══════════════════════════════════════════

# 获取总内存 (MB)
_get_total_ram_mb() {
    local mem_total_kb
    mem_total_kb=$(grep "^MemTotal:" /proc/meminfo 2>/dev/null | awk '{print $2}')
    if [[ -z "${mem_total_kb}" ]]; then
        echo "0"
        return 1
    fi
    echo $((mem_total_kb / 1024))
}

# 计算推荐的 swap 大小 (MB)
_calculate_swap_size_mb() {
    local ram_mb="$1"
    ram_mb=$((ram_mb + 0))  # Ensure numeric

    if [[ "${ram_mb}" -le 0 ]]; then
        echo "0"
        return 1
    fi

    if [[ "${ram_mb}" -lt "${SWAP_RAM_LOW_THRESHOLD}" ]]; then
        # RAM < 2G: swap = RAM * 1
        echo $((ram_mb * SWAP_SIZE_LOW_MULTIPLIER))
    elif [[ "${ram_mb}" -le "${SWAP_RAM_MED_THRESHOLD}" ]]; then
        # RAM 2-8G: swap = 4096 (fixed)
        echo "${SWAP_SIZE_MED_VALUE}"
    else
        # RAM > 8G: swap = 4096 (default)
        echo "${SWAP_SIZE_HIGH_DEFAULT}"
    fi
}

# 获取当前 swap 信息
_get_current_swap_info() {
    if command -v swapon &>/dev/null; then
        swapon --show 2>/dev/null | tail -n +2 || true
    fi
}

# ═══════════════════════════════════════════
# 公共函数
# ═══════════════════════════════════════════

# 检查 swap 状态 (key=value 格式输出)
check_swap_status() {
    local swap_exists="no"
    local swap_size_mb="0"
    local swap_file=""
    local swappiness

    # Check swappiness
    swappiness=$(cat /proc/sys/vm/swappiness 2>/dev/null || echo "60")

    # Check swap using swapon
    if command -v swapon &>/dev/null; then
        local swap_info
        swap_info=$(swapon --show 2>/dev/null)
        if [[ -n "${swap_info}" ]]; then
            swap_exists="yes"
            swap_file=$(echo "${swap_info}" | awk 'NR>1 {print $1}' | head -1)
            swap_size_mb=$(echo "${swap_info}" | awk 'NR>1 {print $3}' | head -1)
            # Convert from KiB to MiB if needed
            if [[ -n "${swap_size_mb}" ]]; then
                swap_size_mb=$((swap_size_mb / 1024))
            fi
        fi
    fi

    echo "swap_exists=${swap_exists}"
    echo "swap_size_mb=${swap_size_mb:-0}"
    echo "swap_file=${swap_file:-}"
    echo "swappiness=${swappiness}"
}

# 设置 swap 文件
setup_swap() {
    log_title "${MSG_SWAP_TITLE}"

    # 检查磁盘空间
    local swap_dir
    swap_dir="$(dirname "${SWAP_FILE_PATH}")"
    local available_mb
    available_mb=$(df -m "${swap_dir}" 2>/dev/null | awk 'NR==2 {print $4}')
    if [[ -z "${available_mb}" ]] || [[ "${available_mb}" -lt 100 ]]; then
        log_error "Insufficient disk space for swap file"
        return 1
    fi

    # 检查当前 swap
    local current_info
    current_info=$(check_swap_status)
    local swap_exists
    swap_exists=$(echo "${current_info}" | grep "^swap_exists=" | cut -d= -f2)
    local swap_size_mb
    swap_size_mb=$(echo "${current_info}" | grep "^swap_size_mb=" | cut -d= -f2)

    # 获取推荐大小
    local ram_mb
    ram_mb=$(_get_total_ram_mb)
    local recommended_mb
    recommended_mb=$(_calculate_swap_size_mb "${ram_mb}")

    # 如果 swap 已存在且大小充足，跳过
    if [[ "${swap_exists}" == "yes" ]] && [[ "${swap_size_mb:-0}" -ge "${recommended_mb}" ]]; then
        log_success "${MSG_SWAP_EXISTS} (${swap_size_mb}MB >= ${recommended_mb}MB recommended)"
        return 0
    fi

    log_info "$(printf "${MSG_SWAP_RECOMMENDED}: %dMB (RAM: %dMB)" "${recommended_mb}" "${ram_mb}")"

    # 创建 swap 文件
    log_step "${MSG_SWAP_CREATING} (${recommended_mb}MB)..."
    if [[ -f "${SWAP_FILE_PATH}" ]]; then
        swapoff "${SWAP_FILE_PATH}" 2>/dev/null || true
    fi

    if ! dd if=/dev/zero of="${SWAP_FILE_PATH}" bs=1M count="${recommended_mb}" 2>/dev/null; then
        log_error "${MSG_SWAP_CREATE_FAIL}"
        return 1
    fi
    chmod 600 "${SWAP_FILE_PATH}"
    log_success "${MSG_SWAP_CREATE_DONE}"

    # 启用 swap
    log_step "${MSG_SWAP_ENABLING}"
    if ! mkswap "${SWAP_FILE_PATH}" 2>/dev/null; then
        log_error "${MSG_SWAP_ENABLE_FAIL}"
        return 1
    fi
    if ! swapon "${SWAP_FILE_PATH}" 2>/dev/null; then
        log_error "${MSG_SWAP_ENABLE_FAIL}"
        return 1
    fi
    log_success "${MSG_SWAP_ENABLE_DONE}"

    # 设置 swappiness
    log_step "${MSG_SWAP_SWAPPINESS}"
    mkdir -p /etc/sysctl.d 2>/dev/null || true
    echo "vm.swappiness=${SWAPPINESS_VALUE}" > /etc/sysctl.d/99-swap.conf
    sysctl -w vm.swappiness="${SWAPPINESS_VALUE}" 2>/dev/null || true
    log_success "$(printf "${MSG_SWAP_SWAPPINESS_DONE} (%d)" "${SWAPPINESS_VALUE}")"

    # 添加到 /etc/fstab
    log_step "${MSG_SWAP_FSTAB_ADD}"
    if ! grep -q "${SWAP_FILE_PATH}" /etc/fstab 2>/dev/null; then
        backup_file "/etc/fstab" "fstab backup before swap entry"
        echo "${SWAP_FILE_PATH} none swap sw 0 0" >> /etc/fstab
    fi
    log_success "${MSG_SWAP_FSTAB_DONE}"

    log_separator
    log_success "${MSG_SWAP_DONE}"
}

# 交互式 swap 向导
run_swap_wizard() {
    log_title "${MSG_SWAP_TITLE}"

    # 显示当前状态
    log_step "${MSG_SWAP_CHECKING}"
    local current_info
    current_info=$(check_swap_status)

    # Display status info
    local key value
    while IFS='=' read -r key value; do
        [[ -n "${key}" ]] && log_info "${key}: ${value}"
    done <<< "${current_info}"

    local ram_mb
    ram_mb=$(_get_total_ram_mb)
    local recommended_mb
    recommended_mb=$(_calculate_swap_size_mb "${ram_mb}")

    log_info "$(printf "${MSG_SWAP_RECOMMENDED}: %dMB (RAM: %dMB)" "${recommended_mb}" "${ram_mb}")"

    # 检查是否已有足够 swap
    local swap_exists
    swap_exists=$(echo "${current_info}" | grep "^swap_exists=" | cut -d= -f2)
    if [[ "${swap_exists}" == "yes" ]]; then
        local swap_size_mb
        swap_size_mb=$(echo "${current_info}" | grep "^swap_size_mb=" | cut -d= -f2)
        if [[ "${swap_size_mb:-0}" -ge "${recommended_mb}" ]]; then
            log_success "${MSG_SWAP_EXISTS} (${swap_size_mb}MB)"
            return 0
        fi
        log_info "$(printf "${MSG_SWAP_SIZE}: %dMB, ${MSG_SWAP_RECOMMENDED}: %dMB" "${swap_size_mb:-0}" "${recommended_mb}")"
    fi

    if confirm "$(printf "${MSG_SWAP_CONFIRM_CREATE} (%dMB)" "${recommended_mb}")" "n"; then
        setup_swap
    else
        log_info "${MSG_SWAP_SKIP}"
    fi
}

log_debug "swap.sh loaded successfully"

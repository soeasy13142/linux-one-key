#!/usr/bin/env bash
# mode.sh - Lite/Full 模式模块注册表
# 定义每个模块属于哪个模式层级

set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

[ -n "${_MODE_LOADED:-}" ] && return 0
readonly _MODE_LOADED=1

# ═══════════════════════════════════════════
# 模式常量
# ═══════════════════════════════════════════

readonly MODE_LITE="lite"
readonly MODE_FULL="full"

# ═══════════════════════════════════════════
# Lite 模式模块（核心安全基线）
# 这些模块在 Lite 和 Full 模式下都可用
# 选择标准：零/极低内存开销，纯配置修改优先
# ═══════════════════════════════════════════
# SSH - 纯配置修改，零内存开销
# Firewall - 1 个轻量 daemon，安全必需
# Kernel - 纯 sysctl 配置修改，零内存开销

# ═══════════════════════════════════════════
# Full 独占模块（Lite 模式不可用）
# Fail2Ban - Python 守护进程 ~50-100MB RSS
# Audit - auditd 守护进程 ~20-50MB RSS
# Users - 非安全基线需求
# Filesystem - 非安全基线需求
# Services - 非安全基线需求
# K3s - 重量级 Kubernetes

# Module lists
MODE_LITE_MODULES=("ssh" "firewall" "kernel")
MODE_FULL_MODULES=("fail2ban" "audit" "users" "filesystem" "services" "k3s" "swap" "autoupdate" "aide" "clamav" "rootkit")
MODE_ALL_MODULES=("ssh" "firewall" "kernel" "fail2ban" "audit" "users" "filesystem" "services" "k3s" "swap" "autoupdate" "aide" "clamav" "rootkit")

# ═══════════════════════════════════════════
# 模式判断函数
# ═══════════════════════════════════════════

# 检查当前模式是否为 Full
# 用法: if is_mode_full; then ...
is_mode_full() {
    [[ "${INSTALL_MODE:-full}" == "full" ]]
}

# 检查当前模式是否为 Lite
# 用法: if is_mode_lite; then ...
is_mode_lite() {
    [[ "${INSTALL_MODE:-full}" == "lite" ]]
}

# 检查指定模块是否在 Lite 模式可用
# 用法: if is_module_lite "ssh"; then ...
is_module_lite() {
    local module="$1"
    local m
    for m in "${MODE_LITE_MODULES[@]}"; do
        [[ "${m}" == "${module}" ]] && return 0
    done
    return 1
}

# 检查指定模块是否在 Full 模式可用
# 用法: if is_module_available "fail2ban"; then ...
is_module_available() {
    local module="$1"
    # 在 Lite 模式下，只返回 Lite 模块
    if is_mode_lite; then
        is_module_lite "${module}"
        return $?
    fi
    # Full 模式下，所有模块都可用
    return 0
}

# ═══════════════════════════════════════════
# 加固模式预设
# ═══════════════════════════════════════════

# Module lists for each hardening mode
MODE_BASIC_MODULES=("init" "ssh" "firewall" "kernel")
MODE_STANDARD_MODULES=("init" "ssh" "firewall" "fail2ban" "users" "kernel")
MODE_ADVANCED_MODULES=("init" "ssh" "firewall" "fail2ban" "users" "audit" "services" "filesystem" "kernel")

# Note: "swap" "autoupdate" "aide" "clamav" "rootkit" "k3s" are optional extras
# NOT included in Basic/Standard/Advanced presets but available from the main menu

# Get module list for a given hardening mode
# Usage: modules=$(get_mode_modules "basic")
get_mode_modules() {
    local mode="$1"
    case "${mode}" in
        basic) echo "${MODE_BASIC_MODULES[@]}" ;;
        standard) echo "${MODE_STANDARD_MODULES[@]}" ;;
        advanced) echo "${MODE_ADVANCED_MODULES[@]}" ;;
        *) echo "" ;;
    esac
}

# Check if a hardening mode is compatible with current Lite setting
# Usage: if is_mode_compatible "standard"; then ...
# Returns 0 if compatible, 1 if incompatible
is_mode_compatible() {
    local mode="$1"
    if is_mode_lite; then
        case "${mode}" in
            basic|custom) return 0 ;;
            standard|advanced) return 1 ;;
        esac
    fi
    return 0
}

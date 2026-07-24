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
MODE_FULL_MODULES=("fail2ban" "audit" "users" "filesystem" "services" "k3s")
MODE_ALL_MODULES=("ssh" "firewall" "kernel" "fail2ban" "audit" "users" "filesystem" "services" "k3s")

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

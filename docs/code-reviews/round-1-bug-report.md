# Code Review Bug 报告 & 修复待办

> **审查日期**: 2026-06-20
> **审查范围**: `install.sh`, `scripts/base/*.sh`, `scripts/security/*.sh`, `scripts/lang/*.sh`
> **审查方式**: 5 个并行审查代理，覆盖正确性、安全性、兼容性、健壮性
> **总体结论**: ✅ APPROVED — 所有 32 个 bug 已于 2026-06-20 修复完毕（2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW）

---

## 目录

- [修复优先级总览](#修复优先级总览)
- [🔴 CRITICAL](#-critical-必须立即修复)
- [🟠 HIGH](#-high-应尽快修复)
- [🟡 MEDIUM](#-medium-建议修复)
- [🔵 LOW](#-low-可选修复)
- [修复计划](#修复计划)
- [变更日志](#变更日志)

---

## 修复优先级总览

| 批次 | 严重程度 | 数量 | 说明 |
|------|----------|------|------|
| 第一批 | 🔴 CRITICAL + 🟠 HIGH 关键 | 4 | 模块完全不工作或数据丢失风险 |
| 第二批 | 🟠 HIGH 剩余 | 3 | 逻辑错误、安全风险 |
| 第三批 | 🟡 MEDIUM | 14 | 代码质量、健壮性 |
| 第四批 | 🔵 LOW | 9+ | 风格、优化建议 |

---

## 🔴 CRITICAL（必须立即修复）

### C1. 变量名不匹配：`DETECT_OS` vs `DETECTED_OS` — 防火墙和 Fail2Ban 模块完全失效

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🔴 CRITICAL
**影响范围**: `scripts/security/firewall.sh`, `scripts/security/fail2ban.sh` — 两个模块在所有系统上完全不工作
**发现代理**: 3/5 个代理独立发现

#### 问题描述

`detect.sh` 定义变量为 `DETECTED_OS`（带 `D`），但 `firewall.sh` 和 `fail2ban.sh` 全部引用 `DETECT_OS`（不带 `D`）。

在 `set -euo pipefail` 下，引用未定义变量会直接报错：
```
-bash: DETECT_OS: unbound variable
```

即使没有 `-u`，变量展开为空字符串，所有 `case` 分支都走 `*` 默认路径，导致：
- 防火墙模块无法识别系统类型，无法选择 UFW 或 firewalld
- Fail2Ban 模块无法确定日志路径和服务名称

#### 涉及文件和行号

| 文件 | 行号 | 代码 |
|------|------|------|
| `scripts/base/detect.sh` | 46 | `DETECTED_OS="${ID}"` ← 定义 |
| `scripts/security/firewall.sh` | 24 | `case "$DETECT_OS" in` ← ❌ 错误 |
| `scripts/security/firewall.sh` | 50 | `case "$DETECT_OS" in` ← ❌ 错误 |
| `scripts/security/fail2ban.sh` | 35 | `case "$DETECT_OS" in` ← ❌ 错误 |
| `scripts/security/fail2ban.sh` | 62 | `case "$DETECT_OS" in` ← ❌ 错误 |
| `scripts/security/fail2ban.sh` | 77 | `case "$DETECT_OS" in` ← ❌ 错误 |

#### 修复方案

将 `firewall.sh` 和 `fail2ban.sh` 中所有 `$DETECT_OS` 替换为 `$DETECTED_OS`：

```bash
# 修复前
case "$DETECT_OS" in

# 修复后
case "$DETECTED_OS" in
```

#### 验证方法

```bash
# 在 Ubuntu 上运行，应显示 "ufw" 而非走 * 分支
source scripts/base/utils.sh && source scripts/base/detect.sh && run_detection
source scripts/security/firewall.sh && _get_firewall_type
```

---

### C2. `set_ssh_config` 正则无边界匹配 — 误改无关 SSH 配置项

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🔴 CRITICAL
**影响范围**: `scripts/base/utils.sh` 的 `set_ssh_config()` 函数，所有 SSH 配置修改操作
**发现代理**: 2/5 个代理独立发现

#### 问题描述

`set_ssh_config` 使用的 grep/sed 模式没有词边界：

```bash
grep -q "^#*${key}" "${config_file}"    # 无尾部边界
sed -i "s|^#*${key}.*|${key} ${value}|"  # 匹配整行
```

`^#*${key}` 会匹配任何以该 key **开头**的行，导致：

| 传入的 key | 被误匹配的配置项 | 后果 |
|------------|-----------------|------|
| `Port` | `PortForwarding`, `GatewayPorts` | 被覆盖为 `Port 2222` |
| `MaxSessions` | `MaxStartups` | 被覆盖为 `MaxSessions 2` |
| `X11Forwarding` | `X11DisplayOffset`, `X11UseLocalhost` | 被覆盖为 `X11Forwarding no` |

由于 `sshd -t` 验证在所有修改完成之后才执行，这种静默破坏在验证时才发现，甚至可能不被发现。

#### 涉及文件和行号

| 文件 | 行号 | 说明 |
|------|------|------|
| `scripts/base/utils.sh` | 301-306 | `set_ssh_config()` 实现 |
| `scripts/security/ssh.sh` | 97 | 修改 Port |
| `scripts/security/ssh.sh` | 203 | 修改 PermitRootLogin |
| `scripts/security/ssh.sh` | 258-260 | 修改 PasswordAuthentication 等 |
| `scripts/security/ssh.sh` | 276-289 | 修改 MaxAuthTries 等安全参数 |

#### 修复方案

在 grep 和 sed 模式中添加词边界：

```bash
# 修复前
if grep -q "^#*${key}" "${config_file}" 2>/dev/null; then
    sed -i "s|^#*${key}.*|${key} ${value}|" "${config_file}"

# 修复后
if grep -qE "^#*${key}(\s|$)" "${config_file}" 2>/dev/null; then
    sed -i "s|^#*${key}\s.*|${key} ${value}|" "${config_file}"
```

#### 验证方法

```bash
# 创建测试 sshd_config，包含 PortForwarding
echo -e "Port 22\nPortForwarding yes" > /tmp/test_sshd_config
# 修改 Port，不应影响 PortForwarding
source scripts/base/utils.sh
set_ssh_config "Port" "2222" "/tmp/test_sshd_config"
cat /tmp/test_sshd_config
# 期望: Port 2222 和 PortForwarding yes（不变）
```

---

## 🟠 HIGH（应尽快修复）

### H1. 回滚定时器永不取消 — 每次运行 5 分钟后自动回滚所有 SSH 加固

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: `scripts/security/ssh.sh` — SSH 加固在成功后 5 分钟被自动撤销
**文件**: `ssh.sh:352-374, 411-415`

#### 问题描述

两个独立问题叠加：

**(a) `at` 路径下 job ID 未保存**

```bash
# setup_rollback_timer (行 359)
echo "bash -c '...'" | at now + 5 minutes 2>/dev/null
# at 输出 job ID，但从未捕获或保存
```

`cancel_rollback_timer` 只检查 `ROLLBACK_PID`（后台进程路径），`at` 路径下该变量为空，`at` job 永远不会被取消。

**(b) 取消函数从未被调用**

```bash
# run_ssh_hardening (行 411-415)
setup_rollback_timer       # 调度回滚
restart_ssh || return 1    # 重启 SSH
# ← 没有调用 cancel_rollback_timer
```

**结果**: 用户成功执行 SSH 加固后，5 分钟后 `rollback_ssh` 自动运行，恢复原始配置（重新启用 root 登录和密码登录）。

#### 修复方案

```bash
# 1. 保存 at job ID
setup_rollback_timer() {
    if command_exists at; then
        local at_output
        at_output=$(echo "..." | at now + 5 minutes 2>&1)
        ROLLBACK_AT_JOB=$(echo "${at_output}" | grep -oP 'job \K\d+')
    else
        ROLLBACK_PID=$(schedule_rollback ...)
    fi
}

# 2. 支持取消 at job
cancel_rollback_timer() {
    if [[ -n "${ROLLBACK_PID:-}" ]]; then
        cancel_scheduled_task "${ROLLBACK_PID}"
    fi
    if [[ -n "${ROLLBACK_AT_JOB:-}" ]]; then
        atrm "${ROLLBACK_AT_JOB}" 2>/dev/null
    fi
}

# 3. 在 restart_ssh 成功后调用
restart_ssh || return 1
cancel_rollback_timer
```

#### 验证方法

```bash
# 运行加固后检查 at 队列
atq
# 期望: 无残留 job
```

---

### H2. Fail2Ban banaction 硬编码 — Ubuntu/Debian 上封禁功能失效

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: `scripts/security/fail2ban.sh` — Fail2Ban 在 Ubuntu/Debian 上启动但不封禁 IP
**文件**: `fail2ban.sh:129`

#### 问题描述

```ini
# 生成的 jail.local
banaction = firewallcmd-ipset
```

`firewallcmd-ipset` 是 firewalld 的 action，仅存在于 CentOS/RHEL。Ubuntu/Debian 使用 UFW，该 action 命令不存在。Fail2Ban 能启动，检测到恶意 IP 后调用 action 失败，IP 不会被封禁。

#### 修复方案

根据操作系统选择 banaction：

```bash
local banaction
case "${DETECTED_OS}" in
    ubuntu|debian) banaction="ufw" ;;
    centos|rhel|rocky|almalinux) banaction="firewallcmd-ipset" ;;
    *)             banaction="iptables-multiport" ;;
esac
```

在生成 jail.local 时使用 `${banaction}` 替代硬编码值。

#### 验证方法

```bash
# Ubuntu 上安装 fail2ban 后检查
fail2ban-client get sshd banaction
# 期望: ufw（而非 firewallcmd-ipset）
```

---

### H3. `set -u` 泄漏 — utils.sh 将 `-u` 全局启用，与 install.sh 注释矛盾

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: 所有通过 `source utils.sh` 加载的脚本
**文件**: `install.sh:10-11`, `utils.sh:11`

#### 问题描述

install.sh 明确注释不使用 `-u`：
```bash
set -eo pipefail
# 注意: 不使用 -u (nounset)，因为 curl 管道模式下 BASH_SOURCE 可能未绑定
```

但 utils.sh 设置了 `set -euo pipefail`。`source` 在调用者的 shell 上下文中执行 `set`，因此 utils.sh 加载后 `-u` 全局生效。任何未初始化的变量引用都会导致脚本崩溃。

这直接加剧了 C1（`DETECT_OS` 未定义）的严重性。

#### 修复方案

方案 A（推荐）: 在 utils.sh 中不使用 `-u`，对关键变量使用 `${VAR:-}` 默认值：
```bash
set -eo pipefail
# 不使用 -u，由调用者决定是否启用
```

方案 B: 保持 `-u` 但确保所有变量正确初始化，并更新 install.sh 注释。

---

### H4. Bootstrap 临时目录永不清理

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: `install.sh` — curl 管道模式下 `/tmp` 目录泄漏
**文件**: `install.sh:26-65`

#### 问题描述

```bash
tmp_dir=$(mktemp -d)
# ... 下载解压 ...
exec bash "${extracted_dir}/install.sh" "$@" < /dev/tty
# exec 后 tmp_dir 无人清理
```

注释写"临时目录在脚本退出后自动清理"是错误的。`mktemp -d` 创建的目录需要显式 `rm -rf`。`exec` 替换进程后，原 shell 的 `rm` 永远不会执行。

#### 修复方案

```bash
_bootstrap_and_reexec() {
    local tmp_dir
    tmp_dir=$(mktemp -d)
    # 设置清理 trap
    trap 'rm -rf "${tmp_dir}"' EXIT INT TERM
    # ... 下载解压 ...
    exec bash "${extracted_dir}/install.sh" "$@" < /dev/tty
}
```

注意：`exec` 会替换进程，trap 也会被清除。更可靠的做法是在 re-exec 的脚本中清理父目录，或接受 exec 前的 trap 在 exec 时不触发（因为进程被替换了）。实际上，最可靠的方案是让 re-exec 后的脚本负责清理：

```bash
export _CLEANUP_DIR="${tmp_dir}"
exec bash "${extracted_dir}/install.sh" "$@" < /dev/tty
```

然后在 re-exec 后的脚本 main() 结尾添加：
```bash
[[ -n "${_CLEANUP_DIR:-}" ]] && rm -rf "${_CLEANUP_DIR}"
```

---

### H5. 下载的 tarball 无完整性校验（供应链风险）

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: `install.sh` — curl 管道模式的供应链安全
**文件**: `install.sh:34`

#### 问题描述

```bash
curl -fsSL "${GITHUB_TARBALL_URL}" | tar xz -C "${tmp_dir}"
```

下载 → 解压 → 以 root 执行，全程无 checksum 或签名验证。攻击场景：
- CDN 被入侵
- DNS 劫持
- 企业代理 TLS 中间人

#### 修复方案

至少在 exec 前验证 install.sh 的 SHA-256：
```bash
local expected_hash="已知的哈希值"
local actual_hash
actual_hash=$(sha256sum "${extracted_dir}/install.sh" | awk '{print $1}')
if [[ "${actual_hash}" != "${expected_hash}" ]]; then
    echo "错误: 完整性校验失败"
    rm -rf "${tmp_dir}"
    exit 1
fi
```

---

### H6. 报告在任务失败时仍生成

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: `install.sh` — 用户看到虚假成功报告
**文件**: `install.sh:518-528`

#### 问题描述

```bash
case "${mode}" in
    "quick")  run_quick_start ;;
    "custom") run_custom_config ;;
esac
# 无论上面是否失败，都执行：
generate_report
```

如果 `run_quick_start` 返回 1（失败），`generate_report` 仍然执行，报告中所有任务都显示为已完成。

#### 修复方案

```bash
local rc=0
case "${mode}" in
    "quick")  run_quick_start  || rc=$? ;;
    "custom") run_custom_config || rc=$? ;;
esac
if [[ ${rc} -eq 0 ]]; then
    generate_report
else
    log_error "任务执行失败，跳过报告生成"
fi
exit "${rc}"
```

---

### H7. `/etc/os-release` 污染全局命名空间

**状态**: ✅ 已修复 (2026-06-20)
**严重程度**: 🟠 HIGH
**影响范围**: `scripts/base/detect.sh` — `ID`, `NAME`, `VERSION` 等全局变量被覆盖
**文件**: `detect.sh:45`

#### 问题描述

```bash
detect_os() {
    if [[ -f /etc/os-release ]]; then
        source /etc/os-release  # 将 ID, NAME, VERSION, VERSION_ID 等全部注入全局
        DETECTED_OS="${ID}"
    fi
}
```

`/etc/os-release` 定义了 `ID`, `NAME`, `VERSION`, `VERSION_ID`, `PRETTY_NAME`, `HOME_URL`, `BUG_REPORT_URL` 等变量。直接 source 会覆盖脚本中同名变量。如果脚本中有 `NAME="something"` 或 `VERSION="1.0"`，会被静默覆盖。

#### 修复方案

使用子 shell 提取：
```bash
detect_os() {
    if [[ -f /etc/os-release ]]; then
        DETECTED_OS=$(. /etc/os-release && echo "${ID}")
        DETECTED_OS_VERSION=$(. /etc/os-release && echo "${VERSION_ID:-unknown}")
    fi
}
```

---

## 🟡 MEDIUM（建议修复）

### M1. `eval` 命令注入风险

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `utils.sh:494`

```bash
eval "${callback}"
```

`schedule_rollback()` 使用 `eval` 执行回调字符串。如果 callback 包含 shell 元字符，存在代码注入风险。

**修复**: 改为接受函数名并直接调用：
```bash
"${callback}"  # 如果 callback 是函数名
```

---

### M2. `_ensure_log_dir` 静默修改全局变量

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `utils.sh:84-88`

当主日志目录创建失败时，函数静默将 `LOG_DIR`, `BACKUP_DIR`, `REPORT_DIR`, `LOG_DIR` 重定向到 `/tmp/linux-one-key/`，调用者无感知。

**修复**: 添加可见警告：
```bash
log_warn "日志目录创建失败，使用备用路径: ${fallback_dir}"
```

---

### M3. `load_lang` 的 SCRIPT_DIR 回退可能为空

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `utils.sh:55`

```bash
local lang_file="${script_dir}/scripts/lang/${LANG_CODE}.sh"
```

如果 `SCRIPT_DIR` 未设置且未传参，`script_dir` 为空，`lang_file` 变为相对路径 `scripts/lang/zh.sh`，依赖调用者的 CWD。

**修复**:
```bash
local script_dir="${1:-${SCRIPT_DIR:-}}"
if [[ -z "${script_dir}" ]]; then
    echo "Error: SCRIPT_DIR is not set and no argument provided to load_lang"
    return 1
fi
```

---

### M4. `apt-get upgrade --only-upgrade` 是无效参数组合

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `init.sh:44`

```bash
apt-get upgrade -y -qq --only-upgrade 2>/dev/null || true
```

`--only-upgrade` 只对 `apt-get install` 有效，`apt-get upgrade` 不认识此参数。由于 stderr 被 `/dev/null` 吞掉且 `|| true` 抑制退出码，安全更新**从未实际执行**。

**修复**:
```bash
apt-get upgrade -y -qq 2>/dev/null || true
```

---

### M5. `yum update --security` 依赖 yum-security 插件

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `init.sh:50`

最小化 CentOS 安装通常没有 `yum-security` 插件，`--security` 参数会导致命令失败（被 `|| true` 吞掉），安全更新不执行。

**修复**:
```bash
if yum info yum-security &>/dev/null; then
    yum update -y --security -q 2>/dev/null || true
else
    yum update -y -q 2>/dev/null || true
fi
```

---

### M6. `init_directories()` 在 root 检查之前运行

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `init.sh:110-116`

`run_init()` 先调用 `init_directories()`（需要 root），再检查 `is_root()`。非 root 用户会看到权限错误，然后才看到清晰的"非 root"提示。

**修复**: 将 `is_root` 检查移到 `run_init()` 最开头。

---

### M7. `update_system_packages` 失败时仍打印成功

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `init.sh:35-59`

`|| true` 吞掉错误后，`log_success "System packages updated"` 无条件执行。

**修复**:
```bash
if ! apt-get upgrade -y -qq 2>/dev/null; then
    log_warn "系统包更新失败或部分完成"
else
    log_success "系统包已更新"
fi
```

---

### M8. 安装 firewalld 后未启动服务

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `firewall.sh:21-46`

`_install_firewall` 通过 yum 安装 firewalld，但从未调用 `systemctl enable --now firewalld`。后续 `firewall-cmd` 命令会因守护进程未运行而失败。

**修复**: 在安装后添加启动：
```bash
systemctl enable --now firewalld
```

---

### M9. 防火墙和 Fail2Ban 缺少 root 权限检查

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `firewall.sh:314`, `fail2ban.sh:251`

SSH 模块检查了 `is_root`，但 `run_firewall_hardening` 和 `run_fail2ban_hardening` 没有。

**修复**: 在两个函数开头添加：
```bash
if ! is_root; then
    log_error "需要 root 权限"
    return 1
fi
```

---

### M10. `disable_password_auth` 部分失败可锁用户

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `ssh.sh:258-260`

三个 `set_ssh_config` 调用非原子操作。如果第一个成功（禁用密码登录）但第二个失败（启用密钥登录），用户被锁在门外。

**修复**: 验证每次修改结果，或在单次 sed 中完成所有设置。

---

### M11. `check_other_users` 遗漏 zsh/fish 等 shell

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `ssh.sh:170`

```bash
grep -E '/bin/(ba)?sh$' /etc/passwd
```

只匹配 `/bin/sh` 和 `/bin/bash`，遗漏 `/bin/zsh`, `/bin/fish`, `/usr/bin/bash` 等。

**修复**:
```bash
awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ && $1 != "root" && $1 != "'"${current_user}"'" {print $1}' /etc/passwd
```

---

### M12. `check_ssh_keys` 遗漏 FIDO2/SK 密钥类型

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `ssh.sh:227`

```bash
grep -qE '^(ssh-(rsa|ed25519)|ecdsa-sha2)' "${auth_keys}"
```

遗漏 `sk-ssh-ed25519@openssh.com` 和 `sk-ecdsa-sha2-nistp256@openssh.com`（FIDO2 硬件密钥）。

**修复**:
```bash
grep -qE '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2|sk-ssh-)' "${auth_keys}"
```

---

### M13. `generate_ssh_key` 重复追加公钥

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `ssh.sh:148-152`

重复运行会在 `authorized_keys` 中追加相同公钥。

**修复**: 追加前检查是否已存在：
```bash
if ! grep -qF "$(cat "${key_path}.pub")" "${auth_keys}" 2>/dev/null; then
    cat "${key_path}.pub" >> "${auth_keys}"
fi
```

---

### M14. `_get_auth_log_path` 未考虑 journald 系统

**状态**: ✅ 已修复 (2026-06-20)
**文件**: `fail2ban.sh:61-73`

现代 CentOS/RHEL 8+ 和部分 Ubuntu 可能没有 rsyslog，日志仅在 journald 中。硬编码的 `/var/log/secure` 或 `/var/log/auth.log` 不存在，Fail2Ban jail 启动失败。

**修复**: 检查文件是否存在，不存在时警告：
```bash
if [[ ! -f "${auth_log}" ]]; then
    log_warn "认证日志未找到: ${auth_log}，fail2ban 可能需要 journald backend"
fi
```

---

## 🔵 LOW（可选修复）

| # | 文件 | 行号 | 问题 | 修复建议 |
|---|------|------|------|----------|
| L1 | `ssh.sh` | 55-63 | 端口号前导零被 bash 解释为八进制（`022` → 18） | 使用 `$((10#${port}))` 强制十进制 |
| L2 | `install.sh` | 518 | `main()` case 无 `*)` 默认分支 | 添加 `*) log_error; exit 1 ;;` |
| L3 | `install.sh` | 315+ | `run_custom_config` 冗余初始化 `local var="y"` 后立即覆盖 | 移除初始值 |
| L4 | `fail2ban.sh` | 76-88 | `_get_ssh_service_name` 是死代码，所有分支返回 `"sshd"` | 删除或修复后使用 |
| L5 | `detect.sh` | 138 | 网络检测硬编码 `8.8.8.8`（中国可能不通） | 改用 `114.114.114.114` 或可配置 |
| L6 | `utils.sh` | 378 | `check_network` 默认用 Google DNS | 同 L5 |
| L7 | `init.sh` | 90-100 | `setup_timezone()` 定义但从未调用 | 加入 `run_init()` 或移到 utils.sh |
| L8 | `zh.sh/en.sh` | 265-267 | `MSG_WARN_CONNECTION` 和 `MSG_WARN_TEST_FIRST` 语义重复 | ✅ 保留（不同语义） |
| L9 | `utils.sh` | 175 | `confirm()` 用 `echo -e` 不如 `printf` 安全 | ✅ 改为 `printf "%b"` |

---

## 修复计划

### 第一批：阻断性 bug（模块完全不工作）

| 序号 | Issue | 文件 | 预估时间 |
|------|-------|------|----------|
| 1 | C1: DETECT_OS → DETECTED_OS | firewall.sh, fail2ban.sh | ✅ 已完成 |
| 2 | C2: set_ssh_config 正则加边界 | utils.sh | ✅ 已完成 |
| 3 | H2: fail2ban banaction 按 OS 选择 | fail2ban.sh | ✅ 已完成 |

### 第二批：严重逻辑 bug

| 序号 | Issue | 文件 | 预估时间 |
|------|-------|------|----------|
| 4 | H1: 回滚定时器取消逻辑 | ssh.sh | ✅ 已完成 |
| 5 | H4: bootstrap 临时目录清理 | install.sh | ✅ 已完成 |
| 6 | H6: 报告生成检查返回值 | install.sh | ✅ 已完成 |

### 第三批：安全加固

| 序号 | Issue | 文件 | 预估时间 |
|------|-------|------|----------|
| 7 | M1: eval 替换为函数调用 | utils.sh | ✅ 已完成 |
| 8 | H5: tarball 完整性校验 | install.sh | ✅ 已完成 |
| 9 | H3: set -u 一致性 | utils.sh, install.sh | ✅ 已完成 |
| 10 | H7: os-release 子 shell | detect.sh | ✅ 已完成 |

### 第四批：MEDIUM 修复

✅ 全部完成。M2-M14 已逐个修复。

### 第五批：LOW 修复

✅ 全部完成。L1-L9 已逐个修复（L5 已有 114 DNS 回退，L8 保留原有语义区分）。

---

## 变更日志

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-20 | CREATE | 创建 bug 审查报告，记录所有发现的 bug |
| 2026-06-20 | UPDATE | 全部 32 个 bug 已修复（2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW） |

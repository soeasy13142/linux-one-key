# Full Project Code Review & Security Audit

**Reviewed**: 2026-07-21
**Scope**: 全项目代码 — `scripts/security/`, `scripts/base/`, `install.sh`, `scripts/lang/`, `config/`, `tests/unit/`
**Method**: 4 parallel agents (security-reviewer + code-reviewer ×3)
**Decision**: ⚠️ WARNING — 7 HIGH findings, recommend fixing before next release

---

## Summary

| Severity | Security | Base | Entry+i18n | Config+Test | **Total** |
|----------|----------|------|------------|-------------|-----------|
| 🔴 CRITICAL | 0 | 0 | 0 | 0 | **0** |
| 🟠 HIGH | 1 | 0 | 5 | 1 | **7** |
| 🟡 MEDIUM | 4 | 4 | 5 | 6 | **19** |
| 🔵 LOW | 6 | 3 | 2 | 2 | **13** |

**Risk Profile**: 无 CRITICAL 安全漏洞。主要风险是 SSH 回滚定时器在脚本退出时被误杀（可导致锁死）、passphrase 通过命令行参数泄露、以及若干代码结构和测试覆盖缺口。

---

## 🟠 HIGH Findings

### H1 — SSH 回滚定时器在脚本退出时被误杀 【最严重】

**File**: `scripts/security/ssh.sh:597-615` + `scripts/base/utils.sh:454-463`
**Module**: SSH / Base

`setup_rollback_timer` 在 `at` 命令不可用时降级为 `schedule_rollback`，创建后台子进程。但 `utils.sh` 的 `_cleanup_on_exit` **主动杀死** 该后台进程。如果用户在 10 分钟回滚定时器触发前退出脚本，SSH 将保持被破坏状态（重启失败），且回滚永远不会执行。

**Impact**: SSH 完全锁死，无自动恢复。**数据完整性风险**。

**Fix**: 在 `schedule_rollback()` 中执行 `disown $!` 后设置 `_SCHEDULED_PID`，或给 `_cleanup_on_exit` 添加 PID 白名单。

---

### H2 — `install.sh` 超长 (1353 行)

**File**: `install.sh` (1353 lines)

项目规范要求文件 < 800 行，实际 1353 行，超出 69%。

- `show_system_status()` 214 行（9 个近乎相同的状态检查块）
- `run_full_wizard()` 176 行（9 个相同的步骤块）
- `load_dependencies()` 110 行（11 个 DRY 违规的加载块）

**Fix**: 提取 `scripts/base/menu.sh`、`scripts/security/status.sh`、`scripts/security/wizard.sh`。

---

### H3 — 缺少 `set -u` 全覆盖

**Files**: `install.sh` + `scripts/security/*.sh` + `scripts/base/*.sh`

所有文件均未设置 `-u` (nounset)。理由是 curl 管道模式下 `BASH_SOURCE` 可能未绑定，但该条件在约 150 行处已被校验。此后变量名拼写错误（如 `DETECTED_OS_VERSIN`）会静默展开为空字符串而非报错。

**Fix**: 在 curl 管道校验通过后全局 `set -u`，对有意可选变量使用 `${VAR:-}` 模式。

---

### H4 — `firewall.bats` 测试覆盖严重不足

**File**: `tests/unit/firewall.bats`

5 个测试覆盖 `firewall.sh` 中 2/7+ 函数。以下函数零覆盖：
- `_ufw_reset`, `_ufw_set_defaults`, `_ufw_allow_port`
- `_firewalld_deny_icmp`, `run_firewall_wizard`

**Impact**: 修改 `_get_firewall_type` 破坏 Rocky/Alma 检测将无测试捕获。

**Fix**: 为每个未测试函数添加测试用例，补充 Rocky/Alma/Fedora 检测测试。

---

### H5 — `show_system_status()` 214 行（4x 规范）

**File**: `install.sh:330-543`

9 个近乎相同的状态检查块，每个重复相同模式：检查 → 设颜色/图标 → 打印行 → 加计数器 → 加入建议列表。任何呈现变更（如加新列）需编辑全部 9 块。

**Fix**: 提取 `_check_module_status` 辅助函数，用数据驱动循环替代。

---

### H6 — `run_full_wizard()` 176 行（3.5x 规范）

**File**: `install.sh:1077-1252`

9 个相同的步骤块（11-15 行/个），仅变量名和消息不同。

**Fix**: 定义步骤数据结构（title, skip_message, error_message, run_function, done_flag），迭代执行。

---

### H7 — `load_dependencies()` 110 行 DRY 违规

**File**: `install.sh:196-305`

11 个模块加载块每个重复 6-7 行完全相同的模式。增删模块需手动编辑重复代码。

**Fix**: 定义路径数组，循环迭代加载。

---

## 🟡 MEDIUM Findings（精选高影响项）

### M1 — SSH 密钥 passphrase 通过命令行参数泄露
**File**: `scripts/security/ssh.sh:222-233`
当 OpenSSH 不支持 `SSH_ASKPASS_REQUIRE=force` 时，降级到 `ssh-keygen -N "${passphrase}"`，passphrase 对所有用户通过 `/proc/<pid>/cmdline` 可见。
**Fix**: 使用 pipe/FIFO 代替 `-N` 参数。

### M2 — `/etc/shadow` 权限硬编码 RHEL 不安全
**File**: `scripts/security/filesystem.sh:20-28`
RHEL 系 `/etc/shadow` 应为 `000`（由 shadow-utils 访问），但代码硬编码期望 `640`。在 RHEL 上运行 `fix_critical_permissions` 会**放宽**权限。
**Fix**: 判断 OS 类型，RHEL 系使用 `000`。

### M3 — `_ensure_log_dir` 故障静默
**File**: `scripts/base/utils.sh:90-104`
当日志目录创建失败（磁盘满等），所有 `log_*` 写入静默失败。fallback 时 `LOG_DIR` 未更新导致目录指向不一致。
**Fix**: 不可写时输出非静默警告，fallback 时同步更新 `LOG_DIR`。

### M4 — `ufw` 命令硬编码在 i18n 消息中
**File**: `scripts/lang/zh.sh:357`, `scripts/lang/en.sh:356`
`MSG_FIREWALL_SSH_PORT22_CLOSE` 硬编码为 `sudo ufw deny 22/tcp`。在 firewalld 系统（CentOS/RHEL/Rocky）上用户执行会报错。
**Fix**: 运行时检测防火墙后端，动态生成正确的命令提示。

### M5 — `at` 作业字符串存在注入模式
**File**: `scripts/security/ssh.sh:604-607`
`SCRIPT_DIR` 直接拼接进经管道传给 `at` 的 shell 命令。若 `SCRIPT_DIR` 包含单引号则可能被利用。
**Fix**: 通过环境变量传递 `SCRIPT_DIR` 或在拼接前转义。

### M6 — `jail.local` IPv6 回环地址被丢弃
**File**: `config/fail2ban/jail.local` / `scripts/security/fail2ban.sh:148`
生成的 `ignoreip` 只写 `127.0.0.1/8`，漏掉 `::1`。IPv6 本地连接将被 Fail2Ban 处理。
**Fix**: 在生成规则中添加 `::1`。

### M7 — `audit.rules` 缺少 32-bit 系统调用变体
**File**: `config/audit/audit.rules:59-62`
`time_change` 规则只有 `b64` 架构变体，32 位进程修改系统时间不会被审计。
**Fix**: 为 `adjtimex` / `settimeofday` / `clock_settime` 添加 `b32` 变体。

### M8 — `hardening.conf` 遗漏关键 CIS 参数
**File**: `config/sysctl/hardening.conf`
缺少 `arp_ignore` / `arp_announce` / `unprivileged_bpf_disabled` / `kexec_load_disabled` / `perf_event_paranoid`。
**Fix**: 补充遗漏参数。

### M9 — SUID 缓存文件可被任意用户读取
**File**: `scripts/security/filesystem.sh:382-418`
SUID 计数缓存存储在 `/tmp/.linux-one-key-suid-cache`，世界可读且无完整性校验。
**Fix**: 设置更严格的权限或校验机制。

### M10 — `curl` 下载无超时
**File**: `install.sh:34`
`curl -fsSL` 无 `--connect-timeout` 或 `--max-time`。网络故障时脚本会无限挂起。
**Fix**: 添加 `--connect-timeout 15 --max-time 120`。

### M11 — `mktemp -d` 无信号清理
**File**: `install.sh:27`
用户 Ctrl+C 中断 curl 下载时，`$tmp_dir` 不会自动清理。
**Fix**: 添加 `trap 'rm -rf "${tmp_dir}"; exit 1' INT TERM`。

### M12 — `auditd.conf` 刷盘策略非最优
**File**: `config/audit/auditd.conf:19`
`flush = INCREMENTAL_ASYNC` 在崩溃时可能丢失未刷盘的审计事件。CIS Level 2 / STIG 推荐 `DATA` 或 `SYNC`。
**Fix**: 改为 `flush = DATA`。

### M13 — `DEBIAN_FRONTEND` 在 apt-get 调用中未设置
**Files**: `scripts/security/` 相关文件
若软件包触发 debconf 提示，交互式脚本可能无限等待输入。
**Fix**: 环境变量 `DEBIAN_FRONTEND=noninteractive`。

### M14 — 测试覆盖和文档问题
未列举（详见各 agent 报告原文，含防火墙测试覆盖缺口、审计测试 mock 过于宽泛、系统状态测试断言与测试名称不匹配等）。

---

## 🔵 LOW 示例（不穷尽）

| 文件 | 行 | 问题 |
|------|----|------|
| `install.sh` | 1035 | `find -printf` 是 GNU 扩展，macOS/BSD 不可用 |
| `install.sh` | 123 | SC2059 禁止掩盖 `printf` 格式串潜在风险 |
| `scripts/base/utils.sh` | 28-30 | `TIMESTAMP` 多余的空初始化 |
| `scripts/base/utils.sh` | 574 | `/proc/$pid/cmdline` 在 `hidepid` 场景下不可用 |
| `scripts/base/init.sh` | 9 | 不一致的单括号 `[` 风格 |
| `tests/unit/system-status.bats` | 34-39 | 断言 ≥5 但测试名声称"8 modules expected" |
| `tests/unit/audit.bats` | 328 | `auditctl` mock 过于宽泛 |

---

## 📋 配置模板检查

| 配置 | 状态 | 备注 |
|------|------|------|
| `config/fail2ban/jail.local` | ⚠️ | IPv6 `::1` 丢失，banaction 注释与实际代码不匹配 |
| `config/sysctl/hardening.conf` | ⚠️ | 遗漏 5 个 CIS 推荐参数 |
| `config/audit/audit.rules` | ⚠️ | 缺 b32 syscall 变体，RHEL 专有路径名 |
| `config/audit/auditd.conf` | ⚠️ | 刷盘策略 `INCREMENTAL_ASYNC` 非最优 |

---

## ✅ 做得好

- **无 CRITICAL 安全漏洞** — 没有硬编码密钥、SQL 注入、XSS
- **密码处理规范** — SSH 密钥使用 Ed25519，密码通过 `chpasswd` + here-string 处理（不暴露在 cmdline）
- **幂等和回滚设计** — 所有修改前备份，设计上支持回滚
- **i18n 完整** — 所有 `MSG_*` 变量在中英文文件中均存在且一致
- **输入校验良好** — install.sh 的 `case` 语句和 SSH 配置均做校验
- **文件结构清晰** — 模块化设计，职责分离合理

---

## 🎯 修复优先级建议

| 优先级 | 问题 | 工作量 | 影响 |
|--------|------|--------|------|
| P0 | H1 — 回滚定时器被误杀 | 1-3 行 | SSH 锁死风险 |
| P0 | H3 — 添加 `set -u` | 1 行 + 审计 | 阻止变量名 typo 静默失败 |
| P1 | M1 — passphrase 泄露 | 5-10 行 | 本地权限提升 |
| P1 | M2 — RHEL shadow 权限 | 3-5 行 | RHEL 安全降级 |
| P1 | M4 — ufw 硬编码 | 10-15 行 | firewalld 用户误导 |
| P1 | M6 — IPv6 回环丢失 | 1 行 | Fail2Ban IPv6 误判 |
| P1 | M10 — curl 无超时 | 1 行 | 网络故障时挂起 |
| P1 | M11 — mktemp 无清理 | 1 行 | /tmp 残留 |
| P2 | H2/H5/H6/H7 — 大函数拆分 | 中等 | 可维护性 |
| P2 | H4 — firewall.bats 覆盖 | 低+ | 测试质量 |
| P2 | M8 — hardening.conf 缺失 | 低 | CIS 合规性 |
| P2 | M12 — auditd.conf 刷盘 | 1 行 | 审计完整性 |

---

## 📊 验证结果

| 检查 | 结果 |
|------|------|
| ShellCheck (`shellcheck scripts/**/*.sh`) | 需运行确认 |
| Bats (`bats tests/unit/*.bats`) | 需运行确认 |
| 安全扫描 (`/security-scan`) | 推荐运行 |

---

## 文件审查清单

| 文件 | 类型 | 结果 |
|------|------|------|
| `install.sh` | 主入口 | ⚠️ 5 HIGH, 5 MEDIUM |
| `scripts/base/utils.sh` | 工具函数 | 🟡 2 MEDIUM |
| `scripts/base/detect.sh` | OS 检测 | ✅ OK |
| `scripts/base/init.sh` | 初始化 | ✅ OK |
| `scripts/base/report.sh` | 报告生成 | 🟡 1 MEDIUM |
| `scripts/security/ssh.sh` | SSH 加固 | 🟠 1 HIGH, 🟡 2 MEDIUM |
| `scripts/security/firewall.sh` | 防火墙 | ✅ OK (2 MEDIUM 已在配置模板侧) |
| `scripts/security/fail2ban.sh` | Fail2Ban | ✅ OK |
| `scripts/security/audit.sh` | 审计配置 | ✅ OK |
| `scripts/security/users.sh` | 用户管理 | ✅ OK |
| `scripts/security/kernel.sh` | 内核加固 | ✅ OK |
| `scripts/security/filesystem.sh` | 文件系统 | 🟡 2 MEDIUM |
| `scripts/security/services.sh` | 服务管理 | ✅ OK |
| `scripts/lang/zh.sh` | i18n 中文 | 🟡 1 MEDIUM |
| `scripts/lang/en.sh` | i18n 英文 | 🟡 1 MEDIUM |
| `config/fail2ban/jail.local` | 配置模板 | 🟡 2 MEDIUM |
| `config/sysctl/hardening.conf` | 配置模板 | 🟡 1 MEDIUM |
| `config/audit/audit.rules` | 配置模板 | 🟡 3 MEDIUM |
| `config/audit/auditd.conf` | 配置模板 | 🟡 1 MEDIUM |
| `tests/unit/*.bats` | 单元测试 | 🟠 1 HIGH, 🟡 2 MEDIUM |

---

*Generated by 4 parallel agents: security-reviewer, code-reviewer ×3*

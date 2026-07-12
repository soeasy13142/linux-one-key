# Code Review Round 4 — 全项目综合审查报告

**审查日期**: 2026-07-11
**审查范围**: 全项目 17 个 Shell 脚本 + 14 个测试文件 + 5 个配置文件模板
**审查方式**: 6 组 Sub Agent 并行审查 → 综合汇总
**上次全面审查**: 2026-06-26（Round 3 + 综合 Bug 审查）

---

## 摘要

| 严重程度 | 数量 | 说明 |
|----------|------|------|
| 🔴 CRITICAL | 4 | 安全/数据丢失风险 |
| 🟠 HIGH | 22 | 逻辑错误/回归/i18n 破坏 |
| 🟡 MEDIUM | 41 | 质量/代码异味 |
| 🔵 LOW | 21 | 风格/小问题 |
| **总计** | **88** | |

### 按模块分布

| 模块 | CRITICAL | HIGH | MEDIUM | LOW | 合计 |
|------|----------|------|--------|-----|------|
| 基础模块 (base/) | 0 | 3 | 5 | 3 | 11 |
| 安全模块 A (SSH/防火墙/Fail2Ban) | 2 | 5 | 7 | 2 | 16 |
| 安全模块 B (用户/内核/文件系统/审计/服务) | 0 | 1 | 3 | 4 | 8 |
| 主入口 + i18n (install.sh/lang) | 0 | 4 | 13 | 4 | 21 |
| 测试文件 (14 .bats) | 2 | 7 | 9 | 5 | 23 |
| 配置模板 + 开发工具 | 0 | 2 | 4 | 3 | 9 |

---

## 🔴 CRITICAL 发现

### C1. SSH 回滚定时器 `at` 路径硬编码 5 分钟，与 `ROLLBACK_DELAY=600` 不一致

- **文件**: `scripts/security/ssh.sh`
- **行**: 585
- **问题**: `setup_rollback_timer()` 有两个代码路径：
  - `at` 路径（585 行）：`at now + 5 minutes` — 硬编码 5 分钟
  - 后台进程路径（592 行）：`schedule_rollback "${ROLLBACK_DELAY}"` 其中 `ROLLBACK_DELAY=600`（10 分钟）
  - `ROLLBACK_DELAY` 曾从 300s 增加到 600s 给用户更多缓冲，但 `at` 路径未同步更新
- **影响**: 如果系统安装了 `at`，回滚定时器在 5 分钟后触发（而非预期的 10 分钟），用户安全窗口减半。可能造成 SSH 配置的过早回滚。
- **建议**: 将硬编码 `5 minutes` 替换为基于 `ROLLBACK_DELAY` 的计算值：`at now + $(( ROLLBACK_DELAY / 60 )) minutes`

### C2. `ufw status` 的 grep 依赖系统语言环境

- **文件**: `scripts/security/firewall.sh`
- **行**: 125
- **问题**: `_ufw_enable()` 验证 UFW 激活时 grep `ufw status` 输出中的 `"Status: active"`。在非英文系统上，`ufw` 输出本地化文本（如中文 `"状态: 已激活"`），导致 grep 失败，即使 UFW 已正确启用。
- **影响**: 在非英文语言环境的服务器上（东亚和欧洲部署常见），UFW 启用始终报告失败，阻塞整个防火墙向导。
- **建议**: 使用 `LC_ALL=C ufw status | grep -q "Status: active"` 强制英文环境，或检查 `ufw --force enable` 的退出码代替文本解析。

### C3. 测试 mock 了模块中不存在的函数（firewall.bats）

- **文件**: `tests/unit/firewall.bats`
- **行**: 57-85（测试行 57, 72, 112-127）
- **问题**: `_get_current_ssh_port` 的测试在测试体内完全重新定义该函数作为本地 mock，但 `_get_current_ssh_port` 不存在于 `firewall.sh` 中。实际使用的函数是 `utils.sh` 中的 `get_ssh_port()`。这些测试测试的是一个完全不存在的函数名。
- **影响**: 这些测试始终通过，无论 firewall.sh 或 utils.sh 发生了什么。对实际代码路径覆盖为零。`get_ssh_port()` 中的 bug 完全无法被检测到。
- **建议**: 测试 `utils.sh` 中的 `get_ssh_port()`（已在 utils.bats 中测试），或移除这些无意义的测试。

### C4. 测试 mock 了模块中不存在的函数（fail2ban.bats）

- **文件**: `tests/unit/fail2ban.bats`
- **行**: 36-64（测试行 36, 51）
- **问题**: 与 C3 相同模式。`_get_ssh_port` 的测试定义本地 mock，但 `_get_ssh_port` 不存在于 `fail2ban.sh` 中。实际函数是 `utils.sh` 中的 `get_ssh_port()`。
- **建议**: 移除这些无意义的测试或测试正确的函数。

---

## 🟠 HIGH 发现

### H1. init.sh 缺少 source guard，双 sourcing 会在 `set -e` 下崩溃

- **文件**: `scripts/base/init.sh`
- **行**: 1-17
- **问题**: 与 utils.sh（6-10 行）和 detect.sh（5-8 行）不同，init.sh 顶部没有 source guard。168 行的 `readonly _INIT_LOADED=1` 在二次 sourcing 时会失败（无法重复设置 readonly 变量）。`set -eo pipefail`（5 行）导致脚本立即退出。
- **影响**: 任何意外的 double-source 都会以不明确的错误信息静默杀死整个加固进程。
- **建议**: 在文件顶部添加与 utils.sh/detect.sh 相同的 source guard 模式。

### H2. report.sh 缺少 source guard，双 sourcing 会在 `set -e` 下崩溃

- **文件**: `scripts/base/report.sh`
- **行**: 1-17
- **问题**: 与 H1 完全相同的结构性回归。
- **建议**: 添加 source guard。

### H3. `apt-get update` 未在 `if` 内保护，网络/仓库失败会崩溃整个脚本

- **文件**: `scripts/base/init.sh`
- **行**: 47-48
- **问题**: `apt-get update -qq 2>/dev/null` 作为裸命令执行，未在 `if` 条件内或由 `|| true` 保护。如果 apt-get update 失败（常见场景：网络不可用、第三方仓库宕机、GPG 密钥问题），命令返回非零值，`set -e` 立即退出整个脚本。同一函数中的 dnf 和 yum 路径在 `if` 条件内优雅处理了失败。
- **影响**: 短暂的 apt 仓库故障或网络波动在真正的加固工作开始前就杀死整个运行。
- **建议**: 将 `apt-get update` 包裹在 `if` 模式中：`apt-get update -qq 2>/dev/null || log_warn "apt update failed, trying upgrade from cache"`

### H4. filesystem status GREEN（已加固）分支在 show_system_status 中不可达

- **文件**: `install.sh`
- **行**: 459-480
- **问题**: `fs_color` 起始为 `${RED}`。唯一条件检查在 `suid_count > 0` 时设其为 `${YELLOW}`。没有代码路径将 `fs_color` 设为 `${GREEN}`。因此 `if [[ "${fs_color}" == "${GREEN}" ]]` 分支（470 行）是死代码——文件系统永远不能显示为完全"已加固"。
- **影响**: 状态显示始终将文件系统显示为"部分"（黄色）或"未加固"（红色），即使运行了完整向导。
- **建议**: 添加 GREEN 触发条件，或移除死分支。

### H5. fail2ban 中多段硬编码中文完全绕过 i18n

- **文件**: `scripts/security/fail2ban.sh`
- **行**: 78, 237-239, 296-297
- **问题**: 警告信息硬编码为中文：
  - 78 行: `"认证日志文件未找到: ${auth_log}，fail2ban 可能需要 journald backend"`
  - 237-239 行: `"SSH 端口: $ssh_port"` 等
  - 完全绕过 MSG_* i18n 系统
- **影响**: 非中文用户无法理解警告，破坏了项目在 i18n 框架上的投入。
- **建议**: 为所有这些字符串创建 MSG_* 变量。

### H6. `enable_firewall()` 返回值在 `run_firewall_wizard()` 中未被检查

- **文件**: `scripts/security/firewall.sh`
- **行**: 394
- **问题**: `run_firewall_wizard()` 调用 `enable_firewall` 且未检查返回值。即使防火墙重新加载失败，向导也继续到 `show_firewall_status` 和 `log_success`。同样，`_install_firewall` 在 356 行虽由 `set -e` 处理了硬安装失败，但 `systemctl enable --now` 失败（43/53 行）被静默吸收。
- **影响**: 如果 `firewall-cmd --reload` 失败或 firewalld 未运行，向导报告成功，系统没有活动防火墙——虚假的安全感。
- **建议**: 使用 `|| return 1` 包裹 `enable_firewall` 并添加失败消息。

### H7. `_install_fail2ban()` 无条件使用 `yum`，而 `_install_firewall()` 使用带 fallback 的 `dnf`

- **文件**: `scripts/security/fail2ban.sh`
- **行**: 39-41
- **问题**: fail2ban 安装函数为 CentOS/RHEL 无条件使用 `yum`，而 firewall.sh 的 `_install_firewall()` 正确检查 `command_exists dnf` 再 fallback 到 `yum`。在 CentOS 8+ / RHEL 8+ 上 `yum` 可能未安装，fail2ban 安装将失败。此外，CentOS 8+ Stream 上 `yum install epel-release` 可能失败，代码未处理此失败模式。
- **影响**: 在新 CentOS/RHEL 系统上 fail2ban 安装静默失败（脚本 abort）。
- **建议**: 复制 `firewall.sh` 中的 `command_exists dnf` 模式，并为 EPEL 安装失败添加错误处理。

### H8. 向导函数仅测试存在性，未测试行为

- **文件**: 多个测试文件
- **行**: users.bats:164-192, kernel.bats:56-74, filesystem.bats:62-83, services.bats:144-183, audit.bats:342-360, ssh.bats（零行为测试）
- **问题**: 大量主要函数（尤其是向导/入口函数）没有对行为进行测试。`ssh.bats` 的问题尤其严重——几乎所有实际安全逻辑都未经测试（`backup_ssh_config`, `change_ssh_port`, `disable_root_login`, `disable_password_auth`, `configure_ssh_params`, `validate_ssh_config` 等）。
- **影响**: 函数可以被重命名、有逻辑错误、返回错误退出码或完全损坏，但所有测试仍然通过。
- **建议**: 至少为向导函数添加冒烟测试，验证它们返回预期退出码或输出期望的关键字符串。为 SSH 模块添加关键函数的行为测试。

### H9. `_is_known_suid_file` 缺少正向测试

- **文件**: `tests/unit/filesystem.bats`
- **行**: 106-113
- **问题**: 测试只检查 `_is_known_suid_file` 拒绝未知文件和空字符串，从未验证函数实际识别 `KNOWN_SUID_FILES` 中的已知 SUID 文件。
- **影响**: 如果函数通配符匹配逻辑损坏，无法被检测到。
- **建议**: 添加正向测试：`_is_known_suid_file "/usr/bin/passwd"`。

### H10. `_get_file_mode` 测试断言过弱

- **文件**: `tests/unit/filesystem.bats`
- **行**: 88-94
- **问题**: 测试仅检查 `[[ "${output}" =~ ^[0-9]+$ ]]`——输出是数字。即使 `_get_file_mode` 返回 `777` 或 `999`，测试也通过。
- **影响**: `_get_file_mode` 返回错误权限值的回归无法被捕获。
- **建议**: 断言实际预期值：`[[ "${output}" == "644" ]]`。

### H11. `_is_safe_port` 使用不一致的模式（直接调用 vs `run`）

- **文件**: `tests/unit/services.bats`
- **行**: 188-208
- **问题**: 正向测试直接调用 `_is_safe_port` 不使用 `run`，负向测试使用 `run` 检查 `${status}`。不一致，正向测试在某些 Bats 版本中可能静默变为无操作。
- **建议**: 对所有 `_is_safe_port` 测试统一使用 `run`。

### H12. `log_info writes to log file` 测试未使用 `run`

- **文件**: `tests/unit/utils.bats`
- **行**: 63-67
- **问题**: 测试直接调用 `log_info`（非 `run`），Bats 无法捕获非零退出码。如果 `log_info` 本身的日志写入失败但日志文件从之前的测试运行中仍然存在，测试可能不正确通过。
- **建议**: 添加 `run log_info "Test log entry"` 并在检查文件前验证 `[[ "${status}" -eq 0 ]]`。

### H13. `ausearch` 错误处理导致正常"无结果"情况脚本退出

- **文件**: `scripts/security/audit.sh`
- **行**: 387
- **问题**: `search_audit_log()` 在 `set -eo pipefail` 下执行 `ausearch`，但当没有匹配的审计事件时 ausp 正常返回非零值，整个流水线返回非零值导致脚本退出。
- **影响**: 使用在审计事件中没有匹配的 key 调用 `search_audit_log`（完全正常的场景）会终止脚本。
- **建议**: 附加 `|| true` 到流水线：`ausearch -k "${key}" -i 2>/dev/null | head -n "${max_results}" || true`

### H14. audit.rules 模板（full）缺少 execve 命令执行规则

- **文件**: `config/audit/audit.rules`
- **行**: 1（头部注释声称"full"）
- **问题**: 模板声称代表"full"级别但缺少 `audit.sh` 在 `_generate_full_rules()` 中包含的 `execve` 审计规则。模板也没有 audit.sh 中 `_generate_standard_rules()` 包含的 NetworkManager 和 boot 脚本监控。
- **影响**: 任何将模板作为"full"级别权威文档阅读的人都会错过命令执行被监控的事实。
- **建议**: 添加缺失的 execve 规则使模板与实际代码一致。

### H15. audit.rules 模板（full）缺少 5 个规则组的 b32 架构变体

- **文件**: `config/audit/audit.rules`
- **行**: 43-44, 46, 50, 58, 61
- **问题**: 模板只有 `arch=b64` 用于权限变更、所有者变更、模块系统调用、挂载操作和文件删除。代码的 `_generate_full_rules()` 始终为这些 syscall 规则发出 `arch=b64` 和 `arch=b32`。模板完全缺少 b32 行。
- **影响**: 在运行 32 位二进制文件的兼容模式 64 位系统上，某些审计事件不会被捕获。
- **建议**: 添加所有缺失的 b32 变体以匹配生成的代码。

---

## 🟡 MEDIUM 发现（精选，完整清单见各分组报告）

| 编号 | 文件 | 行 | 问题 |
|------|------|-----|------|
| M1 | utils.sh | 492-502 | `get_os_type` 重复 detect.sh 的检测逻辑（DRY 违反/偏离风险） |
| M2 | utils.sh | 241-248 | 日志头部覆盖 sourcing 时日志条目 |
| M3 | utils.sh | 322-328 | SSH 端口 sed 模式不处理 `# Port 22`（井号后空格）格式 |
| M4 | report.sh | 多处 | 硬编码英文 MSG_* fallback 字符串 |
| M5 | ssh.sh | ~20 处 | 多段硬编码英文字符串绕过 i18n |
| M6 | firewall.sh | 157-158 | firewalld 默认区域变更未迁移现有接口 |
| M7 | firewall.sh | 43-45,53-55 | `systemctl enable --now` 失败被吸收为警告 |
| M8 | firewall.sh | 165-168 | `_firewalld_allow_port` 的 `comment` 参数声明但未使用 |
| M9 | ssh.sh | 641,644 | `run_ssh_wizard` 在检查密码认证安全前禁用 root 登录 |
| M10 | filesystem.sh | 377 | `/tmp` 中可预测的临时文件路径——符号链接攻击向量 |
| M11 | services.sh | 85-91 | `_disable_service` 验证未检查服务是否实际被禁用 |
| M12 | users.sh | 215,222,225,229,233 | `setup_user_ssh_key` 中 5 处硬编码英文错误消息 |
| M13 | install.sh | 1087-1089 | 向导错误消息使用硬编码英文字符串 |
| M14 | install.sh | 618 | `get_main_menu_choice` 中硬编码中文字符串 |
| M15 | install.sh | 1257-1273 | `run_main_menu_loop` 缺少 `*)` default case |
| M16 | install.sh | 780,818,856,894,932,970 | 模块 4-9 子菜单状态文本硬编码中文 |
| M17 | install.sh | 105-131 | 帮助文本和未知参数错误硬编码英文 |
| M18 | lang/* | 59 个 key | 已定义但未引用的过期 MSG_* key |
| M19 | lang/* | 213-222 | 向导步骤编号跳过 [9/10] |
| M20 | firewall.bats | 32-54 vs 97-108 | 重复测试 |
| M21 | system-status.bats | 37 | 缩进模式未匹配制表符 |
| M22 | system-status.bats | 43 | 颜色常量正则表达式可能脆弱 |
| M23 | parse-args.bats | 14-35 | `_parse_args` 结构性测试脆弱 |
| M24 | view-report.bats | 43-51 | `MSG_TIME_*` key 测试脆弱 |
| M25 | audit.bats | 328-339 | 测试 mock 脆弱 |
| M26 | 多个测试 | 多处 | 不一致的函数存在性检查模式 |
| M27 | jail.local | 17 | 硬编码 RHEL-only banaction，缺少"仅参考"声明 |
| M28 | jail.local | 20 | 缺少 IPv6 回环 `::1` 的 `ignoreip` |
| M29 | gen-file-tree.sh | 56,89-93 | `eval` 与字符串拼接的 find 表达式 |
| M30 | gen-file-tree.sh | 85 | 树输出始终使用 `├──`，从未使用 `└──` |
| M31 | kernel.sh | 196,198 | 硬编码英文字符串 |
| M32 | services.sh | 273 | IPv6 地址中冒号分割的进程名丢失 |
| M33 | audit.sh | 367,368,372 | 硬编码中文字符串 |

> 完整 MEDIUM 级别清单见各分组 Agent 输出。

---

## 🔵 LOW 发现（精选）

> 完整 LOW 级别清单见各分组 Agent 输出。共 21 项，主要涉及：
> - 风格不一致（引号、缩进）
> - 注释过期或不完整
> - `detect_arch` 对未知架构不返回错误
> - 嵌套函数定义泄漏到全局作用域
> - `/proc` 读取在非 Linux 系统上浪费系统调用
> - 测试隔离边界未完全清理
> - jail.local 缺少"仅参考"声明（与 audit 模板不一致）

---

## 各分组报告

| 分组 | 报告 |
|------|------|
| 组 1 基础模块 | `install.sh` 缺少 `get_script_dir`；utils.sh/detect.sh/init.sh/report.sh 审查 |
| 组 2 安全模块 A | SSH 回滚定时器问题、UFW 语言环境依赖、fail2ban i18n 绕过 |
| 组 3 安全模块 B | `ausearch` 错误处理、可预测临时文件、`_disable_service` 验证不完整 |
| 组 4 主入口 + i18n | GREEN 分支死代码、多处硬编码字符串、59 个过期 key、步骤编号错位 |
| 组 5 测试文件 | 2 个不存在的 mock 函数、大量缺少行为测试、脆弱测试断言 |
| 组 6 配置 + 开发工具 | audit.rules 模板与代码不同步、jail.local 缺少声明、`eval` 使用 |

---

## 关键优先修复建议

### 应立即修复（CRITICAL）

1. **C1** — SSH 回滚 `at` 路径 5 分钟 vs 10 分钟 → 用户安全窗口减半
2. **C2** — UFW 状态检查依赖英文语言环境 → 非英文系统防火墙向导完全阻塞
3. **C3/C4** — 测试 mock 不存在的函数 → 虚假的测试信心

### 建议本次发布前修复（HIGH）

1. **H1/H2** — init.sh/report.sh 缺少 source guard → double-source 崩溃
2. **H3** — `apt-get update` 未保护 → 网络故障时整个脚本退出
3. **H5/H6/H7** — fail2ban i18n/返回值检查/安装兼容性
4. **H13** — `ausearch` 正常无结果导致脚本退出

### 建议下个版本修复（MEDIUM）

- i18n 统一：install.sh + ssh.sh + fail2ban.sh 中约 30 处硬编码字符串
- audit.rules 模板与代码同步
- 测试增强：添加向导函数行为测试、`ssh.bats` 关键函数测试
- MEDIUM 级安全项：可预测临时文件、firewalld 区域迁移

---

## 与上次审查的对比

| 指标 | Round 2 (06-20) | Round 3 (06-23) | Round 4 (07-11) |
|------|-----------------|-----------------|-----------------|
| CRITICAL | 10 | 0 | 4 |
| HIGH | 15 | 3 | 22 |
| MEDIUM | 13 | 4 | 41 |
| LOW | 12 | 4 | 21 |
| 总计 | 50 | 11 | 88 |

> 注意：数量差异部分反映了审查范围的扩大（Round 4 覆盖了测试文件、配置模板和 i18n 文件），以及新代码（主菜单重构 v2 ~+240 行）的引入。Round 3 的 11 个发现全部已修复，本次未检出回归。

---

## 文件综述

| 文件 | 行数 | CRITICAL | HIGH | MEDIUM | LOW | 问题密度 (/100行) |
|------|------|----------|------|--------|-----|-------------------|
| install.sh | 1325 | 0 | 1 | 8 | 3 | 0.9 |
| scripts/base/utils.sh | 638 | 0 | 0 | 3 | 1 | 0.6 |
| scripts/base/init.sh | 170 | 0 | 2 | 0 | 0 | 1.2 |
| scripts/base/report.sh | 238 | 0 | 1 | 1 | 1 | 1.3 |
| scripts/security/ssh.sh | 697 | 1 | 1 | 3 | 1 | 0.9 |
| scripts/security/firewall.sh | 429 | 1 | 1 | 3 | 0 | 1.2 |
| scripts/security/fail2ban.sh | 362 | 0 | 3 | 1 | 1 | 1.4 |
| scripts/security/audit.sh | 514 | 0 | 1 | 0 | 2 | 0.6 |
| scripts/security/services.sh | 409 | 0 | 0 | 1 | 1 | 0.5 |
| scripts/security/users.sh | 438 | 0 | 0 | 1 | 0 | 0.2 |
| scripts/security/kernel.sh | 344 | 0 | 0 | 0 | 1 | 0.3 |
| scripts/security/filesystem.sh | 403 | 0 | 0 | 1 | 0 | 0.2 |
| tests/unit/*.bats (14 个) | 2040 | 2 | 7 | 9 | 5 | 1.1 |
| config/* | 354 | 0 | 2 | 2 | 1 | 1.4 |
| scripts/dev/gen-file-tree.sh | 123 | 0 | 0 | 2 | 1 | 2.4 |
| scripts/lang/*.sh | 1652 | 0 | 0 | 2 | 0 | 0.1 |
| **总计** | **~10356** | **4** | **22** | **41** | **21** | **0.85** |

---

*本报告由 6 组并行 Code Review Agent 生成，综合汇总于 2026-07-11。*

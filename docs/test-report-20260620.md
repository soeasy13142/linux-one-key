# Ubuntu 24.04 ARM64 真机测试报告 (Round 2)

> **测试日期**: 2026-06-20
> **测试环境**: Ubuntu 24.04.4 LTS (Noble Numbat), aarch64, Linux 6.8.0-124-generic
> **测试对象**: linux-one-key
> **测试分支**: main @ 8f4213c
> **测试人员**: Charlie

---

## 测试目标

在真实 Ubuntu 虚拟机上，模拟用户通过 `curl` 远程下载执行的方式，测试 linux-one-key 一键安全加固脚本的各项功能。

## 测试环境

| 项目 | 详情 |
|------|------|
| **VM IP** | 10.211.55.8 |
| **系统** | Ubuntu 24.04.4 LTS (Noble Numbat) |
| **内核** | 6.8.0-124-generic |
| **架构** | aarch64 (ARM64) |
| **用户** | root |
| **包管理器** | apt |
| **GitHub 连接** | 正常（raw.githubusercontent.com 可达） |

---

## Round 1 Bug 修复验证

Round 1 测试报告（@ 347000a）发现的 bugs，本次验证结果：

| Round 1 Bug | 描述 | 状态 |
|-------------|------|------|
| Bug #1 | SHA256SUMS URL 用错 → curl 管道崩溃 | ✅ 已修复 |
| Bug #3 | pipefail+grep 全局崩溃 | ✅ 已修复 |
| Bug #4 | SHA256SUMS 校验形同虚设 | ✅ 已修复（换用 raw URL） |
| Bug #5 | sshd vs ssh 服务名错误信息 | ✅ 已修复（加 systemctl list-units 检测） |
| Bug #6 | 日志函数 stdout/stderr 不一致 | ✅ 已修复（统一使用 `>&2`） |
| Bug #7 | schedule_rollback log_info 污染 PID | ✅ 已修复（改用 `echo >&2`） |
| Bug #8 | summary 标题硬编码英文 | ⬜ 未验证 |
| Bug #9 | curl --help 末尾 curl 抱怨 | ⬜ 未测试 |

**Round 1 修复成果**: 6/9 个 bugs 已确认修复，curl 管道模式恢复可用。

---

## Round 2 测试结果

| TC-ID | 测试场景 | 命令 | 状态 |
|-------|---------|------|------|
| TC-01 | curl 管道 + --status | `curl .../install.sh \| bash -s -- --status` | ✅ PASS |
| TC-02 | curl 管道 + --ssh | `curl .../install.sh \| bash -s -- --ssh` | ❌ FAIL |
| TC-03 | curl 管道 + --firewall | `curl .../install.sh \| bash -s -- --firewall` | ✅ PASS |
| TC-04 | curl 管道 + --fail2ban | `curl .../install.sh \| bash -s -- --fail2ban` | ✅ PASS |

---

## 详细测试记录

### TC-01: curl 管道 + `--status` ✅

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | bash -s -- --status
```

**结果**: 通过。Bootstrap 下载正常，SHA256SUMS 校验通过，系统检测输出正确：

```
操作系统: ubuntu 24.04
系统架构: arm64
当前用户: root (root 用户)
包管理器: apt
系统检测完成
```

**新 Bug #2**: `--status` 只显示了系统检测摘要（OS/架构/用户/包管理器），未显示安全状态详情（SSH 端口、防火墙状态、Fail2Ban 状态）。`show_system_status()` 仅在交互模式可用。

---

### TC-02: curl 管道 + `--ssh` ❌

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | bash -s -- --ssh
```

**结果**: **FAIL** — SSH 回滚机制在 `restart_ssh` 调用前提前触发，所有 SSH 加固修改被恢复。

**完整执行时序**:

```
1. [✓] 系统检测完成
2. [✓] SSH 配置备份 → /var/log/linux-one-key/backups/sshd_config.bak.20260620_134310
3. [✓] SSH 端口修改: 22 → 2222
4. [✓] SSH 密钥生成: Ed25519 (/root/.ssh/id_ed25519)
5. [✓] 禁止 root 远程登录
6. [✓] 禁止密码登录
7. [✓] SSH 安全参数配置
8. [✓] SSH 配置语法验证通过 (sshd -t)
9. [→] setup_rollback_timer → schedule_rollback(300, "rollback_ssh")
10. [!] rollback_ssh 立即触发 ← BUG: 应在 300 秒后触发
11. [→] 恢复备份配置 → 重启 SSH
12. [✓] SSH 已回滚到原始状态
13. [→] restart_ssh (主流程)
14. [✓] 检测到新连接，取消回滚定时器 ← 回滚后取消（无效）
15. [✓] SSH 安全加固完成 ← 误导性成功消息
16. [✓] 报告生成
```

**回滚后的实际 SSH 配置**:
```
Port:                    22 (默认，未修改)
PermitRootLogin:         yes (已恢复原始)
PasswordAuthentication:  (默认 yes，未修改)
PubkeyAuthentication:    (默认 yes)
SSH 密钥:               /root/.ssh/id_ed25519 存在（密钥未被回滚）
```

**新 Bug #1 (CRITICAL)**: SSH 回滚定时器在 `setup_rollback_timer` 返回后立即触发 `rollback_ssh`，早于 `restart_ssh` 调用，导致所有 SSH 配置修改在生效前被恢复。此 Bug 与 Round 1 Bug #2 表现不同：

| 维度 | Round 1 Bug #2 | Round 2 新 Bug #1 |
|------|---------------|-------------------|
| 触发时机 | 5 分钟后（定时器正常触发） | setup_rollback_timer 返回后立即 |
| 根因 | log_info 污染 PID → cancel 无效 | **待排查**（log_info 已修复为 stderr） |
| 影响 | 用户以为加固成功，5 分钟后悄悄回滚 | 在 restart_ssh 前就回滚了，修改从未生效 |

**可能的排查方向**:
1. `schedule_rollback` 中命令替换 `$(...)` 与后台进程 `(sleep 300 && ...) &` 是否有竞态
2. `restart_ssh` 是否实际未被调用（输出时序问题）
3. 是否 `ERR trap` 在 `setup_rollback_timer` 后某处触发导致回滚
4. `at` 命令存不存在？系统中已确认 `at` 未安装，走的是 fallback 分支

---

### TC-03: curl 管道 + `--firewall` ✅

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | bash -s -- --firewall
```

**结果**: 通过。UFW 安装、策略配置、端口开放、防火墙启用全部正常。

```
UFW 安装:     已安装 (UFW)
默认策略:     deny incoming, allow outgoing
开放端口:     22/tcp (防锁死), 80/tcp (HTTP), 443/tcp (HTTPS)
              IPv6 规则自动创建 ✓
ICMP:         UFW 默认允许
防火墙状态:   active
```

**观察**: 网络检测失败（`ping 8.8.8.8` 不通）但脚本继续执行，容错机制正确。

---

### TC-04: curl 管道 + `--fail2ban` ✅

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | bash -s -- --fail2ban
```

**结果**: 通过。Fail2Ban 安装、jail 配置、服务启动全部正常。

```
安装:       Fail2Ban 安装完成
Jail:       sshd (端口 22, journald 模式)
配置:       封禁 3600s / 检测窗口 600s / 最大重试 5 次
服务状态:   active (running), enabled
管理命令:   正常显示
```

---

## Round 2 新 Bug 清单

### 新 Bug #1 (CRITICAL) — SSH 回滚定时器提前触发（即时回滚）

- **严重程度**: CRITICAL
- **位置**: `scripts/security/ssh.sh:367-383` `setup_rollback_timer()` + `scripts/base/utils.sh:542-555` `schedule_rollback()`
- **症状**: `setup_rollback_timer` 调用后，`rollback_ssh` 在 `restart_ssh` 之前就执行了，所有 SSH 修改未经生效就被回滚
- **影响**: SSH 加固完全无效，但脚本输出"SSH 安全加固完成"并生成报告，给用户造成成功假象
- **复现率**: 1/1
- **与 Round 1 Bug #2 的区别**: Round 1 是定时器无法取消（5 分钟后回滚），Round 2 是定时器立即触发（不等 300 秒）。Round 1 的根因（log_info → stdout 污染 PID）在 Round 2 已修复（log_info 统一改 `>&2`），但仍出现新的回滚提前触发问题
- **建议**: 需在 `setup_rollback_timer` 和 `restart_ssh` 之间加 debug 输出来定位"即时触发"根因；考虑重新设计回滚机制

### 新 Bug #2 (MEDIUM) — `--status` 参数未展示安全状态详情

- **严重程度**: MEDIUM
- **位置**: `install.sh:734-737` `main()` status case
- **症状**: `--status` 只执行 `run_detection` + `print_detection_summary`，未调用 `show_system_status()`
- **影响**: 用户无法通过 `--status` 查看 SSH/Firewall/Fail2Ban 的详细状态
- **建议**: status case 增加 `show_system_status` 调用

### 新 Bug #3 (LOW) — Bootstrap 临时目录未清理

- **严重程度**: LOW
- **位置**: `install.sh:75` `export _CLEANUP_DIR` + `install.sh:768-770` cleanup
- **症状**: `/tmp/tmp.XXXXXXXX/linux-one-key-main/` 残留未清理
- **影响**: 磁盘空间缓慢泄露
- **可能根因**: `exec bash` 后 `_CLEANUP_DIR` 环境变量在进程替换中丢失，或 cleanup 路径 `[[ -n "${_CLEANUP_DIR:-}" ]]` 条件不满足（实测 `env | grep _CLEANUP` 返回空）

### 新 Bug #4 (LOW) — 版本号未更新

- **严重程度**: LOW
- **位置**: `scripts/base/utils.sh:19` `readonly SCRIPT_VERSION="0.1.0"`
- **症状**: 欢迎界面显示 `Version: 0.1.0`，但项目已迭代 20+ 个 commit
- **建议**: 更新版本号或从 git tag 动态获取

---

## 正常工作项（更新）

| 功能 | 状态 | 备注 |
|------|------|------|
| curl 管道下载 + SHA256SUMS 校验 | ✅ | Round 1 修复 |
| Bootstrap tarball 下载解压 | ✅ | 正常 |
| 系统检测（OS/架构/包管理器） | ✅ | Ubuntu 24.04 ARM64 正确 |
| 非交互模式 (AUTO_ACCEPT) | ✅ | auto-confirm 正确 |
| 参数解析 | ✅ | --status/--ssh/--firewall/--fail2ban 正确 |
| UFW 防火墙配置 | ✅ | 安装/策略/端口/启用 正常 |
| UFW IPv6 规则 | ✅ | 自动创建 |
| UFW 22 端口防锁死 | ✅ | 始终放通 |
| Fail2Ban 安装配置 | ✅ | 安装/jail/启动 正常 |
| SSH 密钥生成 (Ed25519) | ✅ | 正确 |
| SSH 密钥幂等检测 | ✅ | 已存在则跳过 |
| SSH 配置写入 | ✅ | 正确写入 sshd_config |
| SSH 配置验证 (sshd -t) | ✅ | 验证通过 |
| 配置备份 | ✅ | 时间戳备份正常 |
| 报告生成 | ✅ | 每次运行生成 |
| 中文 i18n | ✅ | 正常显示 |
| log_info/log_success 等输出 `>&2` | ✅ | Round 1 修复 |
| SSH 服务名检测 (ssh vs sshd) | ✅ | Round 1 修复 |
| **SSH 回滚保护** | ❌ | 新 Bug #1 — 提前触发 |
| **SSH 加固结果保留** | ❌ | 新 Bug #1 — 修改被回滚 |
| **--status 详细状态** | ❌ | 新 Bug #2 — 仅有检测摘要 |
| **临时目录清理** | ❌ | 新 Bug #3 — 残留 |

---

## Bug 关系总览

```
Round 2 新 Bug                  Round 1 已修复 Bug
─────────────────               ─────────────────
Bug #1 [CRITICAL]               Bug #1 [CRITICAL] ✅ SHA256SUMS URL
  SSH 回滚提前触发                Bug #2 [CRITICAL] ⚠️ 部分修复（log_info→stderr）
  (新根因待查)                    Bug #3 [HIGH]    ✅ pipefail+grep
                                 Bug #4 [HIGH]    ✅ SHA256SUMS raw URL
Bug #2 [MEDIUM]                  Bug #5 [MEDIUM]  ✅ ssh vs sshd 检测
  --status 缺详情                 Bug #6 [MEDIUM]  ✅ 日志输出统一 >&2
                                 Bug #7 [MEDIUM]  ✅ schedule_rollback PID 污染
Bug #3 [LOW]
  临时目录未清理

Bug #4 [LOW]
  版本号 0.1.0
```

---

## 变更日志

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-20 | UPDATE | Round 2 真机测试 — curl 管道模式 4 用例，发现 1 CRITICAL + 1 MEDIUM + 2 LOW 新 bugs |
| 2026-06-20 | CREATE | Round 1 真机测试报告（@ 347000a） |

---

## 下一步建议

1. **P0**: 排查并修复 新 Bug #1 — SSH 回滚提前触发（阻塞 SSH 加固功能）
2. **P1**: 修复 新 Bug #2 — `--status` 补充安全状态详情
3. **P2**: 修复 新 Bug #3 — 临时目录清理
4. **P2**: 更新 新 Bug #4 — 版本号
5. 新 Bug #1 修复后重新测试 `--ssh` 和 `--yes`（一键全部）

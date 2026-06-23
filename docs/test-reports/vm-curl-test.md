# VM 测试报告 — Linux-One-Key 脚本

**测试日期**: 2026-06-20  
**测试人员**: Claude (via automated testing)  
**VM 信息**: `root@10.211.55.8` (密码 123)

---

## 测试环境

| 项目 | 详情 |
|------|------|
| **操作系统** | Ubuntu 24.04.4 LTS (Noble Numbat) |
| **内核** | 6.8.0-124-generic |
| **架构** | aarch64 (ARM64) |
| **宿主机** | macOS, IP `10.211.55.2` |
| **测试方式** | SSH + sshpass; curl over HTTP |
| **脚本版本** | 0.1.0 |

## 初始状态

| 项目 | 初始值 |
|------|--------|
| SSH 端口 | 22 (默认) |
| PermitRootLogin | yes |
| PasswordAuthentication | 未显式设置 (默认 yes) |
| 防火墙 (UFW) | 已安装，未启用 |
| Fail2Ban | 未安装 |
| `at` 命令 | 未安装 |
| authorized_keys | 空文件 |
| 备份目录 | 不存在 |

---

## 测试结果汇总

| # | 测试项 | 结果 | 说明 |
|---|--------|------|------|
| 1 | `--status` 只读模式 | ✅ PASS | 正确检测 OS/架构/用户/包管理器 |
| 2 | `--help` | ✅ PASS | 显示正确帮助信息 |
| 3 | `--yes` (已移除的参数) | ✅ PASS | 显示正确的迁移提示，引导用户使用交互模式 |
| 4 | 未知参数 `--bogus` | ✅ PASS | 显示错误并退出 |
| 5 | 菜单选项 1: 状态检测 | ✅ PASS | 正确显示 SSH/防火墙/Fail2Ban 状态 |
| 6 | 菜单选项 0: 退出 | ✅ PASS | 正常退出，显示 "再见" |
| 7 | 防火墙向导 (完整) | ✅ PASS | UFW 启用，22/80/443/tcp 开放，ICMP 允许 |
| 8 | Fail2Ban 向导 (完整) | ✅ PASS | 安装、jail 配置、服务启动均正常 |
| 9 | 完整向导 (skip-all) | ⚠️ PASS* | 跳过功能正常，但报告有 bug (Issue #2) |
| 10 | curl 下载 + 解压 + 执行 | ✅ PASS | 文件正常提取并运行 |
| 11 | curl pipe `| bash` | ⚠️ PARTIAL | TTY 环境正常，非 TTY 环境卡死 (Issue #4) |
| 12 | curl pipe + `--status` | ✅ PASS | 非交互模式正常完成 |
| 13 | 端口验证函数 | ✅ PASS | 边界值检测正确 (valid/invalid/zero/alpha) |
| 14 | 非 root 用户执行 | ❌ FAIL | Permission denied 写入日志 (Issue #6) |
| 15 | Bats 单元测试 | ❌ 27/46 FAIL | 模块依赖加载顺序问题 (Issue #8) |

---

## 发现的问题

### Issue #1 (MEDIUM) — 网络检测仅使用 ICMP ping

**文件**: `scripts/base/utils.sh:402` (`check_network`)  
**现象**: 系统检测阶段显示 "网络连接: 失败"，但 VM 实际可通过 HTTPS 访问互联网。  
**根因**: `check_network` 函数使用 `ping -c 1 -W 5 8.8.8.8` 检测网络。很多网络环境（包括本次测试的 VM）ICMP 被阻断，但 TCP/HTTP 正常。  
**影响**: 用户看到网络检测失败的警告，可能误以为系统无法联网，但实际上不影响脚本功能。  
**建议**: 增加 HTTP/TCP fallback 检测，例如 `curl -sI --connect-timeout 3 https://google.com`。

```bash
# 当前代码 (utils.sh:402-411)
check_network() {
    local host="${1:-8.8.8.8}"
    local timeout="${2:-5}"
    if ping -c 1 -W "${timeout}" "${host}" &>/dev/null; then
        return 0
    else
        return 1
    fi
}
```

---

### Issue #2 (HIGH) — generate_report() 报告内容硬编码，结果与实际不符

**文件**: `install.sh:659-699` (`generate_report`)  
**现象**: 当完整向导（选项 5）的所有步骤都被用户跳过时，生成的报告仍然显示：
```
[✓] SSH 安全加固
  - Root login: disabled
  - Password auth: disabled
```
但实际 SSH 配置未发生任何变化（`PermitRootLogin yes` 保持不变）。  

**验证过程**:
```bash
# 执行: echo '5\n\ny\ny\ny\n\n0\n' | bash install.sh
# 报告声称 Root login disabled，但实际:
$ grep PermitRootLogin /etc/ssh/sshd_config
PermitRootLogin yes    # ← 未改变!
```

**根因**: `generate_report()` 函数模板完全硬编码，不检查各模块是否实际执行，也不读取实际系统配置。  
**影响**: **用户被报告误导**，以为安全加固已完成，但实际上配置未改变。这是一个信任问题。  
**建议**: 
- 在各模块的 wizard 函数中设置标志变量（如 `_SSH_APPLIED=1`）
- `generate_report()` 根据实际执行状态动态生成报告
- 跳过的模块应显示 `[⊘] SSH 安全加固 — 已跳过` 而非 `[✓] SSH 安全加固`
- 报告应从实际配置文件读取状态，而非硬编码

---

### Issue #3 (LOW) — Bootstrap 下载提示信息硬编码 "GitHub"

**文件**: `install.sh:29`  
**现象**: 当从非 GitHub 源下载时，bootstrap 仍显示 "正在从 GitHub 下载 linux-one-key..."。  
**影响**: 仅影响信息准确性，不影响功能。生产环境中总是从 GitHub 下载，影响极小。  
**建议**: 改为通用提示 "正在下载 linux-one-key..." 或根据 URL 动态判断。

---

### Issue #4 (MEDIUM) — 非 TTY 环境下 curl pipe 模式无限循环

**文件**: `install.sh:86-90`  
**现象**: 在非 TTY 环境（如 `ssh ... "curl ... | bash"`）中，bootstrap re-exec 使用 `< /dev/null` 作为 stdin。所有 `read` 调用返回空字符串，`get_main_menu_choice` 触发无限 "无效选项" 循环。  
**根因**: 
```bash
if tty &>/dev/null; then
    exec bash "${extracted_dir}/install.sh" "${args[@]}" < /dev/tty
else
    exec bash "${extracted_dir}/install.sh" "${args[@]}" < /dev/null  # ← 问题
fi
```
`< /dev/null` 导致所有 `read` 返回空/EOF，交互式菜单在 `get_main_menu_choice` 中无限循环打印 "无效选项"。  
**影响**: CI/CD 或自动化脚本中无法使用 `curl | bash` 进入交互菜单。但 `--status` 参数不受影响（不进入交互循环）。  
**建议**: 
- 非 TTY 模式自动进入 `--status` 只读模式
- 或检测 stdin 不是 TTY 时打印提示并优雅退出
- 或在函数中添加 EOF 检测，防止无限循环

---

### Issue #5 (LOW) — `at` 命令未安装，回滚定时器依赖 fallback

**文件**: `scripts/security/ssh.sh:478-490`  
**现象**: Ubuntu 24.04 默认不安装 `at` 命令。SSH 回滚定时器的主要方案（`echo "..." | at now + 5 minutes`）不可用，依赖 fallback 的 `schedule_rollback` 后台进程。  
**影响**: fallback 机制（后台 sleep + 执行）可用，但后台进程的生命周期不确定——如果终端关闭，进程可能被 SIGHUP 杀死。  
**建议**: 
- 在 SSH 向导开始前检查 `at` 是否可用，不可用时提示用户安装
- 或在依赖项中列出 `at` 为推荐依赖

---

### Issue #6 (MEDIUM) — 非 root 用户执行时日志写入 Permission denied

**文件**: `scripts/base/utils.sh:240` (`init_logging`)  
**现象**: 非 root 用户执行 `--status` 时，`init_logging` 尝试写入 `/var/log/linux-one-key/` 导致 Permission denied。  
**根因**: `LOG_DIR` 默认为 `/var/log/linux-one-key`，普通用户无写权限。`init_logging` 中的 `cat > "${LOG_FILE}"` 没有错误抑制（而后续的 `log_*` 函数使用了 `2>/dev/null || true`）。  
**影响**: 非 root 用户无法正常使用脚本，即使是只读的 `--status` 模式也会在初始化阶段失败。  
**建议**: 
- 非 root 时自动切换 LOG_DIR 到 `/tmp/linux-one-key` 或 `$HOME/.linux-one-key`
- `init_logging` 增加写入权限检查，失败时自动 fallback

---

### Issue #7 (COSMETIC) — macOS 创建的 tar.gz 包含 xattr 元数据

**文件**: N/A (打包流程)  
**现象**: 在 macOS 上使用系统 `tar` 打包时，会包含 `LIBARCHIVE.xattr.*`、`SCHILY.fflags`、`FinderInfo` 等扩展属性以及 `._*` Apple Double 文件。Linux 解压时产生大量 "Ignoring unknown extended header keyword" 警告。  
**影响**: 仅影响 macOS 开发者的本地测试环境。GitHub 自动生成的 tarball 不受此影响。  
**建议**: 
- 本地测试打包时使用 `COPYFILE_DISABLE=1` 环境变量
- 或使用 `--exclude='._*'` 排除 Apple Double 文件
- 项目根目录添加 `.gitattributes` 确保 GitHub 生成的 tarball 干净

---

### Issue #8 (HIGH) — Bats 测试 27/46 失败：模块依赖加载顺序

**文件**: `tests/unit/fail2ban.bats`, `tests/unit/firewall.bats`  
**现象**: 
```
# 测试结果: 19 通过, 27 失败 (总计 46)
# utils.bats:    19/19 全部通过 ✅
# fail2ban.bats:  0/18 全部失败 ❌
# firewall.bats:  0/9  全部失败 ❌
```
所有失败原因相同：
```
Error: utils.sh must be loaded before fail2ban.sh
Error: utils.sh must be loaded before firewall.sh
```
**根因**: 测试文件的 `setup()` 函数直接 source 安全模块，但安全模块（`fail2ban.sh:10-13`, `firewall.sh:10-13`）顶部检查 `_UTILS_LOADED != "1"` 并拒绝加载。`utils.sh` 未被 test setup 预先加载。  
**影响**: 无法运行完整测试套件，CI 会失败，且测试无法验证 fail2ban 和 firewall 模块的函数逻辑。  
**建议**: 
- 测试 setup 中先 `source scripts/base/utils.sh` 再 source 被测模块
- 或创建统一的 `tests/helpers/load.bash` 处理依赖加载顺序
- 需要修改 `tests/unit/fail2ban.bats` 和 `tests/unit/firewall.bats` 第 16 行附近的 setup 函数

---

## 通过的测试详情

### 交互式功能 ✅
- 状态检测菜单正确显示 SSH 端口/root登录/密码认证/密钥认证/防火墙/Fail2Ban 状态
- 防火墙向导完整执行：UFW 安装跳过 → 默认策略配置 → 端口 22/80/443 开放 → 启用
- Fail2Ban 向导完整执行：安装 1.0.2 版本 → jail 配置 → 服务启动 (`systemctl is-active fail2ban` = active)
- 完整向导 skip-all：跳过 SSH/防火墙/Fail2Ban三个步骤，正常完成

### curl 分发方式 ✅
- `curl <URL>/linux-one-key.tar.gz | tar xz && bash install.sh` — 正常
- `curl <URL>/install.sh | bash -s -- --status` — 正常（非交互模式）
- TTY 环境 `curl <URL> | bash` — 正常进入交互菜单

### 参数处理 ✅
- `--status`: 只读检测模式正常
- `--help` / `-h`: 正确显示帮助
- `--yes` / `--ssh` / `--firewall` / `--fail2ban`: 正确显示迁移提示
- 未知参数: 正确报错并退出

### 端口验证 ✅
```
validate_port 2222  → OK (valid)
validate_port 70000 → FAIL (超出范围)
validate_port 0     → FAIL (无效)
validate_port abc   → FAIL (非数字)
```

### utils.bats 测试 ✅
19 个测试全部通过：
- 日志函数: log_info, log_success, log_warn, log_error, log_step, log_title, log_debug
- 备份/恢复: backup_file (含缺失文件错误处理), restore_file
- SSH 配置: set_ssh_config (新增/更新), get_ssh_config
- 工具函数: command_exists, get_os_type
- 常量: SCRIPT_VERSION, TIMESTAMP

---

## 测试覆盖情况

| 功能模块 | 状态 | 测试方式 |
|----------|------|----------|
| 系统检测 | ✅ | --status + 交互菜单 |
| 参数解析 | ✅ | --help, --status, --yes, --bogus |
| SSH 端口验证 | ✅ | 直接调用 validate_port |
| 防火墙安装+配置 | ✅ | 交互向导 + ufw status verify |
| Fail2Ban 安装+配置 | ✅ | 交互向导 + systemctl verify |
| 完整向导 skip-all | ⚠️ | 流程正常，报告有 bug |
| 完整报告生成 | ⚠️ | 报告硬编码 (Issue #2) |
| curl pipe 分发 | ⚠️ | TTY 正常，非 TTY 卡死 (Issue #4) |
| 非 root 执行 | ❌ | Permission denied (Issue #6) |
| Bats 单元测试 | ❌ | 27/46 失败 (Issue #8) |
| SSH 端口修改 | 🔴 未测 | 高风险（可能锁死 VM 访问） |
| SSH root 禁用 | 🔴 未测 | 高风险 |
| SSH 密码禁用 | 🔴 未测 | 高风险 |
| SSH 回滚机制 | 🔴 未测 | 依赖高风险操作触发 |
| CentOS/RHEL | 🔴 未测 | VM 为 Ubuntu |
| firewalld | 🔴 未测 | VM 使用 UFW |

---

## 总结

### 可用性判断

脚本在 **Ubuntu 24.04.4 LTS (aarch64)** 上的核心功能正常。防火墙配置和 Fail2Ban 配置均按预期工作。`--status` 只读模式兼容性良好。

### 优先修复建议

| 优先级 | Issue | 理由 |
|--------|-------|------|
| 🔴 P0 | #2 报告硬编码 | 误导用户，安全隐患 |
| 🔴 P0 | #8 测试 27/46 失败 | CI 不可用，无法保证质量 |
| 🟡 P1 | #6 非 root 执行失败 | 限制了使用场景 |
| 🟡 P1 | #4 非 TTY 死循环 | 影响自动化部署 |
| 🟢 P2 | #1 ICMP 网络检测 | 影响小，有完善 fallback 即可 |
| 🟢 P2 | #5 at 命令缺失 | fallback 可工作 |
| 🟢 P3 | #3 Github 硬编码 | 纯 cosmetic |
| 🟢 P3 | #7 macOS tar xattr | 不影响生产环境 |

---

> **变更日志**
> | 日期 | 操作 | 说明 |
> |------|------|------|
> | 2026-06-20 | CREATE | 初始测试报告，记录 8 个问题，15 个测试用例结果 |

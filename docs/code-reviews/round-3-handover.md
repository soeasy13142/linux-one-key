# Code Review 交接文档

> **审查日期**: 2026-06-23
> **审查范围**: 全项目（10 个源文件 + 3 个测试文件，3975 LOC）
> **决策**: **APPROVE**（附带修复建议）
> **审查人**: Claude Code

---

## 审查结论

项目整体质量良好，架构清晰，i18n、备份/回滚机制、交互式 UX 设计合理。经过多轮迭代和 Code Review，未发现安全漏洞或严重 bug。ShellCheck 静态分析通过（仅有预期的误报），Bats 单元测试 46/46 全部通过。

---

## 待办事项总览

| 编号 | 优先级 | 状态 | 问题 | 文件 |
|------|--------|------|------|------|
| H1 | HIGH | ⬜ 待修复 | 颜色变量在初始化前被引用 | `install.sh:125-131` |
| H2 | HIGH | ⬜ 待修复 | init.sh 已加载但 run_init() 从未调用 | `install.sh:228-229` |
| H3 | HIGH | ⬜ 待修复 | report.sh 中 3 处硬编码中文绕过 i18n | `report.sh:129,133,136` |
| M1 | MEDIUM | ⬜ 待修复 | _ENSURING_LOG_DIR 使用 export 污染环境 | `utils.sh:89` |
| M2 | MEDIUM | ⬜ 待补充 | ssh.sh 缺少单元测试 | `tests/unit/` |
| M3 | MEDIUM | ⬜ 待优化 | fail2ban 启动使用硬编码 sleep 2 | `fail2ban.sh:160` |
| M4 | MEDIUM | ⬜ 待评估 | schedule_rollback 回调以字符串传递 | `utils.sh:509-522` |
| L1 | LOW | ⬜ 可选 | 引号风格不一致 ($var vs ${var}) | `firewall.sh`, `fail2ban.sh` |
| L2 | LOW | ⬜ 可选 | _get_ssh_service_name 永远返回 "sshd" | `fail2ban.sh:79-81` |
| L3 | LOW | ⬜ 可选 | 残留的 `:` 占位符 | `install.sh:80` |
| L4 | LOW | ⬜ 可选 | view_report 使用 GNU find -printf | `install.sh:549` |

---

## HIGH 优先级（应在下次提交前修复）

### H1: 颜色变量在初始化前被引用

**文件**: `install.sh:125-131`

**问题描述**:
`_parse_args` 在第 142 行被调用，此时 `load_dependencies()` 尚未执行（在 `main()` 第 692 行才调用）。函数内引用了 `${RED}`、`${YELLOW}`、`${BLUE}`、`${NC}`，这些变量定义在 `utils.sh` 中。由于 `set -eo pipefail`（没有 `-u`），未定义变量会展开为空字符串——不会崩溃，但 `--yes`、`--ssh` 等已移除参数的错误提示会没有任何颜色格式。

```bash
# 当前代码（第 125-131 行）
echo -e "${RED}Error: --${removed_arg} has been removed.${NC}"
echo -e "${YELLOW}This script is now fully interactive:${NC}"
echo -e "${YELLOW}  sudo bash install.sh${NC}"
echo -e "${BLUE}Tip: --status still works for read-only:${NC}"
echo -e "${BLUE}  sudo bash install.sh --status${NC}"
```

**修复方案**（二选一）:

方案 A — 在 `install.sh` 顶部（`_parse_args` 之前）定义基本颜色常量：
```bash
readonly RED='\033[0;31m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'
```

方案 B — 将 `_parse_args` 调用移入 `main()` 中，放在 `load_dependencies` 之后。

**推荐方案 B**，避免颜色常量重复定义。

---

### H2: init.sh 已加载但 run_init() 从未调用

**文件**: `install.sh:228-229`（source 行）；`scripts/base/init.sh`（整个模块）

**问题描述**:
`load_dependencies()` 中 source 了 `init.sh`，但项目中没有任何菜单路径调用 `run_init()`。以下函数均为死代码：
- `init_directories()` — 创建日志/备份/报告目录
- `update_system_packages()` — 安全更新系统包
- `install_base_tools()` — 安装 curl/wget/vim/unzip
- `setup_timezone()` — 设置时区（默认 Asia/Shanghai）

**修复方案**（二选一）:

方案 A — 在完整安全配置向导（`run_full_wizard`）中增加 Step 0：
```bash
# ── Step 0: System Init ──
log_title "System Initialization"
if confirm "Run system initialization (update packages, install tools)?" "y"; then
    run_init || log_warn "System init had errors"
fi
```

方案 B — 从 `load_dependencies()` 中移除 `source init.sh`，待 v0.3 需要时再启用。

**推荐方案 A**，让向导流程更完整。

---

### H3: report.sh 中 3 处硬编码中文绕过 i18n

**文件**: `scripts/base/report.sh:129,133,136`

**问题描述**:
`generate_report()` 中有 3 条警告消息直接使用中文字符串，未通过 `MSG_*` 变量。在英文模式下，报告中会混入中文。

```bash
# 第 129 行
echo "  ⚠ 防火墙已保留放通 22 端口，确认新 SSH 端口可用后请手动关闭: sudo ufw deny 22/tcp"
# 第 133 行
echo "  ⚠ 防火墙已启用，请确保已正确放通所需端口"
# 第 136 行
echo "  ⚠ 请定期检查 Fail2Ban 日志: sudo tail -f /var/log/fail2ban.log"
```

**修复方案**:

1. 在 `scripts/lang/zh.sh` 中添加：
```bash
MSG_REPORT_WARN_SSH_PORT22="防火墙已保留放通 22 端口，确认新 SSH 端口可用后请手动关闭: sudo ufw deny 22/tcp"
MSG_REPORT_WARN_FIREWALL="防火墙已启用，请确保已正确放通所需端口"
MSG_REPORT_WARN_FAIL2BAN="请定期检查 Fail2Ban 日志: sudo tail -f /var/log/fail2ban.log"
```

2. 在 `scripts/lang/en.sh` 中添加：
```bash
MSG_REPORT_WARN_SSH_PORT22="Firewall kept port 22 open. After confirming new SSH port works, close it: sudo ufw deny 22/tcp"
MSG_REPORT_WARN_FIREWALL="Firewall enabled. Ensure all required ports are properly opened."
MSG_REPORT_WARN_FAIL2BAN="Check Fail2Ban logs regularly: sudo tail -f /var/log/fail2ban.log"
```

3. 在 `report.sh` 中替换为变量引用：
```bash
echo "  ⚠ ${MSG_REPORT_WARN_SSH_PORT22}"
echo "  ⚠ ${MSG_REPORT_WARN_FIREWALL}"
echo "  ⚠ ${MSG_REPORT_WARN_FAIL2BAN}"
```

---

## MEDIUM 优先级（建议修复）

### M1: _ENSURING_LOG_DIR 使用 export 污染环境

**文件**: `scripts/base/utils.sh:89`

**问题描述**:
`export _ENSURING_LOG_DIR=1` 将内部守卫变量导出到所有子进程环境中。该变量仅在当前 shell 进程内用于防止 `_ensure_log_dir` 无限递归，无需 export。

**修复**:
```bash
# 当前
export _ENSURING_LOG_DIR=1
# 改为
_ENSURING_LOG_DIR=1
```

---

### M2: ssh.sh 缺少单元测试

**问题描述**:
SSH 模块（576 行）没有对应的测试文件。`firewall.sh` 有 `firewall.bats`（9 个用例），`fail2ban.sh` 有 `fail2ban.bats`（18 个用例），但 `ssh.sh` 的以下函数完全没有测试覆盖：
- `validate_port()` — 端口号验证
- `check_other_users()` — 检查是否有其他可登录用户
- `check_ssh_keys()` — 检查是否有有效 SSH 密钥
- `configure_ssh_params()` — SSH 安全参数配置
- `change_ssh_port()` — SSH 端口修改（交互式）

**修复**:
创建 `tests/unit/ssh.bats`，至少覆盖：
```bash
# validate_port 测试
@test "validate_port accepts valid port 22"
@test "validate_port accepts valid port 65535"
@test "validate_port rejects port 0"
@test "validate_port rejects port 65536"
@test "validate_port rejects non-numeric input"
@test "validate_port handles octal-looking input (022)"

# check_other_users 测试
@test "check_other_users detects existing users"
@test "check_other_users returns 1 when only root exists"

# check_ssh_keys 测试
@test "check_ssh_keys returns 0 for valid ed25519 key"
@test "check_ssh_keys returns 1 for empty authorized_keys"
@test "check_ssh_keys returns 1 for missing authorized_keys"
```

---

### M3: fail2ban 启动使用硬编码 sleep 2

**文件**: `scripts/security/fail2ban.sh:160`

**问题描述**:
`_enable_fail2ban_service()` 中使用 `sleep 2` 等待服务启动。在慢速系统上 2 秒可能不够，在快速系统上则是浪费时间。

**修复**:
```bash
# 改为轮询等待
local attempts=0
while [[ ${attempts} -lt 10 ]]; do
    if systemctl is-active --quiet fail2ban; then
        break
    fi
    sleep 1
    ((attempts++))
done
```

---

### M4: schedule_rollback 回调以字符串传递

**文件**: `scripts/base/utils.sh:509-522`

**问题描述**:
`schedule_rollback` 接受回调函数名作为字符串参数，然后通过 `"${callback}"` 执行。虽然目前只在内部用硬编码函数名调用，但这种模式比较脆弱，如果调用约定变化可能成为命令注入向量。

**当前用法**（安全）:
```bash
schedule_rollback "${ROLLBACK_DELAY}" "rollback_ssh" "${MSG_SSH_ROLLBACK_TIMER}"
```

**建议**: 添加注释标注此函数仅接受内部硬编码函数名，或改为直接传递函数引用（Bash 中通过 `declare -f` 验证函数存在）。

---

## LOW 优先级（可选修复）

### L1: 引号风格不一致

**文件**: `scripts/security/firewall.sh`, `scripts/security/fail2ban.sh`

这两个文件使用 `"$var"` 风格，而 `utils.sh`、`detect.sh`、`ssh.sh` 使用 `"${var}"` 风格。`"${var}"` 更显式，与项目主流风格一致。

---

### L2: _get_ssh_service_name 永远返回 "sshd"

**文件**: `scripts/security/fail2ban.sh:79-81`

```bash
_get_ssh_service_name() {
    echo "sshd"
}
```

该函数无条件返回 `"sshd"`，与直接使用常量无异。如果不需要按 OS 区分，可直接用常量替换。

---

### L3: 残留的 `:` 占位符

**文件**: `install.sh:80`

```bash
    # curl pipe mode: just re-exec, user gets interactive menu
    :
```

这是移除旧 `--yes` 逻辑后残留的空操作。无害但可清理。

---

### L4: view_report 使用 GNU find -printf

**文件**: `install.sh:549`

```bash
latest_report=$(find "${report_dir}" -maxdepth 1 -name 'report_*.txt' -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
```

`-printf` 是 GNU find 特有选项，在 macOS（BSD find）上会失败。由于目标运行环境是 Linux 服务器，影响仅限于开发环境。

---

## 验证结果

| 检查项 | 结果 |
|--------|------|
| ShellCheck 静态分析 | ✅ 通过（564 SC2034 = i18n 误报，5 SC1091 = /etc/os-release，1 SC2317 = source guard） |
| Bats 单元测试 | ✅ 通过（46/46） |
| 人工审查 | ✅ 完成（10 个源文件 + 3 个测试文件，3975 行） |
| 安全检查 | ✅ 无硬编码密钥、无命令注入、无路径遍历、无 SQL/XSS |

---

## 审查文件清单

| 文件 | 行数 | 类型 | 状态 |
|------|------|------|------|
| `install.sh` | 730 | 主入口 | 已审查 |
| `scripts/base/utils.sh` | 595 | 工具函数库 | 已审查 |
| `scripts/base/detect.sh` | 229 | 系统检测 | 已审查 |
| `scripts/base/init.sh` | 156 | 系统初始化 | 已审查（⚠️ 未使用） |
| `scripts/base/report.sh` | 151 | 报告生成 | 已审查 |
| `scripts/security/ssh.sh` | 576 | SSH 加固 | 已审查 |
| `scripts/security/firewall.sh` | 406 | 防火墙配置 | 已审查 |
| `scripts/security/fail2ban.sh` | 338 | Fail2Ban 配置 | 已审查 |
| `scripts/lang/zh.sh` | 397 | 中文翻译 | 已审查 |
| `scripts/lang/en.sh` | 397 | 英文翻译 | 已审查 |
| `tests/unit/utils.bats` | 157 | 工具函数测试 | 已审查 |
| `tests/unit/firewall.bats` | 128 | 防火墙测试 | 已审查 |
| `tests/unit/fail2ban.bats` | 247 | Fail2Ban 测试 | 已审查 |

---

## 建议的修复顺序

```
第一批（HIGH，阻断性）:
├── H1: _parse_args 颜色变量提前定义          ~5 min
├── H2: 集成 run_init() 到向导流程            ~10 min
└── H3: report.sh 3 处硬编码中文 i18n 化      ~10 min

第二批（MEDIUM，质量提升）:
├── M1: _ENSURING_LOG_DIR 移除 export         ~1 min
├── M3: fail2ban sleep 改为轮询               ~5 min
└── M2: 创建 ssh.bats 单元测试                ~30 min

第三批（LOW，可选）:
├── L1: 统一引号风格                          ~10 min
├── L2: _get_ssh_service_name 改为常量        ~2 min
├── L3: 清理 : 占位符                         ~1 min
└── L4: view_report 兼容 macOS find           ~5 min
```

---

## 变更日志

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-06-23 | CREATE | 全项目 Code Review 交接文档，0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW |

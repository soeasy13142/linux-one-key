---
title: "Batch 5a — 备份/回滚中心 + 安全仪表盘 设计"
status: approved
created: 2026-07-31
updated: 2026-07-31
topic: "feature"
scope: "batch5a-ux"
---

# Batch 5a：备份/回滚中心 + 安全仪表盘

## 1. 背景与动机

项目 v1.5.1 已完成 16 项菜单、473 Bats 测试、Lite/Full 双模式。`main-menu-redesign-v2.md` §5 明确搁置了两个菜单项：**备份/回滚入口** 与 **状态仪表盘**。本次把它们实现为 Batch 5a，并遵循 README 既定政策——**新增功能只进 Full 版，Lite 保持最小安全基线不变**。

同时，代码调研确认两个关键事实：

1. **备份基础设施已就绪但无用户界面**：`backup.sh`（`backup_file`/`restore_file`）、`rollback.sh`（`schedule_rollback`/`cancel_scheduled_task`）、`ssh.sh`（`rollback_ssh`/`setup_rollback_timer`/`cancel_rollback_timer`）、`kernel.sh`（`restore_sysctl_backup`）均存在，但主菜单没有任何备份/恢复/回滚入口。
2. **状态检测已有评分雏形**：`show_system_status()`（install.sh:386）对 SSH 已有 4 项检查（端口/root/密码/公钥 → `ssh_ok/ssh_total`）的评分模式，可推广为全模块评分仪表盘。

## 2. 范围

### 本批次（Batch 5a，Full-only）

| # | 功能 | 类型 |
|---|------|------|
| ① | 备份/回滚中心 | 一级菜单 [17]，编排层（复用现有基础设施） |
| ② | 安全仪表盘 | 一级菜单 [18]，呈现层（扩展现有状态检测） |

### 不在本批次（YAGNI / 后续）

- **Batch 5b**：sudo 加固 + 日志加固模块（独立 spec → plan → 实现）
- HTML/JSON 报告导出（本轮仅终端彩色渲染）
- 无人值守 / 批量部署（用户已排除）
- 备份加密、备份推送远程存储
- 扩展 `schedule_rollback` 回调白名单（当前仅 `rollback_ssh`，本批次不改）

### 模式归属

- 备份/回滚中心与仪表盘 **均仅 Full 模式** 菜单显示，Lite 下不出现（遵循"新增功能只进完整版"政策，用户已确认）。
- 两者是编排/呈现层，**不进入** `MODE_LITE/FULL_MODULES`（不是向导可执行模块，无需在向导中跑）。

## 3. 设计决策（已与用户确认）

| 决策 | 选择 | 理由 |
|------|------|------|
| 备份中心是否进 Lite | 只进 Full | 遵循"新增功能只进完整版"政策 |
| 菜单入口位置 | 追加到末尾 [17]/[18] | 避免现有 0-16 编号重排（HANDOVER 记录过菜单编号变更是坑） |

## 4. 架构

```
install.sh (菜单入口)
  ├─ [17] 备份/回滚中心 ──→ scripts/base/backup_center.sh   (list/group/clean/restore-flow/rollback-status)
  ├─ [18] 安全仪表盘     ──→ scripts/base/dashboard.sh      (scoring + render)
  │
  └─ 复用（不变）：backup.sh · rollback.sh · ssh.sh · kernel.sh · mode.sh · utils.sh
```

- **新增 2 个 base 文件**：`scripts/base/backup_center.sh`、`scripts/base/dashboard.sh`（纯逻辑 + 渲染，可被 Bats source 测试）。
- **install.sh 只加薄菜单处理函数**，调用上述文件，保持 install.sh 不被继续撑大。
- **加载时机**：`utils.sh` 加载 `backup.sh`/`rollback.sh` 之后、菜单循环之前，由 install.sh source 这两个新文件。

## 5. ① 备份/回滚中心 — 菜单 [17]

### 5.1 子菜单

| 子项 | 功能 | 复用/新增 |
|------|------|-----------|
| 1. 查看备份历史 | 按"原始路径所属模块"分组列出 `$BACKUP_DIR` 备份（文件+时间+大小），仅读 | 新增 `list_backups()`、`group_backup_by_path()` |
| 2. 一键恢复模块 | 选择模块 → 列出该模块最新备份 → **双重确认** → 恢复到 `.meta` 记录的原始路径 → 按需重载服务 | 新增 `restore_module_backups()`；复用 `restore_file()` |
| 3. SSH 回滚定时器 | 查看是否有 pending 回滚 + PID + 回调；可取消 | 新增 `rollback_timer_status()`；复用 `cancel_rollback_timer()` |
| 4. 清理旧备份 | 按文件名保留最新 N 份（默认 5），删除更旧 | 新增 `clean_old_backups()` |

### 5.2 backup.sh 变更（向后兼容）

- **`backup_file(file, description)`**：拷贝成功后，额外写入 `echo "${file}" > "${backup_path}.meta"` 记录原始绝对路径。返回的 backup_path 不变 → 现有调用方与测试不受影响。
- **`restore_file(backup_path, target_path="")`**：`target_path` 为空时从 `${backup_path}.meta` 读取原始路径；两者皆无 → 报错返回 1。
- **新增**：
  - `list_backups()`：返回 `$BACKUP_DIR` 下 `*.bak.*`（排除 `.meta`）按 mtime 倒序
  - `get_backup_target(backup_path)`：读 `.meta`，无则返回空
  - `clean_old_backups(keep_per_name=5)`：按 basename 前缀分组，保留最新 N 份，删除更旧

### 5.3 rollback.sh 变更

- **新增只读 `rollback_timer_status()`**：检查 `ROLLBACK_PID`/`_SCHEDULED_PID` 是否存活且 cmdline 含 `sleep`（复用 `cancel_scheduled_task` 的 PID 校验思路）；无定时器返回"无"。

### 5.4 模块分组（仅展示用）

备份文件名不含模块信息，展示分组依据 `.meta` 中的原始路径目录推导（仅影响显示，不影响恢复正确性）：

| 路径前缀 | 显示模块 |
|----------|----------|
| `/etc/ssh/` | SSH |
| `/etc/sysctl.d/` | Kernel |
| `/etc/ufw/` `/etc/firewalld/` | Firewall |
| `/etc/fail2ban/` | Fail2Ban |
| `/etc/audit/` | Audit |
| `/etc/clamav/` | ClamAV |
| `/etc/aide/` `/var/lib/aide/` | AIDE |
| `/etc/apt/` `/etc/yum/` `/etc/dnf/` | AutoUpdate |
| 其他 | 其他 |

### 5.5 安全与错误处理

- **恢复强确认**：选择模块后 `y/N` 双重提示；显示将被恢复的文件清单。
- **路径穿越防护**：`restore_file` 只接受绝对目标路径；`.meta` 内容非绝对路径则拒绝；备份文件必须位于 `$BACKUP_DIR` 内。
- **恢复失败**：`restore_file` 返回非零 → `log_error` 明确提示，**不删除**该备份，保留可重试。
- **无备份/空目录**：`list_backups` 返回空 → 友好提示"暂无备份"。
- **清理**：仅 glob `*.bak.*`；先预览将被删除的文件再确认；**永不删除每组最新一份**；目标目录限定在 `$BACKUP_DIR` 内。
- **服务重载**：恢复后按 `.meta` 路径提示/执行——`/etc/sysctl.d/` → 提示 `sysctl --system`；`/etc/ssh/` → 提示立即测试新连接（复用 SSH 连接测试逻辑）；其余不改动服务状态。

## 6. ② 安全仪表盘 — 菜单 [18]

### 6.1 呈现

终端彩色渲染，每个安全模块一行：

```
SSH           ✅ 5/5   SSH: 非默认端口 / 禁 root / 禁密码 / 公钥 / 算法
Firewall      ⚠️ 2/3   未设置默认拒绝策略
...
───────────────────────────────
总分: 28/34 (82%)  风险等级: Medium
```

底部汇总总分 + 风险等级；风险等级不达标时列出优先建议（复用现有 `recommend_items` 思路）。

### 6.2 评分模型

- **范围**：12 个安全模块（ssh/firewall/fail2ban/audit/users/kernel/filesystem/services/autoupdate/aide/clamav/rootkit）。**不含** K3s（非安全模块）与 swap（非安全基线）。
- **模块分** = 该模块通过检查项数 / 检查项总数；**总分** = Σ通过 / Σ总 × 100。
- **风险等级**：≥90 `Low` · 75-89 `Medium` · 60-74 `High` · <60 `Critical`。
- 未部署模块的所有检查项计为未通过（诚实反映合规缺口）。

### 6.3 检查项定义（v1 默认，纯检测只读）

| 模块 | 检查项 |
|------|--------|
| SSH | 非默认端口 / 禁 root 登录 / 禁密码登录 / 公钥认证开启 / 关键算法限制（5 项） |
| Firewall | 已启用 / SSH 端口已放行 / 默认策略拒绝（3 项） |
| Fail2Ban | 已安装 / 服务运行 / jail.local 已配置（3 项） |
| Audit | auditd 运行 / 规则已加载 / 规则数 ≥ 阈值（3 项） |
| Users | 存在普通用户 / 已授权 sudo（2 项） |
| Kernel | 配置文件存在 / 参数数 ≥ 阈值 / 已生效（3 项） |
| Filesystem | 已执行 SUID 扫描 / 无异常 SUID / sticky bit 正确（3 项） |
| Services | 已审计 / 危险服务已禁用 / 开放端口已记录（3 项） |
| AutoUpdate | 已启用 / cron·timer 生效（2 项） |
| AIDE | 数据库已初始化 / cron 已配置（2 项） |
| ClamAV | 病毒库已更新 / cron 已配置（2 项） |
| Rootkit | rkhunter 已装 / chkrootkit 已装 / cron 已配置（3 项） |

> 合计 34 项。各项为独立小函数（`dashboard_check_<module>_<item>`），纯只读、可单测，内部复用各模块已有状态检测辅助函数（如 `get_ssh_port`、`get_ssh_config`、`check_users_status`）。

### 6.4 dashboard.sh API

| 函数 | 说明 |
|------|------|
| `dashboard_module_items(module)` | 返回该模块检查项键列表 |
| `dashboard_eval_module(module)` | 逐项求值，返回 `pass/total` |
| `dashboard_total_score()` | 汇总 12 模块，返回 `pass/total/pct` |
| `dashboard_risk_level(pct)` | 边界：90/75/60 |
| `dashboard_render()` | 彩色终端渲染（复用 utils.sh 颜色/`log_*`） |

### 6.5 与现有功能关系

- **不改** `show_system_status()`（菜单 [1]）与 `report.sh`——保持现状，避免回归。
- 仪表盘是新增的只读视图，数据独立计算，不写文件、不改配置。

## 7. i18n

新增键（zh.sh + en.sh）：

- `MSG_MAIN_MENU_BACKUP_CENTER` / `MSG_MAIN_MENU_DASHBOARD`
- `MSG_BACKUP_CENTER_*`：标题、子菜单、无备份、恢复确认、清理确认、回滚定时器状态等
- `MSG_DASHBOARD_*`：标题、总分、风险等级（Low/Medium/High/Critical）、模块组名等

## 8. 文件变更清单

| 操作 | 文件 | 说明 |
|------|------|------|
| CREATE | `scripts/base/backup_center.sh` | list/group/clean/restore-flow/rollback-status |
| CREATE | `scripts/base/dashboard.sh` | 评分 + 渲染 |
| MODIFY | `scripts/base/backup.sh` | `.meta` sidecar；`restore_file` 读 meta；新增 list/clean/get_backup_target |
| MODIFY | `scripts/base/rollback.sh` | 新增只读 `rollback_timer_status()` |
| MODIFY | `install.sh` | 菜单 [17][18] + 薄处理函数 + full-only gate（`is_mode_full`） |
| MODIFY | `scripts/lang/zh.sh` / `en.sh` | 新增 MSG 键 |
| CREATE | `tests/unit/backup_center.bats` | 见 §9 |
| CREATE | `tests/unit/dashboard.bats` | 见 §9 |
| MODIFY | `README.md` | 功能列表 + 菜单说明 |
| MODIFY | `HANDOVER.md` | 里程碑快照 |

## 9. 测试计划

### 9.1 Bats 单元测试（TDD：先写测试）

**`tests/unit/backup_center.bats`**
- `list_backups`：倒序排列、排除 `.meta`、空目录返回空
- `clean_old_backups`：每组保留最新 N 份、删除更旧、永不删除最新一份、仅限 `$BACKUP_DIR` 内
- `restore_file`：有 `.meta` 恢复成功；无 `.meta` 且无显式目标 → 报错；`.meta` 非绝对路径 → 拒绝
- `rollback_timer_status`：无定时器 → "无"；mock 存活 sleep PID → "pending"

**`tests/unit/dashboard.bats`**
- 评分：给定 mock 检查项结果 → 期望 `pass/total/pct`
- 风险等级边界：90/89/75/74/60/59
- 模块检查项：SSH 5 项、Firewall 3 项等定义正确（数量断言）
- `dashboard_render`：输出含总分行与风险等级

### 9.2 静态与回归

- `shellcheck -x` 全部改动脚本
- 全量 Bats 回归（现有 473 + 新增）
- Docker Phase 1 冒烟：在容器内跑 `list_backups`（空目录场景）确认无回归

## 10. 实施阶段（供 writing-plans 细化）

1. **Phase 1 — backup.sh 增强**：`.meta` sidecar + `restore_file` meta 读取 + list/clean 函数 + Bats（先写测试）
2. **Phase 2 — 备份中心**：`backup_center.sh` + 菜单 [17] + i18n + Bats
3. **Phase 3 — 仪表盘**：`dashboard.sh` 评分/渲染 + 菜单 [18] + i18n + Bats
4. **Phase 4 — 收尾**：README/HANDOVER + shellcheck + 全量回归

## 11. 风险与注意事项

| 风险 | 缓解 |
|------|------|
| 恢复操作误伤生产配置 | 双重确认；显示待恢复清单；恢复前不删除备份 |
| `.meta` 与备份文件不同步 | `backup_file` 原子写 meta；缺 meta 时强制显式目标路径 |
| 菜单重编号风险 | 追加 [17][18]，不改 0-16 |
| dashboard 检查项与模块实现漂移 | 检查项集中在 dashboard.sh，模块函数变动时回归 Bats 断言 |
| Lite 模式误显示 | 两个菜单项均 `if is_mode_full` 包裹（复用现有 gate 模式） |

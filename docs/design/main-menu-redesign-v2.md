---
title: "Main Menu Redesign v2"
status: proposed
created: 2026-07-10
updated: 2026-07-10
source: "原 main-menu-redesign-prd.md + main-menu-redesign-plan.md (v0.2 阶段，已 superseded)"
topic: "design"
supersedes:
  - main-menu-redesign-prd.md
  - main-menu-redesign-plan.md
---

# Main Menu Redesign v2

> 合并原 PRD + Plan 为单一文档，作为 v1.0 主菜单重构的**理想设计快照**。
> 旧的 `main-menu-redesign-prd.md` 与 `main-menu-redesign-plan.md` 已 `archived` + `superseded-by` 指向本文件。

---

## 1. 设计目标

把 `install.sh` 入口层从「v0.2 阶段、未跟上模块扩展」演进为「v1.0 理想态」：

- **覆盖面**：当前 8 个安全模块（ssh/firewall/fail2ban/audit/users/kernel/filesystem/services）+ 状态检测 + 报告查看 + 全流程向导
- **体验一致性**：所有模块入口体验统一（要么都有子菜单壳，要么都直接进 wizard）
- **状态可视化**：状态检测从「逐项 echo + 空行」升级为「评分 + 颜色 + 建议下一步」
- **历史可追溯**：加固报告支持选择历史查看，不再只能看最新
- **i18n 完整**：zh/en 完整对应，无 `:-` 兜底

底层模块（ssh.sh / firewall.sh 等）的内部重构不在本文档范围。

---

## 2. 现状快照（install.sh 当前行为）

### 2.1 顶层菜单（12 项，无分组）

| # | 菜单项 | 实际行为 | 入口函数 |
|---|---|---|---|
| 1 | 系统状态检测 | 读取 8 项状态，只读 | `show_system_status` |
| 2 | SSH 安全加固 | 子菜单 7 项 | `run_ssh_submenu_loop` |
| 3 | 防火墙配置 | 子菜单 4 项 | `run_firewall_submenu_loop` |
| 4 | Fail2Ban 入侵防护 | 直接进 wizard | `run_fail2ban_wizard` |
| 5 | 审计日志 | 直接进 wizard | `run_audit_wizard` |
| 6 | 用户管理 | 直接进 wizard | `run_users_wizard` |
| 7 | 内核加固 | 直接进 wizard | `run_kernel_wizard` |
| 8 | 文件系统安全 | 直接进 wizard | `run_filesystem_wizard` |
| 9 | 服务管理 | 直接进 wizard | `run_services_wizard` |
| 10 | 一键快速加固 | 9 步全流程 | `run_full_wizard` |
| 11 | 查看加固报告 | 找最新 `report_*.txt`，cat 显示 | `view_report` |
| 0 | 退出 | 清理 + 再见 | `cleanup_and_exit` |

### 2.2 现状特征

- 菜单项密度不均：4-9 都是直接进 wizard，与 2/3 的子菜单体验不一致
- 状态检测输出碎片化：8 项各占一段，长度过长，无评分/颜色
- `view_report` 单文件：只能看最新
- i18n 部分键缺失英文（`MSG_STATUS_USERS` 等使用 `:-` 兜底）
- 非交互错误提示冗长：移除的参数报错时打印 5 行黄色提示

### 2.3 非交互参数（现状）

仅保留 `--status`（只读检测）+ `--help`。其他参数（`--yes` / `--ssh` / `--firewall` 等）一律报错退出。

---

## 3. 理想快照

### 3.1 顶层菜单（带分组）

```
Linux Server Security Hardening v1.0
系统: Ubuntu 22.04 | 架构: x86_64 | 用户: root | SSH 端口: 22 (未加固)

────── 状态 ──────
  [1] 系统状态检测
  [11] 查看加固报告          ← 从 [6] 移到 [11]

────── 加固（按推荐顺序）──────
  [2] SSH 安全加固
  [3] 防火墙配置
  [4] Fail2Ban 入侵防护
  [5] 审计日志
  [6] 用户管理
  [7] 内核加固
  [8] 文件系统安全
  [9] 服务管理

────── 一键 ──────
  [10] 全流程加固向导（9 步）

  [0] 退出
```

**改进点**：
- 加分隔线分组（`状态 / 加固 / 一键`），降低 12 项平铺的视觉疲劳
- `view_report` 移到 `[11]`（状态分组末尾），逻辑聚类
- 顶部状态行增加「SSH 端口 + 是否加固」一键摘要

### 3.2 子菜单（理想）

#### SSH 子菜单（与现状一致）
```
[1] 修改端口 [2] 生成密钥 [3] 禁 root [4] 禁密码
[5] 配置参数 [6] 全流程向导 [0] 返回
```

#### 防火墙子菜单（与现状一致）
```
[1] 全流程向导 [2] 开 HTTP/HTTPS [3] 允许 ICMP [0] 返回
```

#### 模块 4-9 的子菜单壳（理想）

为 Fail2Ban / Audit / Users / Kernel / FS / Services 六个模块**统一增加子菜单壳**：

```
[1] 全流程向导
[2] 仅状态检查 / 快速查看
[0] 返回主菜单
```

理由：让用户能"只查状态"或"只做一项"，不必每次都走全流程；与 SSH/防火墙的子菜单体验一致。

### 3.3 系统状态检测（理想）

- **顶部评分**：8 项分别标 ✅ 已加固 / ⚠️ 部分加固 / ❌ 未加固
- **颜色**：绿=已加固，黄=部分，红=未启用
- **表格对齐**：替代「逐项 echo + 空行」布局
- **末尾建议**：列出 ❌ 项对应的菜单编号（如 `建议先加固：[2] SSH [5] 审计`）

### 3.4 view_report（理想）

升级：从「只显示最新」改为「列出最近 N 份（默认 5），用户选要查看哪份」：

```
[1] report_2026-07-10_1430.txt (3 分钟前)
[2] report_2026-07-09_2115.txt (昨天)
[3] report_2026-07-08_1800.txt (2 天前)
...
[0] 返回主菜单
```

### 3.5 非交互参数（理想，与现状一致）

仅保留 `--status` / `--help`。**不引入** `--ssh` / `--firewall` / `--yes` 等。

### 3.6 i18n（理想）

- `zh.sh` 与 `en.sh` 完整对应，无 `:-` 兜底
- 所有新增菜单/分组标签都有中英两套

---

## 4. 差异表（[GAP-N]）

| ID | 现状 | 理想 | 影响 | 修复方向 | 关联文件 | 优先级 |
|---|---|---|---|---|---|---|
| **GAP-1** | 12 项平铺无分组 | 3 组分隔线（状态/加固/一键） | UX 一致性 | `show_main_menu` 加 echo 分隔 | `install.sh:471-509` | 🟡 中 |
| **GAP-2** | 顶部只显示 OS/arch/user | + SSH 端口 + 加固状态摘要 | 一眼看清关键状态 | `show_main_menu` 顶部加一行 | `install.sh:469` | 🟡 中 |
| **GAP-3** | 模块 4-9 直接进 wizard | 统一子菜单壳 `[1]向导 [2]状态 [0]返回` | 体验一致 + 可"只查状态" | 新增 6×2 函数 | `install.sh` (新增) | 🔴 高 |
| **GAP-4** | 状态检测无评分 | 顶部加「安全评分 / 总览」 | 用户感知强 | `show_system_status` 输出格式升级 | `install.sh:311-449` | 🟡 中 |
| **GAP-5** | 状态检测每项单独 echo + 空行 | 表格对齐布局 + 颜色（绿/黄/红） | 可扫描性 | 重构 `show_system_status` | `install.sh:311-449` | 🟡 中 |
| **GAP-6** | 无"建议下一步" | 检测末尾列出 ❌ 项对应菜单编号 | 引导用户行动 | `show_system_status` 末尾追加 | `install.sh:447` | 🟢 低 |
| **GAP-7** | view_report 只看最新 | 列出最近 N 份 + 用户选 | 历史可追溯 | 重写 `view_report` + 新 i18n | `install.sh:654-672` | 🟡 中 |
| **GAP-8** | i18n 部分用 `:-` 兜底（6 处） | 完整 zh/en 对应，无兜底 | 英文版体验降级 | 补 zh/en 翻译键 | `zh.sh` + `en.sh` | 🟢 低 |
| **GAP-9** | 移除参数报错 5 行黄色提示 | 简化为 1 行错误 + 1 行 usage | 输出冗余 | 改 `_parse_args` 错误分支 | `install.sh:119-130` | 🟢 低 |

### GAP 优先级分布

- 🔴 高：1 个（GAP-3）
- 🟡 中：4 个（GAP-1/2/4/5/7）
- 🟢 低：3 个（GAP-6/8/9）

### GAP 依赖关系

```
GAP-4/5/6 → 都改 show_system_status → 合并 1 Task
GAP-1/2   → 都改 show_main_menu      → 合并 1 Task
GAP-7     → view_report 升级         → 独立
GAP-8     → 纯 i18n                  → 独立
GAP-9     → 单点优化                 → 独立
```

> 📝 **自检记录**：本版本经自检发现，原 [GAP-3]「view_report 在 [6]」不成立——当前 install.sh 已将 view_report 放在 [11]，原 Plan 的旧位置已被新代码自然演进覆盖。因此删除该 GAP，对应 Task 也删除。

---

## 5. 实施 Tasks

6 个独立 commit，每个 commit = install.sh 改 + i18n 改 + bats 测试（如适用）。

| # | 标题 | 关联 GAP | 改动文件 | 测试 | 预估行数 |
|---|---|---|---|---|---|
| **T1** | 模块 4-9 加子菜单壳 | GAP-3 | `install.sh` (新增 6×2 函数) + `zh.sh`/`en.sh` (+18 键) | 新增 `tests/unit/menu-shells.bats` | ~150 |
| **T2** | 顶层菜单加分隔线 + 顶部状态摘要 | GAP-1, GAP-2 | `install.sh:show_main_menu` + lang | 同步 menu bats | ~30 |
| **T3** | 状态检测：评分 + 颜色 + 表格 + 建议下一步 | GAP-4, GAP-5, GAP-6 | `install.sh:show_system_status` + lang | 新增 `tests/unit/system-status.bats` | ~120 |
| **T4** | view_report 升级：历史报告列表 | GAP-7 | `install.sh:view_report` + lang | 新增 `tests/unit/view-report.bats` | ~80 |
| **T5** | i18n 补全：移除 `:-` 兜底 | GAP-8 | `zh.sh` + `en.sh` | 同步 lang 相关 bats | ~20 |
| **T6** | 非交互错误提示精简 | GAP-9 | `install.sh:_parse_args` | 新增 `tests/unit/parse-args.bats` | ~10 |

### 任务依赖顺序

```
T5 (i18n) 可最先做（独立、无依赖）
T1 (子菜单壳) — 高优先级、最先做以建立新结构
T2 (菜单分组) — 依赖 T1 的子菜单壳输出格式
T3 (状态检测) — 独立，但 i18n 键可能与 T5 冲突 → 排在 T5 之后
T4 (view_report 升级) — 独立
T6 (错误提示) — 独立、最简单
```

**推荐实施顺序**：T5 → T1 → T2 → T3 → T4 → T6

### 验证（每个 Task commit 前）

```bash
shellcheck -x install.sh scripts/**/*.sh
bats tests/unit/*.bats
```

### 文档同步（每个 Task commit 后）

- 更新 `HANDOVER.md` 变更日志
- 更新本文档 §5 的"实施状态"小节：标记哪个 GAP/Task 已修
- 全部 Task 完成后：本文档 `status: proposed` → `status: active`

### 范围之外（本文档不处理）

- 底层模块（ssh.sh / firewall.sh / fail2ban.sh / audit.sh / users.sh / kernel.sh / filesystem.sh / services.sh）内部重构
- 新增菜单项（如备份/回滚入口、状态仪表盘）
- 抽离菜单相关函数到独立文件（如 `scripts/base/menu.sh`）— 后续重构
- E2E 测试（Docker 容器）— 属 v1.0 发布范畴

---

## 6. 风险与回滚

| 风险 | 缓解 |
|---|---|
| 一次性改太多破坏交互流程 | Task 严格单 commit、可独立 revert；改前先 grep 当前 case 分支确认无遗漏引用 |
| 子菜单壳新加 12 个函数膨胀 install.sh | 后续可抽到 `scripts/base/menu.sh`，不在本批范围（§5 范围外已声明） |
| 新增 bats 用例覆盖不全 | 每个 Task commit 前自审 + `bats --count` 校验 |
| i18n 同步遗漏 | T5 专项处理；后续 Task commit 前 grep `:-` 兜底确认无新增 |
| view_report 移动位置破坏老用户习惯 | 已不适用（自检后删除该 GAP）|

---

## 7. 实施状态

| Task | GAP | 状态 | Commit |
|---|---|---|---|
| T1 | GAP-3 | ⬜ 未开始 | — |
| T2 | GAP-1, GAP-2 | ⬜ 未开始 | — |
| T3 | GAP-4, GAP-5, GAP-6 | ⬜ 未开始 | — |
| T4 | GAP-7 | ⬜ 未开始 | — |
| T5 | GAP-8 | ⬜ 未开始 | — |
| T6 | GAP-9 | ⬜ 未开始 | — |

---

## 8. 进度记录

- 2026-07-10：创建本文件，status=proposed，合并原 PRD + Plan 内容
- 2026-07-10：原 `main-menu-redesign-prd.md` / `plan.md` → archived + superseded-by 本文件
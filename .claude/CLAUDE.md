# Linux One-Key

Linux 一键安装/安全加固脚本项目。

## Session Entry Point

每次启动会话时，agent **必须**先读取 `HANDOVER.md` 以恢复项目上下文。该文件包含当前进度、已完成工作、文件清单、技术决策、下一步计划、变更日志。

> 如果 `HANDOVER.md` 不存在或被误删，回退策略：执行 `git log --oneline -20` 推断最近进展，并扫描 `docs/`、`scripts/`、`config/` 顶层目录了解当前结构。

## Communication Principles

Agent 与用户的协作原则：**永远不替用户拍板**。任何模糊、不确定、有多种合理选择的情况，都必须停下来提问，由用户做决策。

### Core Rule（铁律）

> 有问题 → 问。模棱两可 → 问。不清楚 → 问。让用户选 → 问。

| 触发场景 | 必做 |
|---|---|
| 需求有多种合理实现路径 | 用 `AskUserQuestion` 列出选项，由用户选 |
| 信息缺失、必须猜测才能继续 | 停下来问，不要替用户假设 |
| 文件归属 / 命名 / 位置不明确 | 问，不要凭感觉决定 |
| 现有规则未覆盖的边界情况 | 问，并建议把规则补进 CLAUDE.md |
| 用户表述前后矛盾或字面模糊 | 问，不要"猜中" |
| 决策一旦执行不可逆或代价大（重命名脚本、删除配置、改动包管理逻辑） | 必须问 |
| 任务收尾前对结果是否符合预期不确定 | 收尾前主动确认 |

### 工具选择

- **首选 `AskUserQuestion`**：结构化提问、单选/多选、内置选项描述和预览支持
- 自然语言对话提问仅用于**极简单**的即时确认；任何"分支式"决策仍必须用 `AskUserQuestion`
- **不论用哪种方式，都不要直接动手 —— 等用户答复后再继续**

### 反模式（禁止）

- ❌ "我猜你想要 ..." 然后直接动手
- ❌ "通常我会 ..." 跳过提问
- ❌ 一次问 5+ 个不相关的问题（保持每轮 1–4 个相关问题）
- ❌ 把决策包装成"已确认"的事实再继续
- ❌ 用户已经明确说过"以后别问"还反复确认

### 提问时机

| 阶段 | 触发条件 |
|---|---|
| **任务启动** | 需求宽泛 → 立刻细化范围 |
| **执行中** | 遇到分支点 / 发现新约束 / 检测到冲突 |
| **收尾前** | 确认结果符合预期，避免"自嗨式交付" |

## Plan-First Principle（计划优先原则）

> 做工程，先计划，再动手。

对于**任何稍复杂或稍大工程量**的任务（不限于 vault 改进，包括批量操作、跨文件重构、阶段化工程、技术方案选型等），agent **必须**在执行前先撰写计划文件。

### 触发条件

以下任务类型触发计划前置要求：

| 任务类型 | 典型场景 |
|---|---|
| 跨多文件的批量操作 | 批量重命名脚本、跨模块重构、批量 i18n 修复 |
| 涉及结构性变更 | 文件夹重组、模板升级、引入新脚本或自动化工具 |
| 逻辑链条较长或判断点较多 | 全项目审计、阶段化改进、技术方案选型（如包管理器选型） |
| 效果不可逆或回滚成本高 | 批量重命名、大规模移动脚本、一次性迁移、修改 SSH 防火墙逻辑 |
| 预计 commit ≥ 3 次 | 任何需要较长时间完成的任务 |

**纯机械 / 简单任务**（单条命令、单词配置项修改、单文件 bug 修复）不在此限。拿不准时，宁可多写一份 plan，不要省。

### 计划文件规范

> ⚠️ **每次写计划文件，必须先读 [`docs/plans/README.md`](../../docs/plans/README.md) 并严格遵守。** 以下为快速摘要，权威规范以 README 为准。

**必读**：[`docs/plans/README.md`](../../docs/plans/README.md)

**摘要**：

- 计划文件统一保存在 `docs/plans/` 目录
- 文件名格式：`YYYY-MM-DD_HH-MM_<topic-kebab>[_<commit-ref>].md`（非 commit 相关用 `_nogit`）
- frontmatter 必填字段：`created` / `updated` / `status`；推荐字段：`title` / `source` / `topic`
- 计划内容建议包含：背景 / 目标 / 执行步骤 / 预期产出 / 风险与注意事项 / 进度记录
- 本地临时草稿可用 `*_nogit.md` 后缀（不入仓）
- **不删除文件**——所有状态的计划文件都保留作为历史记录

### Living Plan（计划即活记录）

计划文件不是写完就丢的静态文档，而是**伴随执行持续更新的记录**：

1. **初始** → 创建 `.md` 文件，`status: draft`，与用户对齐内容
2. **对齐后** → `status: in-progress`，开始执行
3. **执行中** → 按实际进度更新：已完成的步骤打勾标记、变更决策追加说明、遇到阻塞记录原因
4. **完成时** → `status: done`，同步更新 frontmatter 与文件名日期前缀，并更新 `HANDOVER.md` 变更日志
5. **中途废弃** → `status: superseded` 或 `archived`，保留文件作为历史记录，不删除

此原则与 [Phased Improvement Workflow](#phased-improvement-workflow) 协同运作：阶段性改进时，每阶段开始前同样先建计划文件。

## 项目概述

Linux 云服务器安全加固 + 一键环境初始化脚本。用户通过 SSH 连接到新购买的云服务器后，运行主入口脚本即可交互式完成安全配置或软件安装。

**核心特性**：

- 交互式操作，每步确认
- 支持 CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma
- 所有修改前备份，支持回滚
- 幂等设计，重复运行不出错

## 开发规范

- Shell 脚本使用 Bash，首行 `#!/usr/bin/env bash`
- 所有脚本必须设置 `set -euo pipefail`
- 函数命名使用 `snake_case`，常量使用 `UPPER_SNAKE_CASE`
- 每个函数必须有注释说明用途
- 脚本需兼容主流发行版（CentOS 7+, Ubuntu 20.04+, Debian 11+, Rocky, Alma）
- 输出信息使用颜色区分：绿色=成功，红色=错误，黄色=警告，蓝色=信息
- 使用 utils.sh 提供的 log_* 统一日志函数（log_info/log_success/log_warn/log_error），不要直接 echo

## 项目结构

```
linux-one-key/
├── install.sh              # 主入口（菜单、交互流程、curl管道支持）
├── CLAUDE.md               # 本文件
├── HANDOVER.md             # 强制交接文档（精简后约 250 行）
├── README.md
├── scripts/                # 安装脚本目录
│   ├── base/               # 基础环境（utils.sh, detect.sh, init.sh, report.sh）
│   ├── security/           # 安全加固（ssh/firewall/fail2ban/users/kernel/filesystem/audit/services）
│   ├── dev/                # 开发工具脚本（如 gen-file-tree.sh）
│   ├── server/             # 服务器软件安装（预留）
│   ├── lang/               # i18n 文件（zh.sh, en.sh）
│   └── utils/              # 通用工具函数（预留）
├── config/                 # 配置文件模板（fail2ban/, sysctl/, audit/）
├── docs/                   # 文档
│   ├── plans/              # 计划文件（Plan-First 落地目录，含 README）
│   ├── design/             # 架构设计 & 实施计划
│   ├── code-reviews/       # Code Review 报告
│   ├── test-reports/       # 测试报告
│   ├── handover-archive.md # 历史变更日志归档（2026-06-20~24）
│   └── file-tree.generated.md # 自动生成的文件树（gitignored）
└── tests/                  # Bats 单元测试（unit/）
```

## 测试

- 使用 ShellCheck 进行静态检查（`shellcheck scripts/**/*.sh`）
- 使用 Bats 进行单元测试（`bats tests/unit/*.bats`）
- 新增脚本/函数必须在 `tests/unit/` 添加对应测试用例
- 提交前必须跑通 `shellcheck` + `bats`

## Phased Improvement Workflow

大型项目改进（高级功能接入 / 全项目审计 / 跨模块重构 / 阶段性重构）**必须**按阶段推进，避免一次性大批量改动。

**每个阶段的强制流程**：

1. **计划先行**：阶段开始前在 `docs/plans/` 创建一份计划文件，状态设为 `draft`
2. **确认后再执行**：与用户对齐计划内容（哪些项要做、按什么顺序、放弃哪些项），确认后改 `status: in-progress` 并开始执行
3. **阶段内小步前进**：
   - 单类修复（先修 X → 再修 Y → 再修 Z）
   - 每个最小改动单元 → **单独一次 commit**
4. **阶段完成时**：
   - 更新计划文件 frontmatter `status: done` 和 `updated:`
   - 更新文件名日期前缀到当前时间
   - 同步更新 `HANDOVER.md` 的变更日志
   - 写一条总结 commit：`docs: mark <plan-name> as done`
5. **不跨阶段合并 commit**：phase 1 的修复不应混入 phase 2 的增强
6. **不留半成品跨 commit**：一次 commit 必须自洽——shellcheck 通过、测试通过、构建可运行

## Git Workflow

### Commit Format

遵循 conventional commits：

```
feat: add nginx install script
fix: correct centos package version detection
refactor: extract common firewall helpers to utils
docs: add RHEL_Family OS support matrix
test: add fail2ban rollback test cases
chore: update bats to v1.11
```

### Local Commit Frequency（本地提交频率：尽量提高）

**核心原则**：本地 commit **尽可能高频、尽可能小颗粒**。本地历史是详细、可重放的操作日志，每个逻辑步骤都应可见。

**Commit 触发条件**（满足任一即可本地 commit）：

| 触发条件 | 示例 |
|---|---|
| 完成一个独立逻辑单元 | 写完一个函数 / 一个 shell 脚本 / 一个测试用例 → 立即 commit |
| 一次会话多个变更 | 每 2-3 个改动 commit 一次；**绝不让 5+ 个未提交改动堆积** |
| 结构性变更 | 目录移动 / 文件重命名 / 模板编辑 / 配置文件调整 → 立即 commit |
| 阶段性改进 | 每加一个新功能 / 每修复一类问题 → 一次 commit |
| Code Review 修复 | CRITICAL 一起一次 / HIGH 一类一个 commit / MEDIUM 一类一个 commit |
| 文档/配置同步 | `HANDOVER.md` 变更日志 / `CLAUDE.md` 规范更新 → 独立 commit |
| 计划文件状态变更 | plan 文件从 draft → in-progress → done → 独立 commit |

> 💡 **口诀**：能 commit 就 commit；不要攒着。攒 commit 会让回滚粒度变粗、code review 困难、出问题时定位麻烦。

### Push Frequency（远端推送：务必先整理）

**核心原则**：本地频繁 commit，**push 之前务必先整理合并**。绝不长串碎片 micro-commit 直接推上 `main`。

**Push 三步走**：

```
1. 询问用户：是否要 push？       ← 必须确认，未经允许绝不 push
2. 整理本地 commit：               ← 必要时执行
   git rebase -i HEAD~N           ← squash/fixup 合并相关 tiny commit
3. 推送：git push                  ← 仅当用户明确批准
```

**整理原则**：

| 整理方式 | 何时使用 |
|---|---|
| `fixup` / `squash` | 同一类小修复（如"修复多个 typo"），合并为一个 commit |
| `reword` | 改写 commit message，使其语义更清晰 |
| `reorder` | 调整 commit 顺序，让逻辑链路更顺畅 |
| 保留独立 | 大功能、新模块、破坏性变更 → 保留为独立 commit |

**整理后每个 commit 应满足**：

- ✅ 一个明确的语义单元（如 `feat: add SSH hardening module`）
- ✅ 一次 commit 自洽（脚本通过 shellcheck、测试通过、构建可运行）
- ✅ commit message 符合 conventional commits 规范
- ❌ 不应是大杂烩（5+ 个无关改动混在一起）

**整理时机**：仅在准备 push 时、且经用户同意后执行。本地 micro-commit 累积是预期工作流。

### Push Policy（铁律）

| 规则 | 说明 |
|---|---|
| 🚫 **未经用户明确批准，绝不 push** | 始终先问；绝不主动 `git push`，即便在任务或会话结束 |
| ✅ **可以适当提醒用户** | 任务收尾时若有未推送的本地 commit，可提示"已有 N 个本地 commit 待整理推送，是否需要？" |
| 🚫 **绝不长串 micro-commit 直接 push** | 必须先 rebase 整理 |
| 🚫 **绝不 force push 到 main** | 即使用户同意整理 push，也只能 `git push`，不可 `--force` 到 main |

## ECC Plugin Usage

本项目启用 ECC (everything-claude-code) 插件作为 Claude Code 增强层（位于 `everything-claude-code/` 子目录，参考 [官方文档](https://github.com/affaan-m/ECC/blob/main/README.zh-CN.md)）。以下命令为**本项目必须规范化使用**的核心命令。

### 核心命令清单

| 命令 | 触发时机 | 说明 |
|---|---|---|
| `/plan` | 复杂任务启动前 | 实现规划 + 任务拆解，与本项目 Plan-First Principle 配合 |
| `/code-review` | 重要变更后 / 准备 push 前 | 代码质量审查，diff 维度的系统性检查（参考本项目历史已多次使用） |
| `/security-scan` | **任何修改 `scripts/security/*` 后强制** | 安全扫描（基于 AgentShield），本项目为安全加固脚本，安全审查尤为关键 |
| `/refactor-clean` | 月度维护 / Phase 重构后 | 死代码、未引用函数、重复代码清理 |
| `/quality-gate` | 准备 push 前 | 部署前质量门禁：综合 lint / 测试 / 安全 / 文档 完整性检查 |
| `/build-fix` | shellcheck / bats 失败时 | 构建错误诊断与修复（适配本项目的 shellcheck + bats） |
| `/update-docs` | 文档变更后 | 文档同步（`README.md` / `docs/` / 注释） |
| `/test-coverage` | 新增模块后 | 测试覆盖率分析（参考值，非硬性目标） |

### 使用规则

1. **复杂任务必先 `/plan`**：与 Plan-First Principle 一致，复杂任务前先运行 `/plan` 生成执行计划
2. **安全模块修改后必跑 `/security-scan`**：`scripts/security/*.sh` 修改后立即运行，确认无新增安全风险
3. **push 前必跑 `/quality-gate`**：本地 commit 整理后、push 之前作为最后一道质量门禁
4. **Code Review 配合 `/code-review`**：本项目历史已通过 `/code-review` 发现 CRITICAL/HIGH 问题，应持续使用
5. **跨命令组合使用**：典型流程 `/plan` → 实施 → `/code-review` → `/security-scan`（如适用）→ `/quality-gate` → 整理本地 commit → push

### 不适用的命令

以下命令为 ECC 提供但**本项目不适用**，不要调用：

| 命令 | 不适用原因 |
|---|---|
| `/python-review` `/go-review` `/go-test` `/go-build` | 本项目是 Bash 脚本，无 Python/Go 代码 |
| `/setup-pm` `/pm2` | 本项目无 Node.js 服务，无需 PM2 |
| `/multi-plan` `/multi-execute` `/multi-backend` `/multi-frontend` | 需要 ccg-workflow 运行时，且本项目单体脚本规模无需多 agent 编排 |

> 📖 完整命令列表与详细说明见 [ECC 官方文档](https://github.com/affaan-m/ECC/blob/main/README.zh-CN.md)。如需新增/调整命令清单，请更新本节并 commit。

## 交接文档（强制）

**每次修改项目文件时，必须同步更新 `HANDOVER.md`。**

交接文档包含：

- 项目当前进度和状态
- 已完成的工作记录
- 文件清单（当前文件 + 计划文件）
- 技术决策记录
- 下一步工作建议
- 变更日志

规则详见 `.claude/rules/common/handover.md`。

## Dos and Don'ts

### ✅ DO（必做）

#### 任务启动

- ✅ **启动会话先读 [`HANDOVER.md`](../../HANDOVER.md)** 恢复上下文（缺失则用 `git log` + 目录扫描回退）
- ✅ **复杂任务必先写 plan 文件**（[`docs/plans/`](../../docs/plans/)），详见 Plan-First Principle 与 [plans README](../../docs/plans/README.md)
- ✅ **复杂任务启动前运行 `/plan`**（ECC 命令），与 plan 文件流程协同

#### 沟通与决策

- ✅ **遇到任何不清楚、模棱两可、稍有疑惑、找不着、不知道选哪个的问题 → 直接问用户**
- ✅ **多使用 `AskUserQuestion`**：结构化提问，单选/多选，附选项描述与预览
- ✅ **沟通时说明依据**：决策时列出"我看到的事实"+"我推断的理由"+"建议选项"，让用户基于完整信息判断
- ✅ **任务收尾前主动确认**：向用户汇报完成情况，确认是否符合预期，避免"自嗨式交付"

#### 开发与测试

- ✅ 所有 Shell 脚本设 `set -euo pipefail` 并写函数注释
- ✅ 使用 `utils.sh` 的 `log_*` 函数，不直接 `echo`
- ✅ 修改 `scripts/security/*` 后必跑 `/security-scan`
- ✅ 新增脚本/函数必须配对应 Bats 测试用例
- ✅ 提交前跑通 `shellcheck scripts/**/*.sh` + `bats tests/unit/*.bats`

#### Git 与文档

- ✅ 高频小颗粒本地 commit（详见 Git Workflow）
- ✅ push 前用 `/quality-gate` 做最后质量门禁
- ✅ push 前必先 `git rebase -i` 整理本地 commit
- ✅ **每次修改文件后同步更新 [`HANDOVER.md`](../../HANDOVER.md)** 变更日志

---

### 🚫 DON'T（禁止）

#### 决策相关

- 🚫 **不要替用户做决策**（铁律）
- 🚫 **不要"猜中"用户的意图**然后继续——表述模糊、需求矛盾、信息缺失时立即停下
- 🚫 **不要替用户假设默认值**（如默认值、命名规则、文件位置等有多种合理选择时）
- 🚫 **不要把决策包装成"已确认"的事实再继续**——直接说"我打算 XX，可以吗？"
- 🚫 **不要一次问 5+ 个不相关问题**（保持每轮 1–4 个相关问题）

#### Plan 相关

- 🚫 **不要在没有 plan 文件的情况下做大型重构 / 跨模块修改**（详见 Plan-First Principle）
- 🚫 **不要省略 Plan-First 的"与用户对齐"步骤**——写完 plan 后必须等用户确认才能改 status 为 in-progress

#### Git 相关

- 🚫 **不要主动 `git push`**——必须先问用户；但可以适当提醒用户
- 🚫 **不要长串 micro-commit 直接 push 到 main**——必须先 rebase 整理
- 🚫 **不要 force push 到 main**
- 🚫 **不要把多个不相关改动合并到一个 commit**（每类问题 / 每语言 / 每模块单独）
- 🚫 **不要把多个 i18n key 改完合并成一个 commit**——每语言单独
- 🚫 **不要跳过 commit message 规范**（conventional commits）

#### 质量相关

- 🚫 **不要跳过 ShellCheck / Bats 测试**
- 🚫 **不要修改 `scripts/security/*` 后不跑 `/security-scan`**
- 🚫 **不要在没有测试覆盖的情况下引入新脚本/函数**
- 🚫 **不要使用 `echo` 替代 `log_*` 函数**（除非是脚本交互输出）
- 🚫 **不要硬编码密钥、密码、token**——使用环境变量或 config 模板

#### 文档相关

- 🚫 **不要修改文件后忘记更新 `HANDOVER.md`**
- 🚫 **不要把不同阶段的工作合并到一次 commit**（详见 Phased Improvement Workflow）
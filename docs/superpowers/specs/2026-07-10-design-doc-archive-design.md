---
title: "设计文档归档规范化 (docs/design/)"
created: 2026-07-10
updated: 2026-07-10
status: approved
source: "项目文件夹臃肿 → docs/design/ 6 个 md 中 4 个 >8KB，包含已实施/未实施/重设计混合状态"
topic: "docs-refactor"
---

## 背景

`docs/design/` 当前 **6 个 md 文件 / 总计 ~88KB**，混合三种状态：

| 文件 | 大小 | 日期 | 状态 | 说明 |
|---|---|---|---|---|
| `interactive-setup-plan.md` | 35KB | 2026-06-20 | **已实施**（2026-06-23） | 交互式重构 plan |
| `linux-security-hardening-prd.md` | 25KB | 2026-06-23 | 活跃参考 | 总 PRD |
| `main-menu-redesign-plan.md` | 11KB | 2026-06-23 | **未实施** | 主菜单重设计 plan |
| `interactive-setup-spec.md` | 8KB | 2026-06-20 | **已实施** | 交互式重构 spec |
| `main-menu-redesign-prd.md` | 8KB | 2026-06-20 | **未实施** | 主菜单重设计 PRD，状态"待审批" |
| `README.md` | 0.8KB | 2026-06-23 | 索引 | 简单列表索引 |

**臃肿诊断**：

1. **35KB 单文件** `interactive-setup-plan.md` 实施完成后未归档
2. **2 套设计文档并列**：v0.1 早期设计（已实现）+ v0.4 后期重设计（未实施）
3. **缺少状态元数据**：用户/agent 无法一眼分辨"哪些是历史、哪些是规划、哪些是当前参考"
4. **README 索引陈旧**：仅按时间顺序列出，未按状态分组

**约束**（用户明确）：

- ❌ 不改变项目功能
- ❌ 不动 `scripts/**/*.sh`、`install.sh` 等核心功能代码
- ✅ 仅规范化 `docs/design/` 文档结构与元数据
- ✅ 不删除文件（归档而非删除）

## 目标

将 `docs/design/` 从"按时间排列的扁平目录"重构为"按状态分层的可维护结构"，具体：

1. **目录位置 + frontmatter** 双层表达状态
2. **未实施文档留在顶层**（视觉可见"待办"）
3. **已实施文档归档** 到 `archive/` 子目录
4. **README.md 升级** 为按状态分层的索引表
5. **未来新增文档有规范可循**（frontmatter 三态 + README 更新触发器）

## 设计

### 目录结构

```
docs/design/
├── README.md                                  # 重写为分层索引
├── linux-security-hardening-prd.md           # status=active（总 PRD，活跃参考）
├── main-menu-redesign-prd.md                 # status=proposed（待审批）
├── main-menu-redesign-plan.md                # status=proposed（待审批）
└── archive/                                  # 新建子目录
    ├── README.md                             # archive 子目录索引（可选）
    ├── interactive-setup-spec.md             # 移入（已实施）
    └── interactive-setup-plan.md             # 移入（已实施）
```

**关键决策**：

- `git mv` 而非"删除 + 新建"：保留完整 git 历史
- `archive/` 是 docs/design 内**专属子目录**，不是顶层 archive（避免破坏其他 docs/ 子目录）
- main-menu 重设计留在顶层：用户明确说"按已实施/未实施分类归档"，未实施不进 archive

### frontmatter 元数据规范

每个保留在 `docs/design/` 顶层或 `archive/` 的 `.md` 顶部插入 YAML frontmatter（参考 `docs/plans/README.md` 已建立的规范）：

```yaml
---
title: "<原文件名去掉 .md>"
status: active | proposed | archived
created: YYYY-MM-DD         # 文件创建日期（git log 推断）
updated: YYYY-MM-DD         # 最后更新日期
implemented: YYYY-MM-DD     # 仅 status=archived 时填写
supersedes: <旧文件名>      # 可选
superseded-by: <新文件名>   # 可选
---
```

**三态语义**：

| status | 含义 | 目录位置 | 可见性 |
|---|---|---|---|
| `active` | 当前活跃参考（如总 PRD） | `docs/design/` 顶层 | 长期可见 |
| `proposed` | 已规划/待审批，**未实施** | `docs/design/` 顶层 | 视觉待办 |
| `archived` | 已实施完成，仅作历史参考 | `docs/design/archive/` | 仅历史参考 |

**字段填充规则**：

| 文件 | title | status | created | updated | implemented |
|---|---|---|---|---|---|
| linux-security-hardening-prd.md | Linux Security Hardening PRD | active | 2026-06-20 | 2026-06-23 | — |
| main-menu-redesign-prd.md | Main Menu Redesign PRD | proposed | 2026-06-20 | 2026-06-23 | — |
| main-menu-redesign-plan.md | Main Menu Redesign Plan | proposed | 2026-06-23 | 2026-06-23 | — |
| archive/interactive-setup-spec.md | Interactive Setup Spec | archived | 2026-06-20 | 2026-06-20 | 2026-06-23 |
| archive/interactive-setup-plan.md | Interactive Setup Plan | archived | 2026-06-20 | 2026-06-20 | 2026-06-23 |

> `created` 与 `updated` 取自 `git log` 与文件 `ls -la` 综合判断

### README.md 索引设计

重写为"按状态分层"：

```markdown
# Design Documents

> 项目设计文档、PRD、规划。**文件位置 + frontmatter `status` 双层区分状态**。
>
> 维护规则：
> - 新设计文档须含 frontmatter `status` 字段
> - 状态变更须同步更新 frontmatter 与本 README
> - 已实施文档须迁入 `archive/`，不得堆在顶层

## 活跃文档 (status=active)

| 文件 | 用途 |
|---|---|
| [linux-security-hardening-prd.md](linux-security-hardening-prd.md) | 项目总 PRD，v1.0 目标 |

## 待审批文档 (status=proposed)

| 文件 | 用途 |
|---|---|
| [main-menu-redesign-prd.md](main-menu-redesign-prd.md) | 主菜单重设计 PRD（**未实施**） |
| [main-menu-redesign-plan.md](main-menu-redesign-plan.md) | 主菜单重设计实施计划（**未实施**） |

## 已归档 (status=archived)

详见 [docs/design/archive/](archive/)。

| 文件 | 实施日期 |
|---|---|
| `archive/interactive-setup-spec.md` | 2026-06-23 |
| `archive/interactive-setup-plan.md` | 2026-06-23 |
```

### archive/README.md 设计（可选）

如果 archive 内文件超过 3 个，建议加 `archive/README.md` 简单索引。本次 2 个文件，**可选跳过**。

## 实施步骤

| 阶段 | 操作 | commit message |
|---|---|---|
| 1 | `git mv` 2 个已实施文件到 `archive/` | `docs(design): migrate 2 implemented documents to archive/` |
| 2 | 为 3 个保留文档插入 frontmatter（不动主体） | `docs(design): add status frontmatter to 3 active design docs` |
| 3 | 重写 `docs/design/README.md` 为分层索引 | `docs(design): rewrite README.md as layered status index` |
| 4 | 同步 `CLAUDE.md` 项目结构 + `HANDOVER.md` 变更日志 | `docs: sync CLAUDE.md and HANDOVER.md for design restructure` |

**Commit 触发原则**（来自 CLAUDE.md）：
- 每个阶段一个 commit
- 不跨阶段合并
- 不留半成品跨 commit（每个 commit 后 README/frontmatter 自洽）

## 预期产出

| 文件 | 变化 |
|---|---|
| `docs/design/README.md` | 0.8KB → ~1.5KB（重写为分层索引） |
| `docs/design/archive/` | 新建子目录 |
| `docs/design/archive/interactive-setup-spec.md` | 移入（git mv 保留历史） |
| `docs/design/archive/interactive-setup-plan.md` | 移入（git mv 保留历史） |
| `docs/design/linux-security-hardening-prd.md` | + frontmatter（不改主体） |
| `docs/design/main-menu-redesign-prd.md` | + frontmatter（不改主体） |
| `docs/design/main-menu-redesign-plan.md` | + frontmatter（不改主体） |
| `.claude/CLAUDE.md` | 项目结构章节 +1 行（`docs/design/archive/`） |
| `HANDOVER.md` | 变更日志追加 4 条 |

**总产出**：1 个新子目录、5 个 frontmatter 新增、4 个 commits、1 个 README 重写、CLAUDE.md + HANDOVER.md 同步。

## 风险与注意事项

| 风险 | 缓解 |
|---|---|
| `git mv` 失败（用户曾提到 macOS 上有文件锁问题） | 用 `git mv` 标准命令；如失败用 `mv + git add -A + git rm` 组合 |
| main-menu 重设计是否会被用户误判为"待办" | frontmatter status=proposed + README "待审批" 标注，视觉+语义双层明确 |
| 35KB 大文件移动后查找变慢 | 文件物理位置不影响内容检索；`grep -r` 仍可全文搜索 |
| 未来"已实施"的 proposed 文档如何处理 | 维护规则：实施完成 → 改 status=archived + 填 implemented + 移到 archive/ + 更新 README |
| HANDOVER.md 变更日志膨胀 | 遵循上次精简原则，4 条新条目符合 "近期保留 + 历史归档" 模式 |
| 不会修改核心功能代码 | 整个 spec 只动 docs/ 目录的元数据 + 目录结构；scripts/ 与 install.sh 零变更 |

## 验收标准

完成后自检：

- [ ] `git log --follow docs/design/archive/interactive-setup-plan.md` 能追溯到原始 commit 历史
- [ ] `head -10 docs/design/main-menu-redesign-prd.md` 显示 status: proposed
- [ ] `head -10 docs/design/archive/interactive-setup-plan.md` 显示 status: archived + implemented: 2026-06-23
- [ ] `docs/design/README.md` 三段表格完整（active / proposed / archived）
- [ ] `shellcheck scripts/**/*.sh` 仍然通过（无脚本改动）
- [ ] `bats tests/unit/*.bats` 仍然通过（无测试改动）
- [ ] `git log --oneline HEAD~4..HEAD` 显示 4 个规范 commits
- [ ] `HANDOVER.md` 末尾变更日志追加 4 条本次操作
- [ ] `.claude/CLAUDE.md` 项目结构章节显示 `archive/` 子目录
- [ ] `docs/file-tree.generated.md` 通过 `bash scripts/dev/gen-file-tree.sh` 重新生成，反映新结构

## 进度记录

- 2026-07-10 12:55：创建 spec，status=draft
- 2026-07-10 12:55：用户对齐设计 4 节内容
- 2026-07-10 12:55：spec 完成 → status=approved
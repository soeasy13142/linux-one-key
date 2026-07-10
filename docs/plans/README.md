# `docs/plans/` — 计划文件存放区

本目录专门存放**针对 linux-one-key 项目的计划文件**（功能开发计划、Code Review 修复计划、阶段化改进计划、迁移计划、架构调整计划等）。

由 CLAUDE.md 的 **Plan-First Principle** 于 2026-07-10 设立，作为以后所有计划文件的统一存放点。

---

## 命名规范

```
YYYY-MM-DD_HH-MM_<topic-kebab>[_<commit-ref>].md
```

| 段 | 说明 | 示例 |
|---|---|---|
| `YYYY-MM-DD_HH-MM` | 最后修改日期 + 时分（按文件名排序，确保最新计划排在前） | `2026-07-10_14-30` |
| `<topic-kebab>` | 简短主题/问题，kebab-case（单词用小写 + `-` 分隔） | `code-review-r3-fixes` |
| `_<commit-ref>` | **可选**。针对的提交哈希（多个用 `-` 连接）；非提交相关计划用 `nogit` | `_7c65964-7186aa2` 或 `_nogit` |

### 命名示例

| 计划类型 | 文件名 |
|---|---|
| Code Review Round 3 修复（针对 2 个 commit） | `2026-07-10_14-30_code-review-r3-fixes_7c65964-7186aa2.md` |
| 新功能开发（非 commit 相关） | `2026-07-15_09-00_add-nginx-installer_nogit.md` |
| 阶段性改进（如 v1.0 测试 + 文档） | `2026-07-20_10-00_v1-release-prep_nogit.md` |
| 紧急 bug 修复（针对单个 commit） | `2026-07-12_16-45_ssh-rollback-race-fix_a27edc0.md` |

> 编写日期保存在 frontmatter `created:`，最后修改日期同步写入 `updated:` 与文件名前缀。

---

## 计划文件结构

每个计划文件**必须**含 YAML frontmatter + Markdown 正文。

### Frontmatter（必填字段）

```yaml
---
title: "Code Review Round 3 修复计划"      # 简短标题（可选）
created: 2026-07-10                         # 编写日期（YYYY-MM-DD）
updated: 2026-07-10                         # 最后修改日期（YYYY-MM-DD）
status: draft                               # draft | in-progress | done | archived | superseded
source: "Code Review Round 3 report"        # 起因：commit hash / 报告名 / 需求来源
topic: "code-review"                        # 主题分类：code-review | feature | refactor | bugfix | release
---
```

### 字段说明

| 字段 | 必填 | 说明 |
|---|---|---|
| `title` | 推荐 | 计划标题，便于在文件列表中识别 |
| `created` | ✅ | 编写日期，状态从 draft 起即固定 |
| `updated` | ✅ | 最后修改日期，每次更新时同步刷新 |
| `status` | ✅ | 生命周期状态（见下表） |
| `source` | 推荐 | 计划起因（commit hash / 报告路径 / 需求简述） |
| `topic` | 推荐 | 主题分类，便于检索 |

### 状态生命周期

```
draft  →  in-progress  →  done
                       ↘  archived（中途废弃）
                       ↘  superseded（被新计划替代）
```

| 状态 | 含义 | 触发条件 |
|---|---|---|
| `draft` | 待确认 | 计划创建后初始状态；与用户对齐内容中 |
| `in-progress` | 执行中 | 用户确认计划后改为该状态，开始执行 |
| `done` | 已完成 | 全部阶段任务完成 + HANDOVER.md 同步更新 |
| `archived` | 中途废弃 | 计划不再需要但保留作为历史记录 |
| `superseded` | 被替代 | 新计划取代本计划，保留作为历史 |

> ⚠️ **不删除文件**——所有状态（含 done / archived / superseded）的计划文件都保留作为历史记录。

---

## 正文结构建议

```markdown
## 背景

为什么需要这个计划？要解决的问题是什么？

## 目标

明确、可验证的目标（如"修复全部 32 个 CRITICAL bug"）。

## 执行步骤

- [ ] 步骤 1：xxx
- [ ] 步骤 2：xxx
- [ ] 步骤 3：xxx

## 预期产出

- 新增/修改的文件清单
- 单元测试覆盖情况
- 文档更新情况

## 风险与注意事项

- 可能影响范围
- 回滚方案
- 需要用户确认的决策点

## 进度记录

- 2026-07-10: 创建计划，status=draft
- 2026-07-10: 用户确认，status=in-progress
- 2026-07-12: 完成步骤 1-3
- ...
```

---

## 规则

1. **文件名不含空格**，主题段用 `-`，主段间用 `_`。
2. **frontmatter 必填字段**：`created` / `updated` / `status`。
3. **`status` 变化时同步更新**：
   - frontmatter 的 `status` 与 `updated`
   - 文件名中的日期前缀（反映最后修改时间）
4. **不删除文件**——`done` / `archived` / `superseded` 都保留作为历史。
5. **本地临时草稿**可用 `*_nogit.md` 后缀（不入仓），但建议先放入正式目录管理。
6. **每个最小改动单元单独一次 commit**，计划内的进度通过 commit 反映，不要在 plan 文件里写"已 commit 但未完成"。

---

## 与 CLAUDE.md 的协同

| CLAUDE.md 章节 | 与本 README 的关系 |
|---|---|
| [Plan-First Principle](../../.claude/CLAUDE.md#plan-first-principle计划优先原则) | 触发条件、Living Plan 生命周期（本 README 是文件名/结构的权威规范） |
| [Phased Improvement Workflow](../../.claude/CLAUDE.md#phased-improvement-workflow) | 每个阶段开始前在此目录创建计划文件 |
| [交接文档（强制）](../../.claude/CLAUDE.md#交接文档强制) | 计划状态变化时同步更新 `HANDOVER.md` |

> 每次写计划文件，**必须先读本 README**。如有规则变更，需同时更新本 README 与 CLAUDE.md，并作为一次 commit 提交。
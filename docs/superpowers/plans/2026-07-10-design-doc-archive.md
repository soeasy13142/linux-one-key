# Design Document Archive Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restructure `docs/design/` from a flat time-ordered directory into a status-layered, frontmatter-annotated directory that distinguishes active, proposed, and archived design documents.

**Architecture:** Create `docs/design/archive/` subdirectory for implemented documents. Retain proposed (not-yet-implemented) and active (reference) documents at `docs/design/` top level. Add YAML frontmatter `status` field to all design `.md` files. Rewrite `docs/design/README.md` as a layered status index. Sync `CLAUDE.md` project structure section and `HANDOVER.md` changelog.

**Tech Stack:** Git, Bash, Markdown, YAML frontmatter (parallels `docs/plans/README.md` convention).

## Global Constraints

- Project: linux-one-key (Linux 云服务器安全加固一键脚本)
- Working directory: `/Users/charliepan/Downloads/linux-one-key`
- Shell script style: Bash, `set -euo pipefail`, snake_case functions
- Commit message format: conventional commits (`type(scope): description`)
- Git policy: NEVER `git push` without explicit user approval; NEVER force-push to main
- DO NOT modify any file under `scripts/`, `install.sh`, `tests/`, `config/` — only docs/design/ and sync targets (CLAUDE.md, HANDOVER.md)
- DO NOT delete files — use `git mv` for migration
- DO NOT change file bodies of migrated files — only add frontmatter and rewrite README.md

---

## File Structure

| File | Action | Responsibility |
|---|---|---|
| `docs/design/archive/` | Create | Subdirectory for implemented design docs |
| `docs/design/archive/interactive-setup-spec.md` | git mv from `docs/design/` | Historical: interactive wizard spec, implemented 2026-06-23 |
| `docs/design/archive/interactive-setup-plan.md` | git mv from `docs/design/` | Historical: interactive wizard plan, implemented 2026-06-23 |
| `docs/design/linux-security-hardening-prd.md` | Modify (add frontmatter only) | Active PRD (project reference) |
| `docs/design/main-menu-redesign-prd.md` | Modify (add frontmatter only) | Proposed PRD (not yet implemented) |
| `docs/design/main-menu-redesign-plan.md` | Modify (add frontmatter only) | Proposed plan (not yet implemented) |
| `docs/design/README.md` | Rewrite | Status-layered index (active / proposed / archived) |
| `.claude/CLAUDE.md` | Modify (1 line in 项目结构 section) | Project structure diagram update |
| `HANDOVER.md` | Modify (append 4 rows to changelog) | Changelog entries for this restructure |

**Constraints recap:**
- scripts/, install.sh, tests/, config/ → **zero changes**
- 4 commits total, one per task below

---

## Task 1: Migrate 2 Implemented Documents to archive/

**Files:**
- Move: `docs/design/interactive-setup-spec.md` → `docs/design/archive/interactive-setup-spec.md`
- Move: `docs/design/interactive-setup-plan.md` → `docs/design/archive/interactive-setup-plan.md`
- Create: `docs/design/archive/` (subdirectory)

**Interfaces:**
- Consumes: nothing (initial step)
- Produces: 2 files now under `archive/`, ready for frontmatter in Task 2

- [ ] **Step 1: Verify pre-state (documents still at top level)**

Run: `ls -la docs/design/*.md`
Expected: 6 entries ending in `.md` (interactive-setup-spec.md, interactive-setup-plan.md, linux-security-hardening-prd.md, main-menu-redesign-prd.md, main-menu-redesign-plan.md, README.md)

- [ ] **Step 2: Create archive subdirectory**

Run: `mkdir -p docs/design/archive`
Expected: directory created; `ls -la docs/design/` shows `archive` entry

- [ ] **Step 3: git mv first document**

Run: `git mv docs/design/interactive-setup-spec.md docs/design/archive/interactive-setup-spec.md`
Expected: command exits 0; no error output

- [ ] **Step 4: git mv second document**

Run: `git mv docs/design/interactive-setup-plan.md docs/design/archive/interactive-setup-plan.md`
Expected: command exits 0; no error output

- [ ] **Step 5: Verify post-state (both files now in archive/, git tracks renames)**

Run: `git status --short && echo "---" && ls docs/design/archive/`
Expected:
- `git status` shows `R` (rename) markers for both files, prefixed with `docs/design/`
- `ls docs/design/archive/` shows 2 `.md` files

- [ ] **Step 6: Verify git history preserved (rename detection)**

Run: `git log --oneline --follow docs/design/archive/interactive-setup-plan.md | head -3`
Expected: shows the original commit history (e.g., `2e9e98b feat: merge welcome screen...` and earlier interactive-setup commits). If `git log --follow` returns no history, the rename was not detected and you must redo with `git mv`.

- [ ] **Step 7: Commit**

Run:
```bash
git add docs/design/
git commit -m "docs(design): migrate 2 implemented documents to archive/

- interactive-setup-spec.md (implemented 2026-06-23)
- interactive-setup-plan.md (implemented 2026-06-23)

git mv preserves history. Files themselves unchanged; frontmatter
will be added in a separate commit to keep this commit focused on
migration only.

See docs/superpowers/specs/2026-07-10-design-doc-archive-design.md"
```

Expected: commit succeeds; `git log --oneline -1` shows the new commit message.

---

## Task 2: Add Status Frontmatter to 3 Active/Proposed Documents

**Files:**
- Modify: `docs/design/linux-security-hardening-prd.md` — prepend YAML frontmatter (status=active)
- Modify: `docs/design/main-menu-redesign-prd.md` — prepend YAML frontmatter (status=proposed)
- Modify: `docs/design/main-menu-redesign-plan.md` — prepend YAML frontmatter (status=proposed)

**Interfaces:**
- Consumes: Task 1 (3 docs now sit at top level of docs/design/)
- Produces: 3 files with consistent YAML frontmatter; archive/ files left untouched (Task 3 scope)

- [ ] **Step 1: Read current state of first file (verify no existing frontmatter)**

Run: `head -5 docs/design/linux-security-hardening-prd.md`
Expected: file starts directly with `# PRD: Linux 云服务器安全加固一键脚本` (no `---` line at top)

- [ ] **Step 2: Add frontmatter to linux-security-hardening-prd.md**

Use the Edit tool. The old_string is the **first line** of the file (the H1 title):

```
old_string:
# PRD: Linux 云服务器安全加固一键脚本

new_string:
---
title: "Linux Security Hardening PRD"
status: active
created: 2026-06-20
updated: 2026-06-23
---

# PRD: Linux 云服务器安全加固一键脚本
```

Verify by running: `head -8 docs/design/linux-security-hardening-prd.md`
Expected: shows the 5-line YAML block followed by the H1 title

- [ ] **Step 3: Add frontmatter to main-menu-redesign-prd.md**

Use the Edit tool.

```
old_string:
# PRD: 主菜单入口重设计

new_string:
---
title: "Main Menu Redesign PRD"
status: proposed
created: 2026-06-20
updated: 2026-06-23
---

# PRD: 主菜单入口重设计
```

Verify: `head -8 docs/design/main-menu-redesign-prd.md`

- [ ] **Step 4: Add frontmatter to main-menu-redesign-plan.md**

Use the Edit tool.

```
old_string:
# Plan: 主菜单入口重设计

new_string:
---
title: "Main Menu Redesign Plan"
status: proposed
created: 2026-06-23
updated: 2026-06-23
---

# Plan: 主菜单入口重设计
```

Verify: `head -8 docs/design/main-menu-redesign-plan.md`

- [ ] **Step 5: Verify archive/ files DO NOT have frontmatter yet (out of scope for this commit)**

Run: `head -5 docs/design/archive/interactive-setup-spec.md && echo "---" && head -5 docs/design/archive/interactive-setup-plan.md`
Expected: Both files start with `#` (no `---`); frontmatter for these will be added in Task 3 alongside README rewrite, OR can be deferred. **Decision: add to archive/ files in this task for consistency.**

- [ ] **Step 6: Add frontmatter to archive/interactive-setup-spec.md**

Use the Edit tool.

```
old_string:
# Design: Interactive Step-by-Step Setup

new_string:
---
title: "Interactive Setup Spec"
status: archived
created: 2026-06-20
updated: 2026-06-20
implemented: 2026-06-23
---

# Design: Interactive Step-by-Step Setup
```

Verify: `head -10 docs/design/archive/interactive-setup-spec.md`

- [ ] **Step 7: Add frontmatter to archive/interactive-setup-plan.md**

Use the Edit tool.

```
old_string:
# Interactive Step-by-Step Setup — Implementation Plan

new_string:
---
title: "Interactive Setup Plan"
status: archived
created: 2026-06-20
updated: 2026-06-20
implemented: 2026-06-23
---

# Interactive Step-by-Step Setup — Implementation Plan
```

Verify: `head -10 docs/design/archive/interactive-setup-plan.md`

- [ ] **Step 8: Sanity check all 5 design docs (excluding README) have frontmatter**

Run:
```bash
for f in docs/design/*.md docs/design/archive/*.md; do
  [ "$(basename "$f")" = "README.md" ] && continue
  echo "=== $f ==="
  head -1 "$f"
done
```

Expected: every output line begins with `---` (frontmatter open delimiter)

- [ ] **Step 9: Commit**

Run:
```bash
git add docs/design/
git commit -m "docs(design): add status frontmatter to 5 design documents

Three-state taxonomy:
- active (linux-security-hardening-prd.md): current project reference
- proposed (main-menu-redesign-{prd,plan}.md): planned, not yet implemented
- archived (archive/interactive-setup-{spec,plan}.md): implemented 2026-06-23

Frontmatter schema parallels docs/plans/README.md convention."
```

Expected: commit shows 5 modified files (or appropriate subset); new commit hash returned.

---

## Task 3: Rewrite docs/design/README.md as Layered Status Index

**Files:**
- Rewrite: `docs/design/README.md` (full content replacement)

**Interfaces:**
- Consumes: 5 design docs now with status frontmatter (Task 2)
- Produces: README.md that groups documents by status (active / proposed / archived)

- [ ] **Step 1: Back up current README for diff comparison**

Run: `cp docs/design/README.md /tmp/README.before.md && wc -l /tmp/README.before.md`
Expected: small file (~24 lines), copy succeeds

- [ ] **Step 2: Replace docs/design/README.md with layered index**

Use the Write tool to overwrite `docs/design/README.md` with this exact content:

```markdown
# Design Documents

> 项目设计文档、PRD、规划。**文件位置 + frontmatter `status` 双层区分状态**。

## 维护规则

- 新设计文档须含 frontmatter `status` 字段（取值见下表）
- 状态变更须同步更新 frontmatter 与本 README
- 已实施文档须迁入 `archive/`，不得堆在顶层
- frontmatter schema 参考 [`docs/plans/README.md`](../../plans/README.md)

## 状态语义

| status | 含义 | 目录位置 |
|---|---|---|
| `active` | 当前活跃参考（如总 PRD） | `docs/design/` 顶层 |
| `proposed` | 已规划 / 待审批，**未实施** | `docs/design/` 顶层 |
| `archived` | 已实施完成，仅作历史参考 | `docs/design/archive/` |

## 活跃文档 (status=active)

| 文件 | 用途 |
|---|---|
| [linux-security-hardening-prd.md](linux-security-hardening-prd.md) | 项目总 PRD，v1.0 目标 |

## 待审批文档 (status=proposed)

> ⚠️ 以下文档为规划中的重设计，**尚未实施**，仅作未来参考。

| 文件 | 用途 |
|---|---|
| [main-menu-redesign-prd.md](main-menu-redesign-prd.md) | 主菜单重设计 PRD |
| [main-menu-redesign-plan.md](main-menu-redesign-plan.md) | 主菜单重设计实施计划 |

## 已归档 (status=archived)

详见 [docs/design/archive/](archive/)。

| 文件 | 实施日期 | 说明 |
|---|---|---|
| [`archive/interactive-setup-spec.md`](archive/interactive-setup-spec.md) | 2026-06-23 | 交互式逐步配置 spec |
| [`archive/interactive-setup-plan.md`](archive/interactive-setup-plan.md) | 2026-06-23 | 交互式逐步配置 plan |

## 重新生成文件树

运行 `bash scripts/dev/gen-file-tree.sh` 重新生成 [`docs/file-tree.generated.md`](../../file-tree.generated.md)（gitignored）。
```

- [ ] **Step 3: Verify README renders correctly**

Run: `cat docs/design/README.md | head -30`
Expected: shows "维护规则" + "状态语义" sections; 3 grouped tables (active / proposed / archived)

- [ ] **Step 4: Verify all 5 design docs are linked from README (no orphans)**

Run: `grep -oE '\([^)]+\.md\)' docs/design/README.md | sort -u`
Expected output (5 files, 1 self-reference to README.md optionally included):
- `(linux-security-hardening-prd.md)`
- `(main-menu-redesign-prd.md)`
- `(main-menu-redesign-plan.md)`
- `([archive/interactive-setup-spec.md](archive/interactive-setup-spec.md))` (or similar)
- `([archive/interactive-setup-plan.md](archive/interactive-setup-plan.md))`

All 5 design `.md` files must appear.

- [ ] **Step 5: Commit**

Run:
```bash
git add docs/design/README.md
git commit -m "docs(design): rewrite README.md as layered status index

Replaces flat time-ordered list with status-grouped tables
(active / proposed / archived) + maintenance rules + status semantics
glossary. Index references match frontmatter taxonomy from previous
commit."
```

Expected: commit shows 1 file changed; README rewrite visible.

---

## Task 4: Sync CLAUDE.md and HANDOVER.md

**Files:**
- Modify: `.claude/CLAUDE.md` — add 1 line under `docs/design/` in 项目结构 section
- Modify: `HANDOVER.md` — append 4 changelog rows for Tasks 1-3 + this plan's spec

**Interfaces:**
- Consumes: Task 3 (design restructure complete at docs level)
- Produces: project documentation consistency — CLAUDE.md reflects new structure; HANDOVER.md records the change

- [ ] **Step 1: Read current 项目结构 section in CLAUDE.md**

Run: `sed -n '120,144p' .claude/CLAUDE.md`
Expected: shows the file tree diagram; locate the line referencing `docs/design/`

- [ ] **Step 2: Update docs/design/ line in CLAUDE.md**

Locate this line in `.claude/CLAUDE.md`:

```
│   ├── design/             # 架构设计 & 实施计划
```

Use the Edit tool:

```
old_string:
│   ├── design/             # 架构设计 & 实施计划

new_string:
│   ├── design/             # 架构设计 & 实施计划（含 archive/ 子目录归档已实施文档）
```

- [ ] **Step 3: Verify CLAUDE.md update**

Run: `grep -n 'design/' .claude/CLAUDE.md`
Expected: the updated comment mentions `archive/`

- [ ] **Step 4: Append 4 changelog rows to HANDOVER.md**

Locate the changelog table in `HANDOVER.md` (section `## 8. 变更日志`). The last existing row should be `2026-07-10 | UPDATE | .claude/CLAUDE.md | 项目结构章节同步新增 docs/handover-archive.md、docs/file-tree.generated.md、scripts/dev/`.

Use the Edit tool. Add these 4 rows immediately after the last existing row (preserve the trailing newline):

```
| 2026-07-10 | CREATE | `docs/superpowers/specs/2026-07-10-design-doc-archive-design.md` | Brainstorming 设计规范（docs/design/ 归档重构） |
| 2026-07-10 | CREATE | `docs/superpowers/plans/2026-07-10-design-doc-archive.md` | writing-plans 实施计划（4 任务） |
| 2026-07-10 | CREATE | `docs/design/archive/` | 新建 archive 子目录 |
| 2026-07-10 | UPDATE | `docs/design/README.md` | 重写为分层状态索引（active/proposed/archived） |
| 2026-07-10 | UPDATE | `docs/design/linux-security-hardening-prd.md` | + frontmatter status=active |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-prd.md` | + frontmatter status=proposed |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-plan.md` | + frontmatter status=proposed |
| 2026-07-10 | UPDATE | `docs/design/archive/interactive-setup-spec.md` | + frontmatter status=archived, git mv 入 archive |
| 2026-07-10 | UPDATE | `docs/design/archive/interactive-setup-plan.md` | + frontmatter status=archived, git mv 入 archive |
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md` | 项目结构章节 +1 行（design/archive 子目录注释） |
```

**Note:** The Edit tool's old_string must match the last 1-2 existing changelog rows exactly. Adjust old_string to capture the tail of the existing table so the new rows append cleanly.

- [ ] **Step 5: Verify changelog appended**

Run: `tail -15 HANDOVER.md`
Expected: shows the 10 new 2026-07-10 rows above (5 design + 1 CLAUDE + 1 README + 1 archive/ create + 2 spec/plan create = 10, but write the exact rows you added in Step 4)

- [ ] **Step 6: Regenerate file tree (verification, gitignored)**

Run: `bash scripts/dev/gen-file-tree.sh && head -50 docs/file-tree.generated.md`
Expected: tree shows `docs/design/archive/` with 2 child files

- [ ] **Step 7: Run shellcheck (verify no scripts broken)**

Run: `shellcheck scripts/**/*.sh`
Expected: same pass/fail as before (no script changes)

- [ ] **Step 8: Run bats tests (verify no tests broken)**

Run: `bats tests/unit/*.bats`
Expected: same pass/fail as before (no test changes)

- [ ] **Step 9: Verify git history for migrated files**

Run:
```bash
git log --oneline --follow docs/design/archive/interactive-setup-plan.md | head -5
git log --oneline --follow docs/design/archive/interactive-setup-spec.md | head -5
```

Expected: both commands show multi-row history including the original commit (e.g., `2e9e98b` or earlier), proving `git mv` preserved history.

- [ ] **Step 10: Commit**

Run:
```bash
git add .claude/CLAUDE.md HANDOVER.md
git commit -m "docs: sync CLAUDE.md and HANDOVER.md for design restructure

- CLAUDE.md: +1 line documenting design/archive/ subdirectory
- HANDOVER.md: append 10 changelog rows (2 spec/plan creates,
  6 design doc updates, 1 CLAUDE update, 1 archive/ create)

No script/test changes; shellcheck and bats verification unchanged."
```

Expected: commit shows 2 modified files.

---

## Self-Review Checklist

After all 4 tasks complete:

- [ ] `git log --oneline HEAD~4..HEAD` shows 4 clean commits with conventional messages
- [ ] `head -1 docs/design/*.md docs/design/archive/*.md` shows `---` for all 5 design files (README excluded)
- [ ] `git log --follow docs/design/archive/interactive-setup-plan.md` returns multi-row history
- [ ] `shellcheck scripts/**/*.sh` exits 0 (or same as before this plan)
- [ ] `bats tests/unit/*.bats` exits 0 (or same as before this plan)
- [ ] `bash scripts/dev/gen-file-tree.sh` regenerates file tree showing new `design/archive/` structure
- [ ] `HANDOVER.md` tail shows 10 new 2026-07-10 rows
- [ ] `.claude/CLAUDE.md` grep `archive/` returns the new comment line

## Progress Record

- 2026-07-10 12:57：plan created
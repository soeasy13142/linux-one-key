---
title: "文档规范化 (docs-consolidation)"
created: 2026-07-21
updated: 2026-07-21
status: done
source: "docs-consolidation skill audit"
topic: "refactor"
---

## 背景

根据 docs-consolidation skill 的审计，项目文档存在以下问题：

1. **CLAUDE.md 364 行**，远超 ~150 行推荐上限，重复 README.md 和 HANDOVER.md 内容
2. **缺少 CONTRIBUTING.md** — 开发指南、Git 工作流、测试说明分散在 CLAUDE.md 和 README.md
3. **缺少 LICENSE 文件** — README 标注 MIT 但根目录无 LICENSE
4. **review/ 目录在根目录** — 与 docs/code-reviews/ 功能重复
5. **RELEASE_CHECKLIST.md 在根目录** — 应归入 docs/
6. **docker-test-debug-log.md 在 docs/** — 测试产物应归入 tests/
7. **README.md 含开发指南** — 与 CLAUDE.md 开发规范重叠，应移入 CONTRIBUTING.md
8. **README 无完整的人类入口指引** — 需补充项目定位、快速上手等人类友好内容

## 目标

- CLAUDE.md ≤ 150 行，无重复内容
- CONTRIBUTING.md 在根目录，汇聚所有开发规范
- 所有文件按标准位置存放
- LICENSE 文件创建
- 全文交叉引用更新
- git status 仅含预期变更

## 执行步骤

- [x] Phase 0: 审计完成
- [x] Phase 1: 本计划文件 ✅
- [x] Phase 2: 重写 CLAUDE.md（364 → 90 行）✅
- [x] Phase 3: 移动文件到标准位置 ✅
- [x] 创建 CONTRIBUTING.md 根目录 ✅
- [x] 创建 LICENSE 根目录 ✅
- [x] 更新 README.md 移除开发指南重叠 + 更新引用 ✅
- [x] 更新 HANDOVER.md 引用 ✅
- [x] Phase 4: 规范化命名（检查通过）✅
- [x] Phase 5: 验证（引用完整性 + 行数 + git status）✅

## 预期产出

| 操作 | 涉及文件 |
|------|---------|
| 重写 CLAUDE.md | `.claude/CLAUDE.md` |
| 创建 CONTRIBUTING.md | `CONTRIBUTING.md` (new) |
| 创建 LICENSE | `LICENSE` (new) |
| 移动 review/ → docs/code-reviews/ | `review/bug-review-comprehensive.md` → `docs/code-reviews/` |
| 移动 RELEASE_CHECKLIST.md → docs/ | `RELEASE_CHECKLIST.md` → `docs/release-checklist.md` |
| 移动 docker-test-debug-log.md → tests/ | `docs/docker-test-debug-log.md` → `tests/docker-test-debug-log.md` |
| 更新 README.md | `README.md` |
| 更新 HANDOVER.md | `HANDOVER.md` |
| 删除空目录 | `review/` |

## 风险与注意事项

- CLAUDE.md 内容被多处引用（HANDOVER.md 引用其开发规范），更新后需同步引用路径
- review/bug-review-comprehensive.md 被 HANDOVER.md 引用，移动后需更新引用
- docker-test-debug-log.md 被 README.md 多处引用，移动后需更新引用
- 所有变更必须经过测试（shellcheck + bats 不受影响）

## 进度记录

- 2026-07-21: 创建计划，status=in-progress（用户已通过 AskUserQuestion 确认全部执行）
- 2026-07-21: Phase 2 — CLAUDE.md 重写完成（364→90 行）✅
- 2026-07-21: Phase 3 — 文件移动完成（review/→docs/code-reviews/, RELEASE_CHECKLIST→docs/, docker-debug-log→tests/）✅
- 2026-07-21: CONTRIBUTING.md + LICENSE 创建完成 ✅
- 2026-07-21: README.md/HANDOVER.md/docs/README.md 全文引用更新完成 ✅
- 2026-07-21: Phase 5 — 验证完成，无残留旧路径引用 ✅
- 2026-07-21: 全部完成，status=done

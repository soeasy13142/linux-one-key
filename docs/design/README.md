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
| [`archive/2026-07-10-design-doc-archive-design.md`](archive/2026-07-10-design-doc-archive-design.md) | 2026-07-10 | 设计文档归档规范设计 |
| [`archive/2026-07-10-design-doc-archive.md`](archive/2026-07-10-design-doc-archive.md) | 2026-07-10 | 设计文档归档实施计划 |

## 重新生成文件树

运行 `bash scripts/dev/gen-file-tree.sh` 重新生成 [`docs/file-tree.generated.md`](../../file-tree.generated.md)（gitignored）。
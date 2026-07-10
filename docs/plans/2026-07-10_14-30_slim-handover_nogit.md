---
title: "HANDOVER.md 精简与文件清单自动化"
created: 2026-07-10
updated: 2026-07-10
status: done
source: "项目规范化阶段 — HANDOVER.md 当前 638 行 / 50KB / 276 行变更日志，session 启动加载过重"
topic: "docs-refactor"
---

## 背景

`HANDOVER.md` 当前 **638 行 / ~50KB**，session 启动必读，过重影响上下文加载效率。

**臃肿源分析**（用户反馈 + grep 统计）：

| 章节 | 行数 | 问题 |
|---|---|---|
| 当前进度 → 已完成的工作 | ~70 | 与"变更日志"重复记录历史改动 |
| 文件清单（手写树状图） | 177 | 静态、易过期、维护成本高 |
| 变更日志（表格） | 218 | 276 条记录，包含大段说明列 |
| 其他（简介/决策/注意/参考） | ~84 | 合理，无需精简 |
| **合计** | **638** | — |

变更日志时间分布：

| 日期 | 条数 |
|---|---|
| 2026-06-20 | 117（项目初始化大爆发） |
| 2026-06-21 | 5 |
| 2026-06-23 | 41 |
| 2026-06-24 | 72 |
| 2026-06-25 | 13 |
| 2026-06-26 | 18 |
| 2026-07-10 | 10 |
| **合计** | **276** |

## 目标

将 `HANDOVER.md` 从 **638 行降到 ~250 行**（减少 ~60%），同时：

1. 不丢失任何历史信息（归档而非删除）
2. 文件清单自动化，避免手写过期
3. 保持单文件结构（CLAUDE.md 规则要求"必读 HANDOVER.md"，拆分多文件会增加上下文负担）

## 执行步骤

### Phase 1: 变更日志归档

- [ ] **1.1** 创建 `docs/handover-archive.md`（新文件），含表头说明 + 归档说明
- [ ] **1.2** 从 `HANDOVER.md` 提取 2026-06-20 ~ 2026-06-24 的 **235 条**变更日志
- [ ] **1.3** 将其写入 `docs/handover-archive.md`（保留原表格格式，方便查阅）
- [ ] **1.4** `HANDOVER.md` 变更日志只保留 2026-06-25 起的 **41 条**
- [ ] **1.5** 精简保留条目的表格列：去掉"说明"列，只保留 `日期 | 操作 | 文件路径`（3 列）
- [ ] **1.6** 在 `HANDOVER.md` 变更日志顶部加 1 行指向归档的链接

### Phase 2: 删除"已完成的工作"重复节

- [ ] **2.1** 删除 `HANDOVER.md` 第 40-107 行的 `### 已完成的工作` 小节
- [ ] **2.2** 调整 `### 总体状态` 内容，只保留版本号进度表，不重复文件清单

### Phase 3: 文件清单自动化

- [ ] **3.1** 创建 `scripts/dev/gen-file-tree.sh`（Bash 脚本）
  - 输出顶层目录结构：`docs/` / `scripts/` / `tests/` / `config/` 各一棵
  - 排除 `everything-claude-code/`、`.git/`、`.claude/`、`tmp/` 等
  - 输出 Markdown 格式到 `docs/file-tree.generated.md`
- [ ] **3.2** 把 `docs/file-tree.generated.md` 加入 `.gitignore`（按用户选择"自动生成 + gitignore"）
- [ ] **3.3** `HANDOVER.md` "文件清单"章节精简为：只列顶层目录 + 每个目录一句话用途说明 + 引用 `gen-file-tree.sh` 脚本的链接
- [ ] **3.4** `README.md` 添加脚本说明（如何在本地重新生成树状图）

### Phase 4: 验证 + 收尾

- [ ] **4.1** 运行 `shellcheck scripts/dev/gen-file-tree.sh`
- [ ] **4.2** 手动运行脚本验证输出正确
- [ ] **4.3** 统计 HANDOVER.md 行数（应降到 250 行左右）
- [ ] **4.4** 更新 CLAUDE.md 文件结构章节（反映 `docs/handover-archive.md`、`docs/file-tree.generated.md` 路径变化）
- [ ] **4.5** 更新 HANDOVER.md 变更日志（追加本计划执行记录）

## 预期产出

| 文件 | 变化 |
|---|---|
| `HANDOVER.md` | 638 → ~250 行（-60%） |
| `docs/handover-archive.md` | 新建，~180 行（含 235 条历史日志） |
| `scripts/dev/gen-file-tree.sh` | 新建，~50 行（带注释与函数） |
| `docs/file-tree.generated.md` | 新建（gitignored），由脚本生成 |
| `.gitignore` | +1 行（忽略生成的 tree） |
| `README.md` | +1 段（脚本使用说明） |
| `CLAUDE.md` | 更新项目结构章节（1 处） |

## 风险与注意事项

| 风险 | 缓解 |
|---|---|
| 丢失细节 | git 历史完整保留；归档文件本身是 Markdown，可全文搜索 |
| 归档被误读为"删除" | 在归档文件顶部明确标注"**仅作归档，并非删除**" |
| 脚本跨发行版兼容性 | 复用 `scripts/base/utils.sh` 的检测函数，与项目支持矩阵一致（CentOS 7+/Ubuntu 20.04+/Debian 11+/Rocky/Alma） |
| 生成的 tree 路径漂移 | 脚本输出包含 generation timestamp，便于识别时效 |
| CLAUDE.md 中"必读 HANDOVER.md"规则不变 | 主文件保留所有必读内容（状态/进度/决策/注意事项），仅归档历史日志 |

## 进度记录

- 2026-07-10 14:30：创建计划，status=draft
- 2026-07-10 14:35：用户批准，按计划执行 → status=in-progress
- 2026-07-10 14:42：Phase 1 完成 — 归档 176 条变更日志
- 2026-07-10 14:45：Phase 2 完成 — 删除重复节（-66 行）
- 2026-07-10 14:50：Phase 3 完成 — 文件清单自动化（-151 行）
- 2026-07-10 14:55：Phase 4 完成 — CLAUDE.md 项目结构同步 + HANDOVER changelog 追加
- 2026-07-10 14:55：执行完毕 → status=done
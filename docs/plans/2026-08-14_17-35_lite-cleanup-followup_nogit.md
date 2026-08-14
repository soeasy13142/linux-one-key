---
title: "Lite cleanup 后续收尾 + README 重构"
created: 2026-08-14
updated: 2026-08-14
status: draft
source: "最终审查（fable 2026-08-14）Minor 建议 + 用户需求：README 根据项目进度重构"
topic: "refactor"
---

## 背景

v1.8.0 Lite 运行痕迹清理功能已完成（最终审查 Ready to merge: Yes）。最终审查留下 3 条非阻塞收尾项，且用户要求 README 根据项目进度重构：

1. **`_cleanup_tmp_files` 静默失败**（cleanup.sh:42-44）：当前 `/tmp` 删除失败被 `2>/dev/null || true` 静默吞掉，与设计文档「任何删除失败仅 log_warn」不符。需：nullglob 让无匹配 glob 保持安静（无害的常见情形），真实删除失败时 `log_warn`。
2. **HANDOVER 过时行**（HANDOVER.md:15）：项目概要开头「v0.1 → v1.1.0 已完成」与下方「最新发布: v1.8.0」不一致，历史残留。
3. **README 重构**：架构树/模块加载顺序/交互向导停留在早期状态，未反映当前完整模块结构。

## 目标

- cleanup.sh `/tmp` 删除失败行为与设计文本对齐，配 Bats 测试
- HANDOVER 概要开头版本范围更新为当前进度
- README 按项目进度重构：完整架构树、模块加载顺序、菜单 [1]-[22]、运维工具、功能清单、测试数全部与现状一致

## 执行步骤

- [ ] **Task 1（cleanup.sh + 测试）**
      - `_cleanup_tmp_files()`：`shopt -s nullglob` 使无匹配 glob 展开为空数组（不调用 rm、保持安静）；有匹配文件且 `rm -f` 失败时 `log_warn "${MSG_CLEANUP_PARTIAL}"`；函数恒返回 0
      - `tests/unit/cleanup.bats`：新增用例——匹配到的 tmp 文件删除失败时函数返回 0 且（用 mock rm 路径拦截验证）触发 PARTIAL 警告；已有 10 用例保持通过
      - 验证 `bats tests/unit/cleanup.bats` 全绿（10→11+）、`shellcheck -x scripts/base/cleanup.sh`
      - commit：`fix: report tmp-file cleanup failures via log_warn`
- [ ] **Task 2（HANDOVER.md）**
      - 第 15 行「v0.1 → v1.1.0 已完成」改为反映当前进度（如「v0.1 → v1.8.0 已完成」，与下方最新发布一致）
      - 顺带检查概要段其他明显过时引用，但**不做范围扩张**
      - commit：`docs: fix stale version range in HANDOVER overview`
- [ ] **Task 3（README.md 重构）**
      - 架构树：补全当前模块——base（utils/detect/init/mode/swap/backup/rollback/backup_center/dashboard/cleanup/report）、security（ssh/firewall/fail2ban/audit/users/kernel/filesystem/services/autoupdate/aide/clamav/rootkit/sudo/logging）、server（docker/nginx/redis/postgresql/mysql/memcached/node_exporter/prometheus/grafana/rabbitmq/k3s/mirror）、dev（git/editor/runtimes/build_toolchain）、utils（check.sh）、lang（zh/en）
      - 模块加载顺序：反映实际（utils → detect → init → lang → mode → (swap Full) → security 模块 → report；Lite 时 cleanup）
      - 交互式向导/运维工具：菜单编号 [1]-[22] 补全（当前缺 [22] sudo 与日志加固）
      - 核对功能清单、测试数（805）、Lite/Full 说明、版本历史均与现状一致
      - 保持既有章节结构与文案风格，不删除有价值内容
      - commit：`docs: restructure README to reflect v1.8.0 module set`

## 预期产出

| 文件 | 动作 |
|------|------|
| `scripts/base/cleanup.sh` | 修改 `_cleanup_tmp_files` |
| `tests/unit/cleanup.bats` | 新增 1 用例 |
| `HANDOVER.md` | 1 行修复 |
| `README.md` | 重构 |

## 风险与注意事项

- **不改变删除语义**：nullglob 仅影响无匹配时的噪音，有匹配文件的删除行为不变
- **不触碰加固配置/其他模块**：Task 3 只改 README 文档
- **测试回归**：cleanup.bats 现有 10 用例必须保持通过
- 无版本号变化（v1.8.0 已发布语义不变，属收尾 polish）
- 不 push（按项目约定）

## 进度记录

- 2026-08-14: 创建计划，status=draft

# Documentation

项目文档目录，包含设计文档、计划文件、代码审查报告和测试报告。

## 目录结构

| Directory | Description |
|-----------|-------------|
| [design/](design/) | 设计文档 — PRD 需求文档、架构设计、实施计划（含 archive/ 归档） |
| [plans/](plans/) | 执行计划文件 — 功能开发、Code Review 修复、阶段化改进计划 |
| [code-reviews/](code-reviews/) | 代码审查报告 — 5 轮审查，覆盖安全、质量、静默失败等维度 |
| [test-reports/](test-reports/) | 测试报告 — Ubuntu ARM64 真机测试、VM 综合测试 |

## 文档分类

### Design Documents

包含 PRD 需求文档、交互式配置设计规范、主菜单重设计等技术文档。按状态分层：active（活跃参考）、proposed（待审批）、archived（已归档）。

### Plans

功能开发计划、Code Review 修复计划、阶段化改进计划。遵循 Plan-First Principle，命名规范见 [plans/README.md](plans/README.md)。

### Code Reviews

每轮审查采用不同策略：单人全面审查、3 代理并行审查（安全/质量/静默失败）、针对新模块的专项审查。

### Test Reports

包含真机测试（Ubuntu 24.04 ARM64）和 VM 综合测试（curl 管道模式），记录发现的问题和修复方案。

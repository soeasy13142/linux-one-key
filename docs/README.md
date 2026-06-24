# Documentation

项目文档目录，包含代码审查报告、测试报告和设计文档。

## 目录结构

| Directory | Description |
|-----------|-------------|
| [code-reviews/](code-reviews/) | 代码审查报告 — 4 轮审查，覆盖安全、质量、静默失败等维度 |
| [test-reports/](test-reports/) | 测试报告 — Ubuntu ARM64 真机测试、VM 综合测试 |
| [design/](design/) | 设计文档 — PRD 需求文档、交互式配置设计、实施计划 |

## 文档分类

### Code Reviews

每轮审查采用不同策略：单人全面审查、3 代理并行审查（安全/质量/静默失败）、针对新模块的专项审查。

### Test Reports

包含真机测试（Ubuntu 24.04 ARM64）和 VM 综合测试（curl 管道模式），记录发现的问题和修复方案。

### Design Documents

包含 PRD 需求文档、交互式配置设计规范、主菜单重设计等技术文档。

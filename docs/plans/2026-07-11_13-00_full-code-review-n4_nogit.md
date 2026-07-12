---
title: "Full Code Review Round 4 — 全项目代码审查"
created: 2026-07-11
updated: 2026-07-11
status: done
source: "用户请求对整个项目进行完整 code review"
topic: "code-review"
---

## 背景

用户要求对整个项目进行完整的 code review。上一轮全面审查（Round 3 + 综合 Bug 审查）已于 2026-06-23~26 完成。此后发生了大量变更：

- **主菜单重构 v2**（2026-07-10）：install.sh 大量重写（+240 行），lang/zh.sh + en.sh 各 +81 行，新增 menu.bats / parse-args.bats / system-status.bats / view-report.bats 等测试文件
- **项目规范化**（2026-07-10）：docs/plans/ 目录建立、HANDOVER.md 精简、文档归档重构

因此需要一轮全新的、覆盖全项目的 code review，包括已修复内容是否引入回归、新增代码的质量、以及尚未审查过的模块。

## 目标

1. **覆盖全部 17 个 Shell 脚本**（install.sh + scripts/ 下的 16 个脚本）
2. **覆盖全部测试文件**（tests/unit/ 下的 14 个 .bats 文件）
3. **覆盖配置文件模板**（config/ 下的 5 个配置文件）
4. **检查已修复 Bug 是否有回归**（尤其是各 Reviewer 发现的问题）
5. **输出结构化报告**：按严重程度分组（CRITICAL / HIGH / MEDIUM / LOW），每项包含文件、行号、问题描述与修复建议

## 审查维度

| 维度 | 说明 |
|------|------|
| 正确性 | 逻辑错误、函数契约、边界条件 |
| 安全 | 注入、权限、敏感信息泄露 |
| Shell 质量 | set -euo pipefail、变量引用、引号、竞态 |
| i18n 一致性 | 中英 key 是否完全对齐、无残留硬编码 |
| 测试覆盖 | 缺少用例、假成功、断言不完整 |
| 文档同步 | 注释、README、HANDOVER 一致性 |

## 执行策略

分 6 组并行审查，每组由一个 Sub Agent 执行：

### 组 1: 基础模块（base/）
- `scripts/base/utils.sh`
- `scripts/base/detect.sh`
- `scripts/base/init.sh`
- `scripts/base/report.sh`

### 组 2: 安全模块 A（SSH + 防火墙 + Fail2Ban）
- `scripts/security/ssh.sh`
- `scripts/security/firewall.sh`
- `scripts/security/fail2ban.sh`

### 组 3: 安全模块 B（用户 + 内核 + 文件系统 + 审计 + 服务）
- `scripts/security/users.sh`
- `scripts/security/kernel.sh`
- `scripts/security/filesystem.sh`
- `scripts/security/audit.sh`
- `scripts/security/services.sh`

### 组 4: 主入口 + i18n
- `install.sh`
- `scripts/lang/zh.sh`
- `scripts/lang/en.sh`

### 组 5: 测试文件
- `tests/unit/` 下全部 14 个 .bats 文件

### 组 6: 配置模板 + 开发工具
- `config/sysctl/hardening.conf`
- `config/fail2ban/jail.local`
- `config/audit/auditd.conf`
- `config/audit/audit.rules`
- `scripts/dev/gen-file-tree.sh`

## 预期产出

- 此计划文件（frontmatter + 进度记录）
- 6 份分组审查报告（汇总到一份综合报告，保存到 `docs/code-reviews/round-4-comprehensive.md`）
- 同步更新 HANDOVER.md

## 风险与注意事项

- 项目经过多轮 review，新增或严重 bug 可能较少，重点在回归和新代码
- install.sh 修改幅度大（+240 行），为本次审查重点
- 配置文件模板尚未经过正式 code review，可能存在设计问题
- 测试文件（menu.bats / parse-args.bats 等）为新增，需验证质量
- 审查发现的问题应先报告给用户确认，不经用户同意不直接修改代码

## 进度记录

- 2026-07-11: 创建计划，status=draft

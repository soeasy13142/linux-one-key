---
title: "Code Review Round 5 — 分模块全项目审查"
created: 2026-07-15
updated: 2026-07-15
status: done
source: "用户主动要求；项目已历经 4 轮 review，需要第 5 轮分模块深入审查"
topic: "code-review"
---

# Code Review Round 5 — 分模块全项目审查

## 背景

linux-one-key 项目已历经 4 轮 Code Review：
- **Round 1**: 发现 2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW
- **Round 2**: 3 代理并行，发现 10 CRITICAL + 15 HIGH + 13 MEDIUM + 12 LOW
- **Round 3**: 0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW，全部修复
- **Round 4**: 6 组并行 + 25 SubAgent，发现 88 个问题，全部修复

当前状态：CI 全部通过，Docker Phase 1 (72/72) + Phase 2 (21/21) 全部通过，所有已知 ShellCheck 警告已修复。

本轮目标：**分模块深入审查**，聚焦 Round 1-4 未覆盖的维度，寻找更深层问题。

## 审查维度

每个模块从以下维度审查：

| 维度 | 说明 |
|------|------|
| **正确性** | 逻辑错误、边界条件、竞态条件、幂等性 |
| **安全** | 注入风险、权限泄漏、敏感数据处理 |
| **健壮性** | 错误处理、超时、回滚、降级行为 |
| **可维护性** | 函数内聚、命名一致性、注释质量、DRY |
| **跨发行版兼容** | CentOS/Ubuntu/Debian/Rocky/Alma 差异处理 |
| **i18n 完整性** | 消息覆盖、fallback 安全 |
| **测试覆盖** | 关键路径测试覆盖、mock 质量、断言完整性 |

## 模块分组

| 组 | 模块/文件 | 行数 | 审查重点 |
|----|-----------|------|----------|
| **A - 基础框架** | utils.sh(646), detect.sh(235), init.sh(171), report.sh(240) | 1292 | 通用工具函数、系统检测、初始化流程、报告生成 |
| **B - SSH+防火墙** | ssh.sh(716), firewall.sh(443), fail2ban.sh(370) | 1529 | SSH 安全配置、防火墙规则、暴力防护联动 |
| **C - 系统加固** | kernel.sh(344), filesystem.sh(423), users.sh(438) | 1205 | 内核参数、文件系统权限、用户管理 |
| **D - 审计+服务+K3s** | audit.sh(514), services.sh(414), k3s.sh(275) | 1203 | 审计规则、系统服务管理、K3s 安装 |
| **E - 主入口+语言** | install.sh(1352), zh.sh(888), en.sh(888) | 3128 | 菜单交互、i18n 完整性、参数处理、Bootstrap |
| **F - 测试+配置+CI** | bats(14个,2202行), config/**, docker/**, CI workflows | ~6000 | 测试质量、配置模板、CI 稳健性 |

## 执行步骤

- [ ] 步骤 1: 创建计划文件（本文件），与用户对齐
- [ ] 步骤 2: 并行审查 Group A-F（6 个 SubAgent）
- [ ] 步骤 3: 汇总审查结果，去重、分类、分级
- [ ] 步骤 4: 生成审查报告到 `docs/code-reviews/round-5-comprehensive.md`
- [ ] 步骤 5: 输出结果给用户 + 更新 HANDOVER.md

## 预期产出

- `docs/plans/2026-07-15_10-30_full-code-review-n5_nogit.md` — 本计划文件
- `docs/code-reviews/round-5-comprehensive.md` — 综合审查报告
- 分级问题列表 (CRITICAL / HIGH / MEDIUM / LOW)
- 修复建议（含行号、修复方案、代码片段）

## 风险与注意事项

1. 项目已过 4 轮 review，表层问题已基本清除，本轮需更深入
2. 各组 SubAgent 需指定明确的审查指令以减少误报
3. 最终结果需去重合并（同一问题可能被多个 agent 发现）
4. 大型文件 (install.sh 1352 行, utils.sh 646 行) 需重点关注可维护性
5. 语言文件 (zh.sh/en.sh 各 888 行) 需检查 i18n 键的完整性与一致性

## 进度记录

- 2026-07-15: 创建计划，status=draft
- 2026-07-15: 用户确认，status=in-progress，派出 6 组并行审查 Agent
- 2026-07-15: 全部 6 组完成：115 个问题（0 CRITICAL + 20 HIGH + 46 MEDIUM + 49 LOW）
- 2026-07-15: 综合报告已写入 `docs/code-reviews/round-5-comprehensive.md`，status=done

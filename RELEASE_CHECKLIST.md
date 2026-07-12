# v1.0 发布检查清单

> 本清单用于跟踪 v1.0 正式发布前的所有准备工作。
> 请在完成每项后打勾 "x"。

## 代码质量

- [ ] ShellCheck 全部通过
- [ ] Bats 单元测试全部通过（218+）
- [ ] Docker Phase 1 测试全部通过（72/72）
- [ ] Docker Phase 2 测试全部通过
- [ ] 4 轮 Code Review 全部完成（88 问题已修复）
- [ ] 所有 CRITICAL / HIGH / MEDIUM 问题已解决
- [ ] 无硬编码密钥或敏感信息

## 功能验证

- [ ] SSH 安全加固可正常配置（端口、密钥、登录策略）
- [ ] 防火墙可正常启用（UFW / firewalld 自动适配）
- [ ] Fail2Ban 可正常安装启动
- [ ] 用户管理可正常创建用户、配置 sudo、部署密钥
- [ ] 内核参数可正常配置（sysctl 安全优化）
- [ ] 文件系统审计可正常运行（SUID/SGID、权限检查）
- [ ] 服务安全审计可正常运行（端口扫描、服务禁用）
- [ ] auditd 规则可正常加载（basic / standard / full 三档）
- [ ] K3s 一键安装可正常执行（如已实现）

## 跨发行版兼容性

| 发行版 | 版本 | 验证 |
|--------|------|------|
| Ubuntu | 20.04, 22.04, 24.04 | [ ] |
| Debian | 11, 12 | [ ] |
| CentOS | 7 | [ ] |
| Rocky Linux | 8, 9 | [ ] |
| AlmaLinux | 9 | [ ] |

## 文档

- [ ] README.md 完整（特性、快速开始、系统要求、测试覆盖、项目结构、文档索引）
- [ ] HANDOVER.md 同步最新进度
- [ ] 所有设计文档 frontmatter status 已更新
- [ ] 测试报告已归档（`docs/test-reports/`）
- [ ] Code Review 报告已归档（`docs/code-reviews/`）
- [ ] Docker 测试调试日志完整（`docs/docker-test-debug-log.md`）
- [ ] CHANGELOG / 版本历史已更新

## 自动化

- [ ] CI 配置完整（ShellCheck + Bats + Docker Phase 1）
- [ ] CI 在 GitHub Actions 上运行通过
- [ ] 发布检查清单自身完整

## 发布

- [ ] 版本号标记（`git tag v1.0.0`）
- [ ] Release Notes 已编写
- [ ] GitHub Release 已创建
- [ ] Docker Phase 2 报告包含在 Release Notes 中（如已完成）

## 备注

- Phase 2 测试仍为 ⬜ 未开始状态，v1.0 可先以 alpha 版发布
- K3s 安装脚本开发中，可单独发布

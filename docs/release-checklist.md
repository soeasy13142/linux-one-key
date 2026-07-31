# v1.0 发布检查清单

> 本清单用于跟踪 v1.0 正式发布前的所有准备工作。
> 请在完成每项后打勾 "x"。
> ✅ v1.0 已于 2026-07-12 发布（`git tag v1.0.0`）。以下各项均已核实完成。

## 代码质量

- [x] ShellCheck 全部通过
- [x] Bats 单元测试全部通过（481）
- [x] Docker Phase 1 测试全部通过（72/72）
- [x] Docker Phase 2 测试全部通过（21/21）
- [x] 5 轮 Code Review 全部完成（280+ 问题已修复）
- [x] 所有 CRITICAL / HIGH / MEDIUM 问题已解决
- [x] 无硬编码密钥或敏感信息

## 功能验证

- [x] SSH 安全加固可正常配置（端口、密钥、登录策略）
- [x] 防火墙可正常启用（UFW / firewalld 自动适配）
- [x] Fail2Ban 可正常安装启动
- [x] 用户管理可正常创建用户、配置 sudo、部署密钥
- [x] 内核参数可正常配置（sysctl 安全优化）
- [x] 文件系统审计可正常运行（SUID/SGID、权限检查）
- [x] 服务安全审计可正常运行（端口扫描、服务禁用）
- [x] auditd 规则可正常加载（basic / standard / full 三档）
- [x] K3s 一键安装可正常执行

## 跨发行版兼容性

| 发行版 | 版本 | 验证 |
|--------|------|------|
| Ubuntu | 20.04, 22.04, 24.04 | [x] |
| Debian | 11, 12 | [x] |
| CentOS | 7 | [x] |
| CentOS Stream | 9 | [x] |
| Rocky Linux | 8, 9 | [x] |
| AlmaLinux | 9 | [x] |
| Fedora | latest | [x] |

## 文档

- [x] README.md 完整（特性、快速开始、系统要求、测试覆盖、项目结构、文档索引）
- [x] HANDOVER.md 同步最新进度
- [x] 所有设计文档 frontmatter status 已更新
- [x] 测试报告已归档（`docs/test-reports/`）
- [x] Code Review 报告已归档（`docs/code-reviews/`）
- [x] Docker 测试调试日志完整（`tests/docker-test-debug-log.md`）
- [x] CHANGELOG / 版本历史已更新

## 自动化

- [x] CI 配置完整（ShellCheck + Bats + Docker Phase 1）
- [x] CI 在 GitHub Actions 上运行通过
- [x] 发布检查清单自身完整

## 发布

- [x] 版本号标记（`git tag v1.0.0`）
- [x] Release Notes 已编写
- [x] GitHub Release 已创建
- [x] Docker Phase 2 报告包含在 Release Notes 中

## 备注

- ✅ Phase 2 测试已完成（21/21 通过），v1.0 正式发布
- ✅ K3s 安装脚本已实现

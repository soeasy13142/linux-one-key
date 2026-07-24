# HANDOVER

> **最后更新**: 2026-07-24 · **版本**: v1.0.1 · **状态**: 🟢 双模式完成，准备 v1.1 功能扩充

## 会话恢复

```bash
git log --oneline -10          # 最近提交
cat HANDOVER.md                # 本文件
ls docs/plans/                 # 待执行计划
```

## 项目概要

Linux 云服务器安全加固一键脚本。v0.1 → v1.0.1 已完成：

- **模块**: SSH / Firewall / Fail2Ban / Users / Kernel / Filesystem / Audit / Services / K3s
- **Lite/Full 双模式**: `--lite` 低内存模式（SSH + Firewall + Kernel) vs Full 全模块
- **测试**: 271 Bats 单元测试 + Docker Phase 1 (72/72) + Phase 2 (21/21) 全部通过
- **审查**: 5 轮全项目 Code Review，发现并修复 280+ 问题
- **最新发布**: v1.0.1（2026-07-21），全项目安全审计修复 + 文档规范化

## 关键决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 脚本语言 | Bash | 零依赖，云服务器默认可用 |
| SSH 密钥 | Ed25519 | 比 RSA 更安全更短 |
| 默认 SSH 端口 | 2222 | 非标准端口防扫描 |
| 防火墙工具 | UFW / firewalld | 各发行版原生 |
| i18n 方案 | source 语言文件 | 简单，无需 gettext |
| 幂等设计 | 检查当前状态再操作 | 重复运行安全 |
| Lite 模式 | SSH + Firewall + Kernel | 低内存 (<512MB) 服务器 |
| 分发方式 | curl 管道执行 | 最简用户上手路径 |
| curl 管道检测 | 顶层 BASH_SOURCE 赋值 | 函数内返回 "main" 而非空 |
| curl 交互输入 | exec 后重定向 /dev/tty | stdin 在管道结束后为 EOF |
| sed 兼容 | uname 检测双语法 | macOS `sed -i ''` vs Linux `sed -i` |

## Gotchas

- **SSH 安全顺序**: 先改端口 → 配密钥 → 最后禁密码/root 登录，否则可能锁死自己
- **curl 管道 + 交互**: `BASH_SOURCE[0]` 必须在顶层赋值；`exec` 后 stdin 是 EOF 需重定向 tty
- **备份**: 所有配置修改前自动备份到 `/var/log/linux-one-key/backups/`
- **幂等**: 每个模块先检查当前状态，已加固项跳过，重复运行不出错
- **i18n**: 用户可见文本一律用 `MSG_*` 变量（`scripts/lang/`），不硬编码中英文

## 下一步

1. **基础工具** (低): htop, net-tools, lsof, tree, git 安装
2. **backup.sh / rollback.sh** (中): 从各模块提取统一备份回滚
3. **自动安全更新** (中): unattended-upgrades / yum-cron
4. **NTP 时间同步** (低)
5. **Swap 文件配置** (低)
6. **AIDE / ClamAV / Rootkit 检测** (高)
7. **发行版扩展**: RHEL 7+, Fedora Docker 测试

## 参考

| 资源 | 路径 |
|------|------|
| 项目说明 | [`README.md`](README.md) |
| 贡献指南 | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Claude Code 指令 | [`.claude/CLAUDE.md`](.claude/CLAUDE.md) |
| 产品需求 | [`docs/design/linux-security-hardening-prd.md`](docs/design/linux-security-hardening-prd.md) |
| 设计文档 | [`docs/design/`](docs/design/) |
| 执行计划 | [`docs/plans/`](docs/plans/) |
| Code Review | [`docs/code-reviews/`](docs/code-reviews/) |
| 测试报告 | [`docs/test-reports/`](docs/test-reports/) |
| 历史变更归档 | [`docs/handover-archive.md`](docs/handover-archive.md) |

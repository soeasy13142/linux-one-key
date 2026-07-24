# HANDOVER

> **最后更新**: 2026-07-24 · **版本**: v1.1.0 · **状态**: 🟢 Batch 1-4 全部完成（计划文档同步标记）

## 会话恢复

```bash
git log --oneline -10          # 最近提交
cat HANDOVER.md                # 本文件
ls docs/plans/                 # 待执行计划
```

## 项目概要

Linux 云服务器安全加固一键脚本。v0.1 → v1.1.0 已完成：

- **模块**: SSH / Firewall / Fail2Ban / Users / Kernel / Filesystem / Audit / Services / Swap / AutoUpdate / K3s / AIDE / ClamAV / Rootkit Detection
- **Lite/Full 双模式**: `--lite` 低内存模式（SSH + Firewall + Kernel) vs Full 全模块
- **测试**: 442 Bats 单元测试全部通过
- **审查**: 5 轮全项目 Code Review，发现并修复 280+ 问题
- **最新发布**: v1.1.0（2026-07-24），Batch 2 安全与基础设施增强 + Batch 3 Security Plus

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
- **backup.sh / rollback.sh 加载**: 由 utils.sh 在加载过程中 source，此时 `_UTILS_LOADED` 尚未设置（在 utils.sh 末尾设置）。子模块的 guard 不检查 `_UTILS_LOADED`
- **SSH Full 模式增强**: `_restart_and_test_ssh()` 需 SSH 密钥已配置才能通过连接测试（失败是预期的，会自动设置回滚定时器）
- **菜单编号变更**: Batch 2 新增自动安全更新菜单项 [10]，后续编号相应改变：[11] 完整向导、[12] 查看报告、[13] K3s。Batch 3 新增 [14] AIDE、[15] ClamAV、[16] Rootkit

## 下一步

1. **🔄 发行版扩展**: RHEL 7+, Fedora Docker 测试
2. **⏳ ssh-rollback.bats**: 新增 SSH 回滚专用 Bats 测试文件（当前功能已实现但缺专属测试覆盖）
3. **⏳ clamd 可选安装**: 大内存服务器可选择启用 clamd 守护进程
4. **✅ NTP 时间同步** — 已在 Batch 1 实现（init.sh: setup_ntp）
5. **✅ 基础工具扩充** — 已在 Batch 1 实现（install_base_tools 含 htop/net-tools/lsof/tree/git）

> ✅ = 已实现 · 🔄 = 待验证 · ⏳ = 待实现

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

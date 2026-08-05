# HANDOVER

> **最后更新**: 2026-08-05 · **版本**: v1.6.0 · **状态**: ✅ v1.6.0 Batch 5a 完成 + mirror 换源模块合入 · **npm**: `@soeasy13142/linux-one-key` → GitHub Packages

## 会话恢复

```bash
git log --oneline -10          # 最近提交
cat HANDOVER.md                # 本文件
ls docs/plans/                 # 待执行计划
```

## 项目概要

Linux 云服务器安全加固一键脚本。v0.1 → v1.1.0 已完成：

- **模块**: SSH / Firewall / Fail2Ban / Users / Kernel / Filesystem / Audit / Services / Swap / AutoUpdate / K3s / AIDE / ClamAV / Rootkit Detection / **Mirror（更换软件源）**
- **Lite/Full 双模式**: `--lite` 低内存模式（SSH + Firewall + Kernel) vs Full 全模块
- **测试**: 512 Bats 单元测试全部通过
- **审查**: 5 轮全项目 Code Review，发现并修复 280+ 问题
- **最新发布**: v1.6.0（2026-08-01），Batch 5a 备份/回滚中心 + 安全仪表盘
- **新增 [19] 更换软件源**: vendored LinuxMirrors（MIT）完整交互，Lite/Full 均可用

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
| 分发方式 | curl 管道执行 + npm/GitHub Packages | curl 最简上手；npm 支持 npx/npm i -g |
| curl 管道检测 | 顶层 BASH_SOURCE 赋值 | 函数内返回 "main" 而非空 |
| curl 交互输入 | exec 后重定向 /dev/tty | stdin 在管道结束后为 EOF |
| sed 兼容 | uname 检测双语法 | macOS `sed -i ''` vs Linux `sed -i` |
| 换源功能 | vendored LinuxMirrors（MIT）+ subshell 隔离 | 避免 8000 行第三方脚本的命名/全局变量冲突；i18n 走 MSG_MIRROR_* |

## Gotchas

- **SSH 安全顺序**: 先改端口 → 配密钥 → 最后禁密码/root 登录，否则可能锁死自己
- **curl 管道 + 交互**: `BASH_SOURCE[0]` 必须在顶层赋值；`exec` 后 stdin 是 EOF 需重定向 tty
- **备份**: 所有配置修改前自动备份到 `/var/log/linux-one-key/backups/`
- **幂等**: 每个模块先检查当前状态，已加固项跳过，重复运行不出错
- **i18n**: 用户可见文本一律用 `MSG_*` 变量（`scripts/lang/`），不硬编码中英文
- **backup.sh / rollback.sh 加载**: 由 utils.sh 在加载过程中 source，此时 `_UTILS_LOADED` 尚未设置（在 utils.sh 末尾设置）。子模块的 guard 不检查 `_UTILS_LOADED`
- **SSH Full 模式增强**: `_restart_and_test_ssh()` 需 SSH 密钥已配置才能通过连接测试（失败是预期的，会自动设置回滚定时器）
- **菜单编号变更**: Batch 2 新增自动安全更新菜单项 [10]，后续编号相应改变：[11] 完整向导、[12] 查看报告、[13] K3s。Batch 3 新增 [14] AIDE、[15] ClamAV、[16] Rootkit。Batch 5a 新增 [17] 备份中心、[18] 仪表盘。本次新增 [19] 更换软件源（Lite/Full 均可用）
- **vendored lm_core.sh 8094 行**: 属第三方代码有意例外（违反"文件<800 行"规范）；只在 mirror.sh 的 `run_mirror_flow` subshell 内 source，绝不顶层 source
- **MSG_MIRROR_\* 键**: 来自 LinuxMirrors 语言包机械生成，zh/en 必须对称；lm_core 每处 `msg "key"` 都有对应键（mirror.bats 有完整性测试兜底）

## 下一步

本次（v1.5.0）已完成：
1. ✅ **curl 精简核心测试** — 13 测试 × 5 发行版全部通过，发现并修复 kernel.sh mkdir bug
2. ✅ **kernel.sh 修复** — `_generate_sysctl_config()` 增加 `mkdir -p`，修复 Rocky Linux 9 兼容性
3. ✅ **版本号更新** — `0.1.0` → `1.5.0`
4. ✅ **测试报告归档** — `docs/test-reports/curl-lite-mode-test.md`

本次（v1.6.0, Batch 5a）已完成：
1. ✅ **备份/回滚中心** — [17] 菜单：历史/恢复/回滚定时器/清理（backup.sh .meta sidecar，restore 绝对路径守卫）
2. ✅ **安全仪表盘** — [18] 菜单：12 模块 31 项检查评分 + 风险等级（i18n 本地化）
3. ✅ 测试增量 473 → 503，ShellCheck 干净，终审 + 修复波 + 重审通过

本次（mirror 换源）已完成：
1. ✅ **[19] 更换软件源** — vendored LinuxMirrors 完整交互（选站/协议/EPEL/升级），subshell 隔离 + MSG_MIRROR_* i18n，Lite/Full 均可用
2. ✅ **合规声明** — THIRD_PARTY_NOTICES.md（MIT 全文）+ README 致谢；测试 503 → 512，ShellCheck 干净

下次（Batch 5b）规划：
1. ⏳ **sudo + 日志加固** — 独立 spec 排队中

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

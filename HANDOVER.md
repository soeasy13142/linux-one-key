# HANDOVER

> **最后更新**: 2026-08-13 · **版本**: v1.6.0 · **状态**: ✅ Batch 5b + check.sh 收尾完成（HANDOVER 剩余待办清零）· **npm**: `@soeasy13142/linux-one-key` → GitHub Packages

## 会话恢复

```bash
git log --oneline -10          # 最近提交
cat HANDOVER.md                # 本文件
ls docs/plans/                 # 待执行计划
```

## 项目概要

Linux 云服务器安全加固一键脚本。v0.1 → v1.1.0 已完成：

- **模块**: SSH / Firewall / Fail2Ban / Users / Kernel / Filesystem / Audit / Services / Swap / AutoUpdate / K3s / AIDE / ClamAV / Rootkit Detection / **Mirror（更换软件源）** / **Docker** / **Nginx** / **Redis** / **PostgreSQL** / **MySQL** / **Memcached** / **Node Exporter** / **Prometheus** / **Grafana** / **Git** / **Editor** / **Runtimes** / **Build Toolchain** / **RabbitMQ** / **Sudo（加固）** / **Logging（日志加固）** / **check.sh（CIS/STIG 合规扫描器 CLI）**
- **Lite/Full 双模式**: `--lite` 低内存模式（SSH + Firewall + Kernel) vs Full 全模块
- **测试**: 795 Bats 单元测试全部通过
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
- **菜单编号变更**: Batch 2 新增自动安全更新菜单项 [10]，后续编号相应改变：[11] 完整向导、[12] 查看报告、[13] K3s。Batch 3 新增 [14] AIDE、[15] ClamAV、[16] Rootkit。Batch 5a 新增 [17] 备份中心、[18] 仪表盘。[19] 更换软件源（Lite/Full 均可用）。Batch 6a-6e 新增 [20] 服务器软件、[21] 开发工具。Batch 5b 新增 [22] sudo 与日志加固（Full-only）
- **vendored lm_core.sh 8094 行**: 属第三方代码有意例外（违反"文件<800 行"规范）；只在 mirror.sh 的 `run_mirror_flow` subshell 内 source，绝不顶层 source
- **MSG_MIRROR_\* 键**: 来自 LinuxMirrors 语言包机械生成，zh/en 必须对称；lm_core 每处 `msg "key"` 都有对应键（mirror.bats 有完整性测试兜底）
- **prometheus drop-in 绑定 localhost**: 用 systemd drop-in 覆盖 `ExecStart` 加 `--web.listen-address` 时，硬编码了 Debian/Ubuntu 的存储路径（`/var/lib/prometheus/metrics2`）；RHEL 族为 `/var/lib/prometheus`（无 metrics2 后缀），该 drop-in 在 RHEL 上不通用（已知限制，主验证目标为 Debian/Ubuntu）

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

本次（Batch 6a）已完成：
1. ✅ **[20] 服务器软件** — 新增 docker.sh + nginx.sh（install/uninstall/status + 安全基线），菜单 [20] 接入
2. ✅ **Docker 加固** — daemon.json 保守基线（日志限幅/icc/live-restore）+ userns-remap 激进 opt-in
3. ✅ **Nginx 加固** — 安全响应头 drop-in（隐藏版本/X-Frame-Options/nosniff/Referrer-Policy）+ HSTS opt-in
4. ✅ 测试 512 → 544，ShellCheck 干净

本次（Batch 6b）已完成：
1. ✅ **数据库 & 缓存** — redis / postgresql / mysql / memcached 四模块（install/uninstall/status + 安全基线 + Bats）
2. ✅ **Redis 加固** — 绑定 localhost + 禁用 FLUSHALL/FLUSHDB/CONFIG/EVAL
3. ✅ **PostgreSQL 加固** — scram-sha-256 + 仅监听 localhost
4. ✅ **MySQL/MariaDB 加固** — 非交互 mysql_secure_installation + bind 127.0.0.1
5. ✅ **Memcached 加固** — localhost + 禁 UDP + 限内存
6. ✅ 测试 544 → 612，ShellCheck 干净

本次（Batch 6c）已完成：
1. ✅ **监控** — node_exporter / prometheus / grafana 三模块（install/uninstall/status + 安全基线 + Bats）
2. ✅ **Node Exporter** — systemd 加固 drop-in + 双名适配（Debian/Ubuntu 用 prometheus-node-exporter）
3. ✅ **Prometheus** — 绑定 localhost（systemd drop-in 覆盖 --web.listen-address）
4. ✅ **Grafana** — 官方 OSS 源 + 绑定 localhost + 禁用匿名访问
5. ✅ 测试 612 → 660，ShellCheck 干净

本次（Batch 6d）已完成：
1. ✅ **开发工具** — git / editor / runtimes / build_toolchain 四模块 + 新增 [21] 开发工具菜单
2. ✅ **Git** — 安装 + .gitconfig 配置（defaultBranch/别名/name/email）
3. ✅ **Editor** — Vim/Nano 安装 + 安全 dotfile 配置
4. ✅ **Runtimes** — Node/Python/Go 发行版包安装
5. ✅ **Build Toolchain** — build-essential/gcc/make/cmake
6. ✅ 测试 660 → 705，ShellCheck 干净

本次（Batch 6e）已完成：
1. ✅ **消息队列** — rabbitmq 模块（install/uninstall/status + 删除默认 guest 账号 + 管理插件 opt-in）
2. ✅ 测试 705 → 720，ShellCheck 干净

本次（Batch 5b + check.sh）已完成：
1. ✅ **sudo 加固** — `scripts/security/sudo.sh`：requiretty/secure_path/timestamp_timeout、NOPASSWD 白名单 warn、drop-in `99-linux-one-key-sudo`（写前备份 → 0440 → `visudo -c` 双重校验失败回滚）、sudo 命令全量日志 `/var/log/sudo.log`（root:root 0640 + logrotate）
2. ✅ **日志加固** — `scripts/security/logging.sh`：journald drop-in（Storage=persistent/SystemMaxUse/MaxRetentionSec）+ `try-restart`（失败仅 warn）、logrotate 安全 drop-in、`/var/log` 关键文件 owner root + 600/640 修复
3. ✅ **菜单 [22] sudo 与日志加固** — Full-only，子菜单（sudo 向导 / 日志向导）
4. ✅ **check.sh** — `scripts/utils/check.sh` 独立 CLI（ssh/sudo/log/kernel 4 节只读扫描，`--json` + exit code 0/1/2，路径环境变量可 mock）；`scripts/utils/README.md` 补用法
5. ✅ 测试 720 → 795（+45 sudo/logging +30 check），ShellCheck 干净

> ✅ = 已实现 · 🔄 = 待验证 · ⏳ = 待实现

**HANDOVER 剩余待办已全部清零 ✅**。如需后续扩展方向：check.sh 增加更多检查节（firewall/filesystem）、或接入 CI（Docker Phase 矩阵纳入新模块）。

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

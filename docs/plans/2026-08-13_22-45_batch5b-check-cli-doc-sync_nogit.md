---
title: "收尾剩余待办：Batch 5b(sudo+日志) / check.sh CLI / 文档同步"
created: 2026-08-13
updated: 2026-08-14
status: done
source: "HANDOVER.md 剩余待办 + 路线图 D4 + 路线图 D2 文档同步缺口"
topic: "feature"
---

# 收尾剩余待办：Batch 5b / check.sh / 文档同步

## 背景

HANDOVER.md 标记 Batch 6a-6e 全部完成，但仍有三个待办未落地：

1. ⏳ **Batch 5b「sudo + 日志加固」** — 无 spec，独立排队
2. ⏳ **check.sh（CIS/STIG 合规扫描器）** — 路线图 D4 单列延后
3. 📋 **路线图 D2 承诺的文档同步缺口** — CLAUDE.md 模块边界表未更新；路线图计划文件 status 仍为 in-progress

本计划一次性收尾三项。已与用户确认范围：
- Batch 5b = **sudo 加固 + 日志加固**（不含 auditd / 集中日志）
- check.sh = **独立 CLI 扫描器**（直接解析配置文件，零耦合 dashboard，`--json` + exit code）

## 目标

1. 新建 `scripts/security/sudo.sh` + `scripts/security/logging.sh`（Batch 5b，菜单 [22]）
2. 新建 `scripts/utils/check.sh`（CIS/STIG 命令行合规扫描器，独立 CLI）
3. 更新 `.claude/CLAUDE.md` 模块边界表（`scripts/server/` 行 + 新增 `scripts/dev/` 行）
4. 路线图计划文件标 `done` + HANDOVER 同步
5. 全部改动配 Bats 测试 + ShellCheck 干净 + 全量回归

## 执行项

### A. Batch 5b — sudo + 日志加固（`scripts/security/`，菜单 [22]）

**范围**（已确认，核心版，不碰 auditd/集中日志）：

**sudo 加固** `scripts/security/sudo.sh`：
- sudoers 收紧：校验 `NOPASSWD` 白名单（存在则 warn 并提示）、`requiretty`、`secure_path`、`timestamp_timeout`（如 `Defaults timestamp_timeout=5`）
- 写入加固 drop-in：`/etc/sudoers.d/99-linux-one-key-sudo`（须 `visudo -c` 校验，`chmod 0440`）
- sudo 命令全量日志：`Defaults logfile="/var/log/sudo.log"` + 日志文件轮转（logrotate drop-in），确认 `/var/log/sudo.log` 权限（root:root, 640）

**日志加固** `scripts/security/logging.sh`：
- journald 持久化 + 大小限制：`/etc/systemd/journald.conf.d/99-linux-one-key.conf`（`Storage=persistent`、`SystemMaxUse`、`MaxRetentionSec`），随后 `systemctl restart systemd-journald`（或 `systemctl try-restart`，幂等）
- logrotate 安全配置：drop-in 保证权限 `0640` / `su root` / `compress` / `dateext`
- `/var/log` 目录权限防篡改：关键日志文件 owner root + `600/640` 检查

**菜单接入** `install.sh`：
- 新增顶层菜单 **[22] sudo 与日志加固**（Full 模式专用，标灰逻辑复用 `is_mode_lite`）
- `show_main_menu()` 新增两行；`get_main_menu_choice` 正则 `[0-9]|1[0-9]|2[01]` → `[0-9]|1[0-9]|2[0-2]`；`prompt_input` 文案 `[0-21]` → `[0-22]`；`run_main_menu_loop` case 追加 `22) run_sudo_log_menu_loop ;;`
- `load_modules` 在 security 区追加 source `sudo.sh` / `logging.sh`（Full-only）

**i18n**：新增 `MSG_SUDO_*` / `MSG_LOG_*` 键（zh/en 对称），含菜单键 `MSG_MAIN_MENU_SUDO_LOG` / `_DESC`。

**测试**：`tests/unit/sudo.bats` + `tests/unit/logging.bats`（mock 路径覆盖：加固写入/幂等/备份/visudo 校验/日志权限/菜单编号）。

### B. check.sh — CIS/STIG 合规扫描器（`scripts/utils/check.sh`）

**定位**（已确认）：独立 CLI，非菜单模块，零耦合 dashboard。直接解析配置文件（不 import security 模块）。

**CLI 接口**：
```
bash scripts/utils/check.sh [--json] [--section ssh|sudo|log|...] [--help]
```
- 默认输出终端可读的 PASS/FAIL 表格
- `--json`：输出 JSON（数组，每项 {section, id, status, detail}）
- exit code：0 = 全部 PASS；1 = 存在 FAIL；2 = 参数错误

**检查项**（至少覆盖，读配置文件只读判定）：
- ssh：端口 ≠22、PermitRootLogin no、PasswordAuthentication no
- sudo：NOPASSWD 无、timestamp_timeout 存在、logfile 已配、sudoers 权限 0440
- log：journald Storage=persistent、SystemMaxUse 存在、关键日志文件权限
- kernel：sysctl 加固文件存在
- firewall / filesystem：基础检查（可延后，先保证上述 4 节）

**i18n**：新增 `MSG_CHECK_*` 键（zh/en 对称）。

**测试**：`tests/unit/check.bats`（mock 配置文件 + 判定逻辑 + --json 格式 + exit code）。

**接入**：不进菜单；`install.sh` 不 source（独立运行）。README 注明用法。

### C. CLAUDE.md 模块边界表同步

改 `.claude/CLAUDE.md` Module Boundaries 表：
- `scripts/server/` 行：`服务器软件安装（k3s）` → `服务器软件安装（docker/nginx/mysql/postgresql/redis/memcached/rabbitmq/prometheus/grafana/node-exporter/k3s/mirror）`
- 新增 `scripts/dev/` 行：`开发工具（git/editor/runtimes/build_toolchain）`，Must NOT import：security, server

### D. 路线图计划文件标 done

改 `docs/plans/2026-08-13_20-42_server-dev-modules-roadmap_nogit.md`：
- frontmatter `status: in-progress` → `done`，`updated` 刷新
- 进度记录追加 Batch 6a-6e 完成条目

## 文件归属（sub agent 分工，避免共享文件冲突）

- **Sub agent A（Batch 5b）**：`scripts/security/sudo.sh`、`scripts/security/logging.sh`、`tests/unit/{sudo,logging}.bats`、`install.sh`、`scripts/lang/{zh,en}.sh`（`MSG_SUDO_*`/`MSG_LOG_*`/菜单键）、`scripts/security/README.md`
- **Sub agent B（check.sh）**：`scripts/utils/check.sh`、`tests/unit/check.bats`、`scripts/lang/{zh,en}.sh`（`MSG_CHECK_*`）、`scripts/utils/README.md`

> ⚠️ A 与 B **都改** `scripts/lang/{zh,en}.sh` → 必须**顺序执行**（先 A 后 B），避免并行 Edit 冲突。

- **主会话（文档同步）**：`.claude/CLAUDE.md`、`docs/plans/2026-08-13_20-42_*.md`、`HANDOVER.md`（最后同步）

## 统一契约（沿用 k3s.sh / security 模块）

- Guard：`_UTILS_LOADED` 前置检查；文件末尾 `readonly _<MOD>_LOADED=1`（security 模块沿用现有风格）
- 输出：`log_info/success/warn/error` + `MSG_*`，不硬编码
- 安全：所有配置修改前 `backup_file` 到 `/var/log/linux-one-key/backups/`；幂等
- 测试：新模块必须配 Bats；`shellcheck -x scripts/security/sudo.sh scripts/security/logging.sh scripts/utils/check.sh` 干净

## 测试与验证

1. 每个 sub agent 完成自己模块的 Bats 并跑通本文件
2. 全部完成后主会话跑 `shellcheck -x install.sh scripts/**/*.sh` + `bats tests/unit/*.bats` 全量回归
3. 现有 720 测试不得回归（新增后总数 ↑）

## 风险与注意事项

- **sudoers 写坏风险**：写 `/etc/sudoers.d/` 前必须 `visudo -c` 校验，失败立即回滚备份
- **journald 重启**：`systemctl restart systemd-journald` 在部分容器环境可能失败 → 用 `try-restart` + 失败仅 warn
- **check.sh 零耦合**：直接读 `/etc/ssh/sshd_config` 等路径（复用 `utils.sh` 的 `get_ssh_config` 可，但不得 source security 模块）
- **菜单编号**：[22] 是下一个可用项（已确认 [0]-[21] 占用）
- **lang 顺序**：sub agent A 与 B 都改 lang 文件，**严格顺序执行**，不得并行

## 预期产出

- 新增 3 个模块文件（sudo.sh / logging.sh / check.sh）+ 2 个 security Bats + 1 个 utils Bats
- install.sh 菜单 [22] + lang 键对称新增
- CLAUDE.md 模块边界表 + 路线图计划 status 修正
- HANDOVER.md 剩余待办清零（更新测试数 + 下一步）

## 进度记录

- 2026-08-13: 创建计划，status=draft
- 2026-08-13: 用户确认 Batch 5b 范围（sudo+日志核心版）与 check.sh 定位（独立 CLI）；status=in-progress
- 2026-08-14: 三项全部完成（Batch 5b sudo+日志加固、check.sh CLI、文档同步），Bats 720 → 795，ShellCheck 干净；status=done

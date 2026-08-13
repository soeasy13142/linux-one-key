---
title: "服务器软件 + 开发工具模块兑现路线图（Batch 6a-6e）"
created: 2026-08-13
updated: 2026-08-13
status: in-progress
source: "scripts/{server,dev,utils}/README.md 规划中(v0.3+) 的未建模块；用户选定「兑现已规划的运维/开发模块」方向"
topic: "feature"
---

# 服务器软件 + 开发工具模块兑现路线图

## 背景

`scripts/server/README.md`、`scripts/dev/README.md`、`scripts/utils/README.md` 三份文档早在 v0.3 就规划了一批「常用软件安装 + 配置」模块，但除 `k3s.sh`、`mirror.sh` 外几乎未建（`backup.sh`/`rollback.sh` 已实现于 `scripts/base/`，故 utils 里仅剩 `check.sh` 未建）。

现有一个成熟的模块模板 `scripts/server/k3s.sh`（install / uninstall / status / 子菜单 + i18n + 幂等 + 备份），新模块应复用该模式，并在「安装」之上叠加「安全基线」，体现本项目的安全加固基因。

## 目标

1. 兑现 14 个规划模块（+ `check.sh` 单列），**全部走完整版**（符合「新功能只进完整版」规则）。
2. 用第一个批次（Batch 6a）立起「装软件 + 套安全基线」的通用骨架：目录、菜单接入、i18n、Bats 测试、CI。
3. 每个模块 = 安装 + 初始加固 + 状态检查 + 卸载 + 幂等 + 修改前备份 + i18n。

## 架构决策（待用户确认）

### D1 菜单策略（已确认）

**已确认**：新增**两个**顶层菜单 `[20] 服务器软件` + `[21] 开发工具`，分别进入分组子菜单（服务器软件 → Web/数据库/缓存/消息队列/监控/容器；开发工具 → git/editor/runtimes/编译链），每个软件再进各自 install/uninstall/status 子菜单。

- 理由：对应 server/dev 目录结构清晰，主菜单只增 2 项，避免平铺到 33+ 项。
- K3s / Mirror 暂不迁移进分组（后续可选的收敛重构，不在本路线图内）。

### D2 目录归属（已确认）

| 目录 | 模块 | 说明 |
|------|------|------|
| `scripts/server/` | docker, nginx, mysql, postgresql, redis, memcached, rabbitmq, prometheus, grafana, node-exporter | 服务/守护进程类 |
| `scripts/dev/` | git, editor, runtimes, build-toolchain | 开发环境类 |

- **已确认** `docker` 归 `scripts/server/`（容器运行时属服务器基础设施；与 README 原文的 dev/ 归类偏离，以本决策为准）。
- 需同步更新 `.claude/CLAUDE.md` 的 Module Boundaries 表，新增 `scripts/dev/` 行（当前表未含 dev）。
- `scripts/dev/gen-file-tree.sh` 是仓库维护脚本，非用户模块，保持原样。

### D3 通用模式（规则三，避免过早抽象）

先建 **docker + redis** 两个样本，观察真实重复点后，再把「添加仓库 / 装包 / 启用服务 / 写加固配置 / 备份原文件」抽成 `scripts/server/lib.sh`（或并入 `utils.sh`）。**不预先抽框架**。

### D4 `check.sh` 单列 / 延后

与现有 `dashboard.sh`（31 项 CIS 检查）有交集，定位为「CIS/STIG 命令行合规扫描器」而非菜单模块，低优先级，本路线图仅记录、不排批。

### D5 加固默认力度（已确认）

**已确认**：保守默认 + 激进 opt-in —— daemon.json 激进项（`userns-remap` 等）、redis 危险命令禁用、nginx 强安全头等**默认关闭**，由用户在交互中主动开启；保守基线（绑定 localhost、TLS 版本、隐藏版本号、日志限幅）**默认启用**。

## 模块清单

| 模块 | 目录 | 加固要点 | 工作量 | 发行版注意 |
|------|------|----------|:---:|------|
| docker | server | 官方 CE 仓库 + compose 插件；daemon.json 加固（json-file 日志限幅、`icc=false`、`live-restore`；`userns-remap` 等激进项 opt-in）；提示 docker 组权限风险 | M | apt 用官方源 / dnf 用 docker-ce；Debian 需确认 `docker.io` 命名冲突 |
| nginx | server | `server_tokens off`、TLS 1.2/1.3、安全响应头、替换默认站点、body 大小限制 | M | Debian/Ubuntu 默认站点路径 `/etc/nginx/sites-available`；RHEL 族 `/etc/nginx/conf.d` |
| mysql | server | 等价 `mysql_secure_installation`（删匿名用户/测试库、禁 root 远程、设强密码）；绑定 localhost | M | Ubuntu 用 `mysql-server`；CentOS7 为 `mariadb-server`，命名差异大 |
| postgresql | server | `pg_hba.conf` 收紧为 `scram-sha-256` + 仅 localhost；监听 `127.0.0.1`；强密码 | M | 版本号随发行版（Ubuntu22=15、Debian12=15、Rocky9=16） |
| redis | server | 绑定 `127.0.0.1`、`requirepass`、`protected-mode yes`、禁用/重命名危险命令（FLUSHALL/CONFIG/EVAL） | S | 包名 `redis`/`redis-server`（CentOS7 需 EPEL） |
| memcached | server | 绑定 localhost、禁用 UDP（`-U 0`）、限制内存 | S | 包名 `memcached`，配置文件 `/etc/sysconfig/memcached` 或 `/etc/memcached.conf` |
| rabbitmq | server | 可选启用管理插件；删除默认 `guest` 账号或强制改密；绑定 localhost | M | Erlang 依赖；CentOS7 需 EPEL + 官方源 |
| prometheus | server | 基础认证（web basic auth）或绑定 localhost + 反代；数据保留策略 | M | 官方二进制 tarball 或发行版包 |
| grafana | server | 绑定 localhost + 反代；初始 admin 改密；禁用匿名访问 | M | 官方 apt/dnf 源 |
| node-exporter | server | systemd 单元加固（NoNewPrivileges、ProtectSystem）；可选 textfile collector | S | GitHub release 二进制或发行版包 |
| git | dev | 用户/邮箱（可选）、默认分支、常用 alias、credential helper 提示 | S | 无风险，纯写 `.gitconfig` |
| editor | dev | vim/nano 基础配置（语法高亮、行号、缩进、backspace） | S | 无风险，纯写 dotfile |
| runtimes | dev | Node LTS（nvm 或 nodesource）、Python（系统包）、Go（官方 tarball） | M | 第三方源需网络；Go 版本随 arch |
| build-toolchain | dev | `build-essential`/`Development Tools`（gcc/make/cmake） | S | 发行版包名：Debian `build-essential` vs RHEL `@Development Tools` |

> 总模块数：14（含 build-toolchain）；`check.sh` 单列不排批。括号内为扩展计划功能（apache/containerd）不在本路线图内。

## 批次计划

### Batch 6a — 骨架批次：docker + nginx

- **产出**：`scripts/server/docker.sh`、`scripts/server/nginx.sh` + 对应 Bats + i18n + 菜单接入 + `[20] 应用中心` 分组子菜单骨架。
- **意义**：立起「install + harden」通用模式与测试/CI 骨架，后续批次只填内容。
- **测试**：每模块 Bats 单测（install/uninstall/status 的 mock 路径、幂等、备份）+ Docker Phase 1 配置验证。
- **依赖**：无。

### Batch 6b — 数据库 & 缓存：redis + postgresql + mysql + memcached

- 复用 6a 骨架；redis 作为「最小加固样本」先做（S 级），再铺 postgresql/mysql（M 级）。
- 测试同上。

### Batch 6c — 监控：node-exporter + prometheus + grafana

- node-exporter（S）先行，prometheus/grafana（M）后续；三者可选组合。

### Batch 6d — 开发工具：git + editor + runtimes + build-toolchain

- 纯便利、最低风险；git/editor/build-toolchain 为 S，runtimes 为 M。

### Batch 6e — 消息队列：rabbitmq

- 相对小众，放最后。

### 顺序与依赖

```
6a (docker+nginx) ─► 6b (redis→postgres→mysql→memcached)
                 ─► 6c (node-exporter→prometheus→grafana)
                 ─► 6d (git/editor/build-toolchain→runtimes)
                 ─► 6e (rabbitmq)
```

6b/6c/6d 相互独立，可在 6a 完成后并行推进。

## 菜单编号分配

- `[20] 服务器软件` + `[21] 开发工具`（已确认，对应 server/dev 目录）。
- 需改动 `install.sh`：
  - `get_main_menu_choice()` 正则 `[0-9]|1[0-9]` → `[0-9]|1[0-9]|2[01]`；
  - `prompt_input` 文案 `[0-19]` → `[0-21]`；
  - `show_main_menu()` 新增两行（full-only 标灰逻辑复用现有 `is_mode_lite` 判断）；
  - `run_main_menu_loop()` case 追加 `20) run_server_menu_loop ;; 21) run_dev_menu_loop ;;`。

## 每模块统一契约（沿用 k3s.sh）

- 函数：`check_<mod>_installed` / `install_<mod>` / `uninstall_<mod>` / `check_<mod>_status` / `show_<mod>_submenu` / `run_<mod>_submenu_loop`
- Guard：`_UTILS_LOADED` 前置检查；文件末尾 `readonly _<MOD>_LOADED=1`
- 输出：`log_info/success/warn/error` + `MSG_*` i18n（zh/en 对称），不硬编码
- 交互：`confirm` / `prompt_input`；安装前 `is_root` + `command_exists` 检查
- 安全：所有配置文件修改前 `backup_file` 到 `/var/log/linux-one-key/backups/`；幂等（已装则跳过）
- 测试：每个新模块必须配 Bats（install/uninstall/status/幂等/备份路径）

## 测试策略

1. 每模块 Bats 单测（mock 包管理器/命令，覆盖正常/已装/卸载/状态/幂等/备份）。
2. Docker Phase 1 配置验证：把新模块纳入 9 发行版 × 模块矩阵（先覆盖代表性 3 发行版，稳定后扩 9）。
3. ShellCheck 干净（`shellcheck -x scripts/server/*.sh scripts/dev/*.sh`）。
4. 现有 512 测试不得回归。

## 风险与注意事项

- **外部仓库依赖**：docker/grafana/node-exporter/runtimes 需第三方源或 GitHub release，断网环境不可用；需 `confirm` 前提示。
- **加固 vs 可用性平衡**：daemon.json / redis 危险命令禁用 / nginx 安全头等，激进项一律 opt-in，保守项为默认。
- **发行版差异**：包名（`mysql-server` vs `mariadb-server`）、配置路径、systemd unit 名各异，需 `detect.sh` 分支。
- **mysql/postgres 交互安装**：Debian 的 `debconf` 非交互装包（`DEBIAN_FRONTEND=noninteractive`）需处理，避免卡死。
- **加固后自锁**：redis/pg 绑定 localhost 后应用若需远程访问，需显式提供放行开关。

## 决策点（已解决）

1. **菜单策略** → ✅ `[20] 服务器软件` + `[21] 开发工具` 两个顶层项。
2. **docker 归属** → ✅ `scripts/server/`。
3. **加固默认值** → ✅ 保守默认 + 激进 opt-in。

## 预期产出

- 新增 `scripts/server/` 10 个模块文件、`scripts/dev/` 4 个模块文件（分批落地）。
- 新增 `scripts/lang/{zh,en}.sh` 的 `MSG_SERVER_*` / `MSG_DEV_*` 键（对称）。
- 新增 Bats 测试文件（每模块 1 个，约 8-15 用例/模块）。
- 更新 `install.sh`（菜单接入）、`.claude/CLAUDE.md`（模块边界表）、`README.md`（特性/菜单）、`HANDOVER.md`（状态快照）。

## 进度记录

- 2026-08-13: 创建路线图，status=draft。
- 2026-08-13: 用户确认 3 个决策点（菜单 [20]+[21]、docker 归 server/、保守默认加固）；status=in-progress。下一步：Batch 6a（docker + nginx）精设计 → 实现。

---
title: "借鉴科技lion研究：5 项可落地功能（--version / i18n 对称测试 / README 警示 / 写入护栏 / 状态菜单）"
created: 2026-08-18
updated: 2026-08-18
status: done
source: "docs/research/kejilion-study.md §7 可落地清单；对照项目现状筛选出 A-E 五项真实空缺（F/G/H 本轮不做）"
topic: "feature"
---

# 借鉴科技lion研究：5 项可落地功能

## 背景

docs/research/kejilion-study.md（科技lion v4.5.7 学习研究）§7 给出 P0/P1/P2 共 17 条可落地建议。
逐条对照项目现状后，真实空缺仅以下 5 项（其余已具备或与本项目设计冲突）：

| 编号 | 功能 | 文档出处 | 空缺证据 |
|------|------|----------|----------|
| A | install.sh --version（版本 + 最近变更） | P2 #16 | _parse_args 无 --version 分支，未知参数直接报错退出；SCRIPT_VERSION 已在 utils.sh:20 定义 |
| B | zh/en 语言包 key 集合对称性测试 | P1 #7 | zh.sh/en.sh 各 1634 个 MSG_* 键，但 tests/ 无键集对称测试（mirror.bats 只查单模块键非空） |
| C | 写入安全护栏（拒绝符号链接 + 大小/行数边界） | P1 #10 | kernel.sh:49 heredoc 直写、fail2ban/sudo/ssh 写配置前均无 -L 检查、无边界校验 |
| D | 状态感知子菜单（server 模块） | P1 #5 | 11 个 server 模块 check_*_installed/running 函数全齐，但 show_*_submenu 均为静态菜单 |
| E | README 安装命令下 > [!IMPORTANT] 警示块 | P2 #15 | README 已有徽章/安全表，缺高可见度警示块 |

## 目标

- Batch 1（快赢）：A + B + E，带 Bats 测试
- Batch 2：C 写入护栏，应用到 kernel/fail2ban/sudo/ssh 写配置点
- Batch 3：D 状态菜单，11 个 server 模块子菜单加状态行
- 收尾：shellcheck 全绿 + 全量 bats + HANDOVER/README changelog + 本地 commit（不 push）

## 设计决策

### D1 A：--version 输出
- _parse_args 增加 --version|-V 分支：打印 linux-one-key <SCRIPT_VERSION> + 最近 4 条 changelog（i18n 键 MSG_VERSION_LOG_1..4，单行字符串，与 lang 文件现有格式一致）
- --help 输出补一行 --version
- 测试：parse-args.bats 结构测试（grep 契约，与现有风格一致）

### D2 B：键集对称测试
- 新文件 tests/unit/lang-symmetry.bats：从 zh.sh/en.sh 提取 ^MSG_[A-Za-z0-9_]+ 键，sort 后 comm -23 双向比对，缺键即失败并在输出中列出

### D3 C：写入护栏
- utils.sh 新增 assert_safe_config_target <file> [max_size] [max_lines]：
  1. -L 符号链接 → 拒绝（防劫持）
  2. 已存在但不是常规文件 → 拒绝
  3. 大小 > max_size（默认 1MiB）或行数 > max_lines（默认 10000）→ 拒绝
  4. 新键 MSG_GUARD_*（zh/en 对称，B 测试守护）
- 应用点：kernel.sh _generate_sysctl_config 与模板 cp 分支、fail2ban.sh jail.local 原子写前、sudo.sh _write_sudoers_dropin 写前、ssh.sh sshd_config 修改前
- 测试：utils.bats 新增用例（普通文件通过 / 符号链接拒绝 / 超大文件拒绝 / 不存在文件通过）

### D4 D：状态菜单
- utils.sh 新增 render_service_state_label <installed> <running>（1/0 布尔）→ 输出 MSG_MENU_STATE_* 标签
- 新键（zh/en）：MSG_MENU_STATE_LABEL（状态）、MSG_MENU_STATE_NOT_INSTALLED（未安装）、MSG_MENU_STATE_INSTALLED_RUNNING（已安装 · 运行中）、MSG_MENU_STATE_INSTALLED_STOPPED（已安装 · 未运行）
- 11 个 server 模块 show_*_submenu 首行加状态行（docker/nginx/redis/postgresql/mysql/memcached/node_exporter/prometheus/grafana/rabbitmq/k3s；mirror 为纯配置模块，跳过）
- 测试：utils.bats 补 label 4 种状态用例；新增 tests/unit/server-menu-state.bats 结构测试

### D5 范围外（本轮不做）
- F（CLI 子命令别名层）：设计反转，需用户拍板，且与"仅交互 + --status"公开立场冲突
- G（环境变量非交互协议）：check.sh --json + --status 已覆盖只读/机器可读场景，无面板规划前不做
- H（省带宽版本检查/自更新）：加固工具不宜自动改写刚加固的配置；如需仅做"检查更新仅提示"

## 执行项

- [ ] **Batch 1-A**：install.sh _parse_args 加 --version；lang/zh.sh + en.sh 加 MSG_VERSION_* + MSG_HELP_VERSION；parse-args.bats 补测试
- [ ] **Batch 1-B**：新建 tests/unit/lang-symmetry.bats
- [ ] **Batch 1-E**：README 快速开始安装命令下加 > [!IMPORTANT] 块
- [ ] **Batch 2-C**：utils.sh 加护栏 + 4 处应用 + utils.bats 用例
- [ ] **Batch 3-D**：utils.sh 加 label 辅助 + 11 处 submenu + lang 键 + 2 个测试文件
- [ ] **收尾**：shellcheck 全绿、全量 bats、HANDOVER/README 更新、分批次本地 commit


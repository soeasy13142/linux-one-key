# 项目交接文档

> **⚠️ 强制规则**：每次修改项目时，必须同步更新本文档。详见 `.claude/rules/common/handover.md`。

**最后更新**: 2026-07-24（Lite/Full 双模式发布）
**当前阶段**: v1.0.1 已发布 → Lite/Full 双模式实现完成 ✅

> **新增**: Lite/Full 双模式（`--lite` 精简版，低内存服务器优化）

---

## 1. 项目简介

**linux-one-key** 是一个 Linux 云服务器安全加固一键脚本。用户通过 SSH 连接到新购买的云服务器后，运行此脚本即可交互式完成安全配置。

**核心特性**：
- 交互式操作，每步确认
- 支持 CentOS 7+/Ubuntu 20.04+/Debian 11+/Rocky/Alma
- 所有修改前备份，支持回滚
- 幂等设计，重复运行不出错

---

## 2. 当前进度

### 总体状态：🟢 Lite/Full 双模式实现完成 ✅

| 阶段 | 状态 | 说明 |
|------|------|------|
| 需求分析 | ✅ 完成 | PRD 已编写，见 `docs/design/linux-security-hardening-prd.md` |
| 架构设计 | ✅ 完成 | 交互模式、i18n、日志、备份等技术决策已确定 |
| v0.1 基础框架 + SSH 安全 | ✅ 完成 | utils.sh, detect.sh, init.sh, ssh.sh, install.sh, 语言文件, 测试 |
| v0.2 防火墙 + Fail2Ban | ✅ 完成 | firewall.sh, fail2ban.sh, 语言文件更新, 菜单集成, 单元测试 |
| Code Review (Round 1) | ✅ 完成 | 全面审查发现 2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW bug |
| Code Review (Round 2) | ✅ 完成 | 3 代理并行审查，发现 10 CRITICAL + 15 HIGH + 13 MEDIUM + 12 LOW，共 50 个问题 |
| Code Review (Round 3) | ✅ 完成 | 0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW；全部已修复（含 H2、L4） |
| v0.3 用户管理 + 内核加固 + 文件系统 | ✅ 完成 | users.sh, kernel.sh, filesystem.sh, sysctl 模板, i18n, 测试 76 个用例 |
| v0.4 审计日志模块 | ✅ 完成 | audit.sh, audit.bats, config/audit/, i18n 更新, 菜单集成, 44 个测试用例 |
| v0.4 服务管理 | ✅ 完成 | services.sh, services.bats, i18n 更新, 菜单集成, 35 个测试用例 |
| v1.0 主菜单重构 v2 | ✅ 完成 | 子菜单壳 + 分组 + 状态检测升级 + view_report 历史 + i18n 完善 + 错误精简 |
| v1.0 Code Review Round 4 (全项目) | ✅ 完成 | 6 组并行审查 → 88 个问题已全部修复，25 个 SubAgent 并行执行 |
| v1.0 测试 + 文档 + 发布 | ✅ 完成 | Docker Phase 1 配置验证测试：9 distros × 8 modules = 72/72 全部通过 |
| v1.0 K3s 安装模块 | ✅ 完成 | K3s 安装/卸载/状态检查，i18n，菜单集成，17 个 Bats 测试 |
| v1.0 Docker Phase 2（基础设施就绪） | ✅ 完成 | 特权容器 + 服务验证 + 安全扫描 + 回滚测试（3 distros × 7 modules = 21/21 passed）|
| v1.0.1 Lite/Full 双模式 | ✅ 完成 | mode.sh 模块注册表 + install.sh --lite 参数 + 菜单/向导/状态过滤 + i18n + mode.bats 测试 |

---
## 3. 文件清单

> 📋 **详细文件树由 [`scripts/dev/gen-file-tree.sh`](../../scripts/dev/gen-file-tree.sh) 自动生成**，输出到 `docs/file-tree.generated.md`（gitignored，避免过期）。
> 重新生成：`bash scripts/dev/gen-file-tree.sh`

### 顶层目录概览

| 目录/文件 | 用途 |
|---|---|
| `install.sh` | 主入口脚本（菜单、交互流程、curl 管道支持） |
| `README.md` | 项目说明（人类入口） |
| `CONTRIBUTING.md` | 贡献指南（TDD、Git 工作流、ECC 命令） |
| `LICENSE` | MIT 开源许可证 |
| `HANDOVER.md` | 本文件（强制交接文档） |
| `CLAUDE.md` | Claude Code 项目指令（在 `.claude/CLAUDE.md`） |
| `scripts/base/` | 基础环境（utils.sh, detect.sh, init.sh, report.sh） |
| `scripts/security/` | 安全加固模块（ssh/firewall/fail2ban/audit/users/kernel/filesystem/services） |
| `scripts/server/` | 服务器软件安装模块（k3s.sh） |
| `scripts/lang/` | i18n 文件（zh.sh, en.sh） |
| `scripts/dev/` | 开发工具脚本（如 gen-file-tree.sh） |
| `tests/docker/` | Docker 自动化测试框架（Phase 1: 配置验证，Phase 2: 服务验证） |
| `tests/unit/` | Bats 单元测试（utils/firewall/fail2ban/ssh/audit/users/kernel/filesystem/services） |
| `docs/release-checklist.md` | v1.0 发布检查清单 |
| `config/` | 配置文件模板（fail2ban/, audit/, sysctl/） |
| `docs/code-reviews/` | Code Review 报告归档 |
| `docs/test-reports/` | 测试报告归档 |
| `docs/design/` | 设计文档 & 实施计划（含 lite-vs-full-mode.md） |
| `docs/plans/` | 计划文件目录（Plan-First 落地，命名见 [README](plans/README.md)） |
| `docs/handover-archive.md` | 历史变更日志归档（2026-06-20~24） |

完整结构详见自动生成的 [`docs/file-tree.generated.md`](file-tree.generated.md)。

## 4. 技术决策记录

| 决策 | 选择 | 原因 |
|------|------|------|
| 脚本语言 | Bash | 兼容性最好，无需额外依赖 |
| 防火墙工具 | UFW (Ubuntu) / firewalld (CentOS) | 各发行版原生工具 |
| SSH 密钥类型 | Ed25519 | 比 RSA 更安全、更短 |
| 默认 SSH 端口 | 2222 | 非标准端口，避免自动化扫描 |
| Fail2Ban 封禁时间 | 3600 秒 | 平衡安全性和误封风险 |
| 交互模式 | 快速开始 + 自定义配置 | 快速开始执行所有任务，自定义逐项选择 |
| i18n 实现 | 语言文件 source | lang/zh.sh, lang/en.sh，通过 load_lang() 加载 |
| 日志输出 | 分级输出 | 终端显示简化信息，详细信息写入 /var/log/linux-one-key/ |
| 备份目录 | /var/log/linux-one-key/backups/ | PRD 原始设计，统一管理 |
| 依赖方式 | SCRIPT_DIR 绝对路径 | 所有 source 使用 ${SCRIPT_DIR}/scripts/xxx.sh |
| 分发方式 | curl 管道执行 | 支持 curl -fsSL https://xxx/install.sh \| bash |
| sed 兼容 | macOS/Linux 双平台 | 检测 uname 使用不同 sed -i 语法 |
| curl 管道检测 | 顶层捕获 BASH_SOURCE | BASH_SOURCE[0] 在函数内返回 "main" 而非空，必须在顶层赋值给变量 |
| curl 管道 stdin | exec 时重定向 /dev/tty | exec 后 stdin 为 EOF（原管道已关闭），需重定向到终端支持交互 |

---

## 5. 下一步工作

### 已完成

1. ✅ **Lite/Full 双模式实现完成**（2026-07-24）
   - **新增** `scripts/base/mode.sh` 模块注册表
   - **install.sh 改造**：解析 `--lite` 参数，菜单/向导/状态按模式过滤
   - **Lite 模块**：SSH + Firewall + Kernel（零/极低内存开销）
   - **Full 独占**：Fail2Ban / Audit / Users / Filesystem / Services / K3s
   - **i18n**：新增 11 个模式相关键
   - **测试**：13 个 mode.bats 单元测试

2. ✅ **Round 5 分模块 Code Review 已完成**（详见 `docs/code-reviews/round-5-comprehensive.md`）
3. ✅ **修复 Code Review 发现的全部 32 个 bug**
4. ✅ **交互式重构完成**：删除一键模式
5. ✅ **Docker Phase 1 测试框架完成**（72/72）
6. ✅ **Docker Phase 2 基础设施完成**（21/21）

### 接下来要做

1. ✅ **Lite/Full 双模式** — 已完成
2. **PRD 中未实现的补充功能**（优先级排序）：
   - **基础工具扩充**（htop/net-tools/lsof/tree/git）— 低难度
   - **独立 backup.sh/rollback.sh** 提取 — 中难度
   - **自动安全更新**（unattended-upgrades/yum-cron）— 中难度
   - **NTP 时间同步** — 低难度
   - **Swap 文件配置** — 低难度
   - **AIDE / ClamAV / Rootkit 检测** — 高难度
3. **发行版验证**：RHEL 7+ / Fedora Docker 测试

### 实现顺序建议

```
v0.1 ✅ 已完成
├── scripts/base/utils.sh       ✅
├── scripts/base/detect.sh      ✅
├── scripts/base/init.sh        ✅
├── scripts/base/report.sh      ✅
├── scripts/security/ssh.sh     ✅
├── scripts/lang/zh.sh          ✅
├── scripts/lang/en.sh          ✅
├── tests/unit/utils.bats       ✅
└── install.sh                  ✅

v0.2 ✅ 已完成 + Bug 全部修复
├── scripts/security/firewall.sh ✅
├── scripts/security/fail2ban.sh ✅
└── tests/unit/ssh.bats         ✅

v0.3 (第三周)
├── scripts/security/kernel.sh
├── scripts/security/filesystem.sh
└── 用户创建功能

v0.4 ✅ 已完成
├── scripts/security/audit.sh       ✅ (44 个测试用例)
├── scripts/security/services.sh    ✅ (35 个测试用例)
├── scripts/utils/report.sh         ✅ (已移至 scripts/base/report.sh)
└── scripts/utils/backup.sh / rollback.sh ⬜
```

---

## 6. 注意事项

### 开发规范

详见 [`CONTRIBUTING.md`](CONTRIBUTING.md) 的代码规范章节。

快速摘要：首行 `#!/usr/bin/env bash` + `set -euo pipefail`；函数 `snake_case`，常量 `UPPER_SNAKE_CASE`；使用 `utils.sh` 的 `log_*` 函数；修改前备份原文件。

### SSH 安全的特殊考虑

- **修改 SSH 端口前**必须确保新端口没有被占用
- **禁止密码登录前**必须确保密钥已正确配置
- **禁止 root 登录前**必须确保有 sudo 用户
- 建议实现"安全回滚定时器"：配置修改后 5 分钟内无新连接则自动回滚

### 测试

详见 [`CONTRIBUTING.md`](CONTRIBUTING.md) 的测试章节。

快速摘要：ShellCheck 静态检查 + Bats 单元测试 + Docker Phase 1/2。

---

## 7. 参考资料

| 资源 | 路径/链接 |
|------|-----------|
| PRD 需求文档 | `docs/design/linux-security-hardening-prd.md` |
| 项目指令 | `.claude/CLAUDE.md` |
| ECC 配置参考 | `everything-claude-code/` 目录 |
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks |
| OpenSSH 文档 | https://man.openbsd.org/sshd_config |

---


## 8. 变更日志

> 仅保留近期变更。2026-06-20~24 的 176 条历史记录已归档至 [`docs/handover-archive.md`](../docs/handover-archive.md)。

| 日期 | 操作 | 文件 |
|------|------|------|
| 2026-07-12 | CREATE | `scripts/server/k3s.sh` | K3s 安装/卸载/状态检查模块（17 个 Bats 测试） |
| 2026-07-12 | UPDATE | `scripts/lang/zh.sh` | 新增 28 个 K3s i18n 中文键 + 子菜单 + 主菜单 + 分组标题 |
| 2026-07-12 | UPDATE | `scripts/lang/en.sh` | 新增 28 个 K3s i18n 英文键 + 子菜单 + 主菜单 + 分组标题 |
| 2026-07-12 | UPDATE | `install.sh` | K3s 菜单加载 + 主菜单第 4 分组 + option 12 路由 |
| 2026-07-12 | CREATE | `tests/unit/k3s.bats` | 17 个 Bats 测试：函数存在、i18n 键、常量、root 检查、子菜单、英文键 |
| 2026-07-12 | UPDATE | `HANDOVER.md` | 新增 K3s 模块到文件清单/进度/变更日志 |
|------|------|------|
| 2026-07-12 | CREATE | `docs/plans/2026-07-12_15-58_round-4-fixes_nogit.md` | Round 4 修复计划 |
| 2026-07-12 | FIX | `scripts/security/ssh.sh` | C1 SSH at timer + M5 ~25 i18n + M9 order |
| 2026-07-12 | FIX | `scripts/security/firewall.sh` | C2 UFW locale + H6 return check + M6-M8 |
| 2026-07-12 | FIX | `tests/unit/firewall.bats`, `tests/unit/fail2ban.bats` | C3-C4 remove fake mock tests |
| 2026-07-12 | FIX | `scripts/base/init.sh` | H1 source guard + H3 apt-get protection |
| 2026-07-12 | FIX | `scripts/base/report.sh` | H2 source guard + M4 i18n + nested func |
| 2026-07-12 | FIX | `install.sh` | H4 GREEN dead code + M13-M17 i18n+default case |
| 2026-07-12 | FIX | `scripts/security/fail2ban.sh` | H5 i18n + H7 dnf fallback |
| 2026-07-12 | FIX | `scripts/security/audit.sh` | H13 ausearch + M33 i18n |
| 2026-07-12 | FIX | `config/audit/audit.rules` | H14+H15 execve + b32 variants |
| 2026-07-12 | FIX | `scripts/base/utils.sh` | M1-M3 DRY/日志/sed |
| 2026-07-12 | FIX | `scripts/security/filesystem.sh` | M10 tempfile + L2 /proc guard |
| 2026-07-12 | FIX | `scripts/security/services.sh` | M11 disable verify + M32 IPv6 |
| 2026-07-12 | FIX | `scripts/security/users.sh`, `scripts/security/kernel.sh` | M12+M31 i18n |
| 2026-07-12 | UPDATE | `scripts/lang/zh.sh`, `scripts/lang/en.sh` | M18 63 unused keys removed + i18n keys add |
| 2026-07-12 | FIX | `tests/unit/*.bats` (multiple) | M20-M26 + test isolation cleanup |
| 2026-07-12 | FIX | `config/fail2ban/jail.local` | M27 reference notice + M28 IPv6 |
| 2026-07-12 | FIX | `scripts/dev/gen-file-tree.sh` | M29 eval removal + M30 tree symbols |
| 2026-07-12 | FIX | `scripts/base/detect.sh` | L1 detect_arch error return |
| 2026-07-12 | UPDATE | `HANDOVER.md`, plan files | Round 4 全部 88 问题修复完成 |

| 日期 | 操作 | 文件 |
|------|------|------|
| 2026-06-25 | CREATE | `.claude/reviews/false-success-bug-audit-20260625.md`
| 2026-06-25 | UPDATE | `scripts/base/utils.sh`
| 2026-06-25 | UPDATE | `scripts/security/ssh.sh`
| 2026-06-25 | UPDATE | `scripts/security/fail2ban.sh`
| 2026-06-25 | UPDATE | `scripts/security/audit.sh`
| 2026-06-25 | UPDATE | `scripts/base/init.sh`
| 2026-06-25 | UPDATE | `scripts/security/kernel.sh`
| 2026-06-25 | UPDATE | `scripts/security/users.sh`
| 2026-06-25 | UPDATE | `scripts/security/firewall.sh`
| 2026-06-25 | UPDATE | `scripts/security/filesystem.sh`
| 2026-06-25 | UPDATE | `HANDOVER.md`
| 2026-06-26 | UPDATE | `scripts/security/firewall.sh`
| 2026-06-26 | UPDATE | `scripts/base/init.sh`
| 2026-06-26 | UPDATE | `scripts/base/utils.sh`
| 2026-06-26 | UPDATE | `scripts/base/detect.sh`
| 2026-06-26 | UPDATE | `install.sh`
| 2026-06-26 | UPDATE | `scripts/security/ssh.sh`
| 2026-06-26 | UPDATE | `scripts/security/users.sh`
| 2026-06-26 | UPDATE | `scripts/security/fail2ban.sh`
| 2026-06-26 | UPDATE | `scripts/security/audit.sh`
| 2026-06-26 | UPDATE | `review/bug-review-comprehensive.md`
| 2026-06-26 | UPDATE | `scripts/security/ssh.sh`
| 2026-06-26 | UPDATE | `review/bug-review-comprehensive.md`
| 2026-06-26 | UPDATE | `HANDOVER.md`
| 2026-06-26 | UPDATE | `scripts/base/utils.sh`
| 2026-06-26 | UPDATE | `scripts/security/fail2ban.sh`
| 2026-06-26 | UPDATE | `scripts/security/filesystem.sh`
| 2026-06-26 | UPDATE | `install.sh`
| 2026-06-26 | UPDATE | `review/bug-review-comprehensive.md`
| 2026-07-10 | CREATE | `docs/plans/`
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md`
| 2026-07-10 | UPDATE | `HANDOVER.md`
| 2026-07-10 | CREATE | `docs/plans/README.md`
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md`
| 2026-07-10 | UPDATE | `HANDOVER.md`
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md`
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md`
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md`
| 2026-07-10 | UPDATE | `HANDOVER.md`
| 2026-07-10 | CREATE | `docs/handover-archive.md` | 历史变更日志归档（176 条，2026-06-20~24） |
| 2026-07-10 | UPDATE | `HANDOVER.md` | 变更日志精简：归档 176 条 + 列精简（去说明列），保留 39 条 |
| 2026-07-10 | UPDATE | `HANDOVER.md` | 删除重复节"已完成的工作"（-66 行） |
| 2026-07-10 | CREATE | `scripts/dev/gen-file-tree.sh` | 自动生成文件树脚本，输出 docs/file-tree.generated.md |
| 2026-07-10 | UPDATE | `.gitignore` | 忽略 docs/file-tree.generated.md + .superpowers/ |
| 2026-07-10 | UPDATE | `HANDOVER.md` | 文件清单改为脚本引用 + 顶层目录概览表（-151 行） |
| 2026-07-10 | FIX | `.claude/settings.local.json` | 修复 JSON 语法错误：补 `permissions` 与 `env` 之间的缺逗号（Claude Code 启动校验） |
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md` | 项目结构章节同步新增 docs/handover-archive.md、docs/file-tree.generated.md、scripts/dev/ |
| 2026-07-10 | CREATE | `docs/design/archive/2026-07-10-design-doc-archive-design.md` | 设计文档归档规范设计（原 docs/superpowers/specs/） |
| 2026-07-10 | CREATE | `docs/design/archive/2026-07-10-design-doc-archive.md` | 设计文档归档实施计划（原 docs/superpowers/plans/） |
| 2026-07-10 | CREATE | `docs/design/archive/` | 新建 archive 子目录 |
| 2026-07-10 | UPDATE | `docs/design/README.md` | 重写为分层状态索引（active/proposed/archived） |
| 2026-07-10 | UPDATE | `docs/design/linux-security-hardening-prd.md` | + frontmatter status=active |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-prd.md` | + frontmatter status=proposed |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-plan.md` | + frontmatter status=proposed |
| 2026-07-10 | UPDATE | `docs/design/archive/interactive-setup-spec.md` | + frontmatter status=archived, git mv 入 archive |
| 2026-07-10 | UPDATE | `docs/design/archive/interactive-setup-plan.md` | + frontmatter status=archived, git mv 入 archive |
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md` | 项目结构章节 +1 行（design/archive 子目录注释） |
| 2026-07-10 | CREATE | `docs/design/main-menu-redesign-v2.md` | 主菜单重构 v2（合并 PRD+Plan 为单一文档，覆盖 v0.4 现状 + v1.0 理想，10 个 GAP，7 个 Tasks） |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-prd.md` | → archived + superseded-by v2 + 顶部 added superseded notice |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-plan.md` | → archived + superseded-by v2 + 顶部 added superseded notice |
| 2026-07-10 | CREATE | `docs/plans/2026-07-10_16-00_main-menu-redesign-v2_nogit.md` | writing-plans 实施计划（7 任务，按 spec §5 推荐顺序） |
| 2026-07-10 | CREATE | `tests/unit/menu.bats` | i18n 键 smoke tests（10 cases） |
| 2026-07-10 | UPDATE | `scripts/lang/zh.sh` | +81 行（5 段新键：分组/状态/补全/子菜单/历史/错误） |
| 2026-07-10 | UPDATE | `scripts/lang/en.sh` | +81 行（与 zh.sh 镜像） |
| 2026-07-10 | UPDATE | `install.sh` | +6 show_xxx_submenu + 6 run_xxx_submenu_loop 函数（约 +240 行） |
| 2026-07-10 | UPDATE | `install.sh` | run_main_menu_loop case 4-9 改为子菜单壳 |
| 2026-07-10 | UPDATE | `install.sh` | show_main_menu 加 3 组分隔线 + SSH 端口状态摘要 |
| 2026-07-10 | UPDATE | `install.sh`, `tests/unit/system-status.bats` | T3: 状态检测升级（评分 + 颜色 + 表格 + 建议） |
| 2026-07-10 | UPDATE | `install.sh`, `lang/*`, `tests/unit/view-report.bats` | T4: view_report 升级（历史列表 + 相对时间） |
| 2026-07-10 | UPDATE | `install.sh`, `lang/*`, `tests/unit/menu.bats` | T5: 移除全部 `:-` i18n 兜底 |
| 2026-07-10 | UPDATE | `install.sh`, `tests/unit/parse-args.bats` | T6: 移除参数错误精简为 i18n 2 行 |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-v2.md` | T7: status proposed → active, 进度记录补全 |
| 2026-07-11 | CREATE | `docs/plans/2026-07-11_13-00_full-code-review-n4_nogit.md` | Code Review Round 4 计划文件（6 组并行审查方案） |
| 2026-07-11 | CREATE | `docs/code-reviews/round-4-comprehensive.md` | Round 4 综合报告：4 CRITICAL + 22 HIGH + 41 MEDIUM + 21 LOW |
| 2026-07-11 | UPDATE | `HANDOVER.md` | 更新最后更新日期、进度表、已完成工作、下一步工作 |
| 2026-07-12 | DELETE | `.claude/prds/` | 删除重复 PRD（已存在 docs/design/） |
| 2026-07-12 | MIGRATE | `.claude/plans/` → `docs/plans/` | 4 个旧计划文件按规范重命名并迁移到 docs/plans/ |
| 2026-07-12 | DELETE | `.claude/plans/main-menu-redesign.plan.md` | 已存在于 docs/design/main-menu-redesign-plan.md |
| 2026-07-12 | MIGRATE | `docs/superpowers/` → `docs/design/archive/` | 设计文档归档相关的 spec+plan 移入 design archive |
| 2026-07-12 | UPDATE | `docs/README.md` | 重写为统一文档索引（含 plans/ 目录） |
| 2026-07-12 | UPDATE | `docs/design/README.md` | 归档区新增 2 条 superpowers 迁移条目 |
| 2026-07-12 | UPDATE | `docs/code-reviews/README.md` | 新增 round-4-comprehensive.md 条目 |
| 2026-07-12 | UPDATE | `HANDOVER.md` | 旧路径引用更新（.claude/prds/ → docs/design/）|
| 2026-07-12 | FIX | `config/audit/audit.rules` | H14+H15: 补 execve 规则 + 补 b32 架构变体，与 audit.sh _generate_full_rules() 同步 |
| 2026-07-12 | UPDATE | `scripts/lang/zh.sh`, `scripts/lang/en.sh` | M18: 移除 63 个未引用 MSG_* 键；M19: 修复向导步骤 [10/10] → [9/10] |
| 2026-07-12 | UPDATE | `HANDOVER.md` | Round 4 MEDIUM 修复进度同步 |
| 2026-07-12 | FIX | `scripts/base/detect.sh` | L1: detect_arch 未知架构返回 1，设 DETECTED_ARCH="unknown" |
| 2026-07-12 | FIX | `scripts/security/filesystem.sh` | L2: audit_suid_sgid/check_orphan_files/check_filesystem_status 添加 /proc guard |
| 2026-07-12 | FIX | `scripts/base/report.sh` | L3: 将 _report_task_line 从 generate_report 内移出为顶层函数，消除嵌套泄露 |
| 2026-07-12 | CREATE | `tests/docker/` | Docker Phase 1 测试框架：common.bash、run-test.sh、test-all.sh、8 个模块测试脚本、9 个 Dockerfile |
| 2026-07-12 | CREATE | `docs/docker-test-debug-log.md` | 调试日志：12 个已修复问题 + 方法论 + 覆盖率矩阵 |
| 2026-07-12 | UPDATE | `docs/docker-test-debug-log.md` | 填充测试覆盖率矩阵：72/72 全部通过 |
| 2026-07-12 | UPDATE | `HANDOVER.md` | Phase 1 状态更新：72/72 全部通过，Phase 1 ✅ → Phase 2 ⬜ |
| 2026-07-12 | UPDATE | `README.md` | 重写为 v1.0-alpha 就绪版本：新增特性清单、测试覆盖矩阵、文档索引、系统要求状态更新 |
| 2026-07-12 | CREATE | `.github/workflows/test.yml` | GitHub Actions CI 配置：ShellCheck + Bats + Docker Phase 1 |
| 2026-07-12 | CREATE | `RELEASE_CHECKLIST.md` | v1.0 发布检查清单（代码质量、功能验证、跨发行版、文档、自动化） |
| 2026-07-12 | CREATE | `tests/docker/images/ubuntu/22.04.phase2.Dockerfile` | Phase 2 特权容器镜像（Ubuntu 22.04）：添加 openssh-client, nmap, ufw, procps, iproute2 |
| 2026-07-12 | CREATE | `tests/docker/images/centos/7.phase2.Dockerfile` | Phase 2 特权容器镜像（CentOS 7）：添加 openssh-clients, nmap, nmap-ncat, procps-ng |
| 2026-07-12 | CREATE | `tests/docker/images/debian/12.phase2.Dockerfile` | Phase 2 特权容器镜像（Debian 12）：添加 openssh-client, nmap, ufw, procps, iproute2 |
| 2026-07-12 | UPDATE | `tests/docker/lib/common.bash` | 新增 Phase 2 函数：start_privileged_container / exec_in_privileged_container / stop_privileged_container；build_image 支持 phase 参数 |
| 2026-07-12 | UPDATE | `tests/docker/run-test.sh` | 新增 --phase 参数支持，Phase 2 使用 phase2 Dockerfiles + tests/phase2/ 目录 |
| 2026-07-12 | UPDATE | `tests/docker/test-all.sh` | 填充 PHASE2_DISTROS（3 个）+ PHASE2_MODULES（7 个），build_image/test 路径 phase-aware |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/ssh.bash` | Phase 2 SSH 服务验证：配置、启动 sshd、端口监听、本地连接、banner 检测 |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/firewall.bash` | Phase 2 防火墙服务验证：UFW 启用/规则/状态（Ubuntu/Debian），firewalld（CentOS） |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/fail2ban.bash` | Phase 2 Fail2Ban 服务验证：安装、配置 jail、启动服务、client status |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/audit.bash` | Phase 2 Auditd 服务验证：安装、生成规则、加载规则、auditctl -l 验证 |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/users.bash` | Phase 2 用户 SSH 登录验证：创建用户、SSH 密钥、authorized_keys、key-based 登录 |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/security-check.bash` | Phase 2 安全扫描验证：nmap 端口扫描、SSH 算法枚举、cipher 列表查询 |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/rollback.bash` | Phase 2 回滚验证：SHA256 记录、备份、修改、恢复、SHA256 比对 |
| 2026-07-12 | FIX | `tests/docker/lib/common.bash` | Phase 2: build_image stdout leak in start_privileged_container (container name corrupted) |
| 2026-07-12 | FIX | `tests/docker/tests/phase2/ssh.bash` | Phase 2: SSH root login + host keys missing on CentOS 7; service restart compat |
| 2026-07-12 | FIX | `tests/docker/images/centos/7.phase2.Dockerfile` | Phase 2: add initscripts + pre-generate SSH host keys for CentOS 7 |
| 2026-07-12 | FIX | `tests/docker/tests/phase2/firewall.bash` | Phase 2: firewalld D-Bus detection + remove unsupported --pid-file flag |
| 2026-07-12 | FIX | `tests/docker/lib/common.bash` | Phase 2: strip ANSI escape codes in report generation |
| 2026-07-12 | FIX | `tests/docker/test-all.sh` | Phase 2: strip ANSI codes in detail extraction for .result files |
| 2026-07-12 | PASS | `test-all.sh --phase 2` | Phase 2 完整矩阵：3 distros x 7 modules = **21/21 全部通过** |
|------|------|------|
| 2026-07-13 | FIX | `scripts/base/detect.sh` | SC2317: 移除 `return 0` 后冗余的 `\|\| true` |
| 2026-07-13 | FIX | `scripts/base/init.sh` | SC2120/SC2119: `setup_timezone` 显式传参 |
| 2026-07-13 | FIX | `scripts/base/utils.sh` | SC2002: `cat \| tr` 改为 `tr < file` 重定向 |
| 2026-07-13 | FIX | `scripts/security/fail2ban.sh` | SC2034: 恢复 `SSH_SERVICE_NAME` 并加 disable 注释 |
| 2026-07-13 | FIX | `scripts/security/kernel.sh` | SC2012: `ls -t` 替换为 `find -printf` |
| 2026-07-13 | FIX | `install.sh` | SC2059 + SC2012: printf 格式修复 + `ls` 替换为 `find` |
| 2026-07-13 | UPDATE | `.github/workflows/test.yml` | 新增 Docker Phase 2 job（3 distros × 7 modules）|
| 2026-07-13 | CREATE | `.github/workflows/markdown-lint.yml` | Markdown 格式检查 workflow |
| 2026-07-13 | CREATE | `.github/workflows/codeql.yml` | CodeQL 安全扫描 workflow（每周日自动）|
| 2026-07-13 | PASS | CI Test workflow | **全部 4 job 首次通过 ✅**（ShellCheck + Bats + Phase 1 + Phase 2）
| 2026-07-21 | REWRITE | `.claude/CLAUDE.md` | 文档规范化：364→90 行，移除重复内容，精简为 agent 入职指南 |
| 2026-07-21 | CREATE | `CONTRIBUTING.md` | 新建贡献指南（TDD/Git 工作流/ECC/代码规范） |
| 2026-07-21 | CREATE | `LICENSE` | 新建 MIT 开源许可证 |
| 2026-07-21 | MOVE | `review/` → `docs/code-reviews/` | `review/bug-review-comprehensive.md` 移入 code-reviews 归档 |
| 2026-07-21 | DELETE | `review/` | 空目录删除 |
| 2026-07-21 | MOVE | `RELEASE_CHECKLIST.md` → `docs/release-checklist.md` | 发布检查清单归入 docs/ |
| 2026-07-21 | MOVE | `docs/docker-test-debug-log.md` → `tests/docker-test-debug-log.md` | 测试调试日志归入 tests/ |
| 2026-07-21 | UPDATE | `README.md` | 移除开发指南→引用 CONTRIBUTING.md；更新文件引用路径 |
| 2026-07-21 | UPDATE | `HANDOVER.md` | 更新文件清单、引用路径、变更日志 |
| 2026-07-21 | UPDATE | `docs/README.md` | 更新引用路径 |
| 2026-07-21 | CREATE | `docs/plans/2026-07-21_14-00_docs-consolidation_nogit.md` | 文档规范化计划文件 |
|------|------|------|
| 2026-07-15 | CREATE | `docs/plans/2026-07-15_10-30_full-code-review-n5_nogit.md` | Round 5 分模块 Code Review 计划（6 组并行审查方案）|
| 2026-07-15 | CREATE | `docs/code-reviews/round-5-comprehensive.md` | Round 5 综合报告：**115 个发现（0 CRITICAL + 20 HIGH + 46 MEDIUM + 49 LOW）** |
| 2026-07-15 | REVIEW | 全部脚本 | 6 组并行审查完成：A-基础框架(20) / B-SSH+防火墙(19) / C-系统加固(16) / D-审计+服务+K3s(13) / E-主入口+语言(21) / F-测试+配置+CI(26) |
| 2026-07-15 | FIX | `docs/code-reviews/round-5-comprehensive.md` | 修正 11 处行号/描述/表格问题（SubAgent 验证后修复）||
|------|------|------|
| 2026-07-21 | CREATE | `docs/code-reviews/2026-07-21_full-project-security-audit.md` | 全项目代码审查 + 安全审计（4 agent 并行）：0 CRITICAL + 7 HIGH + 19 MEDIUM + 13 LOW |
| 2026-07-21 | FIX | `docs/code-reviews/2026-07-21_full-project-security-audit.md` | 修复 install.sh HIGH 计数（7→5） |
| 2026-07-21 | FIX | `scripts/base/utils.sh` | H1: schedule_rollback() 添加 disown，_cleanup_on_exit 不杀回滚 PID |
| 2026-07-21 | FIX | `install.sh` | H3: curl 管道检测后添加 set -u；M10: curl 添加 --connect-timeout/--max-time；M11: mktemp 后添加 INT/TERM trap |
| 2026-07-21 | FIX | `scripts/security/ssh.sh` | M1: passphrase 泄露修复（-N 参数改为 SSH_ASKPASS 回退链）|
| 2026-07-21 | FIX | `scripts/security/filesystem.sh` | M2: RHEL 系 /etc/shadow 权限改为 000 |
| 2026-07-21 | FIX | `tests/unit/filesystem.bats` | 适配条件化 CRITICAL_FILES 数组 |
| 2026-07-21 | FIX | `scripts/lang/zh.sh`, `scripts/lang/en.sh` | M4: ufw 硬编码消息改为双后端提示 |
| 2026-07-21 | FIX | `scripts/security/fail2ban.sh` | M6: ignoreip 添加 ::1 |
| 2026-07-21 | FIX | `config/sysctl/hardening.conf` | M8: 添加 5 个遗漏 CIS 参数（arp_ignore/announce, bpf_disabled, kexec, perf_paranoid）|
| 2026-07-21 | FIX | `config/audit/auditd.conf` | M12: flush 改为 DATA（CIS Level 2 / STIG 推荐）|
| 2026-07-21 | PASS | `bats tests/unit/*.bats` | **259/259 全部通过** ✅ |
| 2026-07-21 | RELEASE | `v1.0.1` | 补丁发布：全项目安全审计修复（10 项）+ 文档规范化 + Round 5 Review 修正 |
|------|------|------|
| 2026-07-24 | CREATE | `docs/design/lite-vs-full-mode.md` | Lite/Full 双模式设计文档 |
| 2026-07-24 | CREATE | `scripts/base/mode.sh` | 模块注册表：定义 Lite/Full 模块集合 |
| 2026-07-24 | UPDATE | `scripts/lang/zh.sh` | 新增 11 个模式相关 i18n 键 |
| 2026-07-24 | UPDATE | `scripts/lang/en.sh` | 新增 11 个模式相关 i18n 键 |
| 2026-07-24 | UPDATE | `install.sh` | 解析 --lite 参数；菜单/向导/状态按模式过滤 |
| 2026-07-24 | UPDATE | `README.md` | 新增 Lite/Full 双模式文档 |
| 2026-07-24 | UPDATE | `HANDOVER.md` | 变更日志，进度表更新 |
| 2026-07-24 | CREATE | `tests/unit/mode.bats` | 13 个模式模块单元测试 |

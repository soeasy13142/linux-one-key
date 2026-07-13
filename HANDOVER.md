# 项目交接文档

> **⚠️ 强制规则**：每次修改项目时，必须同步更新本文档。详见 `.claude/rules/common/handover.md`。

**最后更新**: 2026-07-13（CI 全面通过 ✅ + 新增 3 个 Workflow）
**当前阶段**: v1.0 最终冲刺全部完成 🎉 → CI 全部绿色 ✅

> **新增**: K3s (Lightweight Kubernetes) 安装模块已实现（`scripts/server/k3s.sh`）

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

### 总体状态：🟢 v0.4 全部模块完成 + 主菜单重构 v2 已实施

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

---


## 3. 文件清单

> 📋 **详细文件树由 [`scripts/dev/gen-file-tree.sh`](../../scripts/dev/gen-file-tree.sh) 自动生成**，输出到 `docs/file-tree.generated.md`（gitignored，避免过期）。
> 重新生成：`bash scripts/dev/gen-file-tree.sh`

### 顶层目录概览

| 目录/文件 | 用途 |
|---|---|
| `install.sh` | 主入口脚本（菜单、交互流程、curl 管道支持） |
| `README.md` | 项目说明 |
| `HANDOVER.md` | 本文件（强制交接文档） |
| `CLAUDE.md` | Claude Code 项目指令（在 `.claude/CLAUDE.md`） |
| `scripts/base/` | 基础环境（utils.sh, detect.sh, init.sh, report.sh） |
| `scripts/security/` | 安全加固模块（ssh/firewall/fail2ban/audit/users/kernel/filesystem/services） |
| `scripts/server/` | 服务器软件安装模块（k3s.sh） |
| `scripts/lang/` | i18n 文件（zh.sh, en.sh） |
| `scripts/dev/` | 开发工具脚本（如 gen-file-tree.sh） |
| `tests/docker/` | Docker 自动化测试框架（Phase 1: 配置验证，Phase 2: 服务验证） |
| `tests/unit/` | Bats 单元测试（utils/firewall/fail2ban/ssh/audit/users/kernel/filesystem/services） |
| `config/` | 配置文件模板（fail2ban/, audit/, sysctl/） |
| `docs/code-reviews/` | Code Review 报告归档 |
| `docs/test-reports/` | 测试报告归档 |
| `docs/design/` | 设计文档 & 实施计划 |
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

1. ✅ **修复 Code Review 发现的全部 32 个 bug**（详见 `docs/bug-review-report.md`）
   - **第一批（阻断性）**: C1 变量名不匹配、C2 正则无边界、H2 banaction 硬编码
   - **第二批（逻辑错误）**: H1 回滚定时器、H4 临时目录清理、H6 报告生成
   - **第三批（安全加固）**: M1 eval 注入、H5 完整性校验、H3 set -u 一致性、H7 os-release 污染
   - **第四批（MEDIUM）**: M2-M14
   - **第五批（LOW）**: L1-L9

2. ✅ **交互式重构完成**：删除一键模式（--yes/--quick），改为逐步交互式向导配置

3. ✅ **Docker Phase 1 测试框架完成**（2026-07-12）
   - **架构**：单容器执行模式 + Sentinel Marker 断言机制
   - **9 个 Docker 镜像**：Ubuntu 20.04/22.04/24.04, Debian 11/12, CentOS 7, Rocky 8/9, Alma 9
   - **8 个模块**：SSH / Kernel / Services / Users / Fail2Ban / Audit / Firewall / Filesystem
   - **72/72 全部通过**
   - **已修复 12 个调试问题**：子 Shell 变量丢失、容器状态丢失、RHEL 包冲突、CentOS 7 EOL 等
   - **调试日志**：`docs/docker-test-debug-log.md`

4. ✅ **Docker Phase 2 基础设施完成**（2026-07-12）
   - **架构**：特权容器 + 后台运行 + docker exec 模式
   - **3 个 Phase 2 Dockerfile**：Ubuntu 22.04 / CentOS 7 / Debian 12
   - **7 个服务验证测试脚本**：SSH / Firewall / Fail2Ban / Audit / Users / Security-Check / Rollback
   - **新增 common.bash 函数**：start_privileged_container / exec_in_privileged_container / stop_privileged_container
   - **run-test.sh / test-all.sh 升级**：支持 --phase 1|2 切换

### 接下来要做

1. ✅ **Phase 2 实际运行验证完成** — 21/21 全部通过（见下方 Phase 2 修复记录）
2. **📋 v1.0 收尾**：文档完善、正式发布、CI 集成

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

### 开发规范（来自 CLAUDE.md）

- 首行 `#!/usr/bin/env bash`，紧跟 `set -euo pipefail`
- 函数命名 `snake_case`，常量 `UPPER_SNAKE_CASE`
- 每个函数必须有注释说明用途
- 输出用颜色区分：绿=成功，红=错误，黄=警告，蓝=信息
- 每个修改操作前备份原文件

### SSH 安全的特殊考虑

- **修改 SSH 端口前**必须确保新端口没有被占用
- **禁止密码登录前**必须确保密钥已正确配置
- **禁止 root 登录前**必须确保有 sudo 用户
- 建议实现"安全回滚定时器"：配置修改后 5 分钟内无新连接则自动回滚

### 测试

- 使用 ShellCheck 静态检查：`shellcheck -x scripts/**/*.sh`
- 使用 Bats 单元测试
- 目标覆盖率 80%+

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
| 2026-07-13 | PASS | CI Test workflow | **全部 4 job 首次通过 ✅**（ShellCheck + Bats + Phase 1 + Phase 2）|

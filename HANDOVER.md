# 项目交接文档

> **⚠️ 强制规则**：每次修改项目时，必须同步更新本文档。详见 `.claude/rules/common/handover.md`。

**最后更新**: 2026-07-10（CLAUDE.md 规范化：迁移 my_obsidian 4 项核心原则）
**当前阶段**: v0.4 全部模块已完成（2026-06-24）→ 项目规范化阶段

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

### 总体状态：🟢 v0.3 用户管理+内核加固+文件系统安全已完成

| 阶段 | 状态 | 说明 |
|------|------|------|
| 需求分析 | ✅ 完成 | PRD 已编写，见 `.claude/prds/linux-security-hardening.prd.md` |
| 架构设计 | ✅ 完成 | 交互模式、i18n、日志、备份等技术决策已确定 |
| v0.1 基础框架 + SSH 安全 | ✅ 完成 | utils.sh, detect.sh, init.sh, ssh.sh, install.sh, 语言文件, 测试 |
| v0.2 防火墙 + Fail2Ban | ✅ 完成 | firewall.sh, fail2ban.sh, 语言文件更新, 菜单集成, 单元测试 |
| Code Review (Round 1) | ✅ 完成 | 全面审查发现 2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW bug |
| Code Review (Round 2) | ✅ 完成 | 3 代理并行审查，发现 10 CRITICAL + 15 HIGH + 13 MEDIUM + 12 LOW，共 50 个问题 |
| Code Review (Round 3) | ✅ 完成 | 0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW；全部已修复（含 H2、L4） |
| v0.3 用户管理 + 内核加固 + 文件系统 | ✅ 完成 | users.sh, kernel.sh, filesystem.sh, sysctl 模板, i18n, 测试 76 个用例 |
| v0.4 审计日志模块 | ✅ 完成 | audit.sh, audit.bats, config/audit/, i18n 更新, 菜单集成, 44 个测试用例 |
| v0.4 服务管理 | ✅ 完成 | services.sh, services.bats, i18n 更新, 菜单集成, 35 个测试用例 |
| v1.0 测试 + 文档 + 发布 | ⬜ 未开始 | |

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
| `scripts/lang/` | i18n 文件（zh.sh, en.sh） |
| `scripts/dev/` | 开发工具脚本（如 gen-file-tree.sh） |
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
   - `generate_random_port()` 随机端口生成
   - SSH 端口 3 选 1（自定义/随机/保持），每参数逐步提示
   - Fail2Ban 参数可自定义（封禁时间/重试次数/检测窗口）
   - 统一函数命名：`run_ssh_wizard` / `run_firewall_wizard` / `run_fail2ban_wizard`

3. ✅ **VM 综合测试（curl 方式）**：15 个测试用例，发现 8 个新问题（详见 `docs/vm-test-report-20260620.md`）
   - Issue #2 (HIGH): `generate_report()` 报告硬编码，与实际执行结果不一致 → ✅ 已修复
   - Issue #4 (MEDIUM): 非 TTY curl pipe 模式无限循环 → ✅ 已修复
   - Issue #6 (MEDIUM): 非 root 用户执行日志 Permission denied
   - Issue #8 (HIGH): Bats 测试 27/46 失败，模块依赖加载顺序问题 → ✅ 已修复

4. ✅ **Code Review Round 3 部分修复**（2026-06-23，详见 `docs/code-review-handover-20260623.md`）
   - ✅ H1: `_parse_args` 移入 `main()` 解决颜色变量未初始化
   - ✅ H3: `report.sh` 3 处硬编码中文替换为 i18n 变量
   - ✅ M1: `_ENSURING_LOG_DIR` 移除 `export`
   - ✅ M2: 创建 `tests/unit/ssh.bats`（16 个测试用例）
   - ✅ M3: `fail2ban.sh` sleep 2 改为轮询等待（最多 10 秒）
   - ✅ M4: `schedule_rollback` 添加安全约束注释
   - ✅ L1: `firewall.sh` 统一引号风格
   - ✅ L2: `_get_ssh_service_name` 替换为 `SSH_SERVICE_NAME` 常量
   - ✅ L3: 移除 `install.sh` 残留 `:` 占位符

### 接下来要做

1. **📋 验证其他发行版**：在 CentOS/Debian VM 中运行完整向导流程
   - SSH 端口交互逻辑
   - Fail2Ban 参数验证
2. **E2E 测试**：在 Docker 容器中各发行版验证
3. **开始 v1.0**：完整测试、文档、正式发布

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
| PRD 需求文档 | `.claude/prds/linux-security-hardening.prd.md` |
| 项目指令 | `.claude/CLAUDE.md` |
| ECC 配置参考 | `everything-claude-code/` 目录 |
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks |
| OpenSSH 文档 | https://man.openbsd.org/sshd_config |

---


## 8. 变更日志

> 仅保留近期变更。2026-06-20~24 的 176 条历史记录已归档至 [`docs/handover-archive.md`](../docs/handover-archive.md)。

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
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md` | 项目结构章节同步新增 docs/handover-archive.md、docs/file-tree.generated.md、scripts/dev/ |
| 2026-07-10 | CREATE | `docs/superpowers/specs/2026-07-10-design-doc-archive-design.md` | Brainstorming 设计规范（docs/design/ 归档重构） |
| 2026-07-10 | CREATE | `docs/superpowers/plans/2026-07-10-design-doc-archive.md` | writing-plans 实施计划（4 任务） |
| 2026-07-10 | CREATE | `docs/design/archive/` | 新建 archive 子目录 |
| 2026-07-10 | UPDATE | `docs/design/README.md` | 重写为分层状态索引（active/proposed/archived） |
| 2026-07-10 | UPDATE | `docs/design/linux-security-hardening-prd.md` | + frontmatter status=active |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-prd.md` | + frontmatter status=proposed |
| 2026-07-10 | UPDATE | `docs/design/main-menu-redesign-plan.md` | + frontmatter status=proposed |
| 2026-07-10 | UPDATE | `docs/design/archive/interactive-setup-spec.md` | + frontmatter status=archived, git mv 入 archive |
| 2026-07-10 | UPDATE | `docs/design/archive/interactive-setup-plan.md` | + frontmatter status=archived, git mv 入 archive |
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md` | 项目结构章节 +1 行（design/archive 子目录注释） |

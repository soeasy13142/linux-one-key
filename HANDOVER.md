# 项目交接文档

> **⚠️ 强制规则**：每次修改项目时，必须同步更新本文档。详见 `.claude/rules/common/handover.md`。

**最后更新**: 2026-06-24（v0.3 Code Review 问题修复完成）
**当前阶段**: v0.3 用户管理+内核加固+文件系统安全已完成（2026-06-24）

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
| Code Review (Round 3) | 🔄 部分修复 | 0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW；H1,H3,M1-M4,L1-L3 已修复，H2 延后，L4 未修复 |
| v0.3 用户管理 + 内核加固 + 文件系统 | ✅ 完成 | users.sh, kernel.sh, filesystem.sh, sysctl 模板, i18n, 测试 76 个用例 |
| v0.4 审计日志模块 | ✅ 完成 | audit.sh, audit.bats, config/audit/, i18n 更新, 菜单集成, 44 个测试用例 |
| v0.4 服务管理 | ⬜ 未开始 | |
| v1.0 测试 + 文档 + 发布 | ⬜ 未开始 | |

### 已完成的工作

| 日期 | 内容 | 文件 |
|------|------|------|
| 2026-06-20 | 项目初始化，搭建基础目录结构 | `scripts/`, `config/`, `docs/`, `tests/` |
| 2026-06-20 | 编写完整 PRD 需求文档 | `.claude/prds/linux-security-hardening.prd.md` |
| 2026-06-20 | 创建交接文档和交接规则 | `HANDOVER.md`, `.claude/rules/common/handover.md` |
| 2026-06-20 | 安装开发工具 (shellcheck, bats) | brew install shellcheck bats-core |
| 2026-06-20 | 创建工具函数库 | `scripts/base/utils.sh` (颜色、日志、备份、SSH配置辅助) |
| 2026-06-20 | 创建系统检测模块 | `scripts/base/detect.sh` (OS、权限、网络、包管理器) |
| 2026-06-20 | 创建系统初始化模块 | `scripts/base/init.sh` (目录创建、系统更新) |
| 2026-06-20 | 创建 SSH 安全加固模块 | `scripts/security/ssh.sh` (端口、密钥、root/密码登录) |
| 2026-06-20 | 创建主入口脚本 | `install.sh` (4模式菜单、交互流程、curl执行支持) |
| 2026-06-20 | 创建中英文语言文件 | `scripts/lang/zh.sh`, `scripts/lang/en.sh` |
| 2026-06-20 | 创建单元测试 | `tests/unit/utils.bats` (19个测试用例) |
| 2026-06-20 | 重新设计菜单系统 | 快速开始 + 自定义配置模式 |
| 2026-06-20 | 创建防火墙配置模块 | `scripts/security/firewall.sh` (支持 UFW/firewalld) |
| 2026-06-20 | 创建 Fail2Ban 配置模块 | `scripts/security/fail2ban.sh` |
| 2026-06-20 | 创建 Fail2Ban 配置模板 | `config/fail2ban/jail.local` |
| 2026-06-20 | 更新 i18n 翻译文件 | 添加防火墙和 Fail2Ban 相关翻译 |
| 2026-06-20 | 集成新模块到菜单 | 更新 install.sh 集成防火墙和 Fail2Ban |
| 2026-06-20 | 创建防火墙单元测试 | `tests/unit/firewall.bats` (9个测试用例) |
| 2026-06-20 | 创建 Fail2Ban 单元测试 | `tests/unit/fail2ban.bats` (18个测试用例) |
| 2026-06-20 | 修复 curl 管道模式 bug | `install.sh` (BASH_SOURCE 检测 + stdin 重定向) |
| 2026-06-20 | 全面 Code Review Round 1 | `docs/bug-review-report.md` (2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW) |
| 2026-06-20 | 全面 Code Review Round 2 | `docs/code-review-report-20260620.md` (10 CRITICAL + 15 HIGH + 13 MEDIUM + 12 LOW, 3 代理并行) |
| 2026-06-20 | 审查代理：安全审查 | 9 项安全发现（无命令注入/硬编码密钥/路径遍历） |
| 2026-06-20 | 审查代理：代码质量 | 12 项发现（含 RHEL 家族 OS 支持缺失 2x HIGH） |
| 2026-06-20 | 审查代理：静默失败 | 31 项发现（核心模式：包安装/防火墙/SSH 操作无错误检查） |
| 2026-06-20 | Ubuntu 24.04 ARM64 真机测试 | SSH 到 10.211.55.8，模拟 curl 管道模式测试全部模块，生成测试报告 |
| 2026-06-20 | 修复 curl 管道模式无限递归 bug | `scripts/base/utils.sh` (_ensure_log_dir 防重入 + init_logging 优雅降级) ⭐ NEW |
| 2026-06-20 | Code Review 问题修复（8 项） | SHA256SUMS 重建、install.sh 参数修复、set 选项统一、get_ssh_port 统一、独立 source 清理、README 更新 |
| 2026-06-20 | 真机测试 Bug #1/#4 修复 | `install.sh` — SHA256SUMS URL 从 GitHub API 改为 raw URL，恢复完整性校验 |
| 2026-06-20 | 真机测试 Bug #3 修复 | `install.sh` — grep 管道添加 `|| true` 防御 pipefail 崩溃 |
| 2026-06-20 | 真机测试 Bug #2/#7 修复 | `scripts/base/utils.sh` — schedule_rollback 改用 echo >&2 防 PID 污染 + sleep&&callback 防回滚误触发 |
| 2026-06-20 | 真机测试 Bug #6 修复 | `scripts/base/utils.sh` — log_info/log_success/log_warn/log_step/log_title/log_separator 统一输出到 stderr |
| 2026-06-20 | 真机测试 Bug #5 修复 | `scripts/security/ssh.sh` — restart_ssh 自动检测 ssh vs sshd 服务名，避免 Ubuntu 误导性错误 |
| 2026-06-20 | 真机测试 Bug #8 修复 | `scripts/lang/zh.sh`, `en.sh`, `scripts/base/detect.sh` — System Detection Summary i18n |
| 2026-06-20 | 创建交互式重构设计文档 | `docs/superpowers/specs/2026-06-20-interactive-setup-design.md` — 交互式安装流程规范 |
| 2026-06-20 | 创建交互式重构实施计划 | `docs/superpowers/plans/2026-06-20-interactive-setup.md` — 交互式重构实施计划 |
| 2026-06-20 | 删除一键模式，改为完整交互式向导 | `install.sh` — 移除 --yes/--quick 参数，改为逐步交互式配置 |
| 2026-06-20 | 新增随机端口生成函数 | `scripts/base/utils.sh` — 新增 generate_random_port() 函数 |
| 2026-06-20 | 重构 SSH 向导为逐步交互模式 | `scripts/security/ssh.sh` — 端口支持 3 选 1（自定义/随机/保持），每参数逐步提示 |
| 2026-06-20 | 重构防火墙向导为逐步交互模式 | `scripts/security/firewall.sh` — 重命名为 run_firewall_wizard，移除自定义变体 |
| 2026-06-20 | 重构 Fail2Ban 向导为逐步交互模式 | `scripts/security/fail2ban.sh` — 参数可自定义，重命名为 run_fail2ban_wizard |
| 2026-06-20 | 添加验证和 i18n 标签 | `scripts/security/fail2ban.sh`, `scripts/lang/zh.sh`, `scripts/lang/en.sh` — Fail2Ban 向导验证和翻译 |
| 2026-06-20 | 集成向导函数并更新所有引用 | `install.sh`, `scripts/base/utils.sh`, `scripts/base/init.sh`, `scripts/base/detect.sh` — 统一向导调用 |
| 2026-06-23 | 创建审计日志模块 | `scripts/security/audit.sh` — auditd 安装、规则生成（3级）、配置、服务管理、向导 |
| 2026-06-23 | 创建审计配置模板 | `config/audit/audit.rules`, `config/audit/auditd.conf` — 参考模板 |
| 2026-06-23 | 添加审计模块 i18n | `scripts/lang/zh.sh`, `scripts/lang/en.sh` — ~40 条 MSG_AUDIT_* 翻译 |
| 2026-06-23 | 集成审计模块到主菜单 | `install.sh` — load_dependencies、菜单[5]、状态检测、full_wizard Step 4 |
| 2026-06-23 | 更新报告模块 | `scripts/base/report.sh` — 添加审计状态、配置文件、警告信息 |
| 2026-06-23 | 创建审计模块单元测试 | `tests/unit/audit.bats` — 44 个测试用例，覆盖常量、规则生成、配置、函数存在性 |
| 2026-06-24 | 创建用户管理模块 | `scripts/security/users.sh` — 创建用户、密码、SSH密钥、sudo NOPASSWD、向导 |
| 2026-06-24 | 创建内核加固模块 | `scripts/security/kernel.sh` — sysctl 参数、内核模块禁用、回滚、向导 |
| 2026-06-24 | 创建文件系统安全模块 | `scripts/security/filesystem.sh` — 权限检查、SUID审计、无主文件、向导 |
| 2026-06-24 | 创建 sysctl 配置模板 | `config/sysctl/hardening.conf` — CIS Benchmark 参考参数 |
| 2026-06-24 | 添加 v0.3 i18n 翻译 | `scripts/lang/zh.sh`, `scripts/lang/en.sh` — ~120 条 MSG_USERS_*/MSG_KERNEL_*/MSG_FS_* 翻译 |
| 2026-06-24 | 集成 v0.3 到主入口 | `install.sh` — load_dependencies、菜单[6-8]、状态检测、full_wizard Step 5-7 |
| 2026-06-24 | 更新报告模块 | `scripts/base/report.sh` — 添加用户/内核/文件系统报告段 |
| 2026-06-24 | 创建 v0.3 单元测试 | `tests/unit/users.bats`(33), `kernel.bats`(20), `filesystem.bats`(23) — 共 76 个测试用例 |
| 2026-06-24 | 修复 v0.3 Code Review 问题 | eval 注入、函数顺序、find 排除、截断警告、状态函数集成等 9 项修复 |

---

## 3. 文件清单

### 当前文件

```
linux-one-key/
├── .claude/
│   ├── CLAUDE.md              # Claude Code 项目指令
│   ├── prds/
│   │   ├── linux-security-hardening.prd.md  # PRD 需求文档
│   │   └── main-menu-redesign.prd.md        # 主菜单重设计 PRD
│   ├── plans/
│   │   ├── main-menu-redesign.plan.md       # 主菜单重设计实施计划
│   │   ├── fix-commit-400933a-review.plan.md # v0.3 Code Review 修复计划
│   ├── commands/
│   │   ├── feature-development.md  # 功能开发命令
│   │   ├── database-migration.md   # 数据库迁移命令
│   │   └── add-language-rules.md   # 添加语言规则命令
│   ├── research/
│   │   └── everything-claude-code-research-playbook.md  # 研究工作流指南
│   ├── reviews/
│   │   ├── local-review-20260621.md  # 代码审查报告
│   │   └── commit-400933a-review.md  # v0.3 commit 代码审查报告
│   │   └── fix-commit-400933a-review.plan.md # v0.3 Code Review 修复计划
│   └── rules/
│       ├── common/            # 通用规则
│       │   ├── agents.md
│       │   ├── code-review.md
│       │   ├── coding-style.md
│       │   ├── development-workflow.md
│       │   ├── git-workflow.md
│       │   ├── guardrails.md  # 安全防护规则
│       │   ├── handover.md    # 交接文档规则
│       │   ├── hooks.md
│       │   ├── node.md        # Node.js 规则
│       │   ├── patterns.md
│       │   ├── performance.md
│       │   ├── security.md
│       │   └── testing.md
│       └── typescript/        # TS 规则（来自 ECC，本项目未使用）
│           ├── coding-style.md
│           ├── hooks.md
│           ├── patterns.md
│           ├── security.md
│           └── testing.md
├── scripts/
│   ├── README.md              # 脚本目录总览
│   ├── base/
│   │   ├── README.md          # 基础模块说明
│   │   ├── utils.sh           # 工具函数库
│   │   ├── detect.sh          # 系统检测
│   │   ├── init.sh            # 系统初始化
│   │   └── report.sh          # 报告生成
│   ├── security/
│   │   ├── README.md          # 安全模块说明
│   │   ├── ssh.sh             # SSH 安全加固
│   │   ├── firewall.sh        # 防火墙配置
│   │   ├── fail2ban.sh        # Fail2Ban 入侵防护
│   │   ├── audit.sh           # 审计日志配置 (v0.4)
│   │   ├── users.sh           # 用户管理 (v0.3)
│   │   ├── kernel.sh          # 内核安全加固 (v0.3)
│   │   └── filesystem.sh      # 文件系统安全 (v0.3)
│   ├── lang/
│   │   ├── README.md          # 语言文件说明
│   │   ├── zh.sh              # 中文翻译
│   │   └── en.sh              # 英文翻译
│   ├── dev/
│   │   └── README.md          # [规划中] 开发工具安装
│   ├── server/
│   │   └── README.md          # [规划中] 服务器软件安装
│   └── utils/
│       └── README.md          # [规划中] 通用工具
├── tests/
│   ├── README.md              # 测试目录总览
│   └── unit/
│       ├── README.md          # 单元测试说明
│       ├── utils.bats         # 工具函数测试
│       ├── firewall.bats      # 防火墙测试
│       ├── fail2ban.bats      # Fail2Ban 测试
│       ├── ssh.bats           # SSH 模块测试
│       ├── audit.bats         # 审计模块测试 (v0.4, 45个用例)
│       ├── users.bats         # 用户管理测试 (v0.3, 33个用例)
│       ├── kernel.bats        # 内核加固测试 (v0.3, 20个用例)
│       └── filesystem.bats    # 文件系统测试 (v0.3, 23个用例)
├── config/
│   ├── README.md              # 配置目录总览
│   ├── fail2ban/
│   │   ├── README.md          # Fail2Ban 配置说明
│   │   └── jail.local         # Fail2Ban 配置模板
│   ├── audit/
│   │   ├── README.md          # 审计配置说明
│   │   ├── audit.rules        # 审计规则模板 (v0.4)
│   │   └── auditd.conf        # auditd 配置模板 (v0.4)
│   └── sysctl/
│       └── hardening.conf     # 内核安全参数模板 (v0.3)
├── scripts/README.md           # 脚本目录总览
├── docs/                      # 文档目录
│   ├── README.md                           # 文档目录总览
│   ├── code-reviews/                       # Code Review 报告
│   │   ├── README.md
│   │   ├── round-1-bug-report.md           # Round 1 Bug 报告
│   │   ├── round-2-code-review.md          # Round 2 综合报告
│   │   └── round-3-handover.md             # Round 3 交接文档
│   ├── test-reports/                       # 测试报告
│   │   ├── README.md
│   │   ├── ubuntu-arm64-test.md            # Ubuntu ARM64 真机测试
│   │   └── vm-curl-test.md                 # VM 综合测试
│   └── design/                             # 设计文档 & 实施计划
│       ├── README.md
│       ├── interactive-setup-spec.md       # 交互式配置设计文档
│       ├── interactive-setup-plan.md       # 交互式配置实施计划
│       ├── linux-security-hardening-prd.md # 安全加固 PRD（副本）
│       ├── main-menu-redesign-prd.md       # 主菜单重设计 PRD（副本）
│       └── main-menu-redesign-plan.md      # 主菜单重设计计划（副本）
├── everything-claude-code/    # ECC 配置参考
├── .gitignore
├── install.sh                 # 主入口脚本
├── README.md                  # 项目说明
└── HANDOVER.md                # 本文件
```

### 计划文件（待创建，v0.3+）

```
├── scripts/
│   ├── security/
│   │   ├── kernel.sh          # 内核安全参数
│   │   ├── filesystem.sh      # 文件系统安全
│   │   └── services.sh        # 服务管理
│   └── utils/
│       ├── backup.sh          # 备份工具
│       ├── rollback.sh        # 回滚工具
│       ├── report.sh          # 报告生成（已移至 scripts/base/report.sh）
│       └── check.sh           # 检查工具
├── config/
│   ├── ssh/                   # SSH 配置模板
│   └── sysctl/                # 内核参数模板
└── tests/
    ├── unit/                  # 单元测试
    └── integration/           # 集成测试
```

### 计划文件（待创建）

```
├── install.sh                 # 主入口脚本
├── scripts/
│   ├── base/
│   │   ├── init.sh           # 系统初始化
│   │   ├── detect.sh         # 系统检测
│   │   └── utils.sh          # 通用工具函数
│   ├── security/              # [新目录] 安全加固脚本
│   │   ├── ssh.sh            # SSH 安全配置
│   │   ├── firewall.sh       # 防火墙配置
│   │   ├── fail2ban.sh       # Fail2Ban 配置
│   │   ├── kernel.sh         # 内核安全参数
│   │   ├── filesystem.sh     # 文件系统安全
│   │   ├── audit.sh          # 审计日志配置
│   │   └── services.sh       # 服务管理
│   └── utils/
│       ├── backup.sh         # 备份工具
│       ├── rollback.sh       # 回滚工具
│       ├── report.sh         # 报告生成
│       └── check.sh          # 检查工具
├── config/
│   ├── ssh/                  # SSH 配置模板
│   ├── fail2ban/             # Fail2Ban 配置模板
│   ├── sysctl/               # 内核参数模板
│   └── audit/                # 审计规则模板
└── tests/
    ├── unit/                 # 单元测试
    └── integration/          # 集成测试
```

---

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

1. **🟡 修复剩余问题**：
   - H2: `init.sh` 已加载但 `run_init()` 从未调用
   - L4: `view_report()` 中 `find -printf` 改为 macOS 兼容方案
   - 非 root 用户自动 fallback 日志目录
2. **📋 验证其他发行版**：在 CentOS/Debian VM 中运行完整向导流程
   - SSH 端口交互逻辑
   - Fail2Ban 参数验证
3. **开始 v0.3**：用户管理 + 内核加固
4. **E2E 测试**：在 Docker 容器中各发行版验证

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

v0.4 🔄 进行中
├── scripts/security/audit.sh       ✅ (44 个测试用例)
├── scripts/security/services.sh    ⬜
├── scripts/utils/report.sh         ⬜ (已移至 scripts/base/report.sh)
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

| 日期 | 操作 | 文件 | 说明 |
|------|------|------|------|
| 2026-06-20 | CREATE | `.claude/prds/linux-security-hardening.prd.md` | 编写完整 PRD |
| 2026-06-20 | CREATE | `HANDOVER.md` | 创建交接文档 |
| 2026-06-20 | CREATE | `.claude/rules/common/handover.md` | 添加交接文档更新规则 |
| 2026-06-20 | UPDATE | `.claude/CLAUDE.md` | 添加交接文档强制规则 |
| 2026-06-20 | CREATE | `.claude/commands/feature-development.md` | 功能开发命令（基于 ECC 定制） |
| 2026-06-20 | CREATE | `.claude/commands/database-migration.md` | 数据库迁移命令（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/commands/add-language-rules.md` | 添加语言规则命令（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/rules/common/guardrails.md` | 安全防护规则（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/rules/common/node.md` | Node.js 规则（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/research/research-playbook.md` | 研究工作流指南（来自 ECC） |
| 2026-06-20 | CREATE | `scripts/base/utils.sh` | 工具函数库（颜色、日志、备份、SSH配置辅助） |
| 2026-06-20 | CREATE | `scripts/base/detect.sh` | 系统检测模块（OS、权限、网络、包管理器） |
| 2026-06-20 | CREATE | `scripts/base/init.sh` | 系统初始化模块（目录创建、系统更新） |
| 2026-06-20 | CREATE | `scripts/security/ssh.sh` | SSH 安全加固模块（端口、密钥、root/密码登录） |
| 2026-06-20 | CREATE | `install.sh` | 主入口脚本（4模式菜单、交互流程） |
| 2026-06-20 | CREATE | `scripts/lang/zh.sh` | 中文翻译文件 |
| 2026-06-20 | CREATE | `scripts/lang/en.sh` | 英文翻译文件 |
| 2026-06-20 | CREATE | `tests/unit/utils.bats` | 工具函数单元测试（19个用例） |
| 2026-06-20 | UPDATE | `HANDOVER.md` | 更新进度和文件清单 |
| 2026-06-20 | UPDATE | `install.sh` | 重新设计菜单，快速开始+自定义配置 |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | 添加 run_ssh_hardening_custom 函数 |
| 2026-06-20 | CREATE | `scripts/security/firewall.sh` | 防火墙配置模块（支持 UFW/firewalld） |
| 2026-06-20 | CREATE | `scripts/security/fail2ban.sh` | Fail2Ban 入侵防护模块 |
| 2026-06-20 | CREATE | `config/fail2ban/jail.local` | Fail2Ban jail 配置模板 |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | 添加防火墙和 Fail2Ban 中文翻译 |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | 添加防火墙和 Fail2Ban 英文翻译 |
| 2026-06-20 | UPDATE | `install.sh` | 集成防火墙和 Fail2Ban 到菜单流程 |
| 2026-06-20 | CREATE | `tests/unit/firewall.bats` | 防火墙模块单元测试（9个用例） |
| 2026-06-20 | CREATE | `tests/unit/fail2ban.bats` | Fail2Ban 模块单元测试（18个用例） |
| 2026-06-20 | UPDATE | `install.sh` | 修复 curl 管道模式两个 bug：(1) BASH_SOURCE 在函数内外行为不一致导致管道检测失败，改为顶层捕获；(2) exec 后 stdin 为 EOF，添加 /dev/tty 重定向支持交互输入 |
| 2026-06-20 | UPDATE | `HANDOVER.md` | 更新交接文档，记录 curl 管道模式修复 |
| 2026-06-20 | UPDATE | `.claude/prds/linux-security-hardening.prd.md` | 添加"已知问题与修复记录"章节，记录 curl 管道模式两个 bug 的根因和修复方案 |
| 2026-06-20 | UPDATE | `scripts/security/firewall.sh` | C1: 修复 DETECT_OS → DETECTED_OS 变量名不匹配（2 处），防火墙模块现已正常工作 |
| 2026-06-20 | UPDATE | `scripts/security/fail2ban.sh` | C1: 修复 DETECT_OS → DETECTED_OS（3 处）；H2: banaction 按 OS 自动选择（ufw/firewallcmd-ipset/iptables-multiport），修复 Ubuntu/Debian 封禁失效 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | C2: set_ssh_config 正则添加词边界，防止 Port 误匹配 PortForwarding 等 |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | H1: 修复回滚定时器永不取消；M10: 密码认证禁用后验证；M11: check_other_users awk；M12: FIDO2/SK 密钥；M13: 密钥去重；L1: 端口八进制 |
| 2026-06-20 | UPDATE | `install.sh` | H4: bootstrap 临时目录清理；H5: tarball 完整性校验（SHA256SUMS）；H6: 报告仅在成功时生成；L2: default 分支；L3: 移除冗余初始化 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | H3: 移除 -u；M1: eval 替换；M2: fallback 警告；M3: load_lang 校验；L9: printf 替代 echo -e |
| 2026-06-20 | UPDATE | `scripts/base/detect.sh` | H7: /etc/os-release 子 shell 隔离 |
| 2026-06-20 | UPDATE | `scripts/base/init.sh` | M4: 移除 --only-upgrade；M5: yum-security 检查；M6: root 检查前置；M7: 更新失败不打印成功；L7: 调用 setup_timezone |
| 2026-06-20 | UPDATE | `scripts/security/firewall.sh` | M8: 安装后启动 firewalld；M9: root 权限检查 |
| 2026-06-20 | UPDATE | `scripts/security/fail2ban.sh` | M9: root 权限检查；M14: journald 警告；L4: 简化 _get_ssh_service_name |
| 2026-06-20 | CREATE | `SHA256SUMS` | 关键文件 SHA-256 校验收录，用于 tarball 完整性验证 |
| 2026-06-20 | CREATE | `docs/bug-review-report.md` | 全面 Code Review 报告，记录 2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW 级别 bug，含修复方案和优先级计划 |
| 2026-06-20 | CREATE | `docs/code-review-report-20260620.md` | 第二轮 Code Review 综合报告，3 代理并行（安全/质量/静默失败），发现 10 CRITICAL + 15 HIGH + 13 MEDIUM + 12 LOW，共 50 个问题 |
| 2026-06-20 | UPDATE | `HANDOVER.md` | 记录第二轮 Code Review 结果、更新进度状态和下一步工作 |
| 2026-06-20 | CREATE | `.claude/prds/main-menu-redesign.prd.md` | 主菜单入口重设计 PRD |
| 2026-06-20 | CREATE | `.claude/plans/main-menu-redesign.plan.md` | 主菜单入口重设计实施计划 |
| 2026-06-20 | UPDATE | `install.sh` | 重构主入口：主菜单循环、SSH/防火墙子菜单、系统状态检测、查看报告、非交互参数扩展 |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | 新增主菜单、子菜单、状态检测等翻译键 (~45 条) |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | 新增对应英文翻译键 (~45 条) |
| 2026-06-20 | UPDATE | `install.sh` | 移除未定义的 log_debug 调用；curl 管道模式自动追加 --yes |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | 新增 get_ssh_port() 公共函数 |
| 2026-06-20 | UPDATE | `scripts/base/init.sh` | set -euo → set -eo，统一 set 选项 |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | set -euo → set -eo；移除重复的 get_ssh_port() |
| 2026-06-20 | UPDATE | `scripts/security/firewall.sh` | set -euo → set -eo；移除独立 source 逻辑和重复函数；改用 get_ssh_port() |
| 2026-06-20 | UPDATE | `scripts/security/fail2ban.sh` | set -euo → set -eo；移除独立 source 逻辑和重复函数；改用 get_ssh_port() |
| 2026-06-20 | UPDATE | `SHA256SUMS` | 重新生成，补充 lang/zh.sh 和 lang/en.sh |
| 2026-06-20 | UPDATE | `README.md` | 补充 -s -- --yes 和 --ssh 参数传递示例 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | 修复 curl 管道模式无限递归 bug：_ensure_log_dir 防重入保护 + init_logging 优雅降级 |
| 2026-06-20 | CREATE | `docs/test-report-20260620.md` | Ubuntu 24.04 ARM64 真机测试报告：发现 2 CRITICAL + 3 HIGH + 3 MEDIUM + 1 LOW，curl 管道模式不可用 + SSH 回滚失效 |
| 2026-06-20 | UPDATE | `install.sh` | Bug #1/#3/#4: SHA256SUMS URL 改用 raw URL + grep 管道添加 \|\| true 防御 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | Bug #2/#6/#7: log 函数统一输出到 stderr + schedule_rollback 防 PID 污染 + sleep&&callback |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | Bug #5: restart_ssh 自动检测 ssh vs sshd 服务名，消除 Ubuntu 误导错误 |
| 2026-06-20 | UPDATE | `scripts/base/detect.sh` | Bug #8: print_detection_summary 标题改用 MSG_DETECTION_SUMMARY i18n |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | Bug #8: 新增 MSG_DETECTION_SUMMARY 翻译 |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | Bug #8: 新增 MSG_DETECTION_SUMMARY 翻译 |
| 2026-06-20 | UPDATE | install.sh, scripts/security/*.sh, scripts/base/utils.sh, scripts/lang/*.sh | 删除一键模式(--yes/--quick)，改为逐步交互式配置；新增随机端口生成；SSH端口支持3选1交互(自定义/随机/保持)；Fail2Ban参数可自定义；新增完整安全配置向导 |
| 2026-06-20 | CREATE | `docs/vm-test-report-20260620.md` | curl 方式综合测试报告：15 个测试用例、8 个新问题（1 HIGH + 4 MEDIUM + 3 LOW），含报告硬编码 bug、Bats 27/46 失败等 |
| 2026-06-20 | UPDATE | `install.sh` | P0 Issue #2 修复：generate_report() 动态生成，根据 _WIZARD_*_DONE 标志和实际系统状态，跳过步骤显示 [⊘] |
| 2026-06-20 | UPDATE | `tests/unit/fail2ban.bats` | P0 Issue #8 修复：source utils.sh + load_lang；修复 DETECT_OS→DETECTED_OS；修复 run_fail2ban_hardening_custom→run_fail2ban_wizard；添加 get_ssh_port mock |
| 2026-06-20 | UPDATE | `tests/unit/firewall.bats` | P0 Issue #8 修复：source utils.sh + load_lang；修复 DETECT_OS→DETECTED_OS |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | 新增 MSG_WIZARD_SKIPPED="已跳过" |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | 新增 MSG_WIZARD_SKIPPED="Skipped" |
| 2026-06-21 | UPDATE | `scripts/base/utils.sh` | 修复 get_os_type()/get_os_version() 环境变量污染：source → 子 shell (. /etc/os-release && echo) |
| 2026-06-21 | UPDATE | `scripts/base/utils.sh` | 修复 set_ssh_config() grep/sed \s → POSIX [[:space:]]，提升 BSD/macOS 兼容性 |
| 2026-06-21 | DELETE | `./.DS_Store`, `./config/.DS_Store`, `./tests/.DS_Store` | 清理 macOS .DS_Store 文件 |
| 2026-06-21 | UPDATE | `install.sh` | 修复 ShellCheck SC2012：view_report() 中 ls -t → find -printf |
| 2026-06-21 | CREATE | `.claude/reviews/local-review-20260621.md` | 代码审查报告：0 CRITICAL + 0 HIGH + 4 MEDIUM + 4 LOW |
| 2026-06-23 | CREATE | `docs/code-review-handover-20260623.md` | 全项目 Code Review Round 3 交接文档：0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW，含待办修复方案 |
| 2026-06-23 | UPDATE | `HANDOVER.md` | 更新当前阶段、添加变更日志 |
| 2026-06-23 | UPDATE | `install.sh` | H1: 将 _parse_args 移入 main()（load_dependencies 之后），解决颜色变量未初始化问题；L3: 移除残留 `:` 占位符；L4: find -printf → ls -t 兼容 macOS |
| 2026-06-23 | UPDATE | `scripts/base/utils.sh` | M1: _ENSURING_LOG_DIR 移除 export；M4: schedule_rollback 添加安全约束注释 |
| 2026-06-23 | UPDATE | `scripts/base/report.sh` | H3: 3 处硬编码中文替换为 MSG_REPORT_WARN_* i18n 变量 |
| 2026-06-23 | UPDATE | `scripts/lang/zh.sh` | H3: 新增 MSG_REPORT_WARN_SSH_PORT22/FIREWALL/FAIL2BAN 翻译 |
| 2026-06-23 | UPDATE | `scripts/lang/en.sh` | H3: 新增 MSG_REPORT_WARN_SSH_PORT22/FIREWALL/FAIL2BAN 翻译 |
| 2026-06-23 | UPDATE | `scripts/security/fail2ban.sh` | M3: sleep 2 改为轮询等待（最多 10 秒）；L2: _get_ssh_service_name 函数替换为 SSH_SERVICE_NAME 常量 |
| 2026-06-23 | UPDATE | `scripts/security/firewall.sh` | L1: 统一引号风格 $VAR → ${VAR} |
| 2026-06-23 | UPDATE | `tests/unit/fail2ban.bats` | L2: 更新测试用例适配 SSH_SERVICE_NAME 常量 |
| 2026-06-23 | CREATE | `tests/unit/ssh.bats` | M2: SSH 模块单元测试（16 个用例：validate_port/check_other_users/check_ssh_keys） |
| 2026-06-23 | DELETE | `SHA256SUMS` | 完整性校验简化为基本检查，不再需要独立校验文件（commit 33dc7e1） |
| 2026-06-23 | UPDATE | `HANDOVER.md` | 全面核对修正：更新文件树（添加缺失文件、移除不存在的 bootstrap.sh）、修正 Code Review Round 3 状态、添加 SHA256SUMS 删除记录、更新下一步工作 |
| 2026-06-23 | MOVE | `docs/bug-review-report.md` → `docs/code-reviews/round-1-bug-report.md` | 文档归类：Code Review 报告移入 code-reviews/ |
| 2026-06-23 | MOVE | `docs/code-review-report-20260620.md` → `docs/code-reviews/round-2-code-review.md` | 文档归类：Code Review 报告移入 code-reviews/ |
| 2026-06-23 | MOVE | `docs/code-review-handover-20260623.md` → `docs/code-reviews/round-3-handover.md` | 文档归类：Code Review 报告移入 code-reviews/ |
| 2026-06-23 | MOVE | `docs/test-report-20260620.md` → `docs/test-reports/ubuntu-arm64-test.md` | 文档归类：测试报告移入 test-reports/ |
| 2026-06-23 | MOVE | `docs/vm-test-report-20260620.md` → `docs/test-reports/vm-curl-test.md` | 文档归类：测试报告移入 test-reports/ |
| 2026-06-23 | MOVE | `docs/superpowers/specs/...` → `docs/design/interactive-setup-spec.md` | 文档归类：设计文档移入 design/ |
| 2026-06-23 | MOVE | `docs/superpowers/plans/...` → `docs/design/interactive-setup-plan.md` | 文档归类：实施计划移入 design/ |
| 2026-06-23 | COPY | `.claude/prds/*.prd.md` → `docs/design/` | PRD 副本归入 design/，原件保留供 Claude Code 工作流使用 |
| 2026-06-23 | COPY | `.claude/plans/*.plan.md` → `docs/design/` | 实施计划副本归入 design/，原件保留供 Claude Code 工作流使用 |
| 2026-06-23 | CREATE | `docs/README.md` | 文档目录总览 |
| 2026-06-23 | CREATE | `docs/code-reviews/README.md` | Code Review 目录说明 |
| 2026-06-23 | CREATE | `docs/test-reports/README.md` | 测试报告目录说明 |
| 2026-06-23 | CREATE | `docs/design/README.md` | 设计文档目录说明 |
| 2026-06-23 | CREATE | `scripts/security/audit.sh` | v0.4 审计日志模块：auditd 安装、3 级规则生成、配置、服务管理、交互式向导 |
| 2026-06-23 | CREATE | `config/audit/audit.rules` | 审计规则参考模板（全面规则示例） |
| 2026-06-23 | CREATE | `config/audit/auditd.conf` | auditd 配置参考模板 |
| 2026-06-23 | UPDATE | `scripts/lang/zh.sh` | 添加 ~40 条 MSG_AUDIT_* 中文翻译，更新菜单编号，添加向导步骤 |
| 2026-06-23 | UPDATE | `scripts/lang/en.sh` | 添加 ~40 条 MSG_AUDIT_* 英文翻译，更新菜单编号，添加向导步骤 |
| 2026-06-23 | UPDATE | `install.sh` | 集成 audit.sh：load_dependencies、菜单[5]、状态检测、full_wizard Step 4 |
| 2026-06-23 | UPDATE | `scripts/base/report.sh` | 添加审计状态、配置文件路径、警告信息到报告 |
| 2026-06-23 | CREATE | `tests/unit/audit.bats` | 审计模块单元测试：44 个用例（常量、规则生成、配置、函数存在性） |
| 2026-06-23 | UPDATE | `HANDOVER.md` | 更新进度状态、文件清单、变更日志 |
| 2026-06-24 | CREATE | `docs/code-reviews/round-4-audit-module-review.md` | v0.4 审计模块 Code Review：1 HIGH + 3 MEDIUM + 2 LOW |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | H1: 修复 auseport→aureport 拼写错误; M2: 添加 MSG_MAIN_MENU_REPORT_DESC |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | M2: 添加 MSG_MAIN_MENU_REPORT_DESC |
| 2026-06-24 | UPDATE | `scripts/security/audit.sh` | M1: 添加 case default 分支; L1: mkdir 错误记录到日志 |
| 2026-06-24 | UPDATE | `tests/unit/audit.bats` | M3: 添加 standard 规则不含 modules 的测试（45 个用例） |
| 2026-06-24 | UPDATE | `config/audit/audit.rules` | L2: 标注模板为 full 级别示例 |
| 2026-06-24 | UPDATE | `install.sh` | M2: 显示报告菜单描述文本 |
| 2026-06-24 | CREATE | `scripts/README.md` | 脚本目录总览：模块说明、加载顺序、依赖关系、编码规范 |
| 2026-06-24 | CREATE | `scripts/base/README.md` | 基础模块说明：utils/detect/init/report 各函数清单 |
| 2026-06-24 | CREATE | `scripts/security/README.md` | 安全模块说明：SSH/防火墙/Fail2Ban/审计功能和通用模式 |
| 2026-06-24 | CREATE | `scripts/lang/README.md` | 语言文件说明：i18n 工作原理、翻译键命名、添加新语言指南 |
| 2026-06-24 | CREATE | `scripts/dev/README.md` | [规划中] 开发工具安装目录说明 |
| 2026-06-24 | CREATE | `scripts/server/README.md` | [规划中] 服务器软件安装目录说明 |
| 2026-06-24 | CREATE | `scripts/utils/README.md` | [规划中] 通用工具脚本目录说明 |
| 2026-06-24 | CREATE | `config/README.md` | 配置目录总览：模板与实际配置的关系 |
| 2026-06-24 | CREATE | `config/audit/README.md` | 审计配置模板说明：3 级规则、auditd.conf 参数 |
| 2026-06-24 | CREATE | `config/fail2ban/README.md` | Fail2Ban 配置模板说明：jail.local 参数和占位符 |
| 2026-06-24 | CREATE | `tests/README.md` | 测试目录总览：Bats 框架、运行方式、测试规范 |
| 2026-06-24 | CREATE | `tests/unit/README.md` | 单元测试说明：107 个用例、测试结构、运行方式 |
| 2026-06-24 | UPDATE | `README.md` | 更新功能列表：审计日志状态 ⬜→✅ |
| 2026-06-24 | UPDATE | `HANDOVER.md` | 更新文件清单、添加变更日志 |
| 2026-06-24 | CREATE | `scripts/security/users.sh` | v0.3 用户管理模块：创建用户、密码、SSH密钥、sudo NOPASSWD、向导 |
| 2026-06-24 | CREATE | `scripts/security/kernel.sh` | v0.3 内核加固模块：sysctl 参数、内核模块禁用、回滚、向导 |
| 2026-06-24 | CREATE | `scripts/security/filesystem.sh` | v0.3 文件系统模块：权限检查、SUID审计、无主文件、向导 |
| 2026-06-24 | CREATE | `config/sysctl/hardening.conf` | v0.3 sysctl 安全参数配置模板（CIS Benchmark） |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | 添加 ~120 条 MSG_USERS_*/MSG_KERNEL_*/MSG_FS_* 中文翻译 |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | 添加 ~120 条对应英文翻译 |
| 2026-06-24 | UPDATE | `install.sh` | 集成 v0.3：load_dependencies、菜单[6-8]、状态检测、full_wizard Step 5-7 |
| 2026-06-24 | UPDATE | `scripts/base/report.sh` | 添加用户/内核/文件系统报告段 |
| 2026-06-24 | CREATE | `tests/unit/users.bats` | 用户管理单元测试（33 个用例） |
| 2026-06-24 | CREATE | `tests/unit/kernel.bats` | 内核加固单元测试（20 个用例） |
| 2026-06-24 | CREATE | `tests/unit/filesystem.bats` | 文件系统单元测试（23 个用例） |
| 2026-06-24 | CREATE | `.claude/plans/v0.3-user-kernel-filesystem.plan.md` | v0.3 实施计划文档 |
| 2026-06-24 | CREATE | `.claude/reviews/commit-400933a-review.md` | v0.3 commit 代码审查：3 HIGH + 4 MEDIUM + 3 LOW，含 eval 注入、find 性能、函数定义顺序等问题 |
| 2026-06-24 | UPDATE | `scripts/security/users.sh` | HIGH#1: eval 注入修复（getent passwd 替代 eval echo）；SSH 密钥无密码警告 |
| 2026-06-24 | UPDATE | `scripts/security/kernel.sh` | HIGH#2: _generate_sysctl_config 移至 apply_sysctl_params 之前 |
| 2026-06-24 | UPDATE | `scripts/security/filesystem.sh` | HIGH#3: find / 添加 -xdev 和排除 /proc /sys；截断警告；tail -1 改为全局变量；status 扫描范围 /usr→/ |
| 2026-06-24 | UPDATE | `scripts/base/report.sh` | 添加文件系统 SUID 详情和警告信息 |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | SSH 无密码警告；截断提示；文件系统报告键 |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | SSH 无密码警告；截断提示；文件系统报告键 |
| 2026-06-24 | UPDATE | `install.sh` | show_system_status 改用 check_*_status() 函数 |
| 2026-06-24 | CREATE | `.claude/plans/fix-commit-400933a-review.plan.md` | v0.3 Code Review 修复计划 |

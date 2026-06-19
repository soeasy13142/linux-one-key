# 项目交接文档

> **⚠️ 强制规则**：每次修改项目时，必须同步更新本文档。详见 `.claude/rules/common/handover.md`。

**最后更新**: 2026-06-20
**当前阶段**: 需求分析完成，待实现

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

### 总体状态：🟢 需求分析完成

| 阶段 | 状态 | 说明 |
|------|------|------|
| 需求分析 | ✅ 完成 | PRD 已编写，见 `.claude/prds/linux-security-hardening.prd.md` |
| 架构设计 | ⬜ 未开始 | |
| v0.1 基础框架 + SSH 安全 | ⬜ 未开始 | |
| v0.2 防火墙 + Fail2Ban | ⬜ 未开始 | |
| v0.3 用户管理 + 内核加固 | ⬜ 未开始 | |
| v0.4 审计日志 + 服务管理 | ⬜ 未开始 | |
| v1.0 测试 + 文档 + 发布 | ⬜ 未开始 | |

### 已完成的工作

| 日期 | 内容 | 文件 |
|------|------|------|
| 2026-06-20 | 项目初始化，搭建基础目录结构 | `scripts/`, `config/`, `docs/`, `tests/` |
| 2026-06-20 | 编写完整 PRD 需求文档 | `.claude/prds/linux-security-hardening.prd.md` |
| 2026-06-20 | 创建交接文档和交接规则 | `HANDOVER.md`, `.claude/rules/common/handover.md` |

---

## 3. 文件清单

### 当前文件

```
linux-one-key/
├── .claude/
│   ├── CLAUDE.md              # Claude Code 项目指令
│   ├── prds/
│   │   └── linux-security-hardening.prd.md  # PRD 需求文档 ⭐
│   ├── commands/
│   │   ├── feature-development.md  # 功能开发命令
│   │   ├── database-migration.md   # 数据库迁移命令
│   │   └── add-language-rules.md   # 添加语言规则命令
│   ├── research/
│   │   └── research-playbook.md    # 研究工作流指南
│   └── rules/
│       ├── common/            # 通用规则
│       │   ├── coding-style.md
│       │   ├── git-workflow.md
│       │   ├── testing.md
│       │   ├── performance.md
│       │   ├── patterns.md
│       │   ├── hooks.md
│       │   ├── agents.md
│       │   ├── security.md
│       │   ├── handover.md    # 交接文档规则 ⭐
│       │   ├── guardrails.md  # 安全防护规则
│       │   └── node.md        # Node.js 规则
│       └── typescript/        # TS 规则（本项目未使用）
├── scripts/
│   ├── base/                  # [空] 基础环境配置
│   ├── dev/                   # [空] 开发工具安装
│   ├── server/                # [空] 服务器软件安装
│   └── utils/                 # [空] 通用工具函数
├── config/                    # [空] 配置文件模板
├── docs/                      # [空] 文档
├── tests/                     # [空] 测试脚本
├── README.md                  # 项目说明（初始版本）
└── HANDOVER.md                # 本文件
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

---

## 5. 下一步工作

### 立即需要做的

1. **实现 v0.1**：基础框架 + SSH 安全
   - 创建 `scripts/base/utils.sh`（颜色输出、日志、错误处理等工具函数）
   - 创建 `scripts/base/detect.sh`（系统检测：OS、权限、网络）
   - 创建 `scripts/base/init.sh`（系统初始化）
   - 创建 `scripts/security/ssh.sh`（SSH 安全配置：端口、密钥、禁止 root/密码登录）
   - 创建 `install.sh`（主入口脚本）

2. **开始前建议**：
   - 先阅读 PRD 文档 `.claude/prds/linux-security-hardening.prd.md`
   - PRD 中第 4 节"交互流程设计"定义了主流程
   - PRD 中第 2.1 节"SSH 安全加固"定义了详细参数

### 实现顺序建议

```
v0.1 (第一周)
├── scripts/base/utils.sh       # 先做，其他脚本依赖它
├── scripts/base/detect.sh      # 系统检测
├── scripts/security/ssh.sh     # SSH 安全（核心功能）
└── install.sh                  # 主入口

v0.2 (第二周)
├── scripts/security/firewall.sh
└── scripts/security/fail2ban.sh

v0.3 (第三周)
├── scripts/security/kernel.sh
├── scripts/security/filesystem.sh
└── scripts/base/init.sh        # 用户创建等功能

v0.4 (第四周)
├── scripts/security/audit.sh
├── scripts/security/services.sh
├── scripts/utils/report.sh
└── scripts/utils/backup.sh / rollback.sh
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

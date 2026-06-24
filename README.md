# Linux One-Key

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-Passing-brightgreen.svg)](https://www.shellcheck.net/)
[![Bats Tests](https://img.shields.io/badge/Tests-218+-brightgreen.svg)](https://github.com/bats-core/bats-core)

**Linux 云服务器安全加固一键脚本** — 通过交互式向导，几步完成 SSH、防火墙、Fail2Ban、审计日志等安全配置。

**A one-key security hardening script for Linux cloud servers** — Complete SSH, firewall, Fail2Ban, and audit configuration through an interactive wizard.

---

## 目录 / Table of Contents

- [功能特性 / Features](#功能特性--features)
- [快速开始 / Quick Start](#快速开始--quick-start)
- [支持系统 / Supported Systems](#支持系统--supported-systems)
- [项目架构 / Project Architecture](#项目架构--project-architecture)
- [交互式向导 / Interactive Wizard](#交互式向导--interactive-wizard)
- [开发指南 / Development Guide](#开发指南--development-guide)
- [安全注意事项 / Security Notes](#安全注意事项--security-notes)
- [参考资料 / References](#参考资料--references)
- [版本历史 / Changelog](#版本历史--changelog)
- [License](#license)

---

## 功能特性 / Features

### SSH 安全加固

- 修改 SSH 端口（支持自定义、随机生成、保持默认三种方式）
- 生成 Ed25519 密钥对（比 RSA 更安全、更短）
- 禁用 root 远程登录
- 禁用密码登录，强制密钥认证
- 配置前自动检测端口占用和密钥状态，避免锁定服务器

### 防火墙配置

- **Ubuntu / Debian**：基于 UFW 的防火墙规则
- **CentOS / Rocky / Alma**：基于 firewalld 的防火墙规则
- 自动放行 SSH 端口，支持自定义额外放行端口
- 安装后自动启动并启用开机自启

### Fail2Ban 入侵防护

- 自动安装和配置 Fail2Ban
- 根据操作系统自动选择 banaction（ufw / firewallcmd-ipset / iptables-multiport）
- 支持自定义封禁时间、最大重试次数、检测窗口
- 自动检测 SSH 服务名（ssh / sshd）

### 审计日志

- 安装和配置 auditd
- 三级审计规则：basic（基础）/ standard（标准）/ full（全面）
- 覆盖认证、文件访问、权限变更、网络连接等关键事件
- 支持开机自启和服务状态检测

### 用户管理

- 创建新用户并配置密码
- 为用户生成 SSH Ed25519 密钥对
- 配置 sudo NOPASSWD 权限
- 创建用户前自动检查用户名冲突

### 内核安全加固

- 基于 CIS Benchmark 的 sysctl 安全参数配置
- 禁用不必要的内核模块（cramfs、freevxfs、hfs 等）
- 配置前自动备份原始参数，支持回滚
- 涵盖网络协议安全、内存保护、日志记录等方面

### 文件系统安全

- 全局 SUID/SGID 文件审计
- 扫描无主文件和目录
- 检查关键目录权限（/etc/passwd、/etc/shadow 等）
- 发现问题后提供修复建议

### 服务管理

- 审计运行中的 systemd 服务
- 检测并禁用不必要服务（telnet、rsh、vsftpd、avahi-daemon 等）
- 扫描开放端口，标记非标准端口并警告
- 支持 ss/netstat/proc 多种端口检测方式

---

## 快速开始 / Quick Start

### 方式一：curl 管道执行（推荐）

适合全新服务器，一行命令即可启动：

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash
```

> 脚本会自动下载完整仓库到临时目录，然后启动交互式向导。

### 方式二：下载后执行

适合想先查看脚本内容再运行的用户：

```bash
wget https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 方式三：克隆仓库执行

适合开发者或需要自定义修改的用户：

```bash
git clone https://github.com/soeasy13142/linux-one-key.git
cd linux-one-key
sudo bash install.sh
```

> **注意**：所有方式都需要 root 或 sudo 权限运行。

---

## 支持系统 / Supported Systems

| 发行版 / Distribution | 版本 / Version | 架构 / Architecture | 状态 / Status |
|------------------------|----------------|---------------------|---------------|
| Ubuntu | 20.04+ | x86_64, ARM64 | ✅ 已测试 |
| Debian | 11+ | x86_64 | ✅ 已测试 |
| CentOS | 7+ | x86_64 | 🔄 待验证 |
| Rocky Linux | 8 / 9 | x86_64 | 🔄 待验证 |
| AlmaLinux | 8 / 9 | x86_64 | 🔄 待验证 |
| RHEL | 7+ | x86_64 | 🔄 待验证 |
| Fedora | 最新版 | x86_64 | 🔄 待验证 |

> 其他基于 systemd 的 Linux 发行版也可能兼容，但未经充分测试。

---

## 项目架构 / Project Architecture

```
linux-one-key/
├── install.sh                 # 主入口脚本（菜单系统、向导流程）
├── scripts/
│   ├── base/                  # 基础模块
│   │   ├── utils.sh           # 工具函数库（日志、备份、SSH 配置辅助）
│   │   ├── detect.sh          # 系统检测（OS、权限、网络、包管理器）
│   │   ├── init.sh            # 系统初始化（目录创建、系统更新）
│   │   └── report.sh          # 安全报告生成
│   ├── security/              # 安全加固模块
│   │   ├── ssh.sh             # SSH 安全加固
│   │   ├── firewall.sh        # 防火墙配置（UFW / firewalld）
│   │   ├── fail2ban.sh        # Fail2Ban 入侵防护
│   │   ├── audit.sh           # 审计日志配置（auditd）
│   │   ├── users.sh           # 用户管理
│   │   ├── kernel.sh          # 内核安全加固（sysctl）
│   │   ├── filesystem.sh      # 文件系统安全
│   │   └── services.sh        # 服务管理
│   └── lang/                  # 国际化
│       ├── zh.sh              # 中文翻译
│       └── en.sh              # 英文翻译
├── config/                    # 配置文件模板
│   ├── fail2ban/jail.local    # Fail2Ban 配置模板
│   ├── audit/                 # auditd 配置和规则模板
│   └── sysctl/                # sysctl 安全参数模板
├── tests/                     # 单元测试（Bats）
│   └── unit/                  # 218+ 测试用例
└── docs/                      # 文档
    ├── code-reviews/          # 代码审查报告
    ├── test-reports/          # 测试报告
    └── design/                # 设计文档和实施计划
```

### 模块加载顺序

脚本按以下顺序加载模块，确保依赖关系正确：

```
utils.sh → detect.sh → init.sh → lang.sh → security modules → report.sh
```

---

## 交互式向导 / Interactive Wizard

脚本采用交互式向导模式，而非无人值守的一键执行。每步操作都会显示说明并等待用户确认。

### 两种运行模式

| 模式 | 说明 |
|------|------|
| **快速开始** | 依次执行所有安全加固步骤，每步确认后继续 |
| **自定义配置** | 从菜单中选择单独执行某一项加固操作 |

### 向导流程

```
Step 0: 系统初始化（更新包管理器、创建目录）
Step 1: SSH 安全加固（端口、密钥、登录策略）
Step 2: 防火墙配置（UFW / firewalld 规则）
Step 3: Fail2Ban 入侵防护（自动封禁策略）
Step 4: 审计日志配置（auditd 规则级别）
Step 5: 用户管理（创建用户、密钥、sudo）
Step 6: 内核安全加固（sysctl 参数）
Step 7: 文件系统安全（SUID 审计、权限检查）
Step 8: 服务管理（审计服务、禁用不必要服务、端口扫描）
Step 9: 生成安全报告
```

### 安全保障

- **自动备份**：所有配置修改前自动备份原文件到 `/var/log/linux-one-key/backups/`
- **幂等设计**：重复运行不会产生副作用，已配置的项目会自动跳过
- **状态检测**：主菜单实时显示各模块的配置状态
- **回滚支持**：内核参数修改支持一键回滚到备份状态

---

## 开发指南 / Development Guide

### 环境准备

```bash
# macOS
brew install shellcheck bats-core

# Ubuntu / Debian
sudo apt install shellcheck
sudo apt install bats        # 或从源码安装: https://github.com/bats-core/bats-core

# CentOS / RHEL
sudo yum install shellcheck
# bats 需要从源码安装
```

### 运行测试

```bash
# 运行全部单元测试
bats tests/unit/*.bats

# 运行单个模块测试
bats tests/unit/ssh.bats
bats tests/unit/firewall.bats
bats tests/unit/fail2ban.bats
```

### ShellCheck 静态检查

```bash
# 检查所有脚本
shellcheck -x scripts/**/*.sh
shellcheck -x install.sh

# -x 参数允许 source 外部文件
```

### 代码规范

| 规范 | 说明 |
|------|------|
| Shebang | 首行 `#!/usr/bin/env bash`，紧跟 `set -eo pipefail` |
| 函数命名 | `snake_case`，如 `run_ssh_wizard`、`detect_os` |
| 常量命名 | `UPPER_SNAKE_CASE`，如 `SUPPORTED_OS`、`SSH_SERVICE_NAME` |
| 函数注释 | 每个函数必须有注释说明用途 |
| 输出颜色 | 绿色=成功，红色=错误，黄色=警告，蓝色=信息 |
| i18n | 所有用户可见的文本必须使用翻译变量（`MSG_*`），不硬编码 |
| 备份 | 修改配置文件前必须备份原文件 |

### 添加新模块

1. 在 `scripts/security/` 下创建新脚本（如 `newmodule.sh`）
2. 在 `scripts/lang/zh.sh` 和 `scripts/lang/en.sh` 中添加翻译
3. 在 `install.sh` 中集成（load_dependencies、菜单项、状态检测）
4. 在 `tests/unit/` 下创建对应的 `.bats` 测试文件
5. 运行 `shellcheck` 和 `bats` 确认无报错

---

## 安全注意事项 / Security Notes

> ⚠️ **请在测试环境先验证，再在生产环境使用。**

| 操作 | 注意事项 |
|------|----------|
| 修改 SSH 端口 | 确保新端口未被其他服务占用，修改后立即测试新端口连接 |
| 禁用密码登录 | 确保 SSH 密钥已正确配置并测试通过，否则会锁定服务器 |
| 禁用 root 登录 | 确保已创建具有 sudo 权限的普通用户 |
| 防火墙规则 | 确认放行了 SSH 端口，避免防火墙阻断远程连接 |
| 内核参数修改 | 脚本会自动备份，但建议了解每个参数的含义 |

### 备份位置

所有备份文件保存在：

```
/var/log/linux-one-key/backups/
```

---

## 参考资料 / References

| 资源 | 链接 |
|------|------|
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks |
| OpenSSH 文档 | https://man.openbsd.org/sshd_config |
| STIG 安全指南 | https://public.cyber.mil/stigs/ |
| NIST 安全指南 | https://www.nist.gov/itl/smallbusinesscyber/guidance-document/technical-guide-securing-network-devices |
| Fail2Ban 文档 | https://github.com/fail2ban/fail2ban/wiki |
| auditd 文档 | https://man7.org/linux/man-pages/man8/auditd.8.html |
| dev-sec Hardening | https://dev-sec.io/ |

---

## 版本历史 / Changelog

| 版本 | 日期 | 说明 |
|------|------|------|
| v0.4 | 2026-06-24 | 审计日志模块（auditd）、服务管理模块 |
| v0.3 | 2026-06-24 | 用户管理、内核安全加固、文件系统安全 |
| v0.2 | 2026-06-20 | 防火墙配置、Fail2Ban 入侵防护 |
| v0.1 | 2026-06-20 | 基础框架、SSH 安全加固、交互式向导、国际化 |

> 详细变更记录见 [HANDOVER.md](HANDOVER.md)

### 待完成

- v1.0：完整测试、文档、正式发布

---

## License

[MIT](LICENSE) © [soeasy13142](https://github.com/soeasy13142)

---

## 致谢 / Acknowledgements

- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) — 安全配置基准
- [dev-sec/linux-baseline](https://github.com/dev-sec/linux-baseline) — Linux 安全基线参考
- [konstruktoid/hardening](https://github.com/konstruktoid/hardening) — Ubuntu 加固脚本参考
- [Bats](https://github.com/bats-core/bats-core) — Bash 自动化测试框架
- [ShellCheck](https://www.shellcheck.net/) — Shell 脚本静态分析工具

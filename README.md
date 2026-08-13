# Linux One-Key

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![ShellCheck](https://img.shields.io/badge/ShellCheck-Passing-brightgreen.svg)](https://www.shellcheck.net/)
[![Bats Tests](https://img.shields.io/badge/Tests-612-brightgreen.svg)](tests/unit/)
[![Docker Phase1](https://img.shields.io/badge/Docker%20Phase1-72%2F72-brightgreen.svg)](tests/docker/)
[![Docker Phase2](https://img.shields.io/badge/Docker%20Phase2-21%2F21-brightgreen.svg)](tests/docker/)
[![curl Lite Test](https://img.shields.io/badge/curl%20Lite-13%2F13%20×%205-brightgreen.svg)](docs/test-reports/curl-lite-mode-test.md)

**Linux 云服务器安全加固 + 一键环境初始化脚本** — 通过交互式向导，几步完成 SSH、防火墙、Fail2Ban、审计日志等安全配置。

**A one-key security hardening + environment setup script for Linux cloud servers** — Complete SSH, firewall, Fail2Ban, and audit configuration through an interactive wizard.

---

## 目录 / Table of Contents

- [功能特性 / Features](#功能特性--features)
- [快速开始 / Quick Start](#快速开始--quick-start)
- [系统要求 / System Requirements](#系统要求--system-requirements)
- [测试覆盖 / Test Coverage](#测试覆盖--test-coverage)
- [项目结构 / Project Architecture](#项目结构--project-architecture)
- [交互式向导 / Interactive Wizard](#交互式向导--interactive-wizard)
- [开发者指南 / Contributing](#开发者指南--contributing)
- [文档 / Documentation](#文档--documentation)
- [安全注意事项 / Security Notes](#安全注意事项--security-notes)
- [参考资料 / References](#参考资料--references)
- [版本历史 / Changelog](#版本历史--changelog)
- [License](#license)

---

## 功能特性 / Features

- [x] ⚡ **Lite/Full 双模式**（`--lite` 精简版 vs 完整版，低内存服务器优化）
- [x] SSH 安全加固（端口、密钥、算法、登录策略）
- [x] SSH 回滚保护（修改前检测活动会话，连接测试失败自动回滚）
- [x] 防火墙配置（UFW / firewalld 自动适配）
- [x] Fail2Ban 入侵防护（SSH 暴力破解防护）
- [x] 用户管理（创建、sudo 授权、密钥部署）
- [x] 内核参数加固（sysctl 安全优化）
- [x] 文件系统安全审计（SUID/SGID、权限异常）
- [x] 系统服务安全审计（开放端口、监听服务）
- [x] auditd 审计规则（CIS 基准，三档级别）
- [x] NTP 时间同步（chrony / ntpd 自动适配 + 时区配置）
- [x] Swap 配置（自动检测 + 智能扩容）
- [x] 自动安全更新（AutoUpdate）
- [x] AIDE 文件完整性监控
- [x] ClamAV 病毒扫描（可选 clamd 守护进程）
- [x] Rootkit 检测
- [x] K3s 一键安装
- [x] Docker 一键安装 + daemon.json 安全加固
- [x] Nginx 一键安装 + 安全响应头基线
- [x] Redis / PostgreSQL / MySQL / Memcached 一键安装 + 安全基线
- [x] 更换软件源（交互式选站，vendored LinuxMirrors，支持多发行版）
- [x] 交互式菜单向导，每步确认
- [x] 快速开始 + 自定义配置双模式
- [x] 多发行版支持（CentOS 7+ / Ubuntu 20.04+ / Debian 11+ / Rocky / Alma / Fedora）
- [x] i18n 国际化（中文 / English）
- [x] 所有修改前自动备份，支持回滚
- [x] 幂等设计，重复运行安全
- [x] curl 管道一键执行 / npm（`npx`）分发
- [x] 备份/回滚中心（浏览备份历史、按模块一键恢复、回滚定时器管理、清理旧备份）— Full 版
- [x] 安全仪表盘（多模块 CIS 合规评分 + 风险等级）— Full 版

---

## 快速开始 / Quick Start

> **💡 新功能：低配服务器可用 `--lite` 精简模式**（见下方「方式四」）

### 方式一：精简模式执行 — 低内存服务器推荐 ⭐

> 适合 **1GB 以下内存** 的轻量云服务器。只执行最核心的安全加固（SSH + 防火墙 + 内核参数），
> **不启动** Fail2Ban（-50~100MB）、auditd（-20~50MB）等守护进程，将内存留给业务应用。

```bash
# 一行命令，精简安装
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash -s -- --lite

# 或下载后本地运行
wget https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh
sudo bash install.sh --lite
```

---

### 方式二：完整模式执行（默认，标准服务器推荐）

适合标准配置云服务器（2GB+ 内存），运行全部 9 个安全模块：

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash
```

> 脚本会自动下载完整仓库到临时目录，然后启动交互式向导。

### 方式三：下载后执行

适合想先查看脚本内容再运行的用户：

```bash
wget https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

### 方式四：克隆仓库执行

适合开发者或需要自定义修改的用户：

```bash
git clone https://github.com/soeasy13142/linux-one-key.git
cd linux-one-key
sudo bash install.sh
```

> **注意**：所有方式都需要 root 或 sudo 权限运行。

---

## 系统要求 / System Requirements

| 发行版 / Distribution | 版本 / Version | 架构 / Architecture | 状态 / Status |
|------------------------|----------------|---------------------|---------------|
| Ubuntu | 20.04, 22.04, 24.04 | x86_64, ARM64 | ✅ Docker Phase 1 通过 |
| Debian | 11, 12 | x86_64 | ✅ Docker Phase 1 通过 |
| CentOS | 7 | x86_64 | ✅ Docker Phase 1 通过 |
| Rocky Linux | 8, 9 | x86_64 | ✅ Docker Phase 1 通过 |
| AlmaLinux | 9 | x86_64 | ✅ Docker Phase 1 通过 |
| RHEL | 7+ | x86_64 | 🔄 待验证 |
| Fedora | 最新版 | x86_64 | 🔄 待验证 |

> 所有标记 "Docker Phase 1 通过" 的发行版均已在 Docker 容器中完成配置文件验证。
> Phase 2（特权容器 + systemd 服务验证）已在 Ubuntu 22.04, CentOS 7, Debian 12 上 21/21 通过。
> 调试文档：[20 个已修复问题](tests/docker-test-debug-log.md) | Debug log: [20 resolved issues](tests/docker-test-debug-log.md)

---

## 测试覆盖 / Test Coverage

### Phase 1：配置验证（Configuration Validation）✅

9 个发行版 × 8 个安全模块 = **72/72 全部通过**

| 模块 \ 发行版 | Ubuntu 20.04 | Ubuntu 22.04 | Ubuntu 24.04 | Debian 11 | Debian 12 | CentOS 7 | Rocky 8 | Rocky 9 | Alma 9 |
|----------------|:------------:|:------------:|:------------:|:---------:|:---------:|:--------:|:-------:|:-------:|:------:|
| SSH | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Firewall | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fail2Ban | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| auditd | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Users | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Kernel | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Filesystem | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Services | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

> 📄 [Phase 1 详细测试报告](tests/docker/phase2-report.md) · [调试日志（20 个已修复问题）](tests/docker-test-debug-log.md)
> 📄 [Phase 1 test report](tests/docker/phase2-report.md) · [Debug log (20 resolved issues)](tests/docker-test-debug-log.md)

### Phase 2：服务验证（Service Verification）✅

3 个代表性发行版 × 7 个验证模块 = **21/21 全部通过**

| 模块 \ 发行版 | Ubuntu 22.04 | CentOS 7 | Debian 12 |
|----------------|:------------:|:--------:|:---------:|
| SSH 服务监听 | ✅ | ✅ | ✅ |
| 防火墙运行状态 | ✅ | ✅ | ✅ |
| Fail2Ban 服务 | ✅ | ✅ | ✅ |
| auditd 规则加载 | ✅ | ✅ | ✅ |
| 用户 SSH 登录 | ✅ | ✅ | ✅ |
| 安全扫描（nmap） | ✅ | ✅ | ✅ |
| 回滚验证 | ✅ | ✅ | ✅ |

> Phase 2 使用 `--privileged` Docker 容器，验证服务实际启动及安全效果。
> 详细测试日志见 [调试文档 §3.13-3.20](tests/docker-test-debug-log.md)（8 个 Phase 2 运行时问题）。

### 单元测试 / Unit Tests

- **612 个** Bats 测试用例覆盖全部模块（612 test cases across all modules）
- 覆盖正常路径、边界条件、幂等性、回滚验证（normal, edge, idempotency, rollback）
- 持续集成中自动运行（ShellCheck + Bats）

### 调试日志 / Debug Log

完整的调试记录（20 个已修复问题）保存在 [`tests/docker-test-debug-log.md`](tests/docker-test-debug-log.md)，涵盖：
- Phase 1（12 个）：子 Shell 变量丢失、容器状态丢失、RHEL 包冲突、CentOS 7 EOL 等
- Phase 2（8 个）：build_image stdout 泄露、容器内 SSH/D-Bus/firewalld 兼容性问题等

> Full debug log at [`tests/docker-test-debug-log.md`](tests/docker-test-debug-log.md) — 20 issues documented with root causes and fixes.

---

## 项目结构 / Project Architecture

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
├── tests/
│   ├── unit/                  # 612 Bats 单元测试
│   └── docker/                # Docker 自动化测试框架
│       ├── images/            # 9 个发行版 Dockerfile
│       ├── tests/             # 8 个模块测试脚本 + Phase 2 目录
│       ├── lib/common.bash    # 公共测试函数库
│       ├── run-test.sh        # 单模块单发行版测试入口
│       └── test-all.sh        # 全量测试运行器
├── docs/                      # 文档
│   ├── design/                # 设计文档（PRD、测试方案）
│   ├── plans/                 # 计划文件（Plan-First 落地）
│   ├── code-reviews/          # 代码审查报告
│   └── test-reports/          # 测试报告
└── .github/workflows/         # CI 配置
```

### 模块加载顺序

脚本按以下顺序加载模块，确保依赖关系正确：

```
utils.sh -> detect.sh -> init.sh -> lang.sh -> security modules -> report.sh
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

> **精简模式（`--lite`）**：步骤 3（Fail2Ban）、步骤 4（Audit）、步骤 5（用户管理）、步骤 7（文件系统）、步骤 8（服务管理）在精简模式下自动跳过，仅执行核心安全加固。

### 安全保障

- **自动备份**：所有配置修改前自动备份原文件到 `/var/log/linux-one-key/backups/`
- **幂等设计**：重复运行不会产生副作用，已配置的项目会自动跳过
- **状态检测**：主菜单实时显示各模块的配置状态（评分 + 颜色 + 建议）
- **回滚支持**：内核参数修改支持一键回滚到备份状态

### 运维工具（Full 版）

- **[17] 备份/回滚中心**：浏览 `/var/log/linux-one-key/backups/` 备份历史；按模块一键恢复到原路径；查看/取消 SSH 回滚定时器；按保留策略清理旧备份。恢复操作需双重确认。
- **[18] 安全仪表盘**：12 个安全模块 × 31 项检查的合规评分（SSH 5 / Firewall 3 / Fail2Ban 3 / Audit 3 / Users 2 / Kernel 2 / Filesystem 2 / Services 2 / AutoUpdate 2 / AIDE 2 / ClamAV 2 / Rootkit 3），总分 + 风险等级（≥90 Low · 75-89 Medium · 60-74 High · <60 Critical）。
- **[19] 更换软件源**：交互式更换系统软件源（vendored [LinuxMirrors](https://github.com/SuperManito/LinuxMirrors)，支持 Debian/Ubuntu/CentOS/Rocky/Alma/openEuler 等；含恢复官方源、查看当前源）— Lite/Full 均可用
- **[20] 服务器软件**：安装 Docker、Nginx、Redis、PostgreSQL、MySQL、Memcached 等常用软件并应用安全基线（daemon.json 加固、安全响应头、数据库本地监听 + 强认证、缓存 localhost + 禁 UDP）— Full 版

---

## ⚡ 精简版 vs 完整版 — 模式选择指南

脚本支持两种运行模式，你可以在 curl 时通过 `--lite` 参数选择：

### 🚀 精简模式 (`--lite`) — 为低内存服务器而生

> **省内存 · 免守护进程 · 零配置开销**

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash -s -- --lite
```

| 特性 | 说明 |
|------|------|
| 包含模块 | SSH 加固 + 防火墙 + 内核参数（3 项核心安全） |
| 内存节省 | **~70~150MB** — 不启动 Fail2Ban (~50-100MB) 和 auditd (~20-50MB) |
| 守护进程 | 仅防火墙 1 个轻量 daemon，其余为纯配置文件修改 |
| 适用场景 | **1GB 以下内存**的轻量云服务器（阿里云轻量、AWS t2.nano/nano 等） |
| 执行耗时 | 约完整版一半 |

### 🏢 完整模式（默认） — 全功能安全加固

```bash
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash
```

| 特性 | 说明 |
|------|------|
| 包含模块 | 全部 9 个安全模块（+Fail2Ban/Audit/用户管理/文件系统/服务管理/K3s） |
| 适用场景 | **2GB+ 内存**的标准云服务器 |

### 菜单差异

精简版主菜单中，完整版专属模块会标灰显示 `[仅在完整版中可用]` 标签，选择后会提示切换到完整版。

### 后续功能规划

所有新增功能将**只进入完整版**，精简版保持最小安全基线不变。

---

## 开发者指南 / Contributing

完整的开发者指南（TDD 流程、Git 工作流、代码规范、测试说明、ECC 命令）请参阅：

👉 **[`CONTRIBUTING.md`](CONTRIBUTING.md)**

主要链接速查：

| 内容 | 位置 |
|------|------|
| ShellCheck 静态检查 | `shellcheck -x scripts/**/*.sh` |
| Bats 单元测试 | `bats tests/unit/*.bats` |
| Docker Phase 1 测试 | `tests/docker/test-all.sh --phase 1` |
| Docker Phase 2 测试 | `tests/docker/test-all.sh --phase 2` |
| 计划文件规范 | `docs/plans/README.md` |

---

## 文档 / Documentation

| 文档 | 说明 |
|------|------|
| [项目 PRD](docs/design/linux-security-hardening-prd.md) | 项目需求与范围定义 |
| [Docker 测试方案](docs/design/docker-test-design.md) | Phase 1 + Phase 2 自动化测试设计 |
| [主菜单重构 v2](docs/design/main-menu-redesign-v2.md) | 主菜单 UI/UX 重设计（已实施） |
| [贡献指南](CONTRIBUTING.md) | 开发者指南、Git 工作流、ECC 命令 |
| [文档索引](docs/README.md) | 全部文档的统一入口 |
| [Code Review 报告](docs/code-reviews/) | 5 轮代码审查报告归档 |
| [测试报告](docs/test-reports/) | 测试结果归档 |
| [发布检查清单](docs/release-checklist.md) | v1.0 发布准备检查 |
| [交接文档](HANDOVER.md) | 项目进度与变更日志 |

---

## 安全注意事项 / Security Notes

> **请在测试环境先验证，再在生产环境使用。**

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
| LinuxMirrors（软件源更换） | https://github.com/SuperManito/LinuxMirrors |

---

## 版本历史 / Changelog

| 版本 | 日期 | 说明 |
|------|------|------|
| v1.0-alpha | 2026-07-12 | Docker Phase 1 测试通过（72/72），主菜单重构 v2，4 轮 Code Review |
| v0.4 | 2026-06-24 | 审计日志模块（auditd）、服务管理模块 |
| v0.3 | 2026-06-24 | 用户管理、内核安全加固、文件系统安全 |
| v0.2 | 2026-06-20 | 防火墙配置、Fail2Ban 入侵防护 |
| v0.1 | 2026-06-20 | 基础框架、SSH 安全加固、交互式向导、国际化 |

> 详细变更记录见 [HANDOVER.md](HANDOVER.md)

---

## License

[MIT](LICENSE) (c) [soeasy13142](https://github.com/soeasy13142)

---

## 致谢 / Acknowledgements

- [CIS Benchmarks](https://www.cisecurity.org/cis-benchmarks) — 安全配置基准
- [dev-sec/linux-baseline](https://github.com/dev-sec/linux-baseline) — Linux 安全基线参考
- [konstruktoid/hardening](https://github.com/konstruktoid/hardening) — Ubuntu 加固脚本参考
- [Bats](https://github.com/bats-core/bats-core) — Bash 自动化测试框架
- [ShellCheck](https://www.shellcheck.net/) — Shell 脚本静态分析工具
- [SuperManito/LinuxMirrors](https://github.com/SuperManito/LinuxMirrors) — 软件源更换功能（vendored，MIT，详见 [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)）

---
title: "Lite vs Full Mode — 精简版/完整版双模式设计"
status: active
created: 2026-07-24
updated: 2026-07-24
topic: "feature"
---

# Lite vs Full Mode 设计文档

## 1. 动机

用户通过 curl 管道安装时，希望有两种选择：

- **精简版 (Lite)**：只含最核心的安全加固功能，不启动额外守护进程，针对低内存云服务器优化
- **完整版 (Full)**：当前所有功能，后续新增功能只进完整版

## 2. 模块划分

### Lite 核心模块（零/极低内存开销）

| 模块 | 说明 | 内存开销 |
|------|------|----------|
| `base/utils.sh` | 日志、备份、工具函数 | 零 |
| `base/detect.sh` | 系统检测 | 零 |
| `base/init.sh` | 系统初始化（目录/时区/包更新） | 零 |
| `base/report.sh` | 安全报告 | 零 |
| `security/ssh.sh` | SSH 安全加固（端口/密钥/登录策略） | 零（纯配置修改） |
| `security/firewall.sh` | 防火墙（UFW/firewalld） | ~1 个轻量 daemon |
| `security/kernel.sh` | 内核参数 sysctl 加固 | 零（纯配置修改） |
| `lang/zh.sh` + `lang/en.sh` | 国际化 | 零 |

### Full 独占模块（Lite 不包含）

| 模块 | 说明 | 排除原因 |
|------|------|----------|
| `security/fail2ban.sh` | Fail2Ban 入侵防护 | Python 守护进程 ~50-100MB RSS |
| `security/audit.sh` | auditd 审计规则 | auditd 守护进程 ~20-50MB RSS |
| `security/users.sh` | 用户管理（创建/sudo/密钥） | 非安全基线需求 |
| `security/filesystem.sh` | 文件系统安全（SUID/权限） | 非安全基线需求 |
| `security/services.sh` | 服务管理（端口扫描/禁用） | 非安全基线需求 |
| `server/k3s.sh` | K3s Kubernetes 安装 | 重量级，非安全范畴 |

## 3. 架构设计

### 3.1 单入口，模式参数

保持一个 `install.sh` 入口点，通过 `--lite` 参数切换模式：

```bash
# 完整版（默认，与当前行为一致）
curl -fsSL https://.../install.sh | sudo bash

# 精简版
curl -fsSL https://.../install.sh | sudo bash -s -- --lite
```

bootstrap 过程中 `--lite` 参数被透传到最终执行的脚本。

### 3.2 模块注册表：`scripts/base/mode.sh`

新建文件，定义每个模块属于哪个层级：

```bash
# 层级定义
MODE_LITE_MODULES=(
  "ssh"
  "firewall"
  "kernel"
)
MODE_FULL_MODULES=(     # 仅在 full 模式下出现的模块
  "fail2ban"
  "audit"
  "users"
  "filesystem"
  "services"
  "k3s"
)
MODE_ALL_MODULES=(      # 所有模块（用于判断总进度）
  "ssh"
  "firewall"
  "kernel"
  "fail2ban"
  "audit"
  "users"
  "filesystem"
  "services"
  "k3s"
)
```

`install.sh` 根据 `INSTALL_MODE` 决定加载哪些模块和显示哪些菜单选项。

### 3.3 菜单系统变化

主菜单保持不变（1-12项），但 Lite 模式下：
- **快速开始** (`run_full_wizard`)：只执行 Lite 核心模块（ssh → firewall → kernel），跳过 full-only 模块
- **自定义菜单**：full-only 模块的菜单项不显示或显示为 "❌ 仅在完整版可用"
- **状态检测**：full-only 模块显示为 "N/A (Lite mode)"

### 3.4 后续功能扩展

- 所有新增模块自动归类到 `MODE_FULL_MODULES`
- 除非经过讨论确认是核心安全基线，否则不进 Lite
- 新增模块只需在 `mode.sh` 中注册，菜单/向导自动适配

### 3.5 实现方式

| 层面 | 实现 |
|------|------|
| CLI 解析 | `install.sh` 解析 `--lite`，设 `INSTALL_MODE="lite"`（默认 `"full"`）|
| 模块注册 | `scripts/base/mode.sh` 定义层级数组 |
| 菜单过滤 | 子菜单入口函数检查 `INSTALL_MODE`，跳过 full-only 模块 |
| 向导过滤 | `run_full_wizard` 在 Lite 模式下只迭代 `MODE_LITE_MODULES` |
| 状态检测 | `show_system_status` 对 full-only 模块输出 "N/A (Lite mode)" |
| i18n | 新增模式相关键：`MSG_MODE_LITE`, `MSG_MODE_FULL` 等 |

## 4. 测试

- **现有 259 Bats 测试不受影响**（所有模块函数依然被 source，只是菜单/向导有条件执行）
- 新增测试：`tests/unit/mode.bats` — 验证 MODE_* 数组定义、`--lite` 解析、菜单过滤行为
- Docker Phase 1/2：新增 Lite 运行场景（--lite 参数传透）

## 5. 文件变更清单

| 操作 | 文件 | 说明 |
|------|------|------|
| CREATE | `scripts/base/mode.sh` | 模块注册表，定义 Lite/Full 模块集合 |
| MODIFY | `install.sh` | 解析 --lite 参数；条件加载/显示模块；向导过滤 |
| MODIFY | `scripts/lang/zh.sh` | 新增模式 i18n 键 |
| MODIFY | `scripts/lang/en.sh` | 新增模式 i18n 键 |
| MODIFY | `README.md` | 文档新增 Lite 模式说明 |
| MODIFY | `HANDOVER.md` | 变更日志 |
| CREATE | `tests/unit/mode.bats` | 模式相关单元测试 |

## 6. Module Boundary 规则更新

| 模块 | 可以 source | 禁止 source |
|------|-------------|-------------|
| `scripts/base/mode.sh` | 无（无业务依赖） | 任何业务模块 |
| 其他模块 | 不变（见 CLAUDE.md） | 不变 |

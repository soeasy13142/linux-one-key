# Security Modules

安全加固模块，实现服务器的各项安全配置功能。

## 文件列表

| 文件 | 用途 | 状态 |
|------|------|------|
| `ssh.sh` | SSH 安全加固 | ✅ 完成 |
| `firewall.sh` | 防火墙配置 | ✅ 完成 |
| `fail2ban.sh` | Fail2Ban 入侵防护 | ✅ 完成 |
| `audit.sh` | 审计日志配置 | ✅ 完成 |
| `kernel.sh` | 内核安全参数 | ⬜ 规划中 (v0.3) |
| `filesystem.sh` | 文件系统安全 | ⬜ 规划中 (v0.3) |
| `services.sh` | 服务管理 | ⬜ 规划中 (v0.4) |

## 模块说明

### ssh.sh — SSH 安全加固

提供交互式 SSH 安全配置向导：

- **端口修改**: 自定义端口 / 随机端口 / 保持当前，端口占用检测
- **密钥生成**: Ed25519 密钥对生成，自动添加到 authorized_keys
- **禁止 root 登录**: 检查其他可登录用户后禁用
- **禁止密码登录**: 检查 SSH 密钥后禁用密码认证
- **安全参数**: MaxAuthTries, LoginGraceTime, ClientAliveInterval 等
- **回滚保护**: 配置修改后 5 分钟内自动回滚定时器

### firewall.sh — 防火墙配置

支持两种防火墙后端，自动根据操作系统选择：

| 操作系统 | 防火墙工具 |
|----------|-----------|
| Ubuntu / Debian | UFW |
| CentOS / RHEL / Rocky / Alma | firewalld |
| Fedora | firewalld |

功能：默认策略配置、端口开放/关闭、ICMP 控制、HTTP/HTTPS 快速开放。

### fail2ban.sh — Fail2Ban 入侵防护

自动安装并配置 Fail2Ban SSH 防护 jail：

- 自动检测认证日志路径（auth.log / secure）
- 根据操作系统选择 banaction（ufw / firewallcmd-ipset / iptables-multiport）
- 可自定义参数：封禁时间、检测窗口、最大重试次数
- 支持手动封禁/解封 IP

### audit.sh — 审计日志配置

自动安装并配置 auditd 系统审计框架，支持 3 个规则级别：

| 级别 | 监控范围 |
|------|----------|
| basic | 身份认证文件 + SSH 配置 + sudo 命令 |
| standard | 基础 + 网络配置 + cron + 日志防篡改 + 启动脚本 |
| full | 标准 + 权限变更 + 命令执行 + 内核模块 + 时间修改 + 挂载 + 文件删除 |

可自定义 auditd 参数：日志大小、保留份数。

## 通用模式

所有安全模块遵循统一的向导模式：

```
run_xxx_wizard() {
    1. 检查 root 权限
    2. 安装依赖软件
    3. 交互式收集用户配置
    4. 备份现有配置
    5. 应用新配置
    6. 启用/重启服务
    7. 显示状态和管理提示
}
```

## 依赖

所有模块都依赖 `scripts/base/utils.sh`（通过 source guard 检查）。

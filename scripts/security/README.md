# Security Modules

安全加固模块，实现服务器的各项安全配置功能。

## 文件列表

| 文件 | 用途 | 状态 |
|------|------|------|
| `ssh.sh` | SSH 安全加固 | ✅ 完成 |
| `firewall.sh` | 防火墙配置 | ✅ 完成 |
| `fail2ban.sh` | Fail2Ban 入侵防护 | ✅ 完成 |
| `audit.sh` | 审计日志配置 | ✅ 完成 |
| `users.sh` | 用户管理 | ✅ 完成 |
| `kernel.sh` | 内核安全加固（sysctl） | ✅ 完成 |
| `filesystem.sh` | 文件系统安全 | ✅ 完成 |
| `services.sh` | 服务管理 | ✅ 完成 |

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

### users.sh — 用户管理

交互式用户创建和管理向导：

- 创建新用户并设置密码
- 为用户生成 SSH Ed25519 密钥对
- 配置 sudo NOPASSWD 权限
- 创建前自动检查用户名冲突和密码强度

### kernel.sh — 内核安全加固

基于 CIS Benchmark 的 sysctl 安全参数配置：

- 网络协议安全（禁用 IP 转发、SYN cookies、反向路径过滤等）
- 内存保护（ASLR、禁止 core dump、dmesg 限制）
- 日志记录（内核 panic 自动重启、BPF 限制）
- 禁用不必要的内核模块（cramfs、freevxfs、hfs、udf 等）
- 配置前自动备份原始参数，支持一键回滚

### filesystem.sh — 文件系统安全

文件系统安全检查和加固：

- 全局 SUID/SGID 文件审计（扫描 /usr、/bin、/sbin 等）
- 扫描无主文件和目录（无有效 owner 的文件）
- 检查关键目录权限（/etc/passwd、/etc/shadow、/etc/gshadow 等）
- 发现问题后提供修复建议
- 结果写入日志文件，支持后续审计

### services.sh — 服务管理

审计运行中的服务、禁用不必要的服务、扫描开放端口：

- 审计所有 systemd 运行中的服务
- 检测并交互式禁用不必要服务（telnet、rsh、rlogin、vsftpd、avahi-daemon、cups、rpcbind）
- 使用 `ss`/`netstat` 扫描监听端口，标记非标准端口并警告
- 可自定义安全端口列表（默认 22/80/443）
- 支持 `/proc/net/tcp` fallback

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

## 依赖关系

| 模块 | 依赖 |
|------|------|
| `ssh.sh` | `utils.sh` |
| `firewall.sh` | `utils.sh` |
| `fail2ban.sh` | `utils.sh` |
| `audit.sh` | `utils.sh` |
| `users.sh` | `utils.sh` |
| `kernel.sh` | `utils.sh` |
| `filesystem.sh` | `utils.sh` |
| `services.sh` | `utils.sh` |

所有模块都依赖 `scripts/base/utils.sh`（通过 source guard 检查）。模块之间无相互依赖，可独立运行。

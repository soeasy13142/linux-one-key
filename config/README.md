# Config

配置文件模板目录。

## 目录结构

```
config/
├── audit/              # 审计日志配置模板
│   ├── audit.rules     # 审计规则模板（full 级别示例）
│   └── auditd.conf     # auditd 主配置模板
├── fail2ban/           # Fail2Ban 配置模板
│   └── jail.local      # Fail2Ban jail 配置模板
└── .gitkeep            # Git 占位文件
```

## 用途说明

此目录存放各安全模块的**参考配置模板**。

> **注意**: 这些模板仅作参考和文档用途。实际运行时，脚本会根据用户交互选择的参数**动态生成**配置文件，而不是直接复制这些模板。

## 模板与实际配置的关系

| 模板文件 | 生成脚本 | 实际安装路径 |
|----------|----------|-------------|
| `audit/audit.rules` | `scripts/security/audit.sh` | `/etc/audit/rules.d/audit.rules` |
| `audit/auditd.conf` | `scripts/security/audit.sh` | `/etc/audit/auditd.conf` |
| `fail2ban/jail.local` | `scripts/security/fail2ban.sh` | `/etc/fail2ban/jail.local` |

## 规划中的配置

```
config/
├── ssh/                # SSH 配置模板
│   └── sshd_config     # SSH 安全配置模板
└── sysctl/             # 内核参数模板
    └── 99-security.conf # sysctl 安全参数
```

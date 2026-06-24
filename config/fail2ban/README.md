# Fail2Ban Config Templates

Fail2Ban 入侵防护配置模板。

## 文件列表

| 文件 | 用途 |
|------|------|
| `jail.local` | Fail2Ban jail 配置模板 |

## jail.local

Fail2Ban SSH 防护 jail 配置模板，包含：

- **默认策略**: 封禁时间 3600 秒、检测窗口 600 秒、最大重试 5 次
- **SSH 防护**: 监控 SSH 登录失败，自动封禁恶意 IP
- **可选扩展**: Nginx HTTP 认证防护、Postfix SMTP 防护、重复封禁（注释状态）

## 模板变量

模板中的占位符由 `scripts/security/fail2ban.sh` 替换：

| 占位符 | 说明 | 示例值 |
|--------|------|--------|
| `{ssh_port}` | SSH 端口 | 22, 2222 |
| `{auth_log_path}` | 认证日志路径 | /var/log/auth.log |

## 使用方式

此模板仅作参考。实际配置由 `scripts/security/fail2ban.sh` 的 `run_fail2ban_wizard()` 根据用户交互动态生成，并自动选择适合当前操作系统的 `banaction`。

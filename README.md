# Linux One-Key

Linux 云服务器安全加固一键脚本。

## 快速开始

```bash
# 一键执行（推荐）
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash

# 非交互模式（自动确认所有步骤）
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash -s -- --yes

# 仅执行 SSH 加固
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash -s -- --ssh

# 或者下载后执行
wget https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 功能特性

- ✅ SSH 安全加固（端口修改、密钥认证、禁止 root/密码登录）
- ✅ 防火墙配置（UFW/firewalld）
- ✅ Fail2Ban 入侵防护
- ⬜ 用户管理（v0.3）
- ⬜ 内核安全加固（v0.3）
- ⬜ 审计日志（v0.4）

## 支持系统

- CentOS 7+
- Ubuntu 20.04+
- Debian 11+
- Rocky Linux 8/9
- AlmaLinux 8/9

## 开发

```bash
# 运行测试
bats tests/unit/*.bats

# ShellCheck 检查
shellcheck -x scripts/**/*.sh
```

## 许可证

MIT

# Linux One-Key

Linux 云服务器安全加固一键脚本。

## 快速开始

```bash
# 交互执行（推荐）
curl -fsSL https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh | sudo bash

# 或者下载后执行
wget https://raw.githubusercontent.com/soeasy13142/linux-one-key/main/install.sh
chmod +x install.sh
sudo ./install.sh
```

## 功能特性

- ✅ SSH 安全加固（端口修改、密钥认证、禁止 root/密码登录）
- ✅ 防火墙配置（UFW/firewalld）
- ✅ Fail2Ban 入侵防护
- ✅ 审计日志（auditd，3 级规则）
- ✅ 用户管理（创建用户、SSH 密钥、sudo 配置）
- ✅ 内核安全加固（sysctl 参数、内核模块禁用）
- ✅ 文件系统安全（权限检查、SUID 审计、无主文件扫描）

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

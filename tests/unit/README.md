# Unit Tests

Bats 单元测试文件目录。

## 测试文件

| 文件 | 测试模块 | 用例数 | 覆盖范围 |
|------|----------|--------|----------|
| `utils.bats` | `scripts/base/utils.sh` | 19 | 颜色定义、日志函数、备份/恢复、SSH 配置、端口检查、命令检查 |
| `ssh.bats` | `scripts/security/ssh.sh` | 16 | 端口验证、其他用户检查、SSH 密钥检查 |
| `firewall.bats` | `scripts/security/firewall.sh` | 9 | 防火墙类型检测、UFW/firewalld 命令 |
| `fail2ban.bats` | `scripts/security/fail2ban.sh` | 18 | 安装、配置生成、服务管理、封禁/解封 |
| `audit.bats` | `scripts/security/audit.sh` | 45 | 常量定义、规则生成（3 级别）、配置生成、函数存在性 |
| `users.bats` | `scripts/security/users.sh` | 33 | 用户创建、密码验证、SSH 密钥、sudo 配置 |
| `kernel.bats` | `scripts/security/kernel.sh` | 20 | sysctl 参数生成、模块禁用、回滚 |
| `filesystem.bats` | `scripts/security/filesystem.sh` | 23 | SUID 审计、无主文件扫描、权限检查 |

**总计: 183 个测试用例**

## 测试结构

每个 Bats 文件遵循统一结构：

```bash
#!/usr/bin/env bats

# 测试前设置
setup() {
    # 创建临时目录
    export TEST_DIR="$(mktemp -d)"
    # 设置脚本目录
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    # 加载依赖
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    # Mock 系统变量
    export DETECTED_OS="ubuntu"
}

# 测试后清理
teardown() {
    rm -rf "${TEST_DIR}"
}

# 测试用例
@test "函数名 描述" {
    # Arrange
    # Act
    # Assert
}
```

## 运行单个测试

```bash
# 运行指定文件
bats tests/unit/audit.bats

# 运行并显示标准输出
bats -t tests/unit/ssh.bats
```

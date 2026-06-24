# Tests

项目测试目录。

## 目录结构

```
tests/
├── unit/               # 单元测试（Bats 框架）
│   ├── utils.bats      # 工具函数测试 (19 个用例)
│   ├── ssh.bats        # SSH 模块测试 (16 个用例)
│   ├── firewall.bats   # 防火墙模块测试 (9 个用例)
│   ├── fail2ban.bats   # Fail2Ban 模块测试 (18 个用例)
│   └── audit.bats      # 审计模块测试 (45 个用例)
├── integration/        # [规划中] 集成测试
└── .gitkeep
```

## 测试框架

使用 [Bats](https://github.com/bats-core/bats-core)（Bash Automated Testing System）进行单元测试。

## 运行测试

```bash
# 运行所有单元测试
bats tests/unit/*.bats

# 运行单个测试文件
bats tests/unit/utils.bats

# 运行并显示详细输出
bats -t tests/unit/*.bats
```

## 测试规范

- 测试文件命名为 `<模块名>.bats`
- 每个测试用例独立运行，使用 `setup()` 和 `teardown()` 管理临时环境
- 使用临时目录（`mktemp -d`）隔离测试，避免影响系统
- Mock 系统命令（`systemctl`, `apt-get` 等）避免实际执行
- 测试覆盖：函数存在性、参数验证、边界条件、错误处理

## 依赖安装

```bash
# macOS
brew install bats-core

# Ubuntu/Debian
sudo apt-get install bats

# CentOS/RHEL
sudo yum install bats
```

## 目标覆盖率

项目目标测试覆盖率 **80%+**。

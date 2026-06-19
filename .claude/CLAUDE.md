# Linux One-Key

Linux 一键安装脚本项目。

## 项目概述

提供 Linux 系统（主要面向 CentOS/Ubuntu/Debian）的一键环境初始化和软件安装脚本。

## 开发规范

- Shell 脚本使用 Bash，首行 `#!/usr/bin/env bash`
- 所有脚本必须设置 `set -euo pipefail`
- 函数命名使用 `snake_case`，常量使用 `UPPER_SNAKE_CASE`
- 每个函数必须有注释说明用途
- 脚本需兼容主流发行版（CentOS 7+, Ubuntu 20.04+, Debian 11+）
- 输出信息使用颜色区分：绿色=成功，红色=错误，黄色=警告，蓝色=信息

## 项目结构

```
linux-one-key/
├── scripts/          # 安装脚本目录
│   ├── base/         # 基础环境配置
│   ├── dev/          # 开发工具安装
│   ├── server/       # 服务器软件安装
│   └── utils/        # 通用工具函数
├── config/           # 配置文件模板
├── docs/             # 文档
└── tests/            # 测试脚本
```

## 测试

- 使用 ShellCheck 进行静态检查
- 使用 Bats 进行单元测试

## 交接文档（强制）

**每次修改项目文件时，必须同步更新 `HANDOVER.md`。**

交接文档包含：
- 项目当前进度和状态
- 已完成的工作记录
- 文件清单（当前文件 + 计划文件）
- 技术决策记录
- 下一步工作建议
- 变更日志

规则详见 `.claude/rules/common/handover.md`。

# Linux One-Key

Linux 一键安装脚本集合，快速初始化服务器环境和安装常用软件。

## 特性

- 支持主流 Linux 发行版（CentOS、Ubuntu、Debian）
- 模块化设计，按需安装
- 自动检测系统环境
- 彩色输出，安装过程清晰可见
- 支持离线安装模式

## 快速开始

```bash
# 下载并执行
curl -fsSL https://example.com/setup.sh | bash

# 或者克隆后执行
git clone https://github.com/yourname/linux-one-key.git
cd linux-one-key
bash scripts/install.sh
```

## 目录结构

```
linux-one-key/
├── scripts/          # 安装脚本
│   ├── base/         # 基础环境配置
│   ├── dev/          # 开发工具
│   ├── server/       # 服务器软件
│   └── utils/        # 工具函数
├── config/           # 配置模板
├── docs/             # 文档
└── tests/            # 测试
```

## 支持的软件

（待补充）

## 许可证

MIT License

# Scripts

脚本目录，包含项目所有 Shell 脚本模块。

## 目录结构

```
scripts/
├── base/           # 基础框架模块（工具函数、系统检测、初始化、报告）
├── security/       # 安全加固模块（SSH、防火墙、Fail2Ban、审计日志）
├── lang/           # 国际化语言文件（中文、英文）
├── dev/            # [规划中] 开发工具安装
├── server/         # [规划中] 服务器软件安装
└── utils/          # [规划中] 通用工具函数
```

## 模块加载顺序

脚本之间存在依赖关系，必须按以下顺序加载：

```
utils.sh → lang/*.sh → detect.sh → init.sh → security/*.sh → report.sh
```

每个模块都使用 source guard（`_XXX_LOADED` 变量）防止重复加载。

## 依赖关系

| 模块 | 依赖 |
|------|------|
| `base/utils.sh` | 无（基础模块） |
| `lang/*.sh` | 无（纯变量定义） |
| `base/detect.sh` | `utils.sh` |
| `base/init.sh` | `utils.sh`, `detect.sh` |
| `base/report.sh` | `utils.sh`, `detect.sh` |
| `security/ssh.sh` | `utils.sh` |
| `security/firewall.sh` | `utils.sh` |
| `security/fail2ban.sh` | `utils.sh` |
| `security/audit.sh` | `utils.sh` |

## 编码规范

- 首行 `#!/usr/bin/env bash`
- 设置 `set -eo pipefail`（不使用 `-u`，避免未绑定变量导致意外退出）
- 函数命名 `snake_case`，常量 `UPPER_SNAKE_CASE`
- 每个函数必须有注释说明用途
- 输出使用颜色区分：绿色=成功，红色=错误，黄色=警告，蓝色=信息
- 所有日志输出到 stderr（`>&2`），避免污染 stdout（影响命令替换）

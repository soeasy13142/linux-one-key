---
name: feature-development
description: 安全加固功能开发工作流
allowed_tools: ["Bash", "Read", "Write", "Grep", "Glob"]
---

# /feature-development

Use this workflow when working on **安全加固功能** in `linux-one-key`.

## Goal

Shell 脚本功能开发，遵循项目开发规范。

## Common Files

- `scripts/**/*.sh`
- `config/**`
- `tests/**/*.bats`

## Suggested Sequence

1. 阅读 `HANDOVER.md` 了解当前进度
2. 阅读 `.claude/prds/linux-security-hardening.prd.md` 了解需求
3. 实现功能，遵循开发规范：
   - 首行 `#!/usr/bin/env bash`，紧跟 `set -euo pipefail`
   - 函数命名 `snake_case`，常量 `UPPER_SNAKE_CASE`
   - 每个函数必须有注释
   - 输出用颜色区分
4. 运行 ShellCheck 静态检查
5. 编写 Bats 测试
6. 更新 `HANDOVER.md`

## Typical Commit Signals

- Add security hardening feature
- Add tests for feature
- Update documentation
- Update HANDOVER.md

## Notes

- 每次修改必须同步更新 `HANDOVER.md`
- 修改配置文件前必须备份
- 兼容 CentOS 7+/Ubuntu 20.04+/Debian 11+

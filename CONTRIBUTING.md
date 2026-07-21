# Contributing to Linux One-Key

感谢您对项目的关注！本文档包含开发流程、测试规范、Git 工作流等开发者指南。

---

## Development Workflow

### 1. Plan First

对于任何稍复杂的任务，先创建计划文件：

```bash
docs/plans/YYYY-MM-DD_HH-MM_<topic-kebab>_nogit.md
```

详见 [`docs/plans/README.md`](docs/plans/README.md)。

### 2. TDD Approach

强制流程（RED → GREEN → IMPROVE）：

1. 在 `tests/unit/` 下编写 Bats 测试
2. 运行测试——应该失败
3. 编写最小实现
4. 运行测试——应该通过
5. 重构
6. 验证覆盖率 80%+

### 3. Code Review

写入代码后立即审查：

- CRITICAL — 必须修复（安全漏洞、数据丢失风险）
- HIGH — 应修复（bug、重大质量问题）
- MEDIUM — 考虑修复（可维护性）
- LOW — 建议（风格、小改进）

使用 ECC 命令：`/code-review`、`/security-scan`（`scripts/security/*` 修改后强制）。

### 4. Commit & Push

详见下方 Git Workflow。

---

## Testing

```bash
# ShellCheck 静态检查
shellcheck -x scripts/**/*.sh
shellcheck -x install.sh

# Bats 单元测试
bats tests/unit/*.bats

# 单模块测试
bats tests/unit/ssh.bats

# Docker Phase 1 测试（9 发行版 × 8 模块 = 72 用例）
tests/docker/test-all.sh --phase 1

# Docker Phase 2 服务验证（3 发行版 × 7 模块 = 21 用例）
tests/docker/test-all.sh --phase 2
```

### 环境准备

```bash
# macOS
brew install shellcheck bats-core

# Ubuntu / Debian
sudo apt install shellcheck
sudo apt install bats       # 或从源码安装

# CentOS / RHEL
sudo yum install shellcheck
# bats 需要从源码安装
```

---

## Code Conventions

| 规范 | 说明 |
|------|------|
| Shebang | 首行 `#!/usr/bin/env bash`，紧跟 `set -euo pipefail` |
| 函数命名 | `snake_case`，如 `run_ssh_wizard`、`detect_os` |
| 常量命名 | `UPPER_SNAKE_CASE`，如 `SUPPORTED_OS`、`SSH_SERVICE_NAME` |
| 函数注释 | 每个函数必须有注释说明用途 |
| 输出颜色 | 使用 `utils.sh` 的 `log_*` 函数，不直接 `echo` |
| i18n | 所有用户可见文本使用 `MSG_*` 翻译变量，不硬编码 |
| 备份 | 修改配置文件前必须备份原文件 |

### 添加新模块

1. 在 `scripts/security/` 下创建新脚本（如 `newmodule.sh`）
2. 在 `scripts/lang/zh.sh` 和 `scripts/lang/en.sh` 中添加翻译
3. 在 `install.sh` 中集成（load_dependencies、菜单项、状态检测）
4. 在 `tests/unit/` 下创建对应的 `.bats` 测试文件
5. 运行 `shellcheck` 和 `bats` 确认无报错

---

## Git Workflow

### Commit Message Format

```
<type>: <description>

<optional body>
```

Types: `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `perf`, `ci`

### Local Commit Frequency（尽量高频）

每个独立逻辑单元完成后立即 commit：

| 触发条件 | 示例 |
|----------|------|
| 完成一个独立逻辑单元 | 写完一个函数 / 一个 shell 脚本 / 一个测试用例 |
| 每次会话多个变更 | 每 2-3 个改动 commit 一次 |
| 结构性变更 | 目录移动 / 文件重命名 |
| 阶段性改进 | 每加一个新功能 / 修复一类问题 |
| Code Review 修复 | CRITICAL 一起一次 / HIGH 一类一个 commit |
| 文档/配置同步 | HANDOVER.md / CLAUDE.md 变更 |

### Push Policy

1. 询问用户是否要 push（**未经允许绝不 push**）
2. 整理本地 commit：`git rebase -i HEAD~N`（squash/fixup 合并）
3. 整理后每个 commit 自洽（shellcheck + bats 通过）
4. **绝不 force push 到 main**

---

## Phased Improvement Workflow

大型项目改进按阶段推进，避免一次性大批量改动：

1. 阶段开始前在 `docs/plans/` 创建 plan 文件（status: draft）
2. 与用户对齐后改 `status: in-progress`
3. 阶段内小步前进，每个最小改动单元单独 commit
4. 阶段完成时更新 plan frontmatter（status: done）和 HANDOVER.md
5. 不跨阶段合并 commit

---

## ECC Plugin Usage

本项目启用 ECC (everything-claude-code) 插件。常用命令：

| 命令 | 触发时机 |
|------|----------|
| `/plan` | 复杂任务启动前 |
| `/code-review` | 重要变更后 |
| `/security-scan` | 修改 `scripts/security/*` 后**强制** |
| `/quality-gate` | push 前 |
| `/build-fix` | shellcheck / bats 失败时 |
| `/refactor-clean` | 月度维护 |

> 完整清单见 [ECC 官方文档](https://github.com/affaan-m/ECC/blob/main/README.zh-CN.md)。

---

## 参考资料

| 资源 | 链接 |
|------|------|
| CIS Benchmarks | https://www.cisecurity.org/cis-benchmarks |
| OpenSSH 文档 | https://man.openbsd.org/sshd_config |
| STIG 安全指南 | https://public.cyber.mil/stigs/ |
| Fail2Ban 文档 | https://github.com/fail2ban/fail2ban/wiki |
| dev-sec Hardening | https://dev-sec.io/ |

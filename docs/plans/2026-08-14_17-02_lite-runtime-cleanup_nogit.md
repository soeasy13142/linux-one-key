---
title: "Lite 版运行痕迹清理功能"
created: 2026-08-14
updated: 2026-08-14
status: done
source: "用户需求（brainstorm）：lite 版运行结束后清理所有产生的文件"
topic: "feature"
---

## 背景

Lite 模式（SSH + Firewall + Kernel + 换源）运行后，脚本会在系统里留下运行痕迹：

| 痕迹 | 位置 |
|------|------|
| 日志 | `/var/log/linux-one-key/hardening_<ts>.log`（或 fallback `/tmp/linux-one-key/`） |
| 备份 | `/var/log/linux-one-key/backups/` |
| 报告 | `/var/log/linux-one-key/reports/` |
| SSH 临时文件 | `/tmp/.ssh-askpass-*`、`/tmp/.ssh-monitor-*` |

bootstrap 临时目录（下载的仓库）已通过 `_CLEANUP_DIR` 在 EXIT trap 中清理 ✅，其余痕迹残留。

目标用户：低配云服务器一次性加固，希望"加固完成、不留脚本痕迹"。

## 目标

- Lite 模式**正常退出**前，询问是否清理脚本运行痕迹（日志/备份/报告 + `/tmp` 临时文件），默认清理。
- **保留**加固配置本身（SSH 配置、防火墙规则、sysctl、时区、软件源）。
- 异常/中断（Ctrl+C、脚本错误）不清理、保留现场，便于排查。
- 清理过程幂等、失败容忍，绝不误删用户文件。

## 设计决策（已与用户确认）

| 决策 | 选择 | 原因 |
|------|------|------|
| 清理边界 | 只清理脚本痕迹（LOG_DIR + /tmp askpass/monitor），保留加固配置 | 加固配置是脚本目的 |
| 触发时机 | 正常退出前询问确认，默认 Y（`[Y/n]`） | 失败时可选 n 保留日志排查 |
| 异常/中断 | 不询问、保留痕迹 | INT/TERM/ERR 仍走 `_cleanup_on_exit`，现状不动 |
| 实现方案 | **方案 A：独立 `scripts/base/cleanup.sh`** | 符合 many-small-files 规范、可单测、清单集中管理 |
| 回滚配套 | 清理前 `cancel_rollback_timer`（若活跃） | 否则回滚定时器到点找不到备份 |
| 已知代价 | 清理后失去手动回滚能力 | 用户已确认接受 |
| Full 模式 | 不接入 | 备份中心[17]/仪表盘[18]依赖这些文件 |

## 执行步骤

- [ ] 1. 新建 `scripts/base/cleanup.sh`
      - source guard `_CLEANUP_LOADED`；依赖检查 `_UTILS_LOADED`
      - 常量 `CLEANUP_LOG_DIR="${LOG_DIR}"`、`CLEANUP_TMP_PATTERNS=( "/tmp/.ssh-askpass-*" "/tmp/.ssh-monitor-*" )`
      - `_cancel_active_rollback()`：`declare -F cancel_rollback_timer && cancel_rollback_timer`（base 层不硬 import security）
      - `cleanup_lite_traces()`：① 取消回滚定时器 ② `rm -f` tmp 模式（nullglob 防空 glob）③ `rm -rf "${LOG_DIR}"`；每步失败 `log_warn` 继续，返回 0；幂等
- [ ] 2. i18n：`scripts/lang/zh.sh` + `en.sh` 新增 `MSG_CLEANUP_PROMPT` / `MSG_CLEANUP_DONE` / `MSG_CLEANUP_PARTIAL` / `MSG_CLEANUP_SKIPPED`（zh/en 对称）
- [ ] 3. `install.sh` 接入：
      - `load_dependencies()`（mode.sh 后）Lite-gated source cleanup.sh（与 swap.sh 的 Full-gated 对称）
      - `cleanup_and_exit()`（Lite 分支）：`confirm "${MSG_CLEANUP_PROMPT}" "y"` 为真 → `cleanup_lite_traces`
- [ ] 4. 新建 `tests/unit/cleanup.bats`（7 用例：正常/幂等/不存在/不误删/失败容忍/回滚取消/fallback 路径）
- [ ] 5. `shellcheck -x scripts/**/*.sh` + `bats tests/unit/*.bats` 全绿（795 → 802）
- [ ] 6. 文档：`HANDOVER.md`（里程碑/决策/下一步）+ `README.md`（Lite 模式说明补一句）+ `docs/handover-archive.md` 归档
- [ ] 7. 版本 bump v1.7.0 → **v1.8.0**（HANDOVER/README 版本号同步）

## 预期产出

**新增文件：**
- `scripts/base/cleanup.sh`（~80-120 行）
- `tests/unit/cleanup.bats`（~120 行）

**修改文件：**
- `scripts/lang/zh.sh`、`scripts/lang/en.sh`（+4 个 MSG_CLEANUP_* 变量）
- `install.sh`（load_dependencies + cleanup_and_exit）
- `HANDOVER.md`、`README.md`、`docs/handover-archive.md`
- 版本号相关引用

## 风险与注意事项

- **删除备份 = 失去手动回滚能力**（已确认接受）；需同步取消活跃回滚定时器，避免定时器到点 `rollback_ssh` 找不到备份。
- **不误删**：`/tmp` 用精确前缀模式（askpass/monitor），`rm` 全部精确路径；`LOG_DIR` 删前判存在。
- **`--status` 只读模式不接入清理**（诊断用途，日志保留）。
- **失败容忍**：任何删除失败仅 `log_warn`，不中断退出流程（`cleanup_and_exit` 总是成功退出）。
- **幂等**：清单项逐项判存在，重复调用安全。
- LOG_DIR fallback（`/tmp/linux-one-key`，当 `/var/log` 不可写时）经 `CLEANUP_LOG_DIR="${LOG_DIR}"` 自动覆盖。

## 进度记录

- 2026-08-14: 创建计划，status=draft（brainstorm 完成，设计经用户逐节确认）
- 2026-08-14: 完成（实现 805 Bats 全绿，ShellCheck 干净；文档/版本 bump v1.8.0 同步），status=done

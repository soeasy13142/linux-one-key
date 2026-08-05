---
title: "移植 LinuxMirrors 完整交互换源功能为新菜单选项 [19]"
created: 2026-08-05
updated: 2026-08-05
status: done
source: "用户需求 — 复制 SuperManito/LinuxMirrors（MIT）完整版交互换源，作为本项目新菜单选项；交互与选项按 LinuxMirrors 一模一样"
topic: "server-module"
---

## 背景

用户希望把开源项目 [SuperManito/LinuxMirrors](https://github.com/SuperManito/LinuxMirrors)（**MIT License**）的换源功能并入本项目 `linux-one-key`，作为主菜单新增选项 **[19] 更换软件源**。已通过 AskUserQuestion 确认三个决策：

1. **交互版本**：复刻**完整版** `ChangeMirrors.sh` 的标志性交互（交互选择镜像站列表 / HTTP/HTTPS / EPEL / 升级软件包），而非精简版（无交互、默认官方源）。
2. **可用模式**：**精简版 + 完整版全模式可用**（不 Gate 为 Full-only）。
3. **文本 i18n**：交互文本**接入项目 MSG_* 双语体系**，文案从 LinuxMirrors 语言包原样搬进 `zh.sh`/`en.sh`，跟随 `LANG_CODE` 切换。

许可合规：MIT 要求保留版权声明 → 新增 `THIRD_PARTY_NOTICES.md` 收录 LinuxMirrors MIT 全文 + 出处，README 加致谢。

## 目标

- 主菜单新增 [19] 更换软件源（全模式可见），进入后为项目风格子菜单，内含「换源（完整交互）」「恢复官方源」「查看当前源」。
- 换源核心逻辑 100% 来自 LinuxMirrors `ChangeMirrors.sh`（所有发行版支持、repo 生成器、交互流程原样保留）。
- 脚本间兼容性：通过 **subshell 隔离** + **msg() 重定向到 MSG_*** 实现，零命名冲突、零宿主污染。
- 合规声明 + 测试 + ShellCheck + commit。

## 架构设计

### 文件布局

```
scripts/server/mirror.sh                 # 集成模块（项目风格，~200 行）【新增】
scripts/server/mirrors/lm_core.sh        # LinuxMirrors 核心（vendored ~8800 行）【新增】
scripts/lang/zh.sh                       # 追加 MSG_MIRROR_*（~250 键，源 zh-hans 包）
scripts/lang/en.sh                       # 追加 MSG_MIRROR_*（~250 键，源 en 包）
install.sh                               # 接线 option 19（source / 渲染 / 范围 / case）
tests/unit/mirror.bats                   # 单元测试【新增】
THIRD_PARTY_NOTICES.md                   # 第三方声明【新增】
README.md                                # 致谢 + 特性表
HANDOVER.md                              # 状态快照更新
```

### 兼容性策略（核心）

**不要直接 source LinuxMirrors 进宿主**。侦察发现：全局变量（`SOURCE`/`BACKUP`/`INPUT`/`RED`/`GREEN`/`SUCCESS`…）、通用函数名（`main`/`msg`/`cleanup`/`backup_file`/`read_key`…）、嵌套函数重定义、`trap`、`exit` 都与宿主高度冲突。方案：

1. **subshell 隔离**：`run_mirror_flow()` 在 `( ... )` 内 `source lm_core.sh` 再调 `lm_main "$@"`。LinuxMirrors 的全部"全局变量/函数"只存在于 subshell 副本中，**不进宿主作用域** → 零命名冲突。
2. **关闭 e/u/pipefail**：subshell 开头 `set +e +u +o pipefail`，保证 vendored 代码的 `$?` 显式判断、假兜底写法不触发 `set -e` 意外退出；退出时不影响宿主 flags。
3. **exit 安全**：vendored 的 `output_error`/`cleanup` 调 `exit` 只退出 subshell（返回非零），**不会杀死 install.sh**。
4. **trap 隔离**：交互函数的 `trap cleanup INT TERM` 局限在 subshell 内。
5. **i18n 重定向**：把 `lm_core.sh` 的 msg 层替换为「读 `MSG_MIRROR_*` 环境变量」实现，键映射规则：`msg "interaction.source.select"` → 变量 `MSG_MIRROR_INTERACTION_SOURCE_SELECT`（点→下划线、转大写、加 `MSG_MIRROR_` 前缀）。宿主已加载的 `MSG_*`（来自 zh.sh/en.sh）被子 shell 继承，可直接 `${!varname}` 取值。`{}` 占位符替换逻辑与 LinuxMirrors 原版一致。
6. **不自动执行**：删除 lm_core.sh 尾部 `init_msg_pack; handle_command_options "$@"; main`，改为入口函数 `lm_main()`；文件只在 subshell 内被 source。
7. `choose_display_language` 仅在 `--lang auto` 时触发（主流程不调用）→ 不动它，语言完全由项目 `LANG_CODE` 决定。

### mirror.sh 集成模块接口（供 install.sh 引用）

| 函数 | 职责 |
|------|------|
| `show_mirror_submenu` | 渲染子菜单（MSG_MIRROR_MENU_*） |
| `run_mirror_submenu_loop` | 子菜单循环：1)换源 2)恢复官方源 3)查看当前源 0)返回 |
| `run_mirror_flow <args...>` | subshell 包装，`source lm_core.sh && lm_main "$@"`；无参=完整交互换源；`--use-official-source`=恢复官方源 |
| `show_current_sources` | 按 `get_package_manager` 打印当前源文件（apt/yum/dnf 分支） |

### i18n 键清单

- **主菜单**：`MSG_MAIN_MENU_MIRROR`、`MSG_MAIN_MENU_MIRROR_DESC`
- **子菜单**：`MSG_MIRROR_MENU_TITLE`、`MSG_MIRROR_MENU_CHANGE_SOURCE`、`MSG_MIRROR_MENU_RESTORE_OFFICIAL`、`MSG_MIRROR_MENU_VIEW_SOURCE`、`MSG_MIRROR_MENU_BACK`、`MSG_MIRROR_MENU_PROMPT`、`MSG_MIRROR_MENU_INVALID`
- **换源交互文本**：`MSG_MIRROR_*`，从 ChangeMirrors.sh 的 `msg_pack_zh_hans`（→zh.sh）/ `msg_pack_en`（→en.sh）逐键复制，键名映射规则见上。两语言**键集必须完全对称**。

## 执行步骤

- [ ] **S1 侦察**：完成（两边结构、兼容性风险已评估）。
- [ ] **S2 Plan**：本文件。
- [ ] **S3-A 移植核心**：`cp /tmp/LinuxMirrors/ChangeMirrors.sh → scripts/server/mirrors/lm_core.sh`；替换 msg 层（`msg()`/`init_msg_pack()` 及三个 `msg_pack_*` 语言包为 MSG_MIRROR_* 解析版）；尾部 `init_msg_pack; handle_command_options "$@"; main` → `lm_main()`；`bash -n` 验证。
- [ ] **S3-B 语言键**：用 python 脚本机械解析 ChangeMirrors.sh 的 `msg_pack_zh_hans`/`msg_pack_en`，生成 `MSG_MIRROR_*` 键追加到 zh.sh/en.sh（保持文件双引号风格、转义正确）；同时追加主菜单/子菜单 9 个手工键；校验 zh/en 键集对称 + 计数对齐 + `bash -n`。
- [ ] **S3-C 集成模块**：写 `scripts/server/mirror.sh`（头注释含 MIT 归属 + THIRD_PARTY_NOTICES 指引；`_UTILS_LOADED` 检查；`run_mirror_flow` subshell 包装；子菜单；root 检查；`readonly _MIRROR_LOADED=1`）。
- [ ] **S4 接线 install.sh**：`load_dependencies` source mirror.sh；`show_main_menu` 运维工具区渲染 [19]（全模式，无 is_mode_lite 灰显）；`get_main_menu_choice` 范围 `0-18`→`0-19`、`1[0-8]`→`1[0-9]`；`run_main_menu_loop` 加 `19) run_mirror_submenu_loop`。
- [ ] **S5 测试**：`tests/unit/mirror.bats` 仿 k3s.bats——函数存在性、i18n 键（zh+en、含「lm_core 里每个 `msg "key"` 都有对应 MSG_MIRROR_*」完整性检查）、常量、非 root 拒绝、子菜单输出、加载标记、`run_mirror_flow` 隔离性（mock lm_core 验证 subshell 内变量不泄漏）。
- [ ] **S6 合规声明**：`THIRD_PARTY_NOTICES.md`（LinuxMirrors MIT 全文 + 来源 + 改动说明）；README 致谢/参考资料加行。
- [ ] **S7 校验 + 提交**：`shellcheck` 相关脚本、`bats tests/unit/mirror.bats`、全量 bats；更新 HANDOVER.md；分步 commit（高频小颗粒，不 push）。

## 预期产出

- 主菜单 [19] 更换软件源，全模式可用。
- 换源流程与 LinuxMirrors 完整版交互一致（选站/协议/EPEL/升级），文本走项目 zh/en 双语。
- `THIRD_PARTY_NOTICES.md` 合规声明；测试全绿。

## 风险与注意事项

- **vendored 文件体积**（~8800 行）：违反"文件 <800 行"规范属有意例外（第三方 vendored 代码），在文件头注释说明。
- **msg 键映射一致性**：键名 `foo.bar-baz` 一律 `MSG_MIRROR_FOO_BARBAZ`（点→`_`、大写、`-` 保留大写拼接）；生成脚本与 msg() 解析必须同一规则，并用完整性测试兜底。
- **bash 版本**：`declare -A`/`${var,,}`/`mapfile` 等需 bash≥4（项目即 bash5 目标，无碍）。
- **高危系统操作**：修改 `/etc/apt/sources.list`、`/etc/yum.repos.d/*` 属高危；子菜单动作前确认；LinuxMirrors 自带 `.bak` 备份，宿主 `backup_file` 因隔离不干预（vendored 自己的备份机制保留）。
- **子 shell 内 `set +e`**：`run_mirror_flow` 返回码取自 `lm_main`；失败路径由子菜单 `log_error` + `press_enter` 处理。
- **ShellCheck CI 未覆盖 server/**：lm_core.sh 不需要过 shellcheck，但 `bash -n` 必须过；mirror.sh 尽量过 shellcheck。
- **编号变更**：新增 19 不触发既有编号右移（安全）；按 HANDOVER gotcha 复查连续性。
- **i18n 测试**：install.sh 不得出现 `${MSG_*:-}` fallback；mirror.sh 同理。

## 进度记录

- 2026-08-05：S1 侦察完成；S2 本 plan 落盘。用户已确认 3 决策（完整交互 / 全模式 / 项目 i18n）。
- 2026-08-05：S3 三 agent 并行完成（lm_core.sh `1076d80`、语言键 `540316c`、mirror.sh `6a34b08`）。S4 install.sh 接线、S5 mirror.bats 完成。S6 合规声明（THIRD_PARTY_NOTICES.md + README）完成。
- 2026-08-05：S7 校验通过 —— bash -n 全过、shellcheck 干净、全量 bats 512/512 通过（含 menu.bats 范围更新 1[0-8]→1[0-9]）。HANDOVER 同步。待收尾 commit。

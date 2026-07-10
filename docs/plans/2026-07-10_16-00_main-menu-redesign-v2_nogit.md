# Main Menu Redesign v2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 实现 `install.sh` 主菜单 v1.0 理想态（带分组的 12 项菜单 + 6 个模块子菜单壳 + 状态可视化 + 历史报告），覆盖 [spec §3-§4](../../design/main-menu-redesign-v2.md) 的 9 个 GAP。

**Architecture:** 仅改 `install.sh` 入口层 + i18n，新增 bats 测试。底层模块（ssh.sh / firewall.sh / fail2ban.sh 等）内部完全不动。

**Tech Stack:** Bash 4+ / bats 1.5+ / shellcheck / i18n（zh.sh + en.sh）

---

## Global Constraints

来源：项目 `CLAUDE.md` + spec。

- 所有 shell 脚本首行 `#!/usr/bin/env bash`，紧跟 `set -eo pipefail`
- 函数命名 `snake_case`，常量 `UPPER_SNAKE_CASE`
- 输出使用 `log_info` / `log_success` / `log_warn` / `log_error`，不要 `echo`（除交互输出）
- 修改 `install.sh` 不属于 `scripts/security/*`，但因含 `cleanup_and_exit` + curl pipe 检测，仍按 main script 走 review
- 提交前必跑：`shellcheck -x install.sh scripts/**/*.sh` + `bats tests/unit/*.bats`
- 本地高频小颗粒 commit，每次 commit 自洽（脚本通过 shellcheck、测试通过、构建可运行）
- 每次 commit 后必更新 `HANDOVER.md` 变更日志 + 本 plan §7 实施状态
- i18n：zh 与 en 完整对应，无 `:-` 兜底（spec GAP-8）
- 推荐实施顺序：T1 → T2 → T3 → T4 → T5 → T6（spec §5 推荐实施顺序）

---

## File Structure

每个 Task 影响的文件清单：

| 文件 | 角色 | 涉及 Task |
|---|---|---|
| `install.sh` | 主入口（含主菜单/子菜单/状态检测/view_report/参数解析） | T2, T3, T4, T5, T6 |
| `scripts/lang/zh.sh` | 中文 i18n | T1 |
| `scripts/lang/en.sh` | 英文 i18n | T1 |
| `tests/unit/menu.bats` (NEW) | 主菜单 + 子菜单壳测试 | T1, T2, T3 |
| `tests/unit/system-status.bats` (NEW) | 状态检测测试 | T4 |
| `tests/unit/view-report.bats` (NEW) | 历史报告测试 | T5 |
| `tests/unit/parse-args.bats` (NEW) | 参数解析测试 | T6 |
| `docs/design/main-menu-redesign-v2.md` | 设计文档，§7 实施状态追踪 | T2-T6 commit 后同步 |
| `HANDOVER.md` | 交接文档 | 每个 Task commit 后追加变更日志 |

不修改：
- `scripts/security/*.sh`（ssh / firewall / fail2ban / audit / users / kernel / filesystem / services）— 全部底层模块保持原样
- `scripts/base/*.sh`（utils / detect / init / report）— 保持原样
- `install.sh:1-200`（curl pipe 检测 + 参数解析 + load_dependencies）— 仅 T6 改参数解析的错误分支

---

## Tasks

### Task 1: i18n 补全（spec §5 T5 / GAP-8）

**Files:**
- Modify: `scripts/lang/zh.sh`（新增 9 个状态键 + 18 个子菜单壳键）
- Modify: `scripts/lang/en.sh`（同上，对应英文）
- Create: `tests/unit/menu.bats`（最小 smoke test）

**Interfaces:**
- Consumes: 现有 `MSG_MAIN_MENU_*` 翻译键命名约定
- Produces: 9 个状态键 + 18 个子菜单壳键，install.sh 的 `show_xxx_submenu` 系列可直接引用

#### 为什么先做 T1（i18n）

i18n 键是后续所有 Task 的依赖：T2-T5 都要新增 `show_xxx_submenu`、`MSG_SECTION_*`、`MSG_STATUS_RECOMMENDATION_*` 等键。先做 i18n 让后续 Task 不用边改边补键。

#### Step 1.1: 写 zh.sh 新增键的测试

在 `tests/unit/menu.bats` 顶部加：

```bash
#!/usr/bin/env bats
# menu.bats - 主菜单 / 子菜单壳 / i18n 键 测试

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export TEST_LANG="zh"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
}

@test "zh.sh has all new module submenu keys (fail2ban)" {
    [[ -n "${MSG_FAIL2BAN_MENU_TITLE:-}" ]]
    [[ -n "${MSG_FAIL2BAN_MENU_WIZARD:-}" ]]
    [[ -n "${MSG_FAIL2BAN_MENU_STATUS:-}" ]]
    [[ -n "${MSG_FAIL2BAN_MENU_BACK:-}" ]]
}

@test "zh.sh has all new module submenu keys (audit/users/kernel/fs/services)" {
    for module in audit users kernel filesystem services; do
        [[ -n "${MSG_${module^^}_MENU_TITLE:-}" ]]
        [[ -n "${MSG_${module^^}_MENU_WIZARD:-}" ]]
        [[ -n "${MSG_${module^^}_MENU_STATUS:-}" ]]
        [[ -n "${MSG_${module^^}_MENU_BACK:-}" ]]
    done
}

@test "zh.sh has status section header keys" {
    [[ -n "${MSG_SECTION_STATUS:-}" ]]
    [[ -n "${MSG_SECTION_HARDENING:-}" ]]
    [[ -n "${MSG_SECTION_QUICK:-}" ]]
    [[ -n "${MSG_STATUS_SSH_PORT_HARDENED:-}" ]]
    [[ -n "${MSG_STATUS_SSH_PORT_DEFAULT:-}" ]]
}

@test "zh.sh has status detection color/score keys" {
    [[ -n "${MSG_STATUS_HARDENED:-}" ]]
    [[ -n "${MSG_STATUS_PARTIAL:-}" ]]
    [[ -n "${MSG_STATUS_NOT_HARDENED:-}" ]]
    [[ -n "${MSG_STATUS_RECOMMENDATION:-}" ]]
}

@test "zh.sh has view_report history keys" {
    [[ -n "${MSG_REPORT_HISTORY_TITLE:-}" ]]
    [[ -n "${MSG_REPORT_NO_FILES:-}" ]]
}

@test "zh.sh has parse_args error keys" {
    [[ -n "${MSG_ERROR_REMOVED_ARG:-}" ]]
    [[ -n "${MSG_ERROR_REMOVED_HINT:-}" ]]
}
```

#### Step 1.2: 运行测试，验证失败

```bash
cd /Users/charliepan/Downloads/linux-one-key
bats tests/unit/menu.bats
```

Expected: 全部 FAIL（键不存在）。

#### Step 1.3: 在 zh.sh 追加新键

在 `zh.sh` 文件末尾追加：

```bash
# ═══════════════════════════════════════════
# 主菜单分组分隔 + 顶部状态摘要
# ═══════════════════════════════════════════

MSG_SECTION_STATUS="────── 状态 ──────"
MSG_SECTION_HARDENING="────── 加固（按推荐顺序）──────"
MSG_SECTION_QUICK="────── 一键 ──────"
MSG_STATUS_SSH_PORT_HARDENED="已加固"
MSG_STATUS_SSH_PORT_DEFAULT="未加固"

# ═══════════════════════════════════════════
# 状态检测：评分 + 颜色 + 建议下一步
# ═══════════════════════════════════════════

MSG_STATUS_HARDENED="已加固"
MSG_STATUS_PARTIAL="部分加固"
MSG_STATUS_NOT_HARDENED="未加固"
MSG_STATUS_RECOMMENDATION="建议下一步"

# ═══════════════════════════════════════════
# 状态键补全（移除 install.sh 中的 :- 兜底）
# ═══════════════════════════════════════════

MSG_STATUS_USERS="用户管理"
MSG_STATUS_USERS_COUNT="自定义用户数"
MSG_STATUS_KERNEL="内核加固"
MSG_STATUS_KERNEL_CONF="sysctl 配置"
MSG_STATUS_FILESYSTEM="文件系统"
MSG_STATUS_FS_SUID="SUID 文件数"
MSG_STATUS_SERVICES="服务管理"
MSG_STATUS_SERVICES_RUNNING="运行中服务"
MSG_STATUS_SERVICES_UNNECESSARY="非必要服务"

# ═══════════════════════════════════════════
# 模块 4-9 子菜单壳（每个模块 4 个键）
# ═══════════════════════════════════════════

MSG_FAIL2BAN_MENU_TITLE="Fail2Ban 入侵防护"
MSG_FAIL2BAN_MENU_WIZARD="[1] 全流程加固"
MSG_FAIL2BAN_MENU_STATUS="[2] 仅查看状态"
MSG_FAIL2BAN_MENU_BACK="[0] 返回主菜单"

MSG_AUDIT_MENU_TITLE="审计日志"
MSG_AUDIT_MENU_WIZARD="[1] 全流程加固"
MSG_AUDIT_MENU_STATUS="[2] 仅查看状态"
MSG_AUDIT_MENU_BACK="[0] 返回主菜单"

MSG_USERS_MENU_TITLE="用户管理"
MSG_USERS_MENU_WIZARD="[1] 全流程加固"
MSG_USERS_MENU_STATUS="[2] 仅查看状态"
MSG_USERS_MENU_BACK="[0] 返回主菜单"

MSG_KERNEL_MENU_TITLE="内核加固"
MSG_KERNEL_MENU_WIZARD="[1] 全流程加固"
MSG_KERNEL_MENU_STATUS="[2] 仅查看状态"
MSG_KERNEL_MENU_BACK="[0] 返回主菜单"

MSG_FILESYSTEM_MENU_TITLE="文件系统安全"
MSG_FILESYSTEM_MENU_WIZARD="[1] 全流程加固"
MSG_FILESYSTEM_MENU_STATUS="[2] 仅查看状态"
MSG_FILESYSTEM_MENU_BACK="[0] 返回主菜单"

MSG_SERVICES_MENU_TITLE="服务管理"
MSG_SERVICES_MENU_WIZARD="[1] 全流程加固"
MSG_SERVICES_MENU_STATUS="[2] 仅查看状态"
MSG_SERVICES_MENU_BACK="[0] 返回主菜单"

# ═══════════════════════════════════════════
# view_report 历史报告
# ═══════════════════════════════════════════

MSG_REPORT_HISTORY_TITLE="加固报告历史"
MSG_REPORT_NO_FILES="未找到任何加固报告"

# ═══════════════════════════════════════════
# parse_args 错误提示（精简后）
# ═══════════════════════════════════════════

MSG_ERROR_REMOVED_ARG="错误：参数 --%s 已移除，本脚本仅支持交互模式"
MSG_ERROR_REMOVED_HINT="提示：使用 --status 只读检测，或不带参数进入交互菜单"
```

#### Step 1.4: 在 en.sh 追加对应英文

在 `en.sh` 文件末尾追加（与 zh.sh 完全镜像）：

```bash
MSG_SECTION_STATUS="────── Status ──────"
MSG_SECTION_HARDENING="────── Hardening (Recommended Order) ──────"
MSG_SECTION_QUICK="────── One-Click ──────"
MSG_STATUS_SSH_PORT_HARDENED="Hardened"
MSG_STATUS_SSH_PORT_DEFAULT="Not hardened"

MSG_STATUS_HARDENED="Hardened"
MSG_STATUS_PARTIAL="Partially hardened"
MSG_STATUS_NOT_HARDENED="Not hardened"
MSG_STATUS_RECOMMENDATION="Recommended next step"

MSG_STATUS_USERS="User Management"
MSG_STATUS_USERS_COUNT="Custom users"
MSG_STATUS_KERNEL="Kernel Hardening"
MSG_STATUS_KERNEL_CONF="sysctl config"
MSG_STATUS_FILESYSTEM="Filesystem"
MSG_STATUS_FS_SUID="SUID files"
MSG_STATUS_SERVICES="Service Management"
MSG_STATUS_SERVICES_RUNNING="Running services"
MSG_STATUS_SERVICES_UNNECESSARY="Unnecessary services"

MSG_FAIL2BAN_MENU_TITLE="Fail2Ban Intrusion Prevention"
MSG_FAIL2BAN_MENU_WIZARD="[1] Full hardening wizard"
MSG_FAIL2BAN_MENU_STATUS="[2] Status only"
MSG_FAIL2BAN_MENU_BACK="[0] Back to main menu"

MSG_AUDIT_MENU_TITLE="Audit Logging"
MSG_AUDIT_MENU_WIZARD="[1] Full hardening wizard"
MSG_AUDIT_MENU_STATUS="[2] Status only"
MSG_AUDIT_MENU_BACK="[0] Back to main menu"

MSG_USERS_MENU_TITLE="User Management"
MSG_USERS_MENU_WIZARD="[1] Full hardening wizard"
MSG_USERS_MENU_STATUS="[2] Status only"
MSG_USERS_MENU_BACK="[0] Back to main menu"

MSG_KERNEL_MENU_TITLE="Kernel Hardening"
MSG_KERNEL_MENU_WIZARD="[1] Full hardening wizard"
MSG_KERNEL_MENU_STATUS="[2] Status only"
MSG_KERNEL_MENU_BACK="[0] Back to main menu"

MSG_FILESYSTEM_MENU_TITLE="Filesystem Security"
MSG_FILESYSTEM_MENU_WIZARD="[1] Full hardening wizard"
MSG_FILESYSTEM_MENU_STATUS="[2] Status only"
MSG_FILESYSTEM_MENU_BACK="[0] Back to main menu"

MSG_SERVICES_MENU_TITLE="Service Management"
MSG_SERVICES_MENU_WIZARD="[1] Full hardening wizard"
MSG_SERVICES_MENU_STATUS="[2] Status only"
MSG_SERVICES_MENU_BACK="[0] Back to main menu"

MSG_REPORT_HISTORY_TITLE="Hardening Report History"
MSG_REPORT_NO_FILES="No hardening reports found"

MSG_ERROR_REMOVED_ARG="Error: --%s has been removed. This script only supports interactive mode."
MSG_ERROR_REMOVED_HINT="Tip: use --status for read-only detection, or no argument for interactive menu."
```

#### Step 1.5: 验证测试通过

```bash
bats tests/unit/menu.bats
```

Expected: 全部 PASS。

#### Step 1.6: 提交

```bash
git add scripts/lang/zh.sh scripts/lang/en.sh tests/unit/menu.bats
git commit -m "feat(i18n): add keys for menu shells, status sections, view_report, parse-args

spec: docs/design/main-menu-redesign-v2.md §5 T5 / GAP-8

新增翻译键：
- 主菜单分组 (MSG_SECTION_*)
- 状态检测评分 (MSG_STATUS_HARDENED/PARTIAL/NOT_HARDENED/RECOMMENDATION)
- 状态键补全 (MSG_STATUS_USERS/KERNEL/FILESYSTEM/SERVICES 等 9 个，移除 install.sh 中的 :- 兜底)
- 模块 4-9 子菜单壳 (MSG_<MODULE>_MENU_* 6×4=24 键)
- view_report 历史 (MSG_REPORT_HISTORY_TITLE/NO_FILES)
- parse_args 精简错误提示 (MSG_ERROR_REMOVED_ARG/HINT)

新增 tests/unit/menu.bats 验证键存在。"
```

---

### Task 2: 模块 4-9 加子菜单壳（spec §5 T1 / GAP-3）

**Files:**
- Modify: `install.sh`（在 `run_firewall_submenu_loop` 后新增 6 个模块的子菜单函数，约 +150 行）
- Modify: `tests/unit/menu.bats`（追加 6 个模块子菜单的 smoke test）

**Interfaces:**
- Consumes: `prompt_input` / `press_enter` / `log_*`（utils.sh）；`MSG_<MODULE>_MENU_*` 翻译键（Task 1）；`run_<module>_wizard`（每个模块的 wizard 函数）；`check_<module>_status`（如果存在，否则用占位）
- Produces: 6 对函数 `show_<module>_submenu` + `run_<module>_submenu_loop`，被 `run_main_menu_loop` 在 case 4-9 调用

#### Step 2.1: 写 show_<module>_submenu 的测试

在 `tests/unit/menu.bats` 追加：

```bash
@test "show_fail2ban_submenu outputs expected sections" {
    source "${SCRIPT_DIR}/install.sh" 2>/dev/null || true
    # install.sh 顶层会执行 main，这里跳过顶层副作用的检查
    # 直接验证 i18n 键足够
    [[ -n "${MSG_FAIL2BAN_MENU_TITLE}" ]]
    [[ "${MSG_FAIL2BAN_MENU_WIZARD}" =~ "1" ]]
    [[ "${MSG_FAIL2BAN_MENU_BACK}" =~ "0" ]]
}

@test "all 6 module submenu keys reference module title" {
    for module in fail2ban audit users kernel filesystem services; do
        local upper="${module^^}"
        # TITLE 不能为空且不应等于 BACK
        [[ -n "${MSG_${upper}_MENU_TITLE}" ]]
        [[ "${MSG_${upper}_MENU_TITLE}" != "${MSG_${upper}_MENU_BACK}" ]]
    done
}
```

#### Step 2.2: 运行测试（应通过 Task 1 已加的键）

```bash
bats tests/unit/menu.bats
```

Expected: 通过（Task 1 已加键）。

#### Step 2.3: 在 install.sh 添加 6 对子菜单函数

定位 `run_firewall_submenu_loop()` 函数（line ~614）后的 `# 查看报告` 注释（line ~651）之前，**插入以下代码**：

```bash
# ═══════════════════════════════════════════
# 模块 4-9 子菜单壳（spec §5 T1 / GAP-3）
# ═══════════════════════════════════════════

# Fail2Ban 子菜单
show_fail2ban_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_FAIL2BAN_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_FAIL2BAN_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_FAIL2BAN_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_FAIL2BAN_MENU_BACK}${NC}"
    echo ""
}

run_fail2ban_submenu_loop() {
    while true; do
        show_fail2ban_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_fail2ban_wizard || log_error "Fail2Ban config failed"
                press_enter
                ;;
            2)
                if type check_fail2ban_status &>/dev/null; then
                    check_fail2ban_status
                else
                    log_info "Fail2Ban 状态：见主菜单 [1] 系统状态检测"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Audit 子菜单
show_audit_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_AUDIT_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_AUDIT_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_AUDIT_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_AUDIT_MENU_BACK}${NC}"
    echo ""
}

run_audit_submenu_loop() {
    while true; do
        show_audit_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_audit_wizard || log_error "Audit config failed"
                press_enter
                ;;
            2)
                if type check_audit_status &>/dev/null; then
                    check_audit_status
                else
                    log_info "Audit 状态：见主菜单 [1] 系统状态检测"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Users 子菜单
show_users_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_USERS_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_USERS_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_USERS_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_USERS_MENU_BACK}${NC}"
    echo ""
}

run_users_submenu_loop() {
    while true; do
        show_users_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_users_wizard || log_error "User management failed"
                press_enter
                ;;
            2)
                if type check_users_status &>/dev/null; then
                    check_users_status
                else
                    log_info "用户状态：见主菜单 [1] 系统状态检测"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Kernel 子菜单
show_kernel_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_KERNEL_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_KERNEL_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_KERNEL_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_KERNEL_MENU_BACK}${NC}"
    echo ""
}

run_kernel_submenu_loop() {
    while true; do
        show_kernel_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_kernel_wizard || log_error "Kernel hardening failed"
                press_enter
                ;;
            2)
                if type check_kernel_status &>/dev/null; then
                    check_kernel_status
                else
                    log_info "内核状态：见主菜单 [1] 系统状态检测"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Filesystem 子菜单
show_filesystem_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_FILESYSTEM_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_FILESYSTEM_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_FILESYSTEM_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_FILESYSTEM_MENU_BACK}${NC}"
    echo ""
}

run_filesystem_submenu_loop() {
    while true; do
        show_filesystem_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_filesystem_wizard || log_error "Filesystem check failed"
                press_enter
                ;;
            2)
                if type check_filesystem_status &>/dev/null; then
                    check_filesystem_status
                else
                    log_info "文件系统状态：见主菜单 [1] 系统状态检测"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# Services 子菜单
show_services_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_SERVICES_MENU_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_SERVICES_MENU_WIZARD}${NC}"
    echo -e "  ${GREEN}${MSG_SERVICES_MENU_STATUS}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_SERVICES_MENU_BACK}${NC}"
    echo ""
}

run_services_submenu_loop() {
    while true; do
        show_services_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-2]" "")
        case "${choice}" in
            1)
                run_services_wizard || log_error "Service management failed"
                press_enter
                ;;
            2)
                if type check_services_status &>/dev/null; then
                    check_services_status
                else
                    log_info "服务状态：见主菜单 [1] 系统状态检测"
                fi
                press_enter
                ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}
```

#### Step 2.4: 修改 `run_main_menu_loop` 的 case 4-9

定位 `install.sh:880-916` 的 `run_main_menu_loop`，将 case `4)` 到 `9)` 的直接 wizard 调用改为子菜单壳：

**改动 1**（line ~884，`4)` 分支）：

```bash
4) run_fail2ban_submenu_loop ;;
```

**改动 2**（line ~889，`5)` 分支）：

```bash
5) run_audit_submenu_loop ;;
```

**改动 3**（line ~893，`6)` 分支）：

```bash
6) run_users_submenu_loop ;;
```

**改动 4**（line ~897，`7)` 分支）：

```bash
7) run_kernel_submenu_loop ;;
```

**改动 5**（line ~901，`8)` 分支）：

```bash
8) run_filesystem_submenu_loop ;;
```

**改动 6**（line ~905，`9)` 分支）：

```bash
9) run_services_submenu_loop ;;
```

#### Step 2.5: 验证 shellcheck + bats

```bash
shellcheck -x install.sh
bats tests/unit/*.bats
```

Expected: shellcheck 通过，bats 全部通过。

#### Step 2.6: 提交

```bash
git add install.sh tests/unit/menu.bats HANDOVER.md docs/design/main-menu-redesign-v2.md
git commit -m "feat(install): add submenu shells for modules 4-9 (fail2ban/audit/users/kernel/fs/services)

spec: docs/design/main-menu-redesign-v2.md §5 T1 / GAP-3

为 fail2ban/audit/users/kernel/filesystem/services 六个模块统一加子菜单壳：
[1] 全流程向导 [2] 仅查看状态 [0] 返回主菜单

main loop case 4-9 改为调用 run_<module>_submenu_loop。

体验与 SSH/防火墙的子菜单一致；check_<module>_status 函数（若存在）
作为选项 [2] 的快速查看入口，缺失则 fallback 到提示信息。"
```

HANDOVER.md 和 main-menu-redesign-v2.md 同步更新 §7 实施状态（T1 → ✅）。

---

### Task 3: 顶层菜单加分隔线 + 顶部状态摘要（spec §5 T2 / GAP-1/2）

**Files:**
- Modify: `install.sh`（`show_main_menu` 函数，约 +15 行）
- Modify: `tests/unit/menu.bats`（追加主菜单显示的 smoke test）

**Interfaces:**
- Consumes: `get_detected_os` / `get_detected_os_version` / `get_detected_arch` / `whoami`（utils.sh / detect.sh）；`get_ssh_port`（ssh.sh）；`MSG_SECTION_*` 翻译键（Task 1）
- Produces: 新的 `show_main_menu` 输出含 3 组分隔线 + 顶部状态摘要行

#### Step 3.1: 追加主菜单 smoke test

在 `tests/unit/menu.bats` 追加：

```bash
@test "show_main_menu section keys all defined" {
    [[ -n "${MSG_SECTION_STATUS}" ]]
    [[ -n "${MSG_SECTION_HARDENING}" ]]
    [[ -n "${MSG_SECTION_QUICK}" ]]
}

@test "SSH port status keys differentiate hardened vs default" {
    [[ -n "${MSG_STATUS_SSH_PORT_HARDENED}" ]]
    [[ -n "${MSG_STATUS_SSH_PORT_DEFAULT}" ]]
    [[ "${MSG_STATUS_SSH_PORT_HARDENED}" != "${MSG_STATUS_SSH_PORT_DEFAULT}" ]]
}
```

#### Step 3.2: 运行测试

```bash
bats tests/unit/menu.bats
```

Expected: 通过（Task 1 已加键）。

#### Step 3.3: 重写 `show_main_menu`

定位 `install.sh:456-509` 的 `show_main_menu` 函数，**整体替换**为：

```bash
show_main_menu() {
    clear 2>/dev/null || true
    echo ""
    echo -e "${BOLD}  _____ _     _       _     ${NC}"
    echo -e "${BOLD} / ____| |   (_)     | |    ${NC}"
    echo -e "${BOLD}| |    | |__  _ _ __ | |__  ${NC}"
    echo -e "${BOLD}| |    | '_ \| | '_ \| '_ \ ${NC}"
    echo -e "${BOLD}| |____| | | | | | | | | | |${NC}"
    echo -e "${BOLD} \_____|_| |_|_|_| |_|_| |_|${NC}"
    echo ""
    echo -e "  ${BOLD}Linux Server Security Hardening ${SCRIPT_VERSION}${NC}"
    echo -e "  ${BLUE}${MSG_WELCOME}${NC}"
    echo ""

    # 顶部状态摘要行（spec §3.1 GAP-2）
    local ssh_port ssh_status_label
    ssh_port=$(get_ssh_port 2>/dev/null || echo "22")
    if [[ "${ssh_port}" == "22" ]]; then
        ssh_status_label="${MSG_STATUS_SSH_PORT_DEFAULT}"
    else
        ssh_status_label="${MSG_STATUS_SSH_PORT_HARDENED}"
    fi
    echo -e "  ${MSG_MAIN_MENU_SYSTEM_INFO}: $(get_detected_os) $(get_detected_os_version) | $(get_detected_arch) | $(whoami) | SSH ${ssh_port} (${ssh_status_label})"
    echo ""

    # 分组 1：状态（spec §3.1 GAP-1）
    echo -e "${BOLD}${MSG_SECTION_STATUS}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_STATUS}${NC}"
    echo -e "      ${MSG_MAIN_MENU_STATUS_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_REPORT}${NC}"
    echo -e "      ${MSG_MAIN_MENU_REPORT_DESC}"
    echo ""

    # 分组 2：加固
    echo -e "${BOLD}${MSG_SECTION_HARDENING}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_SSH}${NC}"
    echo -e "      ${MSG_MAIN_MENU_SSH_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FIREWALL}${NC}"
    echo -e "      ${MSG_MAIN_MENU_FIREWALL_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FAIL2BAN}${NC}"
    echo -e "      ${MSG_MAIN_MENU_FAIL2BAN_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_AUDIT}${NC}"
    echo -e "      ${MSG_MAIN_MENU_AUDIT_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_USERS}${NC}"
    echo -e "      ${MSG_MAIN_MENU_USERS_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_KERNEL}${NC}"
    echo -e "      ${MSG_MAIN_MENU_KERNEL_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_FILESYSTEM}${NC}"
    echo -e "      ${MSG_MAIN_MENU_FILESYSTEM_DESC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_SERVICES}${NC}"
    echo -e "      ${MSG_MAIN_MENU_SERVICES_DESC}"
    echo ""

    # 分组 3：一键
    echo -e "${BOLD}${MSG_SECTION_QUICK}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_MAIN_MENU_QUICK}${NC}"
    echo -e "      ${MSG_MAIN_MENU_QUICK_DESC}"
    echo ""
    echo -e "  ${RED}${MSG_MAIN_MENU_EXIT}${NC}"
    echo ""
}
```

注意：
- `MSG_MAIN_MENU_REPORT` 原为位置 [6]，现移至状态分组 [11]，需在 zh.sh/en.sh 中已存在（已存在）
- 顶部状态摘要行末尾的 SSH 端口摘要使用 `MSG_STATUS_SSH_PORT_HARDENED/DEFAULT`

#### Step 3.4: 验证 shellcheck + bats

```bash
shellcheck -x install.sh
bats tests/unit/*.bats
```

Expected: 全部通过。

#### Step 3.5: 提交

```bash
git add install.sh HANDOVER.md docs/design/main-menu-redesign-v2.md
git commit -m "feat(install): add 3-group separators + SSH port status line to main menu

spec: docs/design/main-menu-redesign-v2.md §5 T2 / GAP-1/GAP-2

- 加 3 组分隔线（状态 / 加固 / 一键）
- 顶部状态行追加 SSH 端口 + 加固状态摘要
- view_report 从原 [6] 移至状态分组首项位置（实际 [11]，spec §4 自检后确认）"
```

HANDOVER.md 和 main-menu-redesign-v2.md §7 同步。

---

### Task 4: 状态检测升级（spec §5 T3 / GAP-4/5/6）

**Files:**
- Modify: `install.sh`（重写 `show_system_status`，约 +60 行）
- Create: `tests/unit/system-status.bats`（新增文件）

**Interfaces:**
- Consumes: `get_ssh_port` / `get_ssh_config` / `MSG_STATUS_*` / `MSG_SECTION_*` 翻译键（Task 1）
- Produces: 重构后的 `show_system_status`，输出含顶部评分、颜色（绿/黄/红）、末尾建议

#### Step 4.1: 写 system-status.bats 测试

新建 `tests/unit/system-status.bats`：

```bash
#!/usr/bin/env bats
# system-status.bats - 系统状态检测函数测试

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LANG_CODE="zh"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    source "${SCRIPT_DIR}/scripts/base/detect.sh"

    # Stub SSH 检测函数
    get_ssh_port() { echo "22"; }
    get_ssh_config() { echo "$2"; }

    # Stub 模块状态函数
    check_users_status() { echo "users_custom=0"; }
    check_kernel_status() { echo "kernel_conf=no"; }
    check_filesystem_status() { echo "fs_suid_count=0"; }
    check_services_status() { echo "services_running=10 services_unnecessary=2"; }

    # Stub 系统命令
    ufw() { return 1; }
    firewall-cmd() { return 1; }
    systemctl() {
        if [[ "$2" == "fail2ban" ]]; then return 1; fi
        if [[ "$2" == "auditd" ]]; then return 1; fi
        return 1
    }
    command() {
        if [[ "$2" == "ufw" ]] || [[ "$2" == "firewall-cmd" ]] || [[ "$2" == "fail2ban-client" ]] || [[ "$2" == "auditctl" ]]; then
            return 1
        fi
        builtin command "$@"
    }
    export -f get_ssh_port get_ssh_config check_users_status check_kernel_status check_filesystem_status check_services_status ufw firewall-cmd systemctl command

    # Source install.sh 但跳过 main 调用
    # install.sh 顶层会执行 main "$@"，需要 stub main
    main() { return 0; }
    export -f main
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "MSG_STATUS_HARDENED is non-empty" {
    [[ -n "${MSG_STATUS_HARDENED}" ]]
}

@test "MSG_STATUS_PARTIAL is non-empty" {
    [[ -n "${MSG_STATUS_PARTIAL}" ]]
}

@test "MSG_STATUS_NOT_HARDENED is non-empty" {
    [[ -n "${MSG_STATUS_NOT_HARDENED}" ]]
}

@test "MSG_STATUS_RECOMMENDATION has placeholder for menu numbers" {
    [[ "${MSG_STATUS_RECOMMENDATION}" =~ "%" ]] || [[ "${MSG_STATUS_RECOMMENDATION}" =~ "：" ]]
}
```

#### Step 4.2: 运行测试

```bash
bats tests/unit/system-status.bats
```

Expected: 全部通过（仅检查 i18n 键）。

#### Step 4.3: 重写 `show_system_status`

定位 `install.sh:311-449` 的 `show_system_status` 函数，**整体替换**为：

```bash
show_system_status() {
    log_title "${MSG_STATUS_TITLE}"
    echo ""

    # 收集各模块加固状态
    local ssh_hardened=0
    local fw_hardened=0
    local f2b_hardened=0
    local audit_hardened=0
    local users_hardened=0
    local kernel_hardened=0
    local fs_hardened=0
    local svc_hardened=0
    local recommendation_parts=()

    # SSH 状态
    echo -e "${GREEN}[SSH]${NC}"
    local ssh_port
    ssh_port=$(get_ssh_port 2>/dev/null || echo "22")
    local root_login pass_auth pubkey_auth
    root_login=$(get_ssh_config "PermitRootLogin" 2>/dev/null || echo "unknown")
    pass_auth=$(get_ssh_config "PasswordAuthentication" 2>/dev/null || echo "unknown")
    pubkey_auth=$(get_ssh_config "PubkeyAuthentication" 2>/dev/null || echo "unknown")

    if [[ "${ssh_port}" != "22" ]] && [[ "${root_login}" == "no" ]] && [[ "${pass_auth}" == "no" ]]; then
        echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        ssh_hardened=1
    elif [[ "${ssh_port}" != "22" ]] || [[ "${root_login}" == "no" ]] || [[ "${pass_auth}" == "no" ]]; then
        echo -e "  ${YELLOW}~${NC} ${MSG_STATUS_PARTIAL}"
        recommendation_parts+=("[2] SSH")
    else
        echo -e "  ${RED}✗${NC} ${MSG_STATUS_NOT_HARDENED}"
        recommendation_parts+=("[2] SSH")
    fi
    echo -e "  ${MSG_STATUS_SSH_PORT}: ${ssh_port} | root: ${root_login} | passwd: ${pass_auth} | pubkey: ${pubkey_auth}"
    echo ""

    # 防火墙状态
    echo -e "${GREEN}[${MSG_STATUS_FIREWALL}]${NC}"
    local fw_active=0
    if command -v ufw &>/dev/null && ufw status 2>/dev/null | grep -q "Status: active"; then
        fw_active=1
    elif command -v firewall-cmd &>/dev/null && firewall-cmd --state &>/dev/null; then
        fw_active=1
    fi
    if [[ "${fw_active}" -eq 1 ]]; then
        echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        fw_hardened=1
    else
        echo -e "  ${RED}✗${NC} ${MSG_STATUS_NOT_HARDENED}"
        recommendation_parts+=("[3] 防火墙")
    fi
    echo ""

    # Fail2Ban
    echo -e "${GREEN}[${MSG_STATUS_FAIL2BAN}]${NC}"
    if command -v fail2ban-client &>/dev/null && systemctl is-active fail2ban &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        f2b_hardened=1
    else
        echo -e "  ${RED}✗${NC} ${MSG_STATUS_NOT_HARDENED}"
        recommendation_parts+=("[4] Fail2Ban")
    fi
    echo ""

    # Audit
    echo -e "${GREEN}[${MSG_STATUS_AUDIT}]${NC}"
    if command -v auditctl &>/dev/null && systemctl is-active auditd &>/dev/null; then
        echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        audit_hardened=1
    else
        echo -e "  ${RED}✗${NC} ${MSG_STATUS_NOT_HARDENED}"
        recommendation_parts+=("[5] 审计")
    fi
    echo ""

    # Users
    echo -e "${GREEN}[${MSG_STATUS_USERS}]${NC}"
    if type check_users_status &>/dev/null; then
        local users_status custom_users
        users_status=$(check_users_status 2>/dev/null)
        custom_users=$(echo "${users_status}" | grep '^users_custom=' | cut -d= -f2)
        echo -e "  ${MSG_STATUS_USERS_COUNT}: ${custom_users}"
        if [[ "${custom_users:-0}" -gt 0 ]]; then
            users_hardened=1
            echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        else
            echo -e "  ${YELLOW}~${NC} ${MSG_STATUS_PARTIAL}"
        fi
    fi
    echo ""

    # Kernel
    echo -e "${GREEN}[${MSG_STATUS_KERNEL}]${NC}"
    if type check_kernel_status &>/dev/null; then
        local kernel_status kernel_conf
        kernel_status=$(check_kernel_status 2>/dev/null)
        kernel_conf=$(echo "${kernel_status}" | grep '^kernel_conf=' | cut -d= -f2)
        if [[ "${kernel_conf}" == "yes" ]]; then
            echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
            kernel_hardened=1
        else
            echo -e "  ${RED}✗${NC} ${MSG_STATUS_NOT_HARDENED}"
            recommendation_parts+=("[7] 内核")
        fi
        echo -e "  ${MSG_STATUS_KERNEL_CONF}: ${kernel_conf}"
    fi
    echo ""

    # Filesystem
    echo -e "${GREEN}[${MSG_STATUS_FILESYSTEM}]${NC}"
    if type check_filesystem_status &>/dev/null; then
        local fs_status suid_count
        fs_status=$(check_filesystem_status 2>/dev/null)
        suid_count=$(echo "${fs_status}" | grep '^fs_suid_count=' | cut -d= -f2)
        echo -e "  ${MSG_STATUS_FS_SUID}: ${suid_count}"
        if [[ "${suid_count:-0}" -lt 20 ]]; then
            fs_hardened=1
            echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        else
            echo -e "  ${YELLOW}~${NC} ${MSG_STATUS_PARTIAL}"
        fi
    fi
    echo ""

    # Services
    echo -e "${GREEN}[${MSG_STATUS_SERVICES}]${NC}"
    if type check_services_status &>/dev/null; then
        local svc_status svc_running svc_unnecessary
        svc_status=$(check_services_status 2>/dev/null)
        svc_running=$(echo "${svc_status}" | grep '^services_running=' | cut -d= -f2)
        svc_unnecessary=$(echo "${svc_status}" | grep '^services_unnecessary=' | cut -d= -f2)
        echo -e "  ${MSG_STATUS_SERVICES_RUNNING}: ${svc_running}"
        echo -e "  ${MSG_STATUS_SERVICES_UNNECESSARY}: ${svc_unnecessary}"
        if [[ "${svc_unnecessary:-0}" -eq 0 ]]; then
            svc_hardened=1
            echo -e "  ${GREEN}✓${NC} ${MSG_STATUS_HARDENED}"
        else
            echo -e "  ${YELLOW}~${NC} ${MSG_STATUS_PARTIAL}"
            recommendation_parts+=("[9] 服务")
        fi
    fi
    echo ""

    # 顶部评分汇总（spec §3.3 GAP-4）
    local total=8 hardened_count=0
    hardened_count=$((ssh_hardened + fw_hardened + f2b_hardened + audit_hardened + users_hardened + kernel_hardened + fs_hardened + svc_hardened))
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_STATUS_TITLE}：${hardened_count} / ${total}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""

    # 末尾建议（spec §3.3 GAP-6）
    if [[ "${#recommendation_parts[@]}" -gt 0 ]]; then
        local joined_recommendations
        joined_recommendations=$(IFS=' '; echo "${recommendation_parts[*]}")
        echo -e "${YELLOW}${MSG_STATUS_RECOMMENDATION}: ${joined_recommendations}${NC}"
        echo ""
    fi

    press_enter
}
```

#### Step 4.4: 验证 shellcheck + bats

```bash
shellcheck -x install.sh
bats tests/unit/*.bats
```

Expected: 全部通过。

#### Step 4.5: 提交

```bash
git add install.sh tests/unit/system-status.bats HANDOVER.md docs/design/main-menu-redesign-v2.md
git commit -m "feat(install): upgrade show_system_status with score, colors, recommendations

spec: docs/design/main-menu-redesign-v2.md §5 T3 / GAP-4/5/6

- 8 项分类各显 ✓ / ~ / ✗ 三态（已加固 / 部分 / 未加固）
- 顶部汇总分数（X/8）
- 末尾列出未加固项对应菜单编号
- 颜色：绿=已加固，黄=部分，红=未启用
- 移除 install.sh 中 9 处 MSG_STATUS_* 变量的 :- 兜底（依赖 Task 1）"
```

HANDOVER.md 和 main-menu-redesign-v2.md §7 同步。

---

### Task 5: view_report 升级（spec §5 T4 / GAP-7）

**Files:**
- Modify: `install.sh`（重写 `view_report`，约 +50 行）
- Create: `tests/unit/view-report.bats`（新增文件）

**Interfaces:**
- Consumes: `REPORT_DIR`（report.sh 提供）；`MSG_REPORT_HISTORY_TITLE` / `MSG_REPORT_NO_FILES` 翻译键（Task 1）
- Produces: 重构后的 `view_report`，列出最近 N 份（默认 5）报告供用户选

#### Step 5.1: 写 view-report.bats 测试

新建 `tests/unit/view-report.bats`：

```bash
#!/usr/bin/env bats
# view-report.bats - 历史报告选择功能测试

setup() {
    export TEST_DIR="$(mktemp -d)"
    export REPORT_DIR="${TEST_DIR}/reports"
    mkdir -p "${REPORT_DIR}"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LANG_CODE="zh"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    # 创建 mock 报告文件（按时间戳排序）
    echo "report 1" > "${REPORT_DIR}/report_2026-07-08_1800.txt"
    echo "report 2" > "${REPORT_DIR}/report_2026-07-09_2115.txt"
    echo "report 3" > "${REPORT_DIR}/report_2026-07-10_1430.txt"

    # Stub main
    main() { return 0; }
    export -f main
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "MSG_REPORT_HISTORY_TITLE is defined" {
    [[ -n "${MSG_REPORT_HISTORY_TITLE}" ]]
}

@test "MSG_REPORT_NO_FILES is defined" {
    [[ -n "${MSG_REPORT_NO_FILES}" ]]
}

@test "test report directory has 3 files" {
    local count
    count=$(ls "${REPORT_DIR}"/report_*.txt 2>/dev/null | wc -l | tr -d ' ')
    [[ "${count}" -eq 3 ]]
}
```

#### Step 5.2: 运行测试

```bash
bats tests/unit/view-report.bats
```

Expected: 全部通过。

#### Step 5.3: 重写 `view_report`

定位 `install.sh:654-672` 的 `view_report` 函数，**整体替换**为：

```bash
view_report() {
    local report_dir="${REPORT_DIR:-/var/log/linux-one-key}"
    local max_reports=5
    local reports=()

    if [[ -d "${report_dir}" ]]; then
        # 使用 ls -t 替代 find -printf，兼容 macOS (BSD find)
        while IFS= read -r f; do
            reports+=("${f}")
        done < <(ls -t "${report_dir}"/report_*.txt 2>/dev/null | head -"${max_reports}")
    fi

    if [[ "${#reports[@]}" -eq 0 ]]; then
        log_warn "${MSG_REPORT_NO_FILES}"
        press_enter
        return 0
    fi

    # 显示历史报告列表（spec §3.4 GAP-7）
    echo ""
    echo -e "${BOLD}${MSG_REPORT_HISTORY_TITLE}${NC}"
    echo ""

    local i
    for i in "${!reports[@]}"; do
        local idx=$((i + 1))
        local basename_file
        basename_file=$(basename "${reports[$i]}")
        echo -e "  ${GREEN}[${idx}]${NC} ${basename_file}"
    done

    echo ""
    echo -e "  ${RED}[0]${NC} ${MSG_BACK}"
    echo ""

    local choice
    choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-${#reports[@]}]" "")

    if [[ "${choice}" == "0" ]] || [[ -z "${choice}" ]]; then
        return 0
    fi

    if [[ "${choice}" =~ ^[0-9]+$ ]] && [[ "${choice}" -ge 1 ]] && [[ "${choice}" -le "${#reports[@]}" ]]; then
        local selected="${reports[$((choice - 1))]}"
        echo ""
        echo -e "${BOLD}--- $(basename "${selected}") ---${NC}"
        echo ""
        cat "${selected}"
        echo ""
    else
        log_error "${MSG_MENU_INVALID}"
    fi

    press_enter
}
```

#### Step 5.4: 验证 shellcheck + bats

```bash
shellcheck -x install.sh
bats tests/unit/*.bats
```

Expected: 全部通过。

#### Step 5.5: 提交

```bash
git add install.sh tests/unit/view-report.bats HANDOVER.md docs/design/main-menu-redesign-v2.md
git commit -m "feat(install): upgrade view_report to show history list (top N, default 5)

spec: docs/design/main-menu-redesign-v2.md §5 T4 / GAP-7

原 view_report 只显示最新一份，现升级为：
- 列出最近 5 份报告（按 mtime 倒序）
- 用户输入编号选择查看哪份
- 0 返回主菜单
- 无报告时显示 MSG_REPORT_NO_FILES 提示"
```

HANDOVER.md 和 main-menu-redesign-v2.md §7 同步。

---

### Task 6: 非交互错误提示精简（spec §5 T6 / GAP-9）

**Files:**
- Modify: `install.sh`（`_parse_args` 函数错误分支，约 -10 行）
- Create: `tests/unit/parse-args.bats`（新增文件）

**Interfaces:**
- Consumes: `MSG_ERROR_REMOVED_ARG` / `MSG_ERROR_REMOVED_HINT` 翻译键（Task 1）
- Produces: 简化的参数错误提示（5 行 → 2 行）

#### Step 6.1: 写 parse-args.bats 测试

新建 `tests/unit/parse-args.bats`：

```bash
#!/usr/bin/env bats
# parse-args.bats - 参数解析错误提示精简测试

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LANG_CODE="zh"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    # Stub main
    main() { return 0; }
    export -f main
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "MSG_ERROR_REMOVED_ARG has %s placeholder" {
    [[ "${MSG_ERROR_REMOVED_ARG}" =~ "%s" ]]
}

@test "MSG_ERROR_REMOVED_HINT is non-empty" {
    [[ -n "${MSG_ERROR_REMOVED_HINT}" ]]
}

@test "removed args message is short (one line)" {
    # 原版 5 行，新版 2 行
    local lines
    lines=$(echo "${MSG_ERROR_REMOVED_ARG}" | wc -l | tr -d ' ')
    [[ "${lines}" -le 1 ]]
}
```

#### Step 6.2: 运行测试

```bash
bats tests/unit/parse-args.bats
```

Expected: 全部通过。

#### Step 6.3: 简化 `_parse_args` 错误分支

定位 `install.sh:119-130` 的 `_parse_args` 错误分支：

```bash
--yes|-y|--quick|--ssh|--firewall|--fail2ban)
    local removed_arg="${arg#--}"
    removed_arg="${removed_arg#-}"
    echo ""
    echo -e "${RED}Error: --${removed_arg} has been removed.${NC}"
    echo -e "${YELLOW}This script is now fully interactive:${NC}"
    echo -e "${YELLOW}  sudo bash install.sh${NC}"
    echo -e "${BLUE}Tip: --status still works for read-only:${NC}"
    echo -e "${BLUE}  sudo bash install.sh --status${NC}"
    echo ""
    exit 1
    ;;
```

**整体替换为**：

```bash
--yes|-y|--quick|--ssh|--firewall|--fail2ban)
    local removed_arg="${arg#--}"
    removed_arg="${removed_arg#-}"
    printf "${RED}${MSG_ERROR_REMOVED_ARG}${NC}\n" "${removed_arg}"
    printf "${BLUE}${MSG_ERROR_REMOVED_HINT}${NC}\n"
    exit 1
    ;;
```

注意：`printf` 替代 `echo -e`，因为 `${MSG_ERROR_REMOVED_ARG}` 包含 `%s` 占位符。

#### Step 6.4: 验证 shellcheck + bats

```bash
shellcheck -x install.sh
bats tests/unit/*.bats
```

Expected: 全部通过。

#### Step 6.5: 提交

```bash
git add install.sh tests/unit/parse-args.bats HANDOVER.md docs/design/main-menu-redesign-v2.md
git commit -m "refactor(install): simplify _parse_args removed-arg error (5 lines → 2)

spec: docs/design/main-menu-redesign-v2.md §5 T6 / GAP-9

原 5 行硬编码英文提示替换为 2 行 i18n 提示：
- 行 1: --%s 已移除错误
- 行 2: --status / 交互模式提示

i18n 键来自 Task 1 (MSG_ERROR_REMOVED_ARG/HINT)。"
```

HANDOVER.md 和 main-menu-redesign-v2.md §7 同步。

---

### Task 7: 最终验证 + 文档归档

**Files:**
- Modify: `docs/design/main-menu-redesign-v2.md`（`status: proposed` → `status: active`，§7 实施状态全部 ✅）
- Modify: `HANDOVER.md`（追加最终变更日志）

#### Step 7.1: 运行完整验证

```bash
shellcheck -x install.sh scripts/**/*.sh
bats tests/unit/*.bats
```

Expected: 全部通过。

#### Step 7.2: 修改 main-menu-redesign-v2.md 状态

修改 frontmatter:

```yaml
status: active   # 原 proposed
updated: 2026-07-10
```

修改 §7 实施状态表：把 6 行 ⬜ 全部改为 ✅。

#### Step 7.3: 最终提交

```bash
git add docs/design/main-menu-redesign-v2.md HANDOVER.md
git commit -m "docs(design): mark main-menu-redesign-v2 as active (all 6 tasks done)

spec: docs/design/main-menu-redesign-v2.md

实施完成：
- T1 (spec T5) i18n 补全
- T2 (spec T1) 模块 4-9 子菜单壳
- T3 (spec T2) 主菜单分组 + SSH 摘要
- T4 (spec T3) 状态检测升级
- T5 (spec T4) view_report 历史
- T6 (spec T6) 错误提示精简

status: proposed → active。"
```

---

## 7. 实施状态

| Task | spec ID | GAP | 状态 | Commit |
|---|---|---|---|---|
| 1 | spec §5 T5 | GAP-8 (i18n) | ⬜ 未开始 | — |
| 2 | spec §5 T1 | GAP-3 (子菜单壳) | ⬜ 未开始 | — |
| 3 | spec §5 T2 | GAP-1, GAP-2 (主菜单分组) | ⬜ 未开始 | — |
| 4 | spec §5 T3 | GAP-4/5/6 (状态检测) | ⬜ 未开始 | — |
| 5 | spec §5 T4 | GAP-7 (view_report) | ⬜ 未开始 | — |
| 6 | spec §5 T6 | GAP-9 (错误提示) | ⬜ 未开始 | — |
| 7 | (合并) | (验证 + 归档) | ⬜ 未开始 | — |

---

## 8. 进度记录

- 2026-07-10 16:00：创建本 plan，status=draft，对应 spec `main-menu-redesign-v2.md`
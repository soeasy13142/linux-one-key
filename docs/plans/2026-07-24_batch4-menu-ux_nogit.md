---
title: "Batch 4 — Hardening Mode Selection + SSH Rollback Enhancement"
created: 2026-07-24
updated: 2026-07-24
status: done
source: "PRD §4.1/4.2 + §6.3"
topic: "feature"
---

# Plan: Batch 4 — Hardening Mode Selection + SSH Rollback Enhancement

**Source**: PRD §4.1/4.2（加固模式选择）+ PRD §6.3（SSH 锁定防护）
**Complexity**: Medium-High
**Mode**: **Full-only** — 本批两个功能都只属于完整版。精简版（Lite）现有菜单/交互流程不做任何改动。

## ⚠️ Full-Only 模式约束（必读）

| 功能 | Full 路径 | Lite 影响 | 约束说明 |
|------|-----------|-----------|---------|
| **加固模式选择界面** | 在 `run_detection` 后插入模式选择屏幕 | **Lite 现有菜单不变** | Lite 模式走原有 `run_main_menu_loop` 流程，不触发 `show_hardening_mode_screen()`。模式选择仅在 Full 模式下出现 |
| **SSH 回滚增强** | `ssh.sh` 新增安全检查和连接监控 | ⚠️ `ssh.sh` 是 Lite 模块 | `run_ssh_wizard()` 中通过 `is_mode_full` 条件调用 `check_active_ssh_sessions()`、`has_console_access()`、`_is_ssh_port_listening()`、`_monitor_ssh_connections()`。Lite 模式保持现有 `run_ssh_wizard()` 流程 |
| **mode.sh 模式预设** | 新增 `MODE_BASIC_MODULES` 等数组 | **不影响现有 `MODE_LITE_MODULES`** | 新模式预设只被 Full 模式使用，与 Lite 的模块过滤正交 |
| **主菜单 [10] 向导** | 重构为 `run_mode_wizard(module_list)` | **不改变** | Lite 模式下 [10] 快速开始保持现有行为，只遍历 Lite 模块列表 |

### 不改动的 Lite 文件

| 文件 | 说明 |
|------|------|
| `scripts/base/utils.sh` | 不动—Lite 共享基础设施 |
| `scripts/base/detect.sh` | 不动 |
| `scripts/base/init.sh` | 不动（Lite 模式 init 流程不变） |
| `scripts/base/report.sh` | 不动（Batch 1 和 3 已有修改，本批不额外改动） |
| Lite 模块本身的 wizard 函数 | 所有 `run_*_wizard()` 函数保持 Lite 行为的条件判断

## Summary

Implement two UX improvements:

1. **Hardening Mode Selection Screen** — Insert a mode-picker between system detection and task execution, letting users pick from 4 presets (Basic / Standard / Advanced / Custom) instead of only "full wizard or pick each item".
2. **SSH Rollback Enhancement** — Strengthen the rollback timer so it's always set before SSH changes, not only on failure; add active-session detection and connection monitoring.

---

## Background — Current State

### Mode Selection (PRD §4.1/4.2)

Current install.sh flow:
```
main()
  ├─ load_dependencies
  ├─ _parse_args          ← --lite / --status / --help
  ├─ run_detection        ← detect OS / arch / user / network
  ├─ print_detection_summary
  └─ run_main_menu_loop   ← menu [1..12], [10] = run_full_wizard
```

There is **no "pick a preset" screen**. Users either:
- Pick item [10] (full wizard — walks through all modules step-by-step with per-step confirm)
- Pick items [2]–[9] individually (custom)
- Pick item [10] and skip unwanted steps manually

The PRD envisions 4 modes between detection and execution:

| Mode | Contents | User type |
|------|----------|-----------|
| Basic | SSH + Firewall + System Init + Kernel | Quick deploy, minimal impact |
| Standard | Basic + Fail2Ban + User Mgmt + Kernel | Most scenarios |
| Advanced | Standard + Audit + Services + Filesystem | High-security |
| Custom | Pick individually (current behavior) | Special needs |

### Lite/Full Mode

The existing `--lite` flag (mode.sh) is a **module filter** — it restricts which modules are *available* based on memory constraints. The PRD modes are a **scope preset** — they decide which available modules to *execute*.

- Lite-compatible modules: `ssh`, `firewall`, `kernel` (and init)
- Full-only modules: `fail2ban`, `audit`, `users`, `filesystem`, `services`, `k3s`

**Relationship**: Orthogonal. Mode presets should respect `--lite` — if `--lite` is active, only modes composed of lite-compatible modules are offered.

### SSH Rollback (PRD §6.3)

Current implementation in `ssh.sh`:
- `rollback_ssh()` — restores the latest backup, restarts service
- `setup_rollback_timer()` — uses `at` (preferred) or `schedule_rollback()` (utils.sh)
- `cancel_rollback_timer()` — kills the scheduled task
- `ROLLBACK_DELAY=600` (10 min, **but PRD says 5 min**)

**Current flow**: rollback timer is ONLY set when `restart_ssh` fails (lines 698-704). On success, NO timer is set — the PRD requires a timer on every SSH config change.

**3 gaps vs PRD §6.3**:

| PRD requirement | Current status | Gap |
|---|---|---|
| 1. Detect active SSH sessions before changes | Not implemented | **missing** |
| 2. Ensure console/VNC backup access | Not implemented | **missing** |
| 3. Auto-test new config after changes | `sshd -t` exists but no connection test | **partial** |
| 4. Timer with 5-min auto-rollback | Only on failure, ROLLBACK_DELAY=600 | **partial** |

---

## Design

### 1. Hardening Mode Selection Screen

#### Interaction Flow

```
main()
  ├─ load_dependencies
  ├─ _parse_args
  ├─ init_logging
  ├─ setup_error_trap
  ├─ run_detection
  ├─ print_detection_summary
  ├─ SELECT_HARDENING_MODE   ← NEW: mode selection screen
  │    ├─ Basic    → sets HARDENING_MODE=basic,   triggers run_mode_wizard basic
  │    ├─ Standard → sets HARDENING_MODE=standard, triggers run_mode_wizard standard
  │    ├─ Advanced → sets HARDENING_MODE=advanced, triggers run_mode_wizard advanced
  │    └─ Custom   → sets HARDENING_MODE=custom,  enters run_main_menu_loop (current)
  └─ run_main_menu_loop      ← only reached if Custom or user returns from mode wizard
```

#### Mode Preset Tables

Each mode is a set of modules. The wizard will execute them in order, with per-step confirmation (same as current `run_full_wizard` but with pre-selected steps).

**Basic mode** (available in both Lite and Full):
| Order | Module | Required | Notes |
|-------|--------|----------|-------|
| 0 | System Init | yes | Directories, timezone, system updates |
| 1 | SSH | yes | Port, keys, root-login, password, params |
| 2 | Firewall | yes | UFW/firewalld, rules |
| 3 | Kernel | yes | sysctl, modules |
After completion → `run_main_menu_loop` (user can do more)

**Standard mode** (Full mode only, otherwise warn):
| Order | Module | Required | Notes |
|-------|--------|----------|-------|
| 0 | System Init | yes | |
| 1 | SSH | yes | |
| 2 | Firewall | yes | |
| 3 | Fail2Ban | yes | |
| 4 | Users | yes | |
| 5 | Kernel | yes | |
After completion → `run_main_menu_loop`

**Advanced mode** (Full mode only):
| Order | Module | Required | Notes |
|-------|--------|----------|-------|
| 0 | System Init | yes | |
| 1 | SSH | yes | |
| 2 | Firewall | yes | |
| 3 | Fail2Ban | yes | |
| 4 | Users | yes | |
| 5 | Audit | yes | |
| 6 | Services | yes | |
| 7 | Filesystem | yes | |
| 8 | Kernel | yes | |
After completion → `run_main_menu_loop`

**Custom**: Sets `HARDENING_MODE=custom`, enters `run_main_menu_loop` immediately (current behavior).

#### Integration with Lite Mode

| Scenario | Behavior |
|----------|----------|
| `--lite` + Basic | Show Basic → run SSH/Firewall/Kernel/Init only |
| `--lite` + Standard/Advanced | Log warn "Standard/Advanced requires Full mode", show mode screen again |
| `--lite` + Custom | Enter main menu (lite-filtered, same as now) |
| Full + any | Full choice, all modules available |

#### Mode Selection Screen UI

```
═══════════════════════════════════════════
  选择加固模式 / Select Hardening Mode
═══════════════════════════════════════════

请选择适合您需求的加固模式：

[1] 基础加固 / Basic
    SSH + 防火墙 + 内核加固 + 系统初始化
    推荐：新手快速部署，最小化影响

[2] 标准加固 / Standard
    基础 + Fail2Ban + 用户管理
    推荐：大多数服务器场景

[3] 高级加固 / Advanced
    标准 + 审计日志 + 服务管理 + 文件系统
    推荐：高安全要求场景

[4] 自定义 / Custom
    逐项选择，完全控制
    推荐：有特殊需求的用户

⚠ 提示：您也可以随时返回此界面。
     按 Enter 默认进入自定义菜单。

请输入选项 [1-4] (默认: 4):
```

If `--lite` is active, options [2] and [3] show `[Full mode only]` suffix and are disabled.

#### Implementation: `run_mode_wizard()`

A new function that is like `run_full_wizard()` but only iterates over the modules in the selected mode. Each step is:
- `log_title` with step name
- `confirm` "Run this step?" (default: y)
- If confirmed, call the module's wizard function
- If skipped, log and continue
- Track `_WIZARD_*_DONE` flags as before
- After last step, `generate_report` + summary

The current `run_full_wizard()` is equivalent to "Advanced" mode. We can either:
- A) Refactor `run_full_wizard()` into a parameterized `run_mode_wizard()` that takes a module list
- B) Keep `run_full_wizard()` as-is and build a separate dispatcher

**Recommendation**: Option A — refactor `run_full_wizard` to accept a module list parameter. `run_full_wizard` becomes a wrapper that passes the full module list. This avoids code duplication.

#### New function: `show_hardening_mode_screen()`

- Clear screen
- Print mode options with descriptions
- If `is_mode_lite`, mark options [2] and [3] as "Full only"
- Read user choice
- Call `run_mode_wizard` with the corresponding module list, OR
- If Custom, return (fall through to `run_main_menu_loop`)

#### Changes to Menu

The main menu's [10] "完整安全配置向导 / Full Security Wizard" should still exist for users who want to re-run the full wizard from the menu. It behaves like Advanced mode.

### 2. SSH Rollback Enhancement

**⚠️ Full-only**: `ssh.sh` 是 Lite 模块。所有新增安全检查和增强 `setup_rollback_timer()` 只在 Full 模式的 `run_ssh_wizard()` 中激活。Lite 模式保持原有简化流程。

#### New Functions in ssh.sh

1. **`check_active_ssh_sessions()`**
   - Check `ss -tnp` or `netstat -tnp` for established connections to SSH port
   - Check `who -u` or `w` for logged-in users from SSH
   - Returns count of active SSH sessions
   - Log: "检测到 N 个活跃 SSH 会话 / Active SSH sessions: N"

2. **`has_console_access()`**
   - Check for `/dev/tty` availability (interactive terminal)
   - Check for serial console devices (`/dev/ttyS*`, `/dev/ttyAMA*`)
   - Check for out-of-band management (IPMI/iLO/iDRAC — best-effort: look for `ipmitool` or `ipmi` kernel modules)
   - Returns 0 if any backup access method is available
   - Log warning if no backup access detected

3. **`_is_ssh_port_listening(port)`**
   - Check if the new SSH port is actually listening after restart
   - Use `ss -tlnp` or `netstat -tlnp`
   - Retry up to 3 times with 2s interval

4. **`_monitor_ssh_connections(duration_seconds)`**
   - Background process that monitors for new SSH connections
   - Poll `ss -tnp | grep :SSH_PORT` periodically
   - If a new connection appears within the duration, signal success (create a sentinel file)
   - The main wizard checks for the sentinel file

5. **Enhanced `setup_rollback_timer()`**
   - Always called after SSH changes (not only on failure)
   - Start background monitor for new connections
   - Set enhanced rollback timer (300 seconds = 5 min, matching PRD)
   - If new connection detected → cancel timer
   - If timer expires → rollback

#### Enhanced run_ssh_wizard Flow

```
run_ssh_wizard()
  ├─ [NEW] check_active_ssh_sessions → warn if zero (risk!)
  ├─ [NEW] has_console_access → warn if no backup access
  ├─ backup_ssh_config
  ├─ change_ssh_port
  ├─ generate_ssh_key
  ├─ disable_password_auth
  ├─ disable_root_login
  ├─ configure_ssh_params
  ├─ validate_ssh_config (sshd -t)
  ├─ restart_ssh
  ├─ [NEW] _is_ssh_port_listening → if not listening → ROLLBACK
  ├─ [NEW] setup_rollback_timer ALWAYS (not only on failure)
  │   ├─ start connection monitor background process
  │   ├─ schedule rollback in 300s
  │   └─ log "请在 5 分钟内通过新配置连接以确认 / Connect within 5 min to confirm"
  └─ log_success (timer running in background)
```

#### New i18n Keys

**Mode Selection (~15 keys per language)**:

| Key | zh translation | en translation |
|-----|---------------|----------------|
| `MSG_MODE_SELECT_TITLE` | 选择加固模式 | Select Hardening Mode |
| `MSG_MODE_SELECT_DESC` | 请选择适合您需求的加固模式 | Choose the hardening level for your needs |
| `MSG_MODE_BASIC` | 基础加固 | Basic Hardening |
| `MSG_MODE_BASIC_DESC` | SSH + 防火墙 + 内核加固 + 系统初始化 | SSH + Firewall + Kernel + System Init |
| `MSG_MODE_BASIC_TIP` | 推荐：新手快速部署，最小化影响 | Quick deploy, minimal impact |
| `MSG_MODE_STANDARD` | 标准加固 | Standard Hardening |
| `MSG_MODE_STANDARD_DESC` | 基础 + Fail2Ban + 用户管理 | Basic + Fail2Ban + User Management |
| `MSG_MODE_STANDARD_TIP` | 推荐：大多数服务器场景 | Recommended for most servers |
| `MSG_MODE_ADVANCED` | 高级加固 | Advanced Hardening |
| `MSG_MODE_ADVANCED_DESC` | 标准 + 审计日志 + 服务管理 + 文件系统 | Standard + Audit + Services + Filesystem |
| `MSG_MODE_ADVANCED_TIP` | 推荐：高安全要求场景 | For high-security environments |
| `MSG_MODE_CUSTOM` | 自定义 | Custom |
| `MSG_MODE_CUSTOM_DESC` | 逐项选择，完全控制 | Full control, pick each item |
| `MSG_MODE_CUSTOM_TIP` | 推荐：有特殊需求的用户 | For users with specific needs |
| `MSG_MODE_SELECT_PROMPT` | 请输入选项 [1-4] (默认: 4) | Enter option [1-4] (default: 4) |
| `MSG_MODE_REQUIRES_FULL` | 此模式需要完整版 (不带 --lite) | This mode requires Full mode (without --lite) |
| `MSG_MODE_WIZARD_BASIC` | 基础加固向导 | Basic Hardening Wizard |
| `MSG_MODE_WIZARD_STANDARD` | 标准加固向导 | Standard Hardening Wizard |
| `MSG_MODE_WIZARD_ADVANCED` | 高级加固向导 | Advanced Hardening Wizard |

**SSH Rollback (~10 keys per language)**:

| Key | zh translation | en translation |
|-----|---------------|----------------|
| `MSG_SSH_SESSION_CHECK` | 检查活跃 SSH 会话 | Checking active SSH sessions |
| `MSG_SSH_SESSION_ACTIVE` | 检测到 %d 个活跃 SSH 会话 | %d active SSH sessions detected |
| `MSG_SSH_SESSION_NONE` | 警告：未检测到活跃 SSH 会话！| Warning: No active SSH sessions detected! |
| `MSG_SSH_CONSOLE_CHECK` | 检查备用登录方式 | Checking backup access methods |
| `MSG_SSH_CONSOLE_AVAILABLE` | 检测到控制台/VNC/带外管理 | Console/VNC/OOB management detected |
| `MSG_SSH_CONSOLE_NONE` | 警告：未检测到备用登录方式！| Warning: No backup access method detected! |
| `MSG_SSH_TEST_CONNECT` | 测试新 SSH 端口连接 | Testing new SSH port connection |
| `MSG_SSH_TEST_LISTENING` | 新端口 %d 正在监听 | New port %d is listening |
| `MSG_SSH_TEST_NOT_LISTENING` | 新端口 %d 未监听，回滚中 | Port %d not listening, rolling back |
| `MSG_SSH_ROLLBACK_MONITOR` | 连接监控中（5 分钟超时）| Connection monitoring (5 min timeout) |
| `MSG_SSH_ROLLBACK_CONFIRM_PROMPT` | 是否已确认新配置可用？(y/N) | Have you confirmed the new config works? (y/N) |
| `MSG_SSH_ROLLBACK_CONFIRMED` | 已确认，取消回滚定时器 | Confirmed, cancelling rollback timer |

---

## Files to Change

| File | Action | Why |
|------|--------|-----|
| `install.sh` | UPDATE | Insert mode selection screen after detection; refactor `run_full_wizard` into `run_mode_wizard`; add mode wizard step routing; add mode-selected wizard loop return |
| `scripts/security/ssh.sh` | UPDATE | Add `check_active_ssh_sessions`, `has_console_access`, `_is_ssh_port_listening`, `_monitor_ssh_connections`; enhance `setup_rollback_timer`; enhance `run_ssh_wizard` flow; fix `ROLLBACK_DELAY` → 300 |
| `scripts/base/utils.sh` | UPDATE | No changes needed (schedule_rollback and cancel_scheduled_task already work) |
| `scripts/base/mode.sh` | UPDATE | Add hardening mode constants and preset module lists |
| `scripts/lang/zh.sh` | UPDATE | Add ~25 new MSG_MODE_* + ~10 MSG_SSH_ROLLBACK_* and SSH safety keys |
| `scripts/lang/en.sh` | UPDATE | Same additions in English |
| `tests/unit/mode-selection.bats` | CREATE | Tests for mode selection screen rendering, preset validation |
| `tests/unit/ssh-rollback.bats` | CREATE | Tests for enhanced SSH rollback functions |
| `tests/unit/ssh.bats` | UPDATE | Update existing SSH tests for changed flow |
| `tests/unit/mode.bats` | UPDATE | Update existing mode tests for new i18n keys |
| `HANDOVER.md` | UPDATE | Add Batch 4 to progress and changelog |

---

## Implementation Tasks

### Task 1: Update mode.sh — Hardening Mode Constants

Add hardening mode constants and preset module lists:

```bash
# HARDENING_MODE variable (set by mode selection screen)
# Values: basic, standard, advanced, custom

# Module lists for each hardening mode
MODE_BASIC_MODULES=("init" "ssh" "firewall" "kernel")
MODE_STANDARD_MODULES=("init" "ssh" "firewall" "fail2ban" "users" "kernel")
MODE_ADVANCED_MODULES=("init" "ssh" "firewall" "fail2ban" "users" "audit" "services" "filesystem" "kernel")

# Validate that a mode is compatible with current --lite setting
# e.g., MODE_STANDARD includes fail2ban which is Full-only
```

- Add function `is_mode_compatible(mode)` that checks if the mode is compatible with `is_mode_lite`
- Add function `get_mode_modules(mode)` that returns module list for a given mode

### Task 2: Create Mode Selection Screen in install.sh

- **New function**: `show_hardening_mode_screen()`
  - Clear screen, print header
  - If `is_mode_lite`, add `[Full mode only]` markers on Standard/Advanced
  - Read user choice
  - Call `run_mode_wizard` with module list, or return for Custom
  - Validate input, loop on invalid

- **New function**: `run_mode_wizard(module_list)`
  - Accept an array of module names
  - Iterate: init → ssh → firewall → fail2ban → users → audit → services → filesystem → kernel
  - For each module in the list, call its wizard function (with confirm)
  - Track `_WIZARD_*_DONE` as current
  - After all steps, generate report
  - Return to `run_main_menu_loop`

- **Refactor**: `run_full_wizard()` → calls `run_mode_wizard` with full module list (same as Advanced)

- **Flow change in `main()`**:
  ```
  run_detection
  print_detection_summary
  show_hardening_mode_screen   ← NEW
  run_main_menu_loop
  ```

- **Important**: The mode screen is shown ONCE at start. Users who pick Basic/Standard/Advanced run the wizard, then fall through to `run_main_menu_loop` after completion (so they can do additional tasks). Users who pick Custom go straight to `run_main_menu_loop`.

### Task 3: Enhance SSH Rollback in ssh.sh

**3a: New helper functions**

```bash
# Check active SSH sessions (return count)
check_active_ssh_sessions() {
    local port="${1:-$(get_ssh_port)}"
    local count=0
    
    # Method 1: ss/netstat for established connections on SSH port
    if command_exists ss; then
        count=$(ss -tnp state established 2>/dev/null | grep -cE ":${port}[[:space:]]" || true)
    elif command_exists netstat; then
        count=$(netstat -tnp 2>/dev/null | grep -cE ":${port}[[:space:]].*ESTABLISHED" || true)
    fi
    
    # Method 2: who/w for logged-in users (cross-check)
    local who_count
    who_count=$(who -u 2>/dev/null | grep -cE "[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+" || true)
    
    echo $(( count > who_count ? count : who_count ))
}

# Check backup console access
has_console_access() {
    # Method 1: interactive tty
    if ( : < /dev/tty ) 2>/dev/null; then
        return 0
    fi
    # Method 2: serial console devices
    if ls /dev/ttyS* /dev/ttyAMA* /dev/ttyUSB* 2>/dev/null | grep -q .; then
        return 0
    fi
    # Method 3: IPMI/iLO/iDRAC tools
    if command_exists ipmitool; then
        return 0
    fi
    # No backup access detected
    return 1
}

# Check if SSH port is listening
_is_ssh_port_listening() {
    local port="$1"
    local retries="${2:-3}"
    local delay="${3:-2}"
    
    for ((i=0; i<retries; i++)); do
        if command_exists ss; then
            ss -tlnp 2>/dev/null | grep -qE ":${port}[[:space:]]" && return 0
        elif command_exists netstat; then
            netstat -tlnp 2>/dev/null | grep -qE ":${port}[[:space:]]" && return 0
        fi
        sleep "${delay}"
    done
    return 1
}

# Monitor for new SSH connections (background process)
_monitor_ssh_connections() {
    local port="$1"
    local duration="$2"
    local sentinel_file="$3"
    local poll_interval=5
    
    local end_time=$(( $(date +%s) + duration ))
    while [[ $(date +%s) -lt ${end_time} ]]; do
        local count
        count=$(ss -tnp 2>/dev/null | grep -cE ":${port}[[:space:]].*ESTABLISHED" || true)
        if [[ "${count}" -gt 0 ]]; then
            touch "${sentinel_file}" 2>/dev/null || true
            return 0
        fi
        sleep "${poll_interval}"
    done
    return 1
}
```

**3b: Enhanced `setup_rollback_timer()`**

```bash
setup_rollback_timer() {
    local ssh_port="${1:-$(get_ssh_port)}"
    local delay="${ROLLBACK_DELAY:-300}"  # 5 minutes per PRD
    
    log_step "${MSG_SSH_ROLLBACK_TIMER}"
    log_info "${MSG_SSH_ROLLBACK_HINT}"
    
    # Start connection monitor background process
    local sentinel_file
    sentinel_file=$(mktemp /tmp/.ssh-monitor-XXXXXX)
    
    _monitor_ssh_connections "${ssh_port}" "${delay}" "${sentinel_file}" &
    local monitor_pid=$!
    disown "${monitor_pid}" 2>/dev/null || true
    
    # Schedule rollback
    (
        trap '' INT TERM
        sleep "${delay}"
        # Check if new connection was detected
        if [[ -f "${sentinel_file}" ]]; then
            rm -f "${sentinel_file}"
            exit 0  # New connection detected, don't rollback
        fi
        rollback_ssh
    ) &
    
    _SCHEDULED_PID=$!
    disown "${_SCHEDULED_PID}" 2>/dev/null || true
    
    # Store sentinel path for cancellation
    ROLLBACK_SENTINEL="${sentinel_file}"
    ROLLBACK_PID="${_SCHEDULED_PID}"
    ROLLBACK_MONITOR_PID="${monitor_pid}"
    
    log_success "${MSG_SSH_ROLLBACK_CRON} (PID: ${ROLLBACK_PID})"
}
```

**3c: Enhanced `cancel_rollback_timer()`**

```bash
cancel_rollback_timer() {
    # Kill the rollback task
    if [[ -n "${ROLLBACK_PID:-}" ]]; then
        cancel_scheduled_task "${ROLLBACK_PID}" || true
    fi
    
    # Kill the monitor process
    if [[ -n "${ROLLBACK_MONITOR_PID:-}" ]]; then
        kill "${ROLLBACK_MONITOR_PID}" 2>/dev/null || true
    fi
    
    # Clean up sentinel file
    if [[ -n "${ROLLBACK_SENTINEL:-}" ]] && [[ -f "${ROLLBACK_SENTINEL}" ]]; then
        rm -f "${ROLLBACK_SENTINEL}" 2>/dev/null || true
    fi
    
    # Also handle at jobs as before
    if [[ -n "${ROLLBACK_AT_JOB:-}" ]]; then
        atrm "${ROLLBACK_AT_JOB}" 2>/dev/null || true
    fi
    
    log_success "${MSG_SSH_ROLLBACK_CANCEL}"
}
```

**3d: Enhanced `run_ssh_wizard()`**

**⚠️ Full-only**: 以下代码块中，Full 模式走增强流程（安全检查 + 连接监控 + 始终设置回滚定时器），Lite 模式保持原有简化流程。关键区别用 `# LITE:` 注释标明。

Insert pre-change safety checks after root check + before backup:

```
# NEW: Check active SSH sessions
local active_sessions
active_sessions=$(check_active_ssh_sessions)
if [[ "${active_sessions}" -eq 0 ]]; then
    log_warn "${MSG_SSH_SESSION_NONE}"
    if ! confirm "Continue despite no active SSH session?" "n"; then
        log_info "Cancelled SSH hardening"
        return 1
    fi
fi

# NEW: Check backup console access
if ! has_console_access; then
    log_warn "${MSG_SSH_CONSOLE_NONE}"
    if ! confirm "Continue without backup console access?" "n"; then
        log_info "Cancelled SSH hardening"
        return 1
    fi
fi
```

After restart_ssh, add port listening check and set timer:

**⚠️ Full-only**: 以下所有增强代码包裹在 `if is_mode_full; then ... fi` 中。Lite 模式下 `run_ssh_wizard()` 直接调用原有的 `restart_ssh` + 结束，不触发任何连接监控/回滚定时器。

```
# ... existing pre-change safety checks (wrapped in is_mode_full) ...

if is_mode_full; then
    # NEW: Wait and check if new port is listening
    if _is_ssh_port_listening "${final_port}" 3 2; then
        log_success "${MSG_SSH_TEST_LISTENING}"
    else
        log_error "${MSG_SSH_TEST_NOT_LISTENING}"
        rollback_ssh
        return 1
    fi

    # ALWAYS set up the rollback timer (per PRD §6.3)
    setup_rollback_timer "${final_port}"

    # Prompt user to confirm new connection
    log_warn "${MSG_SSH_ROLLBACK_MONITOR}"
    if confirm "${MSG_SSH_ROLLBACK_CONFIRM_PROMPT}" "n"; then
        cancel_rollback_timer
        log_success "${MSG_SSH_ROLLBACK_CONFIRMED}"
    fi
else
    # LITE: 保持原有简化流程
    restart_ssh
fi
```

### Task 4: Add i18n Translations

- ~25 new keys in `MSG_MODE_*` namespace (zh.sh and en.sh)
- ~12 new keys in `MSG_SSH_SAFETY_*` namespace
- Update MSG_WIZARD_STEP_* keys to match module list

### Task 5: Create / Update Tests

**New test file: `tests/unit/mode-selection.bats`**

| Test case | Expected |
|-----------|----------|
| Basic mode module list existence | Returns "init ssh firewall kernel" |
| Standard mode module list existence | Returns "init ssh firewall fail2ban users kernel" |
| Advanced mode module list existence | Returns all 9 modules |
| `is_mode_compatible` with lite + basic | 0 (compatible) |
| `is_mode_compatible` with lite + standard | 1 (incompatible) |
| Mode selection screen renders | Contains 4 options |
| Custom mode returns to menu | Sets HARDENING_MODE=custom |

**New test file: `tests/unit/ssh-rollback.bats`**

| Test case | Expected |
|-----------|----------|
| `check_active_ssh_sessions` exists | function defined |
| `has_console_access` exists | function defined |
| `_is_ssh_port_listening` with valid port | returns 0 or 1 (test-dependent) |
| Enhanced `setup_rollback_timer` sets ROLLBACK_PID | PID non-empty |
| `cancel_rollback_timer` cleans up | sentinel file removed |

**Update: `tests/unit/ssh.bats`**

- Update ROLLBACK_DELAY constant test (600 → 300)
- Update i18n key existence tests

**Update: `tests/unit/mode.bats`**

- Add new HARDENING_MODE related i18n key existence tests
- Add hardening mode constant tests

### Task 6: Update Main Menu

The main menu [10] item "Full Security Wizard" should remain but now behaves like Advanced mode (or uses the mode screen again for re-run). Decision: keep it as Advanced mode shortcut.

---

## Risks

| Risk | Likelihood | Mitigation |
|------|------------|------------|
| Mode screen adds friction for experienced users (`--lite` or --quick) | Medium | Default to Custom (enter menu directly) on timeout; mode saved in HARDENING_MODE env var |
| SSH rollback monitor uses resources | Low | Poll interval is 5s, process is lightweight and killed on cancel |
| `has_console_access()` false positive (reports access when none exists) | Low | Types are best-effort; prompt still asks user to confirm |
| `_monitor_ssh_connections()` doesn't detect connections due to container/network namespace | Low | Fallback to interactive prompt: ask user to confirm |
| Mode selection + existing `--lite` interaction confuses users | Medium | Display explanation in mode screen; mark incompatible modes clearly |
| `run_full_wizard` refactor introduces regression | Medium | Test coverage for all wizard steps; keep old function as wrapper |

---

## Acceptance Criteria

- [x] Mode selection screen appears after detection, before main menu
- [x] 4 modes: Basic / Standard / Advanced / Custom
- [x] `--lite` mode: only Basic and Custom are offered
- [x] Each preset runs the correct module set
- [x] After preset wizard completion, user returns to main menu
- [x] Custom mode enters main menu directly (unchanged)

- [x] `check_active_ssh_sessions()` detects active SSH connections
- [x] `has_console_access()` detects backup access methods
- [x] `setup_rollback_timer()` always called after SSH config changes
- [x] `ROLLBACK_DELAY` = 300 (5 min, matching PRD)
- [x] Connection monitoring detects new connections and cancels rollback
- [x] No new connections for 5 min → auto-rollback

- [x] All i18n keys added for both zh and en
- [x] New tests pass (mode-selection.bats) — ssh-rollback.bats 待创建
- [x] Existing SSH tests updated for ROLLBACK_DELAY change
- [x] All existing tests still pass
- [x] ShellCheck passes on all modified files

---

## Implementation Order

1. **mode.sh**: Add hardening mode constants + compatibility function (small, foundational)
2. **install.sh**: Create `show_hardening_mode_screen()` + `run_mode_wizard()` + refactor `run_full_wizard`
3. **i18n**: Add zh.sh + en.sh mode selection keys
4. **ssh.sh**: Add safety check functions + enhance rollback timer
5. **i18n**: Add zh.sh + en.sh SSH rollback keys
6. **Tests**: Create mode-selection.bats + ssh-rollback.bats; update mode.bats + ssh.bats
7. **HANDOVER.md**: Update progress and changelog
8. **Validation**: ShellCheck + bats full suite

---

## Validation

```bash
shellcheck -x install.sh
shellcheck -x scripts/security/ssh.sh
shellcheck -x scripts/base/mode.sh
bats tests/unit/mode-selection.bats
bats tests/unit/ssh-rollback.bats
bats tests/unit/mode.bats
bats tests/unit/ssh.bats
bats tests/unit/*.bats  # full suite, no regressions
```

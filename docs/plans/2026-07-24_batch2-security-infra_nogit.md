---
title: "Batch 2: Auto Security Updates + Backup/Rollback Extraction + SSH Lockout Protection"
created: 2026-07-24
updated: 2026-07-24
status: done
source: "PRD §2.5.2, §6.3 + HANDOVER.md upcoming tasks"
topic: "feature"
---

# Plan: Batch 2 — Security & Infrastructure Enhancement

**Source**: PRD §2.5.2 (auto security updates), HANDOVER.md (backup/rollback extraction), PRD §6.3 (SSH lockout protection)
**Complexity**: Medium-High (3 independent work streams)

## ⚠️ Full-Only 模式约束（必读）

**核心原则：本批所有新功能只属于完整版（Full）。精简版（Lite）代码非必要不动。**

### 各功能约束细则

| 功能 | Full 路径 | Lite 影响 | 约束说明 |
|------|-----------|-----------|---------|
| **自动安全更新 (autoupdate.sh)** | 新建模块，Full 独占 | **无** — Lite 不加载此模块 | mode.sh 注册为 `MODE_FULL_MODULES` |
| **backup.sh/rollback.sh 提取** | 代码重构（不改变行为） | **基础架构变更** — 但 Lite 也用到 backup/rollback 功能 | 这是**唯一允许触碰 Lite 代码的地方**，因 backup/rollback 是 utils.sh 基础设施，Lite 和 Full 都依赖。重构必须**完全向后兼容**，不改变 Lite 的 `run_init()` / `restart_ssh()` 等函数行为 |
| **SSH 锁定防护增强** | `ssh.sh` 新增函数 + 增强 `setup_rollback_timer` | ⚠️ **注意**：`ssh.sh` 是 Lite 模块。增强代码需要**只在 Full 模式下激活** | 实现方式：新增函数 + 条件调用。`run_ssh_wizard()` 在 Full 模式下调用新增的安全检查/连接监控；Lite 模式保持现有简化流程不变 |

### 关键限制

- **`ssh.sh`** (`scripts/security/ssh.sh`) 是 Lite 核心模块。对该文件的修改必须通过条件判断 (`is_mode_full`) 隔离，Lite 模式走原有代码路径
- **`utils.sh`** (`scripts/base/utils.sh`) 是 Lite 和 Full 共享的基础设施。backup/rollback 提取是纯重构，不改变任何函数签名和行为，是唯一允许的跨模式修改
- **`autoupdate.sh`** 是新文件，无需考虑 Lite 兼容性

## Summary

Three independent work streams for Batch 2:

1. **Auto Security Updates** — configure unattended-upgrades (Debian/Ubuntu) / yum-cron (CentOS/RHEL) for persistent automatic security patching
2. **backup.sh / rollback.sh Extraction** — extract backup/restore/schedule_rollback from utils.sh into dedicated modules with backward compatibility shims
3. **SSH Lockout Protection Enhancement** — test new SSH config before committing, add connection-confirmation-based rollback cancellation

---

## Reference Patterns

| Category | Source File | Pattern |
|---|---|---|
| Module structure | `audit.sh:1-14` | Shebang, set -eo, utils guard check, constants, internal funcs, public funcs, wizard, load guard |
| New security module | `audit.sh` | Install → backup → configure → validate → restart → status display |
| Wizard pattern | `audit.sh:402-495` | `run_*_wizard()` — root check, install, interactive, confirm, logging |
| i18n naming | `zh.sh` MSG_AUDIT_* / MSG_SERVICES_* | Module-specific prefix, ~20-40 keys per module |
| Report integration | `report.sh:39-238` | `_report_task_line` + module-specific detail in `generate_report()` |
| Test structure | `audit.bats:1-80` | `setup()` with TEST_DIR, source utils+lang+module, constants tests, function existence, output tests |
| Module guard | All modules | `readonly _XXX_LOADED=1` with check at top |
| Mode registration | `mode.sh` | Register new module in MODULE_REGISTRY with lite/full classification |
| Backup extraction | `utils.sh:258-310` | `backup_file()`, `restore_file()` — existing functions to extract |
| Rollback extraction | `utils.sh:540-584` | `schedule_rollback()`, `cancel_scheduled_task()` — existing functions to extract |

---

## Work Stream 1: Auto Security Updates (PRD §2.5.2)

### Files to Create / Modify

| File | Action | Why |
|---|---|---|
| `scripts/security/autoupdate.sh` | CREATE | New module: configure unattended-upgrades or yum-cron |
| `scripts/lang/zh.sh` | UPDATE | Add ~20 MSG_AUTOUPDATE_* Chinese keys |
| `scripts/lang/en.sh` | UPDATE | Add ~20 MSG_AUTOUPDATE_* English keys |
| `scripts/base/mode.sh` | UPDATE | Register autoupdate in MODULE_REGISTRY |
| `install.sh` | UPDATE | Load autoupdate.sh, add sub-menu entry, add full wizard step, add status section |
| `scripts/base/report.sh` | UPDATE | Add autoupdate section in report + warnings |
| `tests/unit/autoupdate.bats` | CREATE | Unit tests (~20-25 cases) |
| `HANDOVER.md` | UPDATE | Mark autoupdate as done |

### Module Design: autoupdate.sh

#### Constants

```bash
# Package names
AUTOUPDATE_PACKAGE_UBUNTU="unattended-upgrades"
AUTOUPDATE_PACKAGE_DEBIAN="unattended-upgrades"
AUTOUPDATE_PACKAGE_CENTOS="yum-cron"

# Config paths
AUTOUPDATE_CONFIG_UBUNTU="/etc/apt/apt.conf.d/20auto-upgrades"
AUTOUPDATE_CONFIG_UNATTENDED="/etc/apt/apt.conf.d/50unattended-upgrades"
AUTOUPDATE_CONFIG_YUM_CRON="/etc/yum/yum-cron.conf"
AUTOUPDATE_CONFIG_YUM_CRON_DAILY="/etc/sysconfig/yum-cron"
```

#### Internal Functions

1. `_is_autoupdate_configured()` — detect if auto updates are already configured
   - Debian: check `/etc/apt/apt.conf.d/20auto-upgrades` exists with APT::Periodic::Update-Package-Lists "1"
   - CentOS: check yum-cron service is enabled and running
2. `_install_unattended_upgrades()` — Ubuntu/Debian: install unattended-upgrades, configure 20auto-upgrades and 50unattended-upgrades
3. `_install_yum_cron()` — CentOS/RHEL: install yum-cron, enable service, configure for security-only updates
4. `_configure_unattended_upgrades()` — write 50unattended-upgrades with:
   - Only security updates from ${distro_id}-security
   - Automatic removal of unused deps
   - Email notifications (optional)
   - Automatic reboot: never (conservative default)
5. `_configure_yum_cron()` — write yum-cron.conf with:
   - update_cmd = security
   - apply_updates = yes
   - emit_via = stdio

#### Public Functions

1. `install_autoupdate()` — install the appropriate package for the detected OS
2. `configure_autoupdate()` — interactive configuration:
   - Show current status
   - Ask for preferences (security-only vs all, auto-reboot policy)
   - Apply configuration
3. `check_autoupdate_status()` — key=value output for status detection:
   - `autoupdate_installed=yes/no`
   - `autoupdate_enabled=yes/no`
   - `autoupdate_type=unattended-upgrades/yum-cron/none`
4. `run_autoupdate_wizard()` — full interactive flow:
   - Step 1: Check current status
   - Step 2: Install if needed
   - Step 3: Configure interactively
   - Step 4: Enable the service
   - Step 5: Verify configuration
5. `show_autoupdate_info()` — display current config and status

#### Risk: Idempotency

- `_is_autoupdate_configured()` must be thorough — detecting partial config and repairing it
- 50unattended-upgrades has distro-specific origins config (e.g., `Ubuntu` vs `Debian` in the origin patterns). Use `DETECTED_OS` to template correct values.

### i18n Keys (zh.sh / en.sh)

Prefix: `MSG_AUTOUPDATE_*`

| Key | Purpose |
|---|---|
| `MSG_AUTOUPDATE_TITLE` | Module title |
| `MSG_AUTOUPDATE_START` | Starting auto update config |
| `MSG_AUTOUPDATE_INSTALL` | Installing auto update package |
| `MSG_AUTOUPDATE_ALREADY` | Already installed |
| `MSG_AUTOUPDATE_INSTALL_DONE` | Installation complete |
| `MSG_AUTOUPDATE_INSTALL_FAILED` | Installation failed |
| `MSG_AUTOUPDATE_CONFIGURE` | Configuring auto updates |
| `MSG_AUTOUPDATE_CONFIGURE_DONE` | Configuration complete |
| `MSG_AUTOUPDATE_ENABLE` | Enabling auto update service |
| `MSG_AUTOUPDATE_ENABLE_DONE` | Service enabled |
| `MSG_AUTOUPDATE_STATUS` | Current auto update status |
| `MSG_AUTOUPDATE_CONFIGURED` | Already configured |
| `MSG_AUTOUPDATE_NOT_CONFIGURED` | Not configured |
| `MSG_AUTOUPDATE_SCOPE_PROMPT` | Update scope prompt (security/all) |
| `MSG_AUTOUPDATE_SCOPE_SECURITY` | Security only |
| `MSG_AUTOUPDATE_SCOPE_ALL` | All updates |
| `MSG_AUTOUPDATE_REBOOT_PROMPT` | Auto reboot policy |
| `MSG_AUTOUPDATE_REBOOT_NEVER` | Never reboot automatically |
| `MSG_AUTOUPDATE_REBOOT_IF_NEEDED` | Reboot if needed |
| `MSG_AUTOUPDATE_DONE` | Auto update configuration complete |
| `MSG_AUTOUPDATE_TYPE` | Auto update type |
| `MSG_AUTOUPDATE_SUMMARY_ENABLED` | Auto security updates enabled |
| `MSG_AUTOUPDATE_SUMMARY_DISABLED` | Auto security updates disabled |

### Report Integration

Add section in `generate_report()` between Services and Config files:
```bash
_report_task_line "${_WIZARD_AUTOUPDATE_DONE:-0}" "${MSG_TASK_AUTOUPDATE}"
if [[ "${_WIZARD_AUTOUPDATE_DONE:-0}" == "1" ]]; then
    local au_status
    au_status=$(check_autoupdate_status 2>/dev/null | grep '^autoupdate_type=' | cut -d= -f2)
    echo "    - ${MSG_AUTOUPDATE_TYPE}: ${au_status:-unknown}"
fi
```

---

## Work Stream 2: backup.sh / rollback.sh Extraction

### Current State

`utils.sh` contains these functions that must be extracted:

| Current Function | Line | Target File |
|---|---|---|
| `backup_file()` | 262-287 | `scripts/base/backup.sh` |
| `restore_file()` | 290-310 | `scripts/base/backup.sh` |
| `schedule_rollback()` | 547-564 | `scripts/base/rollback.sh` |
| `cancel_scheduled_task()` | 567-584 | `scripts/base/rollback.sh` |

Additionally, `ssh.sh` has SSH-specific rollback functions that remain in `ssh.sh`:
- `rollback_ssh()` — stays in `ssh.sh` (SSH-specific)
- `setup_rollback_timer()` — stays in `ssh.sh` (SSH-specific)
- `cancel_rollback_timer()` — stays in `ssh.sh` (SSH-specific)

### Backward Compatibility Strategy

**Critical rule**: No existing caller code must change. The extraction must be transparent.

Strategy: In `utils.sh`, after loading the new modules, define **shim functions** that delegate to the new location. Or more simply: keep the function definitions in utils.sh as thin wrappers.

Option A (preferred — cleaner): **Source the new modules from utils.sh** and keep only load guards.

```
utils.sh before:
  - defines backup_file(), restore_file(), schedule_rollback(), cancel_scheduled_task()
  - sets _UTILS_LOADED=1

utils.sh after:
  - sources backup.sh (which sets _BACKUP_LOADED and defines backup_file, restore_file)
  - sources rollback.sh (which sets _ROLLBACK_LOADED and defines schedule_rollback, cancel_scheduled_task)
  - checks that all functions exist (defensive)
  - sets _UTILS_LOADED=1
```

This way:
- All existing `source "${SCRIPT_DIR}/scripts/base/utils.sh"` still works
- All callers of `backup_file`, `restore_file`, `schedule_rollback`, `cancel_scheduled_task` still work
- New code can `source "${SCRIPT_DIR}/scripts/base/backup.sh"` independently if desired
- No changes needed to init.sh, ssh.sh, audit.sh, install.sh, etc.

### Files to Create / Modify

| File | Action | Why |
|---|---|---|
| `scripts/base/backup.sh` | CREATE | Extracted backup_file() + restore_file() |
| `scripts/base/rollback.sh` | CREATE | Extracted schedule_rollback() + cancel_scheduled_task() |
| `scripts/base/utils.sh` | UPDATE | Source backup.sh + rollback.sh, remove old definitions |
| `scripts/lang/zh.sh` | UPDATE | Add ~5 MSG_BACKUP_* / MSG_ROLLBACK_* keys (new ones beyond what utils.sh already has) |
| `scripts/lang/en.sh` | UPDATE | Same as zh.sh |
| `tests/unit/backup.bats` | CREATE | Unit tests for backup.sh (~15-20 cases) |
| `tests/unit/rollback.bats` | CREATE | Unit tests for rollback.sh (~10-15 cases) |
| `tests/unit/utils.bats` | UPDATE | Remove tests for backup/rollback functions (moved to dedicated files), keep import test |
| `HANDOVER.md` | UPDATE | Mark extraction as done |

### Module Design: backup.sh

#### Constants (none new — uses BACKUP_DIR from utils.sh)

#### Functions

Mirror existing `backup_file()` and `restore_file()` exactly.

```bash
# Source guard
if [[ "${_BACKUP_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null
fi
readonly _BACKUP_LOADED=1

# Requires utils.sh for log_*, BACKUP_DIR, TIMESTAMP
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before backup.sh"
    exit 1
fi

# backup_file — exact copy of current utils.sh:262-287
backup_file() { ... }
# restore_file — exact copy of current utils.sh:290-310
restore_file() { ... }
```

### Module Design: rollback.sh

#### Functions

Mirror existing `schedule_rollback()` and `cancel_scheduled_task()` exactly.

```bash
if [[ "${_ROLLBACK_LOADED:-}" == "1" ]]; then
    return 0 2>/dev/null
fi
readonly _ROLLBACK_LOADED=1

if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before rollback.sh"
    exit 1
fi

# schedule_rollback — exact copy of current utils.sh:547-564
schedule_rollback() { ... }
# cancel_scheduled_task — exact copy of current utils.sh:567-584
cancel_scheduled_task() { ... }
```

### utils.sh Modification

```bash
# After the tool/utility functions section (before the module load check at bottom)
# Source backup and rollback modules
source "${SCRIPT_DIR}/scripts/base/backup.sh"
source "${SCRIPT_DIR}/scripts/base/rollback.sh"

# Verify all expected functions are available
for _fn in backup_file restore_file schedule_rollback cancel_scheduled_task; do
    if ! declare -F "${_fn}" &>/dev/null; then
        echo "Error: Required function ${_fn} not found after loading backup/rollback modules" >&2
        exit 1
    fi
done
unset _fn
```

Remove the old function definitions in the `#═备份函数═` and `#═延时执行═` sections.

### Risk Analysis

| Risk | Likelihood | Mitigation |
|---|---|---|
| Circular dependency | Low | backup.sh and rollback.sh only depend on utils.sh for log_* + constants; utils.sh sources them after those are defined |
| Function name collision | Low | Use declare -F check after source |
| SCRIPT_DIR not set when utils.sh is first sourced | Medium | The existing pattern requires SCRIPT_DIR to be set before any source. All bootstrap paths set it. Verify in tests. |
| Existing tests break | Medium | Move backup/restore tests to backup.bats; keep a minimal import test in utils.bats |

### Test Plan (backup.bats)

- `backup_file creates backup in BACKUP_DIR`
- `backup_file returns error for missing file`
- `backup_file returns backup path on success`
- `restore_file restores from backup`
- `restore_file returns error for missing backup`
- `backup_file creates backup with unique timestamp suffix`
- `restore_file preserves file permissions`
- `_BACKUP_LOADED is set`
- `backup.sh has source guard`
- Functions: `backup_file`, `restore_file` exist

### Test Plan (rollback.bats)

- `schedule_rollback sets _SCHEDULED_PID`
- `cancel_scheduled_task kills running sleep`
- `cancel_scheduled_task returns 1 for non-existent PID`
- `cancel_scheduled_task verifies PID is a sleep task before killing`
- `_ROLLBACK_LOADED is set`
- `rollback.sh has source guard`

---

## Work Stream 3: SSH Lockout Protection Enhancement (PRD §6.3)

**⚠️ Full-only**: `ssh.sh` 是 Lite 核心模块（`MODE_LITE_MODULES` 之一）。本工作流增强 `setup_rollback_timer` 和 `run_ssh_wizard` 必须通过 `is_mode_full` 条件激活。Lite 模式保持原有 SSH 配置流程：`run_ssh_wizard` 不调用新增的安全检查/连接监控，`setup_rollback_timer` 保持现有简化行为。

### Current State vs. Target

| Aspect | Current | Target |
|---|---|---|
| Config test | `validate_ssh_config()` — runs `sshd -t` before restart | Add `ssh -p <new_port> localhost -o ConnectTimeout=5` connection test after restart |
| Rollback trigger | `setup_rollback_timer()` — 10-min delay via `at` or background `sleep` | Same mechanism, but add: connection test before enabling rollback |
| Rollback cancellation | `cancel_rollback_timer()` — manual | Add: watch for successful SSH connection on new port within window |
| User experience | Warning to test connection manually | Built-in test + guided confirmation |

### What changes in ssh.sh

#### Enhance `restart_ssh()` → rename to `_restart_and_test_ssh()`

After restart, attempt a local SSH connection on the new port to verify the config actually works:

```bash
_restart_and_test_ssh() {
    restart_ssh  # existing logic

    # Wait for service to be ready
    local port
    port=$(get_ssh_port)
    local max_wait=15
    local waited=0
    while [[ ${waited} -lt ${max_wait} ]]; do
        if ss -tlnp 2>/dev/null | grep -qE ":${port}[[:space:]]"; then
            break
        fi
        sleep 1
        ((waited++))
    done

    # Test connection to localhost
    if ssh -p "${port}" -o ConnectTimeout=5 -o StrictHostKeyChecking=no \
         -o BatchMode=yes localhost true 2>/dev/null; then
        log_success "SSH connection test passed on port ${port}"
        return 0
    else
        log_warn "SSH connection test failed on port ${port}"
        log_warn "Rollback timer will be set — connect within $((${ROLLBACK_DELAY}/60)) minutes to confirm"
        return 1
    fi
}
```

#### Enhance `setup_rollback_timer()` — Add Connection Watch

Add a connection watch script that monitors SSH connections on the new port and auto-cancels the rollback:

```bash
setup_rollback_timer() {
    # ... existing at/sleep setup ...

    # Also start a connection watch process that monitors auth.log
    # and auto-cancels rollback on successful login
    _start_connection_watch "${new_port}" "${ROLLBACK_DELAY}"
}

_start_connection_watch() {
    local port="$1"
    local delay="$2"
    local log_file=""

    # Determine auth log path based on OS
    case "${DETECTED_OS}" in
        ubuntu|debian) log_file="/var/log/auth.log" ;;
        centos|rhel|rocky|almalinux|fedora) log_file="/var/log/secure" ;;
    esac

    (
        trap '' INT TERM
        local elapsed=0
        local initial_count
        initial_count=$(grep -c "Accepted.*port ${port}" "${log_file}" 2>/dev/null || echo 0)
        while [[ ${elapsed} -lt ${delay} ]]; do
            sleep 30
            elapsed=$((elapsed + 30))
            local current_count
            current_count=$(grep -c "Accepted.*port ${port}" "${log_file}" 2>/dev/null || echo 0)
            if [[ ${current_count} -gt ${initial_count} ]]; then
                # New connection detected! Cancel rollback
                cancel_rollback_timer
                log_success "New SSH connection detected on port ${port}, rollback cancelled"
                exit 0
            fi
        done
        # Rollback will fire when the at/sleep timer expires
        log_debug "Connection watch expired without detecting new connections"
    ) &

    _WATCH_PID=$!
    disown "${_WATCH_PID}" 2>/dev/null || true
}
```

#### Modify `run_ssh_wizard()` to use new flow

Replace direct `restart_ssh` call with `_restart_and_test_ssh()`:

**⚠️ 注意：** 以下新流程仅在 Full 模式激活。Lite 模式下 `run_ssh_wizard()` 保持原有直接调用 `restart_ssh` 的简化流程。

```bash
# Old flow (Lite & old Full):
# if restart_ssh; then ... else setup_rollback_timer; fi

# New flow (Full only):
if is_mode_full; then
    # SSH 锁定防护增强（Full 独占）
    check_active_ssh_sessions
    has_console_access
    if _restart_and_test_ssh; then
        log_success "SSH configuration verified and active"
        setup_rollback_timer  # 始终设置，PRD §6.3
        # 等待用户确认
    else
        setup_rollback_timer
        log_info "Rollback timer active for $((${ROLLBACK_DELAY}/60)) minutes"
    fi
else
    # Lite 模式：保持现状
    restart_ssh
fi
```

### Files to Modify

| File | Action | Why |
|---|---|---|
| `scripts/security/ssh.sh` | UPDATE | Add `_restart_and_test_ssh()`, `_start_connection_watch()`, update `run_ssh_wizard()` flow |
| `scripts/lang/zh.sh` | UPDATE | Add ~8 MSG_SSH_TEST_* keys |
| `scripts/lang/en.sh` | UPDATE | Add ~8 MSG_SSH_TEST_* keys |
| `tests/unit/ssh.bats` | UPDATE | Add 5-8 new test cases |
| `HANDOVER.md` | UPDATE | Mark SSH lockout protection as done |

### i18n Keys (zh.sh / en.sh) for SSH Enhancement

Prefix: `MSG_SSH_TEST_*`

| Key | Purpose |
|---|---|
| `MSG_SSH_TEST_CONNECTION` | Testing SSH connection on new port... |
| `MSG_SSH_TEST_PASS` | SSH connection test passed on port {port} |
| `MSG_SSH_TEST_FAIL` | SSH connection test failed — setting rollback timer |
| `MSG_SSH_TEST_WAITING` | Waiting for SSH service to be ready... |
| `MSG_SSH_TEST_WATCH_START` | Started connection watch for port {port} |
| `MSG_SSH_TEST_WATCH_CANCEL` | New SSH connection detected, rollback cancelled |
| `MSG_SSH_TEST_CONFIRM` | Please confirm you can SSH in on the new port |
| `MSG_SSH_TEST_INSTRUCTIONS` | In another terminal, run: ssh -p {port} user@host |

### Risk Analysis

| Risk | Likelihood | Mitigation |
|---|---|---|
| `ssh localhost` requires SSH keys or password | Medium | Use BatchMode=yes + PubkeyAuthentication (keys configured earlier in wizard). If keys not set up, test will fail gracefully and set rollback timer. |
| Auth log rotation during watch window | Low | Connection watch reads current count vs. prior count; rotation resets initial_count, which is conservative (might not detect, but that's safe — just leads to rollback that shouldn't fire) |
| Watch process leaks | Low | Watch process exits after delay seconds; also cancel_rollback_timer clears both the timer and the watch |
| Port variable not available in setup_rollback_timer | Medium | Ensure port is passed as parameter or read at runtime inside the function |

---

## Implementation Order

```
Step 1: backup.sh / rollback.sh extraction
  (Foundation — other changes may depend on clean separation)
  └─ 1a. Create backup.sh with existing backup_file(), restore_file()
  └─ 1b. Create rollback.sh with existing schedule_rollback(), cancel_scheduled_task()
  └─ 1c. Update utils.sh — source new modules, remove old definitions, add verify
  └─ 1d. Create backup.bats + rollback.bats tests
  └─ 1e. Update utils.bats (remove moved tests)
  └─ 1f. Run full test suite to confirm no regressions

Step 2: SSH Lockout Protection Enhancement
  (Depends on schedule_rollback being available — already is, but cleaner after extraction)
  └─ 2a. Add _restart_and_test_ssh() to ssh.sh
  └─ 2b. Add _start_connection_watch() to ssh.sh
  └─ 2c. Update run_ssh_wizard() flow
  └─ 2d. Add MSG_SSH_TEST_* i18n keys
  └─ 2e. Update ssh.bats tests
  └─ 2f. Test: verify rollback fires/cancels correctly

Step 3: Auto Security Updates
  (New module, no dependencies)
  └─ 3a. Create autoupdate.sh
  └─ 3b. Add MSG_AUTOUPDATE_* i18n keys
  └─ 3c. Register in mode.sh
  └─ 3d. Integrate into install.sh (menu + wizard + status)
  └─ 3e. Update report.sh
  └─ 3f. Create autoupdate.bats tests
  └─ 3g. Run full test suite

Step 4: Final verification
  └─ 4a. shellcheck -x on all modified/created files
  └─ 4b. bats tests/unit/*.bats (no regressions)
  └─ 4c. Update HANDOVER.md with changelog
```

---

## Files Summary

### Created (5 files)

| File | Est. Lines |
|---|---|
| `scripts/base/backup.sh` | ~60 |
| `scripts/base/rollback.sh` | ~60 |
| `scripts/security/autoupdate.sh` | ~250 |
| `tests/unit/backup.bats` | ~80 |
| `tests/unit/rollback.bats` | ~60 |
| `tests/unit/autoupdate.bats` | ~120 |

### Modified (9 files)

| File | Est. Delta |
|---|---|
| `scripts/base/utils.sh` | ~30 (source, remove old defs, verify) |
| `scripts/security/ssh.sh` | ~80 (new functions, updated wizard flow) |
| `scripts/base/mode.sh` | ~10 (register autoupdate) |
| `install.sh` | ~40 (menu + wizard + status) |
| `scripts/base/report.sh` | ~15 (autoupdate section) |
| `scripts/lang/zh.sh` | ~40 (autoupdate + backup + ssh test keys) |
| `scripts/lang/en.sh` | ~40 (autoupdate + backup + ssh test keys) |
| `tests/unit/utils.bats` | ~10 (remove moved tests, add import test) |
| `tests/unit/ssh.bats` | ~30 (new SSH test cases) |
| `HANDOVER.md` | ~10 (changelog, progress) |

### Total: ~5 created + ~10 modified = ~700-800 net new lines

---

## Validation

```bash
# ShellCheck
shellcheck -x scripts/base/backup.sh
shellcheck -x scripts/base/rollback.sh
shellcheck -x scripts/security/autoupdate.sh
shellcheck -x scripts/base/utils.sh
shellcheck -x scripts/security/ssh.sh
shellcheck -x install.sh
shellcheck -x scripts/base/report.sh

# Bats tests
bats tests/unit/backup.bats
bats tests/unit/rollback.bats
bats tests/unit/autoupdate.bats
bats tests/unit/ssh.bats
bats tests/unit/utils.bats
bats tests/unit/*.bats  # no regressions
```

---

## Risks Summary

| Risk | Stream | Likelihood | Mitigation |
|---|---|---|---|
| backup/rollback extraction breaks existing callers | WS2 | Medium | Shim strategy (utils.sh sources new modules). Full test suite run before/after. |
| SSH connection test (`ssh localhost`) requires prior key setup | WS3 | Medium | Test failure is graceful — sets rollback timer. Wizard flow ensures keys before password disable. |
| Auth log rotation causes false connection watch miss | WS3 | Low | Conservative: initial_count resets on rotation, might not detect new connections but won't false-cancel rollback. |
| unattended-upgrades config differs across Ubuntu/Debian versions | WS1 | Low | Use DETECTED_OS + DETECTED_OS_VERSION for conditional config. |
| yum-cron not in default CentOS 7 repos | WS1 | Low | Check EPEL availability; fall back to warning if package not found. |
| schedule_rollback `callback` parameter changed during extraction | WS2 | Low | Keep exact same signature. `schedule_rollback delay callback description`. |

---

## Acceptance Criteria

- [x] `scripts/base/backup.sh` exists with `backup_file()`, `restore_file()`, source guard, `_BACKUP_LOADED`
- [x] `scripts/base/rollback.sh` exists with `schedule_rollback()`, `cancel_scheduled_task()`, source guard, `_ROLLBACK_LOADED`
- [x] `utils.sh` sources both new modules and verifies all functions exist
- [x] All existing callers work without modification (verified by test suite)
- [x] SSH lockout: `_restart_and_test_ssh()` tests connection and triggers rollback on failure
- [x] SSH lockout: `_start_connection_watch()` monitors auth log and cancels rollback on new connection
- [x] `autoupdate.sh`: unattended-upgrades configures for Ubuntu/Debian (security-only)
- [x] `autoupdate.sh`: yum-cron configures for CentOS/RHEL (security-only)
- [x] i18n keys complete for zh and en (autoupdate + backup + ssh test)
- [x] All new modules registered in mode.sh (autoupdate = full mode)
- [x] Menu integration: autoupdate accessible from install.sh
- [x] Report: autoupdate section in generate_report()
- [x] backup.bats: 15+ test cases
- [x] rollback.bats: 10+ test cases
- [x] autoupdate.bats: 20+ test cases
- [x] ssh.bats: 5+ new test cases, all existing pass
- [x] ShellCheck passes on all files
- [x] `bats tests/unit/*.bats` — all pass, no regressions

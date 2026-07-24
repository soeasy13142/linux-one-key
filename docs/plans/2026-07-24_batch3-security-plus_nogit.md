---
title: "Batch 3: Security Plus Modules (AIDE / ClamAV / Rootkit Detection)"
created: 2026-07-24
updated: 2026-07-24
status: pending
source: "PRD §2.13 + HANDOVER.md Batch 3"
topic: "feature"
---

# Plan: Batch 3 — Security Plus Modules

**Source**: PRD §2.13 (AIDE, ClamAV, Rootkit Detection)
**Complexity**: Medium (3 similar but independent modules)
**Mode**: **Full-only** — 本批 3 个模块全部是 Full 独占，Lite 模式完全不加载这些模块。Lite 模式代码（`install.sh` 菜单、`mode.sh` Lite 列表、`report.sh` Lite 过滤）不做任何改动。

## Summary

Create three new optional security enhancement modules in `scripts/security/`:

| Module | File | Tool(s) | PRD Section |
|--------|------|---------|-------------|
| AIDE Intrusion Detection | `scripts/security/aide.sh` | aide | §2.13.1 |
| ClamAV Virus Scanner | `scripts/security/clamav.sh` | clamav (clamd/freshclam) | §2.13.2 |
| Rootkit Detection | `scripts/security/rootkit.sh` | rkhunter + chkrootkit | §2.13.3 |

All three are **optional** (user confirms before install), **Full-mode exclusive**, and require **cross-distro support** (apt/yum/dnf). Each follows the established module pattern: guard -> constants -> internal functions -> public functions -> wizard -> status check -> load guard.

## Patterns to Mirror

| Category | Source | Pattern |
|---|---|---|
| Module structure | `audit.sh:1-14` | Shebang, `set -eo`, utils guard check, constants, internal funcs, public funcs, wizard, status check, load guard |
| Install function | `audit.sh:33-63` | `_install_*()` with `DETECTED_OS` case, `command_exists` guard, `log_step`/`log_success` |
| Config generation | `audit.sh:76-221` | Atomic write (mktemp + mv), heredoc template, backup before modify |
| Cron setup | (fail2ban has cron-like timer; AIDE needs new cron pattern) | `_setup_aide_cron()` writing to `/etc/cron.d/` |
| Wizard | `audit.sh:412-505` | `run_*_wizard()` — root check, install confirmation, step-by-step, summary, tips |
| Status check | `kernel.sh:318-339` | `check_*_status()` returning `key=value` pairs for `show_system_status()` |
| Submenu | `install.sh:981-1003` | `show_*_submenu()` + `run_*_submenu_loop()` — [1] wizard, [2] status, [0] back |
| Menu integration | `install.sh:678-685` (services pattern) | New menu items in `show_main_menu`, case dispatch with Lite guard, `run_*_submenu_loop` |
| Full wizard | `install.sh:1318-1335` (services pattern) | `_WIZARD_*_DONE` flag, `is_mode_full` guard, confirm skip, run wizard, set flag |
| Report | `report.sh:157-169` (services pattern) | `_report_task_line` + `check_*_status()` detail lines |
| i18n | `zh.sh` MSG_SERVICES_* | MSG_AIDE_*, MSG_CLAMAV_*, MSG_ROOTKIT_* prefix, ~30-40 keys per module |
| Tests | `services.bats:1-80` | `setup()` with TEST_DIR, source utils+lang+module, constants tests, function existence, output tests |

## Files to Change / Create

### Create (3 new module files)

| File | Est. Lines | Description |
|------|-----------|-------------|
| `scripts/security/aide.sh` | ~250-300 | AIDE install, database init, cron setup |
| `scripts/security/clamav.sh` | ~300-350 | ClamAV install, freshclam cron, optional scan cron |
| `scripts/security/rootkit.sh` | ~250-300 | rkhunter install+config, chkrootkit install, run scan |

### Update (existing files)

| File | Action | Why |
|------|--------|-----|
| `scripts/lang/zh.sh` | UPDATE | Add ~30-40 Chinese i18n keys per module |
| `scripts/lang/en.sh` | UPDATE | Add ~30-40 English i18n keys per module |
| `scripts/base/mode.sh` | UPDATE | Register `aide`, `clamav`, `rootkit` in `MODE_FULL_MODULES` and `MODE_ALL_MODULES` |
| `install.sh` | UPDATE | Load 3 new modules, add 3 menu items (13/14/15), full wizard steps 9/10/11, status detection sections |
| `scripts/base/report.sh` | UPDATE | Add 3 report sections + warnings |
| `tests/unit/aide.bats` | CREATE | ~20-25 test cases |
| `tests/unit/clamav.bats` | CREATE | ~20-25 test cases |
| `tests/unit/rootkit.bats` | CREATE | ~20-25 test cases |
| `HANDOVER.md` | UPDATE | Mark Batch 3 as done |

## Module Designs

### 1. AIDE Module (`scripts/security/aide.sh`)

**Constants:**

```
AIDE_CONF="/etc/aide/aide.conf"
AIDE_DB_DIR="/var/lib/aide"
AIDE_DB="${AIDE_DB_DIR}/aide.db.gz"
AIDE_DB_NEW="${AIDE_DB_DIR}/aide.db.new.gz"
AIDE_CRON_FILE="/etc/cron.d/aide-check"
AIDE_REPORT_DIR="/var/log/aide"
```

**Key behaviors:**

| Behavior | Detail |
|----------|--------|
| Install | `apt install aide` / `yum install aide` / `dnf install aide` (plus epel for RHEL-family) |
| Database init | `aideinit --init` or `aide --init` (cross-distro), moves db.new.gz -> db.gz |
| Cron | Daily check via `/etc/cron.d/aide-check` at 02:00, results to `/var/log/aide/` |
| Idempotency | Skip install if already installed; skip db init if db exists; warn to reinit |
| Backup | Backup existing `aide.conf` before overwriting |

**Internal functions:**

1. `_install_aide()` — cross-distro package install, with EPEL for RHEL-family
2. `_backup_aide_config()` — backup existing aide.conf
3. `_configure_aide()` — generate minimal aide.conf (focus: critical system files)
4. `_init_aide_database()` — run `aideinit --init` or `aide --init` (detect binary name)
5. `_setup_aide_cron()` — write daily cron job for `aide --check`
6. `_show_aide_status()` — display DB age, last check time, cron status
7. `_show_aide_tips()` — management commands

**Public functions:**

1. `run_aide_wizard()` — full interactive wizard: install -> configure -> init db -> setup cron -> status
2. `check_aide_status()` — key=value output for show_system_status() (db_exists, cron_enabled)

**Cron entry:**
```bash
# /etc/cron.d/aide-check
0 2 * * * root /usr/sbin/aide --check > /var/log/aide/check-$(date +\%Y\%m\%d).log 2>&1
```

**AIDE config (minimal):** Monitor `/etc/passwd`, `/etc/shadow`, `/etc/group`, `/etc/sudoers`, `/etc/ssh/sshd_config`, `/etc/hosts`, `/etc/crontab`, key system binaries (`/sbin/`, `/bin/`, `/usr/sbin/`, `/usr/bin/`), and `/root/`.

**Risks:**

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `aideinit` binary name differs across distros | Medium | Detect: `aideinit` (Debian/Ubuntu) vs `aide --init` (RHEL) |
| Database init takes 5-30 min on large servers | Medium | Warn user upfront; optional skip |
| Large DB file (>100MB on big servers) | Low | Keep default `gzip_db=yes` in config |
| Cron daemon not running | Low | Check `systemctl is-active cron` before writing cron file |

### 2. ClamAV Module (`scripts/security/clamav.sh`)

**Constants:**

```
CLAMAV_CONF_DIR="/etc/clamav"
CLAMAVD_CONF="${CLAMAV_CONF_DIR}/clamd.conf"
FRESHCLAM_CONF="${CLAMAV_CONF_DIR}/freshclam.conf"
CLAMAV_LOG_DIR="/var/log/clamav"
CLAMAV_QUARANTINE_DIR="/var/quarantine"
CLAMAV_CRON_UPDATE="/etc/cron.d/clamav-freshclam"
CLAMAV_CRON_SCAN="/etc/cron.d/clamav-scan"
```

**Key behaviors:**

| Behavior | Detail |
|----------|--------|
| Install | `apt install clamav clamav-daemon` / `yum install epel-release clamav clamav-update` / `dnf install epel-release clamav clamav-update` |
| Memory warning | ClamAV daemon uses ~200-300MB RSS — warn user before install |
| freshclam cron | Hourly virus database update via cron |
| Optional scan | User can opt into daily scan of `/home`, `/tmp`, `/var` (excluding `/proc`, `/sys`) |
| clamd | **Not enabled by default** — too heavy for server; freshclam + on-demand scan only |
| Idempotency | Skip install if already installed; skip freshclam cron if exists |

**Internal functions:**

1. `_install_clamav()` — cross-distro install, with EPEL for RHEL-family
2. `_configure_freshclam()` — generate minimal freshclam.conf
3. `_setup_freshclam_cron()` — hourly cron for `freshclam --quiet`
4. `_run_freshclam_now()` — initial virus DB update
5. `_setup_scan_cron()` — optional daily scan cron
6. `_run_clamav_scan()` — run on-demand scan of key dirs
7. `_show_clamav_status()` — DB age, cron status, last scan
8. `_show_clamav_tips()` — management commands

**Public functions:**

1. `run_clamav_wizard()` — full wizard: warn memory -> install -> configure -> freshclam cron -> initial update -> optional scan cron -> summary
2. `check_clamav_status()` — key=value output (db_uptodate, cron_enabled)

**Decision: clamd vs no clamd:**
- **Do NOT enable clamd** (the persistent daemon) by default. ClamAV in on-demand mode consumes negligible memory (only during scans).
- Document that clamd can be enabled manually if the user has enough RAM.
- The wizard runs `clamscan` on-demand for one-time scan, then optionally sets up cron for periodic scans.

**Risks:**

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Memory: freshclam uses ~100-200MB during update | Medium | Warn user; freshclam auto-exits after update |
| freshclam rate limit | Low | freshclam has built-in retry with backoff |
| EPEL required for RHEL-family | Medium | Install epel-release first (same pattern as fail2ban) |
| ClamAV on CentOS 7 uses old version | Medium | Still functional for known signatures |
| Large scan slows server | Medium | `nice -n 19 ionice -c3` for scan processes; set scan hours in off-peak |

### 3. Rootkit Detection Module (`scripts/security/rootkit.sh`)

**Constants:**

```
RKHUNTER_CONF="/etc/rkhunter.conf"
RKHUNTER_LOG_DIR="/var/log/rkhunter"
RKHUNTER_CRON="/etc/cron.d/rkhunter"
CHKROOTKIT_LOG_DIR="/var/log/chkrootkit"
RKHUNTER_PROP_FILE="/var/lib/rkhunter/db/rkhunter.dat"
```

**Key behaviors:**

| Behavior | Detail |
|----------|--------|
| Install rkhunter | `apt install rkhunter` / `yum install epel-release rkhunter` / `dnf install epel-release rkhunter` |
| Install chkrootkit | `apt install chkrootkit` / RPM: may not be in all repos — try regardless, warn if not found |
| rkhunter configure | Update file properties: `rkhunter --propupd` |
| Weekly rkhunter cron | Weekly scan via cron (Sundays 03:00) |
| Run both tools | Wizard offers to run both immediately + setup cron |
| Idempotency | Skip install if already installed |

**Internal functions:**

1. `_install_rkhunter()` — install rkhunter (cross-distro)
2. `_install_chkrootkit()` — install chkrootkit (cross-distro, may fail gracefully)
3. `_configure_rkhunter()` — set `MAILTO=root`, `REPORT_METHOD=stdout`, `SCRIPTWHITELIST_DIR=...`
4. `_update_rkhunter_props()` — run `rkhunter --propupd` (file property update)
5. `_setup_rkhunter_cron()` — weekly cron for `rkhunter --check --skip-keypress`
6. `_run_rkhunter_scan()` — run immediate rootkit scan
7. `_run_chkrootkit_scan()` — run immediate chkrootkit scan
8. `_show_rootkit_status()` — last scan time, cron status
9. `_show_rootkit_tips()` — management commands

**Public functions:**

1. `run_rootkit_wizard()` — full wizard: install rkhunter -> install chkrootkit -> propupd -> run scan -> setup cron -> summary
2. `check_rootkit_status()` — key=value output (rkhunter_installed, chkrootkit_installed, cron_enabled)

**Cross-distro notes:**

| Distro | rkhunter | chkrootkit |
|--------|----------|------------|
| Ubuntu/Debian | `apt install rkhunter` | `apt install chkrootkit` |
| CentOS/RHEL/Rocky/Alma | `yum install epel-release rkhunter` | Not in EPEL — warn and skip |
| Fedora | `dnnf install rkhunter` | Not in repos — warn and skip |

**Risks:**

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| rkhunter scan takes 10-30 min | Medium | Warn user; run in background with notification |
| False positives from rkhunter | High | Note in tips: use `rkhunter --check --skip-keypress` and review warnings manually |
| chkrootkit not available on RHEL-family | Medium | Skip gracefully with a warning |
| rkhunter --propupd needed after updates | Medium | Document in tips: run `rkhunter --propupd` after package updates |

## i18n Keys

### MSG_AIDE_* (~30 keys)

| Key | Purpose |
|-----|---------|
| `MSG_AIDE_WIZARD_TITLE` | Wizard title |
| `MSG_AIDE_WIZARD_DESC` | Wizard description |
| `MSG_AIDE_WIZARD_START` | Confirm start wizard |
| `MSG_AIDE_WIZARD_SKIPPED` | Skipped |
| `MSG_AIDE_WIZARD_DONE` | Complete |
| `MSG_AIDE_INSTALL` | Installing AIDE... |
| `MSG_AIDE_INSTALL_DONE` | AIDE installed |
| `MSG_AIDE_ALREADY_INSTALLED` | Already installed |
| `MSG_AIDE_UNSUPPORTED_OS` | Unsupported OS |
| `MSG_AIDE_BACKUP` | Backup config |
| `MSG_AIDE_CONFIGURE` | Configuring AIDE... |
| `MSG_AIDE_CONFIGURE_DONE` | AIDE configured |
| `MSG_AIDE_INIT_DB` | Initializing AIDE database... |
| `MSG_AIDE_INIT_DB_DONE` | AIDE database initialized |
| `MSG_AIDE_INIT_DB_WARN` | AIDE init warning (time) |
| `MSG_AIDE_INIT_DB_SKIP` | Skip DB init |
| `MSG_AIDE_INIT_DB_EXISTS` | DB already exists |
| `MSG_AIDE_INIT_DB_REINIT` | Confirm reinit |
| `MSG_AIDE_DB_STATUS` | Database status |
| `MSG_AIDE_DB_AGE` | DB age |
| `MSG_AIDE_CRON_SETUP` | Setting up cron... |
| `MSG_AIDE_CRON_DONE` | Cron setup done |
| `MSG_AIDE_CRON_EXISTS` | Cron already exists |
| `MSG_AIDE_CRON_SKIP` | Skip cron setup |
| `MSG_AIDE_STATUS` | AIDE status |
| `MSG_AIDE_NOT_INSTALLED` | Not installed |
| `MSG_AIDE_SUMMARY` | AIDE summary |
| `MSG_AIDE_TIPS_TITLE` | Tips title |
| `MSG_AIDE_TIPS_1..4` | 4 management tips |
| `MSG_AIDE_MENU_TITLE` | Submenu title |
| `MSG_AIDE_MENU_WIZARD` | [1] Full wizard |
| `MSG_AIDE_MENU_STATUS` | [2] Status |
| `MSG_AIDE_MENU_BACK` | [0] Back |
| `MSG_HINT_STATUS_AIDE` | Hint for status |
| `MSG_STATUS_AIDE` | Status label |
| `MSG_REPORT_WARN_AIDE` | Report warning |
| `MSG_TASK_AIDE` | Task name |

### MSG_CLAMAV_* (~35 keys)

| Key | Purpose |
|-----|---------|
| `MSG_CLAMAV_WIZARD_TITLE` | Wizard title |
| `MSG_CLAMAV_WIZARD_DESC` | Description |
| `MSG_CLAMAV_WIZARD_START` | Confirm |
| `MSG_CLAMAV_WIZARD_SKIPPED` | Skipped |
| `MSG_CLAMAV_WIZARD_DONE` | Complete |
| `MSG_CLAMAV_INSTALL` | Installing ClamAV... |
| `MSG_CLAMAV_INSTALL_DONE` | Installed |
| `MSG_CLAMAV_ALREADY_INSTALLED` | Already installed |
| `MSG_CLAMAV_UNSUPPORTED_OS` | Unsupported |
| `MSG_CLAMAV_MEMORY_WARN` | Memory warning (~300MB) |
| `MSG_CLAMAV_MEMORY_CONFIRM` | Confirm despite memory warning |
| `MSG_CLAMAV_CONFIGURE` | Configuring... |
| `MSG_CLAMAV_CONFIGURE_DONE` | Configured |
| `MSG_CLAMAV_FRESHCLAM_CRON` | Setting up freshclam cron... |
| `MSG_CLAMAV_FRESHCLAM_CRON_DONE` | Freshclam cron setup done |
| `MSG_CLAMAV_FRESHCLAM_NOW` | Running initial virus DB update... |
| `MSG_CLAMAV_FRESHCLAM_NOW_DONE` | Virus DB updated |
| `MSG_CLAMAV_FRESHCLAM_NOW_WARN` | Update taking long |
| `MSG_CLAMAV_SCAN_CRON_PROMPT` | Setup daily scan cron? |
| `MSG_CLAMAV_SCAN_CRON_SETUP` | Setting up scan cron... |
| `MSG_CLAMAV_SCAN_CRON_DONE` | Scan cron setup done |
| `MSG_CLAMAV_SCAN_CRON_SKIP` | Skipped |
| `MSG_CLAMAV_RUN_SCAN` | Running on-demand scan... |
| `MSG_CLAMAV_SCAN_DONE` | Scan complete |
| `MSG_CLAMAV_SCAN_FOUND` | Threats found |
| `MSG_CLAMAV_SCAN_CLEAN` | No threats found |
| `MSG_CLAMAV_STATUS` | Status |
| `MSG_CLAMAV_DB_STATUS` | DB status |
| `MSG_CLAMAV_DB_UPTODATE` | Up to date |
| `MSG_CLAMAV_DB_OUTDATED` | Out of date |
| `MSG_CLAMAV_LAST_SCAN` | Last scan |
| `MSG_CLAMAV_NOT_INSTALLED` | Not installed |
| `MSG_CLAMAV_SUMMARY` | Summary |
| `MSG_CLAMAV_TIPS_TITLE` | Tips title |
| `MSG_CLAMAV_TIPS_1..4` | 4 tips |
| `MSG_CLAMAV_MENU_TITLE` | Submenu title |
| `MSG_CLAMAV_MENU_WIZARD` | [1] Full wizard |
| `MSG_CLAMAV_MENU_STATUS` | [2] Status |
| `MSG_CLAMAV_MENU_BACK` | [0] Back |
| `MSG_HINT_STATUS_CLAMAV` | Hint |
| `MSG_STATUS_CLAMAV` | Status label |
| `MSG_REPORT_WARN_CLAMAV` | Report warning |
| `MSG_TASK_CLAMAV` | Task name |

### MSG_ROOTKIT_* (~35 keys)

| Key | Purpose |
|-----|---------|
| `MSG_ROOTKIT_WIZARD_TITLE` | Wizard title |
| `MSG_ROOTKIT_WIZARD_DESC` | Description |
| `MSG_ROOTKIT_WIZARD_START` | Confirm |
| `MSG_ROOTKIT_WIZARD_SKIPPED` | Skipped |
| `MSG_ROOTKIT_WIZARD_DONE` | Complete |
| `MSG_ROOTKIT_INSTALL_RKHUNTER` | Installing rkhunter... |
| `MSG_ROOTKIT_INSTALL_RKHUNTER_DONE` | rkhunter installed |
| `MSG_ROOTKIT_RKHUNTER_ALREADY` | Already installed |
| `MSG_ROOTKIT_INSTALL_CHKROOTKIT` | Installing chkrootkit... |
| `MSG_ROOTKIT_INSTALL_CHKROOTKIT_DONE` | chkrootkit installed |
| `MSG_ROOTKIT_CHKROOTKIT_ALREADY` | Already installed |
| `MSG_ROOTKIT_CHKROOTKIT_UNAVAIL` | chkrootkit not available (RHEL-family) |
| `MSG_ROOTKIT_UNSUPPORTED_OS` | Unsupported |
| `MSG_ROOTKIT_CONFIGURE` | Configuring rkhunter... |
| `MSG_ROOTKIT_CONFIGURE_DONE` | Configured |
| `MSG_ROOTKIT_PROPUPD` | Updating file properties... |
| `MSG_ROOTKIT_PROPUPD_DONE` | Props updated |
| `MSG_ROOTKIT_RUN_SCAN` | Running rootkit scan... |
| `MSG_ROOTKIT_SCAN_RUNNING` | Scanning (may take 10-30 min)... |
| `MSG_ROOTKIT_SCAN_DONE` | Scan complete |
| `MSG_ROOTKIT_SCAN_FOUND` | Warnings found |
| `MSG_ROOTKIT_SCAN_CLEAN` | No warnings |
| `MSG_ROOTKIT_CRON_SETUP` | Setting up weekly cron... |
| `MSG_ROOTKIT_CRON_DONE` | Cron setup done |
| `MSG_ROOTKIT_CRON_EXISTS` | Cron already exists |
| `MSG_ROOTKIT_CRON_SKIP` | Skip cron |
| `MSG_ROOTKIT_STATUS` | Status |
| `MSG_ROOTKIT_LAST_SCAN` | Last scan |
| `MSG_ROOTKIT_NOT_INSTALLED` | Not installed |
| `MSG_ROOTKIT_SUMMARY` | Summary |
| `MSG_ROOTKIT_TIPS_TITLE` | Tips title |
| `MSG_ROOTKIT_TIPS_1..4` | 4 tips |
| `MSG_ROOTKIT_MENU_TITLE` | Submenu title |
| `MSG_ROOTKIT_MENU_WIZARD` | [1] Full wizard |
| `MSG_ROOTKIT_MENU_STATUS` | [2] Status |
| `MSG_ROOTKIT_MENU_BACK` | [0] Back |
| `MSG_HINT_STATUS_ROOTKIT` | Hint |
| `MSG_STATUS_ROOTKIT` | Status label |
| `MSG_REPORT_WARN_ROOTKIT` | Report warning |
| `MSG_TASK_ROOTKIT` | Task name |

## Menu Integration

### New Menu Items (show_main_menu)

Insert after the existing services menu item ([9]) and before the quick wizard ([10]):

```
# Services (existing, unchanged)
...

# --- Enhancements section or within hardening section ---
# AIDE (Full only)
MSG_MAIN_MENU_AIDE="[13] AIDE 入侵检测"
MSG_MAIN_MENU_AIDE_DESC="文件完整性检查系统，监控关键文件变更"

# ClamAV (Full only)
MSG_MAIN_MENU_CLAMAV="[14] ClamAV 病毒扫描"
MSG_MAIN_MENU_CLAMAV_DESC="开源杀毒软件，配置病毒库更新和定时扫描"

# Rootkit Detection (Full only)
MSG_MAIN_MENU_ROOTKIT="[15] Rootkit 检测"
MSG_MAIN_MENU_ROOTKIT_DESC="rkhunter + chkrootkit 检测系统是否被植入后门"
```

**Alternative (grouped):** If 3 new top-level items feel too many, they can be nested under a single "[13] Enhanced Security Tools" submenu-within-submenu. This is **not recommended** — each tool is independent and deserves its own submenu per project convention.

### Menu Numbers Shift

**No shift needed** — new items go at the end:

| Number | Item |
|--------|------|
| 1 | Status |
| 2 | SSH |
| 3 | Firewall |
| 4 | Fail2Ban |
| 5 | Audit |
| 6 | Users |
| 7 | Kernel |
| 8 | Filesystem |
| 9 | Services |
| 10 | Wizard |
| 11 | Report |
| 12 | K3s |
| **13** | **AIDE** |
| **14** | **ClamAV** |
| **15** | **Rootkit Detection** |
| 0 | Exit |

### Case Dispatch

Add to `run_main_menu_loop` case statement:

```bash
13|14|15)
    if is_mode_lite; then
        log_error "${MSG_ERROR_LITE_MODE}"
        press_enter
        continue
    fi
    case "${choice}" in
        13) run_aide_submenu_loop ;;
        14) run_clamav_submenu_loop ;;
        15) run_rootkit_submenu_loop ;;
    esac
    ;;
```

### Full Wizard Integration

Insert 3 new steps between the current Step 8 (services) and Step 9 (summary):

```
# Step 8: Services (existing, unchanged)

# NEW Step 9: AIDE (Full only)
if is_mode_full; then
    log_title "MSG_WIZARD_STEP_AIDE" "[9/13] AIDE 入侵检测"
    if confirm skip; then ...
        run_aide_wizard && _WIZARD_AIDE_DONE=1
fi

# NEW Step 10: ClamAV (Full only)
if is_mode_full; then
    log_title "MSG_WIZARD_STEP_CLAMAV" "[10/13] ClamAV 病毒扫描"
    ...
fi

# NEW Step 11: Rootkit Detection (Full only)
if is_mode_full; then
    log_title "MSG_WIZARD_STEP_ROOTKIT" "[11/13] Rootkit 检测"
    ...
fi

# Step 12: Summary (shifted from 9)
# Step 13: Report (shifted from 10 — check actual structure)
```

**Note:** The full wizard currently shows `[0/10]` through `[9/10]` with `[9/10]` being the summary/report. Adding 3 steps changes it to `[0/13]` through `[12/13]`. Update all `MSG_WIZARD_STEP_*` counters.

### New Wizard Step i18n Keys (update existing, add new)

```
MSG_WIZARD_STEP_AIDE="[9/13] AIDE 入侵检测"
MSG_WIZARD_STEP_CLAMAV="[10/13] ClamAV 病毒扫描"
MSG_WIZARD_STEP_ROOTKIT="[11/13] Rootkit 检测"
MSG_WIZARD_STEP_SUMMARY="[12/13] 变更摘要与确认"
# (update all existing step counters too: [0/13], [1/13]...)
```

Add wizard skip/error messages:
```
MSG_WIZARD_SKIPPED_AIDE="跳过 AIDE 配置"
MSG_WIZARD_ERR_AIDE="AIDE 配置出现错误"
MSG_WIZARD_SKIPPED_CLAMAV="跳过 ClamAV 配置"
MSG_WIZARD_ERR_CLAMAV="ClamAV 配置出现错误"
MSG_WIZARD_SKIPPED_ROOTKIT="跳过 Rootkit 检测"
MSG_WIZARD_ERR_ROOTKIT="Rootkit 检测出现错误"
```

### Status Detection Integration

Add these blocks to `show_system_status()` in install.sh, following the existing pattern (after services):

```bash
# --- AIDE ---
if is_mode_lite; then
    _print_status_row "${MSG_STATUS_AIDE}" "${MSG_STATUS_NA_LITE}" "${YELLOW}" "" "⏭️"
else
    local aide_color="${RED}" aide_icon="❌" aide_detail="${MSG_STATUS_NOT_CONFIGURED}"
    if type check_aide_status &>/dev/null; then
        local aide_status aide_db_exists aide_cron
        aide_status=$(check_aide_status 2>/dev/null)
        aide_db_exists=$(echo "${aide_status}" | grep '^aide_db_exists=' | cut -d= -f2)
        aide_cron=$(echo "${aide_status}" | grep '^aide_cron=' | cut -d= -f2)
        if [[ "${aide_db_exists}" == "yes" ]]; then
            aide_color="${GREEN}"; aide_icon="✅"
            aide_detail="DB: OK, Cron: ${aide_cron}"
        fi
    fi
    _print_status_row "${MSG_STATUS_AIDE}" ... "${aide_color}" ... "${aide_detail}" "${aide_icon}"
fi

# --- ClamAV --- (similar pattern)
# --- Rootkit Detection --- (similar pattern)
```

### Report Integration

In `generate_report()` in report.sh, add after services section:

```bash
# AIDE
_report_task_line "${_WIZARD_AIDE_DONE:-0}" "${MSG_TASK_AIDE}"
if [[ "${_WIZARD_AIDE_DONE:-0}" == "1" ]]; then
    if type check_aide_status &>/dev/null; then
        local aide_status
        aide_status=$(check_aide_status 2>/dev/null)
        echo "    - DB initialized: $(echo "${aide_status}" | grep '^aide_db_exists=' | cut -d= -f2)"
        echo "    - Cron: $(echo "${aide_status}" | grep '^aide_cron=' | cut -d= -f2)"
    fi
fi

# ClamAV (similar)
# Rootkit (similar)
```

Add warnings in the warnings section:
```bash
if [[ "${_WIZARD_AIDE_DONE:-0}" == "1" ]]; then
    echo "  ⚠ ${MSG_REPORT_WARN_AIDE}"
fi
# (same for clamav, rootkit)
```

## Test Plans

### `tests/unit/aide.bats` (~20-25 tests)

| # | Test | Category |
|---|------|----------|
| 1 | `_AIDE_LOADED` is set | Guard |
| 2 | `_install_aide` function exists | Function existence |
| 3 | `run_aide_wizard` function exists | Function existence |
| 4 | `check_aide_status` function exists | Function existence |
| 5 | aide constants are defined (AIDE_CONF, AIDE_DB, AIDE_CRON_FILE) | Constants |
| 6 | `check_aide_status` returns key=value format | Output |
| 7 | `check_aide_status` includes aide_db_exists | Output |
| 8 | `check_aide_status` includes aide_cron | Output |
| 9-25 | (more detailed: install detection, config gen, cron gen, wizard structure, etc.) | |

### `tests/unit/clamav.bats` (~20-25 tests)

| # | Test | Category |
|---|------|----------|
| 1 | `_CLAMAV_LOADED` is set | Guard |
| 2 | `_install_clamav` function exists | Function existence |
| 3 | `run_clamav_wizard` function exists | Function existence |
| 4 | `check_clamav_status` function exists | Function existence |
| 5 | Constants defined | Constants |
| 6 | `check_clamav_status` returns key=value | Output |
| 7-25 | (install detection, freshclam config, cron gen, scan cron, etc.) | |

### `tests/unit/rootkit.bats` (~20-25 tests)

| # | Test | Category |
|---|------|----------|
| 1 | `_ROOTKIT_LOADED` is set | Guard |
| 2 | `_install_rkhunter` function exists | Function existence |
| 3 | `_install_chkrootkit` function exists | Function existence |
| 4 | `run_rootkit_wizard` function exists | Function existence |
| 5 | `check_rootkit_status` function exists | Function existence |
| 6 | Constants defined | Constants |
| 7 | `check_rootkit_status` returns key=value | Output |
| 8-25 | (install detection, config gen, cron gen, propupd detection, etc.) | |

## Implementation Order

Phase 1 (can be parallel):
1. **Task 1.1**: Create `scripts/security/aide.sh` — simplest of the three (single tool, deterministic)
2. **Task 1.2**: Add MSG_AIDE_* keys to zh.sh and en.sh

Phase 2 (can be parallel):
3. **Task 2.1**: Create `scripts/security/rootkit.sh` — two tools but straightforward install
4. **Task 2.2**: Add MSG_ROOTKIT_* keys to zh.sh and en.sh

Phase 3 (requires careful design):
5. **Task 3.1**: Create `scripts/security/clamav.sh` — most complex (memory concerns, freshclam, scan cron)
6. **Task 3.2**: Add MSG_CLAMAV_* keys to zh.sh and en.sh

Phase 4 (integration — sequential, must come after all 3 modules):
7. **Task 4.1**: Update `scripts/base/mode.sh` — register 3 modules
8. **Task 4.2**: Update `install.sh` — load 3 modules, add menu items, case dispatch, full wizard steps, status detection
9. **Task 4.3**: Update `scripts/base/report.sh` — add 3 report sections + warnings

Phase 5 (tests):
10. **Task 5.1**: Write `tests/unit/aide.bats`
11. **Task 5.2**: Write `tests/unit/rootkit.bats`
12. **Task 5.3**: Write `tests/unit/clamav.bats`

Phase 6 (finalize):
13. **Task 6.1**: Run full ShellCheck on all modified files
14. **Task 6.2**: Run full Bats test suite
15. **Task 6.3**: Update `HANDOVER.md`

## Validation

```bash
# ShellCheck all new and modified files
shellcheck -x scripts/security/aide.sh
shellcheck -x scripts/security/clamav.sh
shellcheck -x scripts/security/rootkit.sh
shellcheck -x install.sh
shellcheck -x scripts/base/report.sh
shellcheck -x scripts/base/mode.sh

# Bats tests
bats tests/unit/aide.bats
bats tests/unit/clamav.bats
bats tests/unit/rootkit.bats
bats tests/unit/*.bats  # ensure no regressions
```

## Risks Summary

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| AIDE init takes 30+ min on large servers | Medium | Medium | Warn user; optional skip; `timeout 600` guard |
| aideinit binary name differs per distro | Medium | High | Detect both names (`aideinit`/`aide --init`) |
| ClamAV memory: 200-300MB | High | Medium | Warn at wizard start; don't enable clamd; only freshclam + on-demand |
| EPEL required for RHEL-family (rkhunter, clamav) | Medium | Medium | Install epel-release first (existing pattern from fail2ban) |
| chkrootkit not in EPEL | High | Low | Skip gracefully, continue with rkhunter only |
| rkhunter false positives | High | Low | Document in tips; user must review warnings manually |
| Menu becomes long (15 items) | Medium | Low | Consistent with existing pattern; grouped by sections |
| freshclam initial download slow (~100MB) | Medium | Medium | Run in background; inform user; non-blocking |

## Acceptance Criteria

- [ ] `scripts/security/aide.sh` created — install, configure, db init, cron, wizard, status check
- [ ] `scripts/security/clamav.sh` created — install, freshclam config + cron, optional scan cron, memory warning, wizard, status check
- [ ] `scripts/security/rootkit.sh` created — install rkhunter + chkrootkit, configure, propupd, run scan, cron, wizard, status check
- [ ] All i18n keys added for zh and en (~100 total across 3 modules)
- [ ] `scripts/base/mode.sh` updated — 3 modules registered in MODE_FULL_MODULES and MODE_ALL_MODULES
- [ ] `install.sh` updated — load 3 modules, menu items [13][14][15] with Lite guard, case dispatch, full wizard steps 9-11, status detection sections
- [ ] `scripts/base/report.sh` updated — 3 report sections + warnings
- [ ] Full wizard step counters updated ([0/13] through [12/13])
- [ ] ShellCheck passes on all modified files
- [ ] Bats tests pass (3 new test files + no regressions)
- [ ] `HANDOVER.md` updated

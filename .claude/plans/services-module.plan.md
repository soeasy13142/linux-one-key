# Plan: v0.4 Services Management Module (services.sh)

**Source**: PRD §2.9 + HANDOVER.md v0.4 pending task
**Complexity**: Medium

## Summary

Create `scripts/security/services.sh` — a service management module that audits running services, disables unnecessary ones, and scans open ports. This is the last remaining v0.4 module per HANDOVER.md.

## Patterns to Mirror

| Category | Source | Pattern |
|---|---|---|
| Module structure | `audit.sh:1-14` | Shebang, set -eo, utils guard check, constants, internal funcs, public funcs, wizard, load guard |
| Install function | `audit.sh:33-63` | `_install_*()` with DETECTED_OS case, command_exists check, log_step/log_success |
| Wizard | `audit.sh:402-495` | `run_*_wizard()` — root check, install, interactive menu, confirm per step, log_title sections |
| Status check | `kernel.sh:307-329` | `check_*_status()` returning key=value pairs for show_system_status() |
| Menu integration | `install.sh:833-864` | case dispatch, `run_*_wizard \|\| log_error`, press_enter |
| Full wizard | `install.sh:652-806` | _WIZARD_*_DONE flag, confirm skip, run wizard, set flag |
| Report | `report.sh:100-118` | _report_task_line + module-specific detail lines |
| i18n | `zh.sh` MSG_AUDIT_* | MSG_SERVICES_* prefix, ~30-40 keys |
| Tests | `audit.bats:1-80` | setup with TEST_DIR, source utils+lang+module, constants tests, function existence, output tests |

## Files to Change

| File | Action | Why |
|---|---|---|
| `scripts/security/services.sh` | CREATE | New module: service audit, disable unnecessary services, port scan |
| `scripts/lang/zh.sh` | UPDATE | Add ~35 MSG_SERVICES_* Chinese translations + menu items |
| `scripts/lang/en.sh` | UPDATE | Add ~35 MSG_SERVICES_* English translations + menu items |
| `install.sh` | UPDATE | Load services.sh, add menu [9], shift wizard→[10] report→[11], full wizard step, status check |
| `scripts/base/report.sh` | UPDATE | Add services section in report |
| `tests/unit/services.bats` | CREATE | Unit tests (~25-30 test cases) |
| `scripts/security/README.md` | UPDATE | Add services module description |
| `HANDOVER.md` | UPDATE | Mark v0.4 services as done |

## Module Design: services.sh

### Constants

```
# Unnecessary services list (security risk on servers)
UNNECESSARY_SERVICES=(
    "telnet.socket:telnet — 明文传输，不安全"
    "rsh.socket:rsh — 明文传输，不安全"
    "rlogin.socket:rlogin — 明文传输，不安全"
    "vsftpd:FTP — 明文传输，除非必要否则禁用"
    "avahi-daemon:mDNS — 服务器通常不需要"
    "cups:打印服务 — 服务器通常不需要"
    "rpcbind:RPC — 不需要则禁用"
)

# Safe standard ports
SAFE_PORTS=(22 80 443)
```

### Internal Functions

1. `_list_running_services()` — `systemctl list-units --type=service --state=running --no-pager --no-legend`
2. `_check_unnecessary_services()` — iterate UNNECESSARY_SERVICES, check if active
3. `_disable_service(service_name)` — `systemctl stop + disable`, with backup state
4. `_scan_listening_ports()` — `ss -tlnp` or `netstat -tlnp` fallback
5. `_identify_unknown_ports(port)` — check against SAFE_PORTS list, flag unknowns

### Public Functions

1. `audit_services()` — list all running services with status
2. `disable_unnecessary_services()` — interactive: show list, confirm each, stop+disable
3. `scan_open_ports()` — show all listening ports, mark known/unknown
4. `check_services_status()` — key=value output for show_system_status()
5. `run_services_wizard()` — full interactive wizard:
   - Step 1: Audit running services (display only)
   - Step 2: Disable unnecessary services (interactive confirm)
   - Step 3: Scan open ports (display + warning for unknowns)

### Menu Integration

- Main menu [9]: `run_services_wizard`
- Shift existing: wizard→[10], report→[11]
- Update case pattern: `[0-9]|10|11)`
- Full wizard: new Step 8 (between Filesystem and Summary)
- Status: show running service count + unnecessary service count

## Tasks

### Task 1: Create services.sh
- **Action**: Write `scripts/security/services.sh` (~250-300 lines)
- **Mirror**: audit.sh structure (guard, constants, internal, public, wizard, load guard)
- **Validate**: `shellcheck -x scripts/security/services.sh`

### Task 2: Add i18n translations
- **Action**: Add ~35 MSG_SERVICES_* keys to zh.sh and en.sh
- **Mirror**: MSG_AUDIT_* naming pattern
- **Validate**: `grep -c MSG_SERVICES_ scripts/lang/zh.sh` ≈ 35

### Task 3: Integrate into install.sh
- **Action**: Load services.sh, add menu [9], shift wizard/report numbers, add full wizard step, add status section
- **Mirror**: How audit.sh is integrated (lines 251-257, 463-464, 732-745)
- **Validate**: `shellcheck -x install.sh`

### Task 4: Update report.sh
- **Action**: Add services report section (running count, disabled services, open ports)
- **Mirror**: audit section in report.sh (lines 102-118)
- **Validate**: `shellcheck -x scripts/base/report.sh`

### Task 5: Create unit tests
- **Action**: Write `tests/unit/services.bats` (~25-30 test cases)
- **Mirror**: audit.bats structure
- **Validate**: `bats tests/unit/services.bats`

### Task 6: Update documentation
- **Action**: Update scripts/security/README.md, HANDOVER.md
- **Validate**: Review completeness

## Validation

```bash
shellcheck -x scripts/security/services.sh
shellcheck -x install.sh
shellcheck -x scripts/base/report.sh
bats tests/unit/services.bats
bats tests/unit/*.bats  # ensure no regressions
```

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| ss/netstat not available on some systems | Low | Fallback: /proc/net/tcp parsing |
| systemctl not available (older init systems) | Low | Project targets systemd-based distros per PRD |
| Menu number shift breaks existing muscle memory | Medium | Document in changelog, consistent with prior shifts |

## Acceptance

- [ ] services.sh created with all functions
- [ ] i18n keys added for zh and en
- [ ] Menu integration working (item [9], shifted wizard/report)
- [ ] Full wizard includes services step
- [ ] Status detection shows services info
- [ ] Report includes services section
- [ ] Unit tests pass (25+ cases)
- [ ] ShellCheck passes on all modified files
- [ ] All existing tests still pass

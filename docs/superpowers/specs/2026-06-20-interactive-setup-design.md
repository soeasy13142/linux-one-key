# Design: Interactive Step-by-Step Setup

**Date**: 2026-06-20
**Status**: Approved
**Complexity**: Medium

## Summary

将 linux-one-key 从"一键自动配置"重构为"逐步交互式配置"，每一步都由用户做出选择，彻底删除 `--yes`/`--quick` 等非交互模式，保证用户对每次系统修改有完全控制权。

## Motivation

当前的一键模式（`--yes`/`--quick`）使用硬编码默认值（如 SSH 端口→2222）自动修改系统配置，用户无法干预任何参数。这在生产环境中非常危险——端口冲突、锁死、不合规配置等问题随时可能发生。必须改为：每一步都可选、可定制、可跳过。

## Architecture

### Files to Change

| File | Action | Description |
|------|--------|-------------|
| `install.sh` | UPDATE | Remove `--yes`/`--quick`/`--ssh`/`--firewall`/`--fail2ban` args; remove `AUTO_ACCEPT` branches; rename "Quick Hardening" to "Full Wizard" |
| `scripts/security/ssh.sh` | UPDATE | Enhance `change_ssh_port` with random port generation; delete `run_ssh_hardening_custom`; rename `run_ssh_hardening` to `run_ssh_wizard` |
| `scripts/security/firewall.sh` | UPDATE | Enhance interactivity; delete `run_firewall_hardening_custom`; rename `run_firewall_hardening` to `run_firewall_wizard` |
| `scripts/security/fail2ban.sh` | UPDATE | Add user-customizable bantime/findtime/maxretry; delete `run_fail2ban_hardening_custom`; rename `run_fail2ban_hardening` to `run_fail2ban_wizard` |
| `scripts/base/utils.sh` | UPDATE | Add `generate_random_port()` utility function |
| `scripts/lang/en.sh` | UPDATE | Add i18n strings for new interactive prompts |
| `scripts/lang/zh.sh` | UPDATE | Add i18n strings for new interactive prompts |

### What Gets Deleted

- `--yes` / `-y` / `--quick` / `--ssh` / `--firewall` / `--fail2ban` CLI argument parsing
- `AUTO_ACCEPT` environment variable and all `if [[ "${AUTO_ACCEPT}" == "yes" ]]` branches
- Auto-enable non-interactive mode for curl pipe (still download + re-exec, but always interactive)
- `run_ssh_hardening_custom()` / `run_firewall_hardening_custom()` / `run_fail2ban_hardening_custom()`
- The "一键快速加固" menu item (replaced by "完整向导")

### What Stays

- `--status` (read-only, safe)
- `--help` / `-h`
- curl pipe bootstrap (download tarball → verify checksum → re-exec in interactive mode)
- Menu framework (enhanced, not rewritten)
- i18n system (zh + en)
- Rollback protection mechanism (at-based timer)
- Backup-before-modify invariant

## Interaction Design

### SSH Port Modification

```
Current SSH Port: 22

Choose:
  1. Enter custom port (default: 2222)
  2. Generate random high port (1024-65535)
  3. Keep current port (skip)

⚠ After changing the port, ensure the firewall allows the new port.
```

- Option 1: prompt for number → validate range / not in use → confirm
- Option 2: generate random (avoid 0-1023 + well-known ports: 3306, 5432, 6379, 8080, 8443, 9090, 3000, 5000, 8000) → show to user → regenerate or accept
- Option 3: skip

### SSH Key Generation

- Show default path `~/.ssh/id_ed25519` (editable)
- Ask passphrase (recommended but optional)
- If key exists: ask overwrite / skip

### Disable Root Login & Password Auth

- Each step shows risk warning
- Checks preconditions (other sudo users exist, SSH keys present)
- Requires explicit confirmation before execution

### SSH Security Parameters

Show defaults, user can modify each or accept all:

| Parameter | Default |
|-----------|---------|
| MaxAuthTries | 3 |
| LoginGraceTime | 60s |
| ClientAliveInterval | 300s |
| ClientAliveCountMax | 2 |
| MaxSessions | 2 |

### Firewall

- Auto-detect UFW / firewalld
- Always allow SSH port (current + 22 as fallback)
- One-by-one: HTTP/HTTPS? ICMP? Custom ports?
- Show final rule summary before enabling

### Fail2Ban

Show defaults, user can modify or accept:

| Parameter | Default | Description |
|-----------|---------|-------------|
| bantime | 3600s | Ban duration |
| findtime | 600s | Detection window |
| maxretry | 5 | Max failure attempts |

### Full Wizard (replaces old "Quick Hardening")

Sequential walkthrough of all steps above, each step:
1. Show current value + recommended default
2. User: confirm / modify / skip
3. Proceed to next step
4. After all steps: show change summary → final confirmation → execute

## Data Flow

```
install.sh
  ├─ parse args (--status, --help only)
  ├─ bootstrap (curl pipe → download → re-exec → interactive)
  ├─ load deps (utils → lang → detect → init → ssh → fw → f2b)
  ├─ system detection (read-only)
  ├─ main menu loop
  │   ├─ [1] Status → show_system_status()
  │   ├─ [2] SSH → run_ssh_wizard()
  │   │   ├─ change_ssh_port()     ← user input / random gen
  │   │   ├─ generate_ssh_key()    ← path + passphrase
  │   │   ├─ disable_root_login()  ← confirm dialog
  │   │   ├─ disable_password()    ← confirm dialog
  │   │   ├─ configure_ssh_params()← per-item confirm
  │   │   └─ validate + restart + rollback timer
  │   ├─ [3] Firewall → run_firewall_wizard()
  │   ├─ [4] Fail2Ban → run_fail2ban_wizard()
  │   ├─ [5] Full Wizard → run_full_wizard()
  │   ├─ [6] View Report → view_report()
  │   └─ [0] Exit
  └─ generate report + cleanup
```

## Error Handling

| Scenario | Strategy |
|----------|----------|
| User Ctrl+C mid-step | trap EXIT → prompt "cancelled", config already backed up |
| Single step failure | Show error + rollback that step + ask continue/exit |
| `sshd -t` fails | Auto-rollback + prompt user to inspect |
| SSH restart fails | Cancel rollback timer, keep backup, guide manual recovery |
| Port already in use | Prompt re-enter or regenerate random |
| Network failure (curl) | Retry 3x + friendly message |

## Invariants

- **Never** modify system config without backup
- **Never** execute write operations without explicit user confirmation
- **Always** set rollback timer after SSH port change
- **Always** keep port 22 open in firewall (anti-lockout)
- **Always** require double-confirmation for dangerous operations

## Testing

### Unit Tests

| Target | Content |
|--------|---------|
| `generate_random_port()` | Range 1024-65535; excludes well-known ports; varied output |
| `validate_port()` | Valid passes; negative/0/>65535/non-numeric rejected; octal handling |
| Arg parsing | `--status` valid; `--yes`/`--quick` error + migration hint |
| Constants | DEFAULT_SSH_PORT=2222, BANTIME=3600 verified |

### Integration Tests (VM required)

| Scenario | Verification |
|----------|-------------|
| SSH port - custom | Select "custom" → set 2222 → Port 2222 in sshd_config |
| SSH port - random | Select "random" → port written, not 22 |
| SSH port - skip | Select "keep" → sshd_config unchanged |
| Rollback mechanism | Change port, don't confirm → auto-restore after 5 min |
| Firewall HTTP opt-in | Choose yes → 80/tcp rule exists; no → absent |
| Fail2Ban custom params | User sets bantime=7200 → jail.local has bantime=7200 |
| Full wizard | Walk through all steps, summary matches actual config |
| Idempotency | Repeat same step → no errors |
| `--status` preserved | `--status` still works |
| Old args rejected | `--yes`/`--quick` show migration message and exit |

### Acceptance Criteria

- [ ] `--yes`, `--quick`, `--ssh`, `--firewall`, `--fail2ban` args removed with error on use
- [ ] `AUTO_ACCEPT` and all non-interactive branches purged
- [ ] Every write operation has explicit user confirmation
- [ ] Random port generation works and avoids well-known ports
- [ ] Rollback protection functional
- [ ] `--status` read-only mode unaffected
- [ ] ShellCheck passes
- [ ] Both zh/en i18n strings complete

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Users confused by removed --yes | Low | `--help` updated; passing old flags shows migration message |
| curl pipe mode breaks | Medium | Keep bootstrap, remove only the auto-non-interactive; test with `curl \| bash` |
| Rollback timer race condition | Low | Existing fix (commit 6453a0f) already addressed this |

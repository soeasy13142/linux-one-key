# Plan: Fix Code Review Findings (commit 400933a)

**Source**: `.claude/reviews/commit-400933a-review.md`
**Complexity**: Medium

## Summary

Fix all HIGH/RECOMMENDED issues from the v0.3 code review: eval injection, function ordering, find exclusions, fragile parsing, dead code integration, and report gaps.

## Files to Change

| File | Action | Why |
|---|---|---|
| `scripts/security/users.sh` | UPDATE | Fix #1 eval injection, #8 SSH hint, #9 integrate status func |
| `scripts/security/kernel.sh` | UPDATE | Fix #2 function ordering, #9 integrate status func |
| `scripts/security/filesystem.sh` | UPDATE | Fix #3 find exclusions, #4 truncation warning, #5 fragile parsing, #7 scope mismatch, #9 integrate status func |
| `scripts/base/report.sh` | UPDATE | Fix #10 add filesystem details |
| `scripts/lang/en.sh` | UPDATE | Fix #8 add no-passphrase warning text |
| `scripts/lang/zh.sh` | UPDATE | Fix #8 add no-passphrase warning text |
| `install.sh` | UPDATE | Fix #9 use check_*_status() instead of inline logic |

## Tasks

### Task 1: Replace `eval` with `getent passwd` (HIGH #1)
- **File**: `scripts/security/users.sh:184`
- **Action**: Replace `eval echo "~${username}"` with `getent passwd "${username}" | cut -d: -f6`
- **Before**: `user_home=$(eval echo "~${username}" 2>/dev/null || echo "/home/${username}")`
- **After**: `user_home=$(getent passwd "${username}" 2>/dev/null | cut -d: -f6); user_home="${user_home:-/home/${username}}"`

### Task 2: Reorder `_generate_sysctl_config` above call site (HIGH #2)
- **File**: `scripts/security/kernel.sh`
- **Action**: Move `_generate_sysctl_config()` definition (line 82+) above `apply_sysctl_params()` (line 40+)

### Task 3: Add `-xdev` and exclude virtual filesystems from `find /` (HIGH #3)
- **File**: `scripts/security/filesystem.sh:199, 201, 264`
- **Action**: Add `-xdev -not -path '/proc/*' -not -path '/sys/*'` to all `find /` calls in `audit_suid_sgid()` and `check_orphan_files()`

### Task 4: Add truncation warning to `check_orphan_files` (RECOMMENDED #4)
- **File**: `scripts/security/filesystem.sh:264`
- **Action**: After `head -50`, check if count >= 50 and log a warning
- **i18n**: Add `MSG_FS_ORPHAN_TRUNCATED` to en.sh and zh.sh

### Task 5: Fix fragile `tail -1` parsing in `run_filesystem_wizard` (RECOMMENDED #5)
- **File**: `scripts/security/filesystem.sh:312`
- **Action**: Instead of parsing stdout with `tail -1`, use a global variable `_FS_PERM_ISSUE_COUNT` set by `check_critical_permissions()`

### Task 6: Fix `check_filesystem_status` scope mismatch (RECOMMENDED #7)
- **File**: `scripts/security/filesystem.sh:360`
- **Action**: Change `find /usr` to `find /` with `-xdev` exclusions to match `audit_suid_sgid()` scope

### Task 7: Add no-passphrase warning to SSH key hint (RECOMMENDED #8)
- **File**: `scripts/security/users.sh:220`, `scripts/lang/en.sh`, `scripts/lang/zh.sh`
- **Action**: Append a warning about no-passphrase risk to `MSG_USERS_SSH_KEY_HINT`
- **en**: "Please download the private key to local storage. WARNING: The key has no passphrase — protect it carefully."
- **zh**: "请将私钥下载到本地安全保存。警告：密钥无密码保护，请妥善保管。"

### Task 8: Integrate `check_*_status()` into `show_system_status()` (RECOMMENDED #9)
- **File**: `install.sh:405-427`
- **Action**: Replace inline status logic with calls to `check_users_status()`, `check_kernel_status()`, `check_filesystem_status()`, parsing their key=value output

### Task 9: Add filesystem details to report (RECOMMENDED #10)
- **File**: `scripts/base/report.sh:144`
- **Action**: After the filesystem task line, when `_WIZARD_FS_DONE=1`, show SUID count (reuse `check_filesystem_status` output or inline `find`)

## Validation

```bash
# Static analysis
shellcheck scripts/security/users.sh scripts/security/kernel.sh scripts/security/filesystem.sh scripts/base/report.sh install.sh

# Unit tests
bats tests/unit/users.bats tests/unit/kernel.bats tests/unit/filesystem.bats
```

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `getent` not available on all systems | Low | Fallback to `/home/${username}` |
| Function reorder breaks sourcing | Low | Test with `bash -n` syntax check |
| Status function output format mismatch | Medium | Parse `key=value` format consistently |

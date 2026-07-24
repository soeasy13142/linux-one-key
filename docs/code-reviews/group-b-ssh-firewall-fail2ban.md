# Code Review: Group B - SSH + Firewall + Fail2Ban

**Date:** 2026-07-15  
**Reviewer:** Automated code review  
**Files:**
- `scripts/security/ssh.sh` (716 lines)
- `scripts/security/firewall.sh` (443 lines)
- `scripts/security/fail2ban.sh` (370 lines)

---

## HIGH Severity Findings

### H-1: Fallback ssh-keygen exposes passphrase in process list

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 233
- **CATEGORY:** security
- **TITLE:** Fallback passphrase visible via /proc/PID/cmdline

When `SSH_ASKPASS_REQUIRE=force` is not supported (older OpenSSH), the code falls back to passing the passphrase directly via `-N`:

```bash
ssh-keygen -t ed25519 -f "${key_path}" -N "${passphrase}" -C "$(whoami)@$(hostname)"
```

This exposes the passphrase in the process command line, readable by any user on the system via `/proc/PID/cmdline` or `ps aux`. The primary SSH_ASKPASS path (lines 226-228) correctly avoids this, but the fallback undoes the protection.

**SUGGESTION:** Before falling back, log a warning that passphrase will be visible in process list. Consider using `ssh-keygen` with a file descriptor (`--stdin-key-file` if available, or pipe passphrase via `-N` from a temp file). Alternatively, print a prominent warning to the user so they can change the passphrase after generation.

---

### H-2: SSH key type detection missing FIDO/U2F `sk-ecdsa-sha2-*` keys

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 340
- **CATEGORY:** correctness
- **TITLE:** _has_valid_ssh_key does not recognize sk-ecdsa-sha2-nistp256 keys

The regex `^(ssh-(rsa|ed25519|dss)|ecdsa-sha2|sk-ssh-)` does not match `sk-ecdsa-sha2-nistp256@openssh.com` (FIDO/U2F ECDSA keys). While `sk-ssh-ed25519` IS matched, the `sk-ecdsa-*` variant is not.

This means `check_ssh_keys()` and `_check_all_users_ssh_keys()` may return false negatives when users only have FIDO/U2F keys, potentially blocking password authentication when keys are actually available.

**SUGGESTION:** Add `sk-ecdsa-sha2` and `sk-ecdsa-sha2-*` to the regex pattern:
```bash
if grep -qE '^(ssh-(rsa|ed25519|dss)|ecdsa-sha2|sk-(ssh|ecdsa-sha2)-)' "${auth_keys}"; then
```

---

### H-3: Port 22 close instruction always shows ufw, wrong for firewalld

- **FILE:** `scripts/lang/zh.sh` and `scripts/lang/en.sh` (used in `scripts/security/ssh.sh:707`)
- **LINE:** zh.sh:356, en.sh:356
- **CATEGORY:** cross-distro
- **TITLE:** MSG_FIREWALL_SSH_PORT22_CLOSE hardcodes ufw command for all distros

The message reads `sudo ufw deny 22/tcp` regardless of the actual firewall. On firewalld systems (CentOS/RHEL/Rocky/Alma/Fedora), this gives the user an incorrect command that will fail ("command not found"). The user must then figure out the correct firewalld syntax.

The message is displayed from `ssh.sh:707` inside `run_ssh_wizard()`, which does not know which firewall was installed. Both i18n files define the same ufw-only command for both zh and en.

**SUGGESTION:** Either (a) add a `get_firewall_port_close_cmd()` function to `firewall.sh` and call it from `ssh.sh`, or (b) define a second i18n key `MSG_FIREWALL_SSH_PORT22_CLOSE_FIREWALLD` and select dynamically using `DETECTED_OS` in ssh.sh. Option (a) is cleaner but introduces a cross-module dependency.

---

## MEDIUM Severity Findings

### M-1: Four i18n MSG_* keys used but missing from both language files

- **FILE:** `scripts/security/ssh.sh`
- **LINES:** 583, 676, 677, 687
- **CATEGORY:** i18n
- **TITLE:** Undefined i18n keys render empty messages to user

These keys are used in the script but not defined in either `zh.sh` or `en.sh`:

| Key | Line | Context |
|-----|------|---------|
| `MSG_SSH_ROLLBACK_NO_BACKUP` | 583 | Rollback failure message |
| `MSG_SSH_WIZARD_EXTERNAL_MOD` | 676 | Warning about external config modification |
| `MSG_SSH_WIZARD_ROLLBACK_OVERWRITE` | 677 | Warning about rollback overwrite |
| `MSG_SSH_RESTART_FAIL_ROLLBACK` | 687 | Restart fail + rollback message (uses `{delay}` placeholder) |

Since `-u` (nounset) is disabled, referencing undefined variables silently evaluates to empty strings. Users will see blank log_warn/log_error messages instead of meaningful warnings.

**SUGGESTION:** Add these 4 keys to both `scripts/lang/zh.sh` and `scripts/lang/en.sh`. Example values:
```
MSG_SSH_ROLLBACK_NO_BACKUP="No SSH config backup found for rollback"
MSG_SSH_WIZARD_EXTERNAL_MOD="SSH config was modified externally during wizard"
MSG_SSH_WIZARD_ROLLBACK_OVERWRITE="Rollback will overwrite external changes"
MSG_SSH_RESTART_FAIL_ROLLBACK="SSH restart failed, rollback in {delay}s"
```

---

### M-2: Firewall type detection maps by OS only, not actual installation

- **FILE:** `scripts/security/firewall.sh`
- **LINE:** 69-75
- **CATEGORY:** robustness / cross-distro
- **TITLE:** _get_firewall_type infers firewall from OS name, not from what is installed

```bash
_get_firewall_type() {
    case "${DETECTED_OS}" in
        ubuntu|debian)                          echo "ufw" ;;
        centos|rhel|rocky|almalinux|fedora)     echo "firewalld" ;;
        *)                                      echo "unknown" ;;
    esac
}
```

If a Debian admin has installed firewalld and removed ufw, the script will attempt ufw operations and fail. Similarly, if a CentOS admin has installed ufw (uncommon but possible), it would try firewalld. The detection should check for the actual presence of `ufw` or `firewall-cmd` rather than assuming from distro.

**SUGGESTION:** Prefer runtime detection: check `command_exists ufw` and `command_exists firewall-cmd`, with the distro-based mapping as a fallback.

---

### M-3: `_firewalld_start` is unreachable dead code

- **FILE:** `scripts/security/firewall.sh`
- **LINE:** 148-153
- **CATEGORY:** maintainability
- **TITLE:** _firewalld_start function defined but never called

The function is defined but no call path in `firewall.sh` or any other script invokes it. The `run_firewall_wizard` flow goes through `_install_firewall()` which handles firewalld start internally (line 43: `systemctl enable --now firewalld`).

**SUGGESTION:** Either remove the dead code, or if kept as a public API, add a header comment explaining its intended usage and that it assumes firewalld is already installed.

---

### M-4: `_firewalld_allow_port` silently ignores the comment parameter

- **FILE:** `scripts/security/firewall.sh`
- **LINE:** 179-185 (definition), 260 (call site)
- **CATEGORY:** maintainability
- **TITLE:** open_port() passes comment to firewalld variant which ignores it

The public `open_port()` function accepts a `$3` comment parameter and passes it to both UFW and firewalld backends. UFW uses it (line 103: `comment "$comment"`), but firewalld's `_firewalld_allow_port` declares no `$3` parameter, silently ignoring the comment.

**SUGGESTION:** Add a `local comment="$3"` to `_firewalld_allow_port` and document that firewalld does not support per-port comments, or add a log_debug line when comment is provided but ignored.

---

### M-5: Fail2Ban banaction selection has no fallback

- **FILE:** `scripts/security/fail2ban.sh`
- **LINE:** 119-121
- **CATEGORY:** robustness / cross-distro
- **TITLE:** banaction hardcoded, no fallback if firewalld unavailable

```bash
centos|rhel|rocky|almalinux|fedora) banaction="firewallcmd-ipset" ;;
```

If fail2ban runs standalone (firewall step skipped) or firewalld is not running, `firewallcmd-ipset` will fail silently or produce errors at runtime. There is no fallback to `iptables-multiport`.

**SUGGESTION:** Check if firewalld is active before choosing `firewallcmd-ipset`. Fall back to `iptables-multiport` if firewalld is not running:
```bash
if command_exists firewall-cmd && systemctl is-active --quiet firewalld 2>/dev/null; then
    banaction="firewallcmd-ipset"
else
    banaction="iptables-multiport"
fi
```

---

### M-6: `SSH_SERVICE_NAME` declared as readonly but never referenced

- **FILE:** `scripts/security/fail2ban.sh`
- **LINE:** 92-94
- **CATEGORY:** maintainability
- **TITLE:** SSH_SERVICE_NAME is dead code

```bash
readonly SSH_SERVICE_NAME="sshd"
```

The constant is declared with a suppress comment for ShellCheck SC2034, but the actual jail configuration at line 154 hardcodes `[sshd]` as the jail name. The constant is never used.

**SUGGESTION:** Either use `SSH_SERVICE_NAME` in the jail.local template generation for the `[sshd]` section header, or remove the constant.

---

### M-7: String concatenation pattern for i18n (fragile across languages)

- **FILE:** `scripts/security/fail2ban.sh`
- **LINE:** 395
- **CATEGORY:** i18n
- **TITLE:** Deprecated string concatenation for log warning message

```bash
log_warn "${MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND}${auth_log}${MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND_TAIL}"
```

With i18n keys:
```
MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND="Auth log file not found: "
MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND_TAIL=", fail2ban may need journald backend"
```

This pattern assumes the path goes between prefix and suffix, which is English/Chinese word order and may not work for RTL languages or languages with different sentence structure. Better to use placeholder substitution like `{path}`.

**SUGGESTION:** Define a single key with `{path}` placeholder:
```
MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND="Auth log file not found: {path}, fail2ban may need journald backend"
```
Then use: `MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND//\{path\}/${auth_log}`

---

## LOW Severity Findings

### L-1: Empty passphrase still uses `-N ""` exposed in process list

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 219
- **CATEGORY:** security
- **TITLE:** Empty passphrase leaks via process list (minor)

When passphrase is empty, `ssh-keygen` is called with `-N ""`, which may appear as an empty argument in `/proc/PID/cmdline`. While leaking "empty passphrase" is less sensitive than the actual passphrase, it violates the principle applied at line 226 (using SSH_ASKPASS to avoid process list exposure).

**SUGGESTION:** For consistency, use the same SSH_ASKPASS mechanism even for empty passphrases, or add a comment explaining why the `-N ""` path is acceptable (e.g., "empty passphrase exposes no secret").

---

### L-2: `auth_ok` variable persists as true when `.pub` missing

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 240-256
- **CATEGORY:** correctness
- **TITLE:** Misleading success message when key .pub file absent

```bash
local auth_ok=true
if [[ -f "${key_path}.pub" ]]; then
    ...
fi
if [[ "${auth_ok}" == true ]]; then
    log_success "${MSG_SSH_KEY_PERMS}"  # "Correct file permissions set"
fi
```

If the `.pub` file does not exist (key generation failed earlier), `auth_ok` remains `true` and the permissions success message is still shown. The message is technically about the directory permissions (set at line 213), but it appears misleadingly like the key generation succeeded.

**SUGGESTION:** Set `auth_ok` based on actual key generation success: `local auth_ok=false` and set to `true` only after `ssh-keygen` succeeds.

---

### L-3: `current_user` injected into awk script via string concatenation

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 271-272
- **CATEGORY:** robustness
- **TITLE:** Variable interpolation in awk script body

```bash
users=$(awk -F: '$7 !~ /(nologin|false|sync|shutdown|halt)$/ && $1 != "root" && $1 != "'"${current_user}"'" {print $1}' /etc/passwd ...)
```

The `${current_user}` is spliced into the awk script string. While `whoami` on Linux returns a restricted character set (alphanumeric, underscore, hyphen), a maliciously crafted username with `"` or `\` characters could break the awk syntax or inject code. Same pattern at line 374.

**SUGGESTION:** Validate the current_user value before injection, or refactor the awk logic to avoid shell interpolation (e.g., pass via `awk -v` variable).

---

### L-4: Integer division truncation for `at` job timeout

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 604
- **CATEGORY:** robustness
- **TITLE:** ROLLBACK_DELAY / 60 truncation for non-multiple-of-60 delays

```bash
at now + $(( ROLLBACK_DELAY / 60 )) minutes
```

Bash integer division truncates. `ROLLBACK_DELAY=600` gives exactly 10 minutes, but if the constant were changed to 650, it would truncate to 10 minutes (not 10.83). The `at` command does not accept fractional minutes, so this is a limitation, but the 40-second discrepancy could matter for short delays.

**SUGGESTION:** Add a comment documenting the minute-resolution constraint, or document that `ROLLBACK_DELAY` should be a multiple of 60.

---

### L-5: Non-readonly globals inconsistent with project convention

- **FILE:** `scripts/security/ssh.sh`
- **LINE:** 23-24
- **CATEGORY:** maintainability
- **TITLE:** ROLLBACK_PID and ROLLBACK_AT_JOB not declared readonly

These global variables are mutable, unlike other module-level constants (e.g., `SSH_CONFIG`, `DEFAULT_SSH_PORT`, `ROLLBACK_DELAY`). While they are intentionally mutable (they are reassigned), the inconsistency with the project convention of `readonly` for constants could cause confusion.

**SUGGESTION:** Add a comment above the declarations: `# Mutable state for rollback timer tracking (not readonly by design)`

---

### L-6: Firewall interface migration errors silently suppressed

- **FILE:** `scripts/security/firewall.sh`
- **LINE:** 171
- **CATEGORY:** robustness
- **TITLE:** Interface migration failures hidden

```bash
for iface in $(firewall-cmd --zone="${old_zone}" --list-interfaces 2>/dev/null); do
    firewall-cmd --zone=drop --add-interface="${iface}" --permanent 2>/dev/null || true
done
```

Both stdout and stderr are discarded (`2>/dev/null`) and errors are swallowed (`|| true`). If the interface migration fails (e.g., permissions, already assigned), the user will not know. The interface remains in the old zone with potentially different rule sets.

**SUGGESTION:** Log at debug level on success and warn level on failure. Remove the `2>/dev/null` redirect (or keep stdout but let stderr through).

---

### L-7: `enable_firewall` for firewalld does not explicitly enable/enable the service

- **FILE:** `scripts/security/firewall.sh`
- **LINE:** 336-344
- **CATEGORY:** correctness
- **TITLE:** enable_firewall for firewalld only reloads, does not enable service

```bash
firewalld)
    if _firewalld_reload; then
        log_success "${MSG_FIREWALL_ENABLE_DONE}"
    else
        log_error "Failed to enable firewalld"
        return 1
    fi
```

This only reloads rules. It assumes firewalld is already started and enabled (which was done in `_install_firewall`). If `run_firewall_wizard` is not the entry path and `enable_firewall` is called standalone after a skip of the install step, it would not actually start the service. The UFW variant calls `ufw --force enable` which actually enables it.

**SUGGESTION:** Add a `systemctl enable --now firewalld` before reloading, or document that this function assumes the service is already running.

---

### L-8: Redundant `sleep 1` before service polling loop

- **FILE:** `scripts/security/fail2ban.sh`
- **LINE:** 182-192
- **CATEGORY:** maintainability
- **TITLE:** Fixed sleep adds startup delay unnecessarily

```bash
systemctl restart fail2ban >> "${LOG_FILE}" 2>&1
sleep 1
# Polling loop (max 10 attempts at 1s intervals)
```

The `sleep 1` is redundant because the polling loop already waits (up to 10 seconds). Combined, the worst-case wait is 11 seconds instead of 10. The fixed sleep adds latency when the service starts quickly.

**SUGGESTION:** Remove the `sleep 1` and let the polling loop handle timing.

---

### L-9: No local `setup_error_trap` call in any security module

- **FILE:** All three scripts
- **LINES:** Various (ssh.sh:5, firewall.sh:6, fail2ban.sh:6)
- **CATEGORY:** robustness
- **TITLE:** Error traps rely on install.sh being the entry point

All three scripts depend on `install.sh` calling `setup_error_trap()` (install.sh:1319). If any module is sourced standalone for testing or independent use, `set -e` will still cause exit on error, but the ERR/INT/EXIT traps will not be set, leaving `_cleanup_on_exit` (and its scheduled task cleanup) inactive.

**SUGGESTION:** Add a guard: `[[ -z "${_ERROR_TRAP_SET:-}" ]] && command -v setup_error_trap &>/dev/null && setup_error_trap`  at the end of each module, or document that standalone sourcing requires pre-loading scripts/base/init.sh.

---

## Summary

| Severity | Count | Key Areas |
|----------|-------|-----------|
| HIGH | 3 | Passphrase exposure in fallback, missing FIDO key type, wrong firewall close command |
| MEDIUM | 7 | 4 missing i18n keys, OS-only firewall detection, dead code, ignored comment, no banaction fallback, unused constant, fragile i18n concat |
| LOW | 9 | Empty passphrase leak, misleading success message, awk injection, truncation, non-readonly globals, silenced errors, enable vs reload, redundant sleep, no local error trap |

**General observations:**
- The scripts are well-structured with consistent use of `set -eo pipefail` and i18n patterns.
- The SSH module has the most maturity but also the most findings, consistent with its complexity (716 lines vs 443/370).
- The most impactful finding is H-3 (wrong firewall close command), which could confuse users on RHEL-family systems.
- The 4 missing i18n keys (M-1) should be added as a quick fix — they represent real messages currently rendering as blank.
- `_firewalld_start` (M-3) should be cleaned up or documented.

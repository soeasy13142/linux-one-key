# Interactive Step-by-Step Setup — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove all one-key/non-interactive modes from the Linux setup scripts, replacing them with step-by-step interactive dialogs where every system modification requires explicit user confirmation.

**Architecture:** Delete `AUTO_ACCEPT` and all non-interactive branches from `utils.sh` and `install.sh`. Enhance each security module's hardening function with rich interactive prompts. Add random port generation utility. Replace "Quick Hardening" menu item with "Full Wizard" sequential walkthrough.

**Tech Stack:** Bash 4+, POSIX utilities (ss, netstat, grep, sed, awk)

## Global Constraints

- Shell scripts use `#!/usr/bin/env bash`, must set `set -eo pipefail`
- Function naming: `snake_case`, constants: `UPPER_SNAKE_CASE`
- Each function must have a comment describing its purpose
- Compatible with CentOS 7+, Ubuntu 20.04+, Debian 11+
- Colors: green=success, red=error, yellow=warning, blue=info
- All user-visible strings use i18n (`MSG_*` variables)
- ShellCheck must pass with no errors
- `--status` must still work as before
- Rollback protection must still work
- `--yes`/`--quick`/`--ssh`/`--firewall`/`--fail2ban` must show migration error

---

### Task 1: Add `generate_random_port()` utility and new i18n strings

**Files:**
- Modify: `scripts/base/utils.sh:34-36` (remove AUTO_ACCEPT)
- Modify: `scripts/base/utils.sh:181-259` (remove AUTO_ACCEPT from interactive functions)
- Modify: `scripts/base/utils.sh:572-579` (add generate_random_port before module marker)
- Modify: `scripts/lang/zh.sh` (add new i18n strings)
- Modify: `scripts/lang/en.sh` (add new i18n strings)

**Interfaces:**
- Consumes: Nothing new
- Produces: `generate_random_port` (no args, echoes random port 1024-65535 excluding well-known ports)
- Produces: New `MSG_*` i18n variables for interactive prompts

- [ ] **Step 1: Remove AUTO_ACCEPT variable from utils.sh**

In `scripts/base/utils.sh`, delete lines 34-35:
```bash
# Non-interactive mode flag (set by --yes/-y argument)
AUTO_ACCEPT="${AUTO_ACCEPT:-no}"
```

- [ ] **Step 2: Simplify confirm() — remove AUTO_ACCEPT branch**

In `scripts/base/utils.sh`, replace the `confirm()` function (lines 183-205) with:
```bash
# Confirm an action (y/N)
confirm() {
    local prompt="${1:-${MSG_CONFIRM}}"
    local default="${2:-n}"
    local reply

    if [[ "${default}" == "y" || "${default}" == "Y" ]]; then
        prompt="${prompt} [Y/n] "
    else
        prompt="${prompt} [y/N] "
    fi

    read -r -p "$(printf "%b" "${YELLOW}${prompt}${NC}")" reply
    reply="${reply:-${default}}"

    [[ "${reply}" =~ ^[Yy]$ ]]
}
```

- [ ] **Step 3: Simplify press_enter() — remove AUTO_ACCEPT branch**

In `scripts/base/utils.sh`, replace the `press_enter()` function (lines 208-216) with:
```bash
# Wait for user to press Enter
press_enter() {
    local msg="${1:-${MSG_PRESS_ENTER}}"
    read -r -p "$(echo -e "${BLUE}${msg}${NC}")"
}
```

- [ ] **Step 4: Simplify prompt_input() — remove AUTO_ACCEPT branch**

In `scripts/base/utils.sh`, replace the `prompt_input()` function (lines 219-241) with:
```bash
# Read user input with optional default value
prompt_input() {
    local prompt="$1"
    local default="${2:-}"
    local result

    if [[ -n "${default}" ]]; then
        read -r -p "$(echo -e "${BLUE}${prompt}${NC} [${default}]: ")" result
        result="${result:-${default}}"
    else
        read -r -p "$(echo -e "${BLUE}${prompt}${NC}: ")" result
    fi

    echo "${result}"
}
```

- [ ] **Step 5: Simplify prompt_password() — remove AUTO_ACCEPT branch**

In `scripts/base/utils.sh`, replace the `prompt_password()` function (lines 244-259) with:
```bash
# Read password (no echo)
prompt_password() {
    local prompt="$1"
    local password

    read -r -s -p "$(echo -e "${BLUE}${prompt}${NC}: ")" password
    echo ""  # newline after hidden input
    echo "${password}"
}
```

- [ ] **Step 6: Add generate_random_port() function**

In `scripts/base/utils.sh`, add before the "Module loaded" marker (before line 576):
```bash
# ═══════════════════════════════════════════
# Random Port Generation
# ═══════════════════════════════════════════

# Well-known ports to avoid (beyond 0-1023)
readonly WELL_KNOWN_PORTS=(
    3306   # MySQL
    5432   # PostgreSQL
    6379   # Redis
    27017  # MongoDB
    8080   # HTTP alt
    8443   # HTTPS alt
    9090   # Prometheus
    3000   # Grafana / dev
    5000   # Flask / dev
    8000   # Django / dev
    9200   # Elasticsearch
    11211  # Memcached
)

# Generate a random high port (1024-65535) avoiding well-known ports
generate_random_port() {
    local port
    local attempts=0
    local max_attempts=100

    while [[ ${attempts} -lt ${max_attempts} ]]; do
        # Use $RANDOM for portability (bash builtin, 0-32767)
        # Scale to 1024-65535 range
        port=$((1024 + RANDOM % 64512))

        # Avoid well-known ports
        local is_known=0
        for known in "${WELL_KNOWN_PORTS[@]}"; do
            if [[ "${port}" -eq "${known}" ]]; then
                is_known=1
                break
            fi
        done

        if [[ ${is_known} -eq 0 ]]; then
            echo "${port}"
            return 0
        fi

        ((attempts++))
    done

    # Fallback: return a port we know is safe
    echo "2222"
}
```

- [ ] **Step 7: Add new i18n strings to zh.sh**

In `scripts/lang/zh.sh`, after the SSH port section (after line 169), add:
```bash
# SSH Port Interactive Options
MSG_SSH_PORT_OPTION_TITLE="Please select SSH port configuration method"
MSG_SSH_PORT_OPTION_CUSTOM="[1] Enter custom port (default: 2222)"
MSG_SSH_PORT_OPTION_RANDOM="[2] Generate random high port (1024-65535)"
MSG_SSH_PORT_OPTION_KEEP="[3] Keep current port (skip)"
MSG_SSH_PORT_OPTION_PROMPT="Enter option [1-3]"
MSG_SSH_PORT_RANDOM_GEN="Random port generated: "
MSG_SSH_PORT_RANDOM_ACCEPT="Use this port? (y=yes / n=regenerate / enter number=custom)"
MSG_SSH_PORT_CONFIRM="Confirm changing SSH port from {current} to {new}?"
MSG_SSH_PORT_SKIP="Skipping SSH port change"

# SSH Parameter Customization
MSG_SSH_PARAMS_CUSTOM_TITLE="SSH Security Parameter Configuration"
MSG_SSH_PARAMS_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_SSH_PARAMS_MAXAUTHTRIES="Maximum authentication attempts (MaxAuthTries)"
MSG_SSH_PARAMS_LOGINGRACETIME="Login grace time in seconds (LoginGraceTime)"
MSG_SSH_PARAMS_CLIENTALIVEINTERVAL="Client alive interval in seconds (ClientAliveInterval)"
MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX="Maximum client alive count (ClientAliveCountMax)"
MSG_SSH_PARAMS_MAXSESSIONS="Maximum concurrent sessions (MaxSessions)"

# Fail2Ban Custom Parameters
MSG_FAIL2BAN_CUSTOM_TITLE="Fail2Ban Parameter Configuration"
MSG_FAIL2BAN_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_FAIL2BAN_BANTIME_PROMPT="Ban duration in seconds (bantime)"
MSG_FAIL2BAN_FINDTIME_PROMPT="Detection window in seconds (findtime)"
MSG_FAIL2BAN_MAXRETRY_PROMPT="Maximum failure attempts (maxretry)"

# Full Wizard
MSG_WIZARD_TITLE="Full Security Configuration Wizard"
MSG_WIZARD_DESC="This wizard will guide you through all security configurations step by step. Each step: confirm / modify / skip."
MSG_WIZARD_STEP_SSH="[1/4] SSH Security Hardening"
MSG_WIZARD_STEP_FIREWALL="[2/4] Firewall Configuration"
MSG_WIZARD_STEP_FAIL2BAN="[3/4] Fail2Ban Intrusion Prevention"
MSG_WIZARD_STEP_SUMMARY="[4/4] Change Summary & Confirmation"
MSG_WIZARD_SKIP_STEP="Skip this step? (y/N)"
MSG_WIZARD_SUMMARY_TITLE="The following changes will be applied:"
MSG_WIZARD_CONFIRM="Confirm executing all above changes? (y/N)"
MSG_WIZARD_COMPLETE="Wizard complete"
MSG_WIZARD_CANCELLED="Wizard cancelled"

# Old Argument Migration Messages
MSG_ERROR_REMOVED_ARG="Error: --{arg} argument has been removed."
MSG_ERROR_REMOVED_HINT="This script is now fully interactive. Run without arguments: sudo bash install.sh"
MSG_ERROR_REMOVED_STATUS="Tip: --status is still available for read-only checks: sudo bash install.sh --status"
```

Wait — the above strings are in English for zh.sh. Let me fix: zh.sh should have Chinese strings. Let me correct:

For zh.sh, after line 169:
```bash
# SSH 端口交互选项
MSG_SSH_PORT_OPTION_TITLE="请选择 SSH 端口配置方式"
MSG_SSH_PORT_OPTION_CUSTOM="[1] 输入自定义端口 (默认: 2222)"
MSG_SSH_PORT_OPTION_RANDOM="[2] 生成随机高端口 (1024-65535)"
MSG_SSH_PORT_OPTION_KEEP="[3] 保持当前端口 (跳过)"
MSG_SSH_PORT_OPTION_PROMPT="请输入选项 [1-3]"
MSG_SSH_PORT_RANDOM_GEN="已生成随机端口: "
MSG_SSH_PORT_RANDOM_ACCEPT="是否使用此端口？(y=使用 / n=重新生成 / 输入数字=自定义)"
MSG_SSH_PORT_CONFIRM="确认将 SSH 端口从 {current} 修改为 {new}？"
MSG_SSH_PORT_SKIP="跳过 SSH 端口修改"

# SSH 参数自定义
MSG_SSH_PARAMS_CUSTOM_TITLE="SSH 安全参数配置"
MSG_SSH_PARAMS_CUSTOM_PROMPT="每个参数将展示默认值，您可以直接回车接受或输入新值"
MSG_SSH_PARAMS_MAXAUTHTRIES="最大认证尝试次数 (MaxAuthTries)"
MSG_SSH_PARAMS_LOGINGRACETIME="登录超时秒数 (LoginGraceTime)"
MSG_SSH_PARAMS_CLIENTALIVEINTERVAL="客户端心跳间隔秒数 (ClientAliveInterval)"
MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX="最大心跳失败次数 (ClientAliveCountMax)"
MSG_SSH_PARAMS_MAXSESSIONS="最大并发会话数 (MaxSessions)"

# Fail2Ban 自定义参数
MSG_FAIL2BAN_CUSTOM_TITLE="Fail2Ban 参数配置"
MSG_FAIL2BAN_CUSTOM_PROMPT="每个参数将展示默认值，您可以直接回车接受或输入新值"
MSG_FAIL2BAN_BANTIME_PROMPT="封禁时长（秒）(bantime)"
MSG_FAIL2BAN_FINDTIME_PROMPT="检测时间窗口（秒）(findtime)"
MSG_FAIL2BAN_MAXRETRY_PROMPT="最大失败次数 (maxretry)"

# 完整向导
MSG_WIZARD_TITLE="完整安全配置向导"
MSG_WIZARD_DESC="将逐步引导您完成所有安全配置，每步可选择：确认/修改/跳过"
MSG_WIZARD_STEP_SSH="[1/4] SSH 安全加固"
MSG_WIZARD_STEP_FIREWALL="[2/4] 防火墙配置"
MSG_WIZARD_STEP_FAIL2BAN="[3/4] Fail2Ban 入侵防护"
MSG_WIZARD_STEP_SUMMARY="[4/4] 变更摘要与确认"
MSG_WIZARD_SKIP_STEP="跳过此步骤？(y/N)"
MSG_WIZARD_SUMMARY_TITLE="即将执行以下变更："
MSG_WIZARD_CONFIRM="确认执行以上所有变更？(y/N)"
MSG_WIZARD_COMPLETE="向导完成"
MSG_WIZARD_CANCELLED="向导已取消"

# 旧参数迁移提示
MSG_ERROR_REMOVED_ARG="错误: --{arg} 参数已被移除。"
MSG_ERROR_REMOVED_HINT="本脚本已改为纯交互模式，请不带参数运行: sudo bash install.sh"
MSG_ERROR_REMOVED_STATUS="提示: --status 仍然可用用于只读检测: sudo bash install.sh --status"
```

- [ ] **Step 8: Add new i18n strings to en.sh**

In `scripts/lang/en.sh`, after the SSH port section (after line 169), add:
```bash
# SSH Port Interactive Options
MSG_SSH_PORT_OPTION_TITLE="Choose SSH port configuration method"
MSG_SSH_PORT_OPTION_CUSTOM="[1] Enter custom port (default: 2222)"
MSG_SSH_PORT_OPTION_RANDOM="[2] Generate random high port (1024-65535)"
MSG_SSH_PORT_OPTION_KEEP="[3] Keep current port (skip)"
MSG_SSH_PORT_OPTION_PROMPT="Enter option [1-3]"
MSG_SSH_PORT_RANDOM_GEN="Random port generated: "
MSG_SSH_PORT_RANDOM_ACCEPT="Use this port? (y=yes / n=regenerate / enter number=custom)"
MSG_SSH_PORT_CONFIRM="Confirm changing SSH port from {current} to {new}?"
MSG_SSH_PORT_SKIP="Skipping SSH port change"

# SSH Parameter Customization
MSG_SSH_PARAMS_CUSTOM_TITLE="SSH Security Parameter Configuration"
MSG_SSH_PARAMS_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_SSH_PARAMS_MAXAUTHTRIES="Max authentication attempts (MaxAuthTries)"
MSG_SSH_PARAMS_LOGINGRACETIME="Login grace time in seconds (LoginGraceTime)"
MSG_SSH_PARAMS_CLIENTALIVEINTERVAL="Client alive interval in seconds (ClientAliveInterval)"
MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX="Max client alive count (ClientAliveCountMax)"
MSG_SSH_PARAMS_MAXSESSIONS="Max concurrent sessions (MaxSessions)"

# Fail2Ban Custom Parameters
MSG_FAIL2BAN_CUSTOM_TITLE="Fail2Ban Parameter Configuration"
MSG_FAIL2BAN_CUSTOM_PROMPT="Each parameter shows its default; press Enter to accept or type a new value"
MSG_FAIL2BAN_BANTIME_PROMPT="Ban duration in seconds (bantime)"
MSG_FAIL2BAN_FINDTIME_PROMPT="Detection window in seconds (findtime)"
MSG_FAIL2BAN_MAXRETRY_PROMPT="Max failure attempts (maxretry)"

# Full Wizard
MSG_WIZARD_TITLE="Full Security Configuration Wizard"
MSG_WIZARD_DESC="This wizard will guide you through all security configurations step by step. Each step: confirm / modify / skip."
MSG_WIZARD_STEP_SSH="[1/4] SSH Security Hardening"
MSG_WIZARD_STEP_FIREWALL="[2/4] Firewall Configuration"
MSG_WIZARD_STEP_FAIL2BAN="[3/4] Fail2Ban Intrusion Prevention"
MSG_WIZARD_STEP_SUMMARY="[4/4] Change Summary & Confirmation"
MSG_WIZARD_SKIP_STEP="Skip this step? (y/N)"
MSG_WIZARD_SUMMARY_TITLE="The following changes will be applied:"
MSG_WIZARD_CONFIRM="Confirm executing all above changes? (y/N)"
MSG_WIZARD_COMPLETE="Wizard complete"
MSG_WIZARD_CANCELLED="Wizard cancelled"

# Old Argument Migration Messages
MSG_ERROR_REMOVED_ARG="Error: --{arg} argument has been removed."
MSG_ERROR_REMOVED_HINT="This script is now fully interactive. Run without arguments: sudo bash install.sh"
MSG_ERROR_REMOVED_STATUS="Tip: --status is still available for read-only checks: sudo bash install.sh --status"
```

- [ ] **Step 9: Run ShellCheck on utils.sh**

```bash
shellcheck scripts/base/utils.sh
```
Expected: No errors.

- [ ] **Step 10: Commit**

```bash
git add scripts/base/utils.sh scripts/lang/zh.sh scripts/lang/en.sh
git commit -m "feat: add generate_random_port, remove AUTO_ACCEPT, add interactive i18n strings"
```

---

### Task 2: Rewrite install.sh — remove one-key mode, add full wizard

**Files:**
- Modify: `install.sh` (multiple sections)

**Interfaces:**
- Consumes: `generate_random_port` from utils.sh, new `MSG_*` from lang files
- Produces: `run_full_wizard()` function, updated `main()` without non-interactive branch, updated `run_main_menu_loop()`
- Removes: `_parse_args` (replaced), `run_quick_hardening` (replaced by `run_full_wizard`), non-interactive main() branch

- [ ] **Step 1: Replace arg parsing — remove one-key args, keep --status and --help, add migration errors**

In `install.sh`, replace `_parse_args` function (lines 100-152) with:
```bash
# Parse command line arguments
_parse_args() {
    for arg in "$@"; do
        case "${arg}" in
            --status)
                export TARGET_MODULE="status"
                ;;
            --help|-h)
                echo "Usage: bash install.sh [options]"
                echo ""
                echo "Options:"
                echo "  --status       Show system security status (read-only)"
                echo "  --help, -h     Show this help"
                echo ""
                echo "No arguments: interactive menu."
                echo ""
                echo "Examples:"
                echo "  bash install.sh                      # Interactive menu"
                echo "  bash install.sh --status             # Status check only"
                echo "  curl -fsSL .../install.sh | sudo bash"
                exit 0
                ;;
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
            *)
                echo -e "${RED}Unknown argument: ${arg}${NC}"
                echo "Use --help for available options"
                exit 1
                ;;
        esac
    done
}
```

- [ ] **Step 2: Remove auto-non-interactive detection**

In `install.sh`, delete lines 154-158:
```bash
# Delete this block:
# if [[ ! -t 0 ]] && [[ "${AUTO_ACCEPT}" != "yes" ]]; then
#     export AUTO_ACCEPT="yes"
# fi
```

- [ ] **Step 3: Update bootstrap — remove auto --yes for curl pipe**

In `install.sh`, in `_bootstrap_and_reexec()` (lines 83-86), replace:
```bash
    # Old:
    if [[ ${#args[@]} -eq 0 ]] && [[ ! -t 0 ]]; then
        args=("--yes")
    fi
    # New:
    # curl pipe mode: just re-exec, user gets interactive menu
    :
```

- [ ] **Step 4: Update i18n menu labels for "Full Wizard"**

In `scripts/lang/zh.sh`, change lines 73-74:
```bash
MSG_MAIN_MENU_QUICK="[5] 完整安全配置向导"
MSG_MAIN_MENU_QUICK_DESC="逐步引导完成所有安全配置，每步可选择"
```

In `scripts/lang/en.sh`, change lines 73-74:
```bash
MSG_MAIN_MENU_QUICK="[5] Full Security Wizard"
MSG_MAIN_MENU_QUICK_DESC="Step-by-step guided configuration, choose at each step"
```

- [ ] **Step 5: Replace run_quick_hardening() with run_full_wizard()**

In `install.sh`, replace `run_quick_hardening()` (lines 576-623) with:
```bash
# ═══════════════════════════════════════════
# Full Security Configuration Wizard
# ═══════════════════════════════════════════

run_full_wizard() {
    log_title "${MSG_WIZARD_TITLE}"

    echo ""
    echo -e "${BOLD}${MSG_WIZARD_DESC}${NC}"
    echo ""
    press_enter

    local wizard_rc=0

    # ── Step 1: SSH ──
    echo ""
    log_title "${MSG_WIZARD_STEP_SSH}"

    if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
        log_info "Skipping SSH hardening"
    else
        run_ssh_wizard || {
            log_warn "SSH hardening had errors, continuing"
            wizard_rc=1
        }
    fi

    # ── Step 2: Firewall ──
    echo ""
    log_title "${MSG_WIZARD_STEP_FIREWALL}"

    if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
        log_info "Skipping firewall configuration"
    else
        run_firewall_wizard || {
            log_warn "Firewall configuration had errors"
            wizard_rc=1
        }
    fi

    # ── Step 3: Fail2Ban ──
    echo ""
    log_title "${MSG_WIZARD_STEP_FAIL2BAN}"

    if confirm "${MSG_WIZARD_SKIP_STEP}" "n"; then
        log_info "Skipping Fail2Ban configuration"
    else
        run_fail2ban_wizard || {
            log_warn "Fail2Ban configuration had errors"
            wizard_rc=1
        }
    fi

    # ── Step 4: Summary ──
    echo ""
    log_title "${MSG_WIZARD_STEP_SUMMARY}"

    generate_report

    if [[ ${wizard_rc} -eq 0 ]]; then
        log_success "${MSG_WIZARD_COMPLETE}"
    else
        log_warn "${MSG_WIZARD_COMPLETE} (some steps had errors, check logs)"
    fi

    press_enter
    return ${wizard_rc}
}
```

- [ ] **Step 6: Replace non-interactive main() branch with status-only**

In `install.sh`, replace the non-interactive block in `main()` (lines 731-777) with:
```bash
    # --status mode: read-only detection, no system modification
    if [[ "${TARGET_MODULE:-}" == "status" ]]; then
        run_detection || true
        print_detection_summary
        # Clean up bootstrap temp dir
        if [[ -n "${_CLEANUP_DIR:-}" ]] && [[ -d "${_CLEANUP_DIR}" ]]; then
            rm -rf "${_CLEANUP_DIR}" 2>/dev/null || true
        fi
        exit 0
    fi
```

- [ ] **Step 7: Update main menu loop — option 5 calls run_full_wizard**

In `install.sh`, in `run_main_menu_loop()` around line 660, change:
```bash
    5)
        run_full_wizard
        ;;
```

- [ ] **Step 8: Run ShellCheck on install.sh**

```bash
shellcheck install.sh
```

- [ ] **Step 9: Commit**

```bash
git add install.sh scripts/lang/zh.sh scripts/lang/en.sh
git commit -m "feat: remove one-key mode, add full interactive wizard to install.sh"
```

---

### Task 3: Rewrite SSH module — enhanced port interaction + wizard mode

**Files:**
- Modify: `scripts/security/ssh.sh`

**Interfaces:**
- Consumes: `generate_random_port` from utils.sh, new `MSG_SSH_PORT_OPTION_*` and `MSG_SSH_PARAMS_CUSTOM_*` i18n strings
- Produces: `run_ssh_wizard` (replaces `run_ssh_hardening`)
- Removes: `run_ssh_hardening_custom`

- [ ] **Step 1: Enhance change_ssh_port() — 3-choice menu + random port generation**

In `scripts/security/ssh.sh`, replace `change_ssh_port()` (lines 64-100) with:
```bash
# Modify SSH port with interactive options (custom / random / skip)
change_ssh_port() {
    log_title "${MSG_SSH_PORT_TITLE}"

    local current_port
    current_port=$(get_ssh_port)
    log_info "${MSG_SSH_PORT_CURRENT}: ${current_port}"

    local new_port=""

    # Show options
    echo ""
    echo -e "${BOLD}${MSG_SSH_PORT_OPTION_TITLE}${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_SSH_PORT_OPTION_CUSTOM}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_PORT_OPTION_RANDOM}${NC}"
    echo -e "  ${GREEN}${MSG_SSH_PORT_OPTION_KEEP}${NC}"
    echo ""

    local choice
    while [[ -z "${new_port}" ]]; do
        choice=$(prompt_input "${MSG_SSH_PORT_OPTION_PROMPT}" "1")

        case "${choice}" in
            1)
                # Custom port
                while true; do
                    new_port=$(prompt_input "${MSG_SSH_PORT_PROMPT}" "2222")

                    if ! validate_port "${new_port}"; then
                        log_error "${MSG_SSH_PORT_INVALID}"
                        continue
                    fi

                    if [[ "${new_port}" == "${current_port}" ]]; then
                        log_info "Port unchanged, skipping"
                        return 0
                    fi

                    if check_port_in_use "${new_port}"; then
                        log_error "${MSG_SSH_PORT_IN_USE}: ${new_port}"
                        continue
                    fi

                    break
                done
                ;;
            2)
                # Random port
                while true; do
                    new_port=$(generate_random_port)
                    echo ""
                    echo -e "${GREEN}${MSG_SSH_PORT_RANDOM_GEN}${BOLD}${new_port}${NC}"
                    echo ""

                    local rand_choice
                    rand_choice=$(prompt_input "${MSG_SSH_PORT_RANDOM_ACCEPT}" "y")

                    case "${rand_choice}" in
                        y|Y|yes|YES)
                            if validate_port "${new_port}" && ! check_port_in_use "${new_port}"; then
                                break
                            else
                                log_error "${MSG_SSH_PORT_IN_USE}: ${new_port}"
                                new_port=""
                                continue
                            fi
                            ;;
                        n|N|no|NO)
                            new_port=""
                            continue
                            ;;
                        *)
                            # User typed a number — treat as custom
                            if validate_port "${rand_choice}"; then
                                if ! check_port_in_use "${rand_choice}"; then
                                    new_port="${rand_choice}"
                                    break
                                else
                                    log_error "${MSG_SSH_PORT_IN_USE}: ${rand_choice}"
                                    new_port=""
                                    continue
                                fi
                            fi
                            log_error "${MSG_SSH_PORT_INVALID}"
                            new_port=""
                            ;;
                    esac
                done
                ;;
            3)
                log_info "${MSG_SSH_PORT_SKIP}"
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done

    # Confirm the change
    local confirm_msg="${MSG_SSH_PORT_CONFIRM//\{current\}/${current_port}}"
    confirm_msg="${confirm_msg//\{new\}/${new_port}}"
    if ! confirm "${confirm_msg}" "y"; then
        log_info "Cancelled"
        return 0
    fi

    # Apply
    set_ssh_config "Port" "${new_port}"

    log_success "${MSG_SSH_PORT_SUCCESS}: ${current_port} → ${new_port}"
    echo -e "${MSG_SSH_PORT_HINT//\{port\}/${new_port}}"

    return 0
}
```

- [ ] **Step 2: Enhance configure_ssh_params() — per-parameter prompts**

In `scripts/security/ssh.sh`, replace `configure_ssh_params()` (lines 281-303) with:
```bash
# Configure SSH security parameters interactively
configure_ssh_params() {
    log_title "${MSG_SSH_PARAMS_TITLE}"

    echo ""
    echo -e "${BLUE}${MSG_SSH_PARAMS_CUSTOM_PROMPT}${NC}"
    echo ""

    local val

    val=$(prompt_input "${MSG_SSH_PARAMS_MAXAUTHTRIES}" "3")
    set_ssh_config "MaxAuthTries" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_LOGINGRACETIME}" "60")
    set_ssh_config "LoginGraceTime" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_CLIENTALIVEINTERVAL}" "300")
    set_ssh_config "ClientAliveInterval" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX}" "2")
    set_ssh_config "ClientAliveCountMax" "${val}"

    val=$(prompt_input "${MSG_SSH_PARAMS_MAXSESSIONS}" "2")
    set_ssh_config "MaxSessions" "${val}"

    # X11Forwarding always disabled (no need to ask)
    set_ssh_config "X11Forwarding" "no"

    log_success "${MSG_SSH_PARAMS_SUCCESS}"
    return 0
}
```

- [ ] **Step 3: Rename run_ssh_hardening → run_ssh_wizard**

In `scripts/security/ssh.sh`, change line 405:
```bash
# Old: run_ssh_hardening() {
# New: run_ssh_wizard() {
```
Keep function body unchanged (lines 406-466).

- [ ] **Step 4: Delete run_ssh_hardening_custom**

Delete lines 468-556 (the entire function).

- [ ] **Step 5: ShellCheck**

```bash
shellcheck scripts/security/ssh.sh
```

- [ ] **Step 6: Commit**

```bash
git add scripts/security/ssh.sh
git commit -m "feat: enhance SSH port with random gen and per-param prompts, rename to run_ssh_wizard"
```

---

### Task 4: Rewrite Firewall module — rename, remove non-interactive variant

**Files:**
- Modify: `scripts/security/firewall.sh`

**Interfaces:**
- Consumes: Updated `confirm()` from utils.sh (no longer checks AUTO_ACCEPT)
- Produces: `run_firewall_wizard` (replaces `run_firewall_hardening`)
- Removes: `run_firewall_hardening_custom`

- [ ] **Step 1: Rename run_firewall_hardening → run_firewall_wizard**

In `scripts/security/firewall.sh`, line 316:
```bash
# Old: run_firewall_hardening() {
# New: run_firewall_wizard() {
```

- [ ] **Step 2: Delete run_firewall_hardening_custom**

Delete lines 387-470 (the entire function including `_show_firewall_tips` if it was only used there — but `_show_firewall_tips` is also called from `run_firewall_wizard`, so keep it).

- [ ] **Step 3: ShellCheck**

```bash
shellcheck scripts/security/firewall.sh
```

- [ ] **Step 4: Commit**

```bash
git add scripts/security/firewall.sh
git commit -m "feat: rename firewall to run_firewall_wizard, remove custom variant"
```

---

### Task 5: Rewrite Fail2Ban module — customizable parameters

**Files:**
- Modify: `scripts/security/fail2ban.sh`

**Interfaces:**
- Consumes: New `MSG_FAIL2BAN_CUSTOM_*` and `MSG_FAIL2BAN_*_PROMPT` i18n strings
- Produces: `run_fail2ban_wizard` (replaces `run_fail2ban_hardening`)
- Removes: `run_fail2ban_hardening_custom`

- [ ] **Step 1: Replace run_fail2ban_hardening with run_fail2ban_wizard with param prompts**

In `scripts/security/fail2ban.sh`, replace the function (lines 252-293) with:
```bash
# Interactive Fail2Ban configuration with customizable parameters
run_fail2ban_wizard() {
    log_step "${MSG_FAIL2BAN_TITLE}"

    # Check root
    if ! is_root; then
        log_error "${MSG_ERROR_NOT_ROOT}"
        return 1
    fi

    # Install Fail2Ban
    _install_fail2ban

    # Gather config info
    local ssh_port
    ssh_port=$(get_ssh_port)
    local auth_log
    auth_log=$(_get_auth_log_path)

    # Show current info
    echo ""
    log_info "${MSG_FAIL2BAN_CONFIG_INFO}"
    echo "  SSH Port: ${ssh_port}"
    echo "  Auth Log: ${auth_log}"
    echo ""

    # Prompt for customizable parameters
    echo -e "${BOLD}${MSG_FAIL2BAN_CUSTOM_TITLE}${NC}"
    echo -e "${BLUE}${MSG_FAIL2BAN_CUSTOM_PROMPT}${NC}"
    echo ""

    local bantime
    bantime=$(prompt_input "${MSG_FAIL2BAN_BANTIME_PROMPT}" "3600")

    local findtime
    findtime=$(prompt_input "${MSG_FAIL2BAN_FINDTIME_PROMPT}" "600")

    local maxretry
    maxretry=$(prompt_input "${MSG_FAIL2BAN_MAXRETRY_PROMPT}" "5")

    echo ""

    # Configure jail with user-provided values
    _configure_fail2ban_jail "${ssh_port}" "${auth_log}" "${bantime}" "${findtime}" "${maxretry}"

    # Start service
    _enable_fail2ban_service

    # Show status
    _show_fail2ban_status

    # Show tips
    _show_fail2ban_tips

    log_success "${MSG_FAIL2BAN_DONE}"
}
```

- [ ] **Step 2: Delete run_fail2ban_hardening_custom**

Delete lines 299-335.

- [ ] **Step 3: ShellCheck**

```bash
shellcheck scripts/security/fail2ban.sh
```

- [ ] **Step 4: Commit**

```bash
git add scripts/security/fail2ban.sh
git commit -m "feat: add customizable fail2ban parameters, rename to run_fail2ban_wizard"
```

---

### Task 6: Integration — update references, verify, update checksums

**Files:**
- Modify: `install.sh` (update function name references in submenus)
- Modify: `SHA256SUMS`

- [ ] **Step 1: Update SSH submenu — call individual functions instead of deleted _custom**

In `install.sh`, replace `run_ssh_submenu_loop()` (lines 443-494) with direct function calls:
```bash
run_ssh_submenu_loop() {
    while true; do
        show_ssh_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-6]" "")

        case "${choice}" in
            1)
                change_ssh_port || log_error "SSH port change failed"
                press_enter
                ;;
            2)
                generate_ssh_key || log_error "SSH key generation failed"
                press_enter
                ;;
            3)
                disable_root_login || log_error "Disable root login failed"
                press_enter
                ;;
            4)
                disable_password_auth || log_error "Disable password login failed"
                press_enter
                ;;
            5)
                configure_ssh_params || log_error "SSH params config failed"
                press_enter
                ;;
            6)
                run_ssh_wizard || log_error "SSH wizard failed"
                press_enter
                ;;
            0)
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}
```

- [ ] **Step 2: Update firewall submenu — use run_firewall_wizard**

In `install.sh`, replace `run_firewall_submenu_loop()` (lines 514-547):
```bash
run_firewall_submenu_loop() {
    while true; do
        show_firewall_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-3]" "")

        case "${choice}" in
            1)
                run_firewall_wizard || log_error "Firewall config failed"
                press_enter
                ;;
            2)
                _install_firewall
                setup_firewall_defaults
                open_port "80" "tcp" "HTTP"
                open_port "443" "tcp" "HTTPS"
                enable_firewall
                log_success "HTTP/HTTPS ports opened"
                press_enter
                ;;
            3)
                allow_icmp
                press_enter
                ;;
            0)
                return 0
                ;;
            *)
                log_error "${MSG_MENU_INVALID}"
                ;;
        esac
    done
}
```

- [ ] **Step 3: Update main menu — run_fail2ban_wizard**

In `install.sh`, in `run_main_menu_loop()` around line 654:
```bash
    4)
        run_fail2ban_wizard
        press_enter
        ;;
```

- [ ] **Step 4: Verify no stale references**

```bash
grep -rn "AUTO_ACCEPT" install.sh scripts/ --include="*.sh" || echo "CLEAN: no AUTO_ACCEPT"
grep -rn "run_ssh_hardening\b\|run_firewall_hardening\b\|run_fail2ban_hardening\b\|run_quick_hardening" install.sh scripts/ --include="*.sh" || echo "CLEAN: no old function names"
grep -rn "_custom" install.sh scripts/ --include="*.sh" | grep -v "_CUSTOM_" || echo "CLEAN: no _custom function refs"
```

- [ ] **Step 5: ShellCheck all files**

```bash
shellcheck install.sh scripts/base/utils.sh scripts/security/ssh.sh scripts/security/firewall.sh scripts/security/fail2ban.sh
```

- [ ] **Step 6: Syntax check**

```bash
bash -n install.sh && echo "OK"
bash -n scripts/base/utils.sh && echo "OK"
bash -n scripts/security/ssh.sh && echo "OK"
bash -n scripts/security/firewall.sh && echo "OK"
bash -n scripts/security/fail2ban.sh && echo "OK"
```

- [ ] **Step 7: Update SHA256SUMS**

```bash
sha256sum install.sh scripts/base/utils.sh scripts/base/detect.sh scripts/base/init.sh scripts/lang/en.sh scripts/lang/zh.sh scripts/security/ssh.sh scripts/security/firewall.sh scripts/security/fail2ban.sh > SHA256SUMS
```

- [ ] **Step 8: Commit**

```bash
git add install.sh SHA256SUMS
git commit -m "feat: integrate wizard functions, update all references"
```

---

### Task 7: Update HANDOVER.md

- [ ] **Step 1: Update HANDOVER.md**

Add change log entry:
```
| 2026-06-20 | UPDATE | install.sh, scripts/security/*.sh, scripts/base/utils.sh, scripts/lang/*.sh | Removed one-key mode; replaced with step-by-step interactive config; added random port generation |
```

Update "Last Updated" date, current phase, completed work, and next steps.

- [ ] **Step 2: Commit**

```bash
git add HANDOVER.md
git commit -m "docs: update HANDOVER.md for interactive refactoring"
```

---

## Validation

```bash
# 1. Syntax check
bash -n install.sh
bash -n scripts/base/utils.sh
bash -n scripts/security/ssh.sh
bash -n scripts/security/firewall.sh
bash -n scripts/security/fail2ban.sh

# 2. ShellCheck
shellcheck install.sh scripts/base/utils.sh scripts/security/ssh.sh scripts/security/firewall.sh scripts/security/fail2ban.sh

# 3. Dead reference check
grep -rn "AUTO_ACCEPT\|run_ssh_hardening\b\|run_firewall_hardening\b\|run_fail2ban_hardening\b\|run_quick_hardening\|_custom" \
  install.sh scripts/ --include="*.sh" \
  | grep -v "MSG_SSH_PORT_OPTION_CUSTOM\|MSG_FAIL2BAN_CUSTOM\|MSG_SSH_PARAMS_CUSTOM" \
  || echo "Clean check passed"

# 4. --status still works (on VM)
# sudo bash install.sh --status

# 5. Old args rejected (on VM)
# sudo bash install.sh --yes   → exit 1 with migration message
```

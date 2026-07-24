---
title: "Batch 1: Init & Utility Enhancements (NTP / Swap / Base Tools)"
created: 2026-07-24
updated: 2026-07-24
status: done
source: "PRD §2.10-2.12 + HANDOVER.md v1.0.1 pending tasks"
topic: "feature"
---

# Plan: Batch 1 — Init & Utility Enhancements

**Source**: PRD §2.10 NTP Time Sync, §2.11 Swap Configuration, §2.12 Base Tools
**Complexity**: Low-Medium
**Mode**: **Full-only** — 本批所有功能只实现在完整版（不带 `--lite`）中。Lite 模式代码（`scripts/base/init.sh` 现有时区/系统更新/基础工具部分）不做任何改动。

## Summary

Three independent but related enhancements to the system initialization layer:

1. **Expand `install_base_tools()`** — add htop, net-tools, lsof, tree, git to the existing curl/wget/vim/unzip list.
2. **NTP time synchronization** — enhance `setup_timezone()` with interactive timezone selection; add `setup_ntp()` to install chrony/ntpd and configure reliable NTP sources.
3. **Swap file configuration** — new module to detect swap status and create a swap file with size rules.

All three live in `scripts/base/` (the init layer). No new menu items are needed; the full-wizard Step 0 (System Init) already covers these as part of `run_init()`.

## ⚠️ Full-Only 模式约束（必读）

**核心原则：所有新功能只属于完整版（Full），不得改动精简版（Lite）代码路径。**

| 约束 | 说明 |
|------|------|
| **`install_base_tools()` 扩充** | 当前 Lite 模式有 4 个基础工具（curl/wget/vim/unzip），扩充到 9 个后 **Full 模式才装完整列表**。Lite 模式继续保持原有的 4 个工具不变 |
| **NTP 配置** | `setup_ntp()` 调用仅在 Full 模式的 `run_init()` 中执行。Lite 模式的 init 流程不调用 NTP |
| **Swap 模块** | `scripts/base/swap.sh` 是新建模块，**只被 Full 模式加载**。mode.sh 中注册为 `MODE_FULL_MODULES` |
| **`setup_timezone()` 增强** | 交互式时区选择（时区提示、验证）仅在 Full 模式中启用。Lite 模式保持现有 `Asia/Shanghai` 硬编码行为不变 |

**实现方式：**
- `scripts/base/init.sh` 中：Full 模式下 `run_init()` 新增 setup_ntp + 增强 setup_timezone；Lite 模式 `run_init()` 保持原样
- 通过 `mode.sh` 区分：`init.sh` 中判断 `INSTALL_MODE` 决定是否执行 NTP/增强时区交互
- `scripts/base/swap.sh` 只在 Full 模式下 source（通过 mode.sh 的模块列表控制）

## Patterns to Mirror

| Category | Source | Pattern |
|---|---|---|
| New module file | `scripts/security/services.sh:1-14` | Shebang, set -eo, guard check, constants, internal funcs, public funcs |
| Install function | `init.sh:89-124` | `install_base_tools()` — pkg_manager case, batch install array |
| i18n keys | `zh.sh:699-757` `MSG_SERVICES_*` | MSG_NTP_* / MSG_SWAP_* prefix pattern |
| Init integration | `init.sh:145-169` | `run_init()` calls functions in sequence |
| Report | `report.sh:28-239` | `_report_task_line` + detail lines under init section |
| Test | `services.bats:1-277` | constants tests, function existence, source guard |

## Files to Change

| File | Action | Why |
|---|---|---|
| `scripts/base/init.sh` | MODIFY | Expand `install_base_tools()` array; add `setup_ntp()`; enhance `setup_timezone()`; update `run_init()` |
| `scripts/base/swap.sh` | CREATE | New module: swap detection, creation, swappiness config |
| `scripts/base/report.sh` | MODIFY | Add NTP status and swap status sections in `generate_report()` |
| `scripts/lang/zh.sh` | MODIFY | Add ~30 MSG_NTP_* + MSG_SWAP_* Chinese i18n keys |
| `scripts/lang/en.sh` | MODIFY | Add ~30 MSG_NTP_* + MSG_SWAP_* English i18n keys |
| `install.sh` | MODIFY | Load `swap.sh` in `load_dependencies()`; expand full-wizard init step; add status check for swap |
| `scripts/base/mode.sh` | MODIFY | Register `swap` in `MODE_FULL_MODULES` and `MODE_ALL_MODULES` |
| `tests/unit/init.bats` | CREATE | Unit tests for init.sh enhanced functions (Full-mode scoped) |
| `tests/unit/swap.bats` | CREATE | Unit tests for swap.sh |
| `HANDOVER.md` | MODIFY | Mark Batch 1 as done |

## Module Design

### 1. init.sh Enhancements

#### 1a. expand `install_base_tools()`

Change the tools array from:
```bash
local tools=("curl" "wget" "vim" "unzip")
```
to:
```bash
local tools=("curl" "wget" "vim" "unzip" "htop" "net-tools" "lsof" "tree" "git")
```

Key decision: **do NOT fail** if any single package is unavailable on a given distro — the existing `log_warn` fallback handles this. On minimal containers some may not exist; the user will see a warning, not a crash.

Package name mapping (cross-distro):

| Tool | Debian/Ubuntu | CentOS/RHEL/Rocky/Alma |
|------|---------------|------------------------|
| htop | htop | htop |
| net-tools | net-tools | net-tools |
| lsof | lsof | lsof |
| tree | tree | tree |
| git | git | git |

No special repos (EPEL, universe) are required for these on any supported distro.

#### 1b. enhanced `setup_timezone()`

Current: non-interactive, hardcoded `Asia/Shanghai`.

Enhanced signature:
```bash
setup_timezone() {
    local timezone="${1:-Asia/Shanghai}"
    ...
}
```

The interactivity stays in `run_init()` / the wizard — the function itself takes a parameter. The wizard step will:

1. Show current timezone
2. Offer default `Asia/Shanghai`
3. Allow entering custom TZ (e.g., `America/New_York`, `Europe/London`)
4. Validate against `timedatectl list-timezones` (or `ls /usr/share/zoneinfo/` for systems without timedatectl)
5. Apply via `timedatectl set-timezone`

#### 1c. new `setup_ntp()`

```bash
setup_ntp() {
    # Auto-detect: chrony preferred, ntpd fallback
    # 1. Check if chrony or ntpd already installed+active → skip
    # 2. Install chrony if available (chrony recommended), else ntp
    # 3. Configure NTP servers:
    #    - chrony: /etc/chrony/chrony.conf → pool/pool.ntp.org iburst
    #    - ntp: /etc/ntp.conf → pool/pool.ntp.org iburst
    # 4. Start & enable service
    # 5. Wait for sync, show status (timedatectl timesync-status or ntpq -p)
}
```

Distribution detection:

| Distro | Preferred NTP | Fallback |
|--------|---------------|----------|
| Ubuntu 20.04+ | timesyncd (built-in systemd) + chrony | ntp |
| Debian 11+ | timesyncd + chrony | ntp |
| CentOS 7 | chrony | ntp |
| CentOS 8+/9 | chrony | ntp |
| Rocky/Alma 8+ | chrony | ntp |

**Note:** systemd-timesyncd is often already running on modern distros. If timesyncd is active and syncing, skip installation. Otherwise install chrony.

NTP server list (configurable):
```
pool 0.pool.ntp.org iburst
pool 1.pool.ntp.org iburst
pool 2.pool.ntp.org iburst
pool 3.pool.ntp.org iburst
```

Backup: backup `/etc/chrony/chrony.conf` or `/etc/ntp.conf` before modifying.

#### 1d. updated `run_init()`

**⚠️ Full-only**: `setup_ntp` and增强的交互式时区只走 Full 模式路径。Lite 模式的 `run_init()` 保持现有不变。

New call order in `run_init()` (Full mode):

```bash
run_init() {
    # ...
    init_directories
    if is_mode_full; then
        setup_timezone_prompt   # 交互式时区选择（含验证）
        setup_ntp                # NEW: NTP 时间同步
    else
        setup_timezone "Asia/Shanghai"  # Lite: 保持现有行为
    fi
    update_system_packages                # existing
    install_base_tools                    # expanded（Lite 4 个，Full 9 个）
    # swap 不走 init，由独立菜单项触发
    # ...
}
```

### 2. Swap Module: `scripts/base/swap.sh`

#### Constants

```bash
readonly SWAP_FILE_PATH="/swapfile"
# Swap size rules (in MB):
#   RAM < 2G  → SWAP = RAM
#   RAM 2-8G  → SWAP = 4096
#   RAM > 8G  → SWAP = 4096-8192 (interactive)
readonly SWAP_RAM_LOW_THRESHOLD=2048       # MB, < 2G
readonly SWAP_RAM_MED_THRESHOLD=8192       # MB, 2-8G
readonly SWAP_SIZE_LOW_MULTIPLIER=1        # swap = RAM * 1.0
readonly SWAP_SIZE_MED_VALUE=4096          # MB, fixed for 2-8G RAM
readonly SWAP_SIZE_HIGH_DEFAULT=4096       # MB default for >8G RAM
readonly SWAP_SIZE_HIGH_MAX=8192           # MB max for >8G RAM
readonly SWAPPINESS_VALUE=10
```

#### Internal Functions

1. `_get_total_ram_mb()` — read `/proc/meminfo` MemTotal, convert to MB
2. `_calculate_swap_size_mb(ram_mb)` — apply size rules, return recommended MB
3. `_get_current_swap_info()` — `swapon --show` or `free -m | awk '/Swap:/{print $2}'`

#### Public Functions

1. `check_swap_status()` — key=value for show_system_status()
   - Output: `swap_exists=yes|no`, `swap_size_mb=<N>`, `swap_file=<path>`, `swappiness=<N>`

2. `setup_swap()` — main entry point:
   - Check if swap already exists → skip if adequate (>= recommended)
   - If no swap or too small: create swap file
   - Set swappiness = 10 in `/etc/sysctl.d/99-swap.conf`
   - Add to `/etc/fstab` for persistence

3. `run_swap_wizard()` — interactive:
   - Show current swap status
   - Show recommended size
   - Confirm before creating
   - Report result

#### Swap Creation Details

```bash
dd if=/dev/zero of="${SWAP_FILE_PATH}" bs=1M count=<size_mb>
chmod 600 "${SWAP_FILE_PATH}"
mkswap "${SWAP_FILE_PATH}"
swapon "${SWAP_FILE_PATH}"
echo "${SWAP_FILE_PATH} none swap sw 0 0" >> /etc/fstab
```

Backup fstab before modifying. Check for existing swapfile entry in fstab.

### 3. Integration into install.sh

#### ⚠️ Full-Only 集成原则

- `scripts/base/swap.sh` **只**在 Full 模式下 source（通过 mode.sh 的模块列表 + load_dependencies 中的条件判断）
- Lite 模式的 `load_dependencies` 不加载 swap.sh，不触发任何 NTP/swap 相关代码
- install.sh 菜单中 NTP/Swap 不新增菜单项，但 Full 模式下状态检测需要显示 NTP/Swap 状态

#### load_dependencies() — add swap.sh (Full only)

```bash
# After loading init.sh, swap.sh, etc.
if is_mode_full && [[ ! -f "${base_dir}/swap.sh" ]]; then
    echo "Error: Cannot find swap.sh at ${base_dir}/swap.sh"
    exit 1
fi
if is_mode_full; then
    source "${base_dir}/swap.sh"
fi
```

#### Full wizard init step expansion

The `run_full_wizard()` Step 0 currently calls `run_init()`. With the enhancements, `run_init()` already covers NTP + base tools, so no additional wizard steps are needed. The init step automatically picks up the new functionality.

However, the wizard should offer per-substep interactivity if the user wants to customize timezone or NTP servers. Since the PRD says "交互式选择时区", we should add a prompt in the wizard:

```bash
# In run_full_wizard(), Step 0:
if confirm "设置时区？(y/N)" "n"; then
    prompt "输入时区 [Asia/Shanghai]:" tz_input
    setup_timezone "${tz_input:-Asia/Shanghai}"
fi
# NTP setup runs automatically as part of init
# Swap setup runs automatically as part of init
```

#### Status integration

Add swap status to `show_system_status()` in a lightweight way — similar to how other base features are shown. Since swap is a base feature (not a security module), it should appear in the status but doesn't need a menu item.

NTP status can be checked via `timedatectl show` — show whether NTP is active.

### 4. i18n Key Inventory

#### NTP Keys (~15 keys for zh.sh, ~15 for en.sh)

```
MSG_NTP_TITLE              # NTP 时间同步
MSG_NTP_SETTING            # 正在配置 NTP 时间同步...
MSG_NTP_DETECTING          # 正在检测 NTP 服务...
MSG_NTP_INSTALL_CHRONY     # 正在安装 chrony...
MSG_NTP_INSTALL_NTPD       # 正在安装 ntpd...
MSG_NTP_INSTALL_DONE       # NTP 服务安装完成
MSG_NTP_ALREADY_SYNCED     # NTP 时间已同步，跳过安装
MSG_NTP_CONFIG             # 正在配置 NTP 服务器...
MSG_NTP_CONFIG_DONE        # NTP 配置完成
MSG_NTP_SERVICE_START      # 正在启动 NTP 服务...
MSG_NTP_SERVICE_DONE       # NTP 服务已启动
MSG_NTP_STATUS_SYNCED      # 已同步
MSG_NTP_STATUS_UNSYNCED    # 未同步
MSG_NTP_BACKUP_CONF        # 备份 NTP 配置文件
MSG_NTP_TZ_PROMPT          # 请输入时区（留空使用 Asia/Shanghai）
MSG_NTP_TZ_INVALID         # 时区无效，请重新输入
MSG_NTP_SYNC_NOW           # 正在同步时间...
MSG_NTP_SYNC_DONE          # 时间同步完成
MSG_NTP_SYNC_FAIL          # 时间同步失败
```

#### Swap Keys (~15 keys for zh.sh, ~15 for en.sh)

```
MSG_SWAP_TITLE             # Swap 配置
MSG_SWAP_CHECKING          # 正在检测 Swap 状态...
MSG_SWAP_EXISTS            # Swap 已存在
MSG_SWAP_SIZE              # Swap 大小
MSG_SWAP_NO_SWAP           # 未配置 Swap
MSG_SWAP_RECOMMENDED       # 推荐 Swap 大小
MSG_SWAP_CREATING          # 正在创建 Swap 文件...
MSG_SWAP_CREATE_DONE       # Swap 文件创建完成
MSG_SWAP_CREATE_FAIL       # Swap 文件创建失败
MSG_SWAP_ENABLING          # 正在启用 Swap...
MSG_SWAP_ENABLE_DONE       # Swap 已启用
MSG_SWAP_ENABLE_FAIL       # Swap 启用失败
MSG_SWAP_SWAPPINESS        # 设置 swappiness
MSG_SWAP_SWAPPINESS_DONE   # swappiness 已设置为 10
MSG_SWAP_FSTAB_ADD         # 添加 Swap 到 /etc/fstab
MSG_SWAP_FSTAB_DONE        # Swap 已添加到 fstab
MSG_SWAP_CONFIRM_CREATE    # 确认创建 Swap 文件？
MSG_SWAP_SKIP              # 跳过 Swap 配置
MSG_SWAP_DONE              # Swap 配置完成
```

### 5. Report Integration

In `generate_report()` in `report.sh`, add after the init section:

```bash
# NTP
if command -v chronyc &>/dev/null; then
    local ntp_sync
    ntp_sync=$(chronyc tracking 2>/dev/null | grep -c "Leap.*Normal" || echo "0")
    echo "  - ${MSG_NTP_STATUS}: $([ "${ntp_sync}" -gt 0 ] && echo "${MSG_NTP_STATUS_SYNCED}" || echo "${MSG_NTP_STATUS_UNSYNCED}")"
fi

# Swap
echo "  - ${MSG_SWAP_TITLE}: $(free -m | awk '/Swap:/{print $2" MB"}' || echo "${MSG_SWAP_NO_SWAP}")"
```

### 6. Test Plan

#### init.bats (~20 test cases)

1. **Constants tests** (2-3):
   - Verify expanded tools list includes all 9 tools
   - Verify each tool name appears in the array

2. **Function existence** (3-4):
   - `setup_ntp` function exists
   - Enhanced `setup_timezone` still exists

3. **Behavior tests** (10-12):
   - `setup_ntp` skips if NTP already synced (mock timedatectl)
   - `setup_ntp` installs chrony on Ubuntu (mock pkg_manager)
   - `setup_ntp` installs chrony on CentOS
   - `setup_ntp` configuration file backup
   - `install_base_tools` includes all 9 tools in apt call
   - `install_base_tools` includes all 9 tools in dnf call
   - `install_base_tools` includes all 9 tools in yum call
   - `setup_timezone` validates timezone
   - `run_init` calls setup_ntp
   - `run_init` calls setup_timezone

4. **Output tests** (2-3):
   - Function output contains expected strings

#### swap.bats (~18 test cases)

1. **Constants tests** (4-5):
   - SWAP_FILE_PATH is `/swapfile`
   - SWAP_RAM_LOW_THRESHOLD = 2048
   - SWAP_SIZE_MED_VALUE = 4096
   - SWAPPINESS_VALUE = 10

2. **Source guard** (1):
   - `_SWAP_LOADED` is `1`

3. **Function existence** (5):
   - `_get_total_ram_mb` exists
   - `_calculate_swap_size_mb` exists
   - `check_swap_status` exists
   - `setup_swap` exists
   - `run_swap_wizard` exists

4. **Logic tests** (6-8):
   - `_calculate_swap_size_mb` returns RAM for RAM < 2G (e.g., 1024 → 1024)
   - `_calculate_swap_size_mb` returns 4096 for RAM 2-8G (e.g., 4096 → 4096)
   - `_calculate_swap_size_mb` returns 4096 for RAM > 8G (e.g., 16384 → 4096)
   - `check_swap_status` outputs `swap_exists=` key
   - `check_swap_status` outputs `swap_size_mb=` key

5. **Output tests** (2-3):
   - Verify log output on success/failure

### 7. Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| `htop` / `net-tools` / `lsof` / `tree` / `git` not available on minimal containers | Medium | Existing `log_warn` fallback; each tool installed individually within the same case block |
| `chrony` not available on very old CentOS 7 (default is ntp) | Low | Fallback to ntp package; detect at runtime |
| `swapon` / `swapoff` not available | Very Low | Docker containers — skip swap creation gracefully |
| Swap file on systems with very low disk space | Low | Check available disk space before creating; warn if < 2x swap size |
| `timesyncd` conflicts with chrony | Low | Detect running NTP service before installing; don't install chrony if timesyncd is active and syncing |
| Interactive timezone selection requires `timedatectl` | Low | Fallback to `ls /usr/share/zoneinfo/`; show error if neither available |

### 8. Implementation Order

```
Phase 1: init.sh enhancements (no dependencies)
  1a. Expand install_base_tools() array
  1b. Add setup_ntp() function
  1c. Enhance setup_timezone() interactivity
  1d. Update run_init() call order
  → Validate: shellcheck -x scripts/base/init.sh

Phase 2: swap.sh (depends on understanding init pattern, no code dependency)
  2a. Create scripts/base/swap.sh with all functions
  2b. Validate: shellcheck -x scripts/base/swap.sh

Phase 3: i18n (depends on function names from Phase 1 & 2)
  3a. Add MSG_NTP_* keys to zh.sh and en.sh
  3b. Add MSG_SWAP_* keys to zh.sh and en.sh
  → Validate: grep counts match expected key counts

Phase 4: Integration (depends on Phase 1-3)
  4a. Load swap.sh in install.sh load_dependencies()
  4b. Expand full wizard init step with timezone prompt
  4c. Add swap + NTP status sections in show_system_status()
  4d. Add swap + NTP detail lines in report.sh generate_report()
  → Validate: shellcheck -x install.sh, shellcheck -x scripts/base/report.sh

Phase 5: Tests (depends on Phase 1, 2)
  5a. Write tests/unit/init.bats (~20 cases)
  5b. Write tests/unit/swap.bats (~18 cases)
  → Validate: bats tests/unit/init.bats, bats tests/unit/swap.bats

Phase 6: Documentation
  6a. Check HANDOVER.md for changes
```

### 9. Acceptance Criteria

- [x] `install_base_tools()` installs htop, net-tools, lsof, tree, git in addition to existing 4 tools
- [x] `setup_ntp()` detects existing NTP, installs chrony or ntp, configures servers, starts service
- [x] `setup_timezone()` accepts custom timezone parameter and validates it
- [x] `scripts/base/swap.sh` created with all internal and public functions
- [x] `setup_swap()` detects current swap, creates swap file per size rules, sets swappiness=10
- [x] i18n keys added for zh.sh and en.sh (~30 keys each)
- [x] Full-wizard Step 0 includes timezone interaction option
- [x] Report includes NTP sync status and swap info
- [x] init.bats passes (~20 test cases)
- [x] swap.bats passes (~18 test cases)
- [x] ShellCheck passes on all modified files
- [x] All existing tests still pass

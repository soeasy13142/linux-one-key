# Batch 5a：备份/回滚中心 + 安全仪表盘 — 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 linux-one-key 增加两个 Full-only 一级菜单——[17] 备份/回滚中心与 [18] 安全仪表盘，复用并增强已有 backup/rollback 基础设施，新增每模块多检查项安全评分。

**Architecture:** 新增 `scripts/base/backup_center.sh`（编排逻辑，无交互，可 Bats 测试）与 `scripts/base/dashboard.sh`（评分+渲染）。`backup.sh` 的 `backup_file` 增加 `.meta` sidecar 记录原始绝对路径（恢复无需模块注册表）；`restore_file` 支持从 `.meta` 解析目标路径。install.sh 只加薄菜单处理。所有新功能以 `is_mode_full` 包裹（Full-only）。

**Tech Stack:** Bash 5.x、ShellCheck、Bats-core。

## Global Constraints

- Shell header：`#!/usr/bin/env bash`；`backup.sh`/`rollback.sh` 沿用各自现有 header（`set -eo pipefail`，无 `-u`）；新文件 `backup_center.sh`/`dashboard.sh` 用 `set -eo pipefail`。
- 命名：函数 `snake_case`，常量 `UPPER_SNAKE_CASE`。
- i18n：用户可见文本一律用 `MSG_*` 变量（`scripts/lang/`），不硬编码中英文。
- 输出：使用 `utils.sh` 的 `log_info/success/warn/error`；菜单渲染沿用现有 `echo -e` 风格。
- 修改配置文件前必须备份；恢复操作双重确认。
- 新增函数必须配 Bats 测试；TDD：先写测试（RED）→ 最小实现（GREEN）→ 提交。
- 所有新功能 Full-only：菜单项用 `is_mode_full`/`is_mode_lite` 门控，不进入 `MODE_*_MODULES`（编排/呈现层，非向导模块）。
- 提交：conventional commit（`feat:`/`test:`/`docs:`），不 push。
- 运行测试：`bats tests/unit/<file>.bats`；全量 `bats tests/unit/*.bats`；静态 `shellcheck -x scripts/base/*.sh install.sh`。

---

### Task 1: backup.sh — `.meta` sidecar + restore_file 目标解析

**Files:**
- Modify: `scripts/base/backup.sh`（`backup_file()`、`restore_file()`）
- Test: `tests/unit/backup.bats`（追加用例）

**Interfaces:**
- Consumes: `log_*`（utils.sh）、`BACKUP_DIR`、`MSG_*`（lang，运行时解析）
- Produces: `backup_file(file, description)` 返回 backup_path（不变），额外写 `${backup_path}.meta`；`restore_file(backup_path, target_path="", description)` 在 `target_path` 为空时从 `.meta` 解析目标。

- [ ] **Step 1: 在 `tests/unit/backup.bats` 末尾追加失败测试**

```bash
# ── .meta sidecar & restore target resolution ──

@test "backup_file writes .meta sidecar with original path" {
    local test_file="${TEST_DIR}/test.conf"
    echo "content" > "${test_file}"

    run backup_file "${test_file}"
    [[ "${status}" -eq 0 ]]

    local backup_path="${output}"
    [[ -f "${backup_path}.meta" ]]
    [[ "$(cat "${backup_path}.meta")" == "${test_file}" ]]
}

@test "restore_file restores via .meta when target omitted" {
    local test_file="${TEST_DIR}/test.conf"
    echo "original" > "${test_file}"

    run backup_file "${test_file}"
    local backup_path="${output}"

    echo "modified" > "${test_file}"

    run restore_file "${backup_path}"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${test_file}")" == "original" ]]
}

@test "restore_file rejects relative path from .meta" {
    local test_file="${TEST_DIR}/test.conf"
    echo "content" > "${test_file}"

    run backup_file "${test_file}"
    local backup_path="${output}"

    echo "relative/path" > "${backup_path}.meta"

    run restore_file "${backup_path}"
    [[ "${status}" -ne 0 ]]
}

@test "restore_file errors when no meta and no explicit target" {
    local backup="${TEST_DIR}/orphan.conf"
    echo "content" > "${backup}"

    run restore_file "${backup}"
    [[ "${status}" -ne 0 ]]
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `bats tests/unit/backup.bats`
Expected: 新 4 个用例 FAIL（`.meta` 不存在 / restore 报错逻辑缺失）。

- [ ] **Step 3: 实现 `backup_file` 写 meta**

在 `scripts/base/backup.sh` 的 `backup_file()` 中，`cp -a` 成功后、`echo "${backup_path}"` 之前插入：

```bash
    # 记录原始绝对路径到 sidecar，供备份中心按原始路径恢复（写失败不阻断备份）
    echo "${file}" > "${backup_path}.meta" 2>/dev/null || true
```

- [ ] **Step 4: 实现 `restore_file` 目标解析**

将 `scripts/base/backup.sh` 的 `restore_file()` 开头改为：

```bash
restore_file() {
    local backup_path="$1"
    local target_path="${2:-}"
    local description="${3:-${MSG_LOG_RESTORE}}"

    if [[ ! -f "${backup_path}" ]]; then
        log_error "${MSG_ERROR_FILE_NOT_FOUND}: ${backup_path}"
        return 1
    fi

    # 目标未显式给出时，从 .meta sidecar 解析原始路径
    if [[ -z "${target_path}" ]]; then
        if [[ -f "${backup_path}.meta" ]]; then
            target_path="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
            # 安全：meta 必须是绝对路径
            if [[ -z "${target_path}" ]] || [[ "${target_path}" != /* ]]; then
                log_error "${MSG_ERROR_RESTORE_TARGET_REQUIRED}"
                return 1
            fi
        else
            log_error "${MSG_ERROR_RESTORE_TARGET_REQUIRED}"
            return 1
        fi
    fi

    log_step "${description}: ${target_path}"
```

- [ ] **Step 5: 运行测试确认通过**

Run: `bats tests/unit/backup.bats`
Expected: 全部通过（含原有用例，backward compatible）。

- [ ] **Step 6: 提交**

```bash
git add scripts/base/backup.sh tests/unit/backup.bats
git commit -m "feat: record original path in backup .meta sidecar for meta-driven restore"
```

---

### Task 2: backup.sh — list_backups / get_backup_target / clean_old_backups

**Files:**
- Modify: `scripts/base/backup.sh`（追加 3 个函数）
- Test: `tests/unit/backup.bats`（追加用例）

**Interfaces:**
- Consumes: `BACKUP_DIR`
- Produces:
  - `list_backups()` — 输出 `$BACKUP_DIR` 下所有 `*.bak.*`（排除 `.meta`），按文件名倒序（TIMESTAMP 主导），无备份时无输出
  - `get_backup_target(backup_path)` — 输出 `.meta` 内容；无 meta 返回 1
  - `clean_old_backups(keep_per_name=5)` — 按 basename 前缀分组，每组保留最新 N 份（含其 `.meta`），删除更旧；仅操作 `$BACKUP_DIR` 内文件

- [ ] **Step 1: 追加失败测试**

```bash
# ── list_backups / get_backup_target / clean_old_backups ──

@test "list_backups excludes .meta and newest first" {
    local f1="${BACKUP_DIR}/test.conf.bak.20260101100000.1.1"
    local f2="${BACKUP_DIR}/test.conf.bak.20260102100000.2.2"
    echo "a" > "${f1}"; echo "b" > "${f2}"
    echo "/etc/test.conf" > "${f1}.meta"; echo "/etc/test.conf" > "${f2}.meta"

    run list_backups
    [[ "${status}" -eq 0 ]]
    [[ "$(echo "${output}" | head -1)" == "${f2}" ]]
    [[ "$(echo "${output}" | wc -l | tr -d ' ')" == "2" ]]
}

@test "list_backups returns empty when no backups" {
    run list_backups
    [[ "${status}" -eq 0 ]]
    [[ -z "${output}" ]]
}

@test "get_backup_target reads meta" {
    local f1="${BACKUP_DIR}/test.conf.bak.20260101100000.1.1"
    echo "x" > "${f1}"; echo "/etc/test.conf" > "${f1}.meta"
    run get_backup_target "${f1}"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "/etc/test.conf" ]]
}

@test "get_backup_target errors without meta" {
    local f1="${BACKUP_DIR}/test.conf.bak.20260101100000.1.1"
    echo "x" > "${f1}"
    run get_backup_target "${f1}"
    [[ "${status}" -ne 0 ]]
}

@test "clean_old_backups keeps latest N per name" {
    local name="test.conf"
    for i in 1 2 3 4 5 6; do
        echo "v${i}" > "${BACKUP_DIR}/${name}.bak.2026010${i}00000.${i}.${i}"
        echo "/etc/${name}" > "${BACKUP_DIR}/${name}.bak.2026010${i}00000.${i}.${i}.meta"
    done

    run clean_old_backups 3
    [[ "${status}" -eq 0 ]]
    [[ "$(ls "${BACKUP_DIR}"/${name}.bak.* 2>/dev/null | grep -v meta | wc -l | tr -d ' ')" == "3" ]]
}

@test "clean_old_backups never touches newest backup" {
    local name="test.conf"
    echo "v1" > "${BACKUP_DIR}/${name}.bak.20260101000000.1.1"
    echo "v2" > "${BACKUP_DIR}/${name}.bak.20260102000000.2.2"
    echo "/etc/${name}" > "${BACKUP_DIR}/${name}.bak.20260102000000.2.2.meta"

    run clean_old_backups 1
    [[ "${status}" -eq 0 ]]
    [[ -f "${BACKUP_DIR}/${name}.bak.20260102000000.2.2" ]]
    [[ ! -f "${BACKUP_DIR}/${name}.bak.20260101000000.1.1" ]]
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `bats tests/unit/backup.bats`
Expected: 新 6 个用例 FAIL（函数未定义）。

- [ ] **Step 3: 在 backup.sh 追加实现（末尾、`log_debug` 之前）**

```bash
# 列出备份目录下所有备份文件（排除 .meta），按文件名倒序（TIMESTAMP 主导）
list_backups() {
    local backup_path
    local -a files=()
    [[ -d "${BACKUP_DIR}" ]] || return 0
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        files+=("${backup_path}")
    done
    [[ ${#files[@]} -eq 0 ]] && return 0
    printf '%s\n' "${files[@]}" | sort -r
}

# 读取备份的原始目标路径（.meta sidecar）
get_backup_target() {
    local backup_path="$1"
    if [[ ! -f "${backup_path}.meta" ]]; then
        return 1
    fi
    cat "${backup_path}.meta"
}

# 按 basename 前缀分组清理：每组保留最新 N 份（含 .meta），删除更旧
clean_old_backups() {
    local keep_per_name="${1:-5}"
    local backup_path base name file
    local -a names=() group=()
    [[ -d "${BACKUP_DIR}" ]] || return 0

    # 收集去重的文件名前缀
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        base="$(basename "${backup_path}")"
        name="${base%%.bak.*}"
        if ! printf '%s\n' "${names[@]}" | grep -qx "${name}"; then
            names+=("${name}")
        fi
    done

    for name in "${names[@]}"; do
        group=()
        for file in "${BACKUP_DIR}"/"${name}".bak.*; do
            [[ -f "${file}" ]] || continue
            [[ "${file}" != *.meta ]] || continue
            group+=("${file}")
        done
        local sorted=()
        while IFS= read -r file; do
            sorted+=("${file}")
        done < <(printf '%s\n' "${group[@]}" | sort -r)
        local idx=0
        for file in "${sorted[@]}"; do
            idx=$((idx + 1))
            if [[ "${idx}" -gt "${keep_per_name}" ]]; then
                rm -f "${file}" "${file}.meta"
                log_debug "Cleaned old backup: ${file}"
            fi
        done
    done
    return 0
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `bats tests/unit/backup.bats`
Expected: 全部通过。

- [ ] **Step 5: 提交**

```bash
git add scripts/base/backup.sh tests/unit/backup.bats
git commit -m "feat: add backup listing, target lookup and retention cleanup"
```

---

### Task 3: rollback.sh — rollback_timer_status()

**Files:**
- Modify: `scripts/base/rollback.sh`（追加函数）
- Test: `tests/unit/rollback.bats`（追加用例）

**Interfaces:**
- Consumes: `ROLLBACK_PID`/`_SCHEDULED_PID`（可能未设置）
- Produces: `rollback_timer_status()` — 有存活回滚任务时输出 PID 且返回 0；否则输出 `none` 返回 1

- [ ] **Step 1: 追加失败测试**

```bash
# ── rollback_timer_status ──

@test "rollback_timer_status returns none without timer" {
    unset ROLLBACK_PID _SCHEDULED_PID 2>/dev/null || true
    run rollback_timer_status
    [[ "${status}" -ne 0 ]]
    [[ "${output}" == "none" ]]
}

@test "rollback_timer_status detects live sleep task" {
    unset ROLLBACK_PID _SCHEDULED_PID 2>/dev/null || true
    sleep 30 &
    local pid=$!
    ROLLBACK_PID="${pid}"
    run rollback_timer_status
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${pid}" ]]
    kill "${pid}" 2>/dev/null || true
}

@test "rollback_timer_status ignores dead pid" {
    unset ROLLBACK_PID _SCHEDULED_PID 2>/dev/null || true
    sleep 0.1 &
    local pid=$!
    ROLLBACK_PID="${pid}"
    wait "${pid}" 2>/dev/null || true
    run rollback_timer_status
    [[ "${status}" -ne 0 ]]
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `bats tests/unit/rollback.bats`
Expected: 新 3 个用例 FAIL（函数未定义）。

- [ ] **Step 3: 在 rollback.sh 末尾（`log_debug` 之前）追加实现**

```bash
# 只读查询：是否存在待执行的延时回滚任务
# 输出：存活 PID（存在）或 "none"（不存在）；退出码 0=存在 1=不存在
rollback_timer_status() {
    local pid
    pid="${ROLLBACK_PID:-${_SCHEDULED_PID:-}}"
    if [[ -n "${pid}" ]] && kill -0 "${pid}" 2>/dev/null; then
        local cmdline
        cmdline=$(tr '\0' ' ' < "/proc/${pid}/cmdline" 2>/dev/null || echo "")
        if [[ "${cmdline}" == *"sleep"* ]] || [[ -z "${cmdline}" ]]; then
            echo "${pid}"
            return 0
        fi
    fi
    echo "none"
    return 1
}
```

- [ ] **Step 4: 运行测试确认通过**

Run: `bats tests/unit/rollback.bats`
Expected: 全部通过。

- [ ] **Step 5: 提交**

```bash
git add scripts/base/rollback.sh tests/unit/rollback.bats
git commit -m "feat: add read-only rollback timer status query"
```

---

### Task 4: i18n — 新增 MSG_* 键（zh + en）

**Files:**
- Modify: `scripts/lang/zh.sh`、`scripts/lang/en.sh`
- Test: `tests/unit/menu.bats`（追加结构性断言）

**Interfaces:**
- Produces: 下述全部 `MSG_*` 键，供 Task 5/6/7 引用。

- [ ] **Step 1: 在 zh.sh 追加键**

在 `scripts/lang/zh.sh` 中追加（位置不限，建议在 `MSG_SECTION_SERVER` 附近）：

```bash
# ── Batch 5a: 备份/回滚中心 + 仪表盘 ──
MSG_SECTION_OPS="────── 运维工具 ──────"
MSG_MAIN_MENU_BACKUP_CENTER="[17] 备份与回滚中心"
MSG_MAIN_MENU_BACKUP_CENTER_DESC="备份历史浏览、一键恢复、回滚定时器管理"
MSG_MAIN_MENU_DASHBOARD="[18] 安全仪表盘"
MSG_MAIN_MENU_DASHBOARD_DESC="多模块 CIS 合规评分与风险等级"
MSG_ERROR_RESTORE_TARGET_REQUIRED="恢复失败：缺少目标路径（无 .meta 元数据）"
MSG_BACKUP_CENTER_TITLE="备份与回滚中心"
MSG_BACKUP_CENTER_MENU_LIST="1. 查看备份历史"
MSG_BACKUP_CENTER_MENU_RESTORE="2. 一键恢复模块"
MSG_BACKUP_CENTER_MENU_ROLLBACK="3. SSH 回滚定时器"
MSG_BACKUP_CENTER_MENU_CLEAN="4. 清理旧备份"
MSG_BACKUP_CENTER_MENU_BACK="0. 返回主菜单"
MSG_BACKUP_CENTER_HISTORY_TITLE="备份历史（按模块分组）"
MSG_BACKUP_CENTER_NO_BACKUPS="暂无备份，尚未执行任何加固操作？"
MSG_BACKUP_CENTER_SELECT_MODULE="请选择要恢复的模块"
MSG_BACKUP_CENTER_NO_RESTORABLE="该模块没有可恢复的备份"
MSG_BACKUP_CENTER_CONFIRM_RESTORE="将恢复以下文件的最新备份，此操作不可撤销"
MSG_BACKUP_CENTER_CONFIRM_PROMPT="确认恢复？(y/N)"
MSG_BACKUP_CENTER_RESTORED="模块已恢复"
MSG_BACKUP_CENTER_RESTORE_ABORTED="已取消恢复"
MSG_BACKUP_CENTER_RESTORE_SYSCTL="内核参数已恢复，正在重新加载 sysctl..."
MSG_BACKUP_CENTER_RESTORE_SSH_HINT="SSH 配置已恢复，请立即在新端口测试连接；若无法连接请检查系统"
MSG_BACKUP_CENTER_ROLLBACK_NONE="当前没有待执行的 SSH 回滚定时器"
MSG_BACKUP_CENTER_ROLLBACK_PENDING="存在待执行的 SSH 回滚定时器 (PID %s)"
MSG_BACKUP_CENTER_ROLLBACK_CANCEL="已取消回滚定时器"
MSG_BACKUP_CENTER_ROLLBACK_NO_PID="无可取消的回滚定时器"
MSG_BACKUP_CENTER_CLEAN_CONFIRM="将删除超出保留策略的旧备份，确认？(y/N)"
MSG_BACKUP_CENTER_CLEAN_DONE="旧备份清理完成"
MSG_BACKUP_CENTER_CLEAN_EMPTY="没有需要清理的备份"
MSG_DASHBOARD_TITLE="安全仪表盘"
MSG_DASHBOARD_TOTAL="总分"
MSG_DASHBOARD_RISK="风险等级"
MSG_DASHBOARD_RISK_LOW="低 (Low)"
MSG_DASHBOARD_RISK_MEDIUM="中 (Medium)"
MSG_DASHBOARD_RISK_HIGH="高 (High)"
MSG_DASHBOARD_RISK_CRITICAL="严重 (Critical)"
```

> 注：模块检查项描述不单独维护 i18n 键，直接以检查项 id 展示在 `dashboard.sh`（见 Task 6），避免翻译维护成本。

- [ ] **Step 2: 在 en.sh 追加键**

```bash
# ── Batch 5a: Backup/Rollback Center + Dashboard ──
MSG_SECTION_OPS="────── Operations ──────"
MSG_MAIN_MENU_BACKUP_CENTER="[17] Backup & Rollback Center"
MSG_MAIN_MENU_BACKUP_CENTER_DESC="Browse backups, one-key restore, rollback timer management"
MSG_MAIN_MENU_DASHBOARD="[18] Security Dashboard"
MSG_MAIN_MENU_DASHBOARD_DESC="Multi-module CIS compliance scoring and risk level"
MSG_ERROR_RESTORE_TARGET_REQUIRED="Restore failed: target path missing (no .meta metadata)"
MSG_BACKUP_CENTER_TITLE="Backup & Rollback Center"
MSG_BACKUP_CENTER_MENU_LIST="1. View backup history"
MSG_BACKUP_CENTER_MENU_RESTORE="2. Restore module"
MSG_BACKUP_CENTER_MENU_ROLLBACK="3. SSH rollback timer"
MSG_BACKUP_CENTER_MENU_CLEAN="4. Clean old backups"
MSG_BACKUP_CENTER_MENU_BACK="0. Back to main menu"
MSG_BACKUP_CENTER_HISTORY_TITLE="Backup history (grouped by module)"
MSG_BACKUP_CENTER_NO_BACKUPS="No backups found — nothing hardened yet?"
MSG_BACKUP_CENTER_SELECT_MODULE="Select module to restore"
MSG_BACKUP_CENTER_NO_RESTORABLE="No restorable backups for this module"
MSG_BACKUP_CENTER_CONFIRM_RESTORE="The latest backup of each file below will be restored. This cannot be undone."
MSG_BACKUP_CENTER_CONFIRM_PROMPT="Confirm restore? (y/N)"
MSG_BACKUP_CENTER_RESTORED="Module restored"
MSG_BACKUP_CENTER_RESTORE_ABORTED="Restore cancelled"
MSG_BACKUP_CENTER_RESTORE_SYSCTL="Kernel params restored, reloading sysctl..."
MSG_BACKUP_CENTER_RESTORE_SSH_HINT="SSH config restored. Test the new port connection immediately; if unreachable, check the system."
MSG_BACKUP_CENTER_ROLLBACK_NONE="No SSH rollback timer pending"
MSG_BACKUP_CENTER_ROLLBACK_PENDING="SSH rollback timer pending (PID %s)"
MSG_BACKUP_CENTER_ROLLBACK_CANCEL="Rollback timer cancelled"
MSG_BACKUP_CENTER_ROLLBACK_NO_PID="No rollback timer to cancel"
MSG_BACKUP_CENTER_CLEAN_CONFIRM="Old backups beyond retention will be deleted. Confirm? (y/N)"
MSG_BACKUP_CENTER_CLEAN_DONE="Old backups cleaned"
MSG_BACKUP_CENTER_CLEAN_EMPTY="Nothing to clean"
MSG_DASHBOARD_TITLE="Security Dashboard"
MSG_DASHBOARD_TOTAL="Total"
MSG_DASHBOARD_RISK="Risk"
MSG_DASHBOARD_RISK_LOW="Low"
MSG_DASHBOARD_RISK_MEDIUM="Medium"
MSG_DASHBOARD_RISK_HIGH="High"
MSG_DASHBOARD_RISK_CRITICAL="Critical"
```

- [ ] **Step 3: 追加结构性测试到 menu.bats**

```bash
@test "zh.sh has Batch 5a menu + backup center keys" {
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    [[ -n "${MSG_MAIN_MENU_BACKUP_CENTER:-}" ]]
    [[ -n "${MSG_MAIN_MENU_DASHBOARD:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_TITLE:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_MENU_LIST:-}" ]]
    [[ -n "${MSG_BACKUP_CENTER_MENU_BACK:-}" ]]
    [[ -n "${MSG_ERROR_RESTORE_TARGET_REQUIRED:-}" ]]
}

@test "zh.sh has dashboard keys" {
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"
    [[ -n "${MSG_DASHBOARD_TITLE:-}" ]]
    [[ -n "${MSG_DASHBOARD_RISK_LOW:-}" ]]
    [[ -n "${MSG_DASHBOARD_RISK_CRITICAL:-}" ]]
}
```

> 注：menu.bats 现有 `setup()` 已 `source utils.sh && load_lang`，上述测试内的 source 为幂等，直接断言即可。

- [ ] **Step 4: 运行测试确认通过**

Run: `bats tests/unit/menu.bats`
Expected: 新用例通过；全文件回归通过。

- [ ] **Step 5: 提交**

```bash
git add scripts/lang/zh.sh scripts/lang/en.sh tests/unit/menu.bats
git commit -m "feat: add Batch 5a i18n keys (backup center + dashboard)"
```

---

### Task 5: backup_center.sh — 编排逻辑（新文件）

**Files:**
- Create: `scripts/base/backup_center.sh`
- Test: `tests/unit/backup-center.bats`（新建）

**Interfaces:**
- Consumes: `BACKUP_DIR`、`restore_file`、`log_*`、`MSG_BACKUP_CENTER_*`
- Produces:
  - `backup_center_module_of_path(path)` — 按路径前缀输出模块组名（ssh/kernel/firewall/fail2ban/audit/clamav/aide/autoupdate/init/swap/other）
  - `backup_center_list_modules()` — 输出有备份的模块组（去重）
  - `backup_center_latest_for_target(target)` — 输出该目标路径最新备份；无则返回 1
  - `backup_center_restore_module(module)` — 对模块下每个目标文件恢复其最新备份；全部成功返回 0
  - `backup_center_post_restore(backup_path)` — 按目标路径执行恢复后钩子（kernel → `sysctl --system`；SSH → 提示；firewall → reload）

- [ ] **Step 1: 创建失败测试 `tests/unit/backup-center.bats`**

```bash
#!/usr/bin/env bats
# backup-center.bats - 单元测试 for scripts/base/backup_center.sh

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"
    if ! type backup_center_module_of_path &>/dev/null; then
        source "${SCRIPT_DIR}/scripts/base/backup_center.sh"
    fi
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "backup_center_module_of_path groups by path prefix" {
    [[ "$(backup_center_module_of_path "/etc/ssh/sshd_config")" == "ssh" ]]
    [[ "$(backup_center_module_of_path "/etc/sysctl.d/99-hardening.conf")" == "kernel" ]]
    [[ "$(backup_center_module_of_path "/etc/ufw/user.rules")" == "firewall" ]]
    [[ "$(backup_center_module_of_path "/etc/fail2ban/jail.local")" == "fail2ban" ]]
    [[ "$(backup_center_module_of_path "/etc/unknown.conf")" == "other" ]]
}

@test "backup_center_list_modules dedups and lists groups" {
    local f1="${BACKUP_DIR}/sshd_config.bak.20260101000000.1.1"
    local f2="${BACKUP_DIR}/sshd_config.bak.20260102000000.2.2"
    local f3="${BACKUP_DIR}/99-hardening.conf.bak.20260101000000.3.3"
    echo "a" > "${f1}"; echo "/etc/ssh/sshd_config" > "${f1}.meta"
    echo "b" > "${f2}"; echo "/etc/ssh/sshd_config" > "${f2}.meta"
    echo "c" > "${f3}"; echo "/etc/sysctl.d/99-hardening.conf" > "${f3}.meta"

    run backup_center_list_modules
    [[ "${status}" -eq 0 ]]
    [[ "$(echo "${output}" | sort | tr '\n' ' ')" == "kernel ssh " ]]
}

@test "backup_center_list_modules empty without backups" {
    run backup_center_list_modules
    [[ "${status}" -eq 0 ]]
    [[ -z "${output}" ]]
}

@test "backup_center_latest_for_target returns newest backup" {
    local f1="${BACKUP_DIR}/sshd_config.bak.20260101000000.1.1"
    local f2="${BACKUP_DIR}/sshd_config.bak.20260102000000.2.2"
    echo "a" > "${f1}"; echo "/etc/ssh/sshd_config" > "${f1}.meta"
    echo "b" > "${f2}"; echo "/etc/ssh/sshd_config" > "${f2}.meta"

    run backup_center_latest_for_target "/etc/ssh/sshd_config"
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "${f2}" ]]
}

@test "backup_center_restore_module restores each target from latest backup" {
    local ssh1="${BACKUP_DIR}/sshd_config.bak.20260101000000.1.1"
    local ssh2="${BACKUP_DIR}/sshd_config.bak.20260102000000.2.2"
    local kern="${BACKUP_DIR}/99-hardening.conf.bak.20260101000000.3.3"
    mkdir -p "${TEST_DIR}/etc/ssh"
    echo "old" > "${ssh1}"; echo "${TEST_DIR}/etc/ssh/sshd_config" > "${ssh1}.meta"
    echo "newest" > "${ssh2}"; echo "${TEST_DIR}/etc/ssh/sshd_config" > "${ssh2}.meta"
    echo "sysctl" > "${kern}"; echo "/etc/sysctl.d/99-hardening.conf" > "${kern}.meta"
    echo "broken" > "${TEST_DIR}/etc/ssh/sshd_config"

    # 两个 ssh 备份的 meta 都指向 TEST_DIR 内路径，确保恢复只写临时目录、绝不触碰真实 /etc
    run backup_center_restore_module "ssh"
    [[ "${status}" -eq 0 ]]
    [[ "$(cat "${TEST_DIR}/etc/ssh/sshd_config")" == "newest" ]]
}

@test "backup_center_restore_module returns 1 when no restorable backups" {
    run backup_center_restore_module "swap"
    [[ "${status}" -ne 0 ]]
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `bats tests/unit/backup-center.bats`
Expected: FAIL（backup_center.sh 不存在/函数未定义）。

- [ ] **Step 3: 创建 `scripts/base/backup_center.sh`**

```bash
#!/usr/bin/env bash
# backup_center.sh - 备份/回滚中心编排逻辑（无交互，可测试）
# 依赖: utils.sh (log_*, BACKUP_DIR), backup.sh (restore_file)
set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

[ -n "${_BACKUP_CENTER_LOADED:-}" ] && return 0
readonly _BACKUP_CENTER_LOADED=1

# 按原始路径前缀推导模块分组（仅用于展示/编排，不参与恢复正确性）
backup_center_module_of_path() {
    local path="$1"
    case "${path}" in
        /etc/ssh/*) echo "ssh" ;;
        /etc/sysctl.d/*) echo "kernel" ;;
        /etc/ufw/*|/etc/firewalld/*) echo "firewall" ;;
        /etc/fail2ban/*) echo "fail2ban" ;;
        /etc/audit/*) echo "audit" ;;
        /etc/clamav/*) echo "clamav" ;;
        /etc/aide/*|/var/lib/aide/*) echo "aide" ;;
        /etc/apt/*|/etc/yum/*|/etc/dnf/*) echo "autoupdate" ;;
        /etc/init.d/*|/etc/chrony/*|/etc/ntp*) echo "init" ;;
        /etc/fstab) echo "swap" ;;
        *) echo "other" ;;
    esac
}

# 列出存在备份的模块组（去重，无备份时无输出）
backup_center_list_modules() {
    local backup_path meta module
    local -a seen=()
    [[ -d "${BACKUP_DIR}" ]] || return 0
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        if [[ -n "${meta}" ]]; then
            module="$(backup_center_module_of_path "${meta}")"
        else
            module="other"
        fi
        if ! printf '%s\n' "${seen[@]}" | grep -qx "${module}"; then
            seen+=("${module}")
            echo "${module}"
        fi
    done
}

# 返回某目标路径的最新备份；无则返回 1
backup_center_latest_for_target() {
    local target="$1"
    local backup_path meta latest=""
    [[ -d "${BACKUP_DIR}" ]] || return 1
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        if [[ "${meta}" == "${target}" ]]; then
            if [[ -z "${latest}" ]] || [[ "${backup_path}" > "${latest}" ]]; then
                latest="${backup_path}"
            fi
        fi
    done
    if [[ -n "${latest}" ]]; then
        echo "${latest}"
        return 0
    fi
    return 1
}

# 对模块下每个目标文件，用其最新备份恢复到原始路径
backup_center_restore_module() {
    local module="$1"
    local backup_path meta module_name latest
    local -a restored=()
    local rc=0
    [[ -d "${BACKUP_DIR}" ]] || return 1
    for backup_path in "${BACKUP_DIR}"/*.bak.*; do
        [[ -f "${backup_path}" ]] || continue
        [[ "${backup_path}" != *.meta ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        module_name="other"
        [[ -n "${meta}" ]] && module_name="$(backup_center_module_of_path "${meta}")"
        if [[ "${module_name}" == "${module}" && -n "${meta}" ]]; then
            # 每个目标文件只恢复一次（取最新备份）
            if ! printf '%s\n' "${restored[@]}" | grep -qx "${meta}"; then
                if latest="$(backup_center_latest_for_target "${meta}")"; then
                    if restore_file "${latest}" "${meta}" "Restore ${module}"; then
                        restored+=("${meta}")
                    else
                        rc=1
                    fi
                fi
            fi
        fi
    done
    if [[ ${#restored[@]} -eq 0 ]]; then
        return 1
    fi
    return "${rc}"
}

# 恢复后的钩子：按目标路径重载服务 / 提示
backup_center_post_restore() {
    local backup_path="$1"
    local meta
    meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
    case "${meta}" in
        /etc/sysctl.d/*)
            log_info "${MSG_BACKUP_CENTER_RESTORE_SYSCTL}"
            if command -v sysctl &>/dev/null; then
                sysctl --system 2>/dev/null && log_success "sysctl reloaded" || log_warn "sysctl --system failed"
            fi
            ;;
        /etc/ssh/*)
            log_warn "${MSG_BACKUP_CENTER_RESTORE_SSH_HINT}"
            ;;
        /etc/ufw/*)
            if command -v ufw &>/dev/null; then
                ufw reload 2>/dev/null || true
            fi
            ;;
        /etc/firewalld/*)
            if command -v firewall-cmd &>/dev/null; then
                firewall-cmd --reload 2>/dev/null || true
            fi
            ;;
    esac
    return 0
}

log_debug "backup_center.sh loaded successfully"
```

- [ ] **Step 4: 运行测试确认通过**

Run: `bats tests/unit/backup-center.bats`
Expected: 全部通过。

> 注：`restore_module` 测试通过改写 `.meta` 指向 `TEST_DIR` 内路径，避免触碰真实系统；`sysctl --system`/`ufw reload` 属 Task 5 钩子，不在单测内执行（容器冒烟可选）。

- [ ] **Step 5: ShellCheck + 提交**

```bash
shellcheck -x scripts/base/backup_center.sh
git add scripts/base/backup_center.sh tests/unit/backup-center.bats
git commit -m "feat: add backup center orchestration logic (grouping, latest, restore)"
```

---

### Task 6: dashboard.sh — 评分 + 渲染（新文件）

**Files:**
- Create: `scripts/base/dashboard.sh`
- Test: `tests/unit/dashboard.bats`（新建）

**Interfaces:**
- Consumes: `get_ssh_config`（utils.sh）、`log_*`、`MSG_DASHBOARD_*`
- Produces:
  - `DASHBOARD_MODULES`（12 个安全模块数组）
  - `dashboard_module_items(module)` — 输出检查项 id 列表
  - `dashboard_check_item(module, item)` — 0/1 逐项判定（只读）
  - `dashboard_eval_module(module)` — 输出 "pass total"
  - `dashboard_total_score()` — 输出 "pass total"
  - `dashboard_risk_level(pct)` — 输出 low/medium/high/critical
  - `dashboard_item_symbols(module)` — 输出逐项 ✅/❌ 字符串
  - `dashboard_render()` — 彩色渲染到终端

> 设计说明（相对 spec 的检查项收敛）：kernel/filesystem/services 各取 2 项可可靠只读检测的子集，合计 31 项。`DASH_SSH_CONFIG`/`DASH_SYSCTL_CONF` 环境变量供测试覆盖。

- [ ] **Step 1: 创建失败测试 `tests/unit/dashboard.bats`**

```bash
#!/usr/bin/env bats
# dashboard.bats - 单元测试 for scripts/base/dashboard.sh

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"

    export DASH_SSH_CONFIG="${TEST_DIR}/sshd_config"
    export DASH_SYSCTL_CONF="${TEST_DIR}/99-hardening.conf"
    cat > "${DASH_SSH_CONFIG}" <<'EOF'
Port 2222
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
KexAlgorithms curve25519-sha256
EOF
    if ! type dashboard_module_items &>/dev/null; then
        source "${SCRIPT_DIR}/scripts/base/dashboard.sh"
    fi
}

teardown() {
    rm -rf "${TEST_DIR}"
}

@test "dashboard_module_items defines item ids per module" {
    run dashboard_module_items "ssh"
    [[ "${output}" == "port root passwd pubkey algorithms" ]]
    run dashboard_module_items "firewall"
    [[ "${output}" == "enabled ssh_port default_deny" ]]
    run dashboard_module_items "rootkit"
    [[ "${output}" == "rkhunter chkrootkit cron_configured" ]]
    run dashboard_module_items "unknown"
    [[ -z "${output}" ]]
}

@test "dashboard_risk_level boundaries" {
    run dashboard_risk_level 95
    [[ "${output}" == "low" ]]
    run dashboard_risk_level 89
    [[ "${output}" == "medium" ]]
    run dashboard_risk_level 75
    [[ "${output}" == "medium" ]]
    run dashboard_risk_level 74
    [[ "${output}" == "high" ]]
    run dashboard_risk_level 60
    [[ "${output}" == "high" ]]
    run dashboard_risk_level 59
    [[ "${output}" == "critical" ]]
}

@test "dashboard_check_item ssh checks read DASH_SSH_CONFIG" {
    dashboard_check_item "ssh" "port"
    dashboard_check_item "ssh" "root"
    dashboard_check_item "ssh" "passwd"
    dashboard_check_item "ssh" "pubkey"
    dashboard_check_item "ssh" "algorithms"

    # 反向：默认端口 → port 不通过
    cat > "${DASH_SSH_CONFIG}" <<'EOF'
Port 22
PermitRootLogin yes
EOF
    ! dashboard_check_item "ssh" "port"
    ! dashboard_check_item "ssh" "root"
}

@test "dashboard_total_score aggregates via stub eval" {
    dashboard_eval_module() { case "$1" in ssh) echo "4 5";; firewall) echo "0 3";; *) echo "0 0";; esac; }
    run dashboard_total_score
    [[ "${status}" -eq 0 ]]
    [[ "${output}" == "4 8" ]]
}

@test "dashboard_item_symbols renders per-item checkmarks" {
    dashboard_check_item() { return 0; }
    run dashboard_item_symbols "ssh"
    [[ "${output}" == "✅✅✅✅✅" ]]
}
```

> 注：最后两个测试通过**覆盖函数定义**（Bats 中 `run` 子 shell 继承父 shell 已覆盖的函数）验证聚合与渲染逻辑，不依赖真实系统状态。

- [ ] **Step 2: 运行测试确认失败**

Run: `bats tests/unit/dashboard.bats`
Expected: FAIL（dashboard.sh 不存在）。

- [ ] **Step 3: 创建 `scripts/base/dashboard.sh`**

```bash
#!/usr/bin/env bash
# dashboard.sh - 安全仪表盘：多模块评分 + 终端渲染（只读，可测试）
# 依赖: utils.sh (log_*, get_ssh_config), lang (MSG_DASHBOARD_*)
set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

[ -n "${_DASHBOARD_LOADED:-}" ] && return 0
readonly _DASHBOARD_LOADED=1

# 测试可覆盖的路径（默认生产路径）
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${DASH_SSH_CONFIG:=/etc/ssh/sshd_config}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${DASH_SYSCTL_CONF:=/etc/sysctl.d/99-hardening.conf}"

# 安全模块（不含 k3s/swap）
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
DASHBOARD_MODULES=("ssh" "firewall" "fail2ban" "audit" "users" "kernel" "filesystem" "services" "autoupdate" "aide" "clamav" "rootkit")

# 各模块检查项 id 列表
dashboard_module_items() {
    local module="$1"
    case "${module}" in
        ssh) echo "port root passwd pubkey algorithms" ;;
        firewall) echo "enabled ssh_port default_deny" ;;
        fail2ban) echo "installed active jail" ;;
        audit) echo "installed active rules" ;;
        users) echo "custom_user sudo" ;;
        kernel) echo "conf_present params_count" ;;
        filesystem) echo "suid_scanned sticky_bit" ;;
        services) echo "audited ports_recorded" ;;
        autoupdate) echo "enabled timer_active" ;;
        aide) echo "db_initialized cron_configured" ;;
        clamav) echo "db_updated cron_configured" ;;
        rootkit) echo "rkhunter chkrootkit cron_configured" ;;
        *) echo "" ;;
    esac
}

# 单项判定（只读；返回 0=通过 1=不通过）
dashboard_check_item() {
    local module="$1" item="$2"
    case "${module}_${item}" in
        ssh_port)
            [[ "$(get_ssh_config "Port" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "22")" != "22" ]] ;;
        ssh_root)
            [[ "$(get_ssh_config "PermitRootLogin" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "unknown")" == "no" ]] ;;
        ssh_passwd)
            [[ "$(get_ssh_config "PasswordAuthentication" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "unknown")" == "no" ]] ;;
        ssh_pubkey)
            local v
            v="$(get_ssh_config "PubkeyAuthentication" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "yes")"
            [[ "${v}" == "yes" || -z "${v}" ]] ;;
        ssh_algorithms)
            grep -qE '^(KexAlgorithms|Ciphers|MACs)' "${DASH_SSH_CONFIG}" 2>/dev/null ;;
        firewall_enabled)
            if command -v ufw &>/dev/null; then
                ufw status 2>/dev/null | grep -q "Status: active"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --state &>/dev/null
            else
                return 1
            fi ;;
        firewall_ssh_port)
            local port
            port="$(get_ssh_config "Port" "${DASH_SSH_CONFIG}" 2>/dev/null || echo "22")"
            if command -v ufw &>/dev/null; then
                ufw status 2>/dev/null | grep -qE "${port}/tcp"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --list-ports 2>/dev/null | grep -qE "^${port}/tcp"
            else
                return 1
            fi ;;
        firewall_default_deny)
            if command -v ufw &>/dev/null; then
                ufw status verbose 2>/dev/null | grep -qE "^Default: deny"
            elif command -v firewall-cmd &>/dev/null; then
                firewall-cmd --get-default-zone 2>/dev/null | grep -qi "drop"
            else
                return 1
            fi ;;
        fail2ban_installed)
            command -v fail2ban-client &>/dev/null ;;
        fail2ban_active)
            systemctl is-active fail2ban 2>/dev/null | grep -q active ;;
        fail2ban_jail)
            [[ -f /etc/fail2ban/jail.local ]] ;;
        audit_installed)
            command -v auditctl &>/dev/null ;;
        audit_active)
            systemctl is-active auditd 2>/dev/null | grep -q active ;;
        audit_rules)
            auditctl -l 2>/dev/null | grep -q . ;;
        users_custom_user)
            if type check_users_status &>/dev/null; then
                check_users_status 2>/dev/null | grep -qE '^users_custom=[1-9][0-9]*$'
            else
                return 1
            fi ;;
        users_sudo)
            grep -qiE '^%?(sudo|wheel)[[:space:]]' /etc/sudoers 2>/dev/null ;;
        kernel_conf_present)
            [[ -f "${DASH_SYSCTL_CONF}" ]] ;;
        kernel_params_count)
            [[ -f "${DASH_SYSCTL_CONF}" ]] && [[ "$(grep -cE '^[a-z].*=' "${DASH_SYSCTL_CONF}" 2>/dev/null)" -ge 5 ]] ;;
        filesystem_suid_scanned)
            ls /var/log/linux-one-key/report_*.txt &>/dev/null ;;
        filesystem_sticky_bit)
            local perms
            perms="$(stat -c '%a' /tmp 2>/dev/null || stat -f '%Lp' /tmp 2>/dev/null || echo "")"
            [[ -n "${perms}" ]] && [[ "${perms: -1}" =~ [1357] ]] ;;
        services_audited)
            ls /var/log/linux-one-key/report_*.txt &>/dev/null ;;
        services_ports_recorded)
            grep -l "LISTEN\|开放端口\|Open ports" /var/log/linux-one-key/report_*.txt &>/dev/null ;;
        autoupdate_enabled)
            [[ -f /etc/apt/apt.conf.d/20auto-upgrades ]] || command -v yum-cron &>/dev/null || command -v dnf-automatic &>/dev/null ;;
        autoupdate_timer_active)
            systemctl is-active unattended-upgrades 2>/dev/null | grep -q active || \
                systemctl is-active yum-cron 2>/dev/null | grep -q active || \
                systemctl is-active dnf-automatic 2>/dev/null | grep -q active ;;
        aide_db_initialized)
            [[ -f /var/lib/aide/aide.db.gz ]] ;;
        aide_cron_configured)
            crontab -l 2>/dev/null | grep -q aide || ls /etc/cron.d/aide* &>/dev/null ;;
        clamav_db_updated)
            command -v clamscan &>/dev/null && [[ -n "$(ls /var/lib/clamav 2>/dev/null | grep -E '\.cvd$|\.cld$' | head -1)" ]] ;;
        clamav_cron_configured)
            crontab -l 2>/dev/null | grep -qiE 'clamscan|freshclam' || ls /etc/cron.d/*clam* &>/dev/null ;;
        rootkit_rkhunter)
            command -v rkhunter &>/dev/null ;;
        rootkit_chkrootkit)
            command -v chkrootkit &>/dev/null ;;
        rootkit_cron_configured)
            crontab -l 2>/dev/null | grep -qiE 'rkhunter|chkrootkit' ;;
        *)
            return 1 ;;
    esac
}

# 模块得分：输出 "pass total"
dashboard_eval_module() {
    local module="$1"
    local items item pass=0 total=0
    items="$(dashboard_module_items "${module}")"
    for item in ${items}; do
        total=$((total + 1))
        if dashboard_check_item "${module}" "${item}"; then
            pass=$((pass + 1))
        fi
    done
    echo "${pass} ${total}"
}

# 总分：输出 "pass total"
dashboard_total_score() {
    local module result p t pass=0 total=0
    for module in "${DASHBOARD_MODULES[@]}"; do
        result="$(dashboard_eval_module "${module}")"
        p="${result%% *}"
        t="${result##* }"
        pass=$((pass + p))
        total=$((total + t))
    done
    echo "${pass} ${total}"
}

# 风险等级（整数百分比）
dashboard_risk_level() {
    local pct="$1"
    if [[ "${pct}" -ge 90 ]]; then
        echo "low"
    elif [[ "${pct}" -ge 75 ]]; then
        echo "medium"
    elif [[ "${pct}" -ge 60 ]]; then
        echo "high"
    else
        echo "critical"
    fi
}

# 逐项符号串（如 ✅❌✅✅✅）
dashboard_item_symbols() {
    local module="$1"
    local items item out=""
    items="$(dashboard_module_items "${module}")"
    for item in ${items}; do
        if dashboard_check_item "${module}" "${item}"; then
            out+="✅"
        else
            out+="❌"
        fi
    done
    [[ -n "${out}" ]] && echo "${out}"
}

# 渲染：每模块一行 + 总分/风险等级
dashboard_render() {
    local module result pass total pct level label color symbols
    local total_pass=0 total_all=0
    log_title "${MSG_DASHBOARD_TITLE}"
    for module in "${DASHBOARD_MODULES[@]}"; do
        result="$(dashboard_eval_module "${module}")"
        pass="${result%% *}"
        total="${result##* }"
        total_pass=$((total_pass + pass))
        total_all=$((total_all + total))
        symbols="$(dashboard_item_symbols "${module}")"
        if [[ "${total}" -eq 0 ]]; then
            label="N/A"; color="${YELLOW}"
        elif [[ "${pass}" -eq "${total}" ]]; then
            label="✅ ${pass}/${total}"; color="${GREEN}"
        elif [[ "${pass}" -eq 0 ]]; then
            label="❌ 0/${total}"; color="${RED}"
        else
            label="⚠️ ${pass}/${total}"; color="${YELLOW}"
        fi
        printf "${color}  %-12s %-10s %s${NC}\n" "${module}" "${label}" "${symbols}"
    done
    if [[ "${total_all}" -gt 0 ]]; then
        pct=$(( total_pass * 100 / total_all ))
        level="$(dashboard_risk_level "${pct}")"
        log_info "${MSG_DASHBOARD_TOTAL}: ${total_pass}/${total_all} (${pct}%)"
        log_info "${MSG_DASHBOARD_RISK}: ${level}"
    fi
}

log_debug "dashboard.sh loaded successfully"
```

> 注：`filesystem_sticky_bit` 检查里同时兼容 GNU `stat -c` 与 BSD `stat -f`（含防御性 `|| echo 1777` 兜底）。`services_audited`/`filesystem_suid_scanned` 以报告文件存在为代理指标（v1 简化，见 spec §11 风险表）。

- [ ] **Step 4: 运行测试确认通过**

Run: `bats tests/unit/dashboard.bats`
Expected: 全部通过（SSH 5 项在测试配置下全过；总分用例用 stub 验证 4/8）。

- [ ] **Step 5: ShellCheck + 提交**

```bash
shellcheck -x scripts/base/dashboard.sh
git add scripts/base/dashboard.sh tests/unit/dashboard.bats
git commit -m "feat: add security dashboard scoring and rendering"
```

---

### Task 7: install.sh — 加载 + 菜单 [17]/[18] + 交互处理

**Files:**
- Modify: `install.sh`（`load_dependencies`、`show_main_menu`、`get_main_menu_choice`、`run_main_menu_loop`、新增 2 个 submenu 函数 + 4 个交互 helper）
- Test: `tests/unit/menu.bats`（追加结构性断言）

**Interfaces:**
- Consumes: Task 4 的 `MSG_*` 键、Task 5 的 backup_center 函数、Task 6 的 dashboard 函数
- Produces: `run_backup_center_menu()`、`run_dashboard_menu()`（主菜单 case 调用的入口）

- [ ] **Step 1: 追加结构性失败测试到 menu.bats**

```bash
@test "install.sh menu defines [17]/[18] and gates with is_mode_full" {
    run grep -E 'MSG_MAIN_MENU_BACKUP_CENTER' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
    run grep -E 'MSG_MAIN_MENU_DASHBOARD' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
    run bash -c "grep -nE '17\) run_backup_center_menu|18\) run_dashboard_menu' '${SCRIPT_DIR}/install.sh'"
    [[ "$status" -eq 0 ]]
    run bash -c "sed -n '/17|18/,/esac/p' '${SCRIPT_DIR}/install.sh' | grep -q is_mode_lite"
    [[ "$status" -eq 0 ]]
}

@test "install.sh sources backup_center.sh and dashboard.sh in load_dependencies" {
    run grep -F 'scripts/base/backup_center.sh' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
    run grep -F 'scripts/base/dashboard.sh' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
}

@test "get_main_menu_choice accepts 17 and 18" {
    run grep -E '\[0-9\]\|1\[0-8\]' "${SCRIPT_DIR}/install.sh"
    [[ "$status" -eq 0 ]]
}
```

- [ ] **Step 2: 运行测试确认失败**

Run: `bats tests/unit/menu.bats`
Expected: 新 3 个用例 FAIL。

- [ ] **Step 3: 修改 `load_dependencies()`（install.sh:210）**

在函数末尾（最后一个 source 之后、函数结束 `}` 之前）追加：

```bash
    # 加载 backup_center.sh / dashboard.sh（Batch 5a 编排与呈现层）
    if [[ ! -f "${base_dir}/backup_center.sh" ]]; then
        echo "Error: Cannot find backup_center.sh at ${base_dir}/backup_center.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${base_dir}/backup_center.sh"

    if [[ ! -f "${base_dir}/dashboard.sh" ]]; then
        echo "Error: Cannot find dashboard.sh at ${base_dir}/dashboard.sh"
        exit 1
    fi
    # shellcheck source=/dev/null
    source "${base_dir}/dashboard.sh"
```

- [ ] **Step 4: 修改 `show_main_menu()` — 新增「运维工具」分组**

在 Rootkit 块（`MSG_MAIN_MENU_ROOTKIT` 的 `fi` 之后、`echo ""` 与 EXIT 行之前）插入：

```bash
    # 分组 6：运维工具（完整版专用）
    echo -e "${BOLD}${MSG_SECTION_OPS}${NC}"
    echo ""
    # 备份/回滚中心（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_BACKUP_CENTER}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_BACKUP_CENTER_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_BACKUP_CENTER_DESC}"
    fi
    echo ""
    # 安全仪表盘（完整版专用）
    echo -e "  ${GREEN}${MSG_MAIN_MENU_DASHBOARD}${NC}"
    if is_mode_lite; then
        echo -e "      ${MSG_MAIN_MENU_DASHBOARD_DESC} ${YELLOW}${MSG_MODE_FULL_ONLY}${NC}"
    else
        echo -e "      ${MSG_MAIN_MENU_DASHBOARD_DESC}"
    fi
    echo ""
```

- [ ] **Step 5: 修改 `get_main_menu_choice()`（install.sh:895）**

将 `[0-9]|10|11|12|13|14|15|16)` 替换为 `[0-9]|1[0-8])`（匹配 0-9 与 10-18）。同时把同一函数内的提示文案 `prompt_input "${MSG_MAIN_MENU_PROMPT} [0-16]"` 同步改为 `[0-18]`。

- [ ] **Step 6: 修改 `run_main_menu_loop()`（install.sh:1775）**

在 `case` 中追加分支（放在 `0) cleanup_and_exit ;;` 之前）：

```bash
            17|18)
                if is_mode_lite; then
                    log_error "${MSG_ERROR_LITE_MODE}"
                    press_enter
                    continue
                fi
                case "${choice}" in
                    17) run_backup_center_menu ;;
                    18) run_dashboard_menu ;;
                esac
                ;;
```

- [ ] **Step 7: 新增交互函数（放在 `run_main_menu_loop()` 之前）**

```bash
# ═══════════════════════════════════════════
# 备份/回滚中心 子菜单
# ═══════════════════════════════════════════
show_backup_center_submenu() {
    echo ""
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo -e "${BOLD}  ${MSG_BACKUP_CENTER_TITLE}${NC}"
    echo -e "${BOLD}═══════════════════════════════════════════${NC}"
    echo ""
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_LIST}${NC}"
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_RESTORE}${NC}"
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_ROLLBACK}${NC}"
    echo -e "  ${GREEN}${MSG_BACKUP_CENTER_MENU_CLEAN}${NC}"
    echo ""
    echo -e "  ${RED}${MSG_BACKUP_CENTER_MENU_BACK}${NC}"
    echo ""
}

run_backup_center_menu() {
    while true; do
        show_backup_center_submenu
        local choice
        choice=$(prompt_input "${MSG_MAIN_MENU_PROMPT} [0-4]" "")
        case "${choice}" in
            1) backup_center_show_history; press_enter ;;
            2) backup_center_interactive_restore ;;
            3) backup_center_interactive_rollback ;;
            4) backup_center_interactive_clean ;;
            0) return 0 ;;
            *) log_error "${MSG_MENU_INVALID}" ;;
        esac
    done
}

# 查看备份历史（只读）
backup_center_show_history() {
    local modules
    modules="$(backup_center_list_modules)"
    if [[ -z "${modules}" ]]; then
        log_info "${MSG_BACKUP_CENTER_NO_BACKUPS}"
        return 0
    fi
    log_title "${MSG_BACKUP_CENTER_HISTORY_TITLE}"
    local backup_path meta module
    while IFS= read -r backup_path; do
        [[ -f "${backup_path}" ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        module="other"
        [[ -n "${meta}" ]] && module="$(backup_center_module_of_path "${meta}")"
        printf "  [%-10s] %s\n" "${module}" "$(basename "${backup_path}")"
    done < <(list_backups)
}

# 一键恢复（带双重确认）
backup_center_interactive_restore() {
    local modules
    modules="$(backup_center_list_modules)"
    if [[ -z "${modules}" ]]; then
        log_info "${MSG_BACKUP_CENTER_NO_BACKUPS}"
        press_enter
        return 0
    fi
    log_title "${MSG_BACKUP_CENTER_SELECT_MODULE}"
    local module
    printf '%s\n' "${modules}" | sed 's/^/  - /'
    local target_module
    target_module=$(prompt_input "module" "")
    if [[ -z "${target_module}" ]]; then
        return 0
    fi

    # 列出该模块将恢复的文件（按目标路径去重）
    local backup_path meta files=() seen=()
    while IFS= read -r backup_path; do
        [[ -f "${backup_path}" ]] || continue
        meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
        if [[ -n "${meta}" ]] && [[ "$(backup_center_module_of_path "${meta}")" == "${target_module}" ]] && ! printf '%s\n' "${seen[@]}" | grep -qx "${meta}"; then
            files+=("${meta}")
            seen+=("${meta}")
        fi
    done < <(list_backups)
    if [[ ${#files[@]} -eq 0 ]]; then
        log_info "${MSG_BACKUP_CENTER_NO_RESTORABLE}"
        press_enter
        return 0
    fi

    log_warn "${MSG_BACKUP_CENTER_CONFIRM_RESTORE}"
    printf '  %s\n' "${files[@]}" | sed 's/^/    - /'
    local ans
    ans=$(prompt_input "${MSG_BACKUP_CENTER_CONFIRM_PROMPT}" "n")
    if [[ "${ans}" != "y" ]] && [[ "${ans}" != "Y" ]]; then
        log_info "${MSG_BACKUP_CENTER_RESTORE_ABORTED}"
        press_enter
        return 0
    fi

    if backup_center_restore_module "${target_module}"; then
        log_success "${MSG_BACKUP_CENTER_RESTORED}: ${target_module}"
        # 对最近恢复的备份执行钩子
        local latest
        for backup_path in "${files[@]}"; do
            meta="$(cat "${backup_path}.meta" 2>/dev/null || echo "")"
            if latest="$(backup_center_latest_for_target "${meta}")"; then
                backup_center_post_restore "${latest}"
            fi
        done
    else
        log_error "${MSG_BACKUP_CENTER_NO_RESTORABLE}"
    fi
    press_enter
}

# SSH 回滚定时器管理
backup_center_interactive_rollback() {
    local status
    if status="$(rollback_timer_status)"; then
        # shellcheck disable=SC2059
        log_info "$(printf "${MSG_BACKUP_CENTER_ROLLBACK_PENDING}" "${status}")"
        local ans
        ans=$(prompt_input "${MSG_BACKUP_CENTER_ROLLBACK_CANCEL} (y/N)" "n")
        if [[ "${ans}" == "y" ]] || [[ "${ans}" == "Y" ]]; then
            if cancel_rollback_timer 2>/dev/null || cancel_scheduled_task "${status}" 2>/dev/null; then
                log_success "${MSG_BACKUP_CENTER_ROLLBACK_CANCEL}"
            else
                log_error "${MSG_BACKUP_CENTER_ROLLBACK_NO_PID}"
            fi
        fi
    else
        log_info "${MSG_BACKUP_CENTER_ROLLBACK_NONE}"
    fi
    press_enter
}

# 清理旧备份
backup_center_interactive_clean() {
    local ans
    ans=$(prompt_input "${MSG_BACKUP_CENTER_CLEAN_CONFIRM}" "n")
    if [[ "${ans}" != "y" ]] && [[ "${ans}" != "Y" ]]; then
        return 0
    fi
    if clean_old_backups 5; then
        log_success "${MSG_BACKUP_CENTER_CLEAN_DONE}"
    else
        log_info "${MSG_BACKUP_CENTER_CLEAN_EMPTY}"
    fi
    press_enter
}

# ═══════════════════════════════════════════
# 安全仪表盘
# ═══════════════════════════════════════════
run_dashboard_menu() {
    dashboard_render
    press_enter
}
```

- [ ] **Step 8: 运行测试确认通过**

Run: `bats tests/unit/menu.bats`
Expected: 新用例通过；`bash -n install.sh` 无语法错误；全文件回归通过。

- [ ] **Step 9: ShellCheck + 提交**

```bash
shellcheck -x install.sh
bash -n install.sh
git add install.sh tests/unit/menu.bats
git commit -m "feat: wire backup center and dashboard into main menu (17/18, full-only)"
```

---

### Task 8: 文档 + 全量回归

**Files:**
- Modify: `README.md`、`HANDOVER.md`

**Interfaces:** 无新接口；验证 Task 1-7 交付。

- [ ] **Step 1: README 更新**

在 `README.md`「功能特性 / Features」追加两行（Full 版标识）：

```markdown
- [x] 备份/回滚中心（浏览备份历史、按模块一键恢复、回滚定时器管理、清理旧备份）— Full 版
- [x] 安全仪表盘（多模块 CIS 合规评分 + 风险等级）— Full 版
```

在「交互式向导 / Interactive Wizard」之后追加小节：

```markdown
### 运维工具（Full 版）

- **[17] 备份/回滚中心**：浏览 `/var/log/linux-one-key/backups/` 备份历史；按模块一键恢复到原路径；查看/取消 SSH 回滚定时器；按保留策略清理旧备份。恢复操作需双重确认。
- **[18] 安全仪表盘**：12 个安全模块 × 31 项检查的合规评分（SSH 5 / Firewall 3 / Fail2Ban 3 / Audit 3 / Users 2 / Kernel 2 / Filesystem 2 / Services 2 / AutoUpdate 2 / AIDE 2 / ClamAV 2 / Rootkit 3），总分 + 风险等级（≥90 Low · 75-89 Medium · 60-74 High · <60 Critical）。
```

- [ ] **Step 2: HANDOVER 更新**

在 `HANDOVER.md` 顶部状态行更新为 v1.6.0 进行中，并在「下一步」追加：

```markdown
本次（v1.6.0, Batch 5a）规划：
1. ⏳ **备份/回滚中心** — [17] 菜单：历史/恢复/回滚定时器/清理（backup.sh .meta sidecar 已设计）
2. ⏳ **安全仪表盘** — [18] 菜单：12 模块 31 项检查评分 + 风险等级
3. ⏳ Batch 5b（sudo + 日志加固）独立 spec 排队中
```

- [ ] **Step 3: 全量静态 + 回归**

Run:
```bash
shellcheck -x scripts/base/backup.sh scripts/base/rollback.sh scripts/base/backup_center.sh scripts/base/dashboard.sh install.sh
bats tests/unit/*.bats
```
Expected: ShellCheck 无 error；全量 Bats 通过（现有 473 + 新增 ≥21）。

- [ ] **Step 4: 提交**

```bash
git add README.md HANDOVER.md
git commit -m "docs: document Batch 5a backup center and dashboard"
```

- [ ] **Step 5: 收尾确认**

向用户汇报：新增菜单 [17]/[18]、函数清单、测试增量、ShellCheck/Bats 结果；确认是否符合预期后更新 HANDOVER 状态快照（🔄 进行中），后续可启动 Batch 5b spec。

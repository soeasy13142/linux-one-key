---
title: "Lite 版运行痕迹清理 —— 实现计划"
created: 2026-08-14
updated: 2026-08-14
status: done
source: "docs/plans/2026-08-14_17-02_lite-runtime-cleanup_nogit.md（设计文档，已获用户逐节确认）"
topic: "feature"
---

# Lite Runtime Cleanup 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lite 模式正常退出前询问是否清理脚本运行痕迹（`/var/log/linux-one-key` 日志/备份/报告 + `/tmp` SSH 临时文件），清理后保留加固配置本身。

**Architecture:** 新建独立模块 `scripts/base/cleanup.sh`（`cleanup_lite_traces()` 幂等清理函数），install.sh 在 `load_dependencies()` Lite-gated 加载、在 `cleanup_and_exit()` 接入确认提示。回滚定时器经 `declare -F` 探测取消（base 层不 import security）。关键坑：`log_*` 内部 `_ensure_log_dir` 会在删除后重建 `LOG_DIR`，需兜底删除。

**Tech Stack:** Bash 5.x, ShellCheck, Bats-core

## Global Constraints

- 所有脚本 `#!/usr/bin/env bash` + `set -eo pipefail`（不用 `-u`，与 utils.sh 一致）
- `snake_case` 函数，`UPPER_SNAKE_CASE` 常量；`readonly` 常量
- 用户可见文本一律 `MSG_*` 翻译变量（`scripts/lang/zh.sh` / `en.sh`），zh/en 必须对称
- 输出用 `log_info/success/warn`，不直接 `echo`（**例外**：清理路径下 LOG_DIR 已删除，`log_*` 会经 `_ensure_log_dir` 重建目录，需在代码注释中说明例外理由）
- 新脚本/函数必须配 Bats 测试
- 修改配置文件前必须备份（本项目 cleanup 不修改配置文件，跳过）
- 完成修改必须 commit；不擅自 push
- 模块边界：`scripts/base/` 不得 import `scripts/security/`、`scripts/server/`（用 `declare -F` 探测跨层函数）

## File Structure

| 文件 | 动作 | 职责 |
|------|------|------|
| `scripts/base/cleanup.sh` | **新建** | 清理清单常量 + `cleanup_lite_traces()` |
| `tests/unit/cleanup.bats` | **新建** | 7+ 个 Bats 用例 |
| `scripts/lang/zh.sh` | 修改 | +4 个 `MSG_CLEANUP_*` |
| `scripts/lang/en.sh` | 修改 | +4 个 `MSG_CLEANUP_*`（对称） |
| `install.sh` | 修改 | `load_dependencies()` + `cleanup_and_exit()` |
| `scripts/base/utils.sh` | 修改 | `SCRIPT_VERSION` 1.7.0 → 1.8.0（Task 6） |
| `package.json` | 修改 | `version` 1.7.0 → 1.8.0（Task 6） |
| `HANDOVER.md` / `README.md` / `docs/handover-archive.md` | 修改 | 里程碑/决策/归档（Task 6） |

---

## Task 1: 编写失败的 Bats 测试 `tests/unit/cleanup.bats`

**Files:**
- Create: `tests/unit/cleanup.bats`

**Interfaces:**
- Consumes: `utils.sh`（`LOG_DIR`、`log_*`、`_UTILS_LOADED`）、`load_lang`
- Produces: 对 `cleanup_lite_traces` / `_CLEANUP_LOADED` / `CLEANUP_LOG_DIR` / `CLEANUP_TMP_PATTERNS` 的断言契约

- [ ] **Step 1: 创建测试文件**

```bash
cat > /Users/charliepan/Downloads/linux-one-key/tests/unit/cleanup.bats <<'BATSEOF'
#!/usr/bin/env bats
# cleanup.bats - 单元测试 for scripts/base/cleanup.sh
bats_require_minimum_version 1.5.0

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/log/backups"
    export REPORT_DIR="${TEST_DIR}/log/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    # Load dependencies
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    LOG_FILE="${TEST_DIR}/test.log"
    load_lang "${SCRIPT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/cleanup.sh"
}

teardown() {
    rm -rf "${TEST_DIR}"
}

# ── Source guard & 绑定 ──

@test "cleanup.sh: _CLEANUP_LOADED is set" {
    [[ "${_CLEANUP_LOADED:-}" == "1" ]]
}

@test "cleanup.sh: CLEANUP_LOG_DIR binds to LOG_DIR" {
    [[ "${CLEANUP_LOG_DIR}" == "${LOG_DIR}" ]]
}

@test "cleanup.sh: tmp patterns are precise" {
    [[ " ${CLEANUP_TMP_PATTERNS[*]} " == *"/tmp/.ssh-askpass-*"* ]]
    [[ " ${CLEANUP_TMP_PATTERNS[*]} " == *"/tmp/.ssh-monitor-*"* ]]
}

# ── 正常路径 ──

@test "cleanup: removes LOG_DIR and tmp ssh files" {
    touch "${LOG_DIR}/hardening_test.log"
    touch "${BACKUP_DIR}/sshd_config.bak"
    touch "${REPORT_DIR}/report_test.txt"
    mkdir -p "${TEST_DIR}/tmp"
    touch "${TEST_DIR}/tmp/.ssh-askpass-123"
    touch "${TEST_DIR}/tmp/.ssh-monitor-456"
    CLEANUP_TMP_PATTERNS=("${TEST_DIR}/tmp/.ssh-askpass-*" "${TEST_DIR}/tmp/.ssh-monitor-*")

    cleanup_lite_traces

    [[ ! -d "${LOG_DIR}" ]]
    [[ ! -e "${TEST_DIR}/tmp/.ssh-askpass-123" ]]
    [[ ! -e "${TEST_DIR}/tmp/.ssh-monitor-456" ]]
}

# ── 幂等 ──

@test "cleanup: idempotent on repeat" {
    touch "${LOG_DIR}/x.log"
    cleanup_lite_traces
    run cleanup_lite_traces
    [[ "${status}" -eq 0 ]]
    [[ ! -d "${LOG_DIR}" ]]
}

# ── 不存在时不报错 ──

@test "cleanup: no-op when LOG_DIR missing" {
    rm -rf "${LOG_DIR}"
    CLEANUP_TMP_PATTERNS=()
    run cleanup_lite_traces
    [[ "${status}" -eq 0 ]]
}

# ── 不误删 ──

@test "cleanup: does not touch unrelated tmp files" {
    mkdir -p "${TEST_DIR}/tmp"
    touch "${TEST_DIR}/tmp/.ssh-askpass-x"
    touch "${TEST_DIR}/tmp/.ssh-other-x"
    touch "${TEST_DIR}/tmp/unrelated-x"
    CLEANUP_TMP_PATTERNS=("${TEST_DIR}/tmp/.ssh-askpass-*")

    cleanup_lite_traces

    [[ ! -e "${TEST_DIR}/tmp/.ssh-askpass-x" ]]
    [[ -e "${TEST_DIR}/tmp/.ssh-other-x" ]]
    [[ -e "${TEST_DIR}/tmp/unrelated-x" ]]
}

# ── 失败容忍（mock rm 对 cleanup-blocked 路径失败，root/non-root 均有效） ──

@test "cleanup: tolerant when removal fails (returns 0, keeps dir)" {
    mkdir -p "${TEST_DIR}/bin"
    cat > "${TEST_DIR}/bin/rm" <<'EOF'
#!/usr/bin/env bash
case " $* " in
    *"cleanup-blocked"*) exit 1 ;;
esac
exec /bin/rm "$@"
EOF
    chmod +x "${TEST_DIR}/bin/rm"
    mkdir -p "${TEST_DIR}/cleanup-blocked"
    touch "${TEST_DIR}/cleanup-blocked/x.log"
    CLEANUP_LOG_DIR="${TEST_DIR}/cleanup-blocked"
    CLEANUP_TMP_PATTERNS=()
    PATH="${TEST_DIR}/bin:${PATH}"

    run cleanup_lite_traces
    [[ "${status}" -eq 0 ]]
    [[ -d "${TEST_DIR}/cleanup-blocked" ]]
}

# ── 回滚定时器取消 ──

@test "cleanup: cancels active rollback timer" {
    CALLED=0
    cancel_rollback_timer() { CALLED=1; }
    CLEANUP_LOG_DIR="${TEST_DIR}/nonexistent"
    CLEANUP_TMP_PATTERNS=()

    cleanup_lite_traces
    [[ "${CALLED}" -eq 1 ]]
}

# ── fallback 路径清理 ──

@test "cleanup: removes arbitrary CLEANUP_LOG_DIR (fallback path covered)" {
    local fake="${TEST_DIR}/fake-log"
    mkdir -p "${fake}"
    CLEANUP_LOG_DIR="${fake}"
    CLEANUP_TMP_PATTERNS=()

    cleanup_lite_traces
    [[ ! -d "${fake}" ]]
}
BATSEOF
```

- [ ] **Step 2: 运行测试，确认失败（RED）**

Run: `bats /Users/charliepan/Downloads/linux-one-key/tests/unit/cleanup.bats`
Expected: 每个 @test 因 `scripts/base/cleanup.sh` 不存在而失败（`setup` 中 `source` 报错），总共 FAIL。

- [ ] **Step 3: 提交（测试先行）**

```bash
cd /Users/charliepan/Downloads/linux-one-key
git add tests/unit/cleanup.bats
git commit -m "test: add Bats tests for Lite runtime cleanup (RED)"
```

---

## Task 2: 实现 `scripts/base/cleanup.sh`

**Files:**
- Create: `scripts/base/cleanup.sh`

**Interfaces:**
- Consumes: `LOG_DIR`（utils.sh）、`log_success/log_warn`（utils.sh）、`MSG_CLEANUP_DONE/MSG_CLEANUP_PARTIAL`（lang，Task 3 加入；本 Task 测试不依赖其内容）
- Produces: `cleanup_lite_traces()`（返回 0，幂等，清理后 `CLEANUP_LOG_DIR` 不存在）、`_CLEANUP_LOADED`、`CLEANUP_LOG_DIR`、`CLEANUP_TMP_PATTERNS`

- [ ] **Step 1: 创建模块**

```bash
cat > /Users/charliepan/Downloads/linux-one-key/scripts/base/cleanup.sh <<'EOF'
#!/usr/bin/env bash
# cleanup.sh - Lite 模式运行痕迹清理模块
# 清理脚本运行产生的日志/备份/报告目录 + /tmp 临时文件，保留加固配置本身。

set -eo pipefail
# 不使用 -u (nounset)，与 utils.sh 保持一致

# 源加载保护：防止重复 source 导致 readonly 变量错误
[ -n "${_CLEANUP_LOADED:-}" ] && return 0
readonly _CLEANUP_LOADED=1

# 检查依赖
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    echo "Error: utils.sh must be loaded before cleanup.sh"
    exit 1
fi

# ═══════════════════════════════════════════
# 清理清单常量
# ═══════════════════════════════════════════

# 日志/备份/报告目录（绑定 utils.sh 的 LOG_DIR，含 /tmp/linux-one-key fallback）
# shellcheck disable=SC2034 # Public API — 供 Bats 测试覆盖
CLEANUP_LOG_DIR="${LOG_DIR}"
# /tmp 临时文件模式（精确前缀匹配，绝不触碰无关文件）
CLEANUP_TMP_PATTERNS=("/tmp/.ssh-askpass-*" "/tmp/.ssh-monitor-*")

# ═══════════════════════════════════════════
# 清理函数
# ═══════════════════════════════════════════

# 取消活跃的回滚定时器（若存在）
# 不硬依赖 security/ssh.sh（base 层不 import security），用 declare -F 探测
_cancel_active_rollback() {
    if declare -F cancel_rollback_timer &>/dev/null; then
        cancel_rollback_timer 2>/dev/null || true
    fi
}

# 清理 /tmp 临时文件（模式匹配，防空 glob）
_cleanup_tmp_files() {
    local pattern
    for pattern in "${CLEANUP_TMP_PATTERNS[@]}"; do
        # shellcheck disable=SC2086 # 有意 glob 展开匹配多个文件
        rm -f ${pattern} 2>/dev/null || true
    done
}

# 清理 Lite 模式运行痕迹（幂等、失败容忍、清理后 LOG_DIR 不残留）
# Gotcha: log_* 内部调用 _ensure_log_dir，删除 LOG_DIR 后再写日志会重建该目录，
#         因此这里在删除成功后做一次兜底删除，保证最终状态无 LOG_DIR。
cleanup_lite_traces() {
    # ① 取消活跃回滚定时器，避免定时器到点找不到备份文件
    _cancel_active_rollback

    # ② 清理 /tmp 临时文件
    _cleanup_tmp_files

    # ③ 清理日志/备份/报告目录
    local cleaned=0
    if [[ -d "${CLEANUP_LOG_DIR}" ]]; then
        if rm -rf "${CLEANUP_LOG_DIR}" 2>/dev/null; then
            cleaned=1
        fi
    else
        cleaned=1
    fi

    if [[ "${cleaned}" -eq 1 ]]; then
        log_success "${MSG_CLEANUP_DONE}"
    else
        log_warn "${MSG_CLEANUP_PARTIAL}"
    fi

    # 兜底：log_* 的 _ensure_log_dir 可能重建 LOG_DIR，确保最终状态为已删除
    if [[ "${cleaned}" -eq 1 ]] && [[ -d "${CLEANUP_LOG_DIR}" ]]; then
        rm -rf "${CLEANUP_LOG_DIR}" 2>/dev/null || true
    fi

    return 0
}
EOF
```

- [ ] **Step 2: 运行测试，确认通过（GREEN）**

Run: `bats /Users/charliepan/Downloads/linux-one-key/tests/unit/cleanup.bats`
Expected: 全部 PASS（`MSG_CLEANUP_DONE` 等为空字符串不影响断言；`load_lang` 已加载 lang，见 Task 3）。

- [ ] **Step 3: 提交**

```bash
cd /Users/charliepan/Downloads/linux-one-key
git add scripts/base/cleanup.sh
git commit -m "feat: add cleanup.sh for Lite runtime traces cleanup (GREEN)"
```

---

## Task 3: i18n —— `MSG_CLEANUP_*`（zh/en 对称）

**Files:**
- Modify: `scripts/lang/zh.sh`（在 861 行 `MSG_GOODBYE` 后追加）
- Modify: `scripts/lang/en.sh`（在 861 行 `MSG_GOODBYE` 后追加）

**Interfaces:**
- Produces: `MSG_CLEANUP_PROMPT` / `MSG_CLEANUP_DONE` / `MSG_CLEANUP_PARTIAL` / `MSG_CLEANUP_SKIPPED`

- [ ] **Step 1: zh.sh 追加**

用 Edit 在 `MSG_GOODBYE="再见！"`（第 861 行）之后插入：

```bash

# ── Lite 运行痕迹清理 ──
MSG_CLEANUP_PROMPT="是否清理脚本运行痕迹（日志/备份/报告）？清理后将无法回滚。"
MSG_CLEANUP_DONE="运行痕迹已清理"
MSG_CLEANUP_PARTIAL="部分运行痕迹清理失败（已保留）"
MSG_CLEANUP_SKIPPED="已保留运行痕迹"
```

- [ ] **Step 2: en.sh 追加**

用 Edit 在 `MSG_GOODBYE="Goodbye!"`（第 861 行）之后插入：

```bash

# ── Lite runtime cleanup ──
MSG_CLEANUP_PROMPT="Clean up script runtime traces (logs/backups/reports)? Rollback will no longer be possible."
MSG_CLEANUP_DONE="Runtime traces cleaned."
MSG_CLEANUP_PARTIAL="Some runtime traces could not be cleaned (kept)."
MSG_CLEANUP_SKIPPED="Runtime traces kept."
```

- [ ] **Step 3: 验证对称 + 重跑 cleanup 测试**

Run: `bats /Users/charliepan/Downloads/linux-one-key/tests/unit/cleanup.bats`
Expected: 全部 PASS。抽查 zh/en 的 `MSG_CLEANUP_` 键各 4 个、一一对应：

```bash
grep -c "MSG_CLEANUP_" /Users/charliepan/Downloads/linux-one-key/scripts/lang/zh.sh /Users/charliepan/Downloads/linux-one-key/scripts/lang/en.sh
```
Expected: 两个文件各 4。

- [ ] **Step 4: 提交**

```bash
cd /Users/charliepan/Downloads/linux-one-key
git add scripts/lang/zh.sh scripts/lang/en.sh
git commit -m "feat: add MSG_CLEANUP_* i18n for Lite cleanup"
```

---

## Task 4: install.sh 接入

**Files:**
- Modify: `install.sh:246`（`load_dependencies`，mode.sh source 块后插入）
- Modify: `install.sh:1922-1931`（`cleanup_and_exit`）

**Interfaces:**
- Consumes: `is_mode_lite`（mode.sh）、`confirm`（utils.sh）、`cleanup_lite_traces`（cleanup.sh）
- Produces: Lite 正常退出时的清理询问 + 兜底删除

- [ ] **Step 1: `load_dependencies()` 加 Lite-gated source**

在 `source "${base_dir}/mode.sh"` 块（install.sh:240-246）之后、swap.sh 块之前插入：

```bash

    # 加载 cleanup.sh（仅 Lite 模式：退出前清理运行痕迹）
    if is_mode_lite; then
        if [[ ! -f "${base_dir}/cleanup.sh" ]]; then
            echo "Error: Cannot find cleanup.sh at ${base_dir}/cleanup.sh"
            exit 1
        fi
        # shellcheck source=/dev/null
        source "${base_dir}/cleanup.sh"
    fi
```

- [ ] **Step 2: 重写 `cleanup_and_exit()`**

将 install.sh:1922-1931 的整个函数替换为：

```bash
cleanup_and_exit() {
    # Lite 模式：退出前询问清理运行痕迹（日志/备份/报告 + /tmp 临时文件）
    local cleaned=0
    if is_mode_lite; then
        if confirm "${MSG_CLEANUP_PROMPT}" "y"; then
            cleanup_lite_traces
            cleaned=1
        else
            log_info "${MSG_CLEANUP_SKIPPED}"
        fi
    fi

    # 清理 bootstrap 临时目录（保持现有逻辑不变）
    if [[ -n "${_CLEANUP_DIR:-}" ]] && [[ -d "${_CLEANUP_DIR}" ]]; then
        rm -rf "${_CLEANUP_DIR}" 2>/dev/null || true
    fi
    echo ""
    log_info "${MSG_GOODBYE}"
    echo ""
    # Lite 已清理场景：log_info 的 _ensure_log_dir 会重建 LOG_DIR，这里兜底删除
    if [[ "${cleaned}" -eq 1 ]] && [[ -d "${LOG_DIR}" ]]; then
        rm -rf "${LOG_DIR}" 2>/dev/null || true
    fi
    exit 0
}
```

- [ ] **Step 3: ShellCheck**

Run: `cd /Users/charliepan/Downloads/linux-one-key && shellcheck -x install.sh`
Expected: 无错误。

- [ ] **Step 4: 提交**

```bash
cd /Users/charliepan/Downloads/linux-one-key
git add install.sh
git commit -m "feat: wire Lite runtime cleanup into install.sh exit path"
```

---

## Task 5: 全量验证 + 提交

- [ ] **Step 1: 全量 ShellCheck**

Run: `cd /Users/charliepan/Downloads/linux-one-key && shellcheck -x install.sh scripts/base/*.sh scripts/security/*.sh scripts/server/*.sh scripts/dev/*.sh scripts/lang/*.sh`
Expected: 干净（无 error/warning 级别问题）。

- [ ] **Step 2: 全量 Bats**

Run: `cd /Users/charliepan/Downloads/linux-one-key && bats tests/unit/*.bats`
Expected: 795 + 10 = **805 全部通过**（新增 10 个 cleanup 用例）。

> 注：计划里 cleanup.bats 有 10 个 @test（3 绑定 + 7 行为）。若实现时数量有出入，以实际通过数为准并如实报告。

- [ ] **Step 3: 提交（如 Task 4 后无未提交改动则跳过）**

```bash
git add -A && git commit -m "chore: verify Lite cleanup (shellcheck + bats 805)"
```

---

## Task 6: 文档 + 版本 bump

**Files:**
- Modify: `scripts/base/utils.sh:20`（`SCRIPT_VERSION="1.7.0"` → `"1.8.0"`）
- Modify: `package.json:3`（`"version": "1.7.0"` → `"1.8.0"`）
- Modify: `HANDOVER.md`（顶栏版本/状态、关键决策表、下一步、Gotchas 补 `_ensure_log_dir` 重建坑）
- Modify: `README.md`（Lite 模式说明补清理行为；测试徽章 795→805；版本历史表加 v1.8.0）
- Modify: `docs/handover-archive.md`（归档 v1.7.0 段落或追加变更说明）

- [ ] **Step 1: 版本号更新**

```bash
cd /Users/charliepan/Downloads/linux-one-key
# utils.sh:20 与 package.json:3 改为 1.8.0
```

- [ ] **Step 2: 更新 HANDOVER.md**
  - 顶栏：版本 `v1.7.0` → `v1.8.0`，状态补「✅ Lite 运行痕迹清理」
  - 项目概要模块列表追加说明、测试数 `795` → `805`
  - 关键决策表追加一行：Lite 清理（独立 cleanup.sh / 退出前询问默认 Y / 保留加固配置）
  - Gotchas 追加：`_ensure_log_dir` 会在 LOG_DIR 删除后重建目录，清理函数与退出路径需兜底删除
  - 下一步更新为 Lite cleanup 已完成的里程碑

- [ ] **Step 3: 更新 README.md**
  - Lite 模式章节补一句：退出时可选择清理运行痕迹（日志/备份/报告 + /tmp 临时文件）
  - 测试徽章 `Tests-720` → `Tests-805`
  - 版本历史表加 `| v1.8.0 | 2026-08-14 | Lite 运行痕迹清理（cleanup.sh + 退出前询问）；805 Bats |`

- [ ] **Step 4: 归档 + 提交**

```bash
cd /Users/charliepan/Downloads/linux-one-key
git add -A
git commit -m "docs: sync HANDOVER/README for v1.8.0 Lite cleanup"
```

- [ ] **Step 5: 将设计文档与实现计划状态置为 done**

更新 `docs/plans/2026-08-14_17-02_lite-runtime-cleanup_nogit.md` 与 `docs/plans/2026-08-14_17-10_lite-runtime-cleanup-impl_nogit.md`：
- frontmatter `status: draft` → `done`、`updated` 刷新
- 各自「进度记录」追加完成条目
- commit：`chore: mark Lite cleanup plans done`

---

## Self-Review（写完后执行）

1. **Spec coverage**（对照设计文档）：
   - 清理边界（LOG_DIR + /tmp askpass/monitor，保留加固配置）→ Task 1/2 ✅
   - 退出前询问默认 Y → Task 4 `confirm ... "y"` ✅
   - 异常/中断不清理 → 未改动 `_cleanup_on_exit`（INT/TERM/ERR 路径），设计符合 ✅
   - 回滚定时器取消 → `_cancel_active_rollback` + Task 1 用例 ✅
   - i18n 对称 → Task 3 ✅
   - 测试 → Task 1 ✅
   - 文档/版本 → Task 6 ✅
2. **Placeholder scan**：无 TBD/TODO；每个步骤含实际命令与代码 ✅
3. **Type consistency**：`cleanup_lite_traces` / `CLEANUP_LOG_DIR` / `CLEANUP_TMP_PATTERNS` / `MSG_CLEANUP_*` 在 Task 1-4 中命名一致；`is_mode_lite` / `confirm` / `log_info` 均为 utils.sh/mode.sh 现有函数 ✅

## 风险与注意事项

- **`_ensure_log_dir` 重建 LOG_DIR**：已通过「清理后兜底 `rm -rf` + `cleaned` 标记」处理；`cleanup_and_exit` 中 GOODBYE 仍走 `log_info`（保持项目约定），由末尾兜底删除保证最终无目录。
- **删除备份 = 失去手动回滚**：用户已确认接受；清理前取消回滚定时器。
- **不误删**：`/tmp` 精确前缀模式；`CLEANUP_LOG_DIR` 严格等于 `LOG_DIR`。
- **失败容忍**：任何删除失败仅 `log_warn`，`cleanup_lite_traces` 恒返回 0，`cleanup_and_exit` 恒 exit 0。
- **`--status` 模式**：不接入清理（诊断用途保留日志）。
- **测试 root 兼容**：失败容忍用例用 mock rm 按路径拦截，root/non-root 均可复现。

## 进度记录

- 2026-08-14: 创建计划，status=draft
- 2026-08-14: Task 1-5 全部完成（RED→GREEN，805 Bats 全绿 = 795+10 cleanup 用例，ShellCheck 干净），Task 6 文档同步 + 版本 bump v1.8.0 完成，status=done

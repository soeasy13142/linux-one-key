---
title: "SSH 回滚保护模块单元测试 (ssh-rollback.bats)"
created: 2026-07-24
updated: 2026-07-24
status: in-progress
source: "PRD §6.3 + ssh.sh rollback enhancement implementation"
topic: "test"
---

# 计划：SSH 回滚保护模块单元测试

## 背景

SSH 锁定防护增强功能（PRD §6.3）已在 `scripts/security/ssh.sh` 中实现，包括以下新增/增强函数：

| 函数 | 行号 | 功能 |
|------|------|------|
| `check_active_ssh_sessions()` | 620-628 | 通过 ss/netstat 检测活动 SSH 会话 |
| `has_console_access()` | 631-639 | 检查物理/IPMI 控制台访问权限 |
| `_monitor_ssh_connections(port, duration, sentinel_file)` | 644-665 | 后台监控新 SSH 连接，检测到后创建哨兵文件 |
| `_restart_and_test_ssh()` | 590-617 | 重启 SSH 后测试新端口连通性 |
| `setup_rollback_timer()` | 694-736 | 增强版：设置回滚定时器 + 启动连接监控 |
| `cancel_rollback_timer()` | 739-753 | 增强版：清理监控 PID + 哨兵文件 |

现有 `tests/unit/ssh.bats` 已包含 11 个 SSH 回滚相关测试（第 161-218 行），但覆盖不够全面。需要新建专用测试文件 `tests/unit/ssh-rollback.bats`，新增约 12-15 个测试用例，深入覆盖各函数的行为路径。

## 目标

1. 创建 `tests/unit/ssh-rollback.bats`，含约 12-15 个测试用例
2. 确保 `tests/unit/ssh.bats` 现有测试不受影响（不删不改）
3. 通过 shellcheck + bats 验证

## 测试文件结构设计

### 文件: `tests/unit/ssh-rollback.bats`

```bash
#!/usr/bin/env bats
# ssh-rollback.bats - SSH 回滚保护模块单元测试
# 测试 scripts/security/ssh.sh 中的回滚保护相关函数

setup() {
    export TEST_DIR="$(mktemp -d)"
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
    export LOG_DIR="${TEST_DIR}/log"
    export BACKUP_DIR="${TEST_DIR}/backups"
    export REPORT_DIR="${TEST_DIR}/reports"
    export LANG_CODE="zh"

    mkdir -p "${LOG_DIR}" "${BACKUP_DIR}" "${REPORT_DIR}"

    source "${SCRIPT_DIR}/scripts/base/utils.sh"
    load_lang "${SCRIPT_DIR}"

    export DETECTED_IS_ROOT="yes"
    is_root() { [[ "${DETECTED_IS_ROOT}" == "yes" ]]; }

    source "${SCRIPT_DIR}/scripts/security/ssh.sh"

    LOG_FILE="${TEST_DIR}/test.log"
}

teardown() {
    rm -rf "${TEST_DIR}"
}
```

### 测试用例清单（14 个）

#### 第一组：常量定义（3 个）

1. **`ROLLBACK_DELAY 等于 300（PRD §6.3）`**
   ```bash
   @test "ssh-rollback: ROLLBACK_DELAY equals 300" {
       [[ "${ROLLBACK_DELAY}" -eq 300 ]]
   }
   ```

2. **`ROLLBACK_SENTINEL 默认为空字符串`**
   ```bash
   @test "ssh-rollback: ROLLBACK_SENTINEL is empty by default" {
       [[ -z "${ROLLBACK_SENTINEL:-}" ]]
   }
   ```

3. **`ROLLBACK_MONITOR_PID 默认为空字符串`**
   ```bash
   @test "ssh-rollback: ROLLBACK_MONITOR_PID is empty by default" {
       [[ -z "${ROLLBACK_MONITOR_PID:-}" ]]
   }
   ```

#### 第二组：函数存在性（4 个）

4. **`check_active_ssh_sessions 函数存在`**
   ```bash
   @test "ssh-rollback: check_active_ssh_sessions function exists" {
       type check_active_ssh_sessions
   }
   ```

5. **`has_console_access 函数存在`**
   ```bash
   @test "ssh-rollback: has_console_access function exists" {
       type has_console_access
   }
   ```

6. **`_monitor_ssh_connections 函数存在`**
   ```bash
   @test "ssh-rollback: _monitor_ssh_connections function exists" {
       type _monitor_ssh_connections
   }
   ```

7. **`_restart_and_test_ssh 函数存在`**
   ```bash
   @test "ssh-rollback: _restart_and_test_ssh function exists" {
       type _restart_and_test_ssh
   }
   ```

#### 第三组：行为测试（7 个）

8. **`check_active_ssh_sessions 无会话时返回 1`**
   - Mock `ss` 命令返回无 ESTABLISHED 连接
   - 预期返回状态 1
   - 注意：ss 命令调用模式是 `ss -tnp 2>/dev/null | grep -c "ESTABLISHED.*:22[[:space:]]"`
   - Mock 需让 grep 返回 0 或空

9. **`check_active_ssh_sessions 有会话时返回 0`**
   - Mock `ss` 命令返回有 ESTABLISHED 连接
   - 预期返回状态 0

10. **`has_console_access 无控制台且无 tty 登录时返回 1`**
    - Mock `/dev/tty1` 和 `/dev/console` 不存在（test 命令返回非 0）
    - Mock `who -a` 返回空
    - 预期返回状态 1

11. **`_monitor_ssh_connections 检测到连接后创建哨兵文件`**
    - Mock `ss -tnp` 返回含指定端口的 ESTABLISHED 连接
    - 调用 `_monitor_ssh_connections <port> 10 <sentinel>`
    - 验证 sentinel 文件被创建
    - 设置超时避免测试挂起

12. **`_monitor_ssh_connections 无连接时不创建哨兵文件并返回 1`**
    - Mock `ss -tnp` 始终返回空（无 ESTABLISHED 连接）
    - 调用 `_monitor_ssh_connections <port> 5 <sentinel>`
    - 验证 sentinel 文件不存在
    - 验证返回状态 1
    - **注意**：此测试需要等待完整的 poll 周期（5 秒），需设置合适的超时

13. **`setup_rollback_timer 设置 ROLLBACK_PID（at 不可用时）`**
    - Mock `command_exists at` 返回 false
    - Mock `get_ssh_port` 返回 2222
    - Mock `_monitor_ssh_connections` 为立即返回
    - 调用 `setup_rollback_timer`
    - 验证 `ROLLBACK_PID` 不为空
    - 验证 `ROLLBACK_SENTINEL` 不为空
    - 验证 `ROLLBACK_MONITOR_PID` 不为空
    - 清理：`cancel_rollback_timer`

14. **`cancel_rollback_timer 清理哨兵文件和监控 PID`**
    - 先手动设置 `ROLLBACK_SENTINEL` 和 `ROLLBACK_MONITOR_PID`
    - 创建哨兵文件
    - 调用 `cancel_rollback_timer`
    - 验证 `ROLLBACK_SENTINEL` 文件被删除
    - 验证清理后全局变量仍可读

### 与 ssh.bats 的重叠处理

`ssh.bats` 第 161-218 行已有 11 个 SSH 回滚相关测试。**处理原则：保留所有现有测试不变**，ssh-rollback.bats 作为补充覆盖，不改变 ssh.bats。

重叠映射：

| ssh.bats 行号 | 测试用例 | 在 ssh-rollback.bats 中 |
|---------------|----------|------------------------|
| 161-163 | `_restart_and_test_ssh function exists` | 保留，新增 #7 |
| 164-166 | `check_active_ssh_sessions function exists` | 保留，新增 #4 |
| 167-171 | `has_console_access function exists` | 保留，新增 #5 |
| 172-179 | `check_active_ssh_sessions returns 0 when no sessions` | 保留，新增 #8（修正预期值） |
| 180-194 | `has_console_access handles no console users` | 保留，新增 #10 |
| 195-198 | `cancel_rollback_timer function still exists` | 保留 |
| 199-202 | `setup_rollback_timer function still exists` | 保留 |
| 203-206 | `ROLLBACK_DELAY is 300` | 保留，新增 #1 |
| 207-210 | `_monitor_ssh_connections function exists` | 保留，新增 #6 |
| 211-214 | `ROLLBACK_SENTINEL is empty string by default` | 保留，新增 #2 |
| 215-218 | `ROLLBACK_MONITOR_PID is empty string by default` | 保留，新增 #3 |

> **注意**：ssh.bats 第 172-179 行测试名称为 "returns 0 when no sessions" 但 expect `status -eq 1`。这是正确的（函数在无会话时 return 1），但测试名称容易误导。ssh-rollback.bats 中统一使用清晰命名 "#8: check_active_ssh_sessions 无会话时返回 1"。

## 执行步骤

```
Step 1: 创建 tests/unit/ssh-rollback.bats
  └── 1a. 编写 setup/teardown 函数
  └── 1b. 编写常量测试（3 个）
  └── 1c. 编写函数存在性测试（4 个）
  └── 1d. 编写行为测试（7 个）
  └── 1e. shellcheck 验证
  └── 1f. bats 运行验证

Step 2: 验证 ssh.bats 不受影响
  └── 2a. 运行 bats tests/unit/ssh.bats，确认全部通过

Step 3: 全量验证
  └── 3a. shellcheck -x tests/unit/ssh-rollback.bats
  └── 3b. bats tests/unit/ssh-rollback.bats
  └── 3c. bats tests/unit/ssh.bats（无回归）
  └── 3d. bats tests/unit/*.bats（全量无回归）
```

## 预期产出

| 操作 | 涉及文件 |
|------|---------|
| **创建** | `tests/unit/ssh-rollback.bats`（约 200-250 行） |
| **保持不变** | `tests/unit/ssh.bats` |
| **运行验证** | shellcheck + bats 通过 |

### 新增测试文件统计

| 类别 | 数量 | 说明 |
|------|------|------|
| 常量测试 | 3 | ROLLBACK_DELAY, ROLLBACK_SENTINEL, ROLLBACK_MONITOR_PID |
| 函数存在性测试 | 4 | check_active_ssh_sessions, has_console_access, _monitor_ssh_connections, _restart_and_test_ssh |
| 行为测试 | 7 | 返回值、哨兵文件创建/不创建、PID 设置、清理 |
| **合计** | **14** | 覆盖全部 SSH 回滚保护函数的核心行为路径 |

## 风险与注意事项

### 风险 1：`_monitor_ssh_connections` 行为测试的计时问题
`_monitor_ssh_connections` 内部有 `sleep "${poll_interval}"`（5 秒），无连接时的测试需要等待完整 poll 周期。解决方案：
- 在第 12 号测试（无连接场景）中设置 Bats 超时 `export BATS_TIMEOUT=15`
- 或者将 `poll_interval` 作为可覆盖变量（但不建议改动生产代码）
- **推荐方案**：使用 `timeout` 命令包装，或利用短 duration（3-5 秒）+ 短 poll 间隔

### 风险 2：Mock 需要完整覆盖 ss/who 命令
`check_active_ssh_sessions` 使用 `ss -tnp`，`has_console_access` 使用 `who -a`。测试环境可能没有 ss 命令或输出格式不同。解决方案：
- 在函数级 mock（`function ss() { ... }; export -f ss`）
- 确保 mock 覆盖 `command_exists ss` 的检测（直接 mock 函数即可，因为 `command_exists` 检查 `type -t`）

### 风险 3：setup_rollback_timer 产生后台进程
`setup_rollback_timer` 在 `at` 不可用时启动后台进程（`_monitor_ssh_connections &` + `( sleep... ) &`）。测试结束后需要清理，否则产生僵尸进程。解决方案：
- 每个创建后台进程的测试必须在 teardown 或测试末尾调用 `cancel_rollback_timer`
- 测试 13 末尾必须调用 `cancel_rollback_timer`

### 风险 4：/dev/tty1 和 /dev/console 可能在测试环境存在
`has_console_access` 首先检查 `[[ -c /dev/tty1 ]] || [[ -c /dev/console ]]`。MacOS CI 或无 tty 的 Docker 容器通常没有这些设备，但某些 Linux 环境可能有。解决方案：
- 测试中 mock `has_console_access` 函数本身（类似 ssh.bats 第 185-193 行的做法）
- 或者使用 subshell 测试，避免影响外部环境

### 风险 5：测试名称与实际行为的一致性
`check_active_ssh_sessions` 在**有**会话时返回 0（成功），**无**会话时返回 1（失败）。测试名称必须准确反映行为，避免混淆。

## 验证命令

```bash
# ShellCheck 验证
shellcheck -x tests/unit/ssh-rollback.bats

# Bats 验证（新文件）
bats tests/unit/ssh-rollback.bats

# Bats 验证（现有文件无回归）
bats tests/unit/ssh.bats

# 全量无回归
bats tests/unit/*.bats
```

## 进度记录

- 2026-07-24: 创建计划，status=draft

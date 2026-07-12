---
title: "Round 4 Code Review 修复计划"
created: 2026-07-12
updated: 2026-07-12
status: done
source: "docs/code-reviews/round-4-comprehensive.md — 全项目 Code Review 发现 88 个问题"
topic: "code-review"
---

# Round 4 Code Review 修复计划

## 背景

2026-07-11 完成的 Round 4 全项目 Code Review 发现 **4 CRITICAL + 22 HIGH + 41 MEDIUM + 21 LOW** 共 88 个问题（6 组并行审查，覆盖 17 个脚本 + 14 个测试文件 + 5 个配置文件模板）。

Round 3 的 11 个发现已全部修复，本次审查范围扩大至测试文件、配置模板和 i18n。目前仅审查已完成（`full-code-review-n4_nogit.md` status=done），**修复尚未开始**。

## 范围

本次修复覆盖 Round 4 报告中**全部 88 个问题**，按严重程度分阶段推进。

## 执行阶段

### Phase 1: 🔴 CRITICAL（4 个）

| 编号 | 文件 | 问题 | 修复方案 |
|------|------|------|----------|
| C1 | `scripts/security/ssh.sh:585` | `at now + 5 minutes` 硬编码，与 `ROLLBACK_DELAY=600` 不一致 | 替换为 `at now + $(( ROLLBACK_DELAY / 60 )) minutes` |
| C2 | `scripts/security/firewall.sh:125` | `ufw status` grep 依赖英文语言环境 | `LC_ALL=C ufw status \| grep -q "Status: active"` |
| C3 | `tests/unit/firewall.bats:57-85` | mock 了不存在的 `_get_current_ssh_port` | 移除无意义测试，或用 `get_ssh_port()` 替换 |
| C4 | `tests/unit/fail2ban.bats:36-64` | mock 了不存在的 `_get_ssh_port` | 移除无意义测试，或用 `get_ssh_port()` 替换 |

### Phase 2: 🟠 HIGH（22 个）

按修复类别分组：

**组 A: Source Guard 缺失（H1, H2）**
- `scripts/base/init.sh` — 添加 source guard
- `scripts/base/report.sh` — 添加 source guard

**组 B: 错误处理缺陷（H3, H6, H7, H13）**
- H3: `scripts/base/init.sh:47-48` — `apt-get update` 包裹 `if` 保护
- H6: `scripts/security/firewall.sh:394` — `enable_firewall()` 返回值检查
- H7: `scripts/security/fail2ban.sh:39-41` — `yum` → `command_exists dnf` fallback
- H13: `scripts/security/audit.sh:387` — `ausearch` 附加 `|| true`

**组 C: i18n 绕过（H5）**
- H5: `scripts/security/fail2ban.sh:78,237-239,296-297` — 硬编码中文 → MSG_*

**组 D: 死代码（H4）**
- H4: `install.sh:459-480` — filesystem GREEN 分支不可达 → 添加 GREEN 条件或移除死分支

**组 E: 测试增强（H8, H9, H10, H11, H12）**
- H8: 多个 `.bats` — 向导函数行为测试
- H9: `tests/unit/filesystem.bats:106-113` — 添加正向测试
- H10: `tests/unit/filesystem.bats:88-94` — 断言实际预期值
- H11: `tests/unit/services.bats:188-208` — 统一 `run`
- H12: `tests/unit/utils.bats:63-67` — `log_info` 测试使用 `run`

**组 F: 配置模板不同步（H14, H15）**
- H14: `config/audit/audit.rules` — 添加 execve 规则
- H15: `config/audit/audit.rules` — 添加 b32 架构变体

### Phase 3: 🟡 MEDIUM（41 个）

按类别分组：

- **i18n 统一**: install.sh + ssh.sh + users.sh + kernel.sh + audit.sh + report.sh + fail2ban.sh 中约 30 处硬编码字符串 → MSG_*
- **代码质量**: M1 get_os_type 重复、M2 日志头部覆盖、M3 SSH 端口 sed 模式、M8 未使用的参数、M9 顺序问题、M10 /tmp 可预测路径、M11 验证不完整、M14-M17 死代码/硬编码
- **测试改进**: M20 重复测试、M21-M26 测试脆弱性
- **配置同步**: M27-M28 jail.local、M29-M30 gen-file-tree.sh
- **过期清理**: M18 59 个未引用 MSG_* key、M19 步骤编号

### Phase 4: 🔵 LOW（21 个）

- 风格不一致（引号、缩进）
- 注释过期或不完整
- 嵌套函数泄漏到全局作用域
- 测试隔离边界清理
- 其他小问题

## 实施顺序

```
Phase 1 (CRITICAL) → Phase 2 (HIGH) → Phase 3 (MEDIUM) → Phase 4 (LOW)
```

每 phase 内按文件分组提交，每个最小改动单元一次独立 commit。

## 相关文件

- `scripts/security/ssh.sh` — C1, H5(部分)
- `scripts/security/firewall.sh` — C2, H6
- `scripts/security/fail2ban.sh` — H5, H7
- `scripts/security/audit.sh` — H13
- `scripts/base/init.sh` — H1, H3
- `scripts/base/report.sh` — H2
- `install.sh` — H4
- `scripts/lang/zh.sh` / `scripts/lang/en.sh` — H5(新键), M18-M19
- `config/audit/audit.rules` — H14-H15
- `config/fail2ban/jail.local` — M27-M28
- `tests/unit/firewall.bats` — C3
- `tests/unit/fail2ban.bats` — C4
- `tests/unit/filesystem.bats` — H9, H10
- `tests/unit/services.bats` — H11
- `tests/unit/utils.bats` — H12
- `tests/unit/system-status.bats` — M21-M22
- `tests/unit/parse-args.bats` — M23
- `tests/unit/view-report.bats` — M24
- `tests/unit/audit.bats` — M25
- `scripts/dev/gen-file-tree.sh` — M29-M30
- 其他测试和源文件 — H8, M20, M26, LOW 项

## 预期产出

- 所有 88 个问题已修复或已验证无需修复
- `shellcheck -x scripts/**/*.sh` 通过
- `bats tests/unit/*.bats` 全部通过
- i18n 完整性检查通过
- `HANDOVER.md` 变更日志已更新
- 本 plan 文件已标记 `status: done`

## 风险与注意事项

- **C2 改动影响大**: UFW 语言环境修复涉及防火墙核心路径，需确保回归安全
- **H5 i18n 绕过**: 需同步更新 `zh.sh` + `en.sh`，保持对称
- **H14-H15 模板同步**: 修改后需确认与 `audit.sh` 生成规则一致
- **M10 可预测路径**: 涉及安全风险，优先修复
- **M18 过期 key**: 确认 key 确未引用后再删除，避免遗漏

## 进度记录

- 2026-07-12: 创建计划，status=draft
- 2026-07-12: 用户确认，status=in-progress
- 2026-07-12: Phase 1 (CRITICAL) 完成 — C1 SSH timer fix, C2 UFW locale fix, C3-C4 remove fake test mocks
- 2026-07-12: Phase 2 (HIGH) 完成 — H1+H3 init.sh source guard + apt protection, H2 report.sh source guard, H4 install.sh GREEN dead code, H5+H7 fail2ban.sh i18n + dnf fallback, H6 firewall.sh return check, H13 audit.sh ausearch fix, H14+H15 audit.rules template sync, H9+H10 filesystem.bats tests, H11 services.bats run consistency, H12 utils.bats log_info test
- 2026-07-12: Phase 4 (LOW) 完成 — detect_arch error return + /proc guards + nested func extract + test isolation teardown + style/comment cleanup

## 完成摘要

全部 88 个 Round 4 Code Review 问题已修复。25 个 SubAgent 并行执行，覆盖 17 个源文件 + 14 个测试文件 + 5 个配置文件模板。
- 🔴 CRITICAL: 4/4 ✅ | 🟠 HIGH: 22/22 ✅ | 🟡 MEDIUM: 41/41 ✅ | 🔵 LOW: 21/21 ✅
- 最终验证: bats 242/242 通过, shellcheck 无新增 warning

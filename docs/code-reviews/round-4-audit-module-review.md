# Code Review: v0.4 Audit Module (Commit d007088)

**Reviewed**: 2026-06-24
**Commit**: `d007088` — feat: add audit logging module (v0.4)
**Author**: soeasy13142
**Decision**: **REQUEST CHANGES** — 1 HIGH + 3 MEDIUM + 2 LOW

---

## Summary

审计日志模块整体实现质量良好，代码结构清晰，i18n 完整（中英各 47 条），测试覆盖 44 个用例。发现 1 个命令拼写错误（HIGH）、1 个缺少 default 分支的逻辑缺陷（MEDIUM）、以及若干小问题。

---

## Findings

### HIGH

#### H1 — `auseport` 拼写错误（中文翻译）

- **文件**: `scripts/lang/zh.sh:435`
- **问题**: `auseport` 应为 `aureport`。这是一个不存在的命令，用户复制粘贴后会执行失败。
- **当前代码**:
  ```bash
  MSG_REPORT_WARN_AUDIT="请定期检查审计日志: sudo auseport --summary 或 sudo ausearch -k identity"
  ```
- **修复**:
  ```bash
  MSG_REPORT_WARN_AUDIT="请定期检查审计日志: sudo aureport --summary 或 sudo ausearch -k identity"
  ```
- **注意**: 英文翻译 `en.sh:435` 是正确的（`aureport`），仅中文有误。

---

### MEDIUM

#### M1 — `_generate_audit_rules` 缺少 `default` 分支

- **文件**: `scripts/security/audit.sh:188-198`
- **问题**: `case "${level}"` 没有 `*)` 兜底分支。如果传入无效级别，会生成一个只有头部和 `-e 2`（不可变标志）的空规则文件，锁定系统审计配置为"无规则"状态。
- **影响**: 虽然当前调用方（向导）已做验证，但 `_generate_audit_rules` 作为内部函数应自保防御。
- **建议修复**:
  ```bash
  case "${level}" in
      "${AUDIT_LEVEL_BASIC}")
          _generate_basic_rules
          ;;
      "${AUDIT_LEVEL_STANDARD}")
          _generate_standard_rules
          ;;
      "${AUDIT_LEVEL_FULL}")
          _generate_full_rules
          ;;
      *)
          log_warn "Unknown audit level '${level}', falling back to standard"
          _generate_standard_rules
          ;;
  esac
  ```

#### M2 — 主菜单报告选项缺少描述文本

- **文件**: `install.sh:416-417`
- **问题**: 菜单项 `[7] 查看上次加固报告` 没有像其他菜单项那样显示描述文本。其他菜单项都有 `MSG_MAIN_MENU_*_DESC`，但报告项没有。
- **建议**: 在 `zh.sh` 和 `en.sh` 中添加 `MSG_MAIN_MENU_REPORT_DESC`，并在 `install.sh` 中显示。

#### M3 — 测试未覆盖 `_generate_standard_rules` 不含 `modules` 键

- **文件**: `tests/unit/audit.bats`
- **问题**: 测试验证了 `_generate_full_rules` 包含 `modules` 键，但没有反向验证 `_generate_standard_rules` **不包含** `modules` 键。这降低了对规则级别隔离的测试信心。
- **建议添加**:
  ```bash
  @test "_generate_standard_rules excludes modules key" {
      result=$(_generate_standard_rules)
      [[ "${result}" != *"modules"* ]]
  }
  ```

---

### LOW

#### L1 — `_generate_audit_rules` 的 `mkdir -p` 静默忽略错误

- **文件**: `scripts/security/audit.sh:170`
- **问题**: `mkdir -p "${AUDIT_RULES_DIR}" 2>/dev/null || true` 将所有错误静默吞掉。如果目录创建失败（如权限不足），后续写入会失败但错误信息不明确。
- **建议**: 至少记录到日志：
  ```bash
  mkdir -p "${AUDIT_RULES_DIR}" >> "${LOG_FILE}" 2>&1 || {
      log_warn "Failed to create ${AUDIT_RULES_DIR}, trying anyway"
  }
  ```

#### L2 — `config/audit/audit.rules` 模板与代码生成的规则不完全一致

- **文件**: `config/audit/audit.rules`
- **问题**: 模板文件注释说"仅作参考"，但模板中的规则是 `full` 级别，而代码默认生成 `standard` 级别。模板中也没有 `boot_script` 和 `NetworkManager` 监控（standard 级别有），但有 `perm_change`/`owner_change`/`time_change`/`mount`/`file_delete`（这些是 full 级别才有）。可能造成用户混淆。
- **建议**: 在模板文件头部更明确标注这是 `full` 级别示例，或分别提供三个级别的模板。

---

## Validation

| 检查项 | 结果 |
|--------|------|
| ShellCheck (audit.sh) | 未运行（需手动验证） |
| Bats 测试 | 未运行（需手动验证） |
| i18n 一致性 | ✅ 通过（中英各 47 条 MSG_AUDIT_*，key 完全匹配） |
| 菜单编号一致性 | ✅ 通过（主菜单 [0-7]、向导 [1/5]-[5/5] 均正确更新） |
| 源码守卫 | ✅ 通过（`_UTILS_LOADED`、`_AUDIT_LOADED`、`_REPORT_LOADED`） |

---

## Files Reviewed

| 文件 | 变更类型 | 行数 |
|------|----------|------|
| `scripts/security/audit.sh` | 新增 | 498 |
| `tests/unit/audit.bats` | 新增 | 355 |
| `config/audit/audit.rules` | 新增 | 62 |
| `config/audit/auditd.conf` | 新增 | 71 |
| `scripts/lang/zh.sh` | 修改 | +62 |
| `scripts/lang/en.sh` | 修改 | +62 |
| `install.sh` | 修改 | +38 |
| `scripts/base/report.sh` | 修改 | +23 |
| `HANDOVER.md` | 修改 | +29 |

---

## Next Steps

1. **必须修复**: H1（`auseport` 拼写错误）— 直接影响用户体验
2. **建议修复**: M1（default 分支）、M2（菜单描述）、M3（补充测试）
3. **可选修复**: L1、L2

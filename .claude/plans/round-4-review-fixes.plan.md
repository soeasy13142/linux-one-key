# Plan: Round 4 Code Review Fixes

**Source**: `docs/code-reviews/round-4-audit-module-review.md`
**Complexity**: Small

## Summary

修复 v0.4 审计模块 Code Review 发现的 6 个问题（1 HIGH + 3 MEDIUM + 2 LOW），涉及 5 个文件的微调。

## Patterns to Mirror

| Category | Source | Pattern |
|---|---|---|
| i18n | `scripts/lang/zh.sh:70-77` | `MSG_MAIN_MENU_*` + `MSG_MAIN_MENU_*_DESC` 成对定义 |
| Menu display | `install.sh:407-414` | `echo -e "  ${GREEN}${MSG_*}${NC}"` + `echo -e "      ${MSG_*_DESC}"` |
| Error handling | `scripts/security/audit.sh:255` | `if ! cmd; then log_warn "..."; fi` |
| Test style | `tests/unit/audit.bats:88-91` | `result=$(func); [[ "${result}" != *"key"* ]]` |

## Files to Change

| File | Action | Why |
|---|---|---|
| `scripts/lang/zh.sh` | UPDATE | H1: 修复 `auseport` 拼写; M2: 添加 `MSG_MAIN_MENU_REPORT_DESC` |
| `scripts/lang/en.sh` | UPDATE | M2: 添加 `MSG_MAIN_MENU_REPORT_DESC` |
| `scripts/security/audit.sh` | UPDATE | M1: 添加 `case` default 分支; L1: 改进 `mkdir` 错误处理 |
| `tests/unit/audit.bats` | UPDATE | M3: 添加 standard 规则不含 modules 的测试 |
| `config/audit/audit.rules` | UPDATE | L2: 明确标注模板为 full 级别示例 |
| `install.sh` | UPDATE | M2: 显示报告菜单描述文本 |
| `HANDOVER.md` | UPDATE | 记录修复变更 |

## Tasks

### Task 1: H1 — 修复 `auseport` 拼写错误
- **File**: `scripts/lang/zh.sh:435`
- **Action**: `auseport` → `aureport`
- **Validate**: `grep "auseport" scripts/lang/zh.sh` 返回空

### Task 2: M1 — 添加 `case` default 分支
- **File**: `scripts/security/audit.sh:188-198`
- **Action**: 在 `case` 末尾添加 `*) log_warn "..."; _generate_standard_rules ;;`
- **Validate**: 代码审查确认

### Task 3: M2 — 添加报告菜单描述
- **Files**: `scripts/lang/zh.sh`, `scripts/lang/en.sh`, `install.sh`
- **Action**:
  - zh.sh: 在 `MSG_MAIN_MENU_REPORT` 后添加 `MSG_MAIN_MENU_REPORT_DESC`
  - en.sh: 同上
  - install.sh: 在报告菜单项后添加描述行
- **Validate**: `grep "MSG_MAIN_MENU_REPORT_DESC" scripts/lang/zh.sh scripts/lang/en.sh install.sh`

### Task 4: M3 — 补充测试
- **File**: `tests/unit/audit.bats`
- **Action**: 添加 `_generate_standard_rules excludes modules key` 测试
- **Validate**: `bats tests/unit/audit.bats` 通过

### Task 5: L1 — 改进 `mkdir` 错误处理
- **File**: `scripts/security/audit.sh:170`
- **Action**: 将 `2>/dev/null || true` 改为记录到日志
- **Validate**: 代码审查确认

### Task 6: L2 — 标注模板级别
- **File**: `config/audit/audit.rules`
- **Action**: 在头部注释中标注这是 full 级别示例
- **Validate**: 代码审查确认

### Task 7: 更新 HANDOVER.md
- **Action**: 记录所有修复到变更日志

## Validation

```bash
# 1. 确认拼写修复
grep "auseport" scripts/lang/zh.sh  # 应返回空

# 2. 确认 i18n 变量存在
grep "MSG_MAIN_MENU_REPORT_DESC" scripts/lang/zh.sh scripts/lang/en.sh install.sh

# 3. 运行测试
bats tests/unit/audit.bats

# 4. ShellCheck
shellcheck scripts/security/audit.sh
```

## Acceptance

- [ ] H1: `auseport` 已修复
- [ ] M1: `case` 有 default 分支
- [ ] M2: 报告菜单有描述文本
- [ ] M3: 测试覆盖 standard 不含 modules
- [ ] L1: mkdir 错误有日志
- [ ] L2: 模板标注级别
- [ ] HANDOVER.md 已更新

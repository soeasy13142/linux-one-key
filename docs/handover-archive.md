# HANDOVER.md 历史变更日志归档

> ⚠️ **本文件不是删除，是归档**。所有历史变更日志完整保留，仅从主 `HANDOVER.md` 移出以精简上下文加载。
> 
> 检索方式：直接用 grep / IDE 全文搜索本文件；或通过 git 历史（`git log --all --diff-filter=AMD -- '*'`）查找。

---

## 归档信息

---

| 项 | 值 |
|---|---|
| 归档日期 | 2026-07-10（首次）/ 2026-07-24（二次：HANDOVER.md 精简重构，追加 ~170 条） |
| 归档原因 | HANDOVER.md 按 Claude Code 规范精简为 ~70 行状态快照，所有 changelog 归入本文件 |
| 归档范围 | 2026-06-20 ~ 2026-07-24（项目搭建期 → v1.0.1 完整历程） |
| 归档条数 | ~346 条 |
| 主文件 | 不再保留 changelog（git log 替代），仅保留状态/决策/下一步 |

---

## Batch 2: Security & Infrastructure Enhancement (2026-07-24)

**功能变更**:
- **backup.sh / rollback.sh 提取** (WS1): 从 `utils.sh` 提取 `backup_file()`/`restore_file()` → `scripts/base/backup.sh`；提取 `schedule_rollback()`/`cancel_scheduled_task()` → `scripts/base/rollback.sh`。utils.sh 通过 source 向后兼容加载
- **SSH 锁定防护增强** (WS2): 新增 `_restart_and_test_ssh()` 重启后连接测试，`_start_connection_watch()` 监控 auth.log 自动取消回滚，`check_active_ssh_sessions()`/`has_console_access()` 辅助函数。Full 模式增强，Lite 模式保持原有流程
- **自动安全更新** (WS3): 新建 `scripts/security/autoupdate.sh` 模块，支持 unattended-upgrades (Debian/Ubuntu) 和 yum-cron (CentOS/RHEL) 配置
- **菜单编号变更**: 新增自动安全更新 [10] → 完整向导 [11] → 查看报告 [12] → K3s [13]

**文件变更**:
- 新增: `backup.sh`, `rollback.sh`, `autoupdate.sh`, `backup.bats` (15 cases), `rollback.bats` (9 cases), `autoupdate.bats` (18 cases)
- 修改: `utils.sh`, `ssh.sh`, `install.sh`, `mode.sh`, `report.sh`, `zh.sh`, `en.sh`, `utils.bats`, `ssh.bats`, `mode.bats`, `HANDOVER.md`

**测试**: 365/365 全部通过 | **ShellCheck**: 全部通过

---

## 归档日志

| 日期 | 操作 | 文件 | 说明 |
|------|------|------|------|
| 2026-06-20 | CREATE | `.claude/prds/linux-security-hardening.prd.md` | 编写完整 PRD |
| 2026-06-20 | CREATE | `HANDOVER.md` | 创建交接文档 |
| 2026-06-20 | CREATE | `.claude/rules/common/handover.md` | 添加交接文档更新规则 |
| 2026-06-20 | UPDATE | `.claude/CLAUDE.md` | 添加交接文档强制规则 |
| 2026-06-20 | CREATE | `.claude/commands/feature-development.md` | 功能开发命令（基于 ECC 定制） |
| 2026-06-20 | CREATE | `.claude/commands/database-migration.md` | 数据库迁移命令（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/commands/add-language-rules.md` | 添加语言规则命令（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/rules/common/guardrails.md` | 安全防护规则（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/rules/common/node.md` | Node.js 规则（来自 ECC） |
| 2026-06-20 | CREATE | `.claude/research/research-playbook.md` | 研究工作流指南（来自 ECC） |
| 2026-06-20 | CREATE | `scripts/base/utils.sh` | 工具函数库（颜色、日志、备份、SSH配置辅助） |
| 2026-06-20 | CREATE | `scripts/base/detect.sh` | 系统检测模块（OS、权限、网络、包管理器） |
| 2026-06-20 | CREATE | `scripts/base/init.sh` | 系统初始化模块（目录创建、系统更新） |
| 2026-06-20 | CREATE | `scripts/security/ssh.sh` | SSH 安全加固模块（端口、密钥、root/密码登录） |
| 2026-06-20 | CREATE | `install.sh` | 主入口脚本（4模式菜单、交互流程） |
| 2026-06-20 | CREATE | `scripts/lang/zh.sh` | 中文翻译文件 |
| 2026-06-20 | CREATE | `scripts/lang/en.sh` | 英文翻译文件 |
| 2026-06-20 | CREATE | `tests/unit/utils.bats` | 工具函数单元测试（19个用例） |
| 2026-06-20 | UPDATE | `HANDOVER.md` | 更新进度和文件清单 |
| 2026-06-20 | UPDATE | `install.sh` | 重新设计菜单，快速开始+自定义配置 |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | 添加 run_ssh_hardening_custom 函数 |
| 2026-06-20 | CREATE | `scripts/security/firewall.sh` | 防火墙配置模块（支持 UFW/firewalld） |
| 2026-06-20 | CREATE | `scripts/security/fail2ban.sh` | Fail2Ban 入侵防护模块 |
| 2026-06-20 | CREATE | `config/fail2ban/jail.local` | Fail2Ban jail 配置模板 |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | 添加防火墙和 Fail2Ban 中文翻译 |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | 添加防火墙和 Fail2Ban 英文翻译 |
| 2026-06-20 | UPDATE | `install.sh` | 集成防火墙和 Fail2Ban 到菜单流程 |
| 2026-06-20 | CREATE | `tests/unit/firewall.bats` | 防火墙模块单元测试（9个用例） |
| 2026-06-20 | CREATE | `tests/unit/fail2ban.bats` | Fail2Ban 模块单元测试（18个用例） |
| 2026-06-20 | UPDATE | `install.sh` | 修复 curl 管道模式两个 bug：(1) BASH_SOURCE 在函数内外行为不一致导致管道检测失败，改为顶层捕获；(2) exec 后 stdin 为 EOF，添加 /dev/tty 重定向支持交互输入 |
| 2026-06-20 | UPDATE | `HANDOVER.md` | 更新交接文档，记录 curl 管道模式修复 |
| 2026-06-20 | UPDATE | `.claude/prds/linux-security-hardening.prd.md` | 添加"已知问题与修复记录"章节，记录 curl 管道模式两个 bug 的根因和修复方案 |
| 2026-06-20 | UPDATE | `scripts/security/firewall.sh` | C1: 修复 DETECT_OS → DETECTED_OS 变量名不匹配（2 处），防火墙模块现已正常工作 |
| 2026-06-20 | UPDATE | `scripts/security/fail2ban.sh` | C1: 修复 DETECT_OS → DETECTED_OS（3 处）；H2: banaction 按 OS 自动选择（ufw/firewallcmd-ipset/iptables-multiport），修复 Ubuntu/Debian 封禁失效 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | C2: set_ssh_config 正则添加词边界，防止 Port 误匹配 PortForwarding 等 |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | H1: 修复回滚定时器永不取消；M10: 密码认证禁用后验证；M11: check_other_users awk；M12: FIDO2/SK 密钥；M13: 密钥去重；L1: 端口八进制 |
| 2026-06-20 | UPDATE | `install.sh` | H4: bootstrap 临时目录清理；H5: tarball 完整性校验（SHA256SUMS）；H6: 报告仅在成功时生成；L2: default 分支；L3: 移除冗余初始化 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | H3: 移除 -u；M1: eval 替换；M2: fallback 警告；M3: load_lang 校验；L9: printf 替代 echo -e |
| 2026-06-20 | UPDATE | `scripts/base/detect.sh` | H7: /etc/os-release 子 shell 隔离 |
| 2026-06-20 | UPDATE | `scripts/base/init.sh` | M4: 移除 --only-upgrade；M5: yum-security 检查；M6: root 检查前置；M7: 更新失败不打印成功；L7: 调用 setup_timezone |
| 2026-06-20 | UPDATE | `scripts/security/firewall.sh` | M8: 安装后启动 firewalld；M9: root 权限检查 |
| 2026-06-20 | UPDATE | `scripts/security/fail2ban.sh` | M9: root 权限检查；M14: journald 警告；L4: 简化 _get_ssh_service_name |
| 2026-06-20 | CREATE | `SHA256SUMS` | 关键文件 SHA-256 校验收录，用于 tarball 完整性验证 |
| 2026-06-20 | CREATE | `docs/bug-review-report.md` | 全面 Code Review 报告，记录 2 CRITICAL + 7 HIGH + 14 MEDIUM + 9 LOW 级别 bug，含修复方案和优先级计划 |
| 2026-06-20 | CREATE | `docs/code-review-report-20260620.md` | 第二轮 Code Review 综合报告，3 代理并行（安全/质量/静默失败），发现 10 CRITICAL + 15 HIGH + 13 MEDIUM + 12 LOW，共 50 个问题 |
| 2026-06-20 | UPDATE | `HANDOVER.md` | 记录第二轮 Code Review 结果、更新进度状态和下一步工作 |
| 2026-06-20 | CREATE | `.claude/prds/main-menu-redesign.prd.md` | 主菜单入口重设计 PRD |
| 2026-06-20 | CREATE | `.claude/plans/main-menu-redesign.plan.md` | 主菜单入口重设计实施计划 |
| 2026-06-20 | UPDATE | `install.sh` | 重构主入口：主菜单循环、SSH/防火墙子菜单、系统状态检测、查看报告、非交互参数扩展 |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | 新增主菜单、子菜单、状态检测等翻译键 (~45 条) |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | 新增对应英文翻译键 (~45 条) |
| 2026-06-20 | UPDATE | `install.sh` | 移除未定义的 log_debug 调用；curl 管道模式自动追加 --yes |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | 新增 get_ssh_port() 公共函数 |
| 2026-06-20 | UPDATE | `scripts/base/init.sh` | set -euo → set -eo，统一 set 选项 |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | set -euo → set -eo；移除重复的 get_ssh_port() |
| 2026-06-20 | UPDATE | `scripts/security/firewall.sh` | set -euo → set -eo；移除独立 source 逻辑和重复函数；改用 get_ssh_port() |
| 2026-06-20 | UPDATE | `scripts/security/fail2ban.sh` | set -euo → set -eo；移除独立 source 逻辑和重复函数；改用 get_ssh_port() |
| 2026-06-20 | UPDATE | `SHA256SUMS` | 重新生成，补充 lang/zh.sh 和 lang/en.sh |
| 2026-06-20 | UPDATE | `README.md` | 补充 -s -- --yes 和 --ssh 参数传递示例 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | 修复 curl 管道模式无限递归 bug：_ensure_log_dir 防重入保护 + init_logging 优雅降级 |
| 2026-06-20 | CREATE | `docs/test-report-20260620.md` | Ubuntu 24.04 ARM64 真机测试报告：发现 2 CRITICAL + 3 HIGH + 3 MEDIUM + 1 LOW，curl 管道模式不可用 + SSH 回滚失效 |
| 2026-06-20 | UPDATE | `install.sh` | Bug #1/#3/#4: SHA256SUMS URL 改用 raw URL + grep 管道添加 \|\| true 防御 |
| 2026-06-20 | UPDATE | `scripts/base/utils.sh` | Bug #2/#6/#7: log 函数统一输出到 stderr + schedule_rollback 防 PID 污染 + sleep&&callback |
| 2026-06-20 | UPDATE | `scripts/security/ssh.sh` | Bug #5: restart_ssh 自动检测 ssh vs sshd 服务名，消除 Ubuntu 误导错误 |
| 2026-06-20 | UPDATE | `scripts/base/detect.sh` | Bug #8: print_detection_summary 标题改用 MSG_DETECTION_SUMMARY i18n |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | Bug #8: 新增 MSG_DETECTION_SUMMARY 翻译 |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | Bug #8: 新增 MSG_DETECTION_SUMMARY 翻译 |
| 2026-06-20 | UPDATE | install.sh, scripts/security/*.sh, scripts/base/utils.sh, scripts/lang/*.sh | 删除一键模式(--yes/--quick)，改为逐步交互式配置；新增随机端口生成；SSH端口支持3选1交互(自定义/随机/保持)；Fail2Ban参数可自定义；新增完整安全配置向导 |
| 2026-06-20 | CREATE | `docs/vm-test-report-20260620.md` | curl 方式综合测试报告：15 个测试用例、8 个新问题（1 HIGH + 4 MEDIUM + 3 LOW），含报告硬编码 bug、Bats 27/46 失败等 |
| 2026-06-20 | UPDATE | `install.sh` | P0 Issue #2 修复：generate_report() 动态生成，根据 _WIZARD_*_DONE 标志和实际系统状态，跳过步骤显示 [⊘] |
| 2026-06-20 | UPDATE | `tests/unit/fail2ban.bats` | P0 Issue #8 修复：source utils.sh + load_lang；修复 DETECT_OS→DETECTED_OS；修复 run_fail2ban_hardening_custom→run_fail2ban_wizard；添加 get_ssh_port mock |
| 2026-06-20 | UPDATE | `tests/unit/firewall.bats` | P0 Issue #8 修复：source utils.sh + load_lang；修复 DETECT_OS→DETECTED_OS |
| 2026-06-20 | UPDATE | `scripts/lang/zh.sh` | 新增 MSG_WIZARD_SKIPPED="已跳过" |
| 2026-06-20 | UPDATE | `scripts/lang/en.sh` | 新增 MSG_WIZARD_SKIPPED="Skipped" |
| 2026-06-21 | UPDATE | `scripts/base/utils.sh` | 修复 get_os_type()/get_os_version() 环境变量污染：source → 子 shell (. /etc/os-release && echo) |
| 2026-06-21 | UPDATE | `scripts/base/utils.sh` | 修复 set_ssh_config() grep/sed \s → POSIX [[:space:]]，提升 BSD/macOS 兼容性 |
| 2026-06-21 | DELETE | `./.DS_Store`, `./config/.DS_Store`, `./tests/.DS_Store` | 清理 macOS .DS_Store 文件 |
| 2026-06-21 | UPDATE | `install.sh` | 修复 ShellCheck SC2012：view_report() 中 ls -t → find -printf |
| 2026-06-21 | CREATE | `.claude/reviews/local-review-20260621.md` | 代码审查报告：0 CRITICAL + 0 HIGH + 4 MEDIUM + 4 LOW |
| 2026-06-23 | CREATE | `docs/code-review-handover-20260623.md` | 全项目 Code Review Round 3 交接文档：0 CRITICAL + 3 HIGH + 4 MEDIUM + 4 LOW，含待办修复方案 |
| 2026-06-23 | UPDATE | `HANDOVER.md` | 更新当前阶段、添加变更日志 |
| 2026-06-23 | UPDATE | `install.sh` | H1: 将 _parse_args 移入 main()（load_dependencies 之后），解决颜色变量未初始化问题；L3: 移除残留 `:` 占位符；L4: find -printf → ls -t 兼容 macOS |
| 2026-06-23 | UPDATE | `scripts/base/utils.sh` | M1: _ENSURING_LOG_DIR 移除 export；M4: schedule_rollback 添加安全约束注释 |
| 2026-06-23 | UPDATE | `scripts/base/report.sh` | H3: 3 处硬编码中文替换为 MSG_REPORT_WARN_* i18n 变量 |
| 2026-06-23 | UPDATE | `scripts/lang/zh.sh` | H3: 新增 MSG_REPORT_WARN_SSH_PORT22/FIREWALL/FAIL2BAN 翻译 |
| 2026-06-23 | UPDATE | `scripts/lang/en.sh` | H3: 新增 MSG_REPORT_WARN_SSH_PORT22/FIREWALL/FAIL2BAN 翻译 |
| 2026-06-23 | UPDATE | `scripts/security/fail2ban.sh` | M3: sleep 2 改为轮询等待（最多 10 秒）；L2: _get_ssh_service_name 函数替换为 SSH_SERVICE_NAME 常量 |
| 2026-06-23 | UPDATE | `scripts/security/firewall.sh` | L1: 统一引号风格 $VAR → ${VAR} |
| 2026-06-23 | UPDATE | `tests/unit/fail2ban.bats` | L2: 更新测试用例适配 SSH_SERVICE_NAME 常量 |
| 2026-06-23 | CREATE | `tests/unit/ssh.bats` | M2: SSH 模块单元测试（16 个用例：validate_port/check_other_users/check_ssh_keys） |
| 2026-06-23 | DELETE | `SHA256SUMS` | 完整性校验简化为基本检查，不再需要独立校验文件（commit 33dc7e1） |
| 2026-06-23 | UPDATE | `HANDOVER.md` | 全面核对修正：更新文件树（添加缺失文件、移除不存在的 bootstrap.sh）、修正 Code Review Round 3 状态、添加 SHA256SUMS 删除记录、更新下一步工作 |
| 2026-06-23 | MOVE | `docs/bug-review-report.md` → `docs/code-reviews/round-1-bug-report.md` | 文档归类：Code Review 报告移入 code-reviews/ |
| 2026-06-23 | MOVE | `docs/code-review-report-20260620.md` → `docs/code-reviews/round-2-code-review.md` | 文档归类：Code Review 报告移入 code-reviews/ |
| 2026-06-23 | MOVE | `docs/code-review-handover-20260623.md` → `docs/code-reviews/round-3-handover.md` | 文档归类：Code Review 报告移入 code-reviews/ |
| 2026-06-23 | MOVE | `docs/test-report-20260620.md` → `docs/test-reports/ubuntu-arm64-test.md` | 文档归类：测试报告移入 test-reports/ |
| 2026-06-23 | MOVE | `docs/vm-test-report-20260620.md` → `docs/test-reports/vm-curl-test.md` | 文档归类：测试报告移入 test-reports/ |
| 2026-06-23 | MOVE | `docs/superpowers/specs/...` → `docs/design/interactive-setup-spec.md` | 文档归类：设计文档移入 design/ |
| 2026-06-23 | MOVE | `docs/superpowers/plans/...` → `docs/design/interactive-setup-plan.md` | 文档归类：实施计划移入 design/ |
| 2026-06-23 | COPY | `.claude/prds/*.prd.md` → `docs/design/` | PRD 副本归入 design/，原件保留供 Claude Code 工作流使用 |
| 2026-06-23 | COPY | `.claude/plans/*.plan.md` → `docs/design/` | 实施计划副本归入 design/，原件保留供 Claude Code 工作流使用 |
| 2026-06-23 | CREATE | `docs/README.md` | 文档目录总览 |
| 2026-06-23 | CREATE | `docs/code-reviews/README.md` | Code Review 目录说明 |
| 2026-06-23 | CREATE | `docs/test-reports/README.md` | 测试报告目录说明 |
| 2026-06-23 | CREATE | `docs/design/README.md` | 设计文档目录说明 |
| 2026-06-23 | CREATE | `scripts/security/audit.sh` | v0.4 审计日志模块：auditd 安装、3 级规则生成、配置、服务管理、交互式向导 |
| 2026-06-23 | CREATE | `config/audit/audit.rules` | 审计规则参考模板（全面规则示例） |
| 2026-06-23 | CREATE | `config/audit/auditd.conf` | auditd 配置参考模板 |
| 2026-06-23 | UPDATE | `scripts/lang/zh.sh` | 添加 ~40 条 MSG_AUDIT_* 中文翻译，更新菜单编号，添加向导步骤 |
| 2026-06-23 | UPDATE | `scripts/lang/en.sh` | 添加 ~40 条 MSG_AUDIT_* 英文翻译，更新菜单编号，添加向导步骤 |
| 2026-06-23 | UPDATE | `install.sh` | 集成 audit.sh：load_dependencies、菜单[5]、状态检测、full_wizard Step 4 |
| 2026-06-23 | UPDATE | `scripts/base/report.sh` | 添加审计状态、配置文件路径、警告信息到报告 |
| 2026-06-23 | CREATE | `tests/unit/audit.bats` | 审计模块单元测试：44 个用例（常量、规则生成、配置、函数存在性） |
| 2026-06-23 | UPDATE | `HANDOVER.md` | 更新进度状态、文件清单、变更日志 |
| 2026-06-24 | CREATE | `docs/code-reviews/round-4-audit-module-review.md` | v0.4 审计模块 Code Review：1 HIGH + 3 MEDIUM + 2 LOW |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | H1: 修复 auseport→aureport 拼写错误; M2: 添加 MSG_MAIN_MENU_REPORT_DESC |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | M2: 添加 MSG_MAIN_MENU_REPORT_DESC |
| 2026-06-24 | UPDATE | `scripts/security/audit.sh` | M1: 添加 case default 分支; L1: mkdir 错误记录到日志 |
| 2026-06-24 | UPDATE | `tests/unit/audit.bats` | M3: 添加 standard 规则不含 modules 的测试（45 个用例） |
| 2026-06-24 | UPDATE | `config/audit/audit.rules` | L2: 标注模板为 full 级别示例 |
| 2026-06-24 | UPDATE | `install.sh` | M2: 显示报告菜单描述文本 |
| 2026-06-24 | CREATE | `scripts/README.md` | 脚本目录总览：模块说明、加载顺序、依赖关系、编码规范 |
| 2026-06-24 | CREATE | `scripts/base/README.md` | 基础模块说明：utils/detect/init/report 各函数清单 |
| 2026-06-24 | CREATE | `scripts/security/README.md` | 安全模块说明：SSH/防火墙/Fail2Ban/审计功能和通用模式 |
| 2026-06-24 | CREATE | `scripts/lang/README.md` | 语言文件说明：i18n 工作原理、翻译键命名、添加新语言指南 |
| 2026-06-24 | CREATE | `scripts/dev/README.md` | [规划中] 开发工具安装目录说明 |
| 2026-06-24 | CREATE | `scripts/server/README.md` | [规划中] 服务器软件安装目录说明 |
| 2026-06-24 | CREATE | `scripts/utils/README.md` | [规划中] 通用工具脚本目录说明 |
| 2026-06-24 | CREATE | `config/README.md` | 配置目录总览：模板与实际配置的关系 |
| 2026-06-24 | CREATE | `config/audit/README.md` | 审计配置模板说明：3 级规则、auditd.conf 参数 |
| 2026-06-24 | CREATE | `config/fail2ban/README.md` | Fail2Ban 配置模板说明：jail.local 参数和占位符 |
| 2026-06-24 | CREATE | `tests/README.md` | 测试目录总览：Bats 框架、运行方式、测试规范 |
| 2026-06-24 | CREATE | `tests/unit/README.md` | 单元测试说明：107 个用例、测试结构、运行方式 |
| 2026-06-24 | UPDATE | `README.md` | 更新功能列表：审计日志状态 ⬜→✅ |
| 2026-06-24 | UPDATE | `HANDOVER.md` | 更新文件清单、添加变更日志 |
| 2026-06-24 | CREATE | `scripts/security/users.sh` | v0.3 用户管理模块：创建用户、密码、SSH密钥、sudo NOPASSWD、向导 |
| 2026-06-24 | CREATE | `scripts/security/kernel.sh` | v0.3 内核加固模块：sysctl 参数、内核模块禁用、回滚、向导 |
| 2026-06-24 | CREATE | `scripts/security/filesystem.sh` | v0.3 文件系统模块：权限检查、SUID审计、无主文件、向导 |
| 2026-06-24 | CREATE | `config/sysctl/hardening.conf` | v0.3 sysctl 安全参数配置模板（CIS Benchmark） |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | 添加 ~120 条 MSG_USERS_*/MSG_KERNEL_*/MSG_FS_* 中文翻译 |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | 添加 ~120 条对应英文翻译 |
| 2026-06-24 | UPDATE | `install.sh` | 集成 v0.3：load_dependencies、菜单[6-8]、状态检测、full_wizard Step 5-7 |
| 2026-06-24 | UPDATE | `scripts/base/report.sh` | 添加用户/内核/文件系统报告段 |
| 2026-06-24 | CREATE | `tests/unit/users.bats` | 用户管理单元测试（33 个用例） |
| 2026-06-24 | CREATE | `tests/unit/kernel.bats` | 内核加固单元测试（20 个用例） |
| 2026-06-24 | CREATE | `tests/unit/filesystem.bats` | 文件系统单元测试（23 个用例） |
| 2026-06-24 | CREATE | `.claude/plans/v0.3-user-kernel-filesystem.plan.md` | v0.3 实施计划文档 |
| 2026-06-24 | CREATE | `.claude/reviews/commit-400933a-review.md` | v0.3 commit 代码审查：3 HIGH + 4 MEDIUM + 3 LOW，含 eval 注入、find 性能、函数定义顺序等问题 |
| 2026-06-24 | UPDATE | `scripts/security/users.sh` | HIGH#1: eval 注入修复（getent passwd 替代 eval echo）；SSH 密钥无密码警告 |
| 2026-06-24 | UPDATE | `scripts/security/kernel.sh` | HIGH#2: _generate_sysctl_config 移至 apply_sysctl_params 之前 |
| 2026-06-24 | UPDATE | `scripts/security/filesystem.sh` | HIGH#3: find / 添加 -xdev 和排除 /proc /sys；截断警告；tail -1 改为全局变量；status 扫描范围 /usr→/ |
| 2026-06-24 | UPDATE | `scripts/base/report.sh` | 添加文件系统 SUID 详情和警告信息 |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | SSH 无密码警告；截断提示；文件系统报告键 |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | SSH 无密码警告；截断提示；文件系统报告键 |
| 2026-06-24 | UPDATE | `install.sh` | show_system_status 改用 check_*_status() 函数 |
| 2026-06-24 | CREATE | `.claude/plans/fix-commit-400933a-review.plan.md` | v0.3 Code Review 修复计划 |
| 2026-06-24 | UPDATE | `install.sh` | H2 修复：集成 `run_init()` 到向导 Step 0，添加 `_WIZARD_INIT_DONE` 标志 |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | 添加 `MSG_WIZARD_STEP_INIT`/`SKIPPED_INIT`/`ERR_INIT`，步骤编号 /8→/9 |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | 同上英文翻译 |
| 2026-06-24 | UPDATE | `HANDOVER.md` | 更新 Code Review Round 3 状态为 ✅ 完成，更新下一步工作 |
| 2026-06-24 | UPDATE | `README.md` | 更新功能特性列表：用户管理/内核加固/文件系统安全标记为 ✅，新增文件系统安全条目 |
| 2026-06-24 | UPDATE | `README.md` | 重写为专业版：添加徽章、详细功能分类、3 种安装方式、支持系统表格、项目架构、交互式向导流程、开发指南、安全注意事项、参考资料、版本历史、致谢 |
| 2026-06-24 | UPDATE | `scripts/security/README.md` | 更新模块状态：kernel/filesystem/users 标记为 ✅ 完成，补充详细说明 |
| 2026-06-24 | UPDATE | `scripts/lang/README.md` | 更新翻译覆盖范围：添加用户管理/内核/文件系统翻译数量 |
| 2026-06-24 | UPDATE | `config/README.md` | 添加 sysctl 目录，移除规划中状态 |
| 2026-06-24 | UPDATE | `tests/README.md`, `tests/unit/README.md` | 添加 users/kernel/filesystem 测试文件，更新总数 107→183 |
| 2026-06-24 | UPDATE | `docs/README.md`, `docs/code-reviews/README.md` | 丰富文档描述，添加 Round 4 审查记录 |
| 2026-06-24 | UPDATE | `scripts/README.md` | 更新依赖表和目录结构 |
| 2026-06-24 | CREATE | `scripts/security/services.sh` | v0.4 服务管理模块：审计运行服务、禁用不必要服务、端口扫描、交互式向导 |
| 2026-06-24 | UPDATE | `scripts/lang/zh.sh` | 添加 ~35 条 MSG_SERVICES_* 中文翻译，更新菜单编号 /9→/10，添加向导步骤 |
| 2026-06-24 | UPDATE | `scripts/lang/en.sh` | 添加 ~35 条 MSG_SERVICES_* 英文翻译，更新菜单编号，添加向导步骤 |
| 2026-06-24 | UPDATE | `install.sh` | 集成 services.sh：load_dependencies、菜单[9]、向步→[10]报告→[11]、full wizard Step 8、状态检测 |
| 2026-06-24 | UPDATE | `scripts/base/report.sh` | 添加服务管理报告段（运行中服务数、不必要服务数、警告信息） |
| 2026-06-24 | CREATE | `tests/unit/services.bats` | 服务管理单元测试（35 个用例：常量、函数存在性、端口安全检查、状态输出格式） |
| 2026-06-24 | UPDATE | `scripts/security/README.md` | 更新 services.sh 状态为 ✅ 完成，添加模块说明 |
| 2026-06-24 | UPDATE | `HANDOVER.md` | 更新进度状态、文件清单、下一步工作、变更日志 |

---

## 第二批归档（2026-07-24 HANDOVER.md 精简重构时迁入）

> 以下条目原在 HANDOVER.md §8 变更日志（2026-06-25 ~ 2026-07-24），现统一归档。

| 2026-06-25 | CREATE | `.claude/reviews/false-success-bug-audit-20260625.md` | 静默失败专项审计 |
| 2026-06-25 | UPDATE | `scripts/base/utils.sh` | 修复 get_os_type()/get_os_version() 环境变量污染 |
| 2026-06-25 | UPDATE | `scripts/security/ssh.sh` | 安全加固修复 |
| 2026-06-25 | UPDATE | `scripts/security/fail2ban.sh` | 安全加固修复 |
| 2026-06-25 | UPDATE | `scripts/security/audit.sh` | 安全加固修复 |
| 2026-06-25 | UPDATE | `scripts/base/init.sh` | 修复 |
| 2026-06-25 | UPDATE | `scripts/security/kernel.sh` | 修复 |
| 2026-06-25 | UPDATE | `scripts/security/users.sh` | 修复 |
| 2026-06-25 | UPDATE | `scripts/security/firewall.sh` | 修复 |
| 2026-06-25 | UPDATE | `scripts/security/filesystem.sh` | 修复 |
| 2026-06-26 | UPDATE | `scripts/security/firewall.sh`, `init.sh`, `utils.sh`, `detect.sh`, `install.sh`, `ssh.sh`, `users.sh`, `fail2ban.sh`, `audit.sh` | 第二轮 Code Review 修复 |
| 2026-06-26 | UPDATE | `review/bug-review-comprehensive.md` | Code Review 报告更新 |
| 2026-06-26 | UPDATE | `HANDOVER.md` | 变更日志同步 |
| 2026-07-10 | CREATE | `docs/plans/` | 计划文件目录初始化 |
| 2026-07-10 | UPDATE | `.claude/CLAUDE.md` | 项目结构章节更新 |
| 2026-07-10 | CREATE | `docs/handover-archive.md` | 历史变更日志归档（176 条，2026-06-20~24） |
| 2026-07-10 | UPDATE | `HANDOVER.md` | 变更日志精简 + 删除重复"已完成的工作"节 |
| 2026-07-10 | CREATE | `scripts/dev/gen-file-tree.sh` | 自动生成文件树脚本 |
| 2026-07-10 | UPDATE | `.gitignore` | 忽略 docs/file-tree.generated.md |
| 2026-07-10 | UPDATE | `HANDOVER.md` | 文件清单改为概览表 |
| 2026-07-10 | FIX | `.claude/settings.local.json` | JSON 语法修复 |
| 2026-07-10 | CREATE | `docs/design/archive/` | 设计文档归档目录 |
| 2026-07-10 | UPDATE | `docs/design/README.md` | 重写为分层索引 |
| 2026-07-10 | CREATE | `docs/design/main-menu-redesign-v2.md` | 主菜单重构 v2 设计 |
| 2026-07-10 | CREATE | `docs/plans/2026-07-10_16-00_main-menu-redesign-v2_nogit.md` | writing-plans 实施计划 |
| 2026-07-10 | CREATE | `tests/unit/menu.bats` | i18n 键 smoke 测试（10 cases） |
| 2026-07-10 | UPDATE | `scripts/lang/zh.sh`, `scripts/lang/en.sh` | +81 行 i18n 键 |
| 2026-07-10 | UPDATE | `install.sh` | +6 submenu 函数（~240 行），状态检测升级，view_report 升级 |
| 2026-07-10 | UPDATE | `install.sh` | 移除 `:-` i18n 兜底，精简参数错误 |
| 2026-07-11 | CREATE | `docs/plans/2026-07-11_13-00_full-code-review-n4_nogit.md` | Round 4 Code Review 计划 |
| 2026-07-11 | CREATE | `docs/code-reviews/round-4-comprehensive.md` | Round 4 综合报告：4C + 22H + 41M + 21L |
| 2026-07-12 | CREATE | `scripts/server/k3s.sh` | K3s 安装/卸载/状态检查模块 |
| 2026-07-12 | UPDATE | `scripts/lang/zh.sh`, `scripts/lang/en.sh` | +28 K3s i18n 键 |
| 2026-07-12 | UPDATE | `install.sh` | K3s 菜单集成 |
| 2026-07-12 | CREATE | `tests/unit/k3s.bats` | K3s 单元测试（17 cases） |
| 2026-07-12 | FIX | `scripts/security/ssh.sh` | C1 SSH at timer + M5 i18n + M9 order |
| 2026-07-12 | FIX | `scripts/security/firewall.sh` | C2 UFW locale + H6 return check |
| 2026-07-12 | FIX | `tests/unit/firewall.bats`, `tests/unit/fail2ban.bats` | C3-C4 移除假 mock |
| 2026-07-12 | FIX | `scripts/base/init.sh` | H1 source guard + H3 apt-get protection |
| 2026-07-12 | FIX | `scripts/base/report.sh` | H2 source guard + M4 i18n |
| 2026-07-12 | FIX | `install.sh` | H4 GREEN dead code + M13-M17 i18n |
| 2026-07-12 | FIX | `scripts/security/fail2ban.sh` | H5 i18n + H7 dnf fallback |
| 2026-07-12 | FIX | `scripts/security/audit.sh` | H13 ausearch + M33 i18n |
| 2026-07-12 | FIX | `config/audit/audit.rules` | H14+H15 execve + b32 variants |
| 2026-07-12 | FIX | `scripts/base/utils.sh`, `scripts/security/*`, `scripts/lang/*`, `tests/unit/*` | Round 4 M1-M31 批量修复 |
| 2026-07-12 | DELETE | `.claude/prds/` | 清理重复 PRD |
| 2026-07-12 | MIGRATE | `.claude/plans/` → `docs/plans/` | 旧计划文件迁移 |
| 2026-07-12 | MIGRATE | `docs/superpowers/` → `docs/design/archive/` | 设计文档归档 |
| 2026-07-12 | UPDATE | `docs/README.md` | 重写为统一文档索引 |
| 2026-07-12 | CREATE | `tests/docker/` | Docker Phase 1 测试框架（9 Dockerfiles + 8 模块测试） |
| 2026-07-12 | PASS | `test-all.sh --phase 1` | Phase 1：9 distros × 8 modules = **72/72 全部通过** |
| 2026-07-12 | CREATE | `tests/docker/images/ubuntu/22.04.phase2.Dockerfile` | Phase 2 特权容器镜像（Ubuntu 22.04） |
| 2026-07-12 | CREATE | `tests/docker/images/centos/7.phase2.Dockerfile` | Phase 2 特权容器镜像（CentOS 7） |
| 2026-07-12 | CREATE | `tests/docker/images/debian/12.phase2.Dockerfile` | Phase 2 特权容器镜像（Debian 12） |
| 2026-07-12 | UPDATE | `tests/docker/lib/common.bash` | Phase 2 特权容器函数 |
| 2026-07-12 | CREATE | `tests/docker/tests/phase2/` | Phase 2 7 个模块验证脚本 |
| 2026-07-12 | PASS | `test-all.sh --phase 2` | Phase 2：3 distros × 7 modules = **21/21 全部通过** |
| 2026-07-13 | FIX | `scripts/base/detect.sh` | SC2317: 移除冗余 `|| true` |
| 2026-07-13 | FIX | `scripts/base/init.sh` | SC2120/SC2119: setup_timezone 显式传参 |
| 2026-07-13 | FIX | `scripts/base/utils.sh` | SC2002: cat→重定向 |
| 2026-07-13 | FIX | `scripts/security/fail2ban.sh`, `kernel.sh` | ShellCheck 修复 |
| 2026-07-13 | FIX | `install.sh` | SC2059 + SC2012: printf + find 修复 |
| 2026-07-13 | CREATE | `.github/workflows/test.yml` | GitHub Actions CI（ShellCheck + Bats + Phase 1 + Phase 2） |
| 2026-07-13 | CREATE | `.github/workflows/markdown-lint.yml` | Markdown 格式检查 |
| 2026-07-13 | CREATE | `.github/workflows/codeql.yml` | CodeQL 安全扫描 |
| 2026-07-13 | PASS | CI | **全部 4 job 首次通过** |
| 2026-07-15 | CREATE | `docs/plans/2026-07-15_10-30_full-code-review-n5_nogit.md` | Round 5 Code Review 计划 |
| 2026-07-15 | CREATE | `docs/code-reviews/round-5-comprehensive.md` | Round 5：0C + 20H + 46M + 49L（6 组并行审查） |
| 2026-07-21 | CREATE | `docs/code-reviews/2026-07-21_full-project-security-audit.md` | 全项目安全审计：0C + 7H + 19M + 13L |
| 2026-07-21 | FIX | `scripts/base/utils.sh` | H1: schedule_rollback() 添加 disown |
| 2026-07-21 | FIX | `install.sh` | H3: curl 管道检测后 set -u；M10/M11: timeout + trap |
| 2026-07-21 | FIX | `scripts/security/ssh.sh` | M1: passphrase 泄露修复 |
| 2026-07-21 | FIX | `scripts/security/filesystem.sh` | M2: RHEL /etc/shadow 权限 000 |
| 2026-07-21 | FIX | `scripts/lang/zh.sh`, `en.sh` | M4: ufw 双后端提示 |
| 2026-07-21 | FIX | `scripts/security/fail2ban.sh` | M6: ignoreip ::1 |
| 2026-07-21 | FIX | `config/sysctl/hardening.conf` | M8: +5 CIS 参数 |
| 2026-07-21 | FIX | `config/audit/auditd.conf` | M12: flush DATA |
| 2026-07-21 | PASS | `bats tests/unit/*.bats` | **259/259 全部通过** |
| 2026-07-21 | RELEASE | `v1.0.1` | 全项目安全审计修复（10 项）+ 文档规范化 |
| 2026-07-21 | REWRITE | `.claude/CLAUDE.md` | 文档规范化：364→90 行 |
| 2026-07-21 | CREATE | `CONTRIBUTING.md` | 贡献指南 |
| 2026-07-21 | CREATE | `LICENSE` | MIT 开源许可证 |
| 2026-07-21 | MOVE | `review/` → `docs/code-reviews/`, `RELEASE_CHECKLIST.md` → `docs/`, `docs/docker-test-debug-log.md` → `tests/` | 文档归类 |
| 2026-07-21 | UPDATE | `README.md` | 开发指南引用 CONTRIBUTING.md |
| 2026-07-24 | CREATE | `docs/design/lite-vs-full-mode.md` | Lite/Full 双模式设计文档 |
| 2026-07-24 | CREATE | `scripts/base/mode.sh` | 模块注册表 |
| 2026-07-24 | UPDATE | `scripts/lang/zh.sh`, `scripts/lang/en.sh` | +11 模式相关 i18n 键 |
| 2026-07-24 | UPDATE | `install.sh` | --lite 参数解析 + 模式过滤 |
| 2026-07-24 | CREATE | `tests/unit/mode.bats` | 13 个模式模块单元测试 |
| 2026-07-24 | REWRITE | `.claude/CLAUDE.md` | consolidating-docs skill 重构 |
| 2026-07-24 | FIX | `docs/README.md`, `docs/design/README.md`, docs/plans/ | cross-reference 修复 |
| 2026-07-24 | REWRITE | `HANDOVER.md` | 精简为 ~70 行状态快照，全量 changelog 归入本文件 |

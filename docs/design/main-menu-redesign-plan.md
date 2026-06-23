# Plan: 主菜单入口重设计

**Source PRD**: `.claude/prds/main-menu-redesign.prd.md`
**Complexity**: Medium

## Summary

重构 `install.sh` 的入口层，将"检测完直接执行"改为"主菜单循环选择"。底层模块（ssh.sh、firewall.sh、fail2ban.sh、utils.sh、detect.sh）完全不改，仅改 `install.sh` 的调度层和 i18n 翻译文件。

## Patterns to Mirror

| Category | Source | Pattern |
|---|---|---|
| Menu display | `install.sh:263-271` | `echo -e "${GREEN}[N] 标题${NC}"` + 缩进描述 |
| Input prompt | `utils.sh:211-232` | `prompt_input "提示" "默认值"` → echo result |
| Confirm | `utils.sh:174-196` | `confirm "提示" "y/n"` → return 0/1 |
| Press enter | `utils.sh:199-207` | `press_enter "按 Enter 继续..."` |
| Error handling | `install.sh:336-339` | `func \|\| { log_error "msg"; return 1; }` |
| Logging | `utils.sh:100-166` | `log_title`, `log_step`, `log_success`, `log_error`, `log_warn`, `log_info` |
| i18n keys | `scripts/lang/zh.sh` | `MSG_SECTION_KEY="值"` grouped by section |
| Non-interactive | `utils.sh:180-184` | `if [[ "${AUTO_ACCEPT}" == "yes" ]]; then ... fi` |
| SSH custom entry | `ssh.sh:467` | `run_ssh_hardening_custom do_port do_key do_root do_passwd do_params` |
| Firewall custom entry | `firewall.sh:396` | `run_firewall_hardening_custom do_http do_icmp` |
| Fail2Ban entry | `fail2ban.sh:260` | `run_fail2ban_hardening` (no params) |

## Files to Change

| File | Action | Why |
|---|---|---|
| `install.sh` | UPDATE | 重构 main() 流程，新增主菜单/子菜单循环，扩展参数解析 |
| `scripts/lang/zh.sh` | UPDATE | 新增主菜单、子菜单、状态检测相关翻译键 |
| `scripts/lang/en.sh` | UPDATE | 对应的英文翻译键 |

## Tasks

### Task 1: 新增 i18n 翻译键
- **Action**: 在 `scripts/lang/zh.sh` 和 `scripts/lang/en.sh` 的 `# 菜单` section 后新增主菜单和子菜单翻译键
- **Mirror**: 现有 `MSG_MENU_*` 命名模式 (`zh.sh:47-53`)
- **Keys to add**:
  ```
  # 主菜单
  MSG_MAIN_MENU_TITLE="主菜单"
  MSG_MAIN_MENU_STATUS="[1] 系统状态检测"
  MSG_MAIN_MENU_STATUS_DESC="查看当前系统安全状态（不修改任何配置）"
  MSG_MAIN_MENU_SSH="[2] SSH 安全加固"
  MSG_MAIN_MENU_SSH_DESC="端口修改、密钥认证、禁止root/密码登录"
  MSG_MAIN_MENU_FIREWALL="[3] 防火墙配置"
  MSG_MAIN_MENU_FIREWALL_DESC="UFW/firewalld 规则配置"
  MSG_MAIN_MENU_FAIL2BAN="[4] Fail2Ban 入侵防护"
  MSG_MAIN_MENU_FAIL2BAN_DESC="自动封禁恶意登录尝试"
  MSG_MAIN_MENU_QUICK="[5] 一键快速加固（推荐）"
  MSG_MAIN_MENU_QUICK_DESC="按顺序执行以上全部项目，每步确认"
  MSG_MAIN_MENU_REPORT="[6] 查看上次加固报告"
  MSG_MAIN_MENU_EXIT="[0] 退出"
  MSG_MAIN_MENU_PROMPT="请输入选项"
  MSG_MAIN_MENU_CHOICE="请选择操作"

  # SSH 子菜单
  MSG_SSH_MENU_TITLE="SSH 安全加固"
  MSG_SSH_MENU_PORT="[1] 修改 SSH 端口"
  MSG_SSH_MENU_KEY="[2] 生成 SSH 密钥对"
  MSG_SSH_MENU_ROOT="[3] 禁止 root 远程登录"
  MSG_SSH_MENU_PASSWD="[4] 禁止密码登录"
  MSG_SSH_MENU_PARAMS="[5] 配置 SSH 安全参数"
  MSG_SSH_MENU_ALL="[6] 执行以上全部"
  MSG_SSH_MENU_BACK="[0] 返回主菜单"

  # 防火墙子菜单
  MSG_FIREWALL_MENU_TITLE="防火墙配置"
  MSG_FIREWALL_MENU_ENABLE="[1] 启用防火墙并配置基础规则"
  MSG_FIREWALL_MENU_HTTP="[2] 开放 HTTP/HTTPS 端口"
  MSG_FIREWALL_MENU_ICMP="[3] 允许 ICMP ping"
  MSG_FIREWALL_MENU_BACK="[0] 返回主菜单"

  # 状态检测
  MSG_STATUS_TITLE="系统安全状态检测"
  MSG_STATUS_SSH_PORT="SSH 端口"
  MSG_STATUS_SSH_ROOT="root 远程登录"
  MSG_STATUS_SSH_PASSWD="密码认证"
  MSG_STATUS_SSH_KEY="密钥认证"
  MSG_STATUS_FIREWALL="防火墙"
  MSG_STATUS_FAIL2BAN="Fail2Ban"
  MSG_STATUS_ENABLED="已启用"
  MSG_STATUS_DISABLED="未启用"
  MSG_STATUS_INSTALLED="已安装"
  MSG_STATUS_NOT_INSTALLED="未安装"
  MSG_STATUS_ALLOWED="允许"
  MSG_STATUS_NOT_ALLOWED="禁止"

  # 报告查看
  MSG_REPORT_NOT_FOUND="暂无加固报告，请先执行安全加固"

  # 快速加固
  MSG_QUICK_TITLE="一键快速加固"
  ```
- **Validate**: `grep -c "^MSG_MAIN_MENU" scripts/lang/zh.sh` 应 >= 12

### Task 2: 扩展 _parse_args() 支持新参数
- **Action**: 在 `install.sh:96-115` 的 `_parse_args()` 中新增 `--ssh`, `--firewall`, `--fail2ban`, `--status`, `--quick` 参数，设置 `TARGET_MODULE` 变量
- **Mirror**: 现有 `--yes|-y` 和 `--help|-h` 的 case 模式
- **关键**: `--yes` 和 `--quick` 都映射到 `TARGET_MODULE="all"`，保持向后兼容
- **Validate**: `bash install.sh --help` 应显示所有新参数

### Task 3: 新增 show_system_status() 函数
- **Action**: 在 `install.sh` 中新增函数，读取当前 SSH 配置和防火墙/Fail2Ban 状态并格式化显示
- **Mirror**: `print_detection_summary` (`detect.sh:216`) 的输出格式
- **逻辑**:
  - 读取 SSH 端口: `get_ssh_port`
  - 读取 PermitRootLogin: `get_ssh_config "PermitRootLogin"`
  - 读取 PasswordAuthentication: `get_ssh_config "PasswordAuthentication"`
  - 检查防火墙状态: `ufw status` 或 `firewall-cmd --state`
  - 检查 Fail2Ban 状态: `systemctl is-active fail2ban`
- **注意**: 只读不改，读取失败时显示"未知"而非报错
- **Validate**: 选择菜单 1 应显示状态后返回主菜单

### Task 4: 新增 show_main_menu() 和 get_main_menu_choice()
- **Action**: 替代原 `show_execution_mode_menu()` + `get_execution_mode()`
- **Mirror**: 原函数的 echo 颜色 + `prompt_input` 模式 (`install.sh:263-295`)
- **show_main_menu()**: 用 `echo -e` 输出主菜单（含系统摘要一行），使用 `MSG_MAIN_MENU_*` 翻译键
- **get_main_menu_choice()**: 用 `prompt_input` 获取选择，循环校验 0-6
- **Validate**: 交互测试输入 0-6 和无效输入

### Task 5: 新增 SSH 子菜单循环
- **Action**: 新增 `show_ssh_submenu()` + `run_ssh_submenu_loop()`
- **Mirror**: 主菜单的 echo + prompt_input 模式
- **循环逻辑**:
  - 1 → `run_ssh_hardening_custom "y" "n" "n" "n" "n"` (仅端口)
  - 2 → `run_ssh_hardening_custom "n" "y" "n" "n" "n"` (仅密钥)
  - 3 → `run_ssh_hardening_custom "n" "n" "y" "n" "n"` (仅root)
  - 4 → `run_ssh_hardening_custom "n" "n" "n" "y" "n"` (仅密码)
  - 5 → `run_ssh_hardening_custom "n" "n" "n" "n" "y"` (仅参数)
  - 6 → `run_ssh_hardening_custom "y" "y" "y" "y" "y"` (全部)
  - 0 → `return` (回主菜单)
  - 每个操作后 `press_enter` 然后继续循环
- **注意**: SSH 端口单独执行时，需要先备份 + 最后验证 + 重启，现有 `run_ssh_hardening_custom` 已处理
- **Validate**: 选择子菜单 1 后应只改端口，选 0 应回主菜单

### Task 6: 新增防火墙子菜单循环
- **Action**: 新增 `show_firewall_submenu()` + `run_firewall_submenu_loop()`
- **Mirror**: SSH 子菜单模式
- **循环逻辑**:
  - 1 → `run_firewall_hardening_custom "n" "n"` (基础规则)
  - 2 → `run_firewall_hardening_custom "y" "n"` (含HTTP)
  - 3 → `run_firewall_hardening_custom "n" "y"` (含ICMP)
  - 0 → `return`
- **注意**: 防火墙子菜单每次执行都是完整流程（安装→配置→启用），需要幂等处理。`run_firewall_hardening_custom` 内部已有幂等逻辑
- **Validate**: 选择 1 后防火墙启用，选 0 回主菜单

### Task 7: 新增 view_report() 函数
- **Action**: 查找并显示 `/var/log/linux-one-key/report_*.txt`
- **Mirror**: `generate_report()` (`install.sh:500`) 的输出格式
- **逻辑**:
  - `ls -t /var/log/linux-one-key/report_*.txt | head -1` 找最新报告
  - 找到 → `cat` 显示
  - 没找到 → `log_warn MSG_REPORT_NOT_FOUND`
  - `press_enter` 返回
- **Validate**: 无报告时应提示，有报告时应显示

### Task 8: 新增 run_quick_hardening() 函数
- **Action**: 替代原 `run_quick_start()`，逻辑基本一致
- **Mirror**: 原 `run_quick_start()` (`install.sh:323-354`)
- **改动**: 用 `MSG_QUICK_TITLE` 替代硬编码标题，执行完 `press_enter` 返回主菜单（不直接退出）
- **Validate**: 选 5 → 确认 → SSH+防火墙+Fail2Ban 依次执行 → 回主菜单

### Task 9: 新增主菜单循环 run_main_menu_loop()
- **Action**: `while true` 循环，每次显示菜单 → 获取选择 → 分发执行
- **Mirror**: `get_execution_mode()` 的 while+case 模式 (`install.sh:278-294`)
- **关键**: 选项 0 用 `break` 退出循环，其他选项执行后继续循环
- **新增** `cleanup_and_exit()` 函数: 清理 `_CLEANUP_DIR`，打印再见，`exit 0`
- **Validate**: 选 0 应退出脚本

### Task 10: 重构 main() 函数
- **Action**: 替换原 `main()` (`install.sh:546-605`)
- **新逻辑**:
  ```
  main() {
      load_dependencies
      init_logging
      setup_error_trap

      # 非交互模式：根据 TARGET_MODULE 直接执行
      if [[ "${AUTO_ACCEPT}" == "yes" ]]; then
          case "${TARGET_MODULE:-all}" in
              status)   run_detection; print_detection_summary; exit 0 ;;
              ssh)      run_ssh_hardening; generate_report; exit 0 ;;
              firewall) run_firewall_hardening; generate_report; exit 0 ;;
              fail2ban) run_fail2ban_hardening; generate_report; exit 0 ;;
              all)      run_detection; run_quick_hardening; generate_report; exit 0 ;;
          esac
      fi

      # 交互模式
      show_welcome
      run_detection || { log_warn "..."; }
      print_detection_summary
      run_main_menu_loop
  }
  ```
- **注意**: 非交互模式保留原 `--yes` 行为（全部执行），`--status` 只检测不修改
- **Validate**: `bash install.sh --ssh` 应直接执行 SSH 加固

### Task 11: 删除旧代码
- **Action**: 删除以下不再需要的函数：
  - `show_execution_mode_menu()` (install.sh:263-272)
  - `get_execution_mode()` (install.sh:275-295)
  - `show_quick_start_tasks()` (install.sh:302-320)
  - `run_quick_start()` (install.sh:323-354)
  - `run_custom_config()` (install.sh:361-494)
- **Validate**: `bash install.sh` 不报错，主菜单正常显示

### Task 12: 更新 HANDOVER.md
- **Action**: 记录本次变更
- **Mirror**: 现有变更日志格式 (`HANDOVER.md:274-323`)
- **Validate**: HANDOVER.md 包含新变更记录

## Validation

```bash
# 1. ShellCheck 静态检查
shellcheck -x install.sh

# 2. 交互测试（手动）
sudo bash install.sh
# → 应显示主菜单，不自动执行
# → 输入 1 → 显示状态 → 回主菜单
# → 输入 2 → SSH 子菜单 → 输入 0 → 回主菜单
# → 输入 0 → 退出

# 3. 非交互测试
sudo bash install.sh --help      # 应显示所有参数
sudo bash install.sh --status    # 应只显示状态
```

## Risks

| Risk | Likelihood | Mitigation |
|---|---|---|
| SSH 子菜单单独执行端口修改后需要重启 sshd | Medium | 使用现有 `run_ssh_hardening_custom` 已包含验证+重启逻辑 |
| 防火墙子菜单多次执行幂等性 | Low | `run_firewall_hardening_custom` 内部已有幂等处理 |
| 删除旧函数后遗漏引用 | Low | 用 grep 确认无其他调用点 |

## Acceptance

- [ ] 脚本启动后显示主菜单，不自动执行任何修改
- [ ] 选 1 只显示状态，不修改系统
- [ ] 选 2 进入 SSH 子菜单，可单独执行任意一项
- [ ] 选 3 进入防火墙子菜单
- [ ] 选 5 等同于原"快速开始"
- [ ] 选 6 查看报告
- [ ] 选 0 退出
- [ ] `--ssh`, `--firewall`, `--fail2ban`, `--status` 非交互参数正常
- [ ] `--yes` 向后兼容
- [ ] 中英文翻译完整

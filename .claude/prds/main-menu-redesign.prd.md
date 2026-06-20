# PRD: 主菜单入口重设计

**日期**: 2026-06-20
**状态**: 待审批
**影响范围**: `install.sh` 主入口流程重构

---

## 1. 问题描述

当前脚本执行流程：

```
参数解析 → curl引导 → 加载依赖 → 欢迎信息 → 系统检测 → 显示摘要 → 直接进入任务选择(快速开始/自定义) → 执行
```

存在以下安全隐患和体验问题：

1. **无安全入口**: 用户还没看清系统状态，就要决定是否执行加固
2. **粒度太粗**: 只有"全部执行"和"逐项确认"两种模式，无法单独执行某一项
3. **无状态查看**: 用户无法在不修改系统的前提下查看当前安全状态
4. **无历史查看**: 执行过的加固结果无法回顾
5. **非交互模式不够灵活**: `--yes` 一键全部执行，无法指定只做某项

---

## 2. 设计方案

### 2.1 新流程

```
参数解析 → curl引导 → 加载依赖 → 欢迎信息 → 【主菜单】→ 循环选择
                                                  ↓
                                          ┌─ 1. 系统状态检测
                                          ├─ 2. SSH 安全加固
                                          ├─ 3. 防火墙配置
                                          ├─ 4. Fail2Ban 入侵防护
                                          ├─ 5. 一键快速加固（全部执行）
                                          ├─ 6. 查看加固报告
                                          └─ 0. 退出
```

### 2.2 主菜单设计

```
╔═══════════════════════════════════════════════════════════╗
║       Linux 云服务器安全加固脚本 v0.2                     ║
╚═══════════════════════════════════════════════════════════╝

系统: Ubuntu 22.04 LTS | 架构: x86_64 | 用户: root

请选择操作：

  [1] 系统状态检测
      查看当前系统安全状态（不修改任何配置）

  [2] SSH 安全加固
      端口修改、密钥认证、禁止root/密码登录

  [3] 防火墙配置
      UFW/firewalld 规则配置

  [4] Fail2Ban 入侵防护
      自动封禁恶意登录尝试

  [5] 一键快速加固（推荐）
      按顺序执行以上全部项目，每步确认

  [6] 查看上次加固报告

  [0] 退出

请输入选项 [0-6]:
```

### 2.3 各菜单项行为

| 菜单项 | 行为 |
|--------|------|
| 1. 系统状态检测 | 仅执行 `run_detection` + `print_detection_summary`，不修改任何配置，检测完返回主菜单 |
| 2. SSH 安全加固 | 进入 SSH 子菜单，完成后返回主菜单 |
| 3. 防火墙配置 | 进入防火墙子菜单，完成后返回主菜单 |
| 4. Fail2Ban | 直接执行 Fail2Ban 加固，完成后返回主菜单 |
| 5. 一键快速加固 | 按顺序执行 2→3→4，每步确认，完成后返回主菜单 |
| 6. 查看报告 | 读取并显示 `/var/log/linux-one-key/report_*.txt`，返回主菜单 |
| 0. 退出 | 清理并退出 |

### 2.4 SSH 子菜单

```
SSH 安全加固：

  [1] 修改 SSH 端口 (22 → 2222)
  [2] 生成 SSH 密钥对 (Ed25519)
  [3] 禁止 root 远程登录
  [4] 禁止密码登录（仅密钥认证）
  [5] 配置 SSH 安全参数
  [6] 执行以上全部

  [0] 返回主菜单

请输入选项 [0-6]:
```

### 2.5 防火墙子菜单

```
防火墙配置：

  [1] 启用防火墙并配置基础规则
  [2] 开放 HTTP/HTTPS (80/443) 端口
  [3] 允许 ICMP ping

  [0] 返回主菜单

请输入选项 [0-3]:
```

### 2.6 非交互模式扩展

保留现有 `--yes` 参数（全部执行），新增细分参数：

```bash
bash install.sh --ssh          # 仅执行 SSH 加固
bash install.sh --firewall     # 仅执行防火墙配置
bash install.sh --fail2ban     # 仅执行 Fail2Ban
bash install.sh --status       # 仅显示系统状态
bash install.sh --quick        # 等同于 --yes，全部执行
bash install.sh --help         # 显示帮助
```

---

## 3. 实现计划

### 3.1 需要修改的文件

| 文件 | 变更内容 |
|------|----------|
| `install.sh` | 重构 `main()` 流程，新增主菜单循环、子菜单函数、非交互参数解析 |
| `scripts/lang/zh.sh` | 新增菜单相关的中文翻译键 |
| `scripts/lang/en.sh` | 新增菜单相关的英文翻译键 |

### 3.2 代码变更详情

#### 3.2.1 install.sh 变更

**删除/重构：**
- `show_execution_mode_menu()` — 用主菜单替代
- `get_execution_mode()` — 用主菜单循环替代
- `show_quick_start_tasks()` — 合并到"一键快速加固"逻辑
- `run_quick_start()` — 重构为调用子任务函数
- `run_custom_config()` — 删除，用子菜单替代

**新增函数：**
- `show_main_menu()` — 显示主菜单，包含系统状态摘要
- `get_main_menu_choice()` — 获取用户选择
- `run_main_menu_loop()` — 主菜单循环，选择后执行并返回
- `show_ssh_submenu()` — SSH 子菜单
- `run_ssh_submenu_loop()` — SSH 子菜单循环
- `show_firewall_submenu()` — 防火墙子菜单
- `run_firewall_submenu_loop()` — 防火墙子菜单循环
- `show_system_status()` — 仅检测并显示状态，不修改
- `view_report()` — 查看上次报告
- `run_quick_hardening()` — 一键快速加固（替代原 run_quick_start）
- `_parse_extended_args()` — 解析新增的非交互参数

**修改函数：**
- `_parse_args()` — 增加 `--ssh`, `--firewall`, `--fail2ban`, `--status`, `--quick` 参数
- `main()` — 改为根据参数决定进入交互菜单还是直接执行

#### 3.2.2 新的 main() 伪代码

```bash
main() {
    load_dependencies
    init_logging
    setup_error_trap

    # 根据非交互参数直接执行（不显示菜单）
    if [[ "${AUTO_ACCEPT}" == "yes" ]]; then
        case "${TARGET_MODULE:-all}" in
            ssh)       run_ssh_hardening ;;
            firewall)  run_firewall_hardening ;;
            fail2ban)  run_fail2ban_hardening ;;
            status)    run_detection; print_detection_summary; exit 0 ;;
            all)       run_all_hardening ;;
        esac
        generate_report
        exit 0
    fi

    # 交互模式：显示欢迎 → 系统检测 → 主菜单循环
    show_welcome
    run_detection || log_warn "..."
    print_detection_summary
    run_main_menu_loop
}
```

#### 3.2.3 主菜单循环伪代码

```bash
run_main_menu_loop() {
    while true; do
        show_main_menu
        local choice
        choice=$(get_main_menu_choice)

        case "${choice}" in
            1) show_system_status ;;
            2) run_ssh_submenu_loop ;;
            3) run_firewall_submenu_loop ;;
            4) run_fail2ban_hardening ;;
            5) run_quick_hardening ;;
            6) view_report ;;
            0) cleanup_and_exit ;;
        esac
    done
}
```

---

## 4. 用户体验要求

1. **每个操作完成后暂停**: 显示"按 Enter 返回主菜单"
2. **颜色区分**: 绿色=可选操作，蓝色=信息，黄色=警告，红色=错误
3. **系统状态摘要**: 主菜单顶部始终显示 OS、架构、用户、当前 SSH 端口
4. **操作反馈**: 每个任务执行后显示成功/失败状态
5. **幂等提示**: 如果某项已配置过，提示"已配置，是否重新配置？"

---

## 5. 风险评估

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| 改动面大，可能引入新 bug | 高 | 保留原有 SSH/firewall/fail2ban 执行函数不变，仅改入口层 |
| 现有 `--yes` 用户脚本兼容性 | 中 | 保留 `--yes` 为 `--quick` 的别名 |
| 子菜单循环退出逻辑 | 低 | 使用 `return` 返回主菜单，`exit` 退出脚本 |

---

## 6. 验收标准

- [ ] 脚本启动后显示主菜单，不会自动执行任何修改操作
- [ ] 选择"系统状态检测"只显示信息，不修改系统
- [ ] 可以单独执行 SSH/防火墙/Fail2Ban 中的任意一项
- [ ] 每项执行完成后返回主菜单，可以继续操作其他项
- [ ] "一键快速加固"等同于原"快速开始"功能
- [ ] `--ssh`, `--firewall`, `--fail2ban`, `--status` 非交互参数正常工作
- [ ] `--yes` 保持向后兼容
- [ ] 中英文翻译完整

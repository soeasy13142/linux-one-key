#!/usr/bin/env bash
# 中文语言文件
# 所有用户可见的字符串翻译

# ═══════════════════════════════════════════
# 通用
# ═══════════════════════════════════════════

MSG_WELCOME="欢迎使用 Linux 云服务器安全加固脚本"
MSG_VERSION="版本"
MSG_DESCRIPTION="本脚本将帮助您快速配置服务器安全选项"
MSG_PRESS_ENTER="按 Enter 继续..."
MSG_YES="是"
MSG_NO="否"
MSG_CONFIRM="确认"
MSG_CANCEL="取消"
MSG_SKIP="跳过"
MSG_CONTINUE="继续"
MSG_BACK="返回"
MSG_EXIT="退出"

# ═══════════════════════════════════════════
# 系统检测
# ═══════════════════════════════════════════

MSG_DETECT_START="正在检测系统环境..."
MSG_DETECT_OS="操作系统"
MSG_DETECT_VERSION="系统版本"
MSG_DETECT_ARCH="系统架构"
MSG_DETECT_USER="当前用户"
MSG_DETECT_ROOT="root 用户"
MSG_DETECT_NORMAL_USER="普通用户"
MSG_DETECT_PKG_MANAGER="包管理器"
MSG_DETECT_NETWORK="网络连接"
MSG_DETECT_NETWORK_OK="正常"
MSG_DETECT_NETWORK_FAIL="失败"
MSG_DETECT_COMPLETE="系统检测完成"

MSG_ERROR_NOT_ROOT="错误：请使用 root 用户运行此脚本"
MSG_ERROR_UNSUPPORTED_OS="错误：不支持的操作系统"
MSG_ERROR_NO_NETWORK="错误：无法连接网络，请检查网络设置"

# ═══════════════════════════════════════════
# 菜单
# ═══════════════════════════════════════════

MSG_MENU_TITLE="请选择加固模式"
MSG_MENU_BASIC="[1] 基础加固（推荐新手）"
MSG_MENU_STANDARD="[2] 标准加固（推荐）"
MSG_MENU_ADVANCED="[3] 高级加固（有经验用户）"
MSG_MENU_CUSTOM="[4] 自定义（逐项选择）"
MSG_MENU_CHOICE="请输入选项编号"
MSG_MENU_INVALID="无效选项，请重新选择"

MSG_MODE_BASIC="基础加固"
MSG_MODE_STANDARD="标准加固"
MSG_MODE_ADVANCED="高级加固"
MSG_MODE_CUSTOM="自定义"

# ═══════════════════════════════════════════
# 主菜单
# ═══════════════════════════════════════════

MSG_MAIN_MENU_TITLE="主菜单"
MSG_MAIN_MENU_STATUS="[1] 系统状态检测"
MSG_MAIN_MENU_STATUS_DESC="查看当前系统安全状态（不修改任何配置）"
MSG_MAIN_MENU_SSH="[2] SSH 安全加固"
MSG_MAIN_MENU_SSH_DESC="端口修改、密钥认证、禁止root/密码登录"
MSG_MAIN_MENU_FIREWALL="[3] 防火墙配置"
MSG_MAIN_MENU_FIREWALL_DESC="UFW/firewalld 规则配置"
MSG_MAIN_MENU_FAIL2BAN="[4] Fail2Ban 入侵防护"
MSG_MAIN_MENU_FAIL2BAN_DESC="自动封禁恶意登录尝试"
MSG_MAIN_MENU_AUDIT="[5] 审计日志"
MSG_MAIN_MENU_AUDIT_DESC="配置 auditd 系统审计，监控安全事件"
MSG_MAIN_MENU_USERS="[6] 用户管理"
MSG_MAIN_MENU_USERS_DESC="创建用户、配置密码、SSH密钥、sudo权限"
MSG_MAIN_MENU_KERNEL="[7] 内核安全加固"
MSG_MAIN_MENU_KERNEL_DESC="sysctl 安全参数、内核模块限制"
MSG_MAIN_MENU_FILESYSTEM="[8] 文件系统安全"
MSG_MAIN_MENU_FILESYSTEM_DESC="目录权限检查、SUID审计、无主文件检查"
MSG_MAIN_MENU_QUICK="[9] 完整安全配置向导"
MSG_MAIN_MENU_QUICK_DESC="逐步引导完成所有安全配置，每步可选择"
MSG_MAIN_MENU_REPORT="[10] 查看上次加固报告"
MSG_MAIN_MENU_REPORT_DESC="查看上次安全加固的详细报告"
MSG_MAIN_MENU_EXIT="[0] 退出"
MSG_MAIN_MENU_PROMPT="请输入选项"
MSG_MAIN_MENU_CHOICE="请选择操作"
MSG_MAIN_MENU_SYSTEM_INFO="系统"

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

# 系统状态检测
MSG_STATUS_TITLE="系统安全状态检测"
MSG_STATUS_SSH_PORT="SSH 端口"
MSG_STATUS_SSH_ROOT="root 远程登录"
MSG_STATUS_SSH_PASSWD="密码认证"
MSG_STATUS_SSH_KEY="密钥认证"
MSG_STATUS_FIREWALL="防火墙"
MSG_STATUS_FAIL2BAN="Fail2Ban"
MSG_STATUS_AUDIT="审计日志"
MSG_STATUS_ENABLED="已启用"
MSG_STATUS_DISABLED="未启用"
MSG_STATUS_INSTALLED="已安装"
MSG_STATUS_NOT_INSTALLED="未安装"
MSG_STATUS_ALLOWED="允许"
MSG_STATUS_NOT_ALLOWED="禁止"
MSG_STATUS_DEFAULT_PORT="默认端口，建议修改"
MSG_STATUS_CONFIGURED="已配置"
MSG_DETECTION_SUMMARY="系统检测摘要:"

# 报告查看
MSG_REPORT_NOT_FOUND="暂无加固报告，请先执行安全加固"

# 操作确认
MSG_CONFIRM_SSH_PORT="确认修改 SSH 端口？"
MSG_CONFIRM_SSH_KEY="确认生成 SSH 密钥对？"
MSG_CONFIRM_SSH_ROOT="确认禁止 root 远程登录？"
MSG_CONFIRM_SSH_PASSWD="确认禁止密码登录？"
MSG_CONFIRM_SSH_PARAMS="确认配置 SSH 安全参数？"
MSG_CONFIRM_SSH_ALL="确认执行全部 SSH 加固？"
MSG_CONFIRM_FIREWALL_ENABLE="确认启用防火墙？"
MSG_CONFIRM_FIREWALL_HTTP="确认开放 HTTP/HTTPS 端口？"
MSG_CONFIRM_FIREWALL_ICMP="确认允许 ICMP ping？"
MSG_CONFIRM_FAIL2BAN="确认安装并配置 Fail2Ban？"

# 快速加固
MSG_QUICK_TITLE="一键快速加固"

# ═══════════════════════════════════════════
# 任务描述
# ═══════════════════════════════════════════

MSG_TASK_SSH="SSH 安全加固"
MSG_TASK_FIREWALL="防火墙配置"
MSG_TASK_FAIL2BAN="Fail2Ban 入侵防护"
MSG_TASK_USER_MGMT="用户管理"
MSG_TASK_KERNEL="内核安全加固"
MSG_TASK_FILESYSTEM="文件系统安全"
MSG_TASK_AUDIT="审计日志配置"
MSG_TASK_SERVICES="服务管理"
MSG_TASK_DEV_COMING_SOON="开发中..."

MSG_TASK_SSH_DESC="配置 SSH 安全选项，包括修改端口、密钥认证、禁止 root 登录等"
MSG_TASK_FIREWALL_DESC="配置防火墙规则，限制不必要的网络访问"
MSG_TASK_FAIL2BAN_DESC="安装并配置 Fail2Ban，防止暴力破解"

# ═══════════════════════════════════════════
# SSH 安全
# ═══════════════════════════════════════════

MSG_SSH_START="开始 SSH 安全加固..."
MSG_SSH_BACKUP="备份 SSH 配置文件"
MSG_SSH_BACKUP_SUCCESS="备份成功"
MSG_SSH_BACKUP_FAIL="备份失败"

# SSH 端口
MSG_SSH_PORT_TITLE="修改 SSH 端口"
MSG_SSH_PORT_CURRENT="当前 SSH 端口"
MSG_SSH_PORT_PROMPT="请输入新的 SSH 端口号"
MSG_SSH_PORT_DEFAULT="默认"
MSG_SSH_PORT_INVALID="端口号无效，请输入 1-65535 之间的数字"
MSG_SSH_PORT_IN_USE="端口已被占用，请选择其他端口"
MSG_SSH_PORT_SUCCESS="SSH 端口已修改"
MSG_SSH_PORT_HINT="请使用以下命令连接：ssh -p {port} user@your-server-ip"

# SSH 端口交互选项
MSG_SSH_PORT_OPTION_TITLE="请选择 SSH 端口配置方式"
MSG_SSH_PORT_OPTION_CUSTOM="[1] 输入自定义端口 (默认: 2222)"
MSG_SSH_PORT_OPTION_RANDOM="[2] 生成随机高端口 (1024-65535)"
MSG_SSH_PORT_OPTION_KEEP="[3] 保持当前端口 (跳过)"
MSG_SSH_PORT_OPTION_PROMPT="请输入选项 [1-3]"
MSG_SSH_PORT_RANDOM_GEN="已生成随机端口: "
MSG_SSH_PORT_RANDOM_ACCEPT="是否使用此端口？(y=使用 / n=重新生成 / 输入数字=自定义)"
MSG_SSH_PORT_CONFIRM="确认将 SSH 端口从 {current} 修改为 {new}？"
MSG_SSH_PORT_SKIP="跳过 SSH 端口修改"

# SSH 参数自定义
MSG_SSH_PARAMS_CUSTOM_TITLE="SSH 安全参数配置"
MSG_SSH_PARAMS_CUSTOM_PROMPT="每个参数将展示默认值，您可以直接回车接受或输入新值"
MSG_SSH_PARAMS_MAXAUTHTRIES="最大认证尝试次数 (MaxAuthTries)"
MSG_SSH_PARAMS_LOGINGRACETIME="登录超时秒数 (LoginGraceTime)"
MSG_SSH_PARAMS_CLIENTALIVEINTERVAL="客户端心跳间隔秒数 (ClientAliveInterval)"
MSG_SSH_PARAMS_CLIENTALIVECOUNTMAX="最大心跳失败次数 (ClientAliveCountMax)"
MSG_SSH_PARAMS_MAXSESSIONS="最大并发会话数 (MaxSessions)"

# Fail2Ban 自定义参数
MSG_FAIL2BAN_CUSTOM_TITLE="Fail2Ban 参数配置"
MSG_FAIL2BAN_CUSTOM_PROMPT="每个参数将展示默认值，您可以直接回车接受或输入新值"
MSG_FAIL2BAN_BANTIME_PROMPT="封禁时长（秒）(bantime)"
MSG_FAIL2BAN_FINDTIME_PROMPT="检测时间窗口（秒）(findtime)"
MSG_FAIL2BAN_MAXRETRY_PROMPT="最大失败次数 (maxretry)"

# 完整向导
MSG_WIZARD_TITLE="完整安全配置向导"
MSG_WIZARD_DESC="将逐步引导您完成所有安全配置，每步可选择：确认/修改/跳过"
MSG_WIZARD_STEP_SSH="[1/8] SSH 安全加固"
MSG_WIZARD_STEP_FIREWALL="[2/8] 防火墙配置"
MSG_WIZARD_STEP_FAIL2BAN="[3/8] Fail2Ban 入侵防护"
MSG_WIZARD_STEP_AUDIT="[4/8] 审计日志配置"
MSG_WIZARD_STEP_USERS="[5/8] 用户管理"
MSG_WIZARD_STEP_KERNEL="[6/8] 内核安全加固"
MSG_WIZARD_STEP_FILESYSTEM="[7/8] 文件系统安全"
MSG_WIZARD_STEP_SUMMARY="[8/8] 变更摘要与确认"
MSG_WIZARD_SKIP_STEP="跳过此步骤？(y/N)"
MSG_WIZARD_COMPLETE="向导完成"
MSG_WIZARD_SKIPPED="已跳过"
MSG_WIZARD_SKIPPED_SSH="跳过 SSH 安全加固"
MSG_WIZARD_ERR_SSH="SSH 加固出现错误，继续后续步骤"
MSG_WIZARD_SKIPPED_FIREWALL="跳过防火墙配置"
MSG_WIZARD_ERR_FIREWALL="防火墙配置出现错误"
MSG_WIZARD_SKIPPED_FAIL2BAN="跳过 Fail2Ban 配置"
MSG_WIZARD_ERR_FAIL2BAN="Fail2Ban 配置出现错误"
MSG_WIZARD_SKIPPED_AUDIT="跳过审计日志配置"
MSG_WIZARD_ERR_AUDIT="审计日志配置出现错误"
MSG_WIZARD_SKIPPED_USERS="跳过用户管理"
MSG_WIZARD_ERR_USERS="用户管理出现错误"
MSG_WIZARD_SKIPPED_KERNEL="跳过内核加固"
MSG_WIZARD_ERR_KERNEL="内核加固出现错误"
MSG_WIZARD_SKIPPED_FILESYSTEM="跳过文件系统检查"
MSG_WIZARD_ERR_FILESYSTEM="文件系统检查出现错误"
MSG_WIZARD_ERR_HINT="（部分步骤出现错误，请查看日志）"

# SSH 密钥
MSG_SSH_KEY_TITLE="生成 SSH 密钥对"
MSG_SSH_KEY_TYPE="密钥类型"
MSG_SSH_KEY_ED25519="Ed25519（推荐）"
MSG_SSH_KEY_PROMPT_PATH="请输入密钥保存路径"
MSG_SSH_KEY_PROMPT_PASSPHRASE="请输入密钥密码（留空则无密码）"
MSG_SSH_KEY_SUCCESS="SSH 密钥已生成"
MSG_SSH_KEY_AUTHORIZED="公钥已添加到 authorized_keys"
MSG_SSH_KEY_PERMS="已设置正确的文件权限"

# Root 登录
MSG_SSH_ROOT_TITLE="禁止 root 远程登录"
MSG_SSH_ROOT_DESC="禁止 root 用户通过 SSH 登录，提高安全性"
MSG_SSH_ROOT_NO_USER="警告：当前没有其他可登录用户"
MSG_SSH_ROOT_CREATE_USER="请先创建一个具有 sudo 权限的普通用户"
MSG_SSH_ROOT_RISK="风险提示：禁用后 root 将无法通过 SSH 登录"
MSG_SSH_ROOT_CONFIRM="确认禁止 root 远程登录？"
MSG_SSH_ROOT_SUCCESS="已禁止 root 远程登录"

# 密码登录
MSG_SSH_PASSWD_TITLE="禁止密码登录"
MSG_SSH_PASSWD_DESC="禁用密码认证，仅允许密钥认证"
MSG_SSH_PASSWD_NO_KEY="警告：未检测到有效的 SSH 密钥"
MSG_SSH_PASSWD_RISK="风险提示：禁用密码登录后，必须使用密钥登录"
MSG_SSH_PASSWD_CONFIRM="确认禁止密码登录？"
MSG_SSH_PASSWD_SUCCESS="已禁止密码登录，仅允许密钥认证"

# 其他安全参数
MSG_SSH_PARAMS_TITLE="配置其他 SSH 安全参数"
MSG_SSH_PARAMS_SUCCESS="SSH 安全参数已配置"

# 验证
MSG_SSH_VALIDATE="验证 SSH 配置..."
MSG_SSH_VALIDATE_SUCCESS="SSH 配置验证通过"
MSG_SSH_VALIDATE_FAIL="SSH 配置验证失败"
MSG_SSH_RESTART="重启 SSH 服务..."
MSG_SSH_RESTART_SUCCESS="SSH 服务已重启"
MSG_SSH_RESTART_FAIL="SSH 服务重启失败"

# 回滚保护
MSG_SSH_ROLLBACK_TIMER="设置 SSH 回滚保护定时器（5 分钟）"
MSG_SSH_ROLLBACK_HINT="如果 5 分钟内无法通过新配置连接，将自动回滚"
MSG_SSH_ROLLBACK_CANCEL="检测到新连接，取消回滚定时器"
MSG_SSH_ROLLBACK_EXEC="5 分钟内无新连接，正在回滚 SSH 配置..."
MSG_SSH_ROLLBACK_SUCCESS="SSH 配置已回滚到原始状态"
MSG_SSH_ROLLBACK_CRON="已设置回滚定时任务"

MSG_SSH_COMPLETE="SSH 安全加固完成"

# ═══════════════════════════════════════════
# 防火墙
# ═══════════════════════════════════════════

MSG_FIREWALL_TITLE="防火墙配置"
MSG_FIREWALL_INSTALL="安装防火墙工具..."
MSG_FIREWALL_INSTALL_DONE="防火墙工具安装完成"
MSG_FIREWALL_ALREADY_INSTALLED="防火墙工具已安装"
MSG_FIREWALL_UNSUPPORTED_OS="不支持的操作系统，跳过防火墙配置"
MSG_FIREWALL_RESET="重置防火墙规则..."
MSG_FIREWALL_RESET_DONE="防火墙规则已重置"
MSG_FIREWALL_DEFAULT_POLICY="配置默认策略：拒绝入站，允许出站..."
MSG_FIREWALL_DEFAULT_POLICY_DONE="默认策略已配置"
MSG_FIREWALL_CONFIG_SSH="开放 SSH 端口..."
MSG_FIREWALL_PORT_OPENED="已开放端口"
MSG_FIREWALL_PORT_CLOSED="已关闭端口"
MSG_FIREWALL_HTTP_PROMPT="是否需要开放 HTTP/HTTPS 端口？"
MSG_FIREWALL_HTTP_CONFIRM="开放 HTTP (80) 和 HTTPS (443) 端口"
MSG_FIREWALL_ICMP_PROMPT="是否允许 ping (ICMP)？"
MSG_FIREWALL_ICMP_CONFIRM="允许 ICMP ping 请求"
MSG_FIREWALL_ICMP_DEFAULT="UFW 默认允许 ICMP"
MSG_FIREWALL_ICMP_ALLOWED="已允许 ICMP"
MSG_FIREWALL_ICMP_DENIED="已禁止 ICMP"
MSG_FIREWALL_ICMP_UFW_NOTE="UFW 需要手动修改 /etc/ufw/before.rules 来禁止 ICMP"
MSG_FIREWALL_ENABLE="启用防火墙..."
MSG_FIREWALL_ENABLE_DONE="防火墙已启用"
MSG_FIREWALL_STATUS="防火墙状态"
MSG_FIREWALL_DONE="防火墙配置完成"
MSG_FIREWALL_SSH_PORT22="安全保护：已保留放通 22 端口（防止 SSH 端口变更后锁死）"
MSG_FIREWALL_SSH_PORT22_WARN="⚠ 请在确认新 SSH 端口可用后，手动关闭 22 端口："
MSG_FIREWALL_SSH_PORT22_CLOSE="   sudo ufw deny 22/tcp"
MSG_FIREWALL_CUSTOM_PORTS="需要开放其他端口吗？（输入端口号，留空结束）"
MSG_FIREWALL_INVALID_PORT="端口号无效，请输入 1-65535 之间的数字"

MSG_FIREWALL_TIPS_TITLE="防火墙管理命令："
MSG_FIREWALL_TIPS_UFW_1="查看状态: sudo ufw status verbose"
MSG_FIREWALL_TIPS_UFW_2="开放端口: sudo ufw allow <port>"
MSG_FIREWALL_TIPS_UFW_3="关闭端口: sudo ufw deny <port>"
MSG_FIREWALL_TIPS_UFW_4="禁用防火墙: sudo ufw disable"

MSG_FIREWALL_TIPS_FIREWALLD_1="查看状态: firewall-cmd --list-all"
MSG_FIREWALL_TIPS_FIREWALLD_2="开放端口: firewall-cmd --permanent --add-port=<port>/tcp"
MSG_FIREWALL_TIPS_FIREWALLD_3="关闭端口: firewall-cmd --permanent --remove-port=<port>/tcp"
MSG_FIREWALL_TIPS_FIREWALLD_4="重新加载: firewall-cmd --reload"

# ═══════════════════════════════════════════
# Fail2Ban
# ═══════════════════════════════════════════

MSG_FAIL2BAN_TITLE="Fail2Ban 入侵防护"
MSG_FAIL2BAN_INSTALL="安装 Fail2Ban..."
MSG_FAIL2BAN_INSTALL_DONE="Fail2Ban 安装完成"
MSG_FAIL2BAN_ALREADY_INSTALLED="Fail2Ban 已安装"
MSG_FAIL2BAN_UNSUPPORTED_OS="不支持的操作系统，跳过 Fail2Ban 配置"
MSG_FAIL2BAN_CONFIGURE="配置 Fail2Ban jail..."
MSG_FAIL2BAN_CONFIGURE_DONE="Fail2Ban jail 配置完成"
MSG_FAIL2BAN_CONFIG_INFO="Fail2Ban 配置信息："
MSG_FAIL2BAN_ENABLE="启动 Fail2Ban 服务..."
MSG_FAIL2BAN_ENABLE_DONE="Fail2Ban 服务已启动"
MSG_FAIL2BAN_ENABLE_FAILED="Fail2Ban 服务启动失败"
MSG_FAIL2BAN_STATUS="Fail2Ban 状态"
MSG_FAIL2BAN_SERVICE_STATUS="服务状态："
MSG_FAIL2BAN_JAIL_STATUS="Jail 状态："
MSG_FAIL2BAN_BANNED_LIST="已封禁 IP："
MSG_FAIL2BAN_JAIL_NOT_FOUND="Jail 未找到"
MSG_FAIL2BAN_NOT_INSTALLED="Fail2Ban 未安装"
MSG_FAIL2BAN_IP_BANNED="已封禁 IP"
MSG_FAIL2BAN_IP_UNBANNED="已解封 IP"
MSG_FAIL2BAN_DONE="Fail2Ban 配置完成"

MSG_FAIL2BAN_TIPS_TITLE="Fail2Ban 管理命令："
MSG_FAIL2BAN_TIPS_1="查看状态: fail2ban-client status"
MSG_FAIL2BAN_TIPS_2="查看 jail: fail2ban-client status sshd"
MSG_FAIL2BAN_TIPS_3="封禁 IP: fail2ban-client set sshd banip <ip>"
MSG_FAIL2BAN_TIPS_4="解封 IP: fail2ban-client set sshd unbanip <ip>"
MSG_FAIL2BAN_TIPS_5="重启服务: systemctl restart fail2ban"

# ═══════════════════════════════════════════
# 审计日志
# ═══════════════════════════════════════════

MSG_AUDIT_TITLE="审计日志配置"
MSG_AUDIT_INSTALL="正在安装 auditd..."
MSG_AUDIT_INSTALL_DONE="auditd 安装完成"
MSG_AUDIT_INSTALL_FAILED="auditd 安装失败"
MSG_AUDIT_ALREADY_INSTALLED="auditd 已安装"
MSG_AUDIT_UNSUPPORTED_OS="不支持的操作系统，跳过审计配置"
MSG_AUDIT_BACKUP_RULES="备份审计规则文件"
MSG_AUDIT_BACKUP_CONF="备份 auditd 配置文件"
MSG_AUDIT_CONFIGURE_RULES="正在生成审计规则..."
MSG_AUDIT_CONFIGURE_RULES_DONE="审计规则生成完成"
MSG_AUDIT_CONFIGURE_CONF="正在配置 auditd..."
MSG_AUDIT_CONFIGURE_CONF_DONE="auditd 配置完成"
MSG_AUDIT_LOAD_RULES="正在加载审计规则..."
MSG_AUDIT_LOAD_RULES_DONE="审计规则已加载"
MSG_AUDIT_LOAD_RULES_WARN="部分规则加载失败（可能与内核版本不兼容）"
MSG_AUDIT_ENABLE="正在启用 auditd 服务..."
MSG_AUDIT_ENABLE_DONE="auditd 服务已启用"
MSG_AUDIT_ENABLE_FAILED="auditd 服务启用失败"
MSG_AUDIT_STATUS="审计状态"
MSG_AUDIT_SERVICE_STATUS="服务状态："
MSG_AUDIT_RULES_COUNT="规则数量："
MSG_AUDIT_LOG_INFO="日志文件："
MSG_AUDIT_LOG_NOT_FOUND="尚未生成"
MSG_AUDIT_CONFIG_INFO="当前审计配置信息："
MSG_AUDIT_DONE="审计日志配置完成！"
MSG_AUDIT_NOT_INSTALLED="auditd 未安装"

# 审计向导 - 规则级别
MSG_AUDIT_RULES_LEVEL_TITLE="请选择审计规则级别"
MSG_AUDIT_RULES_BASIC="[1] 基础规则 - 身份认证、SSH、sudo 监控"
MSG_AUDIT_RULES_STANDARD="[2] 标准规则 - 基础 + 网络、cron、日志防篡改（推荐）"
MSG_AUDIT_RULES_FULL="[3] 全面规则 - 所有安全事件监控"
MSG_AUDIT_RULES_LEVEL_PROMPT="请选择规则级别"

# 审计向导 - 自定义参数
MSG_AUDIT_CUSTOM_TITLE="auditd 参数配置"
MSG_AUDIT_CUSTOM_PROMPT="每个参数将展示默认值，您可以直接回车接受或输入新值"
MSG_AUDIT_LOG_SIZE_PROMPT="单个日志文件最大大小 (MB)"
MSG_AUDIT_LOG_COUNT_PROMPT="保留日志文件份数"
MSG_AUDIT_INVALID_CHOICE="无效选项，使用默认值（标准规则）"
MSG_AUDIT_INVALID_NUMBER="请输入有效的正整数"

# 审计日志搜索/报告
MSG_AUDIT_SEARCH="搜索审计日志 (key={key})..."
MSG_AUDIT_REPORT="生成审计报告..."
MSG_AUDIT_REPORT_SUMMARY="审计报告摘要："
MSG_AUDIT_REPORT_AUTH="认证审计摘要："

# 审计管理提示
MSG_AUDIT_TIPS_TITLE="审计日志管理命令："
MSG_AUDIT_TIPS_1="查看规则: auditctl -l"
MSG_AUDIT_TIPS_2="搜索日志: ausearch -k <key> -i"
MSG_AUDIT_TIPS_3="审计报告: aureport --summary"
MSG_AUDIT_TIPS_4="实时日志: tail -f /var/log/audit/audit.log"
MSG_AUDIT_TIPS_5="服务状态: systemctl status auditd"

# ═══════════════════════════════════════════
# 用户管理
# ═══════════════════════════════════════════

MSG_USERS_WIZARD_TITLE="用户管理向导"
MSG_USERS_WIZARD_DESC="创建管理员用户、配置密码、SSH密钥、sudo权限"
MSG_USERS_WIZARD_START="是否开始用户管理配置？"
MSG_USERS_WIZARD_SKIPPED="跳过用户管理配置"
MSG_USERS_WIZARD_DONE="用户管理配置完成"

MSG_USERS_CREATE_TITLE="创建管理员用户"
MSG_USERS_ENTER_USERNAME="请输入用户名"
MSG_USERS_ENTER_USERNAME_PASS="请输入要设置密码的用户名"
MSG_USERS_ENTER_USERNAME_SSH="请输入要配置 SSH 密钥的用户名"
MSG_USERS_ENTER_USERNAME_SUDO="请输入要配置 sudo 的用户名"
MSG_USERS_NAME_EMPTY="用户名不能为空"
MSG_USERS_NAME_TOO_SHORT="用户名长度必须在 3-32 个字符之间"
MSG_USERS_NAME_INVALID="用户名格式无效（字母或下划线开头，仅含字母数字下划线和连字符）"
MSG_USERS_ALREADY_EXISTS="用户已存在"
MSG_USERS_NOT_FOUND="用户不存在"
MSG_USERS_CREATING="正在创建用户"
MSG_USERS_CREATE_DONE="用户创建成功"
MSG_USERS_CREATE_FAILED="用户创建失败"
MSG_USERS_CREATE_SKIPPED="跳过用户创建"
MSG_USERS_CONFIRM_CREATE="确认创建此用户并添加到 sudo 组？"
MSG_USERS_WILL_CREATE="将创建用户"

MSG_USERS_SET_PASS_TITLE="设置用户密码"
MSG_USERS_ENTER_PASS="请输入密码"
MSG_USERS_CONFIRM_PASS="请再次输入密码"
MSG_USERS_PASS_TOO_SHORT="密码长度不能少于 8 个字符"
MSG_USERS_PASS_MISMATCH="两次输入的密码不一致"
MSG_USERS_SETTING_PASS="正在设置密码"
MSG_USERS_PASS_SET_DONE="密码设置成功"
MSG_USERS_PASS_SET_FAILED="密码设置失败"

MSG_USERS_SSH_KEY_TITLE="配置 SSH 密钥"
MSG_USERS_SSH_KEY_EXISTS="SSH 密钥已存在"
MSG_USERS_SSH_KEY_OVERWRITE="是否覆盖现有密钥？"
MSG_USERS_SSH_KEY_SKIPPED="跳过 SSH 密钥配置"
MSG_USERS_SSH_KEY_GENERATING="正在生成 Ed25519 密钥对"
MSG_USERS_SSH_KEY_FAILED="SSH 密钥生成失败"
MSG_USERS_SSH_KEY_DONE="SSH 密钥已生成"
MSG_USERS_SSH_KEY_HINT="请将私钥下载到本地安全保存。警告：密钥无密码保护，请妥善保管。"

MSG_USERS_SUDO_TITLE="配置 sudo NOPASSWD"
MSG_USERS_SUDO_SECURITY_HINT="安全提示：NOPASSWD 允许该用户无密码执行 sudo，存在安全风险"
MSG_USERS_SUDO_CONFIGURING="正在配置 sudo NOPASSWD"
MSG_USERS_SUDO_ALREADY_CONFIGURED="sudo NOPASSWD 已配置"
MSG_USERS_SUDO_SYNTAX_ERROR="sudoers 文件语法错误，已回滚"
MSG_USERS_SUDO_DONE="sudo NOPASSWD 配置完成"
MSG_USERS_NOT_IN_SUDO="用户不在 sudo 组中"
MSG_USERS_ADD_TO_SUDO="是否将用户添加到 sudo 组？"
MSG_USERS_ADDED_TO_SUDO="已添加到 sudo 组"
MSG_USERS_SUDO_ADD_FAILED="添加到 sudo 组失败"

MSG_USERS_STEP_CREATE="[1/4] 创建管理员用户"
MSG_USERS_STEP_CREATE_CONFIRM="是否创建新的管理员用户？"
MSG_USERS_STEP_PASS="[2/4] 设置用户密码"
MSG_USERS_STEP_PASS_CONFIRM="是否为用户设置密码？"
MSG_USERS_STEP_SSH="[3/4] 配置 SSH 密钥"
MSG_USERS_STEP_SSH_CONFIRM="是否为用户生成 SSH 密钥？"
MSG_USERS_STEP_SUDO="[4/4] 配置 sudo NOPASSWD"
MSG_USERS_STEP_SUDO_CONFIRM="是否配置 sudo NOPASSWD？（默认跳过）"
MSG_USERS_STEP_SKIPPED="跳过此步骤"

MSG_USERS_SUMMARY="用户管理摘要"
MSG_USERS_SUMMARY_USER="用户名"
MSG_USERS_SUMMARY_GROUP="sudo 组"
MSG_USERS_SUMMARY_HOME="家目录"
MSG_USERS_SUMMARY_NONE="未创建新用户"

# ═══════════════════════════════════════════
# 内核加固
# ═══════════════════════════════════════════

MSG_KERNEL_WIZARD_TITLE="内核安全加固向导"
MSG_KERNEL_WIZARD_DESC="配置 sysctl 安全参数、禁用不需要的内核模块"
MSG_KERNEL_WIZARD_START="是否开始内核安全加固？"
MSG_KERNEL_WIZARD_SKIPPED="跳过内核安全加固"
MSG_KERNEL_WIZARD_DONE="内核安全加固完成"

MSG_KERNEL_SYSCTL_TITLE="sysctl 安全参数配置"
MSG_KERNEL_SYSCTL_APPLYING="正在应用 sysctl 安全参数"
MSG_KERNEL_SYSCTL_DONE="sysctl 安全参数已应用"
MSG_KERNEL_SYSCTL_PARTIAL="部分 sysctl 参数应用失败"
MSG_KERNEL_TEMPLATE_NOT_FOUND="sysctl 模板文件不存在，使用内置配置"
MSG_KERNEL_BACKUP_CONF="备份 sysctl 安全配置"

MSG_KERNEL_VERIFYING="正在验证 sysctl 参数"
MSG_KERNEL_VERIFY_DONE="sysctl 参数验证通过"
MSG_KERNEL_VERIFY_FAILED="参数验证失败"
MSG_KERNEL_VERIFY_PARTIAL="部分参数验证未通过"
MSG_KERNEL_VERIFY_PARAMS_FAILED="个参数"

MSG_KERNEL_MODULES_TITLE="内核模块限制"
MSG_KERNEL_MODULE_DISABLE="正在禁用模块"
MSG_KERNEL_MODULE_DISABLED="已禁用"
MSG_KERNEL_MODULE_CANNOT_DISABLE="无法禁用"
MSG_KERNEL_MODULE_NOT_LOADED="模块未加载，已跳过"
MSG_KERNEL_MODULES_DONE="内核模块处理完成"
MSG_KERNEL_MODULES_DISABLED="个已禁用"
MSG_KERNEL_MODULES_SKIPPED="个已跳过"

MSG_KERNEL_RESTORE_TITLE="回滚 sysctl 配置"
MSG_KERNEL_RESTORE_CONF="恢复 sysctl 配置文件"
MSG_KERNEL_RESTORE_DONE="sysctl 配置已回滚"
MSG_KERNEL_RESTORE_FAILED="sysctl 配置回滚失败"
MSG_KERNEL_NO_CONF_TO_RESTORE="没有需要回滚的 sysctl 配置"
MSG_KERNEL_NO_BACKUP_FOUND="未找到备份文件，将删除加固配置"

MSG_KERNEL_STEP_SYSCTL="[1/2] sysctl 安全参数"
MSG_KERNEL_STEP_SYSCTL_CONFIRM="是否应用 sysctl 安全参数？"
MSG_KERNEL_STEP_MODULES="[2/2] 内核模块限制"
MSG_KERNEL_STEP_MODULES_CONFIRM="是否禁用不需要的内核模块？"
MSG_KERNEL_STEP_SKIPPED="跳过此步骤"

MSG_KERNEL_SYSCTL_SUMMARY_TITLE="将要设置的 sysctl 参数"
MSG_KERNEL_SYSCTL_SUMMARY_SYN="SYN Flood 防护 (tcp_syncookies)"
MSG_KERNEL_SYSCTL_SUMMARY_REDIRECT="禁止 ICMP 重定向"
MSG_KERNEL_SYSCTL_SUMMARY_ROUTE="禁止源路由"
MSG_KERNEL_SYSCTL_SUMMARY_FORWARD="禁止 IP 转发"
MSG_KERNEL_SYSCTL_SUMMARY_ASLR="ASLR 地址随机化"

MSG_KERNEL_MODULES_SUMMARY_TITLE="将要禁用的内核模块"

MSG_KERNEL_SUMMARY="内核加固摘要"
MSG_KERNEL_SUMMARY_CONF="配置文件"
MSG_KERNEL_SUMMARY_PARAMS="参数数量"
MSG_KERNEL_SUMMARY_NO_CONF="未生成配置文件"

# ═══════════════════════════════════════════
# 文件系统安全
# ═══════════════════════════════════════════

MSG_FS_WIZARD_TITLE="文件系统安全向导"
MSG_FS_WIZARD_DESC="检查关键目录权限、SUID/SGID 审计、无主文件检查"
MSG_FS_WIZARD_START="是否开始文件系统安全检查？"
MSG_FS_WIZARD_SKIPPED="跳过文件系统安全检查"
MSG_FS_WIZARD_DONE="文件系统安全检查完成"

MSG_FS_PERM_TITLE="关键目录权限检查"
MSG_FS_PERM_NOT_FOUND="文件不存在"
MSG_FS_PERM_MISMATCH="权限不匹配"
MSG_FS_PERM_OK="权限正确"
MSG_FS_PERM_ALL_OK="所有权限检查通过"
MSG_FS_PERM_CHECKED="个文件已检查"
MSG_FS_PERM_ISSUES="发现权限问题"

MSG_FS_PERM_FIX_TITLE="修复关键目录权限"
MSG_FS_PERM_FIXING="正在修复权限"
MSG_FS_PERM_FIXED="已修复"
MSG_FS_PERM_FIX_FAILED="权限修复失败"
MSG_FS_PERM_FIX_DONE="权限修复完成"
MSG_FS_PERM_FIX_SKIPPED="跳过修复"
MSG_FS_PERM_FIX_SKIPPED_COUNT="个已跳过"
MSG_FS_PERM_CONFIRM_FIX="是否修复此文件权限？"
MSG_FS_PERM_CURRENT="当前权限"
MSG_FS_PERM_EXPECTED="期望权限"
MSG_FS_PERM_ALREADY_OK="权限已正确"
MSG_FS_PERM_ISSUES_FOUND="发现权限问题，是否逐一修复？"

MSG_FS_SUID_TITLE="SUID/SGID 审计"
MSG_FS_SUID_SCANNING="正在扫描 SUID/SGID 文件..."
MSG_FS_SUID_RESULTS_TITLE="SUID/SGID 扫描结果"
MSG_FS_SUID_SUSPICIOUS="可疑"
MSG_FS_SUID_SUMMARY_TITLE="扫描摘要"
MSG_FS_SUID_TOTAL="SUID 文件数"
MSG_FS_SGID_TOTAL="SGID 文件数"
MSG_FS_SUID_SUSPICIOUS_COUNT="可疑文件数"
MSG_FS_SUID_SUSPICIOUS_HINT="发现可疑 SUID 文件，建议手动检查并移除不必要的 SUID 位"
MSG_FS_SUID_REMOVE_CMD="移除 SUID 位的命令:"
MSG_FS_SUID_ALL_KNOWN="所有 SUID 文件均为已知标准文件"

MSG_FS_ORPHAN_TITLE="无主文件检查"
MSG_FS_ORPHAN_SCANNING="正在扫描无主文件..."
MSG_FS_ORPHAN_NONE="未发现无主文件"
MSG_FS_ORPHAN_RESULTS_TITLE="无主文件列表"
MSG_FS_ORPHAN_FOUND="个无主文件"
MSG_FS_ORPHAN_TRUNCATED="仅显示前 50 条结果 — 可能存在更多无主文件"
MSG_FS_ORPHAN_HINT="发现无主文件"
MSG_FS_ORPHAN_FIX_CMD="修复建议: sudo chown root:root <file>"

MSG_FS_STEP_PERM="[1/3] 关键目录权限检查"
MSG_FS_STEP_SUID="[2/3] SUID/SGID 审计"
MSG_FS_STEP_SUID_CONFIRM="是否进行 SUID/SGID 审计？"
MSG_FS_STEP_ORPHAN="[3/3] 无主文件检查"
MSG_FS_STEP_ORPHAN_CONFIRM="是否检查无主文件？"
MSG_FS_STEP_SKIPPED="跳过此步骤"

MSG_FS_SUMMARY="文件系统安全检查摘要"
MSG_FS_SUMMARY_PERM_CHECK="权限检查"
MSG_FS_SUMMARY_SUID_CHECK="SUID 审计"
MSG_FS_SUMMARY_ORPHAN_CHECK="无主文件检查"
MSG_FS_SUMMARY_DONE="已完成"

# ═══════════════════════════════════════════
# 报告
# ═══════════════════════════════════════════

MSG_REPORT_TITLE="安全加固完成报告"
MSG_REPORT_SYSTEM="系统信息"
MSG_REPORT_TASKS="完成的任务"
MSG_REPORT_CONFIGS="修改的配置文件"
MSG_REPORT_WARNINGS="重要提醒"
MSG_REPORT_SAVED="报告已保存到"
MSG_REPORT_WARN_SSH_PORT22="防火墙已保留放通 22 端口，确认新 SSH 端口可用后请手动关闭: sudo ufw deny 22/tcp"
MSG_REPORT_WARN_FIREWALL="防火墙已启用，请确保已正确放通所需端口"
MSG_REPORT_WARN_FAIL2BAN="请定期检查 Fail2Ban 日志: sudo tail -f /var/log/fail2ban.log"
MSG_REPORT_WARN_AUDIT="请定期检查审计日志: sudo aureport --summary 或 sudo ausearch -k identity"
MSG_REPORT_WARN_FS="文件系统权限已更改，请验证关键服务是否正常工作"
MSG_STATUS_FS_SUID="SUID 文件数"

# ═══════════════════════════════════════════
# 日志
# ═══════════════════════════════════════════

MSG_LOG_START="开始执行"
MSG_LOG_COMPLETE="执行完成"
MSG_LOG_ERROR="执行出错"
MSG_LOG_BACKUP="备份文件"
MSG_LOG_RESTORE="恢复文件"

# ═══════════════════════════════════════════
# 错误和警告
# ═══════════════════════════════════════════

MSG_ERROR_SCRIPT_NOT_ROOT="此脚本必须以 root 权限运行"
MSG_ERROR_COMMAND_FAILED="命令执行失败"
MSG_ERROR_FILE_NOT_FOUND="文件不存在"
MSG_ERROR_BACKUP_FAILED="备份失败"
MSG_ERROR_RESTORE_FAILED="恢复失败"

MSG_WARN_CONNECTION="请确保在关闭当前会话前测试新配置"
MSG_WARN_SAVE_KEY="请确保已保存 SSH 私钥文件"
MSG_WARN_TEST_FIRST="请测试新配置后再关闭当前会话"

# ═══════════════════════════════════════════
# 完成信息
# ═══════════════════════════════════════════

MSG_FINISH="安全加固脚本执行完成"
MSG_FINISH_HINT="感谢使用，如有问题请查看日志文件"
MSG_GOODBYE="再见！"

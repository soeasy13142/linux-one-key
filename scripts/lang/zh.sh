#!/usr/bin/env bash
# 中文语言文件
# 所有用户可见的字符串翻译

# ═══════════════════════════════════════════
# 通用
# ═══════════════════════════════════════════

MSG_WELCOME="欢迎使用 Linux 云服务器安全加固脚本"
MSG_PRESS_ENTER="按 Enter 继续..."
MSG_CONFIRM="确认"
MSG_BACK="返回"

# ═══════════════════════════════════════════
# K3s (Lightweight Kubernetes)
# ═══════════════════════════════════════════

MSG_K3S_TITLE="K3s 轻量级 Kubernetes"
MSG_K3S_INSTALLING="正在安装 K3s..."
MSG_K3S_DOWNLOADING="正在从 https://get.k3s.io 下载安装脚本..."
MSG_K3S_INSTALLED="K3s 安装完成"
MSG_K3S_ALREADY="K3s 已安装，跳过"
MSG_K3S_FAILED="K3s 安装失败"
MSG_K3S_CANCELLED="K3s 操作已取消"
MSG_K3S_UNINSTALLING="正在卸载 K3s..."
MSG_K3S_UNINSTALLED="K3s 已卸载"
MSG_K3S_UNINSTALL_FAILED="K3s 卸载失败"
MSG_K3S_UNINSTALL_SCRIPT_NOT_FOUND="K3s 卸载脚本未找到：/usr/local/bin/k3s-uninstall.sh"
MSG_K3S_STATUS_CHECKING="正在检查 K3s 状态..."
MSG_K3S_STATUS_RUNNING="K3s 运行中"
MSG_K3S_STATUS_NOT_RUNNING="K3s 未运行"
MSG_K3S_CONFIRM="确认安装 K3s？"
MSG_K3S_CONFIRM_UNINSTALL="确认卸载 K3s？此操作将删除所有 K3s 数据和配置。"
MSG_K3S_CONFIGURING="正在配置 K3s..."
MSG_K3S_KUBECONFIG="kubeconfig 已复制到 ~/.kube/config"
MSG_K3S_KUBECONFIG_EXISTS="~/.kube/config 已存在，跳过复制"
MSG_K3S_NODE_READY="集群节点状态："
MSG_K3S_NODES_UNAVAILABLE="暂时无法获取节点状态（服务可能仍在启动中）"
MSG_K3S_DISABLE_TRAEFIK="Traefik 已禁用（--disable traefik）"
MSG_K3S_DISABLE_TRAEFIK_PROMPT="是否禁用内置 Traefik Ingress Controller？（推荐禁用）"
MSG_K3S_VERSION="K3s 版本"
MSG_K3S_BINARY="K3s 可执行文件"
MSG_K3S_NOT_INSTALLED="K3s 未安装"
MSG_K3S_CURL_REQUIRED="K3s 安装需要 curl，请先安装 curl"

# ═══════════════════════════════════════════
# 系统检测
# ═══════════════════════════════════════════

MSG_DETECT_START="正在检测系统环境..."
MSG_DETECT_OS="操作系统"
MSG_DETECT_ARCH="系统架构"
MSG_DETECT_USER="当前用户"
MSG_DETECT_ROOT="root 用户"
MSG_DETECT_NORMAL_USER="普通用户"
MSG_DETECT_PKG_MANAGER="包管理器"
MSG_DETECT_NETWORK="网络连接"
MSG_DETECT_NETWORK_FAIL="失败"
MSG_DETECT_COMPLETE="系统检测完成"

MSG_ERROR_NOT_ROOT="错误：请使用 root 用户运行此脚本"
MSG_ERROR_UNSUPPORTED_OS="错误：不支持的操作系统"

# ═══════════════════════════════════════════
# 菜单
# ═══════════════════════════════════════════

MSG_MENU_INVALID="无效选项，请重新选择"
MSG_ERROR_NO_INPUT="未检测到输入，非交互环境请使用 --status 模式"


# ═══════════════════════════════════════════
# 主菜单
# ═══════════════════════════════════════════

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
MSG_MAIN_MENU_SERVICES="[9] 服务管理"
MSG_MAIN_MENU_SERVICES_DESC="审计运行中的服务、禁用不必要服务、扫描开放端口"
MSG_MAIN_MENU_QUICK="[11] 完整安全配置向导"
MSG_MAIN_MENU_QUICK_DESC="逐步引导完成所有安全配置，每步可选择"
MSG_MAIN_MENU_REPORT="[12] 查看上次加固报告"
MSG_MAIN_MENU_REPORT_DESC="查看上次安全加固的详细报告"
MSG_MAIN_MENU_K3S="[13] K3s 轻量级 Kubernetes"
MSG_MAIN_MENU_K3S_DESC="安装或卸载轻量级 Kubernetes (K3s)"
MSG_MAIN_MENU_AUTOUPDATE="[10] 自动安全更新"
MSG_MAIN_MENU_AUTOUPDATE_DESC="配置自动安装安全更新"
MSG_MAIN_MENU_AIDE="[14] AIDE 入侵检测"
MSG_MAIN_MENU_AIDE_DESC="文件完整性检查系统，监控关键文件变更"
MSG_MAIN_MENU_CLAMAV="[15] ClamAV 病毒扫描"
MSG_MAIN_MENU_CLAMAV_DESC="开源杀毒软件，配置病毒库更新和定时扫描"
MSG_MAIN_MENU_ROOTKIT="[16] Rootkit 检测"
MSG_MAIN_MENU_ROOTKIT_DESC="rkhunter + chkrootkit 检测系统是否被植入后门"
MSG_MAIN_MENU_EXIT="[0] 退出"
MSG_MAIN_MENU_PROMPT="请输入选项"
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

# K3s 子菜单
MSG_K3S_MENU_TITLE="K3s 轻量级 Kubernetes"
MSG_K3S_MENU_INSTALL="[1] 安装 K3s"
MSG_K3S_MENU_UNINSTALL="[2] 卸载 K3s"
MSG_K3S_MENU_STATUS="[3] 查看 K3s 状态"
MSG_K3S_MENU_BACK="[0] 返回主菜单"

# 系统状态检测
MSG_STATUS_TITLE="系统安全状态检测"
MSG_STATUS_FIREWALL="防火墙"
MSG_STATUS_FAIL2BAN="Fail2Ban"
MSG_STATUS_AUDIT="审计日志"
MSG_STATUS_ENABLED="已启用"
MSG_STATUS_DISABLED="未启用"
MSG_STATUS_INSTALLED="已安装"
MSG_STATUS_NOT_INSTALLED="未安装"
MSG_DETECTION_SUMMARY="系统检测摘要:"

# 报告查看

# 操作确认
MSG_CONFIRM_FIREWALL_HTTP="确认开放 HTTP/HTTPS 端口？"

# 快速加固

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
MSG_WIZARD_STEP_INIT="[0/14] 系统初始化"
MSG_WIZARD_STEP_SSH="[1/14] SSH 安全加固"
MSG_WIZARD_STEP_FIREWALL="[2/14] 防火墙配置"
MSG_WIZARD_STEP_FAIL2BAN="[3/14] Fail2Ban 入侵防护"
MSG_WIZARD_STEP_AUDIT="[4/14] 审计日志配置"
MSG_WIZARD_STEP_USERS="[5/14] 用户管理"
MSG_WIZARD_STEP_KERNEL="[6/14] 内核安全加固"
MSG_WIZARD_STEP_FILESYSTEM="[7/14] 文件系统安全"
MSG_WIZARD_STEP_SERVICES="[8/14] 服务管理"
MSG_WIZARD_STEP_AIDE="[10/14] AIDE 入侵检测"
MSG_WIZARD_STEP_CLAMAV="[11/14] ClamAV 病毒扫描"
MSG_WIZARD_STEP_ROOTKIT="[12/14] Rootkit 检测"
MSG_WIZARD_STEP_SUMMARY="[13/14] 变更摘要与确认"
MSG_WIZARD_SKIP_STEP="跳过此步骤？(y/N)"
MSG_WIZARD_COMPLETE="向导完成"
MSG_WIZARD_SKIPPED="已跳过"
MSG_WIZARD_SKIPPED_INIT="跳过系统初始化"
MSG_WIZARD_ERR_INIT="系统初始化出现错误"
MSG_WIZARD_ERR_INIT_DETAIL="系统初始化失败，后续步骤（SSH、防火墙等）可能无法正常工作"
MSG_WIZARD_ERR_INIT_PROMPT="仍然继续？（不推荐）"
MSG_WIZARD_ERR_INIT_ABORT="因初始化失败终止向导"
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
MSG_WIZARD_SKIPPED_SERVICES="跳过服务管理"
MSG_WIZARD_ERR_SERVICES="服务管理出现错误"
MSG_WIZARD_SKIPPED_AUTOUPDATE="跳过自动安全更新配置"
MSG_WIZARD_ERR_AUTOUPDATE="自动安全更新配置出现错误"
MSG_WIZARD_SKIPPED_AIDE="跳过 AIDE 配置"
MSG_WIZARD_ERR_AIDE="AIDE 配置出现错误"
MSG_WIZARD_SKIPPED_CLAMAV="跳过 ClamAV 配置"
MSG_WIZARD_ERR_CLAMAV="ClamAV 配置出现错误"
MSG_WIZARD_SKIPPED_ROOTKIT="跳过 Rootkit 检测配置"
MSG_WIZARD_ERR_ROOTKIT="Rootkit 检测配置出现错误"
MSG_WIZARD_STEP_AUTOUPDATE="[9/14] 自动安全更新"
MSG_WIZARD_ERR_HINT="（部分步骤出现错误，请查看日志）"

# SSH 密钥
MSG_SSH_KEY_TITLE="生成 SSH 密钥对"
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

# SSH 端口（续）
MSG_SSH_PORT_UNCHANGED="端口未变化，跳过"
MSG_SSH_PORT_CANCELLED="已取消"
MSG_SSH_PORT_FAIL="SSH 端口修改失败"

# SSH 密钥（续）
MSG_SSH_KEY_EXISTS="密钥已存在：{path}"
MSG_SSH_KEY_OVERWRITE="是否覆盖现有密钥？"
MSG_SSH_KEY_SKIP="跳过密钥生成"
MSG_SSH_KEY_GENERATING="正在生成 Ed25519 密钥对..."
MSG_SSH_KEY_ALREADY_AUTHORIZED="公钥已在 authorized_keys 中，跳过"
MSG_SSH_KEY_AUTHORIZED_FAIL="更新 authorized_keys 失败"

# 无 SSH 密钥警告
MSG_SSH_USERS_NO_KEYS="以下用户没有 SSH 密钥（禁用密码认证后可能无法登录）："

# Root 登录（续）
MSG_SSH_ROOT_SKIP="跳过禁止 root 登录"
MSG_SSH_ROOT_FAIL="禁止 root 登录失败"

# 密码登录（续）
MSG_SSH_PASSWD_CONFIGURE_KEYS="请先配置 SSH 密钥"
MSG_SSH_PASSWD_SKIP="跳过禁止密码登录"
MSG_SSH_PASSWD_USERS_NO_KEYS="以下用户没有 SSH 密钥，禁用密码认证后将被锁定："
MSG_SSH_PASSWD_SETUP_KEYS_HINT="请先为这些用户配置 SSH 密钥，否则他们将无法登录。"
MSG_SSH_PASSWD_CONTINUE_ANYWAY="仍然继续？（不推荐）"
MSG_SSH_PASSWD_SET_FAIL="设置 {param} 失败"

# SSH 参数配置（续）
MSG_SSH_PARAMS_INVALID="{param} 值无效（{range}），使用默认值 {default}"
MSG_SSH_PARAMS_FAIL="设置 {count} 个 SSH 参数失败"

# 回滚保护（续）
MSG_SSH_ROLLBACK_NO_BACKUP="未找到回滚所需的备份"

# 向导
MSG_SSH_WIZARD_EXTERNAL_MOD="检测到外部修改: %s"
MSG_SSH_WIZARD_ROLLBACK_OVERWRITE="用备份覆盖？(y/n)"
MSG_SSH_RESTART_FAIL_ROLLBACK="SSH 重启失败，正在回滚更改"

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
MSG_FIREWALL_SSH_PORT22_CLOSE="   请关闭旧 SSH 端口 22/tcp: sudo ufw deny 22/tcp (Ubuntu/Debian) 或 firewall-cmd --remove-service=ssh (CentOS/RHEL)"

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

MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND="认证日志文件未找到: "
MSG_FAIL2BAN_AUTH_LOG_NOT_FOUND_TAIL="，fail2ban 可能需要 journald backend"
MSG_FAIL2BAN_INFO_SSH_PORT="SSH 端口: "
MSG_FAIL2BAN_INFO_AUTH_LOG="认证日志: "
MSG_FAIL2BAN_INFO_CONFIG_FILE="配置文件: "
MSG_FAIL2BAN_EPEL_FAILED="epel-release 安装失败，继续执行..."

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
MSG_AUDIT_RULES_FILE="规则文件"
MSG_AUDIT_CONF_FILE="配置文件"

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
MSG_USERS_SSH_KEY_AUTH_ADD_FAILED="公钥添加到 authorized_keys 失败"
MSG_USERS_SSH_KEY_PERM_FAILED="设置 {path} 权限失败"
MSG_USERS_SSH_KEY_OWNER_FAILED="设置 {path} 所有权失败"

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
MSG_KERNEL_MODULE_BLACKLISTED="已加入黑名单模块"
MSG_KERNEL_MODULE_BLACKLIST_FAILED="模块加入黑名单失败"
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
MSG_REPORT_WARN_KERNEL="内核参数已修改，可能影响网络/服务运行"
MSG_REPORT_WARN_USERS="已创建新用户，关闭当前会话前请测试登录"
MSG_REPORT_WARN_FS="文件系统权限已更改，请验证关键服务是否正常工作"
MSG_REPORT_WARN_SERVICES="已禁用部分服务，请验证所需服务是否正常运行"

# ═══════════════════════════════════════════
# 日志
# ═══════════════════════════════════════════

MSG_LOG_BACKUP="备份文件"
MSG_LOG_RESTORE="恢复文件"
MSG_BACKUP_SUCCESS="备份成功：%s"
MSG_BACKUP_FAIL="备份失败：%s"
MSG_RESTORE_SUCCESS="已恢复：%s"

# ═══════════════════════════════════════════
# 服务管理
# ═══════════════════════════════════════════

MSG_SERVICES_WIZARD_TITLE="服务管理向导"
MSG_SERVICES_WIZARD_DESC="审计运行中的服务、禁用不必要的服务、扫描开放端口"

# 服务描述
MSG_SERVICES_DESC_TELNET="telnet — 明文远程访问，不安全"
MSG_SERVICES_DESC_RSH="rsh — 明文远程访问，不安全"
MSG_SERVICES_DESC_RLOGIN="rlogin — 明文远程访问，不安全"
MSG_SERVICES_DESC_VSFTPD="FTP — 明文文件传输，除非必要否则禁用"
MSG_SERVICES_DESC_AVAHI="mDNS/DNS-SD — 服务器通常不需要"
MSG_SERVICES_DESC_CUPS="打印服务 — 服务器通常不需要"
MSG_SERVICES_DESC_RPCBIND="RPC 端口映射 — 不需要则禁用"

# 向导步骤
MSG_SERVICES_STEP_AUDIT="Step 1: 审计运行中的服务"
MSG_SERVICES_STEP_AUDIT_CONFIRM="是否显示当前运行中的所有服务？"
MSG_SERVICES_STEP_DISABLE="Step 2: 禁用不必要服务"
MSG_SERVICES_STEP_DISABLE_CONFIRM="是否检测并禁用不必要服务？"
MSG_SERVICES_STEP_PORTS="Step 3: 扫描开放端口"
MSG_SERVICES_STEP_PORTS_CONFIRM="是否扫描当前所有监听端口？"
MSG_SERVICES_STEP_SKIPPED="已跳过此步骤"

# 审计
MSG_SERVICES_AUDIT_TITLE="服务审计"
MSG_SERVICES_RUNNING_TITLE="运行中的服务:"
MSG_SERVICES_RUNNING_TOTAL="运行中服务总数"

# 禁用服务
MSG_SERVICES_UNNECESSARY_TITLE="不必要服务检测"
MSG_SERVICES_UNNECESSARY_DESC="以下不必要服务正在运行:"
MSG_SERVICES_CONFIRM_DISABLE="确认禁用"
MSG_SERVICES_DISABLING="正在禁用服务"
MSG_SERVICES_STOP_FAILED="停止服务失败"
MSG_SERVICES_DISABLE_FAILED="禁用服务自启失败"
MSG_SERVICES_DISABLED="已禁用服务"
MSG_SERVICES_DISABLE_ERROR="禁用服务失败"
MSG_SERVICES_SKIPPED="已跳过服务"
MSG_SERVICES_ALL_CLEAR="未检测到不必要的运行中服务"
MSG_SERVICES_DISABLED_COUNT="已禁用服务数"

# 端口扫描
MSG_SERVICES_PORTS_TITLE="开放端口扫描"
MSG_SERVICES_PORTS_DESC="当前监听端口:"
MSG_SERVICES_PORTS_TOTAL="监听端口总数"
MSG_SERVICES_PORTS_WARNING="发现非标准端口"
MSG_SERVICES_PORTS_UNKNOWN="个端口需要确认是否必要"
MSG_SERVICES_PORT_STANDARD="标准端口"
MSG_SERVICES_PORT_NONSTANDARD="非标准端口，请确认是否必要"

# 检查列表
MSG_SERVICES_CHECK_LIST_TITLE="检查以下服务"

# 摘要
MSG_SERVICES_SUMMARY="服务管理摘要"
MSG_SERVICES_SUMMARY_RUNNING="运行中服务数"
MSG_SERVICES_SUMMARY_UNNECESSARY="仍存在的不必要服务"
MSG_SERVICES_WIZARD_DONE="服务管理配置完成"

# ═══════════════════════════════════════════
# NTP 时间同步
# ═══════════════════════════════════════════

MSG_NTP_TITLE="NTP 时间同步"
MSG_NTP_SETTING="正在配置 NTP 时间同步..."
MSG_NTP_DETECTING="正在检测 NTP 服务..."
MSG_NTP_INSTALL_CHRONY="正在安装 chrony..."
MSG_NTP_INSTALL_NTPD="正在安装 ntpd..."
MSG_NTP_INSTALL_DONE="NTP 服务安装完成"
MSG_NTP_ALREADY_SYNCED="NTP 时间已同步，跳过安装"
MSG_NTP_CONFIG="正在配置 NTP 服务器..."
MSG_NTP_CONFIG_DONE="NTP 配置完成"
MSG_NTP_SERVICE_START="正在启动 NTP 服务..."
MSG_NTP_SERVICE_DONE="NTP 服务已启动"
MSG_NTP_STATUS="NTP 时间同步"
MSG_NTP_STATUS_SYNCED="已同步"
MSG_NTP_STATUS_UNSYNCED="未同步"
MSG_NTP_BACKUP_CONF="备份 NTP 配置文件"
MSG_NTP_TZ_PROMPT="请输入时区（留空使用 Asia/Shanghai）"
MSG_NTP_TZ_INVALID="时区无效，请重新输入"
MSG_NTP_SYNC_NOW="正在同步时间..."
MSG_NTP_SYNC_DONE="时间同步完成"
MSG_NTP_SYNC_FAIL="时间同步失败"

# ═══════════════════════════════════════════
# Swap 配置
# ═══════════════════════════════════════════

MSG_SWAP_TITLE="Swap 配置"
MSG_SWAP_CHECKING="正在检测 Swap 状态..."
MSG_SWAP_EXISTS="Swap 已存在"
MSG_SWAP_SIZE="Swap 大小"
MSG_SWAP_NO_SWAP="未配置 Swap"
MSG_SWAP_RECOMMENDED="推荐 Swap 大小"
MSG_SWAP_CREATING="正在创建 Swap 文件..."
MSG_SWAP_CREATE_DONE="Swap 文件创建完成"
MSG_SWAP_CREATE_FAIL="Swap 文件创建失败"
MSG_SWAP_ENABLING="正在启用 Swap..."
MSG_SWAP_ENABLE_DONE="Swap 已启用"
MSG_SWAP_ENABLE_FAIL="Swap 启用失败"
MSG_SWAP_SWAPPINESS="设置 swappiness"
MSG_SWAP_SWAPPINESS_DONE="swappiness 已设置为 10"
MSG_SWAP_FSTAB_ADD="添加 Swap 到 /etc/fstab"
MSG_SWAP_FSTAB_DONE="Swap 已添加到 fstab"
MSG_SWAP_CONFIRM_CREATE="确认创建 Swap 文件？"
MSG_SWAP_SKIP="跳过 Swap 配置"
MSG_SWAP_DONE="Swap 配置完成"

# ═══════════════════════════════════════════
# 错误和警告
# ═══════════════════════════════════════════

MSG_ERROR_SCRIPT_NOT_ROOT="此脚本必须以 root 权限运行"
MSG_ERROR_FILE_NOT_FOUND="文件不存在"
MSG_ERROR_RESTORE_FAILED="恢复失败"

MSG_WARN_CONNECTION="请确保在关闭当前会话前测试新配置"
MSG_WARN_SAVE_KEY="请确保已保存 SSH 私钥文件"
MSG_WARN_TEST_FIRST="请测试新配置后再关闭当前会话"

# ═══════════════════════════════════════════
# SSH 连接测试（Full 模式）
# ═══════════════════════════════════════════

MSG_SSH_TEST_CONNECTION="正在测试 SSH 连接..."
MSG_SSH_TEST_PASS="SSH 连接测试通过（端口 {port}）"
MSG_SSH_TEST_FAIL="SSH 连接测试失败（端口 {port}）— 将设置回滚定时器"
MSG_SSH_TEST_WAITING="等待 SSH 服务就绪..."
MSG_SSH_TEST_CONFIRM="请确认您能够通过新端口连接到服务器"
MSG_SSH_TEST_INSTRUCTIONS="在其他终端中运行: ssh -p {port} user@host"

# ═══════════════════════════════════════════
# 完成信息
# ═══════════════════════════════════════════

MSG_GOODBYE="再见！"

# ── Lite 运行痕迹清理 ──
MSG_CLEANUP_PROMPT="是否清理脚本运行痕迹（日志/备份/报告）？清理后将无法回滚。"
MSG_CLEANUP_DONE="运行痕迹已清理"
MSG_CLEANUP_PARTIAL="部分运行痕迹清理失败（已保留）"
MSG_CLEANUP_SKIPPED="已保留运行痕迹"

# ═══════════════════════════════════════════
# 自动安全更新
# ═══════════════════════════════════════════

MSG_AUTOUPDATE_TITLE="自动安全更新"
MSG_AUTOUPDATE_START="开始配置自动安全更新..."
MSG_AUTOUPDATE_INSTALL="正在安装自动更新工具..."
MSG_AUTOUPDATE_ALREADY="自动更新工具已安装"
MSG_AUTOUPDATE_INSTALL_DONE="自动更新工具安装完成"
MSG_AUTOUPDATE_INSTALL_FAILED="自动更新工具安装失败"
MSG_AUTOUPDATE_CONFIGURE="正在配置自动安全更新..."
MSG_AUTOUPDATE_CONFIGURE_DONE="自动安全更新配置完成"
MSG_AUTOUPDATE_ENABLE="正在启用自动更新服务..."
MSG_AUTOUPDATE_ENABLE_DONE="自动更新服务已启用"
MSG_AUTOUPDATE_STATUS="当前自动更新状态"
MSG_AUTOUPDATE_CONFIGURED="已配置"
MSG_AUTOUPDATE_NOT_CONFIGURED="未配置"
MSG_AUTOUPDATE_SCOPE_PROMPT="更新范围"
MSG_AUTOUPDATE_SCOPE_SECURITY="[1] 仅安全更新（推荐）"
MSG_AUTOUPDATE_SCOPE_ALL="[2] 所有更新"
MSG_AUTOUPDATE_REBOOT_PROMPT="自动重启策略"
MSG_AUTOUPDATE_REBOOT_NEVER="[1] 不自动重启"
MSG_AUTOUPDATE_REBOOT_IF_NEEDED="[2] 必要时自动重启"
MSG_AUTOUPDATE_DONE="自动安全更新配置完成"
MSG_AUTOUPDATE_TYPE="更新类型"
MSG_AUTOUPDATE_SUMMARY_ENABLED="自动安全更新：已启用"
MSG_AUTOUPDATE_SUMMARY_DISABLED="自动安全更新：未启用"

# ═══════════════════════════════════════════
# 任务描述（续）
# ═══════════════════════════════════════════

MSG_TASK_AUTOUPDATE="自动安全更新"

# ═══════════════════════════════════════════
# 主菜单分组分隔 + 顶部状态摘要（spec §3.1 GAP-1/2）
# ═══════════════════════════════════════════

MSG_SECTION_STATUS="────── 状态 ──────"
MSG_SECTION_HARDENING="────── 加固（按推荐顺序）──────"
MSG_SECTION_QUICK="────── 一键 ──────"
MSG_SECTION_SERVER="────── 服务器软件 ──────"
MSG_STATUS_SSH_PORT_HARDENED="已加固"
MSG_STATUS_SSH_PORT_DEFAULT="未加固"

# ── Batch 5a: 备份/回滚中心 + 仪表盘 ──
MSG_SECTION_OPS="────── 运维工具 ──────"
MSG_MAIN_MENU_BACKUP_CENTER="[17] 备份与回滚中心"
MSG_MAIN_MENU_BACKUP_CENTER_DESC="备份历史浏览、一键恢复、回滚定时器管理"
MSG_MAIN_MENU_DASHBOARD="[18] 安全仪表盘"
MSG_MAIN_MENU_DASHBOARD_DESC="多模块 CIS 合规评分与风险等级"
MSG_ERROR_RESTORE_TARGET_REQUIRED="恢复失败：缺少目标路径（无 .meta 元数据）"
MSG_ERROR_RESTORE_TARGET_NOT_ABSOLUTE="恢复失败：目标路径必须是绝对路径"
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
MSG_BACKUP_CENTER_RESTORE_SYSCTL_SUCCESS="sysctl 已重新加载"
MSG_BACKUP_CENTER_RESTORE_SYSCTL_FAILED="sysctl --system 执行失败"
MSG_BACKUP_CENTER_RESTORE_MODULE="恢复模块 %s"
MSG_BACKUP_CENTER_MODULE_PROMPT="输入要恢复的模块名"
MSG_BACKUP_CENTER_RESTORE_FAILED="模块 %s 恢复失败：一个或多个文件未能恢复"
MSG_BACKUP_CENTER_ROLLBACK_NONE="当前没有待执行的 SSH 回滚定时器"
MSG_BACKUP_CENTER_ROLLBACK_PENDING="存在待执行的 SSH 回滚定时器 (PID %s)"
MSG_BACKUP_CENTER_ROLLBACK_CANCEL="已取消回滚定时器"
MSG_BACKUP_CENTER_ROLLBACK_CANCEL_CONFIRM="取消回滚定时器？(y/N)"
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

# ═══════════════════════════════════════════
# 状态检测：评分 + 颜色 + 建议下一步（spec §3.3 GAP-4/5/6）
# ═══════════════════════════════════════════

MSG_STATUS_HARDENED="已加固"
MSG_STATUS_PARTIAL="部分加固"
MSG_STATUS_NOT_HARDENED="未加固"
MSG_STATUS_NOT_CONFIGURED="未配置"
MSG_STATUS_RECOMMENDATION="建议下一步"

# ═══════════════════════════════════════════
# 子菜单状态回退提示（M16 fix: i18n）
# ═══════════════════════════════════════════

MSG_HINT_STATUS_FAIL2BAN="Fail2Ban 状态：见主菜单 [1] 系统状态检测"
MSG_HINT_STATUS_AUDIT="Audit 状态：见主菜单 [1] 系统状态检测"
MSG_HINT_STATUS_USERS="用户状态：见主菜单 [1] 系统状态检测"
MSG_HINT_STATUS_KERNEL="内核状态：见主菜单 [1] 系统状态检测"
MSG_HINT_STATUS_FILESYSTEM="文件系统状态：见主菜单 [1] 系统状态检测"
MSG_HINT_STATUS_SERVICES="服务状态：见主菜单 [1] 系统状态检测"
MSG_HINT_STATUS_AUTOUPDATE="自动更新状态：见主菜单 [1] 系统状态检测"

# ═══════════════════════════════════════════
# 状态键补全（移除 install.sh 中的 :- 兜底，spec GAP-8）
# ═══════════════════════════════════════════

MSG_STATUS_USERS="用户管理"
MSG_STATUS_USERS_COUNT="自定义用户数"
MSG_STATUS_KERNEL="内核加固"
MSG_STATUS_KERNEL_CONF="sysctl 配置"
MSG_STATUS_FILESYSTEM="文件系统"
MSG_STATUS_FS_SUID="SUID 文件数"
MSG_STATUS_SERVICES="服务管理"
MSG_STATUS_SERVICES_RUNNING="运行中服务"
MSG_STATUS_SERVICES_UNNECESSARY="非必要服务"

# ═══════════════════════════════════════════
# 模块 4-9 子菜单壳（每个模块 4 个键，spec §3.2 GAP-3）
# ═══════════════════════════════════════════

MSG_FAIL2BAN_MENU_TITLE="Fail2Ban 入侵防护"
MSG_AUTOUPDATE_MENU_WIZARD="[1] 全流程加固"
MSG_AUTOUPDATE_MENU_STATUS="[2] 仅查看状态"
MSG_AUTOUPDATE_MENU_BACK="[0] 返回主菜单"
MSG_FAIL2BAN_MENU_WIZARD="[1] 全流程加固"
MSG_FAIL2BAN_MENU_STATUS="[2] 仅查看状态"
MSG_FAIL2BAN_MENU_BACK="[0] 返回主菜单"

MSG_AUDIT_MENU_TITLE="审计日志"
MSG_AUDIT_MENU_WIZARD="[1] 全流程加固"
MSG_AUDIT_MENU_STATUS="[2] 仅查看状态"
MSG_AUDIT_MENU_BACK="[0] 返回主菜单"

MSG_USERS_MENU_TITLE="用户管理"
MSG_USERS_MENU_WIZARD="[1] 全流程加固"
MSG_USERS_MENU_STATUS="[2] 仅查看状态"
MSG_USERS_MENU_BACK="[0] 返回主菜单"

MSG_KERNEL_MENU_TITLE="内核加固"
MSG_KERNEL_MENU_WIZARD="[1] 全流程加固"
MSG_KERNEL_MENU_STATUS="[2] 仅查看状态"
MSG_KERNEL_MENU_BACK="[0] 返回主菜单"

MSG_FILESYSTEM_MENU_TITLE="文件系统安全"
MSG_FILESYSTEM_MENU_WIZARD="[1] 全流程加固"
MSG_FILESYSTEM_MENU_STATUS="[2] 仅查看状态"
MSG_FILESYSTEM_MENU_BACK="[0] 返回主菜单"

MSG_SERVICES_MENU_TITLE="服务管理"
MSG_SERVICES_MENU_WIZARD="[1] 全流程加固"
MSG_SERVICES_MENU_STATUS="[2] 仅查看状态"
MSG_SERVICES_MENU_BACK="[0] 返回主菜单"

# ═══════════════════════════════════════════
# view_report 历史报告（spec §3.4 GAP-7）
# ═══════════════════════════════════════════

MSG_REPORT_HISTORY_TITLE="加固报告历史"
MSG_REPORT_NO_FILES="未找到任何加固报告"
MSG_TIME_JUST_NOW="刚刚"
MSG_TIME_MINUTES_AGO="%d 分钟前"
MSG_TIME_HOURS_AGO="%d 小时前"
MSG_TIME_DAYS_AGO="%d 天前"

# ═══════════════════════════════════════════
# parse_args 错误提示（精简后，spec §3.5 GAP-9）
# ═══════════════════════════════════════════

MSG_ERROR_REMOVED_ARG="错误：参数 --%s 已移除，本脚本仅支持交互模式"
MSG_ERROR_REMOVED_HINT="提示：使用 --status 只读检测，或不带参数进入交互菜单"

# ═══════════════════════════════════════════
# 模式 (Lite/Full)
# ═══════════════════════════════════════════

MSG_MODE_LITE="精简模式"
MSG_MODE_FULL="完整模式"
MSG_MODE_CURRENT="当前模式"
MSG_MODE_LITE_TAG="[精简版]"
MSG_MODE_FULL_TAG="[完整版]"
MSG_MODE_LITE_DESC="仅含核心安全功能，适合低内存服务器"
MSG_MODE_FULL_DESC="所有安全加固功能"
MSG_MODE_FULL_ONLY="[仅在完整版中可用]"
MSG_ERROR_LITE_MODE="此功能仅在完整版中可用。如需使用，请不加 --lite 参数重新运行"

# ═══════════════════════════════════════════
# 加固模式选择（Batch 4）
# ═══════════════════════════════════════════

MSG_MODE_SELECT_TITLE="选择加固模式"
MSG_MODE_SELECT_DESC="请选择适合您需求的加固级别"
MSG_MODE_BASIC="基础加固"
MSG_MODE_BASIC_DESC="SSH + 防火墙 + 内核 + 系统初始化"
MSG_MODE_BASIC_TIP="推荐：新手快速部署"
MSG_MODE_STANDARD="标准加固"
MSG_MODE_STANDARD_DESC="基础 + Fail2Ban + 用户管理"
MSG_MODE_STANDARD_TIP="推荐：大多数服务器场景"
MSG_MODE_ADVANCED="高级加固"
MSG_MODE_ADVANCED_DESC="标准 + 审计 + 服务 + 文件系统"
MSG_MODE_ADVANCED_TIP="推荐：高安全要求场景"
MSG_MODE_CUSTOM="自定义"
MSG_MODE_CUSTOM_DESC="逐项选择，完全控制"
MSG_MODE_CUSTOM_TIP="推荐：有特殊需求的用户"
MSG_MODE_SELECT_PROMPT="请输入选项 [1-4] (默认: 4)"
MSG_MODE_WIZARD_BASIC="基础加固向导"
MSG_MODE_WIZARD_STANDARD="标准加固向导"
MSG_MODE_WIZARD_ADVANCED="高级加固向导"

# ═══════════════════════════════════════════
# SSH 安全增强（Batch 4）
# ═══════════════════════════════════════════

MSG_SSH_SESSION_ACTIVE="检测到活跃 SSH 会话"
MSG_SSH_SESSION_NONE="警告：未检测到活跃 SSH 会话！请在 SSH 连接中运行以避免锁定"
MSG_SSH_CONSOLE_AVAILABLE="检测到备用控制台访问"
MSG_SSH_CONSOLE_NONE="警告：未检测到备用控制台访问"
MSG_SSH_ROLLBACK_CONFIRM_PROMPT="是否继续？"
MSG_STATUS_NA_LITE="N/A（精简模式未包含此模块）"
MSG_HELP_LITE="  --lite          精简模式：仅执行核心安全加固（SSH/防火墙/内核）"

# ═══════════════════════════════════════════
# 命令行帮助文本（M17 fix: i18n）
# ═══════════════════════════════════════════

MSG_HELP_USAGE="用法：bash install.sh [选项]"
MSG_HELP_OPTIONS="选项："
MSG_HELP_STATUS="  --status       查看系统安全状态（只读）"
MSG_HELP_HELP="  --help, -h     显示此帮助"
MSG_HELP_NO_ARGS="无参数：交互式菜单。"
MSG_HELP_EXAMPLES="示例："
MSG_HELP_EXAMPLE_INTERACTIVE="  bash install.sh                        # 交互式菜单"
MSG_HELP_EXAMPLE_STATUS="  bash install.sh --status               # 仅状态检测"
MSG_HELP_EXAMPLE_CURL="  curl -fsSL .../install.sh | sudo bash"
MSG_ERROR_UNKNOWN_ARG="错误：未知参数：%s"
MSG_ERROR_USE_HELP="使用 --help 查看可用选项"

# ═══════════════════════════════════════════
# AIDE 入侵检测
# ═══════════════════════════════════════════

MSG_AIDE_WIZARD_TITLE="AIDE 入侵检测向导"
MSG_AIDE_WIZARD_DESC="文件完整性检查系统，使用 AIDE 监控关键文件变更"
MSG_AIDE_WIZARD_START="是否开始 AIDE 配置？"
MSG_AIDE_WIZARD_SKIPPED="跳过 AIDE 配置"
MSG_AIDE_WIZARD_DONE="AIDE 配置完成"
MSG_AIDE_INSTALL="正在安装 AIDE..."
MSG_AIDE_INSTALL_DONE="AIDE 安装完成"
MSG_AIDE_ALREADY_INSTALLED="AIDE 已安装"
MSG_AIDE_UNSUPPORTED_OS="不支持的操作系统，跳过 AIDE 配置"
MSG_AIDE_BACKUP="备份 AIDE 配置文件"
MSG_AIDE_CONFIGURE="正在配置 AIDE..."
MSG_AIDE_CONFIGURE_DONE="AIDE 配置完成"
MSG_AIDE_INIT_DB="正在初始化 AIDE 数据库..."
MSG_AIDE_INIT_DB_DONE="AIDE 数据库初始化完成"
MSG_AIDE_INIT_DB_WARN="AIDE 数据库初始化在大容量服务器上可能需要 5-30 分钟"
MSG_AIDE_INIT_DB_SKIP="跳过 AIDE 数据库初始化"
MSG_AIDE_INIT_DB_EXISTS="AIDE 数据库已存在"
MSG_AIDE_INIT_DB_REINIT="是否重新初始化 AIDE 数据库？（将覆盖现有）"
MSG_AIDE_DB_STATUS="数据库状态"
MSG_AIDE_DB_AGE="数据库龄期"
MSG_AIDE_CRON_SETUP="设置每日 AIDE 检查定时任务"
MSG_AIDE_CRON_DONE="每日 AIDE 定时任务已设置"
MSG_AIDE_CRON_EXISTS="每日 AIDE 定时任务已存在"
MSG_AIDE_CRON_SKIP="跳过 AIDE 定时任务设置"
MSG_AIDE_STATUS="AIDE 状态"
MSG_AIDE_NOT_INSTALLED="AIDE 未安装"
MSG_AIDE_SUMMARY="AIDE 配置摘要"
MSG_AIDE_TIPS_TITLE="AIDE 管理命令："
MSG_AIDE_TIPS_1="检查完整性：aide --check"
MSG_AIDE_TIPS_2="更新数据库：aide --update"
MSG_AIDE_TIPS_3="查看报告：cat /var/log/aide/check-*.log"
MSG_AIDE_TIPS_4="重新初始化：aideinit --init 或 aide --init"
MSG_AIDE_MENU_TITLE="AIDE 入侵检测"
MSG_AIDE_MENU_WIZARD="[1] 全流程加固"
MSG_AIDE_MENU_STATUS="[2] 仅查看状态"
MSG_AIDE_MENU_BACK="[0] 返回主菜单"
MSG_HINT_STATUS_AIDE="AIDE 状态：见主菜单 [1] 系统状态检测"
MSG_STATUS_AIDE="AIDE"
MSG_REPORT_WARN_AIDE="AIDE 数据库已初始化，请定期运行 aide --check 验证文件完整性"
MSG_TASK_AIDE="AIDE 入侵检测"

# ═══════════════════════════════════════════
# ClamAV 病毒扫描
# ═══════════════════════════════════════════

MSG_CLAMAV_WIZARD_TITLE="ClamAV 病毒扫描向导"
MSG_CLAMAV_WIZARD_DESC="开源杀毒软件，配置 freshclam 和按需扫描"
MSG_CLAMAV_WIZARD_START="是否开始 ClamAV 配置？"
MSG_CLAMAV_WIZARD_SKIPPED="跳过 ClamAV 配置"
MSG_CLAMAV_WIZARD_DONE="ClamAV 配置完成"
MSG_CLAMAV_INSTALL="正在安装 ClamAV..."
MSG_CLAMAV_INSTALL_DONE="ClamAV 安装完成"
MSG_CLAMAV_ALREADY_INSTALLED="ClamAV 已安装"
MSG_CLAMAV_UNSUPPORTED_OS="不支持的操作系统，跳过 ClamAV 配置"
MSG_CLAMAV_MEMORY_WARN="警告：ClamAV freshclam 在病毒库更新时可能使用 ~200-300MB 内存"
MSG_CLAMAV_MEMORY_CONFIRM="尽管有内存警告，是否继续？"
MSG_CLAMAV_CONFIGURE="正在配置 freshclam..."
MSG_CLAMAV_CONFIGURE_DONE="freshclam 配置完成"
MSG_CLAMAV_FRESHCLAM_CRON="设置 hourly freshclam 定时任务"
MSG_CLAMAV_FRESHCLAM_CRON_DONE="Freshclam 定时任务已设置"
MSG_CLAMAV_FRESHCLAM_NOW="正在运行首次病毒库更新..."
MSG_CLAMAV_FRESHCLAM_NOW_DONE="病毒库更新完成"
MSG_CLAMAV_FRESHCLAM_NOW_WARN="Freshclam 更新可能需要一些时间（约 100MB 下载）"
MSG_CLAMAV_SCAN_CRON_PROMPT="是否设置每日扫描定时任务？（默认跳过）"
MSG_CLAMAV_SCAN_CRON_SETUP="正在设置每日扫描定时任务..."
MSG_CLAMAV_SCAN_CRON_DONE="每日扫描定时任务已设置"
MSG_CLAMAV_SCAN_CRON_SKIP="跳过每日扫描定时任务"
MSG_CLAMAV_RUN_SCAN="正在运行按需病毒扫描..."
MSG_CLAMAV_SCAN_DONE="病毒扫描完成"
MSG_CLAMAV_SCAN_FOUND="发现威胁！请检查隔离区和扫描日志"
MSG_CLAMAV_SCAN_CLEAN="未发现威胁"
MSG_CLAMAV_STATUS="ClamAV 状态"
MSG_CLAMAV_DB_STATUS="病毒数据库"
MSG_CLAMAV_DB_UPTODATE="已是最新"
MSG_CLAMAV_DB_OUTDATED="已过期（超过 7 天）"
MSG_CLAMAV_LAST_SCAN="上次扫描"
MSG_CLAMAV_NOT_INSTALLED="未安装"
MSG_CLAMAV_SUMMARY="ClamAV 配置摘要"
MSG_CLAMAV_TIPS_TITLE="ClamAV 管理命令："
MSG_CLAMAV_TIPS_1="更新病毒定义：freshclam"
MSG_CLAMAV_TIPS_2="扫描文件：clamscan <file>"
MSG_CLAMAV_TIPS_3="扫描目录：clamscan -r <dir>"
MSG_CLAMAV_TIPS_4="隔离文件：mv <file> /var/quarantine/"
MSG_CLAMAV_MENU_TITLE="ClamAV 病毒扫描"
MSG_CLAMAV_MENU_WIZARD="[1] 全流程加固"
MSG_CLAMAV_MENU_STATUS="[2] 仅查看状态"
MSG_CLAMAV_MENU_BACK="[0] 返回主菜单"
MSG_HINT_STATUS_CLAMAV="ClamAV 状态：见主菜单 [1] 系统状态检测"
MSG_STATUS_CLAMAV="ClamAV"
MSG_REPORT_WARN_CLAMAV="ClamAV 已安装，请保持病毒库更新：freshclam"
MSG_TASK_CLAMAV="ClamAV 病毒扫描"

# ClamAV clamd 守护进程
MSG_CLAMAV_CLAMD_PROMPT="是否启用 ClamAV 守护进程（clamd）进行实时保护？（需要额外 ~300MB 内存）"
MSG_CLAMAV_CLAMD_SKIPPED="已跳过 clamd 安装"
MSG_CLAMAV_CLAMD_INSTALL="正在安装 clamd 守护进程..."
MSG_CLAMAV_CLAMD_INSTALL_DONE="clamd 安装完成"
MSG_CLAMAV_CLAMD_ALREADY="clamd 已安装"
MSG_CLAMAV_CLAMD_CONFIGURE="正在配置 clamd..."
MSG_CLAMAV_CLAMD_CONFIGURE_DONE="clamd 配置完成"
MSG_CLAMAV_CLAMD_ENABLE="正在启动 clamd 服务..."
MSG_CLAMAV_CLAMD_ENABLE_DONE="clamd 服务已启动"
MSG_CLAMAV_CLAMD_DISABLE="正在停止 clamd 服务..."
MSG_CLAMAV_CLAMD_DISABLE_DONE="clamd 服务已停止"
MSG_CLAMAV_CLAMD_DISABLED="clamd 未启用"
MSG_STATUS_CLAMD="clamd 状态"

# ═══════════════════════════════════════════
# Rootkit 检测
# ═══════════════════════════════════════════

MSG_ROOTKIT_WIZARD_TITLE="Rootkit 检测向导"
MSG_ROOTKIT_WIZARD_DESC="使用 rkhunter 和 chkrootkit 检测系统是否被植入后门"
MSG_ROOTKIT_WIZARD_START="是否开始 Rootkit 检测配置？"
MSG_ROOTKIT_WIZARD_SKIPPED="跳过 Rootkit 检测配置"
MSG_ROOTKIT_WIZARD_DONE="Rootkit 检测配置完成"
MSG_ROOTKIT_INSTALL_RKHUNTER="正在安装 rkhunter..."
MSG_ROOTKIT_INSTALL_RKHUNTER_DONE="rkhunter 安装完成"
MSG_ROOTKIT_RKHUNTER_ALREADY="rkhunter 已安装"
MSG_ROOTKIT_INSTALL_CHKROOTKIT="正在安装 chkrootkit..."
MSG_ROOTKIT_INSTALL_CHKROOTKIT_DONE="chkrootkit 安装完成"
MSG_ROOTKIT_CHKROOTKIT_ALREADY="chkrootkit 已安装"
MSG_ROOTKIT_CHKROOTKIT_UNAVAIL="chkrootkit 在此发行版不可用，仅使用 rkhunter"
MSG_ROOTKIT_UNSUPPORTED_OS="不支持的操作系统，跳过 Rootkit 检测"
MSG_ROOTKIT_CONFIGURE="正在配置 rkhunter..."
MSG_ROOTKIT_CONFIGURE_DONE="rkhunter 配置完成"
MSG_ROOTKIT_PROPUPD="正在更新 rkhunter 文件属性数据库..."
MSG_ROOTKIT_PROPUPD_DONE="rkhunter 文件属性更新完成"
MSG_ROOTKIT_RUN_SCAN="运行 Rootkit 扫描"
MSG_ROOTKIT_SCAN_RUNNING="Rootkit 扫描进行中（可能需要 10-30 分钟）..."
MSG_ROOTKIT_SCAN_DONE="Rootkit 扫描完成"
MSG_ROOTKIT_SCAN_FOUND="发现 Rootkit 警告！请查看 /var/log/rkhunter/rkhunter.log"
MSG_ROOTKIT_SCAN_CLEAN="未发现 Rootkit 警告"
MSG_ROOTKIT_CRON_SETUP="设置每周 rkhunter 定时任务"
MSG_ROOTKIT_CRON_DONE="每周 rkhunter 定时任务已设置"
MSG_ROOTKIT_CRON_EXISTS="每周 rkhunter 定时任务已存在"
MSG_ROOTKIT_CRON_SKIP="跳过每周 rkhunter 定时任务"
MSG_ROOTKIT_STATUS="Rootkit 检测状态"
MSG_ROOTKIT_LAST_SCAN="上次扫描"
MSG_ROOTKIT_NOT_INSTALLED="未安装"
MSG_ROOTKIT_SUMMARY="Rootkit 检测摘要"
MSG_ROOTKIT_TIPS_TITLE="Rootkit 检测管理命令："
MSG_ROOTKIT_TIPS_1="运行 rkhunter 扫描：rkhunter --check --skip-keypress"
MSG_ROOTKIT_TIPS_2="更新文件属性：rkhunter --propupd"
MSG_ROOTKIT_TIPS_3="运行 chkrootkit 扫描：chkrootkit"
MSG_ROOTKIT_TIPS_4="查看 rkhunter 日志：cat /var/log/rkhunter/rkhunter.log"
MSG_ROOTKIT_MENU_TITLE="Rootkit 检测"
MSG_ROOTKIT_MENU_WIZARD="[1] 全流程加固"
MSG_ROOTKIT_MENU_STATUS="[2] 仅查看状态"
MSG_ROOTKIT_MENU_BACK="[0] 返回主菜单"
MSG_HINT_STATUS_ROOTKIT="Rootkit 状态：见主菜单 [1] 系统状态检测"
MSG_STATUS_ROOTKIT="Rootkit 检测"
MSG_REPORT_WARN_ROOTKIT="Rootkit 检测工具已安装，建议每周运行 rkhunter --check"
MSG_TASK_ROOTKIT="Rootkit 检测"

# ═══════════════════════════════════════════
# sudo 与日志加固（Batch 5b）
# ═══════════════════════════════════════════

MSG_MAIN_MENU_SUDO_LOG="[22] sudo 与日志加固"
MSG_MAIN_MENU_SUDO_LOG_DESC="sudo 权限收紧、命令全量日志、journald 持久化、日志轮转安全"

MSG_SUDO_LOG_MENU_TITLE="sudo 与日志加固"
MSG_SUDO_LOG_MENU_SUDO="[1] sudo 安全加固"
MSG_SUDO_LOG_MENU_LOGGING="[2] 日志安全加固"
MSG_SUDO_LOG_MENU_BACK="[0] 返回主菜单"

# sudo 加固
MSG_SUDO_TITLE="sudo 安全加固"
MSG_SUDO_WIZARD_TITLE="sudo 安全加固向导"
MSG_SUDO_WIZARD_DESC="收紧 sudoers 默认参数、写入加固 drop-in（visudo 校验）、开启 sudo 命令全量日志"
MSG_SUDO_WIZARD_START="是否开始 sudo 安全加固？"
MSG_SUDO_WIZARD_SKIPPED="跳过 sudo 安全加固"
MSG_SUDO_WIZARD_DONE="sudo 安全加固完成"
MSG_SUDO_ALREADY_HARDENED="sudo 加固配置已存在，跳过"
MSG_SUDO_BACKUP_DROPIN="备份 sudoers 加固配置"
MSG_SUDO_RESTORE_DROPIN="恢复 sudoers 加固配置"
MSG_SUDO_DROPIN_WRITE_FAILED="sudoers 加固配置写入失败，已回滚"
MSG_SUDO_DROPIN_DONE="sudoers 加固配置已写入并通过 visudo 校验"
MSG_SUDO_VISUDO_FAILED="visudo 校验失败，已回滚 sudoers 加固配置"
MSG_SUDO_NOPASSWD_RISK="检测到 NOPASSWD 配置：允许部分用户/命令免密执行 sudo，存在安全风险，请确认是否符合预期"
MSG_SUDO_LOG_PERMS_DONE="sudo 命令日志文件权限已确认"
MSG_SUDO_LOGROTATE_DONE="sudo 日志轮转配置已写入"
MSG_SUDO_LOGROTATE_EXISTS="sudo 日志轮转配置已存在，跳过"
MSG_SUDO_DONE="sudo 安全加固完成"

# 日志加固
MSG_LOG_TITLE="日志安全加固"
MSG_LOG_WIZARD_TITLE="日志安全加固向导"
MSG_LOG_WIZARD_DESC="journald 持久化与大小限制、logrotate 安全配置、/var/log 关键日志权限修复"
MSG_LOG_WIZARD_START="是否开始日志安全加固？"
MSG_LOG_WIZARD_SKIPPED="跳过日志安全加固"
MSG_LOG_WIZARD_DONE="日志安全加固完成"
MSG_LOG_BACKUP_CONF="备份日志安全配置文件"
MSG_LOG_JOURNALD_EXISTS="journald 加固配置已存在，跳过"
MSG_LOG_JOURNALD_DONE="journald 加固配置已写入"
MSG_LOG_JOURNALD_RESTART_DONE="systemd-journald 已重启，配置生效"
MSG_LOG_JOURNALD_RESTART_WARN="systemd-journald 重启失败（容器/受限环境常见），配置将在下次重启生效"
MSG_LOG_LOGROTATE_EXISTS="logrotate 安全配置已存在，跳过"
MSG_LOG_LOGROTATE_DONE="logrotate 安全配置已写入"
MSG_LOG_PERM_FIXING="正在修复日志文件权限"
MSG_LOG_PERM_FIXED="日志文件权限已修复"
MSG_LOG_PERM_FIX_FAILED="日志文件权限修复失败"
MSG_LOG_CHOWN_FAILED="无法修改日志文件属主（需要 root 权限）"
MSG_LOG_PERM_ALL_OK="关键日志文件权限全部正确"
MSG_LOG_PERM_ISSUES="发现日志文件权限异常"
MSG_LOG_DONE="日志安全加固完成"

# ===== 更换软件源（mirror.sh，vendored from LinuxMirrors）=====
MSG_MIRROR_COMMANDS_HELP="命令选项(名称/含义/值)：

  --abroad                     使用境外以及海外软件源                                             无
  --edu                        使用中国大陆教育网软件源                                           无
  --source                     指定软件源地址(域名或IP)                                           地址
  --source-epel                指定 EPEL 附加软件包仓库的软件源地址(域名或IP)                     地址
  --source-security            指定 Debian / Ubuntu 系统 security 仓库的软件源地址(域名或IP)      地址
  --source-vault               指定 CentOS / AlmaLinux 系统 vault 仓库的软件源地址(域名或IP)      地址
  --source-portage             指定 Gentoo 系统 portage 仓库的软件源地址(域名或IP)                地址
  --source-base-system         指定 Linux Mint / Raspberry Pi OS 底层系统的软件源地址(域名或IP)   地址
  --branch                     指定软件源仓库(路径)                                               仓库名
  --branch-epel                指定 EPEL 附加软件包仓库的软件源仓库(路径)                         仓库名
  --branch-security            指定 Debian 系统 security 仓库的软件源仓库(路径)                   仓库名
  --branch-vault               指定 CentOS / AlmaLinux 系统 vault 仓库的软件源仓库(路径)          仓库名
  --branch-portage             指定 Gentoo 系统 portage 仓库的软件源仓库(路径)                    仓库名
  --branch-base-system         指定 Linux Mint / Raspberry Pi OS 底层系统的软件源仓库(路径)       仓库名
  --codename                   指定 Debian 系 / openKylin 操作系统的版本代号                      代号名称
  --protocol                   指定 Web 协议                                                      http 或 https
  --use-intranet-source        是否优先使用内网软件源地址                                         true 或 false
  --use-official-source        是否使用目标操作系统的官方软件源                                   true 或 false
  --use-official-source-epel   是否使用 EPEL 附加软件包的官方软件源                               true 或 false
  --install-epel               是否安装 EPEL 附加软件包                                           true 或 false
  --backup                     是否备份原有软件源                                                 true 或 false
  --upgrade-software           是否更新软件包                                                     true 或 false
  --clean-cache                是否在更新软件包后清理下载缓存                                     true 或 false
  --clean-screen               是否在运行前清除屏幕上的所有内容                                   true 或 false
  --lang                       指定脚本输出的语言                                                 语言
  --only-epel                  仅更换 EPEL 软件源模式                                             无
  --ignore-backup-tips         忽略覆盖备份提示                                                   无
  --print-diff                 打印源文件修改前后差异                                             无
  --pure-mode                  纯净模式，精简打印内容                                             无
  --help                       查看帮助菜单                                                       无

问题报告 {}"
MSG_MIRROR_END_MOREINFO="脚本运行完毕，更多使用教程详见官网"
MSG_MIRROR_END_SPONSORADS="【赞助商广告】"
MSG_MIRROR_ERROR_CMD_OPTIONS_BOOLEAN=" true 或 false "
MSG_MIRROR_ERROR_CMD_OPTIONS_CODENAME="版本代号"
MSG_MIRROR_ERROR_CMD_OPTIONS_INVALID="命令选项 {} 无效，{}！"
MSG_MIRROR_ERROR_CMD_OPTIONS_LANGKEY="语言 "
MSG_MIRROR_ERROR_CMD_OPTIONS_NEEDCONFIRM="请确认后重新输入"
MSG_MIRROR_ERROR_CMD_OPTIONS_NEEDPROTOCOL=" Web 协议(http/https)"
MSG_MIRROR_ERROR_CMD_OPTIONS_NEEDSPECIFY="请在该选项后指定{}"
MSG_MIRROR_ERROR_CMD_OPTIONS_PROTOCOL=" http 或 https "
MSG_MIRROR_ERROR_CMD_OPTIONS_SOURCEADDRESS="软件源地址"
MSG_MIRROR_ERROR_CMD_OPTIONS_SOURCEREPOSITORY="软件源仓库"
MSG_MIRROR_ERROR_CMD_OPTIONS_UNSUPPORTCODENAME="当前系统不支持使用指定版本代号命令选项，请确认后重试！"
MSG_MIRROR_ERROR_CMD_OPTIONS_UNSUPPORTEPEL="当前系统不支持安装 EPEL 附加软件包，请确认后重试！"
MSG_MIRROR_ERROR_CMD_OPTIONS_UNSUPPORTTWOSOURCEMODE="不可同时使用两种软件源模式，请确认后重试！"
MSG_MIRROR_ERROR_CMD_OPTIONS_VALIDADDRESS="有效的地址"
MSG_MIRROR_ERROR_CMD_OPTIONS_VALIDLANGKEY="有效的语言 ID "
MSG_MIRROR_ERROR_DEFAULTBEHAVIOR_HTTPS="默认使用 HTTPS 协议"
MSG_MIRROR_ERROR_DEFAULTBEHAVIOR_NOCLEAN="默认不清理"
MSG_MIRROR_ERROR_DEFAULTBEHAVIOR_NOOVERWRITE="默认不覆盖"
MSG_MIRROR_ERROR_DEFAULTBEHAVIOR_NOREPLACE="默认不更换"
MSG_MIRROR_ERROR_DEFAULTBEHAVIOR_NOUPDATE="默认不更新"
MSG_MIRROR_ERROR_DEFAULTBEHAVIOR_NOUSEINTRANETSOURCE="默认不使用内网地址"
MSG_MIRROR_ERROR_INPUT="输入错误，{}！"
MSG_MIRROR_ERROR_NEEDROOT="权限不足，请切换至 root 账户后运行本脚本，切换命令 {}"
MSG_MIRROR_ERROR_UNKNOWNSYSTEM="未知系统"
MSG_MIRROR_ERROR_UNKNOWNVERSION="系统版本未知"
MSG_MIRROR_ERROR_UNSUPPORTSYSTEM="不支持当前操作系统（{}），请前往官网查看支持列表！"
MSG_MIRROR_ERROR_UNSUPPORTVERSION="不支持当前系统版本"
MSG_MIRROR_INFO_BACKUPED_SOURCEFILE="已备份原有 {} 源文件"
MSG_MIRROR_INTERACTION_BACKUP_SKIPOVERWRITE_SOURCEFILE="检测到系统存在已备份的 {} 源文件，是否跳过覆盖备份"
MSG_MIRROR_INTERACTION_CACHE_AUTOCLEAN="在更新软件包后，是否自动清理下载缓存"
MSG_MIRROR_INTERACTION_COMMON_NO="否"
MSG_MIRROR_INTERACTION_COMMON_OPERATIONCANCELED="操作已取消"
MSG_MIRROR_INTERACTION_COMMON_TIP="提示"
MSG_MIRROR_INTERACTION_COMMON_YES="是"
MSG_MIRROR_INTERACTION_EPEL_INSTALL="是否安装 EPEL 附加软件包"
MSG_MIRROR_INTERACTION_EPEL_SKIPREPLACE="检测到系统已安装 EPEL 附加软件包，是否替换/覆盖软件源"
MSG_MIRROR_INTERACTION_PROTOCOL_SELECT="请选择软件源网络协议："
MSG_MIRROR_INTERACTION_PROTOCOL_USEHTTP="软件源是否使用 HTTP 协议"
MSG_MIRROR_INTERACTION_SOURCE_SELECT="请选择你想使用的软件源："
MSG_MIRROR_INTERACTION_SOURCE_SELECTANDINPUT="请选择并输入你想使用的软件源"
MSG_MIRROR_INTERACTION_SOURCE_TYPE_INTRANET="内网"
MSG_MIRROR_INTERACTION_SOURCE_TYPE_PUBLIC="公网"
MSG_MIRROR_INTERACTION_SOURCE_TYPE_SELECT="请选择软件源的网络地址(访问方式)："
MSG_MIRROR_INTERACTION_SOURCE_TYPE_USEPUBLICADDRESS="默认使用软件源的公网地址，是否继续"
MSG_MIRROR_INTERACTION_UPGRADE_SKIP="是否跳过更新软件包"
MSG_MIRROR_MIRRORS_ABROAD_0="亚洲 · xTom · 香港"
MSG_MIRROR_MIRRORS_ABROAD_1="亚洲 · 01Link · 香港"
MSG_MIRROR_MIRRORS_ABROAD_10="亚洲 · AniGil Linux Archive · 韩国"
MSG_MIRROR_MIRRORS_ABROAD_11="亚洲 · 工业网络安全中心(ICSCoE) · 日本"
MSG_MIRROR_MIRRORS_ABROAD_12="亚洲 · 北陆先端科学技术大学院大学(JAIST) · 日本"
MSG_MIRROR_MIRRORS_ABROAD_13="亚洲 · 山形大学 · 日本"
MSG_MIRROR_MIRRORS_ABROAD_14="亚洲 · xTom · 日本"
MSG_MIRROR_MIRRORS_ABROAD_15="亚洲 · GB Network Solutions · 马来西亚"
MSG_MIRROR_MIRRORS_ABROAD_16="亚洲 · 孔敬大学 · 泰国"
MSG_MIRROR_MIRRORS_ABROAD_17="欧洲 · Vorboss Ltd · 英国"
MSG_MIRROR_MIRRORS_ABROAD_18="欧洲 · QuickHost · 英国"
MSG_MIRROR_MIRRORS_ABROAD_19="欧洲 · dogado · 德国"
MSG_MIRROR_MIRRORS_ABROAD_2="亚洲 · 新加坡国立大学(NUS) · 新加坡"
MSG_MIRROR_MIRRORS_ABROAD_20="欧洲 · xTom · 德国"
MSG_MIRROR_MIRRORS_ABROAD_21="欧洲 · 亚琛工业大学(RWTH Aachen) · 德国"
MSG_MIRROR_MIRRORS_ABROAD_22="欧洲 · 德累斯顿大学(AG DSN) · 德国"
MSG_MIRROR_MIRRORS_ABROAD_23="欧洲 · CCIN2P3 · 法国"
MSG_MIRROR_MIRRORS_ABROAD_24="欧洲 · Ircam · 法国"
MSG_MIRROR_MIRRORS_ABROAD_25="欧洲 · Crans · 法国"
MSG_MIRROR_MIRRORS_ABROAD_26="欧洲 · CRIHAN · 法国"
MSG_MIRROR_MIRRORS_ABROAD_27="欧洲 · xTom · 荷兰"
MSG_MIRROR_MIRRORS_ABROAD_28="欧洲 · DataPacket · 荷兰"
MSG_MIRROR_MIRRORS_ABROAD_29="欧洲 · Linux Kernel · 荷兰"
MSG_MIRROR_MIRRORS_ABROAD_3="亚洲 · SG.GS · 新加坡"
MSG_MIRROR_MIRRORS_ABROAD_30="欧洲 · xTom · 爱沙尼亚"
MSG_MIRROR_MIRRORS_ABROAD_31="欧洲 · netsite · 丹麦"
MSG_MIRROR_MIRRORS_ABROAD_32="欧洲 · Dotsrc · 丹麦"
MSG_MIRROR_MIRRORS_ABROAD_33="欧洲 · Academic Computer Club · 瑞典"
MSG_MIRROR_MIRRORS_ABROAD_34="欧洲 · Lysator · 瑞典"
MSG_MIRROR_MIRRORS_ABROAD_35="欧洲 · Yandex · 俄罗斯"
MSG_MIRROR_MIRRORS_ABROAD_36="欧洲 · ia64 · 俄罗斯"
MSG_MIRROR_MIRRORS_ABROAD_37="欧洲 · Truenetwork · 俄罗斯"
MSG_MIRROR_MIRRORS_ABROAD_38="欧洲 · Belgian Research Network · 比利时"
MSG_MIRROR_MIRRORS_ABROAD_39="欧洲 · 克里特大学计算机中心 · 希腊"
MSG_MIRROR_MIRRORS_ABROAD_4="亚洲 · xTom · 新加坡"
MSG_MIRROR_MIRRORS_ABROAD_40="欧洲 · 马萨里克大学信息学院 · 捷克"
MSG_MIRROR_MIRRORS_ABROAD_41="欧洲 · 捷克理工大学学生会俱乐部(Silicon Hill) · 捷克"
MSG_MIRROR_MIRRORS_ABROAD_42="欧洲 · Vodafone · 捷克"
MSG_MIRROR_MIRRORS_ABROAD_43="欧洲 · CZ.NIC · 捷克"
MSG_MIRROR_MIRRORS_ABROAD_44="欧洲 · 苏黎世联邦理工学院 · 瑞士"
MSG_MIRROR_MIRRORS_ABROAD_45="北美 · Linux Kernel · 美国"
MSG_MIRROR_MIRRORS_ABROAD_46="北美 · 麻省理工学院(MIT) · 美国"
MSG_MIRROR_MIRRORS_ABROAD_47="北美 · 普林斯顿大学数学系 · 美国"
MSG_MIRROR_MIRRORS_ABROAD_48="北美 · 俄勒冈州立大学开源实验室 · 美国"
MSG_MIRROR_MIRRORS_ABROAD_49="北美 · Fremont Cabal Internet Exchange(FCIX) · 美国"
MSG_MIRROR_MIRRORS_ABROAD_5="亚洲 · 自由软件实验室(NCHC) · 台湾"
MSG_MIRROR_MIRRORS_ABROAD_50="北美 · xTom · 美国"
MSG_MIRROR_MIRRORS_ABROAD_51="北美 · Steadfast · 美国"
MSG_MIRROR_MIRRORS_ABROAD_52="北美 · 不列颠哥伦比亚大学 · 加拿大"
MSG_MIRROR_MIRRORS_ABROAD_53="北美 · GoCodeIT · 加拿大"
MSG_MIRROR_MIRRORS_ABROAD_54="北美 · Switch · 加拿大"
MSG_MIRROR_MIRRORS_ABROAD_55="南美 · PoP-SC · 巴西"
MSG_MIRROR_MIRRORS_ABROAD_56="南美 · 蓬塔格罗萨州立大学 · 巴西"
MSG_MIRROR_MIRRORS_ABROAD_57="南美 · UFSCar · 巴西"
MSG_MIRROR_MIRRORS_ABROAD_58="南美 · Sysarmy Community · 阿根廷"
MSG_MIRROR_MIRRORS_ABROAD_59="大洋 · Fremont Cabal Internet Exchange(FCIX) · 澳大利亚"
MSG_MIRROR_MIRRORS_ABROAD_6="亚洲 · OSS Planet · 台湾"
MSG_MIRROR_MIRRORS_ABROAD_60="大洋 · AARNet · 澳大利亚"
MSG_MIRROR_MIRRORS_ABROAD_61="大洋 · DataMossa · 澳大利亚"
MSG_MIRROR_MIRRORS_ABROAD_62="大洋 · Amaze · 澳大利亚"
MSG_MIRROR_MIRRORS_ABROAD_63="大洋 · xTom · 澳大利亚"
MSG_MIRROR_MIRRORS_ABROAD_64="大洋 · Over the Wire · 澳大利亚"
MSG_MIRROR_MIRRORS_ABROAD_65="大洋 · Free Software Mirror Group · 新西兰"
MSG_MIRROR_MIRRORS_ABROAD_66="非洲 · Liquid Telecom · 肯尼亚"
MSG_MIRROR_MIRRORS_ABROAD_67="非洲 · Dimension Data · 南非"
MSG_MIRROR_MIRRORS_ABROAD_68="官方源"
MSG_MIRROR_MIRRORS_ABROAD_7="亚洲 · 国立阳明交通大学 · 台湾"
MSG_MIRROR_MIRRORS_ABROAD_8="亚洲 · 淡江大学 · 台湾"
MSG_MIRROR_MIRRORS_ABROAD_9="亚洲 · Taiwan Digital Streaming · 台湾"
MSG_MIRROR_MIRRORS_DEFAULT_0="阿里云"
MSG_MIRROR_MIRRORS_DEFAULT_1="腾讯云"
MSG_MIRROR_MIRRORS_DEFAULT_10="南京大学"
MSG_MIRROR_MIRRORS_DEFAULT_11="兰州大学"
MSG_MIRROR_MIRRORS_DEFAULT_12="上海交通大学"
MSG_MIRROR_MIRRORS_DEFAULT_13="华中科技大学"
MSG_MIRROR_MIRRORS_DEFAULT_14="中国科学技术大学"
MSG_MIRROR_MIRRORS_DEFAULT_15="中国科学院软件研究所"
MSG_MIRROR_MIRRORS_DEFAULT_16="中国科技云"
MSG_MIRROR_MIRRORS_DEFAULT_17="官方源"
MSG_MIRROR_MIRRORS_DEFAULT_2="华为云"
MSG_MIRROR_MIRRORS_DEFAULT_3="移动云"
MSG_MIRROR_MIRRORS_DEFAULT_4="天翼云"
MSG_MIRROR_MIRRORS_DEFAULT_5="网易"
MSG_MIRROR_MIRRORS_DEFAULT_6="火山引擎"
MSG_MIRROR_MIRRORS_DEFAULT_7="清华大学"
MSG_MIRROR_MIRRORS_DEFAULT_8="北京大学"
MSG_MIRROR_MIRRORS_DEFAULT_9="浙江大学"
MSG_MIRROR_MIRRORS_EDU_0="北京大学"
MSG_MIRROR_MIRRORS_EDU_1="北京交通大学"
MSG_MIRROR_MIRRORS_EDU_10="吉林大学"
MSG_MIRROR_MIRRORS_EDU_11="荆楚理工学院"
MSG_MIRROR_MIRRORS_EDU_12="江西理工大学"
MSG_MIRROR_MIRRORS_EDU_13="兰州大学"
MSG_MIRROR_MIRRORS_EDU_14="南京大学"
MSG_MIRROR_MIRRORS_EDU_15="南京工业大学"
MSG_MIRROR_MIRRORS_EDU_16="南京邮电大学"
MSG_MIRROR_MIRRORS_EDU_17="南方科技大学"
MSG_MIRROR_MIRRORS_EDU_18="南阳理工学院"
MSG_MIRROR_MIRRORS_EDU_19="齐鲁工业大学"
MSG_MIRROR_MIRRORS_EDU_2="北京外国语大学"
MSG_MIRROR_MIRRORS_EDU_20="清华大学"
MSG_MIRROR_MIRRORS_EDU_21="山东大学"
MSG_MIRROR_MIRRORS_EDU_22="上海科技大学"
MSG_MIRROR_MIRRORS_EDU_23="上海交通大学（思源）"
MSG_MIRROR_MIRRORS_EDU_24="上海交通大学（致远）"
MSG_MIRROR_MIRRORS_EDU_25="武昌首义学院"
MSG_MIRROR_MIRRORS_EDU_26="西安交通大学"
MSG_MIRROR_MIRRORS_EDU_27="西北农林科技大学"
MSG_MIRROR_MIRRORS_EDU_28="浙江大学"
MSG_MIRROR_MIRRORS_EDU_29="中国科学技术大学"
MSG_MIRROR_MIRRORS_EDU_3="北京邮电大学"
MSG_MIRROR_MIRRORS_EDU_30="官方源"
MSG_MIRROR_MIRRORS_EDU_4="重庆大学"
MSG_MIRROR_MIRRORS_EDU_5="重庆邮电大学"
MSG_MIRROR_MIRRORS_EDU_6="大连东软信息学院"
MSG_MIRROR_MIRRORS_EDU_7="电子科技大学"
MSG_MIRROR_MIRRORS_EDU_8="华南农业大学"
MSG_MIRROR_MIRRORS_EDU_9="华中科技大学"
MSG_MIRROR_SOURCE_CHANGERESULT_FAIL="软件源更换完毕，但{}失败"
MSG_MIRROR_SOURCE_CHANGERESULT_SUCCESS="软件源更换完毕"
MSG_MIRROR_SOURCE_CHANGERESULT_TIP1="网络连通性问题：例如连接异常、由地区影响的网络间歇式中断、禁止外部访问、软件源网站防火墙阻断等"
MSG_MIRROR_SOURCE_CHANGERESULT_TIP2="目标软件源异常：请手动前往软件源（镜像站）地址进行验证：{}"
MSG_MIRROR_SOURCE_CHANGERESULT_TIP2_1="若报错内容是提示某个文件不存在那么有可能是软件源的问题，多常见于正在同步中的软件源仓库"
MSG_MIRROR_SOURCE_CHANGERESULT_TIP2_2="若报错内容是目录（path）不存在也有可能是目标软件源不存在当前系统镜像仓库，即不支持当前系统"
MSG_MIRROR_SOURCE_CHANGERESULT_TIP2_3="建议更换其它镜像站进行尝试，少数情况下软件源若处于同步中状态则可能会出现文件同步错误问题"
MSG_MIRROR_SOURCE_CHANGERESULT_TIP3="原有软件源报错：请先排除系统原有的其它软件源报错，因为脚本不会干预这些无关的软件源配置，解决后重新运行脚本即可"
MSG_MIRROR_SOURCE_CHANGERESULT_TIPTITLE="请再次执行脚本并更换相同软件源后进行尝试，若仍然{}失败那么可能由以下原因导致："
MSG_MIRROR_SOURCE_COMMENT_DISABLEDSOURCECODE="默认禁用源码镜像以提高更新速度，如需启用请自行取消注释"
MSG_MIRROR_SOURCE_COMMENT_PROPOSEDSOURCE="预发布软件源（不建议启用）"
MSG_MIRROR_SOURCE_COMMENT_SECURITYSOURCE="安全更新软件源"
MSG_MIRROR_SOURCE_SYNC_TEXT1="更新软件源"
MSG_MIRROR_SOURCE_SYNC_TEXT2="生成软件源缓存"
MSG_MIRROR_SOURCE_SYNC_TEXT3="刷新软件源"
MSG_MIRROR_SOURCE_SYNC_TEXT4="同步软件源"
MSG_MIRROR_SOURCE_SYNC_TEXT5="更新二进制缓存与频道源"
MSG_MIRROR_START_DATETIME="系统时间"
MSG_MIRROR_START_RUNTIMEENV="运行环境"
MSG_MIRROR_START_WELCOME="欢迎使用 GNU/Linux 更换系统软件源脚本"
MSG_MIRROR_TIP_EPEL7="目前部分镜像站没有同步该归档仓库，若换源后出现错误那么请先检查目标镜像站是否支持该仓库。"
MSG_MIRROR_WARN_EPEL7="Extra Packages for Enterprise Linux 7 已结束生命周期并被官方移至归档库！"
MSG_MIRROR_WARN_NEEDINPUTNUMBERINDEX="请输入数字序号！"
MSG_MIRROR_WARN_NEEDVALIDNUMBERINDEX="请输入有效的数字序号！"
MSG_MIRROR_WARN_UNSTABLEDEBIAN="检测到当前系统为 {} 版本，可能会产生一些无法预料的问题。"
MSG_MIRROR_WARN_USEDINTRANETSOURCE="已切换至内网专用地址，仅限在特定环境下使用！"
MSG_MIRROR_WORK_INSTALLEPELPACKAGE="安装 epel-release 软件包..."
MSG_MIRROR_WORK_UPGRADESOFTWARE="更新软件包"
MSG_MAIN_MENU_MIRROR="[19] 更换软件源"
MSG_MAIN_MENU_MIRROR_DESC="交互式更换系统软件源（镜像站）"
MSG_MIRROR_MENU_TITLE="更换软件源"
MSG_MIRROR_MENU_CHANGE_SOURCE="[1] 更换软件源（完整交互流程）"
MSG_MIRROR_MENU_RESTORE_OFFICIAL="[2] 恢复官方源"
MSG_MIRROR_MENU_VIEW_SOURCE="[3] 查看当前软件源"
MSG_MIRROR_MENU_BACK="[0] 返回主菜单"
MSG_MIRROR_MENU_PROMPT="请选择操作："
MSG_MIRROR_MENU_INVALID="无效选项，请重新输入"
MSG_MIRROR_CONFIRM_CHANGE="即将更换系统软件源，是否继续？"
MSG_MIRROR_CONFIRM_RESTORE="即将恢复官方软件源，是否继续？"
MSG_MIRROR_VIEW_TITLE="当前软件源"
MSG_MIRROR_UNSUPPORTED="暂不支持显示当前系统类型的软件源"
MSG_MIRROR_ERROR_CHANGE="更换软件源失败"
MSG_MIRROR_ERROR_RESTORE="恢复官方软件源失败"
MSG_MIRROR_ERROR_VIEW="查看当前软件源失败"

# ═══════════════════════════════════════════
# 服务器软件（Docker / Nginx）
# ═══════════════════════════════════════════

MSG_MAIN_MENU_SERVER="[20] 服务器软件"
MSG_MAIN_MENU_SERVER_DESC="安装 Docker、Nginx 等常用软件并应用安全基线"
MSG_SERVER_MENU_TITLE="服务器软件"
MSG_SERVER_MENU_DOCKER="[1] Docker"
MSG_SERVER_MENU_NGINX="[2] Nginx"
MSG_SERVER_MENU_BACK="[0] 返回主菜单"

# Docker (Container Engine)
MSG_DOCKER_TITLE="Docker 容器引擎"
MSG_DOCKER_INSTALLING="正在安装 Docker..."
MSG_DOCKER_DOWNLOADING="正在从 https://get.docker.com 下载安装脚本..."
MSG_DOCKER_INSTALLED="Docker 安装完成"
MSG_DOCKER_ALREADY="Docker 已安装，跳过"
MSG_DOCKER_FAILED="Docker 安装失败"
MSG_DOCKER_CANCELLED="Docker 操作已取消"
MSG_DOCKER_CONFIRM="确认安装 Docker Engine + compose 插件？"
MSG_DOCKER_CONFIRM_UNINSTALL="确认卸载 Docker？此操作将移除 Docker 引擎及相关组件。"
MSG_DOCKER_UNINSTALLING="正在卸载 Docker..."
MSG_DOCKER_UNINSTALLED="Docker 已卸载"
MSG_DOCKER_UNINSTALL_FAILED="Docker 卸载失败"
MSG_DOCKER_NOT_INSTALLED="Docker 未安装"
MSG_DOCKER_STATUS_CHECKING="正在检查 Docker 状态..."
MSG_DOCKER_STATUS_RUNNING="Docker 服务运行中"
MSG_DOCKER_STATUS_NOT_RUNNING="Docker 服务未运行"
MSG_DOCKER_CURL_REQUIRED="Docker 安装需要 curl，请先安装 curl"
MSG_DOCKER_USERN_REMAP_PROMPT="是否启用 userns-remap 用户命名空间隔离？（激进项，可能影响部分镜像兼容）"
MSG_DOCKER_USERN_REMAP_ENABLED="已启用 userns-remap 用户命名空间隔离"
MSG_DOCKER_DAEMON_WRITTEN="daemon.json 安全基线已写入"
MSG_DOCKER_DAEMON_EXISTS="daemon.json 已存在，已备份并保留现有配置"
MSG_DOCKER_DAEMON_MISSING="daemon.json 未配置（未应用安全基线）"
MSG_DOCKER_BACKUP_DAEMON="备份 daemon.json"
MSG_DOCKER_ENABLE_FAILED="Docker 服务启用/启动失败"
MSG_DOCKER_MENU_TITLE="Docker 容器引擎"
MSG_DOCKER_MENU_INSTALL="[1] 安装 Docker"
MSG_DOCKER_MENU_UNINSTALL="[2] 卸载 Docker"
MSG_DOCKER_MENU_STATUS="[3] 查看 Docker 状态"
MSG_DOCKER_MENU_BACK="[0] 返回"

# Nginx (Web Server)
MSG_NGINX_TITLE="Nginx Web 服务器"
MSG_NGINX_INSTALLING="正在安装 Nginx..."
MSG_NGINX_INSTALLED="Nginx 安装完成"
MSG_NGINX_ALREADY="Nginx 已安装，跳过"
MSG_NGINX_FAILED="Nginx 安装失败"
MSG_NGINX_CANCELLED="Nginx 操作已取消"
MSG_NGINX_CONFIRM="确认安装 Nginx？"
MSG_NGINX_CONFIRM_UNINSTALL="确认卸载 Nginx？"
MSG_NGINX_UNINSTALLING="正在卸载 Nginx..."
MSG_NGINX_UNINSTALLED="Nginx 已卸载"
MSG_NGINX_UNINSTALL_FAILED="Nginx 卸载失败"
MSG_NGINX_NOT_INSTALLED="Nginx 未安装"
MSG_NGINX_STATUS_CHECKING="正在检查 Nginx 状态..."
MSG_NGINX_STATUS_RUNNING="Nginx 服务运行中"
MSG_NGINX_STATUS_NOT_RUNNING="Nginx 服务未运行"
MSG_NGINX_SECURITY_HEADERS_WRITTEN="安全响应头基线已写入"
MSG_NGINX_SECURITY_HEADERS_EXISTS="安全头配置已存在，已备份并保留现有配置"
MSG_NGINX_SECURITY_HEADERS_MISSING="安全响应头未配置（未应用安全基线）"
MSG_NGINX_BACKUP_HEADERS="备份安全头配置"
MSG_NGINX_HSTS_PROMPT="是否启用 HSTS 强安全头？（激进项，仅当站点已启用 HTTPS）"
MSG_NGINX_HSTS_ENABLED="已启用 HSTS 强安全头"
MSG_NGINX_ENABLE_FAILED="Nginx 服务启用/启动失败"
MSG_NGINX_UNSUPPORTED_OS="当前系统不支持 Nginx 自动安装"
MSG_NGINX_MENU_TITLE="Nginx Web 服务器"
MSG_NGINX_MENU_INSTALL="[1] 安装 Nginx"
MSG_NGINX_MENU_UNINSTALL="[2] 卸载 Nginx"
MSG_NGINX_MENU_STATUS="[3] 查看 Nginx 状态"
MSG_NGINX_MENU_BACK="[0] 返回"

# ═══════════════════════════════════════════
# 服务器软件（数据库 / 缓存）
# ═══════════════════════════════════════════

MSG_SERVER_MENU_REDIS="[3] Redis"
MSG_SERVER_MENU_POSTGRES="[4] PostgreSQL"
MSG_SERVER_MENU_MYSQL="[5] MySQL"
MSG_SERVER_MENU_MEMCACHED="[6] Memcached"

# Redis (In-memory Database)
MSG_REDIS_TITLE="Redis 内存数据库"
MSG_REDIS_INSTALLING="正在安装 Redis..."
MSG_REDIS_INSTALLED="Redis 安装完成"
MSG_REDIS_ALREADY="Redis 已安装，跳过"
MSG_REDIS_FAILED="Redis 安装失败"
MSG_REDIS_CANCELLED="Redis 操作已取消"
MSG_REDIS_CONFIRM="确认安装 Redis？"
MSG_REDIS_CONFIRM_UNINSTALL="确认卸载 Redis？"
MSG_REDIS_UNINSTALLING="正在卸载 Redis..."
MSG_REDIS_UNINSTALLED="Redis 已卸载"
MSG_REDIS_UNINSTALL_FAILED="Redis 卸载失败"
MSG_REDIS_NOT_INSTALLED="Redis 未安装"
MSG_REDIS_STATUS_CHECKING="正在检查 Redis 状态..."
MSG_REDIS_STATUS_RUNNING="Redis 服务运行中"
MSG_REDIS_STATUS_NOT_RUNNING="Redis 服务未运行"
MSG_REDIS_CONFIG_WRITTEN="Redis 安全基线已写入（绑定 localhost + 禁用危险命令）"
MSG_REDIS_CONFIG_EXISTS="Redis 配置已存在，已备份并保留现有配置"
MSG_REDIS_CONFIG_MISSING="Redis 安全基线未应用"
MSG_REDIS_BACKUP_CONFIG="备份 Redis 配置"
MSG_REDIS_ENABLE_FAILED="Redis 服务启用/启动失败"
MSG_REDIS_MENU_TITLE="Redis 内存数据库"
MSG_REDIS_MENU_INSTALL="[1] 安装 Redis"
MSG_REDIS_MENU_UNINSTALL="[2] 卸载 Redis"
MSG_REDIS_MENU_STATUS="[3] 查看 Redis 状态"
MSG_REDIS_MENU_BACK="[0] 返回"

# PostgreSQL (Database)
MSG_POSTGRES_TITLE="PostgreSQL 数据库"
MSG_POSTGRES_INSTALLING="正在安装 PostgreSQL..."
MSG_POSTGRES_INSTALLED="PostgreSQL 安装完成"
MSG_POSTGRES_ALREADY="PostgreSQL 已安装，跳过"
MSG_POSTGRES_FAILED="PostgreSQL 安装失败"
MSG_POSTGRES_CANCELLED="PostgreSQL 操作已取消"
MSG_POSTGRES_CONFIRM="确认安装 PostgreSQL？"
MSG_POSTGRES_CONFIRM_UNINSTALL="确认卸载 PostgreSQL？"
MSG_POSTGRES_UNINSTALLING="正在卸载 PostgreSQL..."
MSG_POSTGRES_UNINSTALLED="PostgreSQL 已卸载"
MSG_POSTGRES_UNINSTALL_FAILED="PostgreSQL 卸载失败"
MSG_POSTGRES_NOT_INSTALLED="PostgreSQL 未安装"
MSG_POSTGRES_STATUS_CHECKING="正在检查 PostgreSQL 状态..."
MSG_POSTGRES_STATUS_RUNNING="PostgreSQL 服务运行中"
MSG_POSTGRES_STATUS_NOT_RUNNING="PostgreSQL 服务未运行"
MSG_POSTGRES_CONFIG_WRITTEN="PostgreSQL 安全基线已写入（scram-sha-256 + 仅监听 localhost）"
MSG_POSTGRES_CONFIG_EXISTS="PostgreSQL 认证配置已存在，已备份并保留现有配置"
MSG_POSTGRES_CONFIG_MISSING="PostgreSQL 安全基线未应用"
MSG_POSTGRES_BACKUP_CONFIG="备份 PostgreSQL 认证配置"
MSG_POSTGRES_ENABLE_FAILED="PostgreSQL 服务启用/启动失败"
MSG_POSTGRES_MENU_TITLE="PostgreSQL 数据库"
MSG_POSTGRES_MENU_INSTALL="[1] 安装 PostgreSQL"
MSG_POSTGRES_MENU_UNINSTALL="[2] 卸载 PostgreSQL"
MSG_POSTGRES_MENU_STATUS="[3] 查看 PostgreSQL 状态"
MSG_POSTGRES_MENU_BACK="[0] 返回"

# MySQL (Database)
MSG_MYSQL_TITLE="MySQL 数据库"
MSG_MYSQL_INSTALLING="正在安装 MySQL..."
MSG_MYSQL_INSTALLED="MySQL 安装完成"
MSG_MYSQL_ALREADY="MySQL 已安装，跳过"
MSG_MYSQL_FAILED="MySQL 安装失败"
MSG_MYSQL_CANCELLED="MySQL 操作已取消"
MSG_MYSQL_CONFIRM="确认安装 MySQL？"
MSG_MYSQL_CONFIRM_UNINSTALL="确认卸载 MySQL？"
MSG_MYSQL_UNINSTALLING="正在卸载 MySQL..."
MSG_MYSQL_UNINSTALLED="MySQL 已卸载"
MSG_MYSQL_UNINSTALL_FAILED="MySQL 卸载失败"
MSG_MYSQL_NOT_INSTALLED="MySQL 未安装"
MSG_MYSQL_STATUS_CHECKING="正在检查 MySQL 状态..."
MSG_MYSQL_STATUS_RUNNING="MySQL 服务运行中"
MSG_MYSQL_STATUS_NOT_RUNNING="MySQL 服务未运行"
MSG_MYSQL_CONFIG_WRITTEN="MySQL 安全基线已应用（移除匿名用户/测试库、禁止 root 远程登录）"
MSG_MYSQL_CONFIG_EXISTS="MySQL 已完成安全初始化，跳过"
MSG_MYSQL_CONFIG_MISSING="MySQL 安全基线未应用"
MSG_MYSQL_BACKUP_CONFIG="备份 MySQL 配置"
MSG_MYSQL_ENABLE_FAILED="MySQL 服务启用/启动失败"
MSG_MYSQL_MENU_TITLE="MySQL 数据库"
MSG_MYSQL_MENU_INSTALL="[1] 安装 MySQL"
MSG_MYSQL_MENU_UNINSTALL="[2] 卸载 MySQL"
MSG_MYSQL_MENU_STATUS="[3] 查看 MySQL 状态"
MSG_MYSQL_MENU_BACK="[0] 返回"

# Memcached (Cache)
MSG_MEMCACHED_TITLE="Memcached 缓存"
MSG_MEMCACHED_INSTALLING="正在安装 Memcached..."
MSG_MEMCACHED_INSTALLED="Memcached 安装完成"
MSG_MEMCACHED_ALREADY="Memcached 已安装，跳过"
MSG_MEMCACHED_FAILED="Memcached 安装失败"
MSG_MEMCACHED_CANCELLED="Memcached 操作已取消"
MSG_MEMCACHED_CONFIRM="确认安装 Memcached？"
MSG_MEMCACHED_CONFIRM_UNINSTALL="确认卸载 Memcached？"
MSG_MEMCACHED_UNINSTALLING="正在卸载 Memcached..."
MSG_MEMCACHED_UNINSTALLED="Memcached 已卸载"
MSG_MEMCACHED_UNINSTALL_FAILED="Memcached 卸载失败"
MSG_MEMCACHED_NOT_INSTALLED="Memcached 未安装"
MSG_MEMCACHED_STATUS_CHECKING="正在检查 Memcached 状态..."
MSG_MEMCACHED_STATUS_RUNNING="Memcached 服务运行中"
MSG_MEMCACHED_STATUS_NOT_RUNNING="Memcached 服务未运行"
MSG_MEMCACHED_CONFIG_WRITTEN="Memcached 安全基线已写入（绑定 localhost + 禁用 UDP）"
MSG_MEMCACHED_CONFIG_EXISTS="Memcached 配置已存在，已备份并保留现有配置"
MSG_MEMCACHED_CONFIG_MISSING="Memcached 安全基线未应用"
MSG_MEMCACHED_BACKUP_CONFIG="备份 Memcached 配置"
MSG_MEMCACHED_ENABLE_FAILED="Memcached 服务启用/启动失败"
MSG_MEMCACHED_MENU_TITLE="Memcached 缓存"
MSG_MEMCACHED_MENU_INSTALL="[1] 安装 Memcached"
MSG_MEMCACHED_MENU_UNINSTALL="[2] 卸载 Memcached"
MSG_MEMCACHED_MENU_STATUS="[3] 查看 Memcached 状态"
MSG_MEMCACHED_MENU_BACK="[0] 返回"

# ═══════════════════════════════════════════
# 服务器软件（监控）
# ═══════════════════════════════════════════

MSG_SERVER_MENU_NODE_EXPORTER="[7] Node Exporter"
MSG_SERVER_MENU_PROMETHEUS="[8] Prometheus"
MSG_SERVER_MENU_GRAFANA="[9] Grafana"

# Node Exporter (Metrics Collector)
MSG_NODE_EXPORTER_TITLE="Node Exporter 监控采集"
MSG_NODE_EXPORTER_INSTALLING="正在安装 Node Exporter..."
MSG_NODE_EXPORTER_INSTALLED="Node Exporter 安装完成"
MSG_NODE_EXPORTER_ALREADY="Node Exporter 已安装，跳过"
MSG_NODE_EXPORTER_FAILED="Node Exporter 安装失败"
MSG_NODE_EXPORTER_CANCELLED="Node Exporter 操作已取消"
MSG_NODE_EXPORTER_CONFIRM="确认安装 Node Exporter？"
MSG_NODE_EXPORTER_CONFIRM_UNINSTALL="确认卸载 Node Exporter？"
MSG_NODE_EXPORTER_UNINSTALLING="正在卸载 Node Exporter..."
MSG_NODE_EXPORTER_UNINSTALLED="Node Exporter 已卸载"
MSG_NODE_EXPORTER_UNINSTALL_FAILED="Node Exporter 卸载失败"
MSG_NODE_EXPORTER_NOT_INSTALLED="Node Exporter 未安装"
MSG_NODE_EXPORTER_STATUS_CHECKING="正在检查 Node Exporter 状态..."
MSG_NODE_EXPORTER_STATUS_RUNNING="Node Exporter 服务运行中"
MSG_NODE_EXPORTER_STATUS_NOT_RUNNING="Node Exporter 服务未运行"
MSG_NODE_EXPORTER_CONFIG_WRITTEN="Node Exporter 安全基线已写入（systemd 加固）"
MSG_NODE_EXPORTER_CONFIG_EXISTS="Node Exporter 配置已存在，已备份并保留现有配置"
MSG_NODE_EXPORTER_CONFIG_MISSING="Node Exporter 安全基线未应用"
MSG_NODE_EXPORTER_BACKUP_CONFIG="备份 Node Exporter 配置"
MSG_NODE_EXPORTER_ENABLE_FAILED="Node Exporter 服务启用/启动失败"
MSG_NODE_EXPORTER_MENU_TITLE="Node Exporter 监控采集"
MSG_NODE_EXPORTER_MENU_INSTALL="[1] 安装 Node Exporter"
MSG_NODE_EXPORTER_MENU_UNINSTALL="[2] 卸载 Node Exporter"
MSG_NODE_EXPORTER_MENU_STATUS="[3] 查看 Node Exporter 状态"
MSG_NODE_EXPORTER_MENU_BACK="[0] 返回"

# Prometheus (Monitoring)
MSG_PROMETHEUS_TITLE="Prometheus 监控"
MSG_PROMETHEUS_INSTALLING="正在安装 Prometheus..."
MSG_PROMETHEUS_INSTALLED="Prometheus 安装完成"
MSG_PROMETHEUS_ALREADY="Prometheus 已安装，跳过"
MSG_PROMETHEUS_FAILED="Prometheus 安装失败"
MSG_PROMETHEUS_CANCELLED="Prometheus 操作已取消"
MSG_PROMETHEUS_CONFIRM="确认安装 Prometheus？"
MSG_PROMETHEUS_CONFIRM_UNINSTALL="确认卸载 Prometheus？"
MSG_PROMETHEUS_UNINSTALLING="正在卸载 Prometheus..."
MSG_PROMETHEUS_UNINSTALLED="Prometheus 已卸载"
MSG_PROMETHEUS_UNINSTALL_FAILED="Prometheus 卸载失败"
MSG_PROMETHEUS_NOT_INSTALLED="Prometheus 未安装"
MSG_PROMETHEUS_STATUS_CHECKING="正在检查 Prometheus 状态..."
MSG_PROMETHEUS_STATUS_RUNNING="Prometheus 服务运行中"
MSG_PROMETHEUS_STATUS_NOT_RUNNING="Prometheus 服务未运行"
MSG_PROMETHEUS_CONFIG_WRITTEN="Prometheus 安全基线已写入（绑定 localhost）"
MSG_PROMETHEUS_CONFIG_EXISTS="Prometheus 配置已存在，已备份并保留现有配置"
MSG_PROMETHEUS_CONFIG_MISSING="Prometheus 安全基线未应用"
MSG_PROMETHEUS_BACKUP_CONFIG="备份 Prometheus 配置"
MSG_PROMETHEUS_ENABLE_FAILED="Prometheus 服务启用/启动失败"
MSG_PROMETHEUS_MENU_TITLE="Prometheus 监控"
MSG_PROMETHEUS_MENU_INSTALL="[1] 安装 Prometheus"
MSG_PROMETHEUS_MENU_UNINSTALL="[2] 卸载 Prometheus"
MSG_PROMETHEUS_MENU_STATUS="[3] 查看 Prometheus 状态"
MSG_PROMETHEUS_MENU_BACK="[0] 返回"

# Grafana (Visualization)
MSG_GRAFANA_TITLE="Grafana 可视化"
MSG_GRAFANA_INSTALLING="正在安装 Grafana..."
MSG_GRAFANA_INSTALLED="Grafana 安装完成"
MSG_GRAFANA_ALREADY="Grafana 已安装，跳过"
MSG_GRAFANA_FAILED="Grafana 安装失败"
MSG_GRAFANA_CANCELLED="Grafana 操作已取消"
MSG_GRAFANA_CONFIRM="确认安装 Grafana？"
MSG_GRAFANA_CONFIRM_UNINSTALL="确认卸载 Grafana？"
MSG_GRAFANA_UNINSTALLING="正在卸载 Grafana..."
MSG_GRAFANA_UNINSTALLED="Grafana 已卸载"
MSG_GRAFANA_UNINSTALL_FAILED="Grafana 卸载失败"
MSG_GRAFANA_NOT_INSTALLED="Grafana 未安装"
MSG_GRAFANA_STATUS_CHECKING="正在检查 Grafana 状态..."
MSG_GRAFANA_STATUS_RUNNING="Grafana 服务运行中"
MSG_GRAFANA_STATUS_NOT_RUNNING="Grafana 服务未运行"
MSG_GRAFANA_CONFIG_WRITTEN="Grafana 安全基线已写入（绑定 localhost + 禁用匿名访问）"
MSG_GRAFANA_CONFIG_EXISTS="Grafana 配置已存在，已备份并保留现有配置"
MSG_GRAFANA_CONFIG_MISSING="Grafana 安全基线未应用"
MSG_GRAFANA_BACKUP_CONFIG="备份 Grafana 配置"
MSG_GRAFANA_ENABLE_FAILED="Grafana 服务启用/启动失败"
MSG_GRAFANA_MENU_TITLE="Grafana 可视化"
MSG_GRAFANA_MENU_INSTALL="[1] 安装 Grafana"
MSG_GRAFANA_MENU_UNINSTALL="[2] 卸载 Grafana"
MSG_GRAFANA_MENU_STATUS="[3] 查看 Grafana 状态"
MSG_GRAFANA_MENU_BACK="[0] 返回"

# ═══════════════════════════════════════════
# 开发工具
# ═══════════════════════════════════════════

MSG_MAIN_MENU_DEV="[21] 开发工具"
MSG_MAIN_MENU_DEV_DESC="安装 Git、编辑器、运行时、编译工具链等开发环境"
MSG_DEV_MENU_TITLE="开发工具"
MSG_DEV_MENU_GIT="[1] Git"
MSG_DEV_MENU_EDITOR="[2] 编辑器"
MSG_DEV_MENU_RUNTIMES="[3] 运行时"
MSG_DEV_MENU_BUILD_TOOLCHAIN="[4] 编译工具链"
MSG_DEV_MENU_BACK="[0] 返回主菜单"

# Git (Version Control)
MSG_GIT_TITLE="Git 版本控制"
MSG_GIT_INSTALLING="正在安装并配置 Git..."
MSG_GIT_INSTALLED="Git 配置完成"
MSG_GIT_ALREADY="Git 已配置，跳过"
MSG_GIT_FAILED="Git 安装/配置失败"
MSG_GIT_CANCELLED="Git 操作已取消"
MSG_GIT_CONFIRM="确认安装并配置 Git？"
MSG_GIT_CONFIRM_UNINSTALL="确认撤销 Git 配置？"
MSG_GIT_UNINSTALLING="正在撤销 Git 配置..."
MSG_GIT_UNINSTALLED="Git 配置已撤销"
MSG_GIT_UNINSTALL_FAILED="Git 配置撤销失败"
MSG_GIT_NOT_INSTALLED="Git 未安装"
MSG_GIT_STATUS_CHECKING="正在检查 Git 状态..."
MSG_GIT_MENU_TITLE="Git 版本控制"
MSG_GIT_MENU_INSTALL="[1] 安装并配置 Git"
MSG_GIT_MENU_UNINSTALL="[2] 撤销 Git 配置"
MSG_GIT_MENU_STATUS="[3] 查看 Git 状态"
MSG_GIT_MENU_BACK="[0] 返回"
MSG_GIT_NAME_PROMPT="请输入 Git 用户名（user.name）"
MSG_GIT_EMAIL_PROMPT="请输入 Git 邮箱（user.email）"

# Editor (Vim/Nano)
MSG_EDITOR_TITLE="编辑器配置（Vim/Nano）"
MSG_EDITOR_INSTALLING="正在安装并配置编辑器..."
MSG_EDITOR_INSTALLED="编辑器配置完成"
MSG_EDITOR_ALREADY="编辑器已配置，跳过"
MSG_EDITOR_FAILED="编辑器安装/配置失败"
MSG_EDITOR_CANCELLED="编辑器操作已取消"
MSG_EDITOR_CONFIRM="确认安装并配置编辑器？"
MSG_EDITOR_CONFIRM_UNINSTALL="确认撤销编辑器配置？"
MSG_EDITOR_UNINSTALLING="正在撤销编辑器配置..."
MSG_EDITOR_UNINSTALLED="编辑器配置已撤销"
MSG_EDITOR_UNINSTALL_FAILED="编辑器配置撤销失败"
MSG_EDITOR_NOT_INSTALLED="编辑器未安装"
MSG_EDITOR_STATUS_CHECKING="正在检查编辑器状态..."
MSG_EDITOR_MENU_TITLE="编辑器配置（Vim/Nano）"
MSG_EDITOR_MENU_INSTALL="[1] 安装并配置编辑器"
MSG_EDITOR_MENU_UNINSTALL="[2] 撤销编辑器配置"
MSG_EDITOR_MENU_STATUS="[3] 查看编辑器状态"
MSG_EDITOR_MENU_BACK="[0] 返回"

# Runtimes (Node/Python/Go)
MSG_RUNTIMES_TITLE="编程语言运行时"
MSG_RUNTIMES_INSTALLING="正在安装语言运行时..."
MSG_RUNTIMES_INSTALLED="运行时安装完成"
MSG_RUNTIMES_ALREADY="运行时已安装，跳过"
MSG_RUNTIMES_FAILED="运行时安装失败"
MSG_RUNTIMES_CANCELLED="运行时操作已取消"
MSG_RUNTIMES_CONFIRM="确认安装 Node.js / Python / Go 运行时？"
MSG_RUNTIMES_CONFIRM_UNINSTALL="确认卸载运行时？"
MSG_RUNTIMES_UNINSTALLING="正在卸载运行时..."
MSG_RUNTIMES_UNINSTALLED="运行时已卸载"
MSG_RUNTIMES_UNINSTALL_FAILED="运行时卸载失败"
MSG_RUNTIMES_NOT_INSTALLED="运行时未安装"
MSG_RUNTIMES_STATUS_CHECKING="正在检查运行时状态..."
MSG_RUNTIMES_MENU_TITLE="编程语言运行时"
MSG_RUNTIMES_MENU_INSTALL="[1] 安装运行时"
MSG_RUNTIMES_MENU_UNINSTALL="[2] 卸载运行时"
MSG_RUNTIMES_MENU_STATUS="[3] 查看运行时状态"
MSG_RUNTIMES_MENU_BACK="[0] 返回"

# Build Toolchain (gcc/make/cmake)
MSG_BUILD_TOOLCHAIN_TITLE="编译工具链"
MSG_BUILD_TOOLCHAIN_INSTALLING="正在安装编译工具链..."
MSG_BUILD_TOOLCHAIN_INSTALLED="编译工具链安装完成"
MSG_BUILD_TOOLCHAIN_ALREADY="编译工具链已安装，跳过"
MSG_BUILD_TOOLCHAIN_FAILED="编译工具链安装失败"
MSG_BUILD_TOOLCHAIN_CANCELLED="编译工具链操作已取消"
MSG_BUILD_TOOLCHAIN_CONFIRM="确认安装编译工具链（gcc/make/cmake）？"
MSG_BUILD_TOOLCHAIN_CONFIRM_UNINSTALL="确认卸载编译工具链？"
MSG_BUILD_TOOLCHAIN_UNINSTALLING="正在卸载编译工具链..."
MSG_BUILD_TOOLCHAIN_UNINSTALLED="编译工具链已卸载"
MSG_BUILD_TOOLCHAIN_UNINSTALL_FAILED="编译工具链卸载失败"
MSG_BUILD_TOOLCHAIN_NOT_INSTALLED="编译工具链未安装"
MSG_BUILD_TOOLCHAIN_STATUS_CHECKING="正在检查编译工具链状态..."
MSG_BUILD_TOOLCHAIN_MENU_TITLE="编译工具链"
MSG_BUILD_TOOLCHAIN_MENU_INSTALL="[1] 安装编译工具链"
MSG_BUILD_TOOLCHAIN_MENU_UNINSTALL="[2] 卸载编译工具链"
MSG_BUILD_TOOLCHAIN_MENU_STATUS="[3] 查看编译工具链状态"
MSG_BUILD_TOOLCHAIN_MENU_BACK="[0] 返回"
MSG_BUILD_TOOLCHAIN_UNINSTALL_WARN="移除 build-essential 可能影响依赖它的其他软件包（尽力卸载）"

# ═══════════════════════════════════════════
# 服务器软件（消息队列）
# ═══════════════════════════════════════════

MSG_SERVER_MENU_RABBITMQ="[10] RabbitMQ"

# RabbitMQ (Message Queue)
MSG_RABBITMQ_TITLE="RabbitMQ 消息队列"
MSG_RABBITMQ_INSTALLING="正在安装 RabbitMQ..."
MSG_RABBITMQ_INSTALLED="RabbitMQ 安装完成"
MSG_RABBITMQ_ALREADY="RabbitMQ 已安装，跳过"
MSG_RABBITMQ_FAILED="RabbitMQ 安装失败"
MSG_RABBITMQ_CANCELLED="RabbitMQ 操作已取消"
MSG_RABBITMQ_CONFIRM="确认安装 RabbitMQ？"
MSG_RABBITMQ_CONFIRM_UNINSTALL="确认卸载 RabbitMQ？"
MSG_RABBITMQ_UNINSTALLING="正在卸载 RabbitMQ..."
MSG_RABBITMQ_UNINSTALLED="RabbitMQ 已卸载"
MSG_RABBITMQ_UNINSTALL_FAILED="RabbitMQ 卸载失败"
MSG_RABBITMQ_NOT_INSTALLED="RabbitMQ 未安装"
MSG_RABBITMQ_STATUS_CHECKING="正在检查 RabbitMQ 状态..."
MSG_RABBITMQ_STATUS_RUNNING="RabbitMQ 服务运行中"
MSG_RABBITMQ_STATUS_NOT_RUNNING="RabbitMQ 服务未运行"
MSG_RABBITMQ_CONFIG_WRITTEN="RabbitMQ 安全基线已应用（删除默认 guest 账号）"
MSG_RABBITMQ_CONFIG_EXISTS="RabbitMQ 已完成安全初始化，跳过"
MSG_RABBITMQ_CONFIG_MISSING="RabbitMQ 安全基线未应用"
MSG_RABBITMQ_BACKUP_CONFIG="备份 RabbitMQ 配置"
MSG_RABBITMQ_ENABLE_FAILED="RabbitMQ 服务启用/启动失败"
MSG_RABBITMQ_MENU_TITLE="RabbitMQ 消息队列"
MSG_RABBITMQ_MENU_INSTALL="[1] 安装 RabbitMQ"
MSG_RABBITMQ_MENU_UNINSTALL="[2] 卸载 RabbitMQ"
MSG_RABBITMQ_MENU_STATUS="[3] 查看 RabbitMQ 状态"
MSG_RABBITMQ_MENU_BACK="[0] 返回"

# ═══════════════════════════════════════════
# check.sh CIS/STIG 合规扫描器（独立 CLI）
# ═══════════════════════════════════════════

MSG_CHECK_TITLE="CIS/STIG 合规扫描"
MSG_CHECK_USAGE="用法：bash scripts/utils/check.sh [选项]"
MSG_CHECK_OPTIONS="选项："
MSG_CHECK_OPT_JSON="  --json                         输出 JSON 格式结果（stdout 仅 JSON）"
MSG_CHECK_OPT_SECTION="  --section <ssh|sudo|log|kernel>   仅扫描指定节（可重复指定）"
MSG_CHECK_OPT_HELP="  --help, -h                    显示此帮助"
MSG_CHECK_EXAMPLES="示例："
MSG_CHECK_EXAMPLE_ALL="  bash scripts/utils/check.sh                 # 扫描全部节"
MSG_CHECK_EXAMPLE_SECTION="  bash scripts/utils/check.sh --section ssh    # 仅扫描 SSH 节"
MSG_CHECK_EXAMPLE_JSON="  bash scripts/utils/check.sh --json           # JSON 输出"
MSG_CHECK_EXIT_HINT="退出码：0=全部通过  1=存在未通过项  2=参数错误"

MSG_CHECK_PASS="PASS"
MSG_CHECK_FAIL="FAIL"
MSG_CHECK_SECTION_LABEL="节"
MSG_CHECK_ITEM_LABEL="检查项"
MSG_CHECK_STATUS_LABEL="状态"
MSG_CHECK_DETAIL_LABEL="说明"

MSG_CHECK_SECTION_SSH="SSH"
MSG_CHECK_SECTION_SUDO="sudo"
MSG_CHECK_SECTION_LOG="日志"
MSG_CHECK_SECTION_KERNEL="内核"

MSG_CHECK_SSH_PORT="SSH 端口非默认"
MSG_CHECK_SSH_ROOT="禁止 root 登录"
MSG_CHECK_SSH_PASSWD="禁止密码登录"
MSG_CHECK_SUDO_NOPASSWD="无 NOPASSWD 配置"
MSG_CHECK_SUDO_PERMS="sudoers.d 文件权限 ≤ 0440"
MSG_CHECK_SUDO_DROPIN="sudo 加固 drop-in 存在"
MSG_CHECK_LOG_STORAGE="journald 持久化 Storage=persistent"
MSG_CHECK_LOG_SYSTEMMAXUSE="journald 大小限制 SystemMaxUse"
MSG_CHECK_LOG_SUDO_PERMS="sudo 日志权限 root:root 0640"
MSG_CHECK_KERNEL_CONF="sysctl 加固文件存在"

MSG_CHECK_SSH_PORT_PASS="当前端口：%s（非默认 22）"
MSG_CHECK_SSH_PORT_FAIL="端口仍为默认 22"
MSG_CHECK_SSH_ROOT_PASS="PermitRootLogin 已设为 no"
MSG_CHECK_SSH_ROOT_FAIL="PermitRootLogin 未设为 no（当前：%s）"
MSG_CHECK_SSH_PASSWD_PASS="PasswordAuthentication 已设为 no"
MSG_CHECK_SSH_PASSWD_FAIL="PasswordAuthentication 未设为 no（当前：%s）"

MSG_CHECK_SUDO_NOPASSWD_PASS="sudoers.d 下未发现 NOPASSWD"
MSG_CHECK_SUDO_NOPASSWD_FAIL="sudoers.d 下发现 NOPASSWD 配置：%s"
MSG_CHECK_SUDO_PERMS_PASS="sudoers.d 文件权限合规"
MSG_CHECK_SUDO_PERMS_FAIL="sudoers.d 存在权限过宽文件：%s"
MSG_CHECK_SUDO_DROPIN_PASS="加固 drop-in 存在"
MSG_CHECK_SUDO_DROPIN_FAIL="加固 drop-in 不存在：%s"

MSG_CHECK_LOG_STORAGE_PASS="Storage=persistent 已配置"
MSG_CHECK_LOG_STORAGE_FAIL="journald drop-in 未配置 Storage=persistent"
MSG_CHECK_LOG_SYSTEMMAXUSE_PASS="SystemMaxUse 已配置"
MSG_CHECK_LOG_SYSTEMMAXUSE_FAIL="journald drop-in 未配置 SystemMaxUse"
MSG_CHECK_LOG_SUDO_PERMS_PASS="sudo 日志权限 root:root 0640"
MSG_CHECK_LOG_SUDO_PERMS_FAIL="sudo 日志权限异常（owner:%s mode:%s）"

MSG_CHECK_KERNEL_CONF_PASS="sysctl 加固文件存在"
MSG_CHECK_KERNEL_CONF_FAIL="sysctl 加固文件不存在：%s"

MSG_CHECK_SUMMARY="检查结果"
MSG_CHECK_ALL_PASS="全部通过（%s/%s）"
MSG_CHECK_HAS_FAIL="存在未通过项（%s/%s）"

MSG_CHECK_ERR_UNKNOWN_ARG="错误：未知参数：%s"
MSG_CHECK_ERR_INVALID_SECTION="错误：无效的检查节：%s（可选：ssh|sudo|log|kernel）"
MSG_CHECK_ERR_SECTION_VALUE="错误：--section 需要指定值（可选：ssh|sudo|log|kernel）"

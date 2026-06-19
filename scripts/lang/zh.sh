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

MSG_FW_START="开始防火墙配置..."
MSG_FW_COMING_SOON="防火墙功能开发中，将在 v0.2 版本实现"

# ═══════════════════════════════════════════
# Fail2Ban
# ═══════════════════════════════════════════

MSG_F2B_START="开始 Fail2Ban 配置..."
MSG_F2B_COMING_SOON="Fail2Ban 功能开发中，将在 v0.2 版本实现"

# ═══════════════════════════════════════════
# 用户管理
# ═══════════════════════════════════════════

MSG_USER_START="开始用户管理..."
MSG_USER_COMING_SOON="用户管理功能开发中，将在 v0.3 版本实现"

# ═══════════════════════════════════════════
# 内核加固
# ═══════════════════════════════════════════

MSG_KERNEL_START="开始内核安全加固..."
MSG_KERNEL_COMING_SOON="内核加固功能开发中，将在 v0.3 版本实现"

# ═══════════════════════════════════════════
# 报告
# ═══════════════════════════════════════════

MSG_REPORT_TITLE="安全加固完成报告"
MSG_REPORT_SYSTEM="系统信息"
MSG_REPORT_TASKS="完成的任务"
MSG_REPORT_CONFIGS="修改的配置文件"
MSG_REPORT_WARNINGS="重要提醒"
MSG_REPORT_SAVED="报告已保存到"

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

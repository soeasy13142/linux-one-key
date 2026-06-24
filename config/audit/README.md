# Audit Config Templates

auditd 审计框架配置模板。

## 文件列表

| 文件 | 用途 |
|------|------|
| `audit.rules` | 审计规则模板（full 级别，最全面） |
| `auditd.conf` | auditd 主配置模板 |

## audit.rules

审计规则模板，展示 `full` 级别的完整规则集。实际运行时 `audit.sh` 支持 3 个级别：

| 级别 | 监控范围 |
|------|----------|
| **basic** | 身份认证文件、SSH 配置、sudo 命令 |
| **standard** | basic + 网络配置、cron、日志防篡改、启动脚本 |
| **full** | standard + 权限变更、命令执行、内核模块、时间修改、挂载、文件删除 |

本模板展示的是 `full` 级别。`audit.sh` 默认生成 `standard` 级别。

## auditd.conf

auditd 守护进程主配置模板，包含：

- 日志文件路径和格式
- 日志轮转策略（大小、份数）
- 磁盘空间告警阈值
- 网络监听配置

## 使用方式

这些模板仅作参考。实际配置由 `scripts/security/audit.sh` 的 `run_audit_wizard()` 根据用户选择动态生成。

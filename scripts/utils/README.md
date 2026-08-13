# Utility Scripts

通用工具脚本目录。

## 状态

- ✅ **check.sh** — 已实现（CIS/STIG 合规扫描器，独立 CLI）
- ⬜ backup / rollback — 核心逻辑在 `scripts/base/backup.sh` / `scripts/base/rollback.sh`

## 目录结构

```
utils/
├── check.sh        # CIS/STIG 合规扫描器（独立 CLI，只读判定）
└── README.md
```

## check.sh — CIS/STIG 合规扫描器

独立命令行工具，只读解析配置文件并输出 PASS/FAIL 结果，**不修改系统**。零耦合
`dashboard.sh` 与 `scripts/security/*` 模块（仅复用 `scripts/base/utils.sh` 的
`get_ssh_config` / `load_lang`）。

### CLI 接口

```
bash scripts/utils/check.sh [--json] [--section ssh|sudo|log|kernel] [--help]
```

| 选项 | 说明 |
|------|------|
| `--json` | 输出 JSON 数组（每项 `{section, id, status, detail}`），stdout 仅 JSON |
| `--section <ssh\|sudo\|log\|kernel>` | 仅扫描指定节，可重复指定；缺省扫描全部节 |
| `--help`, `-h` | 显示用法说明 |

### exit code 语义

| 退出码 | 含义 |
|--------|------|
| 0 | 全部检查项通过 |
| 1 | 存在未通过项（FAIL） |
| 2 | 参数错误 |

### 检查项

| 节 | 检查内容 |
|----|----------|
| ssh | Port ≠ 22、PermitRootLogin no、PasswordAuthentication no（读 `/etc/ssh/sshd_config`） |
| sudo | `/etc/sudoers.d/` 下无 NOPASSWD、文件权限 ≤ 0440、加固 drop-in 存在 |
| log | journald `Storage=persistent`、`SystemMaxUse` 存在、`/var/log/sudo.log` 权限 root:root 0640 |
| kernel | sysctl 加固文件 `/etc/sysctl.d/99-hardening.conf` 存在 |

路径均可通过环境变量覆盖（`CHECK_SSH_CONFIG`、`CHECK_SUDOERS_DIR`、
`CHECK_SUDOERS_DROPIN`、`CHECK_JOURNALD_DROPIN`、`CHECK_SUDO_LOG`、
`CHECK_SYSCTL_CONF`），便于测试与自定义。

### 示例

```bash
# 扫描全部节（终端表格）
bash scripts/utils/check.sh

# 仅扫描 SSH 节
bash scripts/utils/check.sh --section ssh

# JSON 输出（供脚本/监控消费）
bash scripts/utils/check.sh --json

# 管道给 jq
bash scripts/utils/check.sh --json | jq -r '.[] | select(.status=="FAIL") | .id'
```

## 注意

基础工具函数已在 `scripts/base/utils.sh` 中实现，此目录用于更高级的工具脚本。

# Language Files

国际化（i18n）语言文件目录。

## 文件列表

| 文件 | 语言 | 说明 |
|------|------|------|
| `zh.sh` | 中文（简体） | 默认语言 |
| `en.sh` | 英文 | 备选语言 |

## 工作原理

语言文件通过 `scripts/base/utils.sh` 中的 `load_lang()` 函数加载：

```bash
# 设置语言（默认 zh）
LANG_CODE="${LANG_CODE:-zh}"

# 加载对应语言文件
source "${SCRIPT_DIR}/scripts/lang/${LANG_CODE}.sh"
```

所有用户可见的字符串都定义为 `MSG_*` 变量，在脚本中通过 `${MSG_XXX}` 引用。

## 翻译键命名规则

```
MSG_<模块>_<功能>_<描述>
```

示例：
- `MSG_SSH_PORT_TITLE` — SSH 端口修改标题
- `MSG_FIREWALL_INSTALL_DONE` — 防火墙安装完成
- `MSG_FAIL2BAN_BANTIME_PROMPT` — Fail2Ban 封禁时间提示
- `MSG_AUDIT_RULES_BASIC` — 审计规则-基础级别

## 翻译覆盖范围

| 模块 | 翻译键数量 |
|------|-----------|
| 通用（欢迎、确认、退出等） | ~20 |
| 系统检测 | ~15 |
| SSH 安全 | ~40 |
| 防火墙 | ~30 |
| Fail2Ban | ~35 |
| 审计日志 | ~40 |
| 主菜单 / 向导 | ~30 |
| 报告 | ~15 |

## 添加新语言

1. 复制 `zh.sh` 为新文件（如 `ja.sh`）
2. 翻译所有 `MSG_*` 变量的值
3. 设置 `LANG_CODE="ja"` 使用新语言

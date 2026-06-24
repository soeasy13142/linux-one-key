# Base Modules

基础框架模块，提供所有其他脚本依赖的核心功能。

## 文件列表

| 文件 | 用途 | 说明 |
|------|------|------|
| `utils.sh` | 通用工具函数库 | 颜色、日志、交互、备份、SSH 配置、网络、错误处理 |
| `detect.sh` | 系统环境检测 | OS、架构、权限、包管理器、网络 |
| `init.sh` | 系统初始化 | 目录创建、时区设置、系统更新、基础工具安装 |
| `report.sh` | 安全加固报告生成 | 动态生成报告，按执行模块输出 |

## 模块说明

### utils.sh

所有脚本的基础依赖，提供：

- **颜色定义**: `RED`, `GREEN`, `YELLOW`, `BLUE`, `CYAN`, `BOLD`, `NC`
- **日志函数**: `log_info()`, `log_success()`, `log_warn()`, `log_error()`, `log_step()`, `log_title()`, `log_debug()`
- **交互函数**: `confirm()`, `press_enter()`, `prompt_input()`, `prompt_password()`
- **备份函数**: `backup_file()`, `restore_file()`
- **SSH 配置**: `set_ssh_config()`, `get_ssh_config()`, `get_ssh_port()`
- **系统服务**: `restart_service()`, `check_service()`
- **网络工具**: `check_port_in_use()`, `check_network()`
- **错误处理**: `error_handler()`, `setup_error_trap()`
- **工具函数**: `check_root()`, `command_exists()`, `get_os_type()`, `get_os_version()`
- **随机端口**: `generate_random_port()`
- **回滚保护**: `schedule_rollback()`, `cancel_scheduled_task()`

### detect.sh

系统环境自动检测，检测结果存储在全局变量中：

- `DETECTED_OS` — 操作系统类型（ubuntu/debian/centos/rocky/almalinux/fedora）
- `DETECTED_OS_VERSION` — 系统版本号
- `DETECTED_ARCH` — 系统架构（amd64/arm64）
- `DETECTED_PKG_MANAGER` — 包管理器（apt/dnf/yum）
- `DETECTED_IS_ROOT` — 是否为 root 用户
- `DETECTED_NETWORK_OK` — 网络是否可用

支持的查询函数：`get_detected_os()`, `get_detected_arch()`, `is_root()`, `is_network_ok()` 等。

### init.sh

系统初始化流程：

1. 创建日志、备份、报告目录
2. 设置系统时区（默认 Asia/Shanghai）
3. 更新系统安全补丁
4. 安装基础工具（curl, wget, vim, unzip）

### report.sh

动态生成安全加固报告，根据实际执行的模块输出对应内容：

- 系统信息（OS、架构、用户、主机名）
- 各模块执行状态（SSH、防火墙、Fail2Ban、审计日志）
- 修改的配置文件列表
- 安全警告提示

## 依赖关系

```
utils.sh (无依赖)
    ↑
detect.sh → utils.sh
    ↑
init.sh → utils.sh + detect.sh
    ↑
report.sh → utils.sh + detect.sh
```

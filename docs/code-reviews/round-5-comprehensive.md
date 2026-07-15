---
title: "Code Review Round 5 — 分模块全项目综合报告"
created: 2026-07-15
status: done
source: "6 组并行 SubAgent 审查（基础框架 / SSH+防火墙 / 系统加固 / 审计+服务+K3s / 主入口+语言 / 测试+配置+CI）"
topic: "code-review"
---

# Code Review Round 5 — 综合报告

## 审查范围

以 **6 组分模块并行审查**方式覆盖全项目 8495 行脚本 + 2202 行测试 + 3491 行 Docker/CI：

| 审查组 | 文件 | 行数 |
|--------|------|------|
| A - 基础框架 | utils.sh, detect.sh, init.sh, report.sh | 1292 |
| B - SSH+防火墙 | ssh.sh, firewall.sh, fail2ban.sh | 1529 |
| C - 系统加固 | kernel.sh, filesystem.sh, users.sh | 1205 |
| D - 审计+服务+K3s | audit.sh, services.sh, k3s.sh + config 模板 | 1600+ |
| E - 主入口+语言 | install.sh(1352), zh.sh(888), en.sh(888) | 3128 |
| F - 测试+配置+CI | 14 bats, config/, docker/, 3 workflows | ~5700 |

审查维度：正确性 / 安全 / 健壮性 / 可维护性 / 跨发行版兼容 / i18n 完整性 / 测试质量

> 各组详细审查报告见 `docs/code-reviews/group-b-ssh-firewall-fail2ban.md`（Group B）

---

## 汇总统计

| 审查组 | CRITICAL | HIGH | MEDIUM | LOW | 合计 |
|--------|----------|------|--------|-----|------|
| A - 基础框架 | 0 | 3 | 9 | 8 | **20** |
| B - SSH+防火墙 | 0 | 3 | 7 | 9 | **19** |
| C - 系统加固 | 0 | 3 | 6 | 7 | **16** |
| D - 审计+服务+K3s | 0 | 2 | 6 | 5 | **13** |
| E - 主入口+语言 | 0 | **7** | 6 | 8 | **21** |
| F - 测试+配置+CI | 0 | 2 | 12 | 12 | **26** |
| **合计** | **0** | **20** | **46** | **49** | **115** |

> **对比 Round 4**: 4 CRITICAL + 22 HIGH → **0 CRITICAL + 20 HIGH**（CRITICAL 清零，HIGH 略有下降，部分 HIGH 是 Round 4 未覆盖的 i18n 维度）

---

## CRITICAL（0 个）

无严重问题。CRITICAL 清零。

---

## HIGH（20 个）

### 分组 A - 基础框架（3 个）

| # | 文件 | 行 | 分类 | 问题 | 建议 |
|---|------|----|------|------|------|
| A-H1 | utils.sh | 323-328 | 正确性 | `set_ssh_config` 中 value 未转义 sed 特殊字符（`|`, `&`, `\1`），传入自定义 SSH 端口时可能损坏 config | 通过 `${value//|/\\|}` 转义 sed 分隔符，或改用 awk |
| A-H2 | utils.sh | 574-576 | 健壮性 | `cancel_scheduled_task` 在 `/proc` 不可用时（容器环境）跳过 PID 验证直接 kill 任何进程 | 添加 `/proc` 可用性检查，或移除 `-z` 无条件跳过分支 |
| A-H3 | init.sh | 51-52 | 正确性 | `apt-get upgrade` 升级所有包而非仅安全更新，与函数名 `update_system_packages` 和注释不符；而 yum/dnf 分支正确使用 `--security` | 更新注释为"全量升级（apt 不支持仅安全更新）"或实现 `unattended-upgrades` 方案 |

### 分组 B - SSH+防火墙（3 个）

| # | 文件 | 行 | 分类 | 问题 | 建议 |
|---|------|----|------|------|------|
| B-H1 | ssh.sh | 232 | 安全 | 回退路径 `ssh-keygen -N "${passphrase}"` 将密码暴露在 `/proc/PID/cmdline` 中 | 添加警告并避免在 -N 参数中传递密码 |
| B-H2 | ssh.sh | 340 | 正确性 | `_has_valid_ssh_key` 正则不匹配 `sk-ecdsa-sha2-nistp256@openssh.com` FIDO/U2F 密钥类型 | 添加 `sk-ecdsa-sha2` 到正则 |
| B-H3 | ssh.sh | 707 (i18n) | 正确性 | `MSG_FIREWALL_SSH_PORT22_CLOSE` 始终显示 `sudo ufw deny 22/tcp`，firewalld 系统上用户看到错误命令 | 根据检测到的防火墙类型动态选择消息 |

### 分组 C - 系统加固（3 个）

| # | 文件 | 行 | 分类 | 问题 | 建议 |
|---|------|----|------|------|------|
| C-H1 | kernel.sh + hardening.conf | 92, 模板 | 安全 | 缺少 `fs.protected_hardlinks = 1` 和 `fs.protected_symlinks = 1`，可被 TOCTOU 竞争条件攻击利用 | 添加到 `config/sysctl/hardening.conf` 和 `_generate_sysctl_config()` |
| C-H2 | filesystem.sh | 213-215, 283, 406 | 健壮性 | `find / -xdev` 遍历整个根文件系统无超时/I/O 优先级控制，百万级文件服务器可能耗时 2-10+ 分钟 | 添加 `ionice -c 3` 和 `timeout 300` 保护 |
| C-H3 | users.sh | 84-124, 340-348 | 可维护性 | `create_admin_user()` 和 `run_users_wizard()` 中存在重复的用户创建逻辑，修复需同步两处 | 重构 `run_users_wizard()` 调用 `create_admin_user()` 而非复制代码 |

### 分组 D - 审计+服务+K3s（2 个）

| # | 文件 | 行 | 分类 | 问题 | 建议 |
|---|------|----|------|------|------|
| D-H1 | audit.sh | 210 | 正确性 | 生成的规则文件含 `-e 2`（不可变模式），第二次运行 `auditctl -R` 因规则不可变而失败，错误信息"部分规则加载失败（可能与内核版本不兼容）"有误导性 | 从生成规则中移除 `-e 2`，或检测不可变模式后输出准确信息 |
| D-H2 | k3s.sh | 113 | 安全 | `--write-kubeconfig-mode 644` 使 kubeconfig 文件全局可读，包含集群管理员 token，任意本地用户可提取凭据 | 移除 `--write-kubeconfig-mode 644`（默认更严格），或使用 POSIX ACL |

### 分组 E - 主入口+语言（7 个）

| # | 文件 | 行 | 分类 | 问题 | 建议 |
|---|------|----|------|------|------|
| E-H1 | install.sh | 345-346 | 正确性 | PubkeyAuthentication 读取失败返回 "unknown" 时被计为通过（`ssh_ok += 1`），虚增安全评分 | 移除 `|| [[ "${ssh_pubkey}" == "unknown" ]]` 条件 |
| E-H2 | install.sh | 330-543 | 可维护性 | `show_system_status` 长达 202 行（4x 项目 50 行规范），8 个模块状态块完全重复 | 提取 `_check_module_status` 辅助函数，缩减至 ~45 行 |
| E-H3 | install.sh | 29-67, 179-188 | i18n | Bootstrap 和早期退出路径使用 14 条硬编码中文消息（i18n 未加载前） | 添加双语检测或同时输出英文+中文 |
| E-H4 | install.sh | 212-300 | i18n | 12 个 `echo "Error: Cannot find ..."` 在 load_lang 之后仍硬编码为英文，未使用 i18n | 替换为 `log_error "$(printf "${MSG_ERR_MODULE_NOT_FOUND}" ...)"` |
| E-H5 | install.sh | 683-985 | i18n | 13 个 `log_error` 调用在子菜单循环中使用硬编码英文（"SSH port change failed" 等） | 添加 MSG_ERROR_* i18n 键并在语言文件中定义 |
| E-H6 | install.sh | 1337-1338 | i18n | `main()` 中 `run_detection` 后两条警告硬编码英文 | 添加 MSG_WARN_DETECTION_WARNINGS 和 MSG_WARN_DETECTION_PARTIAL |
| E-H7 | install.sh | 349, 352, 356 | i18n | SSH 状态显示使用硬编码中文 `"端口 ${ssh_port}"` | 定义为带 `%s` 占位符的 i18n 键 |

### 分组 F - 测试+配置+CI（2 个）

| # | 文件 | 行 | 分类 | 问题 | 建议 |
|---|------|----|------|------|------|
| F-H1 | tests/unit/firewall.bats | 57-63 | 测试质量 | `deny_icmp` 测试仅断言输出包含 "UFW"，几乎无意义（仅 5 个测试覆盖整个防火墙模块） | 添加实际行为测试：mock `ufw`、验证防火墙类型检测条件下的不同行为 |
| F-H2 | config/audit/auditd.conf | 19 | 配置 | `flush = INCREMENTAL_ASYNC` 在 CentOS 7 (auditd 2.x) 上不被支持，静默回退默认值，降低日志完整性 | 改用 `flush = INCREMENTAL` 或添加 auditd 版本检查 |

---

## MEDIUM（46 个）

### 分组 A（9 个）

| # | 文件 | 行 | 问题 | 建议 |
|---|------|----|------|------|
| A-M1 | utils.sh | 334 | `echo "${key} ${value}"` 追加 SSH 配置：value 以 `-` 开头时 `echo` 可能解释为标志 | 改用 `printf '%s %s\n'` |
| A-M2 | utils.sh | 340 | grep 正则中 key 未转义，含 `.` / `+` 的键可能匹配意外行 | 使用 `grep -F` 固定字符串匹配 |
| A-M3 | utils.sh | 223-228 | `prompt_password` 从不 unset `_PROMPT_RESULT`，密码在 shell 生命周期内持久暴露 | 使用密码后 `unset _PROMPT_RESULT` |
| A-M4 | utils.sh | 550-565 | 后台回滚进程在父进程退出后成为孤儿，导致无提示后台回滚 | 添加 EXIT trap 调用 `cancel_scheduled_task` |
| A-M5 | detect.sh | 48 | `/etc/os-release` 中 `HOSTNAME` 非标准字段，使用了多余的子 shell | 直接 `$(hostname 2>/dev/null || echo "unknown")` |
| A-M6 | detect.sh | 165-169 | `run_detection` 中仅检查 detect_os/detect_network 的返回码，detect_arch 失败被静默忽略 | 未知架构时设置 has_error 或记录设计意图 |
| A-M7 | detect.sh | 143 | HTTP 回退检测需要 curl，在最小安装中可能尚未安装 | 检查 `command -v curl` 或回退使用 wget |
| A-M8 | init.sh | 132-137 | `setup_timezone` 依赖 timedatectl，在无 systemd 系统上失败 | 添加 `ln -sf /usr/share/zoneinfo/...` 回退 |
| A-M9 | init.sh | 132-137 / 154-168 | `init_directories` 失败后 init 继续执行（BACKUP_DIR 创建失败时 backup_file 也会失败） | 每一步后添加 `|| return 1` |

### 分组 B（7 个）

| # | 文件 | 行 | 问题 | 建议 |
|---|------|----|------|------|
| B-M1 | ssh.sh | 583, 676-687 | 4 个 i18n 键在 ssh.sh 中使用但在 zh.sh/en.sh 中缺失，用户看到空白警告 | 添加 `MSG_SSH_ROLLBACK_NO_BACKUP`, `MSG_SSH_WIZARD_EXTERNAL_MOD`, `MSG_SSH_WIZARD_ROLLBACK_OVERWRITE`, `MSG_SSH_RESTART_FAIL_ROLLBACK` |
| B-M2 | firewall.sh | 69-75 | `_get_firewall_type()` 仅根据 OS 名称映射，从不检查实际安装的防火墙 | 添加对 `command -v ufw` / `command -v firewalld` 的检查 |
| B-M3 | firewall.sh | 148-153 | `_firewalld_start()` 已定义但从未被调用（死代码） | 移除或修复调用路径 |
| B-M4 | firewall.sh | 179, 260 | `open_port()` 的 `$3` comment 参数 UFW 使用，firewalld 分支静默忽略（未声明 `$3`） | 在 firewalld 分支添加注释说明参数被忽略 |
| B-M5 | fail2ban.sh | 119-121 | Banaction 硬编码为 `firewallcmd-ipset` 无回退，firewalld 未运行时可能失败 | 回退到 `iptables-multiport` |
| B-M6 | fail2ban.sh | 94 | `SSH_SERVICE_NAME` 声明为 readonly 但从未引用 | 移除冗余变量或实际使用 |
| B-M7 | fail2ban.sh | 86 | 字符串拼接 i18n 模式（`前缀${变量}后缀`）对 RTL 语言脆弱，与项目 `{placeholder}` 惯例不一致 | 使用带 `%s` 占位符的完整 i18n 字符串 |

### 分组 C（6 个）

| # | 文件 | 行 | 问题 | 建议 |
|---|------|----|------|------|
| C-M1 | kernel.sh | 92 | `kernel.kptr_restrict = 2` 在 CentOS 7 < 7.3 上静默失败（内核未回传 value 2） | 添加到 `_verify_sysctl_params` 验证列表或添加内核版本检查 |
| C-M2 | kernel.sh | 191-195 | 两行 `echo` 顺序写入 blacklist 文件，中断时产生不完整文件 | 使用 heredoc 原子写入 |
| C-M3 | filesystem.sh | 20-28 | `/etc/shadow:640` 预期权限与 RHEL 家族 `000` 默认值冲突，更安全的 `000` 被标记为"权限不匹配" | 添加 distro-aware 权限检查，接受两种值 |
| C-M4 | users.sh | 68-77 | `_validate_password_strength()` 仅检查最小长度 8 位，`aaaaaaaa` 或 `12345678` 通过验证 | 可选字符类检查或使用 pwscore/cracklib-check（如有） |
| C-M5 | kernel.sh | 112-113 | `cp -a` 保留模板文件所有权，若模板为非 root 所有权则复制到 `/etc/sysctl.d/` 后属主错误 | 复制后添加 `chown root:root` |
| C-M6 | kernel.sh + hardening.conf | — | 缺少多项 CIS 推荐参数：`kernel.sysrq`, ARP 硬化, `fs.protected_*` 系列 | 对照 CIS Benchmark 补充参数 |

### 分组 D（6 个）

| # | 文件 | 行 | 问题 | 建议 |
|---|------|----|------|------|
| D-M1 | audit.sh | 137-138 | `execve` 全量审计在高负载服务器上可能每小时产生 GB 级日志，填满审计分区 | 选择"full"级别时添加磁盘空间警告 |
| D-M2 | audit.sh | 412-505 | `run_audit_wizard` 93 行超过项目 50 行规范 | 拆分为 `_select_audit_level()`, `_execute_audit_hardening()`, `_show_results()` |
| D-M3 | services.sh | 39-43 | 仅使用 systemd 发现服务，缺少 sysvinit 回退 | 添加 systemd 存在性检查和 `service --status-all` 回退 |
| D-M4 | services.sh | 101-180 | `_scan_listening_ports` 80 行含复杂 awk 逻辑，IPv6 解析脆弱 | 提取三个辅助函数：`_parse_ss_output()`, `_parse_netstat_output()`, `_parse_proc_net()` |
| D-M5 | k3s.sh | 112-113 | K3s 安装选项（`--write-kubeconfig-mode` 等）中未设置 `--bind-address`，API Server 默认绑定 `0.0.0.0:6443` 暴露到网络 | 添加 `--bind-address 127.0.0.1` |
| D-M6 | hardening.conf | 41 | `ip_forward=0` 会与 Docker/K3s 容器运行时冲突 | 添加注释警告，kernel.sh 中检测容器包时发出警告 |

### 分组 E（6 个）

| # | 文件 | 行 | 问题 | 建议 |
|---|------|----|------|------|
| E-M1 | install.sh | 774-1000 | 6 个模块的 `show_*_submenu` + `run_*_submenu_loop` 结构完全一致，~230 行代码重复 | 提取通用 `_run_generic_submenu_loop` 函数，参数化调用 |
| E-M2 | install.sh | 1077-1252 | `run_full_wizard` 151 行，9 个步骤完全重复相同模式 | 提取 `_run_wizard_step` 辅助函数，9 次调用 |
| E-M3 | install.sh | 196-305 | `load_dependencies` 96 行，13 个模块加载重复相同 5 行模式 | 定义 `MODULES` 列表循环加载（前 2 项特殊处理） |
| E-M4 | zh.sh / en.sh | 多处 | `%s` (printf) 与 `{param}` (braces) 占位符混用，跨模块 `printf`/参数展开调用不匹配时产生显示错误 | 全项目统一为 `printf %s`（POSIX 标准） |
| E-M5 | install.sh | 10, 152 | `set -u` 在 curl-pipe 检查完成后未重新启用，~1200 行代码中未定义变量静默展开为空 | bootstrap 检查后添加 `set -u` |
| E-M6 | install.sh | 1294 | 菜单选项 12 依赖 k3s.sh 定义的函数，加载失败时无优雅回退 | 添加函数存在性守卫 `type run_k3s_submenu_loop &>/dev/null` |

### 分组 F（12 个）

| # | 文件 | 行 | 问题 | 建议 |
|---|------|----|------|------|
| F-M1 | tests/unit/ssh.bats | 93 | `check_other_users` 测试依赖宿主系统 `/etc/passwd` 状态，非确定行为 | 在 `setup()` 中 mock `/etc/passwd` |
| F-M2 | tests/unit/k3s.bats | 35-43 | 7 个 `type` 检查合并到单个测试，首个失败后后续 6 个被隐藏 | 拆分为独立 `@test` 块 |
| F-M3 | tests/unit/k3s.bats | 113 | `PATH` 修改在 `teardown` 中未恢复（需确认 subprocess 隔离是否足够） | 将 PATH 修改移入 `command()` mock 函数内 |
| F-M4 | config/sysctl/hardening.conf | 58 | `kernel.kptr_restrict = 2` 隐藏 root 的内核指针，破坏 perf/bcc/SystemTap 等调试工具 | 默认使用 `1`，注释说明值 2 适用场景 |
| F-M5 | config/sysctl/hardening.conf | — | 缺少多项 CIS 推荐参数：`kernel.unprivileged_bpf_disabled`, `net.core.bpf_jit_enable`, ARP 硬化等 | 添加推荐参数 |
| F-M6 | tests/docker/lib/common.bash | 133 | `run_in_container` 在 `$(...)` 子 shell 中调用时产生双重输出 | 移除冗余 `echo "$output"` |
| F-M7 | tests/docker/lib/common.bash | 28-29 | `output`/`status` 全局变量在同进程并行调用中不安全 | 添加注释警告（当前并行安全因使用子进程） |
| F-M8 | tests/docker/lib/common.bash | 171-172 | `check_file_in_container` 将 grep pattern 未转义传入容器 | 使用 `printf '%q'` 转义 pattern |
| F-M9 | tests/docker/tests/phase2/security-check.bash | 61 | 全端口扫描 (1-65535) 在 CI 上慢且脆弱（30-90 秒） | 限制为 `--top-ports 100` 或常见端口 |
| F-M10 | tests/docker/images/rockylinux/*.Dockerfile | 16 | Rocky Linux 8/9 和 AlmaLinux 9 镜像依赖基础镜像预装的 `curl-minimal` 提供 curl 功能，未显式验证其可用性（基础镜像变更可能静默丢失 curl） | 添加注释说明依赖 `curl-minimal`，或添加 `RUN command -v curl` 断言 |
| F-M11 | .github/workflows/test.yml | 18-21 | ShellCheck 三步合一步，首个目录失败后停止运行后续检查 | 拆分为三步独立步骤 |
| F-M12 | .github/workflows/test.yml | 36 | Docker 测试 Job 无 `timeout-minutes` 设置，默认 360 分钟 | 添加 `timeout-minutes: 45` |

---

## LOW（49 个）

### 分组 A（8 个）
- A-L1: utils.sh:262 `backup_file` 缺少磁盘空间检查
- A-L2: utils.sh:616 `generate_random_port` 使用非加密随机源 `$RANDOM`
- A-L3: utils.sh:646 `log_debug` 在 `init_logging()` 前触发，排序问题
- A-L4: detect.sh:85 `armv7l`/`armv8l` 32 位 ARM 未被 case 覆盖
- A-L5: init.sh:157 时区硬编码 Asia/Shanghai
- A-L6: report.sh:152 SUID 扫描无超时
- A-L7: report.sh:55 使用 `whoami` 而非已存储的 `DETECTED_CURRENT_USER`
- A-L8: report.sh:63-123 模块状态读取重复模式可抽像

### 分组 B（9 个）
- B-L1: ssh.sh 空口令仍使用 `-N ""` 暴露在进程列表
- B-L2: ssh.sh `.pub` 文件缺失时 `auth_ok` 仍为 true
- B-L3: ssh.sh `current_user` 嵌入 awk 脚本（低风险注入）
- B-L4: ssh.sh:604 `ROLLBACK_DELAY / 60` 非整除时截断（原报告错误归属到 fail2ban.sh）
- B-L5: SSH/firewall/fail2ban 非 readonly 全局变量与项目约定不一致
- B-L6: firewall.sh 接口迁移错误静默抑制
- B-L7: firewall.sh `enable_firewall` firewalld 仅 reload 不显式 enable
- B-L8: fail2ban.sh 冗余 `sleep 1` 在轮询循环前
- B-L9: 三个模块均无本地 `setup_error_trap`

### 分组 C（7 个）
- C-L1: kernel.sh/filesystem.sh/users.sh 使用 `set -eo pipefail` 而非项目要求的 `-euo`
- C-L2: filesystem.sh SUID/SGID 使用两次 find 而非一次带 OR 条件
- C-L3: users.sh 未检查保留用户名（root/daemon/nobody 等）
- C-L4: users.sh 无用户创建失败后的清理回滚
- C-L5: filesystem.sh `/proc`/`/sys` 排除在使用 `-xdev` 后冗余
- C-L6: kernel.sh `DISABLED_MODULES` 未考虑 distro 特定模块名
- C-L7: kernel.sh `ip_forward = 0` 会被 Docker/Podman 运行时覆盖（需注释）

### 分组 D（5 个）
- D-L1: audit.sh:46 RHEL 上 `audit-libs` 是 `audit` 的依赖，可简化安装命令
- D-L2: services.sh:20-28 `UNNECESSARY_SERVICES` 未包含 `bluetooth`, `cups-browsed`, `autofs`, `nfs-server`
- D-L3: services.sh:103 `ss -tlnp` 在 SELinux 强制模式下无法读取进程信息（2>/dev/null 静默）
- D-L4: k3s.sh:133 固定 `sleep 3` 等待服务启动，慢系统不够快系统浪费
- D-L5: config/fail2ban/jail.local:24 仅显示 RHEL banaction 默认值，缺少 Debian 替代行

### 分组 E（8 个）
- E-L1: install.sh 1352 行超项目 800 行限制（约 69%）
- E-L2: install.sh:550-629 `show_main_menu` 74 行超 50 行限制
- E-L3: install.sh:1035 `find -printf` 是 GNU 扩展（当前目标发行版无问题）
- E-L4: install.sh:334,535-536 `|` 分隔符可能与标签文本冲突
- E-L5: install.sh:1308-1319 main() 中无显式 root 检查，非 root 用户在中途才看到错误
- E-L6: zh.sh/en.sh:139-145 "Report"/"Quick Hardening" 节注释无对应 i18n 键（空的占位节）
- E-L7: install.sh:1294 K3s 菜单选项缺少函数存在性守卫（related E-M6）
- E-L8: install.sh:639-650 输入 "00"/"01" 因前导零不匹配 case 模式

### 分组 F（12 个）
- F-L1: kernel.bats:34 基于 grep 的常量验证测试脆弱（reformatting 即 break）
- F-L2: services.bats:36 数组非空断言冗余（已存在精确数量检查）
- F-L3: parse-args.bats:43 行数阈值测量代码结构而非行为
- F-L4: menu.bats:62 grep-on-source 结构测试脆弱（但合理）
- F-L5: config/audit/audit.rules:73 缺少几项 CIS Level 2 规则
- F-L6: config/fail2ban/jail.local:21-23 已有 Debian 替代注释（banaction 行上方），可进一步显式化为条件模板
- F-L7: common.bash:292 7200 秒睡眠超时过长
- F-L8: tests/phase2/firewall.bash:108 firewalld 后台启动不影响容器生命周期
- F-L9: run-test.sh:43 `--distro` 参数验证可更严格
- F-L10: .github/workflows/test.yml:47 缺少 concurrency 取消设置
- F-L11: ~~.github/workflows/codeql.yml:22 CodeQL init 未指定 languages 可能检测不到 Bash~~ ✅ 已在 commit 490ab41 中有意移除显式语言矩阵，改用自动检测
- F-L12: .github/workflows/markdown-lint.yml:20 全局 npm install 增加不必要的开销

---

## 按模块分类发现数量

| 模块 | CRITICAL | HIGH | MEDIUM | LOW | 合计 |
|------|----------|------|--------|-----|------|
| utils.sh | 0 | 2 | 4 | 3 | 9 |
| detect.sh | 0 | 0 | 3 | 1 | 4 |
| init.sh | 0 | 1 | 2 | 1 | 4 |
| report.sh | 0 | 0 | 0 | 3 | 3 |
| ssh.sh | 0 | 3 | 1 | 3 | 7 |
| firewall.sh | 0 | 0 | 3 | 2 | 5 |
| fail2ban.sh | 0 | 0 | 3 | 2 | 5 |
| kernel.sh | 0 | 1 | 3 | 2 | 6 |
| filesystem.sh | 0 | 1 | 1 | 2 | 4 |
| users.sh | 0 | 1 | 2 | 2 | 5 |
| audit.sh | 0 | 1 | 2 | 1 | 4 |
| services.sh | 0 | 0 | 2 | 2 | 4 |
| k3s.sh | 0 | 1 | 1 | 1 | 3 |
| install.sh | 0 | 5 | 4 | 5 | 14 |
| zh.sh/en.sh | 0 | 2 | 2 | 1 | 5 |
| tests/*.bats | 0 | 1 | 3 | 4 | 8 |
| config/模板 | 0 | 1 | 3 | 3 | 7 |
| Docker 框架 | 0 | 0 | 4 | 3 | 7 |
| CI workflows | 0 | 0 | 3 | 3 | 6 |

---

## 模式分析与趋势对比

### Round 4 → Round 5 趋势

| 级别 | Round 4 | Round 5 | 变化 |
|------|---------|---------|------|
| CRITICAL | 4 | 0 | ✅ 清零 |
| HIGH | 22 | 20 | → 基本持平 |
| MEDIUM | 41 | 46 | ↗ 略有增加 |
| LOW | 21 | 49 | ↗ 大幅增加（新维度：测试/i18n/Docker/CI） |
| **合计** | **88** | **115** | ↗ 总量增 30% |

### 核心发现

1. **CRITICAL 清零** ✅：前 4 轮发现的 CRITICAL 问题已全部修复
2. **i18n 成为主要薄弱环节**：20 个 HIGH 中有 7 个来自 i18n（Group E），install.sh 核心 UI 路径仍有多处硬编码消息
3. **可维护性退化**：install.sh 1352 行中 3 个大型函数（show_system_status 202 行、run_full_wizard 151 行、load_dependencies 96 行）存在严重 DRY 违规
4. **配置模板需加固**：hardening.conf 缺少多项 CIS 推荐参数、auditd.conf 使用不兼容的 flush 模式
5. **测试覆盖存在盲区**：firewall.bats 仅 5 个弱断言，Docker Phase 2 nmap 全端口扫描不必要地慢
6. **CI 配置可优化**：ShellCheck step 在首个目录失败后停止、CodeQL 未指定语言、缺少 timeout 和 concurrency 设置

### 推荐修复优先级

**Phase 1 — 高影响 / 低风险（可独立修复）：**
1. 添加 4 个缺失的 i18n 键（B-M1）→ 快速修复，目前用户看到空白
2. 修复 apt-get upgrade 问题（A-H3）→ 修改注释，非功能变更
3. 移除 k3s.sh `--write-kubeconfig-mode 644`（D-H2）→ 安全加固
4. 修复 CI 配置问题（F-M11/F-M12）→ 避免漏报

**Phase 2 — 正确性修复（需验证）：**
5. 修复 PubkeyAuthentication 评分虚增（E-H1）
6. 修复 set_ssh_config 的 sed 转义（A-H1）
7. 修复 cancel_scheduled_task /proc 绕过（A-H2）
8. 修复 audit.sh 不可变模式误导性错误（D-H1）

**Phase 3 — i18n 补齐（需协调 zh/en）：**
9. Install.sh 中 13+12+2 = 27 个硬编码消息替换为 i18n 键（E-H3~E-H7）
10. 统一 `%s` vs `{param}` 占位符约定（E-M4）

**Phase 4 — 架构改进（需计划）：**
11. install.sh 大型函数 DRY 重构（E-H2/E-M1/E-M2）
12. 添加缺失的 sysctl 参数（C-H1/C-M6）

---

## 结论

Round 5 共发现 **115 个问题（0 CRITICAL + 20 HIGH + 46 MEDIUM + 49 LOW）**。项目整体质量稳定，CRITICAL 已清零。主要风险集中在：

1. **i18n 完整性**（7 个 HIGH）— install.sh 核心 UI 路径仍有多处硬编码消息
2. **可维护性**（4 个 HIGH/MEDIUM）— install.sh 大型函数需 DRY 重构
3. **安全配置**（4 个 HIGH）— 包括 kubeconfig 权限、FIDO 密钥缺失、sed 注入、sysctl 缺少参数

无阻断性发布问题，但建议 v1.0 前至少修复所有 HIGH 级别问题。

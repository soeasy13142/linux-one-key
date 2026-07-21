---
created: 2026-07-12
updated: 2026-07-12
status: in-progress
title: Phase 1 Docker Test Implementation — 调试日志
topic: testing
---

# Docker 测试 Phase 1 调试日志

## 1. 概述

本文档记录 linux-one-key Phase 1 Docker 测试实施过程中遇到的**所有问题、根因、修复方法以及调试方法论**。

Phase 1 目标：在 **9 个 Linux 发行版 × 8 个安全模块** 的非特权 Docker 容器中，验证安全脚本输出正确的配置文件。

读者对象：后续参与测试开发的所有开发者（Phase 2、Phase 3 维护者）。本文档的目的是**让你不再踩我们踩过的坑**。

---

## 2. 架构概要

### 核心模式：单容器执行（Single-Container Pattern）

```
run_in_container ubuntu 22.04 "bash -c '... 全部步骤 ...'"
                                          │
                    ┌─────────────────────┼─────────────────────┐
                    │  1. 设置环境变量      │  2. 运行模块函数    │  3. 验证输出
                    │                     │                      │
                    │  export LOG_DIR     │  source scripts      │  echo 'CHECK_X=OK'
                    │  export BACKUP_DIR  │  run_module_func     │  echo 'CHECK_Y=FAIL'
                    └─────────────────────┴──────────────────────┘
```

关键设计决策：

| 决策 | 选择 | 原因 |
|------|------|------|
| 容器生命周期 | 单次 `docker run --rm` 执行全部测试步骤 | 避免跨容器状态丢失（文件、用户等） |
| 结果断言 | Sentinel Marker（`echo KEY=VAL`） | 结构化的 KEY=VAL 输出，解析稳定 |
| 容器挂载 | 项目目录 `:ro` 只读挂载 | 不改动源代码，保证测试可复现 |
| 镜像构建 | 运行时 `docker build`（幂等） | 无需预先准备镜像，CI 友好 |

### 测试矩阵

- **发行版**：Ubuntu 20.04 / 22.04 / 24.04, Debian 11 / 12, CentOS 7, Rocky Linux 8 / 9, AlmaLinux 9
- **模块**：SSH / Firewall / Fail2Ban / Audit / Users / Kernel / Filesystem / Services
- **合计**：9 × 8 = **72 个测试对**

---

## 3. 问题日志

### 3.1 子 Shell 变量丢失（Subshell Variable Loss）

- **问题**：`run_in_container` 在 `$(subshell)` 中调用时，内部设置的 `$output` / `$status` 变量丢失。
- **症状**：`result=$(run_in_container ...)` 后 `$output` 为空，调用方无法获取容器输出。
- **根因**：Bash 的 `$(...)` 在子 Shell 中执行，对全局变量的修改不影响父 Shell。
- **修复**：`run_in_container` 在函数末尾执行 `echo "$output"`，调用方通过 `result=$(run_in_container ...)` 捕获输出。`$output` / `$status` 保留供非子 Shell 场景使用（Bats 风格的兼容接口）。
- **影响范围**：全部 8 个模块测试脚本（均通过 `result=$(run_in_container ...)` 模式调用）。
- **发现方式**：首次编写 ssh.bash 时 `$output` 为空，调试添加 `echo "OUTPUT=${#output} chars"` 发现。

```bash
# 修复前（变量丢失）
run_in_container() { ...; output="$(cat tmpfile)"; }
result=$(run_in_container ubuntu 22.04 "cmd")
# result 为空，因为 $(subshell) 中的 output 不传回父 Shell

# 修复后（echo 输出）
run_in_container() { ...; output="$(cat tmpfile)"; echo "$output"; }
result=$(run_in_container ubuntu 22.04 "cmd")
# result 有内容 ✓
```

---

### 3.2 assert_fail 未绑定变量（assert_fail Unbound Variable）

- **问题**：`assert_fail` 函数在只有一个参数时因 `set -u` 报错退出。
- **症状**：`assert_fail "description"` → `line 179: $2: unbound variable`。
- **根因**：函数定义 `local detail="$2"`，`set -u` 下访问未传参的 `$2` 直接报错。
- **修复**：改为 `local detail="${2:-}"`，当 `$2` 未提供时默认为空字符串。
- **影响范围**：`lib/common.bash` 中 `assert_fail` 函数。
- **发现方式**：运行测试时容器内脚本因 `set -u` 报错终止，但外层未捕获到错误（`|| true` 掩盖了错误码）。

```bash
# 修复前
assert_fail() {
    local description="$1"
    local detail="$2"           # ← unbound variable crash
    ...
}

# 修复后
assert_fail() {
    local description="$1"
    local detail="${2:-}"       # ← 安全默认值
    ...
}
```

---

### 3.3 Bash -c 中 # 注释陷阱（Bash -c # Comment Trap）

- **问题**：`bash -c "..."` 字符串中的 `# comment` 导致后续所有命令被忽略。
- **症状**：容器内执行到 `# comment` 后，该行之后的所有命令静默不执行。
- **根因**：在 `bash -c "..."` 中，`#` 是注释起始符，后续整行（注意：是整行直到换行符）被忽略。如果 `#` 出现在一行中间且不在引号内，该行从 `#` 开始到行尾全部成为注释。
- **修复**：从 `bash -c` 字符串中**移除所有行内注释**。关键配置参数之前用单独一行说明，不要和内联命令放在一起。
- **影响范围**：所有模块测试脚本中的 `bash -c` 字符串。
- **发现方式**：某个模块的验证步骤总是不执行，定位到是 `# comment` 行将后续命令注释掉了。

```bash
# 修复前（疑似伪代码）
cmd='some_command && \
     # 这是一个注释
     echo CHECK=OK'           # ← # 之后的 echo 永远不会执行！

# 修复后
cmd='some_command && \
     echo CHECK=OK'           # ← 移除注释
```

---

### 3.4 容器状态丢失（Container State Loss）

- **问题**：每次 `run_in_container` 调用创建一个新的 `--rm` 容器，不使用相同的容器实例。
- **症状**：先调用创建用户，再调用验证用户 —— 第二个容器中用户不存在。调用安装包，再检查配置文件 —— 包未安装。
- **根因**：`docker run --rm` 每次创建全新容器，前一个容器的文件系统修改全部丢失。
- **修复**：将所有步骤合并到**一次** `run_in_container` 调用中：安装包 → 运行函数 → 输出验证标记（Sentinel Markers）→ 退出。测试脚本解析完整的 sentinel 输出来判断 PASS/FAIL。
- **影响范围**：全体模块测试脚本。
- **发现方式**：users.bash 第一步创建了用户，第二步检查 `id testadmin` 发现用户不存在，才意识到是不同容器。

```bash
# 修复前（状态丢失）
run_in_container ubuntu 22.04 "useradd testadmin"
# 退出容器，状态丢失
run_in_container ubuntu 22.04 "id testadmin"
# → id: 'testadmin': no such user  ✗

# 修复后（单容器模式）
result=$(run_in_container "$distro" "$version" \
    "set -euo pipefail && \
     export LOG_DIR=/tmp/log && ... && \
     useradd testadmin && \
     echo 'USER_CREATED' && \
     id testadmin && echo 'EXISTS_OK'")
# 一个容器执行全部步骤 ✓
```

---

### 3.5 BACKUP_DIR 陈旧的默认值（BACKUP_DIR Stale Default）

- **问题**：`BACKUP_DIR` 在 `LOG_DIR` 被覆盖之前就已经设置，使用了错误的基路径。
- **症状**：测试中设置 `export LOG_DIR=/tmp/log` 后，备份文件仍然被写入 `/var/log/linux-one-key/backups/`（没有写入权限，测试失败）。
- **根因**：`utils.sh` 在文件顶部（第 23-24 行）定义了：
  ```bash
  LOG_DIR="${LOG_DIR:-/var/log/linux-one-key}"
  BACKUP_DIR="${BACKUP_DIR:-${LOG_DIR}/backups}"
  ```
  如果 `LOG_DIR` 在 `source utils.sh` **之前**就被 export，则 `BACKUP_DIR` 会在 `utils.sh` 被 source 时立即求值——此时 `LOG_DIR` 已经被设为 `/tmp/log`，所以 `BACKUP_DIR` 正确；但如果 `LOG_DIR` 是在 `source utils.sh` **之后**才 export，则 `BACKUP_DIR` 已经用默认值 `/var/log/linux-one-key/backups` 初始化完毕。

- **修复**：在每个模块测试脚本中，**在 source utils.sh 之前**就先设置 `LOG_DIR` 和 `BACKUP_DIR` 为环境变量：
  ```bash
  export LOG_DIR=/tmp/log
  export BACKUP_DIR="${LOG_DIR}/backups"
  source /opt/linux-one-key/scripts/base/utils.sh
  ```
  保证 utils.sh 在初始化时使用正确的值。

- **影响范围**：全部 8 个模块测试脚本。
- **发现方式**：备份操作写入 `/var/log` 目录但容器内无写权限，backup 函数静默失败。

---

### 3.6 apt-get 缓存为空（apt-get Update Needed）

- **问题**：Debian/Ubuntu 容器内运行 `apt-get install` 失败。
- **症状**：`apt-get install -y ufw` → 错误提示包未找到或被跳过。
- **根因**：Docker 基础镜像的 apt 缓存是空的（`apt-get update` 未被调用过）。Debian `-slim` 镜像为减体积清空了 `/var/lib/apt/lists/`。
- **修复**：在需要安装包之前添加 `(apt-get update -qq 2>/dev/null || true)`。注意：`2>/dev/null` 避免输出干扰 sentinel 解析，`|| true` 防止 `set -e` 中断。
- **影响范围**：fail2ban.bash、audit.bash、firewall.bash（Debian/Ubuntu 发行版）。
- **发现方式**：firewall.bash 在 Ubuntu 容器中安装 ufw 时失败，查看错误日志发现是 apt 缓存为空。

```bash
# 修复前
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw 2>/dev/null
# → 失败，包索引为空

# 修复后
(apt-get update -qq 2>/dev/null || true) && \
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ufw 2>/dev/null
```

---

### 3.7 ufw.conf 不存在于全新安装（ufw.conf Not on Fresh Install）

- **问题**：测试检查 `/etc/ufw/ufw.conf` 作为 UFW 已安装的证据，但文件不存在。
- **症状**：UFW 安装成功，但 `ufw.conf` 文件不存在，测试标记为 FAIL。
- **根因**：`ufw.conf` 只在第一次 `ufw enable` 时创建。仅仅 `apt-get install ufw` 不会生成 `ufw.conf`。容器内通过包管理器安装后，`/etc/ufw/` 目录存在但 `ufw.conf` 文件不存在。
- **修复**：改为检查 `/etc/ufw/before.rules`（随包安装即存在）和 `which ufw`（二进制文件是否存在），替代对 `ufw.conf` 的检查。
- **影响范围**：firewall.bash 的 UFW 分支（Ubuntu/Debian 发行版）。
- **发现方式**：Ubuntu 20.04 测试中安装 ufw 后，UFW 配置检查全部标记 FAIL，排查发现 `ufw.conf` 文件缺失。

```bash
# 修复前
if [ -f /etc/ufw/ufw.conf ]; then echo "UFW_CONF=OK"; ...
# → 不存在的文件，总是 FAIL

# 修复后
if [ -f /etc/ufw/before.rules ]; then echo "UFW_BEFORE=OK"; ... && \
if which ufw >/dev/null 2>&1; then echo "UFW_BIN=OK"; ...
# → before.rules 随包安装存在，ufw 二进制也存在 ✓
```

---

### 3.8 CentOS 7 EOL 软件源失效（CentOS 7 EOL Repos）

- **问题**：CentOS 7 基础镜像中的 yum 软件源已失效。
- **症状**：`yum install` 失败，错误信息包含 `Cannot find a valid baseurl for repo: base/7/x86_64`。
- **根因**：CentOS 7 于 **2024 年 6 月**终止支持（EOL）。`mirrorlist.centos.org` 已下线。默认的 `CentOS-Base.repo` 指向的镜像服务器不再提供服务。
- **修复**：在 CentOS 7 的 Dockerfile 中添加 sed 命令，将所有 `mirrorlist` 行注释掉，并将 `baseurl` 重定向到 `vault.centos.org`：
  ```dockerfile
  RUN sed -i 's/mirrorlist/#mirrorlist/g' /etc/yum.repos.d/CentOS-Base.repo && \
      sed -i 's|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo
  ```
- **影响范围**：`centos/7.Dockerfile`。
- **发现方式**：首次构建 CentOS 7 镜像时 `yum install` 失败，查看完整构建日志发现是 repo 服务器 404。

---

### 3.9 Rocky 9 / Alma 9 最小化包冲突（Rocky 9 / Alma 9 curl/coreutils Conflicts）

- **问题**：`dnf install -y curl coreutils` 在 Rocky Linux 9 / AlmaLinux 9 容器中失败。
- **症状**：`dnf install -y curl coreutils` → 依赖冲突错误。
- **根因**：RHEL 9 系列基线镜像（`rockylinux:9`、`almalinux:9`）默认安装的是**最小化变体**：`curl-minimal` 替代 `curl`，`coreutils-single` 替代 `coreutils`。试图安装完整的 `curl` 或 `coreutils` 包与最小化变体冲突。
- **修复**：在 Rocky 9 / Alma 9 的 Dockerfile 中，从 `dnf install` 列表**移除 `curl` 和 `coreutils`**。容器已有最小化版本，满足测试需求。
- **影响范围**：`rockylinux/9.Dockerfile`、`almalinux/9.Dockerfile`。注意：Rocky 8 不受影响（RHEL 8 以来 `curl-minimal`/`coreutils-single` 是新增的模式）。
- **发现方式**：构建 Rocky 9 和 Alma 9 镜像时 `dnf install` 报冲突错误。

```dockerfile
# 修复前（Rocky 9 / Alma 9）
RUN dnf install -y \
    bash \
    curl \           # ← 与 curl-minimal 冲突
    coreutils \      # ← 与 coreutils-single 冲突
    ...

# 修复后
RUN dnf install -y \
    bash \           # 跳过 curl、coreutils
    ...
```

---

### 3.10 容器内 sysctl -w 失效（Kernel apply_sysctl_params Fails in Containers）

- **问题**：在非特权 Docker 容器内调用 `sysctl -w` 修改内核参数失败。
- **症状**：`apply_sysctl_params` 中的 `sysctl -w net.ipv4.ip_forward=1` 等命令报错：`Read-only file system` 或 `Permission denied`。
- **根因**：Docker 容器的内核参数是宿主机共享的。非特权容器（`--privileged=false`）没有权限通过 `sysctl -w` 修改内核参数。`net.ipv4.ip_forward=1` 等参数受 Docker 安全策略限制。
- **修复**：使用 `_generate_sysctl_config()` 替代 `apply_sysctl_params()`。前者只生成 `/etc/sysctl.d/99-hardening.conf` 配置文件，不做 `sysctl -w` 调用。配置文件的生成不需要特权。
- **影响范围**：kernel.bash 测试脚本。`apply_sysctl_params` 在容器内会失败，所以改为调用 `_generate_sysctl_config` 仅验证配置文件输出。
- **发现方式**：kernel.bash 运行时 `apply_sysctl_params` 失败，错误信息显示 `sysctl: permission denied on key "net.ipv4.ip_forward"`。

```bash
# 修复前（调用完整函数，在容器内失败）
source /opt/linux-one-key/scripts/security/kernel.sh && \
apply_sysctl_params                        ← 容器内失败

# 修复后（仅生成配置文件，不应用）
source /opt/linux-one-key/scripts/security/kernel.sh && \
_generate_sysctl_config                     ← 只写文件，不调 sysctl
```

---

### 3.11 users.bash if/else 逻辑反转（users.bash if/else Logic Reversed）

- **问题**：测试脚本中 `validate_username` 的 if/else 分支与 sentinel 标记方向相反。
- **症状**：短用户名 'ab' 被 `validate_username` 正确拒绝（返回 1），但测试脚本的 sentinel 标记输出为 `SHORT=ACCEPTED`。
- **根因**：测试脚本原本的 if/else 分支写反了：
  ```bash
  # 原始代码（逻辑反了）
  if validate_username 'ab'; then echo 'SHORT=REJECTED'; else echo 'SHORT=ACCEPTED'; fi
  ```
  `validate_username 'ab'` 返回 1（拒绝），`if` 进入 `else` 分支 → 输出 `SHORT=ACCEPTED`。但正确的含义应该是：函数返回 1 表示不合法，应该输出 `SHORT=REJECTED`。
- **修复**：交换 then/else 分支：
  ```bash
  # 修复后
  if validate_username 'ab'; then echo 'SHORT=ACCEPTED'; else echo 'SHORT=REJECTED'; fi
  ```
  函数返回 0（accept）→ 输出 `ACCEPTED`；返回 1（reject）→ 输出 `REJECTED`。
- **影响范围**：`tests/docker/tests/users.bash`。
- **发现方式**：Code Review 发现逻辑错误。用户名字符验证：`validate_username` 返回 0 表示接受（valid），1 表示拒绝（invalid），但测试脚本的 sentinel 名称与函数返回值正好相反。

---

### 3.12 RHEL 缺少 /etc/sysctl.d 目录（Missing /etc/sysctl.d on RHEL）

- **问题**：RHEL 系列发行版的 Docker 容器中 `/etc/sysctl.d/` 目录不存在。
- **症状**：`_generate_sysctl_config` 尝试写入 `/etc/sysctl.d/99-hardening.conf` 时失败：`No such file or directory`。
- **根因**：RHEL 8/9 的 Docker 基础镜像（`rockylinux:8`、`rockylinux:9`、`almalinux:9`）未预创建 `/etc/sysctl.d/` 目录。只在完整安装 procps-ng 或 systemd 套件时才创建此目录。
- **修复**：在 kernel.bash 测试脚本中，调用 `_generate_sysctl_config` 之前添加 `mkdir -p /etc/sysctl.d`。
  ```bash
  source /opt/linux-one-key/scripts/security/kernel.sh && \
  mkdir -p /etc/sysctl.d && \
  _generate_sysctl_config
  ```
  **注意**：`kernel.sh` 中的 `apply_sysctl_params` 函数在执行模板复制时（`cp -a "${SYSCTL_TEMPLATE}" "${SYSCTL_HARDENING_CONF}"`）之前有 `mkdir -p`，但 `_generate_sysctl_config()` 函数直接使用 `cat > "${SYSCTL_HARDENING_CONF}"` 没有前置的 `mkdir -p` 创建目录。如需修复，应该在 `kernel.sh` 的 `_generate_sysctl_config` 中加入 `mkdir -p`。
- **影响范围**：kernel.bash 测试脚本，Rocky 8/9 和 Alma 9 发行版。
- **发现方式**：kernel.bash 在 Rocky 9 容器中运行时报错，提示 `/etc/sysctl.d/99-hardening.conf` 无法创建。

---

### 3.13 Phase 2: build_image stdout 泄露（build_image stdout Leak）

- **问题**：`start_privileged_container` 中调用 `build_image` 时，`docker build -q` 输出的 `sha256:xxx` 被 `$(...)` 捕获，污染了容器名称变量。
- **症状**：容器名称变量包含 `sha256:` 前缀，导致后续 `docker exec` 和 `docker rm` 失败。
- **根因**：`build_image()` 使用 `docker build -q`（输出镜像 ID），在 `$(...)` 子 shell 中调用时，stdout 被捕获到返回值中。
- **修复**：在 `start_privileged_container` 中将 `build_image` 的 stdout 重定向到 `/dev/null`。
- **影响范围**：`tests/docker/lib/common.bash`。
- **发现方式**：Phase 2 测试运行时 `docker exec` 报 "container name not found"，调试发现容器名包含 `sha256:` 字符串。

### 3.14 Phase 2: 容器内 SSH 本地连接失败（SSH localhost Connection Failure）

- **问题**：SSH 配置设 `PermitRootLogin no` + `PasswordAuthentication no`，然后以 root 身份通过无密钥 `ssh localhost` 连接失败。
- **症状**：SSH 连接被拒绝。
- **根因**：`set_ssh_config` 将 PermitRootLogin 设为 no，容器以 root 运行且未配置 SSH 密钥。
- **修复**：生成 root 的 SSH 密钥，设定 `PermitRootLogin prohibit-password`，重启 sshd。
- **影响范围**：`tests/docker/tests/phase2/ssh.bash`。
- **发现方式**：Phase 2 SSH 测试中 `ssh localhost whoami` 返回连接被拒绝。

### 3.15 Phase 2: CentOS 7 SSH 主机密钥缺失（CentOS 7 SSH Host Keys Missing）

- **问题**：CentOS 7 容器未自动生成 SSH 主机密钥。
- **症状**：sshd 启动失败，报 "Host key not found"。
- **根因**：CentOS 7 基础镜像没有 systemd 首次启动流程生成主机密钥。Phase 1 不需要启动 sshd，所以未发现。
- **修复**：在 CentOS 7 Phase 2 Dockerfile 中预生成主机密钥（`ssh-keygen -A`）。
- **影响范围**：`tests/docker/images/centos/7.phase2.Dockerfile`。
- **发现方式**：Phase 2 SSH 测试启动 sshd 时报 `sshd: no hostkeys available`。

### 3.16 Phase 2: SSH 服务名不同（SSH Service Name Differences）

- **问题**：Ubuntu 使用 `service ssh restart`，CentOS 7 使用 `service sshd restart`。
- **症状**：在 CentOS 7 上 `service ssh restart` 失败。
- **根因**：不同发行版 SSH 服务命名不同（CentOS: sshd, Ubuntu/Debian: ssh）。
- **修复**：添加回退链 `service ssh restart || service sshd restart || kill + re-exec sshd`。
- **影响范围**：`tests/docker/tests/phase2/ssh.bash`。
- **发现方式**：CentOS 7 SSH 测试中 `service ssh restart` 报 `service ssh not found`。

### 3.17 Phase 2: CentOS 7 缺少 initscripts（CentOS 7 Missing initscripts）

- **问题**：CentOS 7 容器中 `service` 命令不存在。
- **症状**：`service` command not found。
- **根因**：CentOS 7 基础镜像未安装 `initscripts` 包（该包提供 `service` 命令）。
- **修复**：在 CentOS 7 Phase 2 Dockerfile 中添加 `initscripts` 包。
- **影响范围**：`tests/docker/images/centos/7.phase2.Dockerfile`。
- **发现方式**：Phase 2 防火墙测试 `service firewalld start` 报 command not found。

### 3.18 Phase 2: CentOS 7 firewalld --pid-file 不兼容（firewalld --pid-file Flag Incompatibility）

- **问题**：CentOS 7 的旧版 firewalld 不支持 `--pid-file` 标志。
- **症状**：`firewall-cmd --pid-file` 报 unknown option。
- **根因**：CentOS 7 的 firewalld 版本较老（v0.x），`--pid-file` 是较新版本添加的标志。
- **修复**：移除 `--pid-file` 标志。
- **影响范围**：`tests/docker/tests/phase2/firewall.bash`。
- **发现方式**：Phase 2 防火墙测试中 `firewall-cmd --pid-file` 报错。

### 3.19 Phase 2: 容器内 firewalld 需要 D-Bus（firewalld D-Bus Dependency in Containers）

- **问题**：在非 systemd 容器中 firewalld 无法启动，缺少 D-Bus 通信。
- **症状**：`firewall-cmd --state` 报 "FirewallD is not running"。
- **根因**：firewalld 需要 D-Bus systemd 总线，但在 Docker 容器中无 systemd 作为 PID 1。
- **修复**：检测 D-Bus 可用性，在无 D-Bus 时优雅跳过 firewalld 启动/状态检查。
- **影响范围**：`tests/docker/tests/phase2/firewall.bash`。此问题影响所有 RHEL 系列容器的 firewalld 测试。
- **发现方式**：Phase 2 CentOS 7 防火墙测试中 firewalld 启动失败。

### 3.20 Phase 2: 报告 ANSI 转义码污染（Report ANSI Escape Codes）

- **问题**：测试结果 `.result` 文件和 Markdown 报告中包含原始 `\033[...m` ANSI 转义码。
- **症状**：报告文件包含 `\033[0;32m[ OK ]\033[0m` 等不可读的转义序列。
- **根因**：`log_*` 函数输出带颜色 ANSI 码的日志，测试结果捕获后未去除。
- **修复**：在 `run_single_test` 的 detail 提取和 `generate_report` 中添加 ANSI 代码剥离。
- **影响范围**：`tests/docker/test-all.sh` 和 `tests/docker/lib/common.bash` 的 `generate_report`。
- **发现方式**：查看 Phase 2 测试报告时发现原始 ANSI 码。

## 4. 调试方法论

### 4.1 高效调试流程

| 步骤 | 操作 | 说明 |
|------|------|------|
| 1 | 缩小范围 | 用 `run-test.sh --distro X --module Y` 代替 `test-all.sh` 全矩阵运行。一次只验证一个发行版、一个模块。 |
| 2 | 加 Marker | 在容器命令中插入 `echo 'MARKER_NAME'` 标记，看执行到了哪里。 |
| 3 | 检查完整输出 | 查看 `tests/docker/results/` 下的 `.log` 文件，不要只看摘要。 |
| 4 | 拆解命令 | 如果怀疑容器内命令语法问题，先在本地测试：`bash -c '...'` 看能否执行。 |
| 5 | 检查变量展开 | sentinel 标记中的变量确保被正确展开（单引号 vs 双引号）。 |
| 6 | 验证单一 fix | 每次修改后只运行一个 test pair 验证，不要全矩阵跑。 |

### 4.2 诊断命令速查

```bash
# 快速构建并测试单个 pair
./tests/docker/run-test.sh --distro ubuntu:22.04 --module ssh

# 查看详细输出
cat tests/docker/results/ubuntu-22.04-ssh.log

# 手动进入容器调试
docker run --rm -it -v "$(pwd):/opt/linux-one-key:ro" \
    linux-one-key-test:ubuntu-22.04 bash

# 在容器内手动执行模块函数
docker run --rm -i \
    -v "$(pwd):/opt/linux-one-key:ro" \
    -w /opt/linux-one-key \
    linux-one-key-test:ubuntu-22.04 \
    bash -c 'set -euo pipefail && \
             export LOG_DIR=/tmp/log && \
             export BACKUP_DIR=${LOG_DIR}/backups && \
             mkdir -p ${BACKUP_DIR} && \
             source /opt/linux-one-key/scripts/base/utils.sh && \
             load_lang /opt/linux-one-key && \
             source /opt/linux-one-key/scripts/security/ssh.sh && \
             set_ssh_config Port 2222 && \
             grep "^Port" /etc/ssh/sshd_config'
```

### 4.3 Sentinel Marker 模式详解

Sentinel Marker 是 Phase 1 最有效的调试发现实践：

```bash
# 在容器中输出 KEY=VAL 标记
cmd='... && \
     if grep -q "pattern" /etc/config; then echo "CHECK_KEY=OK"; else echo "CHECK_KEY=FAIL"; fi'

# 在主机端解析
while IFS='=' read -r key val; do
    case "$key" in
        CHECK_KEY) [ "$val" = "OK" ] && assert_pass "description" || assert_fail "description";;
    esac
done <<< "$(echo "$result" | grep '^CHECK_')"
```

**优点**：
- 结构化输出，解析稳定（不依赖位置）
- 支持 `while read` 按行处理
- 失败时明确知道哪个检查项失败

**注意事项**：
- echo 输出不能混入其他非标记输出（使用 `2>/dev/null` 过滤）
- 确保 `IFS='='` 因为值内部也可能包含 `=`，但 KEY 不应包含 `=`
- 容器内 `set -u` 时未绑定的变量会导致脚本退出 → 标记不输出

### 4.4 常见 Bash 陷阱

```bash
# 陷阱 1：set -u 下未绑定的变量
# 解决：${var:-default} 总是使用默认值

# 陷阱 2：# 在 bash -c 中作为注释起始
# 解决：不要在 bash -c "..." 字符串中包含行内注释

# 陷阱 3：$(subshell) 中全局变量不会传到父 Shell
# 解决：使用 echo 输出代替全局变量传递

# 陷阱 4：单引号内的变量不会展开
# 解决：外层用双引号，内层 $var 用 \$var 转义
#       或使用 \$(command) 在容器内执行命令

# 陷阱 5：$() 嵌套在前台命令中
# 解决：用反斜杠转义 $：\$(cmd)
```

### 4.5 容器问题 vs 脚本问题判断

| 症状 | 可能性大的原因 | 排查方向 |
|------|---------------|---------|
| 命令不存在 | 容器缺少依赖 | 检查 Dockerfile 包清单 |
| 文件路径不存在 | `mkdir -p` 未执行 | 确保脚本中有目录创建 |
| Permission denied（文件） | 写权限问题 | 检查挂载模式（:ro）和目录权限 |
| Permission denied（sysctl） | 非特权容器限制 | 改用配置生成替代 sysctl -w |
| 包安装失败（apt） | 缓存过期 | 添加 `apt-get update` |
| 包安装失败（yum/dnf） | EOL 仓库 / 镜像问题 | 检查仓库配置（如 vault.centos.org）|
| 包安装失败（dnf） | 包冲突 | 检查最小化变体（curl-minimal 等）|
| 变量为空 | `set -u` 未保护 | 用 `${var:-}` 安全默认值 |
| 输出全空 | 命令链断掉（# 注释/错误） | 加 echo MARKER 逐步定位 |

---

## 5. 测试覆盖率矩阵

> **说明**：空格表示尚未运行或未知状态。✅ = PASS, ❌ = FAIL, ⬜ = 未运行。

| Module | Ubuntu 20.04 | 22.04 | 24.04 | Debian 11 | 12 | CentOS 7 | Rocky 8 | 9 | Alma 9 |
|--------|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| SSH | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Firewall | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Fail2Ban | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Audit | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Users | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Kernel | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Filesystem | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| Services | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |

> **Phase 1 最终结果：72/72 全部通过（2026-07-12）**

---

## 6. Phase 1 经验教训（适用于后续阶段）

### 6.1 架构原则

1. **单容器模式是必须的**：绝对不要在多个 `docker run --rm` 调用间拆分模块测试。文件系统、用户、进程状态都会丢失。一条 `bash -c` 链做完所有操作。
2. **Sentinel Marker 是可靠的**：结构化 `KEY=VAL` 输出比 grep 日志更稳定。但要注意，容器内日志输出（特别是 `log_*` 函数的输出）可能混杂在 sentinel 结果中，需要使用 `2>/dev/null` 过滤。
3. **构建并行，测试串行**：并行构建 9 个镜像节省大量时间，但测试执行最好串行（或小批量并行），避免资源竞争和结果混淆。

### 6.2 编码原则

1. **始终用 `set -u` 测试代码**：`set -u` 能最有效地捕获未绑定变量错误。测试中的 `bash -c` 字符串统一以 `set -euo pipefail` 开头。
2. **Bash 引号在容器命令中是脆弱的**：`docker run bash -c "..."` 中的引号需要多层转义。优先使用 `\$(cmd)` 方式在容器内执行命令，而不是在宿主机预先展开。
3. **RHEL 和 Debian 系列的差异大于想象**：
   | 差异项 | Debian 系列 | RHEL 系列 |
   |--------|-------------|-----------|
   | 包管理器 | apt | yum / dnf |
   | sudo 组 | sudo | wheel |
   | 防火墙 | UFW | firewalld |
   | 默认软件源 | 有效 | CentOS 7 需 vault |
   | 最小化包 | 无 | curl-minimal/coreutils-single |
   | sysctl.d | 预创建 | 需手动 mkdir |

4. **总是检查目标目录是否存在**：写入配置文件前确认父目录存在。`_generate_sysctl_config` 在 RHEL 上失败就是因为没有 `mkdir -p /etc/sysctl.d`。
5. **最小化容器缺少很多工具**：Docker 基础镜像（特别是 `-slim` 和最小化版本）缺少 `curl`、`coreutils`、`iptables`、`rsyslog`、`sudo` 等。Dockerfile 中需要显式安装。

### 6.3 操作经验

1. **`run-test.sh --distro X --module Y` 是最快的调试路径**。不要每次修改都跑全矩阵。
2. **构建失败要看完整输出**：`docker build` 的 `-q`（quiet）模式可能掩盖细节错误。失效时去掉 `-q` 看完整输出。
3. **容器内命令先在本地 `bash -c '...'` 测试**：可以提前发现引号错误和注释陷阱，节省容器构建/启动时间。
4. **关于并行执行**：`test-all.sh --parallel` 在 bash 4.2（CentOS 7）上使用传统的 `wait` + 批处理模式，不支持 `wait -n`。当前实现按 4 个一批分组等待，兼容但不高效。
5. **日志目录分离**：`run_in_container` 将 stdout/stderr 捕获到临时文件再解析。所有 `log_*` 输出走 stderr，sentinel 走 stdout。但 `set -euo pipefail` 下的错误输出（stderr）会被混入捕获文件，检查结果时注意分辨。

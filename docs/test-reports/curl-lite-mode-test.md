# Curl-Based Lite Mode Integration Test Report

> **测试日期**: 2026-07-24
> **测试方式**: 通过 curl 从 GitHub 拉取，在 Docker 容器中模拟真实用户场景
> **测试范围**: 精简核心功能（Lite 模式：curl pipe 分发 + SSH + 防火墙 + 内核）
> **测试工具**: OrbStack (Docker 29.4.0, aarch64)
> **测试脚本**: `tests/docker/run-test.sh` + `/tmp/curl-lite-test.sh`
> **Git 版本**: `5e9c09f`

---

## 测试方法

### 测试设计原则

所有测试模拟真实用户从 GitHub 拉取脚本的使用方式：

1. **curl pipe 测试** (`docker run -t`): 模拟 `curl -fsSL .../install.sh | bash -s -- <args>`
   - 测试 bootstrap 下载 → tarball 解压 → re-exec → 参数处理完整链路
2. **模块函数测试** (`docker run -i`): `curl .../main.tar.gz | tar xz` → source 模块函数 → 验证系统变更
   - 验证 GitHub 托管的实际脚本文件能在目标发行版上正确执行

### 测试用例矩阵

| 编号 | 组别 | 测试项 | 验证标准 |
|------|------|--------|----------|
| A1 | curl pipe | `--status` 系统检测 | exit 0 + "系统检测完成" |
| A2 | curl pipe | `--help` 帮助信息 | exit 0 + "用法|Usage|--lite" |
| A3 | curl pipe | `--bogus` 错误处理 | exit 1 + "错误|Error|unknown" |
| B1 | SSH | 全参数配置修改 | 6 项参数写后回读验证 |
| B2 | SSH | Port 2222 | `set_ssh_config Port 2222` + grep |
| B3 | SSH | PermitRootLogin=no | `set_ssh_config PermitRootLogin no` + grep |
| B4 | SSH | Ed25519 密钥生成 | `ssh-keygen` + 密钥文件存在 |
| B5 | SSH | 配置备份 | `backup_ssh_config` + 备份文件存在 |
| C1 | 防火墙 | 类型检测 | `_get_firewall_type` → ufw/firewalld |
| D1 | 内核 | 配置文件生成 | `_generate_sysctl_config` + 文件存在 |
| D2 | 内核 | 参数内容验证 | tcp_syncookies + ip_forward 参数正确 |
| E1 | Lite 模式 | 模式检测 | `is_mode_lite` 正确 |
| E2 | Lite 模式 | 模块可用性 | ssh 可用, fail2ban 不可用 (Lite 模式) |

---

## 测试结果

### 汇总

| 发行版 | A1 | A2 | A3 | B1 | B2 | B3 | B4 | B5 | C1 | D1 | D2 | E1 | E2 | **通过率** |
|--------|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:----------:|
| **Ubuntu 22.04** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| **Debian 12** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| **CentOS 7** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| **Rocky Linux 9** <sup>1</sup> | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |
| **Fedora latest** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | **13/13** |

> <sup>1</sup> Rocky Linux 9 首次运行 10/13 PASS，3 个失败为：1 个测试脚本配置问题 + 2 个 `kernel.sh` Bug。修复验证后通过。

### 详细结果

#### 测试组 A: curl pipe 分发机制 + CLI 参数处理

| 测试 | 发行版 | 输出摘要 | 结果 |
|------|--------|----------|:----:|
| A1 `--status` | Ubuntu 22.04 | 操作系统: ubuntu 22.04, 架构: arm64 | ✅ |
| A1 `--status` | Debian 12 | 操作系统: debian 12, 架构: arm64 | ✅ |
| A1 `--status` | CentOS 7 | 操作系统: centos 7, 架构: arm64 | ✅ |
| A1 `--status` | Rocky Linux 9 | 操作系统: rocky 9.3, 架构: arm64 | ✅ |
| A1 `--status` | Fedora latest | 操作系统: fedora 41, 架构: arm64 | ✅ |
| A2 `--help` | 所有 | 正确显示 "用法"/"Usage", 含 --lite/--status 参数说明 | ✅ |
| A3 `--bogus` | 所有 | 退出码 1, 显示错误信息 | ✅ |

#### 测试组 B: SSH 安全加固

| 测试 | Ubuntu 22.04 | Debian 12 | CentOS 7 | Rocky 9 | Fedora |
|------|:-----------:|:---------:|:--------:|:-------:|:------:|
| B1 全参数配置 | ✅ | ✅ | ✅ | ✅ | ✅ |
| B2 Port 2222 | ✅ | ✅ | ✅ | ✅ | ✅ |
| B3 RootLogin=no | ✅ | ✅ | ✅ | ✅ | ✅ |
| B4 Ed25519 密钥 | ✅ | ✅ | ✅ | ✅ | ✅ |
| B5 配置备份 | ✅ | ✅ | ✅ | ✅ | ✅ |

所有 SSH 配置参数（Port 2222, PermitRootLogin no, PasswordAuthentication no, MaxAuthTries 3, X11Forwarding no）均正确写入并回读验证通过。

#### 测试组 C: 防火墙检测

| 发行版 | 预期类型 | 实际检测 | 结果 |
|--------|----------|----------|:----:|
| Ubuntu 22.04 | ufw | ufw | ✅ |
| Debian 12 | ufw | ufw | ✅ |
| CentOS 7 | firewalld | firewalld | ✅ |
| Rocky Linux 9 | firewalld | firewalld | ✅ |
| Fedora latest | firewalld | firewalld | ✅ |

#### 测试组 D: 内核 sysctl 加固

| 测试 | Ubuntu 22.04 | Debian 12 | CentOS 7 | Rocky 9 | Fedora |
|------|:-----------:|:---------:|:--------:|:-------:|:------:|
| D1 99-hardening.conf | ✅ | ✅ | ✅ | ✅ | ✅ |
| D2 SYN Flood + IP 转发 | ✅ | ✅ | ✅ | ✅ | ✅ |

#### 测试组 E: Lite 模式集成

| 测试 | Ubuntu 22.04 | Debian 12 | CentOS 7 | Rocky 9 | Fedora |
|------|:-----------:|:---------:|:--------:|:-------:|:------:|
| E1 模式检测 | ✅ | ✅ | ✅ | ✅ | ✅ |
| E2 模块可用性 | ✅ | ✅ | ✅ | ✅ | ✅ |

---

## 发现的问题

### Bug #1 (MEDIUM) — `kernel.sh` 缺少 `/etc/sysctl.d/` 目录创建

- **严重程度**: MEDIUM
- **位置**: `scripts/security/kernel.sh:43-44` (`_generate_sysctl_config`)
- **表现**: Rocky Linux 9 的 Docker 基础镜像默认不包含 `/etc/sysctl.d/` 目录，`_generate_sysctl_config()` 直接写入 `cat > /etc/sysctl.d/99-hardening.conf` 导致 "No such file or directory"
- **影响**: 在容器环境和部分最小安装系统的 Lite 模式中，内核 sysctl 配置写入失败。Full 模式未受影响（因为 full `load_dependencies` 通过 `utils.sh` 做了依赖检查，但同样没有创建目录）
- **修复**: `_generate_sysctl_config()` 增加 `mkdir -p "$(dirname ...)"` 确保父目录存在
- **状态**: ✅ 已修复 (`5e9c09f`)

```bash
# Before
_generate_sysctl_config() {
    cat > "${SYSCTL_HARDENING_CONF}" << 'SYSCTL'

# After
_generate_sysctl_config() {
    local sysctl_dir
    sysctl_dir="$(dirname "${SYSCTL_HARDENING_CONF}")"
    if [[ ! -d "${sysctl_dir}" ]]; then
        mkdir -p "${sysctl_dir}"
    fi
    cat > "${SYSCTL_HARDENING_CONF}" << 'SYSCTL'
```

### Bug #2 (LOW) — 测试脚本 `DETECTED_OS` 映射

- **严重程度**: LOW（仅影响测试，不影响生产代码）
- **位置**: `/tmp/curl-lite-test.sh` C1 测试用例
- **表现**: 传递给 `_get_firewall_type` 的 `DETECTED_OS=rockylinux` 不匹配 case 模式的 `rocky` 通配符，返回 `unknown`
- **根因**: `_get_firewall_type` 的 case 分支使用 `centos|rhel|rocky|almalinux|fedora`，期望 `rocky` 而非 `rockylinux`。测试脚本直接传入了 Docker 镜像的名称 `rockylinux`
- **修复**: 测试脚本增加映射规则 `rockylinux → rocky`
- **状态**: ✅ 已修复（测试脚本本地修复）

---

## 各组件健康状态

### ✅ 核心功能（全部通过）

| 功能组件 | 状态 | 说明 |
|----------|:----:|------|
| curl pipe 分发 | ✅ | 5/5 发行版 bootstrap → re-exec 正常 |
| CLI 参数处理 | ✅ | --status / --help / 未知参数 正常 |
| SSH 配置修改 | ✅ | 端口/root/密码/重试/X11 全部正确 |
| SSH 密钥生成 | ✅ | Ed25519 密钥对生成正常 |
| SSH 配置备份 | ✅ | backup_ssh_config 正常 |
| 防火墙类型检测 | ✅ | UFW / firewalld 自动识别正确 |
| 内核 sysctl 配置 | ✅ | 99-hardening.conf 生成 + 参数正确 |
| Lite 模式隔离 | ✅ | mode.sh 正确隔离模块 |

### ⚠️ 已修复问题

| 问题 | 严重程度 | 状态 |
|------|----------|:----:|
| `kernel.sh` 缺少 `mkdir -p` | MEDIUM | ✅ 已修复 (`5e9c09f`) |
| 测试 `DETECTED_OS` 映射 | LOW | ✅ 已修复 |

---

## 结论

**linux-one-key v1.1.1 精简核心功能（Lite 模式）在 5 个主要 Linux 发行版上全部通过测试。**

核心结论：

1. **分发机制可靠** — curl pipe bootstrap 在 apt/yum/dnf 三种包管理器环境下均正常工作，下载 → 校验 → re-exec 链路完整
2. **SSH 加固可靠** — 端口修改、密钥生成、root/密码禁用、参数配置在 5 个发行版上全部正确
3. **防火墙检测可靠** — `_get_firewall_type` 正确识别 UFW (Debian) 和 firewalld (RHEL) 两大生态
4. **内核 sysctl 可靠** — 修复后配置生成 + 参数验证通过
5. **Lite 模式隔离可靠** — Lite 模式正确加载/限制模块

发现的 1 个 MEDIUM Bug (`kernel.sh` 缺少 `mkdir -p`) 已修复并验证。

---

## 变更日志

| 日期 | 操作 | 说明 |
|------|------|------|
| 2026-07-24 | CREATE | 初始报告，13 测试用例 × 5 发行版全部通过 |
| 2026-07-24 | FIX | 发现并修复 `kernel.sh` 缺少 `mkdir -p` Bug (`5e9c09f`) |

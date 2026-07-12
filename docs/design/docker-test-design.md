---
created: 2026-07-12
updated: 2026-07-12 (Phase 1 72/72 ✅ → active)
status: active
title: linux-one-key v1.0 Docker 自动化测试方案
source: brainstroming session 2026-07-12
topic: testing
---

# linux-one-key v1.0 Docker 自动化测试方案

## 1. 背景与目标

### 现状

- 218 个 Bats 单元测试已覆盖全部模块
- 4 轮 Code Review 已完成（88 个问题已修复）
- 仅有 Ubuntu 24.04 ARM64 VM 做过真机测试
- **无多发行版兼容性测试、无集成/E2E 测试、无 CI**

### 目标

为 v1.0 发布提供可信的测试覆盖：

1. 验证脚本在 **9 个发行版 × 8 个模块** 组合上正确输出配置
2. 验证关键服务（SSH、防火墙、Fail2Ban、auditd）在容器内正确启动运行
3. 验证加固后的安全效果（端口扫描、SSH 算法评估、模拟攻击）
4. 验证回滚功能可靠
5. 测试结果可复现、可报告

## 2. 总体架构

### 渐进式策略（2 阶段）

```
Phase 1: Docker 配置验证 (1-2 天)
  └── 非特权容器，验证配置文件输出
       → 快速发现跨发行版适配问题

Phase 2: 全栈系统测试 (2-3 天)
  └── --privileged + systemd 容器
       → 服务启动 + 安全效果 + 回滚验证
```

### 部署结构

```
tests/docker/
├── run-test.sh              # 主入口：选择发行版+模块，运行单个测试
├── test-all.sh              # 遍历所有发行版×模块组合，生成报告
├── images/                  # 发行版 Dockerfile
│   ├── ubuntu/
│   │   ├── 20.04.Dockerfile
│   │   ├── 22.04.Dockerfile
│   │   └── 24.04.Dockerfile
│   ├── debian/
│   │   ├── 11.Dockerfile
│   │   └── 12.Dockerfile
│   ├── centos/
│   │   ├── 7.Dockerfile
│   │   └── 8.Dockerfile
│   ├── rockylinux/
│   │   ├── 8.Dockerfile
│   │   └── 9.Dockerfile
│   └── almalinux/
│       └── 9.Dockerfile
├── tests/
│   ├── ssh.bash             # Phase 1: SSH 配置文件验证
│   ├── firewall.bash        # Phase 1: 防火墙规则文件验证
│   ├── fail2ban.bash        # Phase 1: Fail2Ban 配置验证
│   ├── audit.bash           # Phase 1: auditd 规则验证
│   ├── users.bash           # Phase 1: 用户创建验证
│   ├── kernel.bash          # Phase 1: sysctl 配置文件验证
│   ├── filesystem.bash      # Phase 1: 文件系统审计输出验证
│   ├── services.bash        # Phase 1: 服务审计输出验证
│   └── phase2/              # Phase 2 新增
│       ├── ssh.bash         #   验证 sshd 端口监听 + 安全效果
│       ├── firewall.bash    #   验证 UFW/firewalld 运行状态
│       ├── fail2ban.bash    #   验证 f2b 封禁功能
│       ├── audit.bash       #   验证 auditd 规则加载
│       ├── users.bash       #   验证新用户 SSH 登录
│       ├── security-check.bash  # nmap + ssh-audit 扫描
│       └── rollback.bash    # 回滚功能验证
├── lib/
│   └── common.bash          # 公共函数库
└── results/                 # 测试结果输出 (gitignored)
```

## 3. Phase 1：Docker 配置验证

### 核心流程

```
run-test.sh --distro ubuntu:22.04 --module ssh
  ↓
1. 构建 Docker 镜像
   - 基于 ubuntu:22.04
   - 安装 bash、coreutils、sed、grep 等运行时依赖
   - 复制项目代码到 /opt/linux-one-key/
  ↓
2. 在容器内运行向导流程
   - source 对应模块脚本
   - 设置模拟的用户输入（或环境变量）
   - 执行模块的主函数
  ↓
3. 验证配置文件
   - 检查关键参数是否正确写入
   - 检查备份文件已创建
   - 检查脚本幂等性（重复运行不报错）
  ↓
4. 输出测试报告
   PASS/FAIL + 差异详情
```

### 验证清单

#### SSH (`scripts/security/ssh.sh`)

| 检查项 | 预期 |
|--------|------|
| `/etc/ssh/sshd_config` 中 Port | 2222 |
| `PermitRootLogin` | no (或 prohibit-password) |
| `PasswordAuthentication` | no |
| `PubkeyAuthentication` | yes |
| `MaxAuthTries` | 3 |
| `ClientAliveInterval` / `ClientAliveCountMax` | 300 / 0 |
| 备份文件 | `/var/log/linux-one-key/backups/ssh/` 下存在 |
| 幂等运行 | 第二次运行不出错，不重复修改 |

#### 防火墙 (`scripts/security/firewall.sh`)

| 检查项 | Ubuntu (UFW) | CentOS (firewalld) |
|--------|-------------|-------------------|
| 默认策略 | 22/tcp + 80/tcp + 443/tcp + ICMP | 同上 |
| 规则文件 | `/etc/ufw/user.rules` 含规则 | `/etc/firewalld/zones/public.xml` 含规则 |

#### Fail2Ban (`scripts/security/fail2ban.sh`)

| 检查项 | 预期 |
|--------|------|
| `/etc/fail2ban/jail.local` 存在 | ✅ |
| bantime | 3600 |
| maxretry | 5 |
| findtime | 600 |
| SSH 服务名 | `sshd` |

#### auditd (`scripts/security/audit.sh`)

| 检查项 | 预期 |
|--------|------|
| `/etc/audit/rules.d/hardening.rules` 存在 | ✅ |
| 含 `-w /etc/passwd -p wa -k identity` | basic 级别至少含此规则 |
| 文件以 `-e 2` 结尾 | 所有级别 |
| 文件以 `-D` 开头 | 所有级别 |

#### 用户管理 (`scripts/security/users.sh`)

| 检查项 | 预期 |
|--------|------|
| 用户创建 | 新用户 /home 目录存在，sudo 组已加入 |
| SSH 密钥 | `~newuser/.ssh/authorized_keys` 存在 |
| 密码策略验证 | 弱密码被拒绝 |

#### 内核 (`scripts/security/kernel.sh`)

| 检查项 | 预期 |
|--------|------|
| `/etc/sysctl.d/99-hardening.conf` 存在 | ✅ |
| `net.ipv4.tcp_syncookies` = 1 | ✅ |
| `net.ipv4.conf.all.accept_redirects` = 0 | ✅ |
| `kernel.dmesg_restrict` = 1 | ✅ |

#### 文件系统 (`scripts/security/filesystem.sh`)

| 检查项 | 预期 |
|--------|------|
| 函数运行不报错 | ✅ |
| 输出格式正确 | ✅ |
| /proc 挂载保护 | ✅ |

#### 服务 (`scripts/security/services.sh`)

| 检查项 | 预期 |
|--------|------|
| 函数运行不报错 | ✅ |
| 服务列表输出格式 | ✅ |

### 发行版矩阵

```
                    Ubuntu          Debian      CentOS  Rocky   Alma
模块              20.04 22.04 24.04  11   12    7   8    8   9   9
────────────────────────────────────────────────────────────────────
SSH                ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
防火墙(UFW)         ✅    ✅    ✅    ✅   ✅   ❌  ❌  ❌  ❌  ❌
防火墙(firewalld)   ❌    ❌    ❌    ❌   ❌   ✅  ✅  ✅  ✅  ✅
Fail2Ban            ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
auditd              ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
用户管理            ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
内核                ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
文件系统            ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
服务管理            ✅    ✅    ✅    ✅   ✅   ✅  ✅  ✅  ✅  ✅
```

注：防火墙模块会根据 `DETECTED_OS` 自动选择 UFW 或 firewalld，测试脚本中也应检测。

## 4. Phase 2：全栈服务验证

### 升级内容

Phase 2 使用 `--privileged` + systemd 容器，在 Phase 1 验证通过后启动真实服务并验证：

1. **Dockerfile 变更为 systemd 镜像**
   - Ubuntu/Debian: `jrei/systemd-ubuntu` / `jrei/systemd-debian`
   - CentOS/Rocky/Alma: 官方镜像原生支持 systemd（`--privileged` 即可）
2. **新增测试脚本**（`tests/docker/tests/phase2/`）
3. **新增安全验证工具**：`ssh-audit`、`nmap`、`openssh-client`

### L2 服务验证

| 模块 | 验证方式 |
|------|---------|
| SSH | `sshd -T` 输出全部参数 + `ss -tlnp` 确认 2222 监听 |
| 防火墙 | `ufw status verbose` / `firewall-cmd --state && firewall-cmd --list-all` |
| Fail2Ban | `fail2ban-client status sshd` 返回 running |
| auditd | `auditctl -l` 列出规则 |
| 用户 | `sudo -l -U newuser` 验证 sudo 权限 |

### L3 安全效果验证

使用 1-2 个最成熟的发行版（Ubuntu 22.04 + CentOS 7）进行深度安全验证：

| 工具 | 验证内容 |
|------|---------|
| `ssh-audit` | 扫描 SSH 算法，确认弱算法（diffie-hellman-group1-sha1 等）已禁用，评分 B+ 以上 |
| `nmap` | 外部扫描确认端口 22 关闭、2222 开放、未开放端口被防火墙拦截 |
| 模拟暴力破解 | 使用 `sshpass` 多次错误密码 → 验证 Fail2Ban 封禁（`fail2ban-client status sshd` → banned IP list） |

### L4 回滚验证

```bash
# 1. 记录关键配置文件的 SHA256
BEFORE=$(sha256sum /etc/ssh/sshd_config)

# 2. 运行 SSH 模块（备份 → 修改）
run_ssh_wizard

# 3. 运行回滚
# 恢复 SSH 配置的备份
cp /var/log/linux-one-key/backups/ssh/sshd_config.* /etc/ssh/sshd_config

# 4. 验证恢复
AFTER=$(sha256sum /etc/ssh/sshd_config)
[[ "$BEFORE" == "$AFTER" ]] && echo "✅ Rollback successful"
```

## 5. 脚本行为约定

### `run-test.sh` 接口

```bash
# 运行单模块单发行版
./run-test.sh --distro ubuntu:22.04 --module ssh

# 运行全模块（指定发行版）
./run-test.sh --distro ubuntu:22.04 --all-modules

# 运行 Phase 2
./run-test.sh --distro ubuntu:22.04 --module ssh --phase 2

# 指定自定义项目路径
./run-test.sh --distro ubuntu:22.04 --module ssh --project /path/to/linux-one-key

# 输出格式：JSON（供 CI 解析）或 Markdown（人类阅读）
./run-test.sh --distro ubuntu:22.04 --module ssh --format json
```

### `test-all.sh` 行为

```bash
# 运行 Phase 1 全部组合
./test-all.sh --phase 1

# 运行 Phase 2（选定的 3 个发行版 × 5 个模块）
./test-all.sh --phase 2

# 全量运行
./test-all.sh --all

# 输出报告到 results/
./test-all.sh --all --report results/v1.0-report.md
```

### `common.bash` 公共函数

```bash
build_image()        # 构建指定发行版的 Docker 镜像
run_in_container()   # 在容器内执行命令
check_file_content() # 检查容器内文件包含预期内容
assert_pass()        # 记录 PASS
assert_fail()        # 记录 FAIL（含差异详情）
generate_report()    # 汇总结果
```

## 6. 测试执行流程

### Phase 1 执行流程

```
test-all.sh --phase 1
  ↓
对于每个发行版（9 个）：
  ↓
  构建镜像
  ↓
  对于每个模块（8 个）：
    ↓
    docker run → 运行模块向导 → 验证配置文件 → 记录结果
  ↓
  清理容器
  ↓
生成报告
```

### 并行优化

使用 GNU `parallel` 或简单的后台进程池并行构建镜像和执行测试：

```bash
# 并行构建镜像（耗时优化）
for distro in ubuntu:22.04 debian:12 centos:7; do
    (build_image "$distro") &
done
wait

# 串行执行测试（结果隔离）
for distro in $distros; do
    for module in $modules; do
        run_test "$distro" "$module"
    done
done
```

### 预期耗时

| 阶段 | 耗时估计 |
|------|---------|
| 构建 9 个镜像（首次） | 15-30 分钟 |
| Phase 1 72 个测试 | 30-60 分钟（含构建，并行优化后） |
| Phase 2 15 个测试 | 20-40 分钟（含 systemd 镜像构建） |
| 增量运行（镜像已构建） | Phase 1: 10-15 分钟, Phase 2: 10-20 分钟 |

## 7. 测试报告输出

### Markdown 报告格式

```markdown
# linux-one-key v1.0 Docker 测试报告

**日期**: 2026-07-12
**提交**: eadc42e

## Phase 1: 配置验证

| 发行版 | SSH | FW | F2B | AUDIT | USERS | KERNEL | FS | SRV | 总计 |
|--------|-----|----|-----|-------|-------|--------|----|-----|------|
| Ubuntu 20.04 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| Ubuntu 22.04 | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | 8/8 |
| ...

**总计**: 68/72 (94.4%)
**失败详情**:
- Ubuntu 24.04 kernel: 预期 `net.ipv4.tcp_syncookies=1` 但文件不存在
- ...
```

### JSON 报告格式（CI 友好）

```json
{
  "date": "2026-07-12",
  "commit": "eadc42e",
  "phase": 1,
  "results": [
    {"distro": "ubuntu:22.04", "module": "ssh", "status": "pass", "detail": ""},
    {"distro": "centos:7", "module": "firewall", "status": "pass", "detail": ""}
  ],
  "summary": {"total": 72, "pass": 68, "fail": 4, "rate": 94.4}
}
```

## 8. 与 CI 集成（后续）

Phase 1 和 Phase 2 完成后，可添加 GitHub Actions workflow（不在本设计范围内，作为后续建议）：

```yaml
# .github/workflows/test.yml（建议）
on: [push, pull_request]
jobs:
  docker-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: tests/docker/test-all.sh --all
```

如果项目是公开仓库，GitHub Actions 免费额度足够运行完整测试（约 1 小时）。

## 9. 风险与注意事项

| 风险 | 影响 | 缓解 |
|------|------|------|
| Docker 在 macOS 上性能差（需 Linux VM） | Phase 1 尚可，Phase 2 可能慢 | Phase 2 建议在 Linux 主机或 CI 上跑 |
| systemd 镜像在不同架构上兼容性 | arm64 (M1/M2) 可能需要特定镜像 | 先用 amd64 测试，后续适配 |
| 部分发行版 Docker Hub 拉取限速 | 首次构建慢 | 提示用户 `docker login` 或使用国内镜像 |
| 内核 sysctl 在容器内效果有限 | 仅验证配置文件，不验证实际效果 | 在真实 VM 上做一次内核加固确认 |
| 测试脚本依赖 `bash` 4+ | macOS 默认 bash 3 | 测试脚本前检查 `BASH_VERSINFO` |

## 10. 设计决策

| 决策 | 选择 | 原因 |
|------|------|------|
| 测试框架 | 纯 Bash（不使用 Bats In Docker） | Bats 现有测试需要 mock，实际向导流程跑不通；新写端到端验证脚本更直接 |
| Dockerfile vs docker-compose | Dockerfile 简单构建 | 各镜像差异不大，不用 compose 增加复杂度 |
| 并行策略 | 构建并行 + 测试串行（按发行版） | 测试串行保证隔离，构建并行节省时间 |

## 11. 进度记录

| 日期 | 工作项 | 状态 |
|------|--------|------|
| 2026-07-12 | 设计讨论与方案确认 | ✅ 完成 |
| 2026-07-12 | Phase 1 实施（9 镜像 + 8 模块） | ✅ 完成 |
| 2026-07-12 | Phase 1 验证与修复（72/72 全部通过） | ✅ 完成 |
| 2026-07-12 | Phase 2 实施（systemd + 服务验证） | 🔄 进行中 |
| TBD | v1.0 正式发布 | ⬜ 待开始 |

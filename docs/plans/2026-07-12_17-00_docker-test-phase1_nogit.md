---
created: 2026-07-12
updated: 2026-07-12
status: in-progress
title: linux-one-key v1.0 Docker 测试 Phase 1 实施
source: design docs/design/docker-test-design.md
topic: testing
---

# Docker 测试 Phase 1 实施计划

## 背景

设计文档 (`docs/design/docker-test-design.md`) 已获批准。Phase 1 目标：在 9 个发行版的 Docker 容器中验证 8 个安全模块的配置输出。

## 实施步骤

### Step 1: 公共基础设施
- [ ] `tests/docker/lib/common.bash` — 构建镜像、容器执行、断言、报告
- [ ] `tests/docker/run-test.sh` — 单测试入口
- [ ] `tests/docker/test-all.sh` — 全量矩阵执行
- [ ] `.gitignore` 加入 `tests/docker/results/`

### Step 2: 发行版 Dockerfiles
- [ ] Ubuntu 20.04 / 22.04 / 24.04
- [ ] Debian 11 / 12
- [ ] CentOS 7
- [ ] Rocky Linux 8 / 9
- [ ] AlmaLinux 9

### Step 3: 模块测试脚本
- [ ] `tests/docker/tests/ssh.bash`
- [ ] `tests/docker/tests/firewall.bash`
- [ ] `tests/docker/tests/fail2ban.bash`
- [ ] `tests/docker/tests/audit.bash`
- [ ] `tests/docker/tests/users.bash`
- [ ] `tests/docker/tests/kernel.bash`
- [ ] `tests/docker/tests/filesystem.bash`
- [ ] `tests/docker/tests/services.bash`

### Step 4: 验证与修复
- [ ] 在至少 3 个发行版上运行 Phase 1
- [ ] 修复发现的跨发行版兼容性问题
- [ ] 输出测试报告

### Step 5: 文档同步
- [ ] 更新 `HANDOVER.md` 变更日志
- [ ] 更新设计文档进度记录

## 并行策略

SubAgent 分工：

| Agent | 负责 |
|-------|------|
| Agent A | common.bash + run-test.sh + test-all.sh |
| Agent B | 全部 Dockerfiles (9 个) |
| Agent C | 模块测试脚本 (8 个) |

依赖关系：Agent C 依赖 Agent A（需 common.bash 的接口）。但可以先并行写，因为接口已定义。

## 预期产出

```
tests/docker/
├── run-test.sh
├── test-all.sh
├── lib/common.bash
├── images/
│   ├── ubuntu/20.04.Dockerfile
│   ├── ubuntu/22.04.Dockerfile
│   ├── ubuntu/24.04.Dockerfile
│   ├── debian/11.Dockerfile
│   ├── debian/12.Dockerfile
│   ├── centos/7.Dockerfile
│   ├── rockylinux/8.Dockerfile
│   ├── rockylinux/9.Dockerfile
│   └── almalinux/9.Dockerfile
├── tests/
│   ├── ssh.bash
│   ├── firewall.bash
│   ├── fail2ban.bash
│   ├── audit.bash
│   ├── users.bash
│   ├── kernel.bash
│   ├── filesystem.bash
│   └── services.bash
└── results/ (gitignored)
```

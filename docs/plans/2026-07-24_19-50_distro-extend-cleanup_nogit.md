---
title: "发行版扩展 + Batch 1 验证 + Docker 计划状态修复"
created: 2026-07-24
updated: 2026-07-24
status: in-progress
source: "HANDOVER.md next-steps 发行版扩展 + Batch 1 plan 未检查项 + Docker test phase1 计划状态"
topic: "testing"
---

# 综合计划：发行版扩展 + Batch 1 验证 + Docker 计划状态修复

本计划包含三个独立但相关的任务，统一处理以降低上下文切换成本。

---

## Item 1: 发行版扩展

### 背景

当前 Docker 测试矩阵覆盖的 RHEL 系发行版：
- centos:7（yum，已 EOL）
- rockylinux:8 / rockylinux:9（dnf）
- almalinux:9（dnf）

缺失的覆盖：
- **fedora:latest** — Fedora 是 RHEL 的上游，使用 dnf 包管理器，可验证现代 RHEL 系兼容性
- **centos:stream9** — CentOS Stream 是 RHEL 的滚动上游，替代已 EOL 的 CentOS 8/9

### 实施步骤

#### 1.1 创建 Fedora Dockerfile

**路径**: `tests/docker/images/fedora/latest.Dockerfile`

Fedora 使用 dnf，与 RHEL 9/Rocky 9/Alma 9 一致。参照 `rockylinux/9.Dockerfile`。

关键点：跳过 `coreutils` 和 `curl`（`*-minimal` 版本预装会冲突）。不需要 EPEL 仓库。

#### 1.2 创建 CentOS Stream 9 Dockerfile

**路径**: `tests/docker/images/centos/stream9.Dockerfile`

CentOS Stream 9 使用 dnf。参照 `rockylinux/9.Dockerfile`。安装 `epel-release`。

#### 1.3 更新 test-all.sh

在 `PHASE1_DISTROS` 数组中新增 `"centos:stream9"` 和 `"fedora:latest"`，更新文件头注释。

#### 1.4 更新 HANDOVER.md

将发行版扩展部分标记为 ✅。

### 验收标准

- [ ] `tests/docker/images/fedora/latest.Dockerfile` 创建完成
- [ ] `tests/docker/images/centos/stream9.Dockerfile` 创建完成
- [ ] `test-all.sh` 的 `PHASE1_DISTROS` 包含两个新发行版
- [ ] HANDOVER.md 同步更新

---

## Item 2: Batch 1 全量测试验证

### 背景

`docs/plans/2026-07-24_batch1-init-utils_nogit.md` 最后一个验收标准 `[ ] All existing tests still pass` 从未勾选。

### 实施步骤

#### 2.1 运行全量 Bats 测试

```bash
cd /Users/charliepan/Downloads/linux-one-key
bats tests/unit/*.bats
```

预期：全部通过。

#### 2.2 更新 Batch 1 计划文件

- 将 `[ ] All existing tests still pass` 改为 `[x]`
- 更新 `updated:` 日期

### 验收标准

- [ ] `bats tests/unit/*.bats` 全部通过
- [ ] Batch 1 计划文件最后一格 checkbox 已勾选

---

## Item 3: Docker 测试 Phase 1 计划状态修复

### 背景

`docs/plans/2026-07-12_17-00_docker-test-phase1_nogit.md` 当前 `status: in-progress`，但全部工作已实际完成。

### 实施步骤

#### 3.1 更新 Frontmatter

`status: in-progress` → `done`，`updated` 更新为 `2026-07-24`。

#### 3.2 勾选所有 Checkbox

全部 `- [ ]` 改为 `- [x]`。

#### 3.3 补充完成说明

在文件末尾添加完成说明章节。

### 验收标准

- [ ] `status` 改为 `done`
- [ ] 全部 checkbox 已勾选
- [ ] 补充完成说明章节

---

## 执行顺序

```
Item 3 (最简单，先完成)
  → Item 2 (验证测试通过)
    → Item 1 (发行版扩展，依赖测试套件稳定)
```

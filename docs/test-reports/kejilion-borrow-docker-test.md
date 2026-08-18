# Kejilion 借鉴批次 Docker 集成测试报告

> **测试日期**: 2026-08-18
> **测试方式**: 项目本地仓库挂载进容器，逐项驱动新功能（`tests/docker/run-test.sh` 框架）
> **测试范围**: 科技lion 研究落地批次 A/B/C/D（`--version` / i18n 键集对称 / 写入安全护栏 / 状态感知子菜单）
> **测试工具**: OrbStack (Docker 29.4.0)
> **测试脚本**: `tests/docker/run-test.sh --distro <d:v> --module kejilion-borrow`
> **容器内脚本**: `tests/docker/smoke-kejilion-borrow.sh`
> **Git 版本**: `434e1ca`

---

## 测试方法

镜像使用项目现有 Phase 1 Dockerfile（`tests/docker/images/<distro>/<version>.Dockerfile`），
项目源码以只读挂载到 `/opt/linux-one-key`，容器内以 root 执行 `smoke-kejilion-borrow.sh`，
输出机器可读哨兵 `NAME=OK/FAIL`，host 侧 `run_test()` 逐条断言。

覆盖维度：

- **A. CLI 入口**: `install.sh --version` / `-V` / `--help`（含 `--version` 行）/ 未知参数仍拒绝（回归）
- **B. i18n 对称**: zh/en 语言包 `MSG_*` 键集 `comm -3` 双向比对
- **C. 写入安全护栏**: `assert_safe_config_target` 单元（符号链接/超大小/超行数/新文件）+ 4 处真实写点集成
  - C2: `/etc/ssh/sshd_config` 符号链接 → `set_ssh_config` 拒绝且不写穿；**正向**：恢复为正常文件后 `set_ssh_config` 仍成功写入（护栏不误伤）
  - C3: `/etc/sysctl.d/99-hardening.conf` 2MiB 超界 → `apply_sysctl_params` 提前拒绝且文件未动
  - C4: `/etc/sudoers.d/99-linux-one-key-sudo` 符号链接 → `_write_sudoers_dropin` 拒绝
  - C5: `/etc/fail2ban/jail.local` 符号链接 → `_configure_fail2ban_jail` 拒绝
- **D. 状态感知菜单**: `show_nginx_submenu` 渲染含 `状态: 未安装`；11 个 server 模块结构断言（`render_service_state_label check_<mod>_installed check_<mod>_running`）

## 测试结果

| 发行版 | 断言数 | 通过 | 失败 | 结果 |
|--------|--------|------|------|------|
| debian:12 | 23 | 23 | 0 | ✅ PASS |
| ubuntu:22.04 | 21 | 21 | 0 | ✅ PASS |
| almalinux:9 | 21 | 21 | 0 | ✅ PASS |

详细日志（harness 自动保存）：`tests/docker/results/<distro>-<version>-kejilion-borrow.log`

## 结论

- 三个发行版（apt / deb 系 + RHEL 系）全部 21/21 通过
- 写入护栏在真实 `/etc` 路径上验证有效：符号链接目标拒绝写入、超界文件拒绝覆盖且原文保持不变
- `--version` / `--help` / 未知参数拒绝行为与 macOS 本地验证一致
- 状态菜单在容器内（未安装场景）正确显示 `状态: 未安装`

## 复现方法

```bash
bash tests/docker/run-test.sh --distro debian:12 --module kejilion-borrow
bash tests/docker/run-test.sh --distro ubuntu:22.04 --module kejilion-borrow
bash tests/docker/run-test.sh --distro almalinux:9 --module kejilion-borrow
```

#!/usr/bin/env bash
# 容器内冒烟测试：kejilion 借鉴批次新功能（A: --version / B: i18n 对称 / C: 写入护栏 / D: 状态菜单）
# 由 tests/docker/tests/kejilion-borrow.bash 驱动；输出机器可读哨兵 SENTINEL=OK/FAIL
set -euo pipefail

export SCRIPT_DIR=/opt/linux-one-key
export LOG_DIR=/tmp/log
export BACKUP_DIR=/tmp/log/backups
# 模拟 run_detection 的结果（真实流程由 detect.sh 设置，冒烟测试直接给值）
export DETECTED_OS=debian
mkdir -p "${BACKUP_DIR}"

echo "=== A: install.sh --version / -V / --help ==="
bash install.sh --version > /tmp/v1.out 2>&1 && echo "A_VERSION_EXIT=OK" || echo "A_VERSION_EXIT=FAIL"
grep -q "linux-one-key v" /tmp/v1.out && echo "A_VERSION_LINE=OK" || echo "A_VERSION_LINE=FAIL"
grep -q "最近更新" /tmp/v1.out && echo "A_VERSION_RECENT=OK" || echo "A_VERSION_RECENT=FAIL"
bash install.sh -V > /tmp/v2.out 2>&1 && echo "A_ALIAS_V=OK" || echo "A_ALIAS_V=FAIL"
bash install.sh --help 2>/dev/null | grep -q -- "--version" && echo "A_HELP_VERSION=OK" || echo "A_HELP_VERSION=FAIL"
if bash install.sh --bogus-arg 2>/dev/null; then echo "A_UNKNOWN_REJECT=FAIL"; else echo "A_UNKNOWN_REJECT=OK"; fi

echo "=== B: zh/en MSG_* key symmetry ==="
if comm -3 <(grep -oE '^MSG_[A-Za-z0-9_]+' scripts/lang/zh.sh | sort -u) \
           <(grep -oE '^MSG_[A-Za-z0-9_]+' scripts/lang/en.sh | sort -u) | grep -q .; then
    echo "B_SYMMETRY=FAIL"
else
    echo "B_SYMMETRY=OK"
fi

echo "=== C: assert_safe_config_target + write guard ==="
source scripts/base/utils.sh
load_lang /opt/linux-one-key

echo "Port 22" > /tmp/real.conf
ln -s /tmp/real.conf /tmp/link.conf
if assert_safe_config_target /tmp/link.conf; then echo "C_GUARD_SYMLINK=FAIL"; else echo "C_GUARD_SYMLINK=OK"; fi
head -c 2048 /dev/zero > /tmp/big.conf
if assert_safe_config_target /tmp/big.conf 1024; then echo "C_GUARD_SIZE=FAIL"; else echo "C_GUARD_SIZE=OK"; fi
seq 1 20 > /tmp/many.conf
if assert_safe_config_target /tmp/many.conf 1048576 10; then echo "C_GUARD_LINES=FAIL"; else echo "C_GUARD_LINES=OK"; fi
if assert_safe_config_target /tmp/newfile.conf; then echo "C_GUARD_NEW=OK"; else echo "C_GUARD_NEW=FAIL"; fi

echo "--- C2: set_ssh_config 拒绝符号链接 /etc/ssh/sshd_config（写穿防护） ---"
mv /etc/ssh/sshd_config /tmp/sshd_config.real
ln -s /tmp/sshd_config.real /etc/ssh/sshd_config
if set_ssh_config Port 2222; then echo "C_SETSSH_SYMLINK=FAIL"; else echo "C_SETSSH_SYMLINK=OK"; fi
if grep -qE '^Port[[:space:]]+2222' /tmp/sshd_config.real; then echo "C_SETSSH_WRITETHRU=FAIL"; else echo "C_SETSSH_WRITETHRU=OK"; fi
rm -f /etc/ssh/sshd_config
mv /tmp/sshd_config.real /etc/ssh/sshd_config

echo "--- C3: kernel 超界目标 → apply_sysctl_params 提前拒绝 ---"
source scripts/security/kernel.sh
mkdir -p /etc/sysctl.d
head -c 2097152 /dev/zero > /etc/sysctl.d/99-hardening.conf
if apply_sysctl_params; then echo "C_KERNEL_OVERSIZE=FAIL"; else echo "C_KERNEL_OVERSIZE=OK"; fi
sz=$(wc -c < /etc/sysctl.d/99-hardening.conf)
if [ "${sz}" -ge 2000000 ]; then echo "C_KERNEL_UNTOUCHED=OK"; else echo "C_KERNEL_UNTOUCHED=FAIL"; fi
rm -f /etc/sysctl.d/99-hardening.conf

echo "--- C4: sudoers drop-in 符号链接 → _write_sudoers_dropin 拒绝 ---"
source scripts/security/sudo.sh
touch /tmp/sudoers_hijack
mkdir -p /etc/sudoers.d
ln -s /tmp/sudoers_hijack /etc/sudoers.d/99-linux-one-key-sudo
if _write_sudoers_dropin; then echo "C_SUDO_SYMLINK=FAIL"; else echo "C_SUDO_SYMLINK=OK"; fi
rm -f /etc/sudoers.d/99-linux-one-key-sudo

echo "--- C5: fail2ban jail.local 符号链接 → _configure_fail2ban_jail 拒绝 ---"
source scripts/security/fail2ban.sh
mkdir -p /etc/fail2ban
ln -s /tmp/sudoers_hijack /etc/fail2ban/jail.local
if _configure_fail2ban_jail 22 /var/log/auth.log; then echo "C_F2B_SYMLINK=FAIL"; else echo "C_F2B_SYMLINK=OK"; fi
rm -f /etc/fail2ban/jail.local

echo "=== D: 状态感知子菜单 ==="
source scripts/server/nginx.sh
show_nginx_submenu > /tmp/menu.out 2>/dev/null
grep -q "状态" /tmp/menu.out && echo "D_MENU_STATE=OK" || echo "D_MENU_STATE=FAIL"
grep -qE "未安装|运行中|未运行" /tmp/menu.out && echo "D_MENU_LABEL=OK" || echo "D_MENU_LABEL=FAIL"

fail=0
for pair in docker:docker nginx:nginx redis:redis postgres:postgresql mysql:mysql memcached:memcached node_exporter:node_exporter prometheus:prometheus grafana:grafana rabbitmq:rabbitmq k3s:k3s; do
    mod="${pair%%:*}"
    file="${pair##*:}"
    if ! grep -q "render_service_state_label check_${mod}_installed check_${mod}_running" "scripts/server/${file}.sh"; then
        echo "D_STRUCT_${mod}=FAIL"
        fail=1
    fi
done
[ "${fail}" -eq 0 ] && echo "D_STRUCT_ALL=OK"

echo "SMOKE_DONE"

# 科技lion（kejilion.sh）学习研究报告

> **日期**: 2026-08-18 · **版本**: v4.5.7 · **克隆位置**: `科技lion脚本/sh/`（未纳入版本管理）
> **范围**: 文档 / 脚本逻辑设计 / 代码逻辑 / 测试方法 4 个视角 + Docker 实测
> **结论先行**: 借鉴其"交互 + 非交互双入口"、"包管理器/服务抽象"、"CLI 别名层"与"更新校验"，
> 不模仿其单文件 monolith、无 `set -e`、状态持久化 hack、默认开启埋点。

---

## 1. 总览

| 维度 | kejilion.sh | 本项目（linux-one-key） |
|------|-------------|------------------------|
| 形态 | 单文件 28,498 行（882KB） | 多文件模块化（scripts/base, security, server, dev, lang） |
| 入口 | 交互主菜单 + `k` CLI 子命令 + `KJ_*` 非交互协议 | install.sh 菜单 + `--lite/--status/--json` 等参数 |
| 包管理 | 自研 `install()/remove()` 包装（8 种 PM） | utils.sh 抽象 |
| 服务管理 | 自研 `systemctl()` 包装（Alpine→service） | systemd drop-in 为主 |
| 测试 | 无 Bats，纯"结构契约冒烟测试"（grep/awk 提取函数体断言） | 805 Bats 单测 + Docker CI |
| i18n | 7 语言整文件翻译副本 + Python 转换脚本 + GH Actions | MSG_* 变量 + lang/zh.sh, en.sh |
| 错误处理 | 无 set -e，缺命令静默降级 | set -euo pipefail + log_* + 备份回滚 |
| 状态持久化 | sed 改自身安装副本（~/kejilion.sh 变量值） | /var/log/linux-one-key/ + .meta sidecar |
| 遥测 | send_stats 异步埋点（默认开，可关） | 无 |
| 自更新 | 有（range 请求查版本 + 临时文件校验 + 备份回滚 + cron 自动更新） | 无（可考虑） |

---

## 2. Docker 实测记录（OrbStack）

在 OrbStack 中用 `debian:bookworm-slim` 实际运行了 `kejilion.sh`（容器内 root）：

### 2.1 运行结果

- 主菜单正常渲染：ASCII logo + 16 个主菜单项 + `00 脚本更新` + `0 退出`，配色分层（青/黄/白）。
- 子菜单演示：选 `1 系统信息查询` → 清屏动画 + "正在查询系统信息……" → 信息面板
  （主机名/系统/内核/CPU/内存/硬盘/网络收发/**运营商与地理 IP**/DNS/时间/运行时长）。
  - 地理位置来自外部 API（`ipinfo.io`），容器里 `free/uptime/sysctl/ss` 缺失时
    **逐条报 "command not found" 后继续**（无 set -e 的典型表现，面板字段留空）。
- CLI 子命令：`bash kejilion.sh info` 与菜单项 1 输出相同；`bash kejilion.sh en` 打印
  内置 **`k` 命令速查表**（约 40 条，含中文别名，如 `k 安装 nano wget`、`k 启动 sshd`）。
- 应用市场：`bash kejilion.sh app` 先自动安装 git（`install_dependency` 顺带跑了
  `switch_mirror / check_port / check_swap / prefer_ipv4 / auto_optimize_dns`），再联网拉应用列表。

### 2.2 脚本对系统的真实改动（docker diff 佐证）

- 修改 `/root/.bashrc`、`/root/.profile`（清掉旧 `alias k=` 后重写）。
- 尝试自安装：`cp kejilion.sh ~/kejilion.sh` + 复制到 `/usr/local/bin/k` + 软链 `/usr/bin/k`。
  - ⚠️ 实测发现非原子缺陷：源码 `./kejilion.sh` 缺失时复制静默失败，但
    `/usr/bin/k -> /usr/local/bin/k` **悬空软链照样被创建**。
- `auto_optimize_dns`：按国家改写 DNS（CN→223.5.5.5/183.60.83.19，其他→1.1.1.1/8.8.8.8）；
  `prefer_ipv4` 向 `/etc/gai.conf` 追加 IPv4 优先。
  - 结论：**只是打开应用市场就会触发全局 DNS/网络栈修改**——这正反衬本项目
    "修改前备份 + 幂等检查 + 确认"纪律的价值。

### 2.3 自更新机制实测

- `curl -r 0-200` range 请求只拉文件头 200 字节解析 `sh_v="4.5.7"`（实测可用，200B 对比 882KB）；
- 中国 IP 走 `cn/kejilion.sh` 镜像；下载到 `mktemp` 临时文件，校验非空 + `#!/bin/bash`
  shebang 后才 `mv` 替换；先 `cp ~/kejilion.sh ~/kejilion.sh.bak`，失败自动回滚；
- 更新后重放状态补丁（canshu_v6 / CheckFirstRun_true / yinsiyuanquan2）再同步到 `/usr/local/bin/k`；
- 支持 cron 每天凌晨 2 点自动更新（菜单 2/3 开关，检查 crontab 里是否已有该 job）。

---

## 3. 文档视角（README / 多语言 / 更新日志）

### 3.1 README 结构（161 行，营销型范本）

首屏 logo → 4 个徽章（stars/forks/last-commit/license）→ 7 语言切换条 → TOC →
中英双语内联的介绍与功能清单 → 安装命令 + **`> [!IMPORTANT]` GitHub Alert 警示** →
10 发行版兼容徽章 → 效果图 → 使用与安全 → 打赏（USDT）→ Star History 图。

对"安全加固脚本"项目最值得借鉴的 4 点：
1. **"使用与安全"四段式**（仅从官方域名获取 / 定期备份 / 高风险操作前确认影响范围 / 反馈时脱敏）
   ——本项目 install.sh 有大量破坏性操作，README 完全可以补一段等价的安全提示。
2. **GitHub Alert 警示块**（`> [!IMPORTANT]`）置于安装命令正下方，零成本高可见度。
3. **test / shellcheck 徽章**：把 805 Bats 通过率、ShellCheck clean 亮出来（本项目测试是
   核心竞争力，README 目前未突出）。
4. **兼容矩阵徽章**（10 发行版）——本项目 README 已有类似意识，可规范成徽章行。

### 3.2 多语言方案：整文件翻译副本（结论：不采用）

- 机制：6 个语言目录各放一份 1.2~2.8 万行的 `kejilion.sh` 整文件翻译副本；
  `translate.py` 用**正则保护 `$var` 与引号字符串** + 免费 GoogleTranslator 机翻；
  CI（translate.yml）每周 cron 自动翻译直推 main（只覆盖 en/tw/kr/jp，ru/ir 不在 CI）。
- 实测问题：**5 份翻译副本全部滞后**（en 停在 v4.5.5，ru/ir 停在 v3.9.3，主脚本已 v4.5.7）；
  残留中文（en 副本 414 行仍是中文提示，如 en/kejilion.sh:532）；机翻术语错误
  （README.kr.md:61 "대본"、README.ru.md:80 西里尔 `</р>` 标签被机翻）。
- 结论：整文件副本 + 机器翻译 = **同步维护地狱**。本项目"`MSG_*` 变量 + 语言包 source +
  Bats 对称性测试"（mirror.bats 已用同思路）是正确选择，继续坚持即可；
  可补一条 CI：对比 en/zh 语言包的 key 集合是否对称（已有，保持）。

### 3.3 更新日志与发版纪律

- `kejilion_sh_log.txt`：3 年 335 块的活日志源，脚本在线 `tail -n 30` 拉取展示——
  "日志单源，脚本内联展示"值得借鉴（本项目日志在 HANDOVER.md，可考虑在脚本 `--version`
  或菜单里内联最近变更）。
- `update_log.sh`：停在 v2.5.1 且无人调用的死代码——教训：**版本号/日志/README 三处同步发版**，
  否则必然漂移；README 安装命令的 `en` 参数与脚本实现脱节（实测 `en` 实际无分支，落到速查表）
  也是同一类"文档与实现不同步"问题。

---

## 4. 脚本逻辑设计视角（结构/菜单/入口）

数据：28,498 行、**515 个函数**（全部 `name() {` 风格，0 个 `function` 关键字）、**90 个 `while true` 自绘菜单循环**、**498 处 `read`（其中 `read -e -p` 369 处）**、文件末尾巨型 `case $1` CLI 分发。

### 4.1 双入口设计：交互菜单 + CLI 子命令

- 交互入口：主菜单 `while true; clear; echo -e 手绘边框+ANSI 颜色; read -e -p; case` 循环
  （不用 `select`；"返回上级"= 直接调用主菜单函数，如 `0) kejilion`）。
- 菜单绘制细节：分隔线就是 `echo -e "${gl_kjlan}-----...${gl_bai}"`；两列排版用
  `printf "%-42s %s\n"` 定宽对齐（linux_tools，9725 行附近）；`break_end()`（380 行）用
  `read -n 1 -s -r -p ""` 实现"按任意键继续"。
- **菜单即状态面板**：部分菜单绘制前先探测状态生成彩色状态串（docker 菜单的
  `docker_tato`/`check_docker_app`，如 2616 行），"已安装/未安装/运行中"直接体现在菜单项上。
- **root 守卫模式**：`root_use()`（7104 行）非 root 时提示 + `break_end` + 回到主菜单，
  而非直接退出——保留菜单上下文，交互友好。
- CLI 入口：文件尾部 `case $1` 把每个子命令映射到菜单同款函数，且**每个命令都有中文别名**
  （`k install` / `k add` / `k 安装`），末尾 `*)` 落到 `k_info` 速查表——天然的教学入口，
  新用户敲错命令也能看到全量用法。
- 这解释了"主菜单 + k 命令"双形态能长期共存：**菜单函数本身就是 CLI 函数**，零额外维护成本。
  本项目 install.sh 只有参数没有子命令体系，可评估给每个菜单项补一个 `--xxx` 或 `install.sh xxx` 别名层。

### 4.2 KPanel 非交互协议（最有借鉴价值的模式）

`KJ_*_NONINTERACTIVE=1` 环境变量 + `kpanel_xxx_noninteractive()` 适配层：

```bash
kpanel_ssh_port_noninteractive() {
    [ "${KJ_SSH_PORT_NONINTERACTIVE:-}" = "1" ] || return 2   # 协议守卫
    # root 检查 / 参数个数 / 输入校验（1-65535）/ 配置非符号链接 / 工具可用 / sshd -t 预校验
    # 幂等：已是指定端口 → 输出 KPANEL_SSH_RESULT unchanged 直接返回
    new_ssh_port "$new_port" || return 1                      # 复用交互主业务
    # 回读验证 + sshd -t + ss -ltn 轮询监听（10×0.2s）→ KPANEL_SSH_RESULT applied
}
```

- 适配层**只做校验和机器可读结果，绝不复制主业务改动逻辑**（测试专门断言这一点）。
- 输出 `KPANEL_SSH_RESULT applied|unchanged`、`KPANEL_SSH_PORT <port>` 等稳定契约，
  供 KPanel Web 后端当作"脚本 API"调用；同时是 23 个 smoke 测试可测性的来源。
- **写入安全护栏**（KPanel 区段，23017-26210 行，全文件工程化最高处）：
  - 目标文件先做**边界校验**：`kpanel_system_resource_file_within_bounds "$path" 262144 1024`
    （256KiB / 1024 行上限）；
  - 拒绝符号链接（`[ ! -L "$path" ]`）、`mkdir "$lock_dir"` 锁目录防并发写；
  - 恢复前做**版本哈希比对**，失败输出机器可读 `..._emit failed`。
- 对应到本项目：`check.sh --json` 已是同类思路；可把"环境变量守卫 + 机器可读结果"模式
  推广到 ssh/firewall 等模块，让 Web 面板与 Bats 都能安全驱动同一份业务代码。
- 附带：进度条只在非交互协议里有（`kpanel_app_progress` → `KPANEL_PROGRESS n msg`），
  交互模式无等待动画——"进度上报"也是协议化输出的一部分。

### 4.3 包管理器与服务抽象

- `install()` / `remove()`：按 `command -v dnf/yum/apt/apk/pacman/zypper/opkg/pkg` 分派，
  缺失才装；每次先 `update` 再装（稳健但慢）。⚠️ 直接**遮蔽了 coreutils `install`**，是危险命名。
- `systemctl()`：Alpine（apk）→ `service`，否则 `/bin/systemctl`；其上再包 `start/stop/restart/status/enable`。
- 本项目 utils.sh 已有等价抽象且更安全（不遮蔽系统命令），无需照搬，可核对是否覆盖 apk/zypper。

### 4.4 环境自举与状态持久化（不模仿）

- 启动时静默 `cp -f ./kejilion.sh ~/kejilion.sh` + 复制 `/usr/local/bin/k` + 软链 `/usr/bin/k`，
  把自己装成全局 `k` 命令（**无 curl-pipe 检测**，靠复制自举）。
- 状态持久化：`CheckFirstRun_true()` 用 **sed 改自身安装副本里的变量值**
  （`permission_granted="false"` → `"true"`），`canshu_v6`/`yinsiyuanquan2` 同理。
  脆弱、不可审计；本项目应坚持 `/var/log/linux-one-key/` + `.meta sidecar`。

---

## 5. 代码逻辑视角（实现细节与风险）

### 5.1 亮点

- **省带宽版本检查**：`curl -r 0-200` 只取文件头 200B 解析 `sh_v="..."`（实测可用）。
- **原子自更新**：`mktemp` 临时文件 → 校验非空 + shebang → `mv` 替换；先 `cp .bak`，失败回滚；
  中国 IP 路由到 `cn/kejilion.sh` 镜像；更新后重放状态补丁再同步 `/usr/local/bin/k`；cron 自动更新。
- **原子写入 + 锁目录 + 版本哈希校验**（KPanel 相关区段）：下载资源前校验哈希，写入用锁目录防并发。
- **配置落盘 sysctl.d**：内核调优写入 `/etc/sysctl.d/99-kejilion-optimize.conf`（8028 行）而非直接
  sysctl，注释明说"统一写入 sysctl.d 以防与内核调优模块打架"——与本项目 kernel.sh drop-in 思路一致。
- **容器镜像更新检测**（2657 行）：ghcr.io 走 GitHub Release API、Docker Hub 走 registry digest，
  并把引用规范化为 `repo:tag` 再对比——"镜像源感知的更新检查"。
- **按国家镜像路由**：`quanju_canshu` 里 `gh_proxy` + CN/V6 双模式，`zhushi` 变量控制 `run_command()`
  是否真实执行（注释模式）——一个"dry-run 开关"的朴素实现。
- **功能埋点 send_stats**：异步子 shell POST 到自家 API（版本/国家/架构/功能名），透明注释 + 可关
  （`ENABLE_STATS=false`），`&` 后台不阻塞主流程。

### 5.2 弱点（实测 + 静态确认）

- **无顶层 `set -e/-u/pipefail`**：实测缺 `free/uptime/sysctl/ss` 时逐条报错仍继续，
  面板字段留空但整体显示"操作完成"——静默失败被包装成成功；管道错误也吞
  （`docker ps -a -q 2>/dev/null | wc -l` 在 docker 未装时输出 `0` 而非报错）。
- **命令注入风险**：`read -e -p` 后直接 `$dockername` 展开执行用户输入（docker_ps 531-532 行
  "请输入创建命令: " 把整行输入当命令执行，无二次确认；其余 `docker start $dockername`
  类未加引号展开，含空格/通配符会裂词）。
- **交互健壮性差**：`read -e -p` 无超时、无 `/dev/tty` 重定向——cron/管道/非交互调用时
  `read` 读到 EOF 直接空选择或死循环；菜单输入范围外值多无兜底（部分有 `*)` 提示）。
- **外部 API 无降级**：`ipinfo.io`/`api.github.com`/`linuxmirrors.cn` 贯穿主流程（连菜单绘制
  前都 curl），网络抖动直接卡死菜单。
- **686 处硬编码路径**（`/home/web`、`/home/docker`、`~/kejilion.sh`…用户无法自定义安装位置）、
  **47 处重复的包管理器判定链**（同一段 if 链复制粘贴 47 次）、docker_ps 四个 case 几乎逐字复制。
- **字符串版本比较**（`"$sh_v" = "$sh_v_new"`，v10 会小于 v9）；`update_log.sh` 已废弃（止于 v2.5.1），
  现维护 `kejilion_sh_log.txt`。
- **文件头无任何注释/license 头**；菜单靠 `read -e -p` 全手动，无 select/方向键。
- **自安装非原子**：实测源码缺失时复制静默失败，但 `/usr/bin/k` 悬空软链照样生成。

---

## 6. 测试方法视角（外围脚本与冒烟测试）

### 6.1 外围脚本速写

- **游戏服务器管理器**（mc.sh / palworld.sh）：不是 systemd 管理，而是"菜单壳 + Docker/tmux"
  （`docker start/stop` + `tmux kill-session`）。可借鉴点：**状态感知菜单**——渲染菜单前先探测
  安装/运行状态并显示（mc.sh:120-138），菜单项随状态变化（未安装→安装，已运行→停止）；
  状态行还会拼公网 IP（`curl ipv4.ip.sb`，mc.sh:4-20）。
  - 备份 = 菜单引导 `docker cp` + `tar czvf mcsave_$(date +%Y%m%d%H%M%S).tar.gz`，并把
    `mc_backup.sh` 注册进 crontab（`(crontab -l; echo "0 3 * * * ./mc_backup.sh") | crontab -`，
    mc.sh:307-321）——⚠️ 重复执行菜单项会**累积重复 cron 行**（无去重），且 `./mc_backup.sh`
    相对路径依赖 cwd，cron 下会找不到文件。
  - 版本更新：脚本自更新 = `curl -sS -O https://kejilion.pro/mc.sh` 直接覆盖当前脚本；
    游戏更新 = `docker restart` + steamcmd `app_update`。
- **配置模板三种用法**：外部模板 fetch + `docker cp`（kejilion.sh:2500-2524，**无版本锁定、
  无校验和、无备份**，覆盖即永久）；`sed -i` 占位符替换（ldnmp.sh:31-33，密码含 `/&\\` 会
  破坏 sed 或注入任意替换）；heredoc 生成（manager 脚本的 systemd unit）。
  - **模板档位化**：www.conf / www-1.conf 是 standard/high 双档位（`pm.max_children 20 vs 10`），
    custom_mysql_config.cnf / -1.cnf 同理，由模式选择源文件——"一个模板两档预设"值得学。
  - **模板语义分工**：fail2ban-nginx-cc.conf（filter: failregex/ignoreregex）、cloudflare.conf
    （action: curl 调 CF API v4 封禁/解封）、nginx.local / sshd.local（jail: `enabled = true;
    chain = DOCKER-USER`）——filter/action/jail 三类文件分开维护。
- **TG 通知**：统一 `curl POST sendMessage`；监控型 = tmux 长驻进程 + `@reboot` crontab 拉起
  （非 systemd timer），指标采集用 `/proc/stat` 差分算 CPU、`awk` 累加 `/proc/net/dev` 算流量、
  `bc -l` 比浮点；SSH 登录型 = 读 sshd 注入的 `$SSH_CONNECTION` 取 IP + 百度 opendata 查归属地。
  ⚠️ TG-SSH-check-notify.sh 引用了**从未定义的 token/chat_id**（静默失败 bug）；无重试、无节流。
- **工程化最高的两个脚本**（deepseek_harness_manager.sh / hermes_manager.sh，本仓库亦有关联）：
  18 个可用环境变量覆盖的路径（**测试缝**）、输入校验（API key 正则/域名白名单/模型 ID 字符集）、
  `mktemp + umask 077 + chmod 600 + mv` 原子写、多步操作回滚函数、幂等 appno 标记（grep -qxF 去重）、
  卸载 `rm -rf` 白名单 + y/N 确认、运行态分层探测（systemd is-active → pidfile → pgrep）、
  `BASH_SOURCE` 守卫可被 source 测试。
  - hermes 的独特结构：**Python heredoc 当"配置 CRUD 服务"内嵌在 bash 函数里**（get_info/list_p/
    add_p/bulk_add/del_p/switch，24-238 行），shell 只做 UI 编排；模型同步用 `comm -13/-23`
    算新增/删除；PyPI 版本检查带 6h 缓存 + 后台刷新 + mkdir 锁；交互选择用 gum、降级编号输入。
  - 风格差异：hermes 更"UI 重"（clear/颜色/gum），deepseek 更"运维重"（校验/回滚/systemd）——
    deepseek 的设计完全围绕可测试性，是更值得学的那个。

### 6.2 冒烟测试技术（无 Bats，纯 bash）

1. **契约 grep**：`grep -F '[ "${KJ_F2B_NONINTERACTIVE:-}" = "1" ] ||'` 断言函数/守卫/协议标记
   存在；还断言旧交互菜单仍在（`grep -F '1. 安装防御程序'`），防协议层吞掉原功能。
2. **awk 函数抽取 + 桩 + eval 切片单测**：按 `^funcname\(\) \{` 到 `^}$` 锚点从 monolith 切出
   单个函数，前置 no-op 桩（`break_end(){ return 0; }`、`send_stats(){ return 0; }`）再 eval；
   test_kpanel_app 一次抽取 13 个函数体做状态机测试。⚠️ 锚点脆弱：函数体嵌套 `}` 会截断，
   必须锚 `^}$`。
3. **非交互协议真跑**：`KJ_BBRV3_NONINTERACTIVE=1 LC_ALL=C.UTF-8 bash kejilion.sh bbrv3 status`
   真实执行，再 `grep -Fx 'KPANEL_BBRV3_PROTOCOL 1'` / `grep -F 'KPANEL_BBRV3_STATUS {"supported":'`
   断言机器可读输出——**"如何模拟交互输入"的答案是：不是喂 stdin，而是用环境变量切非交互协议模式**。
4. **mock 二进制 + PATH 前置 + 临时 HOME 沙箱**：`mktemp -d` + 造假 docker/curl/npm/systemctl/
   python3 放 `$tmp/bin` + `PATH="$tmp/bin:$PATH"` + HOME 指临时目录；假 python3 甚至 monkeypatch
   `urllib.request.urlopen` 伪造 `/models` 响应；`source` 管理脚本后直接调函数，`stat -c '%a'`
   断言 600 权限；bash 跑完后用 Python heredoc 断言副作用文件内容/调用日志/备份存在性。
5. **跨语言副本同步守护**：`test_cn_script_sync.sh` 用 sed 把 `canshu` 归一化为 REGION 后
   `cmp -s`，强制 cn 版只允许 canshu 差异；kpanel 测试还要求适配层函数体在 zh/en 副本间
   **逐字节相同**（awk 抽取后直接比对）。
6. **测试卫生惯例**：`set -euo pipefail`、`trap 'rm -rf "$tmp"' EXIT`、`KEEP_WORKDIR=true`
   保留现场、`bash -n` 语法检查、结尾 `printf '%s\n' "xxx_smoke=pass"` 机器可读标记。

### 6.3 与 Bats 对比（结论）

- Bats（本项目）：真单测、断言丰富、CI 友好；冒烟测试（kejilion）：契约级、依赖 grep/awk、
  **未接入任何 CI**（唯一 workflow 是每周自动翻译 translate.yml——周日 02:00 cron +
  deep-translator 全量重译 en/tw/kr/jp，`git diff --staged --quiet` 判断有无变化才 commit，
  `GITHUB_STEP_SUMMARY` 输出各语言 ✅/❌ 表格）。
- 值得吸收的：**协议层测试缝**（环境变量切换非交互模式）、**mock PATH + 临时 HOME 沙箱**、
  **归一化 diff 守护 i18n 对称性**（本项目 mirror.bats 已有 MSG_MIRROR 对称测试，同思路）。
- 移植路线：这套技术可原样搬进 Bats（`run` + `assert_output --partial 'KPANEL_*'`、@test 内
  `source` 规避子 shell 不共享函数的坑、mock bin 目录 + PATH 注入），Bats 补齐报告/隔离/CI。

### 6.4 外围脚本风险清单（不模仿）

- beifen.sh 硬编码 `sshpass -p 123456`（明文密码 + 环回地址占位，直接跑要么泄露要么失败）；
  `iptables -F` + `ip6tables -F` 无确认（auto_cert_renewal-1.sh:28-34，续签脚本直接 wipe 防火墙）；
- **OpenSSH 升级无回滚**（upgrade_openssh9.8p1.sh：`make install` 覆盖系统 ssh 后 `mv ssh ssh.bak`
  + `ln -s`，中途失败直接断 SSH 管理通道，仅开始前一个 Y/N）；
- **auto_cert_renewal.sh 停 nginx 无 trap**：standalone 路径 `docker stop nginx`（75 行）后若
  certbot 失败，nginx 不会自动恢复，网站长时间下线；`--email your@email.com` 硬编码；
- **mc.sh 复制粘贴残留**：更新逻辑里 `app_update 2394010` 是帕鲁 appid，Minecraft 容器里根本没有
  steamcmd 路径（395 行）——选"更新"必失败；存档导出写 `/home/game/mcsave_*` 导入读
  `/home/game/mc/*.tar.gz`，文件名对不上，导入必失败（283 vs 291 行）；
- **TG-check-notify.sh**：`$public_ip` 从未定义（14 行）国家恒空；token 是中文占位符不配置就
  静默失败；`check_and_notify $CPU_USAGE "CPU"` 未加引号有分词风险；依赖 bc/jq 无安装检查；
- **Limiting_Shut_down.sh**：流量超阈值 `shutdown -h now` 无"已关机"幂等保护，阈值硬编码 110GB，
  /proc/net/dev 多网卡解析异常即误关机；
- **ldnmp.sh**：`read -p` 明文回显密码 + `sed -i "s/webroot/$dbrootpasswd/g"` 注入风险；无 set -e；
- **hermes_manager.sh**：`api_management_submenu` 滥用 clear（497 行）破坏可审计性；
  `config_tool` 把 API key 明文写 `~/.hermes/config.yaml` 无权限收紧提示（148-156 行）；
- **cloudflare.conf 泄露真实邮箱**（`cfuser = kejilion@outlook.com` 随公开仓库分发）；
  nginx.local 的 `ignoreip = 192.168.0.1/24` 等占位值直接部署会放行错误网段；
- 冒烟测试没进 CI → 脚本演进后契约静默漂移（唯一 workflow 是翻译，tests/ 全靠手动）。

---

## 7. 可落地借鉴清单（综合，按优先级）

**P0 — 直接可做，收益大**

1. **CLI 子命令别名层**：仿 `k install/启动 sshd/安装 nano`，给 install.sh 每个菜单项加
   子命令 + 中文别名（`install.sh 加固 ssh` / `install.sh 启动 docker`）。菜单函数即 CLI 函数，
   零额外维护。配套一个内置"命令速查表"（未知参数时打印全量用法，天然教学入口）。
2. **环境变量非交互协议**：仿 `KJ_*_NONINTERACTIVE=1` + 机器可读结果
   （`KPANEL_SSH_RESULT applied|unchanged`）：给 ssh/firewall 等模块加
   `LNOK_*_NONINTERACTIVE=1` 守卫，适配层只做校验/结果、复用主业务，供 Bats 与未来 Web 面板
   安全驱动同一份代码。check.sh --json 已是同方向，可统一协议风格。
3. **省带宽版本检查**：自更新/版本检查用 `curl -r 0-200` range 请求读版本号，
   只下载 200B 而非整包（本项目无自更新，未来加时直接用）。
4. **原子自更新模式**（未来做 self-update 时）：mktemp + 非空/shebang 校验 + mv 替换 +
   .bak 回滚 + 失败恢复——这套样板已实测可用。

**P1 — 值得吸收的工程技巧**

5. **状态感知菜单**：菜单渲染前先探测安装/运行状态，菜单项随状态变化（未安装→安装按钮，
   已运行→停止按钮）。本项目服务软件菜单可照做。
6. **mock PATH + 临时 HOME 沙箱**：Bats 测试里用假二进制前置 PATH、隔离 HOME，
   断言文件副作用——比只 mock 环境变量更强。
7. **归一化 diff 守护 i18n 对称性**：语言包 key 集合对称测试（mirror.bats 已有同思路，
   推广到 zh/en 全量）。
8. **heredoc 生成配置 + 双档位预设**：systemd unit/配置文件用 heredoc 生成；
   一个配置两个预设档（standard/high，对应 www.conf/www-1.conf 思路）。
9. **配置落盘 sysctl.d / drop-in**：内核与系统参数用 drop-in 文件，与 kernel.sh 现状一致，保持。
10. **写入安全护栏**：目标文件先做边界校验（大小/行数上限）、拒绝符号链接、锁目录防并发、
    恢复前哈希比对——本项目加固写配置时可补"文件边界校验"（防止被替换成超大/符号链接文件）。
11. **测试缝（env 覆盖路径）**：关键路径允许环境变量覆盖（deepseek/hermes manager 各 18 处），
    便于测试与用户自定义。
12. **输入校验先行**：API key 正则 / 域名白名单 / 模型 ID 字符集，非法即 return——
    加固模块的端口/IP/域名参数同样应先校验再动系统（本项目 ssh 端口输入校验可对齐此标准）。
13. **多步写操作带回滚函数**：任一步失败清理已产生的文件（`rollback_webui_domain_add`，
    deepseek_harness_manager.sh:341-348）——加固失败不能留下半成品状态（本项目已有 rollback 定时器，
    可补"失败即时清理"）。
14. **多发行版矩阵冒烟**：Docker 多发行版镜像跑 `bash -n` + smoke（run_openclaw_manager_matrix.sh:
    debian:12/13、ubuntu:22.04/24.04、rockylinux:9、almalinux:9、fedora:41）——本项目 Docker CI
    Phase 已有多发行版矩阵（curl 精简核心测试 13×5），可把新模块也纳入同一矩阵。

**P2 — 文档与运营**

15. **README 安全四段式 + GitHub Alert + 测试徽章**：805 Bats / ShellCheck 亮出来。
16. **日志单源 + 脚本内联展示最近变更**：`--version` 或菜单展示最近 changelog。

---

## 8. 值得警惕/不模仿清单

- 单文件 2.85 万行：函数命名冲突、重复代码、无法增量测试（本项目多文件 + Bats 更优）。
- 无 `set -euo pipefail`：缺命令静默继续，错误被吞（实测面板大量 command not found 仍"成功"）。
- 状态持久化用 sed 改自身副本：脆弱、不可审计（本项目应坚持 `/var/log/linux-one-key/` + .meta）。
- 埋点默认开启（可关，有透明度注释，但仍是收集行为）；本项目零遥测。
- 自安装逻辑非原子（悬空软链实测）；任何"把自己装成全局命令"的行为需确认。
- **命令注入**：`read -e -p` 后直接展开执行用户输入（`$dockername` 拼进命令）；`sed -i`
  占位符替换有注入面——本项目所有用户输入必须走参数校验 + 引号化。
- **明文凭据**：beifen.sh 硬编码 `sshpass -p 123456`；通知脚本引用未定义 token 静默失败。
- **危险操作无确认**：`iptables -F` 直接清空（无确认/无备份）；OpenSSH 升级无回滚。
- **多语言版本漂移**：5 份翻译副本全部滞后（en v4.5.5、ru/ir v3.9.3 vs 主 v4.5.7）；
  机翻破坏语法（README.ru.md 西里尔 `</р>`）。整文件副本方案天然有此问题。
- **死代码与文档脱节**：update_log.sh 停在 v2.5.1 无人调用；README 的 `en` 参数实际无分支。
- **测试未入 CI**：冒烟测试不进 workflow，契约静默漂移（本项目 Bats 已进 Docker CI，保持）。

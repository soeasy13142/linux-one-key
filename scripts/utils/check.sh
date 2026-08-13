#!/usr/bin/env bash
# ============================================================================
# check.sh - CIS/STIG 命令行合规扫描器（独立 CLI，只读判定，不修改系统）
# 直接解析配置文件：SSH / sudo / 日志 / 内核（kernel）
# 依赖: utils.sh (get_ssh_config, load_lang, log_*), lang (MSG_CHECK_*)
# 零耦合 dashboard 与 security 模块；本脚本为独立可执行工具
# ============================================================================
set -eo pipefail
# 注意: 不使用 -u (nounset)，与 utils.sh 保持一致，避免未绑定变量导致脚本意外退出

# Source guard: 防止重复加载（被 source 时生效；独立执行时 return 不可用则继续）
if [[ -n "${_CHECK_LOADED:-}" ]]; then
    # shellcheck disable=SC2317 # sourced-only early return
    return 0 2>/dev/null || true
fi
readonly _CHECK_LOADED=1

# ============================================================================
# 自加载依赖：utils.sh + i18n（独立执行时；被 source 时由调用方提供 SCRIPT_DIR）
# ============================================================================

if [[ -z "${SCRIPT_DIR:-}" ]]; then
    _check_src="${BASH_SOURCE[0]}"
    if [[ "${_check_src}" != /* ]]; then
        _check_src="${PWD}/${_check_src}"
    fi
    SCRIPT_DIR="$(cd "$(dirname "${_check_src}")/../.." && pwd)"
    unset _check_src
fi
if [[ "${_UTILS_LOADED:-}" != "1" ]]; then
    # shellcheck source=/dev/null
    source "${SCRIPT_DIR}/scripts/base/utils.sh"
fi
if [[ -z "${MSG_CHECK_TITLE:-}" ]]; then
    load_lang "${SCRIPT_DIR}" || true
fi

# ============================================================================
# 配置常量（测试可通过环境变量覆盖路径）
# ============================================================================

# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_SSH_CONFIG:=/etc/ssh/sshd_config}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_SUDOERS_DIR:=/etc/sudoers.d}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_SUDOERS_DROPIN:=/etc/sudoers.d/99-linux-one-key-sudo}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_JOURNALD_DROPIN:=/etc/systemd/journald.conf.d/99-linux-one-key.conf}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_SUDO_LOG:=/var/log/sudo.log}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_SUDO_LOG_OWNER:=root}"
# shellcheck disable=SC2034 # Public API — consumed by Bats tests
: "${CHECK_SYSCTL_CONF:=/etc/sysctl.d/99-hardening.conf}"

# 检查结果集（每项: <section>\t<id>\t<status>\t<detail>）
declare -a CHECK_RESULTS=()
# 待扫描节（--section 指定；空则扫描全部）
declare -a CHECK_SECTIONS=()

# ============================================================================
# 内部辅助
# ============================================================================

# 安全格式化 i18n 文案（集中处理 SC2059）
# shellcheck disable=SC2059 # 格式串来自 i18n 变量（含 %s 占位符）
_check_fmt() {
    local fmt="$1"
    shift
    printf "${fmt}" "$@"
}

# 输出错误信息到 stderr（含换行）
_check_error() {
    local fmt="$1"
    shift
    _check_fmt "${fmt}" "$@" >&2
    printf "\n" >&2
}

# 记录一条检查结果
_check_record() {
    local section="$1" id="$2" status="$3" detail="$4"
    CHECK_RESULTS+=("${section}"$'\t'"${id}"$'\t'"${status}"$'\t'"${detail}")
}

# 是否存在 FAIL（返回 0=存在 FAIL）
_check_has_fail() {
    local entry status
    for entry in "${CHECK_RESULTS[@]}"; do
        IFS=$'\t' read -r _ _ status _ <<< "${entry}"
        if [[ "${status}" == "FAIL" ]]; then
            return 0
        fi
    done
    return 1
}

# 获取文件八进制权限（跨平台：GNU stat / BSD stat）
_get_file_mode() {
    if [[ -e "$1" ]]; then
        stat -c '%a' "$1" 2>/dev/null || stat -f '%Lp' "$1" 2>/dev/null || echo "000"
    else
        echo "NOT_FOUND"
    fi
}

# 获取文件属主（跨平台）
_get_file_owner() {
    stat -c '%U' "$1" 2>/dev/null || stat -f '%Su' "$1" 2>/dev/null || echo "unknown"
}

# JSON 转义（反斜杠、双引号、换行、制表符）
_check_json_escape() {
    local s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    printf "%s" "${s}"
}

# 节标签（i18n）
check_section_label() {
    case "$1" in
        ssh) echo "${MSG_CHECK_SECTION_SSH}" ;;
        sudo) echo "${MSG_CHECK_SECTION_SUDO}" ;;
        log) echo "${MSG_CHECK_SECTION_LOG}" ;;
        kernel) echo "${MSG_CHECK_SECTION_KERNEL}" ;;
        *) echo "$1" ;;
    esac
}

# 检查项名称（i18n）
check_item_label() {
    local section="$1" id="$2"
    case "${section}_${id}" in
        ssh_port) echo "${MSG_CHECK_SSH_PORT}" ;;
        ssh_root) echo "${MSG_CHECK_SSH_ROOT}" ;;
        ssh_passwd) echo "${MSG_CHECK_SSH_PASSWD}" ;;
        sudo_nopasswd) echo "${MSG_CHECK_SUDO_NOPASSWD}" ;;
        sudo_perms) echo "${MSG_CHECK_SUDO_PERMS}" ;;
        sudo_dropin) echo "${MSG_CHECK_SUDO_DROPIN}" ;;
        log_storage) echo "${MSG_CHECK_LOG_STORAGE}" ;;
        log_systemmaxuse) echo "${MSG_CHECK_LOG_SYSTEMMAXUSE}" ;;
        log_sudo_perms) echo "${MSG_CHECK_LOG_SUDO_PERMS}" ;;
        kernel_conf) echo "${MSG_CHECK_KERNEL_CONF}" ;;
        *) echo "${id}" ;;
    esac
}

# ============================================================================
# 各节检查（只读判定，不修改系统）
# ============================================================================

check_section_ssh() {
    local port root passwd
    port="$(get_ssh_config "Port" "${CHECK_SSH_CONFIG}" 2>/dev/null || echo "22")"
    if [[ -z "${port}" ]]; then
        port="22"
    fi
    if [[ "${port}" != "22" ]]; then
        _check_record "ssh" "port" "PASS" "$(_check_fmt "${MSG_CHECK_SSH_PORT_PASS}" "${port}")"
    else
        _check_record "ssh" "port" "FAIL" "${MSG_CHECK_SSH_PORT_FAIL}"
    fi

    root="$(get_ssh_config "PermitRootLogin" "${CHECK_SSH_CONFIG}" 2>/dev/null || echo "unknown")"
    if [[ "${root}" == "no" ]]; then
        _check_record "ssh" "root" "PASS" "${MSG_CHECK_SSH_ROOT_PASS}"
    else
        _check_record "ssh" "root" "FAIL" "$(_check_fmt "${MSG_CHECK_SSH_ROOT_FAIL}" "${root}")"
    fi

    passwd="$(get_ssh_config "PasswordAuthentication" "${CHECK_SSH_CONFIG}" 2>/dev/null || echo "unknown")"
    if [[ "${passwd}" == "no" ]]; then
        _check_record "ssh" "passwd" "PASS" "${MSG_CHECK_SSH_PASSWD_PASS}"
    else
        _check_record "ssh" "passwd" "FAIL" "$(_check_fmt "${MSG_CHECK_SSH_PASSWD_FAIL}" "${passwd}")"
    fi
}

check_section_sudo() {
    local nopasswd_hits=""
    if [[ -d "${CHECK_SUDOERS_DIR}" ]]; then
        nopasswd_hits="$(grep -rlE '^[^#]*NOPASSWD' "${CHECK_SUDOERS_DIR}" 2>/dev/null || true)"
    fi
    if [[ -z "${nopasswd_hits}" ]]; then
        _check_record "sudo" "nopasswd" "PASS" "${MSG_CHECK_SUDO_NOPASSWD_PASS}"
    else
        _check_record "sudo" "nopasswd" "FAIL" "$(_check_fmt "${MSG_CHECK_SUDO_NOPASSWD_FAIL}" "${nopasswd_hits}")"
    fi

    local perms_issue=""
    if [[ -d "${CHECK_SUDOERS_DIR}" ]]; then
        local file mode mode_val
        while IFS= read -r file; do
            [[ -f "${file}" ]] || continue
            mode="$(_get_file_mode "${file}")"
            if [[ "${mode}" != "NOT_FOUND" ]]; then
                mode_val=$((8#${mode}))
                if [[ ${mode_val} -gt $((8#440)) ]]; then
                    perms_issue="${file} (${mode})"
                    break
                fi
            fi
        done < <(find "${CHECK_SUDOERS_DIR}" -maxdepth 1 -type f 2>/dev/null)
    fi
    if [[ -z "${perms_issue}" ]]; then
        _check_record "sudo" "perms" "PASS" "${MSG_CHECK_SUDO_PERMS_PASS}"
    else
        _check_record "sudo" "perms" "FAIL" "$(_check_fmt "${MSG_CHECK_SUDO_PERMS_FAIL}" "${perms_issue}")"
    fi

    if [[ -f "${CHECK_SUDOERS_DROPIN}" ]]; then
        _check_record "sudo" "dropin" "PASS" "${MSG_CHECK_SUDO_DROPIN_PASS}"
    else
        _check_record "sudo" "dropin" "FAIL" "$(_check_fmt "${MSG_CHECK_SUDO_DROPIN_FAIL}" "${CHECK_SUDOERS_DROPIN}")"
    fi
}

check_section_log() {
    local storage=""
    if [[ -f "${CHECK_JOURNALD_DROPIN}" ]]; then
        storage="$(grep -E '^Storage[[:space:]]*=' "${CHECK_JOURNALD_DROPIN}" 2>/dev/null \
            | awk -F'=' '{print $2}' | tr -d '[:space:]' | tail -1 || true)"
    fi
    if [[ "${storage}" == "persistent" ]]; then
        _check_record "log" "storage" "PASS" "${MSG_CHECK_LOG_STORAGE_PASS}"
    else
        _check_record "log" "storage" "FAIL" "${MSG_CHECK_LOG_STORAGE_FAIL}"
    fi

    if [[ -f "${CHECK_JOURNALD_DROPIN}" ]] && grep -qE '^SystemMaxUse[[:space:]]*=' "${CHECK_JOURNALD_DROPIN}" 2>/dev/null; then
        _check_record "log" "systemmaxuse" "PASS" "${MSG_CHECK_LOG_SYSTEMMAXUSE_PASS}"
    else
        _check_record "log" "systemmaxuse" "FAIL" "${MSG_CHECK_LOG_SYSTEMMAXUSE_FAIL}"
    fi

    local mode owner
    if [[ -e "${CHECK_SUDO_LOG}" ]]; then
        mode="$(_get_file_mode "${CHECK_SUDO_LOG}")"
        owner="$(_get_file_owner "${CHECK_SUDO_LOG}")"
        if [[ "${mode}" == "640" ]] && [[ "${owner}" == "${CHECK_SUDO_LOG_OWNER}" ]]; then
            _check_record "log" "sudo_perms" "PASS" "${MSG_CHECK_LOG_SUDO_PERMS_PASS}"
        else
            _check_record "log" "sudo_perms" "FAIL" "$(_check_fmt "${MSG_CHECK_LOG_SUDO_PERMS_FAIL}" "${owner}" "${mode}")"
        fi
    else
        _check_record "log" "sudo_perms" "FAIL" "$(_check_fmt "${MSG_CHECK_LOG_SUDO_PERMS_FAIL}" "NOT_FOUND" "NOT_FOUND")"
    fi
}

check_section_kernel() {
    if [[ -f "${CHECK_SYSCTL_CONF}" ]]; then
        _check_record "kernel" "conf" "PASS" "${MSG_CHECK_KERNEL_CONF_PASS}"
    else
        _check_record "kernel" "conf" "FAIL" "$(_check_fmt "${MSG_CHECK_KERNEL_CONF_FAIL}" "${CHECK_SYSCTL_CONF}")"
    fi
}

# ============================================================================
# 聚合
# ============================================================================

check_run_all() {
    CHECK_RESULTS=()
    local section
    if [[ "${#CHECK_SECTIONS[@]}" -eq 0 ]]; then
        for section in ssh sudo log kernel; do
            "check_section_${section}"
        done
    else
        for section in "${CHECK_SECTIONS[@]}"; do
            "check_section_${section}"
        done
    fi
}

# ============================================================================
# 参数解析
# ============================================================================

check_parse_args() {
    CHECK_JSON=0
    CHECK_SECTIONS=()
    local section arg
    while [[ $# -gt 0 ]]; do
        arg="$1"
        case "${arg}" in
            --json)
                CHECK_JSON=1
                shift
                ;;
            --section=*)
                CHECK_SECTIONS+=("${arg#*=}")
                shift
                ;;
            --section)
                if [[ $# -lt 2 ]]; then
                    _check_error "${MSG_CHECK_ERR_SECTION_VALUE}"
                    exit 2
                fi
                CHECK_SECTIONS+=("$2")
                shift 2
                ;;
            --help|-h)
                check_usage
                exit 0
                ;;
            *)
                _check_error "${MSG_CHECK_ERR_UNKNOWN_ARG}" "${arg}"
                _check_error "${MSG_ERROR_USE_HELP}"
                exit 2
                ;;
        esac
    done

    for section in "${CHECK_SECTIONS[@]}"; do
        case "${section}" in
            ssh|sudo|log|kernel) ;;
            *)
                _check_error "${MSG_CHECK_ERR_INVALID_SECTION}" "${section}"
                exit 2
                ;;
        esac
    done
}

# ============================================================================
# 输出
# ============================================================================

check_usage() {
    cat << EOF
${MSG_CHECK_USAGE}

${MSG_CHECK_OPTIONS}
${MSG_CHECK_OPT_JSON}
${MSG_CHECK_OPT_SECTION}
${MSG_CHECK_OPT_HELP}

${MSG_CHECK_EXAMPLES}
${MSG_CHECK_EXAMPLE_ALL}
${MSG_CHECK_EXAMPLE_SECTION}
${MSG_CHECK_EXAMPLE_JSON}

${MSG_CHECK_EXIT_HINT}
EOF
}

check_render_text() {
    local entry section id status detail
    local pass=0 total=0
    printf "%b\n" "${BOLD}${MSG_CHECK_TITLE}${NC}"
    printf "  %-6s  %-7s  %-24s  %s\n" "${MSG_CHECK_STATUS_LABEL}" "${MSG_CHECK_SECTION_LABEL}" "${MSG_CHECK_ITEM_LABEL}" "${MSG_CHECK_DETAIL_LABEL}"
    for entry in "${CHECK_RESULTS[@]}"; do
        IFS=$'\t' read -r section id status detail <<< "${entry}"
        total=$((total + 1))
        if [[ "${status}" == "PASS" ]]; then
            pass=$((pass + 1))
            # shellcheck disable=SC2059 # color escape codes in format string
            printf "  ${GREEN}%-6s${NC}  %-7s  %-24s  %s\n" "${MSG_CHECK_PASS}" "$(check_section_label "${section}")" "$(check_item_label "${section}" "${id}")" "${detail}"
        else
            # shellcheck disable=SC2059 # color escape codes in format string
            printf "  ${RED}%-6s${NC}  %-7s  %-24s  %s\n" "${MSG_CHECK_FAIL}" "$(check_section_label "${section}")" "$(check_item_label "${section}" "${id}")" "${detail}"
        fi
    done
    if [[ ${total} -eq 0 ]]; then
        return 0
    fi
    if [[ ${pass} -eq ${total} ]]; then
        printf "%b\n" "${GREEN}$(_check_fmt "${MSG_CHECK_ALL_PASS}" "${pass}" "${total}")${NC}"
    else
        printf "%b\n" "${RED}$(_check_fmt "${MSG_CHECK_HAS_FAIL}" "${pass}" "${total}")${NC}"
    fi
}

check_render_json() {
    local entry section id status detail
    local first=1
    printf "[\n"
    for entry in "${CHECK_RESULTS[@]}"; do
        IFS=$'\t' read -r section id status detail <<< "${entry}"
        if [[ ${first} -eq 1 ]]; then
            first=0
        else
            printf ",\n"
        fi
        printf "  {\"section\":\"%s\",\"id\":\"%s\",\"status\":\"%s\",\"detail\":\"%s\"}" \
            "$(_check_json_escape "${section}")" \
            "$(_check_json_escape "${id}")" \
            "$(_check_json_escape "${status}")" \
            "$(_check_json_escape "${detail}")"
    done
    printf "\n]\n"
}

# ============================================================================
# 入口
# ============================================================================

main() {
    check_parse_args "$@"
    check_run_all
    if [[ "${CHECK_JSON}" -eq 1 ]]; then
        check_render_json
    else
        check_render_text
    fi
    if _check_has_fail; then
        exit 1
    fi
    exit 0
}

# 独立执行入口（被 source 时不执行 main）
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

log_debug "check.sh loaded successfully"

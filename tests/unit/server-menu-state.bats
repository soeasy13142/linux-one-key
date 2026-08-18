#!/usr/bin/env bats
# server-menu-state.bats - 状态感知子菜单结构测试（kejilion study P1 #5）
# 断言每个 server 模块的 show_*_submenu 都通过 render_service_state_label
# 渲染状态行，并配对对应的 check_<module>_installed / check_<module>_running 回调。

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
}

@test "utils.sh provides render_service_state_label" {
    run grep -E "^render_service_state_label\(\)" "${SCRIPT_DIR}/scripts/base/utils.sh"
    [[ "${status}" -eq 0 ]]
}

@test "all server submenus render state via render_service_state_label" {
    # check 函数前缀:文件名的映射（postgres 的 check 前缀与文件名不同）
    local pairs="docker:docker nginx:nginx redis:redis postgres:postgresql mysql:mysql memcached:memcached node_exporter:node_exporter prometheus:prometheus grafana:grafana rabbitmq:rabbitmq k3s:k3s"
    local failed=0
    for pair in ${pairs}; do
        local mod="${pair%%:*}"
        local file="${SCRIPT_DIR}/scripts/server/${pair##*:}.sh"
        [[ -f "${file}" ]] || { echo "missing ${file}"; failed=1; continue; }
        run grep -F "render_service_state_label check_${mod}_installed check_${mod}_running" "${file}"
        if [[ "${status}" -ne 0 ]]; then
            echo "${pair##*:}.sh submenu missing state line"; failed=1
        fi
    done
    [[ "${failed}" -eq 0 ]]
}

@test "zh/en have MSG_MENU_STATE_* keys" {
    for key in MSG_MENU_STATE_LABEL MSG_MENU_STATE_NOT_INSTALLED MSG_MENU_STATE_INSTALLED_RUNNING MSG_MENU_STATE_INSTALLED_STOPPED; do
        run grep -E "^${key}=" "${SCRIPT_DIR}/scripts/lang/zh.sh"
        [[ "${status}" -eq 0 ]]
        run grep -E "^${key}=" "${SCRIPT_DIR}/scripts/lang/en.sh"
        [[ "${status}" -eq 0 ]]
    done
}

#!/usr/bin/env bash
# Test: kejilion-borrow - 新功能冒烟（A: --version / B: i18n 对称 / C: 写入护栏 / D: 状态菜单）
# 在单个容器内运行 tests/docker/smoke-kejilion-borrow.sh，断言机器可读哨兵。

run_test() {
    local distro="$1"
    local version="$2"
    local failures=0

    log_info "Testing kejilion borrow features on ${distro}:${version}..."

    # 整个冒烟流程在单个容器内完成（项目只读挂载到 /opt/linux-one-key）
    local result
    result=$(run_in_container "$distro" "$version" \
        "bash /opt/linux-one-key/tests/docker/smoke-kejilion-borrow.sh")

    log_info "--- container output ---"
    # shellcheck disable=SC2001 # 简单缩进，不用参数展开替换
    echo "$result" | sed "s/^/  /" >&2
    log_info "--- end container output ---"

    # 逐条断言哨兵 NAME=OK（NAME=FAIL 计入失败）
    local key val
    while IFS="=" read -r key val; do
        [ -z "$key" ] && continue
        case "$key" in
            SMOKE_DONE) ;;
            *)
                if [ "$val" = "OK" ]; then
                    assert_pass "kejilion-borrow: ${key}"
                else
                    assert_fail "kejilion-borrow: ${key} = ${val}"
                    failures=$((failures + 1))
                fi
                ;;
        esac
    done <<< "$(echo "$result" | grep -E '^[A-Z]_[A-Z0-9_]+=')"

    # 容器脚本必须完整跑完（SMOKE_DONE），否则说明中途 set -e 退出
    if echo "$result" | grep -q "SMOKE_DONE"; then
        assert_pass "kejilion-borrow: smoke completed without abort"
    else
        assert_fail "kejilion-borrow: smoke aborted mid-run (missing SMOKE_DONE)"
        failures=$((failures + 1))
    fi

    if [ $failures -eq 0 ]; then
        log_success "All kejilion borrow checks passed on ${distro}:${version}"
    else
        log_error "${failures} kejilion borrow check(s) failed on ${distro}:${version}"
    fi

    return $failures
}

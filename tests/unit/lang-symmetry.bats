#!/usr/bin/env bats
# lang-symmetry.bats - zh/en 语言包 MSG_* 键集对称性测试
# 来源: docs/research/kejilion-study.md §6.3（P1 #7 归一化 diff 守护 i18n 对称性）
# 目的: 防止 zh.sh / en.sh 键集漂移——任一语言缺键/多键即失败，输出差异清单。
# 说明: 本项目 i18n 采用 MSG_* 变量 + source 语言包方案（非整文件翻译副本），
#       键集对称是该方案的维护底线；本测试以 diff 双向比对守护。

setup() {
    export SCRIPT_DIR="${BATS_TEST_DIRNAME}/../.."
}

# 提取语言文件的 MSG_* 键集合（按行首声明，去重排序）
_extract_lang_keys() {
    grep -oE '^MSG_[A-Za-z0-9_]+' "${1}" | sort -u
}

@test "zh.sh and en.sh both exist" {
    [[ -f "${SCRIPT_DIR}/scripts/lang/zh.sh" ]]
    [[ -f "${SCRIPT_DIR}/scripts/lang/en.sh" ]]
}

@test "zh/en MSG_* key sets are symmetric (no missing keys either way)" {
    local zh_keys en_keys
    zh_keys="$(_extract_lang_keys "${SCRIPT_DIR}/scripts/lang/zh.sh")"
    en_keys="$(_extract_lang_keys "${SCRIPT_DIR}/scripts/lang/en.sh")"

    run diff <(printf '%s\n' "${zh_keys}") <(printf '%s\n' "${en_keys}")
    if [[ "$status" -ne 0 ]]; then
        echo "键集不对称（< 仅 zh 有，> 仅 en 有）："
        echo "$output"
    fi
    [[ "$status" -eq 0 ]]
}

@test "zh/en MSG_* key counts match" {
    local zh_count en_count
    zh_count="$(_extract_lang_keys "${SCRIPT_DIR}/scripts/lang/zh.sh" | wc -l | tr -d ' ')"
    en_count="$(_extract_lang_keys "${SCRIPT_DIR}/scripts/lang/en.sh" | wc -l | tr -d ' ')"
    echo "zh keys=${zh_count} en keys=${en_count}"
    [[ "${zh_count}" -eq "${en_count}" ]]
}

#!/usr/bin/env bash
# scripts/dev/gen-file-tree.sh
# 生成 docs/file-tree.generated.md — HANDOVER.md 引用的文件清单
# 用途：把当前仓库的目录结构自动输出到 docs/file-tree.generated.md（gitignored），
#       避免 HANDOVER.md 中手写树状图过期。
#
# 使用方式：
#   bash scripts/dev/gen-file-tree.sh
#   # 或从项目根目录：
#   ./scripts/dev/gen-file-tree.sh
#
# 输出文件：docs/file-tree.generated.md
# 兼容性：CentOS 7+, Ubuntu 20.04+, Debian 11+, Rocky, Alma

set -euo pipefail

# 切换到项目根目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
cd "${PROJECT_ROOT}"

OUTPUT_FILE="docs/file-tree.generated.md"

# 排除目录
EXCLUDES=(
    ".git"
    ".claude"
    "everything-claude-code"
    ".superpowers"
    "tmp"
    ".tmp"
    "node_modules"
    ".idea"
    ".vscode"
    ".DS_Store"
)

# 构建 find prune 表达式
PRUNE_EXPR=""
for dir in "${EXCLUDES[@]}"; do
    if [[ -z "${PRUNE_EXPR}" ]]; then
        PRUNE_EXPR="\\( -path \"./${dir}\" -o -path \"./${dir}/*\" \\) -prune -o"
    else
        PRUNE_EXPR="${PRUNE_EXPR} \\( -path \"./${dir}\" -o -path \"./${dir}/*\" \\) -prune -o"
    fi
done

# 生成时间戳
TIMESTAMP="$(date '+%Y-%m-%d %H:%M:%S %Z')"

# 收集所有路径到临时数组
ENTRIES=()
while IFS= read -r entry; do
    ENTRIES+=("${entry}")
done < <(
    eval "find . ${PRUNE_EXPR} -type d -print -o -type f -print" 2>/dev/null \
        | sed 's|^\./||' \
        | grep -v '^\.$' \
        | grep -v '\.DS_Store$' \
        | sort
)

# 生成树状图
TREE_OUTPUT=""
TREE_OUTPUT+="linux-one-key/"$'\n'
for entry in "${ENTRIES[@]}"; do
    # 计算深度（按 / 分隔）
    if [[ "${entry}" == */* ]]; then
        depth=$(echo "${entry}" | tr -cd '/' | wc -c | tr -d ' ')
    else
        depth=0
    fi

    # 缩进
    indent=""
    i=0
    while [[ ${i} -lt ${depth} ]]; do
        indent+="│   "
        i=$((i + 1))
    done

    # 文件名
    name="${entry##*/}"

    TREE_OUTPUT+="${indent}├── ${name}"$'\n'
done

# 统计
SH_COUNT=$(eval "find . ${PRUNE_EXPR} -name '*.sh' -type f -print" 2>/dev/null | wc -l | tr -d ' ')
BATS_COUNT=$(eval "find . ${PRUNE_EXPR} -name '*.bats' -type f -print" 2>/dev/null | wc -l | tr -d ' ')
MD_COUNT=$(eval "find . ${PRUNE_EXPR} -name '*.md' -type f -print" 2>/dev/null | wc -l | tr -d ' ')
CONFIG_COUNT=$(find ./config -type f 2>/dev/null | wc -l | tr -d ' ')
TOTAL_COUNT=$(eval "find . ${PRUNE_EXPR} -type f -print" 2>/dev/null | wc -l | tr -d ' ')

# 输出 markdown 文件
cat > "${OUTPUT_FILE}" <<EOF
# File Tree（自动生成）

> **本文件由 \`scripts/dev/gen-file-tree.sh\` 自动生成，不要手动编辑。**
> 重新生成：\`bash scripts/dev/gen-file-tree.sh\`

**生成时间**: ${TIMESTAMP}
**项目根目录**: \`${PROJECT_ROOT}\`
**排除目录**: ${EXCLUDES[*]}

## 顶层结构

\`\`\`
${TREE_OUTPUT}\`\`\`

## 文件统计

| 类型 | 数量 |
|------|------|
| Shell 脚本 (.sh) | ${SH_COUNT} |
| Bats 测试 (.bats) | ${BATS_COUNT} |
| Markdown 文档 (.md) | ${MD_COUNT} |
| 配置文件 | ${CONFIG_COUNT} |
| **总计文件** | ${TOTAL_COUNT} |
EOF

echo "✓ 生成完成：${OUTPUT_FILE}"
echo "  文件大小：$(wc -l < "${OUTPUT_FILE}") 行"
echo "  文件统计：${SH_COUNT} .sh / ${BATS_COUNT} .bats / ${MD_COUNT} .md / 共 ${TOTAL_COUNT} 文件"
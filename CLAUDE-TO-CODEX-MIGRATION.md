# Claude Code → Codex 文件/目录迁移对照表

> 本文档详细列出了 Claude Code 与 Codex（OpenAI 的 CLI 编码工具）之间配置文件和目录的对应关系，
> 供开发者在两个工具之间迁移项目时参考。本文档是一份通用参考，不依赖任何具体项目。

---

## 一、核心文件与目录映射总览

| Claude Code 路径 | Codex 等价物 | 类型 | 说明 |
|---|---|---|---|
| `.claude/` | `.codex/` | 目录 | 项目级配置的根目录，整体改名 |
| `.claude/CLAUDE.md` | `.codex/CODEX.md` 或 `CODEX.md` 或 `AGENTS.md` | 文件 | 项目指令/上下文文件 |
| `.claude/settings.json` | `.codex/config.json` | 文件 | 项目设置（权限、插件、模型等） |
| `.claude/settings.local.json` | `.codex/config.local.json` | 文件 | 本地覆盖设置（不应提交到 Git） |
| `~/.claude/` | `~/.codex/` | 目录 | 用户级全局配置目录 |

### 关于项目指令文件（CLAUDE.md / CODEX.md / AGENTS.md）

Codex 支持多种项目指令文件名，按优先级排列：

1. **`.codex/CODEX.md`** — 放在 `.codex/` 目录内，与 Claude Code 的 `.claude/CLAUDE.md` 一一对应
2. **`CODEX.md`** — 放在项目根目录，简洁直观
3. **`AGENTS.md`** — 通用标准，部分 AI 编码工具（Cursor、Copilot、Codex 等）都支持

> **建议**：如果你的项目只使用 Codex 一种 AI 编码工具，用 `CODEX.md` 放在根目录即可；
> 如果需要兼容多种工具，用 `AGENTS.md` 是更通用的选择。
> 但出于目录结构一致性，推荐 **`.codex/CODEX.md`**，与 Claude Code 的结构完全对应。

---

## 二、子目录对照

### 2.1 规则系统（Rules）

Claude Code 和 Codex 都支持通过规则文件来指导 AI 的行为，结构非常相似。

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/rules/` | `.codex/rules/` | 规则文件根目录 |
| `.claude/rules/common/` | `.codex/rules/common/` | 通用规则（所有语言/框架适用） |
| `.claude/rules/{language}/` | `.codex/rules/{language}/` | 按语言分类的规则目录 |
| `.claude/rules/common/coding-style.md` | `.codex/rules/common/coding-style.md` | 编码风格规则 |
| `.claude/rules/common/security.md` | `.codex/rules/common/security.md` | 安全规则 |
| `.claude/rules/common/testing.md` | `.codex/rules/common/testing.md` | 测试规则 |
| `.claude/rules/common/git-workflow.md` | `.codex/rules/common/git-workflow.md` | Git 工作流规则 |
| `.claude/rules/common/patterns.md` | `.codex/rules/common/patterns.md` | 设计模式规则 |
| `.claude/rules/common/performance.md` | `.codex/rules/common/performance.md` | 性能优化规则 |
| `.claude/rules/common/hooks.md` | `.codex/rules/common/hooks.md` | Git hooks 规则 |
| `.claude/rules/common/guardrails.md` | `.codex/rules/common/guardrails.md` | 安全护栏/防御性规则 |
| `.claude/rules/common/agents.md` | `.codex/rules/common/agents.md` | Agent 编排规则（见下方注意事项） |
| `.claude/rules/common/code-review.md` | `.codex/rules/common/code-review.md` | 代码审查规则 |
| `.claude/rules/common/development-workflow.md` | `.codex/rules/common/development-workflow.md` | 开发流程规则 |
| `.claude/rules/common/handover.md` | `.codex/rules/common/handover.md` | 交接文档规则 |
| `.claude/rules/common/node.md` | `.codex/rules/common/node.md` | Node.js 特定规则 |

> **注意 `agents.md`**：Claude Code 中此文件定义 Agent 编排策略（使用哪些子 Agent、何时使用），
> Codex 的 Agent 模型不同，此文件可能需要重新编写或删除。

### 2.2 自定义命令（Commands）

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/commands/` | `.codex/commands/` | 自定义斜杠命令目录 |
| `.claude/commands/{name}.md` | `.codex/commands/{name}.md` | 单个命令文件，格式基本兼容 |

> Codex 的命令文件格式与 Claude Code 大致相同（Markdown 格式，包含触发词和说明），
> 大多数命令文件可以直接迁移，无需修改内容。

### 2.3 技能系统（Skills）

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/skills/` | `.codex/skills/` | 技能目录 |
| `.claude/skills/{name}/SKILL.md` | `.codex/skills/{name}/SKILL.md` | 技能定义文件 |
| `.claude/skills/{name}/scripts/` | `.codex/skills/{name}/scripts/` | 技能附带的脚本文件 |

> Claude Code 和 Codex 的技能系统概念相似，都是通过 SKILL.md 定义技能的触发条件、
> 工作流程和使用示例。迁移时保留 SKILL.md 和 scripts/，目录结构一致。

### 2.4 计划文档（Plans）

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/plans/` | `.codex/plans/` | 实施计划文档目录 |
| `.claude/plans/{feature}.plan.md` | `.codex/plans/{feature}.plan.md` | 功能实施计划 |

> 计划文档是项目管理的 Markdown 文件，与工具无关，可以直接迁移。

### 2.5 PRD 文档

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/prds/` | `.codex/prds/` | PRD（产品需求文档）目录 |
| `.claude/prds/{name}.prd.md` | `.codex/prds/{name}.prd.md` | 需求文档 |

> PRD 文档是项目管理的 Markdown 文件，与工具无关，可以直接迁移。

### 2.6 代码审查报告（Reviews）

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/reviews/` | `.codex/reviews/` | 代码审查报告目录 |
| `.claude/reviews/{name}.md` | `.codex/reviews/{name}.md` | 审查报告 |

> 审查报告的 Markdown 文件，与工具无关，可以直接迁移。

### 2.7 研究/调研文档（Research）

| Claude Code | Codex | 说明 |
|---|---|---|
| `.claude/research/` | `.codex/research/` | 调研文档目录 |
| `.claude/research/{name}.md` | `.codex/research/{name}.md` | 调研文档 |

> 调研文档与工具无关，可以直接迁移。

---

## 三、配置文件内容差异

### 3.1 settings.json → config.json

```jsonc
// Claude Code: .claude/settings.json
{
  "enabledPlugins": {
    "ecc@ecc": true                      // ← Claude Code 专用插件，Codex 不适用
  },
  "permissions": {
    "defaultMode": "bypassPermissions",
    "allow": [
      "Bash(*)",                         // ← 权限工具的命名方式不同
      "Read(*)",
      "Write(*)",
      "Edit(*)",
      "Glob(*)",
      "Grep(*)",
      "Agent(*)",
      "WebFetch(*)",
      "WebSearch(*)",
      "NotebookEdit(*)",
      "Skill(*)",
      "mcp__context7__*",                // ← MCP 工具，Codex 支持但配置方式可能不同
      "mcp__plugin_ecc_context7__*",     // ← ECC 插件下的 MCP 工具，Codex 不适用
      "mcp__plugin_ecc_exa__*",
      "mcp__plugin_ecc_github__*",
      "mcp__plugin_ecc_memory__*",
      "mcp__plugin_ecc_playwright__*",
      "mcp__plugin_ecc_sequential-thinking__*"
    ]
  }
}
```

```jsonc
// Codex: .codex/config.json（示意）
{
  "permissions": {
    "allow": [
      "terminal",                        // ← 对应 Bash
      "read",                            // ← 对应 Read
      "write",                           // ← 对应 Write
      "edit",                            // ← 对应 Edit
      "search",                          // ← 对应 Glob + Grep
      "web_fetch",
      "web_search",
      "notebook"
    ]
  },
  "mcp_servers": {                       // ← Codex 的 MCP 配置方式
    "context7": { "command": "..." }     // ← 需要从 Claude Code 的 MCP 配置文件中提取
  }
}
```

> **关键差异**：
> 1. Claude Code 的 `enabledPlugins` 在 Codex 中没有对应概念，需要移除
> 2. 权限工具名不同（`Bash` → `terminal`，`Read` → `read` 等）
> 3. MCP 工具的配置格式不同，需要重新配置
> 4. Claude Code 的 `ecc@ecc` 插件体系下的 MCP 工具不能直接移植

### 3.2 settings.local.json → config.local.json

本地配置文件的逻辑相同：都是覆盖项目配置的本地设置，不应提交到 Git。
内容差异与 3.1 相同。

---

## 四、.gitignore 变更

| Claude Code 的 .gitignore 条目 | Codex 的 .gitignore 条目 | 说明 |
|---|---|---|
| `# Claude Code` | `# Codex` | 注释 |
| `.claude/reviews/` | `.codex/reviews/` | 审查报告通常不提交 |
| `.claude/settings.local.json` | `.codex/config.local.json` | 本地设置不提交 |

---

## 五、操作步骤

### 方案一：直接重命名（推荐，快速迁移）

```bash
# 1. 重命名配置目录
mv .claude .codex

# 2. 重命名项目指令文件
mv .codex/CLAUDE.md .codex/CODEX.md

# 3. 重命名配置文件（如果存在）
mv .codex/settings.json .codex/config.json
mv .codex/settings.local.json .codex/config.local.json 2>/dev/null || true

# 4. 更新 .gitignore
sed -i '' 's/\.claude/\.codex/g; s/settings\.local\.json/config.local.json/g' .gitignore

# 5. 更新项目文档中所有 .claude 引用
# 用你的编辑器全局替换 .claude/ → .codex/ 和 CLAUDE.md → CODEX.md
```

### 方案二：复制并保留（渐进式迁移，两套并存）

```bash
cp -r .claude .codex
# 然后按方案一的步骤 2-5 处理 .codex 内的文件
# 确认新环境工作正常后再删除 .claude/
```

---

## 六、不兼容项清单

以下 Claude Code 特有的功能在 Codex 中没有直接等价物：

| Claude Code 功能 | 迁移建议 |
|---|---|
| ECC 插件系统 (`enabledPlugins.ecc@ecc`) | 移除，Codex 无插件系统 |
| ECC 子目录的 MCP 工具 (`mcp__plugin_ecc_*`) | 将 MCP 服务器重新注册到 Codex 的 `mcp_servers` 配置中 |
| Claude-only 权限工具 (`Bash`, `Glob`, `Grep` 等) | 映射为 Codex 的工具名（`terminal`, `search` 等） |
| `defaultMode: "bypassPermissions"` | Codex 的权限模型不同，需确认其配置方式 |
| Agent 编排 (`.claude/rules/common/agents.md`) | Codex 的 Agent 体系不同，此文件需要根据 Codex 的能力重新编写 |

---

## 七、快速参考卡

```
╔═══════════════════════════════════╦═══════════════════════════════════╗
║          Claude Code             ║              Codex               ║
╠═══════════════════════════════════╬═══════════════════════════════════╣
║ .claude/                         ║ .codex/                          ║
║ .claude/CLAUDE.md                ║ .codex/CODEX.md 或 AGENTS.md     ║
║ .claude/settings.json            ║ .codex/config.json               ║
║ .claude/settings.local.json      ║ .codex/config.local.json         ║
║ .claude/rules/                   ║ .codex/rules/                    ║
║ .claude/commands/                ║ .codex/commands/                 ║
║ .claude/skills/                  ║ .codex/skills/                   ║
║ .claude/plans/                   ║ .codex/plans/                    ║
║ .claude/prds/                    ║ .codex/prds/                     ║
║ .claude/reviews/                 ║ .codex/reviews/                  ║
║ .claude/research/                ║ .codex/research/                 ║
║ ~/.claude/ (全局配置)            ║ ~/.codex/ (全局配置)             ║
╚═══════════════════════════════════╩═══════════════════════════════════╝

核心公式：.claude → .codex，CLAUDE → CODEX，settings → config
```

---

> **最后更新**：2026-07-04
> **维护说明**：本文档基于 Claude Code 和 Codex 的当前公开文档编写。
> 随着工具的迭代，部分映射关系可能发生变化，届时请以各工具的官方文档为准。

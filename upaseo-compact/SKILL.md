---
name: upaseo-compact
description: >-
  压缩当前会话上下文并生成可恢复现场的 compact 文档和恢复提示词。用于替代系统 compact
  指令，适合用户说“压缩上下文”“compact”“保存现场”“重建会话后恢复”“生成恢复提示词”等场景。
---

# Upaseo Compact Skill

**User's request:** $ARGUMENTS

本技能只做一件事：把当前工作现场压缩成一份可审计、可恢复、可继续执行的上下文包，并输出一段恢复提示词。它不启动新 Agent，不执行系统 compact，不替代 `/upaseo-handoff`；它面向“未来的本会话或新会话恢复工作”。

## Core Rule

系统 compact 容易丢关键上下文，所以本技能必须先创建 durable compact document，再输出 prompt。对话里的短摘要不能替代文档；文档才是恢复事实源。

## Hook Self-Heal (宿主适配)

`/upaseo-compact` 的自动 compact 文档化与恢复提示注入依赖**项目级 compact hooks**。当前默认实现是 **Codex** 的 `PreCompact`/`PostCompact` hooks；其他宿主（ZCode、Gemini CLI、Claude Code）没有等价的自动触发机制。因此本步骤必须先做**宿主探测**：

- **Codex 宿主**：检查 `.codex/hooks.json` 中的 `PreCompact` hook（系统 compact 前自动创建 `.paseo/compacts/...md`）与 `PostCompact` hook（compact 后自动注入恢复提示）。该自动化是 **repo-scoped** 的，只对当前仓库生效，不修改用户的全局 Codex 配置。hook 失败时必须 fail-open，不能阻断 compact 主流程。
- **非 Codex 宿主**：hooks 不会自动触发。必须向用户明确提示："*当前宿主不支持自动 compact hooks，compact 文档不会在系统 compact 时自动创建。请手动执行 `/upaseo-compact` 来生成文档与恢复提示词；或若宿主支持等价 pre/post compact 钩子，可按相同契约（PreCompact 创建文档、PostCompact 注入恢复提示）接入。*"

### Codex hooks 自愈（仅 Codex 宿主执行）

若当前是 Codex 宿主且发现以下任一文件缺失，则**先自动补齐再继续 compact**：

- `<项目根目录>/.codex/hooks.json`
- `<项目根目录>/.codex/hooks/pre-compact.mjs`
- `<项目根目录>/.codex/hooks/post-compact.mjs`

补齐原则：

- 只修当前仓库，不触碰 `~/.codex/config.toml` 或用户全局 hooks
- 若目录不存在，先创建 `.codex/` 与 `.codex/hooks/`
- 若文件已存在，则优先保留现有版本，不做无谓覆盖；只有明显缺失时才创建
- 自愈安装完成后，再继续执行 compact 文档生成与恢复提示词输出

在最终输出的 `验证：` 段落中，必须说明：当前探测到的宿主、本次是"hooks 已存在"还是"hooks 已自动补齐"还是"非 Codex 宿主，已提示手动执行"。

## Step 0: 避障读取

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `command_error|tool_misuse`。提炼与当前任务、命令、验证、工作区隔离、工具误用相关的避障规则。

## Step 1: 现场取证

压缩前先收集当前真实状态，优先使用只读命令或已有上下文：

- 当前 cwd、仓库名、分支名、`git status --short`
- 当前用户目标、最新指令、不可违反的约束
- 已完成的关键改动和涉及文件
- 未完成事项、下一步最短路径、已知风险和阻塞
- 已运行的验证命令、结果、失败原因或未验证原因
- 当前 `.paseo/plans/`、`.paseo/handoffs/`、`.agents/story/` 中与任务直接相关的文件
- 用户明确要求保留的风格、流程、偏好或禁止事项

不要臆造验证结果。缺少证据时写“未验证”或“未知”，并说明恢复后第一条验证命令。

## Step 2: 创建 compact 文档

路径：

```text
<项目根目录>/.paseo/compacts/<YYYYMMDD-HHMM>-<short-task-slug>.md
```

若 `.paseo/compacts/` 不存在，先创建目录。文件名 slug 要短、可读、稳定。文档必须使用下面结构：

```markdown
# Compact Context: <short task title>

## Restore Prompt
<最终输出给用户的恢复提示词，必须包含本 compact 文档的绝对路径。>

## Task
<当前要完成的目标，用结果导向语言写清楚。>

## Latest User Instructions
- <用户最新指令和硬约束>

## Workspace State
- Cwd: `<absolute path>`
- Branch: `<branch or unknown>`
- Git status: `<clean / dirty summary>`
- Active mode: `<micro / quick / full / handoff / compact / unknown>`

## Files To Read First
- `<absolute path>` — <为什么恢复后必须读>

## Current Progress
- Done: <已经完成什么>
- In progress: <正在做什么>
- Not done: <还没做什么>

## Decisions
- <决策> — <原因>

## Validation Evidence
- `<command>` — <pass/fail/not run + 关键输出摘要>

## Risks And Blockers
- <风险、阻塞、不确定性>

## Next Actions
1. <恢复后第一步>
2. <恢复后第二步>
3. <恢复后第三步>

## Do Not Lose
- <容易被系统 compact 漏掉但必须保留的信息>

## Avoid
- <恢复后不要做的事，例如不要 reset、不要改无关文件、不要重复跑重任务>
```

## Step 3: 生成恢复提示词

最终给用户一段可直接粘贴到新会话或 compact 后的提示词。提示词必须短而有力，包含：

1. 明确要求先读取 compact 文档。
2. compact 文档绝对路径。
3. 当前 cwd。
4. 继续工作的目标。
5. 要求读取后先汇报恢复理解，再继续执行。

模板：

```text
请从 upaseo compact 文档恢复现场。

1. 先读取：<absolute compact document path>
2. 确认当前 cwd 是：<absolute cwd>
3. 根据文档里的 Task、Latest User Instructions、Workspace State、Files To Read First、Validation Evidence 和 Next Actions 恢复上下文。
4. 先用 3-6 句话汇报你恢复到的现场、下一步计划和任何不确定点。
5. 然后继续执行当前目标：<one-line objective>

不要依赖系统 compact 的摘要；compact 文档是 Source of Truth。不要重置或丢弃未提交改动。缺少证据的地方按“未验证”处理，先补验证再宣称完成。
```

## Output Format

完成后只输出：

```text
已创建 compact 文档：
<absolute compact document path>

恢复提示词：
<prompt>

验证：
<用于确认 hooks 状态、文档已创建、路径可读、必要状态已记录的最小证据>
```

## Quality Bar

- **可恢复**：新会话只读 compact 文档和列出的首读文件，就能继续工作。
- **证据真实**：命令、验证、状态不能编造。
- **重点保真**：保留用户最新意图、硬约束、未提交改动、失败原因、下一步。
- **足够短**：文档可以完整，但恢复提示词必须克制，适合直接粘贴。

---
name: upaseo-handoff
description: Hand off the current task to another agent with full context. Use when the user says "handoff", "hand off", "hand this to", or wants to pass work to another agent.
user-invocable: true
---

# Handoff Skill

Transfer the current task — context, decisions, failed attempts, constraints — to a fresh agent. The receiving agent starts with **zero context**, so the handoff prompt must be a self-contained briefing.

**User's arguments:** $ARGUMENTS

## Prerequisites

Read the **upaseo** skill — provider for the receiving agent comes from orchestration preferences unless the user names one.

## 前置避障读取

在构建 handoff prompt 前，检查当前项目根目录下是否存在 `.paseo/learnings.jsonl`。若存在，使用 `view_file` 读取并提炼避障规则，注入到 handoff prompt 的 `## 避障规则` 段落中。若文件不存在则在 handoff prompt 中省略此段落。

## 上下文移交文档

启动接收 Agent 前，必须先创建一份上下文移交文档，作为本次 handoff 的 Source of Truth。

- 路径：`<项目根目录>/.paseo/handoffs/<YYYYMMDD-HHMM>-<short-task-slug>.md`
- 若 `.paseo/handoffs/` 不存在，先创建目录。
- 文档内容必须使用下方 `The handoff prompt` 的同一结构，完整记录任务、上下文、相关文件、当前状态、已尝试方案、决策、验收标准和约束。
- 创建接收 Agent 时，handoff prompt 必须包含该文档绝对路径，并要求接收 Agent 第一步读取它。
- 对话里的简短说明不能替代该文档；文档才是交接事实源。

## Parsing arguments

1. **Provider** — explicit user request first; otherwise resolve from `impl` preference (or `ui` if the task is styling-only). **Remember, UI tasks must use Gemini.**
2. **Worktree** — "in a worktree" / "worktree" → create a worktree via Paseo with a short branch name derived from the task, based on the current branch.
3. **Task description** — anything else the user said.

## The handoff prompt

The receiving agent has zero context. Include:

```
## Task
[Imperative description.]

## Context
[Why this task exists, background needed.]

## 上下文文件（首步必须读取）
- Handoff 移交文档：`<项目根目录>/.paseo/handoffs/<handoff>.md` — 接收后第一步使用 view_file 读取
- 迭代设计文档：`<绝对路径>` — 接收后第一步使用 view_file 读取
- 主计划文件：`<绝对路径>` — 按需读取
- 避障学习记录：`<项目根目录>/.paseo/learnings.jsonl` — 按需读取

严禁跳过 Handoff 移交文档和迭代设计文档的读取。严禁基于口头转述猜测行事。

## 避障规则（来自历史教训，必须严格遵守）
- <规则1>
- <规则2>
(若无 learnings.jsonl 则省略本段落)

## Relevant files
- `path/to/file.ts` — [what it is and why it matters]

## Current state
[What's done, what works, what doesn't.]

## What was tried
- [Approach] — [why it failed or was abandoned]

## Decisions
- [Decision — rationale]

## Acceptance criteria
- [ ] [Criterion]

## Constraints
- [Must-not / must-preserve]
```

**Preserve task semantics.** Investigate-only → "DO NOT edit files." Fix → "implement the fix." Refactor → "refactor, not rewrite." Carry the user's exact intent.

## Launch

Create the agent via Paseo with a `[Handoff] <task>` title, the briefing as initial prompt, and cwd set to the worktree path if `--worktree`.

Don't wait by default — the user decides whether to follow along or move on. Tell them the agent ID and how to follow along (the upaseo skill explains).

**完工通知**：handoff 完成后向 Orchestrator 汇报接收 Agent 的 agentId 及 status。

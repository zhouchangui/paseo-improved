---
name: upaseo-committee
description: Form a committee of two high-reasoning agents to step back, do root cause analysis, and produce a plan. Use when stuck, looping, tunnel-visioning, or facing a hard planning problem.
---

# Upaseo Committee Skill

Two agents from contrasting providers, fresh context, planning a solution in parallel. They stay alive for review after implementation.

The purpose is to step back, not double down. The committee may propose a completely different approach.

**User's additional context:** $ARGUMENTS

## Prerequisites

Read the **upaseo** skill. Contrast is the point of a committee, so pick across providers deliberately rather than using whatever the default category would resolve to.

## Composition

Two members with different reasoning styles:

- **Claude Opus** with extended thinking
- **Codex GPT-5.4** or **Gemini 2.5 Pro** with thinking

Override only when the user explicitly asks for different members.

## Hard rules

- **No edits.** Every prompt to a committee member ends with the no-edits suffix:

  ```
  This is analysis only. Do NOT edit, create, or delete any files. Do NOT write code.
  ```

- **Trust the wait.** Launch members with `background: true` and `notifyOnFinish: true` unless the user explicitly asks for foreground execution. Do not poll, send hurry-ups, or interrupt. GPT-5.4 can reason 15–30 minutes; Opus does extended thinking. Long waits mean it found something worth thinking about.
- **You are the middleman.** Drive plan → implement → review inside the user-approved scope. Ask the user only when the committee materially changes product intent, risk tolerance, scope, or trade-off direction.

## 前置避障读取

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `design_flaw|wrong_assumption`。若提炼出避障规则，作为 committee 成员 prompt 的前缀注入，格式见 reference §1。

## Phase 1: Plan

Write a problem-level prompt:

- High-level goal and acceptance criteria
- Constraints
- Symptoms (if a bug)
- What you tried and why it failed
- Explicit: "do root cause analysis"
- Explicit: "use think-harder — state assumptions, ask why three levels deep, check whether you're patching a symptom or removing the problem"
- **上下文文件**：若有主计划文件或迭代设计文档，在 prompt 中附带绝对路径，要求 committee 成员首步使用 `view_file` 读取后再开始分析。

Create both agents in parallel via Paseo with `[Committee] <task>` titles and the same prompt. Resume synthesis only after both completion notifications arrive — not just whichever finishes first.

Read both responses. Challenge them — do not accept at face value:

- "Why does <underlying thing> happen? Symptom or cause?"
- Verify any assumption the plan makes about the code.
- "What did you considered and reject?"

Send follow-ups until the plan addresses root cause.

Synthesize:

- Convergence → unified plan.
- Significant divergence → involve the user.

Confirm the merged plan with both members. Multi-turn until consensus.

## Phase 2: Implement

Default: implement yourself. If the user said **"delegate"**, launch one impl agent and pass the merged plan.

The committee stays clean — not involved in implementation.

## Phase 3: Review

Send the diff to the committee:

> Implementation is done. Review changes against the plan. Flag drift or missing pieces. <no-edits suffix>

Apply feedback yourself, or send to the impl agent. Repeat 2 → 3 until consensus.

After ~10 iterations without convergence, start a fresh committee with the full history of what was tried — the current committee's context may have drifted too far.

**完工汇报**：review 完成后向 Orchestrator 报告 committee 最终结论，包含 status（consensus/diverged）、一句话 summary、以及关键分歧点（若有）。

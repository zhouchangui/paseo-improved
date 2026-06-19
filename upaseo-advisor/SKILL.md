---
name: upaseo-advisor
description: Spin up a single agent as an advisor for a second opinion without delegating the work. Use when the user says "advisor", "second opinion", "what does X think", wants an outside take, or provides an optional provider and a question/topic.
---

# Upaseo Advisor

Single agent. Reads the situation you're in. Gives a judgment. You decide what to do — the advisor doesn't drive the work.

**User's request:** $ARGUMENTS

## Prerequisites

Read the **upaseo** skill — provider for the advisor comes from orchestration preferences unless the user names one.

## Picking the advisor

1. **User named one** (`--provider claude/opus`) → use it.
2. **Otherwise** resolve from preferences — pick the category that matches the question:
   - Design / approach question → `planning`
   - "Did I miss something" review → `audit`
   - "Is this even right" → `research`
3. **Contrast helps.** If your own provider matches what preferences would pick, swap to a different family on purpose — fresh perspective is the point.

## 前置避障读取

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `design_flaw|wrong_assumption`。若提炼出避障规则，将其作为 advisor briefing 的前缀注入。

## The briefing

The advisor has zero context. Make it self-contained:

- The question, sharply.
- What you've considered and what you've ruled out.
- Relevant files by path (don't paste — let the agent read).
- Explicit ask: "give me a recommendation, with reasoning."
- **上下文文件**：若有主计划文件或迭代设计文档，在 briefing 中附带绝对路径，要求 advisor 首步读取后再开始分析（用当前宿主的文件读取原语，见 `upaseo/SKILL.md` 宿主工具兼容小节）。

End with the no-edits suffix:

```
This is analysis only. Do NOT edit, create, or delete any files. Do NOT write code.
```

## Launch and synthesize

Create the advisor agent via Paseo with a `[Advisor] <topic>` title and the briefing as the initial prompt.

默认按 `upaseo` 的异步规则启动：`background: true`、`notifyOnFinish: true`。不要轮询或忙等；收到完成通知后再读取回复并综合给用户。只有用户明确要求“同步等结果”且当前工具支持阻塞执行时，才可以前台等待。

Synthesize for the user — the advisor's verdict + your recommendation.

**完工汇报**：向 Orchestrator 报告 advisor 结论，包含 status（success/blocked）和一句话 summary。

## Persistent advisor

If the user wants ongoing input ("keep this advisor for the next few decisions"), don't archive after the first reply. Send follow-ups when you need another take. Archive when the user says they're done, or when the topic shifts and a fresh context would serve better.

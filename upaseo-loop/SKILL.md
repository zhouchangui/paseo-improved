---
name: upaseo-loop
description: >-
  Run an agent loop until an exit condition is met. Use when the user says
  "loop", "babysit", "keep trying until", "check every X", "watch", or wants
  iterative autonomous execution.
---

# Upaseo Loop Skill

A loop is a worker/verifier cycle: launch a worker → check verification → repeat until done or limits hit. Use for "keep trying", "babysit", or "watch this until X." This skill is a core primitive for the implement phase in `using-upaseo`.

**User's arguments:** $ARGUMENTS

## Prerequisites

Read the **upaseo** skill for orchestration preferences — worker and verifier providers come from preferences unless the user names them.

Loops are a CLI primitive: `paseo loop run`. Manage with `paseo loop ls`, `paseo loop inspect <id>`, `paseo loop logs <id>`, `paseo loop stop <id>`.

## Step 0.1: 前置避障读取 (Hard Mitigation Precheck) ⚠️ 硬性规定

**本步骤必须在构建 worker prompt 和启动任何循环之前无条件执行。**

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为全量(`command_error|wrong_assumption|tool_misuse|design_flaw`)。若提炼出避障规则，**必须将其作为 worker prompt 的硬性前缀注入**，格式见 reference §1。

## Your job

1. Understand the user's intent from `$ARGUMENTS` and the conversation.
2. **Worker prompt** — self-contained, concrete about what to do this iteration, explicit about what counts as progress. **若 Step 0.1 提取出了避障规则，必须将其作为 worker prompt 的硬性前缀注入。**
3. **上下文文件强制读取指令**：如果本 loop 是由 `using-upaseo` 的迭代流程触发，worker prompt 的第一条指令必须要求 worker 先依次读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md` 的绝对路径（由调用方显式传入；用当前宿主的文件读取原语，见 `upaseo/SKILL.md` 宿主工具兼容小节），再按本轮改动范围读取 `stories.md`、`data_models.md`、`apis.md` 或 `modules.md`。
4. **Verification** — pick the right shape:
   - Shell check (`--verify-check`) for objective criteria a command can answer (`gh pr checks --fail-fast`, `npm test`).
   - Verifier prompt (`--verify`) for judgment ("Return done=true only if all tests pass and the changed files are coherent. Cite the command and the outcome.").
   - Both, when shell rules out the obvious failures and the verifier judges the rest.
   - **合规检查注入**：verifier prompt 中必须增加一条检查——"确认 worker 的早期动作中读取了迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md` 这三个路径（按路径被读取判定，不按工具名判定），若任一缺失则判定为不合规（done=false）"。
5. **Providers** — `--provider` for the worker, `--verify-provider` for the verifier. From preferences unless the user named them. For implementation loops, pair worker and verifier on different providers — each catches the other's blind spots. **UI 或 styling 相关任务的 worker provider 从 `orchestration-preferences.json` 的 `ui` 分类解析；本项目 `ui` 已 pin 到 `codex/gpt-5.5`（未配置时回退 `codex/gpt-5.5`，详见 `upaseo/SKILL.md`）。**
6. **Sleep** — `--sleep` only when polling something external. Otherwise let it run as fast as the loop completes.
7. **Stops** — set a sensible `--max-iterations` and/or `--max-time`. Open-ended loops are how runaways happen.
8. **Archive** — `--archive` keeps agents after each iteration for inspection.
9. Launch with `paseo loop run`.

## Common shapes

**Babysit a PR** — worker checks PR state and fixes issues; shell check is `gh pr checks <n> --fail-fast`; sleep 2m; max-time 1h.

**Drive tests to green** — worker investigates failures and fixes code; shell check is the test command; verifier confirms all tests pass; max-iterations 10.

**Cross-provider implementation** — worker on `impl` provider, verifier on a different provider; verifier checks changed files, runs typecheck and tests; max-iterations and max-time both bounded; archive on so iterations can be inspected.

## Prompt rules

**Worker** — self-contained, concrete (commands, files, branches, tests, PRs, systems), explicit about what counts as progress this iteration. **必须包含避障规则前缀（若有），并在由 using-upaseo 触发时包含迭代设计文档、`architecture_constraints.md`、`coding_standards.md` 的强制读取指令（用当前宿主的文件读取原语，见 `upaseo/SKILL.md` 宿主工具兼容小节）。**

**Verifier** — checks facts, doesn't suggest fixes, cites commands/outputs/file evidence, specific about what "done" means. **必须包含合规检查：确认 worker 早期动作中读取了迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md` 这三个路径（无论用哪个宿主的文件读取原语，按"路径被读取"判定，不按工具名判定；详见 `upaseo/SKILL.md` 宿主工具兼容小节）。**

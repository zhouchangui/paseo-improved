---
name: upaseo-loop
description: >-
  Run an agent loop until an exit condition is met. Use when the user says
  "loop", "babysit", "keep trying until", "check every X", "watch", or wants
  iterative autonomous execution.
user-invocable: true
---

# Upaseo Loop Skill

A loop is a worker/verifier cycle: launch a worker → check verification → repeat until done or limits hit. Use for "keep trying", "babysit", or "watch this until X." This skill is a core primitive for the implement phase in `using-upaseo`.

**User's arguments:** $ARGUMENTS

## Prerequisites

Read the **upaseo** skill for orchestration preferences — worker and verifier providers come from preferences unless the user names them.

Loops are a CLI primitive: `paseo loop run`. Manage with `paseo loop ls`, `paseo loop inspect <id>`, `paseo loop logs <id>`, `paseo loop stop <id>`.

## Step 0.1: 前置避障读取 (Hard Mitigation Precheck) ⚠️ 硬性规定

**本步骤必须在构建 worker prompt 和启动任何循环之前无条件执行。**

1. 检查当前项目根目录下是否存在 `.paseo/learnings.jsonl` 文件。
2. 若文件存在，**必须立即使用 `view_file` 工具完整读取**。
3. 逐行解析其中的 JSON Lines 记录，提炼出所有历史避障规则。
4. **将提炼出的避障规则注入到 worker prompt 中**，作为 worker 的硬约束前缀。例如：
   ```
   [避障规则 - 来自历史教训，必须严格遵守]
   - docker compose 命令必须指定 -p dingding
   - ...
   [避障规则结束]
   ```
5. 若文件不存在，跳过本步骤，继续正常流程。

## Your job

1. Understand the user's intent from `$ARGUMENTS` and the conversation.
2. **Worker prompt** — self-contained, concrete about what to do this iteration, explicit about what counts as progress. **若 Step 0.1 提取出了避障规则，必须将其作为 worker prompt 的硬性前缀注入。**
3. **上下文文件强制读取指令**：如果本 loop 是由 `using-upaseo` 的迭代流程触发，worker prompt 的第一条指令必须要求 worker 先通过 `view_file` 依次读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md` 的绝对路径（由调用方显式传入），再按本轮改动范围读取 `stories.md`、`data_models.md`、`apis.md` 或 `modules.md`。
4. **Verification** — pick the right shape:
   - Shell check (`--verify-check`) for objective criteria a command can answer (`gh pr checks --fail-fast`, `npm test`).
   - Verifier prompt (`--verify`) for judgment ("Return done=true only if all tests pass and the changed files are coherent. Cite the command and the outcome.").
   - Both, when shell rules out the obvious failures and the verifier judges the rest.
   - **合规检查注入**：verifier prompt 中必须增加一条检查——"确认 worker 的早期 tool call 中包含 `view_file` 读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md`，若任一缺失则判定为不合规（done=false）"。
5. **Providers** — `--provider` for the worker, `--verify-provider` for the verifier. From preferences unless the user named them. For implementation loops, pair worker and verifier on different providers — each catches the other's blind spots. **Remember, if the task is UI or styling related, the worker provider MUST be Gemini.**
6. **Sleep** — `--sleep` only when polling something external. Otherwise let it run as fast as the loop completes.
7. **Stops** — set a sensible `--max-iterations` and/or `--max-time`. Open-ended loops are how runaways happen.
8. **Archive** — `--archive` keeps agents after each iteration for inspection.
9. Launch with `paseo loop run`.

## Common shapes

**Babysit a PR** — worker checks PR state and fixes issues; shell check is `gh pr checks <n> --fail-fast`; sleep 2m; max-time 1h.

**Drive tests to green** — worker investigates failures and fixes code; shell check is the test command; verifier confirms all tests pass; max-iterations 10.

**Cross-provider implementation** — worker on `impl` provider, verifier on a different provider; verifier checks changed files, runs typecheck and tests; max-iterations and max-time both bounded; archive on so iterations can be inspected.

## Prompt rules

**Worker** — self-contained, concrete (commands, files, branches, tests, PRs, systems), explicit about what counts as progress this iteration. **必须包含避障规则前缀（若有），并在由 using-upaseo 触发时包含迭代设计文档、`architecture_constraints.md`、`coding_standards.md` 的强制读取指令。**

**Verifier** — checks facts, doesn't suggest fixes, cites commands/outputs/file evidence, specific about what "done" means. **必须包含合规检查：确认 worker 早期 tool call 中含有 view_file 读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md`。**

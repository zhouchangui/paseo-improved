---
name: upaseo
description: Foundation reference for Paseo agents, worktrees, CLI, provider preferences, and daemon operations. This is not the product development workflow entrypoint; use using-upaseo for end-to-end development.
---

# Upaseo Foundation Reference

`upaseo` is the low-level foundation reference for skills that need to manage Paseo agents, worktrees, provider preferences, schedules, or daemon diagnostics. It is not a user-facing development workflow.

For full product development tasks, use `/using-upaseo <task>`. That workflow owns planning, iteration design, Design Council review, implementation loops, verification gates, story asset updates, review, and delivery.

## Scope Boundary

- `upaseo` owns: daemon/CLI surface, agent and worktree primitives, provider preference format, async waiting rules, schedules, and debugging commands.
- `using-upaseo` owns: end-to-end development orchestration, quick/full mode selection, `.paseo/` asset initialization, iteration planning, plan-review council, `upaseo-loop` execution, validation gates, asset refresh, and session recovery.
- Other upaseo skills should read this file only when they need low-level Paseo mechanics. They should not duplicate or reimplement the complete development lifecycle.

## Host Tool Compatibility

Skill prompts describe file reads as a **semantic requirement**, not a hard dependency on one host API. The phrase "读取 `<path>`" (or the legacy word `view_file`) means: read that file using whatever non-mutating file-read primitive the current host runtime provides. Known host mappings:

| Host | File-read primitive |
|:---|:---|
| Codex | `view_file` |
| ZCode | `Read` |
| Claude Code | `Read` |
| Gemini CLI | `read_file` |

When writing prompts for child agents, keep the wording explicit: they must read the listed files before acting, using whatever file-read tool their runtime provides. **Never write a verifier or compliance check that greps a worker's tool-call stream for a literal tool name** (e.g. `view_file`) — match on the *paths read* instead, so the check holds across hosts.

## Runtime Backend

Upaseo assumes **Paseo as the default execution backend**: the daemon owns agent lifecycle, worktree management, the loop primitive, async completion notifications, and the CLI surface. This is an explicit architectural decision (the project requirement exempts Paseo from "external dependency" status) and is **not** host-coupling — Paseo is the backend, while the host (Codex/ZCode/Gemini CLI/Claude Code) is the runtime that drives the skills.

Boundary:

- **Backend primitives (provided by Paseo, not host-replaceable here)**: `create_agent`, `send_agent_prompt`, `list_agents`, `archive_agent`, `create_worktree`, `list_worktrees`, `archive_worktree`, `create_schedule`, `paseo loop run`, daemon health/debug, async `background` + `notifyOnFinish` contract.
- **Host tools (replaceable per host)**: file-read primitive (see table above), slash-command invocation, skill loading mechanism, shell/PATH, and any host-specific hooks (e.g. Codex `PreCompact`/`PostCompact`).

Making the backend itself pluggable across hosts is out of scope for the current design; skills that need low-level mechanics should read this file.

## Source-of-Truth Priority Chain

When a session has multiple durable documents (goal, plan, handoff, compact), recovery and decision-making must follow a single authoritative priority chain to avoid the "each doc claims read-me-first" conflict. Defined here as the single source.

**Priority (high to low):**

1. **compact** (`.paseo/compacts/<ts>-<slug>.md`) — newest现场快照, wins for workspace state, current progress, validation evidence, next actions.
2. **handoff** (`.paseo/handoffs/<ts>-<slug>.md`) — wins for task semantics, acceptance criteria, what-was-tried, decisions, constraints carried to a fresh agent.
3. **plan** (`.paseo/plans/<slug>.md` + `.paseo/plans/<slug>/iter_N_design_tasks.md`) — wins for roadmap, iteration state machine (`State:` field), progress notes, per-iteration design.
4. **goal** (`.paseo/goals/<slug>.md`) — wins for **目标 / 边界 / 验证 constraints only**. Goal boundary and acceptance constraints are immutable by higher-priority docs; higher-priority docs may refine implementation but must not dilute or remove goal constraints.

**Conflict resolution rule:** Read in chain order (compact → handoff → plan → goal). For *workspace state / current progress / next actions*, the highest-priority document present wins. For *goal boundary and acceptance constraints*, the goal is authoritative and cannot be overridden. If a higher-priority doc's stated plan contradicts the goal boundary, surface the conflict to the user instead of silently proceeding.

**Recovery entry point:** `using-upaseo` 异常恢复、`upaseo-compact` Restore Prompt、`upaseo-handoff` 首步读取 all reference this chain instead of each claiming "read me first." Each durable document should declare its own `Priority:` position in its front matter / header.

Upaseo is backed by a daemon that supervises AI coding agents on your machine. Control it through tools or a CLI.

## Worktrees

**`create_worktree`** — three modes:

- From a PR: `{ githubPrNumber: 503 }`.
- Branch off a base: `{ action: "branch-off", branchName: "fix/foo", baseBranch: "main" }`.
- Checkout an existing ref: `{ action: "checkout", refName: "feat/bar" }`.

Returns `{ branchName, worktreePath }`. Pass `cwd` to target a specific repo.

**`list_worktrees`** — current repo (or pass `cwd`).
**`archive_worktree`** — `{ worktreePath }` or `{ worktreeSlug }`. Removes worktree and branch.

## Agents

**`create_agent`** — required: `title`, `provider` (`claude/opus`, `codex/gpt-5.4`, `gemini/gemini-2.5-pro`…), `initialPrompt`. Common: `cwd` (often a `worktreePath`), `background` (default `false` — blocks until completion or permission), `notifyOnFinish`. Returns `{ agentId, … }`.

Compose: call `create_worktree` first, then `create_agent` with `cwd` set to the returned `worktreePath`.

**`send_agent_prompt`** — `{ agentId, prompt }`. Blocks by default; pass `background: true` to fire-and-forget.

**`list_agents`** — filter by `cwd`, `statuses`, `sinceHours`, `includeArchived`.

**`archive_agent`** — `{ agentId }`. Interrupts if running, removes from active list.

## Heartbeats

**`create_schedule`** — required: `prompt`. Pick one of `cron` or `every` (`"5m"`, `"1h"`). Optional: `name`, `target` (`self` | `new-agent`), `provider`, `maxRuns`, `expiresIn`. Use for periodic checks on long-running work or recurring maintenance.

## Models

`claude/sonnet` (default), `claude/opus` (harder reasoning), `codex/gpt-5.5` (frontier coding, default for this project via preferences), `gemini/gemini-2.5-pro` (UI & structural design), `claude/haiku` (tests only).

## Orchestration preferences

User-specific configuration at `~/.paseo/orchestration-preferences.json`. **Any upaseo skill that picks an agent reads this file.** Never hardcode a provider string in another skill — resolve through this file.

Two parts:

- `providers` — map of role categories to provider strings. Pass straight to `create_agent`'s `provider` field.
- `preferences` — freeform string array. Read on startup; weave into agent prompts contextually.

Categories: `impl`, `ui`, `research`, `planning`, `audit`. Skills pick the category that matches the role they're launching.

```json
{
  "providers": {
    "impl": "codex/gpt-5.5",
    "ui": "codex/gpt-5.5",
    "research": "codex/gpt-5.5",
    "planning": "codex/gpt-5.5",
    "audit": "codex/gpt-5.5"
  },
  "preferences": [
    "For this project all role categories default to codex/gpt-5.5; override a category only when a task clearly benefits from a different provider's strengths."
  ]
}
```

If the file is missing, use sensible defaults and tell the user once. For this project the user has pinned all categories (impl/ui/research/planning/audit/test/acceptance) to `codex/gpt-5.5` — skills must respect that pinning and not silently fall back to Gemini for UI/styling.

## Waiting

Agents take time — 10–30+ minutes is routine. Favor asynchronous workflows.

For every `create_agent` or `send_agent_prompt`, pass `background: true` and `notifyOnFinish: true`. Paseo delivers a notification to your conversation when the agent finishes, errors, or needs permission. **You must not call `wait_for_agent` on a notify-on-finish agent.** Move on to other work. The notification arrives on its own.

Don't poll `list_agents` or `get_agent_status` to "check on" a running agent. The notification will tell you.

## CLI parity

The `paseo` CLI is a thin wrapper over the same daemon. Same surface:

```bash
paseo run --provider codex/gpt-5.4 --mode full-access --worktree feat/x "<prompt>"
paseo send <agent-id> "<follow-up>"
paseo ls
paseo worktree ls
paseo schedule create --every 5m "ping main build"
```

Discover with `paseo --help` and `paseo <cmd> --help`.

**If `paseo` isn't on PATH but the desktop app is installed**, the bundled CLI is at:

- macOS: `/Applications/Paseo.app/Contents/Resources/bin/paseo`
- Linux: `<install-dir>/resources/bin/paseo`
- Windows: `C:\Program Files\Paseo\resources\bin\paseo.cmd`

The desktop app's first-run hook (`installCli`) symlinks this to `~/.local/bin/paseo` (macOS/Linux) or drops a `.cmd` trampoline (Windows) and adds `~/.local/bin` to PATH via shell rc files. If that didn't take, offer to symlink it — don't do it silently.

## Ops and debugging

Daemon-client architecture: the daemon owns agent lifecycle, state, and the WebSocket API. Tools, CLI, mobile, and desktop apps are all clients.

|                | Default                                    |
| -------------- | ------------------------------------------ |
| Listen address | `127.0.0.1:6767` (override `PASEO_LISTEN`) |
| Home           | `~/.paseo` (override `PASEO_HOME`)         |
| Daemon log     | `$PASEO_HOME/daemon.log`                   |
| Agent state    | `$PASEO_HOME/agents/<id>.json`             |
| Worktrees      | `$PASEO_HOME/worktrees/`                   |
| PID file       | `$PASEO_HOME/paseo.pid`                    |
| Health         | `GET http://127.0.0.1:6767/api/health`     |

Debug order:

1. `tail -n 200 ~/.paseo/daemon.log`.
2. `paseo daemon status` for liveness.
3. `curl -s localhost:6767/api/health` if the CLI itself is suspect.

**Never restart the daemon without explicit user approval** — it kills every running agent, including, often, the one asking.

## Shared Learnings Format

Workflow skills use learnings files for hard mitigation rules. The full precheck procedure, read order (global + project), category scoping, aging rules, and write format are defined in the **single source of truth**: `upaseo/references/learnings-precheck.md`.

Key points (full detail in the reference):

- Read order: `~/.paseo/global-learnings.jsonl` first (cross-project, maintained by `/upaseo-ship`), then project-level `.paseo/learnings.jsonl`.
- `using-upaseo` owns the lifecycle of the project-level file; `/upaseo-ship` owns the global file sync.
- Any skill that injects constraints reads both files per the reference's category scoping.
- Capacity cap 30 lines/file. Overflow handled by aging-then-trim per the reference.

## Workflow Recovery Ownership

Interrupted development workflow recovery belongs to `using-upaseo`, because it owns `.paseo/plans/`, iteration state, validation gates, and asset refresh. `upaseo` only provides the agent/worktree/daemon primitives needed by that recovery flow.

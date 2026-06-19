<!-- Host note: the @import below is a Codex-specific directive. On non-Codex hosts (ZCode, Gemini CLI, Claude Code), ignore this line and rely on the rest of this file. -->
@/Users/zcg/.codex/RTK.md

# Upaseo Agent Guide

## Project Rules

- Daily development starts from `/using-upaseo <task>`. The low-level `upaseo` skill is reference material, not the full workflow entrypoint.
- Project runtime state lives under `.paseo/`: goals, plans, handoffs, compacts, `todos.md`, and `learnings.jsonl`.
- Long-lived project assets live under `.agents/story/`, so any coding agent can discover them from this file before making changes.
- Before architecture, module, API, data model, user-facing behavior, or coding-standard changes, read the relevant `.agents/story/` asset first.
- Keep all conclusions evidence-backed with command output, tests, logs, or explicit unverified labels.

## Story Assets

- User stories and functional map: `.agents/story/stories.md`
- Data models and schema map: `.agents/story/data_models.md`
- Public APIs and service contracts: `.agents/story/apis.md`
- Modules, packages, routes, and page topology: `.agents/story/modules.md`
- Architecture constraints and system boundaries: `.agents/story/architecture_constraints.md`
- Coding standards, commands, and validation rules: `.agents/story/coding_standards.md`

## Workflow Rules

- Optional goal artifacts live under `.paseo/goals/<slug>.md`; active execution plans live under `.paseo/plans/<slug>.md` and `.paseo/plans/<slug>/iter_N_design_tasks.md`.
- `upaseo-goal` is optional. When a goal file exists, `using-upaseo` should read the goal first and then produce a separate plan file; when no goal file exists, `using-upaseo` may plan directly from the user request.
- For integration / e2e validation tasks, use `/upaseo-e2e`: freeze the test environment first, write the full case matrix before execution, require one manual confirmation before running any case, require CLI tree coverage when applicable, reproduce failures before filing issues, and fall back to `.github/issues/` when `gh` is unavailable.
- If the user mentions todo, TODO, 待办, backlog, 记一下, or 后续要做, update `.paseo/todos.md` through `/upaseo-todo` instead of leaving it only in chat.
- Update `.agents/story/` only after implementation has been verified and the diff proves the asset change is real.
- If `.agents/story/` or this `AGENTS.md` file is missing in a target project, run `/upaseo-init` before normal iteration.

## Documentation Lookup

Use the `ctx7` CLI to fetch current documentation whenever a question or task depends on a library, framework, SDK, API, CLI tool, or cloud service. Run `library` first to resolve the package ID, then `docs` for the selected `/org/project` ID. Do not use ctx7 for refactoring, business-logic debugging, code review, or general programming concepts.

If ctx7 fails with quota errors, tell the user and suggest `npx ctx7@latest login` or `CONTEXT7_API_KEY`. If it fails with DNS or network errors, rerun it outside Codex's default sandbox.

## CodeGraph

Prefer CodeGraph for structural questions: definitions, call graphs, signatures, impact analysis, and focused task context. Use `codegraph_context` first for architecture, feature, and bug-context questions; use native search for literal text only.

If `.codegraph/` is not initialized and CodeGraph reports that state, ask the user whether to run `codegraph init -i` before relying on structural queries.

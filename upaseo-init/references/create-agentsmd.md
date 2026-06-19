# Create Agents.md Reference

This reference is embedded in `upaseo-init` so project initialization can create a complete, high-quality root `AGENTS.md` without depending on the standalone `create-agentsmd` skill at runtime.

## Purpose

`AGENTS.md` is a Markdown "README for agents": a predictable, repository-root file that gives coding agents the context, commands, constraints, and collaboration rules they need to work effectively in a project. It complements `README.md`; it should not replace human-facing documentation.

## Core Principles

- Agent-focused: include detailed technical instructions for automated coding tools.
- Complementary: avoid merely duplicating the README.
- Standard location: write `AGENTS.md` at the repository root by default.
- Standard Markdown: no required schema, but sections must be clear and executable.
- Ecosystem-compatible: avoid tool-specific assumptions unless the project requires them.

## Required Generation Steps

1. Analyze the project structure, languages, frameworks, package manager, and architecture.
2. Inspect key workflow sources such as `package.json` scripts, Makefiles, language build files, CI workflows, README files, and test/lint/typecheck configs.
3. Write specific, actionable commands that agents can run directly.
4. Do not invent commands. If a command cannot be found or verified, mark it as not discovered or requiring confirmation.
5. Preserve existing user rules when updating an existing `AGENTS.md`.

## Essential Sections

- `Project Overview`: purpose, key technologies, and architecture overview.
- `Setup Commands`: dependency installation, environment setup, database or external service preparation.
- `Development Workflow`: dev server, watch mode, package-manager conventions, and local debugging.
- `Testing Instructions`: all tests, focused tests, unit/integration/e2e tests, coverage, test locations, and naming conventions.
- `Code Style`: language conventions, linting, formatting, type checking, file organization, naming, imports, exports, and comments.
- `Build and Deployment`: build commands, output directories, environment configuration, deployment steps, and CI/CD notes.
- `Pull Request Guidelines`: title format, required checks, review process, and commit conventions when available.
- `Additional Notes`: project-specific gotchas, troubleshooting, performance, or operational notes.

## Recommended Sections

- `Security Considerations`: secrets, auth, permissions, sensitive data, and security testing requirements.
- `Monorepo Instructions`: package discovery, cross-package dependency rules, selective install/build/test commands.
- `Debugging and Troubleshooting`: common issues, logs, debug config, and performance diagnostics.

## Upaseo Addendum

When used by `upaseo-init`, the generated or updated `AGENTS.md` must also include an `Upaseo Workflow` or `Upaseo Agent Guide` section that documents:

- Daily development starts from `/using-upaseo <task>`.
- `.paseo/` stores runtime context such as goals, plans, handoffs, compacts, todos, and learnings.
- `.agents/story/` stores long-lived project assets.
- The six story assets are `stories.md`, `data_models.md`, `apis.md`, `modules.md`, `architecture_constraints.md`, and `coding_standards.md`.
- Before changing architecture, modules, APIs, data models, user-facing behavior, or coding standards, agents must read the relevant `.agents/story/` asset first.

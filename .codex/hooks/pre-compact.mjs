#!/usr/bin/env node

import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { execFileSync, spawnSync } from "node:child_process";

function readStdin() {
  return new Promise((resolve, reject) => {
    let data = "";
    process.stdin.setEncoding("utf8");
    process.stdin.on("data", (chunk) => {
      data += chunk;
    });
    process.stdin.on("end", () => resolve(data));
    process.stdin.on("error", reject);
  });
}

function safeJsonParse(text, fallback) {
  try {
    return JSON.parse(text);
  } catch {
    return fallback;
  }
}

function safeExec(cwd, args) {
  try {
    return execFileSync("git", args, {
      cwd,
      encoding: "utf8",
      stdio: ["ignore", "pipe", "ignore"]
    }).trim();
  } catch {
    return "";
  }
}

function safeReadFile(filePath) {
  try {
    return fs.readFileSync(filePath, "utf8");
  } catch {
    return "";
  }
}

function resolveRepoRoot(cwd) {
  return safeExec(cwd, ["rev-parse", "--show-toplevel"]) || cwd;
}

function timestampSlug(date = new Date()) {
  const yyyy = String(date.getFullYear());
  const mm = String(date.getMonth() + 1).padStart(2, "0");
  const dd = String(date.getDate()).padStart(2, "0");
  const hh = String(date.getHours()).padStart(2, "0");
  const mi = String(date.getMinutes()).padStart(2, "0");
  return `${yyyy}${mm}${dd}-${hh}${mi}`;
}

function safeSessionSlug(value) {
  return String(value || "session").replace(/[^a-zA-Z0-9_-]+/g, "-");
}

function slugify(value) {
  const out = String(value || "auto-compact")
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
  return out || "auto-compact";
}

function bestEffortTranscriptSnippet(transcriptPath, role) {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) return "";
  try {
    const tail = readTranscriptTail(transcriptPath);
    const pattern = new RegExp(
      `"role"\\s*:\\s*"${role}"[\\s\\S]{0,2200}?"text"\\s*:\\s*"((?:\\\\.|[^"\\\\]){1,1200})"`,
      "g"
    );
    let match;
    let last = "";
    while ((match = pattern.exec(tail)) !== null) {
      last = match[1];
    }
    if (!last) return "";
    return decodeJsonString(last).replace(/\s+/g, " ").trim().slice(0, 320);
  } catch {
    return "";
  }
}

function readTranscriptTail(transcriptPath) {
  const fd = fs.openSync(transcriptPath, "r");
  const stat = fs.fstatSync(fd);
  const readSize = Math.min(stat.size, 600_000);
  const start = Math.max(0, stat.size - readSize);
  const buffer = Buffer.alloc(readSize);
  fs.readSync(fd, buffer, 0, readSize, start);
  fs.closeSync(fd);
  return buffer.toString("utf8").replace(/\u0000/g, "");
}

function decodeJsonString(value) {
  try {
    return JSON.parse(`"${value}"`);
  } catch {
    return value;
  }
}

function splitSentences(text) {
  return String(text || "")
    .split(/(?<=[.!?。！？])\s+/)
    .map((line) => line.trim())
    .filter(Boolean);
}

function deriveAssistantSummary(text) {
  const sentences = splitSentences(text);
  if (sentences.length === 0) return "";

  const preferred = sentences.filter((line) =>
    /计划|下一步|继续|先|然后|修复|实现|验证|检查|需要|will|next|plan|verify|restore|continue/i.test(line)
  );
  const summary = (preferred.length > 0 ? preferred : sentences).slice(0, 3).join(" ");
  return summary.slice(0, 420);
}

function deriveDecisionBullets(latestAssistant) {
  if (!latestAssistant) {
    return [
      "使用项目级 compact 文档作为恢复事实源，而不是依赖系统 compact 摘要。",
      "保留 transcript_path 作为兜底证据来源，避免上下文遗漏时无从追溯。"
    ];
  }

  const decisions = splitSentences(latestAssistant)
    .filter((line) =>
      /决定|采用|保持|要求|必须|改成|继续|should|must|keep|use|prefer|plan/i.test(line)
    )
    .slice(0, 3);

  if (decisions.length === 0) {
    decisions.push(deriveAssistantSummary(latestAssistant));
  }

  decisions.unshift("使用项目级 compact 文档作为恢复事实源，而不是依赖系统 compact 摘要。");
  return Array.from(new Set(decisions.filter(Boolean))).slice(0, 4);
}

function deriveUnverifiedItems(gitStatusText, transcriptPath) {
  const items = [];
  if (gitStatusText && gitStatusText.trim()) {
    items.push("工作区存在未提交改动，恢复后需要先确认这些改动是否已完成验证。");
  }
  if (!transcriptPath) {
    items.push("本次 compact 没有 transcript_path，最近用户指令和助手结论只能靠工作区文件兜底恢复。");
  }
  items.push("没有明确通过证据的地方都按“未验证”处理，恢复后先补验证再宣称完成。");
  return items;
}

function deriveNextActions({ compactPath, filesToReadFirst, latestUser, assistantSummary, unverifiedItems }) {
  const actions = [];
  actions.push(`先读取 compact 文档 \`${compactPath}\`，再按顺序读取首批关键文件。`);
  if (latestUser) {
    actions.push(`核对最新用户指令是否仍然是：${latestUser}`);
  } else {
    actions.push("从 transcript 或关键计划文件中补齐最近用户指令，确认当前目标没有漂移。");
  }
  if (assistantSummary) {
    actions.push(`用最近助手结论作为恢复起点：${assistantSummary}`);
  }
  if (filesToReadFirst.length > 0) {
    actions.push(`优先检查：${filesToReadFirst.slice(0, 3).map(([filePath]) => path.basename(filePath)).join("、")}`);
  }
  if (unverifiedItems.length > 0) {
    actions.push(`补做未验证项：${unverifiedItems[0]}`);
  }
  return actions.slice(0, 4);
}

function uniqueBy(items, keyFn) {
  const seen = new Set();
  const result = [];
  for (const item of items) {
    const key = keyFn(item);
    if (!key || seen.has(key)) continue;
    seen.add(key);
    result.push(item);
  }
  return result;
}

function findLatestMarkdown(rootDir) {
  if (!fs.existsSync(rootDir)) return "";
  const stack = [rootDir];
  let latest = { path: "", mtimeMs: 0 };
  while (stack.length > 0) {
    const current = stack.pop();
    for (const entry of fs.readdirSync(current, { withFileTypes: true })) {
      const full = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(full);
        continue;
      }
      if (!entry.isFile() || !entry.name.endsWith(".md")) continue;
      const stat = fs.statSync(full);
      if (stat.mtimeMs > latest.mtimeMs) {
        latest = { path: full, mtimeMs: stat.mtimeMs };
      }
    }
  }
  return latest.path;
}

function buildFilesToReadFirst(repoRoot, transcriptPath) {
  const files = [];
  const agentsPath = path.join(repoRoot, "AGENTS.md");
  const requirementPath = path.join(repoRoot, "requirement.md");
  const learningsPath = path.join(repoRoot, ".paseo", "learnings.jsonl");
  const latestPlan = findLatestMarkdown(path.join(repoRoot, ".paseo", "plans"));
  const latestHandoff = findLatestMarkdown(path.join(repoRoot, ".paseo", "handoffs"));

  if (fs.existsSync(agentsPath)) files.push([agentsPath, "workspace instructions"]);
  if (fs.existsSync(requirementPath)) files.push([requirementPath, "workflow or task requirements"]);
  if (latestPlan) files.push([latestPlan, "latest plan or iteration source of truth"]);
  if (latestHandoff) files.push([latestHandoff, "latest handoff context if work was transferred"]);
  if (fs.existsSync(learningsPath)) files.push([learningsPath, "project learnings and avoid rules"]);
  if (transcriptPath && fs.existsSync(transcriptPath)) {
    files.push([transcriptPath, "original transcript when compact summary is insufficient"]);
  }
  return files;
}

function summarizeGitStatus(statusText) {
  if (!statusText) return "clean or unavailable";
  const lines = statusText.split("\n").filter(Boolean);
  if (lines.length === 0) return "clean";
  return `${lines.length} changed path(s): ${lines.slice(0, 8).join(" | ")}${lines.length > 8 ? " | ..." : ""}`;
}

function formatSectionList(items) {
  return items.map(([filePath, why]) => `- \`${filePath}\` — ${why}`).join("\n");
}

function buildCompactionSubagentPrompt({
  repoRoot,
  transcriptPath,
  latestUser,
  latestAssistant,
  branch,
  gitStatusSummary,
  filesToReadFirst
}) {
  const filesBlock = filesToReadFirst.length
    ? filesToReadFirst.map(([filePath, why]) => `- ${filePath} — ${why}`).join("\n")
    : "- none";

  return `You are a read-only compact-prep subagent.

Your task is to produce a high-signal recovery summary for a parent Codex compact hook.

Hard constraints:
- Work read-only.
- Do not modify files.
- Do not run destructive commands.
- Prefer facts over inference.
- If evidence is missing, say "unknown" or "未验证".

Workspace:
- Repo root: ${repoRoot}
- Branch: ${branch || "unknown"}
- Git status summary: ${gitStatusSummary}
- Transcript path: ${transcriptPath || "null"}

Hints:
- Latest user text: ${latestUser || "unknown"}
- Latest assistant text: ${latestAssistant || "unknown"}

Likely relevant files:
${filesBlock}

Use the transcript if available and read the minimum additional files needed to reconstruct:
1. current work goal
2. latest user instructions
3. current progress
4. next steps
5. relevant files
6. validation state

Return strict JSON matching the provided schema. Keep entries concise and concrete.`;
}

function runCompactionSubagent({
  repoRoot,
  transcriptPath,
  latestUser,
  latestAssistant,
  branch,
  gitStatusSummary,
  filesToReadFirst,
  compactDir
}) {
  if (!transcriptPath || !fs.existsSync(transcriptPath)) {
    return { ok: false, reason: "missing transcript_path" };
  }

  const schemaPath = path.join(compactDir, `.compact-schema-${process.pid}.json`);
  const outputPath = path.join(compactDir, `.compact-output-${process.pid}.json`);
  const schema = {
    type: "object",
    additionalProperties: false,
    required: [
      "task",
      "latest_user_instructions",
      "current_progress",
      "decisions",
      "validation_evidence",
      "risks_and_blockers",
      "next_actions",
      "files_to_read_first"
    ],
    properties: {
      task: { type: "string" },
      latest_user_instructions: {
        type: "array",
        items: { type: "string" }
      },
      current_progress: {
        type: "object",
        additionalProperties: false,
        required: ["done", "in_progress", "not_done"],
        properties: {
          done: { type: "string" },
          in_progress: { type: "string" },
          not_done: { type: "string" }
        }
      },
      decisions: {
        type: "array",
        items: { type: "string" }
      },
      validation_evidence: {
        type: "array",
        items: { type: "string" }
      },
      risks_and_blockers: {
        type: "array",
        items: { type: "string" }
      },
      next_actions: {
        type: "array",
        items: { type: "string" }
      },
      files_to_read_first: {
        type: "array",
        items: {
          type: "object",
          additionalProperties: false,
          required: ["path", "why"],
          properties: {
            path: { type: "string" },
            why: { type: "string" }
          }
        }
      }
    }
  };

  fs.writeFileSync(schemaPath, JSON.stringify(schema, null, 2), "utf8");

  const prompt = buildCompactionSubagentPrompt({
    repoRoot,
    transcriptPath,
    latestUser,
    latestAssistant,
    branch,
    gitStatusSummary,
    filesToReadFirst
  });

  const result = spawnSync(
    "codex",
    [
      "exec",
      "--ephemeral",
      "--ignore-user-config",
      "--ignore-rules",
      "-s",
      "read-only",
      "-C",
      repoRoot,
      "-c",
      "hooks={}",
      "--output-schema",
      schemaPath,
      "-o",
      outputPath,
      "-"
    ],
    {
      input: prompt,
      encoding: "utf8",
      timeout: 45_000,
      env: {
        ...process.env,
        CODEX_HOME: process.env.CODEX_HOME || path.join(os.homedir(), ".codex")
      }
    }
  );

  const output = safeJsonParse(safeReadFile(outputPath), null);

  try {
    fs.rmSync(schemaPath, { force: true });
    fs.rmSync(outputPath, { force: true });
  } catch {
    // Ignore cleanup failures in hook path.
  }

  if (result.status !== 0 || !output) {
    return {
      ok: false,
      reason: `codex exec failed with status ${result.status ?? "unknown"}`
    };
  }

  return { ok: true, data: output };
}

function buildDocument({
  compactPath,
  cwd,
  branch,
  gitStatusSummary,
  gitStatusText,
  filesToReadFirst,
  latestUser,
  latestAssistant,
  assistantSummary,
  decisionBullets,
  unverifiedItems,
  nextActions,
  progressState,
  validationEvidence,
  subagentMode,
  transcriptPath,
  trigger,
  sessionId,
  turnId
}) {
  const objective = latestUser || "Resume the interrupted active task from this workspace.";
  const restorePrompt = [
    "请从 upaseo compact 文档恢复现场。",
    "",
    `1. 先读取：${compactPath}`,
    `2. 确认当前 cwd 是：${cwd}`,
    "3. 根据文档里的 Task、Latest User Instructions、Workspace State、Files To Read First、Validation Evidence 和 Next Actions 恢复上下文。",
    "4. 先用 3-6 句话汇报你恢复到的现场、下一步计划和任何不确定点。",
    `5. 然后继续执行当前目标：${objective}`,
    "",
    "不要依赖系统 compact 的摘要；compact 文档是 Source of Truth。不要重置或丢弃未提交改动。缺少证据的地方按“未验证”处理，先补验证再宣称完成。"
  ].join("\n");

  return `# Compact Context: ${objective}

## Restore Prompt
${restorePrompt}

## Task
${objective}

## Latest User Instructions
- ${latestUser || "未从 transcript 提取到明确用户指令；恢复后先查看 transcript_path 和最近变更。"}

## Workspace State
- Cwd: \`${cwd}\`
- Branch: \`${branch || "unknown"}\`
- Git status: \`${gitStatusSummary}\`
- Active mode: \`compact\`
- Trigger: \`${trigger || "unknown"}\`
- Session: \`${sessionId || "unknown"}\`
- Turn: \`${turnId || "unknown"}\`

## Files To Read First
${formatSectionList(filesToReadFirst)}

## Current Progress
- Done: 已保留 compact 前的工作区状态、关键文件入口和恢复提示词。
- In progress: ${progressState.inProgress || assistantSummary || "当前会话在 compact 前被压缩；需要恢复后继续原任务。"}
- Not done: ${progressState.notDone || unverifiedItems[0] || "原任务本身尚未完成，恢复后应先核对最新用户意图与未验证项。"}

## Decisions
${decisionBullets.map((line) => `- ${line}`).join("\n")}

## Validation Evidence
${validationEvidence.map((line) => `- ${line}`).join("\n")}

## Risks And Blockers
${unverifiedItems.map((line) => `- ${line}`).join("\n")}
- 若 transcript_path 不可读或格式变化，恢复后需要人工补读关键文件和未完成改动。

## Next Actions
${nextActions.map((line, index) => `${index + 1}. ${line}`).join("\n")}

## Do Not Lose
- 最新用户意图：${latestUser || "unknown"}
- 最近助手结论：${assistantSummary || latestAssistant || "unknown"}
- 当前工作区状态：${gitStatusSummary}
- 压缩模式：${subagentMode}
- 原始 git status:
\`\`\`text
${gitStatusText || "clean or unavailable"}
\`\`\`

## Avoid
- 不要依赖系统 compact 摘要单独恢复。
- 不要假设验证已经完成；没有证据就按未验证处理。
- 不要 reset、checkout 或清理未提交改动。
`;
}

async function main() {
  const input = safeJsonParse(await readStdin(), {});
  const cwd = input.cwd || process.cwd();
  const repoRoot = resolveRepoRoot(cwd);
  const transcriptPath = input.transcript_path || "";
  const sessionId = input.session_id || "unknown-session";
  const turnId = input.turn_id || "unknown-turn";
  const trigger = input.trigger || "auto";
  const branch = safeExec(repoRoot, ["rev-parse", "--abbrev-ref", "HEAD"]);
  const gitStatus = safeExec(repoRoot, ["status", "--short"]);
  const latestUser = bestEffortTranscriptSnippet(transcriptPath, "user");
  const latestAssistant = bestEffortTranscriptSnippet(transcriptPath, "assistant");
  const compactDir = path.join(repoRoot, ".paseo", "compacts");
  fs.mkdirSync(compactDir, { recursive: true });
  const gitStatusSummary = summarizeGitStatus(gitStatus);
  const heuristicFilesToRead = buildFilesToReadFirst(repoRoot, transcriptPath);
  const heuristicAssistantSummary = deriveAssistantSummary(latestAssistant);
  const heuristicDecisions = deriveDecisionBullets(latestAssistant);
  const heuristicUnverified = deriveUnverifiedItems(gitStatus, transcriptPath);
  const subagent = runCompactionSubagent({
    repoRoot,
    transcriptPath,
    latestUser,
    latestAssistant,
    branch,
    gitStatusSummary,
    filesToReadFirst: heuristicFilesToRead,
    compactDir
  });

  const subData = subagent.ok ? subagent.data : null;
  const effectiveLatestUser = subData?.latest_user_instructions?.[0] || latestUser;
  const effectiveAssistantSummary =
    subData?.current_progress?.in_progress || heuristicAssistantSummary;
  const effectiveDecisions =
    subData?.decisions?.length ? subData.decisions : heuristicDecisions;
  const effectiveUnverified =
    subData?.risks_and_blockers?.length ? subData.risks_and_blockers : heuristicUnverified;
  const effectiveFilesToRead = uniqueBy(
    [
      ...(subData?.files_to_read_first || []).map((item) => [item.path, item.why]),
      ...heuristicFilesToRead
    ],
    ([filePath]) => filePath
  );

  const taskHint = subData?.task || effectiveLatestUser || branch || path.basename(repoRoot);
  const stamp = timestampSlug();
  const slug = slugify(taskHint);
  const compactPath = path.join(compactDir, `${stamp}-${slug}.md`);
  const statePath = path.join(compactDir, `.last-precompact-${safeSessionSlug(sessionId)}.json`);
  const effectiveNextActions =
    subData?.next_actions?.length
      ? subData.next_actions.slice(0, 4)
      : deriveNextActions({
          compactPath,
          filesToReadFirst: effectiveFilesToRead,
          latestUser: effectiveLatestUser,
          assistantSummary: effectiveAssistantSummary,
          unverifiedItems: effectiveUnverified
        });
  const validationEvidence = uniqueBy(
    [
      ...(subData?.validation_evidence || []),
      `\`git rev-parse --abbrev-ref HEAD\` — ${branch ? `pass: ${branch}` : "not run or unavailable"}`,
      `\`git status --short\` — ${gitStatusSummary}`,
      `transcript_path — \`${transcriptPath || "null"}\``,
      `latest assistant summary — \`${effectiveAssistantSummary || "unknown"}\``
    ],
    (line) => line
  );
  const progressState = {
    inProgress: subData?.current_progress?.in_progress || effectiveAssistantSummary,
    notDone: subData?.current_progress?.not_done || effectiveUnverified[0] || ""
  };
  const document = buildDocument({
    compactPath,
    cwd: repoRoot,
    branch,
    gitStatusSummary,
    gitStatusText: gitStatus,
    filesToReadFirst: effectiveFilesToRead,
    latestUser: effectiveLatestUser,
    latestAssistant,
    assistantSummary: effectiveAssistantSummary,
    decisionBullets: effectiveDecisions,
    unverifiedItems: effectiveUnverified,
    nextActions: effectiveNextActions,
    progressState,
    validationEvidence,
    subagentMode: subagent.ok ? "read-only codex exec subagent + heuristic fallback" : `heuristic fallback only (${subagent.reason || "unknown"})`,
    transcriptPath,
    trigger,
    sessionId,
    turnId
  });

  fs.writeFileSync(compactPath, document, "utf8");
  fs.writeFileSync(
    statePath,
    JSON.stringify(
      {
        compactPath,
        cwd: repoRoot,
        branch,
        latestUser: effectiveLatestUser,
        latestAssistant,
        assistantSummary: effectiveAssistantSummary,
        trigger,
        sessionId,
        turnId,
        subagentMode: subagent.ok ? "subagent" : "heuristic",
        createdAt: new Date().toISOString()
      },
      null,
      2
    ),
    "utf8"
  );

  process.stdout.write(JSON.stringify({ continue: true }));
}

main().catch(() => {
  process.stdout.write(JSON.stringify({ continue: true }));
});

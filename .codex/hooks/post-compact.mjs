#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { execFileSync } from "node:child_process";

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

function resolveRepoRoot(cwd) {
  return safeExec(cwd, ["rev-parse", "--show-toplevel"]) || cwd;
}

function safeSessionSlug(value) {
  return String(value || "session").replace(/[^a-zA-Z0-9_-]+/g, "-");
}

function latestCompactFile(compactDir) {
  if (!fs.existsSync(compactDir)) return "";
  const entries = fs
    .readdirSync(compactDir)
    .filter((name) => name.endsWith(".md"))
    .map((name) => {
      const full = path.join(compactDir, name);
      return { path: full, mtimeMs: fs.statSync(full).mtimeMs };
    })
    .sort((a, b) => b.mtimeMs - a.mtimeMs);
  return entries[0]?.path || "";
}

async function main() {
  const input = safeJsonParse(await readStdin(), {});
  const cwd = input.cwd || process.cwd();
  const repoRoot = resolveRepoRoot(cwd);
  const sessionId = input.session_id || "unknown-session";
  const compactDir = path.join(repoRoot, ".paseo", "compacts");
  const statePath = path.join(compactDir, `.last-precompact-${safeSessionSlug(sessionId)}.json`);
  const state = safeJsonParse(fs.existsSync(statePath) ? fs.readFileSync(statePath, "utf8") : "{}", {});
  const compactPath = state.compactPath || latestCompactFile(compactDir);
  const objective = state.latestUser || "Resume the interrupted active task from this workspace.";
  const effectiveCwd = state.cwd || repoRoot;

  const message = compactPath
    ? [
        "[Post-compaction context refresh]",
        `先读取 compact 文档：${compactPath}`,
        `确认当前 cwd：${effectiveCwd}`,
        `继续目标：${objective}`,
        "先用 3-6 句话汇报恢复到的现场、下一步计划和任何不确定点，然后继续执行。",
        "compact 文档是 Source of Truth。不要重置或丢弃未提交改动；没有证据的地方按未验证处理。"
      ].join("\n")
    : [
        "[Post-compaction context refresh]",
        "未找到最新 compact 文档。",
        `确认当前 cwd：${effectiveCwd}`,
        "先检查 .paseo/compacts/、AGENTS.md、requirement.md 和最近改动，再汇报恢复到的现场后继续执行。"
      ].join("\n");

  process.stdout.write(JSON.stringify({ continue: true, systemMessage: message }));
}

main().catch(() => {
  process.stdout.write(JSON.stringify({ continue: true }));
});

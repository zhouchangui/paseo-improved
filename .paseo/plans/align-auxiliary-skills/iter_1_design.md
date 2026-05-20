# 迭代 1 设计文档：辅助技能对齐上下文传递规则

## 迭代目标 (Iteration Goal)

将 `upaseo-advisor`、`upaseo-committee`、`upaseo-handoff` 三个辅助技能对齐 `roles.md` 中定义的全局规程：
1. 子 Agent 派生时必须传递计划文件绝对路径。
2. 子 Agent 启动后首步必须读取关键上下文文件。
3. 子 Agent 完工后必须发送包含 status + files_changed + summary 的通知。
4. Advisor/Committee 的 briefing prompt 中注入 learnings 避障规则前缀（若存在）。

## 极简技术方案 (Surgical Design)

对每个 SKILL.md 进行最小化插入，不改动现有指令逻辑，只在关键位置追加对齐规则：

### upaseo-advisor/SKILL.md
- 在 "The briefing" 段落之前插入：若项目存在 `.paseo/learnings.jsonl`，先读取并提炼避障规则，注入到 advisor 的 briefing prompt 前缀。
- 在 "Launch and synthesize" 段落明确：将结果包含 status + summary 结构化报告。

### upaseo-committee/SKILL.md  
- 在 "Phase 1: Plan" 之前插入：若项目存在 `.paseo/learnings.jsonl`，先读取并将避障规则作为 problem-level prompt 的前缀注入。
- 在 "Phase 3: Review" 末尾追加：完成 review 后通知 Orchestrator 包含结构化汇报。

### upaseo-handoff/SKILL.md
- 在 "The handoff prompt" 模板中追加 `## 避障规则` 段落占位（若存在 learnings）。
- 在模板中追加 `## 上下文文件` 段落：列出主计划和设计文档的绝对路径，要求接收 Agent 首步 view_file 读取。

## 验证计划 (Verification Plan)

- **验证方式**：`agent-run`（通过终端运行 grep 脚本验证）
- **具体验证命令**：
  ```bash
  # 验证三个文件都包含 learnings 读取指令
  for f in upaseo-advisor upaseo-committee upaseo-handoff; do
    grep -q "learnings" /Users/zcg/workroot/paseo-improved/$f/SKILL.md && echo "✅ $f" || echo "❌ $f"
  done
  
  # 验证三个文件都包含上下文传递规则
  for f in upaseo-advisor upaseo-committee upaseo-handoff; do
    grep -q "view_file\|首步" /Users/zcg/workroot/paseo-improved/$f/SKILL.md && echo "✅ $f 上下文" || echo "❌ $f 上下文"
  done
  ```
- **用户手动验证步骤**：运行 `git diff` 查看三个文件的具体改动，确认改动仅限于插入对齐规则，未改动原有逻辑。

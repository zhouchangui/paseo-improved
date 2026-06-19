---
name: upaseo-todo
description: >-
  项目待办记录技能。用户提到 todo、TODO、待办、记一下、加入待办、backlog、
  后续要做、ship 后关闭等场景时使用，把待办写入项目根目录 .paseo/todos.md，
  并在需要时更新完成、延期或取消状态。
---

# Upaseo Todo Skill

**User's request:** $ARGUMENTS

本技能只做一件事：把项目级待办沉淀到一个可审计的文件里，避免 todo 散落在对话、计划和 compact 摘要中。

## Core Rule

只要用户明确提到 `todo`、`TODO`、`待办`、`记一下`、`加入待办`、`backlog`、`后续要做` 等表达，就必须更新：

```text
<项目根目录>/.paseo/todos.md
```

不要只在对话里答应。`.paseo/todos.md` 是项目待办的 Source of Truth。

## Step 0: 避障读取

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `command_error|tool_misuse`。提炼与范围控制、重复记录、发布收尾、工作区安全相关的避障规则。

## Step 1: 自愈 todo 文件

若 `.paseo/` 不存在，先创建。若 `.paseo/todos.md` 不存在，创建以下模板：

```markdown
# Upaseo Project Todos

This file is the Source of Truth for project-level todos captured by `/upaseo-todo`.

## Active

## Done

## Deferred

## Cancelled

## Change Log
```

## Step 2: 记录或更新

根据用户意图选择最小动作：

- 新增：在 `## Active` 下追加一条未完成 todo。
- 完成：把对应条目标记为完成并移到 `## Done`，或在原条目上改为 `[x]`。
- 延期：移到 `## Deferred`，保留原因。
- 取消：移到 `## Cancelled`，保留原因。
- 查询：读取并概述当前 todo，不改文件。

新增条目格式：

```markdown
- [ ] T-YYYYMMDD-HHMM-<slug> | <title> | source: <user/plan/ship/simplify> | type: <task|debt> | created: YYYY-MM-DD | links: <plan/file:line/none> | note: <short context>
```

> `type` 字段缺省为 `task`。`type: debt` 用于登记精简阶梯（`upaseo/references/simplify-ladder.md`）为求简而取的延迟债务：`note` 写"捷径描述 + 被推迟的正确做法"，`source` 填 `simplify`，`links` 指向关联代码 `file:line`。debt 条目默认进 `## Active`，由 `upaseo-ship` 发布前复核。

状态更新格式：

```markdown
- [x] T-YYYYMMDD-HHMM-<slug> | <title> | source: <user/plan/ship/simplify> | type: <task|debt> | created: YYYY-MM-DD | completed: YYYY-MM-DD | shipped: <version/date/none> | links: <plan/file:line/none> | note: <short result>
```

## Matching Rules

- 新增前先扫描 `## Active`，如果已有语义相同的 todo，只补充 note 或 links，不重复创建。
- debt 条目（`type: debt`）同样进 `## Active`，按捷径描述语义去重：若同一捷径已登记，只补充 links/note，不重复建条目。
- 如果用户说“这个 todo 完成了”“关闭上一个 todo”，优先匹配最近新增或标题最接近的 Active 条目。
- 如果无法安全匹配完成/取消对象，不要猜；先列出候选并问用户确认。
- 用户只随口提到普通英文单词 `todo` 但没有待办内容时，不写入文件，先问一句要记录什么。

## Ship Integration

`/upaseo-ship` 必须读取 `.paseo/todos.md`。发布收尾时：

1. 根据本次主计划、CHANGELOG、release notes 和实际 diff，找出与本次发布明确对应的 Active todo。
2. 只关闭有证据证明已经交付的 todo。
3. 将这些 todo 标记为 `[x]`，写入 `completed:` 和 `shipped:`。
4. 无法确认的 todo 保持 Active，并在 ship 输出中报告“仍未关闭”。

## Output Format

完成后简短输出：

```text
已更新 todo：
<absolute path to .paseo/todos.md>

变更：
- <新增/完成/延期/取消/查询摘要>

验证：
- <文件存在、条目 id、必要状态>
```

## Quality Bar

- **不丢上下文**：待办必须包含来源、日期、短说明和相关文件/计划链接。
- **不制造噪音**：语义重复的 todo 合并，不爆炸式追加。
- **不误关任务**：ship 只能关闭有证据的项。
- **可恢复**：新 Agent 只读 `.paseo/todos.md` 就知道还有哪些项目债务。

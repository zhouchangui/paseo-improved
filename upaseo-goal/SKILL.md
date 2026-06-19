---
name: upaseo-goal
description: >-
  将用户的自然语言描述整理成简洁、统一、可由 agent 验证的 goal，并落盘到
  `.paseo/goals/slug.md`。适用于用户说“帮我写 goal”“把这个需求变成
  goal”“整理成可执行目标”“先定目标再做计划”等场景。
---

# Upaseo Goal Skill

**User's request:** $ARGUMENTS

本技能只做一件事：把用户的粗略描述转成一个短小、统一、可由 agent 验证的目标文档，并写入项目根目录：

```text
<项目根目录>/.paseo/goals/<slug>.md
```

本技能**不启动执行**、**不产出计划**、**不调用 `/goal`**。它只负责把零散描述整理成后续可供 `/using-upaseo` 读取的 goal。

## Step 0: 避障读取

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `design_flaw|wrong_assumption`。提炼与"目标定义、范围控制、验证方式、工具误用"相关的避障规则，作为 goal 草案的约束来源。

## Step 0.5: 读取当前项目上下文

在起草 goal 前，优先结合当前项目的真实上下文：

- 若存在 `AGENTS.md`，先读取其中的项目规则。
- 若目标会影响功能边界、模块职责、接口或架构约束，按需读取 `.agents/story/` 下相关资产。
- 若用户给了已有文件、旧计划、旧 goal 或验收线索，先读取这些事实源，再整理目标。

不要脱离当前项目现状写一个“看起来合理”的通用 goal。

## Goal 定义原则

在整理 goal 时，主动应用以下本地技能/原则：

- **`upaseo-brainstorm`**：当用户描述仍有歧义、存在多种合理方向、或边界不够清楚时，先按 Discover -> Propose -> Converge 流程收敛。最多给用户 3 个关键问题，或给出 2 个候选 goal 方向与 trade-offs，等用户确认后再落盘。
- **`karpathy-guidelines`**：显式写出关键假设，不默默替用户做高风险决定；优先更简单、更窄、更容易验证的目标表述；把“完成标准”写成可检查的事实。
- **`upaseo-simplify`**：在落盘前对 goal 文案做一次脱水。删掉实现方案、迭代拆分、角色分工、泛泛背景和未来扩展，只保留目标、边界和验证。

## Workflow

1. **提炼意图**
   - 找出用户真正想要的最终结果，而不是复述任务动作。
   - 至少要沉淀三类信息：要完成什么目标、边界在哪里、怎么验证完成。
   - 用户明确提到的硬约束优先写入 `边界` 或 `验证`，不要把它们埋在背景描述里。
   - 如果缺少关键验证方式，优先给出合理默认验证；只有无法安全假设时才问 1 个问题。

2. **生成 goal 草案**
   - 使用“结果导向”的写法：`完成什么目标` + `边界` + `怎么验证完成`。
   - Goal 必须能被另一个 Agent 独立理解和验证，不依赖本轮对话中的隐含语境。
   - Goal 不写实现方案、迭代拆分、角色分工、风险审计或执行步骤；这些都属于后续 `/using-upaseo` 产出的 plan。
   - 为 goal 生成一个短小稳定的 slug，作为 `.paseo/goals/<slug>.md` 的文件名。

3. **请求确认**
   - 向用户展示 goal 草案、拟写入路径和关键假设。
   - 明确说明：回复“确认”/“落盘”/“保存”后才会写入 `.paseo/goals/<slug>.md`。
   - 用户提出修改时，更新草案并再次确认；不要开始执行，也不要替用户生成计划。

4. **确认后落盘**
   - 若 `.paseo/goals/` 不存在，先创建目录。
   - 将最终 goal 草案写入 `.paseo/goals/<slug>.md`。
   - 写入完成后只汇报路径、内容摘要和后续衔接方式：`/using-upaseo` 可以读取这个 goal 再单独生成 `.paseo/plans/<slug>.md`。

## Goal 文档模板

```text
# Goal: <short title>

Priority: goal
> 本文件在 SoT 优先级链中位列最低（compact > handoff > plan > goal），但目标边界与验收约束不可被更高优先级文档覆盖或稀释。链定义见 `upaseo/SKILL.md` "Source-of-Truth Priority Chain"。

目标：
【一句话说明最终要完成的结果。】

边界：
【一句话说明本目标包含什么、不包含什么；若无需强调可写“仅限 ...，不扩展到 ...”。】

验证：
1. 【验证方式: logs|tests|browser|manual|agent-run】+【客观验证点 1】
2. 【验证方式: logs|tests|browser|manual|agent-run】+【客观验证点 2（如无则省略）】
```

## Quality Bar

好的 goal 应该满足：

- **结果清楚**：读者知道最终要交付什么。
- **边界清楚**：读者知道本次目标不打算顺手解决什么。
- **证据清楚**：知道用什么事实判断完成。
- **可独立落盘**：goal 文件脱离对话也能被另一个 Agent 读取。
- **长度克制**：优先 6-10 行；避免写成计划书。
- **职责单一**：goal 只定义目标、边界和验证，不混入 plan。

## 输出格式

确认前只输出：

```text
我建议把 goal 写成：

路径：
<项目根目录>/.paseo/goals/<slug>.md

<goal 草案>

回复“确认”后我会把它落盘；也可以直接告诉我要改哪一项。
```

确认后只写入 goal 文件，不启动执行，不追加计划讨论；若用户要继续推进，应交给 `/using-upaseo` 基于这个 goal 产出独立的 plan。

# 避障前置读取共享规程 (Learnings Precheck Reference)

本文件是所有 upaseo 技能共享的**单一事实源**,定义了"避障前置读取"的标准动作。各技能在自己的 SKILL.md 中不再重复完整规程,只写一行引用即可。

> 规程位置:本文件。
> 谁该读:任何启动后会向子 Agent 注入约束、构建 prompt 或做决策的 upaseo 技能。
> 何时读:技能启动的**第零优先级动作**,在任何其他步骤之前。

---

## 1. 标准动作 (五步)

1. **检查存在性**:确认当前项目根目录下是否存在 `.paseo/learnings.jsonl` 文件。
2. **读取**:若存在,**必须立即使用当前宿主的文件读取原语完整读取**(各宿主原语名见 `upaseo/SKILL.md` 的"宿主工具兼容"小节;Codex 为 `view_file`,ZCode/Claude Code 为 `Read`,Gemini CLI 为 `read_file`)。文件不存在则跳过本规程。
3. **解析**:逐行解析 JSON Lines 记录,提炼出其中的 `mitigation` 字段作为避障规则。
4. **作用域过滤**(见 §3):只保留与当前技能 category 相关的规则,不要把无关规则注入。
5. **注入**:将过滤后的规则作为**本会话/本子 Agent 的硬约束前缀**注入到后续决策、子 Agent prompt 或 verifier 检查中。注入格式:
   ```
   [避障规则 - 来自历史教训,必须严格遵守]
   - <规则1>
   - <规则2>
   [避障规则结束]
   ```
   若过滤后无规则,省略注入段落,不输出空壳。

---

## 2. 读取顺序 (global 优先 + 项目补充)

为避免"只写不读"的死功能,读取顺序固定为:

1. **先读全局**:`~/.paseo/global-learnings.jsonl`(跨项目通用教训,由 `/upaseo-ship` 同步写入)。
2. **再读项目**:`<项目根目录>/.paseo/learnings.jsonl`(项目专属教训)。
3. **合并去重**:若同一条 `mitigation` 在两处都出现,以项目级为准(项目可能修正了全局规则)。

两个文件都不存在时跳过本规程。global 文件由 `/upaseo-ship` 的 Step 4 维护,任何技能不再宣称 global 是"只写死功能"。

---

## 3. category 作用域过滤

learnings 记录的 `category` 字段(`command_error|wrong_assumption|tool_misuse|design_flaw`)用于决定一条规则对当前技能是否相关。注入前必须按下表过滤,避免把无关规则灌进不相关的决策(例如把 docker compose 命令错误灌进脑暴方案设计)。

| 技能 | 相关 category |
|:---|:---|
| `using-upaseo` / `upaseo-loop` / impl 类子 Agent | `command_error`, `wrong_assumption`, `tool_misuse`, `design_flaw`(全量,实现阶段风险面广) |
| `upaseo-brainstorm` / `upaseo-goal` | `design_flaw`, `wrong_assumption`(只关心设计假设) |
| `upaseo-advisor` / `upaseo-committee` | `design_flaw`, `wrong_assumption` |
| `upaseo-ship` | `command_error`(发布命令相关) |
| `upaseo-e2e` | `command_error`, `wrong_assumption`(测试命令与环境) |
| `upaseo-todo` / `upaseo-simplify` / `upaseo-reviewer` / `upaseo-compact` / `upaseo-handoff` | `command_error`, `tool_misuse` |

`category` 字段缺失的记录按"全量"处理(向后兼容旧记录),不丢弃。

---

## 4. 老化降级 (Aging)

learnings 记录可选 `last_confirmed` 字段(ISO8601)。老化规则:

- 记录无 `last_confirmed` 字段时,用 `timestamp` 字段兜底。
- 超过 **90 天**未被重新确认的条目,从"硬约束"降级为"软提示":注入时前缀改为 `[aged, soft]`,语义为"参考但不强制"。
- 容量控制(每文件 ≤ 30 条)的策略:**先老化降级,再按 `timestamp` 从旧到新裁剪**。优先裁剪已降级的软提示,裁剪到上限内。

---

## 5. 记录格式 (写入规范)

写入方(主要是 `using-upaseo` 的会话复盘步骤)必须遵循以下 JSON Lines 格式:

```json
{"timestamp":"<ISO8601>","session_id":"<conversation-id>","category":"<command_error|wrong_assumption|tool_misuse|design_flaw>","failed_attempt":"<简述失败操作>","mitigation":"<应该怎么做>","last_confirmed":"<ISO8601,可选>"}
```

- `timestamp`:记录创建时间。
- `last_confirmed`:最近一次在本会话中被实际触发/确认的时间;未确认则省略。
- 容量上限 30 条/文件。超过时按 §4 老化与裁剪。
- 写入前去重:检查 `mitigation` 字段是否与已有条目语义重复,重复则跳过或合并。

---

## 6. 引用方式

各技能 SKILL.md 中不再重复本规程,改为:

```markdown
## 前置避障读取

执行标准避障前置读取,见 `upaseo/references/learnings-precheck.md`。本技能的相关 category 见该文件 §3。
```

如需强调本技能专属的注入位置(例如 committee 注入到成员 prompt 前缀、loop 注入到 worker prompt 前缀),在该引用后补一行说明即可,不重复五步动作。

---
name: upaseo-reviewer
description: 本地代码自审与质量监督技能。融合 open-code-review (ocr) 大代码审查引擎与 Agent 模拟审计分层，在提交 PR 前对当前改动进行全面的安全性、稳健性、风格契合度审查，发现隐藏的 bug 和坏味道。
---

# Upaseo Reviewer (本地代码自审技能)

在代码推送 (git push) 或提 PR 之前，**必须强制加载并调用此技能**，从一个挑剔的、极其专业的外部资深代码审计师角度，对当前 diff 进行全方位审查。

## Scope Boundary

- 默认只审查当前 `git diff` 及其直接影响面；不得把历史遗留问题扩展成无关重构。
- 发现的问题若来自本次 diff，必须本地闭环修复；若来自旧代码且未被本次改动放大，只在报告中标注为"既有风险"，不顺手修改。
- 当用户直接调用本技能做只读 review 时，先输出 findings；只有用户明确要求修复，才进入本地闭环修改。

## 审查黄金法则

1. **绝对客观与严格**：
   - 绝不因为"代码是自己写的"而手软。必须像审查陌生人的提交一样对待当前的 diff。
   - 重点关注：边缘用例是否处理、类型定义是否完备、是否存在资源泄漏、异步调用是否未 catch 错误。

2. **零容忍代码坏味道 (Zero Smell)**：
   - 是否存在硬编码的魔术字、魔术数字、本地的硬编码绝对路径？
   - 是否存在潜在的安全性漏洞（如 SQL 注入风险、日志中打印了敏感密码/Token、不安全的动态执行）？

3. **与项目生态的和谐度 (Harmony)**：
   - 变更是否引入了重复的逻辑？是否可以使用项目已有的 utils/helpers 替代？

---

## 前置避障读取

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `command_error|tool_misuse`。提炼的规则作为审查清单的补充——若 diff 中的改动可能触犯某条历史教训，必须在审计报告中**专项标注**。

---

## 审查引擎分层 (Review Engine Tiers)

本技能采用分层审查引擎，强度挂靠 `using-upaseo` 执行模式（微改跳过 / quick 可选 / full 默认 Tier 1）：

### Tier 1：open-code-review (`ocr`) —— 完整模式默认

完整仪式模式默认调用 `ocr` CLI 进行大代码审查。ocr 是可选外部依赖（open-code-review，`ocr` 命令），不可用时降级到 Tier 2。

**ocr 可用性判定**（执行前自检）：
```bash
command -v ocr >/dev/null 2>&1 && ocr llm test >/dev/null 2>&1
```
两项都通过 = Tier 1 可用；任一失败 = 降级 Tier 2 并在报告中标注"ocr 不可用（未安装/未配 LLM/超时），已降级 Agent 模拟审计"。

**Tier 1 调用规程**：
```bash
ocr review \
  --audience agent \
  --format text \
  --from <迭代基线 base 分支或 SHA> \
  --to HEAD \
  --background "<本迭代目标一句话，作审查上下文>"
```
- `--audience agent`：输出 summary-only，便于 Agent 解析而非人类进度条。
- `--from`/`--to`：限定审查范围为本次迭代 diff；单 commit 场景用 `--commit <sha>`。
- `--background`：传迭代目标作业务上下文，让 ocr 聚焦本次意图而非泛泛而谈。
- 可选 `--rule .opencodereview/rule.json`：项目级自定义规则文件（本技能不自动生成，仅文档化位置；缺省走 ocr 内置规则）。
- 可选 `--model <model>`：覆盖默认 LLM。

**ocr findings 处理**：
- 把 ocr 输出的 findings 按 §严重度分级 归类。
- blocker 必须本地闭环修复；minor 记录进报告不阻断。
- ocr 若整体超时/报错（非单条 finding），降级 Tier 2 重审。

### Tier 2：Agent 模拟审计 —— 降级 / quick / 微改

ocr 不可用、快速模式可选、或微改快速通道（仍需最小自审）时，走 Agent 模拟审计，对照下方 §自审清单 输出"自审报告"。

---

## 自审清单 (Agent Audit Checklist, Tier 2)

Agent 在提 PR 之前（Tier 2 路径），必须模拟审计师的角色，对照以下条目输出一份"自审报告"：

1. **正确性与边缘情况 (Robustness)**：
   - 所有的异步操作（Promises, async/await）是否有妥善的错误处理？
   - 传入的参数是否进行了空值/非法边界防御？
   - 是否有任何潜在的线程/异步并发冲突、竞态条件 (race condition)？

2. **资源与内存控制 (Resources)**：
   - 创建的文件流、定时器、事件监听器、网络连接等，是否在生命周期结束时被 100% 妥善释放/注销？

3. **日志与可观测性 (Observability - 核心要求)**：
   - 本次改动是否留下了清晰、有意义的**关键事件调试日志**？
   - 日志输出是否足够支持我们执行"日志优先验证 (Log-Based Verification)"？如果日志过于空泛（例如仅有 `error occurred`），必须在此阶段补充详细的上下文。

4. **审计报告输出 (Report Output)**：
   - 梳理出自审发现的所有问题，按严重度分级处理（见下）。
   - 最终在 PR 描述或 Note 中包含一份极简的自审确认单（含 ocr findings 摘要或 Agent 清单结论）。

---

## 严重度分级 (Severity Triage)

无论 Tier 1 (ocr) 还是 Tier 2 (Agent)，findings 按严重度分级处理：

- **blocker**（安全/正确性/资源泄漏/数据丢失风险）：必须本地 100% 闭环修复，未修复不得提 PR。
- **minor**（风格/可读性/命名/可选优化）：记录进自审报告，不阻断 PR；可登记为 `type: debt` 到 `.paseo/todos.md` 留待后续。

> 这修正了旧版"自审发现任何缺陷必须 100% 闭环修复"的一刀切：blocker 闭环、minor 记录，避免为琐碎风格问题阻塞交付。

---

## 自审报告模板

```markdown
### upaseo-reviewer 自审报告：
- 引擎：Tier 1 (ocr) / Tier 2 (Agent 模拟审计) [ocr 不可用降级]
- ocr findings 摘要：blocker N / minor M（或"未启用 ocr"）
- [x] 无未使用变量/冗余导入
- [x] 所有异步处理均有 error catch
- [x] 日志覆盖度充足，已在关键节点输出 events
- [x] 未引入魔术字/敏感数据
- blocker 闭环：全部修复 / 无 blocker
- minor 登记：N 条已记入 .paseo/todos.md (type: debt)
```

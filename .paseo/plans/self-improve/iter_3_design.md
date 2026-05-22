# 迭代 3 设计文档：upaseo 基座增强

## 迭代目标

`upaseo/SKILL.md` 是所有 upaseo 技能的基座参考文档。当前缺少两个关键内容：
1. **learnings 机制全局说明**：所有 upaseo 技能都应知道 `.paseo/learnings.jsonl` 的存在和作用，但 upaseo 基座中完全没有提及。
2. **异常恢复规程**：upaseo 基座未描述 Agent 中断后如何恢复（这在 using-upaseo 中有，但基座中应有一个简要引用，供独立使用 upaseo 技能的场景参考）。

## 极简技术方案

在 `upaseo/SKILL.md` 末尾追加两个段落：

### 新增段落 1: 避障学习系统
约 10 行，描述：
- `.paseo/learnings.jsonl` 的用途和格式
- 所有 upaseo 技能启动时应读取此文件
- 容量上限 30 条

### 新增段落 2: 异常恢复
约 5 行，简要说明：
- 检查 `.paseo/plans/` 下是否有未完成的计划
- 从上次中断点恢复
- 引用 `using-upaseo` 技能的 §异常恢复 获取完整流程

总预计增加 20 行，不修改任何现有内容。

## 验证计划

- **验证方式**：`agent-run`
- **验证命令**：
  ```bash
  grep -q "learnings" /Users/zcg/workroot/paseo-improved/upaseo/SKILL.md && echo "✅ learnings" || echo "❌"
  grep -q "异常恢复\|Resumability" /Users/zcg/workroot/paseo-improved/upaseo/SKILL.md && echo "✅ 异常恢复" || echo "❌"
  ```
- **用户手动验证**：`cd /Users/zcg/workroot/paseo-improved && git diff upaseo/SKILL.md`

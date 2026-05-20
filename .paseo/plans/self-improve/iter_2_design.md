# 迭代 2 设计文档：对齐 brainstorm / simplify / reviewer 的 learnings 前置读取

## 迭代目标

`upaseo-brainstorm`、`upaseo-simplify`、`upaseo-reviewer` 三个技能目前完全没有引用 `learnings.jsonl`。根据需求 4.2，所有 upaseo 系列技能在执行关键动作前都应该读取避障学习记录。本迭代为这三个技能增加 learnings 前置读取段落。

每个技能的注入策略略有不同：
- **brainstorm**：在"发现阶段 (Discover)"之前注入，避障规则影响方案设计。
- **simplify**：在"Simplify Checklist"之前注入，历史教训影响精简判断。
- **reviewer**：在"Review Checklist"之前注入，避障规则补充审查清单。

## 极简技术方案

对每个 SKILL.md 在已有流程步骤之前插入一个 "前置避障读取" 段落，格式统一：

```markdown
## 前置避障读取

在执行核心流程前，检查当前项目根目录下是否存在 `.paseo/learnings.jsonl`。
若存在，使用 `view_file` 读取并提炼避障规则，在后续执行中作为硬约束遵守。
若不存在则跳过。
```

每个文件预计增加 5-8 行，不修改任何现有内容。

## 验证计划

- **验证方式**：`agent-run`
- **验证命令**：
  ```bash
  for f in upaseo-brainstorm upaseo-simplify upaseo-reviewer; do
    grep -q "learnings" /Users/zcg/workroot/paseo-improved/$f/SKILL.md && \
    grep -q "前置避障\|view_file" /Users/zcg/workroot/paseo-improved/$f/SKILL.md && \
    echo "✅ $f" || echo "❌ $f"
  done
  ```
- **用户手动验证**：`cd /Users/zcg/workroot/paseo-improved && git diff`

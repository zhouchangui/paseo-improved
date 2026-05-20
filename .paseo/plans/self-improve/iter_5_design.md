# 迭代 5 设计文档：using-paseo 拆分优化

## 迭代目标

`using-paseo/SKILL.md` 当前 271 行，是所有技能中最长的文件。Agent 加载此技能时上下文压力大。本迭代目标：

1. **提取快速模式参考卡**：将快速模式的独立流程提取到 `references/quick-mode.md`，主文件中保留引用链接和简要说明。
2. **提取参数速查表**：将所有参数定义提取到 `references/params.md`，主文件中保留 argument-hint 引用。

预计主文件减少 30-40 行，同时保持内容完整性。

## 极简技术方案

### [NEW] using-paseo/references/quick-mode.md
从主文件中提取快速模式的完整流程说明，包含：
- 触发条件
- 执行流程（单迭代：设计 → 实现 → 验证 → 提交）
- 与完整模式的差异

### [NEW] using-paseo/references/params.md
从需求文档中提取参数速查表 + 自主判定规则速查。

### [MODIFY] using-paseo/SKILL.md
- §0.2 自主复杂度判定：保留判定规则和模式表格（这是核心决策逻辑），但在快速模式流程描述处用引用链接替换详细说明。
- 末尾删除可由 references 替代的重复内容。

## 验证计划

- **验证方式**：`agent-run`
- **验证命令**：
  ```bash
  # 1. 主文件行数减少
  wc -l /Users/zcg/workroot/paseo-improved/using-paseo/SKILL.md
  # 2. 引用文件存在且内容完整
  test -f /Users/zcg/workroot/paseo-improved/using-paseo/references/quick-mode.md && echo "✅" || echo "❌"
  test -f /Users/zcg/workroot/paseo-improved/using-paseo/references/params.md && echo "✅" || echo "❌"
  # 3. validate.sh 仍然全绿
  bash /Users/zcg/workroot/paseo-improved/scripts/validate.sh
  ```
- **用户手动验证**：`git diff using-paseo/` 确认拆分逻辑正确，无信息丢失。

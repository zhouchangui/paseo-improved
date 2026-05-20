# upaseo — 自主开发工作流技能套件

基于 paseo 技能链 Rebrand 并增强的全本地化开发工作流，零外部技能依赖。

## 技能清单

| 技能 | 用途 | 触发方式 |
|:-----|:-----|:---------|
| `upaseo` | 基座：Worktree、Agent、CLI、偏好配置 | 被其他技能引用 |
| `using-paseo` | **核心入口**：完整开发生命周期编排 | `/using-paseo <task>` |
| `upaseo-loop` | 实现闭环：worker/verifier 循环 | `/upaseo-loop <task>` |
| `upaseo-brainstorm` | 脑暴收敛：极简方案设计 | 由 using-paseo 自动调用 |
| `upaseo-simplify` | PR 前代码极致精简 | 由 using-paseo 自动调用 |
| `upaseo-reviewer` | PR 前质量自审 | 由 using-paseo 自动调用 |
| `upaseo-advisor` | 单 Agent 二次意见 | `/upaseo-advisor <question>` |
| `upaseo-committee` | 双 Agent 根因分析 | `/upaseo-committee <problem>` |
| `upaseo-handoff` | 任务完整移交 | `/upaseo-handoff <task>` |

## 安装

```bash
# 将所有技能软链接到全局 skills 目录
cd /Users/zcg/workroot/paseo-improved
for skill in upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-handoff upaseo-loop upaseo-reviewer upaseo-simplify using-paseo; do
  ln -sf "$(pwd)/$skill" ~/.agents/skills/$skill
done
```

## 快速使用

```bash
# 完整仪式模式（Agent 自动判定）
/using-paseo 实现用户登录功能

# 强制快速模式
/using-paseo --quick 修复登录按钮样式

# 强制完整模式 + 每迭代独立 PR
/using-paseo --full --pr-per-iteration 重构数据层架构
```

## 目录结构

```
paseo-improved/
├── .gitignore
├── .paseo/                         # 运行时数据（learnings 不入库）
│   ├── learnings.jsonl             # 避障学习记录
│   └── plans/                      # 计划文件 (Source of Truth)
│       └── <slug>.md
├── requirement.md                  # 需求文档
├── scripts/
│   └── validate.sh                 # 自动化一致性验证
├── upaseo/                         # 基座技能
├── upaseo-advisor/
├── upaseo-brainstorm/
├── upaseo-committee/
├── upaseo-handoff/
├── upaseo-loop/
├── upaseo-reviewer/
├── upaseo-simplify/
├── using-paseo/                    # 核心编排入口
│   ├── SKILL.md
│   └── references/
│       └── roles.md
└── README.md
```

## 核心机制

- **避障学习**：`.paseo/learnings.jsonl` — 所有技能启动时读取，容量上限 30 条
- **自主判定**：Agent 自动选择 quick/full 模式和 auto-advance/gate 网关
- **日志优先验证**：验证以运行时日志为第一证据
- **Gemini UI 专属**：UI/Styling 任务强制使用 Gemini 模型

## 验证

```bash
bash scripts/validate.sh
```

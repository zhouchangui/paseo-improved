# upaseo — 自主开发工作流技能套件

基于 paseo 技能链 Rebrand 并增强的全本地化开发工作流，零外部技能依赖。日常开发只需要调用 `/using-upaseo <task>`；`upaseo` 只是底层基座参考，不作为完整开发入口使用。

## 技能清单

| 技能 | 用途 | 触发方式 |
|:-----|:-----|:---------|
| `upaseo` | 底层基座参考：Worktree、Agent、CLI、偏好配置、daemon 调试 | 被其他技能引用，不直接跑完整流程 |
| `using-upaseo` | **唯一完整开发入口**：计划、评审、实现、验证、交付编排 | `/using-upaseo <task>` |
| `upaseo-loop` | 实现闭环：worker/verifier 循环 | `/upaseo-loop <task>` |
| `upaseo-brainstorm` | 脑暴收敛：极简方案设计 | 由 using-upaseo 自动调用 |
| `upaseo-simplify` | PR 前代码极致精简 | 由 using-upaseo 自动调用 |
| `upaseo-reviewer` | PR 前质量自审 | 由 using-upaseo 自动调用 |
| `upaseo-init` | 项目初始化：自动构建 `.paseo/` 结构并逆向扫描提炼六大资产 | `/upaseo-init` |
| `upaseo-goal` | Goal 合成器：把粗略描述整理成可执行、可验收的 goal，确认后启动 `/goal` | `/upaseo-goal <rough request>` |
| `upaseo-ship` | PR 合并后的发布收尾：主干校验、资产固化、CHANGELOG、release metadata commit 与工作区清理 | `/upaseo-ship` |
| `upaseo-advisor` | 单 Agent 二次意见 | `/upaseo-advisor <question>` |
| `upaseo-committee` | 双 Agent 根因分析 | `/upaseo-committee <problem>` |
| `upaseo-handoff` | 任务完整移交 | `/upaseo-handoff <task>` |

## 安装

```bash
# 切换到项目根目录
cd /Users/zcg/workroot/paseo-improved

# 1. 软链接到本地 Agent 运行环境
for skill in upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-goal upaseo-handoff upaseo-init upaseo-loop upaseo-reviewer upaseo-ship upaseo-simplify using-upaseo; do
  ln -sf "$(pwd)/$skill" ~/.agents/skills/$skill
done

# 2. 软链接到 Antigravity 全局配置环境，以便在 / 中进行调用
for skill in upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-goal upaseo-handoff upaseo-init upaseo-loop upaseo-reviewer upaseo-ship upaseo-simplify using-upaseo; do
  ln -sf "$(pwd)/$skill" ~/.gemini/config/skills/$skill
done
```

## 快速使用

```bash
# 完整开发流程入口
/using-upaseo 实现用户登录功能

# 项目初始化与逆向（逆向生成已有的 stories, data_models, apis, modules, architecture_constraints, coding_standards 资产）
/upaseo-init

# 强制快速模式
/using-upaseo --quick 修复登录按钮样式

# 手动触发 Ship 自动化发布
/upaseo-ship

# 把粗略描述整理为 goal，确认后启动执行
/upaseo-goal 想修一下登录页移动端体验
```

## 目录结构

```
paseo-improved/
├── .gitignore
├── .paseo/                         # 运行时数据（learnings 不入库）
│   ├── learnings.jsonl             # 避障学习记录
│   ├── plans/                      # 计划文件 (Source of Truth)
│   │   ├── <slug>.md
│   │   └── <slug>/
│   │       └── iter_N_design_tasks.md
│   └── story/                      # 用户故事、数据模型、API、模块、架构约束、编码规范资产
│       ├── stories.md
│       ├── data_models.md
│       ├── apis.md
│       ├── modules.md
│       ├── architecture_constraints.md
│       └── coding_standards.md
├── requirement.md                  # 需求文档
├── scripts/
│   └── validate.sh                 # 自动化一致性验证
├── upaseo/                         # 基座技能
├── upaseo-advisor/
├── upaseo-brainstorm/
├── upaseo-committee/
├── upaseo-goal/                    # Goal 合成器：先确认，再启动 /goal
├── upaseo-handoff/
├── upaseo-init/                    # 项目初始化与逆向整理技能
├── upaseo-loop/
├── upaseo-reviewer/
├── upaseo-ship/                    # 自动化发布与清理技能
├── upaseo-simplify/
├── using-upaseo/                    # 核心编排入口
│   ├── SKILL.md
│   └── references/
│       └── roles.md
└── README.md
```

## 核心机制

- **避障学习**：`.paseo/learnings.jsonl` — 所有技能启动时读取，容量上限 30 条
- **自主判定**：Agent 自动选择 quick/full 模式和 auto-advance/gate 网关
- **轻量快速模式**：quick 仍创建最小主计划，并通过 bounded `upaseo-loop` 实现
- **入口分层**：`/using-upaseo` 负责完整开发生命周期，`upaseo` 只提供底层 Agent/Worktree/CLI 参考
- **发布分层**：`/using-upaseo` 负责创建 PR；PR 合并后由 `/upaseo-ship` 做发布校验和收尾
- **日志优先验证**：验证以运行时日志为第一证据
- **Gemini UI 专属**：UI/Styling 任务强制使用 Gemini 模型

## 验证

```bash
bash scripts/validate.sh
```

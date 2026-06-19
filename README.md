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
| `upaseo-init` | 项目初始化：自动构建 `.paseo/` 运行态目录、`.agents/story/` 资产库和 `AGENTS.md` 引用，并逆向扫描提炼六大资产 | `/upaseo-init` |
| `upaseo-goal` | Goal 合成器：结合项目上下文和用户确认，把粗略描述整理成简洁、边界清楚、可验证的 goal，并落盘到 `.paseo/goals/` | `/upaseo-goal <rough request>` |
| `upaseo-e2e` | 集成测试与 e2e 验证：先冻结环境和写用例，人工确认一次后再逐条执行，失败先复现并用 `gh` / `.github/issues` 上报 | `/upaseo-e2e <target or flow>` |
| `upaseo-ship` | PR 合并后的发布收尾：主干校验、资产固化、CHANGELOG、release metadata commit 与工作区清理 | `/upaseo-ship` |
| `upaseo-advisor` | 单 Agent 二次意见 | `/upaseo-advisor <question>` |
| `upaseo-committee` | 双 Agent 根因分析 | `/upaseo-committee <problem>` |
| `upaseo-handoff` | 任务完整移交 | `/upaseo-handoff <task>` |
| `upaseo-compact` | 上下文压缩与恢复提示词 | `/upaseo-compact <optional focus>` |
| `upaseo-todo` | 项目待办记录与状态更新 | 用户提到 todo / 待办 / backlog 时自动使用，或 `/upaseo-todo <todo>` |

## 安装

```bash
# 切换到项目根目录
cd /Users/zcg/workroot/paseo-improved

# 1. 软链接到本地 Agent 运行环境
for skill in upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-compact upaseo-e2e upaseo-goal upaseo-handoff upaseo-init upaseo-loop upaseo-reviewer upaseo-ship upaseo-simplify upaseo-todo using-upaseo; do
  ln -sf "$(pwd)/$skill" ~/.agents/skills/$skill
done

# 2. 软链接到 Antigravity 全局配置环境，以便在 / 中进行调用
for skill in upaseo upaseo-advisor upaseo-brainstorm upaseo-committee upaseo-compact upaseo-e2e upaseo-goal upaseo-handoff upaseo-init upaseo-loop upaseo-reviewer upaseo-ship upaseo-simplify upaseo-todo using-upaseo; do
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

# 把粗略描述整理为 goal，并单独落盘
/upaseo-goal 想修一下登录页移动端体验

# 先冻结环境、写完整测试矩阵，再逐条执行 e2e
/upaseo-e2e 验证 CLI 登录、授权、发布主链路

# 直接从任务启动，或读取已有 goal 再产出 plan
/using-upaseo .paseo/goals/login-mobile.md

# 压缩当前上下文并生成恢复提示词
/upaseo-compact 当前技能开发现场

# 记录项目待办
/upaseo-todo ship 时自动关闭本次发布已完成的 todo
```

## 目录结构

```
paseo-improved/
├── .github/
│   └── issues/                     # e2e 失败时的本地 issue 降级记录
├── .gitignore
├── AGENTS.md                       # 编程 Agent 根指引，引用 .agents/story 资产
├── .agents/
│   └── story/                      # 用户故事、数据模型、API、模块、架构约束、编码规范资产
│       ├── stories.md
│       ├── data_models.md
│       ├── apis.md
│       ├── modules.md
│       ├── architecture_constraints.md
│       └── coding_standards.md
├── .paseo/                         # 运行时数据（learnings 不入库）
│   ├── learnings.jsonl             # 避障学习记录
│   ├── compacts/                   # 上下文压缩与恢复文档
│   ├── todos.md                    # 项目待办 Source of Truth
│   ├── goals/                      # 目标文件 (Source of Truth for goals)
│   │   └── <slug>.md
│   ├── plans/                      # 计划文件 (Source of Truth for plans)
│   │   ├── <slug>.md
│   │   └── <slug>/
│   │       └── iter_N_design_tasks.md
├── requirement.md                  # 需求文档
├── .codex/
│   ├── hooks.json                  # 项目级 Codex hooks（PreCompact / PostCompact）
│   └── hooks/
│       ├── pre-compact.mjs
│       └── post-compact.mjs
├── scripts/
│   └── validate.sh                 # 自动化一致性验证
├── upaseo/                         # 基座技能
├── upaseo-advisor/
├── upaseo-brainstorm/
├── upaseo-committee/
├── upaseo-compact/                 # 上下文压缩与恢复提示词技能
├── upaseo-e2e/                     # 集成测试/e2e：环境冻结、case-first、逐条执行、issue 上报
├── upaseo-goal/                    # Goal 合成器：先确认，再落盘到 .paseo/goals/
├── upaseo-handoff/
├── upaseo-init/                    # 项目初始化与逆向整理技能
├── upaseo-loop/
├── upaseo-reviewer/
├── upaseo-ship/                    # 自动化发布与清理技能
├── upaseo-simplify/
├── upaseo-todo/                    # 项目待办记录与状态更新技能
├── using-upaseo/                    # 核心编排入口
│   ├── SKILL.md
│   └── references/
│       └── roles.md
└── README.md
```

## 核心机制

- **避障学习**：`.paseo/learnings.jsonl` — 所有技能启动时读取，容量上限 30 条
- **目标与计划分离**：`.paseo/goals/` 只存目标文档；goal 应简洁、边界清楚、定义好验证方法。`.paseo/plans/` 只存执行计划；`upaseo-goal` 是可选前置，`using-upaseo` 读取 goal 后再单独产出 plan
- **项目待办**：`.paseo/todos.md` — 用户提到 todo/待办/backlog 时由 `/upaseo-todo` 记录，`/upaseo-ship` 只关闭有发布证据的完成项
- **集成测试闭环**：`/upaseo-e2e` 先冻结测试环境并写测试矩阵，先经过一次人工确认，再逐条执行用例；若发现缺陷，必须先复现，再优先通过 `gh issue create` 上报，失败时降级写入 `.github/issues/`
- **资产根指引**：`AGENTS.md` — 项目根入口，引用 `.agents/story/` 六大资产，方便任意编程 Agent 接入上下文
- **历史资产库**：`.agents/story/` — 用户故事、数据模型、API、模块拓扑、架构约束和编码规范的长期 Source of Truth
- **上下文压缩**：`/upaseo-compact` 会先检查并自愈当前仓库的 compact hooks，再创建 `.paseo/compacts/` 恢复文档并输出恢复提示词，替代系统 compact 的低保真摘要
- **安全自动 compact**：仓库内 `.codex/hooks.json` 只在当前 repo 启用 `PreCompact` / `PostCompact`，自动保存现场并在 compact 后提示恢复，不修改全局 Codex 行为
- **自主判定**：Agent 自动选择 micro/quick/full 模式和 auto-advance/gate 网关
- **微改快速通道**：确定性文案、注释、文档、格式、无行为影响样式或机械修正可跳过 TDD/loop，只做最小确定性验证
- **轻量快速模式**：quick 仍创建最小主计划，并通过 bounded `upaseo-loop` 实现有行为风险的小改动
- **入口分层**：`/using-upaseo` 负责完整开发生命周期，`upaseo` 只提供底层 Agent/Worktree/CLI 参考
- **Worktree 会话隔离**：`/using-upaseo --worktree` 创建隔离 worktree 后，必须通过 `/upaseo-handoff --worktree` 在新 worktree cwd 下重建接收会话；计划、实现、验证、提交都以新 worktree 为准
- **发布分层**：`/using-upaseo` 负责创建 PR；PR 合并后由 `/upaseo-ship` 做发布校验和收尾
- **日志优先验证**：验证以运行时日志为第一证据
- **UI 走 preferences**：UI/Styling 任务的 provider 从 `orchestration-preferences.json` 的 `ui` 分类解析，未配置时默认 Gemini 系列，可在 preferences 中覆盖

## 验证

```bash
bash scripts/validate.sh
```

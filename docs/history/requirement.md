# upaseo 开发工作流需求文档（已归档）

> **[Archived in Iter 5 — 2026-06-19]** 本文件为 2026-05-20 会话中提出的原始需求，作为历史归档保留在 `docs/history/`。当前权威的工作流规范分散在 `using-upaseo/SKILL.md`（开发入口编排）、`upaseo/SKILL.md`（基座与 SoT 链、宿主兼容、偏好）、`.agents/story/`（六大长期资产）和 `scripts/validate.sh`（一致性校验）中。新增/变更需求请直接更新上述权威文件，不要再回写本归档文件。
>
> 来源：用户在 2026-05-20 会话中按时序提出的全部需求，经 Agentic 执行视角审查后完善。

---

## 一、基础目标

基于 paseo 技能工作流，复制并创建一套完全属于自己的开发工作流。

- **零外部技能依赖**：所有引用的外部技能（brainstorming、code-simplify、code-reviewer 等）的核心逻辑必须内化到本地 SKILL.md 中。不允许运行时依赖外部 GitHub 仓库的技能文件。
- **paseo CLI 是运行时基座**：`paseo` 命令行工具（`paseo loop run` 等）属于底层运行时基础设施，不属于"外部技能依赖"范畴，允许依赖。
- paseo 系列技能全部复制过来，允许拆分为多个独立技能，必须 **Rebrand 改名**（统一前缀 `upaseo-`）。
- 通过 `ln -s` 软链接部署到 `~/.agents/skills/`，供所有 Agent 全局使用。
- **入口职责分层**：`/using-upaseo <task>` 是唯一完整开发生命周期入口；`upaseo` 只作为底层 Agent、Worktree、CLI、Provider 偏好和 daemon 调试参考，不承载计划、迭代、验收、发布等业务编排。

---

## 二、流程改进要求

### 2.1 验证策略：优先日志验证

- 测试和功能验证时，**优先通过日志验证**（应用运行日志、Debug 日志、关键事件 Trace）。
- 自动化测试作为辅助手段，日志是第一证据。

### 2.2 计划与设计阶段

- 制定计划和设计时，必须遵循以下设计理念（已内化至 `upaseo-brainstorm` 技能）：
  - **极简主义**（源自 karpathy-guidelines）：最少代码、最少抽象、手术刀式修改。
  - **简单优先**（源自 simple）：能用简单方案解决的绝不过度设计。
  - **脑暴收敛**（源自 brainstorming）：2 种方案 + Trade-offs，3 个多选题以内收敛意图。
- 每个迭代在实现前必须进行**迭代计划评审会**：架构设计、功能设计、验收测试三个视角围绕同一份 `iter_N_design_tasks.md` 做 1-2 轮博弈和反馈，先修正功能边界与验收标准，再允许派实现子 Agent。

### 2.3 任务复杂度自主判定

并非所有任务都需要完整仪式，也并非所有安全、确定性的微小修改都需要 TDD 红绿灯和 `upaseo-loop`。**Agent 必须在 Step 0.1 之后自主评估任务复杂度与风险等级**，自动选择执行模式。用户可通过 `--quick` 或 `--full` 参数强制覆盖 quick/full 判定；若用户明确要求 TDD、loop 或完整仪式，则不得走微改快速通道。

**自动判定规则：**

当任务满足以下**全部**条件时，自动进入**微改快速通道**：
- 预估改动范围 ≤ 2 个文件，且改动可以通过人工 diff 审查完整理解
- 只涉及文案、注释、文档、格式、无行为影响的样式微调，或机械性重命名/拼写修正
- 不改变运行时逻辑、控制流、数据结构、公共 API、权限、安全、计费、并发、持久化、构建/部署流程或测试语义
- Agent 对预期结果有确定性，且无需新增测试才能证明行为正确

微改快速通道允许跳过新增失败测试、跳过 `upaseo-loop`、跳过最小主计划和迭代设计文档，但必须在执行前给出一句 `Micro-Change Decision`，说明为什么风险足够低；执行后必须做最小确定性验证（如 diff 审查、格式/文档校验、现有窄域检查）。一旦发现实际改动超出上述边界，必须立即升级到快速模式或完整仪式模式。

当任务不满足微改快速通道，但满足以下**全部**条件时，自动进入快速模式：
- 预估改动范围 ≤ 3 个文件
- 不涉及架构调整或新增模块
- 任务意图明确、无需与用户收敛设计方向（如 Bug 修复、样式微调、配置变更、文案修改）

其余情况进入完整仪式模式。

| 模式 | 触发方式 | 流程 |
|:---|:---|:---|
| 微改快速通道 | Agent 风险判定 / 非 `--full` / 用户未要求 TDD | Micro-Change Decision → 直接手术刀式修改 → 最小确定性验证 → 简短交付 |
| 完整仪式 | 自动判定 / `--full` 强制 | 脑暴 → 迭代拆分 → 每迭代计划评审会 → Loop 实现 → 用户 Gate → 自审 → PR |
| 快速模式 | 自动判定 / `--quick` 强制 | 跳过脑暴，最小主计划 → 单迭代计划评审会 → 轻量 Loop 实现 → 日志验证 → 用户确认 → 提交 |

Agent 选择模式后，必须在执行前向用户简要说明判定理由（一句话），用户可随时纠正。无法确定风险等级时，必须保守升级，不得走微改快速通道。

### 2.4 增量迭代推进

- 计划逻辑必须是**增量迭代**的，不能一次性全量推进。
- 每个迭代必须有**独立的设计与任务文档** (`iter_N_design_tasks.md`)。因为在极简工作流中，**设计与开发任务是合二为一、融为一体的**。该文档必须包含：
  - 迭代目标
  - 极简技术方案
  - **验证计划**：必须明确写清验证方式——`logs`（日志）、`browser`（浏览器）、`manual`/`agent-run`（操作电脑/脚本）
  - 用户可执行的手动验证步骤
- **自适应评审会分级**（轻重自适应以降低流程阻力）：
  - **低风险任务**（仅涉及局部文件修改、简单样式微调或文案配置变动）：跳过多角色辩论，由 Orchestrator 直接进行一份**自检清单（Mini Checklist）**核对即可定稿，避免流程过载。
  - **高风险任务**（涉及数据库 Schema 变更、新增公共 API 路由或核心公共依赖重塑）：强制组织 `architecture-designer`、`feature-designer` 与 `test-strategist` 开展 1-2 轮评审会，定稿时追加 **Design Council Log** 记录角色意见与修正结论。
- 每个迭代除了 Agent 自行验证以外，**必须给用户提供明确的验证内容和方法**。
- 快速模式也必须创建最小主计划 `.paseo/plans/<slug>.md`，并通过轻量 `upaseo-loop` 实现。只有满足 2.3 的微改快速通道条件时，才允许直接修改并跳过 loop。
- **用户验证通过后才能开始下一个迭代**，否则留在当前迭代修复。

### 2.5 用户验证网关与自主推进判定

**Agent 根据验证结果的确定性自主决定是否需要等待用户确认。** 用户可通过 `--autopilot` 强制自动推进，或通过 `--gate` 强制每迭代等待。

**自动判定规则：**

当迭代验证满足以下**全部**条件时，Agent 可自动推进到下一迭代，无需等待用户：
- 验证方式为 `logs` 或 `agent-run`（Agent 可自行完成的客观验证）
- 日志证据完整，关键事件 Trace 全部匹配预期
- 自动化测试全部通过（若有）
- 本迭代无架构性决策变更

当迭代验证包含以下任一条件时，**必须等待用户确认**：
- 验证方式包含 `browser` 或 `manual`（需要人眼判断的场景）
- 涉及 UI/UX 视觉变更
- 迭代中做出了设计文档之外的架构性决策
- Agent 对验证结果存在不确定性

**共同约束：**
- 自动推进时必须在主计划文件中记录 `[auto-advanced]` 标记及验证证据摘要，便于用户事后审查。
- **最终 PR 阶段仍然必须等待用户审批**，不可自动合并。
- 用户可随时在对话中要求回溯查看任何被自动推进的迭代。

### 2.6 实现阶段约束

- 除微改快速通道外，实现阶段**必须使用 upaseo-loop 驱动**，以实现-测试-纠错的闭环。
- TDD 红绿灯用于有行为风险、验收不确定或需要锁定回归的改动；微改快速通道不得为了“走流程”新增低价值测试。
- **UI 设计只能由 Gemini 模型执行**，不可使用其他 Provider。无 Gemini 可用时，暂停并通知用户，不得降级到其他模型。

### 2.7 PR 提交策略与智能兜底

支持两种 PR 策略：

| 策略 | 参数 | 行为 |
|:---|:---|:---|
| 统一 PR（默认） | 无参数 | 所有迭代完成后统一提一个 PR |
| 逐迭代 PR | `--pr-per-iteration` | 每个迭代验证通过后单独提 PR |

提交 PR 前必须先执行：
- **代码极致精简**（`upaseo-simplify`）
- **代码质量自审**（`upaseo-reviewer`）

**PR 智能兜底机制 (PR Fallback)**：
在执行 PR 创建交付时，如果本地环境未安装 `gh` 命令行工具、网络超时或未对 GitHub 授权，系统绝不允许报错崩溃挂起。此时必须**智能、温和地降级为 `Git Local Stage & Commit`（本地整洁提交）模式**。在当前分支或主干创建规范 commit 记录后，由 Agent 向用户清晰引导：“*本地 gh CLI 缺失或未授权，已为您在本地完成整洁提交，请您手动执行推送与 PR 合并。*”

**分支与 Worktree 高追溯性命名**：
在 Step 2 启用 `--worktree` 或 Step 5.F 自动/手动推进创建 checkpoint commit 时，系统必须使用极简、高辨识度的拼音/英文命名规范（如 `upaseo-feat-<task_slug>` 格式），物理工作区也必须规范地在平级目录下隔离（如 `../paseo-improved_upaseo-feat-<task_slug>`），绝不在临时路径堆积垃圾。

### 2.8 回滚机制

当迭代 N 的改动破坏了迭代 N-1 已验证通过的功能时：
1. 优先在当前迭代内修复回归问题。
2. 每个迭代验证通过后必须创建 checkpoint commit，并在主计划 Progress Notes 中记录 commit hash。
3. 若修复失败（超过 loop 最大迭代次数），执行 `git revert` 回退到上一已验证迭代的 checkpoint commit；若 checkpoint 缺失，暂停并向用户说明不能安全自动回滚。
4. 将回退事件记录到主计划文件（标记 `[!] 迭代 N: reverted`），并重新设计当前迭代方案。

---

## 三、上下文管理与状态同步

### 3.1 计划文件统一归属与文件即上下文 (File-as-Context) 理念

- **Source of Truth 唯一且明确**：主计划文件统一存放在项目根目录 `.paseo/plans/<slug>.md`。
- 对话级 artifact（如 `implementation_plan.md`）仅作为起草工具，一旦用户确认即写入项目目录。
- 所有状态同步操作（标记 `[x]`/`[!]`、追加 Notes）均以项目目录中的文件为准。
- **文件即上下文 (File-as-Context) 极简理念**：负责调度的 Agent（Orchestrator）在整个开发生命周期中，必须始终保持自身长 context 的轻量级，**不得在 memory 中堆积每一步的代码更改、调试历史和繁冗逻辑**。Orchestrator 的当前状态（State）、决策点、下一跳动作、验证日志摘要必须**实时、同步、幂等地持久化在物理计划文件及当期迭代设计文档中**，真正践行“以物理文件为最权威上下文”的设计哲学。

### 3.2 `.paseo/` 目录自动初始化

Orchestrator 在 Step 0.1 自动检查并创建所需目录结构：
```
<项目根目录>/
  AGENTS.md                # 编程 Agent 根指引，必须引用 .agents/story 资产
  .agents/
    story/                 # 开发故事与历史资产目录 (Architecture & Asset Map)
      stories.md           # 用户故事与功能用例资产 [NEW]
      data_models.md       # 数据结构与表结构资产
      apis.md              # 核心 API 与接口资产
      modules.md           # 包、模块职责与页面路由拓扑资产
      architecture_constraints.md  # 架构约束、依赖边界与运行时约束资产
      coding_standards.md          # 编码规范、工程约定与验证命令资产
  .paseo/
    learnings.jsonl        # 避障学习记录
    todos.md               # 项目待办记录
    plans/
      <slug>.md            # 主计划文件
      <slug>/
        iter_1_design_tasks.md   # 迭代设计与任务文档
        iter_2_design_tasks.md
        ...
```
使用 `mkdir -p` 确保幂等创建，已存在时不报错。若 story 下资产文件不存在，从模板自愈初始化。

### 3.3 基于文件的上下文传递

- 创建子 Agent 时，**必须在 initialPrompt 中传递文件绝对路径**：
  - 主计划文件绝对路径
  - 当前迭代设计与任务文档绝对路径
  - 避障学习记录路径（`.paseo/learnings.jsonl`）
  - **核心开发资产文档路径**：`.agents/story/` 下关联资产文档的绝对路径（如 `stories.md`、`data_models.md`、`architecture_constraints.md`、`coding_standards.md` 等）
- **精简传递策略**：Orchestrator 在 initialPrompt 中内联传递**关键摘要**（迭代目标 + 验证标准，不超过 5 行），同时附带文件绝对路径供子 Agent 读取。迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md` 是所有实现类子 Agent 的强制启动上下文。
- 子 Agent 启动后**必须先读取迭代设计与任务文档、架构约束资产和编码规范资产**，并根据其改动范围，继续读取关联的历史开发资产文档。
- **合规检查**：在 verifier prompt 中增加一条检查——确认 worker 的早期 tool call 中包含 `view_file` 读取设计与任务文档、`architecture_constraints.md` 和 `coding_standards.md`，若任一缺失则判定为不合规。

### 3.4 开发故事与历史资产目录机制 (Asset Map & Story Closed-Loop)

为了在漫长且多迭代的开发中保持项目架构、接口、数据模型以及功能用例的一致性，彻底避免“重复造轮子”和旧组件架构腐化，Orchestrator 必须强制执行以下历史资产的闭环管控机制：

1. **模板自愈初始化**：在 Step 0 偏好设置检查与目录初始化中，自动创建 `<项目根目录>/.agents/story/` 目录。若对应的 `stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md`、`coding_standards.md` 文件不存在，自动使用 `using-upaseo/references/` 下的模板文件进行复制和自愈。同时创建或修复根 `AGENTS.md` 中的 upaseo 资产引用段落，确保其他编程 Agent 能从根指引发现 `.agents/story/`。
2. **前置强注入 (Asset Injection)**：
   - 在 Step 5.B 派生子 Agent 驱动实现时，主 Agent 在 `initialPrompt` 中**必须以绝对路径形式注入 `.agents/story/` 下关联资产文件的地址**。
   - 强约束：子 Agent 必须将“**读取迭代设计文档、架构约束资产和编码规范资产**”作为启动后第一规程动作；随后再根据改动范围读取关联业务资产（若涉及功能故事修改读取 `stories.md`；若本次迭代包含 API 修改读取 `apis.md`；若涉及数据结构修改读取 `data_models.md`；若涉及包结构或页面路由读取 `modules.md`，以此类推）。
3. **完工后自动刷新与资产防事实漂移校验 (Auto-refresh & Diff-Asset Validation)**：
   - 在 Step 5.C 子 Agent 完工通知与状态同步阶段，Orchestrator 先记录“实现完成，等待验证”；只有验证和必要用户网关通过后，才将主计划状态勾选为 `[x]`，并紧接着执行一个资产审查与刷新步骤。
   - 主 Agent（或派生的 `story-updater` 角色）分析子 Agent 本轮迭代的所有变更（代码 diff 和受影响文件）。
   - **资产防事实漂移校验 (Diff-Asset Validation)**：在写入资产前，主 Agent 必须审查 `git diff` 是否确实实现了 `iter_N_design_tasks.md` 中规划的业务逻辑。**严禁在无代码实现支撑的情况下，直接将纸面设计的空头承诺写入核心历史资产**，确保资产是代码的 100% 真实客观投射。
   - 若校验通过，发现本轮迭代新增或修改了前后台用户功能点用例、数据库表结构、核心类/服务接口、公共 API 路由、新的子包或前端展示页面，**必须第一时间使用代码替换工具，增量更新 `.agents/story/` 下对应的 `.md` 文档**。
   - 所有的增量资产更新描述中，必须以标准格式标注改动的迭代代号，例如 `* [Updated in Iter 2] 新增 /api/v1/auth 登录接口`，确保该历史资产库成为整个项目最新、最准确的架构与资产蓝图（Source of Truth）。

### 3.5 子 Agent 完工通知与状态同步

- 子 Agent 完成任务后必须通知主 Agent。
- 主 Agent 收到通知后，**第一时间更新主计划文件的执行记录**：成功实现先追加“等待验证”的 Progress Notes，不得提前标记 `[x]`；阻塞或不可验证才标记 `[!]`。只有验证和必要用户网关通过后才能标记 `[x]`。
- 严禁跳过状态同步直接推进下一阶段。
- **Auditor 报告格式**：不强制 JSON 格式。Auditor 用自然语言报告即可，但必须包含：验证结论（pass/fail）、关键日志片段、阻塞问题（若有）。Orchestrator 从语义中提取状态。

### 3.6 手动发布与收尾交付阶段 (The Ship Phase - /upaseo-ship)

为了闭合软件研发生命周期的最终交付环，在开发迭代全部完成、提交 PR 且 PR 已合并到主干之后，系统支持由**用户手动敲入 `/upaseo-ship` 触发发布和环境清理工作**。此指令不在开发流中由 Agent 自动运行，而是作为用户受控的交付指令。其包含以下核心规程：

1. **发布前置校验**：
   - 检查主计划状态。只有当所有迭代都已标记为已完成 `[x]`，且本地 Git 状态同步无未提交修改时，方可进行。
   - 终极构建阻断：优先读取 `.agents/story/coding_standards.md` 中记录的构建、Lint、类型检查和测试命令；若资产中没有定义，再执行项目惯例命令（如 `npm run build` 和 `npm run test`）。如果出现编译报错或测试失败，立即阻断发布。
2. **开发资产版本固化与 CHANGELOG 追加**：
   - 扫描 `.agents/story/` 下的 `stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md`、`coding_standards.md` 六个历史资产文件。
   - 将这些文件中的所有 `* [Updated in Iter N]` 备注替换为正式发布标记（若指定了 `--version`，替换为 `* [Released in vX.Y.Z]`，否则默认使用本地日期 `* [Shipped on YYYY-MM-DD]`）。
   - 将主计划的 `Progress Notes` 提炼为大纲，追加至项目根目录 `CHANGELOG.md` 顶部。
   - 若产生 `.agents/story/*` 或 `CHANGELOG.md` 修改，必须创建独立 release metadata commit，保证发布资产变更可追溯。
3. **物理环境与分支安全清理**：
   - 不在 ship 阶段发起 feature 分支合并；只确认 PR 已经合并到主干，且主干包含发布目标提交。
   - 清理 worktree：如果本次开发使用了 `git worktree` 且未指定 `--keep-worktree`，自动运行 `git worktree remove` 安全回收磁盘物理空间。
   - 安全删除本地已合入的临时 feature 开发分支（`git branch -d`），保持本地 `git branch` 清爽。
4. **避障学习全局共享**：
   - 将本项目本地 `.paseo/learnings.jsonl` 中的所有独特避障规则增量导入并合并至全局 `~/.paseo/global-learnings.jsonl`。
   - 遵循完全去重过滤和上限 30 条的高密度原则，多项目共享血泪教训。

### 3.7 项目初始化与逆向整理阶段 (The Init Phase - /upaseo-init)

当现有（或全新）项目需要接入 `upaseo` 开发故事与资产闭环工作流时，支持由**用户手动敲入 `/upaseo-init` 触发项目资产的初始化与逆向整理**。该指令不属于常规迭代内流，而是作为系统准入性指令。其包含以下核心规程：

1. **幂等目录自愈初始化**：一键创建 `.agents/story/` 等目录，在模板缺失时自动自愈装载六大资产空模板，并创建或修复根 `AGENTS.md` 中的资产引用说明。
2. **已有代码库逆向扫描**：在**绝对只读安全红线**下分析 codebase，检测项目技术栈及主要代码路由目录。
3. **六大历史资产整理与 Legacy 转换**：将扫描提炼出的系统已实现用例、数据模型、API 接口、模块拓扑、架构约束和编码规范分别注入 `stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`。为明确表示是遗留成熟功能，所有条目以 `* [Legacy Asset]` 或 `* [Released in v0.0.0]` 前缀开头。
4. **资产地图报告打印**：向用户展示高密度资产统计报告，明确确立 Source of Truth。

### 3.8 异常恢复与断电秒级自愈机制 (Resumability & Self-healing)

为了应对服务器重启、Token 耗尽或由于网络中断导致的意外重启，工作流必须具备完备的**现场重建与秒级恢复能力**：
- **唯一凭证自愈**：所有的断电恢复不依赖任何内存缓存或对话历史，只通过物理计划文件 `.paseo/plans/<slug>.md` 以及当前迭代的 `iter_<N>_design_tasks.md` 进行现场重建。
- **启动首步必读**：当 Orchestrator 在中断后被重新唤醒时，**第一步且必须**通过 `view_file` 工具读取上述两个文件。
- **无感现场复原**：读取文件后，Orchestrator 能够根据文件中登记的 `State` 状态，无缝识别出系统之前所处的精准阶段（如：迭代草案设计、进行中实现、日志验证中、或等待用户网关中），自动还原先前的操作，无需用户提供冗余前置背景解释，实现真正的秒级自愈。


---

## 四、会话总结与避障学习

### 4.1 会话错误记录

- 把会话过程中的**错误判断、指令错误**记录到项目的 `.paseo/learnings.jsonl`。
- 内容必须**精练**，只保留对未来有避障指导价值的结论性规则。

### 4.2 强制前置读取

- **每次任务启动时**（`using-upaseo` 的 Step 0.1）必须先读取 `.paseo/learnings.jsonl`。
- **upaseo-loop 启动时**也必须先读取该文件，并将避障规则注入 worker prompt。
- 读取后提炼的规则作为本次会话的全局硬约束。

### 4.3 容量控制与去重

- **上限 30 条**：超过 30 条时，Agent 必须精炼合并最旧的条目（将相似教训合并为一条），保持总量 ≤ 30。
- **写入前去重**：写入新条目前，检查 `mitigation` 字段是否与已有条目语义重复，重复则跳过。
- 每条记录附带 `session_id`（对话 ID），便于溯源。

### 4.4 记录格式

```json
{"timestamp":"<ISO8601>","session_id":"<conversation-id>","category":"<command_error|wrong_assumption|tool_misuse|design_flaw>","failed_attempt":"<简述失败操作>","mitigation":"<应该怎么做>"}
```

### 4.5 并发安全

当前阶段不考虑多会话并发写入。单会话单项目为基本使用模式。`session_id` 字段为未来排查冲突预留。

---

## 五、参数速查表

以下参数用于**人工覆盖** Agent 的自主判定。不传参数时 Agent 自行决策。

| 参数 | 作用 | 默认行为（无参数时） |
|:---|:---|:---|
| `--quick` | 强制快速模式（跳过脑暴，单迭代） | Agent 根据任务复杂度自主判定 |
| `--full` | 强制完整仪式模式 | Agent 根据任务复杂度自主判定 |
| `--autopilot` | 强制所有迭代自动推进（最终 PR 仍需人工） | Agent 根据验证确定性自主判定 |
| `--gate` | 强制每个迭代都等待用户确认 | Agent 根据验证确定性自主判定 |
| `--worktree` | 使用 git worktree 隔离工作区 | 关闭 |
| `--pr-per-iteration` | 每迭代单独提 PR | 关闭（统一 PR） |

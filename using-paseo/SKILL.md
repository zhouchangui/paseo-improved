---
name: using-paseo
description: >-
  核心开发工作流编排技能。运行重度开发任务的生命周期管理，内置自主复杂度判定、
  增量式迭代推进、独立迭代设计文档、自主推进/用户验证网关、实现阶段强制
  upaseo-loop、UI 强制 Gemini、优先日志验证、PR 提交前强制自审简化、
  会话复盘与避障学习落盘。
user-invocable: true
argument-hint: "[--quick|--full] [--autopilot|--gate] [--worktree] [--pr-per-iteration] <task>"
---

# Using Paseo (核心开发工作流技能)

本技能为唯一的完整开发工作流入口。它将一项任务在完全本地化的 `upaseo` 基座上驱动，严格通过：**避障前置 → 自主复杂度判定 → 脑暴前置（完整模式） → 增量迭代拆分 → 单迭代设计草案 → 迭代计划评审会 → 自主推进/用户网关 → 强制 Loop 实现 → 强制 Gemini UI → 优先日志验证 → 提交PR前强制自审与简化 → 会话复盘学习落盘**的闭环推进。

**User's request:** $ARGUMENTS

---

## 预备知识与依赖
1. 深入阅读全局 `upaseo` 基座参考以了解 Worktree、Agent、CLI 与 Provider 偏好等底层控制逻辑。`upaseo` 只提供低层能力，不承载完整开发流程。
2. 角色职责规范定义在 `references/roles.md`。
3. 快速模式完整流程参见 `references/quick-mode.md`。
4. 参数速查与自主判定规则参见 `references/params.md`。

---

## 执行流程图

```
Step 0: 偏好读取 + .paseo/ 目录初始化
Step 0.1: 前置读取 .paseo/learnings.jsonl (避障)
Step 0.2: 自主判定执行模式 (quick / full)
  │
  ├── [quick 模式] ──> 最小主计划 → 单迭代计划评审会 → 轻量 Loop 实现 → 验证 → 提交
  │
  └── [full 模式]
        │
        ▼
      [Worktree] ──> Research ──> upaseo-brainstorm ──> 迭代分解规划
                                                                │
       ┌──────────────────── 下一个迭代 ────────────────────────┘
       │
       ▼
      创建迭代设计草案 (iter_N_design_tasks.md)
       │
       ▼
      迭代计划评审会 (架构/功能/测试 1-2 轮博弈修正)
       │
       ▼
      派生子 Agent (内联摘要 + 绝对路径) ──> upaseo-loop 实现
       │
       ▼
      子 Agent 完工 ──> 主 Agent 同步更新主计划状态
       │
       ▼
      日志验证 ──> 自主判定是否需要用户确认
       │
       ├── [auto-advance] ──> 记录证据 ──> 下一迭代
       └── [wait-gate] ──> 等待用户确认 ──> 下一迭代
                                                │
       ┌────────────────────────────────────────┘
       ▼
      自审与简化 ──> 提交 PR ──> 会话复盘 ──> 归档
```

---

## 详细阶段规程

### 0. 偏好设置检查与目录初始化 (Pre-start)

1. 读取 `~/.paseo/orchestration-preferences.json` 以获取底层 Agent 的 Provider 分发。
2. **UI 设计 Gemini 专属约束**：涉及 `ui` 或 `ui-impl` 阶段时，Provider **强制限定为 `gemini` 系列模型**。无 Gemini 可用时，暂停并通知用户，不得降级。
3. **自动初始化 `.paseo/` 目录与历史资产库自愈**：
   - 运行 `mkdir -p <项目根目录>/.paseo/plans` 与 `mkdir -p <项目根目录>/.paseo/story` 确保目录结构存在。
   - 历史资产库自愈：检查 `.paseo/story/` 目录下是否存在 `stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`。若有任何文件缺失，自动将 `using-paseo/references/` 下对应的模板文件（例如 `stories_template.md` 等）拷贝/写入生成至该目录下，确保架构基础资产库健全。如果当前项目是遗留或老项目，**推荐手动触发运行 `/upaseo-init` 技能**来进行代码的深度扫描和资产的逆向初始化整理。
4. **Paseo 命令行自动检测与初始化安装**：
   - 检查当前系统 `PATH` 中是否能成功执行 `paseo`（通过 `which paseo` 或运行 `paseo --version`）。
   - 若未在 `PATH` 中找到：
     - 主动在默认桌面端安装路径下搜寻内置 CLI 可执行文件：
       - **macOS**: `/Applications/Paseo.app/Contents/Resources/bin/paseo`
       - **Linux**: `/opt/Paseo/resources/bin/paseo`
       - **Windows**: `C:\Program Files\Paseo\resources\bin\paseo.cmd`
     - 若成功搜寻到内置 CLI：
       - 检测本地用户执行目录 `~/.local/bin` 是否存在；若不存在，可提示用户运行 `mkdir -p ~/.local/bin`。
       - **不得静默创建软链接**。必须向用户展示建议命令，由用户确认后再在 `~/.local/bin/paseo` 创建软链接指向内置 CLI 物理路径（Windows 下为对应的 `.cmd` 启动脚本/Trampoline）。
       - 检查 `~/.local/bin` 是否已在当前 `PATH` 环境变量中。若不在，可在本次会话运行时临时 `export PATH="$HOME/.local/bin:$PATH"`，并提示用户将该 export 追加到 shell 配置（如 `~/.zshrc` 或 `~/.bashrc`）。
     - 若最终无法找到任何内置或全局 CLI，打印醒目警告提示用户先去下载并安装 Paseo 桌面端客户端。

### 0.1 全局会话避障前置读取 (Hard Mitigation Precheck) ⚠️ 硬性规定

**本步骤为整个工作流的第零优先级动作，在任何其他步骤之前必须无条件执行。**

1. 检查当前项目根目录下是否存在 `.paseo/learnings.jsonl` 文件。
2. 若文件存在，**必须立即使用 `view_file` 工具完整读取**。
3. 逐行解析其中的 JSON Lines 记录，提炼出所有历史避障规则。
4. 将提炼出的规则作为**本会话全局硬约束**，在后续所有阶段的决策和指令中绝对遵守，不得违反。
5. 若文件不存在，跳过本步骤，继续正常流程。

> **示例**：若 `learnings.jsonl` 中有一条 `{"category": "command_error", "mitigation": "docker compose 必须指定 -p dingding"}`，则本会话中所有涉及 `docker compose` 的命令都必须自动附加 `-p dingding`。

### 0.2 自主复杂度判定 (Complexity Auto-Assessment)

**Agent 必须在此步骤自主评估任务复杂度，自动选择执行模式。用户可通过 `--quick` / `--full` 参数强制覆盖。**

**自动判定规则：**

当任务满足以下**全部**条件时，自动进入**快速模式**：
- 预估改动范围 ≤ 3 个文件
- 不涉及架构调整或新增模块
- 任务意图明确、无需与用户收敛设计方向（如 Bug 修复、样式微调、配置变更、文案修改）

其余情况进入**完整仪式模式**。

| 模式 | 触发方式 | 流程 |
|:---|:---|:---|
| 完整仪式 | 自动判定 / `--full` 强制 | 脑暴 → 迭代拆分 → 每迭代计划评审会 → Loop 实现 → Gate/Auto → 自审 → PR |
| 快速模式 | 自动判定 / `--quick` 强制 | 跳过脑暴，最小主计划 → 单迭代计划评审会 → 轻量 Loop 实现 → 日志验证 → 用户确认 → 提交 |

**Agent 选择模式后，必须在执行前向用户简要说明判定理由（一句话），用户可随时纠正。**

> **快速模式详细流程**参见 `references/quick-mode.md`。**参数与判定规则完整定义**参见 `references/params.md`。

---

### 1. 自身调研与 Research
- 在开工前，先理解代码环境。对大改动或涉及多个 package 时，可启动 `researcher` 角色对特定范围进行只读分析，绝不写代码。
- 给出你对当前代码状况的 2-3 句话极简总结。

### 2. 准备工作区 (Worktree)
- 若带有 `--worktree` 选项，优先通过 `upaseo` 接口创建一个独立的 git worktree 工作区，避免弄脏主分支。

### 3. 头脑风暴前置 (upaseo-brainstorm) — 仅完整仪式模式
- 在制定整体技术计划前，**强制加载并运行本地的 `upaseo-brainstorm` 技能**。
- 明确提炼出最简架构设想（Simplicity First / Surgical Changes），提出 2 种带 Trade-offs 的方案，并在 3 个多选题以内打包发给用户收敛意图，取得方案的明确批复。
- **快速模式下跳过此步骤。**

### 4. 增量迭代计划制定 (Incremental Iteration Planning)
方案确定后，Orchestrator 必须将整个技术方案切分为数个紧凑的**增量迭代（Incremental Iterations）**。此时只允许形成路线图级别的迭代假设，具体功能设计和验收标准必须在每个迭代开始前通过“迭代计划评审会”定稿。
在 `.paseo/plans/<slug>.md` 写入整体路线图（Source of Truth），标记 Iterations：
```markdown
## 迭代路线图
- [ ] 迭代 1：[简短目标]
- [ ] 迭代 2：[简短目标]

## Progress Notes
(由 Orchestrator 在每个迭代完工后追加)
```

> **快速模式**下只有 1 个迭代，但仍必须创建最小主计划文件 `.paseo/plans/<slug>.md`，用于恢复、状态审计和 `/upaseo-ship` 发布前校验。

### 5. 迭代执行大循环 (The Iteration Loop)
针对路线图中未完成的每一个迭代（N），必须依次严密执行以下子流程：

#### A. 创建单迭代“设计与任务”草案
在 `.paseo/plans/<slug>/iter_<N>_design_tasks.md` 创建独立的设计与任务文档草案（在极简工作流中，技术设计与具体任务融为一体）。该文档必须包含以下段落：
1. **迭代目标 (Iteration Goal)**：清晰描述本轮增量迭代要达到的具体效果。
2. **极简技术方案 (Surgical Design)**：遵循极简主义设计，不留任何冗余接口。
3. **验证计划 (Verification Plan)**：
   - **必须写清楚具体验证方式**，三选一或组合：
     - `logs`（通过观察应用日志、调试日志、特定 key event 输出来验证）。
     - `browser`（通过浏览器页面及元素状态进行验证）。
     - `manual` 或 `agent-run`（通过操作电脑，运行特定脚本或查看终端输出验证）。
   - **用户手动验证具体步骤**：为用户编写一行明晰、无门槛的手动验证命令或操作步骤。

#### B. 迭代计划评审会（架构/功能/测试博弈，硬性规定）

在任何实现类子 Agent 启动前，Orchestrator 必须围绕本轮 `iter_<N>_design_tasks.md` 草案组织 1-2 轮计划评审会。评审会可以派生只读子 Agent，也可以由主 Agent 明确扮演以下角色，但必须在计划文件中记录各角色意见与修正结论：
1. **architecture-designer**：审查架构边界、模块归属、依赖方向、数据流和是否违反 `architecture_constraints.md`。
2. **feature-designer**：审查用户故事、功能边界、交互/业务行为、与既有 `stories.md` 和 `modules.md` 的一致性。
3. **test-strategist**：审查验收标准是否可执行、日志/测试/browser/manual 验证路径是否闭环、失败条件是否明确。

评审流程：
1. **Round 1**：三个角色分别基于迭代草案、`architecture_constraints.md`、`coding_standards.md` 以及相关业务资产提出阻塞问题、风险和具体修改建议。
2. **修正草案**：Orchestrator 将被采纳的意见写回 `iter_<N>_design_tasks.md`，至少补齐功能边界、架构决策、验收标准、测试证据和不做事项。
3. **Round 2（条件触发）**：若 Round 1 存在阻塞问题、验收不可执行、架构边界不清或角色意见冲突，必须再进行一轮复审；若仍无法收敛，暂停并向用户提交争议点。
4. **定稿门槛**：计划文件必须追加 `Design Council Log` 段落，记录每个角色的关键意见、采纳/拒绝理由、最终验收标准。没有该段落或存在未解决阻塞项时，严禁进入实现。

#### C. 强制使用 `upaseo-loop` 驱动实现（含精简上下文传递）

**派生子 Agent 的上下文传递规则（硬性规定）：**

Orchestrator 在 `initialPrompt` 中必须：
1. **内联关键摘要**（迭代目标 + 验证标准，不超过 5 行）。
2. **附带文件绝对路径**供子 Agent 按需深入查阅：

## 上下文摘要
- 迭代目标：<一句话目标>
- 验证方式：<logs|browser|manual>
- 验证标准：<具体通过条件>

## 必读文件（启动后第一步必须 view_file 读取以下文件）
- 迭代设计与任务文档：<iter_N_design_tasks.md 绝对路径>
- 架构约束资产：<项目根目录>/.paseo/story/architecture_constraints.md
- 编码规范资产：<项目根目录>/.paseo/story/coding_standards.md
- 主计划文件（按需）：<主计划文件绝对路径>
- 避障学习记录（按需）：<项目根目录>/.paseo/learnings.jsonl

## 关联历史开发资产（根据改动范围追加读取并绝对遵守）
- 用户故事资产：<项目根目录>/.paseo/story/stories.md
- 数据模型资产：<项目根目录>/.paseo/story/data_models.md
- 核心接口资产：<项目根目录>/.paseo/story/apis.md
- 包与模块资产：<项目根目录>/.paseo/story/modules.md

硬性读取顺序：先读取迭代设计文档，再读取 `architecture_constraints.md` 和 `coding_standards.md`，然后按本轮改动范围读取 `stories.md`、`data_models.md`、`apis.md` 或 `modules.md`。严禁跳过这些启动读取动作。严禁违反已有的核心历史开发资产、架构约束和编码规范进行重复造轮子、破坏性重构或风格漂移。

- 启动 **`upaseo-loop`** 技能，以**实现-测试-纠错**的闭环状态去驱动 `refactorer` 和 `impl` 角色开始写代码；快速模式也必须使用轻量 loop（建议 `max-iterations <= 3`），不得由 Agent 直接绕过 loop 自行修改。
- 如果这是 UI 或 Styling 改动，**强制要求 `upaseo-loop` 的 worker 只能使用 Gemini 模型**。
- TDD 模式推进：先写失败测试/日志埋点，再让它跑通。

#### D. 子 Agent 完工通知与主计划状态同步（硬性规定）

当子 Agent 完成阶段性任务并发出完工通知时，**主 Agent (Orchestrator) 必须执行以下同步规程，在完成之前不得执行任何后续动作**：

1. **读取子 Agent 交付产出**：查看子 Agent 的最终报告或直接 `view_file` 读取受影响的关键文件。
2. **立即记录实现完成状态**：在主计划文件的 `Progress Notes` 段落中追加“实现完成，等待验证”的核心说明；此时不得把路线图勾选为 `[x]`，因为 `[x]` 仅代表验证和必要用户网关都已经通过。
3. **受阻状态同步**：若子 Agent 报告 blocked 或实现结果不可验证，必须在 `.paseo/plans/<slug>.md` 中将当前迭代标记为 `[!]` 并留在本迭代修复。
4. **保存主计划文件后，方可进入后续流程**。
5. **记录待刷新资产范围**：主 Agent 初步分析本轮变更可能影响的故事、数据模型、API、模块、架构约束或编码规范；但在验证和必要用户网关通过之前，不得正式写入 `.paseo/story/` 资产。

> **严禁**：子 Agent 完工后直接跳到下一阶段而不记录主计划执行状态；验证通过前严禁提前将路线图标记为 `[x]`。

#### E. 优先日志验证 (Log-Based Verification)
- 无论是 `upaseo-loop` 的自动验证，还是后续的 Auditor `verify` 阶段，都**必须遵循"优先日志验证"原则**。
- Agent 需要优先捕获并详细分析应用程序在运行时的事件日志 (Event Logs)、Debug 日志以及状态流输出，以此直接自证功能完整性，其后辅以自动化测试用例通过。

#### F. 用户验证网关 / 自主推进判定 (Gate or Auto-Advance)

**Agent 根据验证结果的确定性自主决定是否需要等待用户确认。用户可通过 `--autopilot` / `--gate` 参数强制覆盖。**

**自动推进条件（全部满足时可自动推进）：**
- 验证方式为 `logs` 或 `agent-run`（Agent 可自行完成的客观验证）
- 日志证据完整，关键事件 Trace 全部匹配预期
- 自动化测试全部通过（若有）
- 本迭代无架构性决策变更

**必须等待用户条件（任一满足时必须等待）：**
- 验证方式包含 `browser` 或 `manual`（需人眼判断）
- 涉及 UI/UX 视觉变更
- 迭代中做出了设计文档之外的架构性决策
- Agent 对验证结果存在不确定性

**自动推进时：**
- 在主计划文件中记录 `[auto-advanced]` 标记及验证证据摘要。
- 执行增量历史资产刷新：若本轮新增或修改了前后台用户功能点用例、数据库表结构、类与核心数据结构体、公共 API 路由与服务规范、新的包目录、前端展示页面路由、架构约束或编码规范，必须由主 Agent 或 `story-updater` 更新 `.paseo/story/` 对应文件，并以 `* [Updated in Iter <N>]` 作为前缀。
- 将当前迭代路线图状态更新为 `[x]`，并创建本迭代 checkpoint commit，记录 commit hash 后方可进入下一迭代。
- 用户可随时要求回溯查看。

**等待用户时，向用户展示：**
1. 本迭代完成的成果。
2. 捕获到的关键**日志输出片段/验证结果**。
3. 指导用户自行操作的**手动验证步骤**。
4. 等待用户回复"验证通过"后，将当前迭代路线图状态更新为 `[x]`，执行必要的增量历史资产刷新，创建本迭代 checkpoint commit，记录 commit hash 后方可继续。若不通过，留在本迭代修复。

#### G. 回滚机制 (Rollback)

当迭代 N 的改动破坏了迭代 N-1 已验证通过的功能时：
1. 优先在当前迭代内修复回归问题。
2. 若修复失败（超过 loop 最大迭代次数），执行 `git revert` 回退到上一已验证迭代的 checkpoint commit；若 checkpoint 缺失，必须暂停并向用户说明不能安全自动回滚。
3. 将回退事件记录到主计划文件（标记 `[!] 迭代 N: reverted`），并重新设计当前迭代方案。

---

### 6. 提 PR 门槛、自审与交付

在所有增量迭代全部勾选 `[x]` 完成后，Orchestrator 进入 PR 交付阶段。

**PR 策略**：默认统一 PR。若带 `--pr-per-iteration` 参数，则在每个迭代验证通过后单独提 PR（自审同样在每个 PR 前执行）。

1. **极致精简自理 (upaseo-simplify)**：
   - 强制加载并执行本地 `upaseo-simplify` 技能。
   - 彻底梳理 diff，删除过渡性未使用代码、废弃 imports、多余注释，精简逻辑。

2. **严苛自审质检 (upaseo-reviewer)**：
   - 强制加载并执行本地 `upaseo-reviewer` 技能。
   - 进行质量、边界防御、并发安全和代码坏味道自审，生成自审确认表。
   - 自审发现任何缺陷，必须在本地 100% 闭环修复。

3. **创建 PR 并交付**：
   - 在 worktree 中进行整洁提交，运行 `gh pr create` 提交 PR。
   - 将 PR 链接和自审报告呈给用户。
   - **最终 PR 阶段必须等待用户审批**，不可自动合并。
   - `using-paseo` 到 PR 创建与用户审批为止；用户确认并合并 PR 后，必须手动运行 `/upaseo-ship` 完成发布校验、资产固化、CHANGELOG 和 worktree/分支清理。

### 7. 会话复盘与学习落盘 (Session Learnings Dump) ⚠️ 硬性规定

**在 PR 交付完毕或任务因故挂起归档前，本步骤必须无条件执行。**

1. **深度复盘本次会话/迭代**：回顾整个执行过程，识别出所有：
   - 曾执行但失败的命令或指令（如工具参数错误、路径假设错误）。
   - 被推翻的错误技术假设（如对 API 行为的错误理解、对框架能力的错误预期）。
   - 导致浪费时间的弯路或无效决策。

2. **精炼提取避障规则**：将上述发现提炼为 **1-3 条** 极简、高密度的避障规则。

3. **容量控制与去重**：读取现有 `.paseo/learnings.jsonl`，若条目数 ≥ 30，先精炼合并最旧的相似条目，保持总量 ≤ 30。写入前去重——检查 `mitigation` 字段是否与已有条目语义重复，重复则跳过。

4. **追加写入 `.paseo/learnings.jsonl`**：以 JSON Lines 格式追加。格式规范：
   ```json
   {"timestamp":"<ISO8601>","session_id":"<conversation-id>","category":"<command_error|wrong_assumption|tool_misuse|design_flaw>","failed_attempt":"<简述失败操作>","mitigation":"<应该怎么做>"}
   ```

5. 若本次会话无任何错误或教训，可写入一条 `{"category":"clean_session","mitigation":"无新增避障规则"}` 占位。

---

## 异常恢复 (Resumability)
若执行过程中中断，重新调用 `/using-paseo <slug>` 时：
1. **首先执行 Step 0 和 Step 0.1**：初始化目录、读取 learnings。
2. 扫描 `.paseo/plans/<slug>.md` 确定当前处于哪一个未完成的迭代。
3. 读取该迭代的 `iter_<N>_design_tasks.md` 文件；若遇到旧版历史文件 `iter_<N>_design.md`，先兼容读取，并在继续开发前迁移为 `iter_<N>_design_tasks.md`。
4. 从对应的"设计"、"upaseo-loop 实现"、"日志验证"或"用户验证网关"现场无缝恢复执行。

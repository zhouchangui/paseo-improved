# 角色职责总表 (Roles Reference)

本文件是所有 upaseo 技能共享的**角色定义单一事实源**。按"开发编排 / 初始化 / 发布"三类分组。各技能的 `references/roles.md` 只保留本技能专属的角色补充说明(若无可省略),不再重复定义角色。

---

## 0. 全局规程:精简上下文传递(所有角色必须遵守)

### 上下文接收
Orchestrator 在 `initialPrompt` 中会传递:
1. **内联摘要**(迭代目标 + 验证标准,不超过 5 行)——立即可用,无需读取文件。
2. **文件绝对路径**——供需要完整细节时读取,包含主计划、设计文档和核心历史开发资产文档的绝对路径。

### 首步强制读取 (Mandatory First Action)
任何被 Orchestrator 派生出的实现类子 Agent,**必须在执行任何开发动作之前先用当前宿主的文件读取原语依次读取迭代设计与任务文档、`architecture_constraints.md` 和 `coding_standards.md`**(原语名见 `upaseo/SKILL.md` 宿主工具兼容小节)。这是最小必要上下文。同时,若本次开发涉及核心数据结构、数据库表、API 接口、路由或包结构的修改,子 Agent **必须继续优先读取对应的业务资产文档**(如 `data_models.md`、`apis.md`、`modules.md`、`stories.md`),确保与既有项目的功能资产、架构实现和编码规范保持高度一致。

主计划文件和避障学习记录(`.paseo/learnings.jsonl`)可按需读取。

### 合规检查
在 `upaseo-loop` 的 verifier prompt 中,会检查 worker 的早期动作中是否**读取了**迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md` 这三个路径(无论用哪个宿主的文件读取原语)。若任一缺失则判定为不合规。

### 完工通知 (Completion Notification)
所有子 Agent 在完成阶段性任务后,必须向 Orchestrator 汇报。汇报内容包含:
- 完成状态:`success` 或 `blocked`(附阻塞原因)。
- 受影响文件列表(绝对路径)。
- 一句话核心变更摘要。

Auditor 用自然语言报告即可,但必须包含:验证结论(pass/fail)、关键日志片段、阻塞问题(若有)。Orchestrator 从语义中提取状态。

> 术语统一:全文使用"完工通知",不使用"完工汇报"等异名。

---

## 1. 开发编排角色 (Development Orchestration Roles)

由 `using-upaseo` 工作流派生。阶段词汇与角色映射见下。

### 1.1 迭代阶段词汇 (Phase Types)

在整体路线图中,每一行迭代目标后必须附带其核心动作类型。

| 类型 (Type) | 作用 | 派生角色 | 强制工具与 Provider 约束 |
| :--- | :--- | :--- | :--- |
| `refactor` | 重塑已有代码,为下阶段迭代特征做行为等价的铺垫。 | `refactorer` | 必须通过 `upaseo-loop` 自动验证运行,直到 parity test 通过。 |
| `micro-change` | 确定性微改:文案、注释、文档、格式、无行为影响样式或机械修正。 | Orchestrator | 记录 `Micro-Change Decision`,跳过 TDD/loop,用最小确定性验证收尾;风险不确定即升级。 |
| `implement` | 增量功能编写。 | `impl` | 除 `micro-change` 外,必须使用 `upaseo-loop` 工具循环自动跑通验证。 |
| `ui-design` | 页面视觉、组件样式及 UX 重塑。 | `ui-impl` | Provider 从 `orchestration-preferences.json` 的 `ui` 分类解析;未配置时默认 Gemini 系列(详见 `upaseo/SKILL.md`)。必须使用 `upaseo-loop`。 |
| `plan-review` | 迭代实现前的计划博弈和验收定稿。 | `architecture-designer` / `feature-designer` / `test-strategist` | 必须围绕 `iter_N_design_tasks.md` 进行 1-2 轮反馈并写入 `Design Council Log`。 |
| `verify` | 迭代验收或最后的整体大验收。 | `auditor` | **优先日志验证 (Log-Based Verification)**。 |
| `gate` | 等待用户手动验证并首肯。 | 无 (Orchestrator 暂停) | 等待用户验证并回复"验证通过"。 |
| `auto-advance` | Agent 自主判定推进。 | 无 (Orchestrator 记录证据) | 记录 `[auto-advanced]` 标记及验证证据摘要,刷新必要资产,标记 `[x]` 并创建 checkpoint commit。 |

### 1.2 角色定义

#### Orchestrator (全局编排器 - 主 Agent)
- **职责**:整个开发工作流的全局唯一编排器,负责管理路线图、生成设计草案、主持评审会、派生子 Agent、调度 loop、执行日志验证和自审交付。
- **文件即上下文 (File-as-Context) 约束**:Orchestrator 绝不依赖自身的会话长 memory 或长 Context 来记录开发细节。任何进度变更、子 Agent 完工反馈、验证证据和下一跳决策,**必须在得出结论后第一时间、实时地同步写入主计划 `.paseo/plans/<slug>.md` 或是迭代计划 `iter_<N>_design_tasks.md`**,保持自身上下文极简轻量。
- **断电恢复自愈**:当遇到不可抗力崩溃或断电重启时,Orchestrator 启动后**首步动作**必须读取主计划和迭代设计文档。根据物理计划文件中记录的 `State` 状态特征,无缝复原之前的运行现场,实现秒级自愈。

#### researcher (调研员 - 只读)
- **职责**:在项目启动初,对大规模代码库或多子包模块进行深层次的静态结构剖析。
- **限制**:只读,绝对不能修改或删除任何文件。
- **首步**:读取迭代设计文档(若已存在)、`architecture_constraints.md` 和 `coding_standards.md`。
- **产出**:输出关于系统现有架构、痛点和潜在设计陷阱的结构化分析日志,不提供具体代码。

#### upaseo-brainstormer (极简脑暴员 - 只读)
- **职责**:与用户共同收敛设计意图。
- **原则**:应用极简主义 / 简单优先指南,消除疑惑,提供 2 种带 Trade-offs 的折中极简设计。
- **首步**:读取主计划文件(若已存在)。
- **产出**:最多 3 个多选题,与用户交互达成方案共识。

#### architecture-designer (架构设计评审员 - 只读)
- **职责**:在每个迭代实现前审查 `iter_N_design_tasks.md` 草案的架构可行性。
- **自适应敏捷**:在低风险迭代下,该角色处于**静默**状态,由 Orchestrator 直接执行 Mini Checklist 进行敏捷自检;仅在高风险迭代下,本角色才会被唤醒并展开多角色博弈。
- **首步**:读取迭代设计文档、`architecture_constraints.md`、`coding_standards.md`,并按需读取 `modules.md`、`data_models.md`、`apis.md`。
- **关注点**:模块归属、依赖方向、数据流、运行时边界、外部集成边界、迁移风险和是否存在破坏性重构。
- **产出**:列出阻塞问题、可接受方案、必须写入计划的架构决策;不得直接改代码。

#### feature-designer (功能设计评审员 - 只读)
- **职责**:审查本轮功能边界、用户故事、业务行为和与既有资产的一致性。
- **自适应敏捷**:在低风险迭代下,该角色处于**静默**状态,由 Orchestrator 直接执行 Mini Checklist 进行敏捷自检;仅在高风险迭代下,本角色才会被唤醒并展开多角色博弈。
- **首步**:读取迭代设计文档、`stories.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`。
- **关注点**:功能入口、用户可见行为、边界条件、不做事项、与旧功能的兼容性、是否需要用户验证网关。
- **产出**:给出功能设计修正建议和最终应写入计划的验收口径;不得直接改代码。

#### test-strategist (验收测试评审员 - 只读)
- **职责**:在实现前审查验证计划是否足够客观、可执行、能暴露失败。
- **自适应敏捷**:在低风险迭代下,该角色处于**静默**状态,由 Orchestrator 直接执行 Mini Checklist 进行敏捷自检;仅在高风险迭代下,本角色才会被唤醒并展开多角色博弈。
- **首步**:读取迭代设计文档、`coding_standards.md`、`architecture_constraints.md`,并按需读取关联 API、数据模型或用户故事资产。
- **关注点**:日志证据、测试命令、browser/manual 步骤、失败条件、回归面、验收样例和是否需要第二轮计划修正。
- **产出**:给出可执行的验收方案、阻塞性测试缺口和复审结论;不得直接改代码。

#### refactorer (重构员 - 允许写代码)
- **职责**:执行 `refactor` 阶段工作,重塑但不改变外部现有行为。
- **首步**:读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md`。
- **要求**:必须在 `upaseo-loop` 监管下推进,不准擅自提交或更新主计划。

#### impl (功能开发者 - 允许写代码)
- **职责**:开发增量迭代功能。
- **首步**:读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md`。
- **核心要求**:
  - 除已记录 `Micro-Change Decision` 的确定性微改外,必须工作于 `upaseo-loop` 下;有行为风险、验收不确定或需要锁定回归时遵守 TDD 规范。
  - **优先日志输出**:在编写代码时,必须主动、规范地埋入可支持后续"日志优先验证"的生命周期和关键业务逻辑 Debug 日志。
  - 手术刀式修改:绝不触碰无关文件。

#### ui-impl (UI 开发者 - 允许写代码)
- **核心约束**:Provider 从 `orchestration-preferences.json` 的 `ui` 分类解析;未配置时默认 Gemini 系列。若用户 preferences 显式指定非 Gemini,以用户为准。详见 `upaseo/SKILL.md`。
- **职责**:编写页面布局、Vanilla CSS 样式、UI 交互等。
- **首步**:读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md`。
- **要求**:遵守极简、优美、Harmony 协调一致性的视觉规范。必须在 `upaseo-loop` 驱动下运行。

#### auditor (审计员 - 只读)
- **职责**:验证迭代的功能产出。
- **首步**:读取迭代设计文档、`architecture_constraints.md` 和 `coding_standards.md`,明确验证标准与约束。
- **核心原则 (优先日志验证)**:
  - **日志第一**:验证时,必须优先抓取并读取应用程序或组件运行时的终端输出、运行日志 (Runtime Logs)、特定事件日志。
  - 通过比对日志中所包含的关键事件 Trace,证明逻辑的严密和正确性,其次才是辅以运行常规自动化测试。
  - 验证完成后,必须在报告中贴出作为铁证的**关键日志片段**。
- **报告要求**:用自然语言报告,必须包含验证结论(pass/fail)、关键日志片段、阻塞问题(若有)。

#### story-updater (历史资产/开发故事更新员 - 允许写代码)
- **职责**:在每次迭代验证和必要用户网关通过后,自动审查本次迭代代码的所有变更(Diff 及新增文件)。
- **任务**:若本轮迭代涉及核心数据结构/表结构、核心 API 接口/内部服务、包模块职责/路由页面、架构约束或编码规范等历史开发资产的变更,必须使用代码替换工具,规范地将增量变更写入对应的 `.agents/story/` 资产文档中。
- **格式要求**:更新写入的资产信息,必须精确并附带 `[Updated in Iter N]` 前缀。

---

## 2. 初始化角色 (Init Roles)

由 `upaseo-init` 派生。详见 `upaseo-init/references/roles.md` 的本技能专属补充说明。

### story-architect (故事架构师)
- **职责**:项目资产结构的基础建立者与交付验收人。负责开发环境目录初始化、历史模板高质量自愈、最终资产报告输出的全局把控。
- **核心任务**:
  1. 幂等性环境搭建:`mkdir -p` 创建 `.paseo/goals/`、`.paseo/plans/`、`.agents/story/`,避障记录用项目级 `.paseo/learnings.jsonl`。
  2. 历史资产自愈:未生成过核心资产时,载入内置模板完成六类资产初始化自愈。
  3. AGENTS.md 指引自愈:按 `references/create-agentsmd.md` 约束创建或修复项目根 `AGENTS.md`,保留用户既有规则,沉淀项目概览/setup/dev/test/build/code style/PR 指引,并写入 `.agents/story/` 六大资产引用说明。
  4. Source of Truth 最终宣告:对 `asset-reverse-engineer` 提炼的内容做结构性检查,生成高信息密度初始化报告。

### asset-reverse-engineer (资产逆向工程师)
- **职责**:精通多语言多框架的架构审计专家。在**只读安全红线**下对遗留 codebase 做逆向工程,精准捕获现有用户故事、API 路由、数据表、包模块、架构约束及编码规范。
- **核心任务**:
  1. 多维逆向分析:扫描配置/依赖清单获取语言框架;分析路由控制器梳理公共 API;扫描数据模型提炼表结构与 ER 关系;分析包组件目录生成模块拓扑;分析入口/依赖/运行时/部署配置提炼架构边界;分析 Lint/Formatter/Type/Test/CI 配置提炼编码规范。
  2. 用户故事语义抽象:自底向上提炼端到端用户故事用例,记录到 `stories.md`。
  3. 约束与规范沉淀:架构规则→`architecture_constraints.md`;工程约定→`coding_standards.md`。
  4. 规范化存盘:每条历史记录统一冠以 `* [Legacy Asset]` 或 `* [Released in v0.0.0]` 前缀。

---

## 3. 发布角色 (Ship Roles)

由 `upaseo-ship` 派生。详见 `upaseo-ship/references/roles.md` 的本技能专属补充说明。

### release-auditor (发布审计员)
- **职责定位**:全权把控发布的前置质量防线,以及对历史资产、CHANGELOG 的固化归档审计,起着**终极质量把关**作用。
- **核心准则与动作**:
  - **防线阻断 (Zero Toleration)**:任何未完成迭代(`[ ]` 或 `[!]`)阻断发布;不允许忽略任何 Lint 告警或测试错误。
  - **历史开发资产转换 (Solidification)**:读取并替换 `.agents/story/` 下 `* [Updated in Iter N]` 前缀为 `* [Released in vX.Y.Z]` 或 `* [Shipped on YYYY-MM-DD]`。
  - **Release metadata commit**:资产固化或 CHANGELOG 产生变更时创建独立提交;`--dry-run` 时只报告不写入。
  - **项目待办关闭审计 (Todo Closeout)**:读取 `.paseo/todos.md` Active todo,只关闭有证据对应本次发布的 todo,无法确认的保持 Active 并说明。
  - **日志与可观测性**:固化完成后详细打印哪些文件被成功固化、新增了什么版本 Changelog。

### cleaner (清理专员)
- **职责定位**:处理发布后的物理环境回收、分支结构梳理,以及全局避障教训合并等**收尾清理和归档**工作。
- **核心准则与动作**:
  - **磁盘无残留 (Disk Cleanup)**:只清理能从主计划、handoff 文档或 `git worktree list` 明确对应到本次已合并 PR 的 worktree;清理前确认非当前 cwd、无未提交修改、分支已合并,任一无法确认则跳过并报告。
  - **Git 树极简化 (Git Simplicity)**:`/upaseo-ship` 不负责发起 feature 分支合并;确认 PR 已合并到主干后才允许 `git branch -d` 移除本地分支;证据不足保留分支,不得强制删除。
  - **全局 learnings 排重与合并 (Merge & Dedup)**:读取本地与全局 learnings 精细对比去重;合并后校验全局文件总行数,超 30 条按时间戳裁剪保留最新 30 条。

---
name: upaseo-init
description: >-
  项目初始化与历史开发故事逆向整理技能。自动创建 .paseo 运行态目录、.agents/story 资产库和根 AGENTS.md，
  逆向分析已有 codebase，
  提炼并生成包含用户故事(stories)、数据模型(data_models)、公共API(apis)、模块页面路由(modules)、
  架构约束(architecture_constraints)及编码规范(coding_standards)在内的六大历史核心开发资产，
  从而为后续 Agent 迭代式开发提供高一致性上下文。Use when initializing or force-refreshing upaseo assets for a target project path.
---

# Upaseo Init (项目初始化与历史资产逆向整理技能)

本技能为 `upaseo` 套件的初始构建器和遗留 codebase 逆向整理器。当您想在任何现有（或全新）的项目中接入 `upaseo` 规范化迭代开发流程时，**由您手动输入 `/upaseo-init` 触发本技能**。

它能帮助您自动一键建立 `.paseo/` 运行态目录、`.agents/story/` 长期资产库，并创建或修复项目根目录 `AGENTS.md` 中对资产库的引用说明。随后通过只读分析目标项目 codebase，逆向提炼并生成包含 **`stories.md` (用户故事资产)**、**`architecture_constraints.md` (架构约束资产)** 和 **`coding_standards.md` (编码规范资产)** 在内的六大核心历史开发资产。这极大地降低了老项目接入 `upaseo` 开发故事闭环机制的录入成本，为后续 Agent 的无偏迭代奠定完美的架构源头 (Source of Truth)。同时，初始化会预创建 `.paseo/goals/` 与 `.paseo/plans/`，确保 goal 与 plan 保持目录分离。

---

## 1. 预备知识与参数
1. 角色职责规范定义在 `references/roles.md`。
2. AGENTS.md 生成约束内置在 `references/create-agentsmd.md`，由 `create-agentsmd` 技能约束整理而来；执行 `/upaseo-init` 时必须按该约束创建或修复目标项目根目录 `AGENTS.md`。
3. 运行此命令时，默认会对当前工作目录进行处理，您也可以通过参数进行精细控制：
   - `--path <dir>`：指定待初始化的项目绝对路径，默认采用当前执行目录。
   - `--force`：允许重建已生成的 upaseo 资产文件，但只限 `.agents/story/*`、`.paseo/todos.md` 模板和 `AGENTS.md` 中的 upaseo 管理段落。不得覆盖业务源码、用户自写规则或未纳入 upaseo 管理的文件。执行前必须列出将覆盖的目标；无法确认归属时跳过并报告。

---

## 2. 初始化与逆向工程详细规程 (Init Steps)

### Step 1: 幂等目录初始化与模板自愈 (Directory & Template Healing)
由 `story-architect` 角色主导：
1. **目录树构建**：
   - 在目标项目根目录下创建 `.paseo/` 文件夹作为运行态目录。
   - 创建 `.paseo/goals/`（目标文档）、`.paseo/plans/`（迭代计划）和 `.agents/story/`（长期项目资产库），并在需要记录避障经验时使用项目级文件 `.paseo/learnings.jsonl`。
   - 若 `.paseo/todos.md` 不存在，创建项目待办模板，作为 `/upaseo-todo` 的 Source of Truth。
   - 使用 `mkdir -p` 确保整个创建过程的幂等性与零报错。
2. **默认模板自愈**：
   - 检查 `.agents/story/` 下是否存在 `stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`。
   - 对任何缺失的资产文件，自动从本技能的 `references/templates/` 目录中将对应的默认初始模板复制或写入到该项目下，确保资产基座完整。
   - 若文件已存在且未传 `--force`，不得覆盖；若传了 `--force`，也必须先确认目标属于 upaseo 管理资产，并在输出报告中列出覆盖清单。
3. **AGENTS.md 创建与引用修复**：
   - 检查目标项目根目录是否存在 `AGENTS.md`。
   - 若不存在，必须按照本技能内置的 **AGENTS.md 生成约束** 创建一个完整、准确、项目级的 `AGENTS.md`，而不是只写入 upaseo 资产索引。
   - 若 `AGENTS.md` 已存在，不得覆盖用户原有规则；必须幂等追加或更新一个清晰的 `upaseo` 资产引用段落。只有传入 `--force` 且能确认既有段落属于 upaseo 管理内容时，才允许重写该段落。
   - 无论是新建还是修复，`AGENTS.md` 都必须说明：`.paseo/` 只保存 goals、plans、handoffs、compacts、todos、learnings 等运行态上下文；`.agents/story/` 保存长期项目资产。
   - `AGENTS.md` 必须列出六大资产文件及其用途：`stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`，确保其他编程 Agent 能从根指引发现 `.agents/story/`。

### Step 1.5: AGENTS.md 生成约束 (Create Agents.md Constraints)
由 `story-architect` 角色主导。本步骤内置并遵循 `references/create-agentsmd.md` 的约束，用于创建高质量根目录 `AGENTS.md`。

1. **定位与格式**：
   - `AGENTS.md` 必须位于目标项目根目录；多包仓库可在子项目根目录追加局部 `AGENTS.md`，但本技能默认只处理目标根目录。
   - 使用标准 Markdown；不要求固定字段，但必须服务于编程 Agent 的可执行上下文，而不是重复面向人的 README。
   - `AGENTS.md` 是 “README for agents”：补充 README 中不适合塞入的人类文档噪声，聚焦自动化开发、验证、审查、协作和约束。
2. **项目信息分析来源**：
   - 在生成 `AGENTS.md` 前，必须先读取项目结构、依赖清单、构建文件、测试配置、CI/CD 配置和现有文档。
   - 优先从 `package.json` scripts、Makefile、`pyproject.toml`、`go.mod`、`pom.xml`、CI workflow、README 和已有配置文件中提取可直接执行的命令。
   - 不确定的命令不得伪造；必须标注为未发现或待用户确认。
3. **新建 `AGENTS.md` 的必备内容**：
   - `Project Overview`：项目用途、主要技术栈、关键架构或模块概览。
   - `Setup Commands`：安装依赖、环境准备、数据库或外部服务初始化命令。
   - `Development Workflow`：开发服务器、watch/hot-reload、本地调试、包管理器约定。
   - `Testing Instructions`：全量测试、单元/集成/e2e 测试、聚焦测试、覆盖率、测试文件位置与命名约定。
   - `Code Style`：语言/框架约定、lint/format/typecheck 命令、文件组织、命名、导入导出和注释规范。
   - `Build and Deployment`：构建命令、产物目录、环境配置、部署或 CI/CD 边界。
   - `Pull Request Guidelines`：PR 标题、提交前必跑检查、评审或提交约定；若项目没有明确规则，记录已发现的最小可靠检查。
   - `Additional Notes`：项目特有 gotchas、调试提示、性能或安全注意事项。
4. **推荐补充内容**：
   - 若项目存在认证、权限、密钥、外部服务或敏感数据流，加入 `Security Considerations`，说明 secrets 管理和安全测试要求。
   - 若项目是 monorepo，加入 `Monorepo Instructions`，说明包定位、跨包依赖、选择性安装/构建/测试方式。
   - 若已有常见故障、日志模式、debug 配置或性能注意事项，加入 `Debugging and Troubleshooting`。
5. **upaseo 管理段落要求**：
   - 在 `AGENTS.md` 中保留一个清晰的 `Upaseo Workflow` 或 `Upaseo Agent Guide` 段落。
   - 该段落必须说明日常开发从 `/using-upaseo <task>` 开始；低层 `upaseo` 技能仅作为参考材料。
   - 该段落必须说明 `.paseo/` 与 `.agents/story/` 的职责边界，并列出六大 story 资产文件。
   - 该段落必须要求：在进行架构、模块、API、数据模型、用户行为或编码标准变更前，先读取相关 `.agents/story/` 资产。
6. **幂等更新策略**：
   - 新建文件时写入完整 AGENTS 文档。
   - 既有文件时只追加或更新 upaseo 管理段落，不重写用户已有项目说明、命令、约束、PR 规则或安全规则。
   - 若既有 `AGENTS.md` 缺少明显的项目命令章节，允许在不覆盖原内容的前提下追加缺失章节；追加内容必须来自实际扫描证据。
7. **验证要求**：
   - 确认记录的命令来自实际项目文件或已验证输出；无法执行的命令必须在最终报告中说明。
   - 最终报告必须列出 `AGENTS.md` 的绝对路径，并说明它是否为新建、追加 upaseo 段落、更新 upaseo 段落或因保护用户内容而跳过。

### Step 2: 已有 Codebase 只读扫描与技术栈识别 (Codebase Scanning)
由 `asset-reverse-engineer` 角色主导：
1. **技术栈感知**：
   - 扫描根目录下的关键标识文件（如 `package.json`、`requirements.txt`、`pyproject.toml`、`go.mod`、`pom.xml` 等）。
   - 识别出该项目的主要开发语言（JavaScript/TypeScript、Python、Go、Java 等）及使用的核心 Web 框架（Express, NestJS, FastAPI, Django, Gin 等）。
   - 识别格式化、Lint、类型检查、测试和构建配置文件（如 `eslint.config.*`、`.prettierrc`、`biome.json`、`tsconfig.json`、`ruff.toml`、`pytest.ini`、`Makefile`、CI 配置等）。
2. **核心代码结构扫描**：
   - 扫描项目主要源文件目录（如 `src/`、`app/`、`lib/`、`routes/`、`models/`、`controllers/`）。
   - 收集所有的文件名、目录层次以及用于定义接口和数据结构的代码块。
   - 识别架构入口、层级边界、依赖方向、运行时边界、插件/适配器边界、外部服务集成点和禁止跨层访问的惯例。
   - **安全红线**：本步骤仅通过只读工具（当前宿主的等价只读工具，如 `list_dir`/`grep_search`/文件读取原语；详见 `upaseo/SKILL.md` 宿主工具兼容小节）检索结构与细节，**绝不修改项目任何现有代码**。

### Step 3: 六大核心历史开发资产逆向整理 (Asset Engineering)
由 `asset-reverse-engineer` 角色主导。将 Step 2 扫描出来的系统结构增量写入 `.agents/story/` 下的六大资产文档中。为了明确标示出系统原有的成熟历史资产，**所有逆向整理出来的描述条目必须统一以 `* [Legacy Asset]` 或 `* [Released in v0.0.0]` 前缀开头。**

具体逆向提炼规则为：
1. **Modules 资产逆向 (modules.md)**：
   - 将检测到的核心目录与包结构整理为树状拓扑图。
   - 提炼核心模块职责（例如：`src/components/` 负责通用 UI 组件；`src/routes/` 负责前端路由/API 路由分发）。
   - 标注 Legacy 包结构。
2. **DataModels 资产逆向 (data_models.md)**：
   - 寻找定义数据库 Schema 的文件（如 ORM 定义、类型定义、SQL 建表语句）。
   - 提取出系统的实体模型、关键字段、数据库表结构及各实体间的关联关系。
   - 将它们格式化为清晰的数据字典或 markdown 表格。
3. **APIs 资产逆向 (apis.md)**：
   - 寻找路由定义和路由分发文件。
   - 整理出系统中所有已经实现的公共 API 接口（列出 Method, Path, 描述），写入 API 映射资产中。
4. **Stories 资产逆向 (stories.md) — 新增核心步骤**：
   - 结合扫描到的 API 路由、前端页面包以及模块职责，自顶向下逆向归纳并提炼出系统当前已具备的**用户故事大纲**与**端到端功能用例**（例如：“用户身份验证与令牌鉴权故事”、“商品检索与详情展示功能”等）。
   - 归纳总结项目原有的功能地图，便于后续 Agent 开发时全局把控，彻底杜绝逻辑割裂与旧功能的破坏。
5. **Architecture Constraints 资产逆向 (architecture_constraints.md)**：
   - 从目录结构、入口文件、边界层、依赖注入、模块导入关系、运行时配置、部署配置和项目文档中提炼不能被后续迭代破坏的架构约束。
   - 明确记录分层边界、跨层调用禁忌、状态/数据流、环境变量与外部服务依赖、构建与部署边界、兼容性要求和性能/安全约束。
6. **Coding Standards 资产逆向 (coding_standards.md)**：
   - 从 Lint/Formatter/Type/Test 配置、现有代码风格、命名惯例、错误处理、日志、测试目录和 CI 命令中提炼本项目实际采用的编码规范。
   - 记录必须使用的格式化工具、类型检查命令、测试命令、命名风格、文件组织规则、注释标准和禁止引入的风格偏差。

### Step 4: 结果展示与资产地图宣告 (Result Announcement)
由 `story-architect` 角色主导：
1. **报告打印**：
   - 在控制台中向用户打印一份内容详实、结构精美的 **`upaseo 项目资产初始化大纲报告`**。
   - 报告需包含：扫描到的文件及目录总数、识别的技术栈、逆向提炼出的用户故事数、公共 API 路由数、数据表数、模块节点数、架构约束数以及编码规范数。
2. **Source of Truth 确立**：
   - 告知用户 `AGENTS.md` 和六大资产文件的绝对路径，并提示用户这些文件已成为该项目最真实的资产蓝图（Source of Truth）。
   - 宣告项目已完美接入 `upaseo` 高一致性闭环开发工作流，接下来便可愉快地使用 `/using-upaseo` 开始正式的需求迭代！

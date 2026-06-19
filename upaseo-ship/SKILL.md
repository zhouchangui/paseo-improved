---
name: upaseo-ship
description: >-
  本地发布与收尾交付技能。在 PR 已被批准并合并后由用户手动调用，处理主干发布校验、
  历史开发资产版本正式化(Story Release)、Release metadata commit、物理工作区与临时分支清理，
  以及 CHANGELOG 生成。Use with optional version, keep-worktree, or dry-run arguments after PR approval and merge.
---

# Upaseo Ship (本地发布与收尾交付技能)

本技能为 `upaseo` 套件的发布与清理编排器。在您的功能开发完成、通过 PR 自审、且 PR 已经合并到主干之后，由您**手动敲入 `/upaseo-ship` 命令触发**。它通过**环境前置校验 → 编译与测试防线 → 历史开发资产版本正式化 → Release metadata commit → 物理工作区与开发分支清理 → 全局避障经验同步**，实现项目的高质量交付与开发环境的绝对整洁。

---

## 1. 预备知识与依赖
1. 角色职责规范定义在 `references/roles.md`。
2. 运行此命令前，请确保您在主仓库的工作区中，当前分支为已合并 PR 后的核心开发分支（如 `main` 或 `master`），且已经拉取最新远端代码。
3. 参数说明：
   - `--version <vX.Y.Z>`：手动指定当前发布的正式版本号。若未指定，系统默认采用当前日期 `[Shipped on YYYY-MM-DD]` 进行资产固化。
   - `--keep-worktree`：强制保留本地的临时 worktree 物理目录，不进行物理删除。
   - `--dry-run`：仅输出变更预览，不修改任何文件和执行清理。

---

## 2. 前置避障读取 (Learnings Precheck) ⚠️ 硬性规定

**本步骤为第零优先级动作，在执行任何发布动作之前必须无条件执行。**

执行标准避障前置读取，见 `upaseo/references/learnings-precheck.md`。本技能相关 category 为 `command_error`。严格遵循其中的规则，如果在后续的编译、合并或清理过程中有对应的避障规约，必须予以绝对遵守（例如：若有 `docker compose 必须指定 -p dingding` 且发布涉及容器重启，必须自动附加）。

---

## 3. 发布阶段详细规程 (Ship Steps)

### Step 1: 状态审计与发布前置校验 (Audit & Validation)
由 `release-auditor` 角色主导：
1. **主计划完成度核实**：
   - 检查 `.paseo/plans/` 目录下本次会话的主计划 markdown 文件。
   - 确认其中所有的增量迭代状态是否均已标记为 `[x]`（已完成），是否存在 `[ ]` 未完成或 `[!]` 受阻标记。如果存在未完成项，立即抛出警告并阻断发布。
2. **本地 Git 状态核实**：
   - 检查当前分支是否为核心开发分支，是否已经包含已合并 PR 的最新提交。
   - 检查当前本地分支是否有未提交的更改。如果工作区不干净，提示用户提交或 stash 后再执行 ship。
3. **终极编译与测试阻断 (Compilation & Test Gate)**：
   - 优先读取 `.agents/story/coding_standards.md` 中记录的构建、Lint、类型检查和测试命令；若资产中没有定义，再使用项目惯例命令（例如 `npm run build`、`npm run lint && npm test`）。
   - 执行生产环境构建命令和项目全量单元测试与静态语法检查。
   - **一旦出现任何编译报错、Lint 告警或测试用例未通过，立即抛出醒目警告并强制中断发布，确保不带病上线。**
4. **历史资产存在性核实**：
   - `.agents/story/` 及六个资产文件必须存在。若缺失，阻断发布并提示先运行 `/upaseo-init` 或让 `/using-upaseo` 完成模板自愈初始化。
5. **项目待办读取**：
   - 若 `.paseo/todos.md` 存在，必须读取其中的 Active todo，作为发布收尾状态更新的候选来源。
   - 若文件不存在，不阻断发布；只在输出中说明当前项目尚未启用 `/upaseo-todo` 待办文件。

### Step 2: 历史开发资产固化与 CHANGELOG 追加 (Story Release & Changelog)
由 `release-auditor` 角色主导：
1. **资产版本号转换 (Story Solidification)**：
   - 扫描项目 `.agents/story/` 目录下的六个历史资产文件：`stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`。
   - 将这些文档中，所有在本次开发会话中由主 Agent 追加的以 `* [Updated in Iter N]` 为前缀的描述备注，增量更新替换为：
     - 若指定了 `--version <vX.Y.Z>`，替换为 `* [Released in vX.Y.Z]`
     - 若未指定版本号，替换为 `* [Shipped on YYYY-MM-DD]`（用当前本地日期替换）
   - 在资产文档底部的 `资产更新日志 (Asset Update Log)` 中，增量追加一行以发布版本或日期为名称的归档日志。
2. **CHANGELOG.md 自动生成**：
   - 读取本次主计划文件的 `Progress Notes` 章节，提炼出高密度的改动大纲。
   - 如果项目根目录下存在 `CHANGELOG.md`，自动将本次的改动大纲与版本号/日期作为最新一条记录追加到 `CHANGELOG.md` 的顶部。若文件不存在，则在根目录下新建 `CHANGELOG.md` 并写入。
3. **Release metadata commit**：
   - 若本步骤产生了 `.agents/story/*` 或 `CHANGELOG.md` 修改，必须创建一个独立提交（例如 `chore: release metadata <version-or-date>`），让发布元数据可追溯。
   - 若用户指定 `--dry-run`，只打印将会修改的文件和 commit message，不写文件、不提交。
4. **项目 todo 完成状态更新**：
   - 若 `.paseo/todos.md` 存在，必须根据本次主计划、CHANGELOG、release notes 和实际 diff 匹配与本次发布明确相关的 Active todo。
   - 只关闭有证据证明已经交付的 todo；将其标记为 `[x]`，补充 `completed: YYYY-MM-DD` 与 `shipped: <version-or-date>`，并移动到 `## Done` 或保留在原条目但状态改为完成。
   - 无法确认是否完成的 todo 必须保持 Active，并在 ship 输出中列为“仍未关闭”，不得为了清爽而误关。
   - 若 todo 更新导致工作区产生变更，应纳入 Release metadata commit；`--dry-run` 时只展示将更新的 todo，不写文件。

### Step 3: 物理工作区与分支安全清理 (Physical Cleanup)
由 `cleaner` 角色主导：
1. **合并状态确认 (Merge State Check)**：
   - 本阶段不负责发起 feature 分支合并；它只确认 PR 已经合并到主干，且主干包含发布目标提交。
   - 若 PR 尚未合并，停止并提醒用户先完成 PR 审批与合并。
2. **Worktree 磁盘安全回收**：
   - 若本次开发启用了 `git worktree` 独立物理工作区，且用户**未指定** `--keep-worktree`：
     - 只能清理能从本次主计划、handoff 文档、`git worktree list` 三者之一明确对应到本次已合并 PR 的 worktree。
     - 清理前必须确认目标不是当前 cwd，不包含未提交修改，并且对应分支已经合并到主干。
     - 任一条件无法确认时，跳过清理并在报告中列为“需人工确认”，不得猜测路径。
     - 条件全部满足后，运行 `git worktree remove <worktree路径>` 回收该 worktree。
3. **本地开发分支安全清理**：
   - 只能删除能明确对应本次已合并 PR 的本地临时 feature 分支。
   - 删除前必须通过 `git branch --merged <main-or-master>` 或等价证据确认该分支已合并；若证据不足，保留分支并报告。
   - 条件全部满足后，运行 `git branch -d <branch_name>`；不得使用强制删除。

### Step 4: 避障教训的全局共享与归档 (Learnings Sync)
由 `cleaner` 角色主导：
1. **全局避障数据库合并**：
   - 检查全局 `~/.paseo/global-learnings.jsonl` 文件是否存在（若不存在则自动新建）。
   - 将本项目本地 `.paseo/learnings.jsonl` 中积累的所有独创性避障规则增量导入并合并至全局文件中。
   - **导入去重与上限控制**：合并时进行去重过滤（完全相同的 `failed_attempt` 与 `mitigation` 不重复导入）。若全局教训总条数超过 30 条，先按 `upaseo/references/learnings-precheck.md` §4 的老化规则降级超 90 天未确认的条目，再按时间戳仅保留最新 30 条，确保全局教训高密度且不冗余。
   - **写入方闭环说明**：本步骤是 global-learnings 的唯一写入方；读取方为所有技能的避障前置读取（先读 global 后读项目，见 `upaseo/references/learnings-precheck.md` §2）。因此本步骤写入的规则会在后续任意项目、任意技能的会话启动时被读取并按 category 注入，不再是"只写死功能"。
2. **发布成功宣告**：
   - 打印醒目、带有成功勾选标记的发布总览，向用户展示成功固化的资产、更新的 Changelog、被清理的 Worktree 和已同步的全局 learnings 统计，圆满闭环交付。

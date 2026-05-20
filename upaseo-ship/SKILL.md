---
name: upaseo-ship
description: >-
  本地发布与收尾交付技能。在代码被批准合并后由用户手动调用，处理代码合并、
  生产构建校验、历史开发资产版本正式化(Story Release)、物理工作区与临时分支清理，
  以及 CHANGELOG 生成。
user-invocable: true
argument-hint: "[--version <vX.Y.Z>] [--keep-worktree] [--dry-run]"
---

# Upaseo Ship (本地发布与收尾交付技能)

本技能为 `upaseo` 套件的发布与清理编排器。在您的功能开发完成、通过 PR 自审并被批准合并之后，由您**手动敲入 `/upaseo-ship` 命令触发**。它通过**环境前置校验 → 编译与测试防线 → 历史开发资产版本正式化 → 物理工作区与开发分支清理 → 全局避障经验同步**，实现项目的高质量交付与开发环境的绝对整洁。

---

## 1. 预备知识与依赖
1. 角色职责规范定义在 `references/roles.md`。
2. 运行此命令前，请确保您在主仓库的工作区中，且核心开发分支（如 `main` 或 `master`）保持最新。
3. 参数说明：
   - `--version <vX.Y.Z>`：手动指定当前发布的正式版本号。若未指定，系统默认采用当前日期 `[Shipped on YYYY-MM-DD]` 进行资产固化。
   - `--keep-worktree`：强制保留本地的临时 worktree 物理目录，不进行物理删除。
   - `--dry-run`：仅输出变更预览，不修改任何文件和执行清理。

---

## 2. 前置避障读取 (Learnings Precheck) ⚠️ 硬性规定

**本步骤为第零优先级动作，在执行任何发布动作之前必须无条件执行。**
1. 检查当前项目根目录下是否存在 `.paseo/learnings.jsonl` 文件。
2. 若文件存在，使用 `view_file` 完整读取并解析其中的历史避障记录。
3. 严格遵循其中的规则，如果在后续的编译、合并或清理过程中有对应的避障规约，必须予以绝对遵守（例如：若有 `docker compose 必须指定 -p dingding` 且发布涉及容器重启，必须自动附加）。

---

## 3. 发布阶段详细规程 (Ship Steps)

### Step 1: 状态审计与发布前置校验 (Audit & Validation)
由 `release-auditor` 角色主导：
1. **主计划完成度核实**：
   - 检查 `.paseo/plans/` 目录下本次会话的主计划 markdown 文件。
   - 确认其中所有的增量迭代状态是否均已标记为 `[x]`（已完成），是否存在 `[ ]` 未完成或 `[!]` 受阻标记。如果存在未完成项，立即抛出警告并阻断发布。
2. **本地 Git 状态核实**：
   - 检查当前本地分支是否有未提交的更改。如果工作区不干净，提示用户提交或 stash 后再执行 ship。
3. **终极编译与测试阻断 (Compilation & Test Gate)**：
   - 执行生产环境构建命令（例如 `npm run build` 或项目的编译打包命令）。
   - 运行项目全量单元测试与静态语法检查（例如 `npm run lint && npm test`）。
   - **一旦出现任何编译报错、Lint 告警或测试用例未通过，立即抛出醒目警告并强制中断发布，确保不带病上线。**

### Step 2: 历史开发资产固化与 CHANGELOG 追加 (Story Release & Changelog)
由 `release-auditor` 角色主导：
1. **资产版本号转换 (Story Solidification)**：
   - 扫描项目 `.paseo/story/` 目录下的六个历史资产文件：`stories.md`、`data_models.md`、`apis.md`、`modules.md`、`architecture_constraints.md` 和 `coding_standards.md`。
   - 将这些文档中，所有在本次开发会话中由主 Agent 追加的以 `* [Updated in Iter N]` 为前缀的描述备注，增量更新替换为：
     - 若指定了 `--version <vX.Y.Z>`，替换为 `* [Released in vX.Y.Z]`
     - 若未指定版本号，替换为 `* [Shipped on YYYY-MM-DD]`（用当前本地日期替换）
   - 在资产文档底部的 `资产更新日志 (Asset Update Log)` 中，增量追加一行以发布版本或日期为名称的归档日志。
2. **CHANGELOG.md 自动生成**：
   - 读取本次主计划文件的 `Progress Notes` 章节，提炼出高密度的改动大纲。
   - 如果项目根目录下存在 `CHANGELOG.md`，自动将本次的改动大纲与版本号/日期作为最新一条记录追加到 `CHANGELOG.md` 的顶部。若文件不存在，则在根目录下新建 `CHANGELOG.md` 并写入。

### Step 3: 物理工作区与分支安全清理 (Physical Cleanup)
由 `cleaner` 角色主导：
1. **分支合并与推送 (Merge & Push)**：
   - 在本地安全地将当前的 feature 分支合入主干（`main`/`master`）或发布分支，或提醒用户在远程仓库中点击合并，确保代码的绝对同步。
2. **Worktree 磁盘安全回收**：
   - 若本次开发启用了 `git worktree` 独立物理工作区，且用户**未指定** `--keep-worktree`：
     - 安全地运行 `git worktree remove <worktree路径>` 彻底回收该 worktree 在磁盘上的物理文件夹，防止磁盘垃圾堆积。
3. **本地开发分支安全清理**：
   - 安全删除本地已完成合并的临时 feature 开发分支（运行 `git branch -d <branch_name>`），保持本地 `git branch` 树的绝对清爽与极简。

### Step 4: 避障教训的全局共享与归档 (Learnings Sync)
由 `cleaner` 角色主导：
1. **全局避障数据库合并**：
   - 检查全局 `~/.paseo/global-learnings.jsonl` 文件是否存在（若不存在则自动新建）。
   - 将本项目本地 `.paseo/learnings.jsonl` 中积累的所有独创性避障规则增量导入并合并至全局文件中。
   - **导入去重与上限控制**：合并时进行去重过滤（完全相同的 `failed_attempt` 与 `mitigation` 不重复导入）。若全局教训总条数超过 30 条，根据时间戳仅保留最新 30 条，确保全局教训高密度且不冗余。
2. **发布成功宣告**：
   - 打印醒目、带有成功勾选标记的发布总览，向用户展示成功固化的资产、更新的 Changelog、被清理的 Worktree 和已同步的全局 learnings 统计，圆满闭环交付。

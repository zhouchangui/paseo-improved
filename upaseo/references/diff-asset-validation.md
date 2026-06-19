# 资产防事实漂移校验清单 (Diff-Asset Validation Checklist)

本文件是 `using-upaseo` §5.F 自动推进与等待用户两处都引用的**单一事实源**，定义了"代码已实现并验证通过的内容，才允许写入 `.agents/story/`"的一致性审计标准。任何引用本清单的技能不再重复条文，只写一行引用。

> 规程位置：本文件。
> 谁该读：`using-upaseo` 主 Agent、`upaseo-ship` 的资产固化步骤、任何被指派为 `story-updater` 的子 Agent。
> 何时读：每个迭代验证通过后、`/upaseo-ship` 发布前固化资产前。

---

## 1. 为什么需要这份清单

`iter_N_design_tasks.md` 是"承诺要做的"，`git diff` 是"实际做了的"，`.agents/story/` 是"对外声称的事实"。三者必须一致：

- 若 `iter_N_design_tasks.md` 承诺了 A，但 `git diff` 没有 A 的实现 → **空头承诺**，不得把 A 写进 story。
- 若 `git diff` 实现了 B，但 `iter_N_design_tasks.md` 没规划 B → **越界实现**，要么补回设计文档并补验证，要么回退 B，不得直接把 B 写进 story 当作既定事实。
- 若 `git diff` 实现了 C 且设计文档规划了 C，但 C 没有验证证据（日志/测试/手动验证记录）→ **未验证**，不得写进 story，留在本迭代补验证。

---

## 2. 标准动作（六步）

1. **取 diff 全集**：`git diff <上一迭代 checkpoint commit>...HEAD`（或首个 commit 起），列出本轮所有被修改/新增的文件与关键 hunk。`git status --short` 用于核对是否有未提交改动混入。
2. **取设计承诺全集**：读取当前迭代 `.paseo/plans/<slug>/iter_<N>_design_tasks.md` 的 `迭代目标 / 极简技术方案 / 验证计划` 三段，逐条列出承诺项。
3. **取验证证据全集**：从主计划 `Progress Notes`、验证日志、测试输出、手动验证记录中，汇总本轮已通过的客观证据，标注每条证据对应的命令与结果。
4. **三方对照（核心）**：对每个候选 story 条目，必须同时满足：
   - 在设计承诺中存在对应条目；若不在，先回到设计文档补登记或回退代码。
   - 在 `git diff` 中存在对应实现文件/hunk；若不在，视为空头承诺，丢弃该 story 条目。
   - 存在对应验证证据；若无，留在本迭代补验证，验证通过前不写 story。
5. **逐条登记或拒绝**：对每个候选条目，决定 `写入 story` / `丢弃（空头承诺）` / `挂起（待验证）`，并把决定记录到主计划 `Progress Notes` 的 `Asset Validation Log` 子段，形如：
   ```
   Asset Validation Log (iter N):
   - [write] data_models.md: User.profile.avatar 字段 — diff: src/models/user.py +12, evidence: pytest test_user_avatar pass
   - [drop]  stories.md: "导出 PDF" 用例 — 承诺但 diff 无实现，空头承诺
   - [hold]  apis.md: GET /api/export — 实现但无验证证据，留 iter N 补验证
   ```
6. **写入时打标**：只有 `[write]` 条目才允许更新 `.agents/story/`，且必须以 `* [Updated in Iter <N>]` 作为前缀写入对应资产文件，便于回溯到具体迭代。

---

## 3. 边界与例外

- **微改快速通道（§0.2 判定）**：微改路径不强制三方对照六步，但仍需主 Agent 在最终报告记录 `Micro-Change Decision`、变更范围和最小确定性验证结果；只有当微改触及 story 资产覆盖面时（如改了数据模型字段、改了公共 API），才升级到完整清单。
- **`--pr-per-iteration`**：每个 PR 前都要跑一次本清单，而不是只在最后统一跑。
- **回滚（§5.G）**：若本迭代被 revert，已写入 story 的 `* [Updated in Iter <N>]` 条目必须同步回退或标注 `[reverted]`，不能留下"声称有但代码里没有"的漂移。
- **未触及 story 的迭代**：若本轮改动只是内部重构、测试、文档，不触及 stories/data_models/apis/modules/architecture_constraints/coding_standards 任一资产，`Asset Validation Log` 直接写 `no story asset touched`，跳过写入。

---

## 4. 引用方式

各技能 SKILL.md 中不再重复本清单，改为：

```markdown
执行资产防事实漂移校验，见 `upaseo/references/diff-asset-validation.md`。校验通过前严禁更新 `.agents/story/`。
```

`using-upaseo` §5.F 的"自动推进时"和"等待用户时"两处、`upaseo-ship` 的资产固化步骤都按此引用。

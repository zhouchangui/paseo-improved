# 包、模块与页面拓扑资产 (Modules & Pages Architecture)

本文件定义项目目录包结构、核心模块职责、页面和路由分布，以及它们之间的依赖和调用拓扑。每次迭代若调整模块划分、新增包或页面，必须在此增量更新。

---

## 1. 包与模块职责定义 (Packages & Modules Description)

* [Legacy Asset] `using-upaseo/`：完整开发工作流入口，负责计划、评审、实现、验证、PR 交付和恢复。
* [Legacy Asset] `upaseo/`：底层基座参考，只提供 Paseo agent、worktree、CLI、provider 偏好和 daemon 诊断规则。
* [Legacy Asset] `upaseo-loop/`：实现阶段 worker/verifier 闭环原语。
* [Legacy Asset] `upaseo-ship/`：PR 合并后的发布校验、资产固化、CHANGELOG、release metadata commit 和清理。
* [Legacy Asset] `upaseo-init/`：项目 `.paseo/` 资产初始化、`.agents/story/` 逆向整理，以及按照内置 `references/create-agentsmd.md` 约束创建或修复高质量根目录 `AGENTS.md`。
* [Legacy Asset] `upaseo-e2e/`：独立的集成测试 / e2e 验证入口，负责环境冻结、测试矩阵先行、CLI 树形覆盖、逐条执行、失败复现与 issue 上报。

---

## 2. 页面与前端路由分布 (Pages & UI Routes)

*(暂无资产定义。核心 Web 页面、子视图、对应 UI 路由在此定义。)*

---

## 3. 核心依赖拓扑 (Dependency Topology)

* [Legacy Asset] 日常开发入口必须是 `/using-upaseo <task>`；`using-upaseo` 调用 `upaseo` 基座能力和 `upaseo-loop` 实现闭环。
* [Legacy Asset] PR 合并后的发布收尾必须由 `/upaseo-ship` 触发，不由 `using-upaseo` 自动执行。
* [Legacy Asset] 集成测试 / e2e 验证由 `/upaseo-e2e <target>` 独立执行；若发现缺陷，先通过 `gh` 或 `.github/issues/` 记录，再回流 `/using-upaseo` 做修复。
* [Legacy Asset] `/upaseo-init` 的 AGENTS.md 生成规则来自技能包内置 reference；运行时不得依赖外部 `create-agentsmd` 技能是否存在。
* [Updated in Iter 1] 共享 reference 单一事实源：`upaseo/references/learnings-precheck.md`（避障前置读取五步）、`upaseo/references/roles.md`（16 角色总表）、`upaseo/references/diff-asset-validation.md`（资产防漂移校验六步清单）。各技能 SKILL.md 不再内联重复，只写一行引用。
* [Updated in Iter 2] 多宿主兼容：`upaseo/SKILL.md` 维护宿主工具原语映射表；`using-upaseo`、`upaseo-loop`、`upaseo-handoff`、`upaseo-compact` 的子 Agent prompt / verifier / 恢复读取都引用该表，不硬编码单一宿主原语名。
* [Updated in Iter 4] SoT 优先级链 compact > handoff > plan > goal 作为恢复读取顺序的权威定义；compact/handoff/plan/goal 文档模板各自声明 `Priority:` 元数据。
* [Updated in Iter 5] 一致性校验脚本 `scripts/validate.sh` 三层结构（L1 结构 / L2 交叉引用 / L3 行为）；CI workflow `.github/workflows/validate.yml` 与本地 `scripts/pre-commit.sh` 自动执行。

---

## 4. 资产更新日志 (Asset Update Log)

- **Initialization**: 模块资产库初始化建立。

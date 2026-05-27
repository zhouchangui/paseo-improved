# 包、模块与页面拓扑资产 (Modules & Pages Architecture)

本文件定义项目目录包结构、核心模块职责、页面和路由分布，以及它们之间的依赖和调用拓扑。每次迭代若调整模块划分、新增包或页面，必须在此增量更新。

---

## 1. 包与模块职责定义 (Packages & Modules Description)

* [Legacy Asset] `using-upaseo/`：完整开发工作流入口，负责计划、评审、实现、验证、PR 交付和恢复。
* [Legacy Asset] `upaseo/`：底层基座参考，只提供 Paseo agent、worktree、CLI、provider 偏好和 daemon 诊断规则。
* [Legacy Asset] `upaseo-loop/`：实现阶段 worker/verifier 闭环原语。
* [Legacy Asset] `upaseo-ship/`：PR 合并后的发布校验、资产固化、CHANGELOG、release metadata commit 和清理。
* [Legacy Asset] `upaseo-init/`：项目 `.paseo/` 资产初始化与逆向整理。

---

## 2. 页面与前端路由分布 (Pages & UI Routes)

*(暂无资产定义。核心 Web 页面、子视图、对应 UI 路由在此定义。)*

---

## 3. 核心依赖拓扑 (Dependency Topology)

* [Legacy Asset] 日常开发入口必须是 `/using-upaseo <task>`；`using-upaseo` 调用 `upaseo` 基座能力和 `upaseo-loop` 实现闭环。
* [Legacy Asset] PR 合并后的发布收尾必须由 `/upaseo-ship` 触发，不由 `using-upaseo` 自动执行。

---

## 4. 资产更新日志 (Asset Update Log)

- **Initialization**: 模块资产库初始化建立。

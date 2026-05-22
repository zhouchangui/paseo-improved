# 核心历史资产：用户故事与功能用例大纲 (stories.md)

本文件为项目的用户故事与核心功能用例全局蓝图。后续所有增量迭代均需参考并增量刷新此资产，严禁对已验证的故事主脉络造成破坏性重构或割裂。

---

## 1. 核心角色定义 (Actor Map)

* **开发者 (Developer)**：使用 `/using-upaseo` 执行计划、实现、验证、PR 交付。
* **发布者 (Releaser)**：在 PR 合并后使用 `/upaseo-ship` 完成发布校验、资产固化与清理。

---

## 2. 现有用户故事与核心用例大纲 (User Stories & Use Cases)

* [Legacy Asset] 开发者能够通过 `/using-upaseo <task>` 启动完整开发工作流，并由系统自动选择 quick/full 模式。
* [Legacy Asset] 开发者能够在 quick 模式下获得轻量但仍可恢复、可审计、可发布的单迭代流程。
* [Legacy Asset] 开发者能够在 full 模式下按迭代设计、计划评审、loop 实现、验证网关、自审和 PR 的顺序推进任务。
* [Legacy Asset] 发布者能够在 PR 合并后运行 `/upaseo-ship`，完成主干校验、历史资产固化、CHANGELOG 和环境清理。

---

## 3. 历史资产更新日志 (Asset Update Log)

- **Initialization**: 用户故事资产库初始化建立。

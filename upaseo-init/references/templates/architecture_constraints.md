# 核心历史资产：架构约束与系统边界 (architecture_constraints.md)

本文件定义项目当前必须遵守的架构边界、依赖方向、运行时约束与系统级设计决策。后续所有增量迭代都必须先参考此文件，严禁破坏已经验证的架构前提、跨层职责边界或部署运行约束。

---

## 1. 分层架构与依赖方向 (Layering & Dependency Rules)

> [!NOTE]
> 遗留架构约束统一冠以 `* [Legacy Asset]` 或 `* [Released in vX.Y.Z]` 前缀。

* [Legacy Asset] 示例：UI 层只能通过已定义的服务/API 访问业务能力，不直接读取数据库或持久化实现。
* [Legacy Asset] 示例：领域模型不得依赖具体 Web 框架、ORM 客户端或浏览器运行时对象。

---

## 2. 运行时、配置与部署约束 (Runtime, Config & Deployment)

* [Legacy Asset] 示例：所有环境差异必须通过环境变量或配置文件注入，不在业务代码中硬编码本地路径、端口或密钥。

---

## 3. 外部依赖与集成边界 (External Integration Boundaries)

* [Legacy Asset] 示例：第三方服务调用必须集中在适配器/客户端模块中，业务层仅依赖稳定接口。

---

## 4. 性能、安全与兼容性约束 (Quality Constraints)

* [Legacy Asset] 示例：公共 API 必须保持向后兼容，破坏性响应结构变更需要显式记录迁移策略。

---

## 5. 历史资产更新日志 (Asset Update Log)
- `[v0.0.0] / [Shipped on YYYY-MM-DD]`：初始化 codebase 逆向整理，提炼存盘全部 Legacy 架构约束资产。

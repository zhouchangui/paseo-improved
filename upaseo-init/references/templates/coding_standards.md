# 核心历史资产：编码规范与工程约定 (coding_standards.md)

本文件定义项目当前实际采用的编码风格、命名规则、格式化/Lint/类型检查/测试命令、错误处理与日志约定。后续所有 Agent 写代码前必须参考此文件，避免引入与既有工程风格冲突的实现。

---

## 1. 语言、格式化与静态检查 (Language, Format & Lint)

> [!NOTE]
> 遗留编码规范统一冠以 `* [Legacy Asset]` 或 `* [Released in vX.Y.Z]` 前缀。

* [Legacy Asset] 示例：提交前必须运行项目既有的格式化、Lint、类型检查和测试命令。
* [Legacy Asset] 示例：新增代码必须复用项目已有语言版本、模块系统和构建工具，不擅自引入新的格式化器或包管理器。

---

## 2. 命名、文件组织与导入规则 (Naming, File Layout & Imports)

* [Legacy Asset] 示例：文件命名、导出方式、目录职责和导入顺序必须跟随相邻代码惯例。

---

## 3. 错误处理、日志与可观测性 (Errors, Logs & Observability)

* [Legacy Asset] 示例：错误处理必须保留上下文信息；关键业务路径需要可被日志优先验证的事件或状态输出。

---

## 4. 测试与验证约定 (Testing & Verification)

* [Legacy Asset] 示例：新增行为必须补充贴近风险面的自动化测试或明确的日志/手动验证步骤。

---

## 5. 禁止事项与风格偏差 (Do Not Introduce)

* [Legacy Asset] 示例：不得引入未被项目采用的全局状态方案、代码生成器、大型工具链或与现有风格冲突的抽象。

---

## 6. 历史资产更新日志 (Asset Update Log)
- `[v0.0.0] / [Shipped on YYYY-MM-DD]`：初始化 codebase 逆向整理，提炼存盘全部 Legacy 编码规范资产。

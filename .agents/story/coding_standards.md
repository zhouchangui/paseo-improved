# 编码规范与工程约定 (Coding Standards)

本文件定义项目实际采用的编码风格、命名规则、格式化/Lint/类型检查/测试命令、错误处理和日志约定。每次迭代若新增工程约定或改变验证命令，必须在此增量更新。

---

## 1. 格式化、Lint、类型检查与测试命令

* [Legacy Asset] 当前 upaseo 技能套件的本地一致性验证命令：`bash scripts/validate.sh`。

---

## 2. 命名、文件组织与导入规则

*(暂无额外资产定义。文件命名、导出方式、目录职责、导入顺序和模块组织规则在此定义。)*

---

## 3. 错误处理、日志与可观测性

*(暂无额外资产定义。错误包装、日志字段、调试输出和日志优先验证约定在此定义。)*

---

## 4. 测试与验证约定

* [Legacy Asset] 修改技能工作流后必须运行 `bash scripts/validate.sh`，并复查 `git diff` 中的流程一致性。
* [Legacy Asset] 集成测试 / e2e 必须先冻结测试环境，再写完整测试矩阵，并在执行前完成一次人工确认，之后才允许逐条执行用例。
* [Legacy Asset] 若被测对象支持 CLI，验证方法必须做树形全部覆盖：每个命令节点都要进入测试矩阵并拥有执行、smoke 或 skip 理由。
* [Legacy Asset] 集成测试发现失败时，必须先在冻结环境中复现并分类为 `reproduced`、`flaky` 或 `env-gap`，随后再通过 `gh issue create` 或 `.github/issues/` 记录缺陷。
* [Updated in Iter 6] **代码精简阶梯**：写新代码前对照 `upaseo/references/simplify-ladder.md` 6 级阶梯自检（按项目类型条件启用），命中第一级即停；PR 前由 `upaseo-simplify` 产出删除清单（`[cut]/[shrink]/[keep]`）。安全红线代码（信任边界/防数据丢失/安全/a11y/避障防御）永不入删除清单。
* [Updated in Iter 6] **代码审查引擎分层**：完整模式默认 `ocr review --audience agent`（Tier 1），ocr 不可用降级 Agent 模拟审计（Tier 2）；findings 按 blocker（安全/正确性/资源泄漏，必须闭环）/ minor（风格/可读性，记录不阻断）分级。

---

## 5. 禁止事项与风格偏差

*(暂无额外资产定义。禁止引入的工具链、抽象、风格和危险实现方式在此定义。)*

---

## 6. 资产更新日志 (Asset Update Log)

- **Initialization**: 编码规范资产库初始化建立。

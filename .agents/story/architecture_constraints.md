# 架构约束与系统边界 (Architecture Constraints)

本文件定义项目必须遵守的架构边界、依赖方向、运行时约束和系统级设计决策。每次迭代若引入新的架构规则、改变分层边界或新增外部集成，必须在此增量更新。

---

## 1. 分层边界与依赖方向

*(暂无资产定义。在迭代中发现或新增分层规则、导入方向、领域边界后，请在此定义。)*

---

## 2. 运行时、配置与部署约束

*(暂无资产定义。环境变量、启动方式、部署边界、兼容性要求在此定义。)*

---

## 3. 外部集成与适配器边界

* [Legacy Asset] `upaseo-e2e` 对缺陷上报采取双通道边界：优先使用 `gh issue create` 创建远端 issue；若 `gh` 不可用、未登录或仓库上下文缺失，则必须降级写入仓库内 `.github/issues/`，不得因为外部集成不可用而丢失缺陷记录。
* [Legacy Asset] `upaseo-init` 必须把 AGENTS.md 生成约束内置在自身技能包内；初始化目标项目时可以读取本技能的 `references/create-agentsmd.md`，不得要求目标环境额外安装或可用外部 `create-agentsmd` 技能。
* [Updated in Iter 2] upaseo 技能套件采用**多宿主工具调用层兼容**：文件读取原语、verifier 合规检查、子 Agent prompt 都不得硬编码单一宿主（如 Codex `view_file`）。verifier 按"路径被读取"语义化判定，兼容 ZCode/Claude Code `Read`、Gemini CLI `read_file`。宿主原语映射表定义在 `upaseo/SKILL.md` 的"宿主工具兼容"小节。
* [Updated in Iter 2] UI/Styling 任务的 provider 不得硬编码 Gemini；必须通过 `~/.paseo/orchestration-preferences.json` 的 `ui` 分类解析，未配置时才默认 Gemini 系列。
* [Updated in Iter 4] **SoT 优先级链**（compact > handoff > plan > goal）是恢复与决策的唯一权威链，定义在 `upaseo/SKILL.md`。goal 的边界与验收约束不可被更高优先级文档覆盖或稀释；higher-priority docs 可细化实现但不得移除 goal 约束。
* [Updated in Iter 4] plan 文件必须含 `schema_version` 字段（当前 `1`），决定迭代设计文件命名约定；`schema_version: 0`（无字段）视为旧文件需迁移。迁移规则定义在 `using-upaseo/SKILL.md` 异常恢复小节。
* [Updated in Iter 5] `requirement.md` 已归档到 `docs/history/requirement.md`，仅作历史参考；当前权威工作流规范分散在 `using-upaseo/SKILL.md`、`upaseo/SKILL.md`、`.agents/story/` 与 `scripts/validate.sh`。
* [Updated in Iter 5] `scripts/validate.sh` 重构为三层架构（L1 结构 / L2 交叉引用 / L3 行为），并由 GitHub Actions (`.github/workflows/validate.yml`) 与本地 pre-commit (`scripts/pre-commit.sh`) 自动执行；硬失败阻断，符号链接类（本机部署态）失败仅警告。

---

## 4. 性能、安全与兼容性约束

*(暂无资产定义。影响实现方式的性能、安全、权限、兼容性规则在此定义。)*

---

## 5. 资产更新日志 (Asset Update Log)

- **Initialization**: 架构约束资产库初始化建立。

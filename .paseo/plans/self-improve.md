# upaseo 技能自迭代改进计划

> slug: self-improve
> 模式: 完整仪式模式 (自主判定升级：多迭代 + 架构改进)
> 创建时间: 2026-05-20T14:13:00+08:00

## 迭代路线图
- [x] 迭代 1：对齐辅助技能 (advisor, committee, handoff) 的上下文传递规则
- [x] 迭代 2：对齐 brainstorm、simplify、reviewer 的 learnings 前置读取
- [x] 迭代 3：upaseo 基座增加 learnings 全局引用说明 + 异常恢复规程
- [x] 迭代 4：添加项目基础设施 (.gitignore, README.md) 与自动化验证脚本
- [x] 迭代 5：using-upaseo 长文件拆分优化 — 提取快速模式参考卡

## Progress Notes

### 迭代 1 ✅ [auto-advanced]
- 改动：advisor (+16行), committee (+16行), handoff (+18行)
- 每个文件增加：前置 learnings 读取、上下文文件路径传递+首步 view_file 要求、完工通知
- 验证：agent-run grep 9/9 ✅
- commit: 0316c45

### 迭代 2 ✅ [auto-advanced]
- 改动：brainstorm (+6行), simplify (+6行), reviewer (+6行)
- 每个文件在核心流程前插入"前置避障读取"段落
- simplify 特殊逻辑：若代码存在是为了遵守避障规则，禁止删除
- 验证：agent-run grep 3/3 ✅
- commit: 016fb26

### 迭代 3 ✅ [auto-advanced]
- 改动：upaseo/SKILL.md (+18行)
- 追加"避障学习系统"段落（格式说明、容量上限、去重）
- 追加"异常恢复"段落（检查 .paseo/plans/ 恢复执行）
- 验证：agent-run grep 2/2 ✅
- commit: a6a4d8d

### 迭代 4 ✅ [auto-advanced]
- 新增：.gitignore, README.md, scripts/validate.sh
- validate.sh 综合 6 大检查项：YAML name / 符号链接 / learnings 覆盖 / 外部引用 / 路径一致 / roles.md 规程
- 验证：validate.sh 32/32 ✅
- commit: 1825c9d

### 迭代 5 ✅ [auto-advanced]
- 新增：using-upaseo/references/quick-mode.md, params.md
- 主文件增加 4 处 references 交叉引用
- 快速模式完整流程和参数速查表独立为参考文件
- 验证：validate.sh 32/32 ✅，引用文件内容完整
- commit: ea6e57f

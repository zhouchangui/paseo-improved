# 迭代 4 设计文档：项目基础设施与自动化验证

## 迭代目标

当前项目缺少基本的项目基础设施文件和质量保障工具：
1. **`.gitignore`**：排除 `.DS_Store`、`.paseo/learnings.jsonl`（运行时数据不应入库）等。
2. **`README.md`**：项目概述、技能清单、安装方法、使用示例。
3. **`scripts/validate.sh`**：自动化验证脚本，可一键检查全部技能的内部一致性。

## 极简技术方案

### [NEW] .gitignore
```
.DS_Store
*.swp
.paseo/learnings.jsonl
```
注：`.paseo/plans/` 目录保留入库（计划文件是 Source of Truth）。

### [NEW] README.md
- 项目简介（一段话）
- 技能清单表格
- 安装命令（ln -s）
- 快速使用示例
- 目录结构说明
约 60 行。

### [NEW] scripts/validate.sh
综合此前所有的验证逻辑为一个可执行脚本：
- YAML name 字段校验
- 符号链接完整性
- learnings 读取覆盖率
- 外部技能引用残留检测
- 计划文件路径一致性
输出 PASS/FAIL 总结。约 50 行 bash。

## 验证计划

- **验证方式**：`agent-run`
- **验证命令**：
  ```bash
  bash /Users/zcg/workroot/paseo-improved/scripts/validate.sh
  ```
- **用户手动验证**：阅读 README.md 确认内容完整；运行 validate.sh 确认全绿。

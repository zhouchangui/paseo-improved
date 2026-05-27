# 快速模式流程参考 (Quick Mode Reference)

当 Agent 自主判定（或用户通过 `--quick` 强制）进入快速模式时，执行以下精简流程。快速模式仍适用于小型但有行为风险的实现；若只是确定性微改，优先使用“微改快速通道”，不要为了流程制造测试膨胀。

## 触发条件

### 微改快速通道（先判定）

自动进入微改快速通道需**全部满足**：
- 预估改动范围 ≤ 2 个文件，且 diff 可完整人工审查
- 只涉及文案、注释、文档、格式、无行为影响的样式微调，或机械性重命名/拼写修正
- 不改变运行时逻辑、控制流、数据结构、公共 API、权限、安全、计费、并发、持久化、构建/部署流程或测试语义
- Agent 对结果有确定性，且无需新增测试才能证明行为正确
- 用户没有明确要求 TDD、loop 或完整仪式

微改快速通道执行：
```
Micro-Change Decision（一句话风险判断）
  │
  ▼
直接手术刀式修改
  │
  ▼
最小确定性验证（diff 审查 / 文档校验 / 窄域现有检查）
  │
  ▼
简短交付
```

微改快速通道不创建最小主计划、不创建迭代设计文档、不启动 `upaseo-loop`，也不新增失败测试。一旦实际改动超出边界，必须升级到快速模式或完整仪式模式。

### 快速模式

自动判定进入快速模式需**全部满足**：
- 预估改动范围 ≤ 3 个文件
- 不涉及架构调整或新增模块
- 任务意图明确、无需与用户收敛设计方向（如 Bug 修复、样式微调、配置变更、文案修改）

## 执行流程

```
Step 0: 偏好读取 + .paseo/ 目录初始化
Step 0.1: 前置读取 learnings.jsonl
Step 0.2: 判定为快速模式 → 告知用户（一句话理由）
  │
  ▼
若带 --worktree：创建隔离 worktree → /upaseo-handoff --worktree 到新 worktree 会话
  │
  ▼
创建最小主计划 (.paseo/plans/<slug>.md)
  │
  ▼
创建单迭代设计文档 (iter_1_design_tasks.md)
  │
  ▼
轻量迭代计划评审会（架构/功能/测试 1 轮；有阻塞则第 2 轮）
  │
  ▼
轻量 upaseo-loop 实现（max-iterations <= 3）
  │
  ▼
日志验证 (Log-Based Verification)
  │
  ▼
按 Gate/Auto 规则判定：客观 agent-run/logs 可自动推进；manual/browser/UI 必须等待用户确认
  │
  ▼
upaseo-simplify + upaseo-reviewer
  │
  ▼
checkpoint commit（仅包含本迭代相关文件） → 会话复盘 → PR/提交交付
```

## 与完整模式的差异

| 环节 | 快速模式 | 完整仪式模式 |
|:-----|:---------|:-------------|
| 脑暴 (brainstorm) | **跳过** | 必须执行 |
| 迭代计划评审会 | **必须执行 1 轮，阻塞时第 2 轮** | 每个迭代必须执行 1-2 轮 |
| 迭代数 | **固定 1 个** | 多个 |
| 路线图文件 | 创建最小 `.paseo/plans/<slug>.md` | 创建完整 `.paseo/plans/<slug>.md` |
| TDD / Loop | 有行为风险时仍使用轻量 `upaseo-loop`；确定性微改走微改快速通道 | 必须使用 `upaseo-loop` |
| 自主推进 | 支持同一 Gate/Auto 判定；manual/browser/UI 必须等待用户 | 支持 auto-advance |
| 自审 + 精简 | **同样执行** | 同样执行 |
| 会话复盘 | **同样执行** | 同样执行 |

## Worktree 隔离

快速模式带 `--worktree` 时也必须遵守会话隔离：原会话只创建 worktree 并发起 `/upaseo-handoff --worktree`，接收 Agent 在新 worktree cwd 下创建/读取计划文件、执行轻量 `upaseo-loop`、验证和提交。严禁原会话继续在原仓库路径直接改代码。

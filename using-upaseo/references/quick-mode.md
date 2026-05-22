# 快速模式流程参考 (Quick Mode Reference)

当 Agent 自主判定（或用户通过 `--quick` 强制）进入快速模式时，执行以下精简流程：

## 触发条件

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
等待用户确认（快速模式不支持 auto-advance）
  │
  ▼
upaseo-simplify + upaseo-reviewer
  │
  ▼
checkpoint commit → 会话复盘 → PR/提交交付
```

## 与完整模式的差异

| 环节 | 快速模式 | 完整仪式模式 |
|:-----|:---------|:-------------|
| 脑暴 (brainstorm) | **跳过** | 必须执行 |
| 迭代计划评审会 | **必须执行 1 轮，阻塞时第 2 轮** | 每个迭代必须执行 1-2 轮 |
| 迭代数 | **固定 1 个** | 多个 |
| 路线图文件 | 创建最小 `.paseo/plans/<slug>.md` | 创建完整 `.paseo/plans/<slug>.md` |
| 自主推进 | 不支持（必须用户确认） | 支持 auto-advance |
| 自审 + 精简 | **同样执行** | 同样执行 |
| 会话复盘 | **同样执行** | 同样执行 |

---
name: upaseo-e2e
description: >-
  集成测试与端到端验证技能。先冻结测试环境并写测试用例/验证方法，再逐条执行
  e2e 用例；遇到失败先复现，再通过 gh issue create 上报，若无 gh 则落盘到
  `.github/issues/`。
---

# Upaseo E2E Skill

**User's request:** $ARGUMENTS

本技能用于执行集成测试（integration test）与端到端验证（e2e）。默认目标不是顺手修代码，而是先把环境、用例、证据和缺陷记录跑成闭环：**先冻结测试环境 -> 先写测试用例与验证方法 -> 再逐个执行 -> 失败先复现 -> 再上报 issue**。

## Scope Boundary

- 默认只做测试设计、执行、证据收集与缺陷上报，不在同一轮里顺手修改实现。
- 若验证对象是 CLI、服务编排、跨模块链路、安装/启动/登录/支付/发布主流程，本技能优先。
- 若用户明确要求边测边修，先用本技能产出可复现缺陷与 issue，再把修复交给 `/using-upaseo`。

## Hard Rules

1. **先冻结测试环境，后执行任何用例**。环境没固定，结果一律不算有效。
2. **先写测试用例，后逐个执行**。禁止边跑边补 case。
3. **测试矩阵写完后，必须先经过一次人工确认**。用户未明确确认前，禁止开始执行任何 case。
4. **如果被测对象支持命令行，CLI 验证必须树形全部覆盖**：
   - 先枚举命令树（顶层命令、一级子命令、关键叶子命令）。
   - 每个节点都必须在测试矩阵里出现，并拥有验证方法、执行状态，或明确的 skip 理由。
   - 没进入矩阵的命令节点视为未覆盖。
5. **遇到失败先复现，再创建 issue**。单次偶发失败不能直接上报为确定缺陷。
6. **Issue 上报优先 `gh issue create`**。若当前环境没有 `gh`、未登录或仓库上下文不可用，必须降级写入 `.github/issues/`。

## Step 0: 前置避障读取

如果当前项目根目录存在 `.paseo/learnings.jsonl`，先完整读取并提炼与测试环境、命令使用、历史坑点、验证方式相关的避障规则。后续环境冻结、用例编排、issue 上报都必须服从这些规则。

## Step 0.5: 读取项目上下文

在设计用例前，按需读取当前项目的事实源：

- `AGENTS.md`
- `.agents/story/modules.md`
- `.agents/story/apis.md`
- `.agents/story/architecture_constraints.md`
- `.agents/story/coding_standards.md`
- 用户提供的旧计划、旧报告、旧 issue、CLI 帮助输出或部署说明

不要脱离当前项目真实边界凭空发明验证路径。

## Step 1: 冻结测试环境 (Environment Freeze)

在执行任何 case 前，先把以下信息写进一个测试记录文件。推荐路径：

```text
<项目根目录>/.paseo/plans/<slug>-e2e.md
```

至少记录：

- Git 分支、`git rev-parse HEAD`、`git status --short`
- 当前时间（UTC）、`pwd`、操作系统、关键 runtime/CLI 版本
- 被测服务入口、端口、账号、fixture、seed、测试数据来源
- 需要的环境变量名称（只记键名，敏感值必须脱敏）
- 启动命令、清理命令、重置命令
- 若依赖外部服务，明确说明 stub/mock/real 环境

若环境无法被别人复刻，停止执行，先补齐环境说明。

## Step 2: 先写测试用例与验证方法

开始执行前，必须先写完整的测试矩阵。推荐放在同一个 `.paseo/plans/<slug>-e2e.md` 文件里，至少包含这些字段：

| Case ID | Surface | Preconditions | Action | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |

约束如下：

- `Case ID` 稳定可引用，例如 `CLI-01`、`WEB-02`、`FLOW-03`
- `Verification` 必须写成客观方法：`logs`、`tests`、`browser`、`manual`、`agent-run` 或组合
- `Evidence` 指向命令输出、日志文件、截图、trace、HTML、响应体等
- `Status` 初始统一写 `planned`

### 人工确认门槛

测试矩阵写完后，必须先把以下内容展示给用户做一次人工确认：

- 冻结环境摘要
- 完整 case 列表
- CLI 树形覆盖摘要（若适用）
- 明确的 skip 项与理由

只有当用户明确回复“确认”“开测”“开始执行”或等价指令后，才能进入 Step 3。若用户修改 case、边界或验证方法，则先更新矩阵，再重新确认一次。

### CLI 树形全部覆盖要求

如果目标支持 CLI，必须先做命令树盘点，再映射到测试矩阵：

1. 通过 `<cmd> --help`、`<cmd> help`、`<cmd> <subcmd> --help` 等方式枚举树。
2. 顶层命令、一级子命令、关键叶子命令都要落到矩阵里。
3. 每个节点至少满足以下三者之一：
   - 有执行 case
   - 有 smoke case
   - 有明确 skip 理由（例如“仅云端、当前环境无权限”）
4. 最终报告中必须单列 `CLI Coverage Summary`，不能只说“已覆盖主要命令”。

## Step 3: 逐个执行测试用例

本步骤的前提是：**人工确认已完成**。

执行时遵循单 case 闭环：

1. 只执行一个 `planned` case。
2. 记录实际命令、输入、关键日志、结果证据。
3. 将 case 标记为 `passed`、`failed`、`blocked` 或 `skipped`。
4. 若 case 改变了环境状态，先执行 reset，再进入下一个 case。

禁止一次性跑完所有 case 后再回忆结果补表。

## Step 4: 失败先复现，再认定为缺陷

任何失败都先进入复现步骤：

1. 用同一份冻结环境，重新执行失败 case。
2. 尽量缩小到最小复现命令、最短操作路径、最少前置数据。
3. 记录复现次数与结果：
   - `reproduced`: 稳定复现
   - `flaky`: 间歇复现
   - `env-gap`: 当前环境不足以确认
4. 只有完成上述分类后，才允许创建 issue 或本地缺陷记录。

若问题无法复现，不要把它写成确定性 bug；应记录为 `flaky` 或 `env-gap`。

## Step 5: 上报 issue（`gh` 优先，本地降级）

优先使用仓库内脚本：

```bash
bash upaseo-e2e/scripts/report_issue.sh \
  --title "[e2e][CLI-03] login subcommand exits 1 on valid token" \
  --body-file /tmp/issue-body.md \
  --label bug
```

该脚本的行为是：

- 若 `gh issue create` 可用且当前仓库上下文有效，则直接创建 GitHub issue
- 若 `gh` 不存在、未登录、当前目录不是可上报仓库，或 GitHub 返回错误，则自动降级到：

```text
<项目根目录>/.github/issues/<timestamp>-<slug>.md
```

### issue / 本地记录正文最低要求

无论是 GitHub issue 还是 `.github/issues/*.md`，正文都必须包含：

- 失败的 `Case ID`
- 冻结环境摘要（commit、分支、runtime、fixture）
- 最小复现步骤
- 预期结果
- 实际结果
- 证据路径或关键日志摘录
- `reproduced` / `flaky` / `env-gap` 分类
- 是否阻塞后续 case

## Step 6: 交付报告

完成后输出一份简洁报告，至少包含：

- `Environment Freeze` 摘要
- `Execution Summary`：总 case 数、passed/failed/blocked/skipped 数
- `CLI Coverage Summary`：若有 CLI，列出树形覆盖结果与未覆盖节点
- `Defects`：GitHub issue URL 或 `.github/issues/*.md` 路径
- `Residual Risk`：哪些问题尚未验证、哪些环境结论可能漂移

## 推荐的测试记录模板

```markdown
# E2E Plan: <slug>

## Environment Freeze
- Branch:
- Commit:
- Runtime:
- Target:
- Seed / Fixture:

## Case Matrix
| Case ID | Surface | Preconditions | Action | Verification | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |

## CLI Coverage Summary
- Root:
- Covered nodes:
- Skipped nodes:
- Uncovered nodes:

## Defect Log
- [CLI-03] reproduced -> GitHub issue / local file
```

## Exit Criteria

只有在以下条件满足时，才能说本轮集成测试完成：

- 测试环境已冻结并可复述
- 测试矩阵已先写完，再执行
- 测试矩阵在执行前已完成一次人工确认
- 每个 case 都有最终状态
- 若存在 CLI，命令树节点已全部进入覆盖矩阵
- 每个失败 case 都完成了复现分类
- 每个确认缺陷都有 GitHub issue URL 或 `.github/issues/*.md` 记录

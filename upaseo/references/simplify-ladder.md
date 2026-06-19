# 代码精简阶梯与延迟债务 (Simplification Ladder & Deferred Debt)

本文件是 `upaseo-simplify`、`using-upaseo` §5.C / §6 引用的**单一事实源**，定义精简阶梯、删除清单、延迟债务登记三个规程。任何引用本文件的技能不再重复条文，只写一行引用。

> 规程位置：本文件。
> 谁该读：`using-upaseo` 主 Agent（实现前 ladder 自检 + PR 前 simplify）、`upaseo-simplify` 执行体、`upaseo-ship`（发布前复核 type:debt）。
> 哲学来源：吸收 ponytail "Lazy, not negligent" —— 因必要而小，不是 golf；安全/正确性永不入删除清单。

---

## 1. 精简阶梯 (The Simplification Ladder)

实现一段代码之前，**从上到下逐级判定，命中第一级即停**，不继续往下走：

| 级别 | 自问 | 命中动作 |
|:---:|:---|:---|
| 1 | 这东西需要存在吗？ | 不需要 → 整个跳过（YAGNI），不写 |
| 2 | 标准库能做吗？ | 用标准库，不自造 |
| 3 | 平台原生能力能做吗？ | 用原生能力（运行时/框架内置） |
| 4 | 已安装依赖能做吗？ | 用现成依赖，不重复造轮子 |
| 5 | 一行能做吗？ | 一行实现，不拆不必要的函数/类 |
| 6 | —— 最后才写"能跑的最小实现" | 写最小可用实现，不夹带灵活性 |

- 阶梯只在"要写新代码"时跑；修改既有代码的 bugfix 不强制重跑，但若该 hunk 本轮被大改，顺带自检一次。
- 阶梯判定结论必须可一句话说明（"用了 stdlib 的 X，跳过 5/6"），写入迭代设计草案或 commit note。

---

## 2. 删除清单 (Delete-List)

事后（PR 前的 `upaseo-simplify` 阶段）对当前 `git diff` 逐 hunk 重跑阶梯，产出一份**删除清单**：

1. 列出每个"本可停在更高 rung 却写多了"的 hunk，标注它实际停在第几级、本应停在第几级、可删/可收缩的具体内容。
2. 对每条逐项决定 `[cut]` / `[shrink]` / `[keep]`：
   - `[cut]` 整段删除（如预测性代码、未使用的通用包装）。
   - `[shrink]` 收缩为更短形态（如 50 行 → 标准库 1 行）。
   - `[keep]` 保留并说明为何不能上移 rung（如已被架构约束锁定）。
3. 应用 `[cut]` / `[shrink]` 后必须重新跑验证（测试/日志/validate.sh），确认未破坏行为。
4. 删除清单摘要写入 PR 自审报告。

---

## 3. 延迟债务 (Deferred Debt, `type: debt`)

当为求简而取捷径——主动落到更低 rung（如手写最小实现而暂不抽公共 util），或 simplify 阶段刻意保留某条捷径——必须把这条捷径登记为延迟债务，避免"以后"变成"永不"。

- 登记位置：`.paseo/todos.md` 的 `## Active` 桶，条目带 `type: debt` 字段（格式见 `upaseo-todo/SKILL.md`）。
- 每条债务记录：捷径描述 + 被推迟的"正确做法" + 关联文件:行 + 来源（`source: simplify`）。
- 不登记捷径 = 静默欠债，禁止。登记后即使捷径被长期保留，也是"可见可审计的债"。
- `upaseo-ship` 发布前复核 `type: debt`：被推迟的正确做法若已在本次 release 实现（diff/测试有证据），标记 resolved 移到 Done；否则保持 Active 并在 ship 输出报告"未偿还技术债务"。

---

## 4. 安全红线 (Safety Boundary)

以下代码**永不入删除清单**，无论阶梯判定它多"多余"：

- 信任边界校验（入参/权限/越权防御）。
- 防数据丢失处理（事务/幂等/回滚/备份）。
- 安全相关代码（鉴权/加密/防注入/脱敏）。
- 可访问性 (a11y) 相关代码。
- 避障前置读取（`learnings-precheck.md`）要求保留的防御性代码——若某段代码正是为遵守某条历史教训而存在，禁止视为冗余删除。

"Lazy, not negligent"：因必要而小，不是把安全/正确性也一起砍掉。

---

## 5. 项目类型条件启用

ladder 的完整 6 级判定按项目/改动类型条件启用，避免对纯文档/配置改动过度仪式：

- **diff 含代码文件**（扩展名如 `.py .ts .tsx .js .jsx .go .java .kt .rs .rb .php .cs .swift .c .cc .cpp .h` 等）：走完整 6 级 ladder + 完整删除清单。
- **纯 markdown / shell / json / yaml / 配置改动**：降级为一句话 YAGNI 自检（"这段是否需要存在？是否重复了已有约定？"），不强制逐级走完。
- 判定方法：`git diff --name-only` 扩展名扫描；只要命中任一代码扩展名即视为代码改动走完整规程。

---

## 6. 引用方式

各技能 SKILL.md 中不再重复本清单，改为：

```markdown
执行精简阶梯与删除清单，见 `upaseo/references/simplify-ladder.md`。
```

`upaseo-simplify` 是本文件的执行体；`using-upaseo` §5.C（实现前 ladder 自检）与 §6 item 1（PR 前删除清单 + 债务登记）引用本文件；`upaseo-ship` 复核 `type: debt`。

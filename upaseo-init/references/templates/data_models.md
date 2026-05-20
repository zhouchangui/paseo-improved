# 核心历史资产：数据模型与实体表结构 (data_models.md)

本文件定义了系统目前已存在的数据库表结构、数据模型以及核心类/数据体，是保障多 Agent 迭代开发时数据字典一致性、严禁重复定义相同实体或随意破坏表关系的关键历史资产地图。

---

## 1. 核心实体表结构与数据字典 (Entity Schemas)

> [!NOTE]
> 遗留历史模型表定义统一冠以 `* [Legacy Asset]` 或 `* [Released in vX.Y.Z]` 前缀。

### 实体：User (用户表)
* [Legacy Asset] **模型名称/表名**：`users`
* [Legacy Asset] **数据结构字典**：
  | 字段名 | 类型 | 约束 | 说明 |
  | :--- | :--- | :--- | :--- |
  | `id` | BigInt | Primary Key, Auto Increment | 用户唯一标识 |
  | `username` | String(50) | Unique, Not Null | 登录用户名 |
  | `password` | String(255) | Not Null | 加密后的密码哈希 |
  | `created_at` | DateTime | Not Null | 账户创建时间 |

---

## 2. 实体关系图与物理关联拓扑 (ER Relationship)
* [Legacy Asset] `users.id` (1) <----> (N) `orders.user_id` (用户与订单一对多关联)

---

## 3. 历史资产更新日志 (Asset Update Log)
- `[v0.0.0] / [Shipped on YYYY-MM-DD]`：初始化 codebase 逆向整理，提炼存盘全部 Legacy 数据模型实体。

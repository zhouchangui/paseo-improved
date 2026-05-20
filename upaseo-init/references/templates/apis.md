# 核心历史资产：公共 API 与核心服务接口 (apis.md)

本文件完整罗列了系统中所有已实现的公共 API、核心路由以及业务核心接口规约。所有新增接口或接口修改都必须严格参考此文档，确保请求与响应结构一致，杜绝接口命名杂乱无章和重复造接口的问题。

---

## 1. 核心 HTTP 公共 API 接口规范 (API Directory)

> [!NOTE]
> 遗留公共接口描述统一冠以 `* [Legacy Asset]` 或 `* [Released in vX.Y.Z]` 前缀。

### 模块：用户认证模块 (Auth Controller)
* [Legacy Asset] **`POST /api/v1/auth/register` (用户注册)**：
  - **请求参数**：`{"username": "string", "password": "string"}`
  - **响应结果**：`{"code": 200, "message": "success", "data": {"id": 1}}`
* [Legacy Asset] **`POST /api/v1/auth/login` (用户登录)**：
  - **请求参数**：`{"username": "string", "password": "string"}`
  - **响应结果**：`{"code": 200, "message": "success", "data": {"token": "jwt..."}}`

---

## 2. 内部核心 Service 与公用接口 (Service Interfaces)
(在此罗列系统关键服务层或 RPC 等接口契约)

---

## 3. 历史资产更新日志 (Asset Update Log)
- `[v0.0.0] / [Shipped on YYYY-MM-DD]`：初始化 codebase 逆向整理，提炼存盘全部 Legacy 公共 API 与服务接口。

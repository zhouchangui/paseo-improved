# 核心历史资产：项目目录、包模块职责与页面拓扑 (modules.md)

本文件定义了项目当前的物理目录结构、包/模块的职责边界以及前端的页面路由拓扑地图。用来防范 Agent 在开发中违反物理包职责界线（如把后端逻辑写进前台组件）或造成文件目录混乱。

---

## 1. 物理目录结构与包职责界限 (Package Layout)

> [!NOTE]
> 遗留物理模块职责定义统一冠以 `* [Legacy Asset]` 或 `* [Released in vX.Y.Z]` 前缀。

```
项目根目录/
  ├── src/                 # * [Legacy Asset] 项目主源代码目录
  │    ├── components/     # * [Legacy Asset] 全局共享通用组件
  │    ├── models/         # * [Legacy Asset] 数据库模型定义包
  │    ├── routes/         # * [Legacy Asset] API/页面路由核心包
  │    └── index.js        # * [Legacy Asset] 项目入口启动文件
  └── package.json         # * [Legacy Asset] 依赖清单与项目配置
```

---

## 2. 前端展示页面路由拓扑 (Page Route Topology)
* [Legacy Asset] `/login` ---> 对应组件 `src/views/Login.jsx` (用户登录主页)

---

## 3. 历史资产更新日志 (Asset Update Log)
- `[v0.0.0] / [Shipped on YYYY-MM-DD]`：初始化 codebase 逆向整理，提炼存盘全部 Legacy 项目目录与页面包拓扑资产。

# sla_ecs 总结

## 项目概述

sla_ecs 是一个用 Sla 语言编写的 SA 原生 ECS（实体-组件-系统）运行时。遵循 SA 哲学：不引入 `mut` 关键字，写访问通过线性所有权传递（`fn(World) -> World`）表达。

## 架构决策

### 为什么不照搬 Bevy

Bevy 重度依赖 Rust 类型系统特性（GAT、HRTB、proc-macro、&mut T）。SA 有更强的机制 — Referee O(1) 位掩码验证。因此采用 **SA 原生 ECS 策略**：

| Bevy 方式 | SA 方式 |
|-----------|---------|
| `&mut T` 借用检查 | 线性所有权 + Referee 写推断 |
| trait 分发 Query | 具体 Query 结构体 + for-in 协议 |
| derive 宏生成 impl | 手写 impl 或未来 @derive |
| 函数签名即系统 | 显式 `fn(World) -> World` |

### 关键设计

1. **SoA 存储** — 每个组件按字段拆分为并行数组，缓存友好
2. **for-in 协议** — 通过 `iter_len`/`iter_at` 方法支持 `for item in query` 语法
3. **Mut 写回** — 修改后通过 `write_back(slot, value)` 回写（已验证可行）
4. **交换删除** — `remove` 将最后一个元素交换到被删位置，O(1) 删除

## 编译器修复

发现并修复了 `sa_plugin_sla` codegen 中的一个 bug：

**问题**：`typeSize(.array)` 返回 `元素大小 × 长度`（内联字节数），但数组在结构体中实际以堆指针（8 字节）存储。导致包含数组字段的结构体偏移量计算错误，在循环中访问时产生段错误。

**修复**：将 `typeSize(.array)` 改为返回 `8`（指针大小）。

**回归测试**：`sa_plugin_sla/tests/test_unit_struct_field_array_loop.sla`

## 测试结果

| 文件 | 通过 |
|------|------|
| entity.sla | 3 |
| storage.sla | 5 |
| world.sla | 3 |
| demo_movement.sla | 2 |
| demo_health.sla | 3 |
| demo_full.sla | 3 |
| query_surface.sla | 1 |
| query_iter_probe.sla | 1 |
| query_write_probe.sla | 1 |
| world_min.sla | 1 |
| **总计** | **23** |

## 已知限制

1. **固定容量 16** — 编译期数组，适合演示
2. **无跨文件导入** — Sla 目前不支持 .sla 间的 import，每个文件自包含
3. **impl 方法 + 循环内 return self** — type_checker 拒绝，需用自由函数绕过
4. **嵌套 struct 字段访问** — 需先 `let x = item.field` 再使用，避免临时变量泄漏
5. **result = func(result)** — 触发 UseAfterMove，需用新 `let` 绑定

## 未来方向

- 实现 `Mut<T>` wrapper 类型 + Referee 自动写权限推断
- 添加 `@derive(Component)` 支持
- 泛型 Query 类型替代具体结构体
- 操作符重载支持 Vec 数学运算
- 扩容到动态 Vec 存储（需 Vec 泛型支持）

# 01 总览与分层

> 修订版（N3 对账修订，对账线 2026-11-08）：本文件为 70ad245 所提交
> 01 的修订稿全文，改动点逐处登记于对账线 RESULT-RECONCILE §2；
> 已提交原文不改动，合成落地候主会话。

## 1.1 定位与定案基线

slaengine 是自家特色游戏引擎，总仓 `layola13/slaengine`，形态学 Bevy：
workspace + crates，**SLA 为主**，Zig/Python 为辅（物理已立 **SLA 座**
`crates/sla_physics`，2026-11-01 立座并注册入 workspace；C 不设引擎
域座次、仅作互操作面；非 SLA 面不得漂移成主体）；**Blender 就是
编辑器**（不是备胎），引擎侧只补场景
语义与边玩边改迭代环薄层；`sla_ecs` 与 `sa_plugin_3dengines` 已并入
workspace 作 crate、原仓冻结归档。代码尽量与 Bevy 1:1，但**不用 Bevy
宏**——以编译器内建、描述符注册表、函数指针等轻机制顶替（逐项见 03）。

引擎的第二路输入（用户 2026-11-08 定序）：Warcraft 支线阶段二（原版
24 件 DLL 系统逆向）供**真逻辑与真规格**，OpenRealm 供**组织参考与
行为对照**（见 04/05）。两路输入都先进格式层与规格槽，不直达引擎
运行时。

## 1.2 分层

自上而下，只许向下依赖：

```
┌ 编辑器薄层（仓外为主）：Blender 本体 + 场景语义桥协议（06）
├ 应用层：伞 crate `slaengine` —— App / Plugin 注册 / 主调度标签 / Runner
├ 渲染后端层：sla_webgl（P1）｜ sla_gpu（P2） —— 帧包提交、宿主导入面
├ 资产桥：sla_asset —— 契约→World 生成、按名解析、接口校验（PLAN C1–C8）
├ 域层：sla_3d —— math/time/input/color/transform/geometry/camera/
│        image/material/light/scene/animation/gizmos/particle
│        sla_physics —— 解算层 + 分析预演层（will 事件谱系；
│        定点确定性；章程见 crates/sla_physics/CHARTER.md）
├ ECS 核：sla_ecs —— World/Schedule/System/Query/描述符注册表
├ 生产侧（编译期/资产期，不被运行时反向依赖）：
│   slasl（shader 编译）｜ sax3d（原生格式 + 转换器）｜ 导入族（07）
└ 平台层（workspace 之外、之下）：sa_std（sci）——一切基础核心
```

要点：

- **生产侧与运行时侧分离**（PLAN 已定）：运行时 crate 只消费 slasl
  的产物（shader 文件 + 接口表）与 sax3d 的格式契约（SPEC），不依赖
  两者的工具本体。Warcraft 导入族同属生产侧/加载期，其运行时解析
  形态见 07 的分叉 N1。
- **桥只认契约不认实现**（PLAN 连接面总原则，本集沿用为全仓总则）：
  一切跨层连接以契约（SPEC、接口表、描述符）为界，两侧实现演进不
  穿透；一切按名解析失败**响亮拒绝**，不设静默兜底。
- **sa_std 在 workspace 之下、永不之内**：平台能力（网络、文件、
  线程、GPU 宿主面等基础核心）归 sa_std，引擎逻辑只住成员 crate。

## 1.3 横切面

**调度（goroutine 基础）**。引擎并行模型立在 goroutine 综合体上
（运行时一期已在 native 落地，CPS/状态机共享 lowering）。分工：
ECS 内的系统并行由 sla_ecs 的 access 追踪 + 批规划承载（已验形态）；
ECS 之外的引擎级并发（资产流式加载、网络、编辑器桥通信）一律用
goroutine + 通道/select，**不在引擎内长第二套调度器**（PLAN §2.4
已定：sla_ecs 的 TaskPool/Scope 生产级执行器缺口骑 goroutine 运行时
推进，归 P3）。

**描述符注册表（反宏基底）**。Bevy 靠过程宏 + 反射完成的类型注册、
参数注入、插件唯一性，在本引擎统一落为「描述符 + 命名函数指针 +
注册表查重」——sla_ecs reflect 组即此基底的现形态。此基底同时是
编辑器检查面（06）与 SAB 联邦化相容（下条）的数据来源。

**SAB 注册表联邦化相容**（编译器侧设计约束，引擎侧义务）。联邦化
形态：第三方包自带 SAB 表面清单（名字→lowering 描述），编译器加载
时合并各包清单并只验清单↔该包声明一致性。引擎侧的相容义务：
**每一个对外表面（crate 公共 API、插件注册面、导入族读者 API）都
必须能以「名字 + 描述符」形式枚举**，即与描述符注册表同源登记；
引擎不得出现只能靠编译器中心表才可达的表面。此条是验收检查项，
不是新增机制——注册表纪律本来就要求表面可枚举，联邦化只是让
「不可枚举的表面」从坏习惯升级为不可编译。

**@gpu 依赖登记**。@gpu v1 无设备浮点；开门口径已定（元素形先行、
关 FMA、固定舍入、归约定序、超越函数禁或标近似）。架构后果：
依赖 GPU 计算的设计（粒子/物理计算面）在 v1 必须给出整数/定点
形态，或显式排在浮点开门之后。物理座自身即以定点算术为底
（`crates/sla_physics/CHARTER.md` §6：同种子推演逐位一致是刚需），
与此口径同向。本集在 08 登记此依赖；开门实现不在本集、不在本线。

**浮点纪律（CPU 侧）**。引擎数学面 f32/f64 密集（sla_3d math/
geometry）。SLA 浮点语义以编译器现行为准；F2 分叉（Zig 内核去向）
未裁前，math/geometry 的实现形态保持 PLAN 裁定表的「改造后移植」
状态，不在本集预设结论。

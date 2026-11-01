# 参照普查（轻量版）— Rapier / Jolt / Box2D v3

> 地基批产物（2026-11-01）。只读克隆于 `~/workspace/slaengine-physics-refs/`
> （rapier `475caa3`、jolt `ea4599d`、box2d `dd8bd3f`，均 depth-1 浅克隆）。
> 逐仓按五轴速览：数据布局 / 步进管线 / CCD·扫掠 / 确定性 / 克隆·序列化，
> 每项映射到本座契约位（CHARTER.md §4–§7），标注「学 / 不学」与理由。
> 本表为轻量版：排期到时深化为逐文件细读清单。

## Rapier（主位 — 解算层架构骨架）

许可 Apache-2.0（Cargo.toml `license = "Apache-2.0"`），与 workspace 相容。

| 轴 | 事实（出处） | 映射我方契约位 | 学/不学 |
|---|---|---|---|
| 数据布局 | 状态不在管线内：`PhysicsPipeline::step` 以 `&mut` 借入 RigidBodySet / ColliderSet / IslandManager / CCDSolver 等独立集（src/pipeline/physics_pipeline/mod.rs）；刚体集 = `Arena<RigidBody>`（index+generation 句柄）+ coarena 组件存储（src/data/{arena,coarena}.rs、rigid_body_set.rs） | §4 世界值式多开：状态全在数据集合里、步进器无状态——正是我方 (种子， 剧本） 分支可廉价克隆的前提形态 | **学**：集外置 + 句柄 arena + 步进器无状态，是全表最对口的一条 |
| 步进管线 | `step` 分段：user changes → broad phase → narrow phase → CCD → solver (solve.rs/substep.rs 子步） → integrate → events（physics_pipeline/{mod,solve,substep}.rs) | §3 解算层分段基线；子步形态供我方 dt 契约参考 | **学**分段骨架；子步策略候实现批细定 |
| CCD/扫掠 | 独立 `CCDSolver` + `sweeps.rs`（src/dynamics/ccd/）；QueryPipeline 一等扫掠面：`cast_ray` / `cast_shape` / `cast_shape_nonlinear`（query_pipeline.rs:217/489/525) | §3 预演层扫掠 TOI 求交的接口形态参照：扫掠是独立查询面、不埋在步进里 | **学**接口形态；TOI 数值解法洁净室自研（定点） |
| 确定性 | 顶层文档把「跨机逐位确定 + 快照恢复」列为招牌（src/lib.rs 头注）；`enhanced-determinism` feature（与 simd8 互斥——为确定性牺牲 SIMD 宽度） | §6 确定性前提一的工程形态参照：确定性是显式模式、要付性能价 | **学**「确定性为显式契约」的立场；**不学**其浮点级别——我方终局为定点审计级，它只是 IEEE-754 内跨机一致 |
| 克隆/序列化 | 集与组件 derive Clone；`serde-serialize` feature 下 Serialize/Deserialize（rigid_body_set.rs 等）；管线本身无状态、可任意多开 | §4/§6 分支 = 克隆世界 + 换剧本：集可克隆即分支可开 | **学**；我方克隆面按值语义设计（SLA 值类型），不走 serde |

## Jolt（求解器蓝本）

许可 MIT（LICENSE），与 workspace 相容。

| 轴 | 事实（出处） | 映射我方契约位 | 学/不学 |
|---|---|---|---|
| 数据布局 | `BodyManager` 持有 Body 数组、`BodyID` 句柄；Body 为大结构体（运动性质部分分离）；PhysicsSystem 为有状态门面（Jolt/Physics/Body/、PhysicsSystem.h) | §4 世界形态对照组：门面有状态、多开成本高于 Rapier 集外置 | **不学**其门面形态（与前提三冲突）；Body 内部字段组织在细读批再看 |
| 步进管线 | `PhysicsSystem::Update(dt, collisionSteps, …)`：broadphase → IslandBuilder 分岛 → 速度/位置迭代（默认 10/2, PhysicsSettings.h）→ 积分；JobSystem 多线程分岛并行 + LargeIslandSplitter | §3 解算层求解质量参照：分岛并行与迭代预算的定价方式 | **学**求解器组织与迭代定价；分岛调度与我方 goroutine/@gpu 车道的映射候实现批 |
| CCD/扫掠 | `EMotionQuality::LinearCast` 按体开启的扫掠 CCD（MotionQuality.h:28)；`NarrowPhaseQuery::CastShape` 一等形状扫掠（NarrowPhaseQuery.h:67) | §3 扫掠面：按体分级 CCD(Discrete/LinearCast）是成本控制的好形态 | **学**分级 CCD 思想；预演层 TOI 不靠它（我方事件驱动直接解 TOI) |
| 确定性 | `JPH_CROSS_PLATFORM_DETERMINISTIC` 编译开关（关 FMA 等，Core.h:150/192)，默认关；另有 DeterminismLog 分歧定位设施 | 前提一的反面教材 + 工具参照：确定性靠事后开关补不齐、要从数据布局起设计 | **学** DeterminismLog 式分歧定位工具思想；**不学**开关式确定性（我方定点从底起） |
| 克隆/序列化 | `PhysicsSystem::SaveState/RestoreState(StateRecorder, 过滤器）`（PhysicsSystem.h:165、StateRecorder.h）——为回放/回滚设计、可按状态子集过滤保存 | §3 FPS 应用域的回滚对账、§6 分支快照：过滤式快照（只存会变的状态）值得学 | **学**过滤式快照形态；我方快照 = 世界值克隆，过滤口径借鉴其 StateRecorderState 分类 |

## Box2D v3（C 席位形态 + 2D）

许可 MIT（LICENSE, Erin Catto），与 workspace 相容。

| 轴 | 事实（出处） | 映射我方契约位 | 学/不学 |
|---|---|---|---|
| 数据布局 | v3 全 API 为不透明句柄：`b2WorldId`/`b2BodyId` + 自由函数（include/box2d/{id.h,box2d.h})；内部 SoA 式集 + arena 分配器（src/{body.c,arena_allocator.c,solver_set.c}) | §4 句柄面形态：与我方骨架 WorldId/BodyId 句柄设计同构，C 席位实现时的直接参照 | **学**：句柄 + 自由函数是我方 C/SLA 两面都可落的形态 |
| 步进管线 | `b2World_Step(worldId, timeStep, subStepCount)`;solver = 约束图着色 (constraint_graph.c) + island (island.c) + 宽 SIMD 求解器变体 (contact_solver_w4/w8.c) | §8 @gpu 面：图着色并行求解与车道形态同构——着色后同色约束互不相交、天生元素形 | **学**图着色求解组织（GPU 车道与 CPU 并行共用此思想）；SIMD 宽变体不照搬（我方走定点） |
| CCD/扫掠 | `b2ComputeTimeOfImpact`（docs/collision.md:272、toi 状态机 b2TOIState);`b2World_CastShape` / `b2World_CastMover` 世界级扫掠 + 逐形状 `b2CastShape*`（box2d.h:111/118、collision.h:297+) | §3 预演层 TOI：TOI 作为独立纯函数面（输入两形状运动、输出时刻与状态）是我方事件驱动推进的函数形态参照 | **学** TOI 纯函数面形态；数值法洁净室自研 |
| 确定性 | v3 求解顺序固定（图着色与线程数无关地确定）；large_worlds 文档载跨平台确定性属性在双精度/大世界模式下保持（docs/large_worlds.md:37） | 前提一：着色求解使并行与确定性兼得——我方 @gpu 批量推演的组织参照 | **学**此点（确定性不靠串行牺牲、靠求解组织） |
| 克隆/序列化 | 一等快照 API:`b2World_GetSnapshot` / `b2World_RestoreFromSnapshot` / `b2CreateWorldFromSnapshot(image, size, workerCount)`（box2d.h:324–367)——世界 ↔ 字节镜像互转 | §6 分支模型：世界镜像化（字节图）正是我方 @gpu 侧 sa_mem 镜像的同构形态；分支 = 镜像 + 剧本 | **学**镜像化世界形态（与既有 GPU 镜像经验合流） |

## 汇总：四条前提的参照落实

| 前提 | 最强参照 | 落实形态 |
|---|---|---|
| ①确定性 | Rapier（显式模式）+ Box2D（着色求解） | 定点从底起；确定性写进契约而非开关；求解组织保并行确定性 |
| ②扫掠原生 | Rapier QueryPipeline + Box2D TOI 纯函数面 | 扫掠为独立查询面 + TOI 纯函数；预演层事件驱动直接消费 |
| ③状态可克隆 | Rapier 集外置 + Box2D 世界镜像 | 世界 = 可克隆数据集合 / 字节镜像；分支开仓成本低 |
| ④数据化外力输入 | Rapier 显式施力 (&mut 集 + forces 组件） | `step(world, dt, inputs)` 数据契约；三参照均无回调藏输入之弊，此条主要防我方自蹈 |

## 不学清单（汇总）

- 任何参照的运行时代码与数值常数表（洁净室纪律，全部自研实现）。
- Jolt 的有状态门面与开关式确定性；PhysX 的黑盒 GPU 管线结构
  （仅看切分思想，另行细读不在本轻量批）；Bullet 的架构（仅 Blender
  场景语义对表，另案）。
- 浮点数值路线本身：三参照皆浮点引擎，我方数值底为定点——**布局与
  组织学它们，数值语义不学**，这是本座与全部参照的分界线。

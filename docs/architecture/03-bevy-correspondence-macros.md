# 03 与 Bevy 的对应表（宏顶替逐项）

对应分两层：**概念层**对应（crate 与 App 组织）已由伞 README 与
PLAN §1/§3 定版，本文件只作收束索引；**机制层**对应——Bevy 的宏
面逐项顶替——是本集的核心新增（用户定案：代码尽量与 Bevy 1:1，
但不用 Bevy 宏，以编译器内建、描述符注册表、函数指针等轻机制
顶替）。

## 3.1 概念层对应（索引，不重述）

| Bevy | slaengine | 定版出处 |
|---|---|---|
| bevy 伞 crate（re-export 门面） | 伞 crate（App 层宿主，非平坦门面——差异理由见伞 README） | 伞 README |
| bevy_app（App/Plugin/Schedule 组织） | 伞 crate App 层 | PLAN §3 |
| bevy_ecs | `crates/sla_ecs`（core 组） | PLAN §2 |
| bevy_tasks | sla_ecs tasks 逻辑组（远期 sla_tasks） | PLAN §2.2 |
| bevy_reflect | sla_ecs reflect 逻辑组（描述符子集，远期 sla_reflect） | PLAN §2.2/§2.4 |
| bevy_asset / bevy_gltf | `crates/sla_asset` / `crates/sax3d`（格式与转换器） | PLAN §1/§2.5 |
| bevy_render / bevy_wgpu | `crates/sla_webgl`（P1）/ `crates/sla_gpu`（P2） | PLAN §1/§4.3 |
| bevy_math/time/input/color/transform/mesh/camera/image/pbr/light/scene/animation/gizmos 等域 crate 群 | `crates/sla_3d` 域组（单 crate + 域子目录为现形态；拆分与否 = 分叉 F1） | PLAN §4.3 |
| bevy_shader | `crates/slasl`（生产侧：编译器 + 接口表，无运行时对应物） | PLAN §1 |

## 3.2 宏顶替总表（本集新增）

判读：顶替机制只许三类——**内建**（编译器直接认识的概念）、
**描述符**（描述符注册表条目 + 显式注册函数）、**函数指针**
（命名函数 + 函数指针表）。新遇 Bevy 宏面时先归入此三类之一；
归不进的登记为分叉上报，不自创第四类机制。

| # | Bevy 宏面 | 在 Bevy 中的作用 | slaengine 顶替 | 落点与现状 |
|---|---|---|---|---|
| M1 | `#[derive(Component)]` | 组件类型注册、存储形态派生 | **描述符**：组件描述符（id/布局/丢弃函数指针）经显式注册函数入组件注册表；`component_metadata` 面即其现形态 | sla_ecs core 组；已有形态（metadata 注册表 + 查重先例） |
| M2 | `#[derive(Resource)]` | 资源类型登记 | **描述符**：资源描述符 + 门面 `init_resource` 注册 | sla_ecs 门面；已有机制 |
| M3 | `#[derive(Bundle)]` | 组件束的插入/移除派生 | **描述符**：bundle 描述符表（bundle_info/bundle_writer 家族）驱动插入/移除，不生成派生代码 | sla_ecs core 组；已有形态 |
| M4 | `#[derive(Event)]` / `#[derive(Message)]` | 事件/消息类型登记与缓冲 | **描述符**：消息注册表（message_registry 家族）按名注册 + 显式读写器类型 | sla_ecs core 组；已有形态 |
| M5 | `#[derive(Reflect)]` + `#[reflect(...)]` | 任意值内省、类型数据附着 | **描述符（子集）**：reflect 组的类型描述符 + 显式 id 消费者（AppTypeRegistry / reflect_type_data）；**明确不做** dyn Any 级内省（语言层缺口，PLAN §2.4 定性：长期替代形态即描述符 + 显式格式） | sla_ecs reflect 组；已有形态，P3 随场景/编辑器消费者增厚 |
| M6 | `SystemParam` 派生（`Query`/`Res`/`ResMut`/`Commands` 等参数注入） | 系统函数签名即注入声明 | **函数指针 + 适配器**：系统 = 命名函数指针；参数以 system_param 适配器家族按参数形状显式适配（命名函数代闭包泛型，与 sla_ecs 哲学表第 2 条同纪律） | sla_ecs system_param 家族；机制已验 |
| M7 | `Plugin` trait 实现 + 插件唯一性 | 插件构建钩子、重复注册防护 | **函数指针 + 描述符**：插件 = `fn(App) -> App` 命名函数 + 插件描述符（名/版本/依赖掩码）；注册表按名查重、重复响亮拒绝；finish/cleanup 为可选第二/三函数指针槽 | 伞 crate（PLAN §3.1 定版，吸收 3dengines plugin_desc 草案） |
| M8 | `add_systems(schedule, (a, b, c))` 元组 trait 魔法 | 多系统一次注册的类型级展开 | **函数指针表**：注册点接命名函数指针数组（有序表字面量），无元组 trait | 伞 crate `app_add_systems`；P1 增厚 |
| M9 | `App::register_type::<T>()` 泛型注册调用链 | 反射注册的泛型入口 | **描述符**：注册调用以类型描述符值为参（显式 id），不走泛型单态化入口 | sla_ecs reflect 组 + 伞层插入点（PLAN §3.1 末行） |
| M10 | `#[derive(Asset)]` / AssetLoader 泛型注册 | 资产类型与加载器登记 | **描述符 + 函数指针**：资产种类描述符（扩展名集/格式 id）+ 加载器函数指针入 sla_asset 解析/校验表；按名/按格式解析失败响亮拒绝 | sla_asset（PLAN C1/C4 同调）；P1 |
| M11 | `#[derive(States)]` / `#[derive(ScheduleLabel)]` 等标签派生 | 状态机与调度标签的类型化 | **内建 + 描述符**：标签 = 伞层单点定义的 i32 规范标签 + `EcsScheduleLabelTrait` 类型化包装（sla_ecs 已有先例） | 伞 crate 定义、sla_ecs 承载（PLAN §3.1） |
| M12 | `spawn((A, B, C))` 组件元组推断 | 实体生成时的束推断 | **描述符**：经 bundle_spawner / 门面生成 API 以 bundle 描述符显式生成 | sla_ecs 门面；已有形态 |
| M13 | bevy_derive 其余过程宏（如 `Deref`/`DerefMut` 派生、枚举变体辅助） | 样板消除 | **不顶替**：SLA 侧以普通函数/显式字段访问书写；样板量属可接受范围，不为此引入任何宏面。此条是显式「不做」登记，防止逐案漂移 | 全仓纪律 |

## 3.3 与 1:1 原则的边界

「尽量 1:1」指 API 表面、调用形态、命名对齐（TODO 判读口径，
用户 2026-11-01 定）；内核按我方最有利/最快实现。上表顶替改变的
全是**机制层**（宏展开点），表面形态（注册一个组件、加一个系统、
挂一个插件的调用形状）保持与 Bevy 同构——这是 M 表的设计约束：
任何一项顶替若迫使表面变形，先登记分叉，不静默变形。

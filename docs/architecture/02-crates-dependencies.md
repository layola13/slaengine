# 02 crate 切分与依赖方向

crate 总图与依赖方向以 PLAN §1 为定版，本文件是其**现状对齐版**：
逐座标注 2026-11-08 本机实测状态，避免架构与仓库实物脱节。

> 修订版（N3 对账修订，对账线 2026-11-08）：本文件为 70ad245 所提交
> 02 的修订稿全文，改动点逐处登记于对账线 RESULT-RECONCILE §2；
> 已提交原文不改动，合成落地候主会话。

## 2.1 座次表（实测 2026-11-08，对账后基座）

本地主本 `~/workspace/slaengine-local` 已对账：基座与远端 main
`e7d720fe` 树等价（远端 2 笔物理座提交已并入，见 2.3）。成员以
`workspace.toml` 为唯一真理源。

| crate | 角色（Bevy 对应） | 来源 | 实测状态 |
|---|---|---|---|
| `slaengine`（伞） | App 层宿主（bevy 伞） | 本仓 | 骨架在：`src/slaengine.sla` + `examples/smoke/` |
| `crates/slasl` | shader 编译器（生产侧） | 本仓既有 | **活跃**（DESIGN/REPORT/golden 齐） |
| `crates/sax3d` | 原生资产格式 + 工具链（Zig，生产侧） | 本仓既有 | **活跃**（SPEC 冻结，转换器已交付） |
| `crates/sla_ecs` | ECS 本体（bevy_ecs）+ tasks/reflect 逻辑组 | sla_ecs 一次性 embed（基线 `1be020b`） | **已嵌入**：src 523 文件、tests 427 文件（PLAN 映射目标 521/426，差额为 .sai/.sal 与计数口径）；P0 报告载名字集门 PASS（405=405）——该读数引 P0_REPORT，本线未复跑 |
| `crates/sla_3d` | 3D 域模块群（bevy_math/time/input/…） | sa_plugin_3dengines 逐模块迁入（基线 `06f4fae`） | **批 A 已落**：src 下见 math/time/input/color/transform 五组；批 B 候 P1 |
| `crates/sla_asset` | 资产桥（bevy_asset 加载/句柄层） | 新建（PLAN C1–C8 归属） | 座位在，有 FILL_CENSUS；桥本体候 P1 |
| `crates/sla_webgl` | 渲染后端一期（bevy_render 的 WebGL 面） | 新建（airlock 模式迁入） | 座位在（src/tests/SOURCES），首光候 P1 |
| `crates/sla_gpu` | 渲染后端二期（bevy_render + WebGPU 面） | render_wgpu 改造迁入 | 座位在，候 P2 |
| `crates/sla_physics` | 物理座（解算层 + 分析预演层，will 事件谱系） | 本仓 af300d9 立座、e7d720f 注册入 workspace（license MIT OR Apache-2.0 经所有者 2026-11-01 确认） | **已立座且已对账入本地基座**：CHARTER（章程）+ docs/REFERENCE_SURVEY（rapier/jolt/box2d 普查）+ src/physics.sla 骨架 197 行；原生 SLA 洁净室路线、定点确定性；实现层未排期（CHARTER §9）。分叉 N3（物理座状态对账）已裁定并随本次对账关闭 |
| （远期）`crates/sla_tasks` / `crates/sla_reflect` | bevy_tasks / bevy_reflect | sla_ecs 逻辑组物理拆出 | P3 视消费者定（PLAN 已定，不预拆） |

## 2.2 依赖方向（定版，本集重申）

```
伞 → sla_asset / sla_webgl / sla_gpu → sla_3d / sla_ecs → sa_std
slasl、sax3d、导入族 = 生产侧：被消费的是产物与契约，不是本体
```

规则：

1. 成员间只许 workspace 相对路径互引，不许 reaching 到 workspace
   外的兄弟仓取码（workspace.toml 已明文）。
2. 运行时 crate 不反向依赖生产侧本体（01 §1.2）。
3. `sla_ecs` 内部不长 App；App 经门面 `ecs_world_*` 驱动 World
   （PLAN §3 定版：伞层建 App 是纯增量外挂，ecs 内部零改动）。
4. 新座入 workspace 必须先改 `workspace.toml` 成员表并在 README
   布局表登记——成员表即联邦化表面清单的仓内对应物（01 §1.3）。

## 2.3 本地/远端对账记录（原分歧已消解）

- 远端 main 曾领先本地 2 笔：`af300d9`（physics seat foundation：
  charter、参考普查、SLA 骨架）、`e7d720f`（physics seat 注册入
  workspace 成员 + README 布局；license 经所有者 2026-11-01 确认
  MIT OR Apache-2.0）。对账线 2026-11-08 已逐路径核对：该 2 笔
  相对本地基点 `041f5f0` 的差分 = 新增 `crates/sla_physics/` 5 文件
  + `workspace.toml`/`README.md` 各 1 行注册，无删除；与
  `docs/architecture/` 无路径交集。本修订稿所在合成提交即以
  `e7d720f` 等价基座为父，本地/远端分歧就此消解（逐路径对账表
  见对账线 RESULT-RECONCILE §1）。
- 本地工作树有 1 处未提交修改：`crates/sla_ecs/src/
  app_type_registry_deep.sla`（非本线所为，本线未碰）。
- `workspace.toml` 的 `[workspace.toolchain]` 钉版（sci `83c61d43` /
  sla `e3d2023`）已落后于当前两仓头（2026-11-08：sci `7735c31a` /
  sla `86646d82`）。重钉与随之的验证构建属实现期工作，候主会话
  在实现期开工时一并处置；本线零编译、不代跑。

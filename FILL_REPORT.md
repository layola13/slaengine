# slaengine 占位座填充批 B — 终报（2026-11-01）

一句话结论：**sla_webgl 与 sla_gpu 两座已用生态存量原样填充并通过同口径
验收（失败名字集前后相等）；`3d_render_wgpu` 本体在仓内差一条被 PLAN
明文排除的 import 边、登记为「已复制未验证（仓内）」并附实证诊断；
sla_asset 经全生态普查确认无可复制存量、占位保持并附说明页。**

工地：`~/workspace/slaengine-fill-local/`（自 `~/workspace/slaengine-local/`
头 `8bd4a72` 克隆，staging 提交链、未推送）。本批不碰 sla_ecs / sla_3d
（P0 批独占）。验收在二盒 rig 区口径执行（见 §3）。

提交链（基点 `8bd4a72` 之上）：
- `20a78f5` fill sla_webgl（sidecar 存量）
- `16a2f87` fill sla_gpu（render_wgpu + wgpu 库存量）
- `83800cc` sla_asset 普查页（无存量、占位保持）
- 本报告提交（终报）

## 1. 存量盘点全表

普查范围：本机 `~/workspace` 各相关仓与工地、普查线落地的
`~/workspace/slaengine-survey/sa_plugin_3dengines/`（盒上核验副本）、本机
备份镜像 `~/workspace/sa-backup/*.git`、二盒 `/content/sa_all` 检出
（本批直查：插件家族与本机一致，`sa_plugin_wgpu` 头 `ed61845`、
`sa_plugin_3dengines` 头 `06f4fae` 与镜像/普查基线逐字一致）。
判定依据：`~/workspace/slaengine-survey/PLAN.md` §4.3 逐模块裁定表与
§4.2 架构口径；PLAN 判「不移植」者一律不填。

| # | 候选存量 | 来源（仓 + 头 + 路径） | 归座/处置 | 理由 |
|---|---|---|---|---|
| 1 | sa3d.sai + sa3d.sal（sidecar 导入面 + cube 常量） | sa_plugin_3dengines `06f4fae`，`sa_plugin_3d/sa3d.sai`、`sa3d.sal` | **→ sla_webgl 已填** | PLAN §4.3 聚合行处置 ②：sidecar 机制迁入 sla_webgl |
| 2 | airlock broker（sa3d_airlock_runtime.js + sa3d_airlock_gen.zig） | 同上，`sa_plugin_3d/src/` | **→ sla_webgl 已填** | 同上；gen.zig 为辅助面（@embedFile 嵌 JS），按语言总则登记 |
| 3 | sa3d_sidecar_layout_test.sa | 同上，`sa_plugin_3d/tests/` | **→ sla_webgl 已填**（import 归一 2 行） | sidecar 存量的自带验收 |
| 4 | 聚合 3d.sal + 3d_aggregate_layout_test.sa | 同上 | 不填 | PLAN 处置 ①：模块位掩码已被 workspace.toml 成员表取代 |
| 5 | demos/*.sax | 同上，`sa_plugin_3d/demos/` | 不填 | PLAN 处置 ③：历史参照，不迁 |
| 6 | demos/*_decl.sax3d + tools/lower_sa3d_scene.mjs + sa3d_scene_cubes_layout_test.sa | 同上 | 不填 | PLAN 处置 ④：Scene3D 声明式格式退役（与冻结 SAX3D **同名不同物**，严禁混淆） |
| 7 | 聚合 tools/verify_*.mjs、src/plugin.zig、src/module_config.zig、sap.json、build.zig | 同上 | 不填 | 插件时代工作流/宿主脚手架，PLAN §4.3 common/tools 行：不移植 |
| 8 | 3d_render_wgpu.sai + .sal + layout 测试 | sa_plugin_3dengines `06f4fae`，`sa_plugin_3d_render_wgpu/` | **→ sla_gpu 已填**（.sal 中 wgpu import 归一 1 行；shader import 原样保留、悬空，见 §4） | PLAN §4.3：改造后移植（P2）；本批只落存量，改造归 P2 |
| 9 | render_wgpu 的 plugin.zig/module_config.zig/sap.json/build.zig | 同上 | 不填 | 宿主壳剥离（PLAN 直接移植口径通则） |
| 10 | wgpu.sal + wgpu.sai + wgpu_layout_test.sa | sa_plugin_wgpu `ed61845f56031c4da9a7dd1ecf1597e162c7c4e5`（镜像 refs/box/master；二盒检出头一致），仓根与 `tests/` | **→ sla_gpu 已填**（依赖库存量，`src/wgpu/`） | render_wgpu.sal 的既有 import 依赖；纯 SA 常量/布局库、无 @import、无宿主壳。注意：填的是**库**不是插件依赖——sap/宿主壳未入仓；Jev F3（0.97）「sla_gpu 自带导入面」仍是 P2 终态口径 |
| 11 | wgpu 插件其余件（src/plugin.zig、plugin_api.zig、wgpu_airlock_gen.zig、demos/、tools/verify_*.mjs、build.zig、sap.json、package.json） | sa_plugin_wgpu `ed61845f` | 不填 | 插件宿主 + 其自有 sidecar/demo/验收脚手架；sla_gpu 的 broker 形态由 P2 自带导入面批决定 |
| 12 | sa_plugin_3d_shader（3d_shader.sal，1018 行） | sa_plugin_3dengines `06f4fae` | **不填**（PLAN 明文） | PLAN §4.3：与 slasl 重复、以 slasl 为准；其布局仅作 sla_gpu 绑定层**设计参考**。render_wgpu 对它的 import 边因此悬空，见 §4 登记 |
| 13 | sa_plugin_3d_gltf（.sal 33,790 行，ABI-only） | 同上 | 不填 | PLAN：与 sax3d 转换器重复、以 sax3d 为准；loader 设置面仅作 sla_asset 加载选项的**设计参考**（不复制代码） |
| 14 | sa_plugin_3d_ecs / 3d_app / 3d_xml / 3d_yaml / common/ / tools/ | 同上 | 不填 | PLAN 逐项明文：ecs 以 sla_ecs 为准、app 设计由伞层吸收、xml/yaml 域外、common/tools 脚手架退役 |
| 15 | sla_3d 域 16 模块（math/time/input/color/transform/geometry/camera/camera_controller/image/material/pbr/light/scene/animation/gizmos/particle） | 同上 | 不归本批 | PLAN 落点为 crates/sla_3d，由 P0 批 A / P1 批 B 独占施工，本批不碰 |
| 16 | d.ts2sai 转换产物（three.sai 等 + babylon/playcanvas 产物） | `~/workspace/dts2sai-local/generated/` 等工地 | 不填 | 外部 JS 库的绑定面产物，属 tsgosa/TS 线；引擎两后端绑定的是平台 WebGL/WebGPU 面而非 three.js API，填入只会污染座位语义 |
| 17 | sa_plugin_sax | 二盒 sa_all / 本机镜像 | 不填 | SAX 组装语言插件（CXU/TS 栈），非资产加载存量 |
| 18 | 资产/加载类插件（全家族普查） | 二盒 `/content/sa_all` 全家族 + 本机镜像清单 | **不存在** | 家族全表：3dengines、wgpu、sax、sla、db、node、deno、bc2sa、http_client、http_server、mui、pkg、react、ts、tui、vite、vm——无 asset/loader 插件 |
| 19 | sax3d 侧接口表夹具（如 examples/pbr_std.iface.txt） | 已在 `crates/sax3d` 内 | 不复制 | 已是 workspace 成员内容；复制入 sla_asset 违反「不与 sax3d 格式本体重复」 |
| 20 | sla-shader-local 内的第二份 3dengines 副本 | `~/workspace/sla-shader-local/sa_plugin_3dengines/` | 仅登记 | 本批一律以普查线盒上核验副本（`06f4fae`）为唯一来源，不用第二副本 |

**sla_asset 结论**：桥（PLAN §2.5 的 C1–C8）是 P1 新建工作，生态内无
对应实现存量；相邻项全部已有归属或被 PLAN 排除（#13/#15/#19）。按任务
纪律如实报空：占位保持 + `crates/sla_asset/FILL_CENSUS.md` 一页说明，
未造件充数。

## 2. 逐座填充清单（细节见各座 SOURCES.md，含逐文件 sha256）

### crates/sla_webgl（提交 `20a78f5`）
- `src/sa3d.sai`、`src/sa3d.sal`、`src/sa3d_airlock_runtime.js`、
  `src/sa3d_airlock_gen.zig`：与源文件 **sha256 逐字一致**（SOURCES.md
  逐项登记）。
- `tests/sa3d_sidecar_layout_test.sa`：仅 import 归一 2 行
  （`../sa3d.*` → `../src/sa3d.*`），diff 已验恰为该 2 行。
- `SOURCES.md` 新建（逐文件出处）；`crate.toml` 状态行更新为已填口径
  （存量仍为 WebGPU 目标、WebGL 改造归 P1——明示未改造）。

### crates/sla_gpu（提交 `16a2f87`）
- `src/3d_render_wgpu.sai`、`src/wgpu/wgpu.sal`、`src/wgpu/wgpu.sai`：
  sha256 逐字一致。
- `src/3d_render_wgpu.sal`：仅 1 行归一
  （`../../sa_plugin_wgpu/wgpu.sal` → `wgpu/wgpu.sal`，指向座内依赖
  副本）；另一条 import `../sa_plugin_3d_shader/3d_shader.sal` **原样
  保留**（座内无合法目标，见 §4）。
- `tests/3d_render_wgpu_layout_test.sa`、`tests/wgpu_layout_test.sa`：
  各 1 行 import 归一，diff 已验。
- `SOURCES.md` 新建；`crate.toml` 状态行更新（含悬空边明示）。

### crates/sla_asset（提交 `83800cc`）
- 仅 `FILL_CENSUS.md`（普查结论页）；crate.toml 不动（「无内容」仍属实）。

零语义改动声明：除上述逐项登记的 import 行归一（webgl 2 行、gpu 3 行）
与 crate.toml 状态行/描述的记账更新外，所有复制文件与源文件逐字节
一致；未改任何常量、函数、布局与测试内容。

## 3. 验收（名字集对照）

rig：二盒 `/content/slaengine-rig/` 口径——脚本内实测 sci `83c61d43`、
sla `e3d2023a`、sa 0.1.8（`source /content/tools/env.sh`，
SA_PLUGIN_DEV=1）；跑前清 `.sla-cache`/`.sa-cache`。基线 = 盒上 sa_all
同头检出复制出的**原生兄弟布局**（3dengines 与 wgpu 兄弟并置，import
按源树原样解析）；入仓 = 本批填充树（tar sha256 `665a388b…` 双侧一致）。
口径：`sa test <file>`（该家族 README 定版口径），逐项 [PASS]/[FAIL]
名集对照。原始日志在二盒 `/content/slaengine-fill/*.log`。

| 测试 | 基线（源布局） | 入仓后 | 判定 |
|---|---|---|---|
| sa3d_sidecar_layout_test.sa（→ sla_webgl） | rc=0，2 PASS / 0 FAIL | rc=0，2 PASS / 0 FAIL，同名集 | **失败名集 ∅ = ∅，相等 ✓** |
| wgpu_layout_test.sa（→ sla_gpu 依赖库） | rc=0，4 PASS / 0 FAIL | rc=0，4 PASS / 0 FAIL，名集逐字相同（wgpu draw desc validation / render pipeline desc validation / render pipeline desc accepts multisample counts / shader desc validation） | **相等 ✓** |
| 3d_render_wgpu_layout_test.sa（→ sla_gpu 本体） | rc=0，**16 PASS / 0 FAIL**（名集全文存 base_render.log） | rc=1，`error: PackageNotResolved`（import 解析期整体失败、无测试名集产出） | **已复制未验证（仓内）**——见 §4 登记与诊断实证 |

## 4. 未验证登记（唯一一条）

**对象**：`crates/sla_gpu/src/3d_render_wgpu.sal` 及其测试。
**状态**：已复制未验证（仓内）。基线在其原生布局下 16/16 全绿（§3），
存量本身无恙。
**卡点（精确定位）**：该文件第二条 import
`@import "../sa_plugin_3d_shader/3d_shader.sal"` 指向 PLAN 明文不移植的
`sa_plugin_3d_shader`（仅用其 `SA3D_SHADER_ENTRY_*` 布局常量；shader
真理归 slasl）。填充纪律不许把被排除模块复制入仓、也不许改写 import
去向，故该边在仓内悬空，`sa test` 于包解析期报 PackageNotResolved。
**诊断实证**：在二盒诊断副本（`$F/diag`，非填充内容）中仅把源树原版
`3d_shader.sal` 放到该悬空路径，其余与入仓树逐字相同，复跑即
rc=0、16 PASS / 0 FAIL——证明仓内唯一卡点就是这一条边，归一后的
wgpu 边与本体内容均无恙。
**后续选项（归 P2 改造批裁量，本批不预断）**：① 按 PLAN「布局作绑定层
参考」在 sla_gpu 绑定层重表达该组 layout 常量；② 改由 slasl 产物面
提供 shader entry 布局。二者皆属改造，不属填充。

## 5. 其他说明

- sla_webgl 存量现仍为 WebGPU 目标（sa3d.sai 的导入面即 WebGPU
  sidecar 面）——这是 PLAN 处置 ② 的既定形态（一期以其机制改造为
  WebGL），本批只落存量、未做目标改造，crate.toml 与 SOURCES.md 均已
  明示，不得读作「WebGL 后端已就绪」。
- 语言总则对账：两座主体为 `.sal`/`.sai`/`.js` 存量；Zig 件仅
  `sa3d_airlock_gen.zig` 一件，按辅助面（.sai 之后）登记于
  sla_webgl/SOURCES.md。
- 本批未动 workspace.toml 成员表（座位地基线已立），未动伞层与
  slasl/sax3d 两 crate。
- 盒上工件：`/content/slaengine-fill/`（src-env 基线副本、crate-run
  入仓副本、diag 诊断副本、各 `*.log` 与 `run_fill_accept.sh`）；
  本机工件：`~/workspace/fill-crates.tar`、`~/workspace/run_fill_accept.sh`。

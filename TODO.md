# slaengine TODO — 参考普查可吸收点（执行待办）

> 来源：2026-11-01 参考普查线。研读对象为八个公开仓的浅克隆实物
> （`~/workspace/slaengine-refs/`），每条吸收点都带归宿 crate、归期、
> 形态与仓内出处路径，结论以克隆实物为准。与普查总案
> （`~/workspace/slaengine-survey/PLAN.md`）互补：PLAN 已定版的面
> （sla_ecs 嵌入、App 映射、3dengines 移植裁定、打通清单 C1–C8）
> 不在此重复，本文件只收新增量。
>
> **判读口径（用户 2026-11-01 11:21 定）**：代码方式尽量与 Bevy 1:1
> （API 表面/调用形态/命名对齐）；内核按我们的情况调整，取对我们
> 最有利、开发速度最快的方法，不全盘复制。吸收点优先取「表面与
> 组织」；机制层逐项过「对我们是否最快/最稳」这一关，过不了的标
> 「表面吸收、内核自研」。归期口径：P1 = WebGL 期、P2 = GPU 期、
> P3 = 深化期、「观察」= 仅登记、不排期。

## 研读基线（克隆实测，2026-11-01）

| 仓 | 克隆头 | 体积 | 检出形态 |
|---|---|---|---|
| three.js（mrdoob/three.js） | `fa01dd6a` | 28M | blobless 稀疏：`src`、`examples/jsm` |
| bevy（bevyengine/bevy） | `ae615215` | 40M | blobless 稀疏：`crates` |
| gpu-curtains（martinlaxenaire/gpu-curtains） | `1543af89` | 3.1M | blobless 稀疏：`src` |
| playcanvas（playcanvas/engine） | `4b496a2a` | 17M | blobless 稀疏：`src` |
| babylon.js（BabylonJS/Babylon.js） | `1b26881f` | 52M | blobless 稀疏：`packages/dev/core`、`packages/dev/loaders` |
| blender（blender/blender，第六研读面） | `67c9bddd` | 35M | blobless 稀疏：`source/blender/draw`、`gpu`、`nodes` |
| armory（armory3d/armory） | `0eda113e`，尖端提交 **2026-10-30**（活跃） | 600K | blobless 稀疏：`armory`、`armorcore`、`api` |
| iron（armory3d/iron，Armory 渲染库） | `0456d3eb`，尖端提交 2024-11-22 | 836K | blobless 稀疏：`Sources` |

注：普通全量浅克隆经本机网关三度断连，改以 `--filter=blob:none`
稀疏检出落地，内容为对应子树全量、非摘录。

---

## 1. Bevy（bevyengine/bevy）— 表面 1:1 的主参照

ECS 本体与 App 基础映射已由 PLAN §2/§3 定版，此处只列 PLAN 之外、
超出 ecs 的部分。

- [ ] **SubApp / RenderApp 形态**（P2 决策输入）：主 App 挂具名子
  App（各自 World），渲染子 App 经 Extract 时间表从主 World 提取。
  P2 裁 RenderWorld 双世界时以此为表面原型——子 App 的注册与提取
  调度表面 1:1，提取内核按我们 C7 帧包形态自研。
  归宿：伞 crate App 层 + sla_gpu｜归期：P2｜形态：表面吸收、内核自研
  出处：`crates/bevy_app/src/sub_app.rs`、`crates/bevy_render/src/lib.rs`
- [ ] **RenderSystems 阶段枚举**：渲染子 App 内的阶段序（Extract →
  Prepare → Queue → WriteBindGroup 类的细分集合枚举）作为
  sla_gpu 渲染调度的标签词表原型，与伞层六标签同法管理。
  归宿：sla_gpu｜归期：P2｜形态：直接借鉴设计
  出处：`crates/bevy_render/src/lib.rs`（`pub enum RenderSystems`）
- [ ] **渲染资产提取面**：`RenderAsset` / `ErasedRenderAsset` 与
  extract→prepare 两段式（主 World 资产 → GPU 资产的准备阶段独立
  成段）——C7 帧包在 P2 扩为资产级提取时的组织原型；类型擦除的
  Rust 机制不搬，归 sla_ecs 描述符面承载。
  归宿：sla_webgl / sla_gpu｜归期：P1（帧包）/ P2（资产级）｜形态：表面吸收、内核自研
  出处：`crates/bevy_render/src/render_asset.rs`、`erased_render_asset.rs`、`crates/bevy_extract/`
- [ ] **Material 表面**：材质 = 一组 shader 引用（vertex/fragment/
  prepass/deferred 变体槽）+ `specialize` 钩子（按管线需求改描述符）
  + 绑定组布局声明。我们的材质面表面照此组织；shader 引用落
  slasl 产物名（按名解析，守 keep_name_only），specialize 落为
  描述符级钩子函数指针。
  归宿：sla_3d（material/pbr）｜归期：P1｜形态：表面吸收、内核自研
  出处：`crates/bevy_pbr/src/material.rs`（`pub trait Material`、`fn specialize`）
- [ ] **管线特化缓存键**：渲染管线按（材质 specialize 输出 × 网格
  布局 × 目标格式）组键缓存——与 three.js 程序缓存键（§2）互证，
  两后端共用此纪律，键的构成在 sla_webgl 首光时定版。
  归宿：sla_webgl / sla_gpu｜归期：P1｜形态：直接借鉴设计
  出处：`crates/bevy_render/src/render_resource/`、`crates/bevy_pbr/src/material.rs`
- [ ] **AssetServer 表面**：`load(path) -> Handle`、加载状态查询、
  资产事件（Added/Modified/Removed）、文件夹批量加载——sla_asset
  的运行时加载面表面 1:1；路径与句柄内核走 SAX3D 解析产物契约。
  归宿：sla_asset｜归期：P1｜形态：表面吸收、内核自研
  出处：`crates/bevy_asset/src/server/mod.rs`、`event.rs`、`folder.rs`、`handle.rs`
- [ ] **资产元数据 + 加工管线**：每资产一份 `.meta`（导入参数与
  处理器选择）+ processor 加工级（源资产 → 平台产物，带缓存与
  变更检测）。我们的对应物 = sax3d 转换器 + slasl 编译的「资产期
  加工」定位：借其 meta 驱动与缓存失效的组织，加工本体不新造。
  归宿：sla_asset + sax3d（工具面）｜归期：P1/P3｜形态：表面吸收、内核自研
  出处：`crates/bevy_asset/src/meta.rs`、`processor/`、`io/`
- [ ] **资产热重载的观察者形态**：io 层文件监视 → Modified 事件 →
  消费者自动换新。Web 目标下监视源不同（无本地 fs watch），P1 只
  落事件面与手动重载入口，监视机制候 P3 随部署形态定。
  归宿：sla_asset｜归期：P3｜形态：表面吸收
  出处：`crates/bevy_asset/src/io/`、`event.rs`
- [ ] **核心管线 pass 组织**：core_3d 的阶段划分（prepass → 主
  pass → tonemapping → upscaling → 后处理）与 fullscreen material
  的「全屏材质即后处理单元」形态，作为 sla_gpu pass 链词表；
  P1 WebGL 先落 tonemapping 输出一段（与 Eevee film 面互证，§6）。
  归宿：sla_gpu（P1 先行一段入 sla_webgl）｜归期：P1/P2｜形态：直接借鉴设计
  出处：`crates/bevy_core_pipeline/src/`（`core_3d/`、`prepass/`、`tonemapping/`、`fullscreen_material.rs`）、`crates/bevy_post_process/`、`crates/bevy_anti_alias/`
- [ ] **Scene 序列化形态**：DynamicScene（以类型注册表把实体/组件
  写成可往返的场景数据）+ scene_patch 增量面。我们的场景往返已
  有 SAX3D scene 声明为格式真理，此处只借「以 reflect 注册表驱动
  场景实例化/补丁」的运行时组织，落 sla_ecs reflect 组消费者。
  归宿：sla_ecs（reflect 组）+ sla_asset｜归期：P3｜形态：表面吸收、内核自研
  出处：`crates/bevy_scene/src/`（`scene.rs`、`resolved_scene.rs`、`scene_patch.rs`）
- [ ] **Runner 模式枚举**：ScheduleRunner 的 Once / Loop{wait}
  两态与「runner 是可换插件」的表面——伞层 runner 接口（PLAN §3
  已定 RAF/run-once/fixed-step 三内建）按此枚举形态收口。
  归宿：伞 crate App 层｜归期：P1｜形态：直接借鉴设计
  出处：`crates/bevy_app/src/schedule_runner.rs`（`pub enum RunMode`）
- [ ] **PluginGroup 依赖与顺序的声明面**：插件组以有序表 + 插件
  自述（name/finish/cleanup）组织（PLAN §3 已定机制），补一条：
  组内插件可声明「在 X 之后/之前」的排序约束面，注册时校验成环
  响亮拒绝。机制仍为函数指针+描述符。
  归宿：伞 crate App 层｜归期：P1｜形态：表面吸收、内核自研
  出处：`crates/bevy_app/src/plugin_group.rs`、`plugin.rs`
- [ ] **bevy_shader 的管线缓存与导入面**：shader 以句柄资产管理 +
  编译缓存（shader_cache）。我们的 shader 资产真理在 slasl 产物，
  只借「产物按名/键缓存、变更即失效」的运行时组织。
  归宿：sla_webgl / sla_gpu｜归期：P1｜形态：表面吸收
  出处：`crates/bevy_shader/src/shader_cache.rs`、`shader.rs`

## 2. three.js（mrdoob/three.js）— WebGL 渲染器工程纪律

- [ ] **程序缓存键纪律**：`WebGLPrograms.getParameters` 把（材质 ×
  灯光 × 阴影 × 场景 × 对象）收成参数集、再哈希成 programCacheKey
  决定程序复用——sla_webgl 的程序缓存按此「参数集 → 键」两段式
  定版，与 Bevy 特化键（§1）合并成一条共用纪律。
  归宿：sla_webgl｜归期：P1｜形态：直接借鉴设计
  出处：`src/renderers/webgl/WebGLPrograms.js`（`getParameters`、programCacheKey）
- [ ] **渲染列表排序律**：不透明前→后（省 overdraw）、透明后→前、
  以 groupOrder/renderOrder/material id 分桶——sla_webgl 首光的
  队列排序直接采用此律，落 C7 帧包的排序段。
  归宿：sla_webgl｜归期：P1｜形态：直接借鉴设计
  出处：`src/renderers/webgl/WebGLRenderLists.js`
- [ ] **按关注点拆分的资源管理面**：渲染器内部按 Attributes /
  Geometries / Textures / Objects / Lights / ShadowMap / State
  分册管理 GPU 资源与状态缓存——sla_webgl 内部模块划分照此分册，
  每册自管缓存与失效。
  归宿：sla_webgl｜归期：P1｜形态：直接借鉴设计（组织）
  出处：`src/renderers/webgl/`（`WebGLAttributes.js`、`WebGLGeometries.js`、`WebGLTextures.js`、`WebGLState.js` 等）
- [ ] **PMREM 环境预滤**：任意环境贴图 → PMREM 立方体多级预滤，
  供 PBR 环境光统一消费——sla_3d 环境光的资产期预处理形态；
  与 Eevee lightprobe 面（§6）在 P2 汇合，P1 先落 PMREM 式预滤。
  归宿：sla_3d（image/material）+ sla_asset（加工级）｜归期：P1｜形态：按 SLA 形态改造后吸收
  出处：`src/extras/PMREMGenerator.js`
- [ ] **TSL/节点材质的「一图两后端」立场**（仅立场、非机制）：
  three 以节点图同时生成 WebGL/WebGPU 两后端的材质代码，与
  slasl「一份源码多目标」同构——作为 slasl 材质层方向的外部佐证
  登记，不引入其节点机制（我们的节点图衔接点是 Blender，见 §6）。
  归宿：slasl｜归期：观察｜形态：仅登记观察
  出处：`src/nodes/`、`src/Three.TSL.js`
- [ ] **ShaderChunk 命名片段库**（组织吸收）：three 的 GLSL 以命名
  chunk 文本拼装（ShaderChunk/ShaderLib）。**不吸收其文本拼装
  机制**（shader 真理在 slasl）；可吸收的是「标准片段按名编目」
  的组织——对应 slasl 标准宏库/片段库的编目方式。
  归宿：slasl｜归期：P1｜形态：表面吸收（编目组织）、机制不吸收
  出处：`src/renderers/shaders/ShaderChunk.js`、`ShaderLib.js`
- [ ] **动画混合器组织**：AnimationMixer 以 PropertyBinding 把
  clip 轨道绑到对象属性、Mixer 统一推进+权重混合——sla_3d
  animation 模块（批 B 迁入中）的运行时组织参照；clip 数据真理
  在 SAX3D clip 声明。
  归宿：sla_3d（animation）｜归期：P1｜形态：表面吸收、内核自研
  出处：`src/animation/`（`AnimationMixer.js`、`PropertyMixer.js`、`AnimationClip.js`）

## 3. gpu-curtains（martinlaxenaire/gpu-curtains）— WebGPU 极简面的人体工学

- [ ] **以 WebGPU 自身名词为模块词表**：core 按 bindGroups /
  bindings / buffers / pipelines / renderPasses / computePasses /
  samplers / textures / shaders 分册——sla_gpu 的内部词表照此
  对齐 WebGPU 概念（与我们 F3「自带 wasm 导入面直绑」同向：面
  越贴 API 名词，宿主差异越局部）。
  归宿：sla_gpu｜归期：P2｜形态：直接借鉴设计（组织）
  出处：`src/core/` 目录树
- [ ] **管线条目 + cacheKey 显式化**：PipelineEntry 携带显式
  cacheKey、PipelineManager 按键管理 render/compute 两类条目；
  sla_gpu 管线缓存沿用「条目 + 显式键」形态（键构成与 §1/§2 的
  特化键纪律合并定版）。
  归宿：sla_gpu｜归期：P2｜形态：直接借鉴设计
  出处：`src/core/pipelines/PipelineEntry.ts`、`RenderPipelineEntry.ts`、`ComputePipelineEntry.ts`、`PipelineManager.ts`
- [ ] **RenderPass / ComputePass 一等对象**：pass 是可创建、可
  复用、可挂多 mesh 的对象而非渲染器内部步骤——sla_gpu 的 pass
  面表面照此；P1 WebGL 侧的 C7 帧包阶段命名与之保持可对照。
  归宿：sla_gpu（命名对照及 sla_webgl）｜归期：P2｜形态：表面吸收
  出处：`src/core/renderPasses/`、`src/core/computePasses/`
- [ ] **场景渲染器与资源所有权**：GPURenderer 统一持有 device
  级资源、Scene 只持内容、渲染以 scene 为单位提交——与我们
  「后端 crate 持设备资源、World 持内容」的分工同构，作 sla_gpu
  所有权划分的对照样本（尤其纹理/采样器的缓存归属）。
  归宿：sla_gpu｜归期：P2｜形态：表面吸收、内核自研
  出处：`src/core/renderers/`、`src/core/scenes/`、`src/core/textures/`、`src/core/samplers/`
- [ ] **DOM 元素纹理化**（curtains 本行特色）：HTML 元素 → 纹理
  平面。我们是 ECS-first、无 DOM 内容面，此点不进引擎；仅登记
  为 Web 部署时 UI 覆盖层的一种外部做法观察。
  归宿：—｜归期：观察｜形态：仅登记观察
  出处：`src/curtains/`、README（DOM 2 WebGPU 定位）

## 4. PlayCanvas（playcanvas/engine）— 资产注册表与编辑器契约文化

- [ ] **AssetRegistry 组织**：资产以（id、name、type、tags）注册、
  按类型分 handler 加载、AssetListLoader 批量预载、asset-reference
  以引用对象延迟解析——sla_asset 注册表面的组织原型（与 Bevy
  AssetServer 表面互补：Bevy 给句柄面、PC 给注册表/引用面）。
  归宿：sla_asset｜归期：P1｜形态：表面吸收、内核自研
  出处：`src/framework/asset/`（`asset-registry.js`、`asset.js`、`asset-list-loader.js`、`asset-reference.js`、`handlers/`）
- [ ] **单一 GraphicsDevice、双后端**：同一 scene 代码跑
  WebGL/WebGPU 两 device 实现，device 能力以特性面查询——我们
  两后端（sla_webgl/sla_gpu）之上给 sla_3d 的「能力查询面」组织
  参照；后端本体仍各自自带导入面（F3 口径不变）。
  归宿：sla_3d（能力面）+ 两后端｜归期：P1/P2｜形态：表面吸收（组织）
  出处：`src/platform/graphics/`（`graphics-device.js`、`webgl/`、`webgpu/`、`device-cache.js`）
- [ ] **FrameGraph + 渲染层合成**：scene 以 frame-graph 组织
  pass、以 composition/layer 组织渲染层序与每层灯光/相机掩码——
  sla_gpu 的 pass 图与渲染层词表参照（与 Bevy core_pipeline 的
  pass 组织互证，二选其简者落 P2 设计）。
  归宿：sla_gpu｜归期：P2｜形态：直接借鉴设计
  出处：`src/scene/frame-graph.js`、`src/scene/composition/`、`src/scene/layer.js`
- [ ] **脚本组件的属性模式契约**：编辑器文化在引擎仓的落点 =
  script 组件以声明式 attribute schema 暴露可编辑参数，编辑器
  据此生成面板。我们的编辑器是 Blender（§6），此点转译为：
  trait/组件在 Blender 侧的属性面板由描述符 schema 生成——
  schema 形态借 PC 的声明式属性表。
  归宿：sla_ecs（描述符）+ Blender 插件面（§6）｜归期：P3｜形态：按 SLA 形态改造后吸收
  出处：`src/framework/script/`、`src/framework/components/`
- [ ] **Lightmapper 烘焙管线的位置**：PC 把光照烘焙做成引擎内
  工具面（lightmapper + scene/batching 配合）。我们的 GI 路线
  是 Eevee 探针（§6），烘焙面不另起；仅登记其「烘焙产物即普通
  贴图资产」的管线位置作对照。
  归宿：—｜归期：观察｜形态：仅登记观察
  出处：`src/framework/lightmapper/`
- [ ] **gsplat 一等场景内容**：高斯泼溅在 PC 已是 scene 一等
  公民（统一渲染路）。我们的格式与管线无 splat 面，登记为
  内容类型观察项：若将来引入，先过 SAX3D 承载议题（§7 同法）。
  归宿：—｜归期：观察｜形态：仅登记观察
  出处：`src/framework/gsplat/`、`src/scene/gsplat-unified/`

## 5. Babylon.js（BabylonJS/Babylon.js）— 大型引擎的工学与调试文化

- [ ] **SceneLoader 插件注册表**：导入器以插件注册（按扩展名/
  签名分发）、loader 可插拔——sla_asset 的导入侧组织原型
  （SAX3D 为一等导入、glTF 经 sax3d 转换器，二者同表注册）。
  归宿：sla_asset｜归期：P1｜形态：表面吸收、内核自研
  出处：`packages/dev/core/src/Loading/`、`packages/dev/loaders/`
- [ ] **Node Material 的序列化节点图**：节点块图可序列化为数据、
  build 时生成双后端 shader、带 Optimizer 做图简化——与 §6
  Blender 节点图衔接同题：**节点图的真理形态是数据、生成器是
  slasl**；此点只作「图数据 + 优化级」的组织佐证登记，不引入
  第二套生成器。
  归宿：slasl（衔接点）｜归期：观察｜形态：仅登记观察（组织佐证）
  出处：`packages/dev/core/src/Materials/Node/`（`nodeMaterial.ts`、`Blocks/`、`Optimizers/`）
- [ ] **运行时仪表化面**：Instrumentation 统一采集 CPU/GPU 帧
  耗时与 draw call 计数，Debug 层据此呈现——对应用户定案
  「引擎侧至多轻量运行时调试面」：P3 落一个同等定位的仪表化
  面（采集点在两后端的提交段），呈现借 Blender 侧或独立小面。
  归宿：sla_webgl / sla_gpu + 伞 crate｜归期：P3｜形态：按 SLA 形态改造后吸收
  出处：`packages/dev/core/src/Instrumentation/`、`packages/dev/core/src/Debug/`
- [ ] **Effect 的降级链**（观察）：shader 编译失败时按 defines
  降级重试的 fallback 机制。我们的路是 slasl 目标侧静态生成、
  失败应在资产期响亮暴露，不做运行时静默降级——此点登记为
  「知悉其存在、明确不采用运行时降级」的对照，资产期等价物 =
  slasl 的目标能力矩阵（生成时按目标裁剪）。
  归宿：slasl｜归期：观察｜形态：仅登记观察
  出处：`packages/dev/core/src/Materials/effect.ts`
- [ ] **动画/骨骼的运行时分册**：Animations/Bones/Morph 三册与
  BakedVertexAnimation（把动画烘成纹理供 GPU 播放）——sla_3d
  animation 的分册参照；VAT 式烘焙播放登记为大批量角色场景的
  候选形态（数据承载走 SAX3D image+clip 既有面可表达，候 P3）。
  归宿：sla_3d（animation）｜归期：P1（分册）/ P3（VAT 候选）｜形态：表面吸收
  出处：`packages/dev/core/src/Animations/`、`Bones/`、`Morph/`、`BakedVertexAnimation/`

## 6. Blender / Eevee（第六研读面）+ 导出 + 内嵌播放器 + Armory

研读实物：blender 仓 `source/blender/draw/engines/eevee/`（现行
主线已只余 Eevee Next 一系，模块文件即架构图）、`source/blender/
gpu/`、`source/blender/nodes/shader/`；Armory 两仓（见基线表）。

### 6.1 Eevee 架构兼容吸收（渲染面主线）

目标不是输出碰巧像，而是**管线组织与渲染模式与 Eevee 兼容**：
同一场景、同一材质语义，在我们的管线里以 Eevee 的方式被组织
和求值（实现 clean-room 自研，见 §9 许可证边界）。分层为建议
口径：P1 WebGL 先吸收前向 + 探针类模式，P2 GPU 再及延迟管线 /
探针 GI 级模式；验收 = 同场景 Blender(Eevee）与引擎渲染并排
对照、差距逐项登记。

- [ ] **模块-per-关注点的引擎内部分册**：Eevee 以
  pipeline/material/light/lightprobe/shadow/hiz/renderbuffers/
  sampling/film/volume/raytrace 等单关注模块组成，每个模块带
  一份 `*_shared` 数据契约——sla_webgl/sla_gpu 的内部分册与
  「模块间只经共享数据契约通信」的纪律照此。
  归宿：sla_webgl / sla_gpu｜归期：P1 起｜形态：直接借鉴设计（组织）
  出处：`source/blender/draw/engines/eevee/`（`eevee_pipeline.*`、`eevee_material.*`、`eevee_*_shared.hh` 群）
- [ ] **前向材质求值 + 探针光照（P1 首批）**：Eevee 的前向
  shading 以「直接光逐灯求值 + 光探针提供间接光」为骨架；
  P1 的 sla_webgl 光照模型按此骨架落：直接光面 + sphere/volume
  两型探针的采样契约先行（planar 反射探针候 P2）。
  归宿：sla_webgl + sla_3d（light）｜归期：P1｜形态：按 SLA 形态改造后吸收
  出处：`eevee_light.*`、`eevee_lightprobe.*`、`eevee_lightprobe_sphere.*`、`eevee_lightprobe_volume.*`、`eevee_lightprobe_planar.*`
- [ ] **探针烘焙缓存（lightcache）**：探针数据以独立烘焙产物
  （lightcache）承载、场景引用之——资产期烘焙 + 运行时只读的
  分工与我们「资产期加工」（§1 资产加工级）同构：烘焙器落
  sax3d/sla_asset 工具面，运行时格式走 SAX3D image/blob 承载
  （承载细节候 §7 议题）。
  归宿：sla_asset + sla_webgl｜归期：P1/P2｜形态：表面吸收、内核自研
  出处：`eevee_lightcache.*`、`eevee_precompute.*`
- [ ] **阴影体系分层**：Eevee 阴影以逐灯 shadow tile/页式管理
  + Hi-Z 加速可见性为骨架。P1 先落常规级（级联/图集式）组织，
  页式管理与 raytrace 阴影候 P2 与 GPU 面一并。
  归宿：sla_webgl（P1 常规级）/ sla_gpu（P2 页式）｜归期：P1/P2｜形态：表面吸收、内核自研
  出处：`eevee_shadow.*`、`eevee_hizbuffer.*`
- [ ] **材质求值模型 = 节点图编译为 shader（与 slasl 的衔接，
  本节重点）**：Blender 的做法是节点树 → GPU 堆栈求值 → 按节点
  类型拼 `gpu_shader_material_*` 片段库生成材质 shader（片段
  一节点一文件、按名编目）。我们的同构形态：**Blender 节点图
  是材质创作真理、slasl 是生成真理**——导出器把节点图译成
  slasl 源码/接口（见 §8），片段库的编目组织落 slasl 标准库，
  不在引擎里另建文本拼装器。
  归宿：slasl + blendertosax3d 导出器（§6.2）｜归期：P1 起｜形态：表面吸收、内核自研
  出处：`source/blender/nodes/shader/node_shader_tree.cc`、`source/blender/gpu/shaders/material/gpu_shader_material_*.bsl.hh`、`source/blender/gpu/shaders/gpu_shader_codegen_lib.glsl`
- [ ] **film 级收尾：AgX 观感变换 + pass/AOV 组织**：Eevee 以
  film 段统一做显示变换（AgX 一系）与 render pass/AOV 的
  分发——sla_webgl 的输出段按此落「色彩管理是管线末段的一等
  职责」，观感变换以 AgX 为默认目标（参数/曲线自研实现）；
  AOV 分发候 P2 随延迟管线。
  归宿：sla_webgl（P1 输出段）/ sla_gpu（P2 AOV）｜归期：P1/P2｜形态：按 SLA 形态改造后吸收
  出处：`eevee_film.*`、`eevee_renderbuffers.*`、`eevee_cryptomatte.*`
- [ ] **屏幕空间效应集（P2）**：AO（GTAO 形态）、motion blur、
  depth of field、subsurface、volume 单散射近似、raytrace
  反射——Eevee 的效应清单即 sla_gpu 的 P2/P3 效应路线图，
  逐项以「同场景对照差距登记」验收，不齐头并进。
  归宿：sla_gpu｜归期：P2/P3｜形态：按 SLA 形态改造后吸收
  出处：`eevee_ambient_occlusion.*`、`eevee_motion_blur.*`、`eevee_depth_of_field.*`、`eevee_subsurface.*`、`eevee_volume.*`、`eevee_raytrace.*`
- [ ] **延迟管线与 G-buffer 契约（P2，Eevee Next 主形态）**：
  Next 的延迟合成以 renderbuffers 的 G-buffer 布局为跨模块
  契约——sla_gpu 落延迟路时以「G-buffer 布局先定版为数据
  契约、各 pass 只认契约」为纪律（与 §6.1 首条同法）。
  归宿：sla_gpu｜归期：P2｜形态：表面吸收、内核自研
  出处：`eevee_renderbuffers.*`、`eevee_gbuffer.hh`、`eevee_pipeline.*`
- [ ] **场景同步层（sync）**：Eevee 以独立 sync 模块把场景
  数据增量同步为渲染内部表示——对应我们 C7 帧包提取的增量
  化方向：P1 先全量提取，sync 式增量（变更标记 → 局部更新）
  候 P2，组织原型在此。
  归宿：sla_webgl / sla_gpu｜归期：P2｜形态：表面吸收
  出处：`eevee_sync.*`、`eevee_instance.*`、`eevee_view.*`、`eevee_world.*`

### 6.2 blendertosax3d：Blender 导出路径（部署主线一）

现状与目标：**间接路已现成可用**——Blender 原生导出 glTF →
sax3d 双向转换器（已全绿复验、转换映射表逐项有台账）入引擎；
**完整形态 = Blender 侧导出器直出 SAX3D**（场景级）。约束三条
（用户定，逐条执行）：① SAX3D SPEC 已冻结，导出器只对齐现行
SPEC，超 SPEC 的场景级需求登记为 SPEC 缺口候裁（汇总在 §7），
不许静默扩格式；② 材质到 shader 的衔接走 slasl 产物名
（keep_name_only 定版），导出器不内嵌 shader 源；③ Python 相处
问题见本节末设计点（已按内嵌播放器战略更新状态）。

资产面与现行 SPEC 的覆盖核查（核查对象 = crates/sax3d/SPEC.md
v1 冻结版，§ 号为 SPEC 节号）：

| Blender 资产面 | SPEC 覆盖 | 落点 |
|---|---|---|
| mesh（通道/索引/多 primitive/morph） | 已覆盖（§5.2：position/normal/tangent/uv0-3/color0、自定义 attr、morph 三通道增量、多 primitive 按 material） | 直出 |
| 骨骼 + 蒙皮 | 已覆盖（§5.3 skeleton + inverse_bind 段；§5.2 joints0/weights0 成对通道；scene node 的 `skin:`） | 直出 |
| 动画 clip | 已覆盖（§5.7：sampler 时间轴/输出、linear/step/cubic-spline、node 的 translation/rotation/scale/weights 四路通道） | 直出（骨骼动画经同名 node 通道，§5.3 全资产 node 名唯一即对应依据） |
| 材质 | 已覆盖为「shader 名 + 接口参数」（§5.5：param 按接口名、texture 按接口名绑定、tex_transform、渲染 state） | 直出；Principled 参数集 = slasl blender 接口表约定的型廓（§8），非格式字段 |
| 贴图 | 声明层已覆盖（§5.4：image 格式 png/jpeg/ktx2/raw、color_space 必填、texture 采样器五字段必填）；**解码不在格式层**（SPEC 明示 GAP-2） | 直出声明；解码归运行时/工具面（sla_3d image 迁入模块 + sla_asset） |
| 场景层级/变换 | 已覆盖（§5.6：node 树、TRS 或 matrix、mesh/material 覆盖、skin） | 直出 |
| **相机** | **未覆盖**（§5.6 明文：v1 无 camera 字段，F-7） | → §7 SPEC 缺口候裁 |
| **灯光** | **未覆盖**（同上，F-7） | → §7 SPEC 缺口候裁 |
| 世界/环境（背景、环境光） | 未覆盖（scene 无 world 面） | → §7 SPEC 缺口候裁 |
| 自定义属性（Blender custom properties） | 未覆盖（声明无 extras/自定义键面） | → §7 SPEC 缺口候裁 |

待办条目：

- [ ] **间接路定版为 v0 入口**：Blender → glTF → sax3d 转换器
  的链路写入导出文档与冒烟用例（含转换台账的逐项核对法），
  作为直出导出器落地前的可用路径与对照基准。
  归宿：sax3d（工具面）+ sla_asset（导入侧）｜归期：P1｜形态：直接借鉴设计（既有能力定版）
  出处：`crates/sax3d/CONVERTER_MAP.md`（映射表+台账纪律）、Armory 同为「先经中间格式」起步的路径（§6.4）
- [ ] **直出导出器（Blender 插件形态）**：遍历 depsgraph 求值后
  场景 → 按现行 SPEC 生成组装形 `.sax3d` 文本 + `.saxb3d` 段
  文件（创作形双形态一等，导出器产创作形、合并由 sax3d 工具
  完成）；mesh/材质/贴图/动画/骨骼按上表直出，相机/灯光/世界
  在 SPEC 裁定前**响亮跳过并逐项进导出台账**，不静默丢。
  归宿：Blender 插件（新仓位候定）+ sax3d（契约侧）｜归期：P1（mesh/材质/贴图）/ P2（动画全量与同步）｜形态：自研（Armory 管线为参照，§6.4）
  出处：SPEC §5 全节；参照 `armory/armory/blender/arm/exporter.py`
- [ ] **导出台账纪律**：导出器一切近似/跳过/合成名逐项入台账
  （与 sax3d 转换报告台账同法，零静默丢失），台账随导出产物
  一并落盘供 Play 回路展示（§6.3）。
  归宿：Blender 插件 + sax3d｜归期：P1｜形态：直接借鉴设计
  出处：`crates/sax3d/CONVERTER_MAP.md` §0 总规则
- [ ] **材质衔接**：Blender 材质节点图 → slasl 的生成与命名
  （材质在 SAX3D 里只记 shader 名 + 接口参数，参数名对 slasl
  blender 接口表逐名复核——与 sla_asset 的 C4/C5 校验同法）。
  细目全部落 §8，此处只立衔接点。
  归宿：slasl + 导出器｜归期：P1｜形态：—
  出处：SPEC §5.5、§6.4（keep_name_only 定版）

**设计点（已确认）**——Python 相处：
内嵌播放器战略（§6.3）已给出默认解形：Blender 侧插件的薄胶水
（导出触发、Play/Stop、面板）以 Python 写（Blender 宿主 API
决定、属 Blender 侧代码），重逻辑（格式生成、校验、材质图
编译）一律在引擎侧/sax3d/slasl 工具面；插件 Python 只做数据
搬运与调用。状态 = **已确认采纳（2026-11-01 主会话确认）**：
Blender 插件薄胶水以 Python 写、重逻辑在引擎侧，此后按此执行。

### 6.3 内嵌播放器：以 Blender 为编辑器（部署主线二，用户 11:27 定）

战略：**slaengine 直接内嵌 Blender 作 player view（类 Unreal/
Unity 的 Play 模式）；编辑器就是 Blender，我们不重写重型
editor**（边界见 §9）。形态 = Blender 侧插件（导出 + 播放
胶水）+ 引擎运行时内嵌。工作项群：

- [ ] **Play/Stop 生命周期**：插件提供 Play（导出当前场景 →
  在引擎运行时起 App → 呈现）/ Stop（回收运行时、回编辑态）
  的操作面；引擎侧对应一个「播放会话」资源与确定的启停序
  （与伞层 runner 的 run-once/loop 形态衔接）。
  归宿：Blender 插件 + 伞 crate（会话面）｜归期：P1｜形态：自研（Armory make/play 回路为参照）
  出处：参照 `armory/armory/blender/arm/make.py`（`play()`、`build()`、`export_data()`）
- [ ] **场景同步口径（分层建议）**：先 **export-on-play**（每次
  Play 全量导出、靠导出增量缓存压时延，见 §6.4 Armory 缓存
  条目）；**实时同步**（编辑变更增量推送到运行中会话）候后，
  其协议形态（全量重导出 vs 增量补丁）登记为设计点候选。
  归宿：Blender 插件 + sla_asset｜归期：P1（export-on-play）/ P3（实时同步候选）｜形态：—
  出处：参照 `armory/armory/blender/arm/live_patch.py`（运行中热补丁的既有形态）
- [ ] **视口嵌入路线（设计点候选，先登记不裁定）**：(a) 引擎
  在 Blender 视口内绘制（与编辑器渲染共面、体验最整，代价 =
  与 Blender 绘制/ GPU 上下文耦合最深）；(b) 独立窗口呈现
  （解耦最净、实现最快，代价 = 双窗口体验）；(c) 离屏渲染回传
  贴图进视口（居中，代价 = 一帧拷贝与输入转发层）。三路各自
  代价如注，候主会话裁定后立项。
  归宿：Blender 插件 + sla_webgl/sla_gpu（呈现面）｜归期：候裁｜形态：设计点登记
  出处：先例形态见 §6.4（Armory 经 Kha/Krom 独立呈现；UPBGE 为视口内形态——两路均有既有实证）
- [ ] **引擎侧轻量运行时调试面**（上限已定）：播放会话内只做
  运行时调试（帧耗时/draw 计数/实体查看的最小面，与 §5 仪表
  化条目同批），不长编辑器功能；一切编辑能力借 Blender。
  归宿：伞 crate + 两后端｜归期：P3｜形态：按 SLA 形态改造后吸收
  出处：用户 11:27 定案；仪表化参照 §5 Babylon 条目

### 6.4 Armory 研读面（armory3d/armory + iron）

活跃状态（实测落字）：**armory 本仓活跃**——尖端提交 2026-10-30
（克隆当日两天前）；其渲染库 **iron 尖端提交停在 2024-11-22**
（近一年未动）。「Armory 没更新了」的印象与实测不符，作废；
iron 的静止是分仓维护形态的实测事实，按下方中性条目处理。

第一研读对象 = **Blender 场景导出管线**（`armory/armory/
blender/arm/exporter.py`，3,869 行，`ArmoryExporter`）：

- [ ] **遍历形态**：以 depsgraph 求值结果为准遍历（`export_
  scene(context, filepath, scene, depsgraph, build_cache)`），
  对象递归 `export_object` 携父链下行、按数据类型分发
  （mesh/light/camera/probe/collection 各有专函数）——
  blendertosax3d 的遍历骨架照此：求值后数据为准（修改器/
  几何节点的结果即导出结果）、分发按域拆函数。
  归宿：Blender 插件（导出器）｜归期：P1｜形态：直接借鉴设计
  出处：`armory/armory/blender/arm/exporter.py:195`（export_scene）、`:910`（export_object）、`:2251`（export_collection）
- [ ] **中间格式形态**：Armory 导出为自有二进制 `.arm`（可
  `.lz4` 压缩）。我们的中间格式即 SAX3D 本身（创作形文本可
  审、合并形紧凑），不新造格式——此条目只确认取舍：Armory 的
  教训是自有格式与引擎同仓演进最快，但其格式无独立 SPEC 与
  校验器面；我们已有冻结 SPEC + 校验器 + 双向转换器，守之。
  归宿：sax3d｜归期：P1｜形态：仅登记（取舍确认）
  出处：`armory/armory/blender/arm/exporter.py:235`（`.arm`/`.lz4` 出口）
- [ ] **增量导出缓存（export-on-play 时延的关键）**：`Build
  ExportCache` 在一次 build 内跨场景共享，以「已导出 mesh/
  action 文件集 + 已处理 mesh 名集」跳过重复导出——我们
  export-on-play 的时延纪律照此：导出器维护内容寻址的已导出
  集（按数据块名+内容戳），Play 时只重导变更块；大场景全量
  耗时以实测登记为验收项。
  归宿：Blender 插件（导出器）｜归期：P1｜形态：直接借鉴设计
  出处：`armory/armory/blender/arm/exporter.py:108`（`class BuildExportCache`）
- [ ] **分域转换的取舍表**：Armory 逐域专函数即一份现成的
  「Blender 构造 → 引擎数据」取舍清单：export_mesh_data
  （求值网格直读）、export_skin / export_shape_keys（蒙皮/
  形态键独立通道）、export_animation_track（FCurve → 轨道，
  含 pose markers）、export_light / export_probe / export_
  camera、export_traits。blendertosax3d 的分域清单以此为
  底稿逐项对 SPEC 覆盖表（§6.2）复核，Armory 有而 SPEC 无的
  （相机/灯光/探针/speaker 等）自动汇入 §7 候裁清单。
  归宿：Blender 插件 + sax3d｜归期：P1｜形态：直接借鉴设计（清单法）
  出处：`armory/armory/blender/arm/exporter.py`（`:1740` mesh、`:1403` skin、`:1500` shape keys、`:379` animation track、`:2153` light、`:2238` probe、`:2349` camera、`:3411` traits）
- [ ] **trait 挂载形态**：Blender 侧以属性组把「trait 类名 +
  参数」挂到对象/场景（props_traits），引擎侧 trait 类按名
  实例化——对应我们的组件挂载：Blender 自定义属性/属性组
  承载「组件名 + 参数」，实例化归 sla_ecs 描述符注册表；
  参数 schema 面与 §4 PC 属性模式条目同批设计。
  归宿：Blender 插件 + sla_ecs｜归期：P2｜形态：按 SLA 形态改造后吸收
  出处：`armory/armory/blender/arm/exporter.py:3411`（export_traits）、`arm/props_traits.py`、`armory/Sources/armory/trait/`
- [ ] **逻辑节点系统（观察）**：Armory 以 Blender 节点编辑器
  定义逻辑图（arm/logicnode 按域分册数百节点）、编译为引擎
  trait 代码（make_logic）——形态与材质节点图同构（编辑在
  Blender、数据是图、引擎侧生成）。我们的逻辑面真理在 SLA
  代码 + ECS 系统，此点不吸收为机制；登记为「若将来要可视化
  逻辑，Blender 节点面是现成编辑壳」的观察。
  归宿：—｜归期：观察｜形态：仅登记观察
  出处：`armory/armory/blender/arm/logicnode/`、`arm/make_logic.py`、`armory/Sources/armory/logicnode/`
- [ ] **Play 回路的构成**：make.py 的 build 流水线 = 导出数据
  → 生成 renderpath/world 代码 → 编译 → 启动（Krom/浏览器
  目标）；live_patch 在运行中会话上做热补丁。我们的回路
  对应物：导出（SAX3D）→ sla_asset 入 World → App 会话；
  「生成代码」一步在我们这里是 slasl 编译 + SAX3D 合并，
  均为既有工具面，不新造构建系统。
  归宿：Blender 插件 + 伞 crate｜归期：P1｜形态：表面吸收、内核自研
  出处：`armory/armory/blender/arm/make.py`、`make_renderpath.py`、`make_world.py`、`live_patch.py`
- [ ] **持续维护做法（中性借鉴）**：Armory 把插件、引擎源码、
  shader 库收在一个仓内同批演进（armory/ 下 blender+Sources+
  Shaders 同仓），Blender API 变更时一处适配——我们的对应
  纪律：Blender 插件与 slaengine 同仓演进（插件仓位候定后
  并入 workspace 管理面），Blender 版本适配面收敛在插件
  薄层内、引擎侧零感知。此条与「薄胶水」设计点互证。
  归宿：Blender 插件（仓位）｜归期：P1｜形态：直接借鉴设计（组织）
  出处：`armory/` 仓布局（`armory/blender` + `armory/Sources` + `armory/Shaders` 同仓）、尖端提交 2026-10-30 实测
- [ ] **生态依赖的形态（有实据的风险登记）**：Armory 的运行
  时建立在同组织分仓的 Kha（仓内为子模块）与 iron 之上，
  iron 尖端提交 2024-11-22 后未再推进——分仓依赖的演进节奏
  不受本仓控制，是其实测可见的结构性风险。我们的对策已在
  定案内：引擎依赖面只有 sa_std（同生态自有）+ 格式/编译器
  自有（sax3d/slasl），Blender 侧只依赖 Blender 本体 API；
  此条目作为「不引入第三方运行时依赖」的既有定案之实证注脚
  登记，不新增工作。
  归宿：—｜归期：观察｜形态：仅登记（风险注脚）
  出处：`armory/.gitmodules` 与仓根 `Kha` 子模块、`iron` 仓尖端提交日期（基线表）

## 7. 丰富 SAX3D（一等产出组 · 自 Armory 导出管线与 Blender/Eevee 研读反哺）

每条二分标注：「合 SPEC」= 合现行 v1 SPEC、属转换器/工具/
文档面，可直接丰富；「候裁」= 须 SPEC 演进，只登记为缺口
候裁项（版本议题形态），**不写成既定扩格式**，裁定前导出器
对之响亮跳过 + 台账登记（§6.2 纪律）。

### 7.1 「合 SPEC」可直接丰富（转换器/工具/文档面）

- [ ] **骨骼动画的同名对应约定成文**：SPEC §5.3 已定「全资产
node 名唯一使跨层同名对应无歧义」——把「骨骼关节 ↔ 同名
scene node、clip 通道以 node 为靶」写成导出/创作约定文档 +
转换器校验用例，骨骼动画自此有规范入口（无需动格式）。
归宿：sax3d（文档+转换器）｜归期：P1｜形态：直接丰富
出处：SPEC §5.3、§5.7；Armory `exporter.py` 的 skin 与 animation track 分开导出、运行时按名汇合的形态为参照
- [ ] **Blender 集合/实例的导出约定**：Blender Collection 与
对象实例在 SPEC 里无独立构造——约定为工具面展开（集合 →
node 子树命名规则、实例 → 导出时实体化为独立 node + 共享
mesh 声明），写进导出器约定与转换台账，格式零改动。
归宿：sax3d（导出器约定）｜归期：P1｜形态：直接丰富
出处：SPEC §5.6；Armory `exporter.py:2251`（export_collection 的实体化形态）
- [ ] **Principled 材质型廓文档**：材质在 SPEC 是「shader 名 +
接口参数」——把 Blender Principled 的参数集（base color/
metallic/roughness/alpha/normal 等）定为 slasl blender 接口
表上的**命名型廓约定**（参数名、类型、缺省、贴图绑定位），
挂在转换器/导出器的校验面，材质保真从此有逐名清单可核。
归宿：sax3d（约定文档）+ slasl（接口表侧，见 §8）｜归期：P1｜形态：直接丰富
出处：SPEC §5.5；slasl DESIGN §9.3（blender 约定的接口表同构性）
- [ ] **贴图管线约定补强**：SPEC §5.4 已定 image/texture 声明
与采样器必填——补两件工具面约定：① Blender 贴图的色彩
空间标注 → SPEC `color_space` 的必填映射表（永不猜测的
落法）；② tex_transform（§5.5）承载 Blender UV 变换的
写法规约。解码缺口（GAP-2）维持登记，归 sla_3d image 面。
归宿：sax3d（约定）+ sla_3d（image 解码）｜归期：P1｜形态：直接丰富
出处：SPEC §5.4、§5.5
- [ ] **导出保真台账的 Blender 专册**：转换台账（CONVERTER_
MAP §0）扩 Blender 专册：逐构造（修改器求值、几何节点、
约束烘焙、NLA 合并等 Blender 侧求值项）登记「导出时求值
固化」的口径与丢失边界——保真边界从此是清单而非印象。
归宿：sax3d（台账文档）｜归期：P1/P2｜形态：直接丰富
出处：`crates/sax3d/CONVERTER_MAP.md` §0；Armory 导出器以 depsgraph 求值为准的形态（§6.4）

### 7.2 「候裁」SPEC 缺口候裁项（版本演进议题，仅登记）

- [ ] **GAP-B1 相机声明**：scene/node 无相机字段（SPEC §5.6
F-7 明文排除）。候裁形态：node 下加 camera 声明（透视/正交
参数集）——Blender 导出与 Eevee 式 lookdev 都需要它，是
场景级导出的第一缺口。版本议题：v1.x 增补声明 vs v2。
归宿：sax3d（SPEC 候裁）｜归期：候裁（建议随 P1 导出批一并提请）｜形态：缺口登记
出处：SPEC §5.6（F-7）；Armory `exporter.py:2349`（export_camera 的参数集为需求样本）
- [ ] **GAP-B2 灯光声明**：同 F-7。候裁形态：node 下加 light
声明（point/spot/directional/area 四型 + 颜色/能量/角度集）。
归宿：sax3d（SPEC 候裁）｜归期：候裁｜形态：缺口登记
出处：SPEC §5.6（F-7）；Armory `exporter.py:2153`（export_light）
- [ ] **GAP-B3 世界/环境声明**：scene 无 world 面（背景色/环境
贴图/环境强度）——Eevee world 与探针光照的场景级入口。
候裁形态：scene 级 world 声明（背景 + 环境 image 引用）。
归宿：sax3d（SPEC 候裁）｜归期：候裁｜形态：缺口登记
出处：SPEC §5.6；`eevee_world.*`（§6.1）
- [ ] **GAP-B4 探针烘焙产物承载**：lightcache 类烘焙产物
（探针网格 + 辐射数据）在现行段词表里只能借 image/blob
段权宜承载，无语义声明。候裁形态：probe 声明（网格参数 +
数据段引用）或维持 blob 权宜 + 约定文档，二选一候裁。
归宿：sax3d（SPEC 候裁）｜归期：候裁（P2 探针 GI 前）｜形态：缺口登记
出处：SPEC §4.3 段词表；`eevee_lightcache.*`（§6.1）
- [ ] **GAP-B5 自定义属性面**：Blender custom properties 与
trait 参数（§6.4）无处落。候裁形态：声明级 `props` 键值
面（类型限标量/字符串/数组）——与 trait 挂载设计同批裁。
归宿：sax3d（SPEC 候裁）｜归期：候裁｜形态：缺口登记
出处：SPEC §5（顶层声明封闭词表无此面）；Armory `props_traits.py`（需求样本）

## 8. 丰富 SLASL（一等产出组 · 自 Armory 材质转 shader 与 Eevee 求值模型反哺）

slasl 现行口径：blender 是既定目标之一（DESIGN §9.3：glsl 方言
变体 + Blender 约定层、info 声明与接口表同构、增量最轻），本
组是把该目标从「约定层」补强到「材质节点生成面」的清单。

- [ ] **节点覆盖矩阵（第一件）**：以 Blender 材质节点全集为
行、slasl blender 目标的等价构造为列，逐节点标（已覆盖/
近似+偏差/未覆盖响亮拒绝）——矩阵即 blender 约定的验收
清单；底稿参照两处实物：Blender 官方片段库（一节点一文件
的编目）与 Armory 的分类转换表（按节点类别分文件转换）。
归宿：slasl｜归期：P1｜形态：直接丰富（清单+生成面）
出处：`source/blender/gpu/shaders/material/gpu_shader_material_*.bsl.hh`；`armory/armory/blender/arm/material/cycles_nodes/`（nodes_color/converter/input/shader/texture/vector 六册）、`material/cycles.py`
- [ ] **节点图摄入面**：导出器（或独立工具）把 Blender 节点图
译为 slasl 源码的摄入路径定形：节点图是数据、slasl 是生成
真理——摄入器只做图 → slasl AST/源码的翻译，不在 Blender
侧直接拼 GLSL（与 Armory 在 Python 侧拼 shader 数据的做法
分野：我们的拼装归 slasl，守单一真理）。
归宿：slasl（摄入工具面）+ 导出器｜归期：P1/P2｜形态：自研（形态借鉴）
出处：Armory 反例形态 `armory/armory/blender/arm/material/make_shader.py`、`cycles.py`；我方口径见 §6.1 材质求值条目
- [ ] **Principled 一等构造**：Principled BSDF 落为 slasl
blender 约定的标准材质构造（参数集与 §7.1 型廓文档同表），
各后端（es300/es100/wgsl…）由 slasl 统一生成——「近 Eevee」
的材质保真以此构造的逐参数对照为验收单元。
归宿：slasl｜归期：P1｜形态：直接丰富
出处：`eevee_material.*`（求值组织）；参数集对照 Blender `gpu_shader_material_principled` 一系片段（gpu/shaders/material/）
- [ ] **探针采样构造**：sphere/volume(/planar) 探针采样落为
slasl 标准库构造（与 §6.1 探针光照条目同批），使 Eevee 式
间接光在 WebGL 目标上可生成、P2 在 WGSL 目标同名同义。
归宿：slasl（标准库）｜归期：P1（sphere/volume）/ P2（planar）｜形态：直接丰富
出处：`eevee_lightprobe_sphere.*`、`eevee_lightprobe_volume.*`、`eevee_lightprobe_planar.*`（求值模型参照、实现自研）
- [ ] **AgX 观感变换构造**：AgX 显示变换落为 slasl 后处理/
tonemap 标准构造（与 §6.1 film 条目同批），参数（对比度档
等）按接口表暴露；实现为自研曲线拟合，不搬 Blender 代码。
归宿：slasl（标准库）｜归期：P1｜形态：直接丰富
出处：`eevee_film.*`（管线落点参照）
- [ ] **屏幕空间效应构造集（P2/P3）**：GTAO、SSR、体积单散
射、subsurface 近似逐个落为 slasl 库构造（每构造带目标
能力需求声明，WebGL 目标不可达者响亮拒绝而非静默降质）——
与 §6.1 效应路线图一一对应，此处是生成面清单。
归宿：slasl（标准库）｜归期：P2/P3｜形态：直接丰富
出处：`eevee_ambient_occlusion.*`、`eevee_raytrace.*`、`eevee_volume.*`、`eevee_subsurface.*`
- [ ] **延迟/G-buffer 接口构造（P2）**：Eevee Next 的 G-buffer
打包布局落为 slasl 的接口构造（材质侧写 G-buffer 的标准
出口），与 sla_gpu 的 renderbuffers 契约（§6.1）同表定版。
归宿：slasl + sla_gpu｜归期：P2｜形态：直接丰富
出处：`eevee_gbuffer.hh`、`eevee_renderbuffers.*`
- [ ] **@global 组与 Blender UBO 约定的对齐复核**：slasl
DESIGN 已记 @global 组对应 Blender 的 UBO 声明单位——以
Eevee 的 uniform 共享契约（`eevee_uniform_shared.hh` 一系
「引擎与 shader 共享同一数据契约文件」的形态）复核我们
@global 组的字段纪律：引擎侧与 shader 侧共用一份契约声明，
不两处手抄。
归宿：slasl｜归期：P1｜形态：直接丰富（纪律复核）
出处：`source/blender/draw/engines/eevee/eevee_*_shared.hh` 群；slasl DESIGN §「结构体组」

## 9. 明确不吸收清单与边界（与定案冲突者，一律在此，不入待办）

- **Bevy 的 derive/过程宏体系**（`crates/bevy_derive/`、
`bevy_encase_derive/` 及各 crate 的宏展开面）：不吸收（用户
11:21 定：又长又臭、不学）。顶替方式逐项已定：组件/资源
注册 → 描述符注册表；系统参数注入 → system_param 适配器
函数家族；绑定组布局 → 接口表声明（slasl/sax3d 契约）。
- **第二套 ECS**：PlayCanvas 的组件-实体面、Babylon 的场景
对象模型、three.js 的 Object3D 场景图本体，均不作运行时
真理吸收——ECS 唯一本体 = sla_ecs，场景格式真理 = SAX3D；
三者的表面命名仅在无冲突处作参照（已分别登记在各节）。
- **第二套 shader 真理**：three.js 的 ShaderChunk 文本拼装、
Babylon Node Material 的图生成器、Armory 在插件侧直接生成
GLSL 的做法，均不吸收为生成机制——shader 唯一真理 =
slasl；可吸收的只有编目组织与节点覆盖清单（见 §2/§5/§8）。
- **第二套事件真理**：Babylon 的 Observable 事件原语不吸收
——事件面以 sla_ecs 既有事件机制为准。
- **Haxe/Kha 技术栈**（Armory 的实现栈）：不列吸收点（用户
定）——学其架构/管线/经验（§6.4），栈本身与我们无关；
Kha/iron 分仓依赖形态只作风险注脚。
- **Blender 源码复制**：**许可证边界**——Blender 为 GPL，
Eevee/Blender 一节吸收的全部是架构与模式，实现一律
clean-room 自研、不复制代码（本文件所有 Eevee 出处均为
架构研读引用）。其余各仓为宽松许可，吸收亦以设计/组织为
主；如将来出现代码级借用，逐项核对该仓 LICENSE 后再议。
- **自建重型 editor**：明确边界（用户 11:27 定）——编辑器
借 Blender（§6.3），引擎侧至多轻量运行时调试面；PlayCanvas/
Babylon 的编辑器/检查器文化只以「描述符 schema 生成面板」
的契约形态吸收（§4），不自建编辑器产品。
- **Cycles 作保真标杆**：明确不取（用户 11:24 定）——标杆
是 Eevee（同类实时渲染器），目标为「接近、明示可能达不到」，
不以路径追踪结果对照验收。
- **运行时静默降级**：Babylon Effect 式运行时 shader 降级链
不吸收（§5 已登记）——失败在资产期响亮暴露，是全栈纪律。

---

*本文件由参考普查线写入（未提交，候主会话处置）。条目计数
（逐节实数）：Bevy 13 / three.js 7 / gpu-curtains 5 /
PlayCanvas 6 / Babylon 5 / Blender·Eevee 节 26（Eevee 架构 9 +
导出 4 + 内嵌播放器 4 + Armory 9）/ 丰富 SAX3D 10（合 SPEC 5 +
SPEC 候裁 5）/ 丰富 SLASL 8，待办合计 80 条；明确不吸收与边界
9 类。另有登记性设计点 3 处（Python 相处默认解、视口嵌入路线、
实时同步协议形态），均标候裁未定。*

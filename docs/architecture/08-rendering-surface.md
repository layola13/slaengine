# 08 渲染面

## 8.1 引擎渲染本体（自研面，定版收束）

渲染本体是引擎自己的后端栈，与任何外部渲染库无关：

| 期 | 后端 | 形态 | 出处 |
|---|---|---|---|
| P1 | `crates/sla_webgl` | WebGL 提交面 + wasm 导入面 + JS broker（airlock 模式自 3dengines 聚合插件改造迁入）；帧路径 = PLAN C7 帧包提取（单世界） | PLAN §1/§4.3/§3.2 |
| P2 | `crates/sla_gpu` | WebGPU/Web3D 提交面（render_wgpu 改造迁入）；extract/prepare/queue 阶段按 RenderSystems 词表补齐；RenderWorld 双世界在此期裁 | PLAN §5、TODO 吸收点 |

帧路径纪律（PLAN 已定，本节重申）：提取是一个跑在渲染前
调度的 System，读 Transform/MeshHandle/MaterialHandle，写
后端帧包；帧包结构归后端 crate。接口纪律参考 OpenRealm 的
renderer 独立层 + public 头形态（04）：域层与后端之间只经
帧包契约对话，后端内部（上下文、管线缓存、绑定）不外泄。

shader 供给：slasl 是唯一生产侧——后端消费 per-target 产物
文件 + 接口表（PLAN C4），材质 specialize 等钩子落为描述符
改写（TODO 吸收点）；后端不内嵌 shader 编译。

## 8.2 three.js d.ts2sai 路线的位置（对照，非引擎渲染）

three.js 的 d.ts2sai 绑定是**呈现层路线**：用 SLA 驱动现成
的 three.js 在网页里做呈现，服务于应用/演示场景（如 CXU
前端、衡引擎的呈现层——该分工为既有定案：呈现层 three.js
管三维、JSXGraph 管二维）。它与引擎渲染本体的边界如下，
防混淆：

| 维度 | 引擎渲染本体（sla_webgl/sla_gpu） | three.js d.ts2sai（呈现路线） |
|---|---|---|
| 谁渲染 | 引擎自己的后端（SLA 帧包→WebGL/WebGPU 提交） | three.js（外部 JS 库） |
| 谁持有帧循环 | 伞 App 的 Runner + 调度 | 宿主页面/应用 |
| 资产真理 | SAX3D 声明经 sla_asset 入 World | three.js 自有场景图 |
| 用在哪 | slaengine 本体及其游戏 | slaengine **之外**的呈现型应用 |
| 进不进 workspace | 是（成员 crate） | 否（绑定产物属消费方工程） |

一句话：d.ts2sai 是「SLA 借 three.js 之手呈现」，slaengine
是「SLA 自己渲染」；前者不构成后者的前置、替代或验收面。

## 8.3 @gpu 依赖登记（D-GPU-FLOAT）

引擎自研 GPU 计算面（粒子/物理等计算型负载的设备侧执行）
依赖 @gpu 特性面，现状与口径：

- @gpu v1 已进主线，但**设备侧无浮点**（整数面）；CPU 侧
  f32/f64 不受此限。
- 浮点开门口径已定（用户 2026-11-01）：元素形先行、关 FMA
  收缩、固定舍入、归约定序、超越函数禁或标近似——逐项定
  口径后才开。
- 架构后果：计算型设计在 v1 给整数/定点形态，或明确排在
  开门之后并登记依赖；**不许**在设计里默认设备浮点可用。
- 注意区分：sla_webgl/sla_gpu 经宿主 WebGL/WebGPU API 的
  图形渲染（含其 shader 浮点）是宿主面能力，不属 @gpu
  计算面，本条不约束之。

此依赖的排期输入归主会话（编译器/@gpu 线），本集只登记
依赖关系与设计约束，不排实现。

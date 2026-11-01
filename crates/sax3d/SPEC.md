# SAX3D 格式规格 v1（冻结）

状态：**已冻结**（2026-10-31）。来源：研究线 `~/workspace/sa3d-mesh-local/DESIGN.md`
经实现校正后的定版；与设计不一致处一律以本 SPEC 为准，差异逐项登记于 §11。
命名渊源：格式名 SAX3D 纪念 SAX 的组装纪律（封闭词表、声明树、按名引用、
裁判校验、名→布局解析产物五性）；文法为 SLA 块式（Jev 裁定 F-1），非 XML。

裁定基线（不可在本版内翻动）：
- 几何真理由 SA 描述：通道元素类型即 SA 类型，二进制段是这些类型的
  SA 内存映像；全部记录布局由一份 schema 声明文件钉死（§3）。
- 引用按名为主键（F-3）：索引只是编译产物，只出现在二进制段表与合并形
  编译形组装里，创作文本中不出现。
- 逻辑通道律（F-4）：通道恒独立、紧密打包；交错/交织是消费者派生物，
  不是格式状态。
- 场景载荷 v1 仅核心（F-7）：transform/mesh/材质覆盖/skin/子节点；
  无 camera/light。
- 加载属上层（用户裁定 F-5）：sa_std 不设加载库，本工具链不交付加载器；
  本格式的义务是备齐「名→布局解析产物」契约（§4.5），加载实现自由。
- shader 是独立产物：资产只按名引用 SLASL 产物；编译期依赖的是其
  接口表产物（§9），不是源文本（§6.4 内嵌问题处置）。

## 1. 双形态（F-2 修订定版：两形一等）

同一资产的两种包装，不是两个格式。裁判对两形给出同一结论（实现上由
同一解析器双模 + 同一校验器保证，§6）。

| | 拆分形（创作形） | 合并形（交付形） |
|---|---|---|
| 构成 | 组装文本 `.sax3d` + 二进制伴随文件 `.saxb3d` | 单文件 `.sax3dp` |
| 外部引用 | mesh 二进制、`.slasl` shader、贴图文件按名/路径在外部 | 全部内嵌为段；shader 仍仅按名入册（§6.4） |
| 类比 | glTF 的 .gltf + .bin + 图片 | GLB |
| 互转 | 打包器 `sax3dc pack` 拆分→合并（§10）；合并形内容可被回读解出编译形组装（验收工具，非加载器） | |

## 2. 文件与魔数

| 用途 | 扩展名 | 魔数/首行 |
|---|---|---|
| 组装文本（创作形） | `.sax3d` | 文本，`asset <Name> version 1;` 起头 |
| 二进制伴随（拆分形） | `.saxb3d` | `SAX3DBIN`（8B） |
| 合并形单文件 | `.sax3dp` | `SAX3DPAK`（8B） |
| 段载荷文件（构建期输入约定） | `<section>.bin` | 无头裸字节（§10.2） |

## 3. Schema 单一真理源

`sax3d.sai` 是唯一布局真理：`format SAX3D; version 1 0;`，声明
`Sax3dBinHeader`、`Sax3dSectionRec`、段种类枚举与元素类型表。
`sax3dc` 的写入器、校验器、回读验收工具共用由 `tools/gen_schema.zig`
自 `.sai` 生成的同一份表 `src/schema_gen.zig`；生成器在结构尺寸与声明
不符时响亮失败。任何手抄第二份布局表都是缺陷。验收含 schema 新鲜度
对拍（重生成 == 已入库）。

## 4. 二进制布局（两形共用）

全部整数小端。偏移单位均为字节。

### 4.1 头（32B，`Sax3dBinHeader`）

| 偏移 | 字段 | 类型 | 值 |
|---|---|---|---|
| 0 | magic | u8[8] | `SAX3DBIN` / `SAX3DPAK` |
| 8 | version_major | u16 | 1（版本门：≠1 响亮拒绝） |
| 10 | version_minor | u16 | 0 |
| 12 | section_count | u32 | 段数 |
| 16 | flags | u32 | 0（v1 未定义任何 flag，非零拒绝） |
| 20 | nametab_off | u32 | 名表绝对偏移 |
| 24 | nametab_len | u32 | 名表字节长 |
| 28 | reserved | u8[4] | 0 |

### 4.2 段记录（32B/段，`Sax3dSectionRec`，头后紧排）

| 偏移 | 字段 | 类型 | 义 |
|---|---|---|---|
| 0 | name_off | u32 | 段名在名表中的绝对文件偏移 |
| 4 | kind | u32 | 段种类（§4.3） |
| 8 | offset | u64 | 段载荷绝对偏移 |
| 16 | len | u64 | 段字节长 |
| 24 | align | u32 | 载荷自然对齐要求（信息性，见下） |
| 28 | reserved | u32 | 0 |

紧密律：载荷自 `32 + 32×段数` 起按段表序**紧密累计、零填充**。
`align` 只记录数据类型的自然对齐要求供消费者判读；**偏移不保证按
align 对齐**（紧密律优先，设计 §8 算例即此：indices 段终于偏移 1096，
非 16 对齐）。消费者不得假设 `offset % align == 0`。

### 4.3 段种类（`Sax3dSectionKind`）

| 值 | 名 | 来源 |
|---|---|---|
| 1 | channel | 网格逻辑通道（含 morph 通道） |
| 2 | index | 索引段 |
| 3 | image_raw | raw 格式图像的段源像素 |
| 4 | anim_input | 动画采样器 input（时间轴） |
| 5 | anim_output | 动画采样器 output |
| 6 | inverse_bind | 骨骼逆绑定矩阵段 |
| 7 | blob | 容器格式图像等不透明载荷（含合并形内嵌图像） |
| 8 | assembly | 编译形组装段（仅合并形，恰一段） |

一段在同一资产内只能有一个种类；两处以不同种类使用同一段是诊断
`Sax3dSectionKindConflict`。未被任何声明引用的段记为 blob（保留，不丢弃）。

### 4.4 元素类型表（通道/采样器 IO 的类型词表）

| 名 | 字节 | 对齐 | 名 | 字节 | 对齐 |
|---|---|---|---|---|---|
| f32 | 4 | 4 | quat | 16 | 16 |
| f32x2 | 8 | 8 | u8x4 | 4 | 4 |
| f32x3 | 12 | 4 | u16x4 | 8 | 8 |
| f32x4 | 16 | 16 | u32 | 4 | 4 |
| u16 | 2 | 2 | f32x4x4 | 64 | 16 |

### 4.5 名表与解析产物契约

名表位于文件尾（全部载荷之后），NUL 分隔，每名恰出现一次；
`name_off` 为绝对文件偏移。构建序（确定性，两形/回读共用）：
① 资产名（仅合并形需要；拆分形名表只有段名）② 段名（按最终段表序）
③ 声明名（按种类序 shader/mesh/skeleton/image/texture/material/scene/clip，
同类内声明序；每声明随后附其局部名：mesh 的 primitive/morph/自定义
attr、skeleton 的 joint、scene 的 node（树前序）、clip 的 sampler）。
文件总长 = 载荷终点（nametab_off）+ 名表长。
**解析产物**即：段表（名/kind/偏移/长）+ 名表 + 校验器清单所列的
声明索引（mesh[0]、material[0]…按种类声明序）——上层加载所需的一切
布局信息到此备齐，格式侧契约完备。

### 4.6 段序

拆分形：`binary` 块声明序。合并形：拆分段序 + 路径源图像内嵌段
（按 image 声明序追加）+ 组装段居尾。

## 5. 组装文法（创作形，块式）

封闭词表：顶层声明只有 `asset / binary / mesh / skeleton / image /
texture / shader / material / scene / clip` 十种；未知声明、未知字段
一律具名拒绝。标识符容 `-`/`_`；`//` 行注释；每文件恰一份 asset 头。

### 5.1 asset / binary

```
asset <Name> version 1;
binary "<file>.saxb3d" { section <name> <len>; ... }
```
段长是期望值：校验器按声明用途逐段验算字节适配（§7），写入器按
实际载荷文件复核（§10.2）。

### 5.2 mesh

```
mesh <Name> {
  topology: triangles|triangle-strip|lines|line-strip|points;  // 省略=triangles；无 triangle-fan（D-9 订正，文从码）
  vertices <n>;
  bounds { min: [x,y,z]; max: [x,y,z]; }              // 可选
  channel <role> : <elem> @ <section>;                // 逻辑通道
  attr <Name> : <elem> @ <section>;                   // 自定义属性（名不得占用保留角色名）
  morph <Name> { channel position|normal|tangent : <elem> @ <section>; ... }
  indices u16|u32 @ <section> count <n>;
  primitive <Name> { material: <Material>; }          // ≥1
}
```
角色词表与钉死类型：`position f32x3 / normal f32x3 / tangent f32x4 /
uv0..uv3 f32x2 / color0 f32x4|u8x4 / joints0 u16x4 / weights0 f32x4`。
未知角色名 → `Sax3dUnknownChannel`。`joints0` 与 `weights0` 必须成对。
morph 通道仅 position/normal/tangent 的增量。

### 5.3 skeleton

```
skeleton <Name> {
  joint <Name> { parent: <Joint>|none; bind: { t: [..]; r: [..]; s: [..]; } }
  inverse_bind @ <section>;
}
```
`inverse_bind` 必备，段长 ≥ 关节数 × 64。关节父链不得成环；
关节同名唯一（骨骼内），且全资产 node 名唯一使跨层同名对应无歧义。

### 5.4 image / texture

```
image <Name> {
  source @ <section>;        // 或 source "<path>";（外部文件，创作形）
  format png|jpeg|ktx2|raw-rgba8|raw-rgba16f;
  size <w> <h>;              // raw 格式必填，其余可选注记
  color_space srgb|linear;   // 必填，永不猜测
}
texture <Name> {
  image: <Image>;
  sampler { mag: ..; min: ..; mipmap: ..; wrap_u: ..; wrap_v: ..; wrap_w: ..; }
}
```
raw 格式：声明 size 必须与段长逐字相等（w×h×bpp）。sampler 块 v1
**必填**、五字段（mag/min/mipmap/wrap_u/wrap_v）必填（§11 D-4）；
滤波值集 {nearest, linear}（mipmap 另容 none），环绕值集
{clamp, repeat, mirror}。文法行所列 `wrap_w` 为可选字段（不在
五字段必填内——2D 纹理无 W 轴），出现时同样验环绕值集（规则 9；
此口径与校验器实现一致，2026-11-01 订正批澄清，见 RECOVERY
D-文码-4 收口）。格式层永不解码图像内容（编解码缺口 GAP-2）。

### 5.5 shader / material

```
shader <Name>: slasl "<path>.slasl";
material <Name> {
  shader: <Shader>;
  param <iface-name> = <literal>;            // 标量/bool/[..] 向量
  texture <iface-name>: <Texture>;
  tex_transform <iface-name> { offset: [x,y]; scale: [x,y]; rotation: <f>; }
  state { alpha: opaque|blend|mask; cutoff: <f>; double_sided: <bool>; depth_write: <bool>; }
}
```
参数名/纹理绑定名属 shader 接口命名空间（不是资产名，合并形中保持
字面，§6.3）。绑定裁判全集见 §7 与 §9。

### 5.6 scene

```
scene <Name> { node <Name> { ... } ... }
node <Name> {
  transform { t: [x,y,z]; r: [x,y,z,w]; s: [x,y,z]; }   // 与 matrix 二选一
  matrix: [16 个数];
  mesh: <Mesh>; material: <Material>;    // material 覆盖仅单 primitive 网格合法
  skin: <Skeleton>;
  node ...                                // 子节点任意深
}
```
v1 无 camera/light 字段（F-7）；出现即未知字段拒绝。

### 5.7 clip（动画）

```
clip <Name> {
  sampler <Name> {
    input:  <elem> @ <section> count <n>;     // elem 必须 f32
    output: <elem> @ <section> count <n>;
    interpolation: linear|step|cubic-spline;  // 省略=linear
  }
  channel { node: <Node>; path: translation|rotation|scale|weights; sampler: <Sampler>; }
}
```
计数律：output 数 = input 数 × 每键分量数 ×（cubic-spline 时 3 否则 1）；
weights 通道的每键分量数 = 目标节点 mesh 的 morph 数，其余路径为 1。
路径类型律：translation/scale → f32x3；rotation → quat|f32x4；
weights → f32。

## 6. 编译形组装（合并形内嵌）

### 6.1 同文法、索引化名字
组装段内容是与创作形**同一文法**的规范文本：固定种类序
（asset, binary, shaders, meshes, skeletons, images, textures,
materials, scenes, clips）与固定字段序发射；一切声明名/引用名替换为
`#<名表索引>`（名字只在名表出现一次），段在 `binary` 块中只列名
（长度真理在段表）；`shader` 只留 `shader #<i>;`。同一解析器以
compiled 模式读回，同一校验器复检——两形同裁判由此是结构性的。

### 6.2 与创作形的有意差异（全部在此列明，无静默项）
- shader 的 `.slasl` 路径不入合并形（§6.4）。
- 路径源图像改为段源：其内容内嵌为段，`source @ #<段>`，段名 = 图像名；
  与既有段名冲突 → `Sax3dPackNameCollision`，响亮拒绝。
- 文件路径本体（binary 文件名、image 路径串）是创作形出处注记，
  不属交付语义，不入合并形。

### 6.3 接口名保持字面
材质参数名、纹理绑定名、规范通道角色名属接口/词表命名空间，不是
资产声明名，编译形中保持字面（例：`param base_color = ...` 不变）。

### 6.4 shader 在合并形中的处置（本版定版 + 待裁候选）
**定版**：shader 以引用名入册（名表 + `shader #<i>;`），**不内嵌
`.slasl` 源文本段**。理由：① 用户裁定 F-5 的精神——SLASL 是独立
产物、独立生命周期，资产格式不吞并它；② 资产编译期依赖的契约物是
接口表产物（§9），不是源；③ 交付形体积动机（用户 10:57 理据）与
内嵌源相悖；④ 先例同向——GLB 亦不内嵌 shader 源。
**待裁候选**（已打包交主会话，本线不自裁、不阻塞）：可选内嵌段
`kind` 扩展（如 shader_source 种类）供离线归档场景。利：单文件自足、
归档可复现构建；弊：破坏产物独立性与上述 ②③、源版本与接口表版本
双真理风险。若主会话裁定采纳，另起小批以新段种类 + 版本门落地。

## 7. 裁判规则（校验器义务，全部响亮、无静默回退）

1. 名字唯一：同种类内声明名唯一；node 名全资产唯一；段名唯一；
   joint/sampler/channel/primitive/材质参数与绑定在各自作用域唯一。
2. 引用必达：一切按名引用（段、material、image、shader、texture、
   mesh、skin、clip 的 node/sampler、joint parent）必须解析到声明，
   否则 `Sax3dUnresolvedReference`（clip 通道与 sampler 分别为
   `Sax3dClipTargetMissing` / `Sax3dClipSamplerMissing`）。
3. 字节适配：每段长度 ≥ 其用途所需（通道 = 顶点数 × 元素长；
   索引 = count × 元素长；inverse_bind = 关节数 × 64；
   动画 input = count × 4、output = count × 元素长），不足 →
   `Sax3dSectionOverflow`。raw 图像段为例外：逐字相等（规则 9）。
4. 封闭值集：一切枚举与定值字段出闭集即 `Sax3dInvalidValue`——
   mesh topology（闭集与 §5.2 文法一致；triangle-fan 不在集内，
   原 §5.2 文法误列已按 D-9 订正删除——文从码）、vertices 为 0
   或未声明、indices
   类型非 u16/u32、mesh 无 primitive、image format 出闭集、
   color_space 非 srgb/linear（必填、永不猜测）、sampler 各字段
   值集（§5.4）、material state alpha 非 opaque/mask/blend、
   clip interpolation 与 channel path 出闭集、skeleton 缺
   inverse_bind 段、node 的 material 覆盖或 skin 未伴 mesh。
5. 通道律：`channel` 名出规范角色词表 → `Sax3dUnknownChannel`
   （自定义通道走 `attr`）；角色元素类型与 §5.2 钉死表不符 →
   `Sax3dChannelTypeMismatch`；元素类型不在 §4.4 类型表 →
   `Sax3dUnknownElemType`；`attr` 名占用保留角色名 →
   `Sax3dAttrNameReserved`；morph 通道非 position/normal/tangent
   增量 → `Sax3dMorphChannelInvalid`；`joints0` 与 `weights0`
   不成对 → `Sax3dChannelPairing`。
6. 骨骼律：joint parent 必须是本骨骼关节（规则 2）；父链成环 →
   `Sax3dJointCycle`。
7. 关节-节点对应律：每个 joint 必须有同名 node 存在于某 scene，
   否则 `Sax3dSkinJointNotNode`；该 node 的最近关节祖先必须等于
   joint 声明的 parent（无关节祖先 ⇔ parent 为 none），否则
   `Sax3dJointParentMismatch`；挂 skin 的 node 其 mesh 必须具备
   joints0/weights0 通道，否则 `Sax3dSkinChannelMissing`。
8. 段用途律：同一段被以两种 kind 使用 → `Sax3dSectionKindConflict`
   （§4.3）；未被任何声明引用的段指派为 blob 保留、不丢弃。
9. 图像与采样器律：raw 格式图像声明 size 与段长必须逐字相等
   （w × h × bpp，raw-rgba8 为 4、raw-rgba16f 为 8），否则
   `Sax3dRawImageSizeMismatch`；texture 的 sampler 块缺失或
   mag/min/mipmap/wrap_u/wrap_v 五字段任一缺失 →
   `Sax3dMissingSamplerState`（D-4）；wrap_w 出现时同样验值集。
10. 材质绑定律（对 §9 接口表）：shader 无接口表供给 →
    `Sax3dMissingInterfaceFixture`；param 名不在接口 params →
    `Sax3dUndeclaredParam`；字面量类型与接口类型不符 →
    `Sax3dParamTypeMismatch`；接口 param 未被赋值且无默认值 →
    `Sax3dUnboundParam`（不许静默零值）；纹理绑定名不是接口
    sampler 参数、或 tex_transform 指向未绑定的名字 →
    `Sax3dUndeclaredTextureBinding`；接口 sampler 参数漏绑 →
    `Sax3dUnboundSamplerParam`。param 与纹理绑定在材质内重名
    亦按规则 1 判 `Sax3dDuplicateName`。
11. 装配律：node 同时写 transform 与 matrix →
    `Sax3dTransformConflict`；material 覆盖的 mesh 不是恰 1 个
    primitive → `Sax3dMaterialOverrideAmbiguous`。
12. 动画律：sampler input 元素类型必须 f32，否则
    `Sax3dChannelTypeMismatch`；channel path 对 output 的类型律
    （§5.7）违犯同码；计数律（output = input × 每键分量数 ×
    cubic-spline 的 3 倍因子）违犯 → `Sax3dAnimCountMismatch`。
    时间轴单调性属数据级检查，归 §10.2（D-8），不在声明级判。
13. 输入喂养律：被 mesh 的 primitive 材质所用 shader 的每个
    input，必须有规范映射（§9）对应的通道喂养，否则
    `Sax3dInputNotFed`；接口 input 类型与规范类型、或通道元素
    类型与 input 的相容性违犯 → `Sax3dChannelTypeMismatch`。
14. 文法与夹具律：asset 头缺失或重复（每文件恰一份，D-6）、
    字段/条目出文法 → `Sax3dParseError`；未知顶层声明 →
    `Sax3dUnknownDeclaration`；编译形名字索引越出名表 →
    `Sax3dCompiledNameRef`；接口表夹具条目格式错误 →
    `Sax3dFixtureError`（§9）。
15. 二进制面律（读入/回读面，与 §4.1/§4.5 对应）：魔数不符 →
    `Sax3dBadMagic`；version_major ≠ 1 → `Sax3dUnsupportedVersion`；
    flags 非零 → `Sax3dBadFlags`；文件小于头/段表/段载荷/名表
    所需 → `Sax3dTruncatedFile`；name_off 不能在名表内解析 →
    `Sax3dNameTableMismatch`。段集与声明的一致性归 §10.1。

## 8. 算例（恢复文本，见文末恢复说明）

立方体例（24 顶点、1 primitive、1 材质、1 纹理、1 shader 引用、
1 旋转 clip）拆分形的段布局——载荷基址 = 头 32B + 段表 7×32B
= 256，其后紧密累计：

| 段 | kind | 偏移 | 长 | 内容核算 |
|---|---|---|---|---|
| positions | channel | 256 | 288 | 24 × f32x3（12B） |
| normals | channel | 544 | 288 | 24 × f32x3 |
| uvs | channel | 832 | 192 | 24 × f32x2（8B） |
| indices | index | 1024 | 72 | 36 × u16 |
| checker | image_raw | 1096 | 16 | raw-rgba8 2×2 = 16B |
| spin_times | anim_input | 1112 | 8 | 2 × f32 |
| spin_rots | anim_output | 1120 | 32 | 2 × quat（16B） |

载荷终点 1152（总长口径见 D-2：名表追加于尾，拆分形文件总长
1211 = 1152 + 名表 59B）。indices 段终于 1096、非 16 对齐——
紧密律优先于 align 的实例（§4.2）。材质绑定对账：接口 params
= {base_color: vec4, roughness: f32, metallic: f32 = 0.0}，材质
赋 base_color（[f32;4] ↔ vec4）、roughness（标量 ↔ f32），
metallic 走默认值；textures = {base_color_map: sampler2D} 由
材质绑定；inputs = {position: vec3, normal: vec3, uv: vec2} 由
通道 position/normal/uv0 按 §9 规范映射喂入。

（存疑：第二例 hero（蒙皮动画例）在原 §8 中是否同列，无直接
证据；其实测布局见恢复说明所引 REPORT §2.3，此处不冒充原文。）

## 9. shader 接口表（绑定契约）（恢复文本，见文末恢复说明）

资产编译期依赖的契约物是 shader 的**接口表**：SLASL 编译器核心
的产物（合并/DCE 后的清单，同源生成、禁手写、可哈希规范形；
DCE 消除项自接口表消失）。依赖方向单向：资产侧消费接口表，
SLASL 不感知资产。接口表含三组：

| 组 | 内容 |
|---|---|
| params | 名 → 类型 + 可选默认值（带默认者材质可省略赋值） |
| textures | 名 → sampler 类型（材质纹理绑定的命名空间） |
| inputs | 名 → 类型（mesh 通道喂养的命名空间） |

绑定裁判见 §7 规则 10 与规则 13，要点：param 逐项按名 + 按型
命中（字面量类型对应：f32 ↔ 标量、vec2/3/4 ↔ 数组字面量）；
纹理绑定名必须是 textures 组的 sampler 参数名且不得漏绑；
params 未赋值且无默认 = 响亮拒绝，不许静默零值。通道 → input
的规范映射由格式钉死：position→position、normal→normal、
tangent→tangent、uv0→uv、uv1→uv1、uv2→uv2、uv3→uv3、
color0→color、joints0→joints、weights0→weights；规范 input
类型：position/normal 为 vec3、tangent 为 vec4、uv 家族为
vec2、color 为 vec4、joints 为 uvec4、weights 为 vec4。

v1 处置（GAP-1）：真实接口表 artefact 格式未定形前，以手工
文本夹具代演——三段式（`== params ==` / `== textures ==` /
`== inputs ==`），每行 `名: 类型`，params 行可后缀 `= 默认值`；
以 `block` 开头的布局头行跳过；条目出段或格式错误 →
`Sax3dFixtureError`。材质所用 shader 无夹具供给 →
`Sax3dMissingInterfaceFixture`。

## 10. 工具链义务：构建与打包（恢复文本，见文末恢复说明）

校验不过一律具名诊断 + 非零退出，绝不带病产出文件。

### 10.1 打包（pack：拆分 → 合并）

- 输入拆分形二进制与组装文本声明必须双向一致：文本声明的段
  在二进制中缺失、或长度不符、或二进制多带未声明段（不许
  静默丢弃），均 → `Sax3dSectionMismatch`；读入面的魔数/截断/
  名表解析按 §7 规则 15。
- 路径源图像内嵌为段（段名 = 图像名，按 image 声明序追加，
  §4.6）；与既有段名冲突 → `Sax3dPackNameCollision`（§6.2）。
- 内嵌变换后以同一校验器复检，复检不过不产出。
- 段序：拆分段序 + 内嵌图像段 + 组装段居尾（§4.6）。
- **确定性**：同输入逐字节同输出；名表按 §4.5 规范构建序
  生成（名字恰出现一次、索引按首次出现）。

### 10.2 构建（build：组装文本 + 载荷 → 拆分形二进制）

- 无 binary 块的资产无可写出 → `Sax3dInvalidValue`。
- 段载荷文件约定：`<payload-dir>/<段名>.bin`，无头裸字节
  （§2）；文件不可读 → `Sax3dPayloadMissing`；长度与声明
  逐字不符 → `Sax3dPayloadLengthMismatch`，拒绝产出。
- 数据级检查（D-8）：kind 为 anim_input 的段，其 f32 时间轴
  必须单调不减，违犯 → `Sax3dAnimInputNotMonotonic`。

## 11. 偏差变更日志（与研究稿 DESIGN.md 的差异）（恢复文本，见文末恢复说明）

- D-1 头 reserved 细化为 nametab 指针：§4.1 的 nametab_off /
  nametab_len 两字段占原 reserved 区（偏移/总长不变）。
- D-2 §8 总长口径定版：1152 = 载荷终点，名表追加于尾；
  文件总长 = 载荷终点 + 名表长（拆分形立方体例 1211B）。
- D-3 合并形机制 = 编译形组装段（F-2 修订落地，§6）：
  assembly 段恰一段、居尾（§4.3/§4.6）。
- D-4 sampler 五字段必填收严（§5.4）：sampler 块必填，
  mag/min/mipmap/wrap_u/wrap_v 五字段必填。
- D-5 角色/接口类型钉死：tangent f32x4、joints0 u16x4 /
  接口侧 joints uvec4、weights0 f32x4 等（§5.2/§5.7/§9）。
- D-6 asset 头恰一份强制（§5/§7 规则 14）：空文件缺 asset
  头曾假绿，实测发现后补此规则。
- D-7 bind/bounds/tex_transform 数值全保真入模型：解析保留
  数值本体，不再「只跳过不校验」。
- D-8 动画时间轴单调性归 build 数据级检查（§10.2）：
  声明级校验器无载荷数据，单调性在 build 读载荷后验。
- D-9 topology 值集订正（2026-11-01 订正批，**文从码**）：
  §5.2 文法原列 `triangle-fan`，与校验器闭集 {triangles,
  triangle-strip, lines, line-strip, points} 矛盾（声明即
  `Sax3dInvalidValue`），而转换器双向产/收之——转换产物过不了
  自家裁判。恢复批登记为 D-文码-1 后，Jev 裁决
  text_follows_code（0.99，置信 0.98，2026-11-01）定版：
  §5.2 删 triangle-fan，格式值集以校验器闭集为准；转换器
  改行为——入向遇 glTF TRIANGLE_FAN 展开为三角形列表
  （索引按扇展开、无损，计数口径见 CONVERTER_MAP §1 注），
  出向永不产出 fan（扇形输入按同一展开处置并进台账）。
  本条为订正非扩展：格式接纳面不变（fan 从未合法过）。
  同批顺修：§5.4 wrap_w 口径澄清（D-文码-4 收口，文从码，
  义务不变）。

## 恢复说明（2026-11-01 文档修复批，非格式内容）

本文件曾于 §7 规则 3 中途截断（文件尾留有字面截断标记，
工具截断视图回写落盘所致），§7 规则 3 后半起至 §11 全部
丢失，且无完好副本存世。2026-11-01 修复批据现存证据恢复：
规则执行体（实现代码 src/*.zig 的具名诊断与检查点）、实施
终报（sax3d-impl-local/REPORT.md，§2.2 算例与 §5 偏差清单
为逐字出处）、研究稿（sa3d-mesh-local/DESIGN.md）与本文件
存续正文的交叉引用（§9 接口表、§10 打包/§10.2 载荷复核、
§8 算例均被存续正文引用）。逐段证据对照、44 个 Sax3d*
诊断名 → 规则映射表、文/码双向差异表与存疑清单见同批的
恢复说明
文件（RECOVERY.md）。恢复纪律：恢复不等于修订——格式实质
一字未改；证据不足以定字句处已标「存疑」（§8 第二例、
§10 子节次序与各节原标题、§7 规则 4 起的原编号均属之，
恢复编号为新编）。§1–§7 规则 3 前半为原文存续。

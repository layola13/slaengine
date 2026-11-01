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
  topology: triangles|triangle-strip|triangle-fan|lines|line-strip|points;  // 省略=triangles
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
{clamp, repeat, mirror}。格式层永不解码图像内容（编解码缺口 GAP-2）。

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
   索引 = count × 元素长；inv
...[truncated 10203 chars]
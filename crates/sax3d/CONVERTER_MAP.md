# SAX3D ↔ glTF/GLB 转换映射表（先表后码，本表为转换器实现的规范）

分类：**采**=逐值精确映射；**近似**=表示变换但语义守恒或按表注记的
受控偏差（必须进转换报告台账）；**不支持**=响亮拒绝（具名转换诊断，
整资产不产出或按 §0 规则标记部分转换）。任何未列构造默认**不支持**。

## 0. 总规则

- 零静默丢失：一切近似/不支持/合成（补名、合成段、推断色空间）都进
  转换报告台账，逐项可查；台账为空才许称无损。
- 名字：glTF 的 `name` 可缺省/可含非法字符。处置：合法且不冲突者原样
  采；缺失→按 `<种类>_<glTF 索引>` 合成；非法字符→`_` 替换；冲突→
  追加 `_<索引>`。全部合成/改名进台账（索引→最终名对照表）。
- 索引改名为主键：一切 glTF 索引引用经对照表落为 SAX3D 名，反之亦然。
- 扩展（extensions）：`extensionsRequired` 含未知扩展 → 拒绝
  （`CvtUnsupportedExtension`）；仅 `extensionsUsed` 的未知扩展 → 台账
  记录并标「部分转换」，不静默吞。
- SAX3D 侧输入必须先过 v1 裁判（校验器），带病资产不转换。

## 1. 几何

| 构造 | glTF→SAX3D | SAX3D→glTF | 注 |
|---|---|---|---|
| POSITION/NORMAL (f32x3) | 采 | 采 | 字节直提（解交错 §5） |
| TANGENT (f32x4) | 采 | 采 | |
| TEXCOORD_0..3 → uv0..3 (f32x2) | 采 | 采 | TEXCOORD_4+ → 不支持 |
| COLOR_0 | 采（f32x4 或 u8x4） | 采 | 归一化整数按字节直提，类型即 u8x4 |
| JOINTS_0 u16x4 | 采 | 采 | |
| JOINTS_0 u8x4 | **近似**（拓宽 u16，值守恒、字节变，进台账） | —（SAX3D 只有 u16x4） | |
| WEIGHTS_0 f32x4 | 采 | 采 | |
| WEIGHTS_0 归一化 u8/u16 | **近似**（除 255/65535 化 f32，进台账） | — | |
| 自定义属性 `_FOO` | **近似**→ `attr FOO`（元素类型须落在 §4.4 词表，否则不支持） | `attr FOO` → `_FOO` 采 | 名映射在台账 |
| indices u16/u32 | 采 | 采 | |
| indices u8 | **近似**（拓宽 u16，进台账） | — | |
| 无 indices（非索引绘制） | 采（mesh 无 indices 声明） | 采 | |
| primitive mode（拓扑） | 采（0/1/3/4/5/6 ↔ points/lines/line-strip/triangles/triangle-strip/triangle-fan） | 采 | mode 2 (line loop) → 不支持 |
| 多 primitive（属性集/索引集全同） | 采（一 mesh 多 primitive） | 采 | |
| 多 primitive（属性集或索引不同） | **近似**（按 primitive 拆 mesh，名加后缀，进台账） | — | SAX3D 一 mesh 一通道集/一索引段 |
| SAX3D 多 primitive → glTF | — | **近似**（SAX3D primitive 无索引范围，各 primitive 共用整索引段会重叠绘制，进台账响亮标注） | v1 格式事实，非转换器可补 |
| morph targets（POSITION/NORMAL/TANGENT 增量） | 采 → morph；目标名取 `mesh.extras.targetNames`，缺失则合成（进台账） | 采（写 targetNames 入 extras） | 目标含其他属性 → 不支持 |
| mesh.weights（默认权重） | **近似**（SAX3D 无默认权重位；全 0 时等价省略，非 0 → 不支持） | —（SAX3D 无此构造） | |
| accessor.byteStride 交错 | 采（解交错为独立紧密段，见 §5） | —（出口恒紧密） | |
| accessor.sparse | 不支持（`CvtSparseAccessor`） | — | |
| accessor 归一化 POSITION 等非常规组合 | 不支持 | — | |

## 2. 材质与 shader（核心映射，shader 槽处置在此定版）

**glTF 无 shader 概念；SAX3D 材质必须绑 shader。二选一的裁量与理由：**
取「绑具名标准 PBR shader」——理由：① SAX3D 裁判要求材质 shader 引用
必达，不绑则一切转换产物皆非法，转换器等于无用；② glTF 的
pbrMetallicRoughness 参数集**就是**标准 PBR 模型，与标准 PBR SLASL
shader 的接口是同一语义面的两种记法，绑定不是捏造而是补名；
③ 显式标「未绑」在本格式无合法表达（无 unbound 语法位），硬造伪
状态违反封闭词表。故：普通 mesh 材质绑 `StdPbr`，蒙皮 mesh 的材质
绑 `StdPbrSkinned`（同参数集 + joints/weights 输入），两者的接口
夹具随转换器附带（`converter/fixtures/`），合成绑定逐项进台账。
**反方向**：SAX3D 的 shader 引用在 glTF 无对应物——参数集按本表近似
为 PBR（下行），shader 名写入 glTF `extras.sax3d_shader` 随资产留存，
且在转换报告中逐项列明「shader 语义（含自定义逻辑）未被 glTF 表达」；
`StdPbr*` 视为已由 PBR 参数集等价表达（仅记名），自定义 shader
额外标「自定义 shader 逻辑丢失」。

| 构造 | glTF→SAX3D | SAX3D→glTF | 注 |
|---|---|---|---|
| baseColorFactor → param base_color (vec4) | 采 | 采 | 缺省 (1,1,1,1) 时两侧都不写 |
| roughnessFactor → param roughness | 采 | 采 | |
| metallicFactor → param metallic | 采 | 采 | 我方夹具默认 0.0；glTF 默认 1.0——出口恒显式写出有效值（参数或夹具默认），进口按值落 param |
| baseColorTexture → texture base_color_map | 采 | 采 | texCoord 须 0，非 0 → 不支持（我方无 per-binding 通道选择位） |
| metallicRoughnessTexture / normalTexture / occlusionTexture / emissiveTexture | 不支持（`CvtUnsupportedTextureSlot`；StdPbr 接口无此槽） | — | 响亮拒绝，不静默丢 |
| emissiveFactor（非零） | 不支持（`CvtUnsupportedParam`） | — | 全零/缺省等价省略 |
| alphaMode OPAQUE/BLEND/MASK → state alpha | 采 | 采 | MASK 配 alphaCutoff → cutoff 采 |
| doubleSided | 采 | 采 | |
| （SAX3D）state.depth_write | — | **近似丢失**（glTF 核心无对应；进台账 + extras 注記） | |
| tex_transform（offset/scale/rotation） | KHR_texture_transform → 近似（glTF 侧在 textureInfo.extensions；我方为材质级字段，语义同） | 写出 KHR_texture_transform（extensionsUsed 登记） | 无该扩展时进口遇 tex_transform 字段属 SAX3D 原生，出口按此行 |
| 法线贴图 scale、遮挡强度等 | 不支持（同 texture slot 行） | — | |

## 3. 图像/纹理/采样器

| 构造 | glTF→SAX3D | SAX3D→glTF | 注 |
|---|---|---|---|
| image bufferView（png/jpeg） | 采（段源，format 按 mime） | 采 | |
| image uri（外部文件） | 采（路径源 image） | 路径源 image → **近似**：写为 bufferView 内嵌（路径本身不保留，进台账）；原为段源者直提 | |
| image data: URI | 采（base64 解码为段源） | — | |
| color_space（我方必填） | **推断**（非格式字段，按 glTF 规范角色定：baseColor/emissive 槽 → srgb；normal/occlusion/metallicRoughness 槽 → linear；无角色 → srgb 并进台账标「无角色推断」） | 按声明对应槽位（规范隐含，不需字段） | 推断是 glTF 规范约定而非我方猜测，仍全量入台账 |
| sampler mag/min/mipmap/wrap | 采（值集映射：9728/9729、9984–9987 组合拆解、33071/10497/33648） | 采（组合编码） | wrap_w 无 2D 对应：非缺省值进台账标丢失 |
| texture 无 sampler | **近似**（glTF 缺省采样 = 我方须显式：补 mag/min linear、mipmap linear、wrap repeat——glTF 规范缺省值，进台账） | — | |
| raw 图像（raw-rgba8/16f） | —（glTF 无 raw 形） | **编码**（无损 PNG 编码，同像素；属精确重编码非近似，进台账记「表示变换」） | |
| ktx2 图像 | 采（format ktx2，mime image/ktx2） | 采 | |

## 4. 场景/骨骼/动画

| 构造 | glTF→SAX3D | SAX3D→glTF | 注 |
|---|---|---|---|
| node TRS / matrix | 采 | 采 | 两侧皆备，二选一原样 |
| node.mesh / children / 多 scene | 采 | 采 | |
| node.material 覆盖（我方） | — | **近似**（glTF 无节点级覆盖：按覆盖克隆 mesh 落 primitive 材质，克隆名 `Mesh__ovr_<Node>`，进台账） | |
| node.weights（非零） | 不支持 | —（我方无此构造） | 全零等价省略 |
| camera / KHR_lights_punctual | 不支持（F-7 核心域外，`CvtUnsupportedNodeFeature`） | —（我方文法无此字段） | |
| skin.joints + inverseBindMatrices | 采（关节父按节点树最近关节祖先导出——与我方裁判同规） | 采（按名落关节 node 索引） | |
| skin 无 IBM 访问器 | **近似**（合成单位矩阵段 = glTF 缺省语义，进台账） | — | |
| skin.skeleton（公共根提示） | 省略（仅优化提示，无语义） | 不写 | 台账记一行 |
| animation channel（TRS/weights 路径） | 采 | 采 | target node 必达否则 glTF 本身非法 |
| animation interpolation STEP/LINEAR/CUBICSPLINE | 采 | 采 | CUBICSPLINE 计数律两侧同构（×3） |
| 动画名 / 采样器名 | clip 名采 animation.name（缺失合成）；sampler 名合成 `S<idx>`（glTF 采样器本无名） | clip 名 → animation.name | 合成进台账 |

## 5. 字节层

- 进口解交错：bufferView.byteStride > 元素长时逐元素抽取为紧密段，
  值字节不变（采，非近似）。
- 出口 .bin：各 accessor 独立 bufferView 紧密排布（byteStride 不写），
  与 SAX3D 段一一对应的载荷逐字节同（拓宽/归一化转换过的通道除外，
  那些以「值等价」验收并在台账标明）。
- GLB 出口：JSON 块空格填充、BIN 块零填充（规范填充，不计入台账）。

## 6. 转换诊断码（响亮面）

`CvtBadInput`（输入不可解析/非法 glTF）、`CvtSparseAccessor`、
`CvtUnsupportedExtension`、`CvtUnsupportedTextureSlot`、
`CvtUnsupportedParam`、`CvtUnsupportedNodeFeature`、
`CvtUnsupportedTopology`、`CvtUnsupportedElemType`、
`CvtNameSanitized`（台账级，非致命）、`CvtInternalInvariant`
（转换器自检失败，如产出过不了自家裁判——进口产出强制过 sax3dc 裁判，
过不了即此码，绝不交付带病资产）。

## 附录 B. Blender 专册（保真台账，TODO §7.1 ⑤）

约定本体见 BLENDER.md（B1 同名对应 / B2 集合实例 / B3 Principled
型廓 / B4 贴图管线）；本册只记 Blender 来源特有的转换保真行，
等级口径从 §0。Blender 经官方 glTF 导出器中转时，下表「来源构造」
指 Blender 构造，其 glTF 形态再走 §1–§6 主表。

| 来源构造 | 等级 | 说明 |
|---|---|---|
| 骨骼名（含 `.001` 等后缀/空格/非 ASCII） | SYNTH | 清洗/去重改名入账（BLENDER.md B1）；对应以 claimed 名为准，joint 与 clip 通道同步 |
| 跨 armature 同名骨骼 | SYNTH | 去重改名入账；禁止合并为一根骨骼 |
| 集合（Collection）层级 | SYNTH | 压平为 node 父子（组 node），集合组织语义不入资产 |
| 集合实例 / 关联复制 | 精确 | 展开为多 node 引同一 mesh（BLENDER.md B2）；实例数入账 |
| GPU 实例化（几何节点/粒子） | 近似（展开）或响亮拒绝 | v1 无逐实例矩阵面（GAP-B5 候裁）；展开须入账 SYNTH 行数，禁止静默截断 |
| Principled：Base Color/Metallic/Roughness/Alpha 常量与 Base Color 贴图 | 精确 | B3 型廓表（与 slasl 同表） |
| Principled：IOR / Specular | 近似 | F0 固定 0.04（B3 偏差声明），IOR 不入参 |
| Principled：Emission / Subsurface / Sheen / Coat / Transmission / 法线贴图 / 粗糙金属贴图 | 不支持（响亮） | StdPbr v1 型廓外，入账；不许并入 base_color 或静默丢弃 |
| Principled 输入由节点网络驱动 | 近似 | 导出烘焙贴图/常数，网络本身不入资产（节点面归 slasl 定形） |
| 图像色彩空间 sRGB / Non-Color / Linear | 精确 | 映射 srgb / linear / linear（B4 表） |
| 图像色彩空间其余档（ACES 等） | 不支持（响亮） | 二值枚举装不下；拒绝并指路改设，禁止就近归一 |
| Mapping 节点变换 | 近似 | Y 方向翻转换算后写 tex_transform，入账 APPROX（B4） |
| 图像插值/扩展无对应档位 | 近似 | 入账 APPROX，不许默认 Repeat 掩盖 |
| 相机 / 灯光 / 世界环境 / 自定义属性 | 不支持（响亮） | SPEC §5.6 F-7 排除，GAP-B1…B4 候裁；导出方须明示丢弃清单 |
| 修改器（镜像/阵列等） | 精确（应用后） | 参数化语义丢弃入账 |

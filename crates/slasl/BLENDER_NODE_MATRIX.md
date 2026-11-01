# Blender 材质节点覆盖矩阵（TODO §8 P1 ② — blender 约定验收清单）

行集 = Blender 参照克隆 `source/blender/nodes/shader/nodes/` 的全部
100 个 node_shader_*.cc（2026-11-01 实测清单），逐节点一行。
覆盖口径 = **该节点的计算在 slasl 里可表达**（语言构造/内建/表达式
公式），不是「有同名节点」。图例：

- ● 已覆盖：可直接表达（含本批新增内建函数与构造）。
- ◐ 近似：可表达但有声明偏差，或依赖宿主 @input/@global 面配合。
- ○ 未覆盖—响亮拒绝：无表达面；节点图摄入时必须以具名诊断拒绝
  （节点类型 + 节点名 + 图名），禁止静默跳过或以常数顶替。
- 内：Blender/Eevee 内部管线节点或非节点文件，非用户面，不适用。

统计：● 23 / ◐ 24 / ○ 47 / 内 6（合计 100）。
本矩阵即 blender 约定的**验收清单**：摄入面实现批次（本批只定形，
见文末）逐行对拍，处置列变更必须同步改本表与对应构造。

## 输入与坐标

| 节点（源文件） | 处置 | 依据 / 偏差 |
|---|---|---|
| tex_coord（tex_coord） | ◐ | UV 通道走 @input uv；Generated/Object 等坐标系需宿主以 @input/@global 供给 |
| uvmap（uvmap） | ● | 命名 UV 集 = 选择对应的 @input uv 声明 |
| geometry（geometry） | ◐ | Position/Normal 走 @input；Tangent/True Normal/Incoming 等部分量需宿主面补齐 |
| attribute（attribute） | ◐ | 命名属性经 @param/@global 承载；顶点域属性需 @input 声明 |
| vertex_color（vertex_color） | ◐ | 以 @input color 声明承载 |
| tangent（tangent） | ◐ | 以 @input tangent 声明承载（径向/轴向计算不在片元面） |
| camera（camera） | ○ | View Vector 可由宿主变量拼，但节点整体（含景深量）无面 |
| object_info（object_info） | ○ | 对象级宿主数据（位置/随机/材质索引）无声明面 |
| particle_info / point_info / hair_info | ○ | 粒子/点/毛发宿主数据无面 |
| light_path（light_path） | ○ | 光线类型判定属渲染器面 |
| fresnel（fresnel） | ● | 公式 `pow(1−dot(N,V), 5)` 类由内建直接表达（IOR 变体同公式参数化） |
| layer_weight（layer_weight） | ● | Fresnel/Facing 均为 dot/pow 公式 |
| radial_tiling（radial_tiling） | ◐ | UV 极坐标变换可公式表达，无一等构造 |

## 纹理

| 节点（源文件） | 处置 | 依据 / 偏差 |
|---|---|---|
| tex_image（tex_image） | ● | @param sampler2D + `.get`；色彩空间走资产侧约定（sax3d BLENDER.md B4） |
| tex_environment（tex_environment） | ◐ | `probe_sphere` 构造采样等距圆柱图；与 Blender 环境贴图映射口径差为声明偏差 |
| tex_gradient（tex_gradient） | ◐ | 坐标函数本身平凡，但依赖 tex_coord 的坐标来源（同 ◐） |
| tex_checker（tex_checker） | ◐ | floor 奇偶公式可表达，无一等构造 |
| tex_wave / tex_magic（tex_wave / tex_magic） | ◐ | sin 闭式可表达（参数化公式长），无一等构造 |
| tex_noise / tex_voronoi / tex_gabor / tex_white_noise / tex_brick（同名文件） | ○ | 依赖 hash/细胞 machinery，无内建；程序纹理一律拒绝（烘焙为贴图后走 tex_image） |
| tex_sky（tex_sky） | ○ | 大气模型无面 |
| ies_light（ies_light） | ○ | IES 分布数据无面 |

## 颜色与数值

| 节点（源文件） | 处置 | 依据 / 偏差 |
|---|---|---|
| mix / mix_rgb（mix / mix_rgb） | ● | mix 内建 + 逐分量运算 |
| invert（invert） | ● | `1−x` 逐分量 |
| brightness（brightness） | ● | 加/乘公式 |
| gamma（gamma） | ● | pow 内建 |
| hueSatVal（hueSatVal） | ◐ | HSV 互转公式可表达（长），无一等构造 |
| rgb（rgb）/ value（value） | ● | 常量即字面量 |
| rgb_to_bw（rgb_to_bw） | ● | 亮度权重 dot |
| color_ramp（color_ramp） | ○ | 渐变查表无 1D 采样面；资产侧烘焙为贴图后可走 tex_image |
| curves（curves） | ○ | 曲线查表，同 ColorRamp |
| blackbody / wavelength（同名文件） | ○ | 光谱→RGB 数据表无面 |
| light_falloff（light_falloff） | ○ | 光源距离律属灯光面（SPEC GAP-B2 面外） |
| math（math） | ● | 内建集覆盖主要模式；MOD/Ping-Pong 等以 floor 公式表达（◐ 级注脚）；未知模式拒绝 |
| clamp（clamp）/ map_range（map_range）/ squeeze（squeeze） | ● | clamp 内建 / 线性重映射公式 |
| sepcomb_color / sepcomb_xyz（同名文件） | ● | swizzle 与构造器 |
| vector_math（vector_math） | ● | dot/cross/normalize/length/reflect 等内建集 |
| vector_rotate（vector_rotate） | ● | 轴角/Euler 公式可表达（长） |
| vector_transform（vector_transform） | ◐ | 坐标系变换依赖宿主矩阵 @global |
| mapping（mapping） | ◐ | UV 仿射可公式表达；资产侧对应物是 tex_transform（sax3d B4），两路勿混 |
| normal（normal） | ● | 方向常量 + dot |
| normal_map（normal_map） | ○ | 切线空间扰动需导数/切线帧构造，v1 无面 |
| bump（bump） | ○ | 依赖屏幕导数，无导数内建 |

## 着色器（BSDF 与输出）

| 节点（源文件） | 处置 | 依据 / 偏差 |
|---|---|---|
| bsdf_principled（bsdf_principled） | ◐ | `principled()` 一等构造（本批 B③）；偏差：单直射光、无 IBL/阴影、F0 固定 0.04、型廓外输入（Emission/SSS/Sheen/Coat/Transmission/法线）拒绝——与 sax3d BLENDER.md B3 同表 |
| bsdf_diffuse（bsdf_diffuse） | ◐ | principled 的漫反射项近似（roughness 影响的 Oren-Nayar 不建模） |
| bsdf_glossy（bsdf_glossy） | ◐ | principled 的 GGX 镜面项近似（各向异性/Beckmann 不建模） |
| bsdf_metallic（bsdf_metallic） | ◐ | principled metallic=1 路径近似（导体 F0 由 base color 给） |
| bsdf_transparent（bsdf_transparent） | ◐ | 只出 alpha 语义，混合由宿主 state 承担 |
| holdout（holdout） | ◐ | alpha=0 输出近似 |
| emission（emission） | ● | color×strength 逐分量乘，宿主在输出端相加 |
| background（background） | ◐ | 世界颜色可由 probe 构造/常量给；强度缩放为公式 |
| eevee_specular（eevee_specular） | ◐ | 旧式镜面模型以 principled 近似，参数不一一对应 |
| add_shader / mix_shader（同名文件） | ● | 求值后颜色的加/mix（闭包在摄入层求值化） |
| bsdf_glass / bsdf_refraction（同名文件） | ○ | 透射需场景采样/折射面 |
| bsdf_sheen / bsdf_toon / bsdf_translucent / bsdf_hair / bsdf_hair_principled / subsurface_scattering（同名文件） | ○ | 型廓外或专用模型，无构造 |
| bsdf_ray_portal（bsdf_ray_portal） | ○ | 传送门采样属渲染器面 |
| shader_to_rgb（shader_to_rgb） | ○ | Eevee 专有求值回读，无面 |
| output_material（output_material） | ◐ | Surface 求值结果写 frag_color 的宿主约定；Volume/Displacement 插口无面 |
| output_world（output_world） | ◐ | 同 background 行 |
| output_aov / output_light / output_linestyle（同名文件） | ○ | AOV/灯光组/Freestyle 输出无宿主面 |
| displacement / vector_displacement（同名文件） | ○ | 几何阶段面，非片元求值 |
| ambient_occlusion（ambient_occlusion） | ○ | 需场景采样 |
| bevel（bevel） | ○ | 需几何邻域采样 |
| wireframe（wireframe） | ○ | 需重心/导数面 |
| script（script） | ○ | OSL 脚本不摄入（许可证与面双理由） |
| uv_along_stroke（uv_along_stroke） | ○ | Freestyle 专用 |

## 体积

| 节点（源文件） | 处置 | 依据 / 偏差 |
|---|---|---|
| volume_absorption / volume_scatter / volume_principled / volume_coefficients / volume_info（同名文件） | ○ | 体积求值（相位/消光积分）非片元面；`probe_volume` 是辐照度**采样**构造，与体积着色节点不是一回事，勿混 |

## Blender 内部（非用户面）

common（共享代码非节点）、light_accumulation、light_evaluation、
light_info、light_iter_internal、shadow_raycast、raycast —— Eevee
管线内部构造，不进用户节点图，处置 = 不适用（摄入时遇之即图外
构造，按 ○ 的响亮口径拒绝并注明 internal）。

## 节点图摄入面定形（本批只定形、不实现）

- **输入形态**：摄入源 = Blender 侧薄胶水（Python，TODO §6.2 已确认
  形态）导出的节点图 JSON 中间表示：图名、节点数组（类型 / 名字 /
  插口默认值 / 参数）、连线数组（from 节点.插口 → to 节点.插口）。
  摄入器不直读 .blend。
- **求值化**：摄入器拓扑排序后逐节点按本矩阵展开为 slasl 表达式：
  ● → 表达式模板；◐ → 模板 + 偏差逐项进转换台账；○ → 具名拒绝
  （诊断须含节点类型、节点名、图名；诊断名由摄入实现批次定，
  暂记 `NodeUnsupported` 候选名）。多输出节点展开为共享中间变量；
  未连插口取节点默认值作常量。
- **闭包处置**：BSDF 类节点不是值——在 Material Output 处按
  `principled()` 等构造求值化；Add/Mix Shader 在求值域合成。
  Principled 的型廓外插口有连线即拒绝（与 B3 型廓表同口径）。
- **不在定形内**：驱动器/动画输入（导出侧烘焙）、Geometry Nodes、
  世界节点图之外的编辑器状态。

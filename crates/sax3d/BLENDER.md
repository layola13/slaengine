# SAX3D × Blender 约定（合 SPEC 丰富，不动格式）

定位：本文是 TODO.md §7.1 五条「合 SPEC」丰富项的成文面——把 Blender 场景
导出到 SAX3D v1 时的**约定**钉死。全部约定只用 SPEC v1 已冻结的面
（§5.3 骨骼、§5.4 图像/采样器、§5.5 材质/贴图变换、§5.6 节点、§5.7 clip、
§7 裁判规则 1–3），**不新增任何格式字段**。凡约定无法用现行格式表达的，
一律响亮处置（校验诊断 / 转换台账），并在 §6 登记为 SPEC 缺口候裁，
不在本文静默扩格式。

执行面：Blender 侧经 glTF 中转（Blender 官方 glTF 导出器 → 本仓 convert
to-sax3d），或将来经 Blender 插件薄胶水（Python、TODO §6.1 已确认形态）
直出 SAX3D 文本；两条路共用本文约定。转换台账纪律从 CONVERTER_MAP §0：
零静默丢失，近似/不支持/合成全部入账。

## B1. 骨骼动画同名对应约定

**约定本体**：骨骼关节、场景节点、动画通道三者以**名字**对应，是 SAX3D
的既定设计而非导出器习惯：

- SPEC §5.3：skeleton 的每个 joint 必须对应一个同名 node；joint 集合内
  唯一；joint 的父必须是另一 joint 或同 skeleton 的祖先 node。
- SPEC §5.6 / §7 规则 1：node 名全资产唯一。
- SPEC §5.7：clip 通道以 node 名 + path 寻址目标，采样器按名引用；
  §7 规则 2 给出 `Sax3dClipTargetMissing` / `Sax3dClipSamplerMissing`。

**Blender 侧命名链**：Blender 骨骼（Bone）名 → glTF node 名（Blender
glTF 导出器以骨骼名命名关节节点）→ SAX3D node 名 == joint 名。导出时
禁止改名链中任何一环；不一致即断链，动画静默失效是最坏情形，故约定
以校验兜底（下表）。

**转换器既有行为（tools/convert.zig 实证，本约定予以追认）**：

- 名字经 NamePool.claim：清洗（非 `[A-Za-z0-9_-]` 字符 → `_`；空名 →
  合成；首字符数字/`-` → 前缀 `n`；与 SAX3D 关键字同名 → 后缀 `_`）；
  同池重名 → 去重改名 `<名>_<源索引+n>`。清洗/改名/合成全部进台账
  `SYNTH` 行（`sanitised/deduped '<原名>' -> '<新名>'`），可反查映射。
- joint 名、clip 通道目标名都取自同一份 claimed node 名表，故改名后
  对应关系仍闭合——**对应以 claimed 名为准，原名只出现在台账里**。
- joint 的 parent 由 glTF 节点父链向上找最近的同 skin 关节祖先，
  无则 `parent: none`；skin.skeleton 根提示丢弃入账 `LOSS`（仅优化
  提示、无语义，CONVERTER_MAP §3 同口径）。

**Blender 特有命名情形**：

| 情形 | 处置 |
|---|---|
| 骨骼名含 `.`（如 Blender 重名后缀 `Bone.001`） | 清洗为 `Bone_001`，台账 SYNTH；与去重后缀同形但成因不同，台账原文可分辨 |
| 骨骼名含空格/中文 | 逐字清洗为 `_`，台账 SYNTH；建议源头改名（约定建议、非强制） |
| 两骨骼同名（Blender 内骨骼名本唯一，但跨 armature 合并导出可撞） | 去重改名，台账 SYNTH；通道与 joint 同步改名，对应不断 |
| 骨骼名与 mesh/material 等异类名相同 | 允许：唯一性按种类作用域（SPEC §7 规则 1），node 名全资产唯一是唯一跨界约束 |

**校验兜底（既有语料，本约定引为验收面）**：sax3dc check 负例
`neg_skin_joint_not_node`（Sax3dSkinJointNotNode）、
`neg_joint_parent_mismatch`（Sax3dJointParentMismatch）、
`neg_clip_target_missing`（Sax3dClipTargetMissing）、
`neg_duplicate_name`（Sax3dDuplicateName）；
转换器正/改名两用例见 tests/run_convert.sh §D（skinmin / skindup）。

## B2. 集合 / 实例导出约定

Blender 集合（Collection）与实例化（Collection Instance / 物体实例）
在 glTF 与 SAX3D 中都没有一等公民，按下表折叠，全部只用 SPEC §5.6
node 面（`mesh` / `material` 覆写 / `transform` / `children`）：

| Blender 构造 | 导出形态 | 保真 |
|---|---|---|
| 集合（组织层级） | 不出资产构造；集合层级压平为 node 父子（空 node 作组），集合名可作组 node 名（走 B1 清洗） | 组织语义（可见性开关等）不入资产，属编辑器面 |
| 集合实例（Empty + Instance Collection） | 展开为实例根 node 下的成员 node 子树；成员各自引用**同一 mesh 名** | 几何共享精确；实例数大时 node 数线性涨（见下） |
| 物体实例（Alt+D 关联复制） | 多个 node 引用同一 mesh 名，各带自身 transform；material 覆写按 node 写 | 精确（SPEC §5.6 node.mesh 共享即实例语义） |
| 镜像/阵列修改器 | 导出前应用为真实几何（glTF 路同 Blender 导出器 apply） | 几何精确，参数化语义丢弃入账 |
| GPU 实例化（Geometry Nodes 实例化 / 粒子） | **v1 无表达**：逐实例矩阵表无格式面（TODO §7.2 GAP-B5 已登记候裁）；约定处置 = 展开为 node 实例（数量上限由导出方把握并入账 SYNTH 行数）或响亮拒绝，禁止静默截断 | 缺口候裁，不在本约定内扩格式 |

材质覆写歧义由既有裁判兜底（`Sax3dMaterialOverrideAmbiguous`）：
实例 node 覆写 material 时必须全 primitive 一致口径，否则响亮失败，
不许转换器自选。

## B3. Principled 材质型廓（规范参数表，A/B 同表）

本表是 Blender Principled BSDF → SAX3D/slasl 的**唯一规范映射表**：
A 部（资产/转换器）与 B 部（slasl `principled()` 一等构造，
crates/slasl/DESIGN.md §9）共用此表，任何一侧改表必须两侧同改。

分层口径：**型廓内** = StdPbr/StdPbrSkinned 标准着色器 v1 接口
（converter/fixtures/std_pbr*.iface.txt：参数 base_color/roughness/
metallic + 贴图 base_color_map + 输入 position/normal/uv[/joints/
weights]）；**格式内型廓外** = SAX3D 格式允许自定义 shader 接口声明
任意参数/贴图（SPEC §5.5），但不属标准型廓，转换器不自动绑；
**近似** = 型廓内求值但与 Eevee 有声明偏差；**不覆盖** = 响亮入账，
禁止静默丢弃。

| Principled 输入 | 型廓处置 | 落点 / 偏差 |
|---|---|---|
| Base Color（RGB） | 型廓内，精确 | 参数 `base_color` 的 rgb（SPEC §5.5）；贴图 → `base_color_map`（色彩空间 srgb，B4） |
| Alpha | 型廓内，精确 | `base_color` 的 a；混合模式 → material state（glTF alphaMode 同路） |
| Metallic | 型廓内，精确 | 参数 `metallic`（f32）；贴图形式属格式内型廓外 |
| Roughness | 型廓内，精确 | 参数 `roughness`（f32）；贴图形式属格式内型廓外 |
| 法线（Normal Map 节点） | 型廓外 | StdPbr v1 无 normal_map 槽；转换入账 LOSS/不支持，自定义 shader 可声明 |
| IOR / Specular IOR Level | 近似 | 型廓求值以 F0 介电常数 0.04 固定（slasl principled 偏差声明）；IOR 不入参 |
| Emission（Color/Strength） | 不覆盖 | StdPbr v1 无自发光参数；入账，不许并入 base_color |
| Subsurface / Sheen / Coat / Anisotropy / Transmission / Volume | 不覆盖 | 全部入账响亮拒绝（slasl 节点矩阵同口径，BLENDER_NODE_MATRIX.md） |
| 求值（直接光） | 近似 | slasl `principled()`：Cook–Torrance GGX + (1−metallic) 漫反射，单直射光、无 IBL/阴影；与 Eevee 的多光源/探针求值差为声明偏差 |

Blender 侧前置条件：Principled 的 Base Color 若由节点网络驱动
（贴图/混色/程序纹理），导出的是**烘焙后贴图或常数**——节点网络本身
不进资产（节点面归 slasl 摄入面定形，TODO §8；本批只定形不实现）。

## B4. 贴图管线约定补强

**色彩空间必填映射表**（SPEC §5.4：image 的 color_space 必填、二值
`srgb|linear`、永不猜测；校验器实证：缺失或非二值即
`Sax3dInvalidValue`——"must be declared srgb|linear (never guessed)"，
src/check.zig）：

| Blender 图像色彩空间 | SAX3D color_space | 备注 |
|---|---|---|
| sRGB | `srgb` | 颜色类贴图（Base Color 等）的唯一合法值 |
| Non-Color | `linear` | 数据类贴图（roughness/metallic/法线等） |
| Linear | `linear` | 线性工作空间数据 |
| 其余（Linear ACES、XYZ、Raw 别名等） | **无映射** | 二值枚举装不下 → 导出响亮拒绝并提示改设 sRGB/Non-Color，禁止就近取舍（TODO §7.1 ④ 的「归一」以拒绝+指路实现，不静默归一） |

**tex_transform 写法规约**（SPEC §5.5：`offset [x,y]` / `scale [x,y]` /
`rotation`，弧度、绕 (0,0) 旋转后平移的组合语义以 SPEC 为准）：

- 恒等变换**省略整块**，不写零值块（减体积、避歧义）。
- 只写实际偏离恒等的分量组：offset/scale/rotation 三组各自独立，
  缺组按恒等（scale 缺省 [1,1]）。
- Blender Mapping 节点（Location/Rotation/Scale）→ tex_transform 时
  注意坐标系：Blender 纹理空间与 glTF/UV 的 Y 方向相反，导出方负责
  在写入前完成翻转换算并在台账记 APPROX 一行（换算规则随导出器，
  结果以 UV 采样点对拍为准）；SAX3D 内只存换算后数值，不存来源系。
- KHR_texture_transform（glTF 路）与 SAX3D tex_transform 字段同构，
  转换器逐字段直搬（CONVERTER_MAP §2 既有口径）。

**采样器**：SPEC §5.4 五字段必填（形式从 SPEC）；Blender 图像的
插值（Linear/Closest/Smart）与扩展（Repeat/Clip/Extend）映射到
filter/wrap 时，无对应档位者入账 APPROX，不许默认 Repeat 掩盖。

## B5. 保真台账 Blender 专册

转换台账的 Blender 专册已并入 CONVERTER_MAP.md 附录（与 glTF 专册
同格式：构造 → 等级 → 说明），本文不另立第二台账。等级口径从
CONVERTER_MAP §0：精确 / 近似（APPROX） / 不支持（响亮） / 合成
（SYNTH） / 丢失入账（LOSS）。

## B6. 缺口登记（本批停条 / 候裁）

- SPEC 文件完整性：本仓 SPEC.md 在 §7 规则 3 中途截断（文件尾有字面
  截断标记，规则 4 起与正文引用的 §9 不在文件内）。本批硬约束 SPEC
  零改动，故不在本批修复；已登记回主会话（见 ENRICH_REPORT），
  修复应从 sax3d 源仓取全文比对后单独成批。
- 其余 §7.1 五条经核均可在现行格式内落地，无新增格式缺口；
  GAP-B1…B5（相机/灯光/世界/自定义属性/GPU 实例化）为 TODO §7.2
  既有候裁，本批不重复登记、不动。

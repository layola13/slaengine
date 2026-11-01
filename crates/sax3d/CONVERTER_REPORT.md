# SAX3D ↔ glTF/GLB 双向转换器报告（Phase 2）

一句话结论：**双向转换器已落地并通过往返验收**——真实样本
Khronos **Fox.glb**（蒙皮 24 关节 + 3 动画）完成 glTF→SAX3D→glTF
全往返，21 项等价对拍全同；两个 SAX3D 工作例完成
SAX3D→glTF→SAX3D 往返，段以 (kind,len,sha256) 多重集全等、声明按名
全保留。验收脚本 `tests/run_convert.sh` **24 项全过、失败集为空**；
v1 验收回归 62/62 不变绿。**本批未改 v1 冻结 SPEC**（转换中发现的
格式面事实均按映射表/台账处置，无一例在转换器里绕，见 §5）。

工地：同 v1（`~/workspace/sax3d-impl-local/`），转换器
`tools/convert.zig`（子命令 `to-sax3d` / `to-gltf`），构建并入
`build.zig`。映射规范 = `CONVERTER_MAP.md`（先表后码，每构造
采/近似/响亮不支持分类）；本报告是其执行记录与逐项台账汇总。

## 1. shader 槽处置（任务书要求定明并给理由）

- **进口（glTF→SAX3D）**：绑具名标准 PBR SLASL shader。理由：
  ① SAX3D 裁判要求材质的 shader 引用必达，不绑则一切产物皆非法；
  ② glTF 的 pbrMetallicRoughness 参数集就是标准 PBR 模型，与标准
  PBR shader 接口是同一语义面的两种记法，绑定是补名而非捏造；
  ③「显式未绑」在本格式无合法表达（封闭词表无 unbound 语法位）。
  置换族共 8 个（蒙皮 × UV 输入 × 基础色贴图三轴，真实标准 shader
  的置换模型）：`StdPbr / StdPbrNu / StdPbrNt / StdPbrNtNu /
  StdPbrSkinned / StdPbrSkinnedNu / StdPbrSkinnedNt /
  StdPbrSkinnedNtNu`，接口夹具在 `converter/fixtures/`，逐材质的
  绑定选择逐项进台账。
- **出口（SAX3D→glTF）**：shader 名写入材质 `extras.sax3d_shader`
  随资产留存；标准 shader 记 APPROX（语义已由 PBR 参数集表达），
  自定义 shader 记 LOSS（逻辑不可表达，仅参数近似）。标准性判定 =
  名字前缀 `StdPbr` 或调用方 `--std-shader <名>` 显式声明，不靠猜。

## 2. 真实样本（Fox）全往返证据

样本：`converter/samples/Fox.glb`（Khronos glTF-Sample-Models，
162,852B，sha256 `d97044e701822bac5a62696459b27d7b375aada5de8574ed4362edbba94771f7`；
1 网格非索引绘制、蒙皮 24 关节、3 动画 × 21 通道、1 PNG 贴图、无扩展）。

- 进口产出：133 个载荷段，内部裁判一次通过；台账全量 11 条
  （LOSS 1：skin.skeleton 根提示丢弃——纯优化提示无语义；
  APPROX 1：NORMAL 缺失派生法线，非索引几何逐面精确；
  SYNTH 9：image/texture/skeleton/scene/primitive/采样器补名 +
  fox_material 绑 StdPbrSkinned）。
- 经 `sax3dc build` 外部裁判再验通过（183,678B .saxb3d）。
- 出口往返等价（`tests/fox_equiv.py`，21/21）：POSITION /
  TEXCOORD_0 / JOINTS_0 / WEIGHTS_0 accessor **字节全同**；
  IBM 字节全同、关节数 24=24；3 动画的通道键集（节点名 × 路径）
  与每通道采样器输入/输出字节 + 插值全同（63 通道）；材质
  metallic 0 / roughness 0.58 / baseColorTexture 在位、
  `extras.sax3d_shader = StdPbrSkinned`；节点名集 26=26；
  图像字节全同（26,764B）；GLB 结构复验通过。

## 3. 工作例往返（SAX3D 可表达子集）

- **cube**：出口台账 2 条 APPROX（raw 图像无损 PNG 编码；标准
  shader 名留存）。再进口绑定 StdPbr。再进口产物过裁判 + build。
  等价口径：段 (kind,len,sha256) 多重集全等（段名由转换器按规范
  重生，非语义）；声明按名全等（shader 名除外——标准重绑，映射表
  明定）；图像以像素级验：导出 PNG 解码 == 原始 raw 16B 逐字节同。
- **hero**：出口台账 6 条（LOSS 3 + APPROX 3，逐项见 §4）。
  再进口绑定 StdPbrSkinnedNt（skin_map 绑定已在出口按表丢弃，
  故贴图轴置换变化——台账可溯）。等价：段多重集全等、声明按名
  全等（shader 除外）；图像字节守恒以 sha256 直验（外部文件 →
  内嵌段，哈希同）。共享时间轴段经「按源 accessor 去重」保持
  单段（实施中先试过按字节内容去重，在全零载荷下误并不同角色
  段触发 kind 冲突被内部裁判拦下，已改按 accessor 同源去重——
  此事如实记于此，不掩盖）。

## 4. 逐项台账汇总（零静默的执行面）

**方向二（SAX3D→glTF）的丢失/近似全项**（本批资产实际触发的）：
| 资产 | 项 | 类 | 处置 |
|---|---|---|---|
| hero | param `tint` | LOSS | glTF PBR 无对应参数，丢弃并记名 |
| hero | texture binding `skin_map` | LOSS | StdPbr 进口接口无此槽；导出时绑定丢弃，纹理本体仍以 textures 条目留存 |
| hero | state `depth_write=true` | LOSS | glTF 核心无对应；记入 `extras.sax3d_depth_write` |
| hero | metallic 未设且夹具无默认 | APPROX | glTF 默认 1.0 显式写出（保语义） |
| hero | 路径源图像 | APPROX | 内容内嵌 bufferView，路径引用本身不保留 |
| cube/hero | shader 名（标准） | APPROX | PBR 参数集表达语义，名入 extras |
| cube | raw-rgba8 图像 | APPROX | 无损 PNG 重编码，像素全同（已验） |
| Fox（回程） | shader StdPbrSkinned | APPROX | 同上 |

**方向一（glTF→SAX3D）的合成/近似全项**（Fox 实际触发）：
补名 8 处（image/texture/skeleton/scene/primitive/3 clip 采样器）、
标准 shader 绑定 1、派生法线 1、skin.skeleton 提示丢弃 1（LOSS）。

映射表中已定但本批资产**未触发**的响亮面（实现已在，语料未及）：
sparse accessor、多 primitive 拆分/共用索引、JOINTS u8 拓宽、
WEIGHTS 归一化转 f32、indices u8 拓宽、节点材质覆盖克隆
（出口）、多 primitive 索引重叠标注、KHR_texture_transform、
emissive/额外纹理槽的响亮拒绝、extensionsRequired 拒绝。

## 5. 格式面事实登记（未改 SPEC，按约停报主会话）

转换逼出的三点格式事实，均属 v1 已冻结面的性质而非缺陷绕道：
1. **SAX3D v1 primitive 无索引范围**：多 primitive 网格出口 glTF
   必然重叠绘制（映射表已标近似）。若将来要根治，须 SPEC 级给
   primitive 加 index offset/count——属格式演进裁定，不在本批。
2. **raw-rgba16f 出口无无损 glTF 形**：PNG16 是整数语义，f16 载荷
   直塞即数值重解释；转换器以 `CvtUnsupportedImageFormat` 响亮
   拒绝（已实现）。是否引入 KHR 纹理扩展或 f16→f32 提升规则，
   待裁定。
3. **材质纹理槽位由 shader 接口决定**：出口绑定名 ≠ base_color_map
   即无 glTF 槽（如 hero 的 skin_map）。这是「材质参数面 = 接口面」
   纪律的直接后果，台账逐项可见；将来 SLASL 标准 shader 若定义
   更多标准槽名，映射表可平滑扩充。

## 6. 未证清单（如实）

- 映射表标注的未触发响亮面（§4 末段）只有实现、未建语料逐项验；
  其中 JOINTS u8 拓宽 / WEIGHTS 归一化两条值变换路径未被任何
  本批资产走到（Fox 是 u16+f32 的干净组合）。
- 真实样本只取了 Fox 一例（任务书下限「至少一个」已达）；
  CesiumMan 等带法线/索引的样本未测——其路径（索引网格、现成
  NORMAL）由 hero/cube 两例的构造覆盖，但未在真实资产上复证。
- 往返等价的材质参数面只验了「按映射表的有效值」（因子逐项比），
  未做渲染级对拍（无渲染器在本线范围）。
- 转换器对超大资产（数百 MB 级）的内存/耗时未测（全量驻内存
  模型）；Fox 163KB 级别瞬时完成。
- to-gltf 的节点材质覆盖克隆路径已实现但两例均无覆盖节点，
  未被走到（v1 负例 neg_material_override_ambiguous 证明覆盖
  语义存在；转换器克隆分支待后续语料补验）。

## 7. 验收总账

`tests/run_convert.sh`：**24 passed，FAILED SET 为空**（Fox 段 8 +
cube 段 8 + hero 段 8）。`tests/run_tests.sh`（v1）：**62 passed，
失败集为空**（含 iface 标量默认值扩展后的回归）。两脚本均可重跑、
自包含。

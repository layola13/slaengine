# SAX3D v1 实施线终报

一句话结论：**SAX3D 格式 v1 已按全部裁定落地并冻结（SPEC.md），工具链
`sax3dc`（校验/构建/打包）+ 回读验收全绿——验收脚本 `tests/run_tests.sh`
62 项全过、失败名字集为空；双形态（拆分/合并）逐段等价、裁判同结论。**

工地：`~/workspace/sax3d-impl-local/`（staging only，未推送、未动任何仓）。

## 1. 交付物清单

| 交付 | 路径 |
|---|---|
| schema 单一真理源 | `sax3d.sai` + `tools/gen_schema.zig` → 生成 `src/schema_gen.zig` |
| 解析器/词法 | `src/lexer.zig`、`src/parse.zig`（双模 authoring/compiled） |
| 模型/接口夹具 | `src/model.zig`、`src/iface.zig` |
| 裁判校验器 | `src/check.zig` |
| 布局/名表/二进制 IO | `src/layout.zig`、`src/binio.zig`（布局全取 schema 生成表） |
| 编译形发射器 | `src/packform.zig` |
| 工具链 CLI | `src/main.zig`（`sax3dc check/build/pack`），`build.zig` 统一构建 |
| 回读验收工具（非加载器） | `tools/readback.zig` |
| 参照件/载荷生成（验收专用） | `tools/genref.zig`、`tools/genpayload.zig` |
| 工作例 | `examples/cube.sax3d`、`examples/hero.sax3d` + 两份 iface 夹具 + `hero_tex.png` |
| 负例语料 | `tests/negative/`（22 件，`tests/gen_corpus.py` 由合法基线单点变异生成）+ `tests/valid_control.sax3d` 合法对照 |
| 冻结规格 | `SPEC.md`（含 §11 偏差变更日志） |
| 验收脚本 | `tests/run_tests.sh`（自包含可重跑） |

## 2. 逐项证据

### 2.1 schema 单一真理源
`gen_schema` 自 `sax3d.sai` 生成表并断言结构尺寸（头 32B/记录 32B、
字段偏移逐个与 .sai 声明对齐，mismatch 即响亮失败）；写入器与回读器
只用生成表。验收 0 号项重生成与入库表对拍一致（`schema-fresh` PASS）。

### 2.2 立方体例端到端（设计 §8 算例逐字复现）
`check` 输出 VALIDATION OK，段布局与设计表逐项相同：

| 段 | kind | 偏移 | 长 |
|---|---|---|---|
| positions | channel | 256 | 288 |
| normals | channel | 544 | 288 |
| uvs | channel | 832 | 192 |
| indices | index | 1024 | 72 |
| checker | image_raw | 1096 | 16 |
| spin_times | anim_input | 1112 | 8 |
| spin_rots | anim_output | 1120 | 32 |

载荷终点 1152（= 设计总长口径）；拆分形文件总长 1211B（+ 名表 59B，
SPEC §11 D-2 口径）。

### 2.3 蒙皮动画例端到端（第二例：skin + morph + 双通道动画）
4 顶点蒙皮网格（joints0/weights0 成对）、2 关节骨骼（Root/Tip）、
1 个 morph（Smile）、clip Wave 双通道（Tip 的 rotation + HeroNode 的
weights）、路径源图像 1 张（打包时内嵌）。VALIDATION OK，布局：
base 384（11 段），hero_pos 384 / hero_nrm 432 / hero_uv 480 /
hero_joints 512 / hero_weights 544 / hero_idx 608 / hero_morph_pos 620 /
rig_ib 668 / wave_times 796 / wave_rots 808 / wave_weights 856，
载荷终点 868。两形尺寸：拆分二进制 984B、合并形 2799B。

### 2.4 双形等价（F-2 补定验收）
两例各走双形：readback 拆分形与合并形均 READBACK OK；规范等价摘要
（段 名/kind/长/sha256 + 声明 种类/索引/名）排序后逐行对拍——
**cube 14 行、hero 22 行，两例皆逐行全同**（含 hero 的路径源图像：
拆分侧以外部文件伪段入摘要、合并侧以内嵌段入摘要，同名同 kind
同哈希）。打包确定性：同资产连打两次逐字节相同（`cmp` 验）。
裁判同结论由结构保证：同一解析器 compiled 模式读回编译形组装、
同一校验器复检；负例资产被打包器在校验阶段以同一诊断拒绝。

### 2.5 负例语料（22 件 + 对照 + 缺夹具，全部首诊断命中）

| 文件 | 期望诊断 | 文件 | 期望诊断 |
|---|---|---|---|
| neg_unresolved_ref | Sax3dUnresolvedReference | neg_section_overflow | Sax3dSectionOverflow |
| neg_undeclared_param | Sax3dUndeclaredParam | neg_unknown_channel | Sax3dUnknownChannel |
| neg_param_type_mismatch | Sax3dParamTypeMismatch | neg_transform_conflict | Sax3dTransformConflict |
| neg_unbound_param | Sax3dUnboundParam | neg_material_override_ambiguous | Sax3dMaterialOverrideAmbiguous |
| neg_undeclared_texture_binding | Sax3dUndeclaredTextureBinding | neg_anim_count_mismatch | Sax3dAnimCountMismatch |
| neg_unbound_sampler | Sax3dUnboundSamplerParam | neg_raw_image_size | Sax3dRawImageSizeMismatch |
| neg_channel_type_mismatch | Sax3dChannelTypeMismatch | neg_sampler_state_missing | Sax3dMissingSamplerState |
| neg_input_not_fed | Sax3dInputNotFed | neg_section_kind_conflict | Sax3dSectionKindConflict |
| neg_clip_target_missing | Sax3dClipTargetMissing | neg_joint_parent_mismatch | Sax3dJointParentMismatch |
| neg_skin_joint_not_node | Sax3dSkinJointNotNode | neg_parse_error | Sax3dParseError |
| neg_duplicate_name | Sax3dDuplicateName | neg_unknown_declaration | Sax3dUnknownDeclaration |
| 对照 valid_control（不给夹具） | Sax3dMissingInterfaceFixture | 对照 valid_control（给夹具） | 通过 |

每件以退出码 1 + 期望码出现 + 无 panic 三重断言通过。

### 2.6 二进制面负例（readback 损坏语料 5 件）
魔数改坏 → Sax3dBadMagic；version_major 改 9 → Sax3dUnsupportedVersion；
flags 置 1 → Sax3dBadFlags；首段 name_off 写越界值 → Sax3dNameTableMismatch；
文件截断至 100B → Sax3dTruncatedFile。全部命中且不 panic。

### 2.7 健壮性
512B 随机垃圾与空文件作组装文本：均以具名诊断退出、无 panic
（空文件缺 asset 头在实施中实测发现并补规则，见 SPEC D-6）。
载荷文件长度与声明不符 → Sax3dPayloadLengthMismatch，build 拒绝产出。

## 3. 体积对拍（用户 10:57 理据的实测）

同一立方体例、等价内容、四份包装实测字节（载荷同源；glTF 侧图像
只能 PNG 承载，生成真实最小 PNG：2×2 全零 RGBA、CRC/zlib/像素经
python 校验，与 raw 载荷像素一致；表示差如实计入不删改）：

| 形式 | 总长 | 描述性开销 | 载荷 |
|---|---|---|---|
| SAX3D 拆分形 | 2230（文本）+ 1211 = **3441** | 文本 2230（带大段注释）/ 去注释去空白 **902**；二进制内 315（头 32 + 段表 224 + 名表 59） | 896（几何+动画 880 + raw 图像 16） |
| SAX3D 合并形 | **2303** | **1407**（头 32 + 段表 256 + 编译形组装 973 + 名表 146） | 896 |
| glTF（.gltf+.bin） | **2554** | JSON **1588** | 966（几何+动画 880 + PNG 86） |
| GLB | **2584** | **1616**（头/块头 28 + JSON 块 1588） | 966（块内填充后 968） |

结论（按实测口径，不夸大）：
- **交付形对交付形：SAX3D 合并形 2303B < GLB 2584B（−10.9%）**；
  描述性开销 1407 vs 1616（−12.9%）。用户的理据成立且可测：
  布局由共享 schema 钉死不随资产携带、名字只在名表出现一次
  （本例 19 个名字共 146B）、引用是 `#<n>` 索引记号。
- 拆分形总量 3441 高于 glTF 的 2554，**原因是组装文本带 1300 余字节
  的教学注释**（去注释去空白后文本本体 902B）；拆分形是创作形而非
  交付包装，如实并列，不做口径掩盖。
- **规模注记**：本例是最小玩具资产，固定成本（头/段表/JSON 骨架）
  占比高，差距被稀释。结构性差距随声明数放大：glTF 每多一个
  accessor/材质/节点就多一份键名 JSON；SAX3D 每多一个声明只多
  一条名表项 + 索引引用，schema 侧零增量。此放大律是结构推论、
  本批只测了单点，如实标注为未做多规模实测。

## 4. shader 内嵌问题：按底线落地 + 候选包（交主会话裁）

按任务补定的底线执行：合并形中 shader **只按名入册、不内嵌源**
（SPEC §6.4 定版 + 四条理由）。「可选内嵌 .slasl 源段」是否立项
构成本线识别的真分叉，已在 SPEC §6.4 打包成候选（利弊双论）交
主会话裁定，本线未自裁、未因此阻塞其余交付。

## 5. 偏差清单（与 DESIGN.md 的差异，详见 SPEC §11）

D-1 头 reserved 细化为 nametab 指针（偏移/总长不变）；
D-2 §8 总长口径定版（1152 = 载荷终点，名表追加于尾）；
D-3 合并形机制 = 编译形组装段（F-2 修订落地）；
D-4 sampler 五字段必填收严；
D-5 角色/接口类型钉死（tangent f32x4、joints uvec4 等）；
D-6 asset 头恰一份强制（空文件假绿实测后补）；
D-7 bind/bounds/tex_transform 数值全保真入模型；
D-8 动画时间轴单调性归 build 数据级检查。

## 6. 未证/不在本版（如实登记）

- **真实 .slasl 接口表产物未接入**：绑定校验全程对人写夹具代演
  （GAP-1 的 v1 处置，与研究线原型同）；产物对接是后续批
  （SLA 宏线的声明登记机制在并行建设）。
- **图像内容不可解**：`hero_tex.png` 只是带 PNG 签名的不透明载荷
  （40B），不是可解码 PNG——格式层按设计永不解码（GAP-2 同根）；
  体积对拍中的 PNG 则是结构完整可解的真实 PNG，二者勿混。
- **无加载器**（裁定上层）：readback 是验收回读器，不构成交付的
  加载实现；格式侧契约完备性以 §4.5 解析产物为准。
- **glTF 互转不在 v1**：为 Phase 2 独立批次（用户 11:04 追加定形），
  续行交付 CONVERTER_REPORT.md，本报告不预支其结论。
- 体积对拍只测立方体例单点（任务书口径），多规模放大律未实测（§3）。
- 工具链为本地 Zig 构建产物，本批未做安装/分发形态（sap 插件化
  不在本线任务内）。

## 7. 验收总账

`tests/run_tests.sh` 一次全跑：**62 passed，FAILED SET 为空**
（schema 新鲜度 1 + 构建 1 + 立方体 17 + 蒙皮例 13 + 负例 24 +
损坏 5 + 健壮性 3 + 对拍 2，逐项名见脚本输出）。本机当时负载高
（DEF 主线收尾日），全部断言仍为确定性通过，无重试掩盖。

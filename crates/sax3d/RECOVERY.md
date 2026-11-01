# SAX3D SPEC.md 截断修复 · 恢复说明

修复批：2026-11-01（支线·文档完整性）。对象：本目录 `SPEC.md`。
本文件是恢复工作的证据账：丢失清单、逐段恢复 ↔ 证据对照、
诊断名 → 规则映射、文/码双向差异、存疑清单。恢复纪律 =
**恢复不是修订**：格式实质未改一字；凡恢复文字必有证据出处，
证据不足处标存疑、不冒充原文。

## 1. 丢失清单

- 截断形态：SPEC.md 在 §7 规则 3 中途断句（"…索引 = count ×
  元素长；inv"），文件尾有字面标记 `...[truncated 10203 chars]`
  ——工具截断视图被回写落盘。截断版全长 13254 字节。
- 无完好副本：本机五份副本（slaengine 各工地 + sax3d-impl-local
  源工地）与源工地 git 历史两提交，全部同为 13254 字节截断版
  （主会话核实，ENRICH_REPORT 订正条登记）。
- 丢失面：§7 规则 3 后半句起全部——规则 4 起的全部裁判规则、
  §8（算例）、§9（接口表）、§10（构建/打包）、§11（D-1…D-8
  偏差日志）。存续面：§1–§6 全文 + §7 规则 1、2 与规则 3 前半。
- 恢复后全长：24577 字节（13254 → 24577）。

## 2. 逐段恢复 ↔ 证据对照

证据等级：高 = 有逐字出处或代码执行体逐点对应；中 = 多源旁证
一致但无逐字原文；存疑 = 见 §5 清单。

| 恢复段落 | 证据 | 等级 |
|---|---|---|
| §7 规则 3 补全（inverse_bind = 关节数 × 64；anim input = count × 4、output = count × 元素长；不足 → SectionOverflow） | `src/check.zig`：checkOneChannel（count × elem size）、checkSkeletons（joints × 64）、checkClips（in_count × 4 / out_count × elem size）三处 SectionOverflow 验算式逐点对应 | 高 |
| §7 规则 4 封闭值集 | check.zig 全部 Sax3dInvalidValue 发射点：checkMeshes（topology/vertices/indices/无 primitive）、checkImages（format/color_space）、checkTextures→checkEnum（sampler 值集）、checkMaterials（alpha）、checkClips（interpolation/path）、checkSkeletons（缺 inverse_bind）、checkScenes（覆盖/skin 无 mesh）；main.zig build 无 binary 块同码 | 高 |
| §7 规则 5 通道律 | check.zig checkOneChannel + chanRoleType 白名单 + model.isCanonChannel：UnknownChannel / ChannelTypeMismatch / UnknownElemType / AttrNameReserved / MorphChannelInvalid / ChannelPairing 六码逐点 | 高 |
| §7 规则 6 骨骼律 | checkSkeletons：parent 必达（规则 2 码）+ 父链步数上限环检 → Sax3dJointCycle | 高 |
| §7 规则 7 关节-节点对应律 | checkSkeletonSceneCross（SkinJointNotNode / JointParentMismatch「最近关节祖先」算法）+ checkScenes skin 分支（SkinChannelMissing） | 高 |
| §7 规则 8 段用途律 | Ctx.useSection（SectionKindConflict）+ check() 尾段未引用段指派 blob；与存续 §4.3 正文互证 | 高 |
| §7 规则 9 图像与采样器律 | checkImages raw 分支（w×h×bpp 逐字相等，bpp 4/8）→ RawImageSizeMismatch；checkTextures（sampler 块/五字段必填，注释自注「v1 定形」）→ MissingSamplerState；wrap_w 值集校验同函数 | 高 |
| §7 规则 10 材质绑定律 | checkMaterials 全函数六码逐点；DESIGN.md §6.3「绑定检查（核心纪律）」段同义旁证（按名+按型、漏绑响亮、无默认则报错不许静默零值） | 高 |
| §7 规则 11 装配律 | checkScenes：TransformConflict（TRS 与 matrix 互斥）、MaterialOverrideAmbiguous（prims ≠ 1） | 高 |
| §7 规则 12 动画律 | checkClips：input 非 f32 → ChannelTypeMismatch；path→output 类型表；out_count ≠ in_count × per_key × factor（cubic-spline ×3）→ AnimCountMismatch；weights 的 per_key = 目标 mesh morph 数 | 高 |
| §7 规则 13 输入喂养律 | checkInputCoverage（InputNotFed）+ canonicalInputType 表 + 喂养相容性分支（ChannelTypeMismatch） | 高 |
| §7 规则 14 文法与夹具律 | parse.zig：128 行「missing asset header (exactly one required)」、135 行 duplicate asset、164 行 UnknownDeclaration、61 行 CompiledNameRef、各 fail() → ParseError；iface.zig FixtureError 两点；D-6 出处 REPORT §2.7（空文件实测补规则） | 高 |
| §7 规则 15 二进制面律 | binio.zig parseHeader（TruncatedFile/BadMagic/UnsupportedVersion/BadFlags）+ nameBlob（TruncatedFile）；readback.zig name_off 解析（NameTableMismatch） | 高 |
| §8 算例（cube 表 + 绑定对账） | DESIGN.md §8 表与 REPORT.md §2.2 表两处逐字同（256/544/832/1024/1096/1112/1120、终点 1152）；REVIVAL_REPORT §3 项 2 称之为「§8 算例」且 run_tests 15 项 offset 断言同轮实证；D-2 口径（1211 = 1152 + 名表 59）出自 REPORT §2.2 尾注；绑定对账出自 DESIGN §8 末段 | 高 |
| §9 接口表（三组结构 + 绑定要点 + 规范映射 + v1 夹具形态） | 存续正文三处引用 §9（文件头基线「接口表产物（§9）」、§5.5「绑定裁判全集见 §7 与 §9」、§6.4 理由 ②）；DESIGN §4（接口表 = 合并/DCE 后产物、可哈希、DCE 消除项消失）+ §6.3；iface.zig 头注释与解析代码（三段式、默认值标记、block 行跳过、FixtureError）；examples 两件 iface 夹具实物；规范映射 = model.zig channelInputName 逐字表、规范 input 类型 = check.zig canonicalInputType 逐字表 | 高（映射表逐字）；节标题为恢复拟名（中） |
| §10.1 打包 | 存续 §1 表「打包器 sax3dc pack 拆分→合并（§10）」；main.zig cmdPack 全流程（双向 SectionMismatch 三形态、内嵌变换、变换后复检、组装段居尾）；REVIVAL_REPORT §3 项 4「§4.5/§10 打包确定性」；存续 §4.5/§4.6 | 高 |
| §10.2 构建（载荷文件复核） | 存续 §2 表「段载荷文件（§10.2）」+ §5.1「写入器按实际载荷文件复核（§10.2）」两处交叉引用钉死子节存在与主题；main.zig cmdBuild（PayloadMissing / PayloadLengthMismatch 逐字相等 / anim_input 单调 → AnimInputNotMonotonic）；D-8 出处 REPORT §5 | 高 |
| §11 D-1…D-8 | REPORT.md §5 八行逐条为逐字出处（「详见 SPEC §11」）；各条与实现复核：D-1 = §4.1 存续表 nametab_off/len 占位；D-2 = REPORT §2.2；D-3 = §6 存续正文 + §4.3 kind 8；D-4 = §5.4 存续正文 + checkTextures；D-5 = §5.2/§5.7 存续钉死表 + canonicalInputType；D-6 = parse.zig + REPORT §2.7；D-7 = model.zig bounds_min/max、bind_t/r/s、tex_transforms 字段实存；D-8 = main.zig build 单调检查 | 高（条目集合与实质）；原文措辞不可考（中） |

## 3. 诊断名 → 规则映射表（全数覆盖）

清点口径：全仓代码（src/ + tools/ + converter/ + tests/）字符串
实测——`Sax3d*` 诊断码 **44 个**（另 Sax3dBinHeader /
Sax3dSectionRec 为 schema 类型名、非诊断，不入表；`Cvt*` 转换器
码 10 个单列于表末）。44 码全数映射如下，无遗漏、无虚构：

| 诊断码 | 落点 | 发射处 |
|---|---|---|
| Sax3dDuplicateName | §7 规则 1（+ 规则 10 内重名） | check.zig dupCheck / 各层内查重 |
| Sax3dUnresolvedReference | §7 规则 2 | check.zig refSection / findByName 各处 |
| Sax3dClipTargetMissing | §7 规则 2（动画面） | checkClips |
| Sax3dClipSamplerMissing | §7 规则 2（动画面） | checkClips |
| Sax3dSectionOverflow | §7 规则 3 | checkOneChannel / checkSkeletons / checkClips |
| Sax3dInvalidValue | §7 规则 4（+ §10.2 无 binary 块） | check.zig 多处 / main.zig |
| Sax3dUnknownChannel | §7 规则 5 | checkOneChannel |
| Sax3dChannelTypeMismatch | §7 规则 5（+ 规则 12、13） | checkOneChannel / checkClips / checkInputCoverage |
| Sax3dUnknownElemType | §7 规则 5 | checkOneChannel / checkClips |
| Sax3dAttrNameReserved | §7 规则 5 | checkOneChannel |
| Sax3dMorphChannelInvalid | §7 规则 5 | checkOneChannel |
| Sax3dChannelPairing | §7 规则 5 | checkMeshes |
| Sax3dJointCycle | §7 规则 6 | checkSkeletons |
| Sax3dSkinJointNotNode | §7 规则 7 | checkSkeletonSceneCross |
| Sax3dJointParentMismatch | §7 规则 7 | checkSkeletonSceneCross |
| Sax3dSkinChannelMissing | §7 规则 7 | checkScenes |
| Sax3dSectionKindConflict | §7 规则 8（+ 存续 §4.3） | Ctx.useSection |
| Sax3dRawImageSizeMismatch | §7 规则 9 | checkImages |
| Sax3dMissingSamplerState | §7 规则 9 | checkTextures |
| Sax3dMissingInterfaceFixture | §7 规则 10（+ §9） | checkMaterials |
| Sax3dUndeclaredParam | §7 规则 10 | checkMaterials |
| Sax3dParamTypeMismatch | §7 规则 10 | checkMaterials |
| Sax3dUnboundParam | §7 规则 10 | checkMaterials |
| Sax3dUndeclaredTextureBinding | §7 规则 10 | checkMaterials |
| Sax3dUnboundSamplerParam | §7 规则 10 | checkMaterials |
| Sax3dTransformConflict | §7 规则 11 | checkScenes |
| Sax3dMaterialOverrideAmbiguous | §7 规则 11 | checkScenes |
| Sax3dAnimCountMismatch | §7 规则 12 | checkClips |
| Sax3dInputNotFed | §7 规则 13 | checkInputCoverage |
| Sax3dParseError | §7 规则 14 | parse.zig fail() 全线 |
| Sax3dUnknownDeclaration | §7 规则 14（+ 存续 §5 封闭词表） | parse.zig |
| Sax3dCompiledNameRef | §7 规则 14 | parse.zig（compiled 模式） |
| Sax3dFixtureError | §7 规则 14（+ §9 夹具形态） | iface.zig |
| Sax3dBadMagic | §7 规则 15 | binio.zig / main.zig / readback.zig |
| Sax3dUnsupportedVersion | §7 规则 15 | binio.zig parseHeader |
| Sax3dBadFlags | §7 规则 15 | binio.zig parseHeader |
| Sax3dTruncatedFile | §7 规则 15 | binio.zig / main.zig / readback.zig |
| Sax3dNameTableMismatch | §7 规则 15 | readback.zig / main.zig cmdPack |
| Sax3dSectionMismatch | §10.1（+ 回读面） | main.zig cmdPack / readback.zig |
| Sax3dPackNameCollision | §10.1（+ 存续 §6.2） | main.zig cmdPack |
| Sax3dPayloadMissing | §10.2 | main.zig cmdBuild |
| Sax3dPayloadLengthMismatch | §10.2 | main.zig cmdBuild |
| Sax3dAnimInputNotMonotonic | §10.2（D-8） | main.zig cmdBuild |
| Sax3dIoError | 工具面（非格式规则，仅登记） | main.zig / readback.zig 读写失败 |

转换器面（归 CONVERTER_MAP 口径，不属 §7 校验器义务）：
CvtBadInput、CvtInternalInvariant、CvtSparseAccessor、
CvtUnsupportedElemType、CvtUnsupportedExtension、
CvtUnsupportedImageFormat、CvtUnsupportedNodeFeature、
CvtUnsupportedParam、CvtUnsupportedTextureSlot、
CvtUnsupportedTopology（tools/convert.zig）。

## 4. 文/码双向差异表

| # | 方向 | 差异 | 处置 |
|---|---|---|---|
| D-文码-1 | 文有码拒 | 存续 §5.2 文法 topology 值集含 `triangle-fan`；check.zig 校验器闭集 {triangles, triangle-strip, lines, line-strip, points} 不含之——声明 triangle-fan 的 mesh 会被判 Sax3dInvalidValue。而转换器双向均产/收 triangle-fan（convert.zig 796/1400 行 mode 6） | **只登记、不裁**：本批为文档恢复，无权改格式亦无权改码；§7 规则 4 已加注指向本项。候主会话裁决（补校验器闭集 或 修 §5.2） |
| D-文码-2 | 码有文外 | Sax3dIoError 为工具 IO 面诊断（文件读写失败），非格式规则 | 映射表登记为工具面；恢复 §10 未将其列为格式义务 |
| D-文码-3 | 码有文外（已归位） | Sax3dFixtureError 属 v1 夹具文件格式面 | 恢复入 §9 夹具形态 + 规则 14 |
| D-文码-4 | 文码细差 | 存续 §5.4 文法行列 wrap_w、必填口径称「五字段」；代码对 wrap_w 出现时验值集、不强制必填 | 恢复规则 9 按代码实情写「出现时同样验值集」；与 §5.4 不冲突（未禁第六字段），不改 §5.4 |
| D-文码-5 | 码注与节号出入 | check.zig 注释称通道白名单为「SPEC §6.1 定形」，存续正文实为 §5.2 钉死表（§6.1 是编译形组装） | 只登记（代码注释陈旧），本批不动代码 |
| — | 文已名码已行（无差异对账） | 存续正文点名的 SectionKindConflict（§4.3）、UnknownChannel（§5.2）、PackNameCollision（§6.2）、UnresolvedReference / ClipTargetMissing / ClipSamplerMissing（§7 规则 2）六码，代码同名实现逐一对位一致 | 无动作 |

## 5. 存疑清单（证据不足以定字句，已按恢复纪律标注）

- Q-1 §7 规则 4 起的**原编号与分组**不可考：恢复按执行体
  （check.zig 函数序）分组新编 4–15；原 §7 究有几条规则、
  如何分组，无证据。SPEC 文末恢复说明已注明编号为新编。
- Q-2 §8 是否同列 **hero 第二例**无直接证据：其实测布局
  （REPORT §2.3：base 384、11 段 hero_pos 384 / hero_nrm 432 /
  hero_uv 480 / hero_joints 512 / hero_weights 544 / hero_idx
  608 / hero_morph_pos 620 / rig_ib 668 / wave_times 796 /
  wave_rots 808 / wave_weights 856、载荷终点 868；拆分 984B、
  合并 2799B）仅登记于此，不入 SPEC 正文冒充原文（SPEC §8
  内已加存疑注记）。
- Q-3 §8 标题词「算例」有 REVIVAL_REPORT 旁证（其 §3 称
  「§8 算例」），等级中；§9、§10、§11 的**原标题**无旁证，
  恢复标题为拟名（主题由交叉引用钉死：§9 = 接口表、§10 =
  打包/构建、§11 = 偏差日志——此三点本身为高置信）。
- Q-4 §10 子节次序：§10.2 的存在与主题由存续 §2/§5.1 两处
  交叉引用钉死（高）；但「10.1 = 打包、10.2 = 构建」的编号
  分配系恢复推定（亦可能原稿先 build 后 pack），次序存疑。
- Q-5 §9 原节是否逐字列出规范映射表无证据：映射表内容由
  model.zig channelInputName 逐字恢复（内容高置信），其在
  原 §9 中的呈现形态存疑。
- Q-6 §11 各条原文措辞不可考：REPORT §5 为一行摘要，恢复
  条文据摘要 + 实现落点展开，条目集合与实质高置信、字句
  为恢复文本。
- Q-7 §7 规则 3 原文结尾形态：raw 图像「逐字相等」与规则 3
  泛述「≥」的衔接方式（例外句）为恢复安排；规则 9 的独立
  成条亦然（内容均有代码实证，呈现存疑）。

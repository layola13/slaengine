# ENRICH_REPORT — sax3d/slasl 丰富实施批（支线）

基点：slaengine main `8bd4a72`；工地 ~/workspace/slaengine-enrich-local；
staging 提交链（不推送）：6293e82（TODO 标注）→ 671b721（A 部）→
946a66e（B①②）→ 8f4969b（B③④⑤）→ 本报告。

**语言总则引用**（用户 2026-11-01 11:42 定）：slaengine 以 SLA 为主，
Zig、C、Python 为辅助。本批全部产物落在 SLA/文档面：slasl 编译器
本体即 SLA、sax3d 侧为约定文档与测试语料，零新增 Zig/C/Python 代码。

验收环境：二盒 /content/slaengine-rig/enrich（sci 83c61d43 + sla
e3d2023 rig 口径，source /content/tools/env.sh）；传输 sha256 双确认
（上行包 94618f16…、黄金回传 d22d30b7…，两侧一致）；harness 自带清
.sla-cache。盒上窗口与主线错峰（本批仅 8 次短 ssh）。

## A 部（crates/sax3d，TODO §7.1 五条）——SPEC 零改动

| 条 | 落地形态 |
|---|---|
| ① 同名对应 | `crates/sax3d/BLENDER.md` B1：骨骼名→glTF node 名→SAX3D node 名==joint 名的对应链成文；追认转换器 NamePool 既有行为（清洗/去重改名全入台账 SYNTH、对应以 claimed 名为准、joint parent 取最近关节祖先）；Blender `.001` 后缀等四种命名情形处置表；校验兜底引既有负例四件。新增转换器校验用例 tests/run_convert.sh §D（tests/gen_same_name.py 生成最小蒙皮 glTF 两件：SkinMin 正例 + SkinDup 同名改名例） |
| ② 集合/实例 | BLENDER.md B2：集合压平为 node 父子、集合实例/关联复制 = 多 node 引同一 mesh（SPEC §5.6 既有面）、修改器应用后导出；GPU 实例化无面 → GAP-B5 既有候裁，约定展开入账或响亮拒绝 |
| ③ Principled 型廓 | BLENDER.md B3 规范参数表（型廓内/格式内型廓外/近似/不覆盖四分），与 B 部 slasl `principled()` 构造**同表**（DESIGN §5.4 互引） |
| ④ 贴图管线 | BLENDER.md B4：色彩空间必填映射表（sRGB→srgb、Non-Color/Linear→linear、其余档响亮拒绝不归一）；tex_transform 写法规约（恒等省略、分组缺省、Y 翻转换算入账）。实证订正：缺失/非法色彩空间的校验诊断为 `Sax3dInvalidValue`（src/check.zig），非推测的具名码 |
| ⑤ 保真台账 | CONVERTER_MAP.md 附录 B「Blender 专册」（16 行，等级口径从其 §0） |

**验收**（二盒复跑）：run_tests **62 passed、FAILED SET 为空**（与地基
口径逐项一致）；run_convert **32 passed、FAILED SET 为空** = 既有 24
（Fox 往返等价 fox-roundtrip-equiv 在内全过）+ 新增 §D 8 项全过
（skinmin-import/joint-parent/channel-target/referee-build、
skindup-import/ledger-dedupe/joint-renamed/channel-renamed）。

## B 部（crates/slasl，TODO §8 P1，按序）

| 条 | 落地形态 |
|---|---|
| ① UBO 对齐复核 | `crates/slasl/BLENDER_UBO_REVIEW.md`：发射器实证四事实（按名成块/活字段裁剪/es100 拍平/接口表为合同）→ 对齐判定（按名绑定 ✅、std140 ✅、块成员恒等为声明偏差、es100 拍平为观察项）→ 宿主纪律三条（按 shader 建 UBO、按名绑定、es100 避跨组同名）；DESIGN §7.4 已补复核结论段 |
| ② 节点覆盖矩阵 | `crates/slasl/BLENDER_NODE_MATRIX.md`：Blender 参照克隆 nodes/shader/nodes 全集 **100 行**逐节点处置 —— ● 已覆盖 23 / ◐ 近似 24 / ○ 未覆盖响亮拒绝 47 / 内部不适用 6；文末节点图摄入面**定形**（JSON 中间表示来源、求值化规则、○ 的具名拒绝要求、多输出/未连插口处置），本批不实现摄入器 |
| ③ Principled 构造 | 编译器实现（src/slasl.sla）：`principled(vec3,float,float,vec3,vec3,vec3,vec3)->vec3`，Cook–Torrance GGX 直接光求值，八方言 helper 按 stage 用到才发；签名钉死于检查器，误用 `ShaderConstructError` 具名拒绝 |
| ④ 探针构造 | `probe_sphere` / `probe_volume`（sampler2D, vec3）-> vec4：等距圆柱映射采样；sphere=预过滤辐射度（反射向）、volume=辐照度（法线向），差异在资产内容契约；采样器按既有 `.get` 规则成对展开（HLSL/WGSL/MSL `_sampler`、Unity `sampler<名>`、Unreal `<名>Sampler`）；声明限制：无粗糙度 LOD（需带 LOD 采样面，后续立项） |
| ⑤ AgX 构造 | `agx(vec3)->vec3`：自研拟合——log2 编码（自选 EV 窗 −6…+6）→ 幂 S 曲线（指数 2.4 自选）→ 亮度驱动高光去饱和；**未使用 Blender 代码或 OCIO 数据**，与真 AgX 偏差已在 DESIGN §5.4 声明 |
| 附带 | 数学内建集同批落地（dot/cross/normalize/length/reflect/pow/sqrt/log2/exp2/abs/floor/sin/cos/sign/clamp/mix/max/min；同名直发、仅 HLSL 家族 mix→lerp；签名不合 `ShaderDimensionMismatch`、未知调用名 `ShaderUnknownCall` 响亮拒绝）——矩阵中多个 ● 行以此为依据 |

**验收**（二盒复跑）：run_tests **75 PASS、fails=0** = 既有 53 口径
全过（gate1 八产物 + 既有 samples 逐字节 cmp 通过 = **既有黄金零
漂移**）+ 新增 22（9 个 sample 的 16 件产物黄金 + 6 个负例）。
新黄金经眼检（constructs-es300 frag 全文：helper 形态、放置、
调用点均正确；helper 只发在使用 stage——vert 文件零 helper；
纯内建 sample 零 helper 发射）。新负例覆盖：principled 元数/类型、
probe 非采样器、agx 类型、dot 维度不合、未知调用名，五类响亮拒绝
+ principled 类型共 6 件。

## 附带小事

TODO.md「Python 相处」设计点已标注**已确认采纳（2026-11-01 主会话
确认）**（6293e82）；文末普查脚注为来源记录、未动。

## 停条 / 缺口登记

1. **SPEC.md 文件完整性缺口（停条性登记，回主会话）**：slaengine 仓内
   `crates/sax3d/SPEC.md` 在 §7 规则 3 中途截断，文件尾有字面截断
   标记 `...[truncated 10203 chars]`，规则 4 起与正文引用的 §9 不在
   文件内。本机五份副本（sax3d-impl-local 源工地与 slaengine-local /
   slaengine-p0-local / 本工地 / slaengine-saxport-local）sha256
   全部恒等（76f72952d3ad…）、全部同样截断——截断在 sax3d 实现线
   工地即已存在、先于 slaengine 复制。本批硬
   约束 SPEC 零改动，**未修复**；影响面 = 本批约定只能引 §§4–6 与
   §7 规则 1–3（五条约定所需规则均在此范围内，未受阻）。修复建议：
   先查 sax3d-impl-local 的 git 历史有无截断前版本；若无，须以
   §§4–6 既有规则与校验器实现反推补写 §7 余下规则，单独成批订正。
2. **候选 DEF（slasl 检查器，未修）**：target=glsl-es100 时跨组
   @global 字段重名不被检查器拦（AST 层按组作用域合法），落驱动层
   才报错。建议规则：es100 发射前以 ShaderDuplicateName 拒绝。本批
   B① 为复核面、DEF-2/3/4 亦不在范围，仅登记（见 BLENDER_UBO_
   REVIEW.md 结论节）。
3. A 部五条无一因格式缺口停条；GAP-B1…B5 为 TODO §7.2 既有候裁，
   本批未动、未重复登记。

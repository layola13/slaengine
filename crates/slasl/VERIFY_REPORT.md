# SLASL 二期独立复核报告（VERIFY_REPORT）

日期：2026-11-01。复核线：主会话欠账的验收复核（独立于实现线）。对象：`~/workspace/slasl-p2-local/` 二期交付（staging 提交 `f85863b` / `e295237` / `82b2165` / `dc8c799`，未推送）对一期 DESIGN（`~/workspace/sla-shader-local/DESIGN.md`）与二期 REPORT 的声称逐项核验。**本线只复核，未改实现、未推送。** 缺陷只登记最小复现。

## 0. 复核 rig 与方法

- 盒：二盒（25024，hostname `5586cbdbf3e3`；一盒当时有主线占用，本线全程二盒、与主线错峰）。
- 工具链：sci `83c61d43b5250f78bc5f3fbb76443e185e88dcb4`（盒上 `/content/sa_all/sci`，工作树干净）；sla **master `e3d2023a03134348222ced8d56205f5d4778d0d7`**——以盒上全量仓为基、fetch 增量 bundle（`sla-e3d2023.bundle`，head 即 e3d2023）后 checkout，工作树干净（porcelain 0 行）；HEAD 提交即 DEF-FLAT 语料提交（`tests/test_unit_def_flat_select_reachability.sla` 在册），`select_stmt` 分支在 `plugin_reachability.zig` 等 5 个源文件中 grep 命中（修复在树实证）。
- 插件：本线自建 `zig build -Doptimize=ReleaseFast`（rc=0）+ `sa plugin install --dev`（rc=0），**双确认**：installed `libsla.so` 与本轮构建产物 `cmp` 一致、大小同为 108,378,765 B、mtime 为本轮；标记字面量 `AmbiguousCall: call to` 在装机 .so 中命中。构建需 sci 树作同级 `../sci`（已软链至 sa_all/sci@83c61d43）。
- 构建环境实证：`sa build-exe src/slasl.sla` 需 `SA_STD_DIR=<sci>/sa_std`（`@import "sa_std/*.sai"` 的解析基）+ `SLA_STD_DIR=<sla>/sla_std`；矩阵四种组合实测仅此组合（及含它的超集）成功。此环境契约未随交付物落文（见观察 O-4）。
- 干净树：以二期工地 git HEAD 的文件集打包（src/shaders/golden/samples/samples_golden/neg/run_tests.sh 等，sha256 双侧确认 `8ce15e51…`）在盒上全新目录解压重建，不引用工地既有产物。
- 过程登记（复核线自身事故，不影响结论）：v1 脚本因 bundle 为增量包（缺前置提交 264211e9）克隆失败、v2 因缺 `../sci` 同级与 import 环境未明双双在 rig 段失败，均未产生任何关于实现的信号；v3 修正后全量跑通。探针输出目录曾被本线误清一次，已全量重生成，终证据均出自一致的 v3–v7 运行。

## 1. 交付清单核对（REPORT 声称 vs DESIGN 原文）

| # | 声称项 | DESIGN 出处 | 判定 |
|---|---|---|---|
| 1 | bundle 缺省 8 件（es300/es100 vert+frag、hlsl、layout_before/after、variants） | §8.2/§12.2 原型面 | **已验**（§2 逐字节） |
| 2 | glsl-es300 / glsl-es100 / hlsl 单目标 | §14 P2 | **已验** |
| 3 | webgpu：merged.wgsl + merged.reflection.json（强制同源反射清单） | §14 P2 紧随、§9.4 | **已验**（清单可解析、字段集与 §9.4 对应，§3） |
| 4 | msl：merged.msl | §14 P3 | **已验**（提前交付） |
| 5 | unity：merged.shader（URP 面、UnityPerMaterial 单 cbuffer、纹理宏三元组、无裸 .Sample） | §14 P3、§9.1 | **已验**（§3 抽验全中；但见设计差 D-u 与缺陷 DEF-1） |
| 6 | blender：merged.glsl（无 #version）+ merged_info.py | §14 P3、§9.3 | **已验**（#version 仅出现在说明注释中，指令本体无） |
| 7 | unreal-global：.usf + .ush + glue.cpp 三件套、bool @const 置换域 | §14 P3、§9.2 | **已验**（SHADER_PERMUTATION_BOOL + TShaderPermutationDomain 在 glue 中实证） |
| 8 | SPIR-V 未产出，口径冲突留主会话裁决 | §14 列 P4 | **已验（登记属实）**：未产出与设计分期一致；CLI 对 `--target spirv` 响亮拒绝（rc=2，`slasl: unknown target 'spirv'`），不静默 |
| 9 | 负例 21 件 + 对照，命名诊断 | §6.2/§8.4-4 | **已验**（§4；命名一致性有小疵，见 O-3） |
| 10 | 门 4：宏语料在 sla 树绿（原跑于 a121c04c） | §13 J 包落形语料 | **已验（现行头更强）**：本线在 e3d2023 复跑 4 正例 4/4（§5）；10 负例未复跑（见未验清单） |
| 11 | Jev 裁定落实表 J-1…J-8 / F-3 | §13 | 与产物形态一致（J-7 std 库本体 = 本工具；J-6 @const 仅字面量折叠由 neg const_nonliteral 实证；F-3 列 P4 已登记）；J-8 属导入方向，随 importer 未交付 |
| 12 | 有意偏离 3 条（init 环命名诊断、--check 全链接分析、override/置换域含未引用 @const） | — | **已验属实**：init_cycle 负例实印新诊断文本；probe C 中未被引用的 `STEPS: int` 确在 WGSL 以 `@id(1) override` 出现 |
| 13 | 「执行到 P2+P3 全量」 | §14 P3 含**导入方向开启（Shadertoy importer 子集 1）** | **不符（措辞级超报）**：importer 未交付，且未列入 REPORT 缺口清单（仅 notes/PLAN.md 以「as capacity allows」顺序隐含排除）。产物逐项声称本身无虚报，但「P3 全量」不成立 |
| 14 | Unity 变体数审计旁注 | §9.1/§7.5「发射前做变体数审计并旁注产物」 | **不符（设计差，REPORT 未声称亦未登记）**：merged.shader 内无变体审计旁注；仅 bundle 级 variants.txt 记 @const 取值，非逐目标审计 |
| 15 | Unity builtin（BiRP）兼容 flavor | §8.3/§9.1（urp 主 / builtin 兼容） | **部分交付**：仅 URP；REPORT 自述「URP 面」，未超报 |
| 16 | helper 函数、@range 消费、Mat3x4、SamplerCube/3D、TArray、Buffer/RWTexture、compute | §6.1 生产集、§14 P4 | 未交付、未声称，与分期一致（登记性提及：REPORT 缺口清单未逐项点名，靠分期表覆盖） |

## 2. 黄金复现（现行 rig、干净树重建）

- 仓内 harness `run_tests.sh` 全量复跑：**rc=0，fails=0**——门 1（bundle 对一期黄金）8/8 PASS、门 2（五目标样本黄金）9/9 PASS、门 3（负例）21/21 + 对照 PASS。
- 本线独立复现（不经 harness、自建目录、逐文件 `cmp`）：bundle 输出**文件集与 golden 恰等**（无多无缺），8/8 逐字节一致；8 个单目标全部 rc=0，冻结样本黄金逐字节一致（webgpu 2/2、msl 1/1、unity 1/1、blender 2/2、unreal-global 3/3，另 es300/es100/hlsl 与 bundle 黄金对应件一致）；reflection.json 可被 JSON 解析器正常解析。
- 锚点真实性：二期 `golden/` 与一期 Zig 原型 `proto/golden/` 本地 `cmp` **8/8 逐字节相同**——「对一期黄金对拍」的锚确为一期产物，非自封黄金。
- 确定性：同输入连跑两轮，8 件逐字节全等（DETERMINISM OK）。
- 链接序：CLI 文件序倒置（tint 在前、base 在后）重跑，8 件与黄金逐字节全等——priority 主导合并序、不依赖文件序（REPORT 未声称，本线额外实证）。
- 单目标模式不产 layout/variants 转储（仅 bundle 产），与 REPORT 产物清单一致（见 O-1）。

## 3. 覆盖抽验（目标 × 特性；黄金之外的新增探针）

探针源码见附录。在 base+tint 黄金之外实测生成并比对/目检：

| 目标 | 特性点 1 | 特性点 2 | 特性点 3 | 判定 |
|---|---|---|---|---|
| glsl-es300 | mat3 @param（探针 A3：std140 Params 块内 `mat3 rot` + `rot * position` 发射） | 双采样器 + 双 @global 组（A1a：tex/tex2 双 `uniform sampler2D`、Camera/Fog 两独立 std140 块、组字段访问拍平正确） | 标量 @const 入二元式 → **DEF-1**（`position * SCALE` 悬空名） | 前两项已验；DEF-1 |
| glsl-es100 | 黄金逐字节（texture2D、precision 头、uniform 逐个声明、无 UBO — 黄金实读） | init 依赖序纠正在产物中实证（tint_boost 先于 tint_pre） | @const 同族缺陷未单探 | 已验（黄金面）；DEF-1 同族未验 |
| hlsl | mat3 → `float3x3` + `mul(rot, …)`（A3） | register 落定（黄金：b0/b1/t0/s0 实读） | 标量 @const → **DEF-1** | 已验；DEF-1 |
| webgpu | 双 @global 组 → group 0 内 binding 0/1 两 buffer（A1a） | 双采样器 → group 1 内纹理/采样器拆对 binding 1–4（A1a）；@const float/int（含未引用）→ `@id` override（探针 C） | bool uniform 字段 → UnsupportedInBackend（负例）；反射清单解析 + offset 表（探针 C） | **已验**（唯一对 DEF-1 免疫：override 有声明） |
| msl | 黄金逐字节（metal_stdlib、[[attribute]]/[[buffer]] 形态实读） | 标量 @const → **DEF-1** | mat3 未单探（检查层已过） | 已验（黄金面）；DEF-1 |
| unity | UnityPerMaterial 单 cbuffer 含全部材质参数（黄金 + 探针 C 全文实读：tint2 入 cbuffer 且 Properties 有对应项） | 纹理宏三元组、无裸 `.Sample()`（黄金 grep 0 命中）；`#pragma target 3.5` 在位 | 标量 @const → **DEF-1**（SCALE 悬空，见附录 C 产物节选） | 前两项已验；DEF-1 |
| blender | 源码无 #version 指令（仅注释提及） | merged_info.py 为 GPUShaderCreateInfo 等价声明（vertex_in/fragment_out/uniform_buf/sampler + 具名 StageInterface，黄金实读） | 标量 @const → **DEF-1** | 已验；DEF-1 |
| unreal-global | bool @const → SHADER_PERMUTATION_BOOL 置换域（黄金 glue 实读） | 参数结构宏 BEGIN_SHADER_PARAMETER_STRUCT ×2、FGlobalShader 子类在位 | float/int @const 不入 glue（正确，非置换维）但 USF 内 **DEF-1** | 已验；DEF-1 |
| spirv | 未产出（设计 P4） | 两盒均无 glslangValidator / spirv-as / spirv-dis / tint / dxc（双盒实探） | CLI 响亮拒绝已验 | 未验（无产物无工具） |

另：DCE 行为在探针 A1a 上复证——`v_col`（写而未读）连同其唯一读者链上的 `rot`、`count` 被合法消除，layout_after 的 eliminated 段具名列出且给出理由（`no live read`），与黄金面口径一致。

## 4. 负例集判定

- 独立 `--check` 逐件（负例不用 test 运行器判读，合法对照单跑）：**21/21 rc=1 且输出含文件内 `// expect:` 预期诊断子串**；对照 `shaders/base.slasl` rc=0。原始输出首行全量留存于盒上 `/content/slasl-verify/negres/`，与 REPORT 门 3 的逐族归类（ShaderDuplicateName / ShaderStageViolation / ShaderDimensionMismatch / UnsupportedInBackend + 链接契约类）一致。
- 定位质量：诊断均带文件名，check 类带 shader 名，消息具体（出错标识符/类型/分量名都在内）。
- 平台记号（DESIGN §5.2 要求具名检查错误）：`layout(location = 0)` → parse error 且点名 `'layout'`（`unexpected member 'layout'`）——无专用诊断名，与 REPORT 缺口 #4 登记一致（判定：**与登记一致的不符**）；`#version` 行 → **比登记更差**，见 DEF-3。

## 5. 源码卫生

- `src/slasl.sla`（6224 行）在现行编译器（本线自建 e3d2023 插件）下 `sa build-exe` 成功（harness build ok；import 矩阵实证编译全过）。
- 仓内测试 = `run_tests.sh`：全过（§2）。
- 编译器侧语料抽验（现行头）：`test_unit_typed_macro_params`、`test_unit_macro_expr_output`、`test_unit_sublanguage_shader`、`test_unit_check_hook_audit` 以规范口径（仓根 cwd、清 .sla-cache、SLA_NO_FRESHNESS_CACHE=1、SA_SLA_FIXTURE_DIR、SA_PLUGIN_DEV=1）复跑，**4/4 rc=0 且输出 `test result: ok. 1 passed; 0 failed`**——REPORT 门 4 在旧头 a121c04c 的结论在现行 master 上保持。
- REPORT 声称的「零 String 值数据通路」为源码组织主张，本线未做源码审计，列未验。

## 6. 缺陷登记（最小复现；本线未修）

### DEF-1（正确性，高）标量 @const 嵌套于表达式时不折叠且不声明 → 产物含未声明标识符

- 现象：`@const SCALE: float = 2.0` 在 `vec4(position * SCALE, 1.0)` 中被原样发射为名字 `SCALE`，而任何后端（WGSL 除外）都不发射该 const 的声明 → 生成的 shader 在宿主侧必编译失败。同语句中裸作赋值右端的 `v_s = SCALE` 却被正确折叠为 `2.0`——折叠只覆盖右端为裸 const 标识符的形态。
- 实证范围：glsl-es300（vert 第 17 行）、hlsl、msl、blender（glsl）、unity（merged.shader vertex_main）、unreal-global（merged.usf 第 8 行）**六目标全部命中**；glsl-es100 同族未单探；webgpu 免疫（override 即声明）。
- 为何黄金未拦住：既有黄金中唯一的标量 const 是 bool 型 USE_TINT（作 if 条件、链接期折叠），无 float/int const 入二元式的样本。
- 最小复现：附录探针 C（`probe_c.slasl`），任一上述目标 `--target` 生成后 grep `SCALE` 只得使用处、无声明处。

### DEF-2（语言面，中）运行时复合条件 `if` 解析失败

- 现象：`if count > 1 { … }`（count 为 int @param）触发 `parse error: expected lbrace, got ''`（诊断中 token 文本为空，定位质量亦差）。裸标识符条件（@const bool 或 bool 名，见 tint 黄金）正常。
- 对照：附录探针 A1b（含 if，失败）与 A1a（仅删 if 块，其余 mat3/双组/双采样器/int 参数全同，`--check` rc=0）构成最小对照对。
- DESIGN 出处：§6.1 AST 的 If 条件可为「@const **或运行时值**」——运行时表达式条件在设计内。赋值位置的比较表达式未单测，缺陷边界以 if 条件为已证面。

### DEF-3（诊断，中）`#version` 类 `#` 行被静默吞掉并引发误导性链接错误

- 现象：合法 shader 首行加 `#version 300 es` 后，`--check` 不报词法/语法错误，而是报 `link error: merged vertex never writes clip_position`——该 shader 明明写了 clip_position。`#` 行显然被词法层无声消费且后续分析被扰动。
- 对照：附录探针 tok_version（含 # 行，rc=1 且诊断错误）与 tok_control（同文去 # 行，rc=0 `check ok`）。
- 与 REPORT 缺口 #4 的关系：该登记称平台记号「只在词法/语法层以 unexpected token 失败」——对 `layout(...)` 属实，对 `#` 行**不属实**（无声吞 + 误诊），登记低估了此面。

### DEF-4（健壮性，低-中）超大单结构体触发 PANIC 而非具名诊断

- 现象：单个 `@global struct` 含 5000 个 vec4 字段时，`--check` 即 `PANIC: code=87`（rc=215，进程崩溃）；1000 字段 --check 正常、2000 字段 webgpu 全量发射正常。阈值在 (2000, 5000] 区间，前端（解析/检查）层即崩，与目标无关。
- 期望形态：容量类具名诊断（如字段/节点上限点名），不应崩溃。复现配方见附录。

### 观察（非缺陷）

- O-1：单目标模式不产 layout/variants 转储，与 PLAN.md 工作注记字面（「single target + dumps」）有差，与 REPORT 产物清单一致。
- O-2：swizzle 字段赋值仅允许 var 目标（`frag_color.rgb = …` 被拒：`field assignment only on var in prototype`）——响亮且具体，属子集纪律；但诊断文案仍含 "prototype" 字样，生产工具的文案债。
- O-3：21 件负例中 5 件诊断无 `Shader*` 家族前缀（赋值不符、未定义标识符、链接契约/环/冲突类），均为具体文本 + 定位，仅命名一致性问题；J-5「钩子名前缀」口径大体成立、非全覆盖。
- O-4：交付物不自带 rig 说明——`run_tests.sh` 头注称「source rig.sh first」，但树内无 rig.sh，`SA_STD_DIR`/`SLA_STD_DIR` 环境契约未落文；新环境按 REPORT 无法独立复跑（本线靠矩阵试出）。属打包缺口，落地时应补。

## 7. 未验清单

1. **一切目标语言真编译**：两盒均无 glslangValidator / dxc / tint / Metal 工具链，Unity/Unreal/Blender 宿主不在盒上——与 REPORT 自述上限相同，本线双盒实探确认工具缺位。产物正确性证据止于逐字节黄金 + 结构抽验 + 本报告探针目检（DEF-1 正是在此层级被抓出）。
2. WebGPU 管线级验证（按反射清单建 pipeline + error scope）：需浏览器/WebGPU 运行时，未做。
3. WGSL 超预算响亮失败（DESIGN §9.4 第 1 条，如采样器数/绑定数超限点名）：未构造抽验（极端体积路径先被 DEF-4 截断；计数类超限未单造）。
4. DCE 分量级（swizzle 掩码）粒度（DESIGN §7.3）：现有证据只到 var 级消除 + 理由，分量级未单独造例。
5. glsl-es100 的 DEF-1 同族实证（仅同族推断，未单探）。
6. REPORT 门 4 的编译器侧宏负例 10 件：未在本线复跑（正例 4/4 已在现行头复跑）。
7. 「零 String 值数据通路」源码主张：未审计。
8. mat3 在 msl/unity/blender/unreal 上的发射（已验 es300/hlsl/wgsl 发射 + 全目标检查层）。
9. 导入方向（Shadertoy/Blender/Unreal importer）：未交付（§1 第 13 项），无可验对象。

## 8. 落地建议（供主会话立项）

**形态**：二期工地（4 提交）是一期 staging 的后继而非平行物——`DESIGN.md` 为一期副本、`shaders/` 与 `golden/` 是一期资产的超集、一期 Zig 原型（proto/）金文件与二期 golden 逐字节同锚。建议合并为**单一历史**：一期 staging 提交（DESIGN/测绘/probes/proto）在前、二期 4 提交在后；一期的 `probes/`（宏测绘语料）与 `proto/`（Zig 参考实现）作为谱系目录保留（proto 是语义参照与黄金来源，不宜丢），二期的 `work/` 探针（三个工具链缺陷的绕开证据）建议保留为 evidence 附录或在落地时转 DEF 分诊附件。

**落点**（按复核期间用户 2026-11-01 10:59 的新定案）：SLASL 不再单独成仓，随 **slaengine**（layola13/slaengine，workspace + crates 形态）以 **crate** 落位——原「目标仓待定」问题就此有解。crate 内容建议：`src/slasl.sla` 本体、`shaders/`、`golden/` + `samples/` + `samples_golden/`、`neg/`、`run_tests.sh`、DESIGN.md、REPORT.md 与本 VERIFY_REPORT.md，并**补 rig 说明**（O-4：SA_STD_DIR/SLA_STD_DIR 契约 + 插件构建口径），使 `run_tests.sh` 在新仓内可独立复跑。

**门槛建议**：DEF-1 命中六个目标的主流构造（标量 @const 入算术式），产物在宿主侧不可编译——建议将 DEF-1 修复（或至少链接层全表达式折叠 + 各后端 const 声明二选一）列为该 crate 对外称「可用」的前置门；DEF-2/3/4 可随批修复或显式登记为已知限制。SPIR-V（P4）、importer（P3 尾项，含 §1 第 13 项的口径更正）、F-3、compute 仍按 DESIGN §14 分期在后，不阻塞本次落位。

## 附录：复核探针（最小复现集，盒上原件存 `/content/slasl-verify/probes/slasl-probes/`）

### probe_c.slasl（DEF-1 复现；对照：WGSL 产物含 `@id(0) override SCALE: f32 = 2.0;` 为合法形态）

```slasl
shader ProbeC {
    priority 5;
    @input position: vec3;
    @const SCALE: float = 2.0;
    @const STEPS: int = 3;
    @param tint2: vec4;
    var v_s: float;
    vertex {
        v_s = SCALE;
        clip_position = vec4(position * SCALE, 1.0);
    }
    fragment {
        frag_color = tint2 * v_s;
    }
}
```

DEF-1 产物节选（unity merged.shader）：`output.v_s = 2.0;`（裸右端已折叠）与 `output.position = float4((input.position * SCALE), 1.0);`（嵌套未折叠），全文无 SCALE 声明。

### probe_a1b.slasl（DEF-2 复现）与 probe_a1a.slasl（对照，仅删 if 块）

```slasl
shader ProbeA1b {
    priority 20;
    @global struct Camera { view_proj: mat4; }
    @input position: vec3;
    @input uv: vec2;
    @param tex: sampler2D;
    @param tex2: sampler2D;
    @param rot: mat3;
    @param count: int;
    @param gain: float;
    var v_uv: vec2;
    var v_col: vec4;
    vertex {
        v_uv = uv;
        v_col = vec4(rot * position, 1.0);
        clip_position = Camera.view_proj * vec4(position, 1.0);
    }
    fragment {
        frag_color = tex.get(v_uv) + tex2.get(v_uv);
        frag_color = frag_color * gain;
        if count > 1 {
            frag_color = frag_color * 2.0;
        }
    }
}
```

A1b：`--check` → rc=1 `parse error: expected lbrace, got ''`。A1a = A1b 删去 fragment 内 if 块并在头部多一个 Fog 组（无关变量）→ rc=0 `check ok`；A1a 另在 es300/webgpu/hlsl 发射成功（双组、双采样器实证出自 A1a）。

### probe_tok_version.slasl（DEF-3）与 probe_tok_control.slasl（对照）

```slasl
#version 300 es
shader TokV {
    priority 0;
    @input position: vec3;
    vertex {
        clip_position = vec4(position, 1.0);
    }
    fragment {
        frag_color = vec4(1.0);
    }
}
```

含 `#version` 行：rc=1 `link error: merged vertex never writes clip_position`（误诊）；删首行（control）：rc=0 `check ok (1 fragment(s))`。

### DEF-4 复现配方

生成含 N 个 `f<i>: vec4;` 字段的单个 `@global struct Huge`（vertex 读 `Huge.f0`、fragment 读末字段）：N=1000 `--check` 正常；N=2000 `--target webgpu` 正常；N=5000 `--check` 即 `PANIC: code=87`（rc=215）。

### 其余探针

- probe_a.slasl（A1a + swizzle 左值行）：全目标 rc=1，根因为 DEF-2 的 if 条件（先行命中），swizzle 左值另由 probe_a2 隔离判定（见 O-2）。
- probe_a3.slasl：mat3 活载荷发射实证（es300/hlsl/wgsl）。
- probe_tok_layout.slasl：`layout(location = 0) @input …` → `parse error: unexpected member 'layout' in shader 'TokL'`。

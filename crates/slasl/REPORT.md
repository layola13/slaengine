# SLASL 二期实现 — 终报（staging 交付，未推送）

日期：2026-10-31。工地 `~/workspace/slasl-p2-local/`（本机主本；构建/测试在二盒 25024 的 install.sh rig 上跑，sci `c58e9044` / sla `a121c04c`，与主线现头一致）。实现：单个 SLA 工具 `src/slasl.sla`（6224 行，零 String 值数据通路、扁平 arena 数据模型），实现语言与路线按 DESIGN 实现路线节（SLA 本体实现、宏机制语义落地）。**sa_std 内未进任何引擎/渲染器代码**；交付物只有 shader 文件与宿主包（glue/info/manifest）。

## 产物清单（按目标）

一份通用 .slasl 源码集（按 priority 合并）→ 下列目标文件集，CLI：`slasl <outdir> <files...>`（默认 bundle）/ `slasl --target <id> <outdir> <files...>` / `slasl --check <files...>`。

| 目标 id | 产物 | 阶段（DESIGN §14） |
|---|---|---|
| bundle（缺省） | merged.glsl-es300.vert/.frag、merged.glsl-es100.vert/.frag、merged.hlsl、layout_before.txt、layout_after.txt、variants.txt（8 件） | P1 原型面 |
| glsl-es300 / glsl-es100 / hlsl（别名 hlsl-sm5） | 同上对应单目标文件 | P2 |
| webgpu（别名 wgsl） | merged.wgsl + merged.reflection.json（强制同源反射清单：entries/buffers/textures/samplers/overrides/inputs/varyings/outputs） | P2 紧随 |
| msl | merged.msl | P3 |
| unity | merged.shader（完整 ShaderLab 资产，URP 面） | P3 |
| blender | merged.glsl（无 `#version`）+ merged_info.py（GPUShaderCreateInfo 等价声明面） | P3 |
| unreal-global | merged.usf + merged.ush + merged_glue.cpp（FGlobalShader 三件套） | P3 |
| spirv | **未产出** — 见「未证面/缺口」第一条 | P4 |

约定面要点（与 DESIGN 对账）：Unity 全部材质参数只进单个 `UnityPerMaterial` cbuffer（硬契约）、纹理走 TEXTURE2D/SAMPLER/SAMPLE_TEXTURE2D 三件套、无裸 `.Sample()`；WebGPU group 0 留帧全局、材质自 group 1 起、纹理/采样器拆两个 binding、标量 @const → `@id` override、uniform 布局 16 字节舍入并在清单中钉死 offset/size；Blender 源码无 `#version`、StageInterface 具名 varying 块；Unreal 参数只用逻辑名、组字段扁平化 `<Group>_<field>`、bool @const 生成置换域（值集由独立 SLASL 编译产生，glue 内注释写明）。

## 验收门结果

复跑口径：二盒 rig 全新构建后 `bash run_tests.sh`（脚本在工地根），四联判读（rc、预期输出行、失败名集、字节对拍）。

1. **门 1（一期黄金）**：base.slasl + tint.slasl → 8 产物与一期 Zig 原型黄金件**逐字对拍 8/8 PASS**（新实现复跑，非引用旧结果）。
2. **门 2（新增覆盖）**：webgpu / msl / unity / blender / unreal-global 各以同一对代表样本（base+tint）产出并冻结黄金，复跑 9/9 PASS；glsl-es300/es100/hlsl 由门 1 bundle 黄金覆盖（同输入逐字）。宏库形状：标准库 = 手写 .slasl fragment 文件按 priority 合并（base/tint 即规范样本），无编译器内嵌宏，与 J-7 口径一致（见裁定表）。
3. **门 3（响亮拒绝面）**：负例 21 件 + 合法对照 1 件，全部以独立 `--check` 判读（不用 test 运行器判负例），21/21 命中命名诊断、对照 rc=0。覆盖：ShaderDuplicateName（声明/组各一）、ShaderStageViolation（clip 写于 fragment、frag_color 写于 vertex、@input 读于 fragment）、ShaderDimensionMismatch（swizzle 越界、构造器分量数、二元类型、sampler 坐标、.get 于非 sampler）、undefined identifier、@const 非字面量默认、@const 默认类型不符、赋值类型不符、合并契约（merged vertex never writes clip_position / merged fragment never writes frag_color）、init 依赖环（cycle in init dependencies）、跨 fragment 类型冲突（conflicting types vec4 vs vec3）、@const 跨 fragment 重定义异型、unknown qualifier '@…'、webgpu bool uniform 字段 → UnsupportedInBackend（以 `--target webgpu` 判读）。
4. **门 4（工具链兼容）**：sla 树 `a121c04c`、规范口径（仓根 cwd、清 .sla-cache、SLA_NO_FRESHNESS_CACHE=1、SA_SLA_FIXTURE_DIR、SA_STD_DIR、SA_PLUGIN_DEV=1）下：宏正例 4/4（test_unit_typed_macro_params / test_unit_macro_expr_output / test_unit_sublanguage_shader / test_unit_check_hook_audit，均 rc=0 且输出 `test result: ok. 1 passed; 0 failed`）；宏负例 10/10 被独立 `sla check` 以命名诊断拒绝（MacroExpressionOutputUntyped、SublanguageNotBound、UnknownCheckHook、MacroParamUnused、Redeclaration、typed 参数 TypeMismatch 等，逐件实测文本在案）；合法对照 check rc=0。**失败名集为空，无新失败名**（与宏批合入记录对账一致）。注：本次子集复跑用 `sa sla test` 缺省（SAB）后端；双后端等价是宏批合入门的既有证据，本线未复跑文本后端。

## Jev 裁定逐项落实表

| 项 | 裁定（概率） | 落实 |
|---|---|---|
| J-1 | declaration_sublanguage_registration（0.68） | .slasl 声明子语言面（@global/@input/@param/@const/var + init/vertex/fragment 块 + 特殊名）在工具内以类型化 AST + 检查器实现，诊断名与编译器侧注册面同族；编译器侧语料 test_unit_sublanguage_shader 门 4 复跑绿 |
| J-2 | fold_into_j1（0.71） | 未建独立机制：声明处理折叠进 J-1 面（工具与编译器两侧皆然） |
| J-3 | typed_macro_params（0.75） | 全部声明字段与参数带声明类型，检查器以类型格（binop/ctor/swizzle/sampler 规则）强制，违例走 ShaderDimensionMismatch 命名诊断；语料 test_unit_typed_macro_params 绿 |
| J-4 | leading_output_convention（0.77） | 阶段输出为前导特殊名 clip_position/frag_color，写侧约定由 ShaderStageViolation 家族强制；语料 test_unit_macro_expr_output 绿 |
| J-5 | independent_check_hooks（0.93） | 诊断以钩子名为前缀独立成族：ShaderDuplicateName / ShaderStageViolation / ShaderDimensionMismatch / UnsupportedInBackend，门 3 负例逐族命中 |
| J-6 | comptime_general_later（0.80） | 通用 comptime 未做（按裁定后置）：@const 仅字面量折叠，非字面量默认以命名诊断拒绝（门 3 const_nonliteral） |
| J-7 | std_library_production_baseline（0.99） | 链接器/发射器为 SLA 写的 std 侧工具本体（本工地 src/slasl.sla），生产不依赖编译器改动；标准宏库形状 = 手写 .slasl fragment 集 |
| J-8 | graded_hybrid（0.68） | 目标分级落地：核心目标（GLSL/HLSL/WGSL）全语义；约定面（unity/blender/unreal）为结构产物 + 黄金对账；SPIR-V 按 DESIGN §14 留 P4（见缺口） |
| F-3 | structured_output_group（0.78） | DESIGN §14 列 P4（与 compute/结构化输出同批），本期未做，登记于缺口 |

## 有意偏离登记

- init 环诊断：一期原型此处打印不透明的 `emitter init failed: LinkFailed`；新实现打印命名诊断 `slasl: link error: cycle in init dependencies`（信息更响亮，非静默改形）。
- `--check` 语义补强：原实现 --check 在 link() 后即返回，跑不到 init 编织，环诊断在独立 check 下不可达；已改为 --check 跑完整链接分析（合并/契约/DCE/编织）只不写产物，门 3 因此成立。
- WGSL override 与 Unreal 置换域按「全部标量/bool @const」生成（含未被引用的 @const），与 DESIGN「标量 @const → @id override」直读一致，特此登记。

## 未证面 / 缺口

1. **SPIR-V 未产出**：任务清单列有 SPIR-V，但 DESIGN §14 将其列入 P4（与 compute、F-3 结构化输出同批）；本线执行范围为 P2 全部 + P3 的发射目标（msl/unity/blender/unreal-global），SPIR-V 未开工。**任务清单与 DESIGN 分期的口径冲突留待主会话裁决**，不静默当作已覆盖。（订正：原稿此处称「执行到 P2+P3 全量」不成立——P3 含导入方向，见缺口 6；经独立复核指出后于 2026-11-01 订正。）
2. **无目标语言编译器验证**：两盒均无 glslangValidator / dxc / tint / Metal 工具链；GLSL/HLSL/WGSL/MSL 产物只过黄金对拍 + 结构目检（WGSL 反射清单另过 JSON 解析验证）。Unity/Unreal/Blender 宿主不在盒上，其验收按 DESIGN 证据分级为黄金 + 静态结构对账，非引擎内编译。
3. **约定面样本面窄**：msl/unity/blender/unreal 发射器只在 base+tint 代表样本上冻结了黄金；mat3、整型/无符号路径、多组多采样器、@global 单例等打印层已实现但未逐目标黄金覆盖。
4. **DESIGN §5「源码内平台细节」**：未知 @qualifier 已命名拒绝；裸平台记号（如 `#version`、register 语法）只在词法/语法层以 unexpected token 失败，无专用命名诊断——与 DESIGN 字面要求有差，登记为缺口。
5. **工具链缺陷（a121c04c，非本线代码）**：实现期间以探针实证（探针存 work/）：① 大函数内 Vec&lt;Struct&gt; push 元素损坏（语料 test_unit_vec_index_assign.sla 在该头上本身失败，属已知坏家族）——工具以 arena+槽位写绕开；② 标量元组返回传输损坏——工具全部改 out-param/结构体返回；③ String 字面量按值传参在 build-exe 下 StackEscape——工具全程 (ptr,len) span、零 String 值。这些是上游缺陷证据，建议主会话转 DEF 分诊，本线未修编译器。
6. **Shadertoy importer 子集未交付**：DESIGN §14 的 P3 含导入方向开启（Shadertoy importer 子集 1，J-8 的 importer 面）；本期未交付、原稿亦未列入本清单（仅 notes/PLAN.md 以「as capacity allows」顺序隐含排除），经独立复核（VERIFY_REPORT §1 第 13 项）指出后于 2026-11-01 补登记为显式缺口。导入方向（Shadertoy/Blender/Unreal importer）整体未开工。
7. **Unity 变体数审计旁注缺失**：DESIGN §9.1/§7.5 要求 unity 发射前做变体数审计并旁注产物；现 merged.shader 内无逐目标变体审计旁注，仅 bundle 级 variants.txt 记录 @const 取值。经独立复核（VERIFY_REPORT §1 第 14 项）登记，原稿未声称亦未登记，2026-11-01 补入。

## staging 提交清单（本地，未推送）

- `f85863b` slasl p2 core：SLA 实现，门 1 黄金 8/8 逐字。
- `e295237` webgpu（WGSL + 反射清单）与 P3 约定目标（msl/unity/blender/unreal-global）+ 黄金，门 1+2 绿。
- `82b2165` 门 3 负例集（21 命名诊断 + 对照）；--check 跑完整链接分析。
- 本报告提交（REPORT.md）。

工地构成：src/slasl.sla（工具本体）、shaders/（规范样本）、golden/ + samples/ + samples_golden/（黄金资产）、neg/（负例集）、run_tests.sh（验收脚本）、notes/PLAN.md（范围决议）、work/（探针与分诊证据，保留备查）。

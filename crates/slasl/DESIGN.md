# DESIGN.md — SLASL 与 SLA 宏支持改进设计

状态：P0 设计稿（2026-10-31）。本线定性（用户 2026-10-31 09:55 亲自定）：**本线的本质是改进 SLA 对宏等的支持；shader 是驱动案例与验收负载，不是做一个着色器产品。** 本文档据此组织：主成果 = §3 宏体系测绘 + §4 缺口登记与改进提案；SLASL（§5 起）是建立在改进之上的写面与演示负载。

定形来源（用户经主会话下达，逐条落文）：09:47 后端通杀扩围（Unity/Unreal/Blender 一等发射目标）；09:54「仅生产对应的 shader 文件，内核不要包括整个引擎」；09:55 本线本质 = SLA 宏等支持改进；09:56 顶层形态 = 一源多 target（类 HLSL 交叉编译）；09:57 命名 **SLASL**（SLA Shader Language），源码扩展名 `.slasl`；10:01 WebGPU 列一等 target。

工地：`~/workspace/sla-shader-local/`。基点：sci `bbd06f9e7074033abb8b15292f965dbb61c6f949`、sa_plugin_sla `ccbffb2aeedc5240d398fcb371e1b14adaeb7998`（ls-remote 核对一致）、heaps `f1139c383f7eb70d2d4537da3190cb8a7f2c9733`、sa_plugin_3dengines `06f4faee99d95b79b65b8d6f2cce885f5ecd8bb5`。旧版设计（重构前）存 `DESIGN.v1-preslasl.md`。

---

## 1. 本质与分层

三层关系（自下而上）：

1. **SLA 语言层改进（编译器）**——宏等元编程支持的补强，落在 sa_plugin_sla。hxsl 的全部能力建立在 Haxe 的编译期宏（`haxe.macro.Expr` 语法作为数据 + 类型化检查）之上；SLA 要原生支撑 SLASL 这类 DSL，缺的正是这一层（§3 测绘、§4 登记）。这是本线的主成果面。
2. **SLASL 编译器核心**——类型化 AST、片段合并/链接、DCE、uniform 逻辑打包、多 target 发射。它是**代码生产能力**：输入 SLASL 源码 + target 设置，输出 shader 文件。按 09:54 定界，它作为 std 原生/工具链一等公民存在（§11），但**只生产文件**。
3. **target 文件产物**——各平台的 shader 文件及宿主必需的同包文件（`.shader`、`.usf`+C++ 胶水、create-info 等价声明、WGSL+绑定反射清单等）。

**引擎与运行时永远在外**（09:54 定界）：不设计渲染器、材质系统、场景、驱动层；不在 std 里放 GL/WebGL 的 program/uniform/texture 运行时句柄面。渲染执行一律是宿主引擎（Unity/Unreal/Blender/浏览器/WebGPU 宿主程序）的事。原章程中「运行时面进 std」的选项**作废**，本设计明确排除（§11.2）。

类比口径（09:56）：对外表述即「HLSL 式一源多目标交叉编译」——一份 SLASL 源码、选定 target、产出该平台 shader 文件。

---

## 2. Phase 1 盘点摘要（证据详见 REPORT.md）

**我方现状**：sa_std 图形面为零（`sci/sa_std/` 224 文件、sci/src 对 shader/gpu/gl 检索零命中，无窗口/上下文创建）；sa_plugin_3dengines 的 shader 是 WGSL **源字符串**塞描述符（`3d_shader.sal`，`SA3D_SHADER_FORMAT_WGSL=1`），渲染是绕开 std 的 WebGPU sidecar（`3d_render_wgpu.sai` 仅 8 个 extern）；经 dts2sai 的 three.js 绑定用 shader 只能把 GLSL 字符串塞进 JS 对象的 ShaderMaterial/RawShaderMaterial（`three.sai:63237` 起），零编译期检查；hello_cube 演示用内置材质、无用户 shader。

**hxsl 参考**（heaps `f1139c38` 实读）：`hxsl/Shader.hx:10` 的 `@:autoBuild(hxsl.Macros.buildShader())` 在编译期把 `static var SRC = {...}`（Haxe 块表达式、**非字符串**）经 MacroParser 解析为类型化 AST（`hxsl/Ast.hx` 的 Type/TExpr，含独立 TSwiz 节点、TGlobal 内建表）；`hxsl/Checker.hx`（1545 行）做类型检查；多片段经 `hxsl/Cache.hx:240` compileRuntimeShader 按 priority 收集 → Linker（路径合并+依赖图）→ Dce（分量掩码）→ Flatten（Alloc{pos,size} 打包）→ RuntimeShaderData{params/globals 布局、纹理槽计数}；GlslOut（933 行）/HlslOut（1262 行）独占平台细节（版本头、precision、texture2D/.Sample()、std140、SV_* 语义、寄存器）。`@const` 经 constBits 位打包 + `getInstance(constBits)` 做变体实例化。AST 可序列化（Serializer/CacheFile）。**hxsl 的限制**（照抄形状不抄幻想）：当前 master 只有 GlslOut/HlslOut/NXGlslOut，**没有 MetalOut、没有 SPIR-V Out**，h3d 无 Metal/Vulkan 驱动；TGlobal 表里 Faceforward/Refract 等被注释掉（其自身也不支持）；无 compute 一等面（RWTexture 是边角）。

---

## 3. SLA 宏体系测绘（主成果之一）

SLA 现行有**两套宏世界 + 一个定用途模板设施**，能力边界截然不同。以下逐项给证据（源码为 sla master `ccbffb2a`；行为探针在已装插件 0.1.8（2026-10-29 构建）上实测，探针文件存 `probes/`，源码与行为交叉核对一致）。

### 3.1 SLA 层用户宏（`macro` 声明）

形态：`macro name(params) { stmts }`。parser 的 parseMacroDecl（`parser.zig:1324` 起）只接受**裸标识符参数**（无类型、无变参、无默认值）；宏体经 parseBlock 解析为 AST 语句节点序列（`ast.zig:159` MacroDecl{name, params: [][]const u8, body: []*Node}）——**宏体是 AST 级的，不是 token 级的**。

| 维度 | 现状 | 证据 |
|---|---|---|
| 参数求值形态 | 参数是**已求值的表达式/寄存器**：调用点先 checkExpr 每个实参，再按名绑定 | type_checker.zig:6587 调用分支；探针 p6（传未定义名 `counter` → UndefinedVariable） |
| 宏体检查 | 宏体被类型检查一次，参数以 `.infer` 占位类型入域 | type_checker.zig:3558 checkMacro、3495 注释「Type check macro bodies so codegen can rely on expr_types」 |
| 类型参数化 | 同一宏可用于不同类型的实参（按调用点定型） | 探针 p4（i64 与 f64 两调用点）check 通过 |
| 类型可见性（作者面） | **宏作者读不到实参类型、不能按类型分支、不能按类型报错**；类型信息只服务于 codegen 内部（macro_arg_types / macroArgTypeForName，codegen.zig:3620） | lexer 关键字表无 `comptime`/`typeof`；checkMacro 以 .infer 一查到底 |
| 返回值 | 用户宏调用恒为 `void_type`，**不能出现在表达式位置** | type_checker.zig:6587 分支末尾；探针 p1（TypeMismatch: expected i64, actual void_type） |
| 语法参数 | **无**：块/语句/表达式片段不能作参数 | 探针 p2（传 `{ ... }` → parse error: Unexpected prefix token l_brace） |
| 声明位置 | 宏只能在语句位置调用；顶层调用 = ExpectedDeclaration；宏体不能含声明（fn 等） | 探针 p3、p8（keyword_fn in body → parse error） |
| 卫生性 | 卫生：宏内 let 经绑定别名改名内联（genUserMacroBlockInline，codegen.zig:498；newInlineMacroLocal:492），不泄漏、不捕获；向调用方输出的**唯一通道是给参数赋值**（out-param 惯用法，如语料 `add_one_macro(var_ref)`） | test_edge_cases.sla test_macro_hygiene；探针 p6 |
| 嵌套/分析 | 宏可调宏（探针 p5 通过）；检查器对宏做消费分析（control_flow_rules.zig:62 macroParamConsumption：never/always/conditional，conditional 在调用点报 MacroConditionalConsume）与 try 传播分析（macroHasTryRecursive）；codegen 有 macro_inline_depth 计数（codegen.zig:185/709） | 源码 + p5 |
| 跨文件 | 用户宏可经 `@import` 跨 .sla 文件使用 | 探针 p7 通过 |
| 变参 | 无（`...` 仅 extern 声明可用） | parser.zig:1216-1229 |

### 3.2 SA 层导入宏（`[MACRO]`，自 .sa/.sal 导入）

形态：SA 汇编层的寄存器文本模板（`sci/sa_std/control.sal:18` 起：`[MACRO] IF_ELSE %cond, %label_then, %label_else`——**可把标签（控制流）作参数**，这是 SLA 层没有的形态）。SLA 侧经 plugin_imported_macros.zig（401 行）在**源码行文本层**分析导入宏体：扫 `%param`/`&%param`/`%param+` 文本模式推导借用掩码与地址槽掩码；参数名可用于更长标识符内部做文本插值（注释实证 `__process_argv_slot_%argv_%index`）。输出约定：前导输出参数（名字以 out 开头或属 nonnull_ptr/type_id/any_ref/cursor/take/repeat 名单，isLeadingOutputMacroParam）；恰一个前导输出且实参比 arity 少一时，调用可作**表达式**使用（lowering_rules.zig:3061 importedMacroUsesExpressionOutput + 结果种类表 raw_pointer/boolean/u8/u32/u64/i32/i64/f64）。即：**表达式位置宏在 SA 层存在、在 SLA 层不存在**——一处明确的不对称。

### 3.3 定用途模板设施 `@expand_tuple`

形态：源码预处理层（source_expand.zig，450 行；源里无 `@expand_tuple` 字样即整体跳过，:38）的文本模板：`@expand_tuple(2, 4, T) { 模板 }` 按元数逐档生成**声明**（struct/fn），占位词表固定：`$N`（元数，拼进标识符如 `tuple_sum$N`）、`$I`、`$T`、`$ORD`（序数名），块指令只有 `@each`/`@join`。语料：tests/test_unit_expand_tuple_macro.sla（生成 TupleCarrier 结构体与 tuple_sum/tuple_first 函数）。定性：**声明生成与标识符粘贴在 SLA 里只存在于这个单一用途设施里**，词表与指令集不可由用户扩展，模板拿不到类型信息（纯文本层，在解析之前）。

### 3.4 相邻面

- 除上三者外无用户可编程的编译期面：无 comptime 求值（顶层 const 仅常量声明，无 const fn/编译期调用求值）；无属性驱动的变换钩子（声明种类固定，无用户变换注册点；plugin_api 是编译命令级 ABI，无逐声明回调）。
- 编译器自身大量使用宏：codegen 为 Array/HashMap/BTreeMap/迭代器/Box 等模式合成 SA [MACRO] 定义（emitArrayFillMacros 等，codegen.zig:4445 起）——编译器内部视宏为刚需，用户面却只给了寄存器模板一格。

---

## 4. 缺口登记 SLA-SHADER-GAP（主成果之二）

以 hxsl 的实际需求为标尺逐项编号。每项给：hxsl 需求 / SLA 现状（§3 证据）/ 没有它时 SLASL 只能怎么写 / shader 之外的通用价值 / 分类。**分类口径**：属语言层设计分叉的打包进 REPORT「候 Jev 包」，本线不定形；纯实现缺口可在 staging 原型带语料——本轮测绘的结论是：**shader 阻塞性缺口全部是设计缺席而非实现 bug**（现行宏机器对其既定设计目标是完备的：消费分析、try 传播、卫生别名、导入宏掩码推导都是成品工程），故本轮没有可单方原型的纯实现缺口；原型改为以参考前端实现提案语义来验证提案（§12）。

### GAP-1 语法作为数据（syntax-valued 参数 / 引用）

- hxsl 需求：MacroParser 在编译期拿到 `SRC` 块的**未求值语法**（haxe.macro.Expr），据此构建类型化 AST。这是 hxsl 存在的根基，SLASL 写面整体建立其上。
- SLA 现状：宏参 = 已求值表达式（p2/p6 实证）；AST 层无 syntax/expr 类型；无 quote 构造。
- 没有它时 SLASL 只能怎么写：要么退回**字符串**（运行时解析——正是用户否决的形态），要么由插件为 `shader` 声明**硬编码**一个专用子解析器（可用但那是 shader 专用后门，不是语言能力）。
- 通用价值：一切嵌入式 DSL 的通用地基——查询构造器、序列化 schema、状态机、文法、单位量纲标注（heng 线的 quantity 式检查）都受益；这是「宏等支持改进」里最大的一格。
- 分类：**语言设计分叉 → 候 Jev 包 J-1**。候选：(a) 宏参加 `syntax` 类型（参数收未求值 AST 片段，宏体在 AST 上变换）；(b) 声明级子语言注册（新声明种类由注册的子解析器处理，如 `shader` 声明——SLASL 的最小面）；(c) 属性驱动的声明变换钩子（@:autoBuild 式，变换函数收声明 AST、回声明 AST）。三者可组合，(b) 是 (a)/(c) 的退化特例。

### GAP-2 声明级生成（宏在声明位置生效）

- hxsl 需求：buildShader 在类声明上运行并**生成字段与方法**；SLASL 库要生成参数访问器、接口结构体、逐 target 胶水声明。
- SLA 现状：顶层不能调用宏（p3）、宏体不能含声明（p8）；唯一的声明生成是 @expand_tuple 的定用途文本模板（§3.3，词表封闭、类型盲）。
- 没有它时：生成代码只能靠外部脚本/手写重复声明，库无法自带派生面。
- 通用价值：元组之外的样板生成——trait impl、FFI 绑定、测试夹具、协议编解码。
- 分类：**语言设计分叉 → 候 Jev 包 J-2**（与 J-1 相邻）。候选：(a) 把 @expand_tuple 泛化为用户可命名的声明模板指令（词表可扩展）；(b) 声明位置可调用声明型宏（宏体为声明序列）；(c) 并入 J-1(c) 的声明变换钩子。

### GAP-3 宏内的类型可见性与按类型分派

- hxsl 需求：MacroParser+Checker 产出**带类型**的 TExpr；检查与合并全程在类型上推理（如 swizzle 分量数对向量维数、采样器维度对坐标类型）。
- SLA 现状：类型信息存在但只对 codegen 可见（macroArgTypeForName 是内部函数）；宏作者无 typeof、无按类型条件、无以类型命名的诊断手段；宏体以 .infer 一查到底（p4 的「能用多型」是占位符放行，不是类型推理）。
- 没有它时：DSL 的领域检查（如 SLASL 的阶段规则、维度规则）只能推迟到 DSL 自己的第二遍处理里做——前提是先有 GAP-1 把 AST 拿出来；在现行宏内则完全做不到。
- 通用价值：类型导向代码生成（数值泛型、容器适配）、宏诊断质量对所有宏用户普惠。
- 分类：**语言设计分叉 → 候 Jev 包 J-3**。候选：(a) 宏参可声明类型（收窄+暴露）；(b) 宏体内 `typeof(param)` 表达式 + 编译期条件；(c) 仅暴露给检查钩子（与 J-5 合并）。注：(a) 是其中最小可分离步。

### GAP-4 表达式位置的用户宏（宏返回值）

- hxsl 需求：中——hxsl 的 helper 是普通带返回值函数；落到 SLA 宏面：由宏生成一个表达式（惰性求值实参、计算常量）是 DSL 语法糖的常见需求。
- SLA 现状：用户宏恒 void（p1）；而 SA 层导入宏已有表达式输出的成品先例（前导输出约定 + 结果种类表，§3.2）——**不对称**明确。
- 没有它时：一切宏都只能写成语句 + out-param 赋值，表达式组合性丧失。
- 通用价值：min/max/clamp 式惰性宏、断言宏、惰性日志——宏的日常形态。
- 分类：**语言设计分叉（面小、实现风险低）→ 候 Jev 包 J-4**。候选：(a) 末表达式为值（块表达式化）；(b) 显式 `return` 于宏体 + 返回类型推断；(c) 照搬导入宏的前导输出约定到用户宏。SA 层先例使 (c) 的实现路径最短，但表面语义仍属语言定形。

### GAP-5 编译期求值（comptime / const fn）

- hxsl 需求：**条件性**——布局计算、constBits 打包在 hxsl 里是宿主**运行时**做的（编译器是 Haxe 程序，链接在应用构建/运行期执行）。对应到我方：若 SLASL 编译器核心是 std 里的 SLA 库（由构建步骤运行），布局/打包是该库的普通运行时计算，**不需要**用户程序编译期求值；只有当发射必须发生在应用的 sla 编译期内（静态路径）时才需要。
- SLA 现状：无 comptime 设施（§3.4）。
- 通用价值：大（静态表生成、编译期断言），但**不被 shader 阻塞**。
- 分类：**语言设计分叉 → 候 Jev 包 J-6（与 J-7 链接执行点联动）**：若 J-7 定 (b) std 库生产为语义基准，GAP-5 降为非阻塞的一般改进；若定 (a) 静态路径，则 GAP-5 升为阻塞项。

### GAP-6 标识符构造（名字粘贴）

- hxsl 需求：低-中（生成的访问器名、逐 target 符号名多在编译器核心内部处理，不在宏展开面）。
- SLA 现状：只存在于 @expand_tuple 词表（$N 后缀）与 SA 层文本插值（§3.2/§3.3）；SLA 宏体内标识符固定。
- 分类：**并入 J-2**（声明模板自带名字构造），不单独立包。

### GAP-7 检查器介入点（自定义检查 pass / 领域诊断）

- hxsl 需求：hxsl.Checker 以 DSL 自己的规则报错（阶段规则、限定符规则，1545 行）。SLASL 的领域检查（§6.2）需要在 AST 上跑自定义规则并产出具名诊断。
- SLA 现状：无用户/插件检查 pass 注册面；仅有的先例是编译器内建的宏消费/try 分析。plugin ABI 是命令级，无逐声明回调。
- 没有它时：领域检查只能放在独立工具里（与编译分离，诊断与源码位置脱钩）。
- 通用价值：lint、领域校验器（量纲、协议状态机、schema 一致性）——检查即语言能力的一部分。
- 分类：**语言设计分叉 → 候 Jev 包 J-5**。候选：(a) J-1(c) 的变换钩子兼诊断（变换函数可拒绝并报错）；(b) 独立 `check` 钩子声明（只读 AST + 诊断通道）。

### 缺口总表

| 编号 | 名称 | 阻塞 SLASL 何处 | 分类 |
|---|---|---|---|
| GAP-1 | 语法作为数据 | 写面根基（§5 目标形） | J-1 设计分叉 |
| GAP-2 | 声明级生成 | SLASL 库派生面 | J-2 设计分叉 |
| GAP-3 | 宏内类型可见性 | 领域检查深度 | J-3 设计分叉 |
| GAP-4 | 表达式位置用户宏 | 表达式语法糖 | J-4 设计分叉（小） |
| GAP-5 | 编译期求值 | 仅静态路径需要 | J-6 设计分叉（条件性） |
| GAP-6 | 标识符构造 | 并入声明生成 | 并入 J-2 |
| GAP-7 | 检查器介入点 | 领域诊断 | J-5 设计分叉 |

---

## 5. SLASL 写面

### 5.1 与 GAP 的关系（先说清）

SLASL 的**目标形**依赖 GAP-1 的某种落形：`.slasl` 源码被 SLA 工具链在编译期解析为类型化 AST。在缺口关闭前，**原型形**用独立参考前端实现同一语法与同一语义（§12）——原型不是另一套语言：语法、AST schema、检查规则、链接语义与目标形逐项一致，缺口关闭时只换前端入口，下游（AST→链接→发射）一行不改。原型前端在实现上恰好就是 GAP-1 候选 (b)（声明级子解析器）的独立验证。

### 5.2 表面语法（目标形 = 原型形）

一份 `.slasl` 源码含一个或多个片段声明；编译时选定 target（§8），一组片段合并发射为该 target 的文件集。

```slasl
shader Base {
    priority 0;
    @global struct Camera { view_proj: mat4; }
    @input position: vec3;
    @input uv: vec2;
    @param base_color: vec4;
    @param tex: sampler2D;
    var v_uv: vec2;
    vertex {
        v_uv = uv;
        clip_position = Camera.view_proj * vec4(position, 1.0);
    }
    fragment {
        frag_color = tex.get(v_uv) * base_color;
    }
}
```

规则要点：

- 限定符沿 hxsl：`@global`（全片段共享的引擎/宿主级量）、`@input`（顶点输入）、`@param`（本材质参数）、`@const`（编译期常量，变体唯一来源，§7.3）、`@range`（数值范围提示，后端可用于精度/裁剪）。
- 结构体组：`@global struct Camera { ... }` 成组声明、按组名限定访问（`Camera.view_proj`），对应 hxsl 的 @global 结构组；组是打包与宿主约定的单位（Unity 的 UnityPerMaterial、Blender 的 UBO 声明都以组为界）。
- 阶段块：`init {}`（初始化式，按依赖序编织，§7.2）、`vertex {}`、`fragment {}`；helper 函数形后置登记（原型不做）。
- 特殊名：`clip_position`（vertex 输出，vec4）、`frag_color`（fragment 输出，vec4，单渲染目标）。**原型简化登记**：生产形应为 hxsl 式结构化 output 组（声明输出结构体、按字段写），此点列分叉 F-3（§13）候 Jev；原型用特殊名是标注清楚的窄化，不冒充目标形。
- 采样写**方法式** `tex.get(uv)`：AST 是采样操作节点，方言转写由后端独占（`texture()` / `texture2D()` / `.Sample()` / `textureSample()`）。用户代码出现 `layout`/`binding`/`precision`/版本号/`register` 即具名检查错误——平台细节零泄漏（hxsl 铁律）。
- 片段 = 类库单位：SLASL 片段经文件组合（一次编译给一组 .slasl），对应 hxsl 的 addShader 列表；`priority` 决定合并序（数小先行，同 hxsl 的 priority 降序收集的镜像约定，此处定为升序执行、写入设计以免歧义）。

### 5.3 为什么不做字符串/运行时 builder 主面

用户已定：shader 不是字符串。字符串形态（现行 three.js 路线）零编译期检查、合并只能文本拼贴；运行时 builder 把错误推迟到运行期且与 SLA 的编译期定位相悖。两者只可作逃生舱登记（TSyntax 式），不进主面——原型不做，生产形是否留逃生舱列分叉候议（默认不留）。

---

## 6. 类型化 AST 与 SLASL 检查

### 6.1 AST（与 std 编译器核心共用同一 schema）

类型集（原型子集标 ★）：Float★、Int、UInt、Bool★、Vec2/3/4★、Mat3、Mat4★、Sampler2D★、Struct（具名结构体组★）。生产集补：Mat3x4、SamplerCube/3D、TArray、Buffer/RWTexture（compute 面，随 P4）。表达式节点：字面量、标识符、限定访问（组.字段）、字段访问、**Swizzle（独立节点，含分量掩码，供 DCE）**、BinOp/UnOp、构造（vecN(...)）、采样（Sample{tex, uv, lod?}）、Call、Assign、If（条件可为 @const 或运行时值）、Block、VarDecl。声明节点：ShaderDecl{priority, globals, inputs, params, consts, vars, init, vertex, fragment}。AST 是**可序列化数据**（hxsl 先例：Serializer/CacheFile）——它是前端与编译器核心之间的契约面，schema 由 std 侧与语言层共用。

### 6.2 检查规则（SLASL checker，原型实现其子集 ★）

- 声明规则：限定符唯一性、同名同型跨片段可合并/同名异型报错、@const 必须字面默认、@input 只 vertex 可读。★
- 类型规则：向量/矩阵运算维度、swizzle 分量合法性与左值性、采样坐标类型对采样器维度、赋值类型一致。★（子集）
- 阶段规则：fragment 不得写 @input、vertex 不得读 fragment-only 量、init 不得读阶段输入；**合并后**的 vertex 必须写 clip_position、fragment 必须写 frag_color（链接期校验——单个片段可只贡献一个 stage，如纯 fragment 的效果片段）。★（子集）
- 变体规则：@const 条件在链接期按 target 预算分级特化或降为运行时分支（§7.3/§8.2）。

检查介入点与 GAP-7 的关系：生产形中本节的规则应跑在 SLA 编译内（经 J-5 的钩子或 J-1 的变换内）；原型形中由参考前端承担，规则文本一致。

---

## 7. 合并 / 链接（target 无关层）

链接器输入 = 一组已检查片段 + target 的**预算画像**（只读约束：变体预算、槽位分区规则名）；输出 = `LinkedShader`：双 stage 已合并/特化/DCE 的 AST + 接口表（globals/params 逻辑布局、纹理逻辑槽表、input 表、varying 表、变体键）。**合并、DCE、接口表生成全部在此层完成；target 层只做方言转写 + 约定包裹 + 槽位落定**（09:56 跨目标铁律）。

### 7.1 变量统一

按（限定符, 名）统一：同名同型 = 同一变量（hxsl 按路径合并）；@global 结构组按组名+字段路径合并。重命名只允许发生在宿主保留名冲突时，且由 target 层执行、回写接口表（如 Unity 的 `_BaseMap` 保留名、Unreal 的参数前缀纪律 §9.2）。

### 7.2 阶段合并与 init 编织

同 stage 的块按 priority 序拼接；共享 var 形成跨片段读写依赖。init 式按**依赖序**编织进使用它的 stage 入口（读图拓扑排序；作者书写序无关——原型金文件含乱序实证）。环依赖 = 具名链接错误。

### 7.3 DCE（分量级）

自 stage 输出（clip_position/frag_color + 宿主必需输出）反向标记：VarDeps 风格的**分量掩码**传播（swizzle 读只保留被读分量）；未标记的 var 声明、init 式、@param/@global 字段从 AST 与接口表**同时**消除（hxsl Dce 401 行同构）。@const 条件先特化（以变体键选定值折叠 If）再 DCE。**一致性保持**：采样/导数节点带控制流一致性标注（源自其原始控制流位置）；合并与 DCE 不得使采样点跨越一致性边界（无条件 ↔ 条件内），LinkedShader 保留该标注供 target 层复核（WGSL 为硬门，§9.4 第 6 条；其余方言为可移植性纪律）。

### 7.4 逻辑布局（uniform 打包）

Flatten 同构：globals 组与 params 组各自拍平为逻辑布局——每字段记 (offset, size) 的**逻辑槽**（以 vec4 字为单位的抽象布局 + 字段序），纹理/采样器记逻辑槽号。**AST 层永远只带逻辑槽**；物理绑定（GLSL layout(binding)、HLSL register、WGSL @group/@binding、Metal 索引分区、Blender 的 Metal 重排分区）由 target 层落定（Blender 档案实证：同一 info 逻辑槽在 GL/Vulkan/Metal 下物理排布不同，`mtl_shader_generate.hh`）。

### 7.5 变体统一模型

唯一变体源 = `@const`（hxsl constBits 实例化的对应物）。target 层只**翻译**，不发明新维度：

| target 类 | @const 落形 |
|---|---|
| 裸方言（glsl/hlsl/msl/spirv） | 链接期按变体键直接产出多份文件（或单份 + 宿主自选） |
| webgpu | 无预处理可用：按四级分级（§9.4 第 5 条）——标量条件 → override（@id 登记）；结构变体 → 拆多个 .wgsl 模块；运行时数据不进变体系 |
| unity | 分级：宿主集合照抄（管线注入集）、材质功能 → `shader_feature_local`、低频廉价 → `dynamic_branch`/uniform；**发射前做变体数审计并旁注产物**（关键字项目预算 256、local ≤64/shader，档案 §7） |
| unreal-global | C++ 置换维度类（封闭取值集）+ ShouldCompilePermutation 过滤 + 总数预算报警；维度类由我方**生成**（是文件产物的一部分，§9.2） |
| blender | specialization constants / create-info 侧 DEFINE（档案 §5 对应面） |

分级判据在链接层按 target 预算画像执行：超出预算的 @const 组合必须降级为运行时分支或报错，不许静默膨胀（Unity 乘法爆炸、Unreal 1024 警戒例均为档案实证）。

---

## 8. target 模型与注册表

### 8.1 模型

`target` 是编译一等设置：一次编译 = 一组.slasl + 一个 target → 该 target 的文件集。注册表分两层：**方言后端**（AST→方言文本）与**宿主约定层**（包裹结构、同包文件、绑定落定、变体翻译）。新增 target = 加一层，不动写面与合并层。

### 8.2 方言目标

| target | 方言 | 原型/分期 | 备注 |
|---|---|---|---|
| `glsl-es300` | GLSL ES 3.00 | **原型** | WebGL2；std140、layout 槽落定、texture() |
| `glsl-es100` | GLSL ES 1.00 | **原型** | texture2D、precision、attribute/varying、无 UBO（uniform 逐个声明） |
| `hlsl-sm5` | HLSL SM5 形 | **原型** | cbuffer+register 落定、.Sample()、SV_* |
| `webgpu` | WGSL | P2 紧随第一批（§9.4） | 方言 + 薄约定；随附绑定反射清单 |
| `msl` | Metal Shading Language | P3 | **我方新增**——hxsl 无 MetalOut（§2），不冒充复刻 |
| `spirv` | SPIR-V（经文本汇编或直发二进制） | P4 登记 | 工具链依赖最重，理由在此：宿主（Vulkan/Blender Vulkan 路）多自带 GLSL→SPIR-V，我方直发收益最低 |

### 8.3 约定目标

| target | 组成 | 分期 | 产物 |
|---|---|---|---|
| `unity` | hlsl 方言 + Unity 约定层（flavor: urp 主 / builtin 兼容） | P3 首位 | `.shader` 整资产 |
| `blender` | glsl(430 类) 方言变体 + Blender 约定层 | P3 次位 | `.glsl` + create-info 等价声明（或 Python 构建脚本形） |
| `unreal-global` | hlsl 方言 + Unreal 约定层 | P3 末位（compute 先行） | `.usf` + `.ush` + C++ 胶水三件套 |
| three/wgpu 直用 | 裸方言文件由宿主自行装配 | 不设约定层 | glsl-es300 / webgpu 产物即交付 |

### 8.4 跨目标铁律（档案已证，复述为设计律）

1. AST 层资源槽一律逻辑槽，物理绑定 target 层重映射（Blender 教训）。
2. AST 条件按 target 变体预算分级（Unity/Unreal 教训，§7.5）。
3. 合并/DCE/接口表在 target 无关层完成（§7 帽子）。
4. 后端不支持的 AST 节点：发射期具名拒绝 `UnsupportedInBackend`，**不许降级改写**（hxsl 对导数等面的处理同理）。

---

## 9. 约定层定形（消费三家发射档案 + WebGPU 双档案）

证据等级从档案：Unity = 官方文档 + 官方源码（Graphics 仓 `0efc28ea`，URP 17.7.0），**未经 Unity 编辑器真编译**（本机无 Unity）；Unreal = 官方文档/博客/API/公开插件源码分级标注，**未经真编译且本机不可验**（UE 源码许可门控）；Blender = 源码级核实（blender-src `4f97ee24` 稀疏克隆），未构建未运行；WebGPU = W3C 规范档案 + gpu-curtains 实践档案（均待到达后校准本节，先按主会话定形与规范通识成文，标）。

### 9.1 unity

- 发射单位 = **完整 ShaderLab 资产**：`Shader` 根 + Properties + SubShader/Tags + Pass（LightMode 逐 Pass 对齐）+ 渲染状态在 ShaderLab 层（可 `[_Prop]` 参数化）；正文一律 `HLSLPROGRAM`。
- 双侧对齐硬契约：Properties 每属性 ↔ HLSL 同名同型声明；SRP 下全部材质属性进**唯一** `CBUFFER_START(UnityPerMaterial)`、全 Pass 同一份（放 HLSLINCLUDE）；违反是**静默性能降级**（SRP Batcher not compatible），编译通过发现不了——生成器须以清单自检（档案 §9）。
- 纹理走宏三元组 `TEXTURE2D/SAMPLER/SAMPLE_TEXTURE2D`（CBUFFER 外），**绝不直写 Texture2D/.Sample()**（HLSLcc 跨译 GL 路径会坏）——即 Unity 层对采样节点有自己的转写，覆盖 hlsl 方言默认形。
- pragma 纪律：vertex/fragment 必有、名字自选稳定专名；`#pragma target` 按 AST 能力选档、优先 `#pragma require` 逐项；pragma 只写 `.shader` 本体（include 文件里的会被忽略；需传递时 `#include_with_pragmas`）。
- include 按 flavor：URP = 包路径 Core.hlsl（**RP 包版本是发射参数**，锚点 URP 17.7.0/Unity 6）；BiRP = UnityCG.cginc（已 deprecated、维护至 6.7 LTS，只作兼容 flavor）。引擎内置量（矩阵/时间）只引用不声明；顶点输出 SV_POSITION、片段 SV_Target；精度 half/float（SRP 禁 fixed）。
- 变体按 §7.5 分级 + 变体数审计旁注；instancing 宏套件全有或全无。
- 增量估计：hlsl 方言之上的约定层约当方言后端的 40–60%（包裹生成 + 对齐自检是大头）。验收：金文件 + **装有 Unity 6 + URP 17 的机器上编辑器导入**（Console 零 error + SRP Batcher compatible + 变体数与审计一致）——本机不可验，如实登记为待外部机器验收。

### 9.2 unreal-global（按档案定形，多处推翻本线初版判断，已按档案改）

- **成对（三件套）生产是交付定义**：`.usf`（含入口）+ 可选 `.ush` + **C++ 胶水文件**（FGlobalShader 子类、参数结构、注册宏四元绑定 类↔虚拟路径↔入口名↔频率、置换域、模块加载时序、AddShaderSourceDirectoryMapping）。C++ 胶水是**文件产物**，在本线范围内（09:54 定界不排除文件形态的胶水；排除的是运行时）。
- 参数纪律：USF 全局量与 C++ 参数结构成员**逐字同名**；布局服从引擎宏反射打包（BEGIN_SHADER_PARAMETER_STRUCT 家族宏），**禁止自发 register()/手写 cbuffer 布局**；参数名带来源前缀防扁平拼接撞名；全局 UB（View 等）只以 STRUCT_REF 引用、不生成；每个 USF 外部 define 必须在生成的 C++ 里有来源（SetDefine 清单，含 THREADGROUPSIZE_* 之于 [numthreads]）；include 走虚拟路径且**由文件自写**。
- 变体：§7.5 的置换维度模型（封闭集 + 过滤 + 预算报警），不许退化为 USF 内自由 #ifdef。
- **首落点 = global shader、compute 优先、全屏 pixel 次之**；材质面归引擎代码生成（MaterialTemplate.ush / /Engine/Generated/Material.ush 一系，我方不生成 mesh material），至多 P4 以 Custom 表达式片段注入（假定 Parameters 在作用域、不声明入口/uniform/include）。原章程与本线初版用的「GetMaterialParameters」字面名未在一手来源证实，废止该措辞。
- 只发 HLSL 一份：DXIL/SPIR-V/MSL 跨编译是引擎的事。特性级别集须锁定（PCD3D_SM5/SM6；SM6 自 UE 5.1 为 PC 新项目默认）。
- 派发样板（AllocParameters + FComputeShaderUtils::AddPass / 全屏 FPixelShaderUtils::AddFullscreenPass）同批生成，或以字段清单作契约交付，二选一在实现批定。
- 验收上限 = 静态结构对账（与官方教程/LensDistortion/公开插件.usf 的同构性 + 档案 §9.1 的 14 项 checklist 机械项）；真编译须持证机 UE 5.x 工程，首验目标 = 档案例 B（RDG compute 对）。本机不可验，如实登记。

### 9.3 blender（按档案定形）

- 产物两件套：**info 等价声明 + 方言源码**。接口先行：槽位在 info 侧显式声明（vertex_in/fragment_out/sampler/uniform_buf/push_constant 的链式声明表；C++ `gpu_shader_create_info.hh` 与 Python `GPUShaderCreateInfo` 同构，交付面二选一，Python 面可生成 `create_from_info` 构建脚本）。
- 源码纪律：**不得自带 #version**（宿主注入：GL 430 / Vulkan 450）；宿主注入 standard_defines 与阶段 patch 头——我方发射的标识符须避开宿主注入面，内建函数须以 SourceProcessor 可识别的形态出现（其做词法级 DCE + builtins 元数据提取）；入口默认 `main`；varying 必须具名 StageInterface（SMOOTH/FLAT/NO_PERSPECTIVE）；保留槽避让（printf 13、图元展开 SSBO 7）；push constant 字段序 = 宿主打包 ABI、不可中途插删；共享结构走 TYPEDEF_SOURCE 等价声明。
- 合并模型对照：Blender **没有 AST 级合并**（组合 = info 级声明表合并 + #include 依赖图 + 节点图文本生成 + 词法 DCE）。我方发射落在「一份 info 等价 + 一份**已自合并/自 DCE** 的源码」——借它的**声明/绑定契约**，不依赖它的文本拼图。引擎数据经 ADDITIONAL_INFO 等价声明**或** GPUUniformBuiltin 写死名二选一，不混用。
- Metal 物理重排（SSBO 0..15、UBO 16..27、PushConstant 29、Sampler ArgBuf 30）再次实证 §7.4 逻辑槽律：info 的 slot 必须是可重映射的逻辑槽。
- 新表面 BSL（.bsl.hh）不是真 AST，不作目标登记。
- 增量估计：三家最轻（info 声明与我方接口表同构），约方言后端 30–50%。验收：金文件 + 档案 §6 发射 checklist；真验须构建 blender 二进制无头跑 create_from_info + GPUOffScreen 读回对拍——本机未做（档案亦未构建），登记待验。

### 9.4 webgpu（双档案已汇入：WGSL 规范档案 + gpu-curtains 实践档案 v0.17.2 源码级）

定形：**方言目标 WGSL + 薄约定层**（无引擎宿主，宿主即 WebGPU API 本身）。WGSL 无预处理器、无版本头。以下六条为档案定形，逐条落律：

1. **绑定是双边合同 + 规范硬预算**（档案 §4）：资源四类（uniform/storage buffer、纹理、采样器）各须 `@group+@binding` 双属性、同模块内不重复；接口 = 各入口点的**静态访问集**（DCE 后未被任何入口点用到的资源不进布局要求——清单按入口点分别给接口）。规范默认预算（可移植产物按保底设计）：bind group ≤4、uniform 12/阶段、storage 8/阶段、采样纹理/采样器各 16/阶段、存储纹理 4/阶段、单 uniform 绑定 ≤64KiB（适配器保底 16KiB）、buffer 偏移 256B 对齐、阶段间变量 16。逻辑槽由 target 层在预算内落定；**超预算响亮失败并点名超限项**（哪阶段/哪类/限值与实际值），第一手段是合并 uniform 块（省槽位但吃 64KiB 与 256B 对齐）。
2. **合并采样器拆两槽 + 反射清单为强制同包件**：SLASL 的 `tex.get(uv)` 在 WGSL 展开为纹理绑定 + 采样器绑定 + `textureSample(tex, samp, uv)`，(纹理, 采样器) 配对关系进清单（比较采样走 sampler_comparison 独立槽位）。浏览器 JS 宿主**零反射接口**（GPUShaderModule 只有 getCompilationInfo），故必须随 `.wgsl` 发射**反射清单**（档案 §4.6 字段集：入口点静态访问集、buffer 字节布局表、overrides、required features/limits、采样器配对、入口 IO）。清单与 WGSL **同源生成、禁手写维护**。
3. **接口元数据单源三生成**（gpu-curtains 实践印证）：合并 AST 的接口表同源派生 (a) WGSL 声明段、(b) 绑定清单、(c) 布局偏移表——三者永不分别维护。清单设计为**可哈希的规范形**：宿主据其建/缓存 pipeline layout（gpu-curtains 以 cacheKey 充当布局指纹，正是此刚需的生态实证）。
4. **WGSL 独有布局 + 双保险**：uniform 布局有独有圆整口径（结构体对齐圆整 16、数组步长 16 倍数，规范 §14.4.5；无显式 offset 语法）；**同一逻辑结构体在 uniform 与 storage 下可能是两套物理布局**，偏移表是 target 私有产物、随清单给宿主（宿主填 buffer 与 minBindingSize 都用它，消灭「WGSL 算的布局 ≠ JS 填的字节」类错误）。双保险纪律：凡接口成员布局偏离 WGSL 裸默认布局者，发射器必发 `@align/@size` 钉死（gpu-curtains 的 BufferBinding 范式：uniform 数组另建带 `@size(arrayStride)` 的独立 struct + 字段 @align 注解）。
5. **变体只有 override 一条路 + 结构变体拆模块**：编译期条件按档案 §6 四级分级——(1) 标量开关/数值参数且只影响常量位置与普通分支 → override（必给 `@id` 稳定键名、无默认值的标 `required: true`、宿主漏配在管线创建时响亮失败）；(2) 本属运行时数据者不进 override；(3) 改变资源接口/入口签名/阶段构成者 → **拆多个 .wgsl 模块**（变体维度在 SLASL 层登记，禁止用「声明了但某变体不用」的绑定蒙混——靠 DCE 删净）；(4) 预算意识：二值 override 建议 ≤ 个位数。gpu-curtains 全部变体走 shader constants、零预处理，实证此分级可行。语言特性（f16/subgroups 等）不是变体，是目标能力下限，进清单 `requires` 协商，不做运行时降级发射。
6. **一致性（uniformity）约束**：隐式导数采样（textureSample 等）只在一致控制流可移植地正确（规范 §15.2）。合并/DCE **不得**把采样点挪进/挪出条件分支而改变其一致性归属；采样/导数节点的一致性等级在 AST 层标注、合并后复核，违规在编译期报错（不留给目标运行时 UB）。fragment 外阶段用显式 LOD 采样（textureSampleLevel）。

**绑定落定方案**：group 0 预留宿主/帧级全局接口、材质级接口自 group 1 起（gpu-curtains 的投影网格路径如此；其裸 Mesh/Compute 路径自 0 起排——本设计取「0=全局」为 SLASL 的统一约定，宿主无全局接口时 0 组空置）；组内按**接口表声明序**编号；同一逻辑资源跨入口点/跨变体保持同一 (group, binding)（bind group 对象可复用的前提）；分组按频率分层（帧级→材质→物体→动态预留）。

**与 gpu-curtains 的对照结论（取舍明示）**：可借鉴——其三段命名注入槽（additionalHead / preliminaryContribution / additionalContribution）的**语义锚点**思想：宿主/库片段在良定义的锚点处汇入，而不是任意文本位置；对应到我方 = AST 合并层的具名汇合点（init 编织点、阶段入口点，§7.2）。**不取**（逐项点名）：子串级 chunk 去重、indexOf 式成员推断开关、静默丢弃不合规输入、声明序被实现重排（如数组成员挪尾）。我方纪律：**接口表以声明序为规范序；子集外/不合规输入一律编译期响亮拒绝**——这正是 AST 合并相对字符串拼接的立项理由。其余借鉴限于 shader 生产/组织实践，**不引入其运行时**（09:54 定界）。

**验收门定版**（档案 §5/§8）：`createShaderModule` **永不抛错**，不是验收门；真门 = **按清单布局建管线**（createRenderPipeline/createComputePipeline + error scope 断言为空），模块级前置判据 = getCompilationInfo 的 error 型消息数为 0。本机实测上限（档案 §8）：headless Chrome 156 + SwiftShader 下 L2 合法路径已证（建模块 0 消息、limits 与规范对账），L3 管线级未实跑、坏模块消息回收在 headless-shell 下未证通——如实登记，验收 harness 属浏览器操作须主会话安排。增量估计：发射器约当 hlsl 后端的 60–80%，排 P2 第一批方言之后紧随（§14）。

---

## 10. 导入方向（反向）：既有 shader → SLASL

（用户 2026-10-31 10:06 扩围：已有 shaders 可以全部回转到 SLASL，正反双向对称——Blender 的、Unreal 的、Shadertoy 的都要能转。）

### 10.1 架构对称

每个来源方言一个 **importer 前端**（解析 → 同一份类型化 AST + 接口表回收），与正向 target 后端共用 AST/接口表：AST 是双向枢纽。importer 不是文本转换器：产物必须过 SLASL checker 同一规则集；过不了的构造按 §10.2 拒绝。接口表回收口径：来源自带接口元数据（Blender create-info、Unreal 参数结构）者以其为准回收逻辑槽与参数表；无元数据者（Shadertoy）以宿主契约推导。**形态通则（用户 2026-10-31 10:13 定）：importer 一律是本地转换工具、用户手动发起的单件转换；不做任何来源的 API 客户端、key 管理、批量抓取或索引服务**——只在代码里、页面配置里的信息，由用户在转换时以声明配置补齐（§10.3）。

### 10.2 子集纪律与 round-trip 验收

- **subset 优先**：每来源界定子集（§10.3），子集外构造**响亮拒绝**——具名诊断 `UNSUPPORTED <来源>:<构造>` + 源码位置；不许静默近似（丢精度限定、吞循环边界、抹平未声明扩展行为皆禁）。
- **round-trip 两向分别界定**：
  - 源 → SLASL → 该源 target 产物：与原源做金文件/行为对照，等价面逐项列明（声明集、接口表、计算图）；文本形态不要求逐字同。
  - SLASL → target → SLASL：恒等面 = AST 等价（模 DCE 归一化）；注释、格式、宿主注入的 define 环境不属恒等面，归一化规则逐来源列明。

### 10.3 来源分期与契约面

**① Shadertoy GLSL ES（先行）**【档案已汇入：`~/workspace/shader-targets/shadertoy/REPORT.md`】

- **导入器真实形态 = GLSL ES 前端 + 宿主契约垫片**。契约层小而全机械（查表完成）；语言层是与正向编译器同量级的真前端——以 **ES 3.00 文法为骨架 + ES 1.00 别名/宽容层**（站点现行 WebGL2/ES 3.00 + 官方兼容定义形态；texture2D/textureCube 等存量习语在别名层归一到统一采样节点，扩展习语如 texture2DLodEXT 映射 textureLod 并留痕）。导入对象 = **剥掉宿主前后置后的用户代码 + Common**（API JSON 的 per-pass `code` 天然已剥离）；用户代码本就不含 main()/#version/标准 uniform 声明，全由宿主注入。
- **入口全集**：`mainImage`（Image 与 Buffer A–D 各一份同名入口、逐 pass 独立）、`mainVR`、`mainCubemap`（后二者为逐像素射线入口变体，rayOri/rayDir 进接口表作 per-fragment 输入）；`mainSound` 是**非片段入口种类**（一元时间→立体声样本的函数）——**首版响亮不支持，登记为入口种类缺口**，不近似。
- **契约垫片内容**：标准 uniform 全表（档案 §1.2 逐字表：iResolution/iTime/iTimeDelta/iFrameRate/iFrame/iChannelTime[4]/iChannelResolution[4]/iMouse/iDate/iSampleRate）入接口表作**保留宿主项**（固定名/类型/语义，与 Blender/Unity 的宿主注入项同类处理）；别名表收 `iGlobalTime → iTime`（历史改名、标痕）；`fragColor` 的 alpha 分量在原宿主**被忽略**——导入时在目标层标注此点（转到在意 alpha 的 target 时是语义漂移面）；fragCoord → AST 内建量 `frag_coord`（像素坐标语义逐字保留；正向发射 glsl 落 `gl_FragCoord.xy`）——为此 AST 增设 BuiltinVar 节点（正向承载 clip_position 同族）。
- **通道外部性（头号机械约束）**：`iChannel0..3` 的采样器维度（2D/Cube/3D）**只在页面配置里、从代码不可判定**（`texture(iChannel0, vec3)` 对 Cube 与 3D 不可区分）。故进料形态 = **代码 + 用户声明的配置**：通道采样器类型、filter/wrap/vflip/srgb、pass 归属由用户在转换时声明（声明字段集以档案 §1.3/§3.2 的 JSON 字段集为参照——那是这组信息的完整字段清单）；用户未声明的，工具**响亮标「未定型」并拒绝猜测**，不许默认猜 2D。
- **Pass 图建模**：Common → **链接期 AST 合并**进每个消费者 pass（与 §7 合并层同构；靠 #define 在 Common 里改写后续代码含义的写法除外，见 J-8）；Buffer 0..4 + 通道绑定 = **图层**（节点 = pass、边 = 通道绑定、feedback 标记自反馈边）——**自反馈是图层属性、帧语义（读上一帧/写本帧）由宿主契约声明，不进任何单个 pass 的 AST**。
- **导入器形态 = 本地转换工具、用户手动发起**（用户 2026-10-31 10:13 定：「不是 API 转换，是用户拿到后手动转换，我们不做 API」）：**无 Shadertoy API 客户端、无 key 管理、无批量抓取、无索引服务**；先前「转换器 + 索引」的产物形态**作废**。用户自备 shader 代码（自己从站点等方式拿到），用工具逐个转换到 SLASL——转换是用户触发的单件动作，不是自动化管线。档案中「API JSON 是理想进料」的结论，据此改读为「其字段集即用户声明配置的字段参照」（见通道外部性条）。
- **许可面（随形态简化）**：转换发生在**用户侧、针对用户自备代码**，我方只提供工具——工具本身不承载内容许可。事实背景仍登记：Shadertoy 用户作品默认 CC BY-NC-SA 3.0、逐 shader 须读代码头（作者可另声明 CC0/MIT 等）；这约束的是用户对其自备代码的使用与再分发，与工具无关。本线自身的导入验收语料口径不变：许可内测试夹具 / 用户自备 shader，不做整库转存。
- **覆盖率估算（工程估算、非普查，档案 §4.4）**：Image-only 约 **70–85%**、带 Common 约 **65–80%**；前提 = ES 3.00 核心子集（档案 A 组全量 + B 组数组/动态循环/uint 位运算）+ 宏展开路线（J-8 的 (a) 案为估算前提）。导入器立项后须以用户自备样本做一次抽样普查校准此数。
- **导入器内部决策点（显式登记，不静默改写）**：文件作用域可变全局（B 组高频：跨函数传每像素状态）→ 映射为片段阶段 var 集（工作假设）或在前端裁决他形，导入批内定形并留痕；函数重载/out/inout 参数映射注意 SLA 既有重载裁决与参数方向建模。
- **验收特化**（§10.2 的来源补充）：round-trip 须**多帧**执行（反馈语义第 2 帧起才可观测）+ **输入净化**（固定分辨率与 iTime/iFrame 序列逐帧喂入、iMouse/iDate 固定、通道资产用本地固定文件，视频/摄像头/麦克风类输入替换为静态替身或排除并注明）；数值判读只承诺**无头 WebGL2 真渲染的容差像素比对**（容差内像素占比 + 结构相似），**不承诺逐位等价**（驱动/精度差异使逐位不可达）。语料分层 L0–L6（档案 §4.3），L6 Sound 首版应判不支持且响亮。

**② Blender（次之）**

- 开源 + create-info 自带接口元数据：sampler/UBO/push constant 的 info 声明即接口表，导入时可回收（与 §9.3 正向的 info 件同源双向）。源码面的宿主注入（standard_defines、阶段 patch 头）以「已知宿主环境」建模为内建量/内建函数集。
- 子集界定：接口全由 create-info 声明的手写 gpu shader 先行；节点生成码（gpu_codegen 产物）是机器生成文本、导入价值低，后置登记。

**③ Unreal USF 子集（最后）**

- 只收**自包含子集**：依赖引擎 .ush 语义（Common.ush / MaterialTemplate.ush 等）的代码按构造在子集外，具名拒绝。可收类 = global shader 形态中参数结构显式、入口自包含者。置换 define 集封闭可枚举时映射 @const；不可枚举则拒绝该维度（不近似）。

### 10.4 与正向的里程碑关系

导入方向排在正向 GLSL/HLSL 落产之后（§14 分期 P3 起），来源顺序 Shadertoy → Blender → Unreal 子集。配对关系：Shadertoy 导入与 glsl 方言面共用前端基础设施；Blender 导入与 blender 约定层同批（接口表双向同源）；Unreal 导入在 unreal-global 约定层之后（先会写、再会读）。

## 11. std 落点与排除项

### 12.1 进 std 的（代码生产能力）

- **SLASL 编译器核心的 SLA 实现**（AST schema、checker、linker、emitters）：随 std/工具链分发的 SLA 库代码（P2 本体移植；P0 原型为 Zig 参考实现，§12）。它由构建步骤/资产管线运行，产物只有文件。
- AST schema 是语言层（ §4 提案落形后）与编译器核心的共用契约。

### 12.2 明确排除的（09:54 定界）

- 任何渲染运行时：program/uniform/texture 句柄面（native GL 与 WebGL/wasm 两向都排除）、上下文/窗口、材质/场景/驱动。**原章程「运行时面进 std」选项作废**，理由 = 用户定界原文：我们仅生产对应的 shader 文件，内核不要包括整个引擎。
- 语言层改进本身**不**在 std：宏等支持是 sa_plugin_sla（编译器）的事，std 只承载建立其上的 SLASL 编译器核心——两件事在 §1 分层里分开，勿混为「std 原生支持」的单一口袋。

### 12.3 链接执行点

生产点 = 构建/资产管线：构建步骤以 target 调用编译器核心产出文件集。此为语义基准（对应分叉 J-7 的 (b) 案）；「插件内静态链接」（编译期内完成合并与特化）只作可选优化登记，其成立依赖 GAP-5 的落形，不阻塞主线。

---

## 12. 原型与验收（P0）

验收分两层，对应本线双成果面：

### 12.1 宏测绘语料（已实测，证据层）

`probes/` 八个探针（p1–p8，p7 含库文件 m_lib.sla）+ `probes/run_probes.sh` 复跑脚本：每探针标注预期结果（通过/具名失败），与 §3 表逐项对应。口径声明：探针跑在已装插件 0.1.8 上，源码证据取 master `ccbffb2a`，两者交叉核对一致；这组语料即 GAP 登记的「改进前」基线——GAP 关闭后同一批探针的对应项应翻转（p1/p2/p3/p6/p8 的失败形态改变），是语言批的现成验收资产。

### 12.2 SLASL 演示负载（原型层）

`proto/`：Zig 0.17 参考实现（前端子解析器 = GAP-1 候选 (b) 的独立验证 + checker-lite + linker + 三发射器）。

- 输入：`proto/shaders/base.slasl` + `proto/shaders/tint.slasl`。
- 演示点（金文件逐项可查）：① init 乱序书写、链接后依赖序正确（tint 的 tint_boost/tint_pre）；② 同名同型 @param 跨片段统一为一份布局成员；③ **DCE 实证**：tint 的 `@param dead_weight` 与 `var scratch`（init 写 `scratch = tint * dead_weight`）无通向输出的依赖——须从 AST、参数布局、三后端产物**同时**消失，`golden/layout_before.txt` 与 `layout_after.txt` 对照；④ 采样三译：`tex.get(v_uv)` → ES300 `texture()` / ES100 `texture2D()` / HLSL `tex.Sample(tex_sampler, v_uv)`。
- 产出：`golden/merged.glsl-es300.vert/.frag`、`merged.glsl-es100.vert/.frag`、`merged.hlsl`、`layout_before.txt`、`layout_after.txt`、`variants.txt`。
- `proto/run_tests.sh`：重建 + 重跑 + 逐文件 diff，全等才 PASS（rc + 精确 diff，非肉眼）。
- GLSL 真编译：本机无 glslangValidator/ANGLE 工具链（已查），登记**未证面**；金文件即产品本体（09:54 口径），宿主侧校验由后续环境补。

### 12.3 原型不做清单（响亮登记）

helper 函数、let 临时变量声明、switch、导数内建、TArray 参数、Buffer/RWTexture/compute、Mat3x4、PerInstance、bindless、字符串逃生舱、二进制 AST 序列化（以 JSON/文本转储代）、多渲染目标、@range 消费、导入方向全部 importer（§10，P3 起，本原型只做正向）。逐项对应 hxsl 有而原型无，不静默窄化。

---

## 13. 分叉登记

- **D-1（已裁的事实分歧）**：用户简报称 hxsl 有 MetalOut；heaps master `f1139c38` 实测无（只有 GlslOut/HlslOut/NXGlslOut，h3d 无 Metal 驱动）。处理：MSL 列我方新增后端（P3），不冒充复刻。此项是证据裁定，非候 Jev。
- **候 Jev 包**（REPORT 单列，主会话裁决）：J-1 语法作为数据（GAP-1，候选 a/b/c）；J-2 声明级生成（GAP-2+GAP-6）；J-3 宏内类型可见性（GAP-3）；J-4 表达式位置用户宏（GAP-4）；J-5 检查器介入点（GAP-7）；J-6 编译期求值（GAP-5，条件性）；J-7 链接执行点（(b) std 库生产为基准 / (a) 插件静态链接为优化——本线建议 (b)，与 J-6 联动）；F-3 输出形态（hxsl 结构化 output 组 / 原型特殊名——建议生产形取结构化组，原型特殊名只作过渡）；**J-8 函数式 `#define` 宏的导入路线**（Shadertoy 档案头号分叉：宏被生态当泛型/代码生成器用，是导入覆盖率第一决定因素。候选：(a) **保覆盖·展开路线**——完整 GLSL 预处理器先展开后导入，AST 干净、覆盖率最高（§10.3 覆盖率估算即以此为前提），代价 = 作者结构（命名宏、参数化技巧）丢失、转出 SLASL 可读性降级、错误定位须映射回展开点；(b) **保结构·保真路线**——宏映射为 SLASL/SLA 宏，保真可读，代价 = 覆盖率受 SLA 宏面能力封顶、与 J-1/J-4 的落形强耦合（宏面不落形则此路不成立）；(c) **分级混合**（档案建议形）——对象式常量宏走 (b)、函数式宏首版走 (a) 并在产物留痕，代价 = 两套语义并存、留痕规范须定义。本线只列候选与代价，不定形）。

---

## 14. 分期

| 期 | 内容 | 里程碑口径 |
|---|---|---|
| P0（本线） | §3 测绘 + §4 GAP 登记 + 本设计 + §11 原型与语料 | 已交付形态（本批） |
| P1（语言批，候 Jev 后） | J-1…J-5 选定项落 sa_plugin_sla + 语料（探针翻转 + 新增正例，双后端四联判读）；SLASL 前端由参考实现换为 SLA 工具链原生面 | **本线里程碑在此**（语言改进落地），不在某家后端做完 |
| P2 | SLASL 编译器核心 SLA 本体（std）+ 方言批：glsl-es300/es100/hlsl-sm5 落产，**webgpu 紧随**（含反射清单） | 编译器核心本体化 |
| P3 | 约定层：unity → blender → unreal-global（compute 先行）；msl 方言；**导入方向开启：Shadertoy importer（子集 1：单 pass mainImage，§10.3）** | 约定层逐家以各自验收上限为准（§9）；importer 以 round-trip 纪律验收（§10.2） |
| P4 | spirv 方言、compute 形态、unreal Custom 片段（二期）、helper 函数与结构化 output（F-3 落形后）；**Blender 导入（create-info 接口回收）、Unreal USF 自包含子集导入、Shadertoy 多缓冲子集** | 登记项 |

重活纪律：本机与 CPS/batch-12 线共享（7.9G 无 swap、2 核），构建串行、跑前查 ps。

# SLASL DEF-1 修复报告（FIX_DEF1_REPORT）

日期：2026-11-01。修复线：DEF-1（落地前置门；独立复核 VERIFY_REPORT §6 登记）。对象：`src/slasl.sla`。**本线只修 DEF-1**；DEF-2/3/4 未动（已登记、另行处置）。staging 提交随本报告同批，未推送。

## 1. 根因（源码级）

SLASL 的 @const 折叠发生在链接期：`fold_stmts` 对每条语句的目标/值/条件调用 `subst_expr`（src/slasl.sla:2127），把 kind 2（标识符）节点按名查 `const_by_name` 并替换为常量字面量表达式，递归下降其余复合节点。

表达式节点 kind 分派（parse 侧）：0 数字字面量、1 bool 字面量、2 标识符、3 字段/swizzle、4 二元、5 一元负、6 调用、**7 类型构造式**（`parse_primary`:987——标识符是类型名且后随 `(` 时建成 kind 7，构造类型存 `ty` 字段、实参走 pool）。

**`subst_expr` 的分派表有 kind 2/3/4/5/6 五个分支，唯独漏了 kind 7**，落入缺省 `return e`——构造式整棵子树原样返回，其内任何位置的 @const 标识符（包括嵌在构造式内的二元式）都不被访问。而检查（chk_expr:1478）、DCE 读收集（collect_reads:2498）、类型推导（type_of_expr:3055）、发射（print_expr:3307）四处都有 kind 7 分支——是替换游走的单点遗漏，不是多处设计。各后端均不发射标量 @const 声明（WGSL 例外，见 §4），故未折叠的名字成为未声明标识符，宿主编译必失败。

**缺陷边界的实证修正**：复核报告称「折叠只覆盖右端为裸 const 标识符的形态」。本线对照探针（probe_binop：`v_s = SCALE * 3.0;`，无构造式）在**修复前**即正确折叠为 `v_s = (2.0 * 3.0);`——纯二元/调用/字段/一元嵌套一直可折叠；真正的边界是「@const 出现于任一构造式节点的子树内」。附录探针 C 的二元式失败正因它位于 `vec4(...)` 之内。

## 2. 修复形态与选择理由

两候选：(a) 引用点折叠——给 subst_expr 补 kind 7 分支；(b) 后端补声明——七个发射器各自补标量 @const 声明。

**选 (a)，单点补游走**（+10 行，见 §3），理由是代码与裁定事实而非偏好：

1. **既定语义就是链接期折叠**：bool @const 已在链接期折叠并消除 if（fold_stmts kind 1 路径）；Unreal 发射器内注释明言 “SLASL @const values are folded at SLASL link time”，置换域的值集靠「每个值集一次独立 SLASL 编译」产生。后端再声明一份常量会造出第二个真理源，与变体模型直接冲突。
2. **J-6 口径**：@const 仅字面量折叠（通用 comptime 后置）——折叠面在链接层，不在发射层。
3. **WGSL 的例外是自洽的**：override 是 WGSL 的原生机制（REPORT 有意偏离登记），且 WGSL 对裸右端同样折叠（见 §4 实证）——统一折叠后 WGSL 行为前后一致，不产生新语义决定。
4. (b) 要动 7 个发射器且每个目标的声明语法/位置都不同（GLSL const、HLSL const、MSL constant、ShaderLab、USF…），面大且与 1/2 冲突；(a) 一处补漏即全目标修复，与缺陷的单点成因对称。

未演变为真分叉：成因与两候选的优劣在源码层即可判清，无需试错。

## 3. 改动

`src/slasl.sla` 的 `subst_expr` 在 kind 6 分支后新增 kind 7 分支（+10/−0）：递归替换全部实参、经 `pool_span` 落池、重建节点时**保留 `x.ty`**（print_expr 靠它打构造类型名），a/b/op 与解析侧 kind 7 的取值一致（-1/-1/0）。其余文件零改动（samples/golden 为新增，见 §5）。

## 4. 修复前复现（盒二 rig：sci 83c61d43 + sla e3d2023 插件，与复核线同 rig）

探针 C（附录原文）逐目标生成，`SCALE` 只见使用处、无声明处（节选行号与复核报告一致）：

| 目标 | 悬空使用处（修复前） |
|---|---|
| glsl-es300 | merged.glsl-es300.vert:17 `gl_Position = vec4((position * SCALE), 1.0);` |
| glsl-es100 | merged.glsl-es100.vert:13 同形（**复核未单探、本线补实证：同族命中**） |
| hlsl | merged.hlsl:23 `output.position = float4((input.position * SCALE), 1.0);` |
| msl | merged.msl:22 同形 |
| blender | merged.glsl:19 同形 |
| unity | merged.shader:40 同形 |
| unreal-global | merged.usf:8 同形 |
| webgpu | merged.wgsl:26 用名，但:6 有 `@id(0) override SCALE: f32 = 2.0;` 声明——**合法（免疫）**；同文件:25 裸右端 `output.v_s = 2.0;` 已折叠 |

构造式探针之外，二元对照探针（probe_binop）修复前即折叠，见 §1。

## 5. 回归固化（harness 门 2 正式用例）

新增 8 个样本目录（同一输入 `def1.slasl`：裸右端 + 纯二元 + 构造式内二元三形态同文件），黄金为修复后产物、冻结前逐件目检（三形态在每目标均呈 `2.0` / `(2.0 * 3.0)` / `(position * 2.0)`，无 SCALE/STEPS 泄漏；WGSL 仅保留 override 声明与 reflection 条目）：

| 样本 | 目标 | 黄金文件数 | 修复前二进制对黄金（同/异） |
|---|---|---|---|
| def1-es300 | glsl-es300 | 2 | 1 / 1（vert 异，frag 无关构造故同） |
| def1-es100 | glsl-es100 | 2 | 1 / 1（同上） |
| def1-hlsl | hlsl | 1 | 0 / 1 |
| def1-msl | msl | 1 | 0 / 1 |
| def1-unity | unity | 1 | 0 / 1 |
| def1-blender | blender | 2 | 1 / 1（merged.glsl 异，merged_info.py 不含函数体故同） |
| def1-unreal | unreal-global | 3 | 2 / 1（merged.usf 异；ush/glue 本不含标量 const 使用故同） |
| def1-webgpu | webgpu | 2 | 1 / 1（merged.wgsl 异——修复前合法但未折叠，修复后统一折叠；reflection.json 同） |

每样本至少一件产物在修复前与黄金相异（门 2 判 DIFF = 失败）、修复后全同——「修复前失败、修复后通过」逐样本成立。webgpu 为免疫对照：证明其修复前产物合法（声明在位）的同时，把统一折叠后的字节钉为回归基线。

## 6. 全量回归（修复后，盒二同 rig、干净树、清.sla-cache）

`bash run_tests.sh`：**rc=0，53 条 PASS，fails=0**。构成核对：门 1 bundle 8/8（对一期黄金）+ 门 2 样本 23 件（原有 9 + 新增 14）+ 门 3 负例 21/21 + 合法对照 1 = 53。

- **零漂移**：门 1 与原有门 2 样本的黄金均为修复前冻结件，固定后逐字节全同——除新增用例外，既有黄金全集零变化（既有样本中唯一的标量 const 是 bool 型 USE_TINT，走 if 折叠路径，不经 kind 7，与本修复的作用面实证吻合）。
- **负例**：21/21 仍命中原 `// expect:` 诊断子串，对照 rc=0（在上述 53 内）。
- 探针层复验：probe_c 修复后 7 个非 WGSL 目标 `SCALE` 零出现；probe_binop 输出与修复前逐字相同（`(2.0 * 3.0)`，纯二元面未被本修复扰动）。

## 7. REPORT 诚实订正（仅文档，同批）

按复核 §1 第 13/14 项对 REPORT.md 做两处订正：

1. 缺口 §1：删「执行到 P2+P3 全量」措辞，改实范围（P2 全部 + P3 发射目标），并加订正注指向新缺口 6。
2. 缺口清单补 6（Shadertoy importer 子集未交付——P3 导入方向未开工、原稿未登记）与 7（Unity 变体数审计旁注缺失——仅 bundle 级 variants.txt，非 §9.1/§7.5 的逐目标审计旁注），均注明经独立复核指出、2026-11-01 补登记。

## 8. 过程登记

- rig：本机已装 SLA 插件版本过旧（build 时报 BorrowConflict，属已知上游面），本地构建不可用；全程用二盒复核 rig（sci 83c61d43 + sla e3d2023、插件为复核线装机件）。开工先探盒：二盒当时仅有一台闲置 slanginx 集成验证服务进程、无 bench 在跑；本线全部构建/生成均为短窗，未与主线 bench 同窗。
- 传输：三批 tar + 三个盒上脚本（固定路径 /content/slasl-def1/）均 sha256 双侧一致（tree a9e722d7…、tree2 69a72e6a…、tree3 4bd7e7ce…；脚本 949643f3…/1dba75f3…/ff0839ba…）。连盒全程裸 /usr/bin/ssh 直调，无「卡审核未执行」步。
- 证据留存：复现/修复/门禁探针与盒上脚本在本机 `work/def1/`（probe_c/probe_binop/probe_def1 + box_repro/box_fix/box_gates.sh），随本批提交。

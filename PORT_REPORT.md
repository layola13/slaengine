# SAX3D 工具链 SLA 移植 — 完工报告（PORT_REPORT）

用户裁定（2026-11-01 11:41）：sax3dc + 转换器全量 SLA 化，Zig 树与 SPEC
零改动留作逐字节差分裁判；schema 仍由 sax3d.sai 单一派生，禁手抄二表。
本线接续 12:53 检查点，跑到完工：步骤 5 盒上复验 + 全量差分 + 对齐 +
本报告。**未推送**——集成推送由主会话按守卫流程执行。

## 结论（先说）

- 移植完成：`crates/sax3d/sla/`（24 文件，约 15,000 行 SLA）对齐到
  slaengine main `99d28046` 内容，相对该基点**纯增量、零改动**（见 §5）。
- 全量差分：`run_tests` **62/62**、 `run_convert` **43/43**，两臂 PASS 名集
  逐字一致；`tests-run` 全树逐字节一致（仅垃圾输入与路径串两项已知例外）。
- 转换器全树除 4 个二进制文件外逐字节一致；Fox 导出 JSON、骨架、
  动画、节点顺序现已全部一致。
- **唯一未闭合项（诚实登记）**：Fox 派生法线 payload 有 1 ULP 级残差，
  根因为编译器缺陷 GAP-PORT-10（f32 加法向零截断），不在移植代码内；
  4 个二进制文件因此不同（见 §4）。其余一切逐字节一致。
- 步骤 5 宣称的“Fox 残差已修复”只对了一半：GAP-PORT-8/9 的修复确实
  生效（灾难性 (0,0,1) 回退消失），但差分揭示了两个此前未登记项：
  ① 节点子表遍历缺 idxpool 解引用（移植 bug，已修复，见 §3）；
  ② f32 加法舍入缺陷（编译器缺口，GAP-PORT-10，见 §4）。

## 1. 复验环境（口径偏差如实登记）

- 原定二盒（25024）在本线开工时已断：裸 ssh 两探皆 KEX 阶段
  `Connection reset by 198.19.0.1 port 3128`，一盒（25023）同期正常作对照。
  按任务书口径，本线改用**一盒作替代 rig**（当时一盒集成线已收口、
  负载空闲），并注明：rig 与二盒原 rig 同构（sci `83c61d43` 工作树 +
  sa_plugin_sla `e3d2023a` + 该树同期已装插件 .so md5 `123aa54d…`），
  但宿主 sa 二进制为一盒现行版（1d93041a 构建；SAB 格式未变、无 @gpu
  种类输入，对照不受影响）。
- 构建形态（实证纠正）：`sa sla build-exe`（direct-SAB 路径）对本树入口
  报 `UnsupportedSabDirectFeature`；前序轮次与本轮一律用宿主谓词
  `sa build-exe <入口> -o <bin>`（入口：src/sax3dc.sla；tools/convert、
  readback、genpayload、genref、gen_schema_sla）。五入口 + 派生器全部
  rc=0。盒上留存：`/content/saxport`（Zig 裁判树）、`/content/saxport-sla`
  （SLA 运行树）、`/content/saxport-rig/sci`（83c61d43 工作树）。

## 2. 差分结果（同窗一盒，Zig 裁判 vs SLA）

| 套件 | Zig | SLA | 名集 | 全树 |
|---|---|---|---|---|
| tests/run_tests.sh | 62/62 | 62/62 | 逐字一致 | 逐字节一致（例外见注） |
| tests/run_convert.sh | 43/43 | 43/43 | 逐字一致 | 除 4 个二进制文件外一致 |
| Fox pack（裁判外加项） | — | — | — | 仅派生法线段不同（见 §4） |

注：tests-run 树比较排除项：① `garbage.sax3d`（每轮 fresh /dev/urandom，
前序轮次已登记）；② WROTE/路径串（两树目录名前缀不同）；
③ `build.log`（SLA 轮跳过 Zig 构建步）与 `schema_gen.zig/.sla`
（各自派生器产物，步 0 新鲜度检查两边皆 PASS）。
负例：全部负例日志随 tests-run 树逐字节一致，即首诊断名与顺序一致，
不止“期望码出现”。

## 3. 步骤 6 修复：节点子表遍历缺 idxpool 解引用（移植 bug，已修）

- 现象：SLA `convert to-gltf` 的 Fox 导出节点顺序错乱（同名多重集、
  骨架/动画索引随之重映射，fox_equiv 因按名集比对仍 PASS），cube/hero
  导出逐字节一致；SLA `sax3dc pack` 的 Fox 产物亦差 174 B。
- 根因：SLA 模型里 NodeD.ch_off 是平坦 `x.idxpool` 的偏移
  （parse.sla:1255/1259；场景根同理，parse.sla:1299-1302），且节点
  索引是**后序**（节点在其子节点全部定稿后才入队，parse.sla:1254）。
  正确遍历须解引用（check.sla collect_nodes_rec、layout.sla:216、
  packform.sla:516 的根循环皆如此），但四处写成了偏移直当节点索引：
  layout.sla:122（nt_add_node 递归）、packform.sla:401（pf_node 递归）、
  convert.sla gltf_node_emit 子循环、convert.sla 场景根循环。
  小树/左子树上偏移恰与子索引重合故 cube/hero 全绿；Fox 26 节点树
  上错乱（例：Spine02 的子被读成左臂链倒序）。场景根循环对 Fox 恰
  巧正确（r_off 等于根的后序索引），但多树场景下必错，一并修掉。
- 修复：四处一律改为 `x.idxpool[(off + i)]` 解引用（语义不变、同值）。
  复验：Fox 导出 JSON 19351 B 两边一致、节点顺序/骨架/动画全等；
  Fox pack 除法线段外全段一致（readback packed digest 只差
  fox1_normal_derived 一行）。

## 4. 未闭合项：GAP-PORT-10（f32 加法向零截断，编译器缺陷）

- 现象：Fox 派生法线 `fox1_normal_derived.bin` 1929/5184 个 f32 字不同
  （多为 1–2 ULP，最大 21 ULP，系累积链放大）；连带 4 个二进制文件
  不同：该 payload 本身、裁判 `.saxb3d`、回放 `.bin`、`.glb`。
  其余全部产物（含 Fox.gltf JSON）逐字节一致。
- 定位（探针链，全部盒上实测）：Zig 导出与严格 f32 numpy 重算 0 差异；
  SLA 的 f32 乘/减/除、f64→f32 转换、f64 Newton sqrt 探针皆正确舍入；
  唯 f32 加法截断——最小复现（`probes/probe_f32e.sla`）：
  (1.0 + 2^-23) + 2^-24 的精确和为 1 + 1.5 ULP，正确舍入应为
  0x3F800002，SLA 给 0x3F800001；隔离复现（`probes/probe_f32d.sla`）
  证明和式中三乘与首加皆正确、末加低 1 ULP（精确和更近上邻、非平局）。
- 定性：编译器 f32 加法语义缺陷（加法 lowering 截断，或 f64 加法 +
  截断回写；两探针未区分二者），DEF-14 浮点语义家族。移植侧无
  语义保真绕法（改 f64 求和后单次舍入是另一种舍入方案，不等于 Zig
  的逐操作 f32 舍入），故移植代码保持与 Zig 相同的 f32 算术、
  缺口登记入 GAPS_LEDGER（GAP-PORT-10），不静默降级。
- 对验收口径的影响：除派生法线类 f32 累积量外，移植即逐字节一致；
  法线类产物在 GAP-PORT-10 修复前以“ULP 级一致、fox_equiv 通过”
  为口径，不冒充逐字节一致。

## 5. 对齐（座位形态）

- `git diff 99d28046..HEAD`：24 文件、+14978 行，**全部位于
  `crates/sax3d/sla/`**（src 12 + tools 6 + README/GAPS_LEDGER/probes/
  .gitignore）；Zig 树、SPEC、tests、converter、其余 crate 零改动。
  sla/ 子树即 slaengine 内 sax3d 工具链的 SLA 座位；Zig 实现继续担任
  差分裁判（未动）。
- 本地提交链：3fa381b（步骤 5 WIP）→ a199050（步骤 6 修复 +
  GAP-PORT-10 登记）→ af7b82f（复现探针入 probes/，因 work/ 被
  .gitignore 排除）。**未推送**，候主会话守卫集成。

## 6. GAPS_LEDGER 全表（终态）

- GAP-PORT-1：整数字面量上限 i64（表达缺口；移植用精确算术 2^63）。
- GAP-PORT-2：宏结果就地 cast 失败（实现 bug；移植用 typed 绑定）。
- GAP-PORT-3：f64 −0.0 规范化为 +0.0（语义缺陷；无值级绕法，语料
  计 affected 项；DEF-14 同族）。
- GAP-PORT-4：长寿命局部 struct 经 Vec push 损坏（实现 bug；移植用
  字面量直推 / push 后槽位覆写）。
- GAP-PORT-5：按值传 struct 经 helper push 损坏（实现 bug；移植用
  push 点内建字面量）。
- GAP-PORT-6：浮点字面量无指数记法（表达缺口；移植用算术构造 inf）。
- GAP-PORT-7：Vec<f64> 经整数转换截断（实现 bug，DEF-13 家族；移植
  用 Vec<u64> 存位模式）。
- GAP-PORT-8：f64 过控制流合流失 float 身份（语义缺陷；移植用单次
  绑定 helper / u64 位携带迭代）。
- GAP-PORT-9：while 头变量经 Vec 索引读赋值后永不重测（语义缺陷；
  移植用递归 early-return / 算术更新循环）。
- **GAP-PORT-10（本轮新立）**：f32 加法向零截断（语义缺陷；见 §4）。
- 分歧 D-1…D-4（Zig panic/未定义边，移植走诊断路）与规则 R-1…R-18
  （工具链写法规则，含 R-7/R-8/R-9 校验器 phi 形态）见 GAPS_LEDGER.md
  原文；步骤 6 节点遍历 bug 已修复，不再列为缺口。

## 7. 未验 / 待主会话项

1. 二盒恢复后，建议在二盒原 rig 上重跑一次 §2 两套件作异地复核
   （本轮因二盒断改用一盒，口径已如实登记）。
2. GAP-PORT-1…10（除已修复的移植 bug 外）归属 SLA 编译器线
   （DEF 队列），不属于本移植线；GAP-PORT-10 的复现探针已入
   `crates/sax3d/sla/probes/probe_f32e.sla`（最小）与
   `probe_f32d.sla`（隔离）。
3. 集成推送（sla/ 子树 + 本报告）由主会话执行；本线不自行推送。

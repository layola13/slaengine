# slaengine P0 实施批终报 — sla_ecs embed 接管 + sla_3d 批 A

支线批次（用户 2026-11-01 11:03 支线定位：盒上窗口让主线优先、全程错峰）。
方案 = `~/workspace/slaengine-survey/PLAN.md`（§2.2 切分、§2.3 目录映射、
§4.3 模块裁定、§5 P0 分期）；裁决 = `~/workspace/jev-designs/
slaengine_forks_ruling.json`（F1 单 crate 子目录、F2 Zig 内核支持库、
F5 sla_asset 独立座——后者已由地基留座、本批不涉）。
工地 = `~/workspace/slaengine-p0-local/`（自 slaengine-local 克隆），
staging 提交、未推送（推送由主会话守卫执行）。

## 1. 基点断言（内容断言为准）

| 对象 | 断言 | 结果 |
|---|---|---|
| slaengine 本地主本 | HEAD `be733c8`、工作树干净 | ✓ 开工实测 |
| sla_ecs 源克隆 `~/workspace/sla_ecs` | HEAD `1be020b`、工作树干净；lib 目录 524 条目 = 521 `.sla` + `component_metadata.sai/.sal` + `world_table_erased.sa` | ✓ 开工实测，与 PLAN §2.1/§2.3 一致 |
| sa_plugin_3dengines | `~/workspace/slaengine-survey/sa_plugin_3dengines/`（普查线核验克隆，基线 `06f4fae`、整包 sha256 双侧一致件） | ✓ 沿普查核验记录 |
| rig（二盒 25024，hostname `5586cbdbf3e3`） | `/content/slaengine-rig/`：sla 树 `e3d2023a`、sci `83c61d43`、装机插件 libsla.so md5 `9159ee73…`（与 rig 构建件一致） | ✓ 开工实测 |

## 2. 第一阶段：sla_ecs 全量接管（映射执行记录）

按 PLAN §2.3 执行，脚本 `work/migrate_sla_ecs.sh`：

| 原路径 | 目标 | 数量 | 处置 |
|---|---|---|---|
| `lib/*.sla`（含 `*_deep`） | `crates/sla_ecs/src/` 同名平坦 | 521 | 原样迁入 |
| `lib/component_metadata.sai` / `.sal` | `crates/sla_ecs/src/` | 2 | 原样迁入 |
| `tests/*.sla` | `crates/sla_ecs/tests/` | 426 | 导入前缀 `"lib/…"`（438 处）/`"../lib/…"`（16 处）→ `"../src/…"` |
| `examples/*.sla` | `crates/sla_ecs/examples/` | 90 | 导入前缀 `"../lib/…"`（55 处）→ `"../src/…"` |
| `docs/`（2）+ 根 `*.md` 报告群（10） | `crates/sla_ecs/docs/` | 12 | 原样归档；原 README（含 Bevy 对照/哲学表）存 `docs/README.md` |
| `sa.mod` | `crates/sla_ecs/crate.toml` | — | 地基座位清单改写为 lib crate（entry = 门面 `src/ecs_world.sla`、test = 逐文件口径运行器、provenance 注释块） |
| crate 根 `README.md` | — | — | 改写为 crate 说明（公开面/布局/逻辑组/口径/已知缺口；core/tasks/reflect 逻辑组按 §2.2 在说明中划界，物理拆分候 P3） |

**唯一导入规范化点**（PLAN 点名的 7 文件，本机 grep 实测恰为此 7 个）：
`filtered_resource_builders`、`message_iterators`、`message_mutator`、
`message_reader_writer`、`message_registry_update`、`messages_buffer`、
`query_filtered_set` —— 其 `"lib/x.sla"` 导入改裸名 `"x.sla"`。

**不迁**（PLAN 明列）：`lib/world_table_erased.sa`（生成物；实测无任何
`.sla` 引用它）、`src/main.sla` + `workspace_demo/`（`return 0` 桩）、
`fix_while_semicolon.py`（一次性脚本）。

**保真审计（本机，迁移当轮）**：
- src 其余 514 文件 + `.sai/.sal` 与源逐字节 `cmp` 一致；
- 7 个规范化文件 diff 仅 `@import` 行；tests/examples 全部文件 diff
  仅 `@import` 行（逐文件 diff 过滤非 import 行输出为空）；
- 迁后全树残留 `"lib/…"` / `"../lib/…"` 导入 = 0；
- 导入目标存在性全核：仅 1 处未解析——
  `examples/state_scoped.sla` 的 `@import "../../sla_state/src/lib.sla"`
  为**存量外部引用**（兄弟仓不在接管范围；本机与盒上均无 `sla_state`，
  源树同样不可解析，双树条件对称，见 §4 注记）。

**零语义改动**：sla_ecs 内部除上述导入行外无任何行变更（纯外挂原则
自迁移起算）。

## 3. 验收门禁口径（双树对照）

- 口径 = sla_ecs 自身口径（源 README「Running」节）：逐文件
  `SA_PLUGIN_DEV=1 sa sla test <file>`，范围 = lib/src + tests +
  examples 全部 `.sla`（521+426+90 = 1037 文件/树）；例外两文件按
  README 原注加 `--test-backend sa`：`parallel_iterator.sla`、
  `task_pool_builder.sla`（basename 规则，双树同）。
  注：README 的命令清单只逐条列出 121 个文件（79 lib + 42 examples，
  tests/ 未逐条列），本批口径取「全目录逐文件」——与 PLAN §2.3
  「tests 随迁、逐文件 sa sla test、失败名集同口径对照」的成文一致，
  且双树严格同口径，名集可比性不受清单详略影响。
- 冷口径：每树副本开跑前清 `.sla-cache`，`SLA_NO_FRESHNESS_CACHE=1`；
  rig 同上（sci `83c61d43` + sla `e3d2023`，插件 md5 同轮核对）。
- 执行形态：4 份字节相同树副本分片并行（分片间不共享 `.sla-cache`，
  单文件口径不变），运行器 = crate 内提交的 `tests/run_tests.sh`
  （双布局参数 orig/crate，基线树亦用同一运行器）。
- **失败名字集**定义：`相对路径 :: 失败测试名`（runner 打印具名失败
  时）或 `相对路径 :: <file-level>`（编译/导入级失败）；基线侧
  `lib/` 前缀在合并时归一化为 `src/` 后与迁移侧逐名 diff。
  rc 只记入 results.tsv 作元数据、不入名字集。
- 判读（四联）：逐文件 rc + `test result:` 行 + 名字集 + 双树对照；
  **名字集 diff 非空即不达标**——停下登记，不以改测试收场。

## 4. 双树结果

**名集门裁定：PASS —— 两树失败名集逐名相等、diff 为空。**

二盒 rig 实测（同 rig、同口径，基线 `orig` 布局 / 迁移 `crate` 布局，
各 4 分片并行、每树副本开跑前清 `.sla-cache`）：

| 项 | 基线树（源 sla_ecs @1be020b） | 迁移树（crates/sla_ecs） |
|---|---|---|
| 文件数 | 1037 | 1037 |
| 通过文件（rc=0 且结果行 `test result: ok`） | 704 | 704 |
| 失败文件 | 333 | 333 |
| 失败名集条数 | 405 | 405 |
| 构成 | 具名 87 + 文件级 318 | 具名 87 + 文件级 318 |

- **逐名 diff**：`diff results-baseline/names-derived.txt
  results-migrated/names.txt` 输出为空。
- **对称派生复核**：对迁移侧结果再以同一 `derive_names.sh` 从逐文件
  日志重派生，得 405 条，与驱动合并的 `names.txt` 逐名一致；再与
  基线派生集 diff 仍为空——两侧口径对称、非单侧运行器格式之利。
- **失败条目分布**（迁移集，按区）：tests 246 / src 82 / examples 77；
  333 个失败文件中 318 个为文件级（编译/导入级），其余 15 个文件
  承载 87 条具名失败。此失败存量为源树既有状态（SAB 后端整文件
  问题等，见 §6.4），迁移前后逐名不变——本批门禁的判据即此不变性，
  不冒充全绿。
- **7 个导入规范化文件抽验**（results.tsv 双树逐条）：7 文件双树均
  rc=0、结果行逐字同为 `test result: ok. 0 passed; 0 failed;
  0 skipped`（此 7 文件本无 `@test`，双树同形态空过；规范化未引入
  任何可观察差异）。
- **`examples/state_scoped.sla`**：双树名集均含
  `examples/state_scoped.sla :: <file-level>`——§2 所述 `sla_state`
  存量外部引用双树同形态失败，条件对称（处置见 §6.5）。
- **运行器格式病留痕**（前任回执、本节复核确认）：首轮基线运行器以
  rust 式模式提取具名失败，对 SA 宿主输出零命中，333 个失败文件全
  塌缩为文件级条目（`results-baseline/names.txt` 333 条）；修正为
  宿主实测的 `[FAIL] <name>` 格式后，从保留日志重派生得 405 条
  （具名 87 + 文件级 318），即上表口径。旧 333 条集仅作过程留痕，
  不作判读依据。

## 5. 第二阶段：sla_3d 批 A

模块清单 = PLAN §5 P0 批 A 五模块（math/time/input/color/transform），
源 = sa_plugin_3dengines @ `06f4fae`。脚本 `work/migrate_sla_3d_batch_a.sh`。

语言定位（用户总则 2026-11-01 11:42：**slaengine 以 SLA 为主，
Zig/C/Python 为辅助**）：本批迁入本体为 SLA 源码（sla_ecs 全体、
批 A 各域 `.sal` 行为层），与总则天然一致；批 A 中 math/time/
transform 的 Zig 内核按 Jev F2 以支持库随迁，其定位按此总则登记
为**辅助面**——位于 `.sai` 之后、行为层在 SLA，辅助面不得漂移
成主体。此定位同样适用于后续批 B 的 geometry 内核。

落位与处置（与 PLAN §4.3 裁定逐项对应）：

| 模块 | 裁定 | 落位 | 内容与审计 |
|---|---|---|---|
| math | 改造后移植（内核 F2） | `src/math/`、`native/math.zig`、`tests/math/` | `.sal` 逐字；plugin.zig（759 行、60 exports、6 个 zig 单元测试）的 6 行插件框架胶水（module_plugin 导入 + 2 描述符再导出 + comptime 引用块）替换为对 crate 内 ABI 垫片 `native/saasm_abi.zig` 的注册（同描述符符号、仅身份字段），作支持库随迁；diff 审计变动行恰为此胶水段，别无他行（垫片设立理由见下「描述符偏差记录」） |
| time | 直接移植 | `src/time/`、`native/time.zig`、`tests/time/` | `.sal` 逐字；plugin.zig（199 行、14 exports、1 单元测试）同法替换 6 行胶水为垫片注册。附注：内核全程显式纳秒入参、**从不读宿主时钟**（grep `std.time` 零命中），§4.3「Zig 宿主时钟改绑 sa_std」在内核侧无对象——宿主时钟注入属未来 App/宿主层事项，登记于 crate README |
| input | 直接移植 | `src/input/`、`tests/input/` | `.sal` 逐字；其 plugin.zig 仅 8 行框架样板、无内核 → 不迁（测试零 extern、只测 .sal，与源家口径同） |
| color | 直接移植 | `src/color/`、`tests/color/` | 同 input（plugin.zig 仅 7 行样板） |
| transform | 改造后移植（内核 F2） | `src/transform/`、`native/transform.zig`、`tests/transform/` | `.sal` 仅 1 行改动：第 21 行跨模块导入 `"../sa_plugin_3d_math/3d_math.sal"` → `"../math/3d_math.sal"`；plugin.zig（403 行、29 exports、3 单元测试）同法替换 6 行胶水为垫片注册 |

测试随迁：每域 `tests/<域>/3d_<域>_layout_test.sa`，与源 diff 恰为
第 1 行导入路径（`../3d_<域>.sal` → `../../src/<域>/3d_<域>.sal`）。
crate 级 `build.zig` 构建 `lib3d_{math,time,transform}.so` 支持库并跑
其内嵌 zig 单元测试；`tests/run_tests.sh` 复刻源家口径（zig build +
zig build test + 逐域 `sa test` + `SA_PLUGINS_PATH` 指向本域支持库；
input/color 不设）。

**描述符偏差记录（对 PLAN §4.3「common/ 不移植」的最小偏离，附据）**：
首轮盒上验收中 zig build / zig build test 通过、input/color 两域
`sa test` 各 6/6 PASS，但 math/time/transform 三域 `sa test` 链接
失败（`undefined symbol: sa3d_*_selftest`）——尽管三库的动态符号表
里 selftest 符号俱在（nm -D 核对：math 60 / time 14 / transform 29
个 T 符号）。根因：SA 宿主的开发模式加载（sci `src/plugins.zig`
loadDescriptor / validateDescriptor）只承认导出插件描述符符号
（`saasm_plugin_descriptor_v1` / `_fn`，且 abi_version 与
descriptor_size 须与宿主 ABI 相符）的 `.so`，测试的 extern
selftest 经此加载注册；源家族描述符来自框架
`common/module_plugin.zig`（`pub export const` 于其 :166/:168），
初版迁移按 §4.3 字面删去胶水后描述符符号随之消失，宿主遂不加载
该库。处置（最小偏离）：不迁回框架本体（其 CLI 命令处理器与技能
注册表仍按裁定退役、其 3 个框架单元测试随之退役），只在 crate 内
设 ABI 垫片 `native/saasm_abi.zig`（ABI 类型逐字自源家
`common/plugin_api.zig`，描述符仅身份字段：abi_version / size /
域名 plugin_name；handle_command = null、技能表空），三内核的胶水
段改为对垫片的同形注册。此偏离的性质 = PLAN 未预见宿主加载契约，
非语义改动；三域 SA 测试语料与口径零改动。

**盒上验收结果（二盒 rig 区，垫片修正后复跑，ACCEPT_3D_RC=0）**：
zig build 通过、zig build test 通过（内核单元测试 math 6 / time 1 /
transform 3，共 10；任一步失败验收脚本即非零退出）；五域 SA 布局
测试全 PASS、失败名集为空——math 19 passed、time 10 passed、
input 6 passed、color 6 passed、transform 7 passed（合计 48 passed /
0 failed）。描述符证据：`nm -D lib3d_math.so` 含
`saasm_plugin_descriptor_v1`（D）与 `saasm_plugin_descriptor_v1_fn`
（T），宿主加载成立。批 A 验收通过。

**未迁（PLAN 裁定，本批外）**：3d_ecs（以 sla_ecs 为准）、3d_gltf
（以 sax3d 转换器为准）、3d_shader（以 slasl 为准）不迁；sap.json、
`src/module_config.zig`、各插件 build.zig 为插件时代宿主脚手架，随
宿主壳整体退役（crate 级 build.zig 取代）。

## 6. 未迁 / 待后项清单

1. sla_3d 批 B（P1）：geometry / camera / camera_controller / image /
   material / pbr / light / scene / animation / gizmos / particle，
   按 §4.3 各自裁定（含 geometry 的 F2 内核、image/material/pbr 的
   格式对齐改造）。
2. transform 传播系统改挂 sla_ecs System 形态（以 hierarchy 关系为
   父子真理源、不保留模块私有父子表）——§4.3 的最终形态，属 P1
   打通 C2 的接线工作；批 A 按行为原样迁入，未静默丢弃（crate
   README 已登记）。
3. App 打通与资产桥（C1–C8）不在本批（任务书明示，P1 另行立项）。
4. sla_ecs 已知缺口归期不变（PLAN §2.4）：TaskPool/Scope 完整调度
   P3 骑 goroutine 运行时；bevy_reflect 级反射为语言层事项不归引擎
   期次；SAB 后端个别整文件问题随 DEF 队列——本批门禁以名字集
   如实呈现，不冒充全绿。
5. `examples/state_scoped.sla` 的 `sla_state` 外部引用：兄弟仓
   （Bevy bevy_state 对应）不在本次接管范围；其归宿（迁入
   slaengine 或另行处置）候后续裁定，本批原样保留该引用与失败形态。

## 7. 提交链（staging，未推送）

基点 `be733c8`（地基主本）之上 9 笔：

```
38b036f p0(sla_3d): runner — PASS verdict requires the host result line, not rc alone
9b5d5f8 p0(sla_ecs): runner — extract named failures in the host's [FAIL] format
f3bdd16 p0(sla_3d): ABI shim for batch-A support libraries (descriptor correction)
4e0e049 p0(sla_ecs): runner — file-level failing names carry no rc
b272c06 p0(sla_3d): crate build/tests/manifest for batch A
b0abfd6 p0(sla_3d): batch A domains — math/time/input/color/transform behaviour + native kernels
403cae5 p0(sla_ecs): takeover manifest, crate README, docs archive, test runner
b574528 p0(sla_ecs): embed tests (426) + examples (90) with ../src/ import rewrite
db73699 p0(sla_ecs): embed lib corpus into crates/sla_ecs/src — flat takeover @1be020b
```

本报告（P0_REPORT.md）随收尾提交入链。推送与对齐当前 slaengine
main（`7efd415` 谱系后续头）由主会话守卫执行。

## 8. 纪律登记

- **连盒方式**：全程裸 `/usr/bin/ssh -i … -p 25024 -o ConnectTimeout`
  直调；多步核验用盒上固定路径脚本（`/content/slaengine-rig/
  p0_verify.sh`、`derive_names.sh`），传输以 cat 管道 + sha256
  双确认（`e7aa2e9a…` / `5bf15dd5…`，双侧逐字一致后才执行）。
- **rig 插件加载面歧义（如实登记）**：验收口径 `SA_PLUGIN_DEV=1`
  加载的是 rig 的**装机**插件而非树内构建产物本身；开工断言装机
  `libsla.so` md5 `9159ee73…` 与 rig 构建件同值，两者以此绑定。
  本批未另行验证其他加载路径，名集结论仅在此口径内成立。
- **错峰实况**：ecs 双树验收为长时运行（迁移树 4 分片自 12:39 CST
  启动、约 20 分钟跑完，慢尾集中于 executor `*_deep_isolated` 类
  文件、单文件超时界 600 s）；同期二盒另有主线 slanginx 复跑线与
  saxport 支线活跃。本线（支线定位）未新开 bench 类工作，续跑阶段
  只以裸 ssh 轮询在跑进程、未重启任何分片；批 A 的三域链接失败
  首轮发生时，处置亦未占用主线窗口。
- **卡审核步**：本批全程无卡审核未执行步。

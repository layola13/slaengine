# slaengine 地基线终报 — workspace 地基 + slasl/sax3d 两 crate 落位

日期：2026-11-01。线定位：支线（用户 11:03 定），盒上编译/测试全程给主线
让窗——验收在主线 bench 空窗错峰执行（见「错峰与窗口」节）。
本地主本：`~/workspace/slaengine-local/`（本地提交，未推送；推送由主会话
复核后守卫执行）。

## 0. 结构总则（用户 2026-11-01 11:21 定）

**复刻原则：代码方式尽量与 Bevy 1:1** —— API 表面、调用形态、命名向
Bevy 对齐；**内核实现按我们的情况自由调整**，以对我们最有利、开发速
度最快为准，不全盘复制 Bevy；**Bevy 的宏体系不学** —— derive/过程宏
那套重机制以编译器内建、描述符注册表、函数指针等轻机制顶替。本仓的
workspace 形态、伞 crate 的 App 层留形（§4）与后续一切 crate 的公开面
均按「表面 1:1、内核自由、宏不学」登记与评审。

## 1. 远端真实状态

`https://github.com/layola13/slaengine`：经一盒（25023）盒内 GIT_TOKEN
认证 `git ls-remote` 核实（令牌仅盒内 shell 抽取、未打印）：
**rc=0、零 ref —— 仓库存在且为空仓**（无任何分支/标签）。
本地主本据此 `git init` 建仓并接 `origin` 指向该 URL，未做 fetch/push。

## 2. workspace 结构

顶层清单 `workspace.toml`（学 Bevy 根 Cargo.toml，README 有完整对应表）：

| 节 | 内容 |
|---|---|
| `[workspace]` | 成员表（见下）+ `resolver = "path"`（成员间只许 workspace 相对路径互引） |
| `[workspace.package]` | version `0.1.0`、license `MIT OR Apache-2.0`（Bevy 双许可默认值，待仓主确认）、authors |
| `[workspace.toolchain]` | 验证基 rig 钉死：sci `83c61d43` / sla `e3d2023` / zig `0.17.0` |
| `[workspace.dependencies]` | 共享外部面：`sa_std`（sci/sa_std，经 `@import "sa_std/..."` 绑定；引擎逻辑不进 sa_std） |

成员表：

| 成员 | 形态 | 状态 | 来源/说明 |
|---|---|---|---|
| `.`（伞 crate `slaengine`） | `crate.toml` + `src/slaengine.sla` | 骨架在役 | App 层宿主（见 §4） |
| `crates/slasl` | SLA 工具（`sa build-exe`） | 在役 | slasl-p2-local @ `125208f`（含 DEF-1 修复）字节级导入（§3） |
| `crates/sax3d` | Zig lib+工具（`zig build`） | 在役 | sax3d-impl-local main `e3ebe0f`+`0a44b80` 字节级导入（§3）。Jev F4：资产桥链以此已验 Zig 库产解析产物（0.91）；F6：SPEC §6.4 keep_name_only 维持定版（0.83，置信 0.66） |
| `crates/sla_asset` | 保留座位 | 占位登记 | 资产桥独立成座（Jev F5，0.94；出处 = 普查 PLAN 打通清单 + Jev 裁决）：只认 SAX3D §4.5 契约与 slasl 接口表的桥 crate，本线不填内容 |
| `crates/sla_ecs` | 保留座位 | 占位登记 | sla_ecs embed（源码进仓作 crate、非外部依赖）；切分/映射由普查线 PLAN 定（P0 单 crate 平坦迁入），填充另行立项。迁移基线 sla_ecs @ `1be020b`、原仓冻结（用户 11:01 全量接管定案） |
| `crates/sla_3d` | 保留座位 | 占位登记 | sa_plugin_3dengines 模块移植座位；形态 = 单 crate + 域子目录（Jev F1，0.83）；math/geometry 的 Zig 内核以支持库随迁、经 .sai 暴露（Jev F2，0.83）；逐模块裁定见普查 PLAN（直迁 7 / 改造迁 9 / 不迁 8） |
| `crates/sla_webgl` | 保留座位 | 占位登记 | 渲染后端第一优先（WebGL 面，用户 11:02 定序） |
| `crates/sla_gpu` | 保留座位 | 占位登记 | 渲染后端第二优先（Web3D/GPU 面）；自带 wasm 导入面直绑 WebGPU、不依赖 wgpu 插件（Jev F3，0.97） |

与 Bevy 的对应关系（详见 README「Correspondence with Bevy」）：成员表 /
root package 伞 crate / 每 crate 一清单 / `[workspace.package]` 版本继承
（成员写 `version.workspace = true`）/ `[workspace.dependencies]` 共享面 /
工具链钉死，逐项对应 Bevy 的 `[workspace]`、root `bevy` crate、
`crates/bevy_*`、`[workspace.package]`、`[workspace.dependencies]`、
`rust-version`。生态差异两处明示：① 成员异构（SLA 工具/lib 与 Zig 包
并存，无单一 cargo 式驱动，各 crate 在自己 `crate.toml` 声明 build/test
入口）；② sa_std 在 workspace 之下、不进 workspace。

## 3. 两 crate 导入保真

- **sax3d**：`git archive` 源仓 HEAD（`0a44b80`）整树导入，67 文件与源仓
  跟踪数一致；`build.zig`、`sax3d.sai`、`src/lib.zig` 与源文件 sha256
  逐一相同。导入前状态：复活线已在现行工具链复验 PASS（62/62、24/24、
  Fox 21/21）。
- **slasl**：基点已对齐 DEF-1 修复提交 `125208f`（源仓 `dc8c799` 首
  落位后按主会话通报同步）：`git archive` 取工具本体 + 规范样本 + 黄
  金 + 样例/样例黄金 + 负例集（95 文件）；源仓 `work/` 探针文件不导
  入。`src/slasl.sla` 与源 sha256 相同（`e6cf3869…`）；`golden/`、
  `samples_golden/`、`neg/`、`shaders/`、`samples/` 与源 `diff -r`
  全等。DEF-1 修复内容随基点进入：`subst_expr` 补类型构造式（kind 7）
  @const 折叠分支（+10 行）、`samples/def1-*` 8 个正式用例 + 对应黄金、
  REPORT 措辞订正；`VERIFY_REPORT.md` / `FIX_DEF1_REPORT.md` 随 crate
  在册。修复前基点（`dc8c799`）的 harness 口径为 39 PASS 级，修复后
  口径 = 全量 53 PASS（§5 按此复跑）。

## 4. 伞 crate 向 App 层演进的预留形态

伞 crate 入口 `src/slaengine.sla` 按 Bevy App/System 组织留形，不是普通
再导出层（用户 11:02 定案）：

- `struct App { plugins, systems }` —— App 构建器值，后续一切引擎层挂
  在其上；
- `app_new()` —— 构建入口（预留：将来承载构建器链式配置）；
- `app_add_plugin(&App)` —— Plugin 注册点：本期两个在役 crate 以创始
  Plugin 身份在 `main` 中注册（计数 2）；sla_ecs 嵌入、WebGL/GPU 渲染
  后端落地时走同一注册点，不改入口形态；
- `app_add_system(&App)` / `app_add_systems(&App, schedule)` —— System
  注册点：后者是标杆形态（带 Schedule 标签，0 = Startup、1 = Update）；
  本期计数 1（`main` 以 Startup 标签登记一笔形态），无真实 System；
- `app_run(&App) -> i32` —— Schedule 运行入口：本期打印引擎标识 + 成员
  注册表后 rc=0 退出；
- API 级再导出的生长路径：slasl/sax3d 本期公开面是 CLI 工具 + 产物文件
  （shader 文件 / 资产格式与工具链），伞层以 App 注册 + 管线组合
  （examples/smoke）行使统一入口；待 sla_ecs 等库形态 crate 落地后，
  再导出面随之增厚（slasl 的 lib/bin 拆分是其前置重构，已登记待决）。

### 4.1 对齐用户简洁度标杆所需的 sla_ecs 能力点（逐项待核）

目标表面 = 用户 2026-11-01 给定的 Bevy 动态 system 注册示例（存
`~/workspace/slaengine-survey/bevy_system_registry_example.rs`）：prelude
式单行导入、App 构建器 + `add_systems(标签, 系统)` + `run()`、
`Commands.register_system(闭包)` 返回 `SystemId` 且可存入 Component、
日后 `Commands.run_system(id)` 触发、boxed system 同样可注册、
`Commands.spawn`、`Query` 迭代。骨架阶段只登记形态与命名（见
`src/slaengine.sla` 头注「TARGET SURFACE」段），不实现语义。

普查口径与标杆的张力点先行点名：普查定 Plugin/系统注册为「函数指针
+ 描述符注册表」；标杆要求**闭包/boxed 系统运行时注册**。以下能力点
属 P0/P1 实施批设计题，本报告如实标**待核**，**不许静默降级为仅静态
函数**：

| # | 能力点 | 标杆要求 | 现有底料 / 待核内容 |
|---|---|---|---|
| C1 | prelude 式单行导入 | 一行导入带入 App/Commands/Query/SystemId 等名 | SLA `@import` 粒度与伞 crate 再导出面能否承载，待核 |
| C2 | 闭包系统注册 | `register_system(closure)` 接受带捕获环境的闭包 | 普查底料为 fn 指针 + 描述符；闭包捕获的表示与注册方式待核（sla_ecs `AppFunctionRegistry` 描述符注册表为候选底料） |
| C3 | boxed system 注册 | `register_boxed_system` 接受已装箱系统 | 类型擦除的系统存储（BoxedSystem 等价物）在 SLA/ECS 内的承载待核 |
| C4 | SystemId 入组件 | `SystemId` 是可存进 Component 字段的普通值 | SystemId 的值语义 + 组件存储对其尺寸/登记的要求待核 |
| C5 | Commands 延迟队列 | spawn/register/run 经延迟队列在 Schedule 边界应用 | 延迟队列的存储与应用时机（顺序语义）待核 |
| C6 | run_system(id) 动态触发 | 按 id 在运行时查表并调用已注册系统 | 注册表按 id 索引 + 动态分发路径待核 |
| C7 | Query 迭代 | 系统内 `Query<T>` 迭代组件（含在已注册闭包系统内） | sla_ecs Query 面与注册系统的参数注入方式待核 |
| C8 | exclusive 系统 | 以整个 World 为参数的系统类别可注册 | 与普通系统的注册类别区分待核 |
| C9 | Schedule 标签 | Startup/Update 等命名标签 + 系统挂载 | 标签命名与排序语义待核（骨架已留 `app_add_systems(app, label)` 形态） |

## 5. 盒上验收（错峰窗口内，rig = workspace 钉死口径）

验收在二盒（25024）执行，rig = sci `83c61d43` / zig `0.17.0` / sa
0.1.8。全部 SLA 构建为**冷构建**口径（`SLA_NO_FRESHNESS_CACHE=1` +
清 `.sla-cache`）；判读按四联（rc + 期望结果行 + 失败名字集 + 该项口
径）。逐项结果：

| 项 | 结果 |
|---|---|
| sax3d crate 构建 | `zig build` rc=0 |
| sax3d `tests/run_tests.sh` | rc=0，`RESULT: 62 passed; FAILED SET: (empty)` —— 62/62、失败名字集为空 |
| sax3d `tests/run_convert.sh` | rc=0，`RESULT: 24 passed; FAILED SET: (empty)` —— 24/24；Fox 往返项（fox-import / fox-roundtrip-equiv / fox-glb-structure 等）在 24 项内全 PASS（源仓复活口径 Fox 21/21 与此一致） |
| slasl harness（`crates/slasl/run_tests.sh`，基点 `125208f`） | rc=0，**53 PASS、fails=0**（三门：bundle 8 产物字节级对黄金、samples 含新增 def1-* 8 例、负例 21/21 具名诊断）；与修复线全量口径一致 |
| 伞 crate 冒烟（`examples/smoke/run_smoke.sh`） | rc=0，三项全 PASS：umbrella-entry / slasl-generate / sax3d-check，`SMOKE RESULT: fails=0`；伞入口运行输出含 `plugins registered: 2`、`systems registered: 1`、成员表（active slasl/sax3d；reserved 含 sla_asset） |
| 伞入口单独冷构建（cwd = workspace 根） | rc=0，`Successfully compiled` |

两条 rig 事实（影响一切 SLA 线、非本 workspace 缺陷，如实登记）：

1. **冷构建的 cwd 条件**：本盒 `/content/sa_all` 的 sla 检出停在
   `264211e9`（旧于钉死口径 `e3d2023`），且装机插件的冷导入展开在
   「无已构建 SLA 树的目录区」内会以 `Import Error: failed to expand
   @import SLA sources: error.FileNotFound` 失败（首轮验收曾因此两项
   FAIL；同期表观 PASS 经查为新鲜度缓存命中、非冷通过，已作废不引
   用）。本线在二盒自建 rig 区 `/content/slaengine-rig/`：sla 树对齐
   `e3d2023a`（自 sa_all 克隆 + 增量 bundle 取齐）、`sci` 以 symlink
   指现行 `83c61d43`（插件 build.zig 按 sibling 布局取
   `../sci/src/plugin_bridge.zig`，且需 `-Dsa-std-dir` 指
   `sci/artifacts/sa_std`）、树内 `zig build` 产出 `libsla.so` 后，
   cwd 位于该区内（区根 / 树根 / workspace 根三点实测）的冷构建全部
   通过。正式验收即在此区内的 workspace 副本
   （`/content/slaengine-rig/ws`，整包 sha256 `96fadce8…` 与本地
   `088d1fd` 归档逐片双确认）上执行。
2. **sax3d 测试脚本的 zig 路径**：crate 内 `tests/*.sh` 的 zig 默认
   值是源作者本机路径（`$HOME/workspace/local-sa/zig17/zig`），脚本
   本身支持 `ZIG` 环境变量覆盖；验收以
   `ZIG=/content/tools/zig-x86_64-linux-0.17.0/zig` 覆盖后全绿。未改
   crate 导入文件（保字节保真）；建议源仓后续把默认值改中性。

注：盒上验收的 workspace 树 = 本地提交 `088d1fd`；其后本地仅增注释
（`src/slaengine.sla` 头注复刻原则一行 + 本报告），不影响构建面。

## 6. 错峰与窗口

本线为支线（用户 11:03 定）：盒上工作全程探占用、等空窗、与主线错
峰。一盒（25023）在本线工作期间有主线 bench 在跑，未使用；二盒
（25024）为本线验收盒：首轮验收与冷验收重跑均在二盒无主线重活的窗
口内执行（以进程探针确认 `run_benches/wrk/redis-benchmark/zig build`
等主线特征进程不在场后才启动）；其间 slanginx proxy 修复线在二盒起
过一轮 zig 构建，本线插件构建即让窗等其退出后才启动，未与主线同盒
同窗跑重活。远端状态核实（§1）为一盒上的一次只读 `ls-remote`，不占
构建资源。

## 7. 待决项

1. **推送**：本地主本已成仓（提交见 git log），推送由主会话复核后守卫
   执行（守卫值：远端仍为空仓/零 ref）。
2. **license**：`[workspace.package]` 的 `MIT OR Apache-2.0` 是 Bevy 双
   许可默认值的镜像，待仓主确认。
3. **slasl 复核调和（已收口）**：独立复核已完工（主体属实），其抓到
   的 DEF-1 已修复并随基点 `125208f` 落入本 crate（§3/§5）；复核余
   项 DEF-2/3/4 是 slasl 自身登记在案的缺陷（复合条件解析 / `#` 行
   诊断 / 大 @global --check PANIC），属 SLASL 线辖区、不阻塞地基落
   地，待其修复后 crate 基点再对齐。本线只确认结构落位与黄金可生成
   性，**不宣称 slasl 已验收**（其二期自身缺口登记在案：SPIR-V 按
   DESIGN 分期 P4 未产出；Shadertoy importer 子集与 Unity 变体数审计
   旁注经复核补登记为缺口 #6/#7）。
4. **预留 crate 填充**：sla_ecs embed 与 sla_3d 移植按普查线 PLAN 另行
   立项；sla_asset 按 Jev F5 + 普查打通清单另行立项；sla_webgl（第
   一）/ sla_gpu（第二）渲染后端按用户定序另行立项。
5. **slasl lib/bin 拆分**：伞层 API 级再导出的前置重构（slasl.sla 现为
   单文件带 main 的工具形态），待 App 层增厚时立项。
6. **sax3d 的 SLA 消费面**：sax3d 现无 C ABI 导出（lib.zig 无 export
   fn），SLA 侧经 .sai 绑定消费 sax3d 是后续工作，本期公开面为工具链
   与格式本身。
7. **rig 陈旧检出**：盒上 `/content/sa_all` 的 sla 检出停在
   `264211e9`（§5 事实 1），建议 install.sh/恢复流程把 sla 检出对齐
   钉死口径并保证 rig 区内插件已构建，否则各线的冷构建会在导入展开
   处假失败。本线自建的 `/content/slaengine-rig/` 仅为本线验收用，
   不代全盒 rig。
8. **TODO.md 状态**：参考普查线（五参照仓 three.js/bevy/gpu-curtains/
   playcanvas/babylon.js + Blender/Eevee 节）将以**未提交文件**形式把
   `TODO.md` 写入本仓根；本线收尾时该文件尚未落盘，未纳入本线提交、
   不删不改，落盘后按其自身状态留置（主会话处置）。

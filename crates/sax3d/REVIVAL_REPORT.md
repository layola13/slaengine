# SAX3D 复活线终报（2026-11-01）

一句话结论：**原验收口径在现行工具链上逐项复现，零出入、零缺陷**——
62/62、24/24、Fox 往返 21/21、合并形 2303 B 对 GLB 2584 B 全部与原报
数字逐字一致；SPEC 五处关键条款抽验全过；staging 已整理为可独立成仓
的本地主本（git `main` @ `e3ebe0f`）。GitHub 上无 SAX3D 目标仓，建仓
待用户/令牌条件，本线未推送、未建仓。

## 1. 复验环境与口径

- 执行面：二盒（`5586cbdbf3e3`，25024），install.sh 工具链
  （zig `/usr/local/bin/zig` = **0.17.0**）。一盒当时有 slaredis 步④
  bench 在跑，故选二盒；本线全程为正确性验收（无性能数），与二盒上
  slanginx proxy 实验线错峰、无同窗 bench 干扰项。
- 源码投递：本机 staging 打 tar.gz（排除 `work/`、`.zig-cache/`，
  64 文件），sha256 `734674241b121674595897678c71334765319e653430d433e3fbeec18a5913d7`
  双侧一致后在盒上解到全新目录 `/content/sax3d-revival/src`，
  删除残留 `.zig-cache` 后从干净树跑（两验收脚本自身亦各自
  `rm -rf` 其 work 子目录）。运行脚本 sha256
  `b6ea56b206f6fa635aee3d86303b07e489e00958e9f9a4fee6ed101986976eac`
  双侧一致，detached 启动，盒上日志 `/content/sax3d-revival/run.log`。
- rig 适用性说明（如实登记）：SAX3D 工具链是**纯 Zig 实现**
  （`build.zig` 仅依赖 std，无 sci/sla 链接面），验收结果只受
  zig 0.17.0 决定；任务书的 sci `83c61d43` / sla `e3d2023` rig 头
  对本实现无作用面。SLA 插件重装双确认、清 `.sla-cache` 两项系
  SLA 编译面纪律，本线不涉及（无 SLA 编译发生），未做、亦不冒充做过。

## 2. 复验逐项数（原口径 → 实测）

| 项 | 原口径 | 实测 | 判读 |
|---|---|---|---|
| `tests/run_tests.sh` | 62/62、失败集空 | rc=0，PASS 行 62，FAIL 行 0，`RESULT: 62 passed; FAILED SET: (empty)` | 逐字复现 |
| `tests/run_convert.sh` | 24/24、失败集空 | rc=0，PASS 行 24，FAIL 行 0，`RESULT: 24 passed; FAILED SET: (empty)` | 逐字复现 |
| Fox.glb 往返等价（`fox_equiv.py`） | 21/21 | PASS 行 21，FAIL 行 0，`FOX-EQUIV: ALL PASS` | 逐字复现 |
| cube 合并形体积 | 2303 B | `packed_total=2303` | 一致 |
| cube GLB 参照体积 | 2584 B | `ref_glb_total=2584` | 一致（交付形对交付形 −10.9%） |
| 附带尺寸项 | — | split_bin=1211、assembly 973、名表 146、gltf+json 总 2554 | 与原 REPORT §体积表同 |

无任何失败项，故无失败名字集可给；与原口径**零出入**，不存在
「实现回归 vs 基线变化」的归因问题——工具链自原验收（同为 zig
0.17.0）以来未对本实现产生可观测影响。

## 3. SPEC 一致性抽验（5 处，实测对照冻结文本）

| # | 条款 | 抽验方法 | 结果 |
|---|---|---|---|
| 1 | §4.1 头布局：魔数、版本门 1.0、flags 非零拒绝、头 32B | 解析实测 `cube.sax3dp` 头：`SAX3DPAK`、version 1.0、flags 0、段数 8；版本/flags 拒绝由 62 项内 corrupt-version/corrupt-flags 两件以具名诊断实证 | ✔ |
| 2 | §4.2/§4.6 紧密律与段序：载荷自 `32+32×段数` 起紧密累计零填充、合并形组装段居尾、名表殿后 | 同文件逐段解析：首段 off=288=32+32×8；8 段首尾相接（288→…→2157）；末段 kind=8（assembly）；载荷终点 2157 == nametab_off；总长 2303 == nametab_off+nametab_len。拆分形偏移（§8 算例 positions 256…终点 1152）由 run_tests 的 15 项 offset 断言同轮实证 | ✔ |
| 3 | §7 裁判响亮性：负例必具名诊断、无 panic、无静默回退 | 62 项内含：22 件负例语料逐件命中期望诊断码（`Sax3d*`）、5 件二进制损坏件（BadMagic/UnsupportedVersion/BadFlags/NameTableMismatch/TruncatedFile）、垃圾/空输入健壮性 2 件、载荷长度不符 1 件——全部 rc≠0 + 含码 + 无 panic | ✔ |
| 4 | §4.5/§10 打包确定性：同输入两跑逐字节一致 | cube：套内 pack 两跑 cmp 一致 + 本线独立第三跑 cmp 一致（sha256 `1fe30214a5600424a8b31f3e94706c6be53a173ed0cbdf838c70c85cb92a9122`）；hero：本线另行 pack 两跑 cmp 一致（sha256 `88bcda2f8d8b150a7c7581d35632c83c02198a1cd1d9cf2ef78d45002f403cae`） | ✔ |
| 5 | §6.4 shader keep_name_only 定版：合并形只按名入册、不内嵌 `.slasl` 源/路径 | 字节级检查 `cube.sax3dp`：名表含 shader 名 `PbrStd`（在册），全文**不含** `.slasl` 路径串（源路径未入合并形） | ✔ 按定版执行，未另改 |

## 4. 落地准备（本地主本形态）

staging 原本不是 git 仓；本线已整理为可独立成仓的本地主本：

- 位置不变：`~/workspace/sax3d-impl-local/`，`git init -b main`，
  首提交 **`e3ebe0f`**，66 文件入库、工作树干净。
- 补齐项：`README.md`（格式定位、工具链命令表、构建/验收入口、
  目录表）；`.gitignore`（`work/`、`.zig-cache/`——构建产物只留盘不入库）。
- 构建入口原已完备：`build.zig`（zig 0.17.0 一条命令产
  sax3dc/readback/genpayload/convert/genref 五件工具），未改。
- 入库构成：`SPEC.md`（冻结）、`sax3d.sai`（schema 真理源）、
  `src/`（10 个 .zig）、`tools/`（5 个 .zig）、`examples/`、
  `tests/`（含 22 负例与 Fox 对拍脚本）、`converter/`（夹具 +
  Fox.glb 样本 162,852 B）、`REPORT.md`、`CONVERTER_REPORT.md`、
  `CONVERTER_MAP.md`、本终报。
- 盒上复验副本留置 `/content/sax3d-revival/`（src.tar.gz、run.log、
  两份 .out、脚本），可作复核凭据。

## 5. GitHub 目标仓核查

本机 HTTPS 无凭据（ls-remote 只得到认证拦截，不能区分不存在/私有）；
改在二盒内以 GIT_TOKEN（仅盒内 shell 抽取、未打印）对五个候选名
逐个 `git ls-remote` 只读核查，结果**全 ABSENT**：

`sax3d`、`sa-sax3d`、`sax3d-tools`、`sa_plugin_sax3d`、`sax3d-impl`

结论：layola13 名下现无 SAX3D 目标仓（以认证态 ls-remote 为准）。
**待决：建仓需 repo 级令牌条件（细粒度 PAT 建不了仓），候用户处置；
建仓后本主本可直接首推 `main`。**

## 6. 待决项登记

1. **建仓**（§5）：仓名与建仓令牌待用户；本线不建仓、不推送（已守）。
2. **§6.4 口径复议**：现行 keep_name_only 为 Jev 0.48 / 置信 0.22 的
   默认采纳，用户可推翻。本线复验确认实现与定版一致（§3 抽验 5），
   未另改；若复议改为可选内嵌 shader 源段，按 SPEC §6.4 所记路径
   另起小批（新段种类 + 版本门），不在本线范围。
3. 缺陷登记：**无**。本轮复验未发现任何实现缺陷，无最小复现待立项。

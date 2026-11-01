# SAX3D 工具链 — SLA 实现（移植自 Zig 实现，逐字节差分验收）

用户总则（2026-11-01 11:42）：**slaengine 以 SLA 为主，Zig/C/Python 为辅助**。
本子树即该总则在 sax3d 工具链上的落实：工具链本体改由 SLA 实现，
原 Zig 实现（`../src`、`../tools`，一字不动）退到**差分裁判**的辅助位——
验收时以 Zig 二进制为裁判，SLA 产物与之逐字节对拍。

## 子树布局

- `src/` — SLA 模块（与 Zig 模块一一对应）+ 入口 `sax3dc.sla`
  - `core.sla` 字节缓冲/跨度/文件 IO/参数解析等工具层（沿 slasl 先例的
    数据纪律：数据通路无 String 值、无 format()，一切文本为字节缓冲中的
    (off,len) 跨度，一切集合为扁平 arena）
  - `numfmt.sla` f64 最短往返十进制格式化（精确大整数算法，自带实现；
    std 的 `sa_fmt_f64` 是定点精度格式，与 Zig `{d}` 的最短往返语义不同，
    不可用）+ f64/f32 位级互转
  - `schema_gen.sla` **生成文件**：由 `tools/gen_schema_sla.sla` 自
    `../../sax3d.sai` 派生（schema 纪律：.sai 仍是唯一真理源，禁止手抄
    第二份布局表；派生方式与 Zig 侧 `tools/gen_schema.zig` 同构）
  - `lexer.sla` / `model.sla` / `parse.sla` / `iface.sla` / `check.sla` /
    `layout.sla` / `binio.sla` / `packform.sla` / `json.sla`（转换器用）
- `tools/` — 其余入口：`readback.sla`（回读验收等价物）、`convert.sla`
  （glTF/GLB 双向转换器）、`genpayload.sla` / `genref.sla`（验收生成件）、
  `gen_schema_sla.sla`（schema 派生器）
- `build.sh` — 在 rig 环境下把全部入口编为 `work/bin/` 下与 Zig 同名的
  二进制（sax3dc / readback / convert / genpayload / genref）
- `run_diff.sh` — 差分验收：同一语料分别以 Zig 裁判与 SLA 工具全量跑
  `tests/run_tests.sh` + `tests/run_convert.sh` 的等价流程，逐项比对
  退出码/stdout/stderr/全部产物文件字节

## 构建口径（rig）

二盒 `/content/slaengine-rig/`（sci 83c61d43 + sla e3d2023a）：
`source /content/tools/env.sh` 后还须显式导出
`SA_STD_DIR=/content/slaengine-rig/sci/sa_std` 与
`SLA_STD_DIR=/content/slaengine-rig/sla/sla_std`（独立树下仅 env.sh 不足，
@import 展开报 FileNotFound——实证），清 `.sla-cache` 后构建。

工具链使用规则（rig 头上实证，详见 GAPS_LEDGER.md 的 R-1…R-6）：
extern "C" 声明只放入口文件；宏调用结果不得就地 `as` 转换；
解引用存储经辅助函数或 `.add()` 链；整数字面量上限 i64::MAX。

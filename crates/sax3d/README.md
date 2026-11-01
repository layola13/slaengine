# SAX3D

SA 原生 3D 资产格式（v1，规格已冻结，见 `SPEC.md`）及其工具链。

- **拆分形（创作形）**：组装文本 `.sax3d` + 二进制伴随文件 `.saxb3d`
- **合并形（交付形）**：单文件 `.sax3dp`（类比 GLB）
- 两形一等：同一解析器双模 + 同一校验器裁判，结论一致。
- 几何真理由 SA 类型描述、二进制段为其内存映像；布局唯一真理源是
  `sax3d.sai`（`tools/gen_schema.zig` 生成 `src/schema_gen.zig`，禁止手抄第二份布局表）。
- 引用按名为主键；通道恒独立紧密打包；shader 只按名引用 SLASL 产物，
  合并形不内嵌 shader 源（SPEC §6.4 定版）。
- 加载器不在本仓交付：格式义务止于「名→布局解析产物」契约（SPEC §4.5），
  加载实现属上层。

## 工具链

`sax3dc`（Zig 实现，核心库 `src/lib.zig`）：

| 命令 | 作用 |
|---|---|
| `sax3dc check <asset.sax3d> --iface <Name>=<iface.txt>` | 解析 + 全量裁判校验（诊断码响亮、无静默回退） |
| `sax3dc build <asset.sax3d> --payload-dir <dir> --out <file.saxb3d>` | 按段载荷文件写出拆分形二进制 |
| `sax3dc pack <asset.sax3d> --bin <file.saxb3d> --out <file.sax3dp>` | 打包为合并形（确定性：同输入逐字节同输出） |

辅助工具（`tools/`）：`readback`（回读验收，非加载器）、`convert`
（SAX3D ↔ glTF/GLB 双向转换，映射与台账见 `CONVERTER_MAP.md`）、
`gen_schema`、`genpayload`、`genref`（验收专用）。

## 构建与验收

需要 Zig 0.17.0。

```sh
zig build --prefix work/build-out
bash tests/run_tests.sh    # v1 全量验收（62 项）
bash tests/run_convert.sh  # 转换器验收（24 项，依赖 run_tests.sh 先行产物）
```

## 目录

| 路径 | 内容 |
|---|---|
| `SPEC.md` | 冻结规格 v1（与设计差异逐项登记于 §11） |
| `sax3d.sai` | schema 单一真理源 |
| `src/` | 解析器、校验器、布局/名表、二进制 IO、编译形发射器、CLI |
| `tools/` | 回读、转换、生成类工具 |
| `examples/` | 工作例 cube / hero + shader 接口夹具 |
| `tests/` | 验收脚本、负例语料（22 件）、Fox 往返对拍 |
| `converter/` | 转换器夹具与真实样本（Fox.glb） |
| `REPORT.md` / `CONVERTER_REPORT.md` | 实施终报 / 转换器终报 |

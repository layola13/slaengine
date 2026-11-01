# SAX3D SPEC.md 截断修复批 · 终报（SPECFIX_REPORT）

日期：2026-11-01。工地：`~/workspace/slaengine-specfix-local/`
（自 slaengine-local 克隆，头 c6d3ec2）。支线·文档完整性批。

## 1. 结论

`crates/sax3d/SPEC.md` 已修复：13254 字节截断版 → **24577 字节**
完整版。结构恢复齐全：§7 裁判规则补全至 15 条（规则 3 后半 +
规则 4–15）、§8 算例、§9 接口表、§10 工具链义务（10.1 打包 /
10.2 构建）、§11 偏差日志 D-1…D-8、文末「恢复说明」节。
**格式实质零改动**：只动 SPEC.md 一个文件 + 新增恢复说明文件
`crates/sax3d/RECOVERY.md`；Zig 实现、.sai schema、测试语料
一字未动。

## 2. 丢失清单（摘要，全文见 RECOVERY.md §1）

§7 规则 3 中途断句（"…inv"）+ 文件尾字面截断标记；丢失 =
规则 3 后半起 §7 余下全部、§§8–11 全节。本机五副本 + 源工地
git 两提交皆同为截断版、无完好副本（主会话已核实）。

## 3. 恢复方法与证据（全文见 RECOVERY.md §2–§3）

三源互证：① 实现代码 = 规则执行体（check.zig / parse.zig /
binio.zig / main.zig / iface.zig / model.zig 逐点对位）；
② sax3d-impl-local/REPORT.md（§2.2 算例表、§5 D-1…D-8 逐条、
§2.7 D-6 出处）；③ 存续正文交叉引用（§9 接口表三处、§10
打包、§10.2 载荷复核两处）+ 研究稿 DESIGN.md（§4/§6.3/§8）。

诊断清点（全仓字符串实测）：`Sax3d*` 诊断码 **44 个**，
全数映射入 §7 规则 / §10（映射表 RECOVERY.md §3，逐码带
发射处）；转换器面 `Cvt*` 10 码单列（归 CONVERTER_MAP 口径）。
注：派单口径作「53 个 Sax3d* 诊断名」——实测为 44 个诊断码
（另 Sax3dBinHeader/Sax3dSectionRec 两 schema 类型名非诊断）；
映射表以实测为准、全覆盖无遗漏。

## 4. 双向差异（全文见 RECOVERY.md §4，择要）

- **D-文码-1（重要，候主会话裁）**：存续 §5.2 文法 topology
  值集含 `triangle-fan`，校验器闭集不含之（声明即
  Sax3dInvalidValue），而转换器双向产/收 triangle-fan。
  文/码必有一误；本批只登记 + §7 规则 4 加注，**不自裁**。
- D-文码-4：§5.4「五字段必填」与 wrap_w「出现时验值集」细差，
  恢复规则 9 按代码实情写明，不改 §5.4。
- D-文码-5：check.zig 注释引「SPEC §6.1」实为 §5.2（代码注释
  陈旧，只登记不动代码）。
- Sax3dIoError 为工具面诊断、非格式规则（映射表登记）。

## 5. 存疑清单（全文见 RECOVERY.md §5，择要）

Q-1 §7 规则 4 起原编号/分组不可考（恢复按执行体新编）；
Q-2 §8 是否含 hero 第二例无证据（数值仅登记于 RECOVERY，
不入正文）；Q-3 §§9–11 原标题为拟名（主题由交叉引用钉死）；
Q-4 §10 子节次序为推定（10.2 存在性为高置信）；Q-6 §11
条文字句为恢复文本（条目集合与实质高置信）。

## 6. 验收（二盒 rig 口径复跑，文档修复后）

工件经 tar 管道传二盒（sha256 `2d31b11b…` 双侧一致），
解于 /content/specfix-rig/sax3d，zig 0.17.0
（ZIG=/usr/local/bin/zig 覆盖脚本的原作者本机默认路径）：

- `tests/run_tests.sh`：**RESULT: 62 passed; FAILED SET: (empty)**，rc=0；
- `tests/run_convert.sh`：**RESULT: 32 passed; FAILED SET: (empty)**，rc=0；
- §8 数值实跑复核：cube-check 清单逐字同恢复表——offsets
  256/544/832/1024/1096/1112/1120、payload end 1152、名表
  59B、文件 1211B（run_tests 内 15 项 offset 断言同轮通过；
  hero offsets/payload end 868 断言亦通过）。

文档修复未触任何行为（本批对代码零改动，上数与既有口径一致）。

## 7. 与源工地的关系（候主会话定）

本批只修 slaengine 仓内副本（crates/sax3d/SPEC.md）。
**sax3d-impl-local 源工地的 SPEC.md 仍为截断版，本批未动**；
是否同步修复由主会话决定（建议：以本批恢复版为准同步，
因源工地为冻结存档、其 git 历史两提交皆截断版，无可覆盖
的完好原文风险）。

## 8. 交付物

- staging 提交（本工地，未推送）：SPEC.md 修复 + RECOVERY.md
  新增（+ 本报告 SPECFIX_REPORT.md）。
- 遗留候裁：D-文码-1（triangle-fan 文/码出入）交主会话。

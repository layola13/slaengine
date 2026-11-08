# slaengine 架构设计集（架构期，2026-11-08）

本集为 slaengine **架构期**产出：用户 2026-11-08 16:08 令——不等 SLA
编译器修复、与修复战役并行，先做 slaengine 架构。本集**只定架构，
不含实现**；实现主体候编译器战役收口后按主会话排期投入。

## 与既有定版的关系（先读此条）

slaengine 不是空地：2026-11-01 已有三批定版在先，本集是**增补与收束**，
不推翻、不重写：

| 既有定版 | 位置 | 本集态度 |
|---|---|---|
| 普查总案 PLAN（crate 总图、sla_ecs 嵌入方案、App/System 映射专节、3dengines 逐模块裁定、分期 P0–P3、分叉 F1–F6） | `~/workspace/slaengine-survey/PLAN.md` | 全盘继承；本集只补其未覆盖面 |
| 参考普查吸收点 TODO（八仓研读吸收清单与归期） | 仓内 `TODO.md` | 继承；本集的参考映射与其同法 |
| 伞 README 的 Bevy 组织对应表 | 仓内 `README.md` | 继承 |
| 各 crate README / REPORT 群 | `crates/*/` | 继承，各 crate 细节以其为准 |

本集新增的面（PLAN 未覆盖）：宏顶替总表（03）、OpenRealm 参考映射
（04，用户 2026-11-08 定为正式参考对象）、Warcraft 阶段二逆向接口
预留（05）、Blender 迭代环薄层收束（06）、含 Warcraft 格式族的数据
格式层（07）、渲染面与 three.js 对照的边界划定（08）。

## 本集目录

| 文件 | 内容 |
|---|---|
| `01-overview-layering.md` | 总览与分层、依赖方向总则、横切面（调度/描述符/SAB 联邦相容/@gpu 依赖登记） |
| `02-crates-dependencies.md` | crate 切分与依赖方向（含 2026-11-08 实测现状） |
| `03-bevy-correspondence-macros.md` | 与 Bevy 的对应总表 + **宏顶替逐项表** |
| `04-openrealm-reference-map.md` | OpenRealm 参考映射表（组织吸收/行为对照/不取，三分法） |
| `05-phase2-re-interfaces.md` | Warcraft 阶段二（原版 DLL 逆向）成果接入面预留 |
| `06-blender-editor-loop.md` | 编辑器（Blender）迭代环薄层设计 |
| `07-data-format-layer.md` | 数据格式层设计（原生 SAX3D + 导入族，含 Warcraft 格式族） |
| `08-rendering-surface.md` | 渲染面：引擎自研后端与 three.js d.ts2sai 呈现路线的边界 |

## 口径

- 定案冲突时，用户定案 > PLAN 已定版 > 本集新增。本集与定案冲突处
  以定案为准，并应在评审时指出。
- 本集所有「现状」数字为 2026-11-08 本机实测（见架构线 RESULT.md）。
- 每个文件 ≤700 行（用户硬规矩），本集各文件均远低于此限。

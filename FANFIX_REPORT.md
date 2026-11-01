# FANFIX_REPORT — SAX3D triangle-fan 文码矛盾订正批终报

一句话结论：**D-文码-1 已按 Jev 裁决 text_follows_code（0.99，置信
0.98，2026-11-01）订正闭合**——SPEC §5.2 删 triangle-fan（补记入
§11 D-9），转换器入向展开 fan 为三角形列表、出向永不产 fan；
二盒验收 run_tests 62/62、run_convert 43/43（原 32 + 新增 11），
失败名集为空。顺修 D-文码-4（§5.4 wrap_w，文从码澄清）与
D-文码-5（check.zig 注释节号）两笔小账。

工地：`~/workspace/slaengine-fanfix-local/`（自 slaengine-local
克隆，基点头 `d70184d`；只动 `crates/sax3d`，staging 提交、不推送）。
验收盒：二盒（25024，hostname `5586cbdbf3e3`，zig 0.17.0），
盒上目录 `/content/sax3d-fanfix/sax3d`，日志
`/content/sax3d-fanfix-run3.log`。传输 sha256 双确认
（整包 `f7386b55…`；convert.zig 单文件 `efbd6d4e…`——其间一轮
因远端命令 `&` 绑定整链致 base64 落 0 字节，被 sha 对账当场
拦下、重传后双侧一致才开跑，见 §5）。

## 1. 矛盾与裁决

- 存续矛盾（SPEC 修复批登记 D-文码-1）：SPEC §5.2 文法 topology
  值集含 `triangle-fan`，校验器闭集 {triangles, triangle-strip,
  lines, line-strip, points} 不含之（声明即 `Sax3dInvalidValue`），
  而双向转换器产/收 triangle-fan（convert.zig mode 6 双向映射）——
  转换产物过不了自家校验器。
- 裁决：`~/workspace/jev-designs/sax3d_fan_ruling.json`，
  choice = text_follows_code，概率 0.99，置信 0.98。
  即格式值集以校验器闭集为准，**改文、改转换器行为，校验器不动**。

## 2. 施工明细

### 2.1 SPEC.md（订正以补记形态入文，不静默改字）
- §5.2：topology 文法删 `triangle-fan`，行尾注记「无
  triangle-fan（D-9 订正，文从码）」。
- §7 规则 4：原「与 §5.2 文法有一处出入……本批不裁」注记收口为
  「闭集与 §5.2 文法一致；triangle-fan 不在集内，原 §5.2 文法
  误列已按 D-9 订正删除——文从码」。
- §11 偏差日志续编 **D-9**：载明矛盾形态、Jev 裁决与日期、文从码
  处置（删 §5.2 + 转换器改行为）、「订正非扩展：格式接纳面不变
  （fan 从未合法过）」，并同记 §5.4 wrap_w 顺修。
- RECOVERY.md 差异表：D-文码-1 标注「已订正（2026-11-01 订正批）」
  并引裁决与本报告；D-文码-4 补收口标注；D-文码-5 标注已订正。

### 2.2 转换器（tools/convert.zig，Zig 本体）
- 新增双向共用展开原语（CONVERTER_MAP §1 注 1 为规范表述）：
  `expandFanIndices`（扇序 [i0,…,i_{n−1}] → (i0,i1,i2),
  (i0,i2,i3), …, (i0,i_{n−2},i_{n−1})，输出 3(n−2)，元素宽保持）
  与 `expandFanSequential`（非索引扇先合成恒等索引序再展开，
  宽按顶点数选 u16/u32：≤65536 顶点为 u16）。
- 入向（to-sax3d / convMeshes）：mode 6 的 topo 映射改
  「triangles」并在 mode 判定后、法线派生与 indices 发射之前
  执行展开——法线派生自此只见三角形索引（旧行为对 fan 索引
  按三角形列表误读派生法线的隐患一并消除）。
  - 索引扇：就地改写 idx_bytes/idx_count；展开后字节已非源
    accessor 数据，indices 发射点改判 `idx_expanded` 强制
    `addSection`，禁止 `accSection` 按 accessor 去重复用
    （同一 accessor 另被非 fan 图元引用时字节不同）。
  - 非索引扇：合成索引缓冲后展开，mesh 由无 indices 变为
    带 indices 的 triangles（唯一保持几何的表达）。
  - 逐 mesh 进台账（APPROX 行注明 lossless 与展开后计数）。
  - n < 3：扇展开为空集——以 `CvtUnsupportedTopology` 响亮
    拒绝并注明「expands to zero triangles; refusing (loud, not
    a silent empty mesh)」，不静默产空网格。
- 出向（to-gltf）：删除 `"triangle-fan" → 6` 映射臂——mode 6
  在代码上已无产出路径。扇形输入兜底：mesh 处理处先判
  `is_fan`，按同一展开改写索引 accessor（缓存键加 `#fanexp`
  后缀防与原段 accessor 撞键）、mode 落 TRIANGLES(4)，逐 mesh
  响亮进台账（注明闭集外、无损、索引前后计数、fan never
  emitted）；非索引扇同样合成后展开。须说明的现状层次：
  to-gltf 入口先过裁判，声明 fan 的文本在转换开始前即以
  `Sax3dInvalidValue` 被拒（见 §4 用例 fan-export-refused），
  故该兜底分支在当前管线下不可达——它的作用是把「永不产
  fan」从管线巧合升为转换器自身的结构保证。
- CONVERTER_MAP.md：拓扑行改写（入向 mode 6 → 展开、出向
  永不产 6），§1 表后新增**注 1** 记明展开规则与索引增长
  口径（n → 3(n−2)、元素宽保持、顶点零改动、n<3 响亮拒绝、
  逐 mesh 台账可对账）。

### 2.3 顺修小账一：§5.4 五字段 / wrap_w（D-文码-4）——判**文从码**
逐项判读：
- 「五字段必填」项：SPEC §5.4 正文与 §11 D-4 的必填集 =
  {mag, min, mipmap, wrap_u, wrap_v}；check.zig
  （checkTextures）必填集与之逐一相同，缺一即
  `Sax3dMissingSamplerState`。文码一致，无动作。
- 「wrap_w 验值」项：§5.4 文法行列有 wrap_w，正文未标其
  可选性，易被误读为第六必填；代码仅在 wrap_w 出现时验
  环绕值集（checkEnum 对空值直接通过），§7 规则 9 恢复文本
  亦按此写。判文从码的依据：① D-4 是刻意的必填收严决策，
  其五字段清单未含 wrap_w；② 2D 纹理无 W 轴，强制必填
  无语义收益；③ 全部存量合法资产（examples/ 与
  tests/valid_control.sax3d）均未声明 wrap_w——若改码
  从文（必填化）将使存量合法资产一夜非法，属格式收紧而
  非订正。处置：§5.4 补一句澄清「wrap_w 为可选字段（不在
  五字段必填内——2D 纹理无 W 轴），出现时同样验环绕值集
  （规则 9）」；**义务不变、代码不改**。RECOVERY D-文码-4
  已补收口标注。

### 2.4 顺修小账二：check.zig 注释节号（D-文码-5）
`src/check.zig` 通道白名单注释「SPEC §6.1 定形」→「SPEC
§5.2 定形」（§6.1 实为编译形组装；钉死表在 §5.2）。仅注释。

## 3. 新增回归语料（tests/run_convert.sh 新增 §E 段，11 例）

生成器 `tests/gen_fan.py`（仿 gen_same_name.py 先例）产两件
mode 6 样本；核查脚本 `tests/fan_equiv.py` 逐项对账（非抽样）。

| 用例 | 内容 |
|---|---|
| fanquad-import | 索引扇 FanQuad（扇索引 [0,1,2,3,4]、5 顶点）入向 rc=0 |
| fanquad-ledger-expand | 台账含展开行（APPROX，lossless，SPEC D-9） |
| fanquad-topology | 产物 topology: triangles 且全文无 triangle-fan |
| fanquad-referee-build | 产物过 sax3dc build（裁判）rc=0 |
| fanquad-export | 产物再出向 rc=0 |
| fanquad-equiv | 顶点字节逐字节同源 + 展开索引逐项核 + 出向 mode=4 且索引与展开期望逐项一致 |
| fanfree-import | 非索引扇 FanFree 入向 rc=0 |
| fanfree-equiv | 合成索引展开逐项核（[0,1,2, 0,2,3, 0,3,4]，count 9） |
| fanfree-referee-build | FanFree 产物过裁判 rc=0 |
| fan-export-refused | valid_control 插入 `topology: triangle-fan;` 后 to-gltf 被拒，诊断含 `Sax3dInvalidValue` 与 "topology 'triangle-fan' not in closed set" |
| nofan-scan | 全部出口产物（Fox.glb / cube / hero / fanquad-back）primitive mode 值集扫描，无 6 |

## 4. 验收证据（二盒口径，run3 日志）

- `run_tests.sh`：**RESULT: 62 passed; FAILED SET: (empty)**，
  TESTS_RC=0（校验器与格式面零回归）。
- `run_convert.sh`：**RESULT: 43 passed; FAILED SET: (empty)**，
  CONVERT_RC=0（原 32 例全过 + 新增 11 例全过）。
- fan 端到端链（转入 → check VALID → 转出 → 无 fan）实证：
  - 入向台账：`LEDGER APPROX mesh 'FanMesh': TRIANGLE_FAN
    expanded to triangle list (lossless, SPEC D-9): fan
    indices -> 9 triangle indices`；非索引扇：`index buffer
    synthesized, 5 vertices -> 9 triangle indices`。
  - 等价核查：`fan equiv ok (indexed): 5 verts
    byte-identical; fan [0, 1, 2, 3, 4] -> triangles
    [0, 1, 2, 0, 2, 3, 0, 3, 4] item-identical`；
    `(free)` 同结论。
  - 产物文本：`topology: triangles;`、`indices u16 @
    FanMesh_idx count 9;`（5 扇索引 → 9 三角形索引，
    3(n−2) 口径吻合）。
  - 出向守门：`SAX3D-E Sax3dInvalidValue: mesh 'M':
    topology 'triangle-fan' not in closed set`（to-gltf 拒绝
    交付）。
  - 值集扫描：`export modes seen: [4]`（全部出口产物只有
    TRIANGLES；含 fan 往返产物 FanQuad.gltf）。
- 过程插曲如实登记：首轮盒上构建因新辅助函数局部名 `i0`
  与 Zig 原语类型同名编译失败（run_tests 61/62、唯 build
  红），改名 `first` 后复跑全绿——属本批新代码笔误，非存量
  回归，失败名集已对清。

## 5. 纪律执行

- 本机主本先行：全部改动先落本机工地，再整包传盒
  （base64-stdin 管道 + sha256 双确认；一轮 0 字节事故被
  对账拦下并已在 §首段登记，复传双侧一致后才开跑）。
- 连盒一律裸 `/usr/bin/ssh`；盒上长任务 setsid nohup
  detached + 读日志，未与在跑他线（ECS 基线分片）争用
  同一工作目录。
- 只动 crates/sax3d；staging 提交、不推送；未触碰
  slaengine-saxport-local 工地（SLA 移植线的 Zig 差分裁判
  基线变化点 = 本批 convert.zig 行为，待主会话通知其对齐：
  其差分语料若含 fan 样本，期望值须按本批展开口径更新）。

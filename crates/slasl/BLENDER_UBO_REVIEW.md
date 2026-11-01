# @global 组与 Blender UBO 约定对齐复核（TODO §8 P1 ①）

复核对象：slasl @global 组 / @param 在 glsl-es300（方言 0）与 blender
（方言 6）两条发射路径的 uniform 块形态，对照 Blender GPU 约定
（GPUShaderCreateInfo 按名声明 uniform_block、Eevee `*_shared` 共享
声明头纪律）。证据为 src/slasl.sla 发射器实读（emit_glsl /
emit_blender）与 DESIGN §7.3/§7.4。

## 事实（发射器实证）

- F1 按名成块：每个 @global 组发一个 `layout(std140) uniform <组名>`
  块；未分组的 @global 单字段在 blender 方言收拢为固定名块 `Globals`，
  在 glsl 方言发为散 uniform；@param 发固定名块 `Params`（两方言同）。
  块上**不带 layout(binding)**——物理绑定由宿主按名落定。
- F2 活字段才进块：块成员 = DCE 后的活字段子集（is_live_key 过滤），
  保持声明序。同组在不同 shader 里可产出**不同成员集**的块。
- F3 glsl-es100（方言 1）无块：组被拍平为散 uniform，组名丢弃，
  字段以裸名出现。
- F4 接口表是真合同：每 shader 的接口表（DESIGN §7.4 逻辑槽）列出
  该 shader 实际存活的字段与逻辑槽位，块内容与接口表恒一致。

## 对齐判定

| 面 | 判定 | 说明 |
|---|---|---|
| 按名绑块（create-info uniform_block 按名） | ✅ 对齐 | F1 与 Blender 按名声明/绑定同构；slasl 的 merged_info.py 即 create-info 等价面 |
| std140 布局 | ✅ 对齐 | 成员声明序 + std140 规则；逻辑槽以 vec4 字为单位（§7.4），宿主可据接口表算偏移 |
| 块成员恒等（Eevee *_shared 全结构共享） | ⚠️ 声明偏差 | F2 与 Eevee「同一共享头、同结构处处一致」相反：slasl 是按 shader 裁剪。偏差是 §7.3 DCE 的既定设计，非缺陷；代价转移给宿主纪律（下） |
| es100 拍平 | ⚠️ 观察项 | F3：跨组同名字段在 es100 输出里会重名（AST 层字段按组作用域、检查器不拦），落到驱动层才报错。登记为候选检查规则（本批不修，见结论） |

## 宿主纪律（复核结论，即日起为约定）

1. **按 shader 建 UBO**：同一 @global 组在不同 shader 的块布局可不同；
   宿主必须按**该 shader 的接口表**（活字段、声明序、std140）填缓冲，
   禁止跨 shader 复用一份组布局缓存。
2. **按名绑定**：块绑定只认块名（组名 / `Params` / `Globals`），
   不认编译产物中的出现顺序；`Params`/`Globals` 的作用域是单个
   GPUShader，同名块在不同 shader 间互不冲突（与 Blender 侧同）。
3. **es100 目标**：@global 以散 uniform 按字段名设值；作者应避免跨组
   同名字段（检查器候选规则落地前靠约定）。

## DESIGN 订正

DESIGN §7.4 已补一段「Blender 对齐复核结论」记录上述纪律 1–2 与
es100 观察项；DESIGN 其余文本与本复核无冲突，不作它改。

## 候选登记（不在本批修）

- 候选 DEF：target=glsl-es100 时跨组 @global 字段重名应由检查器以
  ShaderDuplicateName 响亮拒绝（现靠驱动层报错）。属检查器面、
  DEF-2/3/4 之外的新候选，报主会话登记。

# SLASL P2 implementation plan (working notes)

Scope basis: DESIGN §14 P2 = compiler core in SLA (std body, J-7 std_library_production_baseline)
+ dialects glsl-es300 / glsl-es100 / hlsl-sm5 (P0 set) + webgpu (WGSL + reflection manifest).
Extension in DESIGN P3 order as capacity allows: msl, unity, blender, unreal-global.
SPIR-V = DESIGN P4 (registered, not this pass).

Data model (arena, fat nodes, i32 tags — mirrors proto/src/main.zig exactly):
- Ty codes: 0 float, 1 int, 2 uint, 3 bool, 4 vec2, 5 vec3, 6 vec4, 7 mat3, 8 mat4, 9 sampler2D
- Expr arena Vec<Expr{kind,a,b,op,ty,num:String,name:String,bval,args:Vec<i32>}>
  kinds: 0 num, 1 boolean, 2 ident, 3 field, 4 binop, 5 neg, 6 call, 7 ctor
- Stmt arena Vec<Stmt{kind,target,value,cond,body:Vec<i32>}> kinds: 0 assign, 1 ifs, 2 block
- Field{name,ty}; Group{name,fields}; ConstDecl{name,ty,value}; Shader{...}
- All state in one Ctx struct passed as &Ctx; name maps = linear-scan Vecs (deterministic order).

Pipeline: lex -> parse (per file) -> check (per shader) -> link (priority sort, unify,
const fold, stage contracts, DCE fixpoint, init weaving) -> emit per target + dumps.

Byte-exactness anchors: proto golden 8 files; proto error message texts kept for
parse/check/link errors (stderr), exit 1; usage exit 2.

CLI: slasl <outdir> <files...>  (P0 bundle: 8 files)
     slasl --target <id> <outdir> <files...>  (single target + layout/variants dumps)
Targets: glsl-es300, glsl-es100, hlsl, webgpu, msl, blender, unity, unreal-global.

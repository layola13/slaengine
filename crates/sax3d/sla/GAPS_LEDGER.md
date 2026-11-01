# SAX3D SLA port — running gap/divergence ledger (folds into PORT_REPORT.md)

## GAP-PORT-1 (language expressiveness, lexer): integer literals limited to i64 range

- Minimal repro (3 lines):
  ```sla
  fn main() -> i32 {
      let b: u64 = 9223372036854775808;
      return 0;
  }
  ```
  Result: `Syntax Error: failed to parse v_l.sla:2:37: error.InvalidCharacter`.
  Any integer literal > 9223372036854775807 (i64::MAX) is rejected at lex time,
  even when the target type is u64. Zig/Rust accept the full u64 literal range.
- Impact on this port: the f64 sign-bit constant 2^63 in numfmt/core
  (3 sites) is written as exact arithmetic `9223372036854775807 + 1`
  (helper `sx_two63()` in core.sla). Semantically identical — NOT an
  approximation and NOT a semantic workaround; the missing surface is only
  literal syntax. All other port code is unaffected.
- Improvement proposal (draft, for the Jev language-improvement pipeline):
  the SLA lexer should accept integer literals up to u64::MAX
  (18446744073709551615), typing the literal by context/suffix like Zig/Rust
  (comptime_int semantics), and reject only literals exceeding u64::MAX.
  Alternatively accept a `u64` suffix. Either closes the gap; the first is
  closer to Zig/Rust surface behaviour.
- Status: registered 2026-11-01; port proceeds (exact-arithmetic form),
  the gap itself is NOT fixed by this line (compiler change belongs to the
  SLA compiler line via the pipeline).

## Divergences (Zig panics / undefined edges; port takes the diagnostic path)

- D-1: mesh index type not in the .sai elem table (e.g. "banana"): Zig
  `schema.elemType(ity).?` PANICS; port emits Sax3dInvalidValue and skips the
  section block. Non-corpus input.
- D-2: converter JSON invalid-input diagnostic: message suffix (error name)
  will differ from Zig std.json's. (To confirm when converter is ported.)
- D-3: iface default_scalar "inf"/"nan"/hex-float literals: Zig parseFloat
  accepts; port's pre-validated parser yields null. Non-corpus.
- D-4: packform node indent depth >= 16: Zig fixed 32-byte indent buffer
  panics; port emits unbounded indent. Non-corpus.

## Baseline note

- Work copy branched from slaengine @8bd4a72. slaengine main has since
  advanced (enrichment c6d3ec2: convert 24->32; SPEC restoration d70184d;
  fan correction 7efd415: convert 43 items, converter fan caliber =
  inbound expand to triangle list / outbound never fan). The SLA subtree is
  additive; rebase onto the new base at integration. Converter fan behavior
  targets the POST-correction caliber.

## GAP-PORT-2 (compiler implementation bug): cast applied directly to a macro-call result fails codegen

- Minimal repro:
  ```sla
  @import "sa_std/ptr.sa"
  @import "sa_std/string.sa"
  fn getw(p: ptr, i: u64) -> u64 {
      let w = (PTR_BYTE_AT(p, i) as u64) * 3;
      return w;
  }
  ```
  Result: `Error: failed to generate SA code: error.CodegenError`.
  Binding the macro result to a variable first, then casting the variable,
  compiles and runs correctly (verified both forms side by side).
- Class: pure implementation bug (semantics unambiguous), not an
  expressiveness gap. Port uses the bind-then-cast form (core.sla sx_rd_*),
  semantically identical. Registered for the DEF/compiler queue.

## Toolchain usage rules established empirically on this line (rig e3d2023)

- R-1: integer literals are lexed as i64; > i64::MAX is InvalidCharacter (GAP-PORT-1).
- R-2: `if` statements REQUIRE `;` after the closing brace; `while` statements
  must NOT have one (nested case per AGENTS.md).
- R-3: STR_PTR/STR_LEN are SA macros from `sa_std/string.sa`; the TU must
  import string.sa for them to resolve.
- R-4: `extern "C"` blocks belong in ENTRY files only; in imported modules
  the declared symbols get the module prefix (core__malloc) and fail to link.
- R-5: a deref store `*(local as *T) = v` consumes the pointer register for
  the rest of the function (SA verifier UseAfterMove; CodegenError via the
  import path). Passing the pointer to a helper fn, or storing through an
  `.add()` chain / field base, does not consume it.
- R-6: macro-call results cannot be cast in place (GAP-PORT-2).

## GAP-PORT-3 (compiler semantics defect): f64 negative zero is canonicalized to +0.0

- Minimal repro: write bytes [0,0,0,0,0,0,0,128] to a cell, load as f64,
  store the value back to another cell through a helper, read as u64.
  Result: 0 (expected 0x8000000000000000). The -0.0 bit pattern is lost when
  the value is materialized as an SLA f64 (load into a local / crossing a
  call boundary). Negative nonzero values round-trip bit-exactly
  (-1.5 verified: bits bff8000000000000, formats as "-1.5").
- Impact: Zig `{d}` prints "-0" for negative zero; the port prints "0".
  Any corpus float whose value is exactly -0.0 (source literal "-0"/"-0.0",
  or a computed -0.0) will diverge in formatted output. The full-corpus
  differential will count affected items; all other float formatting is
  proven identical (29/30 fixed patterns + negatives + subnormals + max).
- Class: implementation semantics bug (IEEE 754 sign of zero not preserved),
  not an expressiveness gap. No value-level workaround exists (the sign is
  destroyed before user code can observe the value). Registered for the
  DEF/compiler queue.

## R-7（工具链规则，2026-11-01 探针 v_push.sla 定版）
- 经 `&Vec<T>` **参数**在循环内 push（条件/无条件皆然）→ SA 校验 PhiStateConflict（1015）：借用在循环头两条路径上状态不一致（Active vs Composite）。
- 可过形态：① push 进**结构体字段**（`x.field.push(...)`，含 continue/分支）② 本地 owned Vec 循环内填充后 return、调用方经 `&` 赋进字段（`p.toks = lex_tokenize(...)`）。
- 影响面：本移植全部集合均为 X 结构体字段，天然合 ①；唯一参数式集合是词法器输出，已改返回式。slasl 先例同理（集合全在 Ctx 字段里）从未撞上。
- 定性：校验器借用状态合并的严格性（非表达力缺口）——记为规则，不立缺口单；若主线 DEF 队列有意放宽 &Vec 参数循环 push 的 phi 合并，可引本探针为语料。

## R-8（工具链规则，2026-11-01 探针 v_phi*.sla 定版）
- 同一 if/else 链的兄弟分支以**不同形态结尾**时（一条以函数调用结尾、另一条以 while 语句/存储结尾），借用参数在合流点 PhiStateConflict：调用结尾的分支在分支末释放 `&X` 借用（Uninitialized），while/存储结尾的分支保持 Composite。
- 可过形态：把 while 结尾的分支抽成返回 bool 的辅助函数（false → 调用方 return），使各分支统一为调用结尾；语义不变。本移植已按此式改造 parse.sla 三处（p_parse_skeleton 的 joint 分发 → p_joint_item；p_parse_texture 的 sampler 块 → p_tex_sampler；同型预防）。
- 定性：同 R-7，校验器借用 phi 合并严格性；记规则不立缺口单。

## GAP-PORT-4 (compiler implementation bug): struct records stored via Vec push of a long-lived local are corrupted

- Family of runtime corruptions, one suspected common root in aggregate
  materialisation around loops/calls: a struct value held in a named
  local across a loop (or built up through `&local` helper calls) and
  then stored with `x.vec.push(local)` does NOT reliably land in the Vec
  buffer. Symptoms observed, all on rig e3d2023, all deterministic per
  build shape but shifting with surrounding code:
  - probes v_scn.sla: callee builds SceneD-like record after a loop,
    pushes it; the caller reads back all four fields wrong (rc=15).
    In-callee readback immediately after the push is CORRECT (v_scn4) —
    the stored image degrades afterwards (dead-frame aliasing signature).
  - probes v_jd.sla: JointD-like record mutated via `&jd` helpers in a
    loop, then pushed; caller reads the first four i32 fields wrong,
    later fields right (rc=15). The local's in-fn field values are
    correct (v_jd2 snapshots); a field-by-field copy into a fresh
    literal at the push site does NOT repair it (v_jd3, rc=15).
  - production symptom 1: parse of valid_control stored SceneD with
    n_len=862/r_len=54 (truth 2/1) → check panicked (code 32) walking
    scene roots. Symptom 2: joints[0] name span read back empty after
    parse, and after a later arena append (iface parse) the same slot
    read as 'good_f' — the slot behaves like a shared scratch cell that
    later pushes overwrite (cross-Vec contamination signature).
  - production symptom 3: an Iface record (struct of three Vec headers)
    built in a local across a parse loop and pushed into x.ifaces read
    back with wild Vec headers → segfault on first use.
- Forms PROVEN good by probes (the port now uses these; semantics
  unchanged in all cases — same values, same order, same storage):
  - construct the record as a literal directly in the push call from
    scalar/param values (v_scnw1, rc=0) — used for SceneD.
  - push, then immediately overwrite the slot via index assignment with
    a literal rebuilt from the local's fields
    `x.v[(x.v.len()-1)] = T { f: local.f, ... }` (v_jd4, rc=0) — applied
    at all 13 named-local arena push sites in parse.sla and at the
    iface_parse tail.
  - records pushed as fresh literals (diag_commit, prims, params,
    tbinds, collect_nodes) were never affected.
- Class: pure implementation bug (SA verifier passes; codegen/store
  semantics wrong). Minimal repros: work/probe/v_scn.sla and
  work/probe/v_jd.sla (self-contained, exit code = bitmask of bad
  fields, 15 = broken / 0 = fixed). Registered for the DEF/compiler
  queue. No semantic downgrade in the port: the workaround forms store
  exactly the intended records.

## GAP-PORT-5 (compiler implementation bug): struct passed by value through a helper that pushes it corrupts the target Vec

- Minimal repro family: work/probe/v_map7.sla — caller constructs a
  MapEnt literal and passes it BY VALUE to a helper fn, which pushes it
  into a struct-field Vec (`x.sec_lens.push(e)`). Stored entries read
  back wrong through BOTH the helper accessor and direct indexing
  (v_map9: all six field checks fail, rc=63), while map length stays
  correct. Same program with the pushes inlined into the constructing
  fn (v_map10) or done directly by the caller (v_map8) is fully clean
  (rc=0). Accessor-only variants (v_map2..v_map6) isolate the push hop
  as the toxic step: by-value struct param + push inside the callee.
- Production impact: xmap (sec_lens/res maps) returned garbage entries
  (check produced phantom Sax3dDuplicateName for odd-indexed sections
  and missed lookups for even ones on valid input); iface entry puts
  (ifparam_put/ifent_put) had the same shape.
- Port form (semantics unchanged): storage ops construct the record
  literal inside the fn that performs the push/set — xmap_put inlines
  its push/set; ifparam_put/ifent_put take scalar fields and build the
  literal at the push/set site.
- Class: pure implementation bug, same suspected materialisation family
  as GAP-PORT-4. Registered for the DEF/compiler queue.

## Port-side fixes recorded at checkpoint 3 (not compiler gaps)

- Zig model defaults materialised at parse: mesh topology defaults to
  "triangles" and clip sampler interpolation to "linear" when the item
  is absent (Zig model.zig field defaults). The port interns the
  default text and stores that span, so check/layout/pack observe
  exactly the Zig value (an absent span is NOT silently treated as
  valid at check sites).
- iface.sla: removed a self-move (`let rest = rest0;` then using
  rest0) in iface_parse_entry — plain port bug, type checker rejected
  it once the fn was first compiled (UseAfterMove).
- Step-1 acceptance (2026-11-01, box2 rig): front stack builds clean;
  valid_control with `--iface S=tests/neg.iface.txt` → 0 diagnostics,
  rc 0 (matches Zig neg-control); without the fixture → exactly one
  Sax3dMissingInterfaceFixture (matches Zig neg-nofixture).

## GAP-PORT-6: float literals have no exponent notation (lexer gap, found step 2)

- Probes work/probe/v_e1/v_e2/v_e3: `let f: f64 = 1.0e308;` ->
  error.SyntaxError (located at the exponent); `1e5` ->
  error.InvalidCharacter; plain decimals and unary minus (-1.5) fine.
  The float literal grammar lacks the `[eE][+-]?digits` part.
- Extra symptom: when the offending literal sits in an @imported file,
  the error surfaces unlocated as "Import Error: failed to expand
  @import SLA sources: error.SyntaxError" (this cost a long bisection
  during the sax3dc build). Imported functions also appear to be
  parsed lazily by reachability - an uncalled function carrying the
  bad literal does not error (observed, not separately proven).
- Class: expressiveness gap (exponent literals are universal), not an
  implementation bug. Proposal draft: add the exponent part to the
  float literal grammar; unify the two diagnostics
  (InvalidCharacter vs SyntaxError); make syntax errors inside
  imported files surface with file/line/column instead of the
  unlocated import-expansion wrapper.
- Port-side disposition (NOT a downgrade): bn_f32_val builds +/-inf
  arithmetically (1.0 doubled 1024 times overflows to IEEE +inf,
  exact value), semantics unchanged.

## GAP-PORT-7: Vec<f64> element storage truncates values via integer conversion (compiler bug, found step 2)

- Minimal probe work/probe/v_f64vec.sla: `a.push(0.8); a.push(0.1);
  a.push(0.1); a.push(1.0);` on a Vec<f64> reads back
  [0, 0, 0, 5e-324] — i.e. the stored words are the INTEGER
  truncations (u64)0.8=0, (u64)0.1=0, (u64)1.0=1 reinterpreted as
  f64 bit patterns. Same for values returned from a helper fn.
  Vec<i32>/Vec<u64> storage is exact; scalar f64 locals and struct
  fields are exact; only f64 through generic Vec storage is
  converted. Same family as the already-registered DEF-13
  (HashMap/BTreeMap f64 values crossing u64 slots).
- Impact: any SLA program storing f64 in a Vec silently loses the
  values (no diagnostic). Sax3dc symptom: material vec params and
  node transforms in the compiled (packed) text form read as
  [0, 0, 0, 5e-324] instead of [0.8, 0.1, 0.1, 1].
- Class: pure implementation bug (DEF-13 family). Proposal: Vec
  element stores/loads must bit-preserve f64 (store the value's
  bits in the word slot without numeric conversion), with a corpus
  regression (push distinct f64 values incl. fractions/negatives/
  NaN, read back bit-identical) that fails pre-fix.
- Port-side disposition (NOT a downgrade): X.vecpool stores f64
  BIT patterns in a Vec<u64> via nf_f64_bits/nf_f64_from_bits;
  values are bit-exact, semantics unchanged.

## Port-side fixes recorded at checkpoint 4 (step 2, not compiler gaps)

- check_asset section registry (x.sec_lens) is rebuilt from scratch
  at the start of every check_asset run (Zig builds a fresh map per
  run); without it, pack's post-transform second check reported
  every section as Sax3dDuplicateName.
- Morph channels live in their own arena Vec (x.mchans), mirroring
  Zig's per-morph channel lists; the flat x.chans slices of a mesh
  now hold base channels only (previously mesh ch_len swallowed
  morph channels and pairwise dup detection flagged the morph's
  same-named channel against the base one).
- R-9 (verifier shape rules, step-2 instances of the R-8 family):
  (a) a nested byte-copy loop whose body re-derives pointer casts
  from &param fields on every iteration trips a loop-head
  PhiStateConflict — hoist the casts and the struct-field offset
  above the loop (bn_assemble_one); complex loop bodies go through
  a bool helper so the caller loop stays call-tailed.
  (b) a standalone ptr local derived from sx_ptr_add(ap, ...) held
  across if-branches kept its parent borrow Active and tripped
  MemoryLeak (1012) at main's exits — inline the derivation into
  the call arguments (the entry_chk2 form).
- Step-2 acceptance (2026-11-01, box2 rig): sax3dc builds clean;
  cube and hero check/build/pack outputs byte-identical to the Zig
  oracle (split + packed forms, both pack input sources); the only
  stderr deltas are the WROTE path strings of the smoke harness
  itself (different --out paths).
- Step-3 acceptance (2026-11-01, box2 rig): genpayload + genref +
  readback all build clean and match the Zig oracle byte-for-byte
  (payload files, GLB/glTF/BIN artefacts, digest stdout, REF line,
  verdict stderr incl. the 6-diagnostic negative fixture case).
  Findings recorded while getting there:
  - GAP-PORT-2 refined: the trigger is broader than cast-in-place —
    binding a macro result WITHOUT an explicit type annotation
    (`let cb = PTR_BYTE_AT(p, i);`) also fails codegen; the safe
    form used across the tree is a typed binding
    (`let cb: u8 = PTR_BYTE_AT(p, i);`), exactly as core.sla's
    sx_rd_u16/u32 already do.
  - R-10: a bare Vec value (local or &param) has no `.len` FIELD —
    `v.len` is NotAStruct; the method form `v.len()` works, as do
    field chains through a struct (`x.secs.len()`). The same split
    applies to X's Vec fields: `x.plans.len` (field form) fails,
    `x.plans.len()` is the tree-wide convention.
  - R-11: a CONDTIONAL extern call whose argument materialises a
    reference cell (sa_io_write_all's &buf) leaves a Composite
    register on the taken path vs Uninitialized on the other ->
    PhiStateConflict at the merge. Repair: call unconditionally
    (len 0 writes nothing), or hoist all materialisation above the
    branch (rb_flush).
  - PTR_READ_U64's expansion is NOT typed u64 for the checker:
    values read through it must be cast at the use site from the
    bound variable (`tlen as u64`), never on the macro call itself
    (GAP-PORT-2).
  - Layout law re-verified against layout.zig plan(): payloads are
    packed TIGHTLY in declaration order; section alignment is
    recorded in the plan/record but never pads offsets.
- Step-4 acceptance (2026-11-01, box2 rig): run_tests 62-item suite
  run in one sandbox with Zig binaries and with SLA binaries —
  both 62/62 PASS, PASS/FAIL name sets identical, and the full
  tests-run trees (all logs, digests, binaries, SIZE table) are
  byte-identical except the garbage-input log line (the corpus
  generator feeds fresh /dev/urandom bytes each run). Negative
  cases therefore match on first diagnostic name AND order, not
  just on the expected code appearing somewhere.
  Port bugs found by the differential (all in readback.sla, all
  fixed): record names must be collected per-record (the name blob
  also carries declaration names); sx_read_file's status cell is
  not a length — two sites (iface fixture, path image) now use the
  filled SBuf's own len.

## GAP-PORT-8 (compiler semantics defect): f64 values crossing a control-flow merge lose float identity

An f64 local that is reassigned on only one side of a merge — an
if-branch, or carried around a loop — reads back after the merge as
its i64 bit pattern numerically converted to f64 (branch form), or
as NaN (loop form, observed when the carried value feeds division).
Probe work/probe/v_f64.sla (box2 rig): direct `nf_push_f64(1.0)`
prints "1"; a plain local prints "1"; the same local reassigned
inside a never-taken if-branch prints "4607182418800017400" (bits
4607182418800017408). Loop form: a Newton sqrt whose iterate is an
f64 loop-carried local returns NaN for every input whose first
iterate is not already the fixpoint (derive_normals in the
converter produced the (0,0,1) fallback for 1725/1728 Fox vertices
before the workaround). Same family as GAP-PORT-3 (f64 sign/identity
lost before user code observes the value).
Port workaround (semantics-preserving): f64 results reach their use
through a SINGLE unconditional binding — a helper whose body selects
via early returns (mat_factor_pbr / mat_factor_top / metallic_final),
or an iteration carried as u64 bits with a fresh f64 local per step
(nf_f32_sqrt). Improvement proposal: the checker's phi merge must
preserve the f64 register class of merged locals; a regression probe
is v_f64.sla plus the loop form in the converter's sqrt (expected:
branch form prints "1", loop form converges for non-fixpoint seeds).

## GAP-PORT-9 (compiler semantics defect): while-head variable assigned from a Vec index read in the body is never re-tested

If a while loop's condition variable is assigned anywhere in the
body from a Vec index read, the head phi keeps the entry value
forever: the loop either walks out of bounds (runtime PANIC code=32,
process rc=160) or never terminates (timeout rc=124). Probe
work/probe/v_while.sla shapes A-G: self-indexed update, constant
index read, helper-call assignment and independent-index assignment
all fail; arithmetic-only updates of the condition variable are
unaffected. First hit in the converter's conv_skins parent walk
(extra iteration with cur=-1 against a verified-sane parent table).
Port workaround: recursion with early returns
(joint_parent_span), or counter-bounded loops whose condition
variables are only updated arithmetically. Improvement proposal:
loop-head phis must be emitted for every local assigned in the body
regardless of the assignment's RHS shape; regression probe is
v_while.sla (shapes A-G must all terminate with the entry-value
semantics of a normal while).

## R-12 (toolchain rule, step 5): `go` is a reserved word

Any binding named `go` (local, field use in some positions) is a
SyntaxError. The converter's output accumulator is `gout`.

## R-13 (toolchain rule, step 5): float literals take no suffix and no exponent

`0.0f32` is a SyntaxError (cf. GAP-PORT-6 for exponents). Spell
f32 constants as nf_f32_from_bits(<bits>) or cast an f64 literal.

## R-14 (toolchain rule, step 5): string literals bound to locals are descriptors, not data pointers

A string literal bound to a plain local yields the address of its
fat {data_ptr, len} descriptor (probe v_keys.sla: bytes at the
binding read 96, 46 = the data pointer's little-endian bytes; the
length sits at offset 8), NOT the data pointer. Literals passed
DIRECTLY as call arguments yield the data pointer correctly.
Rule: never bind table literals to locals; pass them directly into
walker helpers (kw_index / kw_in in the converter compare a needle
against a directly-passed table literal). Corollary: a literal
pointer written through an out-parameter is a StackEscape (the
callee's stack temp escapes); return an int code and push the
literal at the use site instead.

## R-15 (toolchain rule, step 5): high-byte \xNN literals corrupt generated SA

A literal containing bytes >= 0x80 via \xNN escapes is emitted into
the generated SA as invalid UTF-8 and breaks the build. Spell such
constants as byte arrays (the PNG signature is
[137, 80, 78, 71, 13, 10, 26, 10]).

## R-16 (toolchain rule, step 5): bare blocks take no trailing semicolon

Like while-blocks (R-2), a bare block `{}` used as a statement must
NOT be followed by `;`.

## R-17 (toolchain rule, step 5): whole-struct and field borrows conflict in one call

Passing `&s` and `&s.field` in the same call is a BorrowConflict.
Use field-level helper variants that take the field itself as the
first parameter (put_span_s / put_jspan_j / fl_push pattern).

## R-18 (toolchain rule, step 5): hand-counted literal lengths are unreliable

Every `"...", N` pair in this tree intends N = the literal's UTF-8
byte length, and hand counts were wrong in 32 places in
convert.sla alone (one emitted 2 NUL bytes plus garbage into the
output JSON). The whole tree is audited mechanically (escape-aware
byte-length checker); new literals must pass the same audit.

## R-19 (toolchain rule, step 5): prefix tests need sx_starts_with

x_eq_lit / ar_eq_lit are FULL-span equality, not prefix tests
(the cube "raw-" check silently failed against "raw-rgba8").
Prefix membership uses sx_starts_with(p, n, lit, lit_len).

## Port bug fixed at step 6 (not a compiler gap): node-children traversal read idxpool offsets as node indices

- Symptom (found by the step-5 Fox differential, 2026-11-01): the SLA
  `convert to-gltf` export of Fox emitted glTF nodes in scrambled order
  (same name multiset; skins/animation indices consistently remapped, so
  fox_equiv still passed) while cube/hero exports were byte-identical.
  The SLA `sax3dc pack` of Fox likewise differed (174 B size delta).
- Root cause: in the SLA model, NodeD.ch_off is an offset into the flat
  x.idxpool array (parse.sla:1255/1259; scene roots likewise, parse.sla:
  1299-1302), and node indices are POST-ORDER (a node finalizes after
  its children, parse.sla:1254). The correct traversal dereferences
  (`x.idxpool[(nd.ch_off + ci)]`, as check.sla collect_nodes_rec,
  layout.sla:216 and packform.sla:516 already do for roots), but four
  sites passed the raw offset as a node index:
  layout.sla:122 (nt_add_node recursion), packform.sla:401 (pf_node
  recursion), convert.sla gltf_node_emit children loop, convert.sla
  scene-roots loop. The offset-as-index reading coincides with the true
  children for leftmost/small subtrees (hence cube/hero green) and
  scrambles larger trees (Fox: e.g. Spine02's children read as the
  left-arm chain reversed). The scene-roots loop was accidentally right
  for Fox (r_off == root's post-order index when the scene has one
  multi-node tree plus single-node trees) but wrong in general.
- Fix (semantics-preserving, same values): all four sites now dereference
  through idxpool. Re-verified by the full differentials (run_tests 62,
  run_convert 43, Fox pack byte-compare) in the step-6 re-run.

## GAP-PORT-10 (compiler semantics defect): f32 addition rounds toward zero, not round-to-nearest-even

- Minimal repro (probes/probe_f32e.sla, box rig): f32
  (1.0 + 2^-23) + f32(2^-24) has exact sum 1 + 1.5 ULP; correctly-rounded
  result is 0x3F800002, SLA yields 0x3F800001 (truncation toward zero).
  Isolated form (probes/probe_f32d.sla): for acc
  (0x40f058bc, 0xc204023b, 0xc057515e), the f32 sum
  x0*x0 + y0*y0 + z0*z0 is 0x44909c01 in SLA vs 0x44909c02 correctly
  rounded (exact sum is closer to the upper neighbor, not a tie); all
  three f32 products and the first add match IEEE, only the final add
  is 1 ULP low. f32 sub/mul/div and f64->f32 casts probe correctly
  rounded on the same rig, so the defect is specific to f32 addition
  (whether the add lowering itself truncates, or the add runs in f64
  with a truncating convert back, is not distinguished by these
  probes).
- Impact: Fox derived normals differ from Zig on 1929/5184 f32 words
  (mostly 1-2 ULP, max observed 21 ULP via accumulation cascade); the
  derived payload file, the referee .saxb3d, and the roundtrip .bin
  are therefore not byte-identical, although fox_equiv (name/set
  comparison) passes and all 43 convert items pass. No
  semantics-preserving port-side workaround exists (reordering the
  sum, or computing it in f64 and rounding once, is a different
  rounding scheme, not the Zig per-op f32 rounding) — the port keeps
  Zig-identical f32 arithmetic and the gap is registered for the
  DEF/compiler queue. Same family as DEF-14 (float semantics).

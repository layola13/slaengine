# SA compiler issue: MemoryLeak when accessing fields of a nested @derive(copy) struct

Reported during Batch 401 deepening work in `sla_ecs/`.

## Summary

When a struct field is itself another `@derive(copy)` struct (nested struct),
accessing fields of the nested struct through the outer struct causes the SA
backend to report `MemoryLeak: live registers remain at function exit`, even
when both the outer and nested structs carry `@derive(copy)`.

## Reproducer

Save the following as `repro.sla` and run:

```
sa sla test repro.sla --test-backend sa --jobs 1 --trace-panic
```

```sla
@derive(copy)
struct Inner {
    bits: i32,
    v0: i64,
    vn: i32,
}

@derive(copy)
struct Outer {
    flags: Inner,
    last: i64,
}

fn make_outer() -> Outer {
    return Outer { flags: Inner { bits: 5, v0: 7, vn: 0 }, last: 99 };
}

fn outer_last(w: Outer) -> i64 { return w.last; }
fn outer_flags_bits(w: Outer) -> i32 { return w.flags.bits; }
fn outer_flags_first(w: Outer) -> i64 { return w.flags.v0; }

@test "probe_nested_wrapper"() {
    let w = make_outer();
    let b = outer_flags_bits(w);
    let v0 = outer_flags_first(w);
    let l = outer_last(w);
    if b != 5 { panic(1); };
    if v0 != 7 { panic(2); };
    if l != 99 { panic(3); };
}
```

## Expected

All three accesses succeed; the `@test` passes.

## Actual

The SA backend emits:

```
error[MemoryLeak]: live registers remain at function exit
  in function @test "probe_nested_wrapper"():
  register: tmp_17
  state: Active
```

A live register pointing to a piece of the copied `w.flags` nested struct
remains at function exit, even though only scalar fields were read.

## Notes

- The same pattern with flat scalar fields (no nested struct) does **not** leak.
  Inlining the nested struct's fields directly into the outer struct is the
  current workaround used in `lib/system_trait_deep.sla`.
- The type-level SLA compiler (`sa sla check`) reports this code as fine; the
  leak is only surfaced by the SA backend's register-ownership analysis.
- This issue blocks cleanly modeling shallow modules that legitimately model
  subsystems as nested structs (e.g., `struct SystemStateFlags` stored inside a
  `System`, where callers like `ecs_system_is_initialized(s)` read
  `s.flags.bit`).

## Addendum: recurrence in Batch 405 (`lib/query_access_iter_extras_deep.sla`)

The deep module modeled `AccessIsCompatibleResult` (the result of
`ecs_access_type_deep_is_compatible`) as:

```sla
@derive(copy)
struct AccessIsCompatibleResultDeep {
    ok: i32,
    conflict: EcsAccessConflictErrorDeep,   // <-- nested @derive(copy) struct
}
```

A test that calls `ecs_acr_deep_conflict_*` accessors several times on the
same result (test `conflict_error_fields_set` in
`tests/test_ecs_lib_query_access_iter_extras_deep_isolated.sla`) hit the same
`MemoryLeak`:

```
error[MemoryLeak]: live registers remain at function exit
  in function @test "conflict_error_fields_set"():
  register: tmp_8693
  state: Active
```

Because the previous tracking mix in this batch produces no problems on the
default backend, this confirms the SA-backend-specific ownership analysis is
what fails. The fix used in this batch matches the Batch 401 workaround:
flatten the nested conflict struct's fields directly into the wrapper struct:

```sla
@derive(copy)
struct AccessIsCompatibleResultDeep {
    ok: i32,
    a_variant: i32,
    a_level_kind: i32,
    a_component_id: i32,
    b_variant: i32,
    b_level_kind: i32,
    b_component_id: i32,
}
```

The `EcsAccessConflictErrorDeep` struct was kept for the shallow-parity sub-fields
(`*_deep_*` accessors) but the wrapper now stores the same data flat, so tests
only touch the wrapper's own fields. The same workaround applies for any
deep module that needs to expose a `(bool, SubStruct)` result.

## Addendum: recurrence in Batch 406 (`lib/system_registry_template_deep.sla`)

The deep module originally modeled the result-tuple replacements as small
wrapper structs whose only job was carrying a mutated container plus a
small companion:

```sla
@derive(copy)
struct EcsCachedRegisterResultDeep { registry: EcsCachedSystemRegistryDeep, entity: i64 }

@derive(copy)
struct EcsCachedUnregisterResultDeep { registry: EcsCachedSystemRegistryDeep, success: i32 }

@derive(copy)
struct EcsCachedRunWithResultDeep { entity: i64, input_value: i64 }

@derive(copy)
struct EcsTemplateAllocResultDeep { context: EcsTemplateContextDeep, entity: i64 }

@derive(copy)
struct EcsTemplateBuildResultDeep { template: EcsSystemHandleTemplateDeep, assigned_entity: i64 }
```

Two of the wrapper structs (EcsCachedRegisterResultDeep and
EcsTemplateAllocResultDeep) nest a cap-16 container struct and stores on
top of it. The test `cached_registry_cap16_not_exceeded_on_overflow` calls
`ecs_cached_registry_deep_register` in a tight loop 16 times pulling each
result out through `ecs_cached_register_result_deep_registry(r); ...
ecs_cached_register_result_deep_entity(r);` and then chained into the next
register call. On the SA backend this reported the same `MemoryLeak: live
registers remain at function exit`, even though access was the wrapper's own
field. The same pattern applies to the other three wrappers because they
follow the same nested-wrapper shape.

### Generalised fix used

Flatten the wrapper's tuple-companion value into the container struct
itself, and make the mutating fn return the container directly (not a
wrapper). Companion accessors read the new inline field:

- `EcsCachedSystemRegistryDeep` got `last_registered_entity: i64`,
  `last_unregister_success: i32`, `last_run_with_entity: i64`,
  `last_run_with_input: i64`. `register`, `unregister`, and `run_with` now
  return `EcsCachedSystemRegistryDeep`. `ecs_cached_registry_deep_last_*`
  accessors expose the companions.
- `EcsTemplateContextDeep` got `last_allocated_entity: i64`. `allocate_entity`
  returns `EcsTemplateContextDeep`. The `last_allocated_entity` accessor reads
  the companion.
- `EcsSystemHandleTemplateDeep` got `last_build_entity: i64`. `build` returns
  the mutated `EcsSystemHandleTemplateDeep`. `ecs_template_deep_last_build_entity`
  reads it.

This generalises Batch 401's instructions ("avoid nested @derive(copy)
struct field access") to "also avoid tuple-replacement wrappers that nest the
operational struct" because (a) the leak surfaces the same way, and (b)
returning-only the container struct + reading the companion from the same
struct reproduces the same observable API as the tuple-return result without
needing two structs per mutation.

## Addendum: recurrence in Batch 406 (`lib/system_registry_template_deep.sla`)

The deep module originally modeled the result-tuple replacements as small
wrapper structs whose only job was carrying a mutated container plus a
small companion:

```sla
@derive(copy)
struct EcsCachedRegisterResultDeep { registry: EcsCachedSystemRegistryDeep, entity: i64 }

@derive(copy)
struct EcsCachedUnregisterResultDeep { registry: EcsCachedSystemRegistryDeep, success: i32 }

@derive(copy)
struct EcsCachedRunWithResultDeep { entity: i64, input_value: i64 }

@derive(copy)
struct EcsTemplateAllocResultDeep { context: EcsTemplateContextDeep, entity: i64 }

@derive(copy)
struct EcsTemplateBuildResultDeep { template: EcsSystemHandleTemplateDeep, assigned_entity: i64 }
```

Two of the wrapper structs (EcsCachedRegisterResultDeep and
EcsTemplateAllocResultDeep) nest a cap-16 container struct and stores on
top of it. The test `cached_registry_cap16_not_exceeded_on_overflow` calls
`ecs_cached_registry_deep_register` in a tight loop 16 times, pulling each
result out through the wrapper accessors and chaining into the next register
call. On the SA backend this reported the same `MemoryLeak: live registers
remain at function exit`, even though access was the wrapper's own field.
The same pattern applies to the other wrapper instances because they all
follow the nested-wrapper shape.

### Generalised fix used

Flatten the wrapper's tuple-companion value into the container struct
itself, and make the mutating fn return the container directly (not a
wrapper). Companion accessors read the new inline field:

- `EcsCachedSystemRegistryDeep` got `last_registered_entity: i64`,
  `last_unregister_success: i32`, `last_run_with_entity: i64`,
  `last_run_with_input: i64`. `register`, `unregister`, and `run_with` now
  return `EcsCachedSystemRegistryDeep`; `ecs_cached_registry_deep_last_*`
  accessors expose the companions.
- `EcsTemplateContextDeep` got `last_allocated_entity: i64`. `allocate_entity`
  returns `EcsTemplateContextDeep`; `last_allocated_entity` accessor reads it.
- `EcsSystemHandleTemplateDeep` got `last_build_entity: i64`. `build` returns
  the mutated `EcsSystemHandleTemplateDeep`;
  `ecs_template_deep_last_build_entity` reads it.

This generalises Batch 401's "avoid nested @derive(copy) struct field access"
to "also avoid tuple-replacement wrappers that nest the operational struct".
Returning the container struct directly and reading the companion from the
same struct reproduces the observable API of the tuple result without
requesting an extra nested struct, and the SA backend stops leaking.

## Addendum: Batch 407 — type-checker diagnostic misattributes `UndefinedVariable`

Unrelated to the MemoryLeak lineage above, while fixing
`lib/schedule_node_sets_deep.sla` in Batch 407 we hit a separate SLA
type-checker diagnostic-quality issue that may be worth filing as its own
ticket. The file had an `_essa_contains_wc` helper whose body had been
left in a broken state (it contained the entire body of a separate fn
`ecs_system_access_deep_get_conflicts`, including references to `b`,
`n`, `out0`, `out1`, `out2`, `out3`, `j` — names not in scope of the
helper). The compiler reported only:

```
Type Check Error: failed to verify types: UndefinedVariable: identifier `b`
  is not defined in this scope (error.UndefinedVariable)
```

No file path, line, column, or enclosing-fn name was emitted, so the only
unbound identifier the user is told about is `b`, even though `n`, `out0`,
`out1`, `out2`, `out3`, and `j` are equally unbound in the same function
body. The first unbound name is reported as if it were the sole error, and
the user has no source location to point them at the offending function.

### Suggested improvement

- Surface the offending file path and source range (start line/col) for the
  `UndefinedVariable` diagnostic, the same way the runtime panic output and
  the `check` parse error already do (`path:line:col`).
- When multiple identifiers are unbound in the same scope, report all of
  them (or at least the distinct enclosing declaration site that
  introduced them), not just the first one encountered. This would keep
  users from doing one decode-check cycle per missing name.

### Reproducer

Save the following as `repro_diag.sla` and run `sa sla check repro_diag.sla`.

```sla
@derive(copy)
struct Caps8 {
    rc0: i32, rc1: i32, rc2: i32, rc3: i32,
    rc4: i32, rc5: i32, rc6: i32, rc7: i32,
    rcn: i32,
}

fn rc_at(a: Caps8, idx: i32) -> i32 {
    if idx == 0 { return a.rc0; };
    panic(1);
}

fn contains_clean(a: Caps8, v: i32) -> bool {
    let i: i32 = 0;
    while i < a.rcn {
        if rc_at(a, i) == v { return true; };
        i = i + 1;
    }
    return false;
}

// The intentionally broken function below references `b`, `n`, `out0`,
// `out1`, `out2`, `out3`, `j` — none of which are in scope here. Pointing
// all of these out (and at the function rather than just the first name)
// makes the diagnostic actionable.
fn contains_broken(a: Caps8, v: i32) -> bool {
    let i: i32 = 0;
    while i < a.rcn {
        if b != 0 { return false; };
        if n == 0 { out0 = 1; n = 1; };
        if n == 1 { out1 = 1; n = 2; };
        if n == 2 { out2 = 1; n = 3; };
        if n == 3 { out3 = 1; n = 4; };
        i = i + 1;
    }
    while j < a.rcn {
        i = i + 1;
    }
    return true;
}
```

Observed: only `UndefinedVariable: identifier 'b' is not defined in this
scope` is reported with no file/line/column info; resolving just `b` then
surfaces the *next* name one at a time. Expected: a single `sa sla check`
run reports all unbound identifiers in `contains_broken` together, with the
file path and source location attached.

## Addendum (Batch 415): SA backend `ForbiddenSyntax` regression across deep-iso tests

During Batch 415 (`lib/world_mod_deep.sla`) I noticed that invoking the SA backend on any deep-iso test now fails during SA IR flattening with `error[ForbiddenSyntax]: forbidden syntax detected during flattening`. This is a *toolchain* regression, not specific to Batch 415: I can reproduce it on previously-green test files from earlier batches, for example:

```
sa sla test tests/test_ecs_lib_world_extras_deep_isolated.sla --test-backend sa --jobs 1 --trace-panic
sa sla test tests/test_ecs_lib_reflect_misc_deep_isolated.sla --test-backend sa --jobs 1 --trace-panic
sa sla test tests/test_ecs_lib_schedule_node_sets_deep_isolated.sla --test-backend sa --jobs 1 --trace-panic
```

All three produce a trap of the shape:

```json
{"trap":"ForbiddenSyntax","trap_code":1001,"file":"tests/<NAME>.test.sa","line":<N>,"source_line":<N>,
 "context":[{"line":<N-2>,"text":"    return"},{"line":<N-1>,"text":null},{"line":<N>,"text":null}, ...],
 "repair":{"action":"rewrite","hint":"lower structured control flow into labels, branches, and explicit register moves","confidence":"high"}}
```

The reported context is a `return` immediately followed by two blank lines, with `static_mask`/`actual_mask` and `bad_token` all null. The default backend (`sa sla test tests/<NAME>.sla --jobs 1 --trace-panic`) for the same files compiles and passes — so the failure is isolated to the SA flattener.

### Reproducer (single-file)

Save as `repro.sla` and run `sa sla test repro.sla --test-backend sa --jobs 1 --trace-panic`:

```sla
@derive(copy)
struct CapVec {
    e0: i64, e1: i64, e2: i64, en: i32,
}

fn capvec_push(w: CapVec, v: i64) -> CapVec {
    if w.en == 0 { w.e0 = v; w.en = 1; return w; };
    if w.en == 1 { w.e1 = v; w.en = 2; return w; };
    if w.en == 2 { w.e2 = v; w.en = 3; return w; };
    return w;
}

fn capvec_at(w: CapVec, idx: i32) -> i64 {
    if idx == 0 { return w.e0; };
    if idx == 1 { return w.e1; };
    if idx == 2 { return w.e2; };
    return 0;
}

@test "push_then_read"() {
    let w = CapVec { e0: 0, e1: 0, e2: 0, en: 0 };
    w = capvec_push(w, 11);
    w = capvec_push(w, 22);
    if capvec_at(w, 0) != 11 { return; };
    if capvec_at(w, 1) != 22 { return; };
}
```

Observed under the current toolchain: `ForbiddenSyntax` trap during flattening of the
generated `.test.sa`. Expected: the SA backend flattens the sequential-if pattern the
same way it did in earlier batches (the pre-existing pattern all deep modules rely on)
and runs the test to a pass.

### Impact

- All existing `tests/test_ecs_lib_*_deep_isolated.sla` files fail the SA backend.
- The default backend still passes for these files, so per-file verification can proceed
  using `sa sla test <file> --jobs 1 --trace-panic` (no `--test-backend` flag).
- Batch 415 verification was carried out on the default backend only; SA backend runs
  were used only to surface this trap for the issue report.

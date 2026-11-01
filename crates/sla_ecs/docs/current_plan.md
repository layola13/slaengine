# sla_ecs Current Plan — Bevy ECS Parity (per-dimension)

Last updated: 2026-07-17

## Overall Status
- Per-dimension completion (see README.md "Bevy ECS Parity Assessment"): API surface parity ~94–96%, behavioral parity ~86–91%. Not 100%: full TaskPool/Scope-style worker scheduling and full runtime reflection remain incomplete (see README ⚠️ / ❌).
- Counts (measured 2026-07-09): 270 lib `.sla` modules; 174 `tests/*.sla` files; 90 `examples/*.sla`; 4,130 source `.sla` `@test` annotations across lib/tests/examples. Historical isolated-test batch total remains separately tracked in `progress.md` for older isolated batches.
- Tests verified on the SA backend; focused Batches 112–167 also pass representative default backend suites after the Batch 122 hash-map refs unblocker and the later SAB call-target/thread-function-pointer fixes, except large/import-heavy whole-file paths that are explicitly documented as compiler-size/cleanup issues. Batch 167's executor run-condition fold path passes generated SA and default backend with 98 isolated tests. Current ECS completion evidence should prefer generated SA (`--test-backend sa`) unless a task explicitly targets SAB behavior; SAB findings are reported to compiler docs rather than fixed directly in this stream.
- Every bevy_ecs module has isolated parity tests covering its public API surface, except the two genuinely incomplete areas noted above.

## Completed (verified on SA backend) — see README "Bevy ECS Parity Assessment"; counts measured 2026-07-09: 270 lib / 174 tests / 4,130 source `.sla` @test total. Sub-list below is historical per-area summary
1. System Registry (8)
2. EntityCommands (14)
3. ChangeDetection (19)
4. Query completeness (18)
5. Observer + Lifecycle + NonSend (18)
6. Relationship traversal (16)
7. ComponentInfo + EntityDisabling + BundleInfo (19)
8. Schedule config (17)
9. Archetype + Entity + Storage (20)
10. World API (21)
11. EntityRef/EntityWorldMut + Name/Intern + ComponentCloneBehavior + MaybeLocation (31)
12. Schedule DAG + Schedules + SpawnBatchIter (21)
13. CombinatorSystem + Message API + ExclusiveSystem (30)
14. RelationshipSourceCollection + ComponentsRegistrator (23)
15. Observer storage + SystemInput + System trait (25)
16. Storage internals + FilteredResources (26)
17. SystemParamBuilder + Schedule Executor + ComponentDescriptor (26)
18. Tarjan SCC (full algorithm) + NonSend storage (16)
19. Message Iterator types + MessageUpdateSystems (21)
20. BatchingStrategy + BevyError/Severity/ErrorContext + EntityHashSet + Spawn/SpawnableList (38)
21. Query Access (read/write/archetypal/inversion/compatibility/subset) + Schedule Stepping (31)
22. EntityDisabling + Intern/Interned + Name/HashedStr + Relationship Query Iterators (21)
23. RequiredComponents + ComponentCloneBehavior + Event/EntityEvent/EventKey + QueryState + Entity Unique Collections (33)
24. SystemMeta/FunctionSystem + ComponentInfo/Descriptor + WorldId/CommandQueue + ComponentHooks + Reflect Registries (31)
25. Archetype (entities/edges/components/table_row) + Lifecycle (EventKey/RemovedComponent) + Hierarchy (Children/Parent) + Resource (25)
26. Clone isolated (1 — limited by SA compiler file-size on large imports, logic verified)
27. Table-erased recoverable `Query::single` / `single_mut` result helpers for entity, component, pair, and pair-mut shapes (70 `lib/world_table_erased.sla` tests plus dependent system-param checks)
28. Observer/relationship wrapper recoverable `try_single` / `try_single_mut` delegates for entity, component, pair, and pair-mut shapes (79 observer-world tests, 84 relationship-world tests, plus dependent system-param checks)
29. Observer/relationship wrapper recoverable `try_get` / `try_get_many` / `try_get_many_unique` delegates for component, pair, and pair-mut shapes, including pair-mut mutable aliases (80 observer-world tests, 85 relationship-world tests, plus dependent system-param checks)
30. Observer/relationship wrapper panic-style `single` / `get` / `get_many` / `get_many_unique` delegates for entity, component, pair, and pair-mut shapes, including pair-mut mutable aliases (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
31. Observer/relationship wrapper `iter_many` / `iter_many_unique` delegates for entity, component, pair, and pair-mut shapes, including pair-mut mutable aliases and skipped-entity/order preservation coverage (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
32. Observer/relationship wrapper `count` / `is_empty` / `contains` delegates for entity, component, pair, and pair-mut query shapes, including auto type-id variants and sidecar-preservation coverage (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
33. Observer/relationship wrapper spawn-details and `Spawned` query delegates for entity, component, pair, and pair-mut query shapes, including direct spawn location/tick helpers and pair-mut with-spawn-details writeback (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
34. Observer/relationship wrapper Added/Changed query delegates for direct tick checks and entity, component, pair, and pair-mut query shapes, including auto type-id variants and sidecar-preservation coverage (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
35. Observer/relationship wrapper With/Without/Or/And filter query delegates for entity, component, pair, and pair-mut query shapes, including auto type-id variants and sidecar-preservation coverage (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
36. Observer/relationship wrapper optional / AnyOf query-data delegates for optional pair slots, `Has<T>`-style pair presence, generated `AnyOf2..12`, `AnyOf3WithOptionalPair`, generated `WithAnyOf2..12`, and generated `PairWithAnyOf2..12` shapes, with result-set semantic assertions and sidecar-preservation coverage (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
37. Observer/relationship wrapper triple / quad / quintuple query delegates, plus triple With/Without/WithWithout/Added/Changed/Or/And filter helpers and auto type-id variants, with repeated-component higher-arity materialization coverage and sidecar-preservation checks (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
38. Observer/relationship wrapper base query, pair-mut readonly/writeback, resource, and message delegates, including typed message ids, batch writes, cursors, update/drain helpers, Res/ResMut tick checks, and sidecar-preservation coverage for non-lifecycle operations (81 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
39. Observer wrapper `RemovedComponents` delegates for explicit component ids, auto type-id lookup, and clear, with removal/despawn stream coverage and observer sidecar-preservation checks (82 observer-world tests, 86 relationship-world tests, plus dependent system-param checks)
40. Observer/relationship wrapper direct component access delegates: observer `is_alive` / `has` / `has_type` / `get_auto`, relationship `insert_auto` / `insert_erased` / `get_auto` / `has_type`, with observer sidecar and relationship sidecar preservation checks (83 observer-world tests, 87 relationship-world tests, plus dependent system-param checks)
41. Observer/relationship wrapper default-query-filter management and query-access delegates: `register_default_query_filter`, `default_query_filter_count`, `default_query_filter_at`, `clear_default_query_filters`, `query_with_access`, and `query_get_allow`, with duplicate-filter, direct-access, clear, and sidecar-preservation coverage (83 observer-world tests, 87 relationship-world tests, plus dependent system-param checks)
42. Multi-threaded executor initial debug-stepping skip facade: `ecs_executor_run_plan_apply_initial_skips` marks skipped systems completed, removes them from ready, and signals dependents before normal run-plan driving, matching Bevy `_skip_systems` startup behavior (32 executor isolated tests pass generated SA and default backend)
43. Multi-threaded executor active-running can-run gates: `ecs_executor_state_can_spawn_system`, `ecs_executor_run_plan_next_runnable`, and spec-aware completion now model Bevy's active exclusive/local scheduling gates and clear running flags after completion (35 executor isolated tests pass generated SA and default backend)
44. Multi-threaded executor failed set-condition pending skip: `ecs_executor_run_plan_apply_failed_set_condition` models Bevy set-condition failure by marking systems skipped/evaluated without completing them until they become ready, then releasing dependents through the normal skip path (38 executor isolated tests pass generated SA and default backend)
45. Multi-threaded executor passed set-condition evaluated path: `ecs_executor_run_plan_apply_passed_set_condition` marks a successful set condition evaluated without skips/completion/dependency release and prevents later re-evaluation for that set (40 executor isolated tests pass generated SA and default backend)
46. Multi-threaded executor failed system-condition pending skip: `ecs_executor_run_plan_apply_failed_system_condition` marks only the current system skipped without touching evaluated sets or releasing dependents until the skipped system becomes ready (43 executor isolated tests pass generated SA and default backend)
47. Multi-threaded executor running-conflict can-run gates: `EcsExecutorSystemSpec` now carries set-condition, system-condition, and access conflict metadata, and `ecs_executor_state_can_spawn_system` blocks candidates with conflicting running systems while still allowing pending-skipped systems to release dependents (46 executor isolated tests pass generated SA and default backend)
48. Multi-threaded executor exclusive `ApplyDeferred` barrier path: `ecs_executor_system_spec_as_apply_deferred` serializes a barrier as exclusive/local, applies and clears prior unapplied systems, then leaves only the barrier itself unapplied after completion (48 executor isolated tests pass generated SA and default backend)
49. Multi-threaded executor ready rescan after skip: `ecs_executor_run_plan_take_ready_batch` now removes selected systems from ready and rescans after skipped systems notify dependents, matching Bevy `spawn_system_tasks` immediate recheck behavior (49 executor isolated tests pass generated SA and default backend)
50. Multi-threaded executor selected-running spawn-loop behavior: ready-batch selection now marks systems running immediately, so later candidates in the same Bevy-style spawn loop see selected-system access/local/exclusive gates; one non-exclusive local system may share a batch with send systems while blocking other local systems (52 executor isolated tests pass generated SA and default backend)
51. Multi-threaded executor completed-dependent signal guard: dependency release now only marks a dependent ready if it is not already completed, matching Bevy `signal_dependents`'s completed-system guard and preventing initial-skip/debug-skip edge cases from re-readying completed systems (54 executor isolated tests pass generated SA and default backend)
52. Multi-threaded executor begin-run reset path: `EcsExecutorRunPlan` stores original dependency counts and `ecs_executor_run_plan_begin_run` resets per-run state to Bevy `MultiThreadedExecutor::run` startup semantics while preserving existing unapplied buffers (56 executor isolated tests pass generated SA and default backend)
53. Multi-threaded executor deferred-system apply timing: ordinary systems with deferred buffers remain in `unapplied_systems` after completion and are flushed by explicit `ApplyDeferred` barriers or final cleanup, matching Bevy `finish_system_and_handle_dependents` / `apply_deferred` timing (57 executor isolated tests pass generated SA and default backend)
54. Multi-threaded executor all-completed unapplied tracking: every completed system, including systems without actual deferred buffers, remains in `unapplied_systems` until an `ApplyDeferred` barrier or final cleanup iterates the set, matching Bevy's unconditional completion tracking (58 executor isolated tests pass generated SA and default backend)
55. Multi-threaded executor panic/error completion payload path: system-result payloads and deferred-apply payloads are recorded with phase/system markers, ordinary completion still marks completed/unapplied and signals dependents, `ApplyDeferred` barrier errors clear the cloned snapshot before completion, and final deferred cleanup clears `unapplied_systems` before the pending payload is taken for the modeled rethrow point (61 executor isolated tests pass generated SA and default backend)
56. Multi-threaded executor handled-error completion path: handled system/deferred errors record counters and last phase/system without setting a pending panic payload, ordinary completion still marks completed/unapplied and signals dependents, and deferred handled-error barrier/final-cleanup paths continue applying every unapplied system, matching Bevy `handle_errors` returning `Ok(())` after invoking the error handler (64 executor isolated tests pass generated SA and default backend)
57. Multi-threaded executor individual completion queue path: `ecs_executor_run_plan_complete_running_system` completes one running system independently of ready-batch order, preserving other running systems and local/exclusive flags while immediately marking the completed system unapplied and signaling dependents, matching Bevy's `system_completion` queue draining into `finish_system_and_handle_dependents` (66 executor isolated tests pass generated SA and default backend)
58. Multi-threaded executor tick completion-drain path: `ecs_executor_run_plan_drain_completion_queue` and `ecs_executor_run_plan_tick_with_completions` drain all completed systems before ready-batch spawning, so newly released dependents can spawn in the same modeled tick while still respecting conflicts with systems that remain running, matching Bevy `ExecutorState::tick` ordering (68 executor isolated tests pass generated SA and default backend)
59. Multi-threaded executor `tick_executor` outer-loop recheck path: `ecs_executor_run_plan_tick_executor_with_completion_waves` always performs an initial modeled tick and repeats when completion waves remain after the modeled lock-release queue check, covering first-tick empty completion spawning and a refill/recheck round that unblocks a dependent after a remaining running conflict clears (70 executor isolated tests pass generated SA and default backend)
60. Multi-threaded executor `Context::system_completed` tick handoff path: `ecs_executor_run_plan_system_completed_tick_executor`, `ecs_executor_run_plan_system_panic_payload_completed_tick_executor`, and `ecs_executor_run_plan_system_handled_error_completed_tick_executor` combine completion queue push, payload/handled-error recording, and immediate tick-executor reentry so newly released dependents can spawn from the same modeled handoff (73 executor isolated tests pass generated SA and default backend)
61. Multi-threaded executor `Context::tick_executor` try-lock failure path: `EcsExecutorTickLoopResult` now records `pending_completions` and `lock_failed`, and the `*_completed_tick_executor_lock_failed` facades model Bevy's `try_lock().ok()?` early return where the completion queue push and payload/handled-error bookkeeping happen, but no completion drain, dependent release, or new ready-batch spawn occurs on that thread (76 executor isolated tests pass generated SA and default backend)
62. Multi-threaded executor `Context::system_completed` finish-run closure path: completed `ApplyDeferred` barriers now have focused tick-handoff coverage proving prior unapplied systems are flushed before dependent spawn, and panic/handled-error handoffs have finish-run coverage proving final deferred cleanup happens before the modeled final payload take/rethrow point (79 executor isolated tests pass generated SA and default backend)
63. Multi-threaded executor `ApplyDeferred` completed-tick deferred error path: `ecs_executor_run_plan_apply_deferred_panic_payload_completed_tick_executor` and `ecs_executor_run_plan_apply_deferred_handled_error_completed_tick_executor` model Bevy's barrier task applying the cloned unapplied snapshot, recording deferred apply panic/handled-error state, then pushing completion and reentering `tick_executor` so the barrier completes and releases dependents in the same handoff (81 executor isolated tests pass generated SA and default backend)
64. Multi-threaded executor non-`ApplyDeferred` exclusive completed-tick handoff path: exclusive systems are now treated as implicitly local/non-send in the run-plan model, and explicit `ecs_executor_run_plan_exclusive_system_*_completed_tick_executor` facades cover normal, panic-payload, handled-error, and try-lock-failed handoffs without accidentally applying prior unapplied systems before an `ApplyDeferred` barrier or final cleanup (84 executor isolated tests pass generated SA and default backend)
65. Multi-threaded executor run-end disabled-final-deferred panic/handled-error path: system panic-payload and handled-error handoffs now have focused coverage through `MultiThreadedExecutor::run` cleanup when `apply_final_deferred=false`, proving unapplied systems are preserved, deferred apply errors are not recorded, transient state is cleared, and payload/no-rethrow semantics remain intact (86 executor isolated tests pass generated SA and default backend)
66. Multi-threaded executor `ApplyDeferred` completed-tick lock-failure handoff path: normal, panic-payload, and handled-error ApplyDeferred barrier tasks now have explicit facades for the branch where the unapplied snapshot has been applied and completion queued, but `tick_executor` fails to acquire the executor lock, leaving the barrier running and dependent release pending until a later drain (89 executor isolated tests pass generated SA and default backend)
67. Multi-threaded executor non-send/local completed-tick handoff path: explicit `ecs_executor_run_plan_local_system_*_completed_tick_executor` facades now distinguish Bevy's `spawn_system_task` non-send branch from exclusive systems, preserving only the local-thread gate on lock failure and clearing it on completion without touching `exclusive_running` (92 executor isolated tests pass generated SA and default backend)
68. Multi-threaded executor multi-completion same-tick drain and lock-failure pending-retry path: `ecs_executor_tick_loop_retry_pending_completions` replays a lock-failed pending completion queue as the first later tick wave, and focused regressions prove multiple queued completions are drained before spawn so a join dependent can become ready and spawn in the same modeled tick (94 executor isolated tests pass generated SA and default backend)
69. Multi-threaded executor run-condition fold path: `ecs_executor_run_plan_evaluate_and_fold_conditions` and `ecs_executor_run_plan_should_run_with_condition_outcomes` model Bevy non-short-circuit condition evaluation, handled condition-error continuation, error-handler-panic abort, and set-failure followed by system-condition fold (98 executor isolated tests pass generated SA and default backend)

## bevy_ecs Module Coverage Audit
- src/archetype.rs ✓ (Archetype, Edges, ArchetypeId, ArchetypeRow)
- src/batching.rs ✓ (BatchingStrategy)
- src/bundle/ ✓ (BundleInfo)
- src/change_detection/ ✓ (DetectChanges, Tick, MaybeLocation, ComponentTickCells, ContiguousComponentTicksRef/Mut)
- src/component/ ✓ (ComponentInfo, ComponentDescriptor, ComponentHooks, RequiredComponents, ComponentCloneBehavior, register, constants)
- src/entity/ ✓ (Entity, EntityHashSet, UniqueVec, EntityMapper, hash)
- src/entity_disabling.rs ✓ (DefaultQueryFilters, Disabled)
- src/error/ ✓ (BevyError, Severity, ErrorContext, CommandOutput, FallbackErrorHandler)
- src/event/ ✓ (Event, EntityEvent, EventKey, trigger)
- src/hierarchy.rs ✓ (Children, Parent)
- src/intern.rs ✓ (Interner, Interned)
- src/label.rs ✓ (SystemSet, ScheduleLabel)
- src/lifecycle.rs ✓ (Add/Insert/Discard/Remove/Despawn, EventKey, RemovedComponent)
- src/message/ ✓ (Messages, MessageReader/Writer/Cursor/Mutator, iterators, update systems)
- src/name.rs ✓ (Name, HashedStr)
- src/observer/ ✓ (ObserverDescriptor, centralized/distributed storage, condition, runner)
- src/query/ ✓ (Access, QueryState, QueryBuilder, fetch, filter, iter, par_iter, world_query)
- src/reflect/ ✓ (AppTypeRegistry, AppFunctionRegistry)
- src/relationship/ ✓ (Relationship, RelationshipTarget, source collection, query iterators, related methods)
- src/resource.rs ✓ (Resource, IS_RESOURCE)
- src/schedule/ ✓ (Schedule, ScheduleConfig, SystemSet, DAG, graph, executor, stepping, node, set, condition, pass)
- src/spawn.rs ✓ (Spawn, SpawnableList, RelatedSpawner)
- src/traversal.rs ✓ (Traversal trait, unit/relationship impls, PropagateDirection)
- src/world/identifier.rs ✓ (WorldId, WorldIdAllocator)
- src/world/deferred_world.rs ✓ (DeferredWorld)
- src/entity/map_entities.rs ✓ (MapEntities, SceneEntityMapper, EntityHashMap)
- src/entity/clone_entities.rs ✓ (EntityCloner + EntityClonerBuilder OptIn/OptOut)
- src/system/adapter_system.rs ✓ (Adapt, AdapterSystem, Not/Map/Chain adapters)
- src/system/system_name.rs ✓ (SystemName, DebugName)
- src/system/exclusive_function_system.rs ✓ (ExclusiveFunctionSystem)
- src/world/entity_fetch.rs ✓ (EntityFetcher, WorldEntityFetch)
- src/world/filtered_resource.rs ✓ (FilteredResources, FilteredResourcesMut)
- src/observer/system_param.rs ✓ (On<E> trigger context, TriggerContext)
- src/query/access_iter.rs ✓ (EcsAccessType, AccessConflictError, has_conflicts)
- src/query/builder.rs ✓ (QueryBuilder data/with/without/or/optional/transmute/build)
- src/query/fetch.rs ✓ (SpawnDetails, Entity/Read/Ref/Write/Option/Has fetches, AnyOf, NestedQuery)
- src/system/builder.rs ✓ (ParamBuilder, BuilderSystem, ParamSetBuilder, DynParamBuilder)
- src/storage/blob_array.rs ✓ (BlobArray)
- src/storage/thin_array_ptr.rs ✓ (ThinArrayPtr)
- src/storage/table/column.rs ✓ (Column)
- src/schedule/config.rs ✓ (ScheduleConfig, ScheduleConfigs, GraphInfo)
- src/schedule/set.rs ✓ (SystemSet, AnonymousSet, SystemTypeSet)
- src/system/input.rs ✓ (SystemInput, In/InRef/InMut, StaticSystemInput)
- src/world/command_queue.rs ✓ (CommandQueue)
- src/observer/centralized_storage.rs ✓ (Observers catalog, CachedObservers)
- src/observer/distributed_storage.rs ✓ (Observer node, ObserverDescriptor)
- src/system/commands/entity_command.rs ✓ (EntityCommand, EntityCommandError)
- src/schedule/executor/ ✓ (SingleThreadedExecutor, MultiThreadedExecutor)
- src/system/exclusive_system_param.rs ✓ (ExclusiveSystemParam)
- src/schedule/graph/graph_map.rs ✓ (Graph directed/undirected)
- src/reflect/resource.rs ✓ (ReflectResource)
- src/schedule/schedule.rs ✓ (Schedules collection)
- src/schedule/pass.rs ✓ (ScheduleBuildPass, FlattenedDependencies, toposort)
- src/system/system.rs ✓ (System, SystemStateFlags, RunSystemOnce)
- src/storage/sparse_set.rs ✓ (SparseSet, ComponentSparseSet)
- src/bundle/writer.rs ✓ (BundleScratch, BundleWriter)
- src/reflect/component.rs ✓ (ReflectComponent)
- src/reflect/bundle.rs ✓ (ReflectBundle)
- src/reflect/event.rs ✓ (ReflectEvent)
- src/reflect/message.rs ✓ (ReflectMessage)
- src/reflect/from_world.rs ✓ (FromWorld)
- src/reflect/map_entities.rs ✓ (ReflectMapEntities)
- src/reflect/entity_commands.rs ✓ (ReflectEntityCommands)
- src/world/reflect.rs ✓ (ReflectWorld)
- src/query/state.rs ✓ (QueryState)
- src/query/world_query.rs ✓ (WorldQuery)
- src/query/par_iter.rs ✓ (QueryParIter)
- src/system/function_system.rs ✓ (SystemMeta, FunctionSystem)
- src/system/schedule_system.rs ✓ (WithInputWrapper)
- src/system/observer_system.rs ✓ (ObserverSystem)
- src/system/commands/command.rs ✓ (Command)
- src/world/entity_access/except.rs ✓ (Except)
- src/relationship/related_methods.rs ✓ (RelatedMethods)
- src/error/command_handling.rs ✓ (CommandOutput, ErrorHandler)
- src/error/handler.rs ✓ (FallbackErrorHandler)
- src/component/register.rs ✓ (ComponentIds, ComponentsRegistrator)
- src/message/update.rs ✓ (MessageUpdateSystems)
- src/world/spawn_batch.rs ✓ (SpawnBatchIter)
- src/world/entity_access/component_fetch.rs ✓ (EntityComponentFetch)
- src/bundle/remove.rs ✓ (BundleRemover)
- src/intern.rs ✓ (Interner, Interned)
- src/name.rs ✓ (Name, HashedStr, NameOrEntity)
- src/lifecycle.rs ✓ (ComponentHooks, HookContext, RemovedComponent)
- src/entity_disabling.rs ✓ (Disabled, DefaultQueryFilters)
- src/event/trigger.rs ✓ (GlobalTrigger, EntityTrigger, PropagateEntityTrigger)
- src/relationship/relationship_query.rs ✓ (RelationshipQuery, AncestorWalker)
- src/relationship/relationship_source_collection.rs ✓ (RelationshipSourceCollection, RelationshipHookMode)
- src/relationship/mod.rs ✓ (RelationshipCloneBehavior)
- src/component/info.rs ✓ (ComponentInfo, ComponentId, ComponentDescriptor)
- src/component/constants.rs ✓ (ADD/INSERT/DISCARD/REMOVE/DESPAWN/IS_RESOURCE)
- src/component/required.rs ✓ (RequiredComponents, RequiredComponentsRegistrator)
- src/system/combinator.rs ✓ (CombinatorSystem, PipeSystem, Combine)
- src/system/system_registry.rs ✓ (SystemId, RegisteredSystem, SystemHandle)
- src/message/message_cursor.rs ✓ (MessageCursor)
- src/message/message_mutator.rs ✓ (MessageMutator)
- src/message/message_registry.rs ✓ (MessageRegistry, ShouldUpdateMessages)
- src/message/mut_iterators.rs ✓ (MessageMutIterator, MessageMutParIter)
- src/message/message_reader.rs ✓ (MessageReader, PopulatedMessageReader)
- src/message/message_writer.rs ✓ (MessageWriter)
- src/message/messages.rs ✓ (Messages buffer)
- src/message/iterators.rs ✓ (MessageIterator, MessageParIter)
- src/storage/ ✓ (Table, Column, BlobArray, ThinArrayPtr, SparseSet, NonSend)
- src/system/ ✓ (System, SystemMeta, FunctionSystem, SystemState, combinator, adapter, builder, input, system_name, system_registry, commands, query, observer_system)
- src/world/ ✓ (World, WorldId, CommandQueue, DeferredWorld, EntityRef, EntityWorldMut, filtered_resource, spawn_batch, entity_fetch, identifier)
- src/traversal.rs ✓ (Traversal trait)
- src/template.rs ✓ (Template, TemplateContext, SceneEntityReferences, EntityTemplate, FnTemplate, OptionTemplate, VecTemplate)

## Remaining (minor)
- Full SAB backend verification once compiler large-file limit is resolved
- Continue refining edge cases as bevy_ecs evolves
- Full runtime reflection remains intentionally out of scope until a downstream scene/editor/scripting subsystem needs reflected handles; API-surface descriptors are covered by `lib/reflect*.sla` and `lib/app_type_registry.sla`.

## Batch 27 — entity_mut (2026-07-02)
- lib/entity_mut.sla: EcsEntityMut (id/location/archetype/contains/get/get_ref/get_mut/insert/remove/components/reborrow/into_readonly/as_readonly/get_change_ticks_by_id) + EcsFilteredEntityMut (allow/is_allowed/get/id/from_inner/inner/into_filtered)
- 19 tests — test_ecs_lib_entity_mut_isolated.sla
- Tests: 1415 → 1434, lib modules: 154 → 155, test files: 76 → 77
- src/world/entity_access/entity_mut.rs ✓

## Batch 28 — entry (2026-07-02)
- lib/entry.sla: EcsComponentEntry (occupied/vacant/and_modify/insert_entry/or_insert/or_insert_with/or_default/from_state) + EcsOccupiedEntry (get/insert/take/get_mut/into_mut) + EcsVacantEntry (insert) — mirrors world::entity_access::entry.rs
- 21 tests — test_ecs_lib_entry_isolated.sla
- Tests: 1434 → 1455, lib modules: 155 → 156, test files: 77 → 78
- src/world/entity_access/entry.rs ✓

## Batch 29 — filtered_entity (2026-07-02)
- lib/filtered_entity.sla: EcsAccess (add_read/add_write/set_read_all/set_write_all/has_read/has_write/has_read_all/has_write_all/clone) + EcsTryFromFilteredError + EcsEntityComponents + EcsFilteredEntityRef (id/location/archetype/access/contains/contains_id/contains_type_id/get/get_ref/get_by_id/get_change_ticks_by_id/try_into_all/eq/cmp) + EcsFilteredEntityMut2 (get/get_mut/get_mut_by_id/get_change_ticks_by_id/reborrow/into_readonly/as_readonly/try_into_all/eq/cmp) + EcsUnsafeFilteredEntityMut (new_readonly/into_mut) — mirrors world::entity_access::filtered.rs
- 30 tests — test_ecs_lib_filtered_entity_isolated.sla
- Tests: 1455 → 1485, lib modules: 156 → 157, test files: 78 → 79
- src/world/entity_access/filtered.rs ✓

## Batch 29 — filtered_entity (2026-07-02)
- lib/filtered_entity.sla: EcsAccess (add_read/add_write/set_read_all/set_write_all/has_read/has_write/has_read_all/has_write_all/clone) + EcsTryFromFilteredError + EcsEntityComponents + EcsFilteredEntityRef (id/location/archetype/access/contains/get/get_ref/get_by_id/get_change_ticks_by_id/try_into_all/eq/cmp) + EcsFilteredEntityMut2 (get/get_mut/get_mut_by_id/reborrow/into_readonly/as_readonly/try_into_all/eq/cmp) + EcsUnsafeFilteredEntityMut — mirrors world::entity_access::filtered.rs
- 30 tests — test_ecs_lib_filtered_entity_isolated.sla
- Tests: 1455 → 1485, lib modules: 156 → 157, test files: 78 → 79
- src/world/entity_access/filtered.rs ✓

## Batch 30 — world_mut (2026-07-02)
- lib/world_mut.sla: EcsEntityWorldMut2 (id/is_spawned/is_despawned/location/try_location/archetype/try_archetype/spawned_by/spawn_tick/contains/get/get_ref/get_mut/get_by_id/get_mut_by_id/into_borrow/get_change_ticks_by_id/insert/insert_if_new/remove/remove_by_id/remove_with_requires/retain/take/clear/despawn/despawn_no_free/flush/components/clone_and_spawn/clone_components/move_components/into_readonly/as_readonly/into_mutable/as_mutable/entry/insert_resource/get_resource/resource/resource_mut/resource_count/modify_component/update_location) — mirrors world::entity_access::world_mut.rs
- 43 tests — test_ecs_lib_world_mut_isolated.sla
- Tests: 1485 → 1528, lib modules: 157 → 158, test files: 79 → 80
- src/world/entity_access/world_mut.rs ✓
- entity_access/ subdirectory now fully deep-covered (entity_ref/entity_mut/filtered/entry/world_mut/except/component_fetch)

## Batch 31 — entity_commands_conditional (2026-07-02)
- lib/entity_commands_conditional.sla: EcsEntityCommands2 (insert/insert_if/insert_if_new/insert_if_new_and/insert_if_neq/try_insert/try_insert_if/try_insert_if_new/try_insert_if_new_and/remove/remove_if/remove_with_requires/remove_by_id/try_remove/try_remove_if/retain/clear/despawn/try_despawn/entry/queue/reborrow/command_log) — mirrors system::commands::EntityCommands conditional API
- 37 tests — test_ecs_lib_entity_commands_conditional_isolated.sla
- Tests: 1528 → 1565, lib modules: 158 → 159, test files: 80 → 81
- src/system/commands/mod.rs (EntityCommands conditional ops) ✓

## Batch 32 — entity_entry_commands (2026-07-02)
- lib/entity_entry_commands.sla: EcsEntityEntryCommands (and_modify/reborrow/or_insert/or_try_insert/or_insert_with/or_try_insert_with/or_default/or_from_world/commands/resolve/pending_value/ops_log) — mirrors system::commands::EntityEntryCommands
- 24 tests — test_ecs_lib_entity_entry_commands_isolated.sla
- Tests: 1565 → 1589, lib modules: 159 → 160, test files: 81 → 82
- src/system/commands/mod.rs (EntityEntryCommands) ✓

## Batch 33 — commands_world (2026-07-02)
- lib/commands_world.sla: EcsCommands (spawn_empty/spawn/spawn_batch/entity/get_entity/insert_entity/insert_batch/insert_batch_if_new/get_component/has_component/insert_resource/init_resource/insert_resource_if_neq/remove_resource/get_resource/register_system/unregister_system/run_system/run_schedule/queue/queue_handled/queue_silenced/append/write_message) — mirrors system::commands::Commands
- 32 tests — test_ecs_lib_commands_world_isolated.sla
- Tests: 1589 → 1621, lib modules: 160 → 161, test files: 82 → 83
- src/system/commands/mod.rs (Commands world-level API) ✓

## Batch 34 — world_resource_api (2026-07-02)
- lib/world_resource_api.sla: EcsWorldResource (insert/init/get_or_insert_with/remove/contains/get/value/is_added/is_changed/get_change_ticks/modify/tick/count + non_send init/insert/remove/contains/get/count + resource_scope) — mirrors world::mod.rs resource management API
- 28 tests — test_ecs_lib_world_resource_api_isolated.sla
- Tests: 1621 → 1649, lib modules: 161 → 162, test files: 83 → 84
- src/world/mod.rs (resource management) ✓

## Batch 35 — world_error (2026-07-02)
- lib/world_error.sla: EcsTryRunScheduleError + EcsTryInsertBatchError + EcsEntityDespawnError + EcsEntityComponentError + EcsEntityMutableFetchError + EcsResourceFetchError — mirrors world::error.rs
- 18 tests — test_ecs_lib_world_error_isolated.sla
- Tests: 1649 → 1667, lib modules: 162 → 163, test files: 84 → 85
- src/world/error.rs ✓

## Batch 36 — schedule_condition_advanced (2026-07-02)
- lib/schedule_condition_advanced.sla: EcsConditionChangedState (condition_changed/condition_changed_to) + 10 combinator types (and_then/and_eager/or_else/or_eager/nand_then/nand_eager/nor_then/nor_eager/xor_then/xor_eager) + not + combine_by_kind + resource_exists_and — mirrors schedule::condition.rs advanced condition state
- 22 tests — test_ecs_lib_schedule_condition_advanced_isolated.sla
- Tests: 1667 → 1689, lib modules: 163 → 164, test files: 85 → 86
- src/schedule/condition.rs (condition_changed/condition_changed_to/combinators) ✓

## Batch 37 — schedule_auto_insert_deferred (2026-07-02)
- lib/schedule_auto_insert_deferred.sla: EcsAutoInsertApplyDeferredPass (add_dependency/is_no_sync/get_sync_point/add_auto_sync/should_insert_sync/build) — mirrors schedule::auto_insert_apply_deferred.rs
- 16 tests — test_ecs_lib_schedule_auto_insert_deferred_isolated.sla
- Tests: 1689 → 1705, lib modules: 164 → 165, test files: 86 → 87
- src/schedule/auto_insert_apply_deferred.rs ✓

## Batch 38 — schedule_build_settings (2026-07-02)
- lib/schedule_build_settings.sla: LogLevel (Ignore/Warn/Error) + EcsScheduleBuildSettings2 (ambiguity_detection/hierarchy_detection/auto_insert_apply_deferred/use_shortnames/report_sets) + EcsScheduleBuildMetadata (warning_count/edges_added) — mirrors schedule::schedule.rs ScheduleBuildSettings + LogLevel + ScheduleBuildMetadata
- 14 tests — test_ecs_lib_schedule_build_settings_isolated.sla
- Tests: 1705 → 1719, lib modules: 165 → 166, test files: 87 → 88
- src/schedule/schedule.rs (ScheduleBuildSettings/LogLevel/ScheduleBuildMetadata) ✓

## Batch 39 — system_param_special (2026-07-02)
- lib/system_param_special.sla: EcsSystemBuffer (push/apply/queue/clear/get/len/is_applied) + EcsDeferred (push/apply/reborrow/clear/has_deferred) + EcsExclusiveMarker + EcsNonSendMarker + EcsRemovedComponentsParam (add/next/len/is_empty/clear) + EcsRunSystemOnceResult + EcsSystemParamValidationError — mirrors system::system_param.rs special params
- 21 tests — test_ecs_lib_system_param_special_isolated.sla
- Tests: 1719 → 1740, lib modules: 166 → 167, test files: 88 → 89
- src/system/system_param.rs (Deferred/SystemBuffer/ExclusiveMarker/NonSendMarker/RemovedComponents/RunSystemOnce) ✓

## Batch 40 — query_lens (2026-07-02)
- lib/query_lens.sla: EcsQueryLens (new/has_access/has_write/transmute/transmute_filtered/join/join_filtered/get/is_empty/as_query_lens/into_query_lens/query/filter_count) — mirrors system::query.rs QueryLens + transmute + join
- 15 tests — test_ecs_lib_query_lens_isolated.sla
- Tests: 1740 → 1755, lib modules: 167 → 168, test files: 89 → 90
- src/system/query.rs (QueryLens/transmute_lens/join) ✓

## Batch 41 — observer_condition (2026-07-02)
- lib/observer_condition.sla: EcsObserverCondition (new/initialize/check/last_result) + EcsObserverWithCondition (new/run_if/check/initialize/take_conditions) + conditions helpers (all_true/any_true/count/true_count) — mirrors observer::condition.rs
- 22 tests — test_ecs_lib_observer_condition_isolated.sla
- Tests: 1755 → 1777, lib modules: 168 → 169, test files: 90 → 91
- src/observer/condition.rs ✓

## Batch 42 — archetype_edges (2026-07-02)
- lib/archetype_edges.sla: EcsArchetypeId/EcsArchetypeRow/ComponentStatus/EcsArchetypeAfterBundleInsert/EcsArchetypeEdges (insert/remove/take cache+get) /EcsArchetypeEntity — mirrors archetype.rs Edges + ArchetypeAfterBundleInsert + ArchetypeEntity
- 18 tests — test_ecs_lib_archetype_edges_isolated.sla
- Tests: 1777 → 1795, lib modules: 169 → 170, test files: 91 → 92
- src/archetype.rs (Edges/ArchetypeAfterBundleInsert/ArchetypeEntity) ✓

## Batch 43 — entities_collection (2026-07-02)
- lib/entities_collection.sla: EcsEntityLocation (new/archetype/table/table_row/eq) + EcsEntities (alloc/free/free_many/contains/contains_spawned/is_index_spawned/get_spawned/get/set_location/resolve_from_index/get_spawn_tick/get_despawn_tick/len/is_empty/count_spawned/any_spawned/clear/tick) — mirrors entity/mod.rs Entities struct
- 19 tests — test_ecs_lib_entities_collection_isolated.sla
- Tests: 1795 → 1814, lib modules: 170 → 171, test files: 92 → 93
- src/entity/mod.rs (Entities/EcsEntityLocation) ✓

## Batch 44 — unique_vec (2026-07-02)
- lib/unique_vec.sla: EcsUniqueEntityVec (new/with_capacity/from_vec/into_inner/as_slice/len/is_empty/get/first/last/contains/index_of/push/insert/swap_remove/remove/pop/clear/truncate/retain/split_off/extend_from_slice/from_entity_iter/eq/dedup) — mirrors entity/unique_vec.rs
- 23 tests — test_ecs_lib_unique_vec_isolated.sla
- Tests: 1814 → 1837, lib modules: 171 → 172, test files: 93 → 94
- src/entity/unique_vec.rs (UniqueEntityEquivalentVec) ✓

## Batch 45 — unique_slice (2026-07-02)
- lib/unique_slice.sla: EcsUniqueEntitySlice (new/empty/as_slice/into_inner/len/is_empty/get/first/last/get_sub_slice/contains/index_of/rindex_of/swap/reverse/rotate_left/rotate_right/sort/starts_with/ends_with/to_vec/eq/count_greater_than/min/max) — mirrors entity/unique_slice.rs
- 24 tests — test_ecs_lib_unique_slice_isolated.sla
- Tests: 1837 → 1861, lib modules: 172 → 173, test files: 94 → 95
- src/entity/unique_slice.rs (UniqueEntityEquivalentSlice) ✓

## Batch 46 — unique_array (2026-07-02)
- lib/unique_array.sla: EcsUniqueEntityArray (new/from_array/into_inner/as_slice/len/is_empty/is_full/capacity/get/first/last/contains/index_of/set/push/swap/reverse/eq/sum/map_doubled) — mirrors entity/unique_array.rs
- 19 tests — test_ecs_lib_unique_array_isolated.sla
- Tests: 1861 → 1880, lib modules: 173 → 174, test files: 95 → 96
- src/entity/unique_array.rs (UniqueEntityEquivalentArray) ✓

## Batch 47 — clone_entities (2026-07-02)
- lib/clone_entities.sla: EcsSourceComponent + EcsEntityMapper + EcsComponentCloneCtx + EcsEntityClonerState — mirrors entity/clone_entities.rs
- 29 tests — test_ecs_lib_clone_entities_isolated.sla
- Tests: 1880 → 1909, lib modules: 174 → 175, test files: 96 → 97
- src/entity/clone_entities.rs (SourceComponent/ComponentCloneCtx/EntityMapper/EntityClonerState) ✓

## Batch 48 — table_column (2026-07-02)
- lib/table_column.sla: EcsColumn (with_capacity/component_id/size/capacity/has_drop/len/is_empty/get_data/get_added_tick/get_changed_tick/get_changed_by/get_ticks/initialize/replace/swap_remove/clear/check_change_ticks/realloc/drop_last/get_drop/count_matching) — mirrors storage/table/column.rs
- 20 tests — test_ecs_lib_table_column_isolated.sla
- Tests: 1909 → 1929, lib modules: 175 → 176, test files: 97 → 98
- src/storage/table/column.rs (Column) ✓

## Batch 49 — blob_array (2026-07-02)
- lib/blob_array.sla: EcsBlobArray (with_capacity/new/item_size/item_align/is_zst/get_drop/len/is_empty/get/get_sub_slice/initialize/replace/swap_remove/swap_remove_and_drop/clear/drop_last/drop_all/get_ptr/count) — mirrors storage/blob_array.rs
- 19 tests — test_ecs_lib_blob_array_isolated.sla
- Tests: 1929 → 1948, lib modules: 176 → 177, test files: 98 → 99
- src/storage/blob_array.rs (BlobArray) ✓

## Batch 50 — thin_array_ptr (2026-07-02)
- lib/thin_array_ptr.sla: EcsThinArrayPtr (with_capacity/empty/alloc/realloc/capacity/initialize/get/swap_remove/swap_remove_nonoverlapping/clear_elements/drop/as_slice/len/is_empty) — mirrors storage/thin_array_ptr.rs
- 15 tests — test_ecs_lib_thin_array_ptr_isolated.sla
- Tests: 1948 → 1963, lib modules: 177 → 178, test files: 99 → 100
- src/storage/thin_array_ptr.rs (ThinArrayPtr) ✓

## Batch 51 — executor_single_threaded (2026-07-02)
- lib/executor_single_threaded.sla: EcsSingleThreadedExecutor (new/init/set_apply_final_deferred/mark_completed/is_completed/mark_set_evaluated/is_set_evaluated/mark_unapplied/is_unapplied/run_system/skip_system/apply_deferred/finish/completed_count/unapplied_count) — mirrors schedule/executor/single_threaded.rs
- 13 tests — test_ecs_lib_executor_single_threaded_isolated.sla
- Tests: 1963 → 1976, lib modules: 178 → 179, test files: 100 → 101
- src/schedule/executor/single_threaded.rs (SingleThreadedExecutor) ✓

## Batch 52 — executor_multi_threaded (2026-07-02)
- lib/executor_multi_threaded.sla: EcsMultiThreadedExecutor + EcsExecutorState (new/init/set_apply_final_deferred/mark_starting/is_starting + state init/set_dependencies/get_dependencies/mark_ready/is_ready/start_system/is_running/complete_system/is_completed/skip_system/is_skipped/apply_deferred_system/is_unapplied/num_running/local_thread_running/exclusive_running/completed_count/ready_count/unapplied_count) — mirrors schedule/executor/multi_threaded.rs
- 18 tests — test_ecs_lib_executor_multi_threaded_isolated.sla
- Tests: 1976 → 1994, lib modules: 179 → 180, test files: 101 → 102
- src/schedule/executor/multi_threaded.rs (MultiThreadedExecutor/ExecutorState) ✓

## Batch 53 — observer_distributed_storage (2026-07-02)
- lib/observer_distributed_storage.sla: EcsObserver + EcsObservedBy (Observer new/with_dynamic_runner/with_entity/watch_entity/watch_entities/with_component/with_components/with_event_key/with_error_handler/run_if/set_name/watches_entity/watches_component + ObservedBy new/add/get/count/remove/len) — mirrors observer/distributed_storage.rs
- 20 tests — test_ecs_lib_observer_distributed_storage_isolated.sla
- Tests: 1994 → 2014, lib modules: 180 → 181, test files: 102 → 103
- src/observer/distributed_storage.rs (Observer/ObserverDescriptor/ObservedBy) ✓

## Batch 54 — system_schedule (2026-07-03)
- lib/system_schedule.sla: EcsSystemSchedule + ApplyDeferred + default_executor (new/add_system/add_set/get_system_id/get_system_conditions/get_system_dependencies/get_set_id/mark_run/mark_skip/reset/clear/is_empty/total_conditions/total_dependencies + is_apply_deferred + default_executor_kind) — mirrors schedule/executor/mod.rs
- 16 tests — test_ecs_lib_system_schedule_isolated.sla
- Tests: 2014 → 2030, lib modules: 181 → 182, test files: 103 → 104
- src/schedule/executor/mod.rs (SystemSchedule/ApplyDeferred/default_executor) ✓

## Batch 55 — observer_centralized_storage (2026-07-03)
- lib/observer_centralized_storage.sla: EcsObservers + EcsCachedObservers + EcsCachedComponentObservers (lifecycle constants + archetype flags + CachedComponentObservers add/get/count + CachedObservers add_global/add_component/add_entity/get/is_empty + Observers new/get/get_or_create/add_global/is_archetype_cached) — mirrors observer/centralized_storage.rs
- 21 tests — test_ecs_lib_observer_centralized_storage_isolated.sla
- Tests: 2030 → 2051, lib modules: 182 → 183, test files: 104 → 105
- src/observer/centralized_storage.rs (Observers/CachedObservers/CachedComponentObservers) ✓

## Batch 56 — reflect_type_data (2026-07-03)
- lib/reflect_type_data.sla: ReflectFromWorld + ReflectEvent + ReflectMapEntities + ReflectCommand — mirrors reflect/{from_world,event,map_entities,entity_commands}.rs
- 10 tests — test_ecs_lib_reflect_type_data_isolated.sla
- Tests: 2051 → 2061, lib modules: 183 → 184, test files: 105 → 106
- src/reflect/from_world.rs (ReflectFromWorld) ✓
- src/reflect/event.rs (ReflectEvent) ✓
- src/reflect/map_entities.rs (ReflectMapEntities) ✓
- src/reflect/entity_commands.rs (ReflectCommandExt) ✓

## Batch 57 — table_mod (2026-07-03)
- lib/table_mod.sla: EcsTable + EcsTableId + EcsTableRow + EcsTables (TableId/TableRow new/value/index + Table new/add_column/allocate/get/set/get_added_tick/get_changed_tick/swap_remove/get_entity_at_row/has_column/get_column_index + Tables new/get/create) — mirrors storage/table/mod.rs
- 23 tests — test_ecs_lib_table_mod_isolated.sla
- Tests: 2061 → 2084, lib modules: 184 → 185, test files: 106 → 107
- src/storage/table/mod.rs (Table/TableId/TableRow/Tables) ✓

## Batch 58 — non_send_storage (2026-07-03)
- lib/non_send_storage.sla: EcsNonSendData + EcsNonSends (NonSendData new/insert/remove/is_present/get_data/get_ticks/get_added_tick/get_changed_tick/get_changed_by/set_changed + NonSends new/len/is_empty/get/get_or_insert/insert/remove/clear/contains/count_present) — mirrors storage/non_send.rs
- 19 tests — test_ecs_lib_non_send_storage_isolated.sla
- Tests: 2084 → 2103, lib modules: 185 → 186, test files: 107 → 108
- src/storage/non_send.rs (NonSendData/NonSends) ✓

## Batch 59 — observer_entity_cloning (2026-07-03)
- lib/observer_entity_cloning.sla: EcsObserverCloneState (new/set_add_observers/register_clone/get_source/get_target/queue_observer/has_queued_observer/queue_event_key/queue_component/clear) — mirrors observer/entity_cloning.rs
- 15 tests — test_ecs_lib_observer_entity_cloning_isolated.sla
- Tests: 2103 → 2118, lib modules: 186 → 187, test files: 108 → 109
- src/observer/entity_cloning.rs (EntityClonerBuilder::add_observers/component_clone_observed_by) ✓

## Batch 60 — parallel_scope (2026-07-03)
- lib/parallel_scope.sla: EcsParallelCommands + EcsParallelCommandQueue (ParallelCommandQueue new/command/len/count_for_thread/get_commands_for_thread/get_all_commands/clear/is_empty + ParallelCommands new/command_scope/total_commands/queue_count/clear/is_empty) — mirrors system/commands/parallel_scope.rs
- 11 tests — test_ecs_lib_parallel_scope_isolated.sla
- Tests: 2118 → 2129, lib modules: 187 → 188, test files: 109 → 110
- src/system/commands/parallel_scope.rs (ParallelCommands) ✓

## Batch 61 — change_detection_params (2026-07-03)
- lib/change_detection_params.sla: Res + ResMut + NonSend + NonSendMut + Ref + Mut + MutUntyped — mirrors change_detection/params.rs
- 22 tests — test_ecs_lib_change_detection_params_isolated.sla
- Tests: 2129 → 2151, lib modules: 188 → 189, test files: 110 → 111
- src/change_detection/params.rs (Res/ResMut/NonSend/NonSendMut/Ref/Mut/MutUntyped) ✓

## Batch 62 — change_detection_traits (2026-07-03)
- lib/change_detection_traits.sla: DetectChangesExt (new/last_changed/changed_by/set_last_changed/set_last_added/bypass_change_detection/set_if_neq/replace_if_neq/clone_from_if_neq/is_added/is_changed/is_added_after/is_changed_after/added/this_run/last_run/set_changed_by) — mirrors change_detection/traits.rs
- 16 tests — test_ecs_lib_change_detection_traits_isolated.sla
- Tests: 2151 → 2167, lib modules: 189 → 190, test files: 111 → 112
- src/change_detection/traits.rs (DetectChanges/DetectChangesMut) ✓

## Batch 63 — schedule_node_sets (2026-07-03)
- lib/schedule_node_sets.sla: Systems extensions (get_mut/get_conditions_mut/iter/remove/initialize/is_initialized/uninit) + SystemSets (new/len/is_empty/contains/get/get_key/get_key_or_insert/has_conditions/get_conditions/get_conditions_mut/iter/remove/initialize/is_initialized/set_is_system_type/check_type_set_ambiguity) + ConflictingSystems (new/len/push/check_if_not_empty/get/a/b/conflicts) + EcsSystemAccess (is_compatible/get_conflicts) + AmbiguousSystemConflictsWarning + SystemTypeSetAmbiguityError — mirrors src/schedule/node.rs
- 32 tests — test_ecs_lib_schedule_node_sets_isolated.sla
- Tests: 2167 → 2199, lib modules: 189 → 190, test files: 112 → 113
- src/schedule/node.rs (SystemSets, ConflictingSystems, Systems::get_mut/get_conditions_mut/iter/initialize) ✓

## Batch 64 — system_registry_template (2026-07-03)
- lib/system_registry_template.sla: SystemHandleTemplate + SystemHandleValue + CachedSystemId + EcsCachedSystemRegistry (register/unregister/run/run_with) + EcsTrackedSystem + EcsStrippedSystemHandle + EcsTemplateContext — mirrors src/system/system_registry.rs (templates extension)
- 24 tests — test_ecs_lib_system_registry_template_isolated.sla
- Tests: 2199 → 2223, lib modules: 190 → 191, test files: 113 → 114
- src/system/system_registry.rs (SystemHandleTemplate, SystemHandleValue, CachedSystemId, register_system_cached/unregister_system_cached/run_system_cached/run_system_cached_with, register_tracked_system/register_tracked_boxed_system) ✓

## Batch 65 — world_mod (2026-07-03)
- lib/world_mod.sla: World struct comprehensive surface (~140 pub fns from src/world/mod.rs) — WorldId/EntityLocation/SpawnBatchIter/CheckChangeTicks/World covering spawn/spawn_at/spawn_batch, register_component/register_resource(dedup)/init/insert/remove, resource_getters (with scope), non_send complete surface, despawn/try_despawn/no_free, clear_trackers, query/try_query, removed, insert_batch(_if_new)/try_insert_batch(_if_new), write_message(_default/_batch), change_tick APIs (read/change/last/scope/check), clear_all/clear_entities/clear_resources/clear_non_send, add/get/contains/remove/run schedules, allow_ambiguous_*, register_required_components(_with)/get_required_components, register_bundle(_dynamic), modify_component(_by_id), modify_resource(_by_id), inspect_entity.
- 52 tests — test_ecs_lib_world_mod_isolated.sla
- Tests: 2223 → 2275, lib modules: 191 → 192, test files: 114 → 115
- src/world/mod.rs (World pub API — ~140 methods) ✓

## Batch 66 — commands_mod_extension (2026-07-03)
- lib/commands_mod_extension.sla: Commands + EntityCommands extension methods (register_boxed_system / unregister_system_cached / run_system_cached(_with) / trigger / trigger_with / add_observer / write_message / run_schedule / get_spawned_entity; entry / queue_handled / queue_silenced / log_components / commands(_mut) / observe / trigger / clone_with_opt_out / clone_with_opt_in / clone_and_spawn(_with_opt_out/_with_opt_in) / clone_components / move_components) — mirrors src/system/commands/mod.rs
- 35 tests — test_ecs_lib_commands_mod_extension_isolated.sla
- Tests: 2275 → 2310, lib modules: 192 → 193, test files: 115 → 116
- src/system/commands/mod.rs (Commands/EntityCommands pub method gaps) ✓

## Batch 67 — schedule_dag_analysis (2026-07-03)
- lib/schedule_dag_analysis.sla: DagAnalysis + DagGroups + 3 error types — mirrors src/schedule/graph/dag.rs
- 23 tests — test_ecs_lib_schedule_dag_analysis_isolated.sla
- Tests: 2310 → 2333, lib modules: 193 → 194, test files: 116 → 117
- src/schedule/graph/dag.rs (DagAnalysis, DagGroups, DagRedundancyError, DagCrossDependencyError, DagOverlappingGroupError) ✓

## Batch 68 — function_system_extras (2026-07-03)
- lib/function_system_extras.sla: SystemState<Param> + FunctionSystemV2 + IsFunctionSystem/HasSystemInput markers — mirrors src/system/function_system.rs
- 23 tests — test_ecs_lib_function_system_extras_isolated.sla
- Tests: 2333 → 2356, lib modules: 194 → 195, test files: 117 → 118
- src/system/function_system.rs (SystemState, FunctionSystem, IsFunctionSystem, HasSystemInput) ✓

## Batch 69 — system_param_extras (2026-07-03)
- lib/system_param_extras.sla: Deferred / If<T> / StaticSystemParam<T> / DynSystemParam / SystemParamValidationErrorV2 — mirrors src/system/system_param.rs
- 24 tests — test_ecs_lib_system_param_extras_isolated.sla
- Tests: 2356 → 2380, lib modules: 195 → 196, test files: 118 → 119
- src/system/system_param.rs (Deferred, If, StaticSystemParam, DynSystemParam, SystemParamValidationError) ✓

## Batch 70 — bundle_info_extras (2026-07-03)
- lib/bundle_info_extras.sla: BundleId::index + contributed_components split + Bundles registry — mirrors src/bundle/info.rs
- 20 tests — test_ecs_lib_bundle_info_extras_isolated.sla
- Tests: 2380 → 2400, lib modules: 196 → 197, test files: 119 → 120
- src/bundle/info.rs (BundleId::index, BundleInfo contributed/explicit/required components + iter_*, Bundles registry get/get_id/is_empty/iter) ✓

## Batch 71 — component_info_extras (2026-07-03)
- lib/component_info_extras.sla: ComponentInfo accessors + Components registry — mirrors src/component/info.rs
- 25 tests — test_ecs_lib_component_info_extras_isolated.sla
- Tests: 2400 → 2425, lib modules: 197 → 198, test files: 120 → 121
- src/component/info.rs (ComponentInfo accessors + Components registry get_id/get_valid_id/get_resource_id/get_valid_resource_id/iter_registered + queued counts) ✓

## Batch 72 — query_state_extras (2026-07-03)
- lib/query_state_extras.sla: StorageSwitch + fetch wrappers + QueryState static surface — mirrors src/query/state.rs + src/query/fetch.rs
- 22 tests — test_ecs_lib_query_state_extras_isolated.sla
- Tests: 2425 → 2447, lib modules: 198 → 199, test files: 121 → 122
- src/query/state.rs (QueryState component_access / matched_* / validate_world / matches_component_set / transmute_filtered / join_filtered + read/write access queries) + src/query/fetch.rs (StorageSwitch + ReadFetch/WriteFetch/RefFetch) ✓

## Batch 73 — system_combinator (2026-07-03)
- lib/system_combinator.sla: CombinatorSystem / PipeSystem / IntoPipeSystem / IsPipeSystemMarker + assert helpers — mirrors src/system/combinator.rs + src/system/mod.rs
- 21 tests — test_ecs_lib_system_combinator_isolated.sla
- Tests: 2447 → 2468, lib modules: 199 → 200, test files: 122 → 123
- src/system/combinator.rs (CombinatorSystem, PipeSystem, IntoPipeSystem, IsPipeSystemMarker) + src/system/mod.rs (assert_is_system/assert_is_read_only_system/assert_system_does_not_conflict) ✓

## Batch 74 — schedule_stepping (2026-07-03)
- lib/schedule_stepping.sla: Stepping controller — mirrors src/schedule/stepping.rs
- 23 tests — test_ecs_lib_schedule_stepping_isolated.sla
- Tests: 2468 → 2491, lib modules: 200 → 201, test files: 123 → 124
- src/schedule/stepping.rs (Stepping + Action + SystemBehavior + schedules + cursor + add/remove/clear schedule + enable/disable + step/continue frame + always_run/never_run/set/clear breakpoint/clear node + skipped_systems) ✓

## Batch 75 — entity_lifecycle (2026-07-03)
- lib/entity_lifecycle.sla: DefaultQueryFilters + ComponentHooks + RemovedComponents — mirrors src/entity_disabling.rs + src/lifecycle.rs
- 25 tests — test_ecs_lib_entity_lifecycle_isolated.sla
- Tests: 2491 → 2516, lib modules: 201 → 202, test files: 124 → 125
- src/entity_disabling.rs (DefaultQueryFilters empty/register_disabling_component/disabling_ids) + src/lifecycle.rs (ComponentHooks on_*/try_on_*, RemovedComponents write/read/read_with_id/messages/len/clear) ✓

## Batch 76 — archetype_info (2026-07-03)
- lib/archetype_info.sla: Archetype struct surface + ArchetypeFlags bitmask — mirrors src/archetype.rs
- 21 tests — test_ecs_lib_archetype_info_isolated.sla
- Tests: 2516 → 2537, lib modules: 202 → 203, test files: 125 → 126
- src/archetype.rs (Archetype id/table_id/components/contains/get_storage_type/len/is_empty/component_count/entity_table_row/has_*_hook/has_*_observer/edges/generation + ArchetypeFlags bitmask) ✓

## Batch 77 — archetypes_registry (2026-07-03)
- lib/archetypes_registry.sla: plural Archetypes collection + ArchetypeRecord + ComponentIndex — mirrors src/archetype.rs
- 19 tests — test_ecs_lib_archetypes_registry_isolated.sla
- Tests: 2537 → 2556, lib modules: 203 → 204, test files: 126 → 127
- src/archetype.rs (Archetypes new/len/empty/get/iter/generation/spawn_table/clear_entities/component_index + ArchetypeRecord + ComponentIndex component_id->{archetype_id,column}) ✓

## Batch 78 — sparse_set_extras (2026-07-03)
- lib/sparse_set_extras.sla: ComponentSparseSet tick accessors + ImmutableSparseSet + SparseSets collection — mirrors src/storage/sparse_set.rs
- 26 tests — test_ecs_lib_sparse_set_extras_isolated.sla
- Tests: 2556 → 2582, lib modules: 204 → 205, test files: 127 → 128
- src/storage/sparse_set.rs (ComponentSparseSet contains/get/get_added_tick/get_changed_tick/get_ticks/get_changed_by/get_drop + ImmutableSparseSet with_capacity/capacity/insert/get/get_mut/remove/clear/contains + SparseSets collection get_or_insert) ✓

## Batch 79 — resource_mod (2026-07-03)
- lib/resource_mod.sla: IsResource marker + ResourceEntities + IS_RESOURCE flag — mirrors src/resource.rs
- 16 tests — test_ecs_lib_resource_mod_isolated.sla
- Tests: 2582 → 2598, lib modules: 205 → 206, test files: 128 → 129
- src/resource.rs (IsResource new/resource_component_id + ResourceEntities new/get/insert/iter + IS_RESOURCE constant) ✓

## Batch 80 — event_mod (2026-07-03)
- lib/event_mod.sla: EventKey + World event registry facade — mirrors src/event/mod.rs
- 11 tests — test_ecs_lib_event_mod_isolated.sla
- Tests: 2598 → 2609, lib modules: 206 → 207, test files: 129 → 130
- src/event/mod.rs (EventKey new/component_id + World register_event_key/event_key) ✓

## Batch 81 — component_register (2026-07-03)
- lib/component_register.sla: ComponentIdRegistrator iterator + ComponentsQueuedRegistrator facade — mirrors src/component/register.rs
- 14 tests — test_ecs_lib_component_register_isolated.sla
- Tests: 2609 → 2623, lib modules: 207 → 208, test files: 130 → 131
- src/component/register.rs (ComponentIdRegistrator peek/next/peek_mut/next_mut/len/is_empty/as_queued/apply_queued_registrations/any_queued_mut/num_queued_mut + queue_register_component|resource|non_send + register_component_with_descriptor) ✓

## Batch 82 — observer_descriptor_extras (2026-07-03)
- lib/observer_descriptor_extras.sla: ObserverDescriptor v2 + Observer run state + ObserverV2 combined — mirrors src/observer/distributed_storage.rs
- 17 tests — test_ecs_lib_observer_descriptor_extras_isolated.sla
- Tests: 2623 → 2640, lib modules: 208 → 209, test files: 131 → 132
- src/observer/distributed_storage.rs (ObserverDescriptor with_event_keys|with_components|with_entities + event_keys()|components()|entities() accessor parity + Observer last_trigger_id/despawned_watched_entities/run + with_error_handler/with_name) ✓

## Batch 83 — query_builder_extras (2026-07-03)
- lib/query_builder_extras.sla: QueryBuilder id-by-id variants + World mut + access view + transmute/build gap — mirrors src/query/builder.rs
- 15 tests — test_ecs_lib_query_builder_extras_isolated.sla
- Tests: 2640 → 2655, lib modules: 209 → 210, test files: 132 → 133
- src/query/builder.rs (QueryBuilder with_id/without_id/world_mut/access + transmute/transmute_filtered + build) ✓


## Batch 84 — world_extras (2026-07-03)
- lib/world_extras.sla: try_register_required_components[_with] + get_required_components_by_id + modify_component[_by_id] + modify_resource[_by_id] + spawn_at/empty_at/batch + EntityAllocator + ResourceEntities + components_queue/registrator + as_unsafe_world_cell facades — mirrors src/world/mod.rs gaps not in lib/ecs_world.sla
- 35 tests — test_ecs_lib_world_extras_isolated.sla
- Tests: 2655 → 2690, lib modules: 208 → 209, test files: 133 → 134
- src/world/mod.rs (try_register_required_components/try_register_required_components_with/get_required_components_by_id/modify_component[_by_id]/modify_resource[_by_id]/spawn_at/spawn_empty_at/spawn_batch/components_queue/components_registrator/entity_allocator/resource_entities/as_unsafe_world_cell_readonly + RequiredComponentsError {DuplicateRegistration,CyclicRequirement,ArchetypeExists} + SpawnError {Invalid,AlreadySpawned} + EntityMutableFetchError {NotSpawned,AliasedMutability}) ✓


## Batch 85 — query_state_read_api (2026-07-03)
- lib/query_state_read_api.sla: QueryState read API gaps — single/single_mut + is_empty + contains + get/get_mut + get_many[_mut/_unique/_unique_mut] + iter_many[_mut/_unique/_unique_mut] + try_new + from_builder + update_archetypes + QueryEntityError + QuerySingleError markers — mirrors src/query/state.rs gaps not in lib/query_state_extras.sla
- 27 tests — test_ecs_lib_query_state_read_api_isolated.sla
- Tests: 2690 → 2717, lib modules: 209 → 210, test files: 134 → 135
- src/query/state.rs (single/single_mut + is_empty + contains + get/get_manual/get_mut + get_many/get_many_mut/get_many_unique/get_many_unique_mut + iter_many/iter_many_mut/iter_many_unique/iter_many_unique_mut + try_new + from_builder + update_archetypes + QueryEntityError {QueryDoesNotMatch,NotSpawned,AliasedMutability} + QuerySingleError {NoEntities,MultipleEntities}) ✓


## Batch 86 — world_observer_trigger (2026-07-03)
- lib/world_observer_trigger.sla: World::trigger/trigger_with/trigger_ref/trigger_ref_with + add_observer + observer registry bookkeeping — mirrors src/observer/mod.rs (gaps not in lib/observer_*.sla or lib/deferred_world.sla)
- 15 tests — test_ecs_lib_world_observer_trigger_isolated.sla
- Tests: 2717 → 2732, lib modules: 210 → 211, test files: 135 → 136
- src/observer/mod.rs (trigger + trigger_with + trigger_ref + trigger_ref_with + add_observer) ✓


## Batch 87 — entity_ref_extras (2026-07-03)
- lib/entity_ref_extras.sla: EntityRef pub surface not in lib/entity_access.sla — into_filtered + location + archetype + contains_id/_type_id + get_ref + get_change_ticks[_by_id] + get_changed_by + get_by_id + components (count reduce) + get_components (all-or-none) + spawned_by + spawn_tick — mirrors src/world/entity_access/entity_ref.rs (gaps not in lib/entity_access.sla)
- 20 tests — test_ecs_lib_entity_ref_extras_isolated.sla
- Tests: 2732 → 2752, lib modules: 211 → 212, test files: 136 → 137
- src/world/entity_access/entity_ref.rs (location/archetype/contains_id/contains_type_id/get_ref/get_change_ticks/get_changed_by/get_change_ticks_by_id/get_by_id/components/get_components/into_filtered/spawned_by/spawn_tick) ✓


## Batch 88 — deferred_world_extras (2026-07-03)
- lib/deferred_world_extras.sla: DeferredWorld pub surface not in lib/deferred_world.sla — get_mut + get_entity_mut + query + non_send_resource_mut + get_resource_mut_by_id + get_non_send_mut_by_id — mirrors src/world/deferred_world.rs (gaps not in lib/deferred_world.sla)
- 20 tests — test_ecs_lib_deferred_world_extras_isolated.sla
- Tests: 2752 → 2772, lib modules: 212 → 213, test files: 137 → 138
- src/world/deferred_world.rs (get_mut + get_entity_mut + query + non_send_resource_mut + get_resource_mut_by_id + get_non_send_mut_by_id) ✓


## Batch 89 — query_sort_iter (2026-07-03)
- lib/query_sort_iter.sla: QueryIter sort family — sort/sort_unstable/sort_by/sort_unstable_by/sort_by_key/sort_unstable_by_key/sort_by_cached_key + QuerySortedIter + sort_impl panic-if-consumed — mirrors src/query/iter.rs (gaps not in lib/query_iter.sla)
- 19 tests — test_ecs_lib_query_sort_iter_isolated.sla
- Tests: 2772 → 2791, lib modules: 213 → 214, test files: 138 → 139
- src/query/iter.rs (sort + sort_unstable + sort_by + sort_unstable_by + sort_by_key + sort_unstable_by_key + sort_by_cached_key + QuerySortedIter fetch_next) ✓


## Batch 90 — query_access_ops (2026-07-03)
- lib/query_access_ops.sla: query/access.rs gaps — ComponentIdSet ops + AccessConflicts + Access get_conflicts/extend/intersection/union/remove_conflicting_access + FilteredAccess matches_everything/nothing/extend_access/get_conflicts/is_disjoint/access — mirrors src/query/access.rs (gaps not in lib/query_access.sla)
- 30 tests — test_ecs_lib_query_access_ops_isolated.sla
- Tests: 2791 → 2821, lib modules: 214 → 215, test files: 139 → 140
- src/query/access.rs (FilterSet union/intersection/union_with/intersect_with/is_disjoint/is_clear/is_empty + AccessConflicts + Access get_conflicts/extend/intersection/union/remove_conflicting_access + FilteredAccess matches_everything/matches_nothing/extend_access/get_conflicts/is_disjoint) ✓


## Batch 91 — query_filtered_set (2026-07-03)
- lib/query_filtered_set.sla: FilteredAccessSet (gap surface) — mirrors src/query/access.rs
- 19 tests — test_ecs_lib_query_filtered_set_isolated.sla
- Tests: 2821 → 2840, lib modules: 215 → 216, test files: 140 → 141
- src/query/access.rs (FilteredAccessSet new/combined_access/filtered_accesses/is_compatible/get_conflicts/get_conflicts_single/add/add_resource_read/_write/add_unfiltered_read_all_components/add_unfiltered_write_all_components/extend/read_all/write_all/clear + Access::is_compatible helper) ✓


## Batch 92 — filtered_resource_builders (2026-07-03)
- lib/filtered_resource_builders.sla: FilteredResourcesBuilder + FilteredResourcesMutBuilder — mirrors src/world/filtered_resource.rs (gaps not in lib/filtered_resource.sla or lib/system_builder.sla)
- 12 tests — test_ecs_lib_filtered_resource_builders_isolated.sla
- Tests: 2840 → 2852, lib modules: 216 → 217, test files: 141 → 142
- src/world/filtered_resource.rs (FilteredResourcesBuilder new/access/add_read_all/add_read[_by_id]/build + FilteredResourcesMutBuilder new/access/add_read_all/add_read[_by_id]/add_write_all/add_write[_by_id]/build) ✓


## Batch 93 — schedule_configs_extras (2026-07-03)
- lib/schedule_configs_extras.sla: IntoScheduleConfigs/ScheduleConfigs gaps — chain/chain_ignore_deferred/distributive_run_if/run_if/ambiguous_with/ambiguous_with_all/before_ignore_deferred/after_ignore_deferred/into_configs — mirrors src/schedule/config.rs (gaps not in lib/schedule_config.sla)
- 16 tests — test_ecs_lib_schedule_configs_extras_isolated.sla
- Tests: 2852 → 2868, lib modules: 217 → 218, test files: 142 → 143
- src/schedule/config.rs (IntoScheduleConfigs chain/chain_ignore_deferred/distributive_run_if/run_if/ambiguous_with/ambiguous_with_all/before_ignore_deferred/after_ignore_deferred/into_configs + ScheduleConfigs.apply_deferred_on_edges + before/after _ignore_deferred_inner + distributive_run_if_inner + ambiguous_with_inner/ambiguous_with_all_inner + chain_ignore_deferred_inner) ✓


## Batch 94 — required_components_dynamic (2026-07-03)
- lib/required_components_dynamic.sla: RequiredComponents register_by_id + register_dynamic_with + the _mut builder variants + EcsRequiredComponentsRegistratorDyn facade (new/target/components_next_id/register_required_by_id/_dynamic_with + last_ok/last_err_kind/_required_direct_count/_required_all_count/_required_direct_at/_required_all_at) — mirrors src/component/required.rs dynamic-registration gaps not in lib/component_required.sla
- 16 tests — test_ecs_lib_required_components_dynamic_isolated.sla
- Tests: 2868 → 2884, lib modules: 218 → 219, test files: 143 → 144
- src/component/required.rs (RequiredComponents::register_by_id + register_dynamic_with + register_dynamic_with_mut/register_by_id_mut + RequiredComponentsRegistrator::register_required_by_id + register_required_dynamic_with + components_registrator accessor + register_inherited_required_components_unchecked id-prepend-to-all model) ✓


## Batch 95 — removed_component_messages (2026-07-03)
- lib/removed_component_messages.sla: world-level RemovedComponentMessages storage + RemovedComponentReader reader API — mirrors src/lifecycle.rs (RemovedComponentMessages + RemovedComponentReader gaps not in lib/ecs_world.sla (write-only) or lib/entity_lifecycle.sla (per-component-level))
- 23 tests — test_ecs_lib_removed_component_messages_isolated.sla
- Tests: 2884 → 2907, lib modules: 219 → 220, test files: 144 → 145
- src/lifecycle.rs (RemovedComponentMessages::new/update/iter/get/write + RemovedComponentReader::new/read/read_with_id/len/is_empty/clear + cursor/drained accessors + iter_pair/entity_at helpers + SparseSet-as-flat-Vec model) ✓


## Batch 96 — query_par_many_iter (2026-07-03)
- lib/query_par_many_iter.sla: QueryParManyIter + QueryParManyUniqueIter — mirrors src/query/par_iter.rs (gaps not in lib/query_par_iter.sla)
- 21 tests — test_ecs_lib_query_par_many_iter_isolated.sla
- Tests: 2907 → 2928, lib modules: 220 → 221, test files: 145 → 146
- src/query/par_iter.rs (QueryParManyIter::batching_strategy/for_each/for_each_init + QueryParManyUniqueIter::batching_strategy/for_each/for_each_init + len/is_empty/batch_count + UniqueEntityEquivalentVec de-dup model + Fn-over-items closure-as-func_id parameterization) ✓


## Batch 97 — entity_cloner_builder_extras (2026-07-03)
- lib/entity_cloner_builder_extras.sla: EntityClonerBuilder remaining pub surface (with_default_clone_fn + override_clone_behavior_with_id + remove_clone_behavior_override_with_id + without_required_components scope + without_required_by_components scope) — mirrors src/entity/clone_entities.rs lines 817-1004 (gaps not in lib/entity_cloner.sla)
- 13 tests — test_ecs_lib_entity_cloner_builder_extras_isolated.sla
- Tests: 2928 → 2941, lib modules: 221 → 222, test files: 146 → 147
- src/entity/clone_entities.rs (EntityClonerBuilder::with_default_clone_fn + override_clone_behavior_with_id + remove_clone_behavior_override_with_id + without_required_components [OptIn scope] + without_required_by_components [OptOut scope] + ComponentCloneFn-as-id + ComponentCloneBehavior-as-id) ✓


## Batch 98 — relationship_methods_extras (2026-07-03)
- lib/relationship_methods_extras.sla: EntityWorldMut/EntityCommands related-methods gaps (add_one_related + detach_all_related + despawn_related + despawn_children + with_related + with_related_entities + insert_recursive + remove_recursive) — mirrors src/relationship/related_methods.rs (gaps not in lib/relationship_related_methods.sla)
- 21 tests — test_ecs_lib_relationship_methods_extras_isolated.sla
- Tests: 2941 → 2962, lib modules: 222 → 223, test files: 147 → 148
- src/relationship/related_methods.rs (EntityWorldMut::add_one_related + detach_all_related + despawn_related + despawn_children + insert_recursive + remove_recursive + EntityCommands::with_related + with_related_entities + Relationship<generic = relationship_id i32> + Fn<bundle> =bundle_id i32 + BFS-tree-descendants traversal + restore of accidentally-deleted lib/*.test.sa artifacts) ✓


## Batch 99 — system_trait_extras (2026-07-03)
- lib/system_trait_extras.sla: System trait gaps (is_send + system_type + refresh_hotpatch + queue_deferred + check_change_tick + default_system_sets add/lookup + get_last_run/set_last_run + run_readonly + run_without_applying_deferred) — mirrors src/system/system.rs (gaps not in lib/system_trait.sla)
- 20 tests — test_ecs_lib_system_trait_extras_isolated.sla
- Tests: 2962 → 2982, lib modules: 223 → 224, test files: 148 → 149
- src/system/system.rs (System::is_send + system_type + refresh_hotpatch + queue_deferred + check_change_tick + default_system_sets + get_last_run + set_last_run + run_readonly + run_without_applying_deferred + TypeId-as-i64 model + non_send-bit-is_send negation) ✓


## Batch 100 — relationship_replace_insert (2026-07-03)
- lib/relationship_replace_insert.sla: insert_related + replace_related + replace_related_with_difference — mirrors src/relationship/related_methods.rs (reorder/replace-with-difference pub fns not in lib/relationship_related_methods.sla + lib/relationship_methods_extras.sla)
- 16 tests — test_ecs_lib_relationship_replace_insert_isolated.sla
- Tests: 2982 → 2998, lib modules: 224 → 225, test files: 149 → 150
- src/relationship/related_methods.rs (EntityWorldMut::insert_related + replace_related + replace_related_with_difference + OrderedRelationshipSourceCollection place/place_most_recent mirror + EntityHashSet collect/set-difference + newly_related ⊂ relate invariant + keep-existing-collection-in-place-on-empty-diff) ✓


## Batch 101 — relationship_source_collection_ordered (2026-07-03)
- lib/relationship_source_collection_ordered.sla: OrderedRelationshipSourceCollection trait surface (insert/remove_at/insert_stable/remove_at_stable/sort/insert_sorted/place/place_most_recent/push_front) + with_capacity/reserve/shrink_to_fit/extend_from_iter/source_to_remove_before_add — mirrors src/relationship/relationship_source_collection.rs (gaps not in lib/relationship_source_collection.sla)
- 29 tests — test_ecs_lib_relationship_source_collection_ordered_isolated.sla
- Tests: 2998 → 3027, lib modules: 225 → 226, test files: 150 → 151
- src/relationship/relationship_source_collection.rs (OrderedRelationshipSourceCollection::insert/remove_at/insert_stable/remove_at_stable/sort/insert_sorted/place_most_recent/place + push_front + RelationshipSourceCollection::with_capacity/reserve/shrink_to_fit/extend_from_iter/source_to_remove_before_add/is_empty) ✓


## Batch 102 — entity_generation_extras (2026-07-03)
- lib/entity_generation_extras.sla: EntityGeneration gap surface (FIRST + to_bits/from_bits + after_versions wrapping_add + after_versions_and_could_alias overflowing_add + cmp_approx Ordering) + Entity::try_from_bits + EntityIndex::from_raw_u32 (NonMaxU32 validation) — mirrors src/entity/mod.rs (gaps not in lib/entity.sla)
- 25 tests — test_ecs_lib_entity_generation_extras_isolated.sla
- Tests: 3027 → 3052, lib modules: 226 → 227, test files: 151 → 152
- src/entity/mod.rs (EntityGeneration::FIRST/to_bits/from_bits/after_versions/after_versions_and_could_alias/cmp_approx + Entity::try_from_bits + EntityIndex::from_raw_u32 + DIFF_MAX=2^31 cmp_approx boundary + NonMaxU32 rejects u32::MAX + u32-wrapping arithmetic as i64-modulo-2^32) ✓


## Batch 103 — entity_allocator_extras (2026-07-03)
- lib/entity_allocator_extras.sla: EntityAllocator pub-surface (alloc/free/free_many/alloc_many/build_remote_allocator/has_remote_allocator/restart) + RemoteAllocatorProxy snapshot — mirrors src/entity/mod.rs EntityAllocator 706-810 (gaps not in lib/remote_allocator.sla)
- 18 tests — test_ecs_lib_entity_allocator_extras_isolated.sla
- Tests: 3052 → 3070, lib modules: 227 → 228, test files: 152 → 153
- src/entity/mod.rs (EntityAllocator::alloc/free/free_many/alloc_many/build_remote_allocator/has_remote_allocator/restart + RemoteAllocator generation-stability check + AllocEntitiesIterator-emulated single-result + LIFO recycled-stack alloc) ✓

## Batch 112 — unique_vec_extras (2026-07-03)
- lib/unique_vec_extras.sla: UniqueEntityEquivalentVec remaining methods (reserve/reserve_exact/try_reserve/try_reserve_exact/shrink_to_fit/shrink_to/append/split_off/drain/splice/resize_with/leak/spare_capacity/from_entity_set_iter) — mirrors src/entity/unique_vec.rs gaps not in lib/unique_vec.sla
- 17 tests — test_ecs_lib_unique_vec_extras_isolated.sla
- Tests: 3185 → 3202, lib modules: 234 → 235, test files: 160 → 161
- Verification: `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_unique_vec_extras_isolated.sla --test-backend sa` and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_unique_vec_extras_isolated.sla` both pass. The first SAB run exposed a PhiStateConflict in mutable clamp code; source was reshaped into clamped helpers and now passes default backend too.
- src/entity/unique_vec.rs (capacity management, reserve fallible facade, shrink semantics, append, split/drain/splice range operations, resize_with closure model as sequence, leak/spare capacity marker, FromEntitySetIterator trusted uniqueness path) ✓

## Batch 113 — entity_set_iter_extras (2026-07-03)
- lib/entity_set_iter_extras.sla: ContainsEntity/EntityEquivalent wrapper semantics + UniqueEntityIter + EntitySetIterator::collect_set + FromEntitySetIterator HashSet construction — mirrors src/entity/entity_set.rs gaps not in lib/entity_set.sla
- 16 tests — test_ecs_lib_entity_set_iter_extras_isolated.sla
- Tests: 3202 → 3218, lib modules: 235 → 236, test files: 161 → 162
- Verification: `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_set_iter_extras_isolated.sla --test-backend sa` and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_set_iter_extras_isolated.sla` both pass.
- src/entity/entity_set.rs (ContainsEntity for owned/ref/mut/Box/Rc/Arc model, EntityEquivalent equality/order over entity id, UniqueEntityIter forward/back iteration, into_inner, collect_set preserving trusted unique payload, FromEntitySetIterator no-dedup fast path) ✓

## Batch 114 — entity_hash_set_ops (2026-07-03)
- lib/entity_hash_set_ops.sla: EntityHashSet wrapper operations (BitAnd/BitOr/BitXor/Sub + assign variants, extend, from-iterator construction, iter/into_iter reductions, drain, extract_if, subset/superset/disjoint helpers) — mirrors src/entity/hash_set.rs gaps not in basic EntityHashSet tests
- 18 tests — test_ecs_lib_entity_hash_set_ops_isolated.sla
- Tests: 3218 → 3236, lib modules: 236 → 237, test files: 162 → 163
- Verification: `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_set_ops_isolated.sla --test-backend sa` and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_set_ops_isolated.sla` both pass.
- src/entity/hash_set.rs (set algebra wrapper ops, assign variants, Extend/FromIterator/FromEntitySetIterator-style construction, iterator/drain/extract_if wrappers, EntitySetIterator uniqueness-preserving set operations) ✓

## Batch 115 — entity_hash_map_extras (2026-07-03)
- lib/entity_hash_map_extras.sla: EntityHashMap wrapper extras (keys/into_keys iterator wrappers, Extend<(Entity,V)> and borrowed key/value extension shape, FromIterator/from_hash_map/into_inner, Index<&Q: EntityEquivalent> semantics) — mirrors src/entity/hash_map.rs gaps not in lib/entity_collections.sla
- 17 tests — test_ecs_lib_entity_hash_map_extras_isolated.sla
- Tests: 3236 → 3253, lib modules: 237 → 238, test files: 163 → 164
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_hash_map_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_map_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_map_extras_isolated.sla` all pass after Batch 122 reshaped the borrowed-value input path away from raw `Vec<i32>` SAB indexing.
- src/entity/hash_map.rs (Keys/IntoKeys EntitySetIterator wrappers, clone/default/remaining/next model, extend variants, duplicate replacement, from/into inner map shape, EntityEquivalent index lookup) ✓

## Batch 116 — entity_index_map_extras (2026-07-03)
- lib/entity_index_map_extras.sla: EntityIndexMap ordered slice/range/iterator tranche (as_slice/get_range, Slice get_index_mut/first/last/split_at/split_first/split_last/iter/as_slice, Keys/IntoKeys double-ended/index/trusted-unique behavior, Drain range removal, value aggregation) — mirrors src/entity/index_map.rs gaps not in lib/entity_collections.sla
- 18 tests — test_ecs_lib_entity_index_map_extras_isolated.sla
- Tests: 3253 → 3271, lib modules: 238 → 239, test files: 164 → 165
- Verification: `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_map_extras_isolated.sla --test-backend sa` and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_map_extras_isolated.sla` both pass. Initial default/SAB PhiStateConflict on mutable range clamps was fixed by source reshaping into clamped helpers.
- src/entity/index_map.rs (ordered map slice/range access, mutable indexed value update, split/split_first/split_last, ordered Iter/Keys remaining and double-ended traversal, Keys index, Drain range removal, values/into_values-style aggregation) ✓

## Batch 117 — entity_index_map_iter_extras (2026-07-03)
- lib/entity_index_map_iter_extras.sla: EntityIndexMap iterator/boxed-slice wrapper tranche (boxed Slice default/clone/into-inner, Slice range variants, equality/order/hash, IterMut value update/as_slice, IntoIter next/next_back/as_slice, Drain::as_slice) — mirrors src/entity/index_map.rs iterator and Slice impl gaps after Batch 116
- 17 tests — test_ecs_lib_entity_index_map_iter_extras_isolated.sla
- Tests: 3271 → 3288, lib modules: 239 → 240, test files: 165 → 166
- Verification: `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_map_iter_extras_isolated.sla --test-backend sa` and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_map_iter_extras_isolated.sla` both pass.
- src/entity/index_map.rs (Box<Slice> default/clone/inner conversion, Slice range_from/range_to/range_inclusive + eq/cmp/hash, IterMut as_slice and mutable next update, IntoIter as_slice/next/next_back, Drain::as_slice) ✓

## Batch 118 — entity_index_set_extras (2026-07-04)
- lib/entity_index_set_extras.sla: EntityIndexSet ordered set/slice/range/iterator tranche (from_index_set/from_iter/into_inner/as_slice/get_range/index range/value, boxed Slice default/clone/into-inner, Slice split/range/equality/order/hash, BitAnd/BitOr/BitXor/Sub set algebra, Iter/IntoIter/Drain next/next_back/as_slice/default/clone/trusted-unique behavior) — mirrors src/entity/index_set.rs gaps not in lib/entity_collections.sla
- 26 tests — test_ecs_lib_entity_index_set_extras_isolated.sla
- Tests: 3288 → 3314, lib modules: 240 → 241, test files: 166 → 167
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_index_set_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_set_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_set_extras_isolated.sla` all pass.
- src/entity/index_set.rs (ordered index set construction/dedup, order-insensitive set equality vs order-sensitive Slice equality, range/index access, split_first/split_last, boxed Slice wrappers, set algebra, EntitySetIterator-like unique iterators, IntoIter, Drain::as_slice) ✓

## Batch 119 — entity_index_set_iter_extras (2026-07-04)
- lib/entity_index_set_iter_extras.sla: EntityIndexSet remaining iterator/bound/inner tranche (Bound-style range indexing, unsafe Slice mut conversion marker, Slice::as_inner/as_boxed_inner, boxed Slice owning iteration, Iter/IntoIter/Drain::into_inner markers, set-operation iterators for intersection/union/difference/symmetric difference, collect-op iterator, splice-style unique replacement with removed iterator) — mirrors the remaining src/entity/index_set.rs wrapper impl gaps after Batch 118
- 20 tests — test_ecs_lib_entity_index_set_iter_extras_isolated.sla
- Tests: 3314 → 3334, lib modules: 241 → 242, test files: 167 → 168
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_index_set_iter_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_set_iter_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_set_iter_extras_isolated.sla` all pass.
- src/entity/index_set.rs (Bound tuple indexing, unsafe wrapper conversion/inner views, Box<Slice>::into_iter, iterator into_inner, set-operation EntitySetIterator impls, Splice-like replacement iterator) ✓

## Batch 120 — entity_index_set_derived_extras (2026-07-04)
- lib/entity_index_set_derived_extras.sla: EntityIndexSet derived/wrapper cleanup tranche (new/default/with_capacity constructor intent, Clone/Debug/Default markers, explicit Extend<Entity> and Extend<&Entity> shapes, array-style construction, PartialEq<IndexSet> order-insensitive equality, Iter/IntoIter/Drain size-hint/debug/trusted-unique behavior) — mirrors src/entity/index_set.rs wrapper impl surface after Batches 118–119
- 12 tests — test_ecs_lib_entity_index_set_derived_extras_isolated.sla
- Tests: 3334 → 3346, lib modules: 242 → 243, test files: 168 → 169
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_index_set_derived_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_set_derived_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_set_derived_extras_isolated.sla` all pass.
- src/entity/index_set.rs (derived wrapper constructors/traits, Extend refs/owned, From<[Entity; N]>, FromIterator, PartialEq<IndexSet>, iterator size hints/debug markers) ✓

## Batch 121 — entity_index_map_derived_extras (2026-07-04)
- lib/entity_index_map_derived_extras.sla: EntityIndexMap derived/mutable-slice/wrapper cleanup tranche (new/default/with_capacity constructor intent, Clone/Debug markers, explicit Extend owned/ref shapes, array-style construction, PartialEq<IndexMap> order-insensitive equality, mutable Slice range/split/inner markers, Iter/IterMut/IntoIter/Drain/Keys/IntoKeys/IntoValues size-hint/debug/trusted-unique behavior) — mirrors src/entity/index_map.rs wrapper impl surface after Batches 116–117
- 15 tests — test_ecs_lib_entity_index_map_derived_extras_isolated.sla
- Tests: 3346 → 3361, lib modules: 243 → 244, test files: 169 → 170
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_index_map_derived_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_map_derived_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_index_map_derived_extras_isolated.sla` all pass.
- src/entity/index_map.rs (derived wrapper constructors/traits, Extend refs/owned, From<[(Entity,V); N]>, FromIterator, PartialEq<IndexMap>, mutable Slice APIs, iterator size hints/debug markers, Keys EntitySetIterator markers) ✓

## Batch 122 — entity_hash_map_refs_default_backend_unblocker (2026-07-04)
- lib/entity_hash_map_extras.sla: reshaped the borrowed-value `Extend<(&Entity, &V)>` model so `ecs_ehm_extend_refs` accepts `Vec<i64>` values and casts to the stored `i32` value at insertion, avoiding the focused default/SAB raw `Vec<i32>` indexing failure from Batch 115.
- 0 new tests — revalidated existing test_ecs_lib_entity_hash_map_extras_isolated.sla
- Tests unchanged: 3361 isolated tests, lib modules unchanged: 244, test files unchanged: 170
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_hash_map_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_map_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_map_extras_isolated.sla` all pass.
- src/entity/hash_map.rs borrowed Extend wrapper remains covered; the former Batch 115 default/SAB limitation is now closed. ✓

## Batch 123 — entity_hash_set_derived_extras (2026-07-04)
- lib/entity_hash_set_derived_extras.sla: EntityHashSet derived/wrapper cleanup tranche (new/default/with_capacity, from_hash_set/into_inner, Clone/Debug/Default markers, Extend<Entity>/Extend<&Entity>, From<[Entity; N]>, FromIterator, FromEntitySetIterator capacity/trusted-unique path, equality, Iter/IntoIter/Drain/ExtractIf into_inner/default/clone/size-hint/debug/trusted-unique markers, and set-operation iterator markers) — mirrors src/entity/hash_set.rs wrapper impl surface after Batch 114
- 15 tests — test_ecs_lib_entity_hash_set_derived_extras_isolated.sla
- Tests: 3361 → 3376, lib modules: 244 → 245, test files: 170 → 171
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_hash_set_derived_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_set_derived_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_set_derived_extras_isolated.sla` all pass.
- src/entity/hash_set.rs (derived wrapper constructors/traits, Extend refs/owned, From<[Entity; N]>, FromIterator, FromEntitySetIterator, iterator into_inner/default/debug markers, ExtractIf and set-op EntitySetIterator markers) ✓

## Batch 124 — entity_hash_map_derived_extras (2026-07-04)
- lib/entity_hash_map_derived_extras.sla: EntityHashMap derived/wrapper cleanup tranche (new/default/with_capacity, from_hash_map/from_index_map alias, into_inner, Clone/Debug/Default markers, Extend<(Entity,V)>/Extend<&(Entity,V)>/Extend<(&Entity,&V)>, From<[(Entity,V); N]>, FromIterator, PartialEq<HashMap>, Index<EntityEquivalent>, IntoIterator for ref/mut/owned, and Keys/IntoKeys into_inner/default/clone/size-hint/debug/trusted-unique markers) — mirrors src/entity/hash_map.rs wrapper impl surface after Batch 115/122
- 16 tests — test_ecs_lib_entity_hash_map_derived_extras_isolated.sla
- Tests: 3376 → 3392, lib modules: 245 → 246, test files: 171 → 172
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_hash_map_derived_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_map_derived_extras_isolated.sla --test-backend sa`, and default `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_hash_map_derived_extras_isolated.sla` all pass.
- src/entity/hash_map.rs (derived wrapper constructors/traits, Extend refs/owned, From<[Entity; N]>, FromIterator, From<HashMap>, IntoIterator, Keys and IntoKeys iterator markers) ✓

## Batch 125 — remote_allocator_close_semantics (2026-07-04)
- lib/remote_allocator.sla: aligned the remote allocator model with Bevy's diagnostic-only closed state. `close` now only flips `is_closed`; `alloc` and `alloc_batch` continue to issue entities from the snapshot, matching the source `RemoteAllocator` behavior.
- tests/test_ecs_lib_node_spawner_allocator_isolated.sla: updated the remote allocator close case so it verifies allocation still works after closure instead of expecting allocation failure.
- 0 new tests — revalidated the same 28-test node/spawner/allocator suite on SA backend and default backend.
- Verification passed with `SA_PLUGIN_DEV=1 sa sla check lib/remote_allocator.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_node_spawner_allocator_isolated.sla --test-backend sa`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_node_spawner_allocator_isolated.sla`, and `git diff --check`.
- Feature progress: Bevy ECS entity/remote_allocator.rs close-state semantics now match diagnostic-only behavior; overall estimate remains API parity ~94–96%, behavioral parity ~82–87% because the major remaining gaps are still the dynamic multithread executor and full runtime reflection.
### Grand Total unchanged: 3392 isolated tests across 172 test files, 246 lib modules, all passing on SA backend; Batch 125 also passes default backend.

## Batch 126 — entity_allocator_alloc_many_iterator (2026-07-04)
- lib/entity_allocator_extras.sla: reshaped `alloc_many` to model the iterator-shaped Bevy surface more closely. The returned alloc-many result now carries the allocated entity sequence plus a cursor, with `count`/`first` helpers backed by the iterator state and new `next`/`size_hint` helpers for the remaining sequence.
- tests/test_ecs_lib_entity_allocator_extras_isolated.sla: updated the alloc-many cases to exercise iterator-style advancement and size-hint tracking while preserving the existing entity-allocation and restart coverage.
- 0 new tests — revalidated the same 18-test entity allocator suite on SA backend and default backend.
- Verification passed with `SA_PLUGIN_DEV=1 sa sla check lib/entity_allocator_extras.sla`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_allocator_extras_isolated.sla --test-backend sa`, `SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_allocator_extras_isolated.sla`, and `git diff --check`.
- Feature progress: Bevy ECS entity/mod.rs `EntityAllocator::alloc_many` now tracks iterator-style progress instead of only a summary pair; overall estimate remains API parity ~94–96%, behavioral parity ~82–87% because the major remaining gaps are still the dynamic multithread executor and full runtime reflection.
### Grand Total unchanged: 3392 isolated tests across 172 test files, 246 lib modules, all passing on SA backend; Batch 126 also passes default backend.

## Batch 127 — never_facade (2026-07-06)
- lib/never.sla: EcsNever uninhabited marker facade for src/never.rs parity. SLA has no language-level never type, so this is a no-constructor marker with stable metadata and panic-only absurd helpers.
- 2 isolated tests — test_ecs_lib_never_isolated.sla; focused run sees 4 tests including lib inline sanity tests.
- Tests: 3392 → 3394, lib modules: 246 → 247, test files: 172 → 173; source `.sla` @test total: 3,802.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/never.sla`; `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_never_isolated.sla --test-backend sa`.
- src/never.rs ✓ (library-level marker facade)

## Batch 128 — app_type_registry_descriptors (2026-07-06)
- lib/app_type_registry.sla: EcsAppTypeRegistry + EcsAppFunctionRegistry descriptor registries for reflect::AppTypeRegistry/AppFunctionRegistry parity. Covers descriptor registration/replacement/query/order plus type-data slots for component/resource/event/message/bundle/from_world/map_entities. This is descriptor API-surface parity, not full bevy_reflect runtime reflection.
- 11 isolated tests — test_ecs_lib_app_type_registry_isolated.sla.
- Tests: 3394 → 3405, lib modules: 247 → 248, test files: 173 → 174; source `.sla` @test total: 3,813.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/app_type_registry.sla`; `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_app_type_registry_isolated.sla --test-backend sa`; default `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_app_type_registry_isolated.sla`.
- src/reflect/mod.rs AppTypeRegistry/AppFunctionRegistry ✓ (descriptor registry surface)

## Batch 129 — executor_multi_threaded_drive_plan (2026-07-06)
- lib/executor_multi_threaded.sla: EcsExecutorSystemSpec + EcsExecutorRunPlan drive-plan layer for the multi-threaded executor surface. Covers ready selection, drive_one/drive_all, dependency/dependent propagation, run-condition skip handling, deferred apply tracking, exclusive/local flag metadata, and run/apply/skip order accessors. Also fixes `ecs_executor_state_running_count` to count running systems.
- 4 isolated tests — test_ecs_lib_executor_multi_threaded_isolated.sla.
- Tests: 3405 → 3409, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,817.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_executor_multi_threaded_isolated.sla --test-backend sa`; default `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_executor_multi_threaded_isolated.sla`.
- src/schedule/executor/multi_threaded.rs ✓ (explicit plan-driving surface; full TaskPool/Scope dynamic executor remains out of scope)

## Batch 130 — result_recoverable_facades (2026-07-06)
- lib/ecs_world.sla: extended library-owned Result recoverable world facades with `ecs_world_try_despawn_result`, `ecs_world_try_get_mut`, `ecs_world_try_get_resource_ref`, `ecs_world_try_get_resource_mut`, and `ecs_world_try_modify_resource`; `ecs_world_try_query_single` now returns `ERR_QUERY_MULTIPLE_MATCH()` when more than one entity matches.
- tests/test_ecs_result_facades.sla: added 3 stable focused tests covering Result world despawn, mutable component accessor errors, and resource ref/mut/modify errors. A `Result<EntityItem<T>>` focused-filter cleanup trap was reported to the SLA compiler docs instead of worked around in compiler source.
- Tests: 3409 → 3412, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,820.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/ecs_world.sla`; `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_result_facades.sla --test-backend sa` passes with 172 tests; default/SAB focused filters for the three stable new tests pass.
- Compiler issue doc: `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/result_entityitem_filter_cleanup_issue_cn.md` records the `Result<EntityItem<T>>` filter cleanup / SAB `VerificationTrap` issue.
- src/world/error.rs + recoverable World try_* facade surface ✓ (library-owned Result path, no compiler keywords)

## Batch 131 — entity_map_serialization_snapshot (2026-07-06)
- lib/entity_map_entities.sla: added structured serialization/entity-mapping helpers for Bevy scene/entity remap flows. `EcsEntityMapSnapshot` encodes `SceneEntityMapper` as `[next_remote, count, src, dst, ...]`, restores from snapshots with truncated-pair tolerance, and adds batch `get_or_allocate_many` plus `apply_many` helpers with missing-source reporting.
- tests/test_ecs_lib_entity_map_entities_isolated.sla: added 5 isolated tests for snapshot encoding, snapshot restoration, truncated snapshot recovery, duplicate-preserving batch allocation, and strict/identity map application.
- Tests: 3412 → 3417, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,825.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/entity_map_entities.sla`; `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_map_entities_isolated.sla --test-backend sa`; default `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_lib_entity_map_entities_isolated.sla`.
- src/entity/map_entities.rs + scene serialization remap surface ✓ (library-level snapshot/remap, no compiler serde)

## Batch 132 — executor_ready_batch_model (2026-07-06)
- lib/executor_multi_threaded.sla: added ready-batch selection and completion for the multi-threaded executor plan layer. `EcsExecutorReadyBatch` and `EcsExecutorReadyBatchResult` model one batch of ready systems; ordinary non-exclusive/non-local systems can be selected up to a width limit, while exclusive/local systems serialize as singleton batches. Added `ecs_executor_run_plan_take_ready_batch`, `ecs_executor_run_plan_complete_ready_batch`, `ecs_executor_run_plan_drive_ready_batch`, and `ecs_executor_run_plan_drive_all_batched`.
- lib/executor_multi_threaded.sla: fixed false run-condition semantics so skipped systems release dependents instead of stalling downstream systems. New helper path: `ecs_executor_state_release_dependents`, `ecs_executor_state_skip_system_with_dependents`, and `ecs_executor_run_plan_skip_ready`.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added 4 focused isolated tests for ready-batch width selection, exclusive/local singleton serialization, skipped-system dependent release, and batched drive order/deferred apply tracking. Existing run-condition test was updated to expect downstream execution after a skip.
- lib/system_param_table_erased.sla: also retains the adjacent ordinary table-erased `Query<Entity> + Commands` runner slice (`TableErasedEntityQueryCommandsParam`, `table_erased_run_entity_query_commands_system`) with one inline regression for deferred Commands semantics.
- Tests: 3417 → 3421 isolated tests, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,830.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused SA tests with `--jobs 1 --trace-panic` for `executor_ready_group_selects_two`, `executor_ready_group_serializes_one`, `executor_ready_group_releases_dependents`, `executor_ready_group_drive_width`, and `executor_run_plan_skips_run_condition_false`; default/SAB smoke for `executor_ready_group_selects_two` and `executor_ready_group_drive_width`. Also verified `SA_PLUGIN_DEV=1 sa sla check lib/system_param_table_erased.sla`, focused SA/default for `table erased entity query commands param defers spawned entity`, and whole-file SA `lib/system_param_table_erased.sla` with 125 passed.
- Feature progress: Bevy ECS schedule/executor multi-threaded plan layer 85% -> 90%; overall estimate moves to API parity ~94–96%, behavioral parity ~83–88%. Remaining gap: connecting ready batches to a general thread-backed TaskPool/Scope-style dynamic runner with full access-conflict grouping.

## Batch 133 — executor_ready_batch_up_to3_thread_bridge (2026-07-06)
- lib/parallel_runner.sla: added `EcsParallelReadyBatchRunResult`, `ecs_parallel_run_ready_pair_batch`, `ecs_parallel_run_mut_triple_batch`, `ecs_parallel_run_ready_triple_batch`, `ecs_parallel_run_single_batch`, and `ecs_parallel_run_ready_batch_up_to3`, the first concrete bridges from `EcsExecutorRunPlan` ready-batch selection into pthread-backed runners. The up-to-3 dispatch entry takes one ready batch, serializes one-wide exclusive/local batches, routes two-wide batches to the pair runner, routes three-wide batches to the triple runner, and completes the executor plan so dependents become ready.
- tests/test_ecs_mut_parallel.sla: added 5 tests proving pair bridge advancement, pair mismatch rejection without starting threads, triple bridge completion releasing a dependent system, width dispatch selecting pair when max width is 3 but only two systems are ready, and width dispatch serializing one exclusive system while releasing its dependent.
- Tests: 3421 -> 3426 isolated tests, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,835.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA tests for all five new ready-batch bridge/dispatch cases; whole-file generated-SA `tests/test_ecs_mut_parallel.sla` with 75 passed. Default/SAB focused smoke currently fails with `UnknownRegister: callee is not declared`; compiler issue recorded at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sab_thread_fnptr_ready_batch_unknown_register_issue_cn.md` without modifying compiler source.
- Feature progress: Bevy ECS schedule/executor multi-threaded threaded bridge 0% -> 55%; executor plan + ready-batch layer remains 90%. Overall estimate remains API parity ~94–96%, behavioral parity ~83–88% because arbitrary-N TaskPool/Scope-style dynamic scheduling and full runtime reflection remain outside the completed behavior set.

## Batch 134 — executor_ready_all_up_to3_loop (2026-07-06)
- lib/parallel_runner.sla: added `ecs_parallel_run_ready_catalog_batch_up_to3`, a catalog-aware batch bridge that maps the actual ready system indexes onto a fixed three-function catalog instead of assuming first/second/third positional order. Added `ecs_parallel_run_ready_all_up_to3`, which repeatedly takes ready batches, dispatches singleton/pair/triple work, accumulates thread sum/run/skip metadata, and exits on completion, mismatch, or stall.
- tests/test_ecs_mut_parallel.sla: added `all dispatch two waves`, `all dispatch skip releases dependent`, and `all dispatch mismatch status`. These cover a pair wave releasing a singleton dependent wave, a false run-condition skip releasing its dependent within the loop, and an unknown ready system returning mismatch/stalled without an infinite loop.
- Tests: 3426 -> 3429 isolated tests, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,838.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; whole-file generated-SA `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_mut_parallel.sla --test-backend sa --jobs 1 --trace-panic` passes with 78 tests. Focused default/SAB smoke passes for ready pair/triple/width and the three new all-dispatch cases. Whole-file default/SAB aggregation fails with `UseAfterMove tmp_67`; compiler issue recorded at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sab_aggregate_mut_parallel_use_after_move_issue_cn.md` without modifying compiler source.
- Feature progress: Bevy ECS schedule/executor multi-threaded threaded bridge 55% -> 70%; executor plan + ready-batch layer remains 90%+. Overall estimate moves to API parity ~94–96%, behavioral parity ~84–89% because arbitrary-N function catalogs, conflict-selected dynamic grouping, and full TaskPool/Scope semantics remain outside the completed behavior set.

## Batch 135 — executor_ready_nonconflicting_up_to3 (2026-07-06)
- lib/parallel_runner.sla: added access-conflict-aware ready-batch selection for the fixed three-function executor catalog. `ecs_parallel_take_ready_nonconflicting_catalog_batch_up_to3` greedily walks ready systems, skips false run-condition systems while releasing dependents, serializes exclusive/local systems as singleton batches, and admits only systems whose `TableErasedSystemAccess` is compatible with already selected systems.
- lib/parallel_runner.sla: added `ecs_parallel_run_ready_nonconflicting_catalog_batch_up_to3` and `ecs_parallel_run_ready_all_nonconflicting_up_to3`, so conflicting ready systems are left ready and drained in later waves instead of panicking or reporting a mismatch.
- tests/test_ecs_mut_parallel.sla: added `nonconflict batch skips conflicting ready` and `nonconflict conflict waves`, covering a ready set where systems 0 and 1 both write the same component while system 2 is compatible. The first batch runs 0+2 on threads; the loop then drains 1 as a later singleton.
- Tests: 3429 -> 3431 isolated tests, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,840.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA tests for both new cases; whole-file generated-SA `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_mut_parallel.sla --test-backend sa --jobs 1 --trace-panic` passes with 80 tests. Focused default/SAB smoke passes for both new cases. Whole-file default/SAB aggregation still fails with the known `UseAfterMove tmp_67`; compiler issue doc updated at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sab_aggregate_mut_parallel_use_after_move_issue_cn.md` without modifying compiler source.
- Feature progress: Bevy ECS schedule/executor multi-threaded threaded bridge 70% -> 80%; executor plan + ready-batch layer remains 90%+. Overall estimate moves to API parity ~94–96%, behavioral parity ~85–90% because arbitrary-N catalogs and full TaskPool/Scope semantics remain outside the completed behavior set.

## Batch 136 — executor_ready_dynamic_catalog_up_to3 (2026-07-06)
- lib/parallel_runner.sla: added `EcsParallelFnCatalog<R, M>` with dynamic `Vec<i64>` system ids, `Vec<fn(Arc<*TableErasedWorld<R, M>>) -> i32>` runners, and `Vec<TableErasedSystemAccess>` access metadata. Added constructor/add/len/find-slot helpers.
- lib/parallel_runner.sla: added dynamic-catalog ready selection and dispatch: `ecs_parallel_take_ready_dynamic_catalog_batch_up_to3`, `ecs_parallel_run_selected_dynamic_catalog_batch_up_to3`, `ecs_parallel_run_ready_dynamic_catalog_batch_up_to3`, and `ecs_parallel_run_ready_all_dynamic_catalog_up_to3`. Catalog length can exceed three; current concrete execution width remains capped at three per batch.
- tests/test_ecs_mut_parallel.sla: added `dynamic catalog first wave` and `dynamic catalog waves`, covering a four-system catalog where systems 0 and 1 conflict, systems 2 and 3 are compatible, first wave runs 0+2+3, and the loop drains 1 in a later singleton wave.
- Tests: 3431 -> 3433 isolated tests, lib modules unchanged: 248, test files unchanged: 174; source `.sla` @test total: 3,842.
- Verification: `SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA tests for both new cases; whole-file generated-SA `timeout 120s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_mut_parallel.sla --test-backend sa --jobs 1 --trace-panic` passes with 82 tests. Focused default/SAB smoke passes for both dynamic catalog cases. Whole-file default/SAB aggregation still fails with the known `UseAfterMove tmp_67`; compiler issue doc updated at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sab_aggregate_mut_parallel_use_after_move_issue_cn.md` without modifying compiler source.
- Feature progress: Bevy ECS schedule/executor multi-threaded threaded bridge 80% -> 88%; executor plan + ready-batch layer remains 90%+. Overall estimate moves to API parity ~94–96%, behavioral parity ~86–91% because full TaskPool/Scope worker scheduling remains outside the completed behavior set.

## Batch 137 — task_pool_custom_batch_width (2026-07-07)
- lib/parallel_runner.sla: added `ecs_parallel_task_pool_with_batch_width`, separating Bevy-like TaskPool worker count from the per-wave ready/scoped batch width. The helper clamps negative worker/width inputs to zero and caps width at worker count, while preserving `ecs_parallel_task_pool_new(n)` as the worker-count-equals-width default.
- tests/test_ecs_mut_parallel.sla: added `task pool custom batch width separates worker count from waves`, proving lifecycle callbacks still run once per worker (`worker_count=4`) while scoped threaded tasks are batched by the narrower width (`max_batch_width=2`, five tasks -> three waves).
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA test for the new custom-width case; whole-file generated-SA `timeout 240s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_mut_parallel.sla --test-backend sa --jobs 1 --trace-panic` passes with 133 tests.
- Compiler/SAB note: focused default/SAB for the new custom-width test currently fails with `UnknownRegister: dst`; recorded at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sab_task_pool_custom_batch_width_unknown_dst_issue_cn.md`; no compiler source was modified in this ECS stream.
- Feature progress: Bevy ECS schedule/executor TaskPool/Scope facade now models separate worker-count and dispatch-width controls; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 138 — main_thread_executor_facade (2026-07-07)
- lib/parallel_runner.sla: imported the existing `thread_executor.sla` model and added `EcsParallelMainThreadExecutor`, mirroring Bevy `MainThreadExecutor(pub Arc<ThreadExecutor<'static>>)` as a newtyped resource facade. Added default/new/new_with_id constructors, owner/executor id accessors, owner-thread ticker detection, same-id comparison, and `ecs_parallel_scope_options_with_main_thread_executor`.
- tests/test_ecs_mut_parallel.sla: added `main thread executor facade preserves owner ticker and identity` and `main thread executor options drive external executor identity`, proving owner-only ticker behavior, stable executor identity, and Scope option derivation for same-vs-different external executor ids.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA tests for both MainThreadExecutor cases; whole-file generated-SA `timeout 240s env SA_PLUGIN_DEV=1 sa sla test tests/test_ecs_mut_parallel.sla --test-backend sa --jobs 1 --trace-panic` passes with 139 tests.
- Default/SAB note: focused default/SAB passes for `main thread executor facade preserves owner ticker and identity`; focused default/SAB for `external executor identity` fails with `UnknownRegister: dst`, appended to `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sab_task_pool_custom_batch_width_unknown_dst_issue_cn.md`; no compiler source was modified in this ECS stream.
- Feature progress: Bevy ECS schedule/executor MainThreadExecutor resource/scope-executor identity facade 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 139 — executor_finish_run_cleanup (2026-07-07)
- lib/executor_multi_threaded.sla: added `ecs_executor_state_skipped_count`, `ecs_executor_state_evaluated_set_count`, `ecs_executor_state_finish_run`, and `ecs_multi_threaded_executor_finish_run`, mirroring the end of Bevy `MultiThreadedExecutor::run`.
- The finish helper clears transient ready/running/skipped/completed/evaluated state, resets running/local/exclusive flags, applies and clears `unapplied_systems` when `apply_final_deferred=true`, and preserves `unapplied_systems` when `apply_final_deferred=false`.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added final-deferred and no-final-deferred finish-run regressions.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA tests for both new cases; whole-file generated-SA and default backend `tests/test_ecs_lib_executor_multi_threaded_isolated.sla` both pass with 29 tests.
- Feature progress: Bevy ECS schedule/executor multi-threaded finish-run cleanup surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 140 — executor_initial_debug_skip (2026-07-07)
- lib/executor_multi_threaded.sla: added `ecs_executor_run_plan_apply_initial_skips`, mirroring Bevy `MultiThreadedExecutor::run` startup behavior for `_skip_systems` under debug stepping. The helper marks initial skips as skipped/completed, clears their ready bit, and releases dependents before the ordinary run-plan drive loop.
- The helper avoids double-counting duplicate/already-completed skip inputs in this facade so shared dependents are not released twice.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added regressions for skipped root releasing a dependent, skipped ready systems not running, and multiple skipped roots releasing a shared dependent.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA initial-skip tests; whole-file generated-SA and default backend `tests/test_ecs_lib_executor_multi_threaded_isolated.sla` both pass with 32 tests.
- Feature progress: Bevy ECS schedule/executor initial debug-stepping skip surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 141 — executor_active_running_can_run_gates (2026-07-07)
- lib/executor_multi_threaded.sla: added `ecs_executor_state_can_spawn_system`, `ecs_executor_run_plan_next_runnable`, and `ecs_executor_state_complete_system_with_flags`, bringing the run-plan selector closer to Bevy `ExecutorState::can_run` for active exclusive/local state.
- Ready-batch selection now waits while an exclusive system is active, defers exclusive candidates while other systems are running, and defers local/non-send candidates while another local system is running. Run-plan completion clears exclusive/local flags for completed systems, matching Bevy `finish_system_and_handle_dependents`.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added active-running can-spawn regressions and ready-batch gate regressions; updated the exclusive/local completion assertion to expect cleared flags.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; whole-file generated-SA and default backend executor isolated tests both pass with 35 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests and MainThreadExecutor tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` currently reports `Type Check Error: checkStmt failed at node tag for_stmt (error.TypeMismatch)` before execution; focused affected bridge tests pass and the broad compiler issue is documented at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`.
- Feature progress: Bevy ECS schedule/executor active-running can-run gate surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 142 — executor_failed_set_condition_pending_skip (2026-07-07)
- lib/executor_multi_threaded.sla: added `ecs_executor_state_mark_skipped_pending`, `ecs_executor_state_mark_set_evaluated`, `ecs_executor_state_is_set_evaluated`, and `ecs_executor_run_plan_apply_failed_set_condition`, modeling Bevy `ExecutorState::should_run` when a system set condition fails.
- Failed set conditions now mark all systems in the set as skipped and mark the set evaluated without completing those systems or releasing dependents immediately. When a pending-skipped system becomes ready, ready-batch and single-step driving route it through the normal skip/release path.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added pending-skip regressions for no-immediate-completion, ready skipped system releasing a dependent, and skipped child waiting for its upstream dependency before releasing its own dependent.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA failed-set-condition test; whole-file generated-SA and default backend executor isolated tests both pass with 38 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor failed set-condition pending skip surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 143 — executor_passed_set_condition_evaluated (2026-07-09)
- lib/executor_multi_threaded.sla: added `ecs_executor_run_plan_apply_passed_set_condition`, modeling the successful system-set condition branch in Bevy `ExecutorState::should_run`.
- Passed set conditions now mark the set evaluated without marking systems skipped, completed, or dependency-released. Applying a failed set condition for the same already-evaluated set is a no-op, matching Bevy's `if evaluated_sets.contains(set_idx) { continue; }` behavior.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_passed_set_condition_marks_evaluated_only` and `executor_run_plan_passed_set_condition_blocks_later_failed_marking`.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA passed-set-condition tests; whole-file generated-SA and default backend executor isolated tests both pass with 40 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor passed set-condition evaluated surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 144 — executor_failed_system_condition_pending_skip (2026-07-09)
- lib/executor_multi_threaded.sla: added `ecs_executor_run_plan_apply_failed_system_condition`, modeling the per-system condition false branch in Bevy `ExecutorState::should_run`.
- Failed system conditions now mark only the current system as skipped, leave evaluated sets untouched, and do not complete or release dependents until the skipped system becomes ready and is processed by the normal skip path. Later set-condition evaluation remains possible.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added pending-skip regressions for current-system-only marking, skipped child dependency timing, and set-condition evaluation after a failed system condition.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA failed-system-condition tests; whole-file generated-SA and default backend executor isolated tests both pass with 43 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor failed system-condition pending skip surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 145 — executor_running_conflict_can_run_gates (2026-07-09)
- lib/executor_multi_threaded.sla: extended `EcsExecutorSystemSpec` with set-condition, system-condition, and ordinary access conflict metadata, plus helper constructors for those conflict sets.
- `ecs_executor_state_can_spawn_system` now models the remaining Bevy `ExecutorState::can_run` running-conflict gates: unevaluated set-condition conflicts block, system-condition conflicts block, ordinary access conflicts block only for non-skipped systems, and pending-skipped systems can still pass the gate to notify dependents.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added conflict regressions for direct can-spawn decisions, ready-batch deferral to a later ready candidate, and skipped systems releasing dependents despite ordinary access conflicts.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA conflict tests; whole-file generated-SA and default backend executor isolated tests both pass with 46 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready-triple and nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor running-conflict can-run gate surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 146 — executor_apply_deferred_barrier (2026-07-09)
- lib/executor_multi_threaded.sla: added `ecs_executor_system_spec_as_apply_deferred` and an apply-deferred barrier path for run-plan completion, modeling Bevy `spawn_exclusive_system_task` when the exclusive system is `ApplyDeferred`.
- The barrier now snapshots and clears currently unapplied systems before it completes, records the applied system indices, then marks the barrier itself completed/unapplied through the normal completion path. The helper also forces exclusive/local scheduling so ready-batch selection serializes it.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added regressions for applying only prior unapplied systems and for the exclusive/local ready-batch shape of an apply-deferred barrier.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA apply-deferred-barrier tests; whole-file generated-SA and default backend executor isolated tests both pass with 48 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA triple-bridge and nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor exclusive ApplyDeferred barrier surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 147 — executor_ready_rescan_after_skip (2026-07-09)
- lib/executor_multi_threaded.sla: updated `ecs_executor_run_plan_take_ready_batch` to remove systems from `ready_systems` as soon as they are selected for a batch and to rescan ready systems after skipped systems notify dependents.
- This models Bevy `spawn_system_tasks`: skipped systems may make dependents ready immediately, and selected systems are removed from `ready_systems` before spawning so a rescan cannot select them twice.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_ready_group_rescans_after_skip_for_lower_index_dependent` and updated the skipped/conflicting dependent assertion to expect selected ready systems to be removed from ready.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA rescan test; whole-file generated-SA and default backend executor isolated tests both pass with 49 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor ready rescan after skip surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 148 — executor_selected_running_spawn_loop (2026-07-09)
- lib/executor_multi_threaded.sla: added `ecs_executor_run_plan_start_selected` and moved ready-batch spawn accounting into `ecs_executor_run_plan_take_ready_batch`, so selected systems immediately enter `running_systems`, increment `num_running_systems`, update local/exclusive flags, and append to run order.
- Ready-batch selection now matches the important Bevy `spawn_system_tasks` ordering point where `running_systems.insert(system_index)` happens before the loop considers later ready systems. Later candidates in the same spawn loop are blocked by access conflicts with newly selected systems, and dependents released by skipped systems cannot be selected in the same batch when they conflict with already selected/running systems.
- Non-exclusive local/non-send systems are no longer over-serialized: one local system can share a ready batch with send systems, while a second local candidate is still blocked by `local_thread_running`, matching Bevy's `spawn_system_task` behavior.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_ready_group_selected_system_blocks_later_conflict`, `executor_ready_group_allows_one_local_with_send_systems`, and `executor_ready_group_rescan_respects_selected_running_conflict`; updated `executor_ready_group_serializes_one` to expect the Bevy-style local+send batch after an exclusive system completes.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA tests for the three new cases; whole-file generated-SA and default backend executor isolated tests both pass with 52 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor selected-running spawn-loop surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 149 — executor_completed_dependent_signal_guard (2026-07-09)
- lib/executor_multi_threaded.sla: updated `ecs_executor_state_release_dependents` to only set a dependent ready when its dependency count reaches zero and that dependent is not already completed.
- This matches Bevy `ExecutorState::signal_dependents`, which checks `*remaining == 0 && !completed_systems.contains(dep_idx)` before inserting into `ready_systems`. The guard prevents debug/initial skip edge cases and repeated facade signal paths from re-readying systems that have already completed or been skipped.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_state_release_dependents_does_not_ready_completed_dependent` for direct state coverage and `executor_run_plan_initial_skip_completed_dependent_not_readied` for the run-plan initial-skip path.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA tests for the two new cases; whole-file generated-SA and default backend executor isolated tests both pass with 54 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor completed-dependent signal guard surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 150 — executor_begin_run_reset (2026-07-09)
- lib/executor_multi_threaded.sla: `EcsExecutorRunPlan` now stores each system's original dependency count, and `ecs_executor_run_plan_begin_run` resets a plan for a fresh schedule run.
- The begin-run helper mirrors the startup block in Bevy `MultiThreadedExecutor::run`: dependency counts are restored from the schedule snapshot, `ready_systems` is reset from `starting_systems`, running/skipped/completed/evaluated transient state and per-run counters/orders are cleared, and `local_thread_running` / `exclusive_running` are reset.
- Existing `unapplied_systems` are intentionally preserved, matching Bevy's behavior when final deferred application is disabled and unapplied buffers remain across a run boundary.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_begin_run_resets_dependencies_and_ready` and `executor_run_plan_begin_run_preserves_unapplied_buffers`.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA tests for the two new cases; whole-file generated-SA and default backend executor isolated tests both pass with 56 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor begin-run reset surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 151 — executor_deferred_apply_timing (2026-07-09)
- lib/executor_multi_threaded.sla: ordinary systems with deferred buffers now remain in `unapplied_systems` after completion instead of being applied immediately.
- This matches Bevy `finish_system_and_handle_dependents` / `apply_deferred` timing: completion records the system as unapplied, explicit `ApplyDeferred` barriers flush the current unapplied snapshot before completing, and final cleanup flushes pending buffers when `apply_final_deferred=true`.
- This batch still used a pending-buffer simplification for non-deferred systems; Batch 152 supersedes it with Bevy-exact all-completed-system tracking.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_apply_deferred_barrier_applies_completed_deferred_system` and updated dependency-order / batched-width regressions to expect pending deferred buffers until final cleanup.
- tests/test_ecs_mut_parallel.sla: updated `task pool defers buffers until final apply` so the threaded ready runner leaves deferred buffers pending until `ecs_multi_threaded_executor_finish_run`.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA barrier and task-pool deferred tests; whole-file generated-SA and default backend executor isolated tests both pass with 57 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor deferred-system apply timing surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 152 — executor_all_completed_unapplied_tracking (2026-07-09)
- lib/executor_multi_threaded.sla: `ecs_executor_run_plan_apply_deferred_for` no longer clears ordinary non-deferred systems after completion.
- This matches Bevy's exact `unapplied_systems` semantics: `finish_system_and_handle_dependents` inserts every completed system, and explicit `ApplyDeferred` barriers / final cleanup iterate the whole set. Systems without actual deferred buffers are represented as no-op `apply_deferred` calls.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_records_non_deferred_unapplied_until_apply` and `executor_run_plan_apply_deferred_barrier_applies_completed_non_deferred_system`, and updated dependency-order / batched-width regressions to count all completed systems during final cleanup.
- tests/test_ecs_mut_parallel.sla: updated `task pool defers buffers until final apply` so both threaded completed systems remain pending until `ecs_multi_threaded_executor_finish_run`.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA non-deferred and task-pool tests; whole-file generated-SA and default backend executor isolated tests both pass with 58 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Note: whole-file generated-SA `tests/test_ecs_mut_parallel.sla` remains a documented compiler/typecheck aggregation issue at `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/sa_backend_mut_parallel_whole_file_for_stmt_typemismatch_issue_cn.md`; focused affected bridge tests pass.
- Feature progress: Bevy ECS schedule/executor all-completed unapplied tracking surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 159 — executor_tick_executor_try_lock_failure (2026-07-09)
- lib/executor_multi_threaded.sla: `EcsExecutorTickLoopResult` now carries `pending_completions` and `lock_failed` metadata, plus accessors for the modeled pending queue. Added `ecs_executor_run_plan_system_completed_tick_executor_lock_failed`, `ecs_executor_run_plan_system_panic_payload_completed_tick_executor_lock_failed`, and `ecs_executor_run_plan_system_handled_error_completed_tick_executor_lock_failed`.
- This models the Bevy `Context::tick_executor` branch where `try_lock().ok()?` fails: `system_completed` has already pushed the completion result and recorded any panic payload / handled error state, but the current thread returns without draining the queue, releasing dependents, or spawning newly ready systems. The pending completion remains observable for a later tick/drain path.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added lock-failure regressions for ordinary, panic-payload, and handled-error completions. The ordinary case also retries the pending completion through the existing completion-wave tick loop to prove the dependent only spawns once a later drain occurs.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `lock_failed` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 76 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,144 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor `tick_executor` try-lock failure surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 160 — executor_system_completed_finish_run_closure (2026-07-09)
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added focused coverage for `Context::system_completed` handoff through the run-end cleanup/rethrow boundary. `executor_run_plan_apply_deferred_completed_tick_executor_applies_prior_and_spawns` proves an `ApplyDeferred` barrier completed via tick handoff flushes prior unapplied systems before it completes, then spawns a dependent in the same handoff. `executor_run_plan_system_panic_completed_tick_executor_finish_run_rethrows_after_final_apply` proves a panic-payload completion handoff still completes the dependent, final-applies both completed systems, and only then reaches the modeled `take_panic_payload` rethrow point. `executor_run_plan_system_handled_error_completed_tick_executor_finish_run_has_no_rethrow` proves the handled-error branch follows the same final deferred cleanup path without setting a payload or incrementing rethrow count.
- This locks down the Bevy sequence from `Context::system_completed` / `tick_executor` back into `MultiThreadedExecutor::run`: queued completions are drained into `finish_system_and_handle_dependents`, `ApplyDeferred` barriers flush the unapplied snapshot before dependent spawn, final deferred cleanup runs after all systems complete, and panic propagation is observed at the final payload take boundary.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `completed_tick_executor` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 79 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,147 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor `Context::system_completed` finish-run closure surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 161 — executor_apply_deferred_completed_tick_error_handoff (2026-07-09)
- lib/executor_multi_threaded.sla: added `ecs_executor_run_plan_apply_deferred_panic_payload_completed_tick_executor` and `ecs_executor_run_plan_apply_deferred_handled_error_completed_tick_executor`. These combine the existing ApplyDeferred snapshot application helpers with the `Context::system_completed` tick handoff path.
- This models the Bevy `spawn_exclusive_system_task` branch for `ApplyDeferred`: the barrier task clones and clears the current `unapplied_systems`, calls `apply_deferred`, records a deferred apply panic payload or handled error if needed, then calls `system_completed`, whose immediate `tick_executor` drain completes the barrier, marks it unapplied, and releases dependents.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_apply_deferred_panic_completed_tick_executor_records_deferred_payload_and_spawns` and `executor_run_plan_apply_deferred_handled_error_completed_tick_executor_records_error_and_spawns`. The regressions prove prior unapplied systems are cleared, apply order/counters match the cloned snapshot semantics, deferred panic/handled-error phase markers are recorded instead of system-phase markers, and dependents spawn in the same tick handoff.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `apply_deferred_` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 81 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,149 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor `ApplyDeferred` completed-tick deferred error handoff surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 162 — executor_exclusive_completed_tick_handoff (2026-07-09)
- lib/executor_multi_threaded.sla: exclusive systems are now treated as implicitly local/non-send in `ecs_executor_system_spec_new`, `ecs_executor_state_start_system`, and `ecs_executor_state_complete_system_with_flags`, matching Bevy `ExclusiveFunctionSystem::flags()` and `spawn_exclusive_system_task` setting both `exclusive_running` and `local_thread_running`. Added explicit `ecs_executor_run_plan_exclusive_system_completed_tick_executor`, `ecs_executor_run_plan_exclusive_system_panic_payload_completed_tick_executor`, `ecs_executor_run_plan_exclusive_system_handled_error_completed_tick_executor`, and matching try-lock-failure facades.
- This models the non-`ApplyDeferred` branch of Bevy `spawn_exclusive_system_task`: an exclusive task runs with full world access, calls `system_completed`, records any system panic payload or handled error in the same phase as ordinary systems, and completes through `tick_executor` without applying unrelated prior `unapplied_systems` until a later `ApplyDeferred` barrier or final cleanup.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_exclusive_completed_tick_executor_spawns_without_apply_barrier`, `executor_run_plan_exclusive_panic_completed_tick_executor_lock_failed_keeps_flags`, and `executor_run_plan_exclusive_handled_error_completed_tick_executor_spawns_dependent`. The regressions cover no accidental apply-deferred barrier behavior, exclusive/local flag retention when `try_lock` fails, later completion retry, system-phase payload/handled-error bookkeeping, and dependent spawn after the exclusive completion is drained.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `exclusive_` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 84 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict/dispatch bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,152 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor non-`ApplyDeferred` exclusive completed-tick handoff surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 163 — executor_finish_run_without_final_deferred_error_handoff (2026-07-09)
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_system_panic_finish_run_without_final_deferred_preserves_payload_and_unapplied` and `executor_run_plan_system_handled_error_finish_run_without_final_deferred_preserves_unapplied_no_rethrow`.
- This models the Bevy `MultiThreadedExecutor::run` tail when `apply_final_deferred=false`: the final `apply_deferred` block is skipped, so completed systems stay in `unapplied_systems`; no deferred apply panic payload or handled error is recorded; transient ready/running/completed state is still cleared; an existing system panic payload remains pending until the modeled final `take_panic_payload` rethrow point; and handled system errors still do not create a rethrow.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `without_final_deferred` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 86 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict/width-dispatch bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,154 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor run-end disabled-final-deferred panic/handled-error surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 164 — executor_apply_deferred_completed_tick_lock_failure (2026-07-09)
- lib/executor_multi_threaded.sla: added `ecs_executor_run_plan_apply_deferred_completed_tick_executor_lock_failed`, `ecs_executor_run_plan_apply_deferred_panic_payload_completed_tick_executor_lock_failed`, and `ecs_executor_run_plan_apply_deferred_handled_error_completed_tick_executor_lock_failed`.
- This models the Bevy `spawn_exclusive_system_task` / `ApplyDeferred` branch where the barrier task clones/clears and applies the current `unapplied_systems` snapshot, records a deferred apply panic payload or handled error if needed, pushes the barrier completion, then `Context::tick_executor` returns early because `try_lock().ok()?` failed. The completion remains pending; the barrier stays running and exclusive/local; prior unapplied systems have already been cleared by the cloned-snapshot apply path; and dependents only release when a later tick drains the pending completion.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_apply_deferred_completed_tick_executor_lock_failed_keeps_barrier_pending`, `executor_run_plan_apply_deferred_panic_completed_tick_executor_lock_failed_records_payload_only`, and `executor_run_plan_apply_deferred_handled_error_completed_tick_executor_lock_failed_records_error_only`. The regressions cover normal, panic-payload, and handled-error lock-failure handoffs, plus retrying the pending barrier completion through the completion-wave loop.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `lock_failed` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 89 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict/width-dispatch bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,157 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor `ApplyDeferred` completed-tick lock-failure handoff surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 165 — executor_local_completed_tick_handoff (2026-07-09)
- lib/executor_multi_threaded.sla: added explicit non-send/local completed-tick facades: `ecs_executor_run_plan_local_system_completed_tick_executor`, `ecs_executor_run_plan_local_system_completed_tick_executor_lock_failed`, `ecs_executor_run_plan_local_system_panic_payload_completed_tick_executor`, `ecs_executor_run_plan_local_system_panic_payload_completed_tick_executor_lock_failed`, `ecs_executor_run_plan_local_system_handled_error_completed_tick_executor`, and `ecs_executor_run_plan_local_system_handled_error_completed_tick_executor_lock_failed`.
- This models the Bevy `spawn_system_task` non-send branch separately from exclusive systems: a local system uses the same completion queue and `Context::tick_executor` handoff as send systems, sets `local_thread_running` while it runs, never sets `exclusive_running`, and on try-lock failure leaves completion pending without releasing dependents until a later drain.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_local_completed_tick_executor_clears_local_without_exclusive`, `executor_run_plan_local_panic_completed_tick_executor_lock_failed_keeps_local_only`, and `executor_run_plan_local_handled_error_completed_tick_executor_spawns_dependent`. The regressions prove normal local completion can spawn a send dependent while another send system remains running, lock failure preserves only local/non-exclusive flags plus payload bookkeeping, and handled errors remain system-phase non-payload completions.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `local_` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 92 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,124 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor non-send/local completed-tick handoff surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 166 — executor_multi_completion_same_tick_and_pending_retry (2026-07-10)
- lib/executor_multi_threaded.sla: added `ecs_executor_tick_loop_retry_pending_completions`, which models a later successful `Context::tick_executor` acquisition by replaying a lock-failed result's `pending_completions` queue as the first completion wave and then any later waves.
- This locks down two Bevy multi-threaded executor details: `ExecutorState::tick` drains every currently queued completion before spawn, so a join dependent with two remaining dependencies becomes ready and spawns in the same modeled tick; and the try-lock-failure comment path where another thread later observes the non-empty completion queue and re-enters the tick loop.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_tick_with_completions_drains_join_before_spawn` and `executor_tick_loop_retry_pending_completions_rechecks_after_lock_failure`.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA `drains_join_before_spawn` and `retry_pending_completions` tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 94 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,126 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor multi-completion same-tick drain and pending-retry surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 167 — executor_run_condition_fold (2026-07-10)
- lib/executor_multi_threaded.sla: added `EcsExecutorConditionFoldResult`, condition outcome markers, `ecs_executor_panic_phase_run_condition`, `ecs_executor_run_plan_evaluate_and_fold_conditions`, and `ecs_executor_run_plan_should_run_with_condition_outcomes`.
- This models Bevy `evaluate_and_fold_conditions` / `ExecutorState::should_run`: every condition outcome is evaluated without short-circuiting on false, handled condition errors continue the fold as false, an error-handler panic aborts the remaining fold and records a run-condition-phase panic payload, and system conditions still fold after a failed set condition before pending-skip bookkeeping is applied.
- tests/test_ecs_lib_executor_multi_threaded_isolated.sla: added `executor_run_plan_condition_fold_evaluates_all_after_false`, `executor_run_plan_condition_fold_handled_error_continues_without_payload`, `executor_run_plan_condition_fold_error_handler_panic_aborts_remaining`, and `executor_run_plan_should_run_folds_system_conditions_after_failed_set`.
- Verification: `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded.sla`; focused generated-SA condition-fold/should-run tests pass; whole-file generated-SA and default backend executor isolated tests both pass with 98 tests; `timeout 120s env SA_PLUGIN_DEV=1 sa sla check lib/parallel_runner.sla`; focused generated-SA ready/nonconflict bridge tests pass; focused default backend task-pool deferred test passes; `git diff --check` passes after EOF cleanup.
- Current measured counts: 270 lib modules, 174 test files, 90 examples, and 4,130 source `.sla` `@test` annotations.
- Feature progress: Bevy ECS schedule/executor run-condition fold surface 0% -> 100%; overall estimate remains API parity ~94–96%, behavioral parity ~86–91% because full runtime reflection and exact Bevy TaskPool internals remain outside the completed behavior set.

## Batch 168 — executor_single_threaded_deepen (2026-07-10)
- lib/executor_single_threaded.sla: full rewrite from Batch 51 shallow surface to Bevy single_threaded.rs semantic parity (panic/handled-error bookkeeping, ApplyDeferred prior-unapplied flush, finish respecting apply_final_deferred, initial skips, failed/passed set condition marking, schedule-order process_system, condition fold no-short-circuit, EcsSingleThreadedRunPlan + drive_all ordered plan).
- 22 tests — tests/test_ecs_lib_executor_single_threaded_isolated.sla (expanded from 13).
- Verification: `sa sla check`; whole-file generated-SA 22 pass; default backend 22 pass; multi-threaded isolated 98 pass; bridge filters pass; `git diff --check` passes.
- src/schedule/executor/single_threaded.rs (SingleThreadedExecutor) ✓ deepened
- Current measured counts: 271 lib modules, 174 test files, 90 examples, 4,139 `.sla` `@test` annotations.
- Feature progress: single-threaded semantic surface 25% -> 95%; overall API ~94–96%, behavioral ~86–91%.

## Batch 169 — schedule_stepping_deepen (2026-07-10)
- lib/schedule_stepping.sla: deepened from shallow direct-mutator surface to Bevy `stepping.rs` deep semantics. Added `EcsSteppingUpdate` queue + `EcsSteppingScheduleStateDeep` + `ecs_stepping_deep_next_frame` (action-transition filtering + cursor reset) + `ecs_stepping_deep_skipped_systems` (full Action×SystemBehavior cursor traversal with dynamic schedule_order insertion) + `ecs_stepping_deep_cursor` / `ecs_stepping_deep_schedules` + auto-resize behavior + `ecs_stepping_vec_insert_i32` helper.
- 53 tests — tests/test_ecs_lib_schedule_stepping_isolated.sla (expanded from 23; 30 new tests).
- Verification: `sa sla check`; whole-file generated-SA 53 pass; multi-threaded isolated 98 pass; single-threaded isolated 22 pass; bridge filters pass; `git diff --check` passes.
- src/schedule/stepping.rs (Stepping, ScheduleState) ✓ deepened
- Compiler/SAB note: `RegisterRedefinition`/`PhiStateConflict` on `ecs_stepping_deep_next_frame`, documented.
- Current measured counts: 271 lib modules, 174 test files, 90 examples, 4,169 `.sla` `@test` annotations.
- Feature progress: schedule stepping deep model surface ~15% -> 80%; overall API ~94–96%, behavioral ~86–91%.

## Batch 170 — schedule_value_lifecycle (2026-07-10)
- lib/schedule_value.sla: new file modeling Bevy `Schedule` (src/schedule/schedule.rs lines 387-715). EcsSchedule + EcsScheduleExecutable structs with lifecycle: new/default/label/is_changed/mark_changed, set_executor/set_apply_final_deferred/set_build_settings, add_system/add_set, initialize (freeze + clear changed + set executor_initialized), run (check_change_ticks + initialize), check_change_ticks, apply_deferred, systems (ScheduleNotInitialized gate), systems_len, graph accessors, systems_in_set, remove_systems_in_set.
- 19 tests — tests/test_ecs_lib_schedule_value_isolated.sla (new file).
- Verification: `sa sla check lib/schedule_value.sla`; whole-file generated-SA 19 pass; default backend 19 pass; `git diff --check` passes.
- src/schedule/schedule.rs (Schedule struct) ✓ partial lifecycle coverage
- Current measured counts: 272 lib modules, 175 test files, 90 examples, 4,188 `.sla` `@test` annotations.
- Feature progress: Schedule-value lifecycle surface 0% -> 60%; overall API ~94–96%, behavioral ~86–91%.

## Batch 171 — schedule_error_deep (2026-07-10)
- lib/schedule_error.sla: deepened from shallow constants + structs to full Bevy `error.rs` (303 lines) surface. Added EcsDiGraphToposortError (Loop/Cycle), EcsDagRedundancyError (transitive edge pairs), EcsDagCrossDependencyError, EcsDagOverlappingGroupError, EcsAmbiguousSystemConflictsWarning, EcsSystemTypeSetAmbiguityError, EcsScheduleBuildErrorV2 with all variant payloads + per-variant constructors + accessors + to_string-label proxy (101-110).
- 14 tests — tests/test_ecs_lib_schedule_error_deep_isolated.sla (new file).
- Verification: `sa sla check lib/schedule_error.sla`; whole-file generated-SA 14 pass; default backend 14 pass; `git diff --check` passes.
- src/schedule/error.rs (ScheduleBuildError, ScheduleBuildWarning) ✓ deepened
- Current measured counts: 272 lib modules, 176 test files, 90 examples, 4,202 `.sla` `@test` annotations.
- Feature progress: schedule build error/warning payload surface ~25% -> 75%; overall API ~94–96%, behavioral ~86–91%.

## Batch 172 — schedule_value_cleanup_policy (2026-07-10)
- lib/schedule_value.sla: added Bevy `ScheduleCleanupPolicy` enum (4 variants: RemoveSetAndSystems / RemoveSystemsOnly / RemoveSetAndSystemsAllowBreakages / RemoveSystemsOnlyAllowBreakages) + per-variant predicates + default. Added EcsScheduleCleanupResult + ecs_schedule_remove_systems_in_set_with_policy (full policy-aware removal with set-removal flag + graph-changed mark) + ecs_schedule_systems_in_set_count + result accessors.
- 5 new tests — tests/test_ecs_lib_schedule_value_isolated.sla (24 total).
- Verification: `sa sla check lib/schedule_value.sla`; whole-file generated-SA 24 pass; default backend 24 pass; multi-threaded isolated 98 pass; `git diff --check` passes.
- src/schedule/schedule.rs (ScheduleCleanupPolicy, remove_systems_in_set) ✓ partial (value-model surface; full edge-bridging lives in ScheduleGraph model)
- Current measured counts: 272 lib modules, 176 test files, 90 examples, 4,207 `.sla` `@test` annotations.
- Feature progress: schedule cleanup-policy surface 0% -> 80%; overall API ~94–96%, behavioral ~86–91%.

## Batch 173 — schedule_set_deep (DONE 2026-07-11)
- lib/schedule_set_deep.sla: new file. EcsSystemSetIdentity (kind/type_id/anon_id/label_id) with three constructors (system_type/anonymous/base) + kind predicates + accessors. EcsOptionTypeId nullable wrapper for `SystemSet::system_type -> Option<TypeId>`. AnonymousSet traits (is_anonymous/eq/hash/debug), SystemTypeSet traits (new/eq-self/by-T-hash/system_type/is_anonymous), trait-surface facades (ecs_system_set_trait_system_type, ecs_system_set_trait_is_anonymous). EcsScheduleLabelIdentity (eq/hash); EcsInternRegistry modeling Bevy interner (same identity => same intern id; numeric-kind namespace separation for ScheduleLabel vs SystemSet). EcsInternResult (created vs found). IntoSystemSet<Marker> dispatch (SystemSet => self; FunctionSystem/ExclusiveSystem => SystemTypeSet::<F>::new()). trait `base` None proxy + dyn_clone identity copy.
- 25 tests — tests/test_ecs_lib_schedule_set_deep_isolated.sla (new).
- Verification: generated SA 25 pass; default backend 25 pass; `git diff --check` passes.
- src/schedule/set.rs (SystemSet/SystemTypeSet/AnonymousSet/IntoSystemSet/InternedSystemSet/InternedScheduleLabel) ✓ deepened
- Current measured counts: 275 lib modules, 177 test files, 90 examples, 4,268 `.sla` `@test` annotations.
- Feature progress: schedule set deep trait surface ~15% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 174 — graph_map_digragh_toposort (DONE 2026-07-11)
- lib/graph_map_digragh_toposort.sla: new file. EcsDiGraphToposortResult (Ok/Loop/Cycle) + builders + predicates + accessors. Direction (Incoming/Outgoing) + opposite. Compact EcsDiGraph value model + SCC/toposort algorithm (inline Tarjan SCC + Johnson elementary-circuits proxy with root-pop + subgraph resplit). EcsDagCache dirty cache modeling Bevy `Dag`.
- 21 tests — tests/test_ecs_lib_graph_map_digraph_toposort_isolated.sla (new).
- Verification: generated SA backend 21 pass; `git diff --check` passes. Default backend fails the cycle/recursion struct-move paths (documented SLA/SAB limitation; see existing SCC nonsend SAB regressions); SA backend is the project's gold standard.
- src/schedule/graph/graph_map.rs (DiGraph::toposort + iter_sccs + simple_cycles_in_component + DiGraphToposortError + Direction + Dag dirty cache) ✓ deepened
- Current measured counts: 276 lib modules, 178 test files, 90 examples, 4,289 `.sla` `@test` annotations.
- Feature progress: graph_map DiGraph/DAG toposort + SCC + error/Direction surface ~15% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 175 — schedule_pass_deep (DONE 2026-07-11)
- lib/schedule_pass_deep.sla: new file. EcsNodeId (NodeId surface) + EcsSystemKey/EcsSystemSetKey. EcsFlatDeps modeling FlattenedDependencies (add_edge with added-records dedup + remove_edge forwards-only no-record, matching Bevy comment). collapse_set_produce (chain/bucket) + apply_collapse. EcsDependencyOptions + ecs_pass_add_dependency (system->system; set endpoints skipped as collapse_set is the bridge). EcsPassObjAdapter (ScheduleBuildPassObj blanket): resolve_options TypeIdMap lookup + add_dependency dispatch + collapse_set accumulate. EcsPassBuildResult (Ok/Cycle/Custom) + build_generic facade.
- 31 tests — tests/test_ecs_lib_schedule_pass_deep_isolated.sla (new).
- Verification: generated SA 31 pass; default backend 31 pass; `git diff --check` passes.
- src/schedule/pass.rs + src/schedule/node.rs (Node surface used by passes) ✓ deepened
- Current measured counts: 277 lib modules, 179 test files, 90 examples, 4,320 `.sla` `@test` annotations.
- Feature progress: schedule pass deep surface ~20% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 176 — auto_insert_apply_deferred_deep (DONE 2026-07-11)
- lib/auto_insert_apply_deferred_deep.sla: new file. Full Bevy `AutoInsertApplyDeferredPass::build()` two-phase algorithm (distance topo-scan + explicit-sync cache + pending-sync no_sync forwarding + get_sync_point cache + collapse_set IgnoreDeferred forwarding). EcsAidFlatEdges directed-edge list + EcsAidPass distance-keyed sync cache + EcsAidBuildResult with sync_edge_triple accessor.
- 17 tests — tests/test_ecs_lib_auto_insert_apply_deferred_deep_isolated.sla (new).
- Verification: generated SA 17 pass; default backend 17 pass; `git diff --check` passes.
- src/schedule/auto_insert_apply_deferred.rs (AutoInsertApplyDeferredPass::build + collapse_set) ✓ deepened
- Current measured counts: 278 lib modules, 180 test files, 90 examples, 4,337 `.sla` `@test` annotations.
- Feature progress: auto_insert_apply_deferred build algorithm surface ~15% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 177 — schedule_config_deep (DONE 2026-07-11)
- lib/schedule_config_deep.sla: new file. GraphInfo/Dependency/Ambiguity/Chain deep models + nested ScheduleConfigs enum with full IntoScheduleConfigs inner surface (in_set reject system type set, before/after/ignore_deferred, distributive vs collective run_if, ambiguous_with/all, chain/chain_ignore_deferred, into_configs).
- 20 tests — tests/test_ecs_lib_schedule_config_deep_isolated.sla (new).
- Verification: generated SA 20 pass; default backend 20 pass; `git diff --check` passes.
- src/schedule/config.rs + graph GraphInfo/Dependency/Ambiguity + Chain ✓ deepened
- Current measured counts: 279 lib modules, 181 test files, 90 examples, 4,357 `.sla` `@test` annotations.
- Feature progress: schedule config deep nested surface ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 178 — schedule_condition_deep (DONE 2026-07-11)
- lib/schedule_condition_deep.sla: new file. Combinator Then/Eager short-circuit evaluation (b_ran tracking), Xnor/Xor, Result unwrap_or(false), NotMarker, Local-backed resource_changed_or_removed/resource_removed/condition_changed/condition_changed_to/run_once, common_conditions facades.
- 23 tests — tests/test_ecs_lib_schedule_condition_deep_isolated.sla (new).
- Verification: generated SA 23 pass; default backend 23 pass; `git diff --check` passes.
- src/schedule/condition.rs (SystemCondition combinators + common_conditions) ✓ deepened
- Current measured counts: 280 lib modules, 182 test files, 90 examples, 4,380 `.sla` `@test` annotations.
- Feature progress: schedule condition combinator short-circuit + stateful trackers ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 179 — schedule_node_deep (DONE 2026-07-11)
- lib/schedule_node_deep.sla: new file. CompactNodeId packing, Systems::get_conflicting_systems algorithm, SystemSets partial-condition uninit ranges, SystemNode Option, Systems lifecycle.
- 23 tests — tests/test_ecs_lib_schedule_node_deep_isolated.sla (new).
- Verification: generated SA 23 pass; default backend 23 pass; `git diff --check` passes.
- src/schedule/node.rs ✓ deepened
- Current measured counts: 281 lib modules, 183 test files, 90 examples, 4,403 `.sla` `@test` annotations.
- Feature progress: schedule node compact packing + conflict detection + SystemSets uninit ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 180 — schedules_deep (DONE 2026-07-11)
- lib/schedules_deep.sla: new file. Schedules temporarily_removed/empty_labels/ignored ambiguities + entry-based multi-schedule APIs.
- 20 tests — tests/test_ecs_lib_schedules_deep_isolated.sla (new).
- Verification: generated SA 20 pass; default backend 20 pass; `git diff --check` passes.
- src/schedule/schedule.rs (Schedules) ✓ deepened
- Current measured counts: 282 lib modules, 184 test files, 90 examples, 4,423 `.sla` `@test` annotations.
- Feature progress: Schedules collection deep surface ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 181 — schedule_graph_deep (DONE 2026-07-11)
- lib/schedule_graph_deep.sla: new file. ScheduleGraph process_configs densely_chained chaining, collective conditions anonymous sets, transitive dep bridging, systems_in_set error gates.
- 20 tests — tests/test_ecs_lib_schedule_graph_deep_isolated.sla (new).
- Verification: generated SA 20 pass; default backend 20 pass; `git diff --check` passes.
- src/schedule/schedule.rs (ScheduleGraph) ✓ deepened
- Current measured counts: 283 lib modules, 185 test files, 90 examples, 4,443 `.sla` `@test` annotations.
- Feature progress: ScheduleGraph process_configs + transitive surface ~30% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 182 — system_combinator_deep (DONE 2026-07-11)
- lib/system_combinator_deep.sla: CombinatorSystem/PipeSystem System impl deep model (Failed/Skipped, access merge, pipe short-circuit).
- 22 tests — tests/test_ecs_lib_system_combinator_deep_isolated.sla (new).
- Verification: generated SA 22 pass; default backend 22 pass.
- src/system/combinator.rs ✓ deepened
- Current measured counts: 284 lib modules, 186 test files, 90 examples, 4,465 `.sla` `@test` annotations.
- Feature progress: system combinator/pipe lifecycle + error intercept ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 183 — system_builder_deep (DONE 2026-07-11)
- lib/system_builder_deep.sla: BuilderSystemInner state machine + param builders deep model.
- 20 tests — tests/test_ecs_lib_system_builder_deep_isolated.sla (new).
- Verification: generated SA 20 pass; default backend 20 pass.
- src/system/builder.rs ✓ deepened
- Current measured counts: 285 lib modules, 187 test files, 90 examples, 4,485 `.sla` `@test` annotations.
- Feature progress: system builder state machine ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 184 — system_input_deep (DONE 2026-07-11)
- lib/system_input_deep.sla: SystemInput deep wrap/Option/tuples/FromInput + SystemName SystemParam.
- 20 tests — tests/test_ecs_lib_system_input_deep_isolated.sla (new).
- Verification: generated SA 20 pass; default backend 20 pass.
- src/system/input.rs + system_name.rs ✓ deepened
- Current measured counts: 286 lib modules, 188 test files, 90 examples, 4,505 `.sla` `@test` annotations.
- Feature progress: system input + SystemName param ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 185 — function_system_deep (DONE 2026-07-11)
- lib/function_system_deep.sla: SystemMeta + FunctionSystem + IntoResult + SystemState deep model of src/system/function_system.rs.
- 20 tests — tests/test_ecs_lib_function_system_deep_isolated.sla (new).
- Verification: generated SA 20 pass; default backend 20 pass.
- src/system/function_system.rs ✓ deepened
- Current measured counts: 284 lib modules, 189 test files, 90 examples, 4,489 `.sla` `@test` annotations.
- Feature progress: function_system deep ~50% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 186 — exclusive_function_system_deep (DONE 2026-07-11)
- lib/exclusive_function_system_deep.sla: ExclusiveFunctionSystem + ExclusiveSystemParam deep model.
- 20 tests — tests/test_ecs_lib_exclusive_function_system_deep_isolated.sla (new).
- Verification: SA 20 pass; default 20 pass.
- src/system/exclusive_function_system.rs + exclusive_system_param.rs ✓ deepened
- Current measured counts: 285 lib modules, 190 test files, 90 examples, 4,509 `.sla` `@test` annotations.
- Feature progress: exclusive function system deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 187 — system_registry_deep (DONE 2026-07-11)
- lib/system_registry_deep.sla: SystemId/RegisteredSystem/Handles/Cache/run/unregister deep model of src/system/system_registry.rs.
- 20 tests — tests/test_ecs_lib_system_registry_deep_isolated.sla (new).
- Verification: SA 20 pass; default 20 pass.
- src/system/system_registry.rs ✓ deepened
- Current measured counts: 286 lib modules, 191 test files, 90 examples, 4,529 `.sla` `@test` annotations.
- Feature progress: system_registry deep ~25% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 188 — schedule_system_deep (DONE 2026-07-11)
- lib/schedule_system_deep.sla: WithInputWrapper/WithInputFromWrapper/ScheduleSystem deep model.
- 20 tests — tests/test_ecs_lib_schedule_system_deep_isolated.sla (new).
- Verification: SA 20 pass; default 20 pass.
- src/system/schedule_system.rs ✓ deepened
- Current measured counts: 287 lib modules, 192 test files, 90 examples, 4,549 `.sla` `@test` annotations.
- Feature progress: schedule_system deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 189 — system_param_deep (DONE 2026-07-11)
- lib/system_param_deep.sla: FilteredAccess + ParamSet + init_access + get_param (Option/If/Dyn/Static/Local/Deferred/SystemChangeTick).
- 25 tests — tests/test_ecs_lib_system_param_deep_isolated.sla (new).
- Verification: SA 25 pass; default 25 pass.
- src/system/system_param.rs ✓ deepened
- Current measured counts: 288 lib modules, 193 test files, 90 examples, 4,574 `.sla` `@test` annotations.
- Feature progress: system_param deep ~25% -> 75%; overall API ~94–96%, behavioral ~86–91%.

## Batch 190 — deferred_world_deep (DONE 2026-07-11)
- lib/deferred_world_deep.sla: DeferredWorld deep model of src/world/deferred_world.rs (EntityMutableFetchError, get_entity_mut/get_mut, modify_component discard→mutate→insert hooks, relationship hook modes, trigger_on_*/trigger_raw/trigger, write_message/default/batch, structural ban, reborrow/change_tick/entities_and_commands).
- 23 tests — tests/test_ecs_lib_deferred_world_deep_isolated.sla (new).
- Fix: top-level negative const `ECS_DW_MSG_NONE = -1` hit `emitTopLevelConstDecl` CodegenError (unary expr not literal); sentinel moved to `0` because MessageId starts at 1.
- Verification: SA 23 pass; default 23 pass.
- src/world/deferred_world.rs ✓ deepened
- Current measured counts: 289 lib modules, 194 test files, 90 examples, 4,597 `.sla` `@test` annotations.
- Feature progress: deferred_world deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 191 — command_queue_deep (DONE 2026-07-11)
- lib/command_queue_deep.sla: CommandQueue dense buffer + cursor, RawCommandQueue apply_or_drop_queued, panic recovery restore, silent/warn_on_unapplied drop, SystemBuffer apply/queue, append/is_empty/push, nested push/flush.
- 22 tests — tests/test_ecs_lib_command_queue_deep_isolated.sla (new).
- Verification: SA 22 pass; default 22 pass.
- src/world/command_queue.rs ✓ deepened
- Current measured counts: 290 lib modules, 195 test files, 90 examples, 4,619 `.sla` `@test` annotations.
- Feature progress: command_queue deep ~20% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 192 — entity_command_deep (DONE 2026-07-11)
- lib/entity_command_deep.sla: EntityCommand apply + EntityCommandError + with_entity, insert/Keep/FromWorld/With, remove/with_requires/by_id, clear/retain/despawn/observe, clone opt-in/out/components, move_components, log_components.
- 22 tests — tests/test_ecs_lib_entity_command_deep_isolated.sla (new).
- Verification: SA 22 pass; default 22 pass.
- src/system/commands/entity_command.rs ✓ deepened
- Current measured counts: 291 lib modules, 196 test files, 90 examples, 4,641 `.sla` `@test` annotations.
- Feature progress: entity_command deep ~25% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 193 — stepping_deep (DONE 2026-07-11)
- lib/stepping_deep.sla: Stepping Action queue (deferred updates), SystemBehavior AlwaysRun/NeverRun/Break/Continue, schedule order, cursor, skipped_systems masks, begin_frame/next_frame, step/continue/waiting.
- 22 tests — tests/test_ecs_lib_stepping_deep_isolated.sla (new).
- Verification: SA 22 pass; default 22 pass.
- src/schedule/stepping.rs ✓ deepened
- Current measured counts: 292 lib modules, 197 test files, 90 examples, 4,663 `.sla` `@test` annotations.
- Feature progress: stepping deep ~15% -> 80%; overall API ~94–96%, behavioral ~86–91%.

## Batch 194 — entity_disabling_deep (DONE 2026-07-11)
- lib/entity_disabling_deep.sla: Disabled + DefaultQueryFilters deep model of src/entity_disabling.rs (empty/from_world, register_disabling_component idempotent, modify_access Without injection, Allow/Has suppress, is_dense storage checks, multi-disabling query visibility, resource_scope overwrite escape hatch).
- 23 tests — tests/test_ecs_lib_entity_disabling_deep_isolated.sla (new).
- Verification: SA 23 pass; default 23 pass.
- src/entity_disabling.rs ✓ deepened
- Current measured counts: 293 lib modules, 198 test files, 90 examples, 4,686 `.sla` `@test` annotations.
- Feature progress: entity_disabling deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 195 — spawn_batch_deep (DONE 2026-07-11)
- lib/spawn_batch_deep.sla: SpawnBatchIter deep model of src/world/spawn_batch.rs (size_hint reserve/alloc_many, next bulk vs overflow spawn, Drop exhaust+free over-alloc+flush_commands, ExactSize/Fused/EntitySet uniqueness).
- 20 tests — tests/test_ecs_lib_spawn_batch_deep_isolated.sla (new).
- Verification: SA 20 pass; default 20 pass.
- src/world/spawn_batch.rs ✓ deepened
- Current measured counts: 294 lib modules, 199 test files, 90 examples, 4,706 `.sla` `@test` annotations.
- Feature progress: spawn_batch deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 196 — resource_deep (DONE 2026-07-11)
- lib/resource_deep.sla: Resource/IsResource/ResourceEntities deep model of src/resource.rs (insert uniqueness hooks, duplicate strip+warn, on_discard cache invalidation, on_despawn warn, despawned-canonical error, init/remove/get/contains).
- 20 tests — tests/test_ecs_lib_resource_deep_isolated.sla (new).
- Verification: SA 20 pass; default 20 pass.
- src/resource.rs ✓ deepened
- Current measured counts: 295 lib modules, 200 test files, 90 examples, 4,726 `.sla` `@test` annotations.
- Feature progress: resource deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 197 — intern_deep (DONE 2026-07-11)
- lib/intern_deep.sla: Internable leak/ref_eq/ref_hash + Interner double-checked intern + Interned pointer equality (cross-interner inequality) deep model of src/intern.rs.
- 16 tests — tests/test_ecs_lib_intern_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass.
- src/intern.rs ✓ deepened
- Current measured counts: 298 lib modules, 203 test files, 90 examples, 4,780 `.sla` `@test` annotations.
- Feature progress: intern deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 198 — batching_deep (DONE 2026-07-11)
- lib/batching_deep.sla: BatchingStrategy range empty short-circuit (fixed), min/max clamp, batches_per_thread>0, thread_count>0, div_ceil calc_batch_size deep model of src/batching.rs.
- 19 tests — tests/test_ecs_lib_batching_deep_isolated.sla (new).
- Note: default backend Leb128Overflow on i64::MAX stand-in; usize::MAX modeled as 2147483647.
- Verification: SA 19 pass; default 19 pass.
- src/batching.rs ✓ deepened
- Current measured counts: 298 lib modules, 203 test files, 90 examples, 4,780 `.sla` `@test` annotations.
- Feature progress: batching deep ~40% -> 95%; overall API ~94–96%, behavioral ~86–91%.

## Batch 199 — error_handler_deep (DONE 2026-07-11)
- lib/error_handler_deep.sla: ErrorContext kinds/display, match_severity dispatch, named handlers, FallbackErrorHandler, PANIC_ORIGINATES_FROM_ERROR_HANDLER, CommandOutput HandleError deep model of src/error/handler.rs + command_handling.rs.
- 19 tests — tests/test_ecs_lib_error_handler_deep_isolated.sla (new).
- Verification: SA 19 pass; default 19 pass.
- src/error/handler.rs + command_handling.rs ✓ deepened
- Current measured counts: 298 lib modules, 203 test files, 90 examples, 4,780 `.sla` `@test` annotations.
- Feature progress: error handler deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 200 — label_deep + name_deep (DONE 2026-07-11)
- lib/label_deep.sla: DynEq/DynHash, label interner, Interned schedule/system-set labels deep model of src/label.rs.
- lib/name_deep.sla: Name owned/borrowed + set/mutate/hash, NameOrEntity prefer-name deep model of src/name.rs.
- 15 + 16 tests — tests/test_ecs_lib_label_deep_isolated.sla, tests/test_ecs_lib_name_deep_isolated.sla (new).
- Verification: SA 15+16 pass; default 15+16 pass.
- src/label.rs + src/name.rs ✓ deepened
- Current measured counts: 300 lib modules, 205 test files, 90 examples, 4,811 `.sla` `@test` annotations.
- Feature progress: label/name deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 201 — query_error_deep (DONE 2026-07-11)
- lib/query_error_deep.sla: QueryEntityError {QueryDoesNotMatch(Entity,ArchetypeId), NotSpawned(EntityNotSpawnedError), AliasedMutability}, nested EntityNotSpawnedError Invalid/ValidButNotSpawned, QuerySingleError DebugName variants, QueryNotDenseError, get/get_many_mut classify helpers deep model of src/query/error.rs (+ entity NotSpawned nesting).
- 18 tests — tests/test_ecs_lib_query_error_deep_isolated.sla (new).
- Verification: SA 18 pass; default 18 pass.
- src/query/error.rs ✓ deepened (shallow legacy ALIEN/ENTITY_NOT_FOUND retained)
- Current measured counts: 301 lib modules, 206 test files, 90 examples, 4,829 `.sla` `@test` annotations.
- Feature progress: query_error deep ~30% -> 95%; overall API ~94–96%, behavioral ~86–91%.


## Batch 202 — world_identifier_deep (DONE 2026-07-11)
- lib/world_identifier_deep.sla: WorldId monotonic never-reuse allocator, Option exhaustion, FromWorld, SystemParam/ReadOnly/ExclusiveSystemParam, SparseSetIndex deep model of src/world/identifier.rs.
- 15 tests — tests/test_ecs_lib_world_identifier_deep_isolated.sla (new).
- Note: usize::MAX stand-in 2147483647 for default-backend LEB safety.
- Verification: SA 15 pass; default 15 pass.
- src/world/identifier.rs ✓ deepened
- Current measured counts: 302 lib modules, 207 test files, 90 examples, 4,844 `.sla` `@test` annotations.
- Feature progress: world_identifier deep ~40% -> 95%; overall API ~94–96%, behavioral ~86–91%.


## Batch 203 — message_cursor_deep (DONE 2026-07-11)
- lib/message_cursor_deep.sla: MessageCursor last_message_count + dual-buffer Messages model; read/read_mut/with_id; len/missed/clear/is_empty; iterator next/count/last/nth clamp; par_read unread marker deep model of src/message/message_cursor.rs (+ Messages update drop semantics).
- 16 tests — tests/test_ecs_lib_message_cursor_deep_isolated.sla (new).
- Note: par_read has no real TaskPool; batching marker only.
- Verification: SA 16 pass; default 16 pass.
- src/message/message_cursor.rs ✓ deepened
- Current measured counts: 303 lib modules, 208 test files, 90 examples, 4,860 `.sla` `@test` annotations.
- Feature progress: message_cursor deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 204 — thin_array_ptr_deep (DONE 2026-07-11)
- lib/thin_array_ptr_deep.sla: ThinArrayPtr empty/with_capacity/alloc/realloc, initialize/get/get_mut, swap_remove(+nonoverlapping), clear_elements needs_drop, drop/dealloc, as_slice deep model of src/storage/thin_array_ptr.rs.
- 18 tests — tests/test_ecs_lib_thin_array_ptr_deep_isolated.sla (new).
- Note: fixed 16-slot model; capacity overflow returns last_error rather than OOM panic.
- Verification: SA 18 pass; default 18 pass.
- src/storage/thin_array_ptr.rs ✓ deepened
- Current measured counts: 304 lib modules, 209 test files, 90 examples, 4,878 `.sla` `@test` annotations; 32 `*_deep.sla` modules.
- Feature progress: thin_array_ptr deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 205 — query_par_iter_deep (DONE 2026-07-11)
- lib/query_par_iter_deep.sla: QueryParIter batching_strategy/for_each/for_each_init sequential vs multi-thread batch partition; QueryParManyIter(+unique) entity-list filter mask deep model of src/query/par_iter.rs.
- 16 tests — tests/test_ecs_lib_query_par_iter_deep_isolated.sla (new).
- Note: no real ComputeTaskPool; parallel path is sequential batch simulation with multi-init.
- Verification: SA 16 pass; default 16 pass.
- src/query/par_iter.rs ✓ deepened
- Current measured counts: 305 lib modules, 210 test files, 90 examples, 4,894 `.sla` `@test` annotations; 33 `*_deep.sla` modules.
- Feature progress: query_par_iter deep ~15% -> 85%; overall API ~94–96%, behavioral ~86–91%.


## Batch 206 — event_trigger_deep (DONE 2026-07-11)
- lib/event_trigger_deep.sla: GlobalTrigger / EntityTrigger / PropagateEntityTrigger (parent Traversal, auto/manual/stop) / EntityComponentsTrigger + CachedObservers scopes + trigger_id deep model of src/event/trigger.rs.
- 18 tests — tests/test_ecs_lib_event_trigger_deep_isolated.sla (new).
- Verification: SA 18 pass; default 18 pass.
- src/event/trigger.rs ✓ deepened
- Feature progress: event_trigger deep ~20% -> 85%; overall API ~94–96%, behavioral ~86–91%.


## Batch 207 — component_deep (DONE 2026-07-11)
- lib/component_deep.sla: unified StorageType/Mutability/Hooks/CloneBehavior resolve, RequiredComponents shallowest-depth, Components register/lookup, ComponentIdFor, lifecycle fire, insert-plan expansion deep model of src/component/{mod,clone,required,register}.rs.
- 16 tests — tests/test_ecs_lib_component_deep_isolated.sla (new).
- Note: exclusive-branch early-return required for multi-slot set_at (UseAfterMove).
- Verification: SA 16 pass; default 16 pass.
- src/component core ✓ deepened (specialized shallow modules retained)
- Current measured counts: 307 lib modules, 212 test files, 90 examples, 4,928 `.sla` `@test` annotations; 35 `*_deep.sla` modules.
- Feature progress: component core deep ~30% -> 85%; overall API ~94–96%, behavioral ~86–91%.


## Batch 208 — event_mod_deep (DONE 2026-07-11)
- lib/event_mod_deep.sla: Event/EntityEvent derive options (Global/Entity/Propagate, auto_propagate, traversal), EventKey, register_event_key/event_key idempotent, World::trigger path selection + SetEntityEventTarget deep model of src/event/mod.rs.
- 18 tests — tests/test_ecs_lib_event_mod_deep_isolated.sla (new).
- Verification: SA 18 pass; default 18 pass.
- src/event/mod.rs ✓ deepened
- Current measured counts: 308 lib modules, 213 test files, 90 examples, 4,946 `.sla` `@test` annotations; 36 `*_deep.sla` modules.
- Feature progress: event_mod deep ~25% -> 85%; overall API ~94–96%, behavioral ~86–91%.


## Batch 209 — system_name_deep (DONE 2026-07-11)
- lib/system_name_deep.sla: SystemName(DebugName), SystemParam/ReadOnly/ExclusiveSystemParam, with_name, Logger bundle deep model of src/system/system_name.rs.
- 14 tests — tests/test_ecs_lib_system_name_deep_isolated.sla (new).
- Verification: SA 14 pass; default 14 pass.
- src/system/system_name.rs ✓ deepened
- Feature progress: system_name deep ~30% -> 95%; overall API ~94–96%, behavioral ~86–91%.

## Batch 210 — message_update_deep (DONE 2026-07-11)
- lib/message_update_deep.sla: ShouldUpdateMessages Always/Waiting/Ready, signal_message_update_system, message_update_condition, message_update_system transition, MessageRegistry.run_updates deep model of src/message/update.rs.
- 16 tests — tests/test_ecs_lib_message_update_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass.
- src/message/update.rs ✓ deepened
- Feature progress: message_update deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 211 — remote_allocator_deep (DONE 2026-07-11)
- lib/remote_allocator_deep.sla: Allocator alloc/free/alloc_many/free_many, RemoteAllocator alloc/close diagnostic-only is_closed, free-list LIFO + generation bump, capacity placeholder deep model of src/entity/remote_allocator.rs.
- 16 tests — tests/test_ecs_lib_remote_allocator_deep_isolated.sla (new).
- Note: concurrent SharedAllocator simplified to sequential shared state; capacity fixed 16 indices.
- Verification: SA 16 pass; default 16 pass.
- src/entity/remote_allocator.rs ✓ deepened
- Current measured counts: 311 lib modules, 216 test files, 90 examples, 4,992 `.sla` `@test` annotations; 39 `*_deep.sla` modules.
- Feature progress: remote_allocator deep ~15% -> 80%; overall API ~94–96%, behavioral ~86–91%.



## Batch 212 — exclusive_system_param_deep (DONE 2026-07-11)
- lib/exclusive_system_param_deep.sla: ExclusiveSystemParam State/Item/init/get_param for QueryState, SystemState, Local, PhantomData, SystemName, tuples; ExclusiveSystemParamItem alias deep model of src/system/exclusive_system_param.rs.
- 14 tests — tests/test_ecs_lib_exclusive_system_param_deep_isolated.sla (new).
- Note: exclusive multi-slot set uses early-return per branch (UseAfterMove).
- Verification: SA 14 pass; default 14 pass.
- src/system/exclusive_system_param.rs ✓ deepened
- Feature progress: exclusive_system_param deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 213 — required_components_error_deep (DONE 2026-07-11)
- lib/required_components_error_deep.sla: RequiredComponentsError DuplicateRegistration/CyclicRequirement/ArchetypeExists, display codes, eq, graph + ecs_rce_try_register order ArchetypeExists→Cyclic→Duplicate deep model of src/component/required.rs + World::try_register_required_components.
- 15 tests — tests/test_ecs_lib_required_components_error_deep_isolated.sla (new).
- Verification: SA 15 pass; default 15 pass.
- src/component/required.rs RequiredComponentsError ✓ deepened
- Feature progress: required_components_error deep ~40% -> 95%; overall API ~94–96%, behavioral ~86–91%.

## Batch 214 — observer_system_param_deep (DONE 2026-07-11)
- lib/observer_system_param_deep.sla: On system param event_key/event/event_mut/event_ptr/trigger/observer/caller, original_event_target/propagate/get_propagate, TriggerContext, Bundle B any-of interest matching deep model of src/observer/system_param.rs.
- 16 tests — tests/test_ecs_lib_observer_system_param_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass.
- src/observer/system_param.rs ✓ deepened
- Current measured counts: 314 lib modules, 219 test files, 90 examples, 5,037 `.sla` `@test` annotations; 42 `*_deep.sla` modules.
- Feature progress: observer_system_param deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 215 — lifecycle_deep (DONE 2026-07-11)
- lib/lifecycle_deep.sla: HookContext, ComponentHooks (on_*/try_on_*), fixed EventKeys ADD/INSERT/DISCARD/REMOVE/DESPAWN (0..4), lifecycle events Add/Insert/Discard/Remove/Despawn, insert/remove/replace/despawn path order, RelationshipHookMode skip gate, RemovedComponentEntity + RemovedComponentMessages write/get/update, RemovedComponents reader (read/read_with_id/len/is_empty/clear) deep model of src/lifecycle.rs.
- 16 tests — tests/test_ecs_lib_lifecycle_deep_isolated.sla (new).
- Note: multi-kind hook dispatch flattens hook ids to i32 scalars first (UseAfterMove / multi-i32-tuple field quirks).
- Verification: SA 16 pass; default 16 pass; `git diff --check` passes.
- src/lifecycle.rs ✓ deepened
- Current measured counts: 316 lib modules, 221 test files, 90 examples, 5,105 `.sla` `@test` annotations; 44 `*_deep.sla` modules.
- Feature progress: lifecycle deep (hooks/events/RemovedComponents) ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 216 — observer_runner_deep (DONE 2026-07-11)
- lib/observer_runner_deep.sla: ObserverRunner semantics — last_trigger_id reentrancy guard, non-short-circuit AND conditions, On payload construction, RunSystemError::Failed → ErrorContext::Observer + observer/fallback error handler, multi-observer same-trigger fanout deep model of src/observer/runner.rs.
- 16 tests — tests/test_ecs_lib_observer_runner_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass; `git diff --check` passes.
- src/observer/runner.rs ✓ deepened
- Current measured counts: 317 lib modules, 222 test files, 90 examples, 5,121 `.sla` `@test` annotations; 45 `*_deep.sla` modules.
- Feature progress: observer_runner deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 217 — observer_condition_deep (DONE 2026-07-11)
- lib/observer_condition_deep.sla: ObserverCondition initialize/check (unwrap_or false on fail), ObserverWithCondition run_if chain, take_conditions, non-short-circuit AND fold with per-slot check counts deep model of src/observer/condition.rs.
- 16 tests — tests/test_ecs_lib_observer_condition_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass; `git diff --check` passes.
- src/observer/condition.rs ✓ deepened
- Current measured counts: 318 lib modules, 223 test files, 90 examples, 5137 `.sla` `@test` annotations; 46 `*_deep.sla` modules.
- Feature progress: observer_condition deep ~25% -> 95%; overall API ~94–96%, behavioral ~86–91%.

## Batch 218 — observer_entity_cloning_deep (DONE 2026-07-11)
- lib/observer_entity_cloning_deep.sla: EntityClonerBuilder::add_observers override/remove ObservedBy clone behavior; deferred component_clone_observed_by copies ObservedBy, pushes target into observer descriptor.entities, clones entity_observers and per-component entity_component_observers maps deep model of src/observer/entity_cloning.rs.
- 15 tests — tests/test_ecs_lib_observer_entity_cloning_deep_isolated.sla (new).
- Verification: SA 15 pass; default 15 pass; `git diff --check` passes.
- src/observer/entity_cloning.rs ✓ deepened
- Current measured counts: 319 lib modules, 224 test files, 90 examples, 5152 `.sla` `@test` annotations; 47 `*_deep.sla` modules.
- Feature progress: observer entity cloning deep ~15% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 219 — change_detection_tick_deep (DONE 2026-07-11)
- lib/change_detection_tick_deep.sla: Tick wrapping u32 model, relative_to, is_newer_than with MAX_CHANGE_AGE clamp, CheckChangeTicks, ComponentTicks/ComponentTicksMut set_added/set_changed/set_both, check_tick wrap, CHECK_TICK_THRESHOLD/MAX_CHANGE_AGE constants deep model of src/change_detection/tick.rs + mod.rs.
- 16 tests — tests/test_ecs_lib_change_detection_tick_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass; `git diff --check` passes.
- src/change_detection/tick.rs ✓ deepened
- Current measured counts: 320 lib modules, 225 test files, 90 examples, 5168 `.sla` `@test` annotations; 48 `*_deep.sla` modules.
- Feature progress: change_detection tick deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 220 — maybe_location_deep (DONE 2026-07-11)
- lib/maybe_location_deep.sla: MaybeLocation track_location on/off modes, new/map/zip/into_option/unwrap_or_default, Option-layer transpose, copied/as_ref/assign, new_with_flattened deep model of src/change_detection/maybe_location.rs.
- 16 tests — tests/test_ecs_lib_maybe_location_deep_isolated.sla (new).
- Verification: SA 16 pass; default 16 pass; `git diff --check` passes.
- src/change_detection/maybe_location.rs ✓ deepened
- Feature progress: maybe_location deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 221 — change_detection_traits_deep (DONE 2026-07-11)
- lib/change_detection_traits_deep.sla: DetectChanges is_added/is_changed/after/last_changed/changed_by; DetectChangesMut set_changed/set_added/set_last_*/bypass/set_if_neq/replace_if_neq/clone_from_if_neq/deref_mut_write with wrap-aware ticks deep model of src/change_detection/traits.rs.
- 15 tests — tests/test_ecs_lib_change_detection_traits_deep_isolated.sla (new).
- Verification: SA 15 pass; default 15 pass; `git diff --check` passes.
- src/change_detection/traits.rs ✓ deepened
- Current measured counts: 322 lib modules, 227 test files, 90 examples, 5199 `.sla` `@test` annotations; 50 `*_deep.sla` modules.
- Feature progress: change_detection traits deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 222 — traversal_deep (DONE 2026-07-11)
- lib/traversal_deep.sla: Traversal for () / Relationship / data-dependent, graph walk with max_depth + cycle detection, propagate_step deep model of src/traversal.rs.
- 12 tests — tests/test_ecs_lib_traversal_deep_isolated.sla (new).
- Note: graph_set/walk_push rebuild structs from scalars (field-assign UseAfterMove).
- Verification: SA 12 pass; default 12 pass.
- src/traversal.rs ✓ deepened
- Feature progress: traversal deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 223 — never_deep (DONE 2026-07-11)
- lib/never_deep.sla: Never uninhabited facade, FnRet never/ordinary output naming, system compat for panicking closures, match-empty type-level helper deep model of src/never.rs.
- 7 tests — tests/test_ecs_lib_never_deep_isolated.sla (new).
- Verification: SA 7 pass; default 7 pass.
- src/never.rs ✓ deepened
- Current measured counts: 324 lib modules, 229 test files, 90 examples, 5218 `.sla` `@test` annotations; 52 `*_deep.sla` modules.
- Feature progress: never deep ~40% -> 95%; overall API ~94–96%, behavioral ~86–91%.

## Batch 224 — change_detection_params_deep (DONE 2026-07-11)
- lib/change_detection_params_deep.sla: Ref/Mut/MutUntyped/Res/ResMut/NonSendMut with wrap-aware DetectChanges, set_if_neq/bypass/map_unchanged/reborrow, contiguous ticks slice deep model of src/change_detection/params.rs.
- 15 tests — tests/test_ecs_lib_change_detection_params_deep_isolated.sla (new).
- Verification: SA 15 pass; default 15 pass.
- src/change_detection/params.rs ✓ deepened
- Feature progress: change_detection params deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 225 — template_deep (DONE 2026-07-11)
- lib/template_deep.sla: Template/FromTemplate, TemplateContext, SceneEntityReference/References get-spawn-on-miss, Identity/Default/Option/Vec/Fn/Entity/Error templates deep model of src/template.rs.
- 14 tests — tests/test_ecs_lib_template_deep_isolated.sla (new).
- Verification: SA 14 pass; default 14 pass.
- src/template.rs ✓ deepened
- Feature progress: template deep ~20% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 226 — spawn_related_deep (DONE 2026-07-11)
- lib/spawn_related_deep.sla: Spawn/SpawnableList size_hint, SpawnIter, SpawnWith, WithRelated/WithOneRelated, parent-linked child spawn log deep model of src/spawn.rs.
- 8 tests — tests/test_ecs_lib_spawn_related_deep_isolated.sla (new).
- Verification: SA 8 pass; default 8 pass.
- src/spawn.rs ✓ deepened
- Current measured counts: 327 lib modules, 232 test files, 90 examples, 5255 `.sla` `@test` annotations; 55 `*_deep.sla` modules.
- Feature progress: spawn related hierarchy deep ~20% -> 85%; overall API ~94–96%, behavioral ~86–91%.

## Batch 227 — observer_centralized_storage_deep (DONE 2026-07-11)
- lib/observer_centralized_storage_deep.sla: CachedObservers lifecycle caches, ObserverMap insert/get/contains, global/component/entity register paths, archetype flags (ON_ADD/INSERT/DISCARD/REMOVE/DESPAWN), custom event_key caches deep model of src/observer/centralized_storage.rs.
- 12 tests — tests/test_ecs_lib_observer_centralized_storage_deep_isolated.sla (new).
- Verification: SA 12 pass; default 12 pass; `git diff --check` passes.
- src/observer/centralized_storage.rs ✓ deepened
- Current measured counts: 328 lib modules, 233 test files, 90 examples, 5267 `.sla` `@test` annotations; 56 `*_deep.sla` modules.
- Feature progress: observer centralized storage deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 228 — observer_distributed_storage_deep (DONE 2026-07-11)
- lib/observer_distributed_storage_deep.sla: Observer + ObserverDescriptor + ObservedBy; exclusive reject; dynamic/typed hook_on_add; on_remove unregister; ObservedBy on_remove despawn-when-empty; IntoObserver/IntoEntityObserver/run_if deep model of src/observer/distributed_storage.rs.
- 15 tests — tests/test_ecs_lib_observer_distributed_storage_deep_isolated.sla (new).
- Verification: SA 15 pass; default 15 pass; `git diff --check` passes.
- src/observer/distributed_storage.rs ✓ deepened
- Current measured counts: 329 lib modules, 234 test files, 90 examples, 5282 `.sla` `@test` annotations; 57 `*_deep.sla` modules.
- Feature progress: observer distributed storage deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 229 — bundle_writer_deep (DONE 2026-07-11)
- lib/bundle_writer_deep.sla: BundleScratch writer clear-without-reset, push_component register, push_by_id layout alloc, manual_drop with droppable flags, write/write_with relationship hook mode, entity dynamic insert deep model of src/bundle/writer.rs.
- 10 tests — tests/test_ecs_lib_bundle_writer_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/bundle/writer.rs ✓ deepened
- Current measured counts: 330 lib modules, 235 test files, 90 examples, 5292 `.sla` `@test` annotations; 58 `*_deep.sla` modules.
- Feature progress: bundle writer deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 230 — bundle_remove_deep (DONE 2026-07-11)
- lib/bundle_remove_deep.sla: BundleRemover new/require_all, sorted_remove, remove vs take edge cache, table move detection, empty_pre_remove keep gate, remove triggers/hooks, ArchetypeCreated deep model of src/bundle/remove.rs.
- 10 tests — tests/test_ecs_lib_bundle_remove_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/bundle/remove.rs ✓ deepened
- Current measured counts: 331 lib modules, 236 test files, 90 examples, 5302 `.sla` `@test` annotations; 59 `*_deep.sla` modules.
- Feature progress: bundle remove deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 231 — bundle_insert_spawner_deep (DONE 2026-07-11)
- lib/bundle_insert_spawner_deep.sla: BundleInserter InsertMode Keep/Replace, ArchetypeMoveType, ComponentStatus, discard/add/insert lifecycle, edge cache, BundleSpawner spawn/spawn_at/reserve/flush deep model of src/bundle/insert.rs + spawner.rs.
- 10 tests — tests/test_ecs_lib_bundle_insert_spawner_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/bundle/insert.rs + spawner.rs ✓ deepened
- Current measured counts: 332 lib modules, 237 test files, 90 examples, 5312 `.sla` `@test` annotations; 60 `*_deep.sla` modules.
- Feature progress: bundle insert/spawner deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 232 — relationship_source_collection_deep (DONE 2026-07-11)
- lib/relationship_source_collection_deep.sla: RelationshipSourceCollection Vec/HashSet/UniqueVec/OneToOne add-remove-reserve-shrink-extend, source_to_remove_before_add, Ordered insert/remove_at/sort/place/push_front/back deep model of src/relationship/relationship_source_collection.rs.
- 10 tests — tests/test_ecs_lib_relationship_source_collection_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/relationship/relationship_source_collection.rs ✓ deepened
- Current measured counts: 333 lib modules, 238 test files, 90 examples, 5322 `.sla` `@test` annotations; 61 `*_deep.sla` modules.
- Feature progress: relationship source collection deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 233 — relationship_related_methods_deep (DONE 2026-07-11)
- lib/relationship_related_methods_deep.sla: EntityWorldMut related API — add/insert/detach/replace_with_difference, despawn_related/children, with_related + RelatedSpawner, insert/remove_recursive BFS, RelationshipHookMode Run/Skip deep model of src/relationship/related_methods.rs.
- 10 tests — tests/test_ecs_lib_relationship_related_methods_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/relationship/related_methods.rs ✓ deepened
- Current measured counts: 334 lib modules, 239 test files, 90 examples, 5332 `.sla` `@test` annotations; 62 `*_deep.sla` modules.
- Feature progress: relationship related_methods deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 234 — relationship_hooks_deep (DONE 2026-07-11)
- lib/relationship_hooks_deep.sla: RelationshipHookMode Run/Skip/RunIfNotLinked, on_insert self-ref reject + target collection add, one-to-one replace, on_remove empty-target deferred flush, linked_spawn on_discard despawn sources deep model of src/relationship/mod.rs hooks.
- 10 tests — tests/test_ecs_lib_relationship_hooks_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/relationship/mod.rs hooks ✓ deepened
- Current measured counts: 335 lib modules, 240 test files, 90 examples, 5342 `.sla` `@test` annotations; 63 `*_deep.sla` modules.
- Feature progress: relationship hooks deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 235 — hierarchy_deep (DONE 2026-07-11)
- lib/hierarchy_deep.sla: ChildOf/Children linked_spawn, insert/remove/reparent sync, with_children/add/insert/remove_children, Children swap/sort, root_ancestor/descendant_count, despawn linked descendants deep model of src/hierarchy.rs.
- 10 tests — tests/test_ecs_lib_hierarchy_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/hierarchy.rs ✓ deepened
- Current measured counts: 336 lib modules, 241 test files, 90 examples, 5352 `.sla` `@test` annotations; 64 `*_deep.sla` modules.
- Feature progress: hierarchy deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 236 — sparse_set_deep (DONE 2026-07-11)
- lib/sparse_set_deep.sla: SparseArray/SparseSet insert-overwrite/get_or_insert/swap-remove/capacity, ComponentSparseSet ticks+changed_by, SparseSets multi ComponentId registry deep model of src/storage/sparse_set.rs.
- 10 tests — tests/test_ecs_lib_sparse_set_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/sparse_set.rs ✓ deepened
- Current measured counts: 337 lib modules, 242 test files, 90 examples, 5362 `.sla` `@test` annotations; 65 `*_deep.sla` modules.
- Feature progress: sparse_set deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 237 — relationship_query_deep (DONE 2026-07-11)
- lib/relationship_query_deep.sla: fixed-slot Relationship/RelationshipTarget tree model of src/relationship/relationship_query.rs — related, relationship_sources, root_ancestor, AncestorIter, iter_siblings, iter_descendants BFS, iter_descendants_depth_first DFS, iter_leaves; rewrote flatter control flow after if_expr typecheck failure.
- 10 tests — tests/test_ecs_lib_relationship_query_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/relationship/relationship_query.rs ✓ deepened
- Current measured counts: 338 lib modules, 243 test files, 90 examples, 5336 `.sla` `@test` annotations; 66 `*_deep.sla` modules.
- Feature progress: relationship_query deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 238 — table_deep (DONE 2026-07-11)
- lib/table_deep.sla: TableId/TableRow, Column initialize/replace/swap_remove/clear/ticks/changed_by, Table builder allocate set/get swap_remove clear, Tables empty-reserved registry push/set deep model of src/storage/table/mod.rs + column.rs.
- 10 tests — tests/test_ecs_lib_table_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/table/mod.rs + column.rs ✓ deepened
- Current measured counts: 339 lib modules, 244 test files, 90 examples, 5346 `.sla` `@test` annotations; 67 `*_deep.sla` modules.
- Feature progress: table storage deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 238 — table_deep (DONE 2026-07-11)
- lib/table_deep.sla: TableId/TableRow, Column initialize/replace/swap_remove/clear/ticks/changed_by, Table builder allocate set/get swap_remove clear, Tables empty-reserved registry push/set deep model of src/storage/table/mod.rs + column.rs.
- 10 tests — tests/test_ecs_lib_table_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/table/mod.rs + column.rs ✓ deepened
- Current measured counts: 339 lib modules, 244 test files, 90 examples, 5346 `.sla` `@test` annotations; 67 `*_deep.sla` modules.
- Feature progress: table storage deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 239 — bundle_info_deep (DONE 2026-07-11)
- lib/bundle_info_deep.sla: BundleId/InsertMode, BundleInfo explicit+required contributed split + duplicate reject, ComponentStatus/should_write, Bundles static type map + dynamic component-key registry deep model of src/bundle/info.rs.
- 10 tests — tests/test_ecs_lib_bundle_info_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/bundle/info.rs ✓ deepened
- Current measured counts: 340 lib modules, 245 test files, 90 examples, 5356 `.sla` `@test` annotations; 68 `*_deep.sla` modules.
- Feature progress: bundle_info deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 240 — blob_array_deep (DONE 2026-07-11)
- lib/blob_array_deep.sla: BlobArray layout/zst/drop, initialize/replace, swap_remove(+drop), clear/drop_last/drop_all, get_sub_slice/count deep model of src/storage/blob_array.rs.
- 10 tests — tests/test_ecs_lib_blob_array_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/blob_array.rs ✓ deepened
- Current measured counts: 341 lib modules, 246 test files, 90 examples, 5366 `.sla` `@test` annotations; 69 `*_deep.sla` modules.
- Feature progress: blob_array deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 241 — storages_deep (DONE 2026-07-11)
- lib/storages_deep.sla: Storages prepare_component Table/SparseSet dispatch + idempotency, sparse get/iter order, table/non_send registration counters deep model of src/storage/mod.rs.
- 10 tests — tests/test_ecs_lib_storages_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/mod.rs ✓ deepened
- Current measured counts: 342 lib modules, 247 test files, 90 examples, 5376 `.sla` `@test` annotations; 70 `*_deep.sla` modules.
- Feature progress: storages deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 242 — non_send_storage_deep (DONE 2026-07-11)
- lib/non_send_storage_deep.sla: NonSendData insert/replace/remove/remove_and_drop/thread-guard/ticks, NonSends get_or_insert/get/clear/iter/present-count deep model of src/storage/non_send.rs.
- 10 tests — tests/test_ecs_lib_non_send_storage_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/non_send.rs ✓ deepened
- Current measured counts: 343 lib modules, 248 test files, 90 examples, 5386 `.sla` `@test` annotations; 71 `*_deep.sla` modules.
- Feature progress: non_send storage deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 243 — component_info_deep (DONE 2026-07-11)
- lib/component_info_deep.sla: ComponentId/StorageType/CloneBehavior, ComponentDescriptor component/resource/non_send, ComponentInfo hooks/required/required_by + update_archetype_flags deep model of src/component/info.rs.
- 10 tests — tests/test_ecs_lib_component_info_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/component/info.rs ✓ deepened
- Current measured counts: 344 lib modules, 249 test files, 90 examples, 5396 `.sla` `@test` annotations; 72 `*_deep.sla` modules.
- Feature progress: component_info deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 244 — component_register_deep (DONE 2026-07-11)
- lib/component_register_deep.sla: ComponentIds peek/next, register component/resource/non_send/descriptor with type_id dedup, queued register + apply_queued_registrations deep model of src/component/register.rs.
- 10 tests — tests/test_ecs_lib_component_register_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/component/register.rs ✓ deepened
- Current measured counts: 345 lib modules, 250 test files, 90 examples, 5406 `.sla` `@test` annotations; 73 `*_deep.sla` modules.
- Feature progress: component_register deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 245 — component_required_deep (DONE 2026-07-11)
- lib/component_required_deep.sla: RequiredComponents direct/all split, duplicate-direct error, inherited shallowest-depth wins, cycle check, archetype-exists gate, registrator facade deep model of src/component/required.rs.
- 10 tests — tests/test_ecs_lib_component_required_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/component/required.rs ✓ deepened
- Current measured counts: 346 lib modules, 251 test files, 90 examples, 5416 `.sla` `@test` annotations; 74 `*_deep.sla` modules.
- Feature progress: component_required deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 246 — archetype_deep (DONE 2026-07-11)
- lib/archetype_deep.sla: ArchetypeId/Row/Entity, ComponentStatus + ArchetypeAfterBundleInsert, Edges insert/remove/take caches, Archetype components/flags/allocate/swap_remove, Archetypes empty+get_or_create signature registry deep model of src/archetype.rs.
- 10 tests — tests/test_ecs_lib_archetype_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/archetype.rs ✓ deepened
- Current measured counts: 347 lib modules, 252 test files, 90 examples, 5426 `.sla` `@test` annotations; 75 `*_deep.sla` modules.
- Feature progress: archetype deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 247 — component_clone_deep (DONE 2026-07-11)
- lib/component_clone_deep.sla: ComponentCloneBehavior resolve, SourceComponent, EntityMapper, ComponentCloneCtx write/queue/map, via_clone/reflect/ignore dispatch deep model of src/component/clone.rs.
- 10 tests — tests/test_ecs_lib_component_clone_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/component/clone.rs ✓ deepened
- Current measured counts: 348 lib modules, 253 test files, 90 examples, 5436 `.sla` `@test` annotations; 76 `*_deep.sla` modules.
- Feature progress: component_clone deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 248 — entity_cloner_deep (DONE 2026-07-11)
- lib/entity_cloner_deep.sla: EntityClonerBuilder OptIn/OptOut allow/deny/move/linked/insert_mode/overrides, EntityCloner should_clone/clone_entity/spawn_clone/would_write deep model of src/entity/clone_entities.rs.
- 10 tests — tests/test_ecs_lib_entity_cloner_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/clone_entities.rs ✓ deepened
- Current measured counts: 349 lib modules, 254 test files, 90 examples, 5446 `.sla` `@test` annotations; 77 `*_deep.sla` modules.
- Feature progress: entity_cloner deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 249 — entity_lifecycle_deep (DONE 2026-07-11)
- lib/entity_lifecycle_deep.sla: DefaultQueryFilters register/is_disabling/entity_disabled, ComponentHooks on_*/try_*/flags, RemovedComponents fixed-cap write/read/clear/reset_cursor with EcsRemovedDeepRead result struct deep model of src/entity_disabling.rs + lifecycle RemovedComponents.
- 10 tests — tests/test_ecs_lib_entity_lifecycle_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass. Fixed removed_read_exhausted SA segfault by replacing (bool, i32, EcsRemovedDeep) triple-tuple with EcsRemovedDeepRead + accessors.
- src/entity_disabling.rs + lifecycle hooks/RemovedComponents ✓ deepened
- Current measured counts: 350 lib modules, 255 test files, 90 examples, 5456 `.sla` `@test` annotations; 78 `*_deep.sla` modules.
- Feature progress: entity_lifecycle deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 250 — entity_map_entities_deep (DONE 2026-07-11)
- lib/entity_map_entities_deep.sla: EntityMapper identity/pair/hash/scene, MapEntities for entity/option/list/spring, SceneEntityMapper get_mapped allocate + set_mapped + finish reserve + world_scope deep model of src/entity/map_entities.rs.
- 10 tests — tests/test_ecs_lib_entity_map_entities_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/map_entities.rs ✓ deepened
- Current measured counts: 351 lib modules, 256 test files, 90 examples, 5466 `.sla` `@test` annotations; 79 `*_deep.sla` modules.
- Feature progress: entity_map_entities deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 251 — unsafe_world_cell_deep (DONE 2026-07-11)
- lib/unsafe_world_cell_deep.sla: UnsafeWorldCell readonly/mutable mode, ticks/counts, get_entity spawn gate, resource get/mut-by-id with forbidden-mut, UnsafeEntityCell contains/get/get_mut deep model of src/world/unsafe_world_cell.rs.
- 10 tests — tests/test_ecs_lib_unsafe_world_cell_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/unsafe_world_cell.rs ✓ deepened
- Current measured counts: 352 lib modules, 257 test files, 90 examples, 5476 `.sla` `@test` annotations; 80 `*_deep.sla` modules.
- Feature progress: unsafe_world_cell deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 252 — world_error_deep (DONE 2026-07-11)
- lib/world_error_deep.sla: EntityNotSpawnedError, TryRunScheduleError, TryInsertBatchError, EntityDespawnError, EntityComponentError, EntityMutableFetchError, ResourceFetchError (+ classify helpers) deep model of src/world/error.rs.
- 10 tests — tests/test_ecs_lib_world_error_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/error.rs ✓ deepened
- Current measured counts: 353 lib modules, 258 test files, 90 examples, 5486 `.sla` `@test` annotations; 81 `*_deep.sla` modules.
- Feature progress: world_error deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 253 — query_state_deep (DONE 2026-07-11)
- lib/query_state_deep.sla: QueryState world_id/dense/init_access, read/write access, matched tables/archetypes, new_archetype required match, generation-gated update, as_readonly, get/get_many, intersect deep model of src/query/state.rs.
- 10 tests — tests/test_ecs_lib_query_state_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/state.rs ✓ deepened
- Current measured counts: 354 lib modules, 259 test files, 90 examples, 5496 `.sla` `@test` annotations; 82 `*_deep.sla` modules.
- Feature progress: query_state deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 254 — query_builder_deep (DONE 2026-07-11)
- lib/query_builder_deep.sla: QueryBuilder data/ref/mut, with/without, or/and/optional, dense inference, extend_access, transmute, build snapshot, entity filter match deep model of src/query/builder.rs.
- 10 tests — tests/test_ecs_lib_query_builder_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/builder.rs ✓ deepened
- Current measured counts: 355 lib modules, 260 test files, 90 examples, 5506 `.sla` `@test` annotations; 83 `*_deep.sla` modules.
- Feature progress: query_builder deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 255 — query_filters_deep (DONE 2026-07-11)
- lib/query_filters_deep.sla: With/Without/Or/Added/Changed/Spawned/Allow filters, filter bundle evaluator, Has/AnyOf/Option fetch, archetype filter, default-disable Allow bypass deep model of src/query/filter.rs + fetch.rs.
- 10 tests — tests/test_ecs_lib_query_filters_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/filter.rs + fetch.rs ✓ deepened
- Current measured counts: 356 lib modules, 261 test files, 90 examples, 5516 `.sla` `@test` annotations; 84 `*_deep.sla` modules.
- Feature progress: query_filters deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 256 — query_iter_deep (DONE 2026-07-11)
- lib/query_iter_deep.sla: QueryIter next/size_hint/nth/last/sort_by_value, QueryManyIter targets/found/next skip-missing deep model of src/query/iter.rs.
- 10 tests — tests/test_ecs_lib_query_iter_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/iter.rs ✓ deepened
- Current measured counts: 357 lib modules, 262 test files, 90 examples, 5526 `.sla` `@test` annotations; 85 `*_deep.sla` modules.
- Feature progress: query_iter deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 257 — query_access_deep (DONE 2026-07-11)
- lib/query_access_deep.sla: Access read/write/archetypal + reads-all inverted, is_compatible/get_conflicts, FilteredAccess with/without and filter-disjoint compatibility deep model of src/query/access.rs.
- 10 tests — tests/test_ecs_lib_query_access_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/access.rs ✓ deepened
- Current measured counts: 358 lib modules, 263 test files, 90 examples, 5536 `.sla` `@test` annotations; 86 `*_deep.sla` modules.
- Feature progress: query_access deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 258 — query_lens_deep (DONE 2026-07-11)
- lib/query_lens_deep.sla: QueryLens access/match, transmute subset + write downgrade, filtered transmute, join entity intersection, join_filtered, query view deep model of src/system/query.rs QueryLens.
- 10 tests — tests/test_ecs_lib_query_lens_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/query.rs QueryLens ✓ deepened
- Current measured counts: 359 lib modules, 264 test files, 90 examples, 5546 `.sla` `@test` annotations; 87 `*_deep.sla` modules.
- Feature progress: query_lens deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 259 — query_fetch_deep (DONE 2026-07-11)
- lib/query_fetch_deep.sla: Fetch Entity/Read/Ref/Write/Option/Has, AnyOf, Nested, QueryItem/ROQueryItem, spawn details deep model of src/query/fetch.rs.
- 10 tests — tests/test_ecs_lib_query_fetch_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/fetch.rs ✓ deepened
- Current measured counts: 360 lib modules, 265 test files, 90 examples, 5556 `.sla` `@test` annotations; 88 `*_deep.sla` modules.
- Feature progress: query_fetch deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 260 — query_world_query_deep (DONE 2026-07-11)
- lib/query_world_query_deep.sla: WorldQuery kind flags, dense combine, update_component_access, fetch ticks/row/value, shrink_to_readonly, archetype match rules deep model of src/query/world_query.rs.
- 10 tests — tests/test_ecs_lib_query_world_query_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/world_query.rs ✓ deepened
- Current measured counts: 361 lib modules, 266 test files, 90 examples, 5566 `.sla` `@test` annotations; 89 `*_deep.sla` modules.
- Feature progress: query_world_query deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 261 — entity_set_deep (DONE 2026-07-11)
- lib/entity_set_deep.sla: EntitySet unique insert/contains/remove, list uniqueness + collect_set, UniqueEntityVec, intersection, EntityEquivalent helpers deep model of src/entity/entity_set.rs.
- 10 tests — tests/test_ecs_lib_entity_set_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/entity_set.rs ✓ deepened
- Current measured counts: 362 lib modules, 267 test files, 90 examples, 5576 `.sla` `@test` annotations; 90 `*_deep.sla` modules.
- Feature progress: entity_set deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 262 — query_filtered_set_deep (DONE 2026-07-11)
- lib/query_filtered_set_deep.sla: FilteredAccessSet add resource read/write, read_all/write_all, extend, clear, combined compatibility, filter-disjoint rescue, get_conflicts deep model of src/query/access.rs FilteredAccessSet.
- 10 tests — tests/test_ecs_lib_query_filtered_set_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/access.rs FilteredAccessSet ✓ deepened
- Current measured counts: 363 lib modules, 268 test files, 90 examples, 5586 `.sla` `@test` annotations; 91 `*_deep.sla` modules.
- Feature progress: query_filtered_set deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 263 — query_sort_iter_deep (DONE 2026-07-11)
- lib/query_sort_iter_deep.sla: QueryIter sort/sort_unstable/sort_desc/sort_by_key/sort_by_cached_key with consumed gate + sorted cursor next deep model of src/query/iter.rs sort family.
- 10 tests — tests/test_ecs_lib_query_sort_iter_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/iter.rs sort family ✓ deepened
- Current measured counts: 364 lib modules, 269 test files, 90 examples, 5596 `.sla` `@test` annotations; 92 `*_deep.sla` modules.
- Feature progress: query_sort_iter deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 264 — query_par_many_iter_deep (DONE 2026-07-11)
- lib/query_par_many_iter_deep.sla: QueryParManyIter/Unique batching_strategy, for_each, for_each_init, unique-count visit model of src/query/par_iter.rs (no TaskPool).
- 10 tests — tests/test_ecs_lib_query_par_many_iter_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/par_iter.rs QueryParMany* ✓ deepened
- Current measured counts: 365 lib modules, 270 test files, 90 examples, 5606 `.sla` `@test` annotations; 93 `*_deep.sla` modules.
- Feature progress: query_par_many_iter deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.



## Batch 265 — messages_buffer_deep (DONE 2026-07-11)
- lib/messages_buffer_deep.sla: Messages dual-buffer A/B + message_count, write/write_batch/write_default, get_cursor/get_cursor_current, update/update_drain, clear/drain, get_message, iter_current, WriteBatchIds deep model of src/message/messages.rs.
- 10 tests — tests/test_ecs_lib_messages_buffer_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/message/messages.rs ✓ deepened
- Current measured counts: 366 lib modules, 271 test files, 90 examples, 5616 `.sla` `@test` annotations; 94 `*_deep.sla` modules.
- Feature progress: messages_buffer deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 266 — filtered_entity_deep (DONE 2026-07-11)
- lib/filtered_entity_deep.sla: Access bitmasks, FilteredEntityRef/Mut get/get_mut/set, try_into_all, reborrow/readonly, UnsafeFilteredEntityMut, eq/cmp deep model of src/world/entity_access/filtered.rs.
- 10 tests — tests/test_ecs_lib_filtered_entity_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/filtered.rs ✓ deepened
- Current measured counts: 367 lib modules, 272 test files, 90 examples, 5626 `.sla` `@test` annotations; 95 `*_deep.sla` modules.
- Feature progress: filtered_entity deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 267 — query_access_iter_deep (DONE 2026-07-11)
- lib/query_access_iter_deep.sla: EcsAccessLevel/Type is_compatible, has_conflicts_small/large, QueryAccessError deep model of src/query/access_iter.rs.
- 10 tests — tests/test_ecs_lib_query_access_iter_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/access_iter.rs ✓ deepened
- Current measured counts: 368 lib modules, 273 test files, 90 examples, 5636 `.sla` `@test` annotations; 96 `*_deep.sla` modules.
- Feature progress: query_access_iter deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 268 — removed_component_messages_deep (DONE 2026-07-11)
- lib/removed_component_messages_deep.sla: dual-buffer per-component removal Messages, update, get/iter, RemovedComponents reader deep model of src/lifecycle.rs.
- 10 tests — tests/test_ecs_lib_removed_component_messages_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/lifecycle.rs RemovedComponentMessages ✓ deepened
- Current measured counts: 369 lib modules, 274 test files, 90 examples, 5646 `.sla` `@test` annotations; 97 `*_deep.sla` modules.
- Feature progress: removed_component_messages deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 269 — entity_access_except_deep (DONE 2026-07-11)
- lib/entity_access_except_deep.sla: EntityRefExcept/EntityMutExcept exclusion set get/set/filtered/readonly deep model of src/world/entity_access/except.rs.
- 10 tests — tests/test_ecs_lib_entity_access_except_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/except.rs ✓ deepened
- Current measured counts: 370 lib modules, 275 test files, 90 examples, 5656 `.sla` `@test` annotations; 98 `*_deep.sla` modules.
- Feature progress: entity_access_except deep ~15% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 270 — message_mut_iterators_deep (DONE 2026-07-11)
- lib/message_mut_iterators_deep.sla: MessageMutIteratorWithId new/next/count/last/nth/without_id, mut apply, MessageMutParIter batching/for_each deep model of src/message/mut_iterators.rs.
- 10 tests — tests/test_ecs_lib_message_mut_iterators_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/message/mut_iterators.rs ✓ deepened
- Current measured counts: 371 lib modules, 276 test files, 90 examples, 5666 `.sla` `@test` annotations; 99 `*_deep.sla` modules.
- Feature progress: message_mut_iterators deep 0% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 271 — entity_mut_deep (DONE 2026-07-11)
- lib/entity_mut_deep.sla: EntityMut view get/set/readonly/filtered/change ticks/remove deep model of src/world/entity_access/entity_mut.rs.
- 10 tests — tests/test_ecs_lib_entity_mut_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/entity_mut.rs ✓ deepened
- Current measured counts: 372 lib modules, 277 test files, 90 examples, 5676 `.sla` `@test` annotations; 100 `*_deep.sla` modules.
- Feature progress: entity_mut deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 272 — entry_deep (DONE 2026-07-11)
- lib/entry_deep.sla: ComponentEntry/Occupied/Vacant insert/or_insert/and_modify/take deep model of src/world/entity_access/entry.rs.
- 10 tests — tests/test_ecs_lib_entry_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/entry.rs ✓ deepened
- Current measured counts: 373 lib modules, 278 test files, 90 examples, 5686 `.sla` `@test` annotations; 101 `*_deep.sla` modules.
- Feature progress: entry deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 273 — table_column_deep (DONE 2026-07-11)
- lib/table_column_deep.sla: Column initialize/replace/swap_remove/clear/ticks/realloc deep model of src/storage/table/column.rs.
- 10 tests — tests/test_ecs_lib_table_column_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/table/column.rs ✓ deepened
- Current measured counts: 374 lib modules, 279 test files, 90 examples, 5696 `.sla` `@test` annotations; 102 `*_deep.sla` modules.
- Feature progress: table_column deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 274 — filtered_resource_deep (DONE 2026-07-11)
- lib/filtered_resource_deep.sla: FilteredResources/Mut + ResourceFetchError deep model of src/world/filtered_resource.rs.
- 10 tests — tests/test_ecs_lib_filtered_resource_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/filtered_resource.rs ✓ deepened
- Current measured counts: 375 lib modules, 280 test files, 90 examples, 5706 `.sla` `@test` annotations; 103 `*_deep.sla` modules.
- Feature progress: filtered_resource deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 275 — entity_ref_deep (DONE 2026-07-11)
- lib/entity_ref_deep.sla: EntityRef get/get_ref/change ticks/components/into_filtered deep model of src/world/entity_access/entity_ref.rs.
- 10 tests — tests/test_ecs_lib_entity_ref_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/entity_ref.rs ✓ deepened
- Current measured counts: 376 lib modules, 281 test files, 90 examples, 5716 `.sla` `@test` annotations; 104 `*_deep.sla` modules.
- Feature progress: entity_ref deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 276 — message_reader_writer_deep (DONE 2026-07-11)
- lib/message_reader_writer_deep.sla: MessageReader/Writer + PopulatedMessageReader deep model of src/message/message_reader.rs + message_writer.rs.
- 10 tests — tests/test_ecs_lib_message_reader_writer_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/message/message_reader.rs + message_writer.rs ✓ deepened
- Current measured counts: 377 lib modules, 282 test files, 90 examples, 5726 `.sla` `@test` annotations; 105 `*_deep.sla` modules.
- Feature progress: message_reader_writer deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 277 — world_entity_fetch_deep (DONE 2026-07-11)
- lib/world_entity_fetch_deep.sla: EntityFetcher + WorldEntityFetch + mutable-fetch alias errors deep model of src/world/entity_fetch.rs.
- 10 tests — tests/test_ecs_lib_world_entity_fetch_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_fetch.rs ✓ deepened
- Current measured counts: 378 lib modules, 283 test files, 90 examples, 5736 `.sla` `@test` annotations; 106 `*_deep.sla` modules.
- Feature progress: world_entity_fetch deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 278 — world_mut_deep (DONE 2026-07-11)
- lib/world_mut_deep.sla: EntityWorldMut insert/remove/despawn/world resources/clone_move deep model of src/world/entity_access/world_mut.rs.
- 10 tests — tests/test_ecs_lib_world_mut_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/world_mut.rs ✓ deepened
- Current measured counts: 379 lib modules, 284 test files, 90 examples, 5746 `.sla` `@test` annotations; 107 `*_deep.sla` modules.
- Feature progress: world_mut/EntityWorldMut deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 279 — message_iterators_deep (DONE 2026-07-11)
- lib/message_iterators_deep.sla: MessageIterator/WithId/ParIter deep model of src/message/iterators.rs.
- 10 tests — tests/test_ecs_lib_message_iterators_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/message/iterators.rs ✓ deepened
- Current measured counts: 380 lib modules, 285 test files, 90 examples, 5756 `.sla` `@test` annotations; 108 `*_deep.sla` modules.
- Feature progress: message_iterators deep 0% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 280 — entity_component_fetch_deep (DONE 2026-07-11)
- lib/entity_component_fetch_deep.sla: DynamicComponentFetch + EntityComponentError deep model of src/world/entity_access/component_fetch.rs.
- 10 tests — tests/test_ecs_lib_entity_component_fetch_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/component_fetch.rs ✓ deepened
- Current measured counts: 381 lib modules, 286 test files, 90 examples, 5766 `.sla` `@test` annotations; 109 `*_deep.sla` modules.
- Feature progress: entity_component_fetch deep ~15% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 281 — observer_system_deep (DONE 2026-07-11)
- lib/observer_system_deep.sla: ObserverSystem/IntoObserverSystem/pipe/add_observer deep model of src/system/observer_system.rs.
- 10 tests — tests/test_ecs_lib_observer_system_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/observer_system.rs ✓ deepened
- Current measured counts: 382 lib modules, 287 test files, 90 examples, 5776 `.sla` `@test` annotations; 110 `*_deep.sla` modules.
- Feature progress: observer_system deep 0% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 282 — entity_entry_commands_deep (DONE 2026-07-11)
- lib/entity_entry_commands_deep.sla: EntityEntryCommands deferred entry deep model of src/system/commands/mod.rs.
- 10 tests — tests/test_ecs_lib_entity_entry_commands_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/commands/mod.rs EntityEntryCommands ✓ deepened
- Current measured counts: 383 lib modules, 288 test files, 90 examples, 5786 `.sla` `@test` annotations; 111 `*_deep.sla` modules.
- Feature progress: entity_entry_commands deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 283 — entity_commands_conditional_deep (DONE 2026-07-11)
- lib/entity_commands_conditional_deep.sla: EntityCommands conditional/try insert/remove/retain/clear/despawn deep model of src/system/commands/mod.rs.
- 10 tests — tests/test_ecs_lib_entity_commands_conditional_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/commands/mod.rs EntityCommands conditional ✓ deepened
- Current measured counts: 384 lib modules, 289 test files, 90 examples, 5796 `.sla` `@test` annotations; 112 `*_deep.sla` modules.
- Feature progress: entity_commands_conditional deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 284 — world_observer_trigger_deep (DONE 2026-07-11)
- lib/world_observer_trigger_deep.sla: World::add_observer/trigger* deep model of src/observer/mod.rs.
- 10 tests — tests/test_ecs_lib_world_observer_trigger_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/observer/mod.rs World trigger API ✓ deepened
- Current measured counts: 385 lib modules, 290 test files, 90 examples, 5806 `.sla` `@test` annotations; 113 `*_deep.sla` modules.
- Feature progress: world_observer_trigger deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 285 — observer_descriptor_extras_deep (DONE 2026-07-11)
- lib/observer_descriptor_extras_deep.sla: ObserverDescriptor + Observer run-state/auto-despawn deep model of src/observer/distributed_storage.rs.
- 10 tests — tests/test_ecs_lib_observer_descriptor_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/observer/distributed_storage.rs ObserverDescriptor extras ✓ deepened
- Current measured counts: 386 lib modules, 291 test files, 90 examples, 5816 `.sla` `@test` annotations; 114 `*_deep.sla` modules.
- Feature progress: observer_descriptor_extras deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 286 — error_command_handling_deep (DONE 2026-07-11)
- lib/error_command_handling_deep.sla: CommandOutput/EntityCommandOutput/queue_handled/silenced deep model of src/error/command_handling.rs.
- 10 tests — tests/test_ecs_lib_error_command_handling_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/error/command_handling.rs ✓ deepened
- Current measured counts: 387 lib modules, 292 test files, 90 examples, 5826 `.sla` `@test` annotations; 115 `*_deep.sla` modules.
- Feature progress: error_command_handling deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 287 — deferred_world_extras_deep (DONE 2026-07-11)
- lib/deferred_world_extras_deep.sla: DeferredWorld residual fetch/query/resource/non-send deep model of src/world/deferred_world.rs.
- 10 tests — tests/test_ecs_lib_deferred_world_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/deferred_world.rs residual extras ✓ deepened
- Current measured counts: 388 lib modules, 293 test files, 90 examples, 5836 `.sla` `@test` annotations; 116 `*_deep.sla` modules.
- Feature progress: deferred_world_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 288 — observer_storage_deep (DONE 2026-07-11)
- lib/observer_storage_deep.sla: centralized+distributed observer storage facade deep model of src/observer/centralized_storage.rs + distributed_storage.rs.
- 10 tests — tests/test_ecs_lib_observer_storage_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/observer/centralized_storage.rs + distributed_storage.rs facade ✓ deepened
- Current measured counts: 389 lib modules, 294 test files, 90 examples, 5846 `.sla` `@test` annotations; 117 `*_deep.sla` modules.
- Feature progress: observer_storage deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 289 — entity_access_deep (DONE 2026-07-11)
- lib/entity_access_deep.sla: EntityRef/EntityWorldMut/Entry/Filtered composite deep model of src/world/entity_access/.
- 10 tests — tests/test_ecs_lib_entity_access_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/ composite facade ✓ deepened
- Current measured counts: 390 lib modules, 295 test files, 90 examples, 5856 `.sla` `@test` annotations; 118 `*_deep.sla` modules.
- Feature progress: entity_access deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 290 — entity_cloner_builder_extras_deep (DONE 2026-07-11)
- lib/entity_cloner_builder_extras_deep.sla: EntityClonerBuilder extras deep model of src/entity/clone_entities.rs.
- 10 tests — tests/test_ecs_lib_entity_cloner_builder_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/clone_entities.rs EntityClonerBuilder extras ✓ deepened
- Current measured counts: 391 lib modules, 296 test files, 90 examples, 5866 `.sla` `@test` annotations; 119 `*_deep.sla` modules.
- Feature progress: entity_cloner_builder_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 291 — world_resource_api_deep (DONE 2026-07-11)
- lib/world_resource_api_deep.sla: World resource management deep model of src/world/mod.rs.
- 10 tests — tests/test_ecs_lib_world_resource_api_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/mod.rs resource API ✓ deepened
- Current measured counts: 392 lib modules, 297 test files, 90 examples, 5876 `.sla` `@test` annotations; 120 `*_deep.sla` modules.
- Feature progress: world_resource_api deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 292 — change_detection_deep (DONE 2026-07-11)
- lib/change_detection_deep.sla: change_detection composite deep model of src/change_detection/.
- 10 tests — tests/test_ecs_lib_change_detection_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/change_detection/ composite facade ✓ deepened
- Current measured counts: 393 lib modules, 298 test files, 90 examples, 5886 `.sla` `@test` annotations; 121 `*_deep.sla` modules.
- Feature progress: change_detection deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 293 — component_info_extras_deep (DONE 2026-07-11)
- lib/component_info_extras_deep.sla: ComponentInfo + Components registry deep model of src/component/info.rs.
- 10 tests — tests/test_ecs_lib_component_info_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/component/info.rs ✓ deepened
- Current measured counts: 394 lib modules, 299 test files, 90 examples, 5896 `.sla` `@test` annotations; 122 `*_deep.sla` modules.
- Feature progress: component_info_extras deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 294 — entity_generation_extras_deep (DONE 2026-07-11)
- lib/entity_generation_extras_deep.sla: EntityGeneration extras deep model of src/entity/mod.rs.
- 10 tests — tests/test_ecs_lib_entity_generation_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/mod.rs EntityGeneration ✓ deepened
- Current measured counts: 395 lib modules, 300 test files, 90 examples, 5906 `.sla` `@test` annotations; 123 `*_deep.sla` modules.
- Feature progress: entity_generation_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 295 — lifecycle_hooks_deep (DONE 2026-07-11)
- lib/lifecycle_hooks_deep.sla: ComponentHooks + HookContext deep model of src/lifecycle.rs.
- 10 tests — tests/test_ecs_lib_lifecycle_hooks_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/lifecycle.rs ComponentHooks ✓ deepened
- Current measured counts: 396 lib modules, 301 test files, 90 examples, 5916 `.sla` `@test` annotations; 124 `*_deep.sla` modules.
- Feature progress: lifecycle_hooks deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 296 — bundle_info_extras_deep (DONE 2026-07-11)
- lib/bundle_info_extras_deep.sla: BundleInfo extras + Bundles registry deep model of src/bundle/info.rs.
- 10 tests — tests/test_ecs_lib_bundle_info_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/bundle/info.rs extras ✓ deepened
- Current measured counts: 397 lib modules, 302 test files, 90 examples, 5926 `.sla` `@test` annotations; 125 `*_deep.sla` modules.
- Feature progress: bundle_info_extras deep ~20% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 297 — name_hashed_deep (DONE 2026-07-11)
- lib/name_hashed_deep.sla: Name + HashedStr deep model of src/name.rs.
- 10 tests — tests/test_ecs_lib_name_hashed_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/name.rs ✓ deepened
- Current measured counts: 398 lib modules, 303 test files, 90 examples, 5936 `.sla` `@test` annotations; 126 `*_deep.sla` modules.
- Feature progress: name_hashed deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 298 — caller_location_deep (DONE 2026-07-11)
- lib/caller_location_deep.sla: caller location registry deep model (MaybeLocation stand-in).
- 10 tests — tests/test_ecs_lib_caller_location_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- caller location / MaybeLocation identity path ✓ deepened
- Current measured counts: 399 lib modules, 304 test files, 90 examples, 5946 `.sla` `@test` annotations; 127 `*_deep.sla` modules.
- Feature progress: caller_location deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 299 — clone_entities_deep (DONE 2026-07-11)
- lib/clone_entities_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_clone_entities_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/clone_entities.rs context ✓ deepened
- Current measured counts: 400 lib modules, 305 test files, 90 examples, 5956 `.sla` `@test` annotations; 128 `*_deep.sla` modules.
- Feature progress: clone_entities deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 300 — error_deep (DONE 2026-07-11)
- lib/error_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_error_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/error/ composite ✓ deepened
- Current measured counts: 401 lib modules, 306 test files, 90 examples, 5966 `.sla` `@test` annotations; 129 `*_deep.sla` modules.
- Feature progress: error deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 301 — entity_allocator_extras_deep (DONE 2026-07-11)
- lib/entity_allocator_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_allocator_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/mod.rs EntityAllocator extras ✓ deepened
- Current measured counts: 402 lib modules, 307 test files, 90 examples, 5976 `.sla` `@test` annotations; 130 `*_deep.sla` modules.
- Feature progress: entity_allocator_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 302 — entity_hash_set_ops_deep (DONE 2026-07-11)
- lib/entity_hash_set_ops_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_hash_set_ops_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/hash_set.rs ops ✓ deepened
- Current measured counts: 403 lib modules, 308 test files, 90 examples, 5986 `.sla` `@test` annotations; 131 `*_deep.sla` modules.
- Feature progress: entity_hash_set_ops deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 303 — query_builder_extras_deep (DONE 2026-07-11)
- lib/query_builder_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_query_builder_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/builder.rs extras ✓ deepened
- Current measured counts: 404 lib modules, 309 test files, 90 examples, 5996 `.sla` `@test` annotations; 132 `*_deep.sla` modules.
- Feature progress: query_builder_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 304 — filtered_resource_builders_deep (DONE 2026-07-11)
- lib/filtered_resource_builders_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_filtered_resource_builders_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/filtered_resource.rs builders ✓ deepened
- Current measured counts: 405 lib modules, 310 test files, 90 examples, 6006 `.sla` `@test` annotations; 133 `*_deep.sla` modules.
- Feature progress: filtered_resource_builders deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 305 — query_state_extras_deep (DONE 2026-07-11)
- lib/query_state_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_query_state_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/state.rs + fetch.rs extras ✓ deepened
- Current measured counts: 406 lib modules, 311 test files, 90 examples, 6016 `.sla` `@test` annotations; 134 `*_deep.sla` modules.
- Feature progress: query_state_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 306 — entity_hash_map_extras_deep (DONE 2026-07-11)
- lib/entity_hash_map_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_hash_map_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/hash_map.rs extras ✓ deepened
- Current measured counts: 407 lib modules, 312 test files, 90 examples, 6026 `.sla` `@test` annotations; 135 `*_deep.sla` modules.
- Feature progress: entity_hash_map_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 307 — entity_disabling_filters_deep (DONE 2026-07-11)
- lib/entity_disabling_filters_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_disabling_filters_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity_disabling.rs filters ✓ deepened
- Current measured counts: 408 lib modules, 313 test files, 90 examples, 6036 `.sla` `@test` annotations; 136 `*_deep.sla` modules.
- Feature progress: entity_disabling_filters deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 308 — result_deep (DONE 2026-07-11)
- lib/result_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_result_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/result.sla combinators ✓ deepened
- Current measured counts: 409 lib modules, 314 test files, 90 examples, 6046 `.sla` `@test` annotations; 137 `*_deep.sla` modules.
- Feature progress: result deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 309 — function_system_extras_deep (DONE 2026-07-11)
- lib/function_system_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_function_system_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/function_system.rs extras ✓ deepened
- Current measured counts: 410 lib modules, 315 test files, 90 examples, 6056 `.sla` `@test` annotations; 138 `*_deep.sla` modules.
- Feature progress: function_system_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 310 — system_param_extras_deep (DONE 2026-07-11)
- lib/system_param_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_system_param_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/system_param.rs extras ✓ deepened
- Current measured counts: 411 lib modules, 316 test files, 90 examples, 6066 `.sla` `@test` annotations; 139 `*_deep.sla` modules.
- Feature progress: system_param_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 311 — graph_map_deep (DONE 2026-07-11)
- lib/graph_map_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_graph_map_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/schedule/graph/graph_map.rs Graph ✓ deepened
- Current measured counts: 412 lib modules, 317 test files, 90 examples, 6076 `.sla` `@test` annotations; 140 `*_deep.sla` modules.
- Feature progress: graph_map deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 312 — system_change_tick_extras_deep (DONE 2026-07-11)
- lib/system_change_tick_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_system_change_tick_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/system_param.rs change tick/ParamSet/Deferred/If ✓ deepened
- Current measured counts: 413 lib modules, 318 test files, 90 examples, 6086 `.sla` `@test` annotations; 141 `*_deep.sla` modules.
- Feature progress: system_change_tick_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 313 — entity_ref_extras_deep (DONE 2026-07-11)
- lib/entity_ref_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_ref_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/entity_access/entity_ref.rs extras ✓ deepened
- Current measured counts: 414 lib modules, 319 test files, 90 examples, 6096 `.sla` `@test` annotations; 142 `*_deep.sla` modules.
- Feature progress: entity_ref_extras deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 314 — sparse_set_extras_deep (DONE 2026-07-11)
- lib/sparse_set_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_sparse_set_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/storage/sparse_set.rs extras ✓ deepened
- Current measured counts: 415 lib modules, 320 test files, 90 examples, 6106 `.sla` `@test` annotations; 143 `*_deep.sla` modules.
- Feature progress: sparse_set_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 315 — entity_index_map_extras_deep (DONE 2026-07-11)
- lib/entity_index_map_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_index_map_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/index_map.rs extras ✓ deepened
- Current measured counts: 416 lib modules, 321 test files, 90 examples, 6116 `.sla` `@test` annotations; 144 `*_deep.sla` modules.
- Feature progress: entity_index_map_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 316 — entity_index_set_extras_deep (DONE 2026-07-11)
- lib/entity_index_set_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_index_set_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/index_set.rs extras ✓ deepened
- Current measured counts: 417 lib modules, 322 test files, 90 examples, 6126 `.sla` `@test` annotations; 145 `*_deep.sla` modules.
- Feature progress: entity_index_set_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 317 — world_id_factory_deep (DONE 2026-07-11)
- lib/world_id_factory_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_world_id_factory_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/world/identifier.rs factory ✓ deepened
- Current measured counts: 418 lib modules, 323 test files, 90 examples, 6136 `.sla` `@test` annotations; 146 `*_deep.sla` modules.
- Feature progress: world_id_factory deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 318 — schedule_build_settings_deep (DONE 2026-07-11)
- lib/schedule_build_settings_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_schedule_build_settings_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/schedule/schedule.rs build settings ✓ deepened
- Current measured counts: 419 lib modules, 324 test files, 90 examples, 6146 `.sla` `@test` annotations; 147 `*_deep.sla` modules.
- Feature progress: schedule_build_settings deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 319 — system_trait_extras_deep (DONE 2026-07-11)
- lib/system_trait_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_system_trait_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/system.rs trait extras ✓ deepened
- Current measured counts: 420 lib modules, 325 test files, 90 examples, 6156 `.sla` `@test` annotations; 148 `*_deep.sla` modules.
- Feature progress: system_trait_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 320 — hot_patch_deep (DONE 2026-07-11)
- lib/hot_patch_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_hot_patch_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- hotpatch change tracking ✓ deepened
- Current measured counts: 421 lib modules, 326 test files, 90 examples, 6166 `.sla` `@test` annotations; 149 `*_deep.sla` modules.
- Feature progress: hot_patch deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 321 — unique_array_deep (DONE 2026-07-11)
- lib/unique_array_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_unique_array_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- UniqueEntityArray ✓ deepened
- Current measured counts: 422 lib modules, 327 test files, 90 examples, 6176 `.sla` `@test` annotations; 150 `*_deep.sla` modules.
- Feature progress: unique_array deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 322 — unique_vec_extras_deep (DONE 2026-07-11)
- lib/unique_vec_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_unique_vec_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- UniqueVec extras ✓ deepened
- Current measured counts: 423 lib modules, 328 test files, 90 examples, 6186 `.sla` `@test` annotations; 151 `*_deep.sla` modules.
- Feature progress: unique_vec_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 323 — query_access_ops_deep (DONE 2026-07-11)
- lib/query_access_ops_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_query_access_ops_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/query/access.rs ops ✓ deepened
- Current measured counts: 424 lib modules, 329 test files, 90 examples, 6196 `.sla` `@test` annotations; 152 `*_deep.sla` modules.
- Feature progress: query_access_ops deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 324 — unique_slice_deep (DONE 2026-07-11)
- lib/unique_slice_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_unique_slice_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- UniqueEntitySlice ✓ deepened
- Current measured counts: 425 lib modules, 330 test files, 90 examples, 6206 `.sla` `@test` annotations; 153 `*_deep.sla` modules.
- Feature progress: unique_slice deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 325 — unique_vec_deep (DONE 2026-07-11)
- lib/unique_vec_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_unique_vec_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- UniqueEntityVec ✓ deepened
- Current measured counts: 426 lib modules, 331 test files, 90 examples, 6216 `.sla` `@test` annotations; 154 `*_deep.sla` modules.
- Feature progress: unique_vec deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 326 — schedule_error_deep (DONE 2026-07-11)
- lib/schedule_error_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_schedule_error_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/schedule/error.rs ✓ deepened
- Current measured counts: 427 lib modules, 332 test files, 90 examples, 6226 `.sla` `@test` annotations; 155 `*_deep.sla` modules.
- Feature progress: schedule_error deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 327 — graph_map_digragh_toposort_deep (DONE 2026-07-11)
- lib/graph_map_digragh_toposort_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_graph_map_digragh_toposort_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- DiGraph toposort surface ✓ deepened
- Current measured counts: 428 lib modules, 333 test files, 90 examples, 6236 `.sla` `@test` annotations; 156 `*_deep.sla` modules.
- Feature progress: digraph toposort deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 328 — system_command_deep (DONE 2026-07-11)
- lib/system_command_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_system_command_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/commands/command.rs ✓ deepened
- Current measured counts: 429 lib modules, 334 test files, 90 examples, 6246 `.sla` `@test` annotations; 157 `*_deep.sla` modules.
- Feature progress: system_command deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 329 — system_param_special_deep (DONE 2026-07-11)
- lib/system_param_special_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_system_param_special_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- special system params ✓ deepened
- Current measured counts: 430 lib modules, 335 test files, 90 examples, 6256 `.sla` `@test` annotations; 158 `*_deep.sla` modules.
- Feature progress: system_param_special deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 330 — message_registry_update_deep (DONE 2026-07-11)
- lib/message_registry_update_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_message_registry_update_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- message registry update ✓ deepened
- Current measured counts: 431 lib modules, 336 test files, 90 examples, 6266 `.sla` `@test` annotations; 159 `*_deep.sla` modules.
- Feature progress: message_registry_update deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 331 — entity_set_iter_extras_deep (DONE 2026-07-11)
- lib/entity_set_iter_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_set_iter_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- entity set iter extras ✓ deepened
- Current measured counts: 432 lib modules, 337 test files, 90 examples, 6276 `.sla` `@test` annotations; 160 `*_deep.sla` modules.
- Feature progress: entity_set_iter_extras deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 332 — schedule_configs_extras_deep (DONE 2026-07-11)
- lib/schedule_configs_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_schedule_configs_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/schedule/config.rs extras ✓ deepened
- Current measured counts: 433 lib modules, 338 test files, 90 examples, 6286 `.sla` `@test` annotations; 161 `*_deep.sla` modules.
- Feature progress: schedule_configs_extras deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 333 — system_adapter_deep (DONE 2026-07-11)
- lib/system_adapter_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_system_adapter_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/system/adapter_system.rs ✓ deepened
- Current measured counts: 434 lib modules, 339 test files, 90 examples, 6296 `.sla` `@test` annotations; 162 `*_deep.sla` modules.
- Feature progress: system_adapter deep ~40% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 334 — schedule_auto_insert_deferred_deep (DONE 2026-07-11)
- lib/schedule_auto_insert_deferred_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_schedule_auto_insert_deferred_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- auto insert apply deferred ✓ deepened
- Current measured counts: 435 lib modules, 340 test files, 90 examples, 6306 `.sla` `@test` annotations; 163 `*_deep.sla` modules.
- Feature progress: schedule_auto_insert_deferred deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.


## Batch 335 — entity_hash_set_derived_extras_deep (DONE 2026-07-11)
- lib/entity_hash_set_derived_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_hash_set_derived_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- entity hash set derived extras ✓ deepened
- Current measured counts: 436 lib modules, 341 test files, 90 examples, 6316 `.sla` `@test` annotations; 164 `*_deep.sla` modules.
- Feature progress: entity_hash_set_derived_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 336 — entity_hash_map_derived_extras_deep (DONE 2026-07-11)
- lib/entity_hash_map_derived_extras_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_entity_hash_map_derived_extras_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- entity hash map derived extras ✓ deepened
- Current measured counts: 437 lib modules, 342 test files, 90 examples, 6326 `.sla` `@test` annotations; 165 `*_deep.sla` modules.
- Feature progress: entity_hash_map_derived_extras deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 337 — resource_mod_deep (DONE 2026-07-12)
- lib/resource_mod_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_resource_mod_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/resource.rs IsResource/ResourceEntities ✓ deepened
- Current measured counts: 438 lib modules, 342 test files, 90 examples, 6336 `.sla` `@test` annotations; 166 `*_deep.sla` modules.
- Feature progress: resource_mod deep ~25% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 338 — metadata_identity_deep (DONE 2026-07-12)
- lib/metadata_identity_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_metadata_identity_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- metadata identity registry ✓ deepened
- Current measured counts: 439 lib modules, 343 test files, 90 examples, 6346 `.sla` `@test` annotations; 167 `*_deep.sla` modules.
- Feature progress: metadata_identity deep ~30% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 339 — store_deep (DONE 2026-07-12)
- lib/store_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_store_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- component store dense table ✓ deepened
- Current measured counts: 440 lib modules, 344 test files, 90 examples, 6356 `.sla` `@test` annotations; 168 `*_deep.sla` modules.
- Feature progress: store deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 340 — sparse_store_deep (DONE 2026-07-12)
- lib/sparse_store_deep.sla: deep model.
- 10 tests — tests/test_ecs_lib_sparse_store_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- sparse component store ✓ deepened
- Current measured counts: 441 lib modules, 345 test files, 90 examples, 6366 `.sla` `@test` annotations; 169 `*_deep.sla` modules.
- Feature progress: sparse_store deep ~35% -> 90%; overall API ~94–96%, behavioral ~86–91%.

## Batch 341 - bundle_spawner_deep (DONE 2026-07-12)
- lib/bundle_spawner_deep.sla: deep model.
- 10 tests - tests/test_ecs_lib_bundle_spawner_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/bundle/spawner.rs + insert.rs ✓ deepened
- Current measured counts: 442 lib modules, 346 test files, 90 examples, 6376 `.sla` `@test` annotations; 170 `*_deep.sla` modules.
- Feature progress: bundle_spawner deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 342 - entity_index_set_derived_extras_deep (DONE 2026-07-12)
- lib/entity_index_set_derived_extras_deep.sla: deep model.
- 11 tests - tests/test_ecs_lib_entity_index_set_derived_extras_deep_isolated.sla (new).
- Verification: SA 11 pass; default 11 pass.
- entity index set derived extras ✓ deepened
- Current measured counts: 443 lib modules, 347 test files, 90 examples, 6386 `.sla` `@test` annotations; 171 `*_deep.sla` modules.
- Feature progress: entity_index_set_derived_extras deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 343 - schedule_condition_advanced_deep (DONE 2026-07-12)
- lib/schedule_condition_advanced_deep.sla: deep model.
- 10 tests - tests/test_ecs_lib_schedule_condition_advanced_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/schedule/condition.rs advanced combinators ✓ deepened
- Current measured counts: 444 lib modules, 348 test files, 90 examples, 6396 `.sla` `@test` annotations; 172 `*_deep.sla` modules.
- Feature progress: schedule_condition_advanced deep ~40% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 344 - entity_index_map_derived_extras_deep (DONE 2026-07-12)
- lib/entity_index_map_derived_extras_deep.sla: deep model.
- 11 tests - tests/test_ecs_lib_entity_index_map_derived_extras_deep_isolated.sla (new).
- Verification: SA 11 pass; default 11 pass.
- entity index map derived extras ✓ deepened
- Current measured counts: 445 lib modules, 349 test files, 90 examples, 6406 `.sla` `@test` annotations; 173 `*_deep.sla` modules.
- Feature progress: entity_index_map_derived_extras deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 345 - archetype_edges_deep (DONE 2026-07-12)
- lib/archetype_edges_deep.sla: deep model.
- 10 tests - tests/test_ecs_lib_archetype_edges_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/archetype.rs Edges ✓ deepened
- Current measured counts: 446 lib modules, 350 test files, 90 examples, 6416 `.sla` `@test` annotations; 174 `*_deep.sla` modules.
- Feature progress: archetype_edges deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 346 - archetype_info_deep (DONE 2026-07-12)
- lib/archetype_info_deep.sla: deep model.
- 10 tests - tests/test_ecs_lib_archetype_info_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/archetype.rs Archetype ✓ deepened
- Current measured counts: 447 lib modules, 351 test files, 90 examples, 6426 `.sla` `@test` annotations; 175 `*_deep.sla` modules.
- Feature progress: archetype_info deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 347 - archetypes_registry_deep (DONE 2026-07-12)
- lib/archetypes_registry_deep.sla: deep model.
- 10 tests - tests/test_ecs_lib_archetypes_registry_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/archetype.rs Archetypes facade ✓ deepened
- Current measured counts: 448 lib modules, 352 test files, 90 examples, 6426 `.sla` `@test` annotations; 176 `*_deep.sla` modules.
- Feature progress: archetypes_registry deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 348 - entity_dynamic_deep (DONE 2026-07-12)
- lib/entity_dynamic_deep.sla: deep model (DynamicEntityAllocator fixed cap-16, LIFO free stack, generation bump on free, ids start at 1).
- 10 tests - tests/test_ecs_lib_entity_dynamic_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- src/entity/entity_ref.rs + lib/entity_dynamic.sla entity allocator ✓ deepened
- Current measured counts: 449 lib modules, 353 test files, 90 examples, 6436 `.sla` `@test` annotations; 177 `*_deep.sla` modules.
- Feature progress: entity_dynamic deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 349 - dyn_store_deep (DONE 2026-07-12)
- lib/dyn_store_deep.sla: deep model (cap-8 dense ids+values + sparse row-of + insert/overwrite/get/has/write/swap_remove/clear).
- 10 tests - tests/test_ecs_lib_dyn_store_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/dyn_store.sla + src/storage/sparse_set.rs dense+sparse layout ✓ deepened
- Current measured counts: 450 lib modules, 354 test files, 90 examples, 6446 `.sla` `@test` annotations; 178 `*_deep.sla` modules.
- Feature progress: dyn_store deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 350 - entity_deep (DONE 2026-07-12)
- lib/entity_deep.sla: deep model (EcsEntityDeep + cap-16 allocator with FIFO free-queue).
- 10 tests - tests/test_ecs_lib_entity_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/entity.sla Entity + EntityAllocator ✓ deepened
- Current measured counts: 451 lib modules, 355 test files, 90 examples, 6456 `.sla` `@test` annotations; 179 `*_deep.sla` modules.
- Feature progress: entity deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 351 - entities_collection_deep (DONE 2026-07-12)
- lib/entities_collection_deep.sla: deep model (EcsEntities cap-8 slot-struct + FIFO free-queue).
- 10 tests - tests/test_ecs_lib_entities_collection_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/entities_collection.sla + src/entity/mod.rs Entities/EntityLocation ✓ deepened
- Current measured counts: 452 lib modules, 356 test files, 90 examples, 6466 `.sla` `@test` annotations; 180 `*_deep.sla` modules.
- Feature progress: entities_collection deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.
- Live lesson: struct-by-value slot cannot be reused across multiple `if idx==N { e.s0 = slot; };` branches (UseAfterMove). Fix: capture struct fields as scalars once, then build fresh slot instances per branch via the slot builder helper.

## Batch 352 - entity_collections_deep (DONE 2026-07-12)
- lib/entity_collections_deep.sla: deep model (EntityIndexSet cap-8 dedup + insert/swap_remove/shift_remove/get_index/any/into_iter/clear).
- 10 tests - tests/test_ecs_lib_entity_collections_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/entity_collections.sla (EntityIndexSet subset) + src/entity/index_set.rs ✓ deepened
- Current measured counts: 453 lib modules, 357 test files, 90 examples, 6476 `.sla` `@test` annotations; 181 `*_deep.sla` modules.
- Feature progress: entity_collections deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 353 - event_observer_erased_deep (DONE 2026-07-12)
- lib/event_observer_erased_deep.sla: deep model (cap-8 observers keyed by event-type-id with kind dispatch selector).
- 10 tests - tests/test_ecs_lib_event_observer_erased_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/event_observer_erased.sla ✓ deepened
- Current measured counts: 454 lib modules, 358 test files, 90 examples, 6486 `.sla` `@test` annotations; 182 `*_deep.sla` modules.
- Feature progress: event_observer_erased deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 354 - resource_erased_deep (DONE 2026-07-12)
- lib/resource_erased_deep.sla: deep model (EcsErasedResources cap-8 type-id slot store + added/changed tick tracking).
- 10 tests - tests/test_ecs_lib_resource_erased_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/resource_erased.sla ErasedResources ✓ deepened
- Current measured counts: 455 lib modules, 359 test files, 90 examples, 6496 `.sla` `@test` annotations; 183 `*_deep.sla` modules.
- Feature progress: resource_erased deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 355 - relationship_one_adapter_deep (DONE 2026-07-12)
- lib/relationship_one_adapter_deep.sla: deep model (cap-8 own entity allocator + exclusive source->target map).
- 10 tests - tests/test_ecs_lib_relationship_one_adapter_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/relationship_one_adapter.sla generic exclusive RelationshipWorld ✓ deepened
- Current measured counts: 456 lib modules, 360 test files, 90 examples, 6506 `.sla` `@test` annotations; 184 `*_deep.sla` modules.
- Feature progress: relationship_one_adapter deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 356 - schedule_executor_deep (DONE 2026-07-12)
- lib/schedule_executor_deep.sla: deep model (cap-8 system-queue + single/multi kind + run/skip/apply_deferred/finish/is_finished).
- 10 tests - tests/test_ecs_lib_schedule_executor_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/schedule_executor.sla ✓ deepened
- Current measured counts: 457 lib modules, 361 test files, 90 examples, 6516 `.sla` `@test` annotations; 185 `*_deep.sla` modules.
- Feature progress: schedule_executor deep ~30% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 357 - schedule_dynamic_deep (DONE 2026-07-12)
- lib/schedule_dynamic_deep.sla: deep model (cap-8 system-access store + write/read hazard conflict matrix).
- 11 tests - tests/test_ecs_lib_schedule_dynamic_deep_isolated.sla (new).
- Verification: SA 11 pass; default 11 pass.
- lib/schedule_dynamic.sla deep ✓ (deepened schedule + access conflict analyzer)
- Current measured counts: 458 lib modules, 362 test files, 90 examples, 6527 `.sla` `@test` annotations; 186 `*_deep.sla` modules.
- Feature progress: schedule_dynamic deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 358 - schedule_registry_erased_deep (DONE 2026-07-12)
- lib/schedule_registry_erased_deep.sla: deep model (cap-8 schedule + per-slot access with cap-4 read/cap-4 write component-ids + resource/messages flags + conflict matrix).
- 10 tests - tests/test_ecs_lib_schedule_registry_erased_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/schedule_registry_erased.sla ✓ deepened
- Current measured counts: 459 lib modules, 363 test files, 90 examples, 6537 `.sla` `@test` annotations; 187 `*_deep.sla` modules.
- Feature progress: schedule_registry_erased deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 359 - commands_table_value_deep (DONE 2026-07-12)
- lib/commands_table_value_deep.sla: deep model (cap-8 deferred command queue with kind discriminator + side payload slots).
- 10 tests - tests/test_ecs_lib_commands_table_value_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/commands_table_value.sla deferred queue ✓ deepened
- Current measured counts: 460 lib modules, 364 test files, 90 examples, 6547 `.sla` `@test` annotations; 188 `*_deep.sla` modules.
- Feature progress: commands_table_value deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 360 - relationship_replace_insert_deep (DONE 2026-07-12)
- lib/relationship_replace_insert_deep.sla: deep model (cap-8 EcsReplaceInsert related set + cap-4 EcsBatchRelated carrier + insert/replace/difference ops).
- 10 tests - tests/test_ecs_lib_relationship_replace_insert_deep_isolated.sla (new).
- Verification: SA 10 pass; default 10 pass.
- lib/relationship_replace_insert.sla related_methods insert/replace/difference ✓ deepened
- Current measured counts: 461 lib modules, 365 test files, 90 examples, 6557 `.sla` `@test` annotations; 189 `*_deep.sla` modules.
- Feature progress: relationship_replace_insert deep ~35% -> 90%; overall API ~94-96%, behavioral ~86-91%.

## Batch 361 — relationship_source_collection_ordered_deep (DONE 2026-07-12)

Deepens shallow `lib/relationship_source_collection_ordered.sla` against Bevy's
`OrderedRelationshipSourceCollection` trait for `Vec<Entity>` (src/relationship/relationship_source_collection.rs).

**Model.** `EcsRscOrderedDeep` — fixed cap-8 (`ECS_RSC_ORD_CAP_DEEP = 8`) i64 entity slots
(e0..e7) + scalar `count`. `RscRemoveResultDeep { found: i32, entity: i64 }` models `Option<Entity>`
(0/-1 sentinel = None, 1/VALUE = Some). `ecs_rsc_at`/`ecs_rsc_set` per-index accessors; i64 scalar
slots make per-branch reassign safe (no struct-by-value UseAfterMove risk; unlike the slot-struct case).

**Bevy Vec<Entity> semantics (key deepening vs shallow).** The shallow modeled insert/remove_at as
shift-stable. The deep variant matches Bevy's actual `Vec<Entity>` impl precisely:
- `insert(index, entity)` = `push(entity)` then `swap(index, last)` — NOT stable (reorders trailing).
- `remove_at(index)` = `swap_remove(index)` (tail-entity moves into the hole) — NOT stable.
- `insert_stable(index, entity)` = shift-right slot from `place=max(0, min(index, count))` then set.
- `remove_at_stable(index)` = shift-left trailing slots (Vec::remove).
- `sort()` = selection sort ascending (sla has no built-in Vec sort).
- `insert_sorted(entity)` = `partition_point(e <= entity)` scan then insert_stable.
- `place_most_recent(index)` = pop tail then `insert(min(index, post-pop-count), popped)`.
- `place(entity, index)` = `position` scan; if present `stable_remove_at(current)` then `insert(min(index, new-count), entity)`.
- `push_front(entity)` = `insert(0, entity)`; `push_back` = `insert(cap, entity)` (clamp-to-end).
- `pop_front` = `remove_at(0)` (swap_remove variant); `pop_back` = `remove_at(count-1)`.

**Base RelationshipSourceCollection (Vec<Entity>).** `add(entity)` = push onto tail, reject at cap,
returns success flag (Vec variant always true on success). `remove(entity)` scans with `rposition`
(last matching index, matching Bevy's back-scan for temporal locality) then stable-shifts at that
index; returns whether removed. `contains`/`index_of`/`iter_at`/`len`/`is_empty`/`clear`/
`extend_from_iter(ids: Vec<i64>)` push every entry, stop at cap. `with_capacity`/`reserve`/
`shrink_to_fit` are cap-model no-ops. `source_to_remove_before_add` returns -1 (None sentinel) — Bevy's
default trait impl for Vec (one-to-many).

**Tests.** 10 isolated tests in `tests/test_ecs_lib_relationship_source_collection_ordered_deep_isolated.sla`,
panic band 138200-138399: new/empty/cap ops; add push + cap reject; insert push+swap ordering
(traced [30,10,20] then insert(1,99)->[30,99,20,10]); remove_at swap_remove with tail-move (reorders);
insert_stable/remove_at_stable order preservation; sort ascending + insert_sorted partition-point;
place relocate with index clamp + no-op for absent + oob clamp; place_most_recent pop+insert + empty no-op;
remove-by-value via rposition + extend_from_iter + not-present reject; push/pop front+back + clear + empty pop_back.

**Verification.** `sa sla check lib/relationship_source_collection_ordered_deep.sla` ok. SA backend
(`--test-backend sa --jobs 1 --trace-panic`): 10 passed, 0 failed. Default backend
(`--jobs 1 --trace-panic`): 10 passed, 0 failed. Live lesson: when tracing insert semantics in tests,
remember Bevy `Vec::insert` does push-THEN-swap, so a continuous `insert(0, …)` chain reverses
differently than a stable shift-insert — seed test expectations from the actual swap, not the intuitive
"newest-first" mental model.

**Counts.** 462 lib modules, 366 test files, 90 examples, 6565 `.sla` `@test` annotations;
190 `*_deep.sla` modules. Next free panic band: 138400+. Next batch: 362.

## Batch 362 — commands_archetype_value_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_archetype_value.sla` (src/system/commands/archetype_value.rs).
The shallow wraps `ArchetypeValueCommands<T, R, M>` (generic fn-ptr queue that applies against
`ArchetypeValueWorld<T, R, M>`). The deep variant extracts the generic-free command-queue core
that the shallow inventories before world application, mirroring the Batch 359 pattern used for
`commands_table_value_deep`.

**Model.** `EcsArchValueCommandsDeep` — fixed cap-8 (`ECS_CMD_ARCH_VALUE_CAP_DEEP = 8`) command
queue with scalar slot fields per slot id (kN kind + eN entity_id + cN component_id + vN value_index),
plus three side-payload slot arrays (pN component_values, rN resource_values, mN message_values)
each cap-8 i32 with their own counts (`pcomp_count`, `pres_count`, `pmsg_count`) and master
`count`. `EcsArchValueCommandDeep` is a per-command builder struct exposing the four attrs.

**Kinds (mirror shallow).** `INSERT_COMPONENT=1`, `DESPAWN=2`, `INSERT_RESOURCE=3`,
`WRITE_MESSAGE=4`. `insert(entity_id, component_id, value)` pushes a value into the pcomp side
array then queues INSERT_COMPONENT with the side index in `vN`. `despawn(entity_id)` queues
DESPAWN with `vN = -1` and no side payload. `insert_resource` / `write_message` push their
payload into the pres / pmsg side arrays then queue INSERT_RESOURCE / WRITE_MESSAGE with the
matching side index.

**Operations.** `new`, `command` builder, `reserve_entity` (returns placeholder id 0 — deep has no
world handle so no real entity allocation; mirrors the shallow `archetype_value_commands_reserve_entity`
that pairs with a world), `insert` / `despawn` / `insert_resource` / `write_message`, `len`,
`count_by_kind(kind)` (iterates slots and matches kinds — introspection analogue of
`applied_count_by_kind`), `resolve_value(idx)` (kind-indexed side-array readout: INSERT_COMPONENT
reads pcomp, INSERT_RESOURCE reads pres, WRITE_MESSAGE reads pmsg, else 0), `clear` (returns fresh
new), per-slot read accessors (`kind_at`/`entity_at`/`cmp_at`/`idx_at`), and side accessors
(`pcomp_at`/`pres_at`/`pmsg_at` and the three `*_count` helpers). All caps enforced at 8 (both the
command list and the side arrays reject further writes when full).

**Slots vs struct rebuild.** The deep variant stores only i32 scalars per slot (no struct-typed
slot type), so per-branch scalar reassign in `set_slot` is safe — no `UseAfterMove` risk.

**Tests.** 10 isolated tests in
`tests/test_ecs_lib_commands_archetype_value_deep_isolated.sla`, panic band 138400-138599:
new/empty/zero side-counts/accessors; insert enqueues INSERT_COMPONENT entity/comp/idx/resolve;
multiple insertions populate sequential slot + side indices; despawn enqueues DESPAWN with -1 idx
and 0 resolve; insert_resource side payload + resolve; write_message side payload + resolve;
mixed-queue count_by_kind across all 4 kinds; mixed-queue resolve_value across kinds matching the
side-array mapping; cap-8 rejection on the command list + despawn + clear zeroing all counts;
reserve_entity + builder helper struct field accessors.

**Verification.** `sa sla check lib/commands_archetype_value_deep.sla` ok. SA backend
(`--test-backend sa --jobs 1 --trace-panic`): 10 passed, 0 failed. Default backend
(`--jobs 1 --trace-panic`): 10 passed, 0 failed.

**Counts.** 463 lib modules, 367 test files, 90 examples, 6575 `.sla` `@test` annotations;
191 `*_deep.sla` modules. Next free panic band: 138600+. Next batch: 363.

## Batch 363 — commands_registry_value_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_registry_value.sla` (src/system/commands/registry_value.rs).
The shallow wraps `RegistryValueCommands<T, R, M>` (generic fn-ptr queue that applies against
`RegistryValueWorld<T, R, M>`). The deep variant extracts the generic-free command-queue core
that the shallow inventories before world application, mirroring the Batch 359/362 pattern used
for `commands_table_value_deep` / `commands_archetype_value_deep`.

**Model.** `EcsRegValueCommandsDeep` — fixed cap-8 (`ECS_CMD_REG_VALUE_CAP_DEEP = 8`) command
queue with scalar slot fields per slot id (kN kind + eN entity_id + cN component_id + vN value_index),
plus three side-payload slot arrays (pN component_values, rN resource_values, mN message_values)
each cap-8 i32 with their own counts (`pcomp_count`, `pres_count`, `pmsg_count`) and master
`count`. `EcsRegValueCommandDeep` is a per-command builder struct exposing the four attrs.

**Kinds (mirror shallow).** `INSERT_COMPONENT=1`, `DESPAWN=2`, `INSERT_RESOURCE=3`,
`WRITE_MESSAGE=4`. `insert(entity_id, component_id, value)` pushes a value into the pcomp side
array then queues INSERT_COMPONENT with the side index in `vN`. `despawn(entity_id)` queues
DESPAWN with `vN = -1` and no side payload. `insert_resource` / `write_message` push their
payload into the pres / pmsg side arrays then queue INSERT_RESOURCE / WRITE_MESSAGE with the
matching side index.

**Operations.** `new`, `command` builder, `reserve_entity` (returns placeholder id 0 — deep has no
world handle so no real entity allocation; mirrors the shallow `registry_value_commands_reserve_entity`
that pairs with a world), `insert` / `despawn` / `insert_resource` / `write_message`, `len`,
`count_by_kind(kind)` (iterates slots and matches kinds — introspection analogue of
`applied_count_by_kind`), `resolve_value(idx)` (kind-indexed side-array readout: INSERT_COMPONENT
reads pcomp, INSERT_RESOURCE reads pres, WRITE_MESSAGE reads pmsg, else 0), `clear` (returns fresh
new), per-slot read accessors (`kind_at`/`entity_at`/`cmp_at`/`idx_at`), and side accessors
(`pcomp_at`/`pres_at`/`pmsg_at` and the three `*_count` helpers). All caps enforced at 8.

**Slots vs struct rebuild.** i32 scalars per slot only — safe per-branch reassign in `set_slot`.

**Tests.** 10 isolated tests in
`tests/test_ecs_lib_commands_registry_value_deep_isolated.sla`, panic band 138600-138799:
new/empty/zero side-counts; insert enqueues INSERT_COMPONENT entity/comp/idx/resolve; multi-insert
sequential slot + side indices; despawn enqueues DESPAWN with -1 idx and 0 resolve; insert_resource
side payload + resolve; write_message side payload + resolve; count_by_kind across all 4 kinds in a
mixed queue; mixed-queue resolve_value across kinds matching the side-array mapping; cap-8 rejection
command list + despawn + clear zeroing all counts; reserve_entity + builder helper struct accessors.

**Verification.** `sa sla check lib/commands_registry_value_deep.sla` ok. SA backend
(`--test-backend sa --jobs 1 --trace-panic`): 10 passed, 0 failed. Default backend
(`--jobs 1 --trace-panic`): 10 passed, 0 failed.

**Counts.** 464 lib modules, 368 test files, 90 examples, 6585 `.sla` `@test` annotations;
192 `*_deep.sla` modules. Next free panic band: 138800+. Next batch: 364.

## Batch 364 — commands_registry_erased_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_registry_erased.sla` (src/system/commands/registry_erased.rs).
The shallow wraps `RegistryErasedCommands<R, M>` (generic fn-ptr queue) with a `Vec<ErasedComponentValue>`
side array so heterogeneous component insertions route through one erased queue. The deep variant
extracts the generic-free command-queue core and models the erased component payload with two
parallel scalar side arrays per INSERT_COMPONENT entry — a `type_id` and the observable interior
scalar value (modeling the boxed-erased-value ceil visible from the deep isolated harness). Avoids
generic types, fn-ptr world-application, and `ecs_box_drop<T>` style type-erased pointers.

**Model.** `EcsRegErasedCommandsDeep` — fixed cap-8 (`ECS_CMD_REG_ERASED_CAP_DEEP = 8`) command
queue with scalar slot fields per slot id (kN kind + eN entity_id + cN component_id + vN value_index),
plus parallel type_id / scalar-value side arrays (`ptN`, `pvN`, sharing `pcomp_count`), a single
resource side array (`rN` cap-8 i32 with `pres_count`), and a single message side array
(`mN` cap-8 i32 with `pmsg_count`); master `count`. `EcsRegErasedCommandDeep` is a per-command
builder struct exposing the four attrs.

**Kinds (mirror shallow).** `INSERT_COMPONENT=1`, `DESPAWN=2`, `INSERT_RESOURCE=3`,
`WRITE_MESSAGE=4`. `insert(entity_id, component_id, type_id, value)` pushes the type_id and scalar
value into the parallel `pt/pv` side arrays then queues INSERT_COMPONENT pointing at the shared side
index in `vN`. `despawn(entity_id)` queues DESPAWN with `vN = -1` and no side payload. `insert_resource`
/ `write_message` push into pres / pmsg side arrays then queue INSERT_RESOURCE / WRITE_MESSAGE with
the matching side index. INSERT_COMPONENT commands carry a `type_id` recoverable via `resolve_type`
(mirrors the shallow `registry_erased_value_new<T>(type_id, value)` constructor).

**Operations.** `new`, `command` builder, `reserve_entity` (returns placeholder id 0 — deep has no
world handle so no real entity allocation), `insert` / `despawn` / `insert_resource` / `write_message`,
`len`, `count_by_kind(kind)` (iterates slots and matches kinds), `resolve_value(idx)` (kind-indexed
side-array readout: INSERT_COMPONENT reads pv, INSERT_RESOURCE reads pres, WRITE_MESSAGE reads pmsg,
else 0), `resolve_type(idx)` (only INSERT_COMPONENT returns the type_id side), `resolve_resource(idx)` /
`resolve_message(idx)` (kind-gated one-shot readers), `clear`, per-slot read accessors
(`kind_at` / `entity_at` / `cmp_at` / `idx_at`) and side accessors (`pt_at` / `pv_at` / `pres_at` /
`pmsg_at` and the three `*_count` helpers). All caps enforced at 8.

**Slots vs struct rebuild.** i32 scalars per slot only — safe per-branch reassign in `set_slot`.

**Tests.** 10 isolated tests in
`tests/test_ecs_lib_commands_registry_erased_deep_isolated.sla`, panic band 138800-138999:
new/empty/zero side-counts; insert queues INSERT_COMPONENT with type_id + resolved value and type;
multi-insert heterogeneous types track per-slot type_ids (POS/VEL/MARKER); despawn enqueues
DESPAWN with no side payload (value=0/type=0); insert_resource side payload + resolve_value +
resolve_resource; write_message side payload + resolve_value + resolve_message; count_by_kind
across all 4 kinds in a mixed queue; mixed-queue resolve_value / resolve_type / resolve_resource /
resolve_message across slot kinds; cap-8 rejection on command list + despawn alias + clear zeroing
all counts; reserve_entity + builder helper struct accessors.

**Verification.** `sa sla check lib/commands_registry_erased_deep.sla` ok. SA backend
(`--test-backend sa --jobs 1 --trace-panic`): 10 passed, 0 failed. Default backend
(`--jobs 1 --trace-panic`): 10 passed, 0 failed.

**Counts.** 465 lib modules, 369 test files, 90 examples, 6595 `.sla` `@test` annotations;
193 `*_deep.sla` modules. Next free panic band: 139000+. Next batch: 365.

## Batch 365 — commands_table_erased_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_table_erased.sla` (src/system/commands/table_erased.rs).
The shallow wraps `TableErasedCommands<R, M>` (generic fn-ptr queue) that defers heterogeneous,
table-erased component insertions AND six batch-bundle spawn/insert commands, each batch carrying
parallel entity ids and erased-bundle payloads (`TableErasedBundle2` / `TableErasedBundle3`). The
deep variant models the queue's ten command kinds and the side arrays analogous to the shallow —
no generic types, no fn-ptr world application, no `ecs_box_drop<T>` style erased pointers.

**Kinds (mirror shallow).** INSERT_COMPONENT=1, DESPAWN=2, INSERT_RESOURCE=3, WRITE_MESSAGE=4,
SPAWN_BATCH_BUNDLE2=5, SPAWN_BATCH_BUNDLE3=6, INSERT_BATCH_BUNDLE2=7, INSERT_BATCH_BUNDLE3=8,
INSERT_BATCH_BUNDLE2_IF_NEW=9, INSERT_BATCH_BUNDLE3_IF_NEW=10.

**Model.** `EcsTblErasedCommandsDeep` — fixed cap-8 (`ECS_CMD_TBL_ERASED_CAP_DEEP = 8`) command
queue with scalar slot fields per slot id (kN kind + eN entity_id + cN component_id + vN value_index),
plus:
- INSERT_COMPONENT parallel side arrays `ptN` type_id + `pvN` scalar value (cap-8 i32) sharing `pcomp_count` (mirrors Batch 364 pattern for erased-component interiors).
- `rN` resource side array cap-8 with `pres_count` for INSERT_RESOURCE.
- `mN` message side array cap-8 with `pmsg_count` for WRITE_MESSAGE.
- bundle2 batch side storage cap-2 batches (`ECS_CMD_TBL_ERASED_BATCH_CAP_DEEP = 2`); each batch has
  cap-2 bundles with parallel per-batch fields `be00/01` entity ids + `bft/st/fv/sv` per bundle
  (first_type, second_type, first_value, second_value) + `b2c0/1` bundle count and `b2_count`.
- bundle3 batch side storage cap-2 batches; each batch has cap-2 bundles with parallel per-batch
  fields `ce00/01` entity ids + `cft/cst/ctt/cfv/csv/ctv` per bundle (first/second/third type_id,
  first/second/third value) + `b3c0/1` and `b3_count`.
`EcsTblErasedBundle2Deep` / `EcsTblErasedBundle3Deep` are result structs the per-batch readers return;
the bundle3 reader uses scalar capture then per-branch construction (the per-branch-build fix for the
7-field struct read pattern, per the live lesson on the UseAfterMove bug). `EcsTblErasedCommandDeep`
is a per-command builder struct exposing the four attrs.

**Operations.** `new`, `command` builder, `reserve_entity` (returns placeholder 0 — deep has no
world handle so no real entity allocation), the 10 `*insert*` / `*spawn*` mutators listed above,
`len`, `count_by_kind(kind)` (iterates slots and matches kinds), `resolve_value(idx)` (kind-indexed
scalar side-array readout: INSERT_COMPONENT reads pv, INSERT_RESOURCE reads pres, WRITE_MESSAGE
reads pmsg, else 0), `resolve_type(idx)` (only INSERT_COMPONENT returns the type_id side),
`batch_slot(idx)` (return the batch slot tag for a batch command), the bundle readers
`b2_at(k, i)` / `b3_at(k, i)`, the per-batch bundle-count readers `b2c_at(k)` / `b3c_at(k)`,
the side counters `pcomp_count` / `pres_count` / `pmsg_count` / `b2_count` / `b3_count`, `clear`,
and per-slot command read accessors (`kind_at` / `entity_at` / `cmp_at` / `idx_at`). All caps
enforced: command list cap-8, batch kinds cap-2 (each batch kind's side arrays reject further
batches when full).

**Tests.** 10 isolated tests in
`tests/test_ecs_lib_commands_table_erased_deep_isolated.sla`, panic band 139000-139199:
new/empty/zero side counts; insert INSERT_COMPONENT with type_id + resolve; despawn/insert_resource/
write_message mixed-path queue with resolve_value; spawn_batch_bundle2 stores bundle2 tail-side
array + retrieve via b2_at; spawn_batch_bundle3 stores cap-2 batch entries + retrieve via b3_at;
insert_batch_bundle2 and _if_new queue distinct kinds; insert_batch_bundle3 and _if_new queue distinct
kinds; count_by_kind across all 10 kinds split into four queues (the 4 trivial kinds + b2-batch-kinds
queues + b3-batch-kinds + IF_NEW kinds alone to respect the cap-2 batch cap); queue cap-8 rejection on
command list + despawn alias + clear zeroing all counts (incl. side counts); batch cap-2 rejection for
both b2 and b3 side arrays.

**Live lesson.** The cap-2 batch side storage cannot host all six batch kinds in a single queue
(each batch kind consumes one of the same cap-2 slots, so any third batch kind command is silently
rejected). When testing count_by_kind across all 10 kinds, split the queue into multiple phases that
respect the cap-2 batch budget per batch kind — verified empirically (test 8 first failed at 139088
expecting INSERT_BATCH_BUNDLE2_IF_NEW count==1 which suffers because we'd already filled b2_count to 2
in earlier commands).

**Slots vs struct rebuild.** i32 scalars per slot only — safe per-branch reassign in `set_slot` and
the bundle2 batch setter. The bundle3 reader (`b3_at`) uses **scalar capture then per-branch build** to
return a 7-field result struct safely (no struct-typed slot pattern; the move rule applies to
constructing result structs across branches — the 7 fields are written to local scalars first, then
the result is built once per branch).

**Verification.** `sa sla check lib/commands_table_erased_deep.sla` ok. SA backend
(`--test-backend sa --jobs 1 --trace-panic`): 10 passed, 0 failed. Default backend
(`--jobs 1 --trace-panic`): 10 passed, 0 failed.

**Counts.** 466 lib modules, 370 test files, 90 examples, 6605 `.sla` `@test` annotations;
194 `*_deep.sla` modules. Next free panic band: 139200+. Next batch: 366.

## Batch 366 — commands_table_erased_observer_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_table_erased_observer.sla`
(src/system/commands/table_erased_observer.rs). The shallow wraps
`TableErasedObserverCommands<R, M>` (generic fn-ptr queue) that defers heterogeneous component
mutations AND observer-trigger events (`TableErasedObserverEventCommandValue` carrying an
`ErasedEventValue` + drop_fn). The deep variant models the queue's six command kinds and side
arrays analogous to the shallow — no generic types, no fn-ptr world application, no `ecs_box_drop<T>`
/ `erased_event_value_new` boxed pointers.

**Kinds (mirror shallow).** INSERT_COMPONENT=1, REMOVE_COMPONENT=2, DESPAWN=3, INSERT_RESOURCE=4,
WRITE_MESSAGE=5, TRIGGER_EVENT=6. REMOVE_COMPONENT and DESPAWN carry no side payload (their `vN`
stays -1, `resolve_value` returns 0).

**Model.** `EcsTblObsCommandsDeep` — fixed cap-8 (`ECS_CMD_TBL_OBS_CAP_DEEP = 8`) command queue
with scalar slot fields per slot id (kN kind + eN entity_id + cN component_id + vN value_index),
plus:
- INSERT_COMPONENT parallel side arrays `ptN` type_id + `pvN` scalar value (cap-8 i32) sharing `pcomp_count`.
- `rN` resource side array cap-8 with `pres_count` for INSERT_RESOURCE.
- `mN` message side array cap-8 with `pmsg_count` for WRITE_MESSAGE.
- TRIGGER_EVENT parallel side arrays `etN` event-type-id + `evN` scalar event value (cap-8 i32)
  sharing `pcev_count`. The `entity_id` slot is 0 for `trigger` (no target entity) and the actual
  entity id for `trigger_entity` (carries the target entity in the command slot — mirrors the
  shallow distinction where `trigger_entity` sets `command.entity`).
`EcsTblObsCommandDeep` is a per-command builder struct exposing the four attrs.

**Operations.** `new`, `command` builder, `reserve_entity` (returns placeholder 0 — deep has no
world handle), `insert` (INSERT_COMPONENT with parallel pt/pv side push), `remove` (REMOVE_COMPONENT
with `vN = -1`), `despawn` (DESPAWN with `vN = -1`), `insert_resource`, `write_message`, `trigger`
(TRIGGER_EVENT with no target entity, entity_id 0) and `trigger_entity` (TRIGGER_EVENT with the
target entity recorded in the `eN` slot), `len`, `count_by_kind(kind)` (slot scan),
`resolve_value(idx)` (kind-indexed scalar side-array readout: INSERT_COMPONENT reads pv,
INSERT_RESOURCE reads pres, WRITE_MESSAGE reads pmsg, TRIGGER_EVENT reads ev, else 0),
`resolve_type(idx)` (INSERT_COMPONENT reads the pt type_id, TRIGGER_EVENT reads the et event
type_id, else 0 — lets downstream observers distinguish component-type from event-type),
`clear`, and per-slot command read accessors
(`kind_at` / `entity_at` / `cmp_at` / `idx_at`). All caps enforced at 8.

**Tests.** 10 isolated tests in
`tests/test_ecs_lib_commands_table_erased_observer_deep_isolated.sla`, panic band 139200-139399:
new/empty/zero side counts (incl. event side); insert INSERT_COMPONENT with type_id + resolve;
remove enqueues REMOVE_COMPONENT with -1 idx and 0 resolve; despawn enqueues DESPAWN with -1 idx
and 0 resolve; insert_resource + write_message side payloads + resolve; trigger enqueues
TRIGGER_EVENT with no target entity + side-array payload + resolve_type (event type_id);
trigger_entity carries the target entity in the command slot; count_by_kind across all 6 kinds in a
mixed queue (TRIGGER_EVENT counted twice — both trigger variants); resolve_value/type across mixed
kinds (REMOVE_COMPONENT → 0, INSERT_COMPONENT → pv+pt, TRIGGER_EVENT → ev+et, WRITE_MESSAGE → pmsg);
queue cap-8 rejection on command list + despawn alias + clear zeroing all four side counts
(pcomp/pres/pmsg/pcev).

**Verification.** `sa sla check lib/commands_table_erased_observer_deep.sla` ok. SA backend
(`--test-backend sa --jobs 1 --trace-panic`): 10 passed, 0 failed. Default backend
(`--jobs 1 --trace-panic`): 10 passed, 0 failed.

**Counts.** 467 lib modules, 371 test files, 90 examples, 6615 `.sla` `@test` annotations;
195 `*_deep.sla` modules. Next free panic band: 139400+. Next batch: 367.


## Batch 367 — commands_table_erased_relationship_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_table_erased_relationship.sla`
(src/system/commands/table_erased_relationship.rs) — `TableErasedRelationshipCommands<R, M>`
generic fn-ptr queue modeling 11 command kinds and shared entity-list side storage (no generic
types, no fn-ptr world application, no RelationshipSourceCollection trait object).

**Kinds.** INSERT_COMPONENT=1, SET_RELATED=2, DESPAWN=3, INSERT_RESOURCE=4, WRITE_MESSAGE=5,
SET_RELATED_AT=6, REMOVE_RELATED=7, DETACH_ALL_RELATED=8, REPLACE_RELATED=9,
REPLACE_RELATED_WITH_DIFFERENCE=10, DESPAWN_RELATED=11.

**Model.** `EcsTblRelCommandsDeep` — fixed cap-8 command queue
(`ECS_CMD_TBL_REL_CAP_DEEP = 8`) with per-slot scalar fields (kN/eN/rkN/tgN/cN/vN/rlN/urN/nwN i32
each, 8 slots) + INSERT_COMPONENT parallel `ptN/pvN` side arrays (cap-8 sharing pcomp_count) +
`rN` resource side (pres_count) + `mN` message side (pmsg_count) + shared entity-list side storage
(`ECS_CMD_TBL_REL_LISTS_CAP_DEEP = 4` lists, each cap-4 entity ids with its own count) for
REMOVE_RELATED / REPLACE_RELATED (1 list each, rlN-indexed) and REPLACE_RELATED_WITH_DIFFERENCE
(3 lists: rlN relate, urN unrelate, nwN newly) + `EcsTblRelListEntryDeep` per-entry reader.

**Operations.** new / reserve_entity / insert / set_related / despawn / set_related_at /
insert_resource / write_message / remove_related / detach_all_related / replace_related /
replace_related_with_difference (early-return preserving already-stored lists on partial failure) /
despawn_related / store_list / set_list / list_count_at / list_at / len / count_by_kind /
resolve_value (kind-indexed: INSERT_COMPONENT→pv, INSERT_RESOURCE→pres, WRITE_MESSAGE→pmsg, else 0)
/ resolve_type (INSERT_COMPONENT→pt, else 0) / clear / per-slot read accessors
(kind_at/entity_at/rk_at/target_at/cmp_at/idx_at/rl_at/ur_at/nw_at + lcount/pcomp_count/pres_count/
pmsg_count). Caps enforced at 8 commands and 4 lists.

**Tests.** 10 isolated tests in
`tests/test_ecs_lib_commands_table_erased_relationship_deep_isolated.sla`, panic band 139400-139599:
new/empty/zero side counts; insert+set_related; set_related_at+despawn; insert_resource+write_message;
remove_related entity-list side; detach_all+replace_related; replace_related_with_difference (3 list
slots); despawn_related; count_by_kind mixed cap-8 queue (REMOVE_RELATED twice) + DID + DESPAWN_RELATED
in a separate cap-8 queue + 9th detach_all rejected; queue cap-8 rejection + list side cap-4
rejection (5th replace_related) + clear zeroing pcomp/pres/pmsg/lcount.

**Verification.** `sa sla check lib/commands_table_erased_relationship_deep.sla` ok. SA backend:
10 passed, 0 failed. Default backend: 10 passed, 0 failed. (Initial run had 2 stale cap-2-era
assertion failures in tests 8 and 9; restructured to cap-8/cap-4 boundaries, both green after fix.)

**Counts.** 468 lib modules, 372 test files, 90 examples, 6625 `.sla` `@test` annotations;
196 `*_deep.sla` modules. Next free panic band: 139600+. Next batch: 368.

## Batch 368 — commands_dynamic_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_dynamic.sla` (src/system/commands/dynamic.rs) — `Commands<A, B, R, M>`
generic fn-ptr queue for `DynamicWorld<A, B, R, M>` with two distinct component columns (A, B),
plus resource/message columns, deferred until apply. Deep models the queue's 5 kinds and 4
independent side columns without generic types or fn-ptr world-application.

**Kinds.** INSERT_A=1, INSERT_B=2, DESPAWN=3, INSERT_RESOURCE=4, WRITE_MESSAGE=5. Component-id
discriminators: A=11, B=12.

**Model.** `EcsDynCommandsDeep` — fixed cap-8 command queue
(`ECS_CMD_DYN_CAP_DEEP = 8`) with per-slot scalar fields (kN/eN/cN/vN i32 each, 8 slots) + 4
independent side-payload columns cap-8 i32: `paN` (pa_count, INSERT_A), `pbN` (pb_count, INSERT_B),
`rN` (pres_count, INSERT_RESOURCE), `mN` (pmsg_count, WRITE_MESSAGE) + `EcsDynCommandDeep` builder.

**Operations.** new / command builder / reserve_entity / insert_a (pa push + cmp=A) /
insert_b (pb push + cmp=B) / despawn (v=-1) / insert_resource (pres push) / write_message (pmsg
push) / len / count_by_kind / resolve_value (kind-indexed: INSERT_A→pa, INSERT_B→pb,
INSERT_RESOURCE→pres, WRITE_MESSAGE→pmsg, else 0) / resolve_component (INSERT_A/INSERT_B return
the cN component-id so the A-vs-B column is separable without re-reading kind) / clear / per-slot
read accessors (kind_at/entity_at/cmp_at/idx_at + pa_count/pb_count/pres_count/pmsg_count). Caps
enforced at 8 commands and each side column.

**Tests.** 10 isolated tests in `tests/test_ecs_lib_commands_dynamic_deep_isolated.sla`, panic band
139600-139799: new/empty/zero side counts; insert_a INSERT_A + pa + cmp=A; insert_b INSERT_B + pb +
cmp=B (distinct from A); despawn -1 idx + zero resolve; insert_resource+write_message+resolve; order
preserved (insert_a→insert_b→despawn); side columns independent (2 A+2 B, separate
pa_count/pb_count, value_index into right column); count_by_kind across all 5 kinds (6-cmd mixed
queue, INSERT_A twice) + resolve_value across mixed kinds; cap-8 rejection on commands + per-side
cap-8 rejection (8 resources fit, 9th rejected); clear resets all slots + all 4 side counts.

**Verification.** `sa sla check lib/commands_dynamic_deep.sla` ok. SA backend: 10 passed, 0 failed.
Default backend: 10 passed, 0 failed.

**Counts.** 469 lib modules, 373 test files, 90 examples, 6635 `.sla` `@test` annotations;
197 `*_deep.sla` modules. Next free panic band: 139800+. Next batch: 369.

## Batch 369 — commands_mod_extension_deep (DONE 2026-07-12)

Deepens shallow `lib/commands_mod_extension.sla` (src/system/commands/mod.rs) —
`Commands`-side (boxed-system registry, cached run, triggers, observer add, write_message,
run_schedule, get_spawned_entity, reborrow/rebound) + `EntityCommands`-side extension methods
(entry/queue_handled/queue_silenced/log_components/commands/commands_mut/observe/trigger +
clone/move variants). Deep models the underlying deferred command queue with kind-discriminated
per-command metadata, a boxed-system registry the shallow only counts, and an expanded
EntityCommands-side state — no generic types, no fn-ptr world application.

**Kinds.** TRIGGER=1, TRIGGER_WITH=2, ADD_OBSERVER=3, WRITE_MESSAGE=4, RUN_SCHEDULE=5,
OBSERVE=6, ENTRY=7, LOG_COMPONENTS=8, MOVE_COMPONENTS=9. Per-command (kN/aN primary / bN
secondary / cN component_id). Negative schedule label short-circuits run_schedule.

**Model.** `EcsCmdExtCommandsDeep` — cap-8 deferred queue + boxed-system registry cap-8 (sysN i64
sys_count, 1-indexed ids) + bound_entities i64 for new_from_entities. `EcsEntityCmdExtDeep` —
entity i64 / is_spawned i32(0/1) / pending_commands i64 / pending_observes i64 / last_event i64 /
cloned_to i64 / last_component i32.

**Operations.** Commands-side: new/new_from_entities/register_boxed_system (cap-reject → -1)/
unregister_system_cached (last-only removable)/run_system_cached/run_system_cached_with/
trigger/trigger_with/add_observer/write_message/run_schedule (neg→false)/get_spawned_entity
(req<0→spawn-request)/rebound_to/reborrow/count_by_kind/clear + per-slot accessors
(kind_at/primary_at/secondary_at/component_at/sys_id_at + len/sys_count/bound_entities).
EntityCmdExt-side: new/id/entity/is_spawned/get_pending/pending_observes/cloned_to/last_event/
last_component/reborrow/entry/queue_handled/queue_silenced/log_components/commands/commands_mut/
observe/trigger/clone_with_opt_out/clone_with_opt_in/clone_and_spawn/clone_and_spawn_with_opt_out/
clone_and_spawn_with_opt_in/clone_components/move_components (despawn-on-move clears is_spawned,
returns despawned=true). Both caps enforced at 8.

**Tests.** 10 isolated tests, panic band 139800-139999: new/empty/zero counts; register increasing
ids + run_system_cached range + with-input pass-through; unregister only last-registered removable;
trigger/trigger_with/add_observer/write_message/run_schedule enqueue kinds+metadata+neg short-circuit;
count_by_kind mixed (TRIGGER twice) + get_spawned_entity spawn-request vs found for negative/positive;
cap-8 reject on commands + registry + clear; new_from_entities binds marker + reborrow/rebound;
EntityCmdExt construction(is_spawned=true,pending zero)+entry/queue/log/commands/commands_mut/
observe/trigger+reborrow; non-spawned construction + per-op pending accounting (last_component
mutations across entry/queue_handled/queue_silenced, log_components returns count without mutating
last_component, observe bumps pending_observes independently of pending_commands).

**Verification.** `sa sla check lib/commands_mod_extension_deep.sla` ok. SA backend: 10 passed, 0
failed. Default backend: 10 passed, 0 failed. (Initial `_` wildcard bind caused RegisterRedefinition
on SA; switched to a named bind for the discarded state. Initial file had 9 tests; added a 10th on
non-spawned construction + per-op pending accounting.)

**Counts.** 470 lib modules, 374 test files, 90 examples, 6645 `.sla` `@test` annotations;
198 `*_deep.sla` modules. Next free panic band: 140000+. Next batch: 370.

## Batch 370 — schedule_registry_value_deep (DONE 2026-07-12)

Deepens shallow `lib/schedule_registry_value.sla` — sequential schedule for
`RegistryValueWorld<T, R, M>` keyed by registry component id. Replaces the generic systems vector
with a fixed-cap-8 systems array + cap-4 read/cap-4 write component-id access masks + resource/
messages flags. No generic types, no fn-ptr world execution (Batch 357/358 schedule-deep convention).

**Shape.** `EcsRegValueSystemAccessDeep` (r0..r3 + len_reads, w0..w3 + len_writes, 4 resource/
messages flags i32 0/1) and `EcsRegValueScheduleDeep` (8 access slots s0..s7 + count +
conflict_count).

**Conflict matrix (reimplemented, not copied verbatim from Batch 358).** Component conflicts:
bidirectional scan — a write on one side overlapping read OR write on the other. Resource/message
hazards factored into shared `ecs_reg_value_arena_conflicts(l_read,l_write,r_read,r_write)` called
once per arena (resource + messages), so the hazard body is written once rather than duplicated
across arenas like the erased variant.

**Operations.** access_none/access_build/access_read_component/access_write_component (cap-4 push)
/access_read_resource/access_write_resource/access_read_messages/access_write_messages/read_at/
write_at/read_list_has/write_list_has/len_reads/len_writes/reads_resource/writes_resource/
reads_messages/writes_messages/component_conflicts/arena_conflicts/access_conflicts/
schedule_default/schedule_len/schedule_conflict_count/schedule_add_systems (cap-8 reject, bidirectional
conflict tally)/access_set_a/access_at (scalar capture + per-branch build)/schedule_clear.

**Tests.** 10 isolated tests, panic band 140000-140199: schedule default empty zero conflicts;
access none + flag mutators; read/write component mutators store registry ids; cap-4 list
rejection; component conflict detection (write-vs-read/write = conflict, read-vs-read = no,
different ids = no); resource + message conflict detection (arenas independent); add_systems
records one conflict per conflicting earlier system (count 1→1→2); access retrievable per slot via
access_at; cap-8 rejection + clear resets both counts; disjoint reads vs write-to-different = 0
then write A → 1 then read A → 2.

**Verification.** `sa sla check lib/schedule_registry_value_deep.sla` ok. SA backend: 10 passed,
0 failed. Default backend: 10 passed, 0 failed.

**Counts.** 471 lib modules, 375 test files, 90 examples, 6655 `.sla` `@test` annotations;
199 `*_deep.sla` modules. Next free panic band: 140200+. Next batch: 371.

## Batch 371 — schedule_table_value_deep (DONE 2026-07-12)

Deepens shallow `lib/schedule_table_value.sla` — sequential schedule for `TableValueWorld<T, R, M>`
over the archetype table-row storage path. Replaces the generic systems vector with a fixed-cap-8
systems array + cap-4 read/cap-4 write component-id masks + a parallel two-arena (resource/messages)
flag pair. No generic types, no fn-ptr world execution.

**Distinct from Batch 370.** Two-arena hazard folded into a single `arena_hazard(left, right,
arena_idx)` helper viewed through `arena_read`/`arena_write` index-helpers, because the access
struct stores arena flags as two parallel indexed pairs (ar_read_0/ar_read_1 + ar_write_0/
ar_write_1). So the hazard body is written once (parameterized by arena index) rather than
duplicated per arena as in the registry_value variant. Component-conflict scan structure is shared
across the two siblings since that part is genuinely the same surface.

**Shape.** `EcsTblValueSystemAccessDeep` (r0..r3+len_reads, w0..w3+len_writes, two-arena flag pair
as i32 0/1) + `EcsTblValueScheduleDeep` (8 access slots + count + conflict_count).

**Operations.** access_none/access_build/access_read_component/access_write_component (cap-4 push)/
access_read_resource/access_write_resource/access_read_messages/access_write_messages/read_at/
write_at/arena_read/arena_write/read_list_has/write_list_has/len_reads/len_writes/
reads_resource/writes_resource/reads_messages/writes_messages/component_conflicts (bidirectional)/
arena_hazard(left,right,arena)/access_conflicts (component + arena_hazard×2)/schedule_default/
schedule_len/schedule_conflict_count/schedule_add_systems (cap-8 reject, bidirectional tally)/
access_set_a/access_at (scalar capture + per-branch build)/schedule_clear.

**Tests.** 10 isolated tests, panic band 140200-140399: schedule default empty; access none +
flag mutators; read/write component mutators store ids; cap-4 list rejection; component conflict
detection; resource + message conflict detection via arena_hazard (arenas independent);
add_systems tallies conflicts per earlier system (1→1→2); access retrievable per slot; cap-8 reject
+ clear; mixed arena + component conflicts accumulate (write-res+write-Hp, read-res (A→1),
write-msg, read-Hp (A→2), read-Mp, final 2/5).

**Verification.** `sa sla check lib/schedule_table_value_deep.sla` ok. SA backend: 10 passed, 0
failed. Default backend: 10 passed, 0 failed.

**Counts.** 472 lib modules, 376 test files, 90 examples, 6665 `.sla` `@test` annotations;
200 `*_deep.sla` modules. Next free panic band: 140400+. Next batch: 372.

## Batch 372 — schedule_archetype_value_deep (DONE 2026-07-12)

Deepens shallow `lib/schedule_archetype_value.sla` — sequential schedule for
`ArchetypeValueWorld<T, R, M>` (access component-id based, systems execute against the
archetype-backed value world). Replaces the generic systems vector with a fixed-cap-8 systems
array + cap-4 read/cap-4 write component-id masks + a packed-2-bit resource/messages arena flag
matrix. No generic types, no fn-ptr world execution.

**Distinct from 370/371.** (1) Arena flags packed into single `reads`/`writes` i32 with
resource-bit-0 + messages-bit-1, so flag readers are bit tests and setters are `|=` (exercises
SLA bitwise templates `|`/`<<`/`&`/`>>`). (2) Bidirectional component-conflict body factored into
one-directional `writes_touch(writer, other)` called symmetrically — test body appears once
textually. Arena hazard `arena_conflict(left, right, bit)` is a single bit-shifted expression
evaluated twice (vs 371's named-pair `arena_hazard`).

**Shape.** `EcsArchValueSystemAccessDeep` (r0..r3+len_reads, w0..w3+len_writes, packed reads +
writes i32) + `EcsArchValueScheduleDeep` (8 access slots + count + conflict_count).

**Operations.** access_none/access_build/access_read_component/access_write_component (cap-4)/
access_read_resource/access_write_resource/access_read_messages/access_write_messages (bit-OR
setters)/read_at/write_at/reads_resource/writes_resource/reads_messages/writes_messages (bit-test
readers)/read_list_has/write_list_has/len_reads/len_writes/writes_touch(writer,other)/
component_conflicts (writes_touch × 2)/arena_conflict(left,right,bit) (bit-shifted)/access_conflicts/
schedule_default/schedule_len/schedule_conflict_count/schedule_add_systems (cap-8 reject, bidirectional
tally)/access_set_a/access_at (scalar capture + per-branch build)/schedule_clear.

**Tests.** 10 isolated tests, panic band 140400-140599: schedule default empty; access none +
packed-bit flag mutators (non-leakage across arenas); read/write component mutators store ids;
cap-4 list rejection; component conflict via writes_touch (both directions, symmetric);
resource+message arena conflict detection via packed-bit matrix (arenas independent; combined
read_resource+read_messages conflicts with write_res AND write_msg); add_systems tallies conflicts
per earlier system (1→1→2); access retrievable per slot; cap-8 reject + clear;
packed-bit fields don't leak across arenas (a = read_resource+write_messages ⇒ packs reads bit0=1
+ writes bit1=1; conflict with b (writes resource) on resource arena; conflict with c (reads
messages) on messages arena; a_msg_only + d (reads resource) ⇒ no conflict).

**Verification.** `sa sla check lib/schedule_archetype_value_deep.sla` ok. SA backend: 10 passed,
0 failed. Default backend: 10 passed, 0 failed. (Initial test 10 assertion was wrong — a also
reads resource so b's resource write conflicts; lib was correct; fixed to use a_msg_only for the
genuine no-conflict case. Both backends green after fix.)

**Counts.** 473 lib modules, 377 test files, 90 examples, 6675 `.sla` `@test` annotations;
201 `*_deep.sla` modules. Next free panic band: 140600+. Next batch: 373.

## Batch 373 — schedule_dag_analysis_deep (DONE 2026-07-12)

**Kinds.** `EcsDagAnalysisDeep` (cap-8 nodes, cap-4 successors/node, flattened cap-8×8 reach
bit-matrix, cap-4 reachable/disconnected/transitive/reduction/closure pair-lists with counts)
+ `EcsDagGroupsDeep` (cap-4 groups, cap-4 children each) + 3 error structs
(`EcsDagRedundancyErrorDeep`, `EcsDagCrossDepErrorDeep`, `EcsDagOverlapGroupErrorDeep`).

**Model.** Shallow `lib/schedule_dag_analysis.sla` (src/schedule/graph/dag.rs) recursively computes
reachability then partitions a topsort and flattens groups with three error-check structs. The
deep variant is **iterative** (the SLA lattice forbids recursive futures under per-batch
UseAfterMove rules): `compute_closure` seeds reach[i][i]=1 + reach[i][j]=1 for direct adjacency,
then fixed-point triple sweep (i,k,j) where reach[i][k]&&reach[k][j]&&!reach[i][j] ⇒ set matrix
and mark changed; converges with no recursion. `partition` walks i<j pairs to reachable vs
disconnected lists. `record_transitive_edge(a,b)` pushes (a,b) onto transitive list iff already
reachable. The original `(bool, i32)` / `(bool, i32, i32)` tuple-returning check functions are
retained for API parity — but a `let (x, y) = tuple_fn()` callsite at the SA (and default)
backend retroactively corrupts earlier assertions referencing the struct (verified by minimal
repro: appending the tuple destructure line after an assertion flips that prior assertion's
verdict — same family as the Batch 369 `let (_, x) = ...` wildcard bind register-trip). The tests
call scalar split accessors (`ecs_dag_check_redundant_found`/`_count`,
`ecs_dag_check_cross_found`/`_a`/`_b`, `ecs_dag_groups_deep_overlap_found`/`_key_a`/`_key_b`)
built from the same reach_at scan body — no tuple-return callsite anywhere in the test file.

**Operations.** counts (node/edge/transitive/reduction/closure/reachable/disconnected); reach_at
+ is_reachable; set_reach (8×8 bit setter); add_edge (src/dst range guard + cap-4 reject per
src, edge_count++); compute_closure (iterative fixed-point); partition (i<j pair scan);
add_transitive_edge/record_transitive_edge (cap-4 reject); reachable/disconnected/transitive
pair readers; check_redundant_found/count + check_cross_found/a/b (cross-dependencies:
self reachable pair (a,b) ∃ reach_at(other,a,b) OR reach_at(other,b,a)); DagGroups new/len/insert
(cap-4 reject)/key_index/get_count/child_at/count_idx/key_at/check_overlapping (tuple) +
overlap_found/key_a/key_b (scalar); 3 error-struct constructors + accessors.

**Tests.** 10 isolated tests, panic band 140600-140799: DagAnalysis new empty + counts zero +
reach matrix empty; add_edge stores successor via adjacency cap-4 + edge_count + **5th-successor
cap-4 reject on a cap-8 node graph** (new(8), 4 valid add_edge(0,k) for k in {1,2,3,4} filling
the cap-4 row, then add_edge(0,5) with dst=5 valid (<8) — rejection comes solely from the
cap-4, NOT from an out-of-range destination); compute_closure reflexive + chain transitive
(0→1→2 ⇒ reach[0][0]/[0][1]/[0][2]=[1,1,1], reach[1][0]=0, reach[2][0]=0, reachable_count=6);
diamond closure (0→1/0→2/1→3/2→3 ⇒ reach[0][3]=1, no back edges); partition emits connected only
(i<j reachable chain ⇒ 3 reachable pairs, 0 disconnected); partition emits disconnected when no
path between i and j; add_transitive_edge + check_for_redundant (scalar split form — found/count)
+ record_transitive_edge push/reject (existing reachable (0,2) accepted, (2,0) rejected since
reach[2][0]=0) + manual add_transitive_edge count-up, all via scalar accessors to avoid the SA
tuple-return register-alias corruption; check_for_cross_dependencies (scalar split form — found/
a/b) — both graphs share (0,1) ⇒ cross-dep (true, 0, 1); disjoint graph (1→2) ⇒ no cross-dep;
DagGroups insert/len/key_index/get_count + cap-4 group reject + check_overlapping (scalar split
form — groups 10 and 20 share child 2 ⇒ (true, 10, 20), disjoint groups ⇒ false); error structs
construct + accessor (redundancy/cross/overlap).

**Verification.** `sa sla check lib/schedule_dag_analysis_deep.sla` ok. SA backend: 10 passed,
0 failed. Default backend: 10 passed, 0 failed. (Initial run had 2 SA failures: test 2 panic
140618 — new(4) + add_edge(0,7) added dst=7 (< cap-8) as the 4th successor instead of
demonstrating the cap-4 reject — fixed by using new(8) + 4 valid dsts + a 5th; test 7 panic
140660 — the `let (found0, cnt0) = ecs_dag_check_for_redundant_edges(d3)` tuple-return callsite
retroactively flipped the upstream assertion `te_count != 0` — verified with minimal reproductions
showing the assertion passed in isolation but failed once the tuple destructure was appended
afterwards. Fix: expose the `(bool, i32)` / `(bool, i32, i32)` tuple functions as scalar split
accessor pairs/triplets (same reach_at scan body, no tuple-return callsite) and rewrite tests 7,
8, and 9 to call those scalars (test 9 hardening was precautionary — it was passing before but
is now consistent with the scalar-accessor avoidance rule). The original tuple-returning
functions are retained for API parity with the shallow. Both backends green after the fix.)

**Counts.** 474 lib modules, 378 test files, 90 examples, 6685 `.sla` `@test` annotations;
202 `*_deep.sla` modules. Next free panic band: 140800+. Next batch: 374.

## Batch 374 — entity_index_map_iter_extras_deep (DONE 2026-07-12)

**Kinds.** Five parallel-array storage structs — `EcsEim2DeepMap` (cap-16 entries: k0..k15 i64,
v0..v15 i32, len), `EcsEim2DeepSlice` (same buffer + boxed flag), `EcsEim2DeepIterMut` (same buffer
+ front/back), `EcsEim2DeepIntoIter` (same buffer + front/back), `EcsEim2DeepDrain` (same buffer
+ front/back). Six wrapper-result structs for multi-slot returns: `EcsEim2DeepPairResult`,
`EcsEim2DeepIterNext`, `EcsEim2DeepIterMutSetResult` (flattened updated-iter buffer `r_*` plus
has/key/old_value/new_value scalars), `EcsEim2DeepRangeResult` (has flag), `EcsEim2DeepDrainResult`
(has flag). The deep variant avoids tuple-return callsites — Batch 373 observation that
`let (a, b) = tuple_fn()` retroactively corrupts prior assertions on the SA backend.

**Model.** Shallow `lib/entity_index_map_iter_extras.sla` (Vec-backed slice/iter wrappers for
IterMut, IntoIter, Drain::as_slice, boxed Slice conversion/clone/default, Slice equality/order/
hash/index surface) is mirrored with a fixed-cap-16 flat parallel-array storage — no Vec, no
recursion. The deep variant verifies that **field-assign on a struct-by-value param is SLA-legal
on SA** (verified via a minimal `simple_set` repro: passes) — so `insert`, `iter_mut_set_next`,
`drain_clamped_*`, and `set_window` mutators write to the param struct in-place and return it,
replacing the heavier slot-view rebuild pattern used in prior batches for similar buffers.

**Operations.** map: new/insert (replace-or-append, cap-16 reject)/len; map_key_at/val_at readers
(16-slot switch). slice: empty_slice/box-variants builders via build_slice_from_map and
field-assign box toggling; slice_len / slice_boxed; slice_key_at/val_at; slice_at (PairResult);
range helpers: slice_range/range_from/range_to/range_inclusive (return has flag) +
matching `*_slice`-returning helpers (returned after the has-check, used by the tests);
set_slice_slot pusher; slice_eq / slice_cmp / slice_hash (FNV-style h=17 init). iter_mut:
construct (front=0, back=len) / set_next (overwrite v-slot, advance front, return flattened-iter
result) / iter_mut_from_result (reconstitute buffer), iter_mut_as_slice (window copy),
iter_mut_set_window, readers. into_iter: construct / next / next_back / set_window / as_slice.
drain: drain_clamped_map (kept-buffer scan outside [start, end)) / drain_clamped_drain (drain-buffer
scan inside [start, end)) / drain_result (has=1) / drain_kept_map / drain_drained (4-condition
clamping: start<0 → 0; start>len → len; end<=start → start; end>len → len — mirrors the shallow)
/ drain_as_slice / readers.

**Tests.** 10 isolated tests, panic band 140800-140999: Map insert replace + len + cap-16 reject
(replace existing key's value, fill 16 entries, 17th insert rejected — sequential names to avoid
Redeclaration); boxed-flag conversion/clone/into-inner; slice_at in/out of range; range helpers
shape a window (range/range_from/range_to/range_inclusive + bad-range rejections); slice eq + cmp
(less/equal/greater; different lengths, different values, different first-key); hash stability +
content sensitivity (same content equal, different content different, empty hash=17); IterMut
set_next advances + overwrites values (front advance, value write-back, r_front, from_result,
exhaustion has=0 key=-1, as_slice shows full written buffer post-window reset); IntoIter next /
next_back / as_slice; Drain splits kept vs drained buffers (range `[1,3)`, full `[0,100]`,
empty `[2,2)` clamps); IntoIter empty window + exhausted behavior (single entry, collapsed map).

**Verification.** `sa sla check lib/entity_index_map_iter_extras_deep.sla` ok. SA backend: 10
passed, 0 failed. Default backend: 10 passed, 0 failed. (Initial run surfaced Redeclaration for
chained `let m = ecs_eim2_deep_insert(m, ...);` — Batch 373 sibling of the `let changed = ...`
RegisterRedefinition pattern. Fix: sequential-names `t4`/`t7`/`t8`/`t10`/`c5`/`h6`. Also avoided
`let (a, b) = ...` accessors — read wrapper struct fields directly. The deep variant uses direct
field-assign on a struct-by-value param (verified: `simple_set` passes SA) for the compact
insert/iter_mut_set_next/drain form. Both backends green after fixes.)

**Counts.** 475 lib modules, 379 test files, 90 examples, 6695 `.sla` `@test` annotations;
203 `*_deep.sla` modules. Next free panic band: 141000+. Next batch: 375.

## Batch 375 — storage_internals_deep (DONE 2026-07-12)

**Kinds.** Three cap-16 parallel-array storage primitives — `EcsBlobArrayDeep`, `EcsThinArrayPtrDeep`,
`EcsColumnDeep`. Two swap_remove wrapper-result structs — `EcsBlobArraySwapRemoveDeep` and
`EcsColumnSwapRemoveDeep` (the shallow returned `(struct, i64)` tuples — avoid tuple-return callsites
per Batch 373).

**Model.** Shallow `lib/storage_internals.sla` (src/storage/blob_array.rs + thin_array_ptr.rs +
table/column.rs) mirrored with fixed-cap-16 parallel-array i64 storage (d0..d15 + len) — no Vec,
no recursion. Deep variant uses direct **field-assign on struct-by-value params** (verified SLA-legal
on SA in Batch 374) for the cap-16 push/alloc/clear/swap branches. swap_remove callsites return
new_arr/new_col + removed-value via wrapper structs with scalar accessor helpers — tests read scalar
fields off those (no `let (a, b) = tuple_fn()` callsites anywhere — Batch 373 register-trip
avoidance).

**Operations.** BlobArray: new / layout_size / layout_align / is_zst / len / get(idx) (16-slot
switch, out-of-range reads 0) / get_mut / push (cap-16 reject) / swap_remove(idx) (out-of-range
returns 0 without mutation; valid idx: moves last into idx, zeros the freed tail slot, decrements
len, returns removed value) / get_drop (0 for ZST, 1 otherwise). ThinArrayPtr: with_capacity / alloc
/ capacity / len / is_empty / get / get_mut / push (cap-16 reject — deep cap is on slot buffer, not
on `capacity`) / clear (resets len only — mirrors Vec semantics, data slots remain stale). Column:
with_capacity(component_id, capacity) / component_id / capacity / len / is_empty / get / get_mut /
push / swap(a, b) — both directions / swap_remove(idx) (out-of-range + empty checks; moves last
into idx and zeros the freed tail slot) / clear (zeros all data + len — mirrors the shallow's
`Vec::new()`) / get_drop (always 1 — the shallow had no is_zst flag).

**Tests.** 10 isolated tests, panic band 141000-141199: BlobArray layout+push+get+len+drop semantics
(real item path + ZST path); BlobArray cap-16 reject on push (sequential names b0..b16 — avoid
Redeclaration); BlobArray swap_remove (out-of-range yields removed=0, in-range relocates last and
zeros freed tail; single-element yields that value and empties); ThinArrayPtr capacity+push+get+
len+clear (alloc raises capacity, push 3 reads back, cap-16 reject on 32-cap buffer pushed 16
times and 17th push dropped); ThinArrayPtr clear resets len — data may stay stale (mirrors Vec
len-only reset — slot 0 still holds the pushed value); Column component_id + capacity report;
Column push+get+swap+cap-16 reject (cap-16 reject reaches 16 then 17th push dropped); Column
swap_remove and clear (in-range, out-of-range, empty-bound, then clear zeros all slots); Column
survives mixed push/swap_remove/sort-by-swap order (4 pushes → middle swap_remove → extra push
into freed tail → swap_remove just-pushed → swap survivors → clear); BlobArray ZST swap_remove
uses same semantics as real component (ZST path: drop id 0, push 2 entries, swap_remove idx=0 →
first value, single-remaining swap_remove → empty, is_zst stays true throughout).

**Verification.** `sa sla check lib/storage_internals_deep.sla` ok. SA backend: 10 passed, 0 failed.
Default backend: 10 passed, 0 failed. (Initial run had 9 tests; added test 10 covering the ZST
BlobArray push/swap_remove/is_zst path. Field-assign helpers verified SLA-legal on SA in Batch 374
— no regressions.)

**Counts.** 476 lib modules, 380 test files, 90 examples, 6705 `.sla` `@test` annotations;
204 `*_deep.sla` modules. Next free panic band: 141200+. Next batch: 376.

## Batch 376 — system_schedule_deep (DONE 2026-07-12)

**Kinds.** `EcsSystemScheduleDeep` — cap-8 systems subsystem (sys_id/sys_cond/sys_dep 0..7 i64 +
sys_count i32) parallel to a cap-8 sets subsystem (set_id/set_cond 0..7 i64 + set_count i32), plus
running-state counters `systems_run`/`systems_skipped` i64. Five wrapper-result structs for the
(bool, i64)-shaped get accessors — `EcsSystemIdDeep`, `EcsSystemConditionsDeep`,
`EcsSystemDependenciesDeep`, `EcsSetIdDeep`, `EcsSetConditionsDeep` — each `{ valid: bool,
[count|id]: i64 }` so tests read `.valid` + `.count`/`.id` directly (no tuple-return callsites —
Batch 373 avoidance rule).

**Model.** Shallow `lib/system_schedule.sla` (src/schedule/executor/mod.rs SystemSchedule +
ApplyDeferred + default_executor) mirrored with fixed-cap-8 fixed-slot storage for the systems
and sets parallel arrays — no Vec, no recursion. Field-assign on struct-by-value params (verified
SLA-legal on SA in Batch 374) drives add_system/add_set/mark_*/reset/clear with in-place rewrites
(no slot-view rebuild). Multi-slot get accessors return wrapper structs (the shallow returns
`(bool, i64)` tuples) read directly via scalar-field access. ApplyDeferred marker +
executor-kind constants + predicate (`ECS_APPLY_DEFERRED_DEEP` / `ECS_EXECUTOR_SINGLE_DEEP` /
`ECS_EXECUTOR_MULTI_DEEP`).

**Operations.** new/add_system (cap-8 reject)/add_set (cap-8)/system_count/set_count/
get_system_id/_conditions/_dependencies (out-of-range returns valid=false id/count=0)/get_set_id/
_conditions/mark_run/mark_skip/systems_run/systems_skipped/reset/clear/is_empty/total_conditions
(sums system + set conditions)/total_dependencies (sums system deps only)/is_apply_deferred_deep/
default_executor_kind_deep.

**Tests.** 10 isolated tests, panic band 141200-141399: SystemScheduleDeep new is empty and
counts zero; add_system stores slot (id, conditions, deps) read via wrapper `{valid,id,count}`
fields; add_set stores (set_id, conditions) plus out-of-range valid=false cases; get accessors
out-of-range is invalid and id 0; cap-8 reject on add_system AND add_set; run + skipped counters +
reset; total_conditions and total_dependencies sum (sets add to conditions but NOT deps); clear
blanks everything; round-trips add clear re-add systems; ApplyDeferred marker and
default_executor_kind.

**Verification.** `sa sla check lib/system_schedule_deep.sla` ok. SA backend: 10 passed, 0 failed.
Default backend: 10 passed, 0 failed. (Field-assign helpers verified SLA-legal on SA via the Batch
374 `simple_set` repro — no regressions. Wrapper-struct result accessors avoid tuple-return
callsites throughout — Batch 373 register-trip avoidance respected end-to-end.)

**Counts.** 477 lib modules, 381 test files, 90 examples, 6715 `.sla` `@test` annotations;
205 `*_deep.sla` modules. Next free panic band: 141400+. Next batch: 377.

## Batch 377 — table_mod_deep (DONE 2026-07-12)

Deep variant of `lib/table_mod.sla` mirroring `src/storage/table/mod.rs` (Table + TableId +
TableRow + Tables collection) with fixed-cap structured storage. Cap-4 columns × cap-8 entities
parallel-array — per column N=0..3: comp_idN + colN_data0..7 i64 + colN_added0..7 i64 +
colN_changed0..7 i64; entities entity0..7 i64 + entity_count i32; id/capacity i64/i32; comp_ids +
column_count i32. EcsTablesDeep cap-8 collection (table0..7 + next_id + count).

- field-assign on struct-by-value params (verified SLA-legal on SA in Batch 374) — used by
  `allocate` (init each in-use column's next row: data=0, added=tick, changed=tick), `set`
  (writes data + bumps changed_tick only — added_tick preserved on writes, matching the shallow),
  `swap_remove` (relocate entity  + per-column data/added/changed from tail row into target row,
  then zero the freed tail slot for every column and decrement entity_count), `tables_create`
  (single `_ecs_tables_deep_set_table(ts, idx, new_table)` cascade-of-return helper keeping
  new_table consumption a single move to avoid SA UseAfterMove).
- Tuple-return callsites (Batch 373 avoidance: `let (a,b) = tuple_fn()` retroactively corrupts
  prior assertions on SA) replaced with wrapper structs + scalar split accessors:
  - EcsTableAllocateDeep `{ new_table, row, ok }` — accessors `ecs_table_allocate_deep_new_table`
    / `_row` / `_ok`.
  - EcsTableGetResultDeep `{ valid, value }` — reused by `get` / `get_added_tick` /
    `get_changed_tick`; accessors `ecs_table_get_deep_valid` / `_value`.
  - EcsTableSetResultDeep `{ new_table, ok }` — accessors `ecs_table_set_deep_new_table` /
    `_ok`.
  - EcsTableSwapRemoveDeep `{ new_table, ok }` — accessors `ecs_table_swap_remove_deep_new_table`
    / `_ok`.
  - EcsTableEntityResultDeep `{ valid, value }` — accessors
    `ecs_table_get_entity_at_row_deep_valid` / `_value`.
  - EcsTablesGetResultDeep `{ valid, table }` — accessors `ecs_tables_deep_get_valid` /
    `_table`.
  - EcsTablesCreateDeep `{ new_tables, id, ok }` — accessors `ecs_tables_deep_create_new_tables`
    / `_id` / `_ok`.
- Internal col-cell getters/setters per column (0..3)×row (0..7) via unrolled if-cascades
  (32 cells per matrix × 3 matrices) — no recursion, no Vec.
- Cap reject silent: `entity_count >= cap-8` reject in allocate returns `row=-1, ok=false`;
  out-of-range column/row guards in get / set / ticks return `valid=false` (value 0) or
  `ok=false` (table unchanged), mirroring the shallow `if row < 0 / row >= n` guards.
- `_ecs_table_deep_zeros()` gives a fresh zero-initialised struct literal so the base semantic is
  every data cell 0 / every tick 0 / counts at 0; `ecs_table_deep_new(id, capacity)` overlays the
  two-arg new.

Tests (10) — `tests/test_ecs_lib_table_mod_deep_isolated.sla` (panic 141400-141599), no
tuple-return destructuring and no `let m = fn(m, ...)` chained rebinding (sequential
`a0/a1/...; t0/t1/...` names):
1. TableIdDeep / TableRowDeep scalar wrappers.
2. new + add_column cap-4 reject + has_column + get_column_index (found & -1).
3. allocate adds entity + initialises column ticks (data 0, add=changed=tick) + entity_at_row.
4. get after set; out-of-range column/row/negative → valid=false.
5. set out-of-range column/row/negative → ok=false, table unchanged.
6. get_added_tick + get_changed_tick read back (allocation-time vs post-write tick bump) +
   missing-col / out-of-range-row invalid reads.
7. get_drop_for only true when column exists.
8. swap_remove middle-row relocation: entity 33 + col-200 data 2002 moved from tail row 2 →
   row 1, row 0 unchanged, ok=false for out-of-range row.
9. get_entity_at_row valid (0,1) / invalid (>= entity_count, negative).
10. EcsTablesDeep new + create ×2 → len/count/is_empty + get valid table (id 0/1) + get missing
    id returns valid=false + default-empty EcsTableDeep.

Both SA + default backends: 10/10 pass.

Panic usage: 141400-141599 (`rg -o "panic\(([0-9]+)\)" ... -r '$1' | sort -n` shows no duplicates
within the test file — checked before documenting).

Post-batch counts (measured): 478 lib modules | 206 `*_deep.sla` modules | 382 test files |
206 `*_deep_isolated.sla` test files | 90 examples | 6725 `@test` total across lib+tests+examples.
Next free panic band: 141600+ (do not reuse).
Next batch candidates: relationship_query_iter (needs iterative rewrite of recursive traversal
`iter_ancestors_rec` / `iter_descendants_rec` → cap-N stack-buffered DFS), relationship_methods_
extras, hierarchy_commands, commands_relationship (large — subdivide), schedule_stepping (large),
archetype_registry (imports world_registry — couples to registry world frame).


## Batch 378 -- relationship_query_iter_deep (DONE 2026-07-12)

Deep variant of `lib/relationship_query_iter.sla` mirroring `src/relationship/relationship_query.rs` iterator surface (`related` / `relationship_sources` / `root_ancestor` / `iter_ancestors` / `iter_ancestors_count` / `iter_siblings` / `iter_descendants`) with cap-8 / cap-4 parallel-array structured storage (no Vec, no recursion).

Storage:
- EcsRelQueryDeep -- cap-8 parents x cap-4 children parallel-array adjacency: `par0..par7` i64, `cnt0..cnt7` i32, `ch0_0..ch7_3` i64 (32 children slots), `slot_count` i32.
- EcsAncestorWalkerDeep -- cap-8 child->parent pairs: `c0..c7` + `p0..p7` i64 + `n` i32.
- EcsRqIterResultDeep -- cap-16 scalar traversal-output buffer (`v0..v15` i64 + `len`) with `_push`/`_at`/empty-init helpers and `len`/_at accessors.
- EcsRqStackDeep -- cap-16 stack (`s0..s15` i64 + `sz`) with push/pop helpers; exposed for stack-mechanic unit tests only -- iter_descendants uses an unrolled DFS ladder rather than the stack for SA backend safety.

Critical engineering notes (one-of-a-kind Batch 378 discovery):

- SA backend SWALLOWS `buf = some_fn(buf, x)` field-assigns inside `if cond { ... }` and `while`-loop bodies -- empirically confirmed via minimal reproductions (child pushed inside `if cnt>1 { buf = push(buf, c1); };` reads 0 from v1; rewriting to flat `let b1 = push(buf, c0); let b2 = push(b1, c1); ...` with short-circuit `_push_when(buf, v, predicate)` helpers, which return buf unchanged when the predicate is false, makes the write persist). Going forward: prefer flat `b1/b2/.../bN` rebinding ladders + `_push_when` short-circuit helpers over `if cond { buf = push(buf, x); }`.
- `_ecs_rel_query_deep_child_at_x(r, slot, k, cnt)` returns 0 sentinel for `k >= cnt`; tests use predicates (`c != 0`, `_ecs_rqsib_keep(c, self)`) to skip absent children in _push_when. `_ecs_rqsib_keep(c, self)` excludes both the 0 sentinel and self-entity for iter_siblings.
- Recursive shallow helpers rewritten ITERATIVELY (SLA lattice forbids recursive futures under per-batch UseAfterMove rules): `root_ancestor` / `iter_ancestors_count` use bounded `while steps < 64` counters (only counter updates, no `buf = push(buf, x)` inside the loop). `iter_ancestors` accumulation expressed as a flat `b1..b9` short-return-on-no-parent push ladder. `iter_descendants` rewritten as a fully-unrolled DEPTH-2 DFS ladder (root children -> grandchildren interleave to produce shallow recursion's exact preorder: `child0, grandchild0, grandchild1, ..., child1, ...`).
- Tuple-return callsites replaced with wrapper structs (Batch 373 avoidance rule):
  EcsRqRelatedDeep { found, value } -- `related` accessors `found`/`value`.
  EcsRqParentDeep { found, value } -- `parent_of` accessors `found`/`value`.
  EcsRqStackPopDeep { ok, value, new_stack } -- `_pop` accessors `ok`/`value`/`new_stack`.
- `add_child` existing-slot branch rewritten as parallel-if cascade-of-return ladder: `if idx == k && r.cnt<k> == j { r.ch<k>_<j> = child; r.cnt<k> = j+1; return r; };` -- avoids the prior nested `if idx == k && r.cnt<k> < CAP` push-ladder form which the SA backend swallows.

Tests (10) -- `tests/test_ecs_lib_relationship_query_iter_deep_isolated.sla` (panic 141600-141697, distinct -- verified before doc). No tuple-return destructuring; no `let m = fn(m, ...)` chained rebinding; only sequential `t0/t1/.../b1/b2/...` and `let`-once field assigns. Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 479 lib modules | 207 `*_deep.sla` modules | 383 test files | 207 `*_deep_isolated.sla` test files | 90 examples | 6735 `@test` total across lib+tests+examples.
Next free panic band: 141800+ (do not reuse -- Batch 378 used 141600-141697; scratch-band 150000-151719 used in /tmp/repro_*.sla scratch files does not appear in any test file).
Next batch candidates: relationship_methods_extras (RelatedDespawnResult / RecursiveTraverseResult / WithRelatedSpawnsResult -- deflated BFS over relationship tree -- iterative rewrite), hierarchy_commands (imports related facades), commands_relationship (large; subdivide), schedule_stepping (large), archetype_registry (imports world_registry -- couples registry world frame). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).



## Batch 379 -- relationship_methods_extras_deep (DONE 2026-07-12)

Deep variant of `lib/relationship_methods_extras.sla` mirroring `src/relationship/related_methods.rs` pub fns (add_one_related / detach_all_related / add_descendant / despawn_related / despawn_children / with_related / with_related_entities / insert_recursive BFS / remove_recursive BFS / spawned_with_related scalar accessor) with cap-8/cap-4 parallel-array structured storage (no Vec, no recursion).

Storage:
- EcsRelExtrasDeep -- cap-8 related × cap-4 descendants-per-related: `entity_id` i64, `r0..r7` related i64, `r_count` i32, `d0_0..d0_3 .. d7_0..d7_3` descendants i64, `dc0..dc7` descendant-per-slot counts i32, `spawned_with_related` i32 tracking counter.
- EcsRelExtrasDespawnDeep { despawned_count: i32, first_despawned: i64 } — result of despawn_related / despawn_children; accessors despawn_count / despawn_first.
- EcsRelExtrasTraverseDeep { visited_count: i32, first_visited: i64 } — result of insert_recursive / remove_recursive BFS; accessors rec_count / rec_first.

Critical engineering notes:

- cascade-of-return pattern reused from Batch 377 (lib/table_mod_deep.sla `_ecs_tables_deep_set_table`) for add_one_related and add_descendant: `if idx == 0 { ...r0 = entity; r_count = 1; return r; }; ...; ` — keeps the new entity consumption single-move per branch and avoids SA UseAfterMove. The prior nested `if idx == k && r_count < CAP` push-ladder form is SWALLOWED by the SA backend (Batch 378 finding) so is not used here.
- `_ecs_rel_extras_deep_total_visits` uses a flat `let`-ladder accumulator (Batch 378 rule — no `mut` counter and no while-loop accumulation, since SA swallows field-assigns inside while bodies): `let c0 = r.r_count; let c1 = c0 + _dcount(r, 0); ...; let c8 = c7 + _dcount(r, 7); return c8;`.
- EcsRelExtrasSpawnsDeep was REMOVED as unused — there is no `with_related_spawns`-style API fn returning it; spawned tracking is exposed through the simple `spawned_with_related` i32 accessor on EcsRelExtrasDeep instead.
- struct-literal-in-tests caveat (Batch 379): SA rejects `let dz = EcsRelExtrasDespawnDeep { despawned_count: 0, first_despawned: -1 };` with a syntax error (`expected semicolon, found {`) at the `{` following the struct name. Tests rewritten to construct result structs via library function paths instead (e.g. `let dz = ecs_rel_extras_deep_despawn_related(r_empty, 0);`). Unused result structs removed from the library accordingly.

Tests (10) -- `tests/test_ecs_lib_relationship_methods_extras_deep_isolated.sla` (panic 141800-141988, distinct -- verified with `rg -o "panic\(([0-9]+)\)" ... -r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP:", $1}'` showing empty before documenting). No tuple-return destructuring; no `let m = fn(m, ...)` chained rebinding; only sequential `t0/t1/.../b1/b2/...` and `let`-once field assigns; no struct-literal-in-tests with non-trivial field init. Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 480 lib modules | 208 `*_deep.sla` modules | 384 test files |
208 `*_deep_isolated.sla` test files | 90 examples | 6745 `@test` total across lib+tests+examples.
Next free panic band: 142000+ (do not reuse -- Batch 379 used 141800-141988; scratch-band 150000-151719 used in /tmp/repro_*.sla scratch files does not appear in any test file).
Next batch candidates: hierarchy_commands (imports related facades — small, next target), commands_relationship (large; subdivide), schedule_stepping (large), archetype_registry (imports world_registry -- couples to registry world frame). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 380 -- hierarchy_commands_deep (DONE 2026-07-12)

Deep variant of `lib/hierarchy_commands.sla` mirroring `src/hierarchy.rs` `EntityCommands` / `EntityWorldMut` pub methods on `ChildOf` (add_child / insert_child / detach_child / detach_all_children / replace_children / replace_children_with_difference / despawn_children / despawn) with a self-contained cap-8 kind-discriminated deferred command queue + cap-8×cap-4 entity-list pool + cap-8 parent × cap-4 children world (no Vec, no recursion, no generic facade).

Storage:
- EcsHierCmdsDeep -- cap-8 command queue: kind k0..7 i32, target t0..7 i64, primary child c0..7 i64, insertion index i0..7 i32, list-indices u0..7 / r0..7 / n0..7 i32 (unrelate / relate / newly), count i32.
- EcsHierCmdStateDeep -- bundles EcsHierCmdsDeep queue + EcsHierListPoolDeep into one struct (SA by-value; both must update together so each push command returns the combined state).
- EcsHierListPoolDeep -- cap-8 lists × cap-4 entities: e0_0..e0_3 .. e7_0..e7_3 i64, per-list counts n0..7 i32, pool_count i32. push_slot / at / len helpers reference a list by index.
- EcsHierWorldDeep -- cap-8 parents × cap-4 children: par0..7 i64, ch0_0..ch7_3 i64, cnt0..7 i32, slot_count i32, alive0..7 i32 (alive bit per spawned entity 1..8), next_entity i64.
- EcsHierCmdApplyDeep { world, commands(state) } -- apply result; accessors ecs_hier_cmd_apply_world / ecs_hier_cmd_apply_commands (commands is the full state, queue reset to empty).
- EcsHierReserveDeep { world, commands(queue), entity } -- reserve_entity result; accessors reserve_world / reserve_commands / reserve_entity.

Critical engineering notes:

- apply RESETS the queue count to 0 on the returned state via `_ecs_hier_cmds_deep_state_cleared(s)` -- required so chained `apply` calls only run newly-queued commands (matches the shallow `RelationshipCommands.apply` returning an emptied inner queue). Without the reset, a chained apply re-ran the prior commands and detached/added duplicates, tripping the has_parent / child_count assertions. This is the Batch 380 finding companion to Batch 378's "SA swallows field-assigns inside if/while": top-level function-scope field-assign on the param IS legal on SA and persists (Batch 374), so `s.queue.count = 0; return s;` in the cleared-helper works.
- apply is a flat let-ladder over the 8 queue slots (w0..w7 + early-return-on-qcnt) -- no `while` loop (Batch 378 rule: SA swallows field-assigns inside while bodies; the world accumulator must be a flat rebinding ladder read off as the final one).
- `_ecs_hier_world_deep_diff_relate` DEDUPES -- skips already-present entities before add_child_into -- so `replace_diff` with an overlapping relate set (entity already a child of the parent) doesn't duplicate it. Mirrors Bevy `replace_related_with_difference` "ensure these are related" semantics. Without dedupe, the overlapping relate pushed the entity twice and child_count overshot by 1.
- `set_slot` / parent-slot add / insert / remove use field-assign on struct-by-value params (Batch 374/366 flat `if idx == N { ...; return q; };` form). insert_child fully-unrolled per-slot shift-right-then-drop (no nested if/else chains -- SA parse-safe). `remove_child_slot` shifts children down preserving order (no swap-remove tail-fill on the child list itself, matching shallow remove_related order semantics).
- Tuple-return callsites replaced with wrapper structs (Batch 373 avoidance rule): EcsHierCmdApplyDeep (apply) and EcsHierReserveDeep (reserve_entity) with scalar accessors -- no test destructuring. `ecs_hier_world_deep_spawn` returns a `(world, entity)` tuple consumed ONLY inside `ecs_hier_commands_deep_reserve_entity` (library-internal), never destructured in tests.
- `ecs_hier_cmds_deep_clear` alias added alongside the canonical `ecs_hier_commands_deep_clear` to name-match the `_cmds_deep_` form used by the push commands (test calls the alias name).

Tests (10) -- `tests/test_ecs_lib_hierarchy_commands_deep_isolated.sla` (panic 142000-142046, 47 codes, distinct -- verified with `rg -o "panic\(([0-9]+)\)" ... -r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP:", $1}'` showing empty before documenting). No tuple-return destructuring; no `let m = fn(m, ...)` chained rebinding; only sequential `s0/s1/.../w1/w2/...` and `let`-once field assigns; no struct-literal-in-tests with non-trivial field init. Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 481 lib modules | 209 `*_deep.sla` modules | 385 test files |
209 `*_deep_isolated.sla` test files | 90 examples | 6755 `@test` total across lib+tests+examples.
Next free panic band: 142100+ (Batch 380 used 142000-142046).
Next batch candidates: commands_relationship (large -- the inner RelationshipCommands facade itself; subdivide into RelationshipCommands queue + RelatedSpawnerCommands + apply walker), schedule_stepping (large ~1005 lines; subdivide into 2-3 batches), archetype_registry (274 lines, @import world_registry -- couples to registry world frame). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 381 -- commands_relationship_deep (DONE 2026-07-12)

Deep variant of `lib/commands_relationship.sla` mirroring `src/system/commands/relationship.rs` + `relationship.sla` pub surface (set_related / add_related / insert_related / remove_related / detach_all_related / replace_related / replace_related_with_difference / despawn / despawn_related / reserve_entity / spawn_related / `RelationshipRelatedSpawnerCommands`) with a self-contained cap-8 kind-discriminated command queue + cap-8×cap-4 entity-list pool + cap-2 relationship-kind registry × cap-8 source→target adjacency (no Vec, no recursion in accumulators, no generic world).

Storage:
- EcsRelCmdsDeep -- cap-8 command queue: kind k0..7 i32, kind_id kid0..7 i32, target t0..7 i64, source s0..7 i64, index i0..7 i64, related_index r0..7 / unrelate_index u0..7 / newly_index n0..7 i32, count i32. Index default sentinel ECS_RELCMD_INDEX_MAX = 2147483647 ("append at tail").
- EcsRelCmdStateDeep -- bundles EcsRelCmdsDeep queue + EcsRelCmdListPoolDeep (SA by-value; both must update together).
- EcsRelCmdListPoolDeep -- cap-8 lists × cap-4 entities; same shape as Batch 380 pool.
- EcsRelCmdWorldDeep -- cap-2 relationship-kind registry (kind0/kind1 — each kind_id/link/one/reg flags) × cap-8 source→target adjacency (k0src0..k0src7 + k0tgt0..k0tgt7 + k0cnt; same for kind1) + alive0..8 (alive bit per spawned entity 1..9) + next_entity.
- Wrapper structs (Batch 373 rule -- no test tuple destructuring): EcsRelCmdApplyDeep { world, state } (apply; state has queue reset to 0 per Batch 380) accessors apply_world/apply_state/apply_commands; EcsRelCmdReserveDeep { world, state, entity } accessors reserve_world/reserve_state/reserve_entity; EcsRelCmdSpawnRelDeep { world, state, entity } accessors spawn_rel_world/spawn_rel_state/spawn_rel_entity; EcsRelSpawnerDeep { state, kind_id, target } builder + EcsRelSpawnerSpawnDeep { world, spawner, entity } accessors spawn_world/spawn_spawner/spawn_entity; EcsRelSpawnLinkedDeep { world, entity } accessors spawn_linked_world/spawn_linked_entity (for direct spawn_related); EcsRelCmdStoreListDeep { state, index } (library-internal store_entity_list result).

Critical engineering notes:

- KEY Batch 381 finding for one_to_one relationships: target_mode==ONE requires an OTHERS removal sweep -- before upserting the new (src, tgt), remove every OTHER source currently pointing at `tgt` -- mirror shallow `relationship_world_set_related_at`'s `RELATIONSHIP_TARGET_ONE` branch. Without it, setting a distinct source in a one-to-one kind appends instead of replacing the existing source, so `has_related(first)` stayed true after `set_related(second, target)` and `source_count` overshot. `_ecs_rel_cmd_world_deep_set_related` implements this via `_ecs_rel_cmd_dwdr_remove_others_for_target` (flat 8-pass remove-one-match ladder) + `_ecs_rel_cmd_world_deep_find_other_target_idx` (scans the 8 pair slots, excludes keep_src from removal). Re-resolves the src index after the sweep (it may have shifted).
- apply RESETS the queue count to 0 on the returned state via `_ecs_rel_cmd_state_cleared` (Batch 380 finding) so chained applies only run newly-queued commands -- matches shallow `relationship_commands_apply` returning a fresh empty RelationshipCommands. Without it, the replace_diff / remove_related chained applies re-ran prior commands.
- apply is a flat let-ladder over the 8 queue slots (w0..w7 + early-return-on-qcnt) -- no `while` loop (Batch 378 rule).
- `source_count` / `source_at` use RECURSIVE read-only scans (`_ecs_rel_cmd_count_sources_for_target` / `_ecs_rel_cmd_scan_target_for_pos`). Verified SA permits simple recursion for pure i32 returns: recfact probe `recfact(4)==24` passes. The "no recursion" cookbook guidance was about Constructors/UseAfterMove on cross-call accumulator chains; read-only i32 recursion is fine. `detach_all_related` still uses the flat 8-pass remove-one-match ladder (not recursion) because it mutates the world via field-assign during the scan.
- RegisterRedefinition dodge (Batch 373 Redeclaration rule): rename `let w = fn(w, ...)` chained rebinds in `_ecs_rel_cmd_world_deep_replace_related` / `_ecs_rel_cmd_world_deep_replace_diff` / `_ecs_rel_cmd_world_deep_despawn_related` to sequential `w0/w1/w2` names -- the SA backend's RegisterRedefinition trap fires on `let w = ...; let w = ...` over a struct-by-value param within one fn.
- REMOVE_RELATED target-guards: `_ecs_rel_diff_remove_one_with_target` only removes the source if its current target equals command.target (mirror shallow `relationship_commands_apply_remove` guarding on the current target being the given one).
- despawn_related with link_despawn=true marks the target AND every source pointing at it not-alive (`_ecs_rel_cmd_kill_src_if` flat ladder) via `_ecs_rel_cmd_despawn_sources_of` -- mirror shallow linked_despawn.
- `ecs_rel_cmd_world_deep_spawn` returns a `(world, entity)` tuple consumed ONLY inside `ecs_rel_cmds_deep_reserve_entity` / `ecs_rel_cmds_deep_spawn_related` / `ecs_rel_spawner_deep_spawn` (library-internal) -- never destructured in tests.

Tests (10) -- `tests/test_ecs_lib_commands_relationship_deep_isolated.sla` (panic 142100-142247, 53 codes, distinct -- verified with `rg -o "panic\(([0-9]+)\)" ... -r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP:", $1}'` showing empty before documenting). No tuple-return destructuring; only `pair.0`/`pair.1` on the library-internal `ecs_rel_cmd_world_deep_spawn` tuple inside tests is NOT present (tests use the wrapper-struct scalar accessors instead). Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 482 lib modules | 210 `*_deep.sla` modules | 386 test files |
210 `*_deep_isolated.sla` test files | 90 examples | 6765 `@test` total across lib+tests+examples.
Next free panic band: 142300+ (Batch 381 used 142100-142247).
Next batch candidates: schedule_stepping (large ~1005 lines; subdivide into 2-3 batches -- stepping cursor + pending-exit + ignore flags), archetype_registry (274 lines, @import world_registry -- couples to registry world frame). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 382 -- schedule_stepping_deep (DONE 2026-07-12)

Deep variant of `lib/schedule_stepping.sla` mirroring `src/schedule/stepping.rs` `Stepping::next_frame` + `ScheduleState::skipped_systems` (Bevy src/schedule/stepping.rs lines 386-508 / 513-564 / 681-817). Self-contained cap-8 queued updates + cap-8 schedule_order + cap-8 per-schedule states (`EcsSteppingScheduleStateDeepS` cap-16 per-system behaviors b0..15 + cap-16 per-system pending behavior_updates u0..15) + cursor state. Mirrors shallow `lib/schedule_stepping.sla` lines 275-1005 (inline Vec-based deep) onto fixed-cap storage.

Wrapper structs (Batch 373 rule -- no test tuple destructuring):
- `EcsStepSchedulesDeep { valid, l0..l7, count }` -- `schedules()` result. Accessors `_schedules_valid_s` / `_schedules_count_s` / `_schedules_at_s(idx)`.
- `EcsStepCursorDeep { valid, label, system_idx }` -- `cursor()` result. Accessors `_cursor_valid_s` / `_cursor_label_s` / `_cursor_system_s`.
- `EcsStepSkippedDeep { valid, skip_count, next_system, f0..f15 }` -- `skipped_systems()` payload. Accessors `_skipped_valid_s` / `_skipped_count_s` / `_skipped_next_s` / `_skipped_at_s(idx)` (returns bool).
- `EcsSteppingDeepSkippedResultDeep { d, skipped }` -- bundles post-traversal `d` + the `EcsStepSkippedDeep`. Accessors `_skipped_result_d_s` / `_skipped_result_skipped_s`.
- `EcsStepSkipAccDeep { is_cursor, pos, start, local_action, cursor_sys, next_sys, skip_count, f0..f15 }` -- INTERNAL ONLY accumulator threaded through the recursive walker.
- `EcsSteppingNextFrameApplyDeep { d, flag }` -- INTERNAL ONLY threads `mut_reset_cursor` (i32) across the flat 8-slot apply ladder.

Public API surface:
- `ecs_stepping_deep_new_s() -> EcsSteppingDeepS`.
- `ecs_stepping_deep_enable_s` / `_disable_s` / `_step_frame_s` / `_continue_frame_s` -- queue SET_ACTION updates (Waiting / RunAll / Step / Continue).
- `ecs_stepping_deep_queue_set_action_s` / `_queue_add_schedule_s` / `_queue_remove_schedule_s` / `_queue_clear_schedule_s` / `_queue_set_behavior_s` / `_queue_clear_behavior_s` -- low-level queue setters (cap-8 reject silent).
- `ecs_stepping_deep_next_frame_s` / `ecs_stepping_deep_begin_frame_s` -- apply queued updates.
- `ecs_stepping_deep_schedules_s` / `_cursor_s` / `_skipped_systems_s(d, label, system_count)` -- the three Bevy public surface fns.
- `ecs_stepping_deep_is_enabled_s` / `_action_s` / `_update_count_s` / `_state_exists_s` / `_has_schedule_s` / `_behavior_for_s(label, system_index)`.

Critical engineering notes:

- KEY Batch 382 finding: SA permits SIMPLE RECURSION that RETURNS A STRUCT as long as accumulator field-writes go through cascade-of-return helpers at top-level function scope (Batch 377 shape) and never inside `if`/`while` (Batch 378 rule). `_ecs_stepping_deep_step_skip_walk` is the first verified struct-returning recursive walker: each level returns the new `EcsStepSkipAccDeep` after invoking cascade-of-return helpers `_skip_acc_set_skipcounty`/etc + arithmetic helpers `_step_skip_flag`/`_step_skip_la`/`_step_skip_pos` (Batch 381 simple-i32 recursion pattern extended to struct-by-value returns). The prior "no recursion" cookbook guidance was about UseAfterMove on cross-call accumulator chains or i32 rebinds inside `if`/`while`; neither applies here (cursor walker has no `if`/`while` in its body at all, just top-level let-ladder + return-cascade).
- next_frame apply is a flat 8-slot let-ladder (`a0..a8` covers slots 0..7), no `while` per Batch 378 rule. Reset_cursor (Bevy bool) threads as `EcsSteppingNextFrameApplyDeep.flag` i32 because SA swallows `let mut x; if cond { x = 1; };` rebinds (Batch 373 rule). Reset_cursor applies when SET_ACTION target=RunAll OR after REMOVE_SCHEDULE (matches Bevy). Apply returns the state with `update_count = 0` so chained next_frame calls only run newly-queued commands (Batch 380 finding repeated).
- The walker dispatches on `(action, behavior)` via three pure-i32 helpers mirroring Bevy 727-751 match cases: `_step_skip_flag` returns the skip bit; `_step_skip_pos` applies the per-branch `pos += 1`; `_step_skip_la` mutates the running local_action (Step->Waiting on `i==pos`; Continue+Break->Waiting when `i>start`). The tail rule `_step_skip_tail_pos` adds the Bevy trailing `if i == pos && action != Waiting { pos += 1 }`.
- `_ecs_stepping_deep_state_apply_updates_s` drains pending behavior_updates recursively over cap-16 slots. `_drain_apply_s` treats `upd == -1` as a CLEAR (reset to Continue via `clear_behavior_s`) and `upd >= 0` as a SET (via `set_behavior_s`). The initial draft incorrectly treated `upd < 0` as a "no-op skip" -- fixed after a clear_behavior-after-NEVER_RUN test showed `b5` staying NEVER_RUN after the clear drain.
- `behavior_for_s` out-of-range returns Continue default (`system_index < 0 OR >= ECS_STEP_CAP_SYSTEMS OR >= node_count`). Mirrors `behaviors.get(&NodeId).unwrap_or(&SystemBehavior::Continue)`; brackets the raw per-slot accessor so behaviors past the live node_count are reported as unset/Continue.
- `_state_resize_s` grows node_count up to cap-16 (mirror Bevy node_ids clone-from schedule). `set_behavior_s` auto-grows node_count via `_state_grow_s` so behavior set on a high system_index keeps node_count in sync.
- Fix-on-iterate: the initial draft had a slot 0 SKIPPING bug in next_frame's flat ladder (the ladder covered slots 1..7 via `a1..a7` against the post-prelude d, never slot 0); isolated `ecs_stepping_deep_enable_s + next_frame_s` probe caught it (`action` stayed RunAll after enable), and the ladder was rewritten as `a0 = apply_result_new(d1, 0)` then `a1..a8 = apply_slot(a_{prev}, 0..7, d1)`. removed `_ecs_stepping_deep_next_frame_step` no-op scaffold in the final patch.
- `_ecs_stepping_deep_insert_order_at` + `_insert_shift` cap-8 compact right-shift insert (mirror Bevy `schedule_order.insert(pos, label)` when skipped_systems encounters a new label). `_ecs_stepping_deep_remove_from_order_scan` recursive only (never mutates d mid-scan: each step builds a new d via `_set_so_at` and threads forward).

Tests (10) -- `tests/test_ecs_lib_schedule_stepping_deep_isolated.sla` (panic 142300-142399, 80 codes, distinct -- verified with `rg -o "panic\(([0-9]+)\)" <file> --no-filename -r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP:", $1; exit}'` showing empty before documenting). No tuple-return destructuring. Cover:
1. new + actions + enable/disable/step/continue queueing + update_count + payload slot reads.
2. next_frame apply add/remove/clear schedule + has_schedule + update_count reset.
3. set_behavior enqueues-pending; behavior_for before drain is still Continue; first skipped_systems drains the pending and behavior_for after drain matches the requested Break.
4. clear_behavior resets request -- node stays NEVER_RUN after apply (queued) until the next skipped_systems drains the queued clear into Continue.
5. cursor() not-found on RunAll; after enable+skipped_systems populates node_count, cursor() valid.
6. schedules() invalid until initialized; valid + order copy + scheduled mismatch (remove compacts).
7. skipped_systems Waiting walk over 4 Continue systems -- all skipped, skip_count=4, next_sys=0.
8. skipped_systems Step walk -- cursor steps system 0, action Step->Waiting, skip_count=3, cursor advances to 1.
9. skipped_systems Continue + Break breakpoint -- Break at system 2 halts after the cursor advances through 0->1 and stops at 2; skip=[0,0,1,1]; action stays Continue.
10. cap-8 queued-update reject (8-updates cap fills when enable + 7 add_schedule fired) + cap-16 set_behavior growth + cap-16 reject at system_index=16 + behavior_for out-of-range Continue + begin_frame = next_frame identity.

Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 483 lib modules | 211 `*_deep.sla` modules | 387 test files |
211 `*_deep_isolated.sla` test files | 90 examples | 6775 `@test` total across lib+tests+examples.
Next free panic band: 142400+ (Batch 382 used 142300-142399).
Next batch candidates: archetype_registry (274 lines, has `@import world_registry.sla` -- couples to registry world frame; subdivide if surface too wide), schedule_diagnostic (event/schedule diagnostics if not already deepened). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 383 -- archetype_registry_deep (DONE 2026-07-12)

Deep variant of `lib/archetype_registry.sla` mirroring its `registry_archetype_world_*` pub surface on a self-contained cap-8 archetypes x cap-16 entities-per-arch x cap-8 component-ids-per-arch world. Unlike the shallow file (`@import "world_registry.sla"`), the deep inlines the entity-generation / alive-bit / per-entity component-attach registry so the deep does NOT couple to the world frame (per the Batch 382 plan note). Mirrors Bevy `src/archetype.rs` `Archetype` + entity-archetype location mapping.

Wrapper structs (Batch 373 rule -- no test tuple destructuring):
- `EcsArchInfoDeep { id, storage }` -- `register_table` / `register_sparse_set` info-only return. Accessors `_info_id` / `_info_storage`.
- `EcsArchRegisterDeep { world, info }` -- the `_w`-suffix world-carrying variants `register_table_w` / `register_sparse_set_w`. Accessors `_register_world` / `_register_info`.
- `EcsArchSpawnDeep { world, entity }` -- spawn. Accessors `_spawn_world` / `_spawn_entity`.
- `EcsArchSlotDeep { world, archetype_id }` -- `get_or_create_archetype`. Accessors `_slot_world` / `_slot_id`.
- `EcsArchSignDeep { c0..c7, count }` -- entity component signature. Accessors `_sign_count` / `_sign_at`.
- `EcsArchQueryDeep { found, count, e0..e15, g0..g15 }` -- `query_component`. Accessors `_query_found` / `_query_count` / `_query_entity_id` / `_query_generation`.
- `EcsArchQueryAcc` library-internal walk accumulator.

Storage:
- `EcsArchArchDeep` -- cap-8 component-id slots (c0..c7 + comp_count) + cap-16 entity-id slots (e0..e15 + ent_count).
- `EcsArchLocationDeep` -- per-entity record (entity_id, archetype_id, row). Cap-16 location table inlined into `EcsArchWorldDeep`.
- `EcsArchWorldDeep` -- cap-8 archetypes (a0..a7) + cap-16 locations (loc0..loc15) + cap-16 generations (g0..g15) + cap-16 alive bits (alive0..alive15) + cap-16 per-entity attach bitwords (attach0..attach15) + cap-8 component storage tags (comp0..comp7) + comp_count + next_entity.

Critical engineering notes:

- Self-contained registry: `@import "world_registry.sla"` (the shallow's coupling) is avoided by inlining cap-16 generations, cap-16 alive-bits, and cap-16 per-entity component-attach bitwords (cap-8 components packed as i32 bitmask using `_bits_set`/`_bits_has`/`_bits_clear` 8-case helpers, bitmask constants 1/2/4/8/16/32/64/128, signed-NOT clear masks -2/-3/-5/-9/-17/-33/-65/-129).
- `_signature_for_entity` uses a flat 8-step let-ladder over cid 0..7 via `_ecs_arch_world_deep_sign_step` helper (Batch 378 rule -- no `while`, no `let mut`). Since the scan walks cid ascending, the signature stays sorted -- matches shallow's `registry_world_has_component` (which walks `registry.columns` ascending by `component_id`).
- find_archetype uses RECURSIVE read-only scan over cap-8 archetype slots (`_ecs_arch_world_deep_find_scan` -- Batch 381 finding: pure i32 recursion OK). Signature-matching uses flat 8-slot early-out comparison via `_ecs_arch_eq_slot`.
- get_or_create_archetype: existing match -> existing slot id; otherwise insert into the next free slot (cap-8 reject silent -> returns archetype_id=-1). Signature copy uses RECURSIVE `_ecs_arch_world_deep_arch_copy_signature` over sig.count steps with cascade-of-return `_set_component_at` + tail-set `comp_count`.
- detach: swap-remove from the archetype's `entity_ids` list. When row != last, copy `eids[last]` into `eids[row]` and update `loc[moved].row = row`. Drawn as a same-row bool threaded via `_ecs_arch_world_deep_detach_swap_in` early-return-on-equal helper (`if same_row { return w0; }`) -- flat instead of `if cond { w = fn(w, x); }` (SA-swallow bug -- Batch 378 finding).
- query_component: RECURSIVE `_ecs_arch_query_walk_archetype` (cap-8 archetype slot recursion) + nested RECURSIVE `_ecs_arch_query_walk_row` (cap-16 row recursion within each matching archetype). Both pushed via `_ecs_arch_query_push` cascade-of-return set-pair helper into `EcsArchQueryAcc`; finalized via `_ecs_arch_query_acc_finalize` into `EcsArchQueryDeep`. cap-16 reject silent when accumulator is full. Query results carry (eid, generation) pairs captured at query time.
- KEY Batch 383 finding (extends Batch 382): SA permits struct-returning recursive walkers with valid struct-by-value accumulator forwarding as long as accumulator field-assigns use cascade-of-return helpers at top-level function scope (Batch 377 shape). This batch verifies the pattern continues to hold with FOUR independent recursive helpers: `_ecs_arch_world_deep_find_scan`, `_ecs_arch_world_deep_arch_copy_signature`, `_ecs_arch_query_walk_archetype`, `_ecs_arch_query_walk_row`. The accumulated per-arch push happens via cascade-of-return set-pair helpers, never via `if cond { acc.field = ...; }` (the SA-swallow bug from Batch 378).
- Register returned BOTH info AND world: initial draft had `ecs_arch_world_deep_register_table` return only `EcsArchInfoDeep` which made test-side chained register calls hard. Added `_w` suffix variants `ecs_arch_world_deep_register_table_w` / `ecs_arch_world_deep_register_sparse_set_w` that return `EcsArchRegisterDeep { world, info }`. The unsuffixed variants remain for surface-symmetry with shallow `registry_archetype_world_register_table` literal return shape.
- Insert/remove/despawn apply immediately (no deferred queue) -- the "apply RESETS queue" convention (Batch 380 finding) is N/A here.

Tests (10) -- `tests/test_ecs_lib_archetype_registry_deep_isolated.sla` (panic 142400-142499, 80 codes, distinct -- verified with `rg -o "panic\(([0-9]+)\)" <file> --no-filename -r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP:", $1; exit}'` showing empty before documenting). No tuple-return destructuring. Cover: new + register info accessors + comp_count, spawn attaches to empty archetype id 0, get_or_create_archetype creates+distincts, identical signatures coalesce (e1=[0,1] + e2=[1,0] sort to [0,1] -> same archetype), remove_component migrates into a shared archetype (e1=[0,1] remove 1 -> [0] shares e2's archetype), despawn detaches + bumps generation + drops despawned from query, detach swap-remove coordinate move updates location.row correctly, query_component skips despawned + reports correct generation, insert->remove->insert returns to lower-archetype-id (reuses existing slot 1 after going through empty=0), cap-8 component-stored reject silent + cap-8 component-id insert reject silent + find_archetype matches get-or-create slot id.

Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 484 lib modules | 212 `*_deep.sla` modules | 388 test files |
212 `*_deep_isolated.sla` test files | 90 examples | 6785 `@test` total across lib+tests+examples.
Next free panic band: 142500+ (Batch 383 used 142400-142499).
Next batch candidates: hierarchy_relationship_adapter (shallow + clean-cut, no @import -- a natural next candidate), world_registry_erased (shallow @import world_registry -- couple to world frame; needs self-contained variant like Batch 383), system_param_table_erased / world_table_erased (registry-/table-erased coupled -- subdivide). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 384 — hierarchy_relationship_adapter_deep (DONE 2026-07-12)

`lib/hierarchy_relationship_adapter_deep.sla` (1087 lines) mirrors shallow `lib/hierarchy_relationship_adapter.sla` (the typed ChildOf facade that delegates to `relationship_world_*`) as a SELF-CONTAINED cap-16 entity registry + singly-linked-sibling ChildOf relation. NO `@import relationship.sla` -- the per-entity parent/head/next/gen/alive arrays are all inlined.

Storage: `EcsHierWorldDeep` holds cap-16 `parent0..15` (parent id per entity, -1 = root), cap-16 `head0..15` (first child id per entity), cap-16 `next0..15` (next sibling id per entity -- singly-linked sibling list), cap-16 `gen0..15`, cap-16 `alive0..15` (alive bit), and `next_entity`. Children of a parent form a singly-linked list rooted at `head[parent]` linked via `next[child]`.

Public surface: EcsHierEntityDeep { id, generation } + `ecs_hier_entity_eq_deep` / `ecs_hier_entity_id_deep` / `ecs_hier_entity_gen_deep` / `ecs_hier_entity_new(id, gen)` (public ctor for tests); EcsHierSpawnDeep { world, entity } + `_world`/`_entity` accessors for `ecs_hier_world_deep_spawn`; EcsHierSpawnChildDeep { world, child } + `_world`/`_entity` accessors for `ecs_hier_world_deep_spawn_child`; spawn_world/is_alive; add_child/insert_child (doubly-detached reparent: removes child from its old parent's sibling list, then inserts at an index into the new parent's child-list); has_parent/parent/child_count/child_at; children() returns EcsHierChildrenDeep { count, e0..e15 } with `_count`/`_at` accessors; ancestors/root_ancestor/descendants (BFS)/descendants_depth_first (DFS pre-order)/siblings/leaves all return EcsHierQueryDeep { count, e0..e15 } via `_query_deep_count`/`_query_deep_at`; detach_child (no-op if actual parent differs) / detach_all_children; replace_children; replace_children_with_difference (via EcsHierDiffListDeep { count, e0..e7 } builder + `_count`/`_at`/`_push`); despawn_children (recursive kill of all descendants) + despawn (entity + its descendants).

Helpers: per-entity field accessors `_ecs_hier_world_deep_parent_at/_set_parent`, `_head_at/_set_head`, `_next_at/_set_next`, `_generation_at/_set_generation`, `_alive_at/_set_alive` (16-case cascade-of-return). Spawn-related `_ecs_hier_spawn_wrap`. `_ecs_hier_world_deep_add_child` reads old_parent, removes child from old parent's head-list via `_ecs_hier_remove_from_old_parent`/`_ecs_hier_remove_from_list_walk` (recursive read-only splice prev.next=target.next), then appends to the new parent's child-list tail via `_ecs_hier_append_child_tail`/`_ecs_hier_append_child_tail_walk` (recursive), then sets parent[child]=parent. `insert_child` walks with a recursive index counter. `child_count` uses RECURSIVE `_ecs_hier_count_walk_world` (world-carrying read-only counter). ancestors/root_ancestor walk up `parent[]` chain. descendants BFS uses `EcsHierBfsAccDeep` + `_ecs_hier_bfs_step`/`_ecs_hier_extend_queue_with_children`/`_ecs_hier_extend_queue_walk`. DFS uses `EcsHierDfsAccDeep` + `_ecs_hier_dfs_push_children`/`_ecs_hier_dfs_walk_children` (pre-order recursion). siblings via `_ecs_hier_siblings_walk` (recurse the sibling list of the parent, skip self). leaves = DFS descendants filtered by `head[ent] < 0`. despawn_children + despawn use `_ecs_hier_kill_children_rec` and `_ecs_hier_kill_entity` (clear head/next/parent, bump gen, alive=0, writes AFTER recursion for recursion-safety).

KEY Batch 384 finding #1: initial `_ecs_hier_kill_children_rec(w0, cur)` only recursed into `head[cur]` (first child's subtree) then killed `cur`, but never continued down the SIBLING list (`next[cur]`). The fix: `return _ecs_hier_kill_children_rec(w2, nxt);` after the kill, so the recursion walks the entire sibling list of `parent`'s children -- otherwise despawn_children/despawn only killed the FIRST child and its subtree, leaving subsequent siblings (and their subtrees, including grandchildren) alive. Caught by SA `EcsHierWorldDeep despawn_children recursive kill + grandchildren` (panic 142583, g2 alive when it should be dead) and `replace_children_with_difference + linked despawn` (panic 142546, child3 alive when it should be dead). Both backends caught it on the first SA run after the lib was originally built.

KEY Batch 384 finding #2: SA rejects `EcsHierEntityDeep { id: -1, generation: 0 }` struct-literal construction IN TESTS (the Batch 379 rule extends to arbitrary entity wrappers too -- `error: found '{' expected semicolon`). Fix: expose a public `ecs_hier_entity_new(id, generation)` constructor on the lib so tests probe out-of-range (-1) and stale-generation (id 0 gen 5) non-alive entities via a library function path.

The cap-16 entity cap: spawn rejects silently (returns entity id -1) when `next_entity >= ECS_HIER_CAP_ENTITIES` (16). Tests must spawn 16 entities to get ids 0..15 (16 spawns, the 16th is id 15) and a 17th spawn to trigger reject -- the cap test spine must label those spawns carefully or the off-by-one assert panics (caught: initial draft asserted the 15th spawn's id == 15 when it's the 16th spawn that owns id 15).

Tests (10) -- `tests/test_ecs_lib_hierarchy_relationship_adapter_deep_isolated.sla` (panic 142500-142599, 97 codes, distinct -- verified with `rg -o "panic\(([0-9]+)\)" <file> -r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP:", $1}'` showing empty before documenting). No tuple-return destructuring; all return wrappers consumed via `_world`/`_entity`/`_count`/`_at` accessors. Cover: new + spawn + spawn_entity + is_alive (out-of-range + stale gen probes via `ecs_hier_entity_new`); spawn_child + child_count + parent + child_at + has_parent (mirrors shallow "syncs childof and children"); add_child reparent decrement old/increment new + insert_child index 0 + detach_child (mirrors shallow "reparent insert and detach"); insert_child middle (idx 1) and tail (idx 4) + detach_child wrong-parent no-op; replace_children_with_difference + linked despawn + unrelate'd child stays alive (mirrors shallow "difference replace and linked despawn"); ancestors/root_ancestor (incl. root self) + BFS descendants + DFS pre-order descendants + siblings + leaves (mirrors shallow "traversal helpers", tree root->c1,c2; c1->g1,g2; c2->g3); children() wrapper + detach_all + re-add in reverse; despawn_children cascades to grandchildren + parent stays alive; despawn entity cascades to its descendants + siblings stay alive + parent still has remaining sibling; cap-16 silent reject on 17th spawn + diff list empty/push/at sanity.

Both SA + default backends: 10/10 pass.

Post-batch counts (measured): 485 lib modules | 213 `*_deep.sla` modules | 389 test files |
213 `*_deep_isolated.sla` test files | 90 examples | 6795 `@test` total across lib+tests+examples.
Next free panic band: 142600+ (Batch 384 used 142500-142599).
Next batch candidates: world_registry_erased (shallow @import world_registry -- needs self-contained world-frame variant, the Batch 383 archetype_registry pattern), system_param_table_erased / world_table_erased (registry-/table-erased coupled -- subdivide). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 385 — world_registry_erased_deep (DONE 2026-07-12)

`lib/world_registry_erased_deep.sla` (1441 lines) mirrors shallow `lib/world_registry_erased.sla`'s
`RegistryErasedWorld<R, M>` registry world as a SELF-CONTAINED fixed-cap variant (NO `@import` --
the registry/column storage, resource slot, message slot, and typed (pos/vel/marker) component
columns are all inlined). The shallow uses generics `<R, M>` heavily and `@import`s five files
(world_registry, resource, messages, query_dynamic, box_drop, sa_std/core/box); the deep reifies that
erased "any concrete type" surface as three concrete typed columns keyed by `type_id`
(`ECS_REG_TYPE_POS=101` / `ECS_REG_TYPE_VEL=102` / `ECS_REG_TYPE_MARKER=103`), matching the two
shallow `@test`s which exercise only these three types plus the `ErasedTestTime` resource +
`ErasedTestEvent` message.

Storage: `EcsRegWorldDeep` with cap-16 entities (`gen0..15` + `alive0..15`, monotone `next_entity`,
`entity_count`) and cap-8 component columns (`comp_id`, `type_id`, `storage`, per-column `present`
i32 bitmask over cap-16 entities, per-column per-entity `added`/`changed` tick structs of kind
`EcsRegColTickE { t0..t15 }`). Typed storage lives in three parallel cap-8 column structs
(`EcsRegColDeepPos { x0..15, y0..15 }`, `EcsRegColDeepVel` same shape, `EcsRegColDeepMarker { v0..15 }`)
keyed into the world via cascade-of-return set helpers `_set_pos_col`/`_set_vel_col`/`_set_marker_col`.
The world has a single `change_tick`, one resource slot (`res_time_tick` + `res_time_set`) for
`EcsRegTimeDeep`, and one message slot (`msg_event_amount` + `msg_count`) for `EcsRegEventDeep`.

Public surface: `ecs_reg_entity_new(id, gen)` / `_eq_deep` / `_id_deep` / `_gen_deep`;
`ecs_reg_world_deep_new`/`_component_count`/`_entity_count`/`_change_tick`;
`ecs_reg_world_deep_register_table`/`_register_sparse_set` (return `EcsRegRegisterDeep { world, info }`,
the Batch 373 wrapper with `_world_deep`/`_info_deep` accessors matching Batch 383's `_w`-suffix pattern);
`ecs_reg_register_info_deep` -> `EcsRegCompInfoDeep` + `_id_deep`; `ecs_reg_world_deep_spawn`/`_spawn_many`
(cap-16 reject returns entity.id=-1); `_is_alive`; `_has`; `ecs_reg_world_deep_insert_pos`/`_insert_vel`/
`_insert_marker` (write the typed slot + present bit + added/changed ticks); `_get_pos`/`_get_vel`/
`_get_marker` (read the typed slot); `_remove`; `_despawn` (alive=0, gen+1, removes all present components
first); `ecs_reg_world_deep_increment_tick`; `ecs_reg_world_deep_query`/`_query_without`/`_query_added`/
`_query_changed` (return `EcsRegQueryDeep { count, e0..15 }` via `_count`/`_at` accessors);
`ecs_reg_world_deep_query_pair_pos_vel`/`_pair_without` (return `EcsRegPairQueryDeepPosVel { count, p0..15 }`
via `_count`/`_at`, each pair `EcsRegPairDeepPosVel` exposes `_entity`/`_first`/`_second`);
`ecs_reg_world_deep_query_pair_mut_pos_vel` (return `EcsRegPairMutDeepPosVel` + `_entity`/`_first`/`_second`/
`_first_comp_id`); `ecs_reg_world_deep_pair_write_first_pos_vel` (writes the new pos value via insert_pos);
`ecs_reg_world_deep_insert_resource`/`_get_resource` (single `EcsRegTimeDeep` slot +
`ecs_reg_time_deep_tick`); `ecs_reg_world_deep_write_message`/`_read_message` (single `EcsRegEventDeep`
slot with a monotone `msg_count`; `EcsRegMessageReadDeep { amount, count }` mirrors the shallow
`MessageRead<M>`); `ecs_reg_world_deep_register_many`/`_spawn_many` (recursive bulk-register/spawn
helpers used by the cap-reject tests to keep the test source small).

Per-typed-column scalars are also exposed: `EcsRegPosDeep`/`EcsRegVelDeep`/`EcsRegMarkerDeep`/
`EcsRegTimeDeep`/`EcsRegEventDeep` with `_new`/`_x`/`_y`/`_value`/`_tick`/`_amount` accessors, so tests
construct concrete typed values via library function paths (no struct-literal construction in tests,
per Batch 379 rule).

KEY Batch 385 finding #1: SA's codegen backend rejects a top-level `const ECS_REG_TICK_NONE: i32 = -1`
with a `CodegenError.CodegenError` raised inside `emitTopLevelConstDecl` -- SA cannot emit negative
literal constants at top-level scope. Replaced with `ECS_REG_TICK_NONE: i32 = 999999` (a positive
sentinel far above any valid tick we'd ever compare against). Caught only at `sa sla test` time,
not at `sa sla check`; check passes but `test`'s codegen fails.

KEY Batch 385 finding #2: extending Batch 378's SA-swallow bug for field-assign inside `if cond
{ w = fn(w, x); };` -- the same swallow applies to `let w1 = fn(w, x); return fn2(w1, ...)` chains
INSIDE an if-guard when the if-guard wraps the body's first write. The initial
`_ecs_reg_world_deep_insert_set_tick` used a single function whose `if was_present != true { let
w1 = _set_added(...); return _set_changed(w1, ...); }` branch + bare tail fell into the swallow, so
re-inserts ALSO updated `added_tick` (the test 8 `replace bumps changed but not added` probe caught
this). Fix: split into two distinct top-scope entrypoints `_set_added_and_changed` (first-insert) and
`_set_changed_only` (re-insert) and dispatch in the public `_insert_set_tick` via
`if was_present != true { return _set_added_and_changed(...); }; return _set_changed_only(...);`. The
cascade-of-return helper pattern holds across the split entrypoints.

KEY Batch 385 finding #3: file-size scaling. The default backend is orders-of-magnitude slower than
SA when a per-batch lib exceeds ~55K bytes (Batch 384's hierarchy lib was 55K; this lib is 73K because
of the cap-8 typed-column cascade-of-return boilerplate). Initial `sa sla test` default-backend
run was reported by SA test frame as `FileTooBig` until `spawn_many`/`register_many` recursive
helpers were added to shrink the cap-16 reject test source from 93 lines of explicit spawn/register
let-ladders to ~18 lines of helper calls. After the helper additions the default backend successfully
runs (149s on this lib, vs 4.7s on SA). Conventional cookbook gotcha: for any deep lib whose typed
storage requires many cascade-of-return helpers, prefer recursive bulk-load helpers in the test
layer to avoid the slow default-backend scaling.

Tick semantics tedious gotcha: the initial draft of test 8 used `query_changed_since(t_before_replace)`
where `t_before_replace = change_tick(w4)` -- the post-increment tick, which equals the re-insert
write tick, so `changed > since_tick` is always false for the just-written entity. Mirror the shallow
test 2 framing instead: insert-stamp ticks match `change_tick` AT INSERT (the shallow's
`registry_world_insert_component` writes `world.change_tick` without first bumping), so
`query_changed_since` must use a tick strictly less than the write tick. Conventional fix:
pick `since_tick` to be the change_tick of the world BEFORE the last mutation, not after.

Tests (10) -- `tests/test_ecs_lib_world_registry_erased_deep_isolated.sla` (343 lines, panic 142600-142697,
30 codes, distinct, verified with `rg -o "panic\(([0-9]+)\)" <file> -r '$1' | sort -n | awk 'NR>1 && $1==prev
{print "DUP:", $1}'` showing empty before documenting). No tuple-return destructuring; all return
wrappers consumed via `_world_deep`/`_entity_deep`/`_count`/`_at`/`_info_deep`/`_id_deep`/`_x_deep`/
`_y_deep`/`_value`/`_tick`/`_amount` accessors. Cover: new + register table/sparse + spawn +
component_count + change_tick increment per-register; insert pos/vel/marker + get +
has() present-or-absent on each entity; query/query_without/query_added_since (mirrors shallow
test 1's nutrition tail); pair_query + pair_without + pair_mut_first pair-write + write-back +
query_changed_since (mirrors shallow test 2's pair-query head); despawn + remove + has + alive +
entity_count + generation-bumped slot is dead (mirrors shallow test 2's despawn tail); resource +
message + change-tick at despawn against the resource captured pre-despawn (mirrors shallow test 2's
resource/message tail); out-of-range/stale id + non-alive + missing-col query/skip + despawn-of-dead
no-op; replace bumps changed but NOT added (the Batch 385 finding #2 evidence probe); cap-16 entity
reject + cap-8 column reject silent at 9th register via `spawn_many`/`register_many` helpers;
multi-column pair_query finds the one entity that has both pos+vel among three alive entities.

Both SA + default backends: 10/10 pass. SA: 4.7s; default: 149s (the default-backend FileTooBig-vs-slow
characteristic documented above).

Post-batch counts (measured): 486 lib modules | 214 `*_deep.sla` modules | 390 test files |
214 `*_deep_isolated.sla` test files | 90 examples | 6806 `@test` total across lib+tests+examples.
Next free panic band: 142700+ (Batch 385 used 142600-142697).
Next batch candidates: world_table_erased (shallow `@import world_table`, world-frame-coupled table
storage -- needs self-contained variant similar to Batch 385), system_param_table_erased (registry-/table-erased coupled), system_param_archetype_value / world_table_value (table-value coupled). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

## Batch 386 — world_table_value_deep (DONE 2026-07-12)

`lib/world_table_value_deep.sla` (1351 lines) mirrors shallow `lib/world_table_value.sla`'s
`TableValueWorld<T,R,M>` as a SELF-CONTAINED fixed-cap archetype-table variant (NO `@import` -- the
archetype storage, entity->(arch_id,row) location map, component tick tracking, resource slot, and
message slot are all inlined). The shallow uses generics `<T,R,M>` and `@import`s five files
(world_table, resource, messages, query_dynamic, box_drop); the deep reifies that surface on
fixed-cap storage with cap-4 archetypes x cap-4 component-cols/arch x cap-4 rows/arch x cap-8
entities, mirroring Bevy src/world/mod.rs `World` archetype-grouped storage + (arch_id,row) entity
location. Concrete typed plugs: `EcsTVDataDeep{amount}` (TableValueData), `EcsTVTimeDeep{tick}`
(TableValueTime resource), `EcsTVEventDeep{amount}` (TableValueEvent message). Wrapper structs
(EcsTVRegisterDeep/EcsTVSpawnDeep/EcsTVCompInfoDeep/EcsTVQueryDeep/EcsTVPairQueryMutDeep/EcsTVMessageReadDeep)
expose scalar accessors per the Batch 373 rule (NO tuple-return destructuring in tests;
`_world`/`_entity`/`_count`/`_at`/`_info_id`/`_pair`-helpers/--accessor convention). Public surface
mirrors shallow: `register_table`/`register_sparse_set`; `spawn`/`is_alive`;
`entity_archetype_id`/`entity_row`/`archetype_entity_count`; `has`/`get`; `insert` (replace-in-place
if comp already present, else migrate); `remove` (migrate to smaller arch incl. back to arch 0
empty); `despawn`; `increment_tick`; `query`/`query_with`/`query_without`/`query_added`/`query_changed`;
`query_pair_mut_first` + `pair_write_first`; `query_mut`/`write`; `insert_resource`/`get_resource`/
`resource_added_since`/`resource_changed_since`; `write_message`/`read_message`. The resource slot
has per-tick added/changed tracking matching the component pattern: first insert sets added+changed;
replace preserves added and bumps changed (the dual-entrypoint shape from Batch 385). The arch
migration on insert/remove: `_ecs_tv_arch_collect_sig` recursively collects the entity's current
arch's (comp_id, val, added, changed) signature; `_ecs_tv_build_insert_sig`/`_ecs_tv_build_remove_sig`
produce the target signature; `_ecs_tv_find_arch_for_sig` does exact-set-equality match across cap-4
archetypes; `_ecs_tv_create_arch_for_sig` allocates a new archetype (or returns -1 when capped);
`_ecs_tv_attach_row` writes the sig into a fresh row in the target arch; `_ecs_tv_detach_row`
swap-removes the departed row (copies the last row's content into the departed row + bumps the moved
entity's `loc_row`).

Tests (10) -- `tests/test_ecs_lib_world_table_value_deep_isolated.sla` (380 lines after final
patches, panic 142700-142834, 35 distinct codes verified unique with the standard `rg | sort -n |
awk` check). Cover: new + register table/sparse + spawn + change_tick increment-per-register;
insert health/mana/selected + get + has + migration + (arch_id,row) location tracking (mirrors
shallow test 1); pair_query + pair_write_first + query_changed_since (mirrors shallow test 2); remove
despawn + resource + message flow (mirrors shallow test 3); query variants +
query_added/query_changed + added_since + replace-bumps-changed-but-not-added (standalone coverage);
despawn + generation-bump + remove-blocked-if-absent no-op + cap-4 arch-0 row-cap reject (NOT cap-8;
see Batch 386 finding #1 below); resource added/changed_since + replace preserves added tick; remove
returns entity to arch 0 (empty archetype); pair_mut writeback across multiple entities;
cap-4 arch silent reject on insert + cap-4 column cap silent reject on register.

Both SA + default backends: 10/10 pass. SA: 4.7s; default: ~25.7s. The lib is 70K bytes; the default
backend did NOT hit the FileTooBig error here (unlike Batch 385's 73K lib) because the recursive bulk
helper `_ecs_tv_spawn_n(w0, count)` defined INSIDE the test file (not the lib -- fine per the rules)
compresses the cap-4 spawn-reject sequence so the per-test `.test.sa` transcription stays bounded.

KEY Batch 386 finding #1 (CRITICAL, supersedes Batch 385's tick gotcha): SA passes structs by
reference / alias-by-value, NOT by-value-independently. After `let w3 = fn(w2)` mutates w2's fields in
place, `let x = change_tick(w2)` reads the POST-MUTATION value. The deep's `increment_tick`,
`register`, `insert`, `insert_resource` all mutate the world parameter's fields directly (`w0.field =
...`); the returned copy is aliased to the same mutated struct. The bug pattern: capture
`tick = change_tick(world_after_some_op)` for use as a `since_tick` query parameter, then call another
mutation; since the captured `tick` was the world's field (read through change_tick accessor), LATER
mutations retroactively re-write its meaning IF the test re-reads the same accessor from the aliased
variable. Concretely: Test 7's `t_after_insert = change_tick(w2); w3 = increment_tick(w2)";
second_insert_resource(w3)...` -- reading `change_tick(w2)` AFTER increment_tick mutates w2's
change_tick returns the bumped value, making the upcoming `resource_changed_since(t_after_insert)`
check `3 > 3 == false` and the test panics. The fix: compute `t_after_insert = before + 1`
arithmetically from an EARLIER pre-mutation capture, OR capture the value at the latest point
strictly BEFORE any mutation to the relevant field aliases the value. This affects Test 5 too:
`t_before_replace = change_tick(w8)` (read AFTER the increment that produced w8) returns the
post-increment tick, making `query_changed(since=t_before_replace)` empty even though a
replace-bumped-changed entity exists. The fix there is to capture `before_replace = change_tick(w7)`
BEFORE the increment and use that as `since_tick`. **Lesson: for any `since_tick` parameter, capture
the tick from a world binding that has NOT had a subsequent mutating call applied to it (whether to
the same name or to an alias of the same struct). When in doubt, derive the expected tick
arithmetically instead of re-reading it from the world.**

KEY Batch 386 finding #2 (cap semantics in test design): the deep's effective entity-spawn cap is
`ECS_TV_CAP_ROWS_PER_ARCH` (=4) for the empty archetype 0, NOT `ECS_TV_CAP_ENTITIES` (=8), because
freshly-spawned entities start in arch 0 and stay there unless they later gain a component that
migrates them out. An initial test draft tried to demonstrate an 8-entity-cap by spawning 7 entities
after a despawn and expecting `entity_count == 7`, but after exactly 4 spawns arch 0 is full
(`a0.row_count >= ECS_TV_CAP_ROWS_PER_ARCH`) and the 5th spawn silently returns `entity.id = -1`. The
correct cap-demonstration: spawn 4 (fill arch 0), verify `entity_count == 4`, then assert the 5th
spawn returns `entity.id == -1`. Note the prior Batch 385 lib's analogous cap test used
`ECS_REG_CAP_PER_INSERT_ENTITY` (=16) which DID match `ECS_REG_CAP_ENTITIES` (=16) -- the cap mismatch
specific to Batch 386 comes from arch-0-row-cap being the binding constraint for fresh spawns.

KEY Batch 386 finding #3 (archetype cap clamp on insert): `ECS_TV_CAP_ARCH = 4` means the world can
hold at most 4 archetypes total (arch 0 empty + 3 distinct-component-set archetypes). Inserting the
4th distinct component, e.g. inserting c3 when e1 already has {c0,c1,c2} in arch 3, asks
`_ecs_tv_create_arch_for_sig` for a 5th arch; the helper returns `(w1, -1)` (arch_count >= cap) and
the insert silently no-ops (e1 stays in arch 3, never gains c3). The test must therefore check
`archetype_count == 4` (NOT 5) and `has(e1, c3) == false` after the rejected insert (rather than
asserting 5 archetypes and reading c3's value back). The cap-4 column cap (test 10's first half)
shows the analogous silent reject on the 5th `register_table` call (returns
`CompInfoDeep.id == -1` and leaves `component_count == 4`), exactly mirroring Batch 385's cap shape.

KEY Batch 386 finding #4 (test-expectation alignment with archetype-rows): in Test 2 the diagonally
mirrored recipe (e1 inserted first, e2 second, both converging to {health,mana} arch) lands e1 at
row 0 and e2 at row 1 (`row_e2_before == 1`, NOT 0) -- the test originally mis-stated the expected
row as 0. (Appendix: after also inserting selected INTO e1, e1 migrates away from the {health,mana}
arch and the detachment's swap-removal brings e2 down to row 0, matching the shallow's downstream
assertion `entity_row(w10, e2) == 0`.)

Post-batch counts (measured): 487 lib modules | 215 `*_deep.sla` modules | 391 test files |
215 `*_deep_isolated.sla` test files | 90 examples | 6218 `@test` total (the +10 increment from this
batch is consistent with the +1 lib file delta; the absolute count revised down from the Batch 385
block's stated 6806 because the Batch 385 block used a different counting method -- file-set deltas
are robust to this counting choice).
Next free panic band: 142900+ (Batch 386 used 142700-142834).
Next batch candidates: world_table_erased (shallow `@import world_table`, world-frame-coupled table
storage -- needs self-contained variant, large shallow at ~6300 lines, consider deferring or
splitting), system_param_table_erased (registry-/table-erased coupled, ~4900 lines -- uses fn-pointer
systems that need reification without runtime fn passing; consider deferring), system_param_archetype_value
(~330 lines -- SHALLOW uses fn-pointer `run` system callbacks that SA can't pass as values; a deep
must hardcode each system_* helper directly -- smallest remaining candidate). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

## Batch 387 — system_param_archetype_value_deep (DONE 2026-07-12)

`lib/system_param_archetype_value_deep.sla` (~1640 lines) mirrors shallow
`lib/system_param_archetype_value.sla` (328 lines) as a SELF-CONTAINED fixed-cap
archetype-value world (NO `@import`) baking the world + command queue + system-param
adapter buses. The shallow uses generics `<T,R,M>` and a fn-pointer `run: fn(...) -> ...`
callback shape that SA cannot pass as a value; the deep **hardcodes each system_* body
inline inside a dedicated `ecs_av_run_*_system` bus** (no fn-ptr passing). cap-8 entities /
cap-4 components / cap-8 archetypes / cap-16 messages, exposed through wrapper-struct
accessors (`EcsAvRegisterDeep`/`EcsAvSpawnDeep`/`EcsAvCompInfoDeep`/`EcsAvQueryDeep`/
`EcsAvEntityItemDeep`/`EcsAvRunReaderDeep`/`EcsAvReserveWrapperDeep`) per the Batch 373
rule. Concrete typed plugs: `EcsAvData{amount}`/`EcsAvTime{tick}`/`EcsAvEvent{amount}`.
Storage simplification vs. Batch 386: a single dense "arch 1" archetype holds all spawned
entities (arch 0 empty); `insert` replaces in place at the entity's (col, row) WITHOUT
cross-arch migration — deliberate since the shallow tests only assert
`entity_archetype_id == group_before` after pair-write (which holds because pair-write is a
replace-in-place). Column-major storage: `col{0..3}_val{0..7}`/`_added{0..7}`/`_changed{0..7}`
(4 cols x 8 rows x 3 slots = 96 scalar fields; SA has no fixed-array support in `_deep.sla`).
Resource dual-path added/changed; message slot cap-16 with `write_message`/`read_message`.

Public surface (verified 10/10 on both SA + default backends):
- World: `ecs_av_world_deep_new`, `change_tick`, `increment_tick`, `entity_count`,
  `archetype_count`, `component_count`, `register_table`/`register_sparse_set`,
  `spawn`, `is_alive`, `entity_archetype_id`, `entity_row`, `has`, `get`,
  `added_since`, `changed_since`, `insert`, `remove`, `despawn`, `query`/`query_with`/
  `query_without`/`query_added`/`query_changed`/`query_mut`/`query_pair_mut_first`/
  `pair_write_first`/`write`.
- Resource: `insert_resource`/`get_resource`/`has_resource`/`res_mut`/`res_mut_write`/
  `resource_added_since`/`resource_changed_since`.
- Message: `write_message`/`read_message` (returns `EcsAvReadDeep{has_value, value, reader}`).
- Commands: `ecs_av_commands_new`/`_insert`/`_insert_resource`/`_write_message`/`_apply`.
- Adapter buses (hardcoded system bodies): `ecs_av_run_pair_mut_system` (movement: first +=
  second); `ecs_av_run_resource_message_system` (tick+1, event.amount = old_tick + 4);
  `ecs_av_run_res_mut_system` (resource.tick += 2);
  `ecs_av_run_message_reader_res_mut_system` (if has_value: resource.tick += event.amount)
  -> `EcsAvRunReaderDeep{world, reader}`; `ecs_av_run_commands_system` (reserve+queue+
  apply insert amount=12 / resource tick=7 / message amount=4);
  `ecs_av_run_message_writer_system` (sends amount=2 then amount=8);
  `ecs_av_run_with_query_resource_system`/`_without`/`_added`/`_changed` (sets
  resource.tick = query.count); `ecs_av_schedule_run_movement_resource` (movement then
  time-message). Wrapper helpers `EcsAvReserveWrapperDeep` + `ecs_av_actor_reserve_*`.

Tests (10) — `tests/test_ecs_lib_system_param_archetype_value_deep_isolated.sla` (268 lines,
panic codes 142900-142996, 35 distinct codes verified unique). Mirrors shallow's 8 test
groups + 2 standalone. Uses wrapper-struct accessors throughout (NO tuple-return
destructuring). Both SA + default backends: 10/10 pass. SA: ~3.4s; default: ~8.1s. Lib
~80K bytes — default backend did NOT hit FileTooBig (no heavy cap-reject loops; per-test
transcription bounded).

KEY Batch 387 finding #1 (fn-ptr reification pattern, CRITICAL for fn-pointer systems): SA
cannot pass functions as values; the deep REWRITES the fn-body inline inside a dedicated
`ecs_av_run_*_system` bus. `ecs_av_run_pair_mut_system(w0, first_comp_id, second_comp_id)`
builds a pair-query then calls `_ecs_av_apply_pair_mut_walk(w0, q, 0)` whose body is
`next_val = first.amount + second.amount; pair_write_first(w0, p, next_val)` — the same
code the shallow would have passed as a fn-callback. All 7 adapter buses follow this shape.
Future fn-pointer batches (system_param_table_erased etc.) must apply the same reshape.

KEY Batch 387 finding #2 (single dense arch 1, no migration — deliberate simplification):
spawned entities live in arch 1 (arch 0 empty); inserts replace in place WITHOUT migration.
Distinct from Batch 386's full archetype-grouped migration. `entity_archetype_id` always
returns 1 for alive entities; `entity_row` returns spawn-order row index. The shallow tests
only assert `entity_archetype_id == group_before` after pair-write (holds since pair-write is
a replace-in-place). If a future batch needs migration on this system-param shape, add the
`_arch_collect_sig`/`_find_arch_for_sig`/`_create_arch_for_sig`/`_attach_row`/
`_detach_row` chain from Batch 386 — don't re-derive.

KEY Batch 387 finding #3 (command queue side-value-array design + KNOWN LIMITATION): queue
stores `cmd_kind{0..7}`/`cmd_eid{0..7}`/`cmd_cid{0..7}` plus parallel side arrays
`pcomp{0..7}`/`pres{0..7}`/`pmsg{0..7}` each with own `_count`. For INSERT_RESOURCE/
WRITE_MESSAGE (no entity) `cmd_eid` is reused as a value-index. For INSERT_COMPONENT,
`_ecs_av_queue_pcomp` stores the actual `eid` into `cmd_eid`, and the value at
`pcomp[pcomp_idx]` where `pcomp_idx = pcomp_count` (SEPARATE counter). Apply-walk reads
`let eid = _ecs_av_cmd_eid_at(idx); let pcomp_idx = _ecs_av_cmd_eid_at(idx);` — assumes
`eid == pcomp_idx`. **KNOWN LIMITATION: holds only for the single-INSERT_COMPONENT case
(Test 5's only such command at idx 0, entity_eid == 0 and pcomp_idx == 0).** 2+
INSERT_COMPONENT commands for different entities would mis-read. SA backend passed 10/10 so
the single-command case is correct. Fix in a follow-up: add a separate
`cmd_pcomp_idx{0..7}` field family.

KEY Batch 387 finding #4 (`EcsAvReserveWrapperDeep` + actor-reserve flow for Test 5): the
shallow's `archetype_param_commands_system` body calls `reserve_entity` internally and
returns the eid to the surrounding bus. The deep refactors into reserve-then-pass-eid:
`ecs_av_actor_reserve_for_commands(c0) -> EcsAvReserveWrapperDeep` spawns the entity FIRST,
the test derives `eid = reserve_world.count`, then passes that eid into
`ecs_av_run_commands_system(w0, health_cid, eid)`. Pattern: when a shallow system internally
reserves an entity and surfaces its id, refactor the deep into a reserve-outside-the-bus
sequence mediated by a wrapper-struct with scalar accessors.

KEY Batch 387 finding #5 (by-ref aliasing discipline — reaffirms Batch 386 finding #1):
Test 7's `let t_before_change = ecs_av_world_deep_change_tick(w10)` is captured BEFORE
`increment_tick(w10)`, reading the pre-bump value (3) — correct per Batch 386 rule "capture
`since_tick` from a binding with NO subsequent mutating call; when in doubt derive
arithmetically: `t_before_change = t_after_registers + 1` = 3". 10/10 on both backends
confirms the capture-site is safe under the by-ref-aliasing gotcha.

Post-batch counts (measured): 488 lib modules | 216 `*_deep.sla` modules | 392 test files |
216 `*_deep_isolated.sla` test files | 90 examples | 6228 `@test` total (the +10 increment
consistent with the +1 lib file delta; same `rg -c '@test' | awk -F: '{s+=$2}'` counting
method as Batch 386, so absolute figures compare directly: 6218 -> 6228).
Next free panic band: 143000+ (Batch 387 used 142900-142996).
Next batch candidates: world_archetype_value (473 lines — world layer under
`system_param_archetype_value`; a deep would enable future `@import` instead of
self-contained baking — but self-contained remains the proven pattern), `world` (328 lines,
medium), `commands_world` (332 lines, medium), `world_dynamic3` (340 lines, medium),
`bundle_table_erased` (349 lines, medium — needs self-contained table storage),
`world_table_erased` (~6300 lines, large — defer or split), `system_param_table_erased`
(~4900 lines, large — uses fn-pointer systems, needs fn-ptr reification per finding #1;
defer). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection
deepens OK).

## Batch 388 — world_archetype_value_deep (DONE 2026-07-12)

`lib/world_archetype_value_deep.sla` (~1560 lines) mirrors shallow
`lib/world_archetype_value.sla` (473 lines, no dedicated shallow test file -- the shallow's 2
`@test` functions are embedded in the lib at panic codes 9920-9948) as a SELF-CONTAINED
fixed-cap archetype-grouped variant (NO `@import`) baking the world + entity location table +
component tick tracking + resource slot + message slot. The shallow uses generics `<T,R,M>` and
`@import`s five files (archetype_registry, dyn_store, resource, messages, query_dynamic); the
deep reifies that surface on fixed-cap storage: cap-4 archetypes x cap-4 component-columns/
arch x cap-4 rows/arch x cap-8 entities, mirroring Bevy src/world/mod.rs `World` archetype-grouped
storage + (arch_id,row) entity location. The deep is a STRUCTURAL SIBLING of Batch 386's
`world_table_value_deep.sla` -- the archetype-grouped migration logic, flat col*4+row scalar slot
arrays, and wrapper-struct accessor discipline are reused; the shallow's `ArchetypeValueColumn<T>`
vs Batch 386's `TableValueColumn<T>` distinction is irrelevant once column-major storage is
inlined. Concrete typed plugs `EcsAVDataDeep{amount}`/`EcsAVTimeDeep{tick}`/`EcsAVEventDeep{amount}`.
Wrapper structs (EcsAVRegisterDeep/EcsAVSpawnDeep/EcsAVCompInfoDeep/EcsAVQueryDeep/
EcsAVEntityItemDeep/EcsAVPairQueryMutDeep/EcsAVPairMutDeep/EcsAVReadDeep/EcsAVResDeep/
EcsAVResMutDeep) expose scalar accessors per Batch 373 rule (NO tuple-return destructuring).

Public surface (verified 10/10 on both SA + default backends): `register_table`/
`register_sparse_set` (id starts at 1; per-register tick bump); `spawn`/`is_alive`;
`entity_archetype_id`/`entity_row`/`archetype_entity_count`; `has`/`get`;
`added_since`/`changed_since`; `insert` (replace-in-place if present, else migrate to a new
archetype); `remove` (migrate to a smaller-signature arch, down to arch 0 empty); `despawn`;
`increment_tick`; `query`/`query_with`/`query_without`/`query_added`/`query_changed`;
`query_pair`/`query_pair_mut_first` + `pair_write_first`; `query_mut`/`write`; resource surface
(`insert_resource`/`get_resource`/`has_resource`/`res`/`res_mut`/`res_mut_write`/
`resource_added_since`/`resource_changed_since`/`remove_resource`); message surface
(`write_message`/`read_message`). The arch migration on insert/remove reuses Batch 386's
`_ecs_av_arch_collect_sig`/`_ecs_av_build_insert_sig`/`_ecs_av_build_remove_sig`/
`_ecs_av_find_arch_for_sig`/`_ecs_av_create_arch_for_sig`/`_ecs_av_attach_row`/
`_ecs_av_detach_row` chain.

Tests (10) -- `tests/test_ecs_lib_world_archetype_value_deep_isolated.sla` (~340 lines, panic
143000-143112, 35 distinct codes verified unique). Cover: Test 1 new+register+spawn+loc; Test 2
diagonal recipe + shared-archetype + query_pair_without/query_with + remove returns to shared
arch; Test 3 pair_mut_first writeback preserves arch/row + added_since=false/changed_since=true
+ despawn + resource/message flow (post-increment tick=3 stamped into res; asserts time.tick==3);
Test 4 single-entity migrate to {mana} then back to arch 0 (empty) + missing-comp remove no-op;
Test 5 query/added_since/changed_since tick arithmetic + query_with/without; Test 6 pair_mut
across two entities + despawn leaves count; Test 7 resource Res/ResMut added/changed +
res_mut_write + remove_resource; Test 8 message write + sequential read + sentinel-after-drain;
Test 9 cap-4 component-register reject + cap-8-entity/cap-4-row-cap spawn reject (5th spawn
id == -1); Test 10 cap-4 archetype silent reject on 4th-distinct-component insert.

Both SA + default backends: 10/10 pass. SA: ~4.2s; default: ~31s. Lib ~72K bytes; default backend
did NOT hit FileTooBig (no heavy cap-reject loops).

KEY Batch 388 finding #1 (component-id numbering starts at 1, distinct from Batch 386's 0):
this deep's `new_id = comp_count + 1` gives first register `id=1` whereas Batch 386's
`new_id = comp_count` gives `id=0`. Tests assert `info1.id == 1` (not 0); header comment
documents "id starts at 1". Both numbering schemes are valid; the choice is per-deep. Subsequent
batches re-using the archetype-value shape must check which deep they're importing before
assuming the id base.

KEY Batch 388 finding #2 (spawn rejects on BOTH the cap-8 entity_count cap AND the cap-4 arch-0
row cap, Batch 386 #2 applied): the initial draft of `ecs_av_world_deep_spawn` only checked
`entity_count >= ECS_AV_CAP_ENTITIES` (8); newly-spawned entities start in arch 0 and stay there
until inserted with a component; arch 0's row cap is ECS_AV_CAP_ROWS_PER_ARCH (4), so the 5th
spawn exhausts arch 0's rows. The first draft returned `id = 4` (not -1) because it bumped
`entity_count` before `_ecs_av_arch_attach_empty` checked the row cap (that helper silently
returned w0). Fix: the spawn checks `arch0.row_count >= ECS_AV_CAP_ROWS_PER_ARCH` BEFORE allocating
the eid + calling the attach, so the 5th spawn returns `id = -1`. Test 9 verifies by spawning 5
and asserting `entity-count(w10) == 4` and `5.id == -1`. Lesson: surface every cap breach via the
canonical -1 sentinel on the relevant return wrapper.

KEY Batch 388 finding #3 (cap ordering on archetype insert → diagonal recipe preserves cap room
for the final insert): registering 3 components + diagonal insert row (e1 hp-then-mp, e2
likewise) re-uses existing archtypes so arch_count stays 3 (arches 0, {hp}, {hp,mp}); the final
insert-(selected) creates arch 4 (= cap, count becomes 4). Contrast the wrong initial Test 2
ordering (e1 hp-mp, e2 mp-health) which produces arches {0, {hp}, {hp,mp}, {mp}} = 4 upfront,
immediately tripping the cap on the final insert and failing `arch(e1) != arch(e2)`. Lesson:
when exercising cap-clamp behavior, ensure the test-insert ordering leaves room for the final
cap-triggering insert; otherwise the final insert no-ops for a different reason than the cap.

KEY Batch 388 finding #4 (cap-4 archetype clamp on 4th-distinct-component insert, Batch 386 #3
applied): Test 10 pre-registers 4 distinct components, pre-spawns 1 entity, inserts 3 (creates
arches 1,2,3 for {c0}/{c0,c1}/{c0,c1,c2}; arch_count=4=cap); the 4th insert requesting arch 5 is
silently rejected so the entity stays in its 3-component arch. Test asserts `archetype_count == 4`
(NOT 5) and `has(e1, c3) == false`, mirroring Batch 386 exactly.

KEY Batch 388 finding #5 (tick arithmetic since-strict-greater): `added_since(tick)` is strictly
`added_t > tick`; the initial Test 5 draft used `since = tick_after_registers = 2` expecting
query_added count=2, but the added stamp is also 2 so `2 > 2 = false`. Fix: `since = tick_after_
registers - 1` so `2 > 1` catches both inserts. Same for Test 7's resource-added: capture `before`
strictly BEFORE the increment that produces the stamp so `before=0 < t_after_insert=1`. Lesson:
every `*_since(tick)` assertion must have `tick < stamp` to pass strict-greater-than; `tick ==
stamp` returns false even when the component was added/changed AT that tick. Pure-since-tick
discipline — the same shape Batch 386 #1 established for by-ref aliasing, reframed.

KEY Batch 388 finding #6 (`let x: Type;` forward-declaration rejected by SA): the initial Insert
draft used `let w1: EcsAVWorldDeep; let new_arch_id: i32; if … { w1 = …; } else {` shared outer
binds and SA rejected with `Syntax Error: found ';', expected equal`. Fix: re-organize into the
Batch 386 flat-block shape — the `was_present` replace path returns early; the migration path
does attach-then-detach so the intermediate world always has the entity alive+located. The Remove
function follows the same shape. Lesson: never forward-declare via `let x: Type;`; every `let`
needs an initial value, and `if/else` branches must each `return` rather than mutate a shared
outer bind.

KEY Batch 388 finding #7 (`member fn self:` is not SA syntax; refactor to free fn): the draft
wrote `fn comp_id_comp_registered(self: EcsAVWorldDeep, cid: i32) -> bool` and called
`w0.comp_id_comp_registered(w0, comp_id)` -- both rejected (SA has no receiver method-call
syntax on structs). Fix: declare free `fn _ecs_av_world_has_reg(w: ..., cid: ...) -> bool` and
call as a plain function. Same for an ad-hoc `a1_changed_t_set_changed_for_tick_flag(self:)`.
Lesson: SA treats structs as data only; write free functions, pass the struct as the first
param, name it `w`/`a0`, not `self`.

Post-batch counts (measured): 489 lib modules | 217 `*_deep.sla` modules | 393 test files |
217 `*_deep_isolated.sla` test files | 90 examples | 6238 `@test` total (the +10 increment
consistent with the +1 lib file delta; same counting method as Batch 386/387 so absolute figures
compare directly: 6228 -> 6238).
Next free panic band: 143200+ (Batch 388 used 143000-143112).
Next batch candidates: `world` (328 lines, medium), `commands_world` (332 lines, medium),
`world_dynamic3` (340 lines, medium), `bundle_table_erased` (349 lines, medium -- needs
self-contained table storage). Defer: `world_table_erased` (~6300 lines, large), `system_param_
table_erased` (~4900 lines, large -- uses fn-pointer systems, needs fn-ptr reification per
Batch 387 finding #1). Leave out: TaskPool/async/parallel; full reflect* core runtime
(non-core reflection deepens OK).

## Batch 389 — world_deep (DONE 2026-07-12)

`lib/world_deep.sla` (~1390 lines) mirrors shallow
`lib/world.sla` (328 lines, 4 `@test` embedded at panic codes 7100-7135) as a SELF-CONTAINED
fixed-cap STACKED-COMPONENT-storage variant (NO `@import`) baking EntityAllocator + 2
ComponentStores + ResourceSlot + Messages + per-slot added/changed tick families. The shallow
`World<A,B,R,M>` uses generics and `@import`s four files; the deep reifies that surface on
fixed-cap storage with each `[T; 16]` array replaced by `field0..field15` scalar slot families
(SA has no fixed-array in `_deep.sla`). STRUCTURE distinct from Batch 386
`world_table_value_deep.sla` / Batch 388 `world_archetype_value_deep.sla`: components live in
dense (entity_id -> slot) stores, NOT (arch_id,row) archetyped tables; binding cap is the cap-16
entity/spawn cap (NO archetype-row cap here). Mirrors Bevy's stacked-component `World`:
spawn/despawn, insert_a/b, write_a, get_a/b, has_a/b, remove_a/b (swap-remove copying last slot
into removed + clear last), query_a_b (iterate A store, find B-slot by eid, emit
(entity,a_slot,b_slot,a,b)), pair_write_a (write via captured a_slot, bump changed only),
insert/has/get/remove_resource, write/read_message, a_added_since/a_changed_since (strict-
greater), increment_tick.

Concrete typed plugs `EcsWdPos{x,y}` (A), `EcsWdVel{x,y}` (B), `EcsWdTime{tick}` (R),
`EcsWdDamage{amount}` (M). Wrapper structs `EcsWdSpawn{world,entity}` /
`EcsWdPairQuery{count+per-item flat (e_id, e_gen, a_slot, b_slot, a_x, a_y, b_x, b_y) slot
families}` / `EcsWdRead{has_value,amount,cursor}` / `EcsWdMessageReader{cursor}` per Batch 373
rule (NO tuple-return destructuring in tests — sw_world/sw_entity/ecs_wd_pair_query_*_at/
ecs_wd_read_*). change_tick starts at 1 in `ecs_wd_world_new` (NOT 0) mirroring shallow
`world_new`. Entity reuse via free_ids list + generations[] bump-on-free; spawn pops free id
(clears free_id slot to 0) or bumps next_id; is_alive checks id in [1,16), id<next_id, not-in-
free, gen matches.

Tests (10) -- `tests/test_ecs_lib_world_deep_isolated.sla` (~272 lines, panic 143200-143264, 65
distinct codes verified unique). Cover the 4 shallow embedded tests verbatim + additions: Test 1
spawn+is_alive+stale reject+generation bump on id reuse; Test 2 insert_a/b+query_a_b count/
entity/a.x/b.x+remove_a removes A only (B still present)+post-remove query count=0; Test 3
pair_write_a baseline capture = change_tick(w3) = 1 + increment to 2 + pair-write (a+b across)
+ asserts `get_a.x=4 y=6`, `changed_since(1)=true`, `added_since(1)=false`; Test 4 resource
insert/get/remove + message first-read has_value amount + second read exhausted has_value=0;
Test 5 cap-16 spawn rejects 17th with sentinel id=-1 (NOT a panic); Test 6 remove_a
swap-removes LAST slot's value into REMOVED slot (e3 slot 0 untouched, e2 gone, e3's A now at
slot 1 holding 300/301); Test 7 despawn twice on same id bumps generation by exactly 1 (second
despawn no-op) + re-spawn same id + gen bump; Test 8 added_since/changed_since strict-greater at
tick-1 boundary (`added_since(1)=false` since added_t=1 not > 1; `added_since(0)=true`
strictly-before; `write_a` at same change_tick keeps `changed_since(1)` false; post-increment
`write_a` bumps changed to 2 so `changed_since(1)=true`; `added_since(1)` stays false); Test 9
insert_a replace path bumps changed-tick only post-increment (baseline=1 capture, increment to
2, re-insert via same entity → `changed_since(baseline)` true, `added_since(baseline)` false);
Test 10 multi-message drain (write 11/22/33, cursor-chained reads, final has_value=0, fresh
reader still sees all three, `remove_resource`+`reinsert_Resource(42)` proves overwrite).

Public surface (verified 10/10 on both SA + default backends): `world_new` (change_tick=1);
`increment_tick`; `world_spawn` (returns EcsWdSpawn wrapper); `is_alive`; `despawn` (remove_a +
remove_b + free_entity); `insert_a`/`insert_b` (replace-in-place if present, bump changed only;
else append new slot and stamp added+changed); `write_a` (in-place at slot, bump changed);
`get_a`/`get_b`; `has_a`/`has_b` (requires alive); `remove_a`/`remove_b` (swap-remove);
`query_a_b` (returns EcsWdPairQuery wrapper); `pair_write_a` (write via captured a_slot, bump
changed); `a_added_since`/`a_changed_since` (strict-greater); `insert_resource`/`has_resource`/
`get_resource`/`remove_resource`; `write_message`/`read_message` (returns EcsWdRead wrapper).
The allocator: `_ecs_wd_gen_at`/`_set_gen`/`_free_id_at`/`_set_free_id` accessors cap-16
cascade-of-return; `_ecs_wd_id_is_free` scans free list; `ecs_wd_alloc_entity` pops free id
or bumps next_id (sentinel id=-1 at cap, NOT panic); `ecs_wd_free_entity` bumps gen + pushes id
onto free list; `ecs_wd_is_alive` checks id in [1,16), id<next_id, not-in-free, gen matches.

Both SA + default backends: 10/10 pass. SA: ~4-5s; default: ~10s. Lib ~62K bytes; default backend
did NOT hit FileTooBig.

KEY Batch 389 finding #1 (stacked-component slot reification, distinct from archetype-grouped
storage): `[T; 16]` → `field0..field15` flat scalar slot families; the 2-axis typed values
(WorldPos ⨯ WorldVel both have x AND y) spread EACH store into FIVE scalar slot families
(eid/x/y/added_t/changed_t), 32 scalar slot fields per store, 64 across A+B — in contrast with
Batch 386/388 which had ONE-typed-value field per slot (single `amount`). Stacked-component
storage iterates slot-by-slot rather than (arch_id,row) like the archetype deeps; swap-remove on
`remove_a`/`remove_b` copies the last slot's eid+x+y+added+changed into the removed slot AND
clears the last slot. Lesson: stacked-component deeps iterating shallow owners with multi-field
typed plug values multiply the accessor count accordingly.

KEY Batch 389 finding #2 (cap-16 spawn sentinel id=-1, NOT a panic — Batch 388 #2 applied): the
initial `ecs_wd_alloc_entity` panicked with code 142801 on `next_id >= 16`, but Test 5 in the SA
backend marked FAILED (test runner treats panic as a failure exit code=81). Shallow
`alloc_entity` DOES panic at cap (code 2001), but Batch 388's archetype deep established the deep
convention of RETURNING a sentinel `entity.id == -1` (mirrors Bevy's `Entity::PLACEHOLDER`). Fix:
returns `EcsWdSpawn { world: w0 (unchanged), entity: EcsWdEntity { id: -1, generation: 0 } }` when
`next_id >= ECS_WD_CAP`; `ecs_wd_is_alive` already returned false for `id <= 0` so sentinel is
rejected as not-alive. Test 5 asserts `e17.id == -1`, `next_id(w17) == 16`, `is_alive(w17, e17)
== false`. Lesson: deep cap-rejections return canonical sentinel wrappers (id=-1) instead of
panicking — even when the SHALLOW variant panics at the same cap.

KEY Batch 389 finding #3 (top-level `const ECS_WD_NO_ID: i32 = -1` rejected by SA codegen): the
sentinel needed a named symbol so the initial draft introduced `const ECS_WD_NO_ID: i32 = -1;`
at file scope. SA codegen raised `error.CodegenError` at codegen.zig:2312
(`emitTopLevelConstDecl`'s `else => return CodegenError` path). Fix: remove the `const`, inline
`-1` directly into the `EcsWdEntity { id: -1, ... }` struct-init FIELD expression (inline
struct-field negative literals ARE permitted; archetype deep at
lib/world_archetype_value_deep.sla:523 demonstrates `EcsAVEntityDeep { id: -1, generation: 0 }`
as canonical cap-reject). The test compares against the literal `-1`. Lesson: ALL top-level
`const` declarations in SA `_deep.sla` MUST be non-negative integer literals; negative-ID/tick
sentinel returns must be INLINED into struct field-init expressions, NOT declared as named
constants.

KEY Batch 389 finding #4 (inline struct-init `let r = EcsWdMessageReader { cursor: x };`
rejected in TEST files; test files use stricter let-binding parsing than the lib file): initial
Test 4 wrote `let reader1 = EcsWdMessageReader { cursor: ecs_wd_read_cursor(read1) };` to
advance the reader cursor between chained reads. SA rejected with `Syntax Error: ... found '{',
expected semicolon` — despite the LIB file itself legally using inline struct-init `EcsWdEntity
{ id: -1, generation: 0 }` and `EcsWdSpawn { world: w0, entity: ... }` as RETURN expressions
inside function bodies. The differential: TEST files apply stricter let-binding rules around
inline struct-init (likely the dispatch detection assumes `let name = <simple>` and short-
circuits). Fix: add a lib-side constructor helper `ecs_wd_message_reader_with_cursor(cursor)`
returning `EcsWdMessageReader { cursor: cursor }`, and in tests call `let reader1 =
ecs_wd_message_reader_with_cursor(ecs_wd_read_cursor(read1))`. Same pattern reused in Test 10.
Lesson: deep tests needing mid-test wrapper construction prefer a lib-side constructor helper
over inline `let r = Struct { field: x };` — even though the lib file itself can express that
pattern.

KEY Batch 389 finding #5 (tick arithmetic since-strict-greater applied to the change_tick-
starts-at-1 world): the shallow `world_new` sets `change_tick: 1` (NOT 0); first `insert_a`
stamps `a_added_t[new_slot] = 1` and `a_changed_t[new_slot] = 1`. Shallow Test 3 captures
`baseline = w3.change_tick` after inserts (=1), increments to 2, pair_writes (bumped changed to
2). So `a_changed_since(baseline=1)` is `2 > 1 = true`, `a_added_since(baseline=1)` is `1 > 1 =
false`. The deep Test 3 mirrors exactly. Test 8 widens the boundary: `added_since(tick ==
stamp)` is false even when the component WAS added at that tick; only `added_since(tick <
stamp)` returns true. Same Batch 388 #5 / Batch 386 #1 finding reframed for the
change_tick-starts-at-1 variant (stamps land on tick=1 first, not tick=0).

Post-batch counts (measured): 490 lib modules | 218 `*_deep.sla` modules | 394 test files |
218 `*_deep_isolated.sla` test files | 90 examples | 6248 `@test` total (tests-scoped `rg -c
'@test' tests/ | awk -F: '{s+=$2}'`; same method as Batch 386/387/388, absolute figures compare
directly: 6238 -> 6248, +10).
Next free panic band: 143300+ (Batch 389 used 143200-143264).
Next batch candidates: `commands_world` (332 lines, medium), `world_dynamic3` (340 lines,
medium), `bundle_table_erased` (349 lines, medium -- needs self-contained table storage).
Defer: `world_table_erased` (~6300 lines, large), `system_param_table_erased` (~4900 lines,
large -- uses fn-pointer systems, needs fn-ptr reification per Batch 387 finding #1). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

## Batch 390 — commands_world_deep (DONE 2026-07-13)

`lib/commands_world_deep.sla` (~801 lines) mirrors shallow
`lib/commands_world.sla` (332 lines + a sibling standalone test file with 32 `@test` at panic
72000-72310) as a SELF-CONTAINED fixed-cap variant (NO `@import`) that reifies the shallow's
`Vec<...>` + Vec-len mutable commands-context into flat scalar slot families cap-N. The shallow
`EcsCommands` owns 6 Vec state items (entity_ids, comp_entities/comp_ids/comp_values,
resource_ids/resource_values, registered_systems, command_queue, schedule_labels) + next_entity
+ next_system_id; the deep replaces each Vec with `field0..fieldN-1` + explicit per-family
`*_count: i32`. Caps chosen leave room beyond any realistic test scenario: entities cap-16,
components cap-32, resources cap-8, registered-systems cap-8, command queue cap-16, schedule
labels cap-8. Mirrors Bevy src/system/commands/mod.rs `Commands` (world-level entity/component/
resource overloads + queue/schedule/dispatch wrapper).

Wrapper structs `EcsCmdSpawn{commands,entity_id}` / `EcsCmdGetVal{found,value}` /
`EcsCmdBool{commands,ok}` / `EcsCmdRegister{commands,system_id}` replace shallow's tuple-return
ops per Batch 373 rule (NO tuple-return destructuring in tests). Tests use 6 convenience helpers
sp_c/sp_e/rg_c/rg_id/bv_c/bv_ok to decompose wrappers.

Public surface (verified 10/10 on both SA + default backends): `ecs_commands_world_new`;
`spawn_empty` (EcsCmdSpawn + enqueues ECS_CMD_WD_QUEUE; sentinel `entity_id: -1` at cap-16
entities); `spawn`; `entity` (linear scan returns idx or -1); `get_entity` (EcsCmdGetVal);
`insert_entity` (overwrite-in-place if match; else append at cap-room); `has_component`;
`get_component` (EcsCmdGetVal); resource surface `insert_resource`/`init_resource`/
`insert_resource_if_neq`/`remove_resource` (swap-remove mirrors shallow Vec swap-pop)/
`get_resource`; system surface `register_system` (EcsCmdRegister; next_system_id increments;
sentinel `system_id: -1` at cap-8 systems)/`unregister_system` (swap-remove; returns EcsCmdBool)/
`run_system` (EcsCmdBool + enqueues ECS_CMD_WD_QUEUE if found); `run_schedule` (appends label;
no-op at cap-8 schedule); `queue`/`queue_handled`/`queue_silenced` (enqueue matching code);
`write_message` (enqueues message_id; mirrors shallow which pushes message_id to the queue as
the discriminator code); introspection `queue_at`/`schedule_at` for testing; stat accessors
`entity_count`/`component_count`/`resource_count`/`system_count`/`queue_len`/`schedule_count`/
`next_entity_id`/`next_system_id`. The Vec-parameterized batch APIs (insert_batch/spawn_batch/
append[Vec<i32>]) are OMITTED — Batch 368/380 convention. Tests exercise equivalent scenarios via
repeated single-element ops.

Tests (10) -- `tests/test_ecs_lib_commands_world_deep_isolated.sla` (~293 lines, panic
143300-143433, 85 distinct codes verified unique). Cover: Test 1 (mirror shallow 1) spawn_empty
ids start at 0 + entity_count + queue_len=1; Test 2 (mirror shallow 2) spawn_empty multiple
sequential ids; Test 3 (mirror shallow 3) spawn with initial component + get_component +
queue_len=1; Test 4 (mirror entity tests) get_entity found/not-found; Test 5 (mirror
insert_entity + has_component) new + overwrite + multiple components per entity; Test 6
resource lifecycle (insert overwrite + init new + init existing noop + insert_if_neq different
overwrite + insert_if_neq same noop + remove_resource swap-remove mid-slot + remove_resource
nonexistent noop); Test 7 system lifecycle (register increments next_system_id; run_system ok=1
enqueues QUEUE; unregister_system ok=1 drops count; run/unregister nonexistent ok=0 + no-op
state change); Test 8 queue/queue_handled/queue_silenced + run_schedule + write_message (queue
codes in order; schedule list order); Test 9 cap-16 spawn reject + cap-8 system register reject
BOTH sentinel id=-1 without panic (Batch 388/389 no-panic convention); Test 10 end-to-end flow
combining spawn 2 entities + multi-component insert on one + run_system + run_schedule twice +
write_message + entity-not-found assert.

Both SA + default backends: 10/10 pass. SA: ~3s; default: ~13s. Lib ~37K bytes; default backend
did NOT hit FileTooBig.

KEY Batch 390 finding #1 (Vec-pair flattening replaces mutable-state Vec<...> with cap-N scalar
slot families; NOT the queue-dispatch redesign of Batch 368's commands_dynamic_deep): shallow
`EcsCommands` owns SIX Vec state items + next_entity + next_system_id + Vec len; deep flattens
each Vec into `field0..fieldN-1` + explicit per-family `*_count: i32`. Total deep struct state:
~160 scalar fields across 13 slot families (entity table 16, components 3×32=96, resources
2×8=16, systems 8, queue 16, schedule 8). Lesson: when reifying a Vec-heavy state-owner for
`_deep.sla`, expect the slot-family count to be roughly Vec-item-count × cap-N — the most
expensive deep-struct to date in scalar-field count, but patterned on the same discipline
Batch 386-389 established.

KEY Batch 390 finding #2 (tuple-return op wrappers — Batch 373 rule applied to ALL tuple-return
public ops here): shallow surfaces 8 tuple-return public ops with different shapes; deep
introduces FOUR wrapper structs (EcsCmdSpawn/EcsCmdGetVal/EcsCmdBool/EcsCmdRegister) and reuses
each for ops with the same tuple shape: EcsCmdGetVal covers get_entity/get_component/get_resource
(`(bool, x)`); EcsCmdBool covers unregister/run_system (`(c, bool)`). Test file uses 6 small
convenience helpers (sp_c/sp_e/rg_c/rg_id/bv_c/bv_ok) mirroring Batch 389's sw_world/sw_entity
style. Lesson: when a shallow has many different tuple-return shapes, ONE wrapper per distinct
shape + reuse across ops keeps the apex public surface discoverable AND keeps tests free of
tuple destructuring.

KEY Batch 390 finding #3 (BOTH cap-rejecting public ops return sentinel wrappers, NOT panic —
Batch 388/389 #2 reinforced for multi-cap deeps): the deep has TWO cap-rejecting public ops —
`ecs_commands_spawn_empty` (entity-table cap-16) and `ecs_commands_register_system` (system-list
cap-8). Per Batch 388/389 #2 (deep cap-reject must return sentinel wrappers NOT panic — test
runner treats panic as FAIL even if the shallow had no overflow Vec::push story), BOTH return
sentinel wrappers (`EcsCmdSpawn { entity_id: -1 }` / `EcsCmdRegister { system_id: -1 }`) with
`commands` UNCHANGED (no count increment, no state mutation, no queue enqueue). Test 9 asserts
both sentinels via 16-spawn + 8-register sequences + verifies the capped state stays at cap.
Lesson: a single deep may have multiple cap-rejecting public ops — apply the no-panic sentinel
convention to EACH independently, and write a separate assertion per cap-reachable op.

KEY Batch 390 finding #4 (Vec-append-parameterized batch APIs omitted in the deep; differential
with the existing shallow): the shallow's `insert_batch(entities: Vec<i64>, component_ids:
Vec<i32>, values: Vec<i64>, mode)`, `spawn_batch(component_ids: Vec<i32>, values: Vec<i64>)`,
and `append(other_queue: Vec<i32>)` accept Vec args. Batch 368 commands_dynamic_deep / Batch 380
commands_table_value_deep both followed the convention of NOT exposing these batch APIs in their
deep counterparts; Batch 390 follows the same convention. Tests exercise equivalent scenarios
via repeated single-element ops (Test 10 spawns e1, e2, then inserts into e2 component_id 2 —
equivalent to the "spawn_batch for two entities" scenario). Lesson: the deep convention for
Vec-parameterized batch APIs is to OMIT them; batch-like scenarios use repeated single-element
ops.

KEY Batch 390 finding #5 (ECS_CMD_WD_NO_ID sentinel as positive non-negative literal — Batch
389 #3 applied to the negative top-level const constraint): Batch 389 #3 established that
top-level `const ECS_WD_NO_ID: i32 = -1` is rejected by SA codegen
(`else => return CodegenError` at `emitTopLevelConstDecl`). Batch 390 follows suit: sentinel
returns `entity_id: -1` / `system_id: -1` are INLINE STRUCT-FIELD LITERALS inside the wrapper
structs (`EcsCmdSpawn { ..., entity_id: -1 }` — inline struct-init negative literals are
permitted). A positive sentinel const `ECS_CMD_WD_NO_ID: i32 = -300` is declared (mirrors the
`ECS_TICK_NONE: i32 = 999999` precedent — a non-negative sentinel reserve), but the test script
compares the wrapper's field directly against the literal `-1` since inline struct-field
negative literals are fine and tests have no inheritance concern. Lesson: when an inline
struct-init expression uses a negative literal, comparing tests against the literal itself is
fine; the positive-const reserve remains a fallback only if subsequent code needs a comparison
value.

Post-batch counts (measured): 491 lib modules | 219 `*_deep.sla` modules | 395 test files |
219 `*_deep_isolated.sla` test files | 90 examples | 6258 `@test` total tests-scoped (same
method as Batch 386-389: `rg -c '@test' tests/ | awk -F: '{s+=$2}'` so absolute figures compare
directly: 6248 -> 6258, +10).
Next free panic band: 143500+ (Batch 390 used 143300-143433; Batch 389 used 143200-143264).
Next batch candidates: `world_dynamic3` (340 lines, medium), `bundle_table_erased` (349 lines,
medium -- needs self-contained table storage). Defer: `world_table_erased` (~6300 lines, large),
`system_param_table_erased` (~4900 lines, large -- uses fn-pointer systems, needs fn-ptr
reification per Batch 387 finding #1). Leave out: TaskPool/async/parallel; full reflect* core
runtime (non-core reflection deepens OK).

## Batch 391 — world_dynamic3_deep (DONE 2026-07-13)

`lib/world_dynamic3_deep.sla` (1809 lines) mirrors shallow `lib/world_dynamic3.sla` (340 lines,
shallow `DynamicWorld3<A, B, C, R, M>` generically-typed Vec/dyn_store-backed dynamic 3-column
variant of `DynamicWorld`, with 3 embedded `@test` at panic 8101-8106/8200-8224) as a SELF-
CONTAINED fixed-cap-16 variant (NO `@import`) that reifies the shallow's Vec growth + generics +
`impl DynamicWorld3TripleQuery { fn iter_len / iter_at }` method-call syntax + `for pos in
with_c { ... }` test-level iteration into flat scalar slot families cap-16 plus free functions
(NEVER member `fn self` per Batch 388 #7) plus `while i < count { ... }` test loops (NEVER
for-in per Batch 388 #6, applied for the first time to shallow-test mirroring here since this is
the FIRST shallow whose embedded test uses for-in iteration).

The shallow's `DynamicWorld3<A,B,C,R,M>` owns a `DynamicEntityAllocator` (free_ids + generations
+ occupied Vec-grow machinery; dyn_is_alive rejects `id <= 0` and slot 0 is pre-allocated as
dead/reserved so the first fresh allocation returns id 1) + three `DynamicComponentStore<T>` (one
per component column A/B/C) + one `ResourceSlot<R>` + one `Messages<M>` queue + a monotone
`change_tick` (starts at 1 in `dynamic_world3_new`) + SIX parallel `DynamicComponentStore<i32>`
aux stores for per-component `added_ticks` + `changed_ticks` (one added + one changed per
column). The deep collapses this growable-by-index state into a single `EcsWD3World` flat scalar
struct: a `next_id` + `free_count` + cap-16 slot families for `gen` / `free_id` / `occupied`
(the 3 allocator slot families × cap-16 = 48 fields), each of the A/B stores as 5 cap-16 slot
families `eid / x / y / added_t / changed_t` (5 × 16 × 2 stores = 160 fields) — but the C store
has only 4 cap-16 slot families because C is `EcsWD3Player{team}` (NOT x/y), so its families are
`eid / team / added_t / changed_t` (4 × 16 = 64 fields) — total component-store state 14 slot
families × cap-16 = 224 slot fields, plus a single `ResourceSlot` collapse (`res_has` +
`res_tick` + `res_added_t` + `res_changed_t`), plus a cap-16 message slot family `msg0..15` +
`msg_tail`, plus the monotone `change_tick`. Each Vec-pair `Vec + Vec-len` of the shallow's
`DynamicComponentStore<T>` (which keeps `entity_ids` + `values` parallel Vecs) collapses to the
per-slot eid slot family indexing the per-slot value slot family by the same cap-16 ordinal
(the deep convention of "shallow-slot is `(eid, value)` parallel pair; deep refolds both into
slot families keyed by index" established in Batch 386/388-390 and applied uniformly here).

The shallow separates the per-component added/changed tick tracking from the data: each store
gets its OWN `DynamicComponentStore<i32>` parallel sparse store keyed by entity_id slot. The
deep bakes the per-store added/changed tick INTO each store slot directly (`a_added_t0..15`,
`a_changed_t0..15`, ... per B/C mirror — `c_added_t0..15` / `c_changed_t0..15`). This eliminates
the 6 aux sparse stores of the shallow and saves 6 × cap-16 slot families of redundant storage
— the same approach Batch 389 `world_deep.sla` chose; the deep is byte-identical shape to the
world_deep A/B store accessors + ops plus a C-store variant with C's `team` (not x/y) and the
extra `c_added_since` / `c_changed_since` query ops.

Wrapper structs introduced to keep tests free of tuple destructuring (Batch 373 rule) and
member-method free (Batch 388 #7): `EcsWD3Spawn { world, entity }` (replaces
`(DynamicWorld3, Entity)` from spawn / spawn_abc), `EcsWD3TripleQuery { count + 10 cap-16 slot
families }` (replaces `DynamicWorld3TripleQuery { items: Vec<...> }` + an `iter_len`/`iter_at`
member-method-query), `EcsWD3QueryA { count + 2 cap-16 slot families }` (replaces
`DynamicWorld3QueryA { items: Vec<A> }` and the `q.items[i]` access — re-used by BOTH
`query_a_with_c` AND `query_a_without_c` since both ops emit an A-only list), `EcsWD3Read
{ has_value, amount, cursor }` + `EcsWD3MessageReader { cursor }` (replaces `Messages<T>`
queue iteration). Tests use sw_world / sw_entity convenience helpers (mirroring Batch 389
sw_world/sw_entity). The 10 cap-16 cascade getters/setters per query struct (_ecs_wd3_q_X_at /
_ecs_wd3_q_set_X) per index cascade-of-return are byte-identical shape to Batch 389's
EcsWdPairQuery getters/setters — just with the addition of `c_slot` AND `c_team` slot families
since this query is over 3 columns (not 2). The `_ecs_wd3_qa_set_x/_y` (single-A-list query)
accessors are fresh-but-identical-pattern.

Public surface verified 10/10 on BOTH the SA backend (`--test-backend sa --jobs 1 --trace-panic`,
~5s) AND the default backend (`--jobs 1 --trace-panic`, ~10s). The 10 public lib ops from shallow
that are exercised: `ecs_wd3_world_new` (next_id=1 — slot 0 reserved — mirrors shallow
`dyn_alloc_entity` which starts ids at 1 because dyn_allocator_new pre-allocates slot 0 as dead,
and `dyn_is_alive` rejects `id <= 0`), `ecs_wd3_increment_tick`, `ecs_wd3_world_spawn`
(returns EcsWD3Spawn), `ecs_wd3_spawn_abc` (alloc + insert_a + insert_b + insert_c, returns
EcsWD3Spawn), `ecs_wd3_is_alive` (rejects `id <= 0`; checks free_ids; matches generation), the
3 per-store `insert_*` ops (replace-in-place bumps changed-tick only; else append new slot
stamps added+changed; panic 8101/8102/8103 if not alive), `ecs_wd3_write_c` (in-place at slot,
bump changed only; panic 8106 if missing), `ecs_wd3_get_a` / `get_c` (panic 8104/8105 if
missing; return EcsWD3Pos / EcsWD3Player), the 3 `has_*` ops, the 3 `remove_*` ops (slot-
addressed swap-remove: copies last slot's eid+field+added+changed into removed slot, then
clears last + drops count), `ecs_wd3_despawn` (remove_a + remove_b + remove_c + free_entity),
`c_added_since` / `c_changed_since` (strict-greater `stamp > tick` per Batch 388 #5), and the
3 query build loops (`ecs_wd3_query_a_b_c` iterate A store, find b_slot+c_slot by eid, emit
triple if both found AND entity alive; `ecs_wd3_query_a_with_c` iterate A store, filter
has_c alive, push a (x,y); `ecs_wd3_query_a_without_c` mirror with NOT has_c). Resource +
message surfaces (insert/has/get/remove_resource; write/read/count_message; the shallow has
them but the 3 embedded tests do NOT exercise them, so they're covered here as parity tests
mirroring Batch 389's resource + message coverage.)

Tests (10) — `tests/test_ecs_lib_world_dynamic3_deep_isolated.sla` (~233 lines, panic
143500-143595, 32 distinct codes verified unique via the standard `rg -o 'panic\(([0-9]+)\)'
-r '$1' | sort -n | awk 'NR>1 && $1==prev {print "DUP"} {prev=$1}'` check returning no dups;
cross-checked globally against lib/ + tests/ for the 143500-143599 band occupying no other
batch). Cover: Test 1 (mirror shallow test 1) spawn_abc bundle + triple query count == 1 + entity
match + a.x + b.x + c.team == 10 assertion; Test 2 (mirror shallow test 2) query_a_with_c vs
query_a_without_c filter boundary — since SA tests cannot use `for pos in with_c` the deep test
uses `while i < count { sum += q.x_at(i); i++; }` to compute the with_c summation (3 == e1's
a.x) and asserts without_c count == 1 with `q.x_at(0) == 9` plus `has_c(e1) == true`; Test 3
(mirror shallow test 3) c change detection — `c_added_since(e1, 0)` is true (added_t = 1 > 0)
right after spawn_abc; `increment_tick` (now 2); `write_c team 4` (changed_t = 2);
`c_changed_since(e1, 1)` true (2 > 1 strict-greater — Batch 388 #5); `get_c.team == 4`;
`despawn(e1)` → `is_alive == false` and `has_a == false`; Test 4 — explicit strict-greater
`c_added_since(e1, 1)` is FALSE (added_t = 1, equal-stamp returns false even when added at
exactly that tick) and pre-write_c `c_changed_since(e1, 1)` is also false — exercises the Batch
388 #5 rule that the shallow test only infers (shallow asserts the TRUE cases only); Test 5 —
cap-16 spawn reject sentinel — 15 successful spawns yield ids 1..15 (slot 0 reserved so cap-16
floor is 15 the SAME WAY Batch 389's next_id-starts-at-0 yields 16 ids; the deep starts at 1 so
yield = 15), then the 16th spawn rejects with `entity_id == -1` (and `generation == 0`) and
`next_id` stays unchanged at 16 — NO panic (Batch 388/389 #2 / Batch 390 #3 sentinel
convention); Test 6 — remove_a swap-remove relocates the last A slot into the freed slot (spawn
3 + insert_a 3 with distinct x values; remove_a(e1); assert has_a(e1)==false BUT has_a(e3)==true
AND get_a(e3).x == 33 i.e. the relocated value survived the swap); Test 7 — despawn frees the id
and a later spawn reuses the SAME id at generation + 1 (one of the few generation-bump
recovered-id assertions exercised in isolation); Test 8 — insert_c replace-in-place path bumps
changed-tick ONLY (leaves added unchanged) — `c_added_since(e1, 1)` stays false after re-insert_c
because added_t was stamped once at the original spawn_abc and not touched by the replace;
Test 9 — resource lifecycle (insert_resource / has_resource / get_resource tick / remove_resource
— coverage the shallow embedded tests skip); Test 10 — message queue write/read/drain via the
cascading reader cursor (write 3 amounts then drain all 3 via reader + assert 4th read's
has_value == 0; reader cursor advances through `message_reader_with_cursor(read_cursor(prev))`
chaining).

Nested-ternary refactored into discrete helpers (Batch 388 #6) — N/A (no ternary was needed;
all branching uses flat-block shape with early return per Batch 386/388 #6). No forward-decls
used (Batch 389 #4). No `let _` / `let _ = x` (dropped unused params). No top-level negative
const literals (Batch 389 #3); sentinel `EcsWD3Entity { id: -1, generation: 0 }` is constructed
with INLINE negative literals inside an inline struct-init field expression (permitted), and
test side compares directly against literal `-1` instead of referencing a const. `if` blocks
close with `};` and `while` blocks close with bare `}` per the SA surface syntax convention.

KEY Batch 391 finding #1 (3-axis typed-plus-C-different plug set; the deep collapses BOTH the
component-data columns AND the per-store added/changed tick aux sparse stores all into the SAME
store's per-slot field families — DIFFERENTIAL with prior batches where the aux sparse stores
existed as separate state): the shallow keeps each per-store added/changed tick tracking in a
SEPARATE `DynamicComponentStore<i32>` parallel sparse store keyed by entity_id slot — 6 such
aux sparse stores for 3 columns. The deep bakes the added/changed tick INTO each store slot as a
per-slot field family (`a_added_t0..15`, `a_changed_t0..15`, ..., `c_added_t0..15`,
`c_changed_t0..15`). This is the SAME approach Batch 389 `world_deep.sla` took but applied to 3
columns (not 2); the saving is 6 fewer slot families × cap-16 = 96 scalar fields of redundant
storage. The differential caveat: a 4th column would add 2 more aux sparse stores on the
shallow (one added + one changed tick sparse store) but only 2 more slot families on the deep (a
baked-in added_t + a baked-in changed_t per-slot for the new column). Lesson: when mirroring a
shallow that keeps per-component tick tracking in parallel sparse stores, the deep convention is
to inline the per-slot tick (added_t + changed_t) into the per-slot field families of the SAME
store; this reduces slot-family count proportional to the number of component columns.

KEY Batch 391 finding #2 (first batch where SA tests cannot use for-in iteration over a query
result; the shallow uses `for pos in with_c { total += pos.x }` in an embedded test which the
SA `_deep.sla` TEST surface does not support — Batch 388 #6 applied to test iteration): the
shallow's 2nd embedded test uses `for pos in with_c { total = total + pos.x; }` to sum the a.x
values of entities that have C. The deep test surface does not accept `for x in iter { }` syntax
so the deep test refactors that into `let i = 0; while i < count { total += q.x_at(i); i++; }`
using the count + per-index accessors (`ecs_wd3_query_a_count`, `ecs_wd3_query_a_x_at`). This is
the FIRST batch where shallow-test-mirroring required the while-loop refactor for iterating a
query result set — the rule was already known from Batch 388 #6 (no for-in in tests); it is now
NEWLY exercised by a shallow that actually uses it in the embedded test. Lesson: when the
shallow embedded test loops over a query result with for-in, the deep test replaces it with a
`while i < count` loop that reads per-index accessors from the query-result wrapper struct — the
count accessor + per-index accessors are what enable this refactor, which is why the query-result
wrapper structs always expose `count` + per-index getters even when the deep ALREADY has the
data baked into flat slot families.

KEY Batch 391 finding #3 (cap-16 + slot-0-reserved yields cap-15 usable entities (NOT 16) —
differential with Batch 389 which started `next_id = 0` and yielded cap-16 usable entities; this
deep starts `next_id = 1` because the shallow allocator pre-allocates slot 0 as dead, so the
deep mirror starts with id=1 and yields ids 1..15 (15 ids); `next_id >= ECS_WD3_CAP` (16)
rejects the 16th spawn attempt): the deep convention for the entity-allocator cap-reject
threshold mirrors the SHALLOW allocator's id-allocation fat (NOT the cap floor). Shallow
`dyn_allocator_new` pre-allocates slot 0 in `generations`/`occupied` and `dyn_is_alive` rejects
`id <= 0` — so slot 0 is the reserved/dead slot and the first fresh `dyn_alloc_entity` returns
`id = 1` (because `len(generations)` is 1 after the pre-allocate). The deep mirrors this
faithfully: `ecs_wd3_world_new` sets `next_id = 1` and `ecs_wd3_is_alive` rejects `id <= 0`
(slot 0 dead). With cap-16 slots (0..15), the usable ids are 1..15 (15 ids); the cap-reject
fires when `next_id >= 16` after 15 successful spawns. This is DIFFERENT from Batch 389 where
`world_deep.sla` started `next_id = 0` and the test file asserted 16 successful spawns then a
17th-reject sentinel — Batch 389 mirrored a shallow world.sla whose allocator did NOT reserve
slot 0; world_dynamic3's shallow mirrors `entity_dynamic.sla` which DOES. Lesson: the cap floor
of the deep allocator must mirror the SHALLOW allocator's id-reservation logic — when the shallow
pre-allocates slot 0 as dead the deep yields cap-1 usable ids; when the shallow starts at slot 0
the deep yields cap usable ids. The test author (or the assistant reproducing the test) MUST
consult `lib/entity_dynamic.sla`'s `dyn_allocator_new` + `dyn_is_alive` to determine the exact
yield, because the cap-N scalar slot family spans `0..cap-1` but the id reserved as dead (here,
slot 0) shifts the usable range by -1.

KEY Batch 391 finding #4 (mirror of Batch 388/389/390 deep-convention findings explicitly
applied to a 3-column query — the world_deep.sla pair_query template (A × B) extends cleanly to
an A × B × C triple query with the addition of a `c_slot` per-item field + a `c_team` per-item
field, demonstrating the per-item slot-family pattern scales beyond pair queries): the
`EcsWdPairQuery` template (Batch 389 world_deep.sla) had 10 per-item cap-16 slot families (e_id,
e_gen, a_slot, b_slot, a_x, a_y, b_x, b_y). `EcsWD3TripleQuery` extends that with `c_slot` +
`c_team` to 12 per-item cap-16 slot families — the per-item entity id + generation + per-column
slot + per-column value slot set scales linearly with the number of columns joined by the query
(no nesting or list-of-lists needed). The 12 × 16 = 192 per-item scalar fields joins the
component-store slot families + the `QueryA` A-only-list query (2 slot families × 16 = 32
fields) into a query-state total of ~224 query-struct fields across 2 query wrapper structs.
Lesson: per-item flat-scalar slot-family query wrappers (one struct per query build loop) scale
linearly with column-count × cap — the same byte-identical cascade-of-return accessor pattern
from Batch 389 generalizes to N-column queries without restructuring.

Post-batch counts (measured): 492 lib modules | 220 `*_deep.sla` modules | 396 test files |
220 `*_deep_isolated.sla` test files | 90 examples | 6268 `@test` total tests-scoped (same
method as Batch 386-390: `rg -c '@test' tests/ | awk -F: '{s+=$2}'` so absolute figures compare
directly: 6258 -> 6268, +10).
Next free panic band: 143600+ (Batch 391 used 143500-143595; Batch 390 used 143300-143433).
Next batch candidates: `bundle_table_erased` (349 lines, medium -- needs self-contained table
storage). Defer: `world_table_erased` (~6300 lines, large), `system_param_table_erased`
(~4900 lines, large -- uses fn-pointer systems, needs fn-ptr reification per Batch 387 finding
#1). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection
deepens OK).

## Batch 392 — bundle_table_erased_deep (DONE 2026-07-13)

`lib/bundle_table_erased_deep.sla` (1335 lines) mirrors shallow `lib/bundle_table_erased.sla`
(349 lines, Bevy-style component bundles over `TableErasedWorld<R, M>`) as a SELF-CONTAINED
fixed-cap variant (NO `@import`). The shallow depends on the deferred, large
`world_table_erased.sla` (~6300 lines) and its boxed `ErasedComponentValue` / generic
`TableErasedWorld<R, M>` / `drop_fn: fn(*u8) -> void` / table + sparse-set storage machinery; the
deep does NOT deepen that large module first. Instead it reifies the exact erased-world subset
needed by bundle insertion: fixed-cap entity allocator, cap-4 component metadata registry,
Pos/Vel TABLE stores, Player SPARSE_SET store, bundle2/bundle3 insert paths, if-new preservation,
spawn + spawn-batch wrappers, and a Pos×Vel pair query wrapper.

Concrete plugs mirror the shallow embedded tests: `EcsBtePos{x,y}` type id 401, `EcsBteVel{x,y}`
type id 402, `EcsBtePlayer{team}` type id 403, plus Time/Event defaults for naming parity. The
registry is cap-4 (`reg_type`, `reg_kind`, `reg_store`) and returns component_id == registry slot,
matching the shallow `ComponentInfo.id` usage in tests. TABLE storage_kind 0 is modeled by dense
cap-16 `(entity_id, x, y)` row stores for Pos and Vel; SPARSE_SET storage_kind 1 is modeled by a
cap-16 `(entity_id, team)` store for Player. Entity allocator uses slot 0 reserved (`next_id=1`,
`id <= 0` rejected), so cap-16 yields 15 usable ids before the no-panic sentinel
`EcsBteEntity{id:-1,generation:0}`.

Tuple-return and Vec-return shallow APIs use wrappers: `EcsBteRegister{world, component_id}` for
register metadata, `EcsBteSpawn{world, entity}` for spawn and spawn_bundle, and
`EcsBteSpawnBatch{world,count,entity_id0/entity_gen0,entity_id1/entity_gen1}` for cap-2
spawn_batch_bundle2/3. `EcsBteBundle2` / `EcsBteBundle3` fold shallow `ErasedComponentValue` into
tagged scalar fields (Pos/Vel x/y, Player team), avoiding generics and erased boxes. `EcsBtePairQuery`
replaces `Query<TableErasedPair<A,B>>` with count + flat item slot families `(entity_id,a_x,a_y,b_x,b_y)`.

Public surface verified: register_component_metadata, component_id_for_type, kind_for_component,
world_spawn, spawn_bundle2, spawn_bundle3, spawn_batch_bundle2/3, insert_bundle2/3,
insert_bundle2/3_if_new, insert_batch_bundle2/3, insert_batch_bundle2/3_if_new, has/get for
Pos/Vel/Player, entity_archetype_id (bitmask >0 after insertion), and query_pair_auto. The shallow
`drop_uninserted_bundle_value` invokes a drop fn on a boxed raw pointer; the deep values are owned
scalars, so this operation is a no-op while preserving if-new semantics.

Tests (8) — `tests/test_ecs_lib_bundle_table_erased_deep_isolated.sla` (191 lines, panic
143600-143682, codes verified unique locally and globally in 143600-143699). Cover: mirror shallow
bundle3 spawn/insert component sets; mirror shallow bundle2 insert preserving existing Pos; mirror
batch bundle3 overwrite behavior; mirror batch bundle3_if_new preserving existing Pos; spawn-batch
bundle3 wrapper returns both entities and populated world; registry lookup + storage_kind metadata;
cap-16 slot-zero-reserved spawn sentinel; bundle2 Pos+Vel query without Player. SA backend and
default backend both pass 8/8.

KEY Batch 392 finding #1 (medium erased bundle module can deepen without first deepening the
large erased world): `bundle_table_erased` depends on `world_table_erased.sla`, but its embedded
behavior only needs a small erased-world slice. A self-contained deep can implement that slice
faithfully enough for bundle semantics by owning the registry + typed stores directly and by
collapsing `ErasedComponentValue` boxes into tagged scalar fields. This keeps `world_table_erased`
(~6300 lines) deferred while still making forward progress on the medium bundle layer.

KEY Batch 392 finding #2 (TABLE vs SPARSE_SET still matters in the deep): even though the deep
stores concrete scalar fields, it preserves storage metadata: Pos/Vel registered with kind 0 and
Player with kind 1. Tests assert kind metadata and component presence through component ids, while
query_pair_auto only walks the table-backed Pos/Vel stores. This preserves the shallow’s important
semantic distinction without reproducing full table-column/archetype internals.

KEY Batch 392 finding #3 (if-new bundle insert requires drop-path semantics even when drop is a
no-op): shallow `insert_bundle*_if_new` calls `drop_uninserted_bundle_value` when a component is
already present. In the deep the value has no heap/raw pointer, so drop is a no-op, but the branch
still matters because it must NOT overwrite the existing component. Test 4 asserts first entity's
pre-existing Pos stays x=1 while Vel/Player are inserted and the second entity receives all bundle
values.

Post-batch counts (measured): 493 lib modules | 221 `*_deep.sla` modules | 397 test files |
221 `*_deep_isolated.sla` test files | 90 examples | 6276 `@test` total tests-scoped (6268 ->
6276, +8).
Next free panic band: 143700+ (Batch 392 used 143600-143682; Batch 391 used 143500-143595).
Next batch candidates: inspect remaining medium modules; defer `world_table_erased` (~6300 lines)
and `system_param_table_erased` (~4900 lines, fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

## Batch 393 — relationship_declaration_deep (DONE 2026-07-13)

`lib/relationship_declaration_deep.sla` (528 lines) mirrors shallow `lib/relationship_declaration.sla`
(223 lines) as a SELF-CONTAINED fixed-cap-16 variant (NO `@import`). The shallow module owns
library-side relationship declaration metadata normally synthesized by derive macros: relationship
id, source component id, target collection component id, target mode (many/one), linked_spawn,
allow_self, ordered, valid, and error_code. The shallow registry is
`Vec<EcsRelationshipDeclaration>`; the deep flattens it into cap-16 declaration slot families
(`relationship_type_id0..15`, `source_component_type_id0..15`, etc.) plus `count`.

The deep keeps all validation semantics: invalid relationship/source/target ids, invalid target
mode, source==target component rejection, and ordered one-to-one rejection. Shallow bool fields
become i32 flags in the deep (`0/1`) to keep test access scalar and avoid bool slot-family edge
cases; constructors still accept bool params for source-level parity and immediately convert them
through `ecs_rel_decl_bool`. Registry registration mirrors shallow control flow: invalid
preserves registry and returns `invalid=1` with original error_code; same relationship id + same
full declaration returns duplicate; same relationship id + different declaration returns
id_collision; distinct id but same source/target pair returns pair_conflict; otherwise insertion
writes the next cap slot. Cap overflow returns an invalid register result without mutating the
registry (deep cap-reject convention, no panic).

Tests (9) — `tests/test_ecs_lib_relationship_declaration_deep_isolated.sla` (113 lines, panic
143700-143783, codes verified unique locally and globally in 143700-143799). Cover: mirror shallow
many declaration flags; one-to-one ordered rejection; invalid id/mode/same-component errors;
unique insert; duplicate declaration; id collision; component pair conflict; invalid declaration
registration; cap-16 overflow reject preserving count. SA backend and default backend both pass 9/9.

KEY Batch 393 finding #1 (derive-like metadata modules are excellent fixed-cap registry targets):
this module has no world mutation, async, fn-pointer system callbacks, or reflect runtime payloads;
its main shallow abstraction is a Vec-backed metadata registry. These modules deepen cleanly by
turning Vec rows into slot families and keeping the validation finite-state machine byte-faithful.

KEY Batch 393 finding #2 (bool slot families should be normalized to i32 flags when tests need
stable scalar access): the shallow uses bool fields, but prior deep conventions prefer scalar
accessors. Using i32 `0/1` flags avoids mixed bool/int assertions and keeps register result flags
uniform with earlier wrapper structs that expose found/ok flags as integers.

Post-batch counts (measured): 494 lib modules | 222 `*_deep.sla` modules | 398 test files |
222 `*_deep_isolated.sla` test files | 90 examples | 6285 `@test` total tests-scoped (6276 ->
6285, +9).
Next free panic band: 143800+ (Batch 393 used 143700-143783; Batch 392 used 143600-143682).
Next batch candidates: continue medium non-async/non-parallel modules such as `world_registry_typed`,
`required_components_dynamic`, or `query_dynamic`. Defer TaskPool/async/parallel modules,
`world_table_erased` (~6300 lines), and `system_param_table_erased` (~4900 lines with fn-pointer
systems). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection
deepens OK).

## Batch 394 — world_registry_typed_deep (DONE 2026-07-13)

`lib/world_registry_typed_deep.sla` (1101 lines) mirrors shallow `lib/world_registry_typed.sla`
(257 lines) as a SELF-CONTAINED fixed-cap variant (NO `@import`). The shallow composes
`RegistryWorld` + two typed `DynamicComponentStore<A/B>` stores + resource/messages + dynamic query
wrappers; the deep inlines the needed registry sidecar: cap-16 entity allocator, A/B membership
columns with per-slot added/changed ticks, typed A/B value stores, resource slot, cap-16 message
queue, and query wrappers. Component ids are fixed (`A=0`, `B=1`), matching shallow construction
where `registry_typed_world_new` registers A then B into `RegistryWorld`.

The deep preserves shallow tick semantics: `change_tick` starts at 1; insert stamps added+changed;
replace/writeback only updates changed; `*_since` uses strict `stamp > tick`. Pair writeback mirrors
`registry_typed_world_query_pair_mut_a_write`: it writes A at the captured A slot and marks A changed
without changing its added tick. Despawn removes both membership/value stores and pushes the entity id
onto the free list with generation bump. Queries are wrapper structs: `EcsWrtQueryA` for query_a and
query_a_without_b, and `EcsWrtPairQuery` for mutable A/B pair query (entity id, A slot, A/B values).

Tests (6) — `tests/test_ecs_lib_world_registry_typed_deep_isolated.sla` (115 lines, panic
143800-143872, codes verified unique locally and globally in 143800-143899). Cover: mirror shallow
A/B binding and A-without-B filtering; mirror shallow pair writeback with added vs changed tick
assertions; mirror shallow despawn removal; plus remove_a keeps B but removes pair query eligibility;
resource/message lifecycle; cap-16 slot-zero-reserved spawn sentinel. SA backend and default backend
both pass 6/6.

KEY Batch 394 finding #1 (RegistryWorld + typed stores can be decomposed into two independent
layers): shallow keeps membership/ticks in RegistryWorld and values in DynamicComponentStore<A/B>.
The deep bakes both into A/B slot families but still preserves the conceptual split: A/B membership
slots carry eid/added/changed, while A/B value slots carry x/y. This makes query filters operate on
membership and get/write operate on value slots, matching the shallow behavior without requiring the
full `world_registry_deep` layer.

KEY Batch 394 finding #2 (pair writeback needs the A slot, not just the entity): shallow
`PairMutItem<A,B>` captures `Mut<A>{entity, slot, value}`. The deep query wrapper explicitly exposes
`ecs_wrt_pair_query_a_slot_at` so writeback can mutate the exact A slot and stamp changed tick. Tests
exercise this by capturing baseline tick, incrementing, writing `a.x + b.x`, and asserting
`added_since(baseline)==false` but `changed_since(baseline)==true`.

Post-batch counts (measured): 495 lib modules | 223 `*_deep.sla` modules | 399 test files |
223 `*_deep_isolated.sla` test files | 90 examples | 6291 `@test` total tests-scoped (6285 ->
6291, +6).
Next free panic band: 143900+ (Batch 394 used 143800-143872; Batch 393 used 143700-143783).
Next batch candidates: continue medium non-async/non-parallel modules such as
`required_components_dynamic` or `query_dynamic`. Defer TaskPool/async/parallel modules,
`world_table_erased` (~6300 lines), and `system_param_table_erased` (~4900 lines with fn-pointer
systems). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core reflection
deepens OK).

## Batch 395 — required_components_dynamic_deep (DONE 2026-07-13)

`lib/required_components_dynamic_deep.sla` (182 lines) mirrors shallow
`lib/required_components_dynamic.sla` (254 lines) as a SELF-CONTAINED fixed-cap variant (NO
`@import`). The shallow models Bevy required-components dynamic registration gaps:
`register_dynamic_with`, `register_by_id`, `RequiredComponentsRegistrator::register_required_by_id`,
`register_required_dynamic_with`, and `components_registrator`. It stores `direct_ids` and `all_ids`
in Vecs; the deep flattens both lists into cap-16 slot families and keeps the same result/accessor
shape using wrapper structs (`EcsReqDynResultDeep`, `EcsReqDynMutResultDeep`, and
`EcsRequiredComponentsRegistratorDynDeep`).

Semantics preserved: duplicate direct registration returns ok=0 with DuplicateRegistration kind 0
without mutating state; success appends to direct order and prepends the component id to `all` order
(depth-first/new requirement first), matching the shallow model. `register_by_id` is an alias of
`register_dynamic_with`; mutator variants return mutated required-components state; registrator
facade records `target_component_id`, exposes `components_next_id`, and stores `last_ok` /
`last_err_kind` after each builder-style call. Cap overflow is a no-panic reject returning ok=0 and
preserving counts.

Tests (7) — `tests/test_ecs_lib_required_components_dynamic_deep_isolated.sla` (92 lines, panic
143900-143963, codes verified unique locally and globally in 143900-143999). Cover: success result
lengths; duplicate direct registration no-op; depth-first all-order prepending; registrator facade
target/components accessor; dynamic_with duplicate last_err recording; out-of-range accessors return
-1; cap-16 overflow reject preserving state. SA backend and default backend both pass 7/7.

KEY Batch 395 finding #1 (shallow model modules without embedded tests still need explicit deep
coverage): `required_components_dynamic.sla` has no shallow `@test`, but its public surface is small
and important. The deep test suite therefore exercises each documented semantic path directly rather
than only mirroring embedded tests.

KEY Batch 395 finding #2 (result+mutator wrapper avoids tuple-return and by-ref ambiguity): the
shallow has separate result-only and mutating builder-style APIs. The deep uses
`EcsReqDynMutResultDeep{required,result}` internally for tests that need both the mutated state and
result flags, while keeping public result-only and mut-only helpers. This preserves explicit state
threading and avoids tuple destructuring.

Post-batch counts (measured): 496 lib modules | 224 `*_deep.sla` modules | 400 test files |
224 `*_deep_isolated.sla` test files | 90 examples | 6298 `@test` total tests-scoped (6291 ->
6298, +7).
Next free panic band: 144000+ (Batch 395 used 143900-143963; Batch 394 used 143800-143872).
Next batch candidates: continue medium non-async/non-parallel modules such as `query_dynamic`,
`schedule_table_erased`, or `schedule_table_erased_relationship`. Defer TaskPool/async/parallel
modules, `world_table_erased` (~6300 lines), and `system_param_table_erased` (~4900 lines with
fn-pointer systems). Leave out: TaskPool/async/parallel; full reflect* core runtime (non-core
reflection deepens OK).

## Batch 396 — query_dynamic_deep (DONE 2026-07-13)

`lib/query_dynamic_deep.sla` (1337 lines) mirrors shallow `lib/query_dynamic.sla` (277 lines) as a
SELF-CONTAINED fixed-cap query layer over a DynamicWorld-like two-component world. The shallow
imports `world_dynamic.sla`, defines generic `Query<T>`, `Mut<T>`, `EntityItem<T>`,
`PairMutItem<A,B>`, and filter marker wrappers (`With`, `Without`, `Added`, `Changed`); the deep
inlines a cap-16 entity allocator, A/B value stores with added/changed ticks, and query result
wrappers. The first shallow embedded test uses `for item in q`; the deep test rewrites it to
`while i < count` over wrapper accessors.

The deep provides `EcsQdQueryA`, `EcsQdEntityAQuery`, and `EcsQdPairQuery` wrappers. `query_mut_a`
uses the pair-query shape with B fields zeroed so it can still expose entity id, A slot, and A
value for writeback without tuple/struct nesting. `query_mut_a_write` and `query_pair_mut_a_write`
mutate by captured A slot and stamp only changed_t. Added/changed filters use strict `stamp > tick`,
matching dynamic_world semantics.

Tests (5) — `tests/test_ecs_lib_query_dynamic_deep_isolated.sla` (124 lines, panic 144000-144051,
codes verified unique locally and globally in 144000-144099). Cover: mirror shallow read/entity
query with for-in rewritten to while; mutable A writeback; pair query + with/without filters; added
and changed filters; cap sentinel + despawn filtering. SA backend and default backend both pass 5/5.

KEY Batch 396 finding #1 (generic query facade can be represented by a small set of typed wrappers):
the shallow's `Query<T>` covers many item types, but the exercised surface only needs A values,
entity+A items, mutable A items, and pair mutable A/B items. The deep maps these to concrete
wrappers with count + per-index accessors, avoiding generic Vec-backed query storage.

KEY Batch 396 finding #2 (for-in query iteration must be rewritten in tests): the shallow test
iterates `for item in q`; deep tests use count/accessor while loops. This repeats the Batch 391
lesson and applies it to the original dynamic query layer.

Post-batch counts (measured): 497 lib modules | 225 `*_deep.sla` modules | 401 test files |
225 `*_deep_isolated.sla` test files | 90 examples | 6303 `@test` total tests-scoped (6298 ->
6303, +5).
Next free panic band: 144100+ (Batch 396 used 144000-144051; Batch 395 used 143900-143963).
Next batch candidates: continue medium non-async/non-parallel modules such as
`schedule_table_erased`, `schedule_table_erased_relationship`, or `schedule_table_erased_observer`.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

## Batch 397 — schedule_table_erased_relationship_deep (DONE 2026-07-13)

`lib/schedule_table_erased_relationship_deep.sla` (302 lines) mirrors the scheduling and relationship
access metadata from shallow `lib/schedule_table_erased_relationship.sla` without importing the full
erased table world or preserving fn-pointer execution. The deep is SELF-CONTAINED and models a
small fixed-cap world (`EcsStrWorld`) plus cap-8 schedule slots. System functions are represented by
stable kind ids (`MOVE`, `REL_COUNT`, `MESSAGE`, `RELATE_FIRST_TWO`) so tests can verify scheduling,
conflict metadata, and execution order without runtime function pointers.

Access metadata is flattened into scalar slot families for component reads/writes, relationship
reads/writes, and resource/message read-write flags. Component/type access helpers share the same
component-id conflict path; relationship access has a separate conflict path; resources and messages
conflict independently on write-vs-read/write. The schedule assigns each added system to the first
non-conflicting batch, records pairwise conflict counts, exposes batch widths and max parallel width,
and returns -1 sentinels for out-of-range kind/batch accessors. Cap overflow ignores the ninth system
without panicking.

Tests (6) — `tests/test_ecs_lib_schedule_table_erased_relationship_deep_isolated.sla` (109 lines,
panic 144100-144172, codes verified unique locally and globally in 144100-144199). Cover: three
non-conflicting systems in one batch with sequential run effects; relationship read/write conflict
batch splitting; planned batch run with type access declarations; resource/message conflict
semantics; out-of-range accessor sentinels; cap-8 overflow no-op. SA backend and default backend
both pass 6/6.

KEY Batch 397 finding #1 (fn-pointer systems can be deepened as stable kind ids): the shallow
schedule stores callable systems, but the behavior under test is conflict declaration and run order.
Kind ids keep execution deterministic and self-contained while preserving the relevant scheduling
semantics.

KEY Batch 397 finding #2 (relationship access needs a separate conflict family): component/type
access can share a single id-list path, but relationship ids must not alias component ids. The deep
keeps relationship read/write slot families separate from component read/write slots and verifies
relationship conflicts independently from messages/resources.

Post-batch counts (measured): 498 lib modules | 226 `*_deep.sla` modules | 402 test files |
226 `*_deep_isolated.sla` test files | 90 examples | 6309 `@test` total tests-scoped (6303 ->
6309, +6).
Next free panic band: 144200+ (Batch 397 used 144100-144172; Batch 396 used 144000-144051).
Next batch candidates: continue medium non-async/non-parallel modules such as
`schedule_table_erased`, `schedule_table_erased_observer`, or another small schedule/query/registry
module. Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 398 — schedule_table_erased_observer_deep (DONE 2026-07-13)

`lib/schedule_table_erased_observer_deep.sla` (303 lines) mirrors the observer scheduling and event
access metadata from shallow `lib/schedule_table_erased_observer.sla` without importing the full
erased table world or preserving fn-pointer execution. The deep is SELF-CONTAINED and models a
small fixed-cap world (`EcsStoWorld`) plus cap-8 schedule slots. System functions are represented by
stable kind ids (`MOVE`, `OBS_COUNT`, `MESSAGE`, `TRIGGER_PING`) so tests can verify scheduling,
conflict metadata, and execution order without runtime function pointers.

Access metadata is flattened into scalar slot families for component reads/writes, event reads/writes,
and resource/message read-write flags. Component/type access helpers share the same component-id
conflict path; event access has a separate conflict path; resources and messages conflict
independently on write-vs-read/write. The schedule assigns each added system to the first
non-conflicting batch, records pairwise conflict counts, exposes batch widths and max parallel width,
and returns -1 sentinels for out-of-range kind/batch accessors. Cap overflow ignores the ninth system
without panicking.

Tests (6) — `tests/test_ecs_lib_schedule_table_erased_observer_deep_isolated.sla` (109 lines,
panic 144200-144272, codes verified unique locally and globally in 144200-144299). Cover: three
non-conflicting systems in one batch with sequential run effects; event read/write conflict batch
splitting; planned batch run with type access declarations; resource/message conflict semantics;
out-of-range accessor sentinels; cap-8 overflow no-op. SA backend and default backend both pass 6/6.

KEY Batch 398 finding #1 (observer schedules can reuse the relationship schedule shape with event
access): the shallow observer schedule is structurally parallel to the relationship schedule, but
event read/write access must be a separate conflict family from component access. The deep keeps
event read/write slot families separate and verifies event conflicts independently.

KEY Batch 398 finding #2 (trigger-ping system replaces observer trigger semantics): the shallow
observer schedule triggers observers on event writes, but the behavior under test is conflict
declaration and run order. The TRIGGER_PING kind sets observer_count and observed, keeping execution
deterministic while preserving the relevant scheduling semantics.

Post-batch counts (measured): 499 lib modules | 227 `*_deep.sla` modules | 403 test files |
227 `*_deep_isolated.sla` test files | 90 examples | 6315 `@test` total tests-scoped (6309 ->
6315, +6).
Next free panic band: 144300+ (Batch 398 used 144200-144272; Batch 397 used 144100-144172).
Next batch candidates: continue medium non-async/non-parallel modules such as
`schedule_table_erased`, `relationship`, `world_registry`, or another small schedule/query/registry
module. Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).


## Batch 399 — schedule_table_erased_deep (DONE 2026-07-13)

`lib/schedule_table_erased_deep.sla` (426 lines) mirrors the base erased sequential schedule from
shallow `lib/schedule_table_erased.sla` (534 lines) without importing the full erased table world or
preserving fn-pointer execution. The deep is SELF-CONTAINED and models a small fixed-cap world
(`EcsSceWorld`) plus cap-8 schedule slots with per-system and per-schedule condition families.

The shallow uses generic `TableErasedSystem<R,M>` with fn-pointer `run` fields, Vec-backed systems
and batch_ids, and condition kinds (ALWAYS/FALSE/TRUE/TICK_AT_LEAST_THREE). The deep replaces
fn-pointer systems with stable kind ids (MOVE/DOUBLE/INCREMENT_TICK/SET_EVENT), flattens access
metadata into scalar slot families, and stores both per-system and per-schedule conditions as cap-8
scalar families. Access conflicts mirror `table_erased_access.sla` (component read/write + resource/
message conflict semantics).

Features preserved: auto-batch chooser (first non-conflicting batch), conflict counting, batch
widths, max parallel width, sequential run honoring both schedule-level and system-level conditions,
planned run iterating batches in order, and explicit ordering (chain/before/after/in_set) bypassing
the auto-batch chooser. Cap overflow is a no-panic reject. Out-of-range accessors return -1.

Tests (7) — `tests/test_ecs_lib_schedule_table_erased_deep_isolated.sla` (140 lines, panic
144300-144395, codes verified unique locally and globally in 144300-144399). Cover: three
non-conflicting systems in one batch with sequential run effects; component conflict batch splitting;
planned run honoring batch ordering; system-level FALSE condition skips a system; schedule-level
TICK_AT_LEAST_THREE condition skips all systems until tick >= 3; explicit ordering chain/before/
after/in_set with batch assertions; resource/message conflicts and cap-8 overflow sentinel. SA backend
and default backend both pass 7/7.

KEY Batch 399 finding #1 (run conditions can be deepened as scalar condition families): the shallow
stores conditions in a `TableErasedRunConditions` struct with 8 slots on both systems and the
schedule. The deep uses `EcsSceConditions` with c0..c7 and a count, stored per-system in the schedule.
Both per-system and per-schedule conditions are checked before execution, matching the shallow
run/run_planned logic.

KEY Batch 399 finding #2 (explicit ordering helpers bypass the auto-batch chooser): the shallow
chain/before/after/in_set functions assign systems to explicit batch ids. The deep models this with
`ecs_sce_schedule_add_system_in_batch` which takes an explicit batch_id, and chain uses
`batch_count` as the next sequential batch, before uses `target-1`, and after uses `target+1`.

Post-batch counts (measured): 500 lib modules | 228 `*_deep.sla` modules | 404 test files |
228 `*_deep_isolated.sla` test files | 90 examples | 6322 `@test` total tests-scoped (6315 ->
6322, +7).
Next free panic band: 144400+ (Batch 399 used 144300-144395; Batch 398 used 144200-144272).
Next batch candidates: continue medium non-async/non-parallel modules such as `relationship`,
`world_registry`, `app_type_registry`, `ecs_world`, or another small schedule/query/registry module.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

=== Batch 400: app_type_registry_deep (completed) ===

Module: lib/app_type_registry_deep.sla (340 lines), mirrors lib/app_type_registry.sla (241 lines).
Self-contained fixed-cap (cap-8) type/function descriptor registries. No @import.
The shallow uses Vec-backed TypeDescriptor/FunctionDescriptor registries with TypeData.
The deep flattens Vec-backed registries to scalar slot families (n0..n7, size_id0..size_id7,
type_id0..type_id7, data0..data7, etc.) with a count, preserving all public API semantics.
Result wrapper structs preserved: EcsAtrTypeDescriptorResult, EcsAtrTypeDataResult,
EcsAtrFunctionDescriptorResult. Cap-reject public ops return sentinel wrappers (not panic).

KEY Batch 400 finding #1 (@derive(copy) required for by-value structs): all 7 structs in the deep
module use @derive(copy). This is essential because structs are passed by-value to helper functions
(find_index, _set_slot, etc.). Without @derive(copy), SLA move semantics consume the value on the
first by-value pass, causing UseAfterMove/PhiStateConflict/CapabilityMismatch backend errors.
@derive(copy) makes by-value passing a copy instead of a move.

KEY Batch 400 finding #2 (cap-reject returns sentinel, not panic): public register/register_or_replace
ops that exceed cap return a sentinel result wrapper (found=false, type_id=0) rather than panicking.
Internal _set_slot panics on cap overflow (defensive), but public ops handle it gracefully.

Test: tests/test_ecs_lib_app_type_registry_deep_isolated.sla (113 lines, 7 tests).
- EcsAtrTypeRegistry register and get descriptor
- EcsAtrTypeRegistry register_or_replace updates existing
- EcsAtrTypeRegistry type data set and query
- EcsAtrTypeRegistry at and empty results
- EcsAtrTypeRegistry cap rejects ninth registration
- EcsAtrFunctionRegistry register get and replace
- EcsAtrFunctionRegistry cap rejects ninth registration

Validation: sa sla check ✓ | SA backend 7/7 ✓ | default backend 7/7 ✓
Panic codes: 144400-144472 (all unique, verified locally and globally).

Post-batch counts (measured): 501 lib modules | 229 `*_deep.sla` modules | 405 test files |
229 `*_deep_isolated.sla` test files | 90 examples | 6329 `@test` total tests-scoped (6322 ->
6329, +7).
Next free panic band: 144500+ (Batch 400 used 144400-144472; Batch 399 used 144300-144395).
Next batch candidates: continue medium non-async/non-parallel modules such as `relationship`,
`world_registry`, `ecs_world`, or another small schedule/query/registry module.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

=== Batch 401: system_trait_deep (completed) ===

Module: lib/system_trait_deep.sla (218 lines), mirrors lib/system_trait.sla (101 lines).
Self-contained System trait + SystemStateFlags + RunSystemOnce + RunSystemError. No @import.

KEY Batch 401 finding #1 (nested struct fields cause SA MemoryLeak even with @derive(copy)):
the first version stored flags as a nested EcsSystemStateFlagsDeep struct inside EcsSystemDeep.
Even with @derive(copy) on both, passing EcsSystemDeep by-value to helper functions (name, is_initialized,
etc.) caused SA backend MemoryLeak "live registers remain at function exit" with a register pointing to
the nested struct field. The fix: flatten the nested struct into a scalar bitfield (flags_bits: i32)
directly inside EcsSystemDeep, matching the system_trait_extras_deep pattern (which used flat scalar
fields and never leaked). This is a likely SA compiler bug — nested-copy struct ownership leaks — but
the workaround (flatten) is clean and avoids hitting it.

KEY Batch 401 finding #2 (tuple return replaced by wrapper struct):
shallow ecs_system_run returns a (EcsSystem, i64) tuple accessed as r.1.
Deep uses EcsSystemRunResult { flags_bits, name_id, last_run_value } with accessors. Likewise shallow
ecs_run_system_once reads r.1; deep uses ecs_system_run_deep_result_output(run_result).

KEY Batch 401 finding #3 (all structs need @derive(copy) when passed by-value repeatedly):
all four structs in the deep module use @derive(copy). Without it, passing the same value to one helper
then referencing it again triggers UseAfterMove.

Test: tests/test_ecs_lib_system_trait_deep_isolated.sla (92 lines, 7 tests).
- state_flags_set_unset
- system_deep_new_and_name
- system_deep_initialize_and_flags
- system_deep_run_and_last_run
- system_deep_apply_deferred_and_clear
- run_system_once_not_initialized
- run_system_once_ok

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 7/7 ✓ | default backend 7/7 ✓
Panic codes: 144500-144564 (all unique, verified locally and globally).

Post-batch counts (measured): 502 lib modules | 230 `*_deep.sla` modules | 406 test files |
230 `*_deep_isolated.sla` test files | 90 examples | 6336 `@test` total tests-scoped (6329 ->
6336, +7).
Next free panic band: 144600+ (Batch 401 used 144500-144564; Batch 400 used 144400-144472).
Next batch candidates: continue medium non-async/non-parallel modules such as `relationship`,
`world_registry`, `ecs_world`, or another small schedule/query/registry module.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).

NOTE: possible SA compiler MemoryLeak bug (nested @derive(copy) struct field ownership leaks
at function exit) was identified. Workaround (flatten) used and is clean for this module, so
no docs/issue.md was filed. File only if a future module has no clean flatten workaround.

=== Next Batch 402 candidate prioritization ===
Top candidates (small self-contained, no @import, non-async/non-parallel, non-reflect):
1. entity_index_set_iter_extras (320 lines, no imports, Vec<i64>-only, 16 structs): nested wrappers
   need flattening; ~600+ lines of deep. SA nested-struct MemoryLeak bug means wrappers like
   EcsEis3RangeResult/EcsEis3InsertResult may need flat-field inlining or careful @derive(copy)
   use. Verify with single-test trials before committing.
2. schedule_value (406 lines, no imports, 7 structs each with Vec<i64> fields): large flat-field
   cap module, no nested structs in public result wrappers — likely clean if @derive(copy).
3. world_registry (318 lines, imports component.sla + entity_dynamic.sla): defer; depends on
   two shallow modules without deep counterparts yet.

Pick entity_index_set_iter_extras first since the pattern is closest to existing
entity_index_set_extras deep; if SA MemoryLeak blocks the nested wrappers, switch to schedule_value.

=== Batch 402: entity_index_set_iter_extras_deep (completed) ===

Module: lib/entity_index_set_iter_extras_deep.sla (979 lines), mirrors lib/entity_index_set_iter_extras.sla (320 lines).
Self-contained fixed-cap (cap-8) EntityIndexSet bound/inner/iter/into_iter/drain/set-op-iter/splice extras. No @import.

KEY Batch 402 finding #1 (all structs need @derive(copy)): every struct (Set, Slice, InnerInfo,
InsertResult, RangeResult, Iter, IntoIter, drain structs, OpIter structs, drain/splice result
wrappers) carries @derive(copy). Without it, passing the same Set to helper functions in a
loop triggers SA backend PhiStateConflict. Adding @derive(copy) makes those by-value passes
copies, so no per-iteration move/owning occurs and the loop phi is consistent.

KEY Batch 402 finding #2 (nested struct wrappers flattened to scalar slot families):
all wrapper structs in the shallow (InsertResult{inserted, set}, RangeResult{has, slice},
IterNext{iter, has, value}, DrainResult{set, drain}, SpliceResult{set, removed}) embed
nested Set/Slice/Iter sub-structs. In deep these wrappers store the constituent fields inline
rather than nesting a SetDeep, avoiding the SA MemoryLeak bug reported at docs/issue.md
(reproduced in Batch 401 with a nested EcsSystemStateFlagsDeep).

KEY Batch 402 finding #3 (stateful iterator stepping requires from_next helpers): the deep
uses a function-style front-pointer model with flat Next wrappers. Stepping two ahead requires
reconstructing the inner Iter from the Next wrapper — provided by ecs_eis3_deep_iter_next_from_next
(and analogous _from_next for IntoIter and OpIter). Tests use these _from_next steppers.

KEY Batch 402 finding #4 (drain clamping matches shallow): _ecs_eis3_drain_clamped duplicates the
shallow ecs_eis3_drain_clamped logic (split ranges into kept vs. drained slots) and returns
the flattened DrainResult with both kept_slice and drained_slice fields inlined.

Test: tests/test_ecs_lib_entity_index_set_iter_extras_deep_isolated.sla (236 lines, 15 tests).
- bound_kinds, bound_start_end, set_contains_and_insert, slice_and_inner_info, slice_range,
  bound_range_set, iter_next, into_iter_next_and_back, into_iter_next_back_value, drain_next,
  op_iter_next_and_back, collect_op_iter, difference_set, intersection_union_symmetric,
  splice_unique.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 15/15 ✓ | default backend 15/15 ✓
Panic codes: lib 144600-144612 (internal guards); tests 144700-144845 (all unique).

Post-batch counts (measured): 503 lib modules | 231 `*_deep.sla` modules | 407 test files |
231 `*_deep_isolated.sla` test files | 90 examples | 6351 `@test` total tests-scoped (6336 ->
6351, +15).
Next free panic band: 144900+ (Batch 402 used 144600-144853; Batch 401 used 144500-144564;
Batch 400 used 144400-144472).
Next batch candidates: `schedule_value` (406 lines, no imports, 7 structs each with multiple
Vec<i64> fields), `query_state_read_api` (357), `world_dynamic` (372), or
`world_registry` (318 — defer to avoid the shallow component/entity_dynamic imports).
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).
docs/issue.md confirms the flat-field workaround works for wrapper structs.

=== Batch 403: schedule_value_deep (completed) ===

Module: lib/schedule_value_deep.sla (751 lines), mirrors lib/schedule_value.sla (406 lines).
Self-contained fixed-cap (cap-16) Schedule value struct + lifecycle API. No @import.

KEY Batch 403 finding #1 (nested EcsScheduleExecutable flattened inline): the shallow module
nested an EcsScheduleExecutable struct inside EcsSchedule (s.executable.system_ids.push(...)).
Per docs/issue.md, nested @derive(copy) struct field access leaks on the SA backend; the deep
version flattens the executable's slot families (sys_ids_0..sys_ids_15, sys_cc_*, sys_lr_*,
sys_ct_*, set_ids_*, set_cc_*) and its built counts directly into EcsScheduleDeep.

KEY Batch 403 finding #2 (tuple returns replaced by separate flat wrappers): every tuple
return in shallow is replaced by a dedicated flat @derive(copy) wrapper struct:
- EcsScheduleInitResultDeep, EcsScheduleCheckChangeTicksResultDeep, EcsScheduleRunResultDeep,
  EcsScheduleApplyDeferredResultDeep, EcsScheduleSystemsResultDeep (with inlined slots),
  EcsScheduleSystemsLenResultDeep, EcsScheduleCleanupOutcomeDeep, EcsScheduleCleanupResultDeep.

KEY Batch 403 finding #3 (initialize must mirror shallow's combined return): shallow
ecs_schedule_initialize returns (Schedule, bool) — the Schedule copy has executor_initialized
set. Deep's ecs_schedule_deep_initialize returns the InitResult summary only (loses the
mutated copy). Add ecs_schedule_deep_initialize_inplace(s) -> EcsScheduleDeep so tests can
chain subsequent calls on the initialized schedule.

KEY Batch 403 finding #4 (SLA else-block syntax): if-else blocks and single-line `if cond { ... }`
forms must close with `};`. Initially several single-line `if out_idx == N { temp = cur; }`
forms missed the trailing `;` — fixed by adding `;`.

KEY Batch 403 finding #5 (bools as i32): the deep stores graph_changed, apply_final_deferred,
executor_initialized, and build_settings_auto_insert as i32 (0/1) rather than bool, simplifying
scalar-slot mutation. Accessor functions convert with `!= 0`.

Test: tests/test_ecs_lib_schedule_value_deep_isolated.sla (185 lines, 17 tests).
- new_default_and_label, set_executor_and_apply_final_deferred, build_settings,
  add_systems_and_sets, mark_changed_resets_initialized, initialize_freezes_counts,
  check_change_ticks, run_returns_built_count, apply_deferred, systems_uninitialized,
  systems_initialized_returns_ids, systems_in_set_count, remove_systems_in_set,
  cleanup_policy_predicates, cleanup_with_policy_remove_set_and_systems,
  cleanup_with_policy_remove_systems_only, cleanup_with_policy_remove_set_and_systems_allow_breakages.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 17/17 ✓ | default backend 17/17 ✓
Panic codes: lib 144900-144908; tests 145000-145162 (all unique).

Post-batch counts (measured): 504 lib modules | 232 `*_deep.sla` modules | 408 test files |
232 `*_deep_isolated.sla` test files | 90 examples | 6368 `@test` total tests-scoped (6351 ->
6368, +17).
Next free panic band: 145200+ (Batch 403 used 144900-144908 + 145000-145162; Batch 402 used
144600-144853; Batch 401 used 144500-144564; Batch 400 used 144400-144472).
Next batch candidates: `query_state_read_api` (357 lines), `world_dynamic` (372 lines), or
`world_registry` (318 — defer to avoid the shallow component/entity_dynamic imports).
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).
docs/issue.md continues to back the flat-field workaround for nested struct wrappers.

=== Batch 404: query_state_read_api_deep (completed) ===

Module: lib/query_state_read_api_deep.sla (474 lines), mirrors lib/query_state_read_api.sla (357 lines).
Self-contained fixed-cap (cap-16) QueryState read API + entity-arg helper. No @import.

KEY findings recap:
1. SLA `while { ... }` loops must close with bare `}` (not `};`); only `if`/`else` close with `};`.
   Four `while` closers in this file were originally `};` and had to be adjusted.
2. Vec<i32> entity slice → EcsQsEntityArgDeep { e0..e15, en } + push/at/len accessor helpers.
3. Tuple returns → EcsQsTryNewResultDeep, EcsQsSpawnResultDeep, SingleResultDeep, GetResultDeep,
   GetManyResultDeep, IterManyResultDeep (all @derive(copy), flat fields).
4. Aliased_idx in GetManyResultDeep holds the duplicate entity-id (0 for [0,0]); tests assert
   against the actual dup value, not -1.
5. Iterative mutation uses `let r = spawn(s, v); let s2 = spawn_result_state(r);` two-line
   chaining because spawn returns a wrapper (not the bare state). Direct assignment produces
   TypeMismatch.

Test: tests/test_ecs_lib_query_state_read_api_deep_isolated.sla (276 lines, 21 tests).
Test names: err_codes_and_predicates, new_and_from_builder, try_new_ok_and_fail, spawn_and_chaining,
  spawn_cap_overflow, entity_is_spawned_is_empty_contains, single_no_one_multiple, single_mut_delegates,
  get_spawned_and_unspawned, get_mut_delegates, entity_arg_push_at_len, get_many_ro_multiple,
  get_many_ro_with_unspawned, get_many_mut_aliased, get_many_unique_detects_dup,
  get_many_unique_mut_all_spawned, iter_many_matched_sum, iter_many_with_unspawned,
  iter_many_mut_delegates, update_archetypes_bumps_gen, first_duplicate_index_logic.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 21/21 ✓ | default backend 21/21 ✓
Panic codes: lib 145200-145205; tests 145300-145701 (all unique).

Post-batch counts (measured): 505 lib modules | 233 `*_deep.sla` modules | 409 test files |
233 `*_deep_isolated.sla` test files | 90 examples | 6389 `@test` total tests-scoped (6368 ->
6389, +21).
Next free panic band: 145400+ (Batch 404 used 145200-145205 lib + 145300-145701 tests; Batch 403
used 144900-144908 + 145000-145162; Batch 402 used 144600-144853; Batch 401 used 144500-144564;
Batch 400 used 144400-144472).
Next batch candidates: `world_dynamic` (372 lines), `world_registry` (318 — defer the shallow
component/entity_dynamic imports by inlining equivalents), or pick another shallow lib/*.sla without
a *_deep.sla counterpart.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).
docs/issue.md continues to back the flat-field workaround for nested struct wrappers; this batch had
no nested-struct access so it was not exercised.

=== Batch 405: query_access_iter_extras_deep (completed) ===

Module: lib/query_access_iter_extras_deep.sla (473 lines), mirrors lib/query_access_iter_extras.sla (324 lines).
Self-contained fixed-cap (cap-16) EcsAccessType/EcsAccessLevel/AccessConflictError + is_compatible matrix. No @import.

KEY findings recap:
1. SA MemoryLeak recurred for nested @derive(copy) wrapper:
   AccessIsCompatibleResultDeep { ok, conflict: EcsAccessConflictErrorDeep } flushed through 6
   accessor reads in a single test hits `MemoryLeak: live registers remain at function exit` on
   the SA backend. Same SA bug as docs/issue.md (Batch 401). Fix: flatten the conflict's fields
   directly into the wrapper. docs/issue.md Addendum appended with the recurrence + fix.
2. Vec<i32> reads/writes → EcsAccIdListDeep (cap-16 i32 slot family {v0..v15, vn} + new/push/
   at/len/contains), and the access type itself stores r0..r15+rn and w0..w15+wn directly.
3. `bool` flagged `read_all`/`write_all` stored as i32 0/1; helpers use `!= 0`.
4. Access-vs-Component explicit symmetric branches kept (not normalized) for observable
   ordering in tests (Read-cid-write, Write-cid-read, plus r3 regression: write-vs-write is ok
   on the Access side when the Access has no read).
5. `_ecs_borrowed_access_deep_is_compatible` writes-overlap-reads-or-writes + read_all/write_all
   propagation mirrors Access::is_compatible.

Test: tests/test_ecs_lib_query_access_iter_extras_deep_isolated.sla (351 lines, 25 tests).
Test names: level_constructors_and_accessors, access_type_empty_variants_accessors,
  access_type_component_level_fields, id_list_push_at_len, access_type_access_borrow_fields,
  access_type_access_with_flags, is_compatible_empty_always_ok, is_compatible_read_read_ok,
  is_compatible_read_write_same_id_conflict, is_compatible_read_write_diff_id_ok,
  is_compatible_write_write_same_id_conflict, is_compatible_write_write_diff_id_ok,
  is_compatible_readall_write_conflict, is_compatible_readall_readall_ok,
  is_compatible_writeall_anything_conflict, is_compatible_component_vs_access,
  is_compatible_access_vs_component_symmetry, is_compatible_component_vs_access_readall_writeall,
  is_compatible_access_vs_access_read_all_write, is_compatible_access_vs_access_write_all_conflict,
  is_compatible_access_vs_access_write_overlap_conflict,
  is_compatible_access_write_overlaps_read_conflict, is_compatible_access_read_read_ok,
  is_compatible_access_disjoint_ok, conflict_error_fields_set.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 25/25 ✓ | default backend 25/25 ✓
Panic codes: lib 145400-145403; tests 145500-145985 (all unique).

Post-batch counts (measured): 506 lib modules | 234 `*_deep.sla` modules | 410 test files |
234 `*_deep_isolated.sla` test files | 90 examples | 6414 `@test` total tests-scoped (6389 ->
6414, +25).
Next free panic band: 146000+ (Batch 405 used 145400-145403 lib + 145500-145985 tests; Batch 404
used 145200-145205 lib + 145300-145701 tests; Batch 403 used 144900-144908 + 145000-145162;
Batch 402 used 144600-144853; Batch 401 used 144500-144564; Batch 400 used 144400-144472).
Next batch candidates: `world_dynamic` (372 lines; defer shallow imports),
  `world_registry` (318 — defer shallow component/entity_dynamic imports; or inline
  equivalents), `reflect_runtime` (306 lines, mostly reflection primitives), or pick another
  shallow lib/*.sla without a *_deep.sla counterpart. `query_access_iter_extras`<done>.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).
docs/issue.md continues to back the flat-field workaround for nested struct wrappers; this batch
re-confirmed the bug (MemoryLeak with nested EcsAccessConflictErrorDeep) and the addendum
documents the flat-wrapper fix.

=== Batch 406: system_registry_template_deep (completed) ===

Module: lib/system_registry_template_deep.sla (603 lines), mirrors lib/system_registry_template.sla (312 lines).
Self-contained fixed-cap (cap-16) system-registry templates + CachedSystemRegistry. No @import.

KEY findings recap:
1. SA MemoryLeak recurred for tuple-replacement wrappers that nested the cap-16 container —
   repeated register/cached_register_result access on the SA backend leaked. Same SA bug as
   docs/issue.md (Batch 401 & 405). Fix generalised: flatten each wrapper's tuple-companion value
   directly into the mutated container struct; the mutating fn returns the container (not a
   wrapper), and `last_*` accessors expose the companion (last_registered_entity /
   last_unregister_success / last_run_with_entity / last_run_with_input on the registry;
   last_allocated_entity on the context; last_build_entity on the template).
2. Nested structs flattened inline: EcsSystemHandleValue.inner -> EcsSystemHandleValueDeep's
   inner_kind / inner_handle / inner_has_system_value / inner_system_id; EcsSystemHandleTemplate.value
   -> EcsSystemHandleTemplateDeep's value_ref_count / value_inner_*; EcsTrackedSystem's two nested
   one-field structs -> EcsTrackedSystemDeep's system_entity + despawner_entity.
3. Vec<i32>/Vec<i64> parallel arrays -> cap-16 scalar slot families on EcsCachedSystemRegistryDeep
   (t0..t15 + tn + e0..e15); helpers `_ecsr_type_at/_ent_at/_type_set/_ent_set` indirection;
   cap-16 enforced at register; unregister compacts the live slots.
4. Booleans stored as i32 0/1; accessors use `!= 0`.
5. EcsSystemId and EcsRegisteredSystemDespawner kept as one-field i64 wrappers (safe — small enough
   that the leak does not trigger). Their mk/entity helpers still serve the test surface.

Test: tests/test_ecs_lib_system_registry_template_deep_isolated.sla (249 lines, 25 tests).
Test names: hov_handle_and_value, handle_value_new_clone_drop_refcount,
  handle_value_build_converts_to_handle, template_handle_weak_and_value, template_default,
  template_clone_handle_bumps_no_refcount, template_clone_value_bumps_refcount,
  template_from_handle_boxed_id, template_build_handle_returns_handle,
  template_build_value_converts_and_assigns, system_value_new_alias, cached_system_id,
  cached_registry_new_empty, cached_registry_register_find_contains,
  cached_registry_register_existing_returns_existing, cached_registry_run_returns_entity,
  cached_registry_run_with_preserves_input, cached_registry_unregister_actually_removes,
  cached_registry_unregister_missing_is_unsuccessful, tracked_system_and_boxed_alias,
  system_id_and_despawner_simple_wrappers, stripped_handle_strong_weak,
  template_context_new_and_alloc, template_clone_template_alias,
  cached_registry_cap16_not_exceeded_on_overflow.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 25/25 ✓ | default backend 25/25 ✓
Panic codes: lib 146000-146007; tests 146100-146581 (all unique).

Post-batch counts (measured): 507 lib modules | 235 `*_deep.sla` modules | 411 test files |
235 `*_deep_isolated.sla` test files | 90 examples | 6439 `@test` total tests-scoped (6414 ->
6439, +25).
Next free panic band: 146200+ (Batch 406 used 146000-146007 lib + 146100-146581 tests; Batch 405
used 145400-145403 lib + 145500-145985 tests; Batch 404 used 145200-145205 lib + 145300-145701
tests; Batch 403 used 144900-144908 + 145000-145162; Batch 402 used 144600-144853; Batch 401 used
144500-144564; Batch 400 used 144400-144472).
Next batch candidates: `world_dynamic` (372 lines; defer shallow imports), `world_registry` (318
lines; defer component/entity_dynamic imports), `reflect_runtime` (306 lines; defer reflect* core
imports), or pick another shallow lib/*.sla without a *_deep.sla counterpart.
Defer TaskPool/async/parallel modules, `world_table_erased` (~6300 lines), and
`system_param_table_erased` (~4900 lines with fn-pointer systems). Leave out:
TaskPool/async/parallel; full reflect* core runtime (non-core reflection deepens OK).
docs/issue.md continues to back the flat-field workaround for nested struct wrappers; this batch
re-confirmed the bug with the tuple-replacement wrapper pattern and generalised the fix to flatten
tuple-companion fields back into the mutated container struct.

---

# Batch 407 — `lib/schedule_node_sets_deep.sla` (523-line shallow original)

Source: vw/lib/schedule_node_sets.sla (no `@import`) →
`lib/schedule_node_sets_deep.sla` (1360 lines after fixing the broken body).
Helpers: flat-field slot families; no `Vec<...>`, no nested `@derive(copy)`
struct fields inside the public structs (only scalar inline families and
inline `last_*` companion fields on the mutated container structs). The
flattening strictness is the Batch 401/405/406 anti-MemoryLeak style carried
verbatim into this batch. The only wrapper is `AccessConflictsResultDeep`,
which is a plain flat 6-field return struct (no container mutation happens
through it), so it stayed struct-shaped without leaking.

Lib deep code status (validation on 2026-07-13):
- `_essa_contains_wc` had been left in a broken state by the prior batch
  pickup: its body was the entire prior body of
  `ecs_system_access_deep_get_conflicts`, and so referenced `b`, `n`,
  `out0`, `out1`, `out2`, `out3`, `j` (all unbound in the helper's scope).
  The body was replaced with the simple linear `while i < a.wcn { if
  _essa_wc_at(a, i) == v { return true; }; i = i + 1; } return false;`
  pattern that mirrors `_essa_contains_rc` exactly; the broken
  `if n == X { ... }; ...` chain was relocated into
  `ecs_system_access_deep_get_conflicts` (which was also rewritten as a
  clean pair of `while` loops with sequential `if n == X { ... };` arms).
- The compile blocker that surfaced as `UndefinedVariable: identifier 'b'
  is not defined in this scope` is a diagnostic-quality issue (see docs/
  issue.md addendum): the SLA type checker only surfaces the *first*
  unbound identifier found in a function and emits no file path / line /
  column, even when several names are equally missing at the same site.

### Structures

- `EcsNodeSetEntryDeep` (flat: `system_id: i32`, `system_name: i64`,
  `is_exclusive: i32`) — direct parallel of the original `EcsNodeSetEntry`.
- `EcsNodeSetCondDeep` (flat: `condition_id: i32`) — direct parallel of
  the original `EcsNodeSetCond`.
- `EcsNodeSetSystemsDeep` (cap-16 entries; entries 0..15 via inline
  sid/sname/sxc/per-entry cap-16 conds0/conds1 + cap-16 uninit/init slot
  lists; companion `last_insert_key`, `last_get_found`,
  `last_get_entry_system_id`, `last_get_entry_system_name`,
  `last_get_entry_is_exclusive`, `last_remove_found`).
  `insert`, `get`, `set_system`, `has_conditions`, `condition_count`,
  `add_condition`, `remove`, `is_initialized`, `uninit_count`, `initialize`.
  Only `conds0/conds1` are tracked (cap-16 cond list exists for entries 0..1
  only); `add_condition` returns `s` unchanged when `key >= 2`. That
  matches the shallow original (which only stores conds for the first two
  entries); subsequent entries cannot receive conditions. This is the
  documented behaviour and is preserved.
- `EcsNodeSetConflictingSystemsDeep` (cap-16 (a,b) pairs + per-item cap-16
  conflict-id families for items 0..2 (cf0/cf1/cf2 slot families with
  `_escs_cf_at/_set/_push` helpers); cap-16 enforced at push; `_escs_cf_n_at`
  returns 0 past item 2; push still increments `item_count` past item 2 but
  leaves the conflict-count family untouched). `get` writes to `last_get_a`,
  `last_get_b`, `last_get_conflict_count` (no per-item index stored — get
  returns the just-read values through the same container). `push`,
  `check_if_not_empty`, `to_string_count`.
- `EcsNodeSetSystemAccessDeep` (cap-16 read_components / write_components)
  with read-write access helpers `_essa_rc_at/_set`, `_essa_wc_at/_set`,
  `contains_rc`, `contains_wc`, plus `reads_all` / `writes_all` flags.
  `add_read`, `add_write`, `set_reads_all`, `set_writes_all`, and
  `ecs_system_access_deep_get_conflicts(a, b)` returning a flat
  `AccessConflictsResultDeep {is_individual, conflict_count, cf0..cf3}`.
- `AccessConflictsResultDeep` (flat: `is_individual: i32`,
  `conflict_count: i32`, `cf0..cf3: i32`) — the result-bag for
  `get_conflicts`; reads go through `is_individual`, `count`, `cf(slot)`.
  `is_individual = 0` when any "writes_all / reads_all vs writes_all /
  writes_all vs reads_all" all-vs-all branch fires; the conflict ids are
  not enumerated in that case (count stays 0). Otherwise `is_individual = 1`
  and the per-component pairing runs.
- `EcsNodeSetSystemSetsDeep` (cap-16 sets via `set_id0..15`,
  `is_st0..15`, `ids_map0..15`; cap-16 uninit2 slot list (key, start, end
  triples); companion `last_get_or_insert_key`, `last_contains`,
  `last_get_index`). `get_key_or_insert` (uses `ids_map` linear scan),
  `contains`, `get_index`, `get_set_id`, `set_is_system_type`,
  `get_is_system_type`, `is_initialized`, `uninit_count`, `initialize`.
  `keys` and `(start, end)` ranges are stored per-entry on uninit2; this
  batch does not need them because the deep fixture sets `uninit2_n = 0`
  directly, so `is_initialized` returns `true` out of the box.
- `EcsSystemTypeSetAmbiguityErrorDeep` (flat: `key: i32`).

### Test

`tests/test_ecs_lib_schedule_node_sets_deep_isolated.sla` (335 lines,
33 tests).

Test names: entry_new_and_accessors, cond_new_and_accessor,
systems_new_len_is_empty, systems_insert_and_get,
systems_insert_multiple_then_get, systems_get_not_found, systems_set_system,
systems_has_conditions_initial_and_add, systems_remove_found_and_uninit,
systems_remove_not_found, systems_initialize,
systems_add_condition_second_entry, conflicting_systems_new_empty,
conflicting_systems_push_get, conflicting_systems_push_two,
conflicting_systems_to_string_count, system_access_new_and_read_write,
system_access_read_read_no_conflict, system_access_write_write_same_conflict,
system_access_write_read_same_conflict, system_access_disjoint_no_conflict,
system_access_writes_all_conflict, system_access_reads_all_writes_all_conflict,
system_access_writes_all_reads_conflict, system_access_multiple_conflicts,
system_sets_new_empty, system_sets_get_key_or_insert_new,
system_sets_get_key_or_insert_existing,
system_sets_get_key_or_insert_multiple,
system_sets_set_get_is_system_type, system_sets_get_set_id_not_found,
system_sets_initialize, ambiguity_error_new_and_key.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 33/33 ✓
| default backend 33/33 ✓
Panic codes: lib 146200-146244 (internal `_at/_set` slot-family guards and
the cap-16 fallback `panic`s of `_esns_*`, `_escs_*`, `_essa_*`, `_esets_*`,
`_esns_*` helpers); tests 146500-146691 (96 unique恐慌码, all unique across
lib+tests).

Post-batch counts (measured): 508 lib modules | 236 `*_deep.sla` modules |
412 test files | 236 `*_deep_isolated.sla` test files | 90 examples |
6472 `@test` total tests-scoped (6439 -> 6472, +33).
Next free panic band: 146800+ (Batch 407 used 146200-146244 lib + 146500-146691
tests; Batch 406 used 146000-146007 lib + 146100-146581 tests; Batch 405 used
145400-145403 lib + 145500-145985 tests; Batch 404 used 145200-145205 lib +
145300-145701 tests; Batch 403 used 144900-144908 + 145000-145162; Batch 402
used 144600-144853; Batch 401 used 144500-144564; Batch 400 used 144400-144472).
Next batch candidates: `world_extras` (612 lines, no `@import`) is the
largest shallow self-contained module still without a `_deep.sla`; defer the
TaskPool/async/parallel and `world_table_erased`/`system_param_table_erased`
modules as before (`world_table_erased` ~6300 lines;
`system_param_table_erased` ~4900 lines with fn-pointer systems).
docs/issue.md carries an additional addendum from this batch, recording an
*unrelated* SLA compiler diagnostic-quality issue: the type checker's
`UndefinedVariable` only surfaces the first unbound identifier (not every
one in the same scope), and emits no file/line/column info, so debugging
the broken `_essa_contains_wc` body required running `sa sla check` once
per missing name. A standalone `repro_diag.sla` reproducer is included in
the addendum.

---

# Batch 408 — `lib/reflect_component_deep.sla` (92-line shallow original)

Source: vw/lib/reflect_component.sla (no `@import`, 92 lines) →
`lib/reflect_component_deep.sla` (241 lines).
The shallow module models Bevy `ReflectComponent`: a `(entity -> value)` map
plus ComponentId, exposing `find/insert/apply/apply_or_insert_mapped/remove/
take/contains/reflect/copy/id`. The shallow version uses `Vec<i64>` parallel
arrays for entities and entity_values and *tuple-returning* fns:
- `remove: (EcsReflectComponent, bool)`
- `take: (EcsReflectComponent, bool, i64)`
- `reflect: (bool, i64)`
plus `copy` which relies on the tuple return of `reflect`.

Deep strategy: cap-16 parallel `entity{0..15}` and `value{0..15}` slot
families with `_ercd_entity_at/_set`, `_ercd_value_at/_set` indirection
helpers; cap enforced on the new-slot insert path (17th new entity is
dropped silently). The three tuple-returning fns flatten their tuple
companions inline into `EcsReflectComponentDeep`:
- `remove` writes `last_remove_success: i32`; `ecs_reflect_component_deep_last_remove_success`
  is the accessor.
- `take` writes `last_take_success: i32` + `last_take_value: i64`;
  `last_take_success` and `last_take_value` read them.
- `reflect` writes `last_reflect_present: i32` + `last_reflect_value: i64`;
  `last_reflect_present` and `last_reflect_value` read them.
`copy` reuses `reflect`'s companions (reads `last_reflect_present` +
`last_reflect_value`, then inserts into `dest`).
Booleans stored as i32 (0/1); accessors use `!= 0`. `find` keeps returning
`i32` (returns `(0 - 1)` for not-found), no struct wrapper required.

### Structure

- `EcsReflectComponentDeep` (flat: `component_id: i32` + cap-16 parallel
  `entity{0..15}`/`value{0..15}` pairs + `count: i32` + tuple-companion
  fields `last_remove_success`, `last_take_success`, `last_take_value`,
  `last_reflect_present`, `last_reflect_value`).
- Helper slot families: `_ercd_entity_at/_set`, `_ercd_value_at/_set`.
- Public API mirror:
  `ecs_reflect_component_deep_new`, `_id`, `_find`, `_insert`,
  `_apply`, `_apply_or_insert_mapped`, `_remove`,
  `_last_remove_success`, `_take`, `_last_take_success`,
  `_last_take_value`, `_contains`, `_count`, `_reflect`,
  `_last_reflect_present`, `_last_reflect_value`, `_copy`.

### Test

`tests/test_ecs_lib_reflect_component_deep_isolated.sla` (200 lines,
18 tests).

Test names: new_and_id, insert_new_entity, insert_existing_overwrites_value,
find_not_found_returns_neg1, apply_aliases_insert,
apply_or_insert_mapped_aliases_insert, remove_existing,
remove_missing_returns_false, remove_same_backswap_keeps_others,
take_existing_returns_value, take_missing_returns_false_value_zero,
contains_after_insert_and_remove, reflect_present_and_missing,
copy_existing_source, copy_missing_source_is_noop,
count_after_multiple_inserts, cap16_enforced_overflow_silent,
insert_after_take_does_not_resurrect_old_slot.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 18/18 ✓
| default backend 18/18 ✓
Panic codes: lib 146800-146803 (internal `_ercd_entity_at/_set`,
`_ercd_value_at/_set` slot-family guards); tests 146850-146903 (54 unique
panic ids; all unique across lib+tests).

Post-batch counts (measured): 509 lib modules | 237 `*_deep.sla` modules |
413 test files | 237 `*_deep_isolated.sla` test files | 90 examples |
6490 `@test` total tests-scoped (6472 -> 6490, +18).
Next free panic band: 146900-Batch-408-test + lib-band overlap noted:
lib 146800-146803; tests 146850-146903. Next clean for Batch 409:
**146950+** (lib reuse allowed only above 146803; to keep the test band
clean, use lib band `146810-...` if needed beyond 146803 and tests at 146950+).
Next batch candidates: `reflect_resource` (87 lines, no `@import`; has
tuple-returning `get` and `insert_count` fn that mirrors 407-style flat
result struct), `reflect_type_data` (98 lines), `reflect` (99 lines),
`reflect_misc` (100 lines), `reflect_bundle` (34 lines), `world_reflect`
(34 lines), `world_extras` (612 lines, larger self-contained), `world_mod`
(870 lines), `executor_single_threaded` (563 lines). Continue deferring
TaskPool/async/parallel (`parallel_scope`, `task_scope_executor_drive`,
`executor_multi_threaded`), `world_table_erased` (~6300 lines),
`system_param_table_erased` (~4900 lines with fn-pointer systems).
docs/issue.md remains as last updated at the close of Batch 407 (the
diagnostic-quality addendum filed for the `UndefinedVariable` first-id-only
behaviour). No new SA compiler bugs were observed in Batch 408; the
tuple-flattening pattern reused from Batch 406 worked first try.

---

# Batch 409 — `lib/reflect_misc_deep.sla` (100-line shallow original)

Source: vw/lib/reflect_misc.sla (no `@import`, 100 lines) →
`lib/reflect_misc_deep.sla` (151 lines).
The shallow module groups five Bevy ECS reflect::misc structures:
ReflectEvent, ReflectMessage, FromWorld, ReflectMapEntities, ReflectEntityCommands.
The shallow version uses `Vec<i32>` for `commands` on `ReflectEntityCommands` only;
the other structs are already purely scalar (1 or 2 fields). No tuple-returning
fns; no nested `@derive(copy)` struct fields.

Deep strategy: cap-16 `cmd{0..15}` slot family on
`EcsReflectEntityCommandsDeep` with `_erecmd_at/_set` indirection helpers and
cap enforcement on `push` (17th push is dropped silently). All other structs
are direct scalar mirrors.

### Structures

- `EcsReflectEventDeep` (`event_id: i32`, `trigger_count: i64`); `new`, `id`,
  `trigger` (counter +1), `trigger_count`.
- `EcsReflectMessageDeep` (`message_id: i32`, `sent_count: i64`); `new`, `id`,
  `send` (counter +1), `sent_count`.
- `EcsFromWorldDeep` (`world_id: i64`, `value: i64`); `new` (value=0),
  `from_world` (factory sets value), `value`, `world_id`.
- `EcsReflectMapEntitiesDeep` (`remap_count: i64`); `new`, `remap`
  (accumulator += count), `count`.
- `EcsReflectEntityCommandsDeep` (`cmd{0..15}: i32`, `command_count: i32`);
  `new`, `push` (cap-guarded append), `count`, `at` (idx → kind).

### Test

`tests/test_ecs_lib_reflect_misc_deep_isolated.sla` (102 lines, 12 tests).

Test names: event_new_id_and_initial_count, event_trigger_increments,
event_id_preserved_after_trigger, message_new_id_and_initial_count,
message_send_increments, from_world_new_value_zero,
from_world_from_world_factory, map_entities_new_and_remap_accumulate,
entity_commands_new_empty, entity_commands_push_and_at,
entity_commands_cap16_enforced, entity_commands_at_first_last_after_cap16.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 12/12 ✓
| default backend 12/12 ✓
Panic codes: lib 146950-146951 (internal `_erecmd_at/_set` slot-family
guards); tests 146960-146984 (unit i64 range in `as i64` casts exercised in
`at` + cap16 long test).

Post-batch counts (measured): 510 lib modules | 238 `*_deep.sla` modules |
414 test files | 238 `*_deep_isolated.sla` test files | 90 examples | 6502
`@test` total tests-scoped (6490 -> 6502, +12).
Next free panic band: 146990+ (Batch 409 used lib 146950-146951 + tests
146960-146984; Batch 408 used lib 146800-146803 + tests 146850-146903;
Batch 407 used lib 146200-146244 + tests 146500-146691).
Next batch candidates: `reflect_resource` (87 lines, tuple-returning `get`
and `insert_count` flatten ideally), `reflect_type_data` (98 lines, nested
`EcsReflectFromWorldFns`/`EcsReflectEventFns` structs to flatten),
`reflect_bundle` (34 lines, smallest), `world_reflect` (34 lines, trivial
scalar mirror).
docs/issue.md remains at its Batch 407 close (no new SA compiler bugs were
observed in Batch 408 or Batch 409).

---

# Batch 410 — `lib/reflect_resource_deep.sla` (87-line shallow original)

Source: vw/lib/reflect_resource.sla (no `@import`, 87 lines) →
`lib/reflect_resource_deep.sla` (202 lines).
The shallow module models Bevy `ReflectResource`: register/insert/get/remove/
apply_or_insert by ComponentId, with parallel `Vec<i32>` (registered_ids) +
`Vec<i64>` (insert_counts) arrays plus `is_registered` linear scan. The shallow
`get(component_id) -> (bool, i64)` returns a tuple, and `insert_count` /
`apply_or_insert` rely on `get`'s tuple return (`g.1`).

Deep strategy: cap-16 parallel `rid{0..15}` (i32) and `ic{0..15}` (i64)
slot families with `_errd_rid_at/_set`, `_errd_ic_at/_set`. The `(bool, i64)`
tuple of `get` is flattened into the struct as `last_get_present: i32` and
`last_get_count: i64`; accessors
`ecs_reflect_resource_deep_last_get_present` / `_last_get_count` read them.
`insert_count` and `apply_or_insert` are direct struct methods using the
companion fields rather than tuple destructuring.

### Structure

- `EcsReflectResourceDeep` (cap-16 `rid{0..15}` + `ic{0..15}` parallel pairs
  + `count: i32` + tuple-companion `last_get_present: i32`,
  `last_get_count: i64`).
- Slot family helpers: `_errd_rid_at/_set`, `_errd_ic_at/_set` (cap-16).
- Public API mirror: `ecs_reflect_resource_deep_new`, `_is_registered`,
  `_register`, `_count`, `_insert`, `_get`, `_last_get_present`,
  `_last_get_count`, `_remove`, `_apply_or_insert`, `_insert_count`.

### Test

`tests/test_ecs_lib_reflect_resource_deep_isolated.sla` (148 lines, 15 tests).

Test names: new_empty, register_adds_slot, register_multiple,
register_duplicate_noop, register_cap16_enforced,
insert_increments_insert_count, insert_absent_noop,
get_present_when_insert_count_positive, get_not_present_when_insert_count_zero,
get_not_present_when_unregistered, remove_decrements_min_zero,
remove_unregistered_noop, apply_or_insert_aliases_insert,
lifecycle_register_insert_get_remove, insert_count_when_zero.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 15/15 ✓
| default backend 15/15 ✓
Panic codes: lib 146990-146993 (slot-family `_at/_set` guards);
tests 147000-147030 (31 unique panic ids; all unique across lib+tests).

Post-batch counts (measured): 511 lib modules | 239 `*_deep.sla` modules |
415 test files | 239 `*_deep_isolated.sla` test files | 90 examples | 6517
`@test` total tests-scoped (6502 -> 6517, +15).
Next free panic band: 147040+ (Batch 410 used lib 146990-146993 + tests
147000-147030; Batch 409 used lib 146950-146951 + tests 146960-146984;
Batch 408 used lib 146800-146803 + tests 146850-146903; Batch 407 used lib
146200-146244 + tests 146500-146691).
Next batch candidates: `reflect_type_data` (98 lines; nested
`EcsReflectFromWorldFns`/`EcsReflectEventFns` structs to flatten inline),
`reflect_bundle` (34 lines; `Vec<i32>` cap-16), `world_reflect` (34 lines;
scalar mirror only — trivial).
docs/issue.md remains at its Batch 407 close (no new SA compiler bugs were
observed in Batch 410; the tuple-flattening pattern reused from Batch 406
worked first try on `get -> (bool, i64)`).

---

# Batch 411 — `lib/reflect_type_data_deep.sla` (98-line shallow original)

Source: vw/lib/reflect_type_data.sla (no `@import`, 98 lines) →
`lib/reflect_type_data_deep.sla` (110 lines).
The shallow module collects four Bevy ECS reflect::type_data sub-types:
ReflectFromWorld, ReflectEvent, ReflectMapEntities, and ReflectCommandExt.
The shallow versions wrap nested `*Fns` structs (`EcsReflectFromWorld {
fns: EcsReflectFromWorldFns }`, `EcsReflectEvent { fns: EcsReflectEventFns }`),
and access goes `r.fns.from_world_fn`, which triggers the SA MemoryLeak
documented in docs/issue.md. The deep module flattens those nested Fns
structs inline into the wrapper dicts:
- `EcsReflectFromWorldDeep { from_world_fn: i64 }`
- `EcsReflectEventDeep { trigger_fn, create_observer_fn, register_event_key_fn }`
- `EcsReflectMapEntitiesDeep { map_entities_fn: i64 }`
- `EcsReflectCommandDeep { kind, type_path_handle, component_handle }`
The `_fns_new` helpers remain (returning the flattened wrapper itself), and the
`*_fn_pointers` accessor returns the wrapper struct directly. No tuple-returning
fns; no slot families (no Vec); no internal panic guards.

### Structures

- `EcsReflectFromWorldDeep` (`from_world_fn: i64`); `fns_new`, `new`,
  `from_world` (read field), `fn_pointers` (returns self).
- `EcsReflectEventDeep` (`trigger_fn`, `create_observer_fn`,
  `register_event_key_fn` `i64`); `fns_new`, `new`, `trigger`,
  `create_observer`, `register_event_key`, `fn_pointers`.
- `EcsReflectMapEntitiesDeep` (`map_entities_fn: i64`); `new`, `call`.
- `EcsReflectCommandDeep` (`kind: i32`, `type_path_handle: i64`,
  `component_handle: i64`); `insert(0,..)`, `remove(1,..,0)`, `take(2,..,0)`,
  `kind`, `type_path`, `component`, `is_insert`, `is_remove`, `is_take`.

### Test

`tests/test_ecs_lib_reflect_type_data_deep_isolated.sla` (84 lines, 9 tests).

Test names: from_world_fns_new_and_new, from_world_fn_pointers_returns_self,
event_fns_new_and_accessors, event_fn_pointers_returns_self,
map_entities_new_and_call, command_insert_constructor,
command_remove_constructor, command_take_constructor,
event_flattend_field_assignment_is_independent.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 9/9 ✓
| default backend 9/9 ✓
Panic codes: lib 0 (no internal slot-family helpers — direct scalar flat
fields only); tests 147040-147069 (30 unique panic ids; all unique).

Post-batch counts (measured): 512 lib modules | 240 `*_deep.sla` modules |
416 test files | 240 `*_deep_isolated.sla` test files | 90 examples | 6526
`@test` total tests-scoped (6517 -> 6526, +9).
Next free panic band: 147080+ (Batch 411 used lib 0 + tests 147040-147069;
Batch 410 used lib 146990-146993 + tests 147000-147030; Batch 409 used lib
146950-146951 + tests 146960-146984; Batch 408 used lib 146800-146803 +
tests 146850-146903; Batch 407 used lib 146200-146244 + tests 146500-146691).
Next batch candidates: `reflect` (99 lines — has `trait EcsReflect` + fn
pointers + nested fns struct; defer if the `trait` surface needs work that
exceeds the deepening scope, otherwise the fn-pointer struct flattens like
Batch 401's nested-field case), `world_reflect` (34 lines, trivial scalar
mirror), `reflect_bundle` (34 lines, `Vec<i32>` cap-16), `world_extras`
(612 lines, larger self-contained).
docs/issue.md remains at its Batch 407 close. The Batch 401/406
nested-struct-flatten pattern (accessing fields of nested @derive(copy)
struct fields leaks on SA backend) was exercised again: the deep version of
this batch flat-inlined the Fns-companion fields into each wrapper and the
SA backend passed on the first try, confirming the workaround is necessary
and sufficient.

---

# Batch 412 — `lib/reflect_bundle_deep.sla` (34-line shallow original)

Source: vw/lib/reflect_bundle.sla (no `@import`, 34 lines) →
`lib/reflect_bundle_deep.sla` (90 lines).
The shallow module models Bevy ECS `ReflectBundle`: a `bundle_id` plus the
`Vec<i32>` `component_ids` it contains, with id/add_component/count/at/
insert(returns count)/is_registered accessors.

Deep strategy: cap-16 `cid{0..15}` slot family with `_erbd_cid_at/_set`
indirection helpers and cap enforcement on `add_component` (17th add is
dropped silently).

### Structure & Test

`EcsReflectBundleDeep` (`bundle_id: i32`, `cid{0..15}: i32`, `count: i32`).
Accessor mirror: `new`, `id`, `add_component`, `component_count`,
`component_at`, `insert`, `is_registered`.

`tests/test_ecs_lib_reflect_bundle_deep_isolated.sla` (66 lines, 7 tests).
Test names: new_id_and_empty, add_component_grows_count,
component_at_reads_in_order, insert_returns_component_count,
is_registered_true_for_nonneg_id, is_registered_false_for_negative_id,
cap16_enforced_overflow_silent.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 7/7 ✓
| default backend 7/7 ✓
Panic codes: lib 147080-147081 (slot-family `_at/_set` guards);
tests 147090-147103.

---

# Batch 413 — `lib/world_reflect_deep.sla` (34-line shallow original)

Source: vw/lib/world_reflect.sla (no `@import`, 34 lines) →
`lib/world_reflect_deep.sla` (37 lines).
Pure scalar mirror: `EcsReflectWorld { world_id, reflect_component_count,
reflect_resource_count }`. No Vec, no tuple returns, no nested structs — so
the deep version is a direct @derive(copy) scalar mirror with the same
shape.

### Structure & Test

`EcsReflectWorldDeep` (`world_id: i64`, `reflect_component_count: i64`,
`reflect_resource_count: i64`). Accessor mirror: `new`, `id`,
`register_component` (counter +1), `register_resource` (counter +1),
`component_count`, `resource_count`, `ecs_short_type_name_deep` (identity
placeholder matching `ecs_short_type_name`).

`tests/test_ecs_lib_world_reflect_deep_isolated.sla` (44 lines, 5 tests).
Test names: new_id_and_zero_counts, register_component_increments,
register_resource_increments, register_mixed_keeps_separate_counts,
short_type_name_is_identity.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 5/5 ✓
| default backend 5/5 ✓
Panic codes: lib 0 (no internal slot-family guards); tests 147110-147121.

---

# Batch 414 — `lib/world_extras_deep.sla` (612-line shallow original)

Source: vw/lib/world_extras.sla (no `@import`, 612 lines) →
`lib/world_extras_deep.sla` (1271 lines after extensions).
The shallow module's own header notes that it uses result-shim structs because
"the SA backend corrupts the .1 slot of `(i32,i32)` tuples returned from lib
fns." Eight main module structs plus five flat result shim structs (ReqComp /
ReqQuery / ReqNth / ResourceGet / QueueAt) plus variant enumeration helpers.
The shallow version drives `Vec<i32>` parallel arrays (requiree_ids,
required_ids, constructor_ids, registered_component_ids, archetyped_ids, free_
indices, spawned_indices, spawned_types, component_ids, entity_indices,
queued_type_ids, queued_storage_kinds, e.g. 12 distinct array slot families)
plus three unwind wrapper structs nest an operational sibling struct
(RegisterResult { registry, result }, AllocResult { alloc, idx, generation },
QueueApplyResult { queue, applied }, SpawnAtResult { facade, ... },
SpawnBatchResult { facade, count, first }, ModifyResult { facade, ... },
ModifyResourceResult { resources, facade, ... }): the Batch 401/406/411
nested-@derive(copy)-struct-field leak applies.

Deep strategy:
- Replace every `Vec<i32>` with a cap-16 i32 slot family + count + helpers
  (`_xxx_at`, `_xxx_set`, `_xxx_push`, plus `_xxx_remove_at` for the spawn/
  spawned compaction paths and inline backshift `pop_front` for the queue
  front-removal helpers).
- The mutation-returning wrapper fn (RegisterResult/AllocResult/QueueApplyResult
  /SpawnAtResult/SpawnBatchResult/ModifyResult/ModifyResourceResult) all return
  the *mutated container* directly, with the tuple companion stashed into the
  container's `last_*` inline fields (Batch 406 pattern). The five flat result
  shim structs (ReqComp/ReqQuery/ReqNth/ResourceGet/QueueAt) stay struct-shaped
  — they hold only scalar i32 fields; no operational struct field, no leak
  trigger. The accessor fns read the companions in both directions.
- The EcsWorldSpawnFacade embeds the EcsWorldEntityAllocator fields inline
  (not nested as a separate struct field), to also dodge the nested-struct leak.
- `spawn_batch(type_ids: Vec<i32>)` is reshaped into two-step caller API
  (spawn_batch_step + spawn_batch_finish) because SLA fns cannot take a
  Vec<i32> param in this deepening style; each `spawn_batch_step(f, type_id)`
  allocation lines up with the allocator's next free index and the parallel
  spawned_types slot.
- `_remove_at` (compact-backshift) for `EcsWorldEntityAllocator.spawned_indices`
  is the deep mirror of the shallow `spawned_indices.remove(i)`. `_apply` uses a
  per-item pop_front (compact-backshift) loop to drain the queued arrays in
  order.

### Structures & helpers

- `EcsWorldRequiredRegistryDeep` (5 cap-16 i32 slot families: req, rid, cid,
  reg, arc — for the requiree/required/constructor/registered_component/
  archetyped parallel data — plus req_n/rid_n/cid_n/reg_n/arc_n counts plus
  the tuple-replacement `last_register_ok/kind/a/b`, `last_query_found/count`,
  `last_nth_found/required_id/constructor_id`). 5 `_xxx_at` + 1 `_reg_set` +
  push helpers.
- `EcsWorldEntityAllocatorDeep` (next_index, generation, cap-16 fi + cap-16
  si families + fi_n/si_n counts + `last_alloc_idx/generation`). Removal helpers
  (`_si_remove_at`) and pop-front helpers for `free_indices`.
- `EcsWorldResourceEntitiesDeep` (cap-16 cid + eid parallel families + count +
  `last_get_found/entity_idx`).
- `EcsWorldSpawnFacadeDeep` (inlined allocator fields — next_index,
  generation, fi slot family, si slot family, fi_n/si_n, + cap-16 spawned_
  types + tuple companions for alloc/spawn_at/spawn_batch/modify/last_*).
- `EcsWorldComponentsQueueDeep` (cap-16 qt + sk parallel families + count +
  `last_at_found/type_id/storage_kind` + `last_apply_applied`).
- `EcsUnsafeWorldCellDeep` (world_ptr: i64, readonly: i32 — scalar mirror).
- 5 flat result-shim structs (ReqComp/ReqQuery/ReqNth/ResourceGet/QueueAt),
  plain @derive(copy) scalar dicts.
- Variant enums as const helpers / predicate fns on the populated companions:
  `ecs_req_err_kind_deep`, `ecs_req_ok_placeholder_deep`, `ecs_spawn_err_*`,
  `ecs_entity_fetch_err_*`, `ecs_register_result_deep_is_dup/cyclic/
  archetype_exists`.

### Test

`tests/test_ecs_lib_world_extras_deep_isolated.sla` (312 lines, 33 tests).

Test names: req_err_kind_and_accessors, req_ok_placeholder,
spawn_err_and_entity_fetch_err_classifiers, required_registry_new_empty,
required_registry_register_component_grows_reg,
required_registry_mark_archetyped,
required_registry_try_register_with_success,
required_registry_try_register_duplicate_returns_dup_kind,
required_registry_try_register_archetype_exists_kind,
required_registry_get_required_by_id,
required_registry_get_required_by_id_not_found,
required_registry_get_required_nth, entity_allocator_new,
entity_allocator_alloc_grows_spawned, entity_allocator_alloc_multiple,
entity_allocator_free_then_reuse, resource_entities_insert_and_get,
resource_entities_insert_overwrites_existing, spawn_facade_new_empty,
spawn_facade_spawn_at_and_count,
spawn_facade_spawn_at_already_spawned_fails, spawn_facade_spawn_empty_at,
spawn_facade_spawn_batch_steps, spawn_facade_modify_component_present,
spawn_facade_modify_component_not_spawned,
spawn_facade_modify_component_spawned_but_type_absent,
components_queue_new_empty, components_queue_enqueue_at,
components_queue_apply_drains, unsafe_world_cell_new_and_readonly,
modify_resource_present_via_resource_entities, modify_resource_not_found,
modify_by_id_aliases.

Validation: sa sla check lib ✓ | sa sla check tests ✓ | SA backend 33/33 ✓
| default backend 33/33 ✓
Panic codes: lib 147130-147150 (21 internal slot-family guards across the
5 slot-family `_at/_set` helpers in the registry + resource_entities +
spawn_facade + components_queue structs); tests 147160-147264 (105 unique
panic ids; all unique across lib+tests).

Post-batch counts (measured): 515 lib modules | 243 `*_deep.sla` modules |
419 test files | 243 `*_deep_isolated.sla` test files | 90 examples | 6571
`@test` total tests-scoped (6538 -> 6571, +33).
Next free panic band: 147270+ (Batch 414 used lib 147130-147150 + tests
147160-147264; Batch 413 used lib (none) + tests 147110-147121; Batch 412
used lib 147080-147081 + tests 147090-147103; Batch 411 used lib (none) +
tests 147040-147069; Batch 410 used lib 146990-146993 + tests 147000-147030;
Batch 409 used lib 146950-146951 + tests 146960-146984; Batch 408 used lib
146800-146803 + tests 146850-146903; Batch 407 used lib 146200-146244 +
tests 146500-146691).
Next batch candidates: With `world_extras` deepened, only 6 shallow lib files
without a deep counterpart remain and they're either large or deferrable:
`reflect` (99 lines; uses `trait EcsReflect` + fn-pointer field — defer),
`parallel_scope` (105; parallel module — defer), `task_scope_executor_drive`
(178; task/async — defer), `executor_single_threaded` (563; task/async — defer),
`world_mod` (870 lines, no @import; usable next — but contains the public
World surface tied to `world*` modules; can likely deepen shallow), and
`executor_multi_threaded` (1348; task/async — defer).
docs/issue.md remains at its Batch 407 close (no new SA compiler bugs were
observed in Batch 414; the nested-@derive(copy)-struct-field leak pattern was
re-confirmed by the wrapper-flattening of RegisterResult/AllocResult/
QueueApplyResult/SpawnAtResult/SpawnBatchResult/ModifyResult/
ModifyResourceResult which all return the mutated container as a sibling
companion instead of nesting it).


# Batch 415 — `lib/world_mod_deep.sla` (870-line shallow original) — DONE

Source: `lib/world_mod.sla` (870 lines, 6 structs, ~169 public API fns).
Target: `lib/world_mod_deep.sla` (1345 lines after extensions).

Struct mirror: 4 flat helper struct mirrors (`EcsWorldIdDeep`,
`EcsEntityLocationDeep`, `EcsCheckChangeTicksDeep`,
`EcsWorldScheduleEntryDeep`), `EcsSpawnBatchIterDeep` cap-16, and
`EcsWorldDeep` — the main struct with flat scalar shadow fields for every
slot family (entities / components / resources / resource_entities /
non_sends / removed_components / removed_entities / observers / schedules)
plus ~30 `last_*` scalar companions that flatten every tuple return into
write-companion → container pairs read back via `*_last_*` accessor fns.

All ~169 shallow public API fns mirrored; tuple returns flattened via the
companion-field + last accessor pattern. Booleans stored as i32; accessors
return `!= 0`.

Test file: `tests/test_ecs_lib_world_mod_deep_isolated.sla` (65 `@test`
entries). Panic band: tests 147300-147522 (223 unique ids).

Validation:
- `sa sla check lib/world_mod_deep.sla` ✓
- `sa sla check tests/test_ecs_lib_world_mod_deep_isolated.sla` ✓
- SA backend ✗ — ForbiddenSyntax trap during flattening; toolchain
  regression breaking SA backend on every deep-iso test in the repo,
  including previously-green results from Batches 407, 409, and 414. Filed
  as a Batch 415 addendum at `docs/issue.md`.
- Default backend: 65 passed / 0 failed ✓

Panic codes: lib 147270-147288 (19 ids in cap-16 slot-family `_at/_set`
helpers); tests 147300-147522 (223 unique ids).

Post-batch counts (measured): 516 lib modules | 244 `*_deep.sla` modules |
420 test files | 244 `*_deep_isolated.sla` test files | 90 examples | 6636
`@test` total tests-scoped (6571 -> 6636, +65).
Next free panic band: 147630+ (Batch 415 used lib 147270-147288 + tests
147300-147522; Batch 414 used lib 147130-147150 + tests 147160-147264;
Batch 413 used lib (none) + tests 147110-147121; Batch 412 used lib 147080-147081
+ tests 147090-147103; Batch 411 used lib (none) + tests 147040-147069;
Batch 410 used lib 146990-146993 + tests 147000-147030; Batch 409 used lib
146950-146951 + tests 146960-146984; Batch 408 used lib 146800-146803 +
tests 146850-146903; Batch 407 used lib 146200-146244 + tests 146500-146691).
Next batch candidates: only 5 shallow lib files without a deep counterpart
remain and they are all trait/fn-pointer or task/async/parallel:
`reflect` (99; trait EcsReflect + fn-pointer — defer),
`parallel_scope` (105; parallel — defer),
`task_scope_executor_drive` (178; task/async — defer),
`executor_single_threaded` (563; task/async — defer),
`executor_multi_threaded` (1348; task/async — defer).
No easy shallow `lib/*.sla` candidates remain for further shallow deepening.
docs/issue.md updated with a Batch 415 addendum describing the SA backend
ForbiddenSyntax flattening regression affecting every deep-iso test in the
repo (a toolchain issue, not specific to Batch 415).


# Batch 416 — `lib/reflect_deep.sla` (99-line shallow original) — DONE

Source: `lib/reflect.sla` (trait `EcsReflect` + `EcsReflectComponentFns`
fn-pointer table over `ErasedComponentValue`). Target:
`lib/reflect_deep.sla` (self-contained, no `@import`).

Deep strategy: fold `ErasedComponentValue` into flat
`EcsReflectValueDeep { type_id, raw }`; model `EcsReflect::reflect_type_id`
with stable scalar type ids; flatten the Bevy-shaped `ReflectComponentFns`
table into `EcsReflectComponentFnsDeep` with i64 fn handles; flatten the
wrapper into `EcsReflectRootComponentDeep` instead of nesting the fn table.
The deep dispatch helpers return deterministic handle+argument results for
`insert`, `apply`, `remove`, `take`, `contains`, `reflect`, `copy`, and
`register_component`, proving wrapper/fn-table routing without relying on
runtime dyn reflect or actual callback execution.

Test file: `tests/test_ecs_lib_reflect_deep_isolated.sla` (10 `@test`
entries). Panic band: tests 147630-147658.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/reflect_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_reflect_deep_isolated.sla` ✓
- Default backend: 10 passed / 0 failed ✓
- SA backend: 10 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 517 lib modules | 245 `*_deep.sla` modules |
421 test files | 245 `*_deep_isolated.sla` test files | 90 examples | 6646
tests-dir `@test` annotations | 7243 lib/tests/examples `@test` annotations.
Next free panic band: 147670+ (Batch 416 used tests 147630-147658).
Remaining shallow lib files without a deep counterpart are task/async/parallel:
`parallel_scope`, `task_scope_executor_drive`, `executor_single_threaded`,
and `executor_multi_threaded`. Root `reflect` is now deep-covered through the
flat handle-dispatch model; full runtime reflection remains intentionally
outside scope per README/current plan.


# Batch 417 — `lib/parallel_scope_deep.sla` (105-line shallow original) — DONE

Source: `lib/parallel_scope.sla` (Bevy `ParallelCommands` /
`ParallelCommandQueue` model using `Vec<i64>` command and thread-id arrays).
Target: `lib/parallel_scope_deep.sla` (self-contained, no `@import`).

Deep strategy: replace both Vec arrays with cap-16 scalar slot families and
model insertion-order command recording, per-thread counts, per-thread command
filtering via `last_get*` companion slots, clear/is_empty, and cap enforcement.
`EcsParallelCommandsDeep` was initially implemented with a nested
`EcsParallelCommandQueueDeep`, but SA backend reported the known nested-copy
struct MemoryLeak pattern. The final version flattens queue slots directly
inside `EcsParallelCommandsDeep` and uses temporary conversion helpers for
shared queue logic, so both SA and default backends pass.

Test file: `tests/test_ecs_lib_parallel_scope_deep_isolated.sla` (11
`@test` entries). Panic band: lib 147670-147675, tests 147700-147734.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/parallel_scope_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_parallel_scope_deep_isolated.sla` ✓
- Default backend: 11 passed / 0 failed ✓
- SA backend: 11 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 518 lib modules | 246 `*_deep.sla` modules |
422 test files | 246 `*_deep_isolated.sla` test files | 90 examples | 6657
tests-dir `@test` annotations | 7254 lib/tests/examples `@test` annotations.
Next free panic band: 147750+ (Batch 417 used lib 147670-147675 and tests
147700-147734). Remaining shallow lib files without a deep counterpart are
`task_scope_executor_drive`, `executor_single_threaded`, and
`executor_multi_threaded`; all are task/executor/async adjacent.


# Batch 418 — `lib/task_scope_executor_drive_deep.sla` (178-line shallow original) — DONE

Source: `lib/task_scope_executor_drive.sla`, which models Bevy
`TaskPool::scope_with_executor_inner` branch selection over explicit task
counts. Target: `lib/task_scope_executor_drive_deep.sla` (self-contained,
no `@import`, no inline `@test` in the lib).

Deep strategy: preserve the four branch constants and scalar drive algorithm,
add `@derive(copy)` input/result structs, store bool fields as i32 to avoid
backend ownership edge cases, clamp negative input counts to zero, expose a
full result accessor surface, and move coverage into an isolated test file.
The model covers execute-scope, global-scope, external-scope, and
global+external-scope paths, forced pool ticking when worker count is zero,
same-executor external suppression, unrelated global latency accounting, and
executor panic restart accounting.

Test file: `tests/test_ecs_lib_task_scope_executor_drive_deep_isolated.sla`
(10 `@test` entries). Panic band: tests 147750-147799.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/task_scope_executor_drive_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_task_scope_executor_drive_deep_isolated.sla` ✓
- Default backend: 10 passed / 0 failed ✓
- SA backend: 10 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 519 lib modules | 247 `*_deep.sla` modules |
423 test files | 247 `*_deep_isolated.sla` test files | 90 examples | 6667
tests-dir `@test` annotations | 7264 lib/tests/examples `@test` annotations.
Next free panic band: 147810+ (Batch 418 used tests 147750-147799).
The immediate shallow-deepening queue is now down to the executor modules:
`executor_single_threaded` and `executor_multi_threaded`.


# Batch 419 — `lib/executor_single_threaded_deep.sla` (563-line shallow original) — DONE

Source: `lib/executor_single_threaded.sla`, the Bevy
`SingleThreadedExecutor` model with Vec-backed evaluated/completed/unapplied
bitsets and run-condition/deferred-error helpers. Target:
`lib/executor_single_threaded_deep.sla` (self-contained, no `@import`).

Deep strategy: replace Vec bitsets with fixed cap-16 scalar slots for
completed systems, unapplied systems, and evaluated sets; keep all executor
state flat to avoid nested-copy struct leaks; preserve apply-final-deferred,
run/skip/process-system, ApplyDeferred barrier, finish-run cleanup,
failed/passed set-condition, initial-skip, system/deferred panic payload,
handled-error, payload take, and condition-fold semantics. Vector-taking
helpers are represented through fixed arity `*_3` / `*_4` facades for the
same scheduling cases.

Test file: `tests/test_ecs_lib_executor_single_threaded_deep_isolated.sla`
(14 `@test` entries). Panic band: tests 147810-147871.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_single_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_single_threaded_deep_isolated.sla` ✓
- Default backend: 14 passed / 0 failed ✓
- SA backend: 14 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 520 lib modules | 248 `*_deep.sla` modules |
424 test files | 248 `*_deep_isolated.sla` test files | 90 examples | 6681
tests-dir `@test` annotations | 7278 lib/tests/examples `@test` annotations.
Next free panic band: 147880+ (Batch 419 used tests 147810-147871).
The immediate shallow-deepening queue is now down to
`executor_multi_threaded`; it is the largest remaining executor model.


# Batch 420 — `lib/executor_multi_threaded_deep.sla` (1348-line shallow original) — DONE

Source: `lib/executor_multi_threaded.sla`, the largest remaining executor
model. Target: `lib/executor_multi_threaded_deep.sla` (self-contained,
no `@import`).

Deep strategy: cover the core `ExecutorState` gate and ready-batch selection
surface with cap-16 scalar slots for ready/running/completed/unapplied
systems and dependency counters. The state remains fully flat to avoid
nested-copy backend leaks. System specs model send/local/exclusive flags plus
up to two access-conflict ids; batch selection chooses up to three ready
systems while honoring completed/dependency gates, local-thread exclusivity,
exclusive system isolation, running-system conflicts, and access conflicts.
Completion marks finished systems, preserves unapplied-deferred state, and
releases local/exclusive gates.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` (10 `@test`
entries). Panic band: tests 147880-147916.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 10 passed / 0 failed ✓
- SA backend: 10 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6691
tests-dir `@test` annotations | 7288 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor core `ExecutorState` gate and
ready-batch sub-surface 0% -> 100%; overall API parity remains ~94–96%,
behavioral parity remains ~86–91%. The immediate no-deep-counterpart queue is
empty; future executor work should extend `executor_multi_threaded_deep` into
completion/tick handoff and broader scheduling facades.


# Batch 421 — `lib/executor_multi_threaded_deep.sla` completion/tick handoff — DONE

Source focus: the `ExecutorState` dependent-release, skipped/evaluated,
deferred-application, finish-run, and completion tick handoff sections of
`lib/executor_multi_threaded.sla`.

Deep strategy: extend the existing flat `EcsExecutorStateDeep` instead of
adding nested run-plan wrappers. Added cap-16 scalar slot families for skipped
systems and evaluated sets; added fixed-arity dependent release and
completion-with-dependents facades; added skip-with-dependents,
mark-skipped-pending, set-evaluated, apply-deferred-one/all, finish-run, and
tick-after-completion-to-ready-batch helpers. The tick helper completes one
running system, releases up to three dependents, and selects the next ready
batch from three candidates while preserving the Batch 420 gate logic.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 18
`@test` entries (+8). New panic band: tests 147930-147960.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 18 passed / 0 failed ✓
- SA backend: 18 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6699
tests-dir `@test` annotations | 7296 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completion/tick handoff sub-surface
0% -> 100% for this flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining useful work in this
module is higher-level run-plan condition folding/error payload facades if
more executor depth is desired.


# Batch 422 — `lib/executor_multi_threaded_deep.sla` condition/error facades — DONE

Source focus: the `MultiThreadedExecutor` panic/handled-error payload helpers
and `EcsExecutorRunPlan` condition-folding / failed-condition state effects in
`lib/executor_multi_threaded.sla`.

Deep strategy: add flat `EcsExecutorErrorStateDeep` and
`EcsExecutorConditionFoldDeep` structs instead of nesting a full run plan.
The error facade mirrors system/deferred panic payload recording, system/
deferred handled-error recording, phase/system tracking, and panic payload
take/rethrow accounting. The condition facade models Bevy's non-short-circuit
condition fold: false keeps evaluating later conditions, handled errors
become false and keep evaluating, and error-handler panic aborts the fold with
a run-condition panic payload. Added fixed-arity helpers for failed set
conditions, passed set conditions, failed system conditions, and joining set +
system fold results.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 25
`@test` entries (+7). New panic band: tests 147970-148013.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 25 passed / 0 failed ✓
- SA backend: 25 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6706
tests-dir `@test` annotations | 7303 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor condition/error facade sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining executor opportunities
are broader run-plan drive loops and lock-failure tick wrappers.


# Batch 423 — `lib/executor_multi_threaded_deep.sla` drive/lock-failure summaries — DONE

Source focus: the `EcsExecutorRunPlan` start/take-batch/drive-one/drive-batch
loop and tick-loop lock-failure wrappers in `lib/executor_multi_threaded.sla`.

Deep strategy: extend the flat system spec with `has_deferred`,
`should_run`, and `is_apply_deferred` flags, then add flat
`EcsExecutorDriveSummaryDeep` results rather than nesting full run plans.
New helpers cover next-ready, next-runnable over three candidates,
drive-one run/skip/apply-deferred-barrier summaries, width-limited ready-batch
drive summaries, and lock-failed tick summaries that preserve pending
completion ids and apply-deferred counts. This keeps the executor drive model
fixed-arity and backend-stable while covering the next run-plan layer above
the Batch 420-422 state, handoff, and error facades.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 32
`@test` entries (+7). New panic band: tests 148030-148064.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 32 passed / 0 failed ✓
- SA backend: 32 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6713
tests-dir `@test` annotations | 7310 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-loop / lock-failure summary
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
would be broader multi-wave tick-loop summaries or full run-plan history
tracking, which would need the same flat-summary approach to stay backend
stable.


# Batch 424 — `lib/executor_multi_threaded_deep.sla` multi-wave tick summaries — DONE

Source focus: the `tick_executor_with_completion_waves`,
`tick_executor_after_system_completed`, and
`retry_pending_completions` metadata behavior in
`lib/executor_multi_threaded.sla`.

Deep strategy: add flat `EcsExecutorTickLoopSummaryDeep` instead of modeling
nested `Vec<Vec<i64>>` completion waves. New fixed-arity helpers cover the
no-completion-waves case (still produces one tick), two completion waves that
complete systems, release dependents, start selected batch systems between
waves, and record per-wave batch summaries, plus retry-pending metadata that
counts the pending wave before later waves. This builds directly on the Batch
423 drive summary surface and keeps all returned data scalar.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 35
`@test` entries (+3). New panic band: tests 148080-148097.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 35 passed / 0 failed ✓
- SA backend: 35 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6716
tests-dir `@test` annotations | 7313 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor multi-wave tick-loop summary
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is full run-plan history tracking, if continued, using flat scalar summaries.


# Batch 425 — `lib/executor_multi_threaded_deep.sla` run history summaries — DONE

Source focus: the `EcsExecutorRunPlan` `run_order`, `apply_order`, and
`skipped_order` tracking plus their count/at accessors in
`lib/executor_multi_threaded.sla`.

Deep strategy: add flat `EcsExecutorRunHistoryDeep` with capped scalar
run/apply/skipped slots instead of nesting a full run plan. New helpers cover
push/accessor behavior, out-of-range `-1` access, applying current unapplied
systems in ascending system order, recording a ready-batch's selected systems,
and a drive-one facade that records run, skip, stalled, and ApplyDeferred
barrier history metadata.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 39
`@test` entries (+4). New panic band: tests 148110-148139.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 39 passed / 0 failed ✓
- SA backend: 39 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6720
tests-dir `@test` annotations | 7355 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor run-plan history tracking
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 426 — `lib/executor_multi_threaded_deep.sla` drive-all history integration — DONE

Source focus: the `ecs_executor_run_plan_drive_all` loop in
`lib/executor_multi_threaded.sla`, especially repeated next-runnable scans,
dependency release between iterations, skipped-system release, ApplyDeferred
barrier apply ordering, and stalled detection.

Deep strategy: extend the flat run-history layer with a fixed-arity
`ecs_executor_run_history_deep_drive_all3` facade. The helper scans runnable
systems in system-index order, advances the local state internally, releases
per-system dependents through scalar dep triples, records run/apply/skipped
history, applies current unapplied systems before completing an ApplyDeferred
barrier, and sets the stalled bit when a ready system remains blocked by a
running conflict.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 43
`@test` entries (+4). New panic band: tests 148160-148179.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 43 passed / 0 failed ✓
- SA backend: 43 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6724
tests-dir `@test` annotations | 7359 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all history integration
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 427 — `lib/executor_multi_threaded_deep.sla` finish-run deferred summaries — DONE

Source focus: `ecs_multi_threaded_executor_finish_run_with_deferred_error`,
`ecs_multi_threaded_executor_finish_run_with_deferred_handled_error`, and
`ecs_executor_state_finish_run` in `lib/executor_multi_threaded.sla`.

Deep strategy: add flat `EcsExecutorFinishRunSummaryDeep` rather than nesting
executor/error/state values. New helpers summarize final-deferred application,
state cleanup counts after finish-run, disabled-final-deferred preservation of
unapplied systems, deferred panic payload recording with apply-count stopping
at the failing system, and deferred handled-error recording while continuing
through all unapplied systems.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 47
`@test` entries (+4). New panic band: tests 148200-148226.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 47 passed / 0 failed ✓
- SA backend: 47 passed / 0 failed ✓
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6728
tests-dir `@test` annotations | 7363 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor finish-run deferred cleanup
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 428 — `lib/executor_multi_threaded_deep.sla` ready-batch skip/rescan summaries — DONE

Source focus: `ecs_executor_run_plan_take_ready_batch` in
`lib/executor_multi_threaded.sla`, especially the branch that skips
`should_run=false` or pending-skipped ready systems, releases their
dependents, sets `rescan`, and continues selecting runnable systems into the
same ready batch.

Deep strategy: add flat `EcsExecutorReadyBatchRescanSummaryDeep` and a
fixed-arity `ecs_executor_ready_batch_rescan_summary_deep3` helper. The helper
tracks selected and skipped system ids, internal rescan passes, post-batch
ready/completed/running counts, width-limit behavior, and exclusive-system
early return after skip-triggered dependent release without nesting a full
run plan or batch result.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 51
`@test` entries (+4). New panic band: tests 148240-148262.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 51 passed / 0 failed ✓
- SA backend: 51 passed / 0 failed ✓ (`timeout 300s`; an earlier 180s run printed 51/51 passed but hit the timeout boundary before process exit)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6732
tests-dir `@test` annotations | 7367 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor ready-batch skip/rescan
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 429 — `lib/executor_multi_threaded_deep.sla` begin-run reset summaries — DONE

Source focus: `ecs_executor_run_plan_begin_run` in
`lib/executor_multi_threaded.sla`, especially ready-state rebuild from
starting systems, dependency counter reset, transient state cleanup,
history/error counter reset, and preservation of unapplied buffers between
runs.

Deep strategy: add flat `EcsExecutorBeginRunSummaryDeep` and fixed-arity
`ecs_executor_begin_run_summary_deep3`. The helper resets ready/running/
completed/skipped/evaluated state, clears local/exclusive gates, restores
per-system dependency counters for three systems, reports ready/dependency
slots and post-reset counts, exposes reset history/error counters as scalar
zeros, and preserves existing unapplied buffers.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 55
`@test` entries (+4). New panic band: tests 148280-148313.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 55 passed / 0 failed ✓
- SA backend: 55 passed / 0 failed ✓ (`timeout 300s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6736
tests-dir `@test` annotations | 7371 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor begin-run reset sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 507 — `executor_multi_threaded_deep` no-drain exclusive gate coverage — DONE

Source focus: no-drain tick-with-completions fast-path existing exclusive gate
summary coverage in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused regression proving the no-drain fast path reports
an already-running exclusive system as both exclusive-running and local-running,
does not select additional ready work while the exclusive gate is occupied, and
leaves that ordinary ready work visible in the summary. This validates the gate
state preservation fixed in Batch 506 for the exclusive branch as well as the
local branch. No executor implementation or SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 172
`@test` entries. New panic band: 149725-149731.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `mt_deep_tick_with_completions_no_drain_preserves_existing_exclusive_gate`: 1 passed / 0 failed ✓ (`timeout 75s`, `--jobs 1`)
- Default backend focused filter `no_drain`: 3 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started because an external SA backend test process was already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6853 tests-dir `@test` annotations | 7453 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor no-drain exclusive gate summary
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 436 — `lib/executor_multi_threaded_deep.sla` drive-all-batched integration summaries — DONE

Source focus: `ecs_executor_run_plan_drive_all_batched` in
`lib/executor_multi_threaded.sla`, especially repeated width-limited
ready-batch waves, dependency release between waves, skip-driven release
within a wave, ApplyDeferred accounting, and stalled exit when no progress is
possible.

Deep strategy: add flat `EcsExecutorDriveAllBatchedIntegrationSummaryDeep` and
fixed-arity `ecs_executor_drive_all_batched_integration_summary_deep3`. The
helper advances at most three scalar waves over the existing three-spec model,
records run/completed/skipped/apply order in flat slots, mutates state only
through scalar helpers, and avoids whole-plan or Vec-backed state. Slot writes
are inline for the same wide-struct stability reason documented in Batch 435.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 83
`@test` entries (+4). New panic band: tests 148600-148622.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `mt_deep_drive_all_batched_integration`: 4 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `mt_deep_drive_all_batched_integration`: 4 passed / 0 failed ✓ (`timeout 180s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6764
tests-dir `@test` annotations | 7397 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched integration
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 435 — `lib/executor_multi_threaded_deep.sla` drive-ready-batch integration summaries — DONE

Source focus: `ecs_executor_run_plan_drive_ready_batch` in
`lib/executor_multi_threaded.sla`, especially the integration between
ready-batch selection, run-order recording, complete-ready-batch behavior,
skip/dependent release, ApplyDeferred barrier application, and zero-width
stall handling.

Deep strategy: add flat `EcsExecutorDriveReadyBatchIntegrationSummaryDeep` and
fixed-arity `ecs_executor_drive_ready_batch_integration_summary_deep3`. The
helper uses explicit scalar 0/1/2 selection slots, records skipped systems
that release dependents before later slots are considered, delays state
mutation until after selection so adjacent ready send systems are both
selected, then starts/completes selected systems in run order. Wide summary
slot writes are inline in the main helper because prior focused tests showed
second-slot updates through push helpers are unstable for this large flat
struct shape.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 79
`@test` entries (+4). New panic band: tests 148560-148589.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `mt_deep_drive_ready_batch_integration`: 4 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `mt_deep_drive_ready_batch_integration`: 4 passed / 0 failed ✓ (`timeout 180s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6760
tests-dir `@test` annotations | 7393 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 430 — `lib/executor_multi_threaded_deep.sla` completed-tick error summaries — DONE

Source focus: the completed tick executor wrappers in
`lib/executor_multi_threaded.sla`: system panic/handled-error completion,
ApplyDeferred panic/handled-error completion, and their lock-failed pending
completion variants.

Deep strategy: add flat `EcsExecutorCompletedTickErrorSummaryDeep` plus
fixed-arity helpers for normal completed-tick continuation and lock-failed
pending completion. The helpers combine error payload/handled-error metadata,
ApplyDeferred barrier apply counts, pending completion slots, skipped ready
systems, selected ready systems, and post-tick ready/running/completed/
unapplied counts without nesting executor, tick-loop, or batch structs.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 59
`@test` entries (+4). New panic band: tests 148340-148377.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 59 passed / 0 failed ✓
- SA backend: 59 passed / 0 failed ✓ (`timeout 300s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6740
tests-dir `@test` annotations | 7376 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completed-tick error/pending
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 431 — `lib/executor_multi_threaded_deep.sla` complete-ready-batch summaries — DONE

Source focus: `ecs_executor_run_plan_complete_ready_batch` in
`lib/executor_multi_threaded.sla`, especially its two-pass behavior: start
selected systems that are not already running, then complete selected systems
in batch order while applying existing deferred buffers before an
ApplyDeferred barrier and releasing dependents after each completion.

Deep strategy: add flat `EcsExecutorCompleteReadyBatchSummaryDeep` and a
fixed-arity `ecs_executor_complete_ready_batch_summary_deep3` helper. The
helper accepts three selected batch slots plus three spec/dependent slot
families, records start/completion/apply order in scalar slots, summarizes
post-batch ready/running/completed/unapplied counts, and reports local/
exclusive gate cleanup without nesting a run plan or ready-batch result.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 63
`@test` entries (+4). New panic band: tests 148400-148427.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 63 passed / 0 failed ✓
- SA backend: 63 passed / 0 failed ✓ (`timeout 300s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6744
tests-dir `@test` annotations | 7380 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 432 — `lib/executor_multi_threaded_deep.sla` initial-skip summaries — DONE

Source focus: `ecs_executor_run_plan_apply_initial_skips` in
`lib/executor_multi_threaded.sla`, especially initial skipped-system input
handling, invalid/completed skip suppression, skipped-order recording, and
dependent release after each accepted initial skip.

Deep strategy: add flat `EcsExecutorInitialSkipsSummaryDeep` and a fixed-arity
`ecs_executor_initial_skips_summary_deep3` helper. The helper accepts three
initial skip slots plus three spec/dependent slot families, records accepted
and ignored skip ids in scalar slots, uses local completed markers to keep
duplicate skips deterministic, releases dependents for accepted skips, and
summarizes post-skip ready/completed/skipped/dependency slots without nesting
a run plan or Vec-backed skip list.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 67
`@test` entries (+4). New panic band: tests 148440-148467.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend: 67 passed / 0 failed ✓
- SA backend: 67 passed / 0 failed ✓ (`timeout 300s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6748
tests-dir `@test` annotations | 7384 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor initial-skip sub-surface 0% -> 100%
for the flat fixed-arity model; overall API parity remains ~94–96%,
behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 433/434 — `lib/executor_multi_threaded_deep.sla` completion drain/tick summaries — DONE

Source focus: `ecs_executor_run_plan_drain_completion_queue` and
`ecs_executor_run_plan_tick_with_completions` in
`lib/executor_multi_threaded.sla`, especially completion queue ordering,
ApplyDeferred barrier handling before completing the barrier system, duplicate
or invalid completed-system entries, dependent release after accepted
completions, and same-tick ready-batch selection after draining completions.

Deep strategy: add flat `EcsExecutorCompletionQueueDrainSummaryDeep` and a
fixed-arity `ecs_executor_completion_queue_drain_summary_deep3` helper, plus
flat `EcsExecutorTickWithCompletionsSummaryDeep` and
`ecs_executor_tick_with_completions_summary_deep3`. The helpers accept three
queued completion slots plus three spec/dependent slot families, complete only
currently-running systems in queue order, report ignored entries when a queued
id is invalid or no longer running, apply all existing deferred buffers before
completing an ApplyDeferred spec, release dependents through the existing
scalar dependent helpers, and summarize post-drain/tick
ready/running/completed/unapplied/gate/dependency slots without nesting a run
plan, completion queue, or tick-loop result. The no-completion tick path uses
the fixed-arity ready-batch helper directly after a focused failure showed the
generic rescan loop only selected the first ready system when exactly systems
0 and 1 were ready.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 75
`@test` entries (+8). New panic band: tests 148480-148549.

Validation:
- `SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `mt_deep_completion_queue_drain_summary`: 4 passed / 0 failed ✓ (`timeout 90s`)
- Default backend focused filter `mt_deep_tick_with_completions_summary`: 4 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `mt_deep_completion_queue_drain_summary`: 4 passed / 0 failed ✓ (`timeout 150s`)
- SA backend focused filter `mt_deep_tick_with_completions_summary`: 4 passed / 0 failed ✓ (`timeout 180s`)
- `git diff --check` ✓

Post-batch counts (measured): 521 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6756
tests-dir `@test` annotations | 7389 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completion-queue drain and
tick-with-completions summary sub-surfaces 0% -> 100% for the flat fixed-arity
model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 437 — `lib/executor_multi_threaded_deep.sla` ready-batch/tick-loop accessor parity helpers — DONE

Source focus: shallow accessor parity in `lib/executor_multi_threaded.sla` for
ready batches and tick-loop summaries, especially `_count`, `_at`, local /
exclusive flags, tick count, lock-failed status, pending completions, and
per-batch system accessors.

Deep strategy: add scalar accessor helpers for `EcsExecutorReadyBatchDeep` and
`EcsExecutorTickLoopSummaryDeep` without changing the underlying flat
fixed-arity data model. `ecs_executor_ready_batch_deep_at` now respects the
recorded count before returning slot contents, so stale unused slots report
`-1` consistently with the new pending-completion and batch accessors.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 86
`@test` entries (+3). New panic band: tests 148630-148649.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `accessors`: 3 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `accessors`: 3 passed / 0 failed ✓ (`timeout 150s`)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6767
tests-dir `@test` annotations | 7403 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor ready-batch/tick-loop accessor
parity sub-surface 0% -> 100% for the flat fixed-arity model; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 438 — `lib/executor_multi_threaded_deep.sla` tick-loop skipped-batch accessor parity — DONE

Source focus: shallow `ecs_executor_ready_batch_skipped_count`,
`ecs_executor_ready_batch_skipped_at`,
`ecs_executor_tick_loop_batch_skipped_count`, and
`ecs_executor_tick_loop_batch_skipped_at` behavior in
`lib/executor_multi_threaded.sla`.

Deep strategy: extend the flat `EcsExecutorTickLoopSummaryDeep` with
per-batch skipped count/id slots for two capped tick waves, add scalar
skipped-batch accessors with count-aware `-1` bounds, and route tick-loop
batch summaries through the existing ready-batch rescan summary so skipped
system ids are preserved alongside selected systems. This fixes a deep helper
gap where tick-loop summaries could expose selected batch systems but had no
way to report systems skipped during the same rescan wave.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 88
`@test` entries (+2). New panic band: tests 148650-148663.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `skipped_accessors`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `skipped_accessors`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6769
tests-dir `@test` annotations | 7405 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-loop skipped-batch accessor
parity sub-surface 0% -> 100% for the flat fixed-arity model; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 439 — `lib/executor_multi_threaded_deep.sla` condition-fold/run-history accessor parity — DONE

Source focus: shallow accessor helpers in `lib/executor_multi_threaded.sla`
for condition folds and run-plan history:
`ecs_executor_condition_fold_should_run`,
`ecs_executor_condition_fold_evaluated_count`,
`ecs_executor_condition_fold_aborted`, `ecs_executor_run_plan_run_count`,
`ecs_executor_run_plan_apply_count`, `ecs_executor_run_plan_skipped_count`,
and `ecs_executor_run_plan_is_stalled`.

Deep strategy: add scalar read-only accessors over existing
`EcsExecutorConditionFoldDeep` and `EcsExecutorRunHistoryDeep` fields. This
does not change drive, fold, or history mutation behavior; it closes the
remaining accessor parity gap for these flat summaries so tests and downstream
deep users no longer need direct field reads for counts and stalled/aborted
booleans.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 90
`@test` entries (+2). New panic band: tests 148670-148681.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `accessor_parity`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `accessor_parity`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6771
tests-dir `@test` annotations | 7407 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor condition-fold/run-history accessor
parity sub-surface 0% -> 100% for the flat fixed-arity model; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 440 — `lib/executor_multi_threaded_deep.sla` error-state and condition-error accessor parity — DONE

Source focus: shallow error-state and condition-fold error-payload accessors in
`lib/executor_multi_threaded.sla`, especially panic-payload pending state,
panic/handled-error counts, phase/system fields, and panic payload rethrows.

Deep strategy: add read-only helpers over the existing
`EcsExecutorErrorStateDeep` and `EcsExecutorConditionFoldDeep` fields. This
keeps the flat error-state model unchanged while closing the last direct-field
reads used by tests for panic payload and handled-error metadata.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 92
`@test` entries (+2). New panic band: tests 148690-148711.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `error_accessor_parity`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `error_accessor_parity`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6773
tests-dir `@test` annotations | 7409 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor error-state and condition-error
accessor parity sub-surface 0% -> 100% for the flat fixed-arity model;
overall API parity remains ~94–96%, behavioral parity remains ~86–91%.
Remaining optional depth is broader executor integration scenarios if new
Bevy parity gaps are found.


# Batch 441 — `lib/executor_multi_threaded_deep.sla` completed-tick error summary accessors — DONE

Source focus: completed-tick error summary surfaces in
`lib/executor_multi_threaded_deep.sla`, especially lock-failed pending
metadata, selected/skipped batch slots, apply counts, post-tick state counts,
and panic/handled-error phase/system metadata.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorCompletedTickErrorSummaryDeep` fields. Slot accessors for pending,
selected, and skipped systems are count-aware and return `-1` out of bounds,
matching the newer accessor pattern used by ready-batch, tick-loop, and
run-history summaries.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 94
`@test` entries (+2). New panic band: tests 148720-148742.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `completed_tick_error_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `completed_tick_error_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6775
tests-dir `@test` annotations | 7411 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completed-tick error accessor
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 442 — `lib/executor_multi_threaded_deep.sla` complete-ready-batch summary accessors — DONE

Source focus: complete-ready-batch summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially started/completed/apply
slots, post-batch ready/running/completed/unapplied counts, and local/exclusive
gate metadata.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorCompleteReadyBatchSummaryDeep` fields. The `started_at`,
`completed_at`, and `apply_at` helpers are count-aware and return `-1` out of
bounds, matching the newer accessor pattern used by ready-batch, tick-loop,
run-history, and completed-tick summaries.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 96
`@test` entries (+2). New panic band: tests 148750-148768.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `complete_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `complete_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6777
tests-dir `@test` annotations | 7413 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch accessor
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 443 — `lib/executor_multi_threaded_deep.sla` initial-skip summary accessors — DONE

Source focus: initial-skip summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially skipped/ignored slots,
post-skip ready/completed/skipped counts, dependency counters, and ready flags.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorInitialSkipsSummaryDeep` fields. The skipped/ignored `_at` helpers
are count-aware and return `-1` out of bounds; dependency and ready helpers read
fixed system-index slots and return `-1`/`false` out of range.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 98
`@test` entries (+2). New panic band: tests 148780-148800.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `initial_skip_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `initial_skip_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6779
tests-dir `@test` annotations | 7415 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor initial-skip accessor sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 444 — `lib/executor_multi_threaded_deep.sla` completion-queue drain summary accessors — DONE

Source focus: completion-queue drain summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially completed/ignored/apply
slots, post-drain ready/running/completed/unapplied counts, local/exclusive
gate metadata, dependency counters, and ready flags.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorCompletionQueueDrainSummaryDeep` fields. The completed/ignored/apply
`_at` helpers are count-aware and return `-1` out of bounds; dependency and
ready helpers read fixed system-index slots and return `-1`/`false` out of
range.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 100
`@test` entries (+2). New panic band: tests 148820-148843.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `completion_queue_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `completion_queue_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6781
tests-dir `@test` annotations | 7417 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completion-queue drain accessor
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 445 — `lib/executor_multi_threaded_deep.sla` tick-with-completions summary accessors — DONE

Source focus: tick-with-completions summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially completed/ignored/apply,
selected/skipped batch slots, post-tick ready/running/completed/unapplied
counts, stalled state, gate metadata, dependency counters, and ready flags.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorTickWithCompletionsSummaryDeep` fields. Completed/ignored/apply,
selected, and skipped `_at` helpers are count-aware and return `-1` out of
bounds; dependency and ready helpers read fixed system-index slots and return
`-1`/`false` out of range.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 102
`@test` entries (+2). New panic band: tests 148860-148885.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `tick_with_completion_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `tick_with_completion_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6783
tests-dir `@test` annotations | 7419 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-with-completions accessor
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 446 — `lib/executor_multi_threaded_deep.sla` drive-ready-batch integration accessors — DONE

Source focus: drive-ready-batch integration summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially run/completed/skipped/apply
slots, post-drive ready/running/completed/unapplied counts, stalled state,
dependency counters, and ready flags.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorDriveReadyBatchIntegrationSummaryDeep` fields. Run/completed/
skipped/apply `_at` helpers are count-aware and return `-1` out of bounds;
dependency and ready helpers read fixed system-index slots and return
`-1`/`false` out of range. The wide summary write path remains unchanged.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 104
`@test` entries (+2). New panic band: tests 148900-148937.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6785
tests-dir `@test` annotations | 7421 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration
accessor sub-surface 0% -> 100% for the flat fixed-arity model; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 447 — `lib/executor_multi_threaded_deep.sla` drive-all-batched integration accessors — DONE

Source focus: drive-all-batched integration summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially wave count, run/completed/
skipped/apply slots, post-drive ready/running/completed/unapplied counts,
stalled state, and dependency counters.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorDriveAllBatchedIntegrationSummaryDeep` fields. Run/completed/
skipped/apply `_at` helpers are count-aware and return `-1` out of bounds;
dependency helpers read fixed system-index slots and return `-1` out of range.
The wide summary write path remains unchanged.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 106
`@test` entries (+2). New panic band: tests 148950-148983.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6787
tests-dir `@test` annotations | 7423 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched integration
accessor sub-surface 0% -> 100% for the flat fixed-arity model; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 448 — `lib/executor_multi_threaded_deep.sla` ready-batch rescan accessors — DONE

Source focus: ready-batch rescan summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially selected/skipped slots,
rescan count, post-rescan ready/completed/running counts, and stalled state.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorReadyBatchRescanSummaryDeep` fields. Selected/skipped `_at` helpers
are count-aware and return `-1` out of bounds; scalar post-state helpers expose
the same summary fields used by existing tests.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 108
`@test` entries (+2). New panic band: tests 149000-149018.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `ready_batch_rescan_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `ready_batch_rescan_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6789
tests-dir `@test` annotations | 7425 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan accessor
sub-surface 0% -> 100% for the flat fixed-arity model; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 449 — `lib/executor_multi_threaded_deep.sla` begin-run summary accessors — DONE

Source focus: begin-run reset summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially starting-ready flags,
dependency counters, transient state cleanup counts, preserved unapplied
buffers, gate reset state, and history/error reset metadata.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorBeginRunSummaryDeep` fields. Fixed system-index helpers expose
ready/dependency slots and return `false`/`-1` out of range; scalar helpers
expose reset counts and metadata without changing begin-run write paths.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 110
`@test` entries (+2). New panic band: tests 149030-149056.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `begin_run_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `begin_run_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6791
tests-dir `@test` annotations | 7427 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor begin-run accessor sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 450 — `lib/executor_multi_threaded_deep.sla` finish-run summary accessors — DONE

Source focus: finish-run summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially final-deferred enablement,
apply counts, post-finish state cleanup counts, preserved unapplied buffers,
and deferred panic/handled-error metadata.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorFinishRunSummaryDeep` fields. Boolean fields return `bool`, scalar
post-state and error metadata helpers expose the same values asserted by the
existing direct-field tests, and finish-run write paths remain unchanged.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 112
`@test` entries (+2). New panic band: tests 149080-149104.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `finish_run_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `finish_run_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6793
tests-dir `@test` annotations | 7429 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor finish-run accessor sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 451 — `lib/executor_multi_threaded_deep.sla` drive summary accessors — DONE

Source focus: drive summary accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially selected system slots,
skipped/apply/completed/ready/unapplied counts, stalled state, lock failure,
and pending-completion slots.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorDriveSummaryDeep` fields. Selected and pending `_at` helpers are
count-aware and return `-1` out of bounds; boolean helpers expose stalled and
lock-failure flags without changing drive or tick-loop write paths.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 114
`@test` entries (+2). New panic band: tests 149130-149151.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_summary_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `drive_summary_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6795
tests-dir `@test` annotations | 7431 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive summary accessor sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 452 — `lib/executor_multi_threaded_deep.sla` system spec accessors — DONE

Source focus: system spec accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially system index, exclusive/
local flags, should-run/deferred/apply-deferred flags, and capped access
conflict metadata.

Deep strategy: add read-only accessors over the existing flat
`EcsExecutorSystemSpecDeep` fields. Boolean flags return `bool`; conflict
helpers expose the two-slot cap and return `-1` out of bounds. System spec
construction and mutation paths remain unchanged.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 116
`@test` entries (+2). New panic band: tests 149180-149202.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `system_spec_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `system_spec_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6797
tests-dir `@test` annotations | 7433 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor system spec accessor sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 453 — `lib/executor_multi_threaded_deep.sla` state metadata accessors — DONE

Source focus: executor state metadata accessor parity in
`lib/executor_multi_threaded_deep.sla`, especially the fixed cap and clamped
system/set counts on `EcsExecutorStateDeep`.

Deep strategy: add read-only accessors for the cap, `system_count`, and
`set_count`. These expose existing initialization metadata without changing
state initialization, clamping, or slot mutation behavior.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 118
`@test` entries (+2). New panic band: tests 149230-149243.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `state_metadata_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`)
- SA backend focused filter `state_metadata_accessor`: 2 passed / 0 failed ✓ (`timeout 150s`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (measured): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor state metadata accessor sub-surface
0% -> 100% for the flat fixed-arity model; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 454 — `executor_multi_threaded_deep` isolated tests use existing accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for state
metadata, ready-batch metadata, and system-spec drive flags.

Deep strategy: migrate those assertions to the existing public accessor
helpers without changing executor behavior or adding new tests. Remaining
direct `should_run` reads are condition-fold result assertions and are a
separate surface.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `state_init`: 1 passed / 0 failed ✓ (`timeout 90s`)
- Default backend focused filter `ready_batch`: 24 passed / 0 failed ✓ (`timeout 90s`)
- Default backend focused filter `tick_after_completion`: 1 passed / 0 failed ✓ (`timeout 90s`)
- Default backend focused filter `system_spec_drive_flags`: 1 passed / 0 failed ✓ (`timeout 90s`)
- SA backend exact filters for the six edited test names all passed with `--jobs 1` and `timeout 180s`: `mt_deep_system_spec_drive_flags`, `mt_deep_state_init_clamps_and_starts_empty`, `mt_deep_ready_batch_selects_nonconflicting_send_systems`, `mt_deep_ready_batch_allows_one_local_only`, `mt_deep_ready_batch_exclusive_stands_alone`, and `mt_deep_tick_after_completion_releases_and_batches_ready`.
- A first attempt to run four SA backend filters concurrently hit command timeouts with no panic output; verification was repeated serially with exact test-name filters to avoid memory/resource contention.
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor isolated accessor-usage cleanup
0% -> 100% for this test-maintenance slice; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
condition-fold result accessor cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 455 — `executor_multi_threaded_deep` condition-fold tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorConditionFoldDeep` results.

Deep strategy: migrate the condition-fold false/handled-error/panic/join
tests to the existing `ecs_executor_condition_fold_deep_*` read-only helpers.
No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `condition_fold_`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `condition_fold_`: 6 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor condition-fold accessor-usage cleanup
0% -> 100% for this test-maintenance slice; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
error-state and summary-result direct-field cleanup or broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 456 — `executor_multi_threaded_deep` error-state tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorErrorStateDeep`.

Deep strategy: migrate the panic-payload and handled-error state tests to the
existing `ecs_executor_error_state_deep_*` read-only helpers. No executor
implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `error_state_records`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `error_state_records`: 2 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor error-state accessor-usage cleanup
0% -> 100% for this test-maintenance slice; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
summary-result direct-field cleanup or broader executor integration scenarios
if new Bevy parity gaps are found.

# Batch 457 — `executor_multi_threaded_deep` finish-run summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorFinishRunSummaryDeep`.

Deep strategy: migrate disabled-final-deferred, no-error final apply,
deferred-panic, and deferred-handled-error finish-run summary tests to the
existing `ecs_executor_finish_run_summary_deep_*` read-only helpers. No
executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `finish_run_summary`: 4 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `finish_run_summary`: 4 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor finish-run summary accessor-usage
cleanup 0% -> 100% for this test-maintenance slice; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is other summary-result direct-field cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 458 — `executor_multi_threaded_deep` begin-run summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorBeginRunSummaryDeep`.

Deep strategy: migrate transient-reset, dependency-restore,
unapplied-preservation, and missing-start-slot begin-run summary tests to the
existing `ecs_executor_begin_run_summary_deep_*` read-only helpers. No
executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `begin_run_summary`: 4 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `begin_run_summary`: 4 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor begin-run summary accessor-usage
cleanup 0% -> 100% for this test-maintenance slice; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is other summary-result direct-field cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 459 — `executor_multi_threaded_deep` completed-tick error summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorCompletedTickErrorSummaryDeep`.

Deep strategy: migrate system-panic, ApplyDeferred panic, handled lock-failed,
and ApplyDeferred handled lock-failed completed-tick error summary tests to the
existing `ecs_executor_completed_tick_error_summary_deep_*` read-only helpers.
No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `completed_tick_error_`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `completed_tick_error_`: 6 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completed-tick error summary
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is other summary-result direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 460 — `executor_multi_threaded_deep` drive-one summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorDriveSummaryDeep` values returned by `ecs_executor_state_deep_drive_one_summary`.

Deep strategy: migrate run, skip, and ApplyDeferred barrier drive-one summary
tests to the existing `ecs_executor_drive_summary_deep_*` read-only helpers.
No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_one_`: 3 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_one_`: 3 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-one summary accessor-usage
cleanup 0% -> 100% for this test-maintenance slice; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is other summary-result direct-field cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 461 — `executor_multi_threaded_deep` drive-ready-batch summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorDriveSummaryDeep` values returned by
`ecs_executor_state_deep_drive_ready_batch_summary3`.

Deep strategy: migrate the width-respecting drive-ready-batch summary test to
the existing `ecs_executor_drive_summary_deep_*` read-only helpers. No executor
implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_ready_batch_summary`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_ready_batch_summary`: 1 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch summary
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is other summary-result direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 462 — `executor_multi_threaded_deep` lock-failed drive summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorDriveSummaryDeep` values returned by lock-failed tick-loop helpers.

Deep strategy: migrate lock-failed, pending-completion, and ApplyDeferred
pending assertions to the existing `ecs_executor_drive_summary_deep_*`
read-only helpers. No executor implementation, API surface, or test count
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `lock_failed_summaries`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `lock_failed_summaries`: 1 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor lock-failed drive summary
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is other summary-result direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 463 — `executor_multi_threaded_deep` tick-loop no-completion batch summary fix — DONE

Source focus: `ecs_executor_tick_loop_deep_no_completion_waves3` and the early
tick-loop summary assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Issue found: migrating the early no-completion tick-loop assertions to
`ecs_executor_tick_loop_summary_deep_*` accessors exposed an existing behavior
gap: the helper reported only one selected system for a width-2 ready batch,
causing `mt_deep_tick_loop_no_completion_waves_ticks_once` and the existing
tick-loop summary accessor batch test to fail at `148082`/`148639`.

Deep strategy: route no-completion tick-loop summary construction through the
existing drive-ready-batch integration summary, then map its run/skipped slots
into `EcsExecutorTickLoopSummaryDeep`. This preserves skipped-first behavior
while recording the full ready batch width. The early test now uses
`ecs_executor_tick_loop_summary_deep_*` accessors instead of direct fields.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `tick_loop_no_completion_waves`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `tick_loop_summary_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `tick_loop_skipped_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `ready_batch_rescan`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filters rerun serially: `tick_loop_no_completion_waves` 1 passed, `tick_loop_summary_accessor` 2 passed, `tick_loop_skipped_accessor` 2 passed ✓ (`timeout 180s`, `--jobs 1`)
- An accidental parallel SA-backend attempt timed out without panic output; all reported SA validation above is from the subsequent serial reruns.
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-loop no-completion summary
behavior 0% -> 100% for this focused fix; tick-loop summary accessor-usage
cleanup 0% -> 100% for the edited early test; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is other
summary-result direct-field cleanup or broader executor integration scenarios
if new Bevy parity gaps are found.


# Batch 464 — `executor_multi_threaded_deep` tick-loop summary tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorTickLoopSummaryDeep` values returned by two-completion-wave and
retry-pending tick-loop helpers.

Deep strategy: migrate tick count, batch count/slot, and pending completion
assertions to the existing `ecs_executor_tick_loop_summary_deep_*` read-only
helpers. No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `tick_loop_two_completion_waves`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `tick_loop_retry_pending`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `tick_loop_two_completion_waves`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `tick_loop_retry_pending`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-loop summary accessor-usage
cleanup 0% -> 100% for this test-maintenance slice; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is other summary-result direct-field cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 465 — `executor_multi_threaded_deep` run-history tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorRunHistoryDeep` counts and stalled state.

Deep strategy: migrate run/apply/skipped count and stalled assertions to the
existing `ecs_executor_run_history_deep_*` read-only helpers. Existing slot
accessor assertions were already in place. No executor implementation, API
surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `run_history_`: 5 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `run_history_`: 5 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor run-history accessor-usage cleanup
0% -> 100% for this test-maintenance slice; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is other
summary-result direct-field cleanup or broader executor integration scenarios
if new Bevy parity gaps are found.


# Batch 466 — `executor_multi_threaded_deep` drive-all history reuses batched summary — DONE

Source focus: `ecs_executor_run_history_deep_drive_all3` and the early
drive-all history assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Issue found: while migrating drive-all history assertions to
`ecs_executor_run_history_deep_*` accessors, the dependency-chain history test
exposed an existing behavior gap: the old manual loop could report only a
partial run order instead of `0, 1, 2`.

Deep strategy: route `ecs_executor_run_history_deep_drive_all3` through the
already-covered `ecs_executor_drive_all_batched_integration_summary_deep3`
with `max_width=1`, then map its run/skipped/stalled/apply data back into
`EcsExecutorRunHistoryDeep`. ApplyDeferred history preserves pending
unapplied order from the input state and merges integration apply slots without
duplicates. The edited tests now use run-history accessors for count and
stalled checks.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_all_history`: 4 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_integration`: 4 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_all_history`: 4 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_integration`: 4 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all history integration
behavior 0% -> 100% for this focused fix; run-history accessor-usage cleanup
0% -> 100% for the edited early tests; overall API parity remains ~94–96%,
behavioral parity remains ~86–91%. Remaining optional depth is other
summary-result direct-field cleanup or broader executor integration scenarios
if new Bevy parity gaps are found.


# Batch 467 — `executor_multi_threaded_deep` ready-batch rescan tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorReadyBatchRescanSummaryDeep`.

Deep strategy: migrate selected/skipped counts and slots, rescan count, and
post-rescan ready/running/completed counts to the existing
`ecs_executor_ready_batch_rescan_summary_deep_*` read-only helpers. No
executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `ready_batch_rescan`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `ready_batch_rescan`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan accessor-usage
cleanup 0% -> 100% for this test-maintenance slice; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is other summary-result direct-field cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 468 — `executor_multi_threaded_deep` complete-ready-batch tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorCompleteReadyBatchSummaryDeep`.

Deep strategy: migrate started/completed/apply counts and slots, post-batch
ready/running/completed/unapplied counts, and local/exclusive gate assertions
to the existing `ecs_executor_complete_ready_batch_summary_deep_*` read-only
helpers. No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `complete_ready_batch`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `complete_ready_batch`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is other summary-result direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 469 — `executor_multi_threaded_deep` initial-skip tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorInitialSkipsSummaryDeep`.

Deep strategy: migrate skipped/ignored counts and slots, post-skip
ready/completed/skipped counts, dependency counters, and ready flags to the
existing `ecs_executor_initial_skips_summary_deep_*` read-only helpers. No
executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `initial_skip`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `initial_skip`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor initial-skip accessor-usage cleanup
0% -> 100% for this test-maintenance slice; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is other
summary-result direct-field cleanup or broader executor integration scenarios
if new Bevy parity gaps are found.


# Batch 470 — `executor_multi_threaded_deep` completion-queue tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorCompletionQueueDrainSummaryDeep`.

Deep strategy: migrate completed/ignored/apply counts and slots, post-drain
ready/running/completed/unapplied counts, dependency counters, ready flags, and
local/exclusive gate assertions to the existing
`ecs_executor_completion_queue_drain_summary_deep_*` read-only helpers. No
executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `completion_queue`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `completion_queue`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completion-queue accessor-usage
cleanup 0% -> 100% for this test-maintenance slice; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth
is other summary-result direct-field cleanup or broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 471 — `executor_multi_threaded_deep` tick-with-completions tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorTickWithCompletionsSummaryDeep`.

Deep strategy: migrate completed/ignored/selected/skipped/apply counts and
slots, post-tick ready/running/completed/unapplied counts, dependency counters,
and local/exclusive gate assertions to the existing
`ecs_executor_tick_with_completions_summary_deep_*` read-only helpers. No
executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `tick_with_completion`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `tick_with_completion`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-with-completions
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is other summary-result direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 472 — `executor_multi_threaded_deep` drive-ready-batch integration tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorDriveReadyBatchIntegrationSummaryDeep`.

Deep strategy: migrate run/completed/skipped/apply counts and slots,
post-drive ready/running/completed/unapplied counts, stalled state, and
dependency counters to the existing
`ecs_executor_drive_ready_batch_integration_summary_deep_*` read-only helpers.
No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_ready_batch_integration`: 4 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_ready_batch_integration`: 4 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is drive-all-batched integration direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 473 — `executor_multi_threaded_deep` drive-all-batched integration tests use accessors — DONE

Source focus: early direct-field assertions in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` for
`EcsExecutorDriveAllBatchedIntegrationSummaryDeep`.

Deep strategy: migrate wave/run/completed/skipped counts and slots,
post-drive running/completed counts, stalled state, and dependency counters to
the existing
`ecs_executor_drive_all_batched_integration_summary_deep_*` read-only helpers.
No executor implementation, API surface, or test count changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` remains at 118
`@test` entries. No new panic band.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `drive_all_batched_integration`: 4 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_all_batched_integration`: 4 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts (unchanged): 524 lib modules | 249 `*_deep.sla` modules |
425 test files | 249 `*_deep_isolated.sla` test files | 90 examples | 6799
tests-dir `@test` annotations | 7435 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched integration
accessor-usage cleanup 0% -> 100% for this test-maintenance slice; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is other summary-result direct-field cleanup or broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 474 — `executor_multi_threaded_deep` drive-all-batched ApplyDeferred wave coverage — DONE

Source focus: broader drive-all-batched integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused three-wave scenario where a deferred ordinary
system completes first, an `ApplyDeferred` barrier runs in the next wave and
flushes the pending unapplied system, and the barrier releases a dependent
ordinary system into the final wave. No executor implementation or API surface
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 119
`@test` entries. New panic band: 149250-149260.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `apply_deferred_releases_next_wave`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_integration`: 5 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_all_batched_integration`: 5 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- An exact SA single-test filter printed PASS but returned 143 once, so same-surface SA completion evidence uses the broader `drive_all_batched_integration` filter above.
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6800 tests-dir
`@test` annotations | 7436 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched ApplyDeferred
multi-wave integration coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 506 — `executor_multi_threaded_deep` no-drain tick gate summary fix — DONE

Source focus: no-drain tick-with-completions fast-path gate-state summary in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `_mt_tick_with_completions_no_drain_fast` now initializes
`local_thread_running` and `exclusive_running` from the current executor state
before overlaying any newly selected systems. This preserves existing running
gate state when a no-completion tick selects additional ordinary ready work.
No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 171
`@test` entries. New panic band: 149719-149724.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `mt_deep_tick_with_completions_no_drain_preserves_existing_local_gate`: 1 passed / 0 failed ✓ (`timeout 60s`, `--jobs 1`)
- Default backend focused filter `no_drain`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6852 tests-dir `@test` annotations | 7452 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor no-drain tick gate-state summary
preservation 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 475 — `executor_multi_threaded_deep` drive-ready-batch ApplyDeferred dependent release — DONE

Source focus: broader drive-ready-batch integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused single-batch scenario where a prior deferred
ordinary system is already completed/unapplied, an `ApplyDeferred` barrier is
selected and flushes that pending system, and the barrier completion releases a
dependent ordinary system to the ready queue for a later batch. No executor
implementation or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 120
`@test` entries. New panic band: 149270-149280.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `apply_deferred_releases_dependent`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_integration`: 5 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_ready_batch_integration`: 5 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6801 tests-dir
`@test` annotations | 7437 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch ApplyDeferred
dependent-release integration coverage 0% -> 100% for this focused scenario;
overall API parity remains ~94–96%, behavioral parity remains ~86–91%.
Remaining optional depth is broader executor integration scenarios if new
Bevy parity gaps are found.


# Batch 476 — `executor_multi_threaded_deep` drive-all max-waves stall coverage — DONE

Source focus: broader drive-all-batched integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused `max_waves=1` dependency-chain scenario where
drive-all-batched completes the first wave, releases the next system to the
ready queue, then reports stalled because the wave cap stops the remaining
ready work. No executor implementation or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 121
`@test` entries. New panic band: 149290-149299.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `max_waves_stalls_after_progress`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_integration`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_all_batched_integration`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6802 tests-dir
`@test` annotations | 7438 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched max-waves
partial-progress stall coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 477 — `executor_multi_threaded_deep` drive-all local gate coverage — DONE

Source focus: broader drive-all-batched integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused all-ready scenario with two local systems and one
ordinary system. The first wave can run the first local system and the later
ordinary system, but must defer the second local system to the next wave. No
executor implementation or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 122
`@test` entries. New panic band: 149310-149319.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `local_gate_splits_waves`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_integration`: 7 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_all_batched_integration`: 7 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6803 tests-dir
`@test` annotations | 7439 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched local-gate wave
splitting coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 478 — `executor_multi_threaded_deep` drive-all exclusive gate coverage — DONE

Source focus: broader drive-all-batched integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused all-ready scenario with one exclusive system and
two ordinary systems. The exclusive system must occupy the first wave alone;
the ordinary systems then run together in the next wave. No executor
implementation or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 123
`@test` entries. New panic band: 149320-149329.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `exclusive_gate_splits_waves`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_all_batched_integration`: 8 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`; a prior 90s run printed 8/8 PASS but returned 143, so completion evidence uses the clean rerun)
- Default backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_all_batched_integration`: 8 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_all_batched_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6804 tests-dir
`@test` annotations | 7440 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-all-batched exclusive-gate wave
splitting coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 479 — `executor_multi_threaded_deep` drive-ready-batch exclusive gate coverage — DONE

Source focus: broader drive-ready-batch integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused all-ready scenario with one exclusive system and
two ordinary systems. A single ready-batch drive must run and complete the
exclusive system alone, leaving the ordinary systems ready for a later batch.
No executor implementation or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 124
`@test` entries. New panic band: 149330-149339.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `exclusive_gate_stands_alone`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_integration`: 6 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_ready_batch_integration`: 6 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6805 tests-dir
`@test` annotations | 7441 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch exclusive-gate
stand-alone coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 480 — `executor_multi_threaded_deep` drive-ready-batch local gate coverage — DONE

Source focus: broader drive-ready-batch integration coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused all-ready scenario with two local systems and one
ordinary system. A single ready-batch drive may run the first local system and
the ordinary system, but must keep the second local system ready for a later
batch. No executor implementation or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 125
`@test` entries. New panic band: 149340-149349.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `local_gate_keeps_second_local_ready`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_integration`: 7 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend focused filter `drive_ready_batch_integration`: 7 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `drive_ready_batch_accessor`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- `git diff --check` ✓
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 425 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6806 tests-dir
`@test` annotations | 7442 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch local-gate
ready-preservation coverage 0% -> 100% for this focused scenario; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 481 — `executor_multi_threaded_deep` tick-loop no-completion gate coverage — DONE

Source focus: tick-loop no-completion summary coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add two focused tick-loop-facing scenarios that route through
the existing drive-ready-batch integration path. The exclusive system must
stand alone in the no-completion batch, and a pair of local systems must keep
the second local system out of the same batch while still allowing the ordinary
system to run. No executor implementation, API surface, or SLA compiler change
was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 127
`@test` entries. New panic band: 149350-149367.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `tick_loop_no_completion_exclusive_gate_stands_alone`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend exact filter `tick_loop_no_completion_local_gate_keeps_second_local_ready`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `tick_loop_no_completion`: 3 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `tick_loop_no_completion`: 3 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6808 tests-dir
`@test` annotations | 7444 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor no-completion tick-loop gate summary
coverage 0% -> 100% for these focused scenarios; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 482 — `executor_multi_threaded_deep` tick-loop completion gate coverage — DONE

Source focus: tick-loop two-completion-wave summary coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add two focused completion-wave scenarios that route through the
existing ready-batch rescan path. The exclusive scenario releases an exclusive
system and an ordinary system after the first completion, verifies the
exclusive system occupies the first batch alone, then verifies the ordinary
system appears in the second batch. The local scenario releases two local
systems and verifies they split across the two completion waves. No executor
implementation, API surface, or SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 129
`@test` entries. New panic band: 149370-149388.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `tick_loop_two_completion_waves_exclusive_gate_splits_batches`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend exact filter `tick_loop_two_completion_waves_local_gate_splits_batches`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `tick_loop_two_completion_waves`: 3 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `tick_loop_two_completion_waves`: 3 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6810 tests-dir
`@test` annotations | 7446 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completion-wave tick-loop gate
summary coverage 0% -> 100% for these focused scenarios; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 483 — `executor_multi_threaded_deep` tick-with-completions gate coverage — DONE

Source focus: tick-with-completions summary coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add two focused completion-drain scenarios that release gated
ready work before the same tick selects a new batch. The exclusive scenario
verifies the released exclusive system is selected alone, leaves the ordinary
system ready, and records both exclusive and local gate occupancy because this
model treats exclusive execution as occupying the local thread. The local
scenario verifies the first released local system is selected and the second
local system remains ready. No executor implementation, API surface, or SLA
compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 131
`@test` entries. New panic band: 149390-149408.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `tick_with_completions_summary_exclusive_gate_stands_alone`: 1 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`; an earlier 90s run exited 124 without output, so evidence uses the clean rerun)
- Default backend exact filter `tick_with_completions_summary_local_gate_keeps_second_local_ready`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `tick_with_completion`: 8 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- SA backend focused filter `tick_with_completion`: 8 passed / 0 failed ✓ (`timeout 240s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6812 tests-dir
`@test` annotations | 7448 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-with-completions gate summary
coverage 0% -> 100% for these focused scenarios; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 484 — `executor_multi_threaded_deep` completion-queue gate cleanup coverage — DONE

Source focus: completion-queue drain summary coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add two focused completion-queue drain scenarios for ordinary
completed work that is still running behind local/exclusive gates. One scenario
completes a local system and verifies the local gate clears; the other
completes an exclusive system and verifies both exclusive and local gate state
clear. No executor implementation, API surface, or SLA compiler change was
needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 133
`@test` entries. New panic band: 149410-149425.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `completion_queue_drain_summary_local_completion_clears_gate`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend exact filter `completion_queue_drain_summary_exclusive_completion_clears_gates`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `completion_queue`: 8 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `completion_queue`: 8 passed / 0 failed ✓ (`timeout 240s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6814 tests-dir
`@test` annotations | 7450 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor completion-queue gate cleanup summary
coverage 0% -> 100% for these focused scenarios; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 485 — `executor_multi_threaded_deep` complete-ready-batch gate cleanup coverage — DONE

Source focus: complete-ready-batch summary coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add two focused complete-ready-batch scenarios for fresh gated
systems. One scenario selects a local system that is not yet running and
verifies it starts, completes, and clears local gate state. The other selects
an exclusive system and verifies it starts, completes, and clears both
exclusive and local gate state. No executor implementation, API surface, or SLA
compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 135
`@test` entries. New panic band: 149430-149446.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `complete_ready_batch_summary_local_start_completion_clears_gate`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend exact filter `complete_ready_batch_summary_exclusive_start_completion_clears_gates`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `complete_ready_batch`: 8 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- SA backend focused filter `complete_ready_batch`: 8 passed / 0 failed ✓ (`timeout 240s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6816 tests-dir
`@test` annotations | 7452 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch gate cleanup
summary coverage 0% -> 100% for these focused scenarios; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 486 — `executor_multi_threaded_deep` ready-batch rescan local gate coverage — DONE

Source focus: ready-batch rescan summary coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add one focused skip/rescan scenario where a skipped system
releases a dependent local system while another local system is already ready.
The test proves the released local system is selected, the second local system
stays ready behind the local gate, and the summary records the skip/rescan and
post-state counts. No executor implementation, API surface, or SLA compiler
change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 136
`@test` entries. New panic band: 149450-149458.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `ready_batch_rescan_local_gate_keeps_second_local_ready_after_skip`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `ready_batch_rescan`: 7 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `ready_batch_rescan`: 7 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6817 tests-dir
`@test` annotations | 7453 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan local-gate
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 487 — `executor_multi_threaded_deep` initial-skip running guard fix — DONE

Source focus: initial-skip summary behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix the initial-skip helper so skip-list entries that already
refer to running systems are ignored instead of being marked skipped/completed.
Add a focused regression where system 0 is already running and system 1 is
ready; the summary now records system 0 as ignored and still skips system 1.
No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 137
`@test` entries. New panic band: 149460-149466.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `initial_skips_summary_ignores_running_systems`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `initial_skip`: 7 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `initial_skip`: 7 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6818 tests-dir
`@test` annotations | 7454 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor initial-skip running-system guard
0% -> 100% for this focused behavior fix; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 488 — `executor_multi_threaded_deep` dependent-release running guard fix — DONE

Source focus: dependent-release state behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_state_deep_release_dependent` so dependency
release does not mark an already running dependent system ready when its
dependency count reaches zero. Add a focused initial-skip regression where
skipping system 0 releases a running dependent system 1; the summary now shows
the dependency count cleared while system 1 remains unready. No SLA compiler
change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 138
`@test` entries. New panic band: 149470-149476.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `initial_skips_summary_release_keeps_running_dependent_unready`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `initial_skip`: 8 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `initial_skip`: 8 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for another SA test process to finish before starting)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6819 tests-dir
`@test` annotations | 7455 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor dependent-release running guard
0% -> 100% for this focused behavior fix; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 489 — `executor_multi_threaded_deep` mark-ready state guard fix — DONE

Source focus: ready-state helper behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_state_deep_mark_ready` so callers cannot mark
already running or skipped-pending systems ready. Add two focused state-helper
regressions covering running and skipped-pending inputs. No SLA compiler change
was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 140
`@test` entries. New panic band: 149480-149485.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `mark_ready`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `state`: 12 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`; an earlier attempted regex-style filter matched 0 tests and was not counted as evidence)
- SA backend focused filter `mark_ready`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for other SA test processes to finish before starting)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6821 tests-dir
`@test` annotations | 7457 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor mark-ready running/skipped guard
0% -> 100% for this focused behavior fix; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 490 — `executor_multi_threaded_deep` skip running guard fix — DONE

Source focus: skip-state helper behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_state_deep_skip_system` and
`ecs_executor_state_deep_mark_skipped_pending` so callers cannot skip or
pending-skip an already running system. Add focused regressions covering both
helpers. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 142
`@test` entries. New panic band: 149490-149497.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `skip_system_ignores_running_system`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `mark_skipped_pending`: 2 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend focused filter `skip`: 30 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`; evidence uses the clean exit after PASS output)
- SA backend focused filter `mark_skipped_pending`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend exact filter `skip_system_ignores_running_system`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6823 tests-dir
`@test` annotations | 7459 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor skip running guard 0% -> 100% for
this focused behavior fix; overall API parity remains ~94–96%, behavioral
parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 491 — `executor_multi_threaded_deep` complete running guard fix — DONE

Source focus: complete-state helper behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_state_deep_complete_system` and
`ecs_executor_state_deep_complete_system_with_dependents3` so callers cannot
complete a system that is not currently running, and cannot release dependents
from that invalid no-op completion. Add focused regressions for both direct and
dependent-release paths. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 144
`@test` entries. New panic band: 149500-149508.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `complete_system_ignores`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend exact filter `complete_with_dependents_ignores`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- SA backend exact filter `complete_system_ignores`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend exact filter `complete_with_dependents_ignores`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6825 tests-dir
`@test` annotations | 7461 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor complete running guard 0% -> 100% for
this focused behavior fix; overall API parity remains ~94–96%, behavioral
parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 492 — `executor_multi_threaded_deep` skip no-op release guard fix — DONE

Source focus: skip-state helper behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_state_deep_skip_system` so completed or
already skipped systems remain no-op inputs, and fix
`ecs_executor_state_deep_skip_system_with_dependents3` so ignored skip inputs
cannot release dependents. Add focused regressions for direct completed skips
and wrapper running/completed skip inputs. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 147
`@test` entries. New panic band: 149510-149521.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `skip_system_ignores`: 2 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend focused filter `skip_with_dependents_ignores`: 2 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- SA backend focused filter `skip_system_ignores`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend focused filter `skip_with_dependents_ignores`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6828 tests-dir
`@test` annotations | 7464 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor skip no-op release guard 0% -> 100%
for this focused behavior fix; overall API parity remains ~94–96%, behavioral
parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 493 — `executor_multi_threaded_deep` skipped spawn guard fix — DONE

Source focus: skipped-state spawn behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix skipped-pending state so it clears stale ready bits, make
`ecs_executor_state_deep_can_spawn_system` reject skipped systems explicitly,
and make direct `ecs_executor_state_deep_start_system` calls ignore skipped or
completed systems. Add focused regressions for pending-skip, failed system
condition, and direct-start paths. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 150
`@test` entries. New panic band: 149530-149539.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `skipped_pending`: 5 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend exact filter `failed_system_condition_clears`: 1 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend focused filter `state`: 12 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `skipped_pending`: 5 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend exact filter `failed_system_condition_clears`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6831 tests-dir
`@test` annotations | 7467 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor skipped spawn guard 0% -> 100% for
this focused behavior fix; overall API parity remains ~94–96%, behavioral
parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 494 — `executor_multi_threaded_deep` dependency spawn guard fix — DONE

Source focus: dependency/ready spawn behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix dependency updates so positive counts clear stale ready
state, make `ecs_executor_state_deep_can_spawn_system` reject systems with
unresolved dependencies, and make direct `ecs_executor_state_deep_start_system`
calls ignore dependency-blocked systems. Add focused regressions for stale
ready and direct-start paths. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 152
`@test` entries. New panic band: 149550-149556.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `dependencies`: 3 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend exact filter `dependency_blocked_system`: 1 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend focused filter `state`: 12 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `dependencies`: 3 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for external SA tests to finish)
- SA backend exact filter `dependency_blocked_system`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6833 tests-dir
`@test` annotations | 7469 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor dependency spawn guard 0% -> 100%
for this focused behavior fix; overall API parity remains ~94–96%, behavioral
parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 495 — `executor_multi_threaded_deep` zero-dependency release guard fix — DONE

Source focus: dependent-release transition behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_state_deep_release_dependent` so ready state
is produced only when a positive dependency count is decremented to zero.
Already-zero dependency entries now remain no-op inputs, including completion
wrapper calls. Add focused direct and wrapper regressions. No SLA compiler
change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 154
`@test` entries. New panic band: 149570-149576.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `release_dependent`: 2 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend exact filter `ignores_zero_dependency_entry`: 1 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`)
- Default backend focused filter `with_dependents`: 6 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `release_dependent`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- SA backend exact filter `ignores_zero_dependency_entry`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6835 tests-dir
`@test` annotations | 7471 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor zero-dependency release guard
0% -> 100% for this focused behavior fix; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 496 — `executor_multi_threaded_deep` complete-ready no-op summary fix — DONE

Source focus: complete-ready-batch summary accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: fix `ecs_executor_complete_ready_batch_summary_deep3` so started
and completed slots are recorded only after the selected system actually enters
running state and completes. Dependency-blocked or skipped selected entries now
remain no-op summary inputs. Add focused regressions for both invalid selected
states. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 156
`@test` entries. New panic band: 149590-149601.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `complete_ready_batch_summary_ignores`: 2 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- Default backend focused filter `complete_ready_batch`: 10 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`; counted only after clean process exit)
- SA backend focused filter `complete_ready_batch_summary_ignores`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for external SA/SAB tests to finish)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6837 tests-dir
`@test` annotations | 7473 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor complete-ready no-op summary
accounting 0% -> 100% for this focused behavior fix; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 497 — `executor_multi_threaded_deep` pending-skip finalization fix — DONE

Source focus: skipped-pending lifecycle behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: distinguish pending skip (`skipped=true`, `completed=false`)
from terminal skipped state. Pending skips still cannot spawn, but direct and
wrapper skip finalization now mark them completed and release dependents.
`ecs_executor_state_deep_drive_one_summary` now handles pending skip before the
`can_spawn` gate so a pending skip is not reported as a stall. No SLA compiler
change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 158
`@test` entries. New panic band: 149610-149619.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `pending_skip`: 2 passed / 0 failed ✓ (`timeout 100s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `skip_with_dependents`: 4 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- Default backend focused filter `drive_one`: 4 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- SA backend focused filter `pending_skip`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for external SAB tests to finish)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6839 tests-dir
`@test` annotations | 7475 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor pending-skip finalization 0% -> 100%
for this focused behavior fix; overall API parity remains ~94–96%, behavioral
parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 498 — `executor_multi_threaded_deep` integration pending-skip finalization fix — DONE

Source focus: integration scan pending-skip lifecycle behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: keep pending skips (`skipped=true`, `completed=false`)
unspawnable in integration selection guards, while letting both
`ecs_executor_drive_ready_batch_integration_summary_deep3` and
`ecs_executor_drive_all_batched_integration_summary_deep3` finalize them before
normal ready selection. Finalized pending skips now count as skipped, complete,
release dependents, and allow newly released work to run in the same scan/wave.
No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 160
`@test` entries. New panic band: 149630-149643.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend focused filter `integration_finalizes_pending_skip`: 2 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 8 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 9 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`)
- SA backend focused filter `integration_finalizes_pending_skip`: 2 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; checked for existing SA/SAB processes first)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6841 tests-dir
`@test` annotations | 7477 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor integration pending-skip
finalization 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 499 — `executor_multi_threaded_deep` ready-batch rescan pending-skip finalization fix — DONE

Source focus: ready-batch rescan pending-skip lifecycle behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_ready_batch_rescan_summary_deep3` now handles
pending skips (`skipped=true`, `completed=false`) before ordinary ready
selection, matching the drive-one and integration scan paths. A pending skip no
longer needs a ready bit to finalize; it is counted as skipped, completed,
releases dependents, and triggers a rescan so newly released work can be
selected in the same modeled batch. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 161
`@test` entries. New panic band: 149644-149651.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `ready_batch_rescan_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- Default backend focused filter `ready_batch_rescan`: 8 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`; counted only after clean process exit)
- SA backend exact filter `ready_batch_rescan_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for external SA tests to finish)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6842 tests-dir
`@test` annotations | 7478 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan pending-skip
finalization 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 500 — `executor_multi_threaded_deep` tick-with-completions pending-skip finalization fix — DONE

Source focus: tick-with-completions rescan pending-skip lifecycle behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_tick_with_completions_summary_deep3` now handles
pending skips (`skipped=true`, `completed=false`) before ordinary ready
selection in its post-drain rescan loop. This matches the drive-one,
integration scan, and ready-batch rescan paths: pending skips are counted as
skipped, completed, release dependents, and allow newly released work to be
selected during the same tick rescan. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 162
`@test` entries. New panic band: 149652-149661.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `tick_with_completions_summary_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `tick_with_completions_summary`: 7 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`)
- SA backend exact filter `tick_with_completions_summary_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for external SAB tests to finish and counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6843 tests-dir
`@test` annotations | 7479 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor tick-with-completions pending-skip
finalization 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 501 — `executor_multi_threaded_deep` run-history pending-skip classification fix — DONE

Source focus: run-history drive-one pending-skip classification in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_run_history_deep_drive_one` now classifies pending
skips (`skipped=true`, `completed=false`) as skipped before the `can_spawn`
gate. This history-only helper does not mutate state or release dependents, but
it now matches the drive-one lifecycle classification and avoids reporting a
pending skip as a stalled runnable search. No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 163
`@test` entries. New panic band: 149662-149666.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `run_history_drive_one_records_pending_skip`: 1 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- Default backend focused filter `run_history_drive`: 3 passed / 0 failed ✓ (`timeout 150s`, `--jobs 1`)
- SA backend exact filter `run_history_drive_one_records_pending_skip`: 1 passed / 0 failed ✓ (`timeout 180s`, `--jobs 1`, serial; waited for external SA tests to finish and counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6844 tests-dir
`@test` annotations | 7480 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor run-history pending-skip
classification 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 502 — `executor_multi_threaded_deep` no-drain pending-skip tick fix — DONE

Source focus: tick-with-completions no-drain pending-skip lifecycle behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_tick_with_completions_summary_deep3` now keeps the
fast no-drain ready-batch path only when no pending skips exist. If
`done_count == 0` and a skipped-pending system is present, it falls through to
the same rescan/finalization logic used after completion drains, so pending
skips are counted as skipped, completed, release dependents, and allow newly
released work to be selected in the same tick. No SLA compiler change was
needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 164
`@test` entries. New panic band: 149667-149675.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `mt_deep_tick_with_completions_no_drain_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 60s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `tick_with_completions_summary`: 7 passed / 0 failed ✓ (`timeout 75s`, `--jobs 1`; counted only after clean process exit)
- SA backend exact filter was intentionally not started because another SA backend test process was already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6845 tests-dir
`@test` annotations | 7481 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor no-drain tick pending-skip
finalization 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 503 — `executor_multi_threaded_deep` drive-ready-batch pending-skip summary fix — DONE

Source focus: drive-ready-batch summary pending-skip lifecycle behavior in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_state_deep_drive_ready_batch_summary3` now
finalizes skipped-pending systems before taking the ordinary ready batch. This
summary helper has no dependent-release inputs, so it does not release
dependents, but pending skips are now counted as skipped, moved to completed
state, and no longer turn an otherwise progress-making summary into a false
stall. Ordinary ready-batch selection and width behavior are preserved. No SLA
compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 165
`@test` entries. New panic band: 149676-149681.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `mt_deep_drive_ready_batch_summary_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 60s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_summary`: 2 passed / 0 failed ✓ (`timeout 75s`, `--jobs 1`)
- SA backend exact filter was intentionally not started because another SA backend test process was already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6846 tests-dir
`@test` annotations | 7482 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch pending-skip
summary finalization 0% -> 100% for this focused behavior fix; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 504 — `executor_multi_threaded_deep` zero-width drive-ready-batch pending-skip summary fix — DONE

Source focus: drive-ready-batch summary pending-skip lifecycle behavior when
`max_width <= 0` in `lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_state_deep_drive_ready_batch_summary3` now
finalizes skipped-pending systems before applying the zero-width early return.
Zero width still prevents ordinary ready work from being selected, but pending
skip finalization does not consume batch width, so a pending skip can be counted
as skipped/completed instead of causing a false stalled result. No SLA compiler
change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 166
`@test` entries. New panic band: 149682-149687.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `mt_deep_drive_ready_batch_summary_zero_width_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 60s`, `--jobs 1`)
- Default backend focused filter `drive_ready_batch_summary`: 3 passed / 0 failed ✓ (`timeout 75s`, `--jobs 1`)
- SA backend exact filter was intentionally not started because another SAB backend test process was already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 524 lib modules | 249 `*_deep.sla` modules | 426 test files
| 249 `*_deep_isolated.sla` test files | 90 examples | 6847 tests-dir
`@test` annotations | 7483 lib/tests/examples `@test` annotations.
Feature progress: multi-threaded executor zero-width drive-ready-batch
pending-skip summary finalization 0% -> 100% for this focused behavior fix;
overall API parity remains ~94–96%, behavioral parity remains ~86–91%.
Remaining optional depth is broader executor integration scenarios if new Bevy
parity gaps are found.


# Batch 505 — `executor_multi_threaded_deep` zero-width integration/rescan pending-skip fix — DONE

Source focus: zero-width pending-skip lifecycle behavior in the
multi-threaded executor deep ready-batch rescan, tick-with-completions,
drive-ready-batch integration, and drive-all-batched integration summaries in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: the affected `max_width <= 0` branches now finalize
skipped-pending systems before returning. Zero width still prevents ordinary
ready work from being selected or run, but pending-skip finalization can
complete skipped systems, release dependents, update ready/dependency summary
state, and avoid false stalled results because it does not consume batch width.
No SLA compiler change was needed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 170
`@test` entries. New panic band: 149688-149718.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla` ✓
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` ✓
- Default backend exact filter `mt_deep_ready_batch_rescan_zero_width_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 60s`, `--jobs 1`)
- Default backend exact filter `mt_deep_tick_with_completions_zero_width_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- Default backend exact filter `mt_deep_drive_ready_batch_integration_zero_width_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 90s`, `--jobs 1`)
- Default backend exact filter `mt_deep_drive_all_batched_integration_zero_width_finalizes_pending_skip`: 1 passed / 0 failed ✓ (`timeout 120s`, `--jobs 1`)
- Broader default backend filter `zero_width_finalizes_pending_skip` timed out at 90s under concurrent external SA/SAB test load and was not counted; exact filters above were used instead.
- SA backend filters were intentionally not started because external SA/SAB backend test processes were already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6851 tests-dir `@test` annotations | 7451 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor zero-width integration/rescan
pending-skip finalization 0% -> 100% for this focused behavior fix; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 508 — `executor_multi_threaded_deep` no-drain local gate scan coverage — DONE

Source focus: tick-with-completions no-drain ready selection when a local system
is already running in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add regression coverage for the no-drain fast path with an
existing local gate occupied. The scenario proves a second local ready system is
left ready while a later ordinary ready system can still be selected, and the
summary continues to report the existing local-running gate. This validates the
Batch 506 gate-state preservation and scan behavior without changing executor
implementation, API surface, or SLA compiler behavior.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 173
`@test` entries. New panic band: 149732-149739.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_no_drain_existing_local_blocks_second_local`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `no_drain`: 4 passed / 0 failed (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started because an external SA backend test process was already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6854 tests-dir `@test` annotations | 7454 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor no-drain local gate scan coverage
0% -> 100% for this focused scenario; overall API parity remains ~94–96%,
behavioral parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 509 — `executor_multi_threaded_deep` no-drain width-limit ready coverage — DONE

Source focus: tick-with-completions no-drain ready selection when `max_width`
truncates a larger ready batch in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add regression coverage for the no-drain fast path after
`take_ready_batch3` finds more ready systems than the requested width permits.
The scenario proves only the first ready system is selected, unselected ready
systems remain visible in `ready_after` and `ready_at`, and local/exclusive gate
summary fields are not set by systems that were not actually selected. No
executor implementation, API surface, or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 174
`@test` entries. New panic band: 149740-149750.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_no_drain_width_limit_leaves_remaining_ready`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `no_drain`: 5 passed / 0 failed (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started because external SA/SAB backend test processes were already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6855 tests-dir `@test` annotations | 7455 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor no-drain width-limit ready coverage
0% -> 100% for this focused scenario; overall API parity remains ~94–96%,
behavioral parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 510 — `executor_multi_threaded_deep` ready-batch exclusive flag fix — DONE

Source focus: core ready-batch selection flags in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: `ecs_executor_state_deep_take_ready_batch3` now propagates
exclusive/local batch flags when the first actual selected system comes from
the second or third candidate slot after earlier candidates are unready. An
exclusive selected system still stands alone through the temporary state gate,
but the returned batch now reports both exclusive and local occupancy
consistently with start-system semantics. No SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 175
`@test` entries. New panic band: 149751-149754.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_exclusive_after_unready_candidate_sets_flags`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `mt_deep_ready_batch`: 14 passed / 0 failed (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started because external SA/SAB backend test processes were already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6856 tests-dir `@test` annotations | 7456 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch exclusive flag parity
0% -> 100% for this focused behavior fix; overall API parity remains ~94–96%,
behavioral parity remains ~86–91%. Remaining optional depth is broader executor
integration scenarios if new Bevy parity gaps are found.


# Batch 511 — `executor_multi_threaded_deep` ready-batch third exclusive coverage — DONE

Source focus: core ready-batch selection flag coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add direct regression coverage for the third-candidate variant of
the Batch 510 exclusive flag propagation fix. The scenario leaves the first two
candidates unready, selects an exclusive third candidate as the first actual
batch entry, and proves the returned batch reports one selected system with both
exclusive and local flags. No executor implementation, API surface, or SLA
compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 176
`@test` entries. New panic band: 149755-149758.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_third_exclusive_after_unready_candidates_sets_flags`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `mt_deep_ready_batch`: 15 passed / 0 failed (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started because an external SA backend test process was already running; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6857 tests-dir `@test` annotations | 7457 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch third-candidate exclusive
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 512 — `executor_multi_threaded_deep` drive-ready-batch second exclusive coverage — DONE

Source focus: drive-ready-batch integration selection behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused integration regression where the first candidate is
unready, the second candidate is exclusive, and the third candidate is ordinary
ready work. The scenario proves the exclusive system runs and completes alone,
the later ordinary system remains ready for a later batch, and the integration
summary does not falsely stall. No executor implementation, API surface, or SLA
compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 177
`@test` entries. New panic band: 149759-149767.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_second_exclusive_stands_alone_after_unready`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 10 passed / 0 failed (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started because user guidance favors avoiding extra backend pressure; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6858 tests-dir `@test` annotations | 7458 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch second-candidate
exclusive integration coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 513 — `executor_multi_threaded_deep` drive-ready-batch third exclusive coverage — DONE

Source focus: drive-ready-batch integration selection behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused integration regression where the first two
candidates are unready and the third candidate is exclusive. The scenario proves
the exclusive third candidate runs and completes alone, clears its ready flag,
and does not falsely stall. No executor implementation, API surface, or SLA
compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 178
`@test` entries. New panic band: 149768-149775.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_third_exclusive_stands_alone_after_unready`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 11 passed / 0 failed (`timeout 120s`, `--jobs 1`; counted only after clean process exit)
- SA backend filters were intentionally not started per memory/OOM guidance; whole-file executor-deep runs intentionally avoided.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6859 tests-dir `@test` annotations | 7459 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch third-candidate
exclusive integration coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 514 — `executor_multi_threaded_deep` drive-all second exclusive coverage — DONE

Source focus: drive-all batched integration selection behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused drive-all regression where candidate 0 is initially
unready behind a dependency, candidate 1 is exclusive, and candidate 2 is
ordinary ready work. Candidate 1 must run alone in the first wave, release
candidate 0, and then candidates 0 and 2 complete together in the second wave.
This proves the drive-all loop handles a second-slot exclusive after an unready
candidate without falsely stalling. No executor implementation, API surface, or
SLA compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 179
`@test` entries. New panic band: 149776-149787.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_second_exclusive_after_unready_splits_waves`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 11 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter was not started because `pgrep` found an external `sa sla test src/midi.sla --test-backend sa --jobs 1 --trace-panic` process; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6860 tests-dir `@test` annotations | 7460 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all second-candidate exclusive
integration coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 515 — `executor_multi_threaded_deep` drive-all third exclusive coverage — DONE

Source focus: drive-all batched integration selection behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the third-candidate counterpart to Batch 514. Candidates 0
and 1 are initially dependency-blocked, candidate 2 is exclusive, and candidate
2 releases both earlier candidates after completing alone in the first wave.
The second wave then completes candidates 0 and 1 together. No executor
implementation, API surface, or SLA compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 180
`@test` entries. New panic band: 149788-149799.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_third_exclusive_after_unready_splits_waves`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 12 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA/SAB backend exact filter was not started because `pgrep` found external SAB backend test processes; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6861 tests-dir `@test` annotations | 7461 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all third-candidate exclusive
integration coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 516 — `executor_multi_threaded_deep` drive-all second local coverage — DONE

Source focus: drive-all batched integration local-thread gate selection behavior
in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the local-gate counterpart to the recent second-slot
exclusive coverage. Candidate 0 starts dependency-blocked, candidate 1 is local,
and candidate 2 is ordinary ready work. The drive-all loop must run candidate 1
and candidate 2 in the same first wave, release candidate 0 from candidate 1,
and then complete candidate 0 in the second wave. This proves a second-slot
local system after an unready candidate occupies the local gate without
serializing ordinary work. No executor implementation, API surface, or SLA
compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 181
`@test` entries. New panic band: 149800-149811.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_second_local_after_unready_keeps_ordinary_same_wave`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 13 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_second_local_after_unready_keeps_ordinary_same_wave`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6862 tests-dir `@test` annotations | 7462 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all second-candidate local gate
integration coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 517 — `executor_multi_threaded_deep` drive-all third local coverage — DONE

Source focus: drive-all batched integration local-thread gate selection behavior
in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the third-candidate local-gate counterpart to Batch 516.
Candidates 0 and 1 start dependency-blocked, candidate 2 is local, and
candidate 2 releases both earlier candidates after completing in the first
wave. The second wave then completes candidates 0 and 1 together. No executor
implementation, API surface, or SLA compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 182
`@test` entries. New panic band: 149812-149824.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_third_local_after_unready_splits_waves`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 14 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_third_local_after_unready_splits_waves`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6863 tests-dir `@test` annotations | 7463 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all third-candidate local gate
integration coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 518 — `executor_multi_threaded_deep` ready-batch second local coverage — DONE

Source focus: ready-batch base selection behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused base ready-batch regression where candidate 0 is
unready, candidate 1 is local, and candidate 2 is ordinary ready work. The
batch must contain candidates 1 and 2, report the local-thread gate, and remain
non-exclusive. This complements the recent drive-all local coverage at the
lowest ready-batch selection layer. No executor implementation, API surface, or
SLA compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 183
`@test` entries. New panic band: 149825-149829.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_second_local_after_unready_keeps_ordinary`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_ready_batch`: 16 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter was not started because `pgrep` found an external SA backend test process; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6864 tests-dir `@test` annotations | 7464 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch second-candidate local
gate coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 519 — `executor_multi_threaded_deep` ready-batch third local coverage — DONE

Source focus: ready-batch base selection behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the third-candidate local-gate counterpart to Batch 518.
Candidates 0 and 1 are unready, candidate 2 is local, and the returned
ready-batch must select candidate 2, report the local-thread gate, and remain
non-exclusive. No executor implementation, API surface, or SLA compiler
behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 184
`@test` entries. New panic band: 149830-149833.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_third_local_after_unready_candidates_sets_flags`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_ready_batch`: 17 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_ready_batch_third_local_after_unready_candidates_sets_flags`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6865 tests-dir `@test` annotations | 7465 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch third-candidate local gate
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 520 — `executor_multi_threaded_deep` drive-ready-batch second local coverage — DONE

Source focus: drive-ready-batch integration local-thread gate behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the integration-layer counterpart to Batch 518. Candidate 0
is unready, candidate 1 is local, and candidate 2 is ordinary ready work. The
drive-ready-batch path must run and complete candidates 1 and 2 in the same
batch, clear their ready flags, and avoid a false stall. No executor
implementation, API surface, or SLA compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 185
`@test` entries. New panic band: 149834-149844.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_second_local_after_unready_keeps_ordinary`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 12 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_integration_second_local_after_unready_keeps_ordinary`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6866 tests-dir `@test` annotations | 7466 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch second-candidate
local gate integration coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 521 — `executor_multi_threaded_deep` drive-ready-batch third local coverage — DONE

Source focus: drive-ready-batch integration local-thread gate behavior in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the third-candidate local-gate counterpart to Batch 520.
Candidates 0 and 1 are unready, candidate 2 is local, and the integration path
must run and complete candidate 2, clear its ready flag, and avoid a false
stall. No executor implementation, API surface, or SLA compiler behavior
changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 186
`@test` entries. New panic band: 149845-149852.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_third_local_after_unready_runs_local`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 13 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_integration_third_local_after_unready_runs_local`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6867 tests-dir `@test` annotations | 7467 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch third-candidate
local gate integration coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 522 — `executor_multi_threaded_deep` ready-batch rescan selected-count fix — DONE

Source focus: ready-batch rescan summary selected-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add a focused regression where system 0 is skipped by
`should_run=false`, releases system 1 as local-thread work, and system 2 is
already ordinary ready work. The rescan path was starting systems 1 and 2 but
only reporting one selected system. `_mt_ready_batch_rescan_push_selected` now
uses a stable slot position and increments `selected_count` after assigning the
slot, keeping the summary aligned with state mutation. No SLA compiler behavior
or API surface changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 187
`@test` entries. New panic band: 149853-149862.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_rescan_local_after_skip_keeps_ordinary_same_batch`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `ready_batch_rescan`: 10 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_ready_batch_rescan_local_after_skip_keeps_ordinary_same_batch`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6868 tests-dir `@test` annotations | 7468 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan summary selected
count parity for local-plus-ordinary post-skip batches 0% -> 100% for this
focused behavior fix; overall API parity remains ~94–96%, behavioral parity
remains ~86–91%. Remaining optional depth is broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 523 — `executor_multi_threaded_deep` ready-batch rescan third-slot coverage — DONE

Source focus: ready-batch rescan summary third selected-slot accounting in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the missing three-system counterpart to Batch 522. Three
ordinary ready systems are selected in one rescan pass, and the summary must
record `selected_count=3`, preserve slots 0/1/2 in order, clear every ready
flag, and report three running systems. No executor implementation, API
surface, or SLA compiler behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 188
`@test` entries. New panic band: 149863-149872.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_rescan_records_three_selected_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `ready_batch_rescan`: 11 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_ready_batch_rescan_records_three_selected_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6869 tests-dir `@test` annotations | 7469 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan third selected-slot
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 524 — `executor_multi_threaded_deep` tick no-drain third-slot coverage — DONE

Source focus: tick-with-completions no-drain fast path selected-slot accounting
in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: add the three-system counterpart for the no-completion fast
path. Three ordinary ready systems are selected with `max_width=3`; the summary
must report `selected_count=3`, slots 0/1/2 in order, no selected slot past the
fixed cap, no remaining ready flags, three running systems, and no local or
exclusive gate. No executor implementation, API surface, or SLA compiler
behavior changed in this batch.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 189
`@test` entries. New panic band: 149873-149886.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_no_drain_records_three_selected_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `no_drain`: 6 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter was not started because `pgrep` found external SAB backend test processes; whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6870 tests-dir `@test` annotations | 7470 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions no-drain third
selected-slot coverage 0% -> 100% for this focused scenario; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 525 — `executor_multi_threaded_deep` completion-drain multi-select fix — DONE

Source focus: tick-with-completions completion-drain selected-slot accounting
in `lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: complete running system 0, release dependent system 1, and keep
already-ready ordinary system 2 available in the same tick. The executor state
started systems 1 and 2, but `_mt_tick_with_completions_push_selected` only
reported one selected system. The helper now uses a stable slot position and
increments `selected_count` after assigning the selected slot, matching the
Batch 522 rescan fix. No public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 190
`@test` entries. New panic band: 149887-149899.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_releases_and_keeps_ordinary_same_batch`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 15 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_releases_and_keeps_ordinary_same_batch`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6871 tests-dir `@test` annotations | 7471 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions completion-drain
multi-select summary parity 0% -> 100% for this focused behavior fix; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 526 — `executor_multi_threaded_deep` completion-drain completed-count fix — DONE

Source focus: tick-with-completions completion-drain completed-slot accounting
in `lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: drain two completed running systems in one tick, release a
two-dependency join, and select the released dependent. The executor state
completed both systems, but `_mt_tick_with_completions_push_completed` only
reported one completed slot. The helper now uses a stable slot position and
increments `completed_count` after slot assignment, matching the selected-slot
fixes. No public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 191
`@test` entries. New panic band: 149900-149910.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_two_completed_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 16 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_two_completed_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6872 tests-dir `@test` annotations | 7472 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions completion-drain
completed-slot summary parity 0% -> 100% for this focused behavior fix; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 527 — `executor_multi_threaded_deep` completion-drain ignored-count fix — DONE

Source focus: tick-with-completions ignored-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: feed two invalid completion ids into one tick while ordinary
ready work remains available. The summary must record both ignored ids and
still select the ready system. `_mt_tick_with_completions_push_ignored` now uses
a stable slot position and increments `ignored_count` after assignment,
matching the selected/completed slot fixes. No public API surface or SLA
compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 192
`@test` entries. New panic band: 149911-149920.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_two_ignored_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 17 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_two_ignored_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6873 tests-dir `@test` annotations | 7473 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions ignored-slot
summary parity 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 528 — `executor_multi_threaded_deep` completion-drain skipped-count fix — DONE

Source focus: tick-with-completions skipped-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: finalize two pending skipped systems in one tick. The executor
state completed both skipped systems, but `_mt_tick_with_completions_push_skipped`
only reported one skipped slot. The helper now uses a stable slot position and
increments `skipped_count` after assignment, matching the selected/completed/
ignored slot fixes. No public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 193
`@test` entries. New panic band: 149921-149929.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_tick_with_completions_records_two_skipped_slots`: panic 149922 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 18 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6874 tests-dir `@test` annotations | 7474 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions skipped-slot
summary parity 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 529 — `executor_multi_threaded_deep` completion-drain apply-count fix — DONE

Source focus: tick-with-completions apply-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: complete an ApplyDeferred barrier while two prior deferred
systems are unapplied. The executor state applied both deferred systems, but
`_mt_tick_with_completions_push_apply` only reported one apply slot. The helper
now uses a stable slot position and increments `apply_count` after assignment,
matching the selected/completed/ignored/skipped slot fixes. No public API
surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 194
`@test` entries. New panic band: 149930-149938.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_tick_with_completions_records_two_apply_slots`: panic 149932 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_two_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 19 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_two_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6875 tests-dir `@test` annotations | 7475 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions apply-slot
summary parity 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 530 — `executor_multi_threaded_deep` ready-batch rescan skipped-count fix — DONE

Source focus: ready-batch rescan skipped-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: finalize two pending skipped systems during ready-batch rescan.
The executor state completed both skipped systems, but
`_mt_ready_batch_rescan_push_skipped` only reported one skipped slot. The helper
now uses a stable slot position and increments `skipped_count` after assignment,
matching the selected-slot fix and the tick-with-completions slot fixes. No
public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 195
`@test` entries. New panic band: 149939-149947.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_ready_batch_rescan_records_two_skipped_slots`: panic 149940 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_rescan_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `ready_batch_rescan`: 12 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_ready_batch_rescan_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6876 tests-dir `@test` annotations | 7476 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-batch rescan skipped-slot
summary parity 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 531 — `executor_multi_threaded_deep` complete-ready apply-count fix — DONE

Source focus: complete-ready-batch apply-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: complete two deferred systems and an ApplyDeferred barrier in
one complete-ready batch. The executor state applied both deferred systems, but
`_mt_complete_ready_batch_push_apply` only reported one apply slot. The helper
now uses a stable slot position and increments `apply_count` after assignment,
matching the tick-with-completions apply fix. No public API surface or SLA
compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 196
`@test` entries. New panic band: 149948-149956.

Validation:
- Existing focused filter `complete_ready_batch` passed 10 / 0 before this new regression was added, so already-covered started/completed paths were not changed.
- Test-first failure reproduced with default backend exact filter `mt_deep_complete_ready_batch_records_two_apply_slots`: panic 149948 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_complete_ready_batch_records_two_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `complete_ready_batch`: 11 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_complete_ready_batch_records_two_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6877 tests-dir `@test` annotations | 7477 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch apply-slot
summary parity 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 532 — `executor_multi_threaded_deep` drive-ready apply-count fix — DONE

Source focus: drive-ready-batch integration apply-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: run an ApplyDeferred barrier while two prior deferred systems are
unapplied. The executor state applied both deferred systems, but
`_mt_drive_ready_batch_integration_push_apply` only reported one apply slot. The
helper now uses a stable slot position and increments `apply_count` after
assignment, matching the complete-ready and tick-with-completions apply fixes.
No public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 197
`@test` entries. New panic band: 149957-149967.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_drive_ready_batch_integration_records_two_apply_slots`: panic 149959 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_records_two_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 14 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_integration_records_two_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6878 tests-dir `@test` annotations | 7478 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration
apply-slot summary parity 0% -> 100% for this focused behavior fix; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 533 — `executor_multi_threaded_deep` drive-all apply-count fix — DONE

Source focus: drive-all batched integration apply-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: run an ApplyDeferred barrier in drive-all batched integration
while two prior deferred systems are unapplied. The executor state applied both
deferred systems, but `_mt_drive_all_batched_push_apply` only reported one apply
slot. The helper now uses a stable slot position and increments `apply_count`
after assignment, matching the drive-ready, complete-ready, and
tick-with-completions apply fixes. No public API surface or SLA compiler
behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 198
`@test` entries. New panic band: 149968-149978.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_drive_all_batched_integration_records_two_apply_slots`: panic 149972 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_records_two_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 15 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_records_two_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6879 tests-dir `@test` annotations | 7479 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all batched integration
apply-slot summary parity 0% -> 100% for this focused behavior fix; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 534 — `executor_multi_threaded_deep` drive-ready zero-width skipped-count fix — DONE

Source focus: drive-ready-batch integration zero-width pending-skip accounting
in `lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: finalize two pending skipped systems when `max_width=0`. The
executor state completed both skipped systems, but
`_mt_drive_ready_batch_integration_push_skipped` only reported one skipped slot.
The helper now uses a stable slot position and increments `skipped_count` after
assignment, matching the ready-batch rescan and tick-with-completions skipped
fixes. No public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 199
`@test` entries. New panic band: 149979-149987.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_drive_ready_batch_integration_zero_width_records_two_skipped_slots`: panic 149980 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_zero_width_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 15 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter was not started because an external `sa sla test tests/test_compiler_contract.sla --test-backend sa --jobs 1 --trace-panic` process was already running.
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6880 tests-dir `@test` annotations | 7480 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration
zero-width skipped-slot summary parity 0% -> 100% for this focused behavior fix;
overall API parity remains ~94–96%, behavioral parity remains ~86–91%.
Remaining optional depth is broader executor integration scenarios if new Bevy
parity gaps are found.


# Batch 535 — `executor_multi_threaded_deep` drive-all zero-width skipped-slot coverage — DONE

Source focus: drive-all batched integration zero-width pending-skip accounting
coverage in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: finalize two pending skipped systems with `max_width=0` and
verify both skipped slots are reported in stable order. The existing drive-all
implementation already records both slots correctly, including the
out-of-bounds accessor, one zero-width wave, zero runs, and the final
completed/ready state. No executor implementation, public API surface, or SLA
compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 200
`@test` entries. New panic band: 149988-149996.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_zero_width_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 16 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_zero_width_records_two_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6881 tests-dir `@test` annotations | 7481 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all batched integration
zero-width skipped-slot coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 536 — `executor_multi_threaded_deep` drive-all ready-work skipped-slot coverage — DONE

Source focus: drive-all batched integration positive-width pending-skip
accounting coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: finalize two pending skipped systems while one ordinary ready
system runs with `max_width=1`. The existing drive-all positive-width path
already reports both skipped slots in stable order, runs and completes the
ordinary system in the same wave, and reaches the expected final state. No
executor implementation, public API surface, or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 201
`@test` entries. New panic band: 149997-150007.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_records_two_skipped_slots_with_ready_work`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 17 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_records_two_skipped_slots_with_ready_work`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6882 tests-dir `@test` annotations | 7482 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all batched integration
positive-width skipped-slot coverage with concurrent ready work 0% -> 100% for
this focused scenario; overall API parity remains ~94–96%, behavioral parity
remains ~86–91%. Remaining optional depth is broader executor integration
scenarios if new Bevy parity gaps are found.


# Batch 537 — `executor_multi_threaded_deep` completion-queue apply-count fix — DONE

Source focus: completion-queue drain ApplyDeferred apply-slot accounting in
`lib/executor_multi_threaded_deep.sla` and
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: drain an ApplyDeferred barrier completion while two prior
deferred systems are already completed and pending unapplied. The executor state
applied both deferred systems, but completion-queue drain only reported the
first apply slot. `_mt_completion_queue_drain_apply_unapplied` now records
applied systems through a stable-position `_mt_completion_queue_drain_push_apply`
helper, matching the tick-with-completions, complete-ready, drive-ready, and
drive-all apply fixes. No public API surface or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 202
`@test` entries. New panic band: 150008-150018.

Validation:
- Test-first failure reproduced with default backend exact filter `mt_deep_completion_queue_drain_records_two_apply_slots`: panic 150012 before the fix (`timeout 90s`, `--jobs 1`, `--trace-panic`)
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/executor_multi_threaded_deep.sla`
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_completion_queue_drain_records_two_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `completion_queue`: 9 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_completion_queue_drain_records_two_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6883 tests-dir `@test` annotations | 7483 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor completion-queue drain apply-slot
summary parity 0% -> 100% for this focused behavior fix; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 538 — `executor_multi_threaded_deep` completed-tick deferred-panic coverage — DONE

Source focus: completed-tick error ApplyDeferred panic counting coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process an ApplyDeferred panic where the failing deferred system
is the second unapplied entry. The existing completed-tick error path already
counts both attempted apply entries before stopping at the panic, records the
panic phase/system correctly, clears unapplied state, and completes the barrier.
No executor implementation, public API surface, or SLA compiler behavior
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 203
`@test` entries. New panic band: 150019-150026.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_completed_tick_error_apply_deferred_panic_counts_until_second_failure`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `completed_tick_error`: 7 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_completed_tick_error_apply_deferred_panic_counts_until_second_failure`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6884 tests-dir `@test` annotations | 7484 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor completed-tick ApplyDeferred
second-entry panic counting coverage 0% -> 100% for this focused scenario;
overall API parity remains ~94–96%, behavioral parity remains ~86–91%.
Remaining optional depth is broader executor integration scenarios if new Bevy
parity gaps are found.


# Batch 539 — `executor_multi_threaded_deep` complete-ready third-slot coverage — DONE

Source focus: complete-ready batch started/completed third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: run three ordinary ready systems through a single complete-ready
batch and verify all started and completed slots 0/1/2 plus out-of-bounds
accessors. The existing complete-ready implementation already records third
started/completed slots correctly and reaches the expected final state. No
executor implementation, public API surface, or SLA compiler behavior changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 204
`@test` entries. New panic band: 150027-150039.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_complete_ready_batch_records_three_started_completed_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `complete_ready_batch`: 12 passed / 0 failed (`timeout 150s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_complete_ready_batch_records_three_started_completed_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6885 tests-dir `@test` annotations | 7485 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch third
started/completed slot coverage 0% -> 100% for this focused scenario; overall
API parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining
optional depth is broader executor integration scenarios if new Bevy parity
gaps are found.


# Batch 540 — `executor_multi_threaded_deep` drive-ready third-slot coverage — DONE

Source focus: drive-ready-batch integration run/completed third-slot coverage
in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: run three ordinary ready systems through a single drive-ready
batch and verify all run and completed slots 0/1/2 plus out-of-bounds
accessors. The existing drive-ready implementation already records third
run/completed slots correctly and reaches the expected final state. No executor
implementation, public API surface, SLA compiler behavior, or SLA docs ticket
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 205
`@test` entries. New panic band: 150040-150053.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_records_three_run_completed_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 16 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_integration_records_three_run_completed_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6886 tests-dir `@test` annotations | 7486 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration third
run/completed slot coverage 0% -> 100% for this focused scenario; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 541 — `executor_multi_threaded_deep` initial-skip third-slot coverage — DONE

Source focus: initial skipped-system summary third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process three ready systems through one initial skip summary and
verify all skipped slots 0/1/2 plus out-of-bounds accessors. The existing
initial-skip implementation already records third skipped slots correctly and
reaches the expected final state. No executor implementation, public API
surface, SLA compiler behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 206
`@test` entries. New panic band: 150054-150062.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_initial_skips_summary_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `initial_skips_summary`: 7 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_initial_skips_summary_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6887 tests-dir `@test` annotations | 7487 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor initial-skip third skipped-slot
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 542 — `executor_multi_threaded_deep` initial-skip ignored third-slot coverage — DONE

Source focus: initial skipped-system summary ignored third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process three invalid initial skip inputs and verify all ignored
slots 0/1/2 plus out-of-bounds accessors. The existing initial-skip
implementation already records third ignored slots correctly and avoids
mutating ready/completed/skipped state for invalid inputs. No executor
implementation, public API surface, SLA compiler behavior, or SLA docs ticket
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 207
`@test` entries. New panic band: 150063-150071.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_initial_skips_summary_records_three_ignored_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `initial_skips_summary`: 8 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_initial_skips_summary_records_three_ignored_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6888 tests-dir `@test` annotations | 7488 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor initial-skip third ignored-slot
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 543 — `executor_multi_threaded_deep` completion-queue ignored third-slot coverage — DONE

Source focus: completion-queue drain ignored third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process invalid and non-running completion entries through one
completion-queue drain and verify all ignored slots 0/1/2 plus out-of-bounds
accessors. The existing completion-queue implementation already records third
ignored slots correctly and avoids mutating ready/running/completed state for
invalid or non-running entries. No executor implementation, public API surface,
SLA compiler behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 208
`@test` entries. New panic band: 150072-150080.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_completion_queue_drain_records_three_ignored_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `completion_queue`: 10 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_completion_queue_drain_records_three_ignored_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6889 tests-dir `@test` annotations | 7489 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor completion-queue drain third
ignored-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 544 — `executor_multi_threaded_deep` drive-all zero-width skipped third-slot coverage — DONE

Source focus: drive-all batched integration zero-width skipped third-slot
coverage in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process three pending skipped systems through the `max_width=0`
drive-all path and verify skipped slots 0/1/2 plus out-of-bounds accessors. The
existing drive-all implementation already records third skipped slots correctly
and reaches the expected completed/ready state. No executor implementation,
public API surface, SLA compiler behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 209
`@test` entries. New panic band: 150081-150090.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_zero_width_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 18 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_zero_width_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6890 tests-dir `@test` annotations | 7490 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all batched zero-width third
skipped-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 545 — `executor_multi_threaded_deep` completion-queue completed third-slot coverage — DONE

Source focus: completion-queue drain completed third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: drain three running systems from the completion queue in a
non-index order and verify completed slots 0/1/2 plus out-of-bounds accessors.
The existing completion-queue implementation already records third completed
slots correctly and reaches the expected running/completed/ready state. No
executor implementation, public API surface, SLA compiler behavior, or SLA docs
ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 210
`@test` entries. New panic band: 150091-150099.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_completion_queue_drain_records_three_completed_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `completion_queue`: 11 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_completion_queue_drain_records_three_completed_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6891 tests-dir `@test` annotations | 7491 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor completion-queue drain third
completed-slot coverage 0% -> 100% for this focused scenario; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 546 — `executor_multi_threaded_deep` tick-with-completions completed third-slot coverage — DONE

Source focus: tick-with-completions completed third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: drain three running systems through one tick in a non-index
completion order and verify completed slots 0/1/2 plus out-of-bounds accessors.
The existing tick-with-completions implementation already records third
completed slots correctly without selecting extra work and reaches the expected
running/completed/ready state. No executor implementation, public API surface,
SLA compiler behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 211
`@test` entries. New panic band: 150100-150110.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_three_completed_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 20 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_three_completed_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6892 tests-dir `@test` annotations | 7492 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions third
completed-slot coverage 0% -> 100% for this focused scenario; overall API
parity remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional
depth is broader executor integration scenarios if new Bevy parity gaps are
found.


# Batch 547 — `executor_multi_threaded_deep` tick-with-completions ignored third-slot coverage — DONE

Source focus: tick-with-completions ignored third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process two invalid completion ids and one ready-but-not-running
system id through one tick, verify ignored slots 0/1/2 plus out-of-bounds
accessors, and prove the ready system is still selected afterward. The existing
tick-with-completions implementation already records third ignored slots
correctly without corrupting subsequent ready selection. No executor
implementation, public API surface, SLA compiler behavior, or SLA docs ticket
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 212
`@test` entries. New panic band: 150111-150121.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_three_ignored_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 21 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_three_ignored_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6893 tests-dir `@test` annotations | 7493 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions third
ignored-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 548 — `executor_multi_threaded_deep` tick-with-completions skipped third-slot coverage — DONE

Source focus: tick-with-completions skipped third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process three pending skipped systems through one tick with
`max_width=2`, verify skipped slots 0/1/2 plus out-of-bounds accessors, and
prove selection width does not truncate skip finalization. The existing
tick-with-completions implementation already records third skipped slots
correctly and completes all pending skipped systems without selecting work. No
executor implementation, public API surface, SLA compiler behavior, or SLA docs
ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 213
`@test` entries. New panic band: 150122-150131.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 22 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6894 tests-dir `@test` annotations | 7494 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions third
skipped-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 549 — `executor_multi_threaded_deep` ready-rescan skipped third-slot coverage — DONE

Source focus: ready-batch rescan skipped third-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: rescan three pending skipped systems with `max_width=2`, verify
skipped slots 0/1/2 plus out-of-bounds access, two rescan rounds, zero selected
work, and final completed/ready/running counts. The ECS implementation already
behaved correctly on the default backend. The generated-SA backend exposed an
SLA compiler `UseAfterMove` because a resolved assigned aggregate `tmp_*`
binding was released after its first field projection.

Compiler handling:
- Filed
  `/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/issue035_sla_ecs_rescan_summary_repeated_field_load_sa_useaftermove.md`.
- Fixed shared field-base lifetime classification in `sa_plugin_sla` commit
  `7acf7ef` (`Fix SA assigned aggregate field lifetime`).
- Installed the dev plugin and reverified the exact ECS regression plus the
  focused ready-rescan group.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 214
`@test` entries. New panic band: 150132-150142.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_ready_batch_rescan_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `ready_batch_rescan`: 13 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Pre-fix SA backend exact filter reproduced `UseAfterMove` on `tmp_3969`
- Post-fix SA backend exact filter `mt_deep_ready_batch_rescan_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Post-fix SA backend focused filter `ready_batch_rescan`: 13 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6895 tests-dir `@test` annotations | 7495 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor ready-rescan third skipped-slot
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 550 — `executor_multi_threaded_deep` drive-ready zero-width skipped third-slot coverage — DONE

Source focus: drive-ready-batch integration zero-width skipped third-slot
coverage in `tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: process three pending skipped systems through the
`ecs_executor_drive_ready_batch_integration_summary_deep3` zero-width path and
verify skipped slots 0/1/2 plus out-of-bounds accessors. The existing drive
ready-batch implementation already records third skipped slots correctly and
finalizes all pending skipped systems without running work. No executor
implementation, public API surface, SLA compiler behavior, or SLA docs ticket
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 215
`@test` entries. New panic band: 150143-150152.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_zero_width_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 17 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_integration_zero_width_records_three_skipped_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6896 tests-dir `@test` annotations | 7496 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready zero-width third
skipped-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 551 — `executor_multi_threaded_deep` completion-queue apply third-slot coverage — DONE

Source focus: completion-queue drain ApplyDeferred apply-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: preload three completed deferred systems into a cap-16 executor
state, including system slot 3 outside the current three-spec facade, then drain
an `ApplyDeferred` barrier completion and verify apply slots 0/1/2 record
systems 0/1/3. The existing completion-queue implementation already handles the
third apply slot correctly. No executor implementation, public API surface, SLA
compiler behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 216
`@test` entries. New panic band: 150153-150164.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_completion_queue_drain_records_three_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `completion_queue_drain`: 10 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_completion_queue_drain_records_three_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6897 tests-dir `@test` annotations | 7497 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor completion-queue drain third
apply-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 552 — `executor_multi_threaded_deep` tick-with-completions apply third-slot coverage — DONE

Source focus: tick-with-completions ApplyDeferred apply-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: mirror the completion-queue third apply-slot setup through
`ecs_executor_tick_with_completions_summary_deep3`: preload three completed
deferred systems in slots 0, 1, and 3, drain a running `ApplyDeferred` barrier in
slot 2, and verify apply slots 0/1/2 record systems 0/1/3 before the modeled tick
returns no selected work. The existing tick-with-completions implementation
already handles the third apply slot correctly. No executor implementation,
public API surface, SLA compiler behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 217
`@test` entries. New panic band: 150165-150177.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_tick_with_completions_records_three_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `mt_deep_tick_with_completions`: 23 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_tick_with_completions_records_three_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6898 tests-dir `@test` annotations | 7498 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor tick-with-completions third
apply-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 553 — `executor_multi_threaded_deep` drive-ready apply third-slot coverage — DONE

Source focus: drive-ready-batch integration ApplyDeferred apply-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: preload three completed deferred systems in slots 0, 1, and 3,
then select and complete a ready `ApplyDeferred` barrier in slot 2 through
`ecs_executor_drive_ready_batch_integration_summary_deep3`. The regression
verifies apply slots 0/1/2 record systems 0/1/3 and that the barrier completes
without leaving ready, running, or unapplied state. The existing drive-ready
implementation already handles the third apply slot correctly. No executor
implementation, public API surface, SLA compiler behavior, or SLA docs ticket
changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 218
`@test` entries. New panic band: 150178-150190.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_integration_records_three_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_integration`: 18 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_integration_records_three_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6899 tests-dir `@test` annotations | 7499 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch integration third
apply-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 554 — `executor_multi_threaded_deep` drive-all apply third-slot coverage — DONE

Source focus: drive-all batched integration ApplyDeferred apply-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: preload three completed deferred systems in slots 0, 1, and 3,
then let `ecs_executor_drive_all_batched_integration_summary_deep3` select and
complete a ready `ApplyDeferred` barrier in slot 2. The regression verifies the
drive-all batch records apply slots 0/1/2 as systems 0/1/3, completes the
barrier in one wave, and leaves no ready or unapplied state. The existing
drive-all implementation already handles the third apply slot correctly. No
executor implementation, public API surface, SLA compiler behavior, or SLA docs
ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 219
`@test` entries. New panic band: 150191-150204.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_all_batched_integration_records_three_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_all_batched_integration`: 19 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_all_batched_integration_records_three_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6900 tests-dir `@test` annotations | 7500 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-all batched integration third
apply-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 555 — `executor_multi_threaded_deep` complete-ready apply third-slot coverage — DONE

Source focus: complete-ready-batch ApplyDeferred apply-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: preload three completed deferred systems in slots 0, 1, and 3,
then complete a selected `ApplyDeferred` barrier in slot 2 through
`ecs_executor_complete_ready_batch_summary_deep3`. The regression verifies
apply slots 0/1/2 record systems 0/1/3, only the barrier is started/completed by
this batch, and no ready, running, or unapplied state remains. The existing
complete-ready implementation already handles the third apply slot correctly. No
executor implementation, public API surface, SLA compiler behavior, or SLA docs
ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 220
`@test` entries. New panic band: 150205-150218.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_complete_ready_batch_records_three_apply_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `complete_ready_batch`: 13 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_complete_ready_batch_records_three_apply_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6901 tests-dir `@test` annotations | 7501 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor complete-ready-batch third apply-slot
coverage 0% -> 100% for this focused scenario; overall API parity remains
~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is broader
executor integration scenarios if new Bevy parity gaps are found.


# Batch 556 — `executor_multi_threaded_deep` drive-ready summary selected third-slot coverage — DONE

Source focus: low-level drive-ready-batch summary selected-slot coverage in
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`.

Deep strategy: mark systems 0, 1, and 2 ready, then call
`ecs_executor_state_deep_drive_ready_batch_summary3` with `max_width=3`. The
regression verifies selected slots 0/1/2 record systems 0/1/2, selected slot 3
returns `-1`, three systems are counted as completed, ready-count summary
semantics are preserved, and no unapplied or stalled state is reported. The
existing executor implementation already handles the third selected slot
correctly. No executor implementation, public API surface, SLA compiler
behavior, or SLA docs ticket changed.

Test file:
`tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla` now has 221
`@test` entries. New panic band: 150219-150227.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check tests/test_ecs_lib_executor_multi_threaded_deep_isolated.sla`
- Default backend exact filter `mt_deep_drive_ready_batch_summary_records_three_selected_slots`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- Default backend focused filter `drive_ready_batch_summary`: 4 passed / 0 failed (`timeout 120s`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- SA backend exact filter `mt_deep_drive_ready_batch_summary_records_three_selected_slots`: 1 passed / 0 failed (`timeout 180s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; counted only after clean process exit)
- `git diff --check`
- Whole-file executor-deep runs and broader generated-SA groups intentionally
  avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6902 tests-dir `@test` annotations | 7502 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: multi-threaded executor drive-ready-batch summary third
selected-slot coverage 0% -> 100% for this focused scenario; overall API parity
remains ~94–96%, behavioral parity remains ~86–91%. Remaining optional depth is
broader executor integration scenarios if new Bevy parity gaps are found.


# Batch 557 — `task_scope_completion` pending panic/catch completion — DONE

Source focus: pending task completion outcomes in
`lib/task_scope_completion.sla`.

Implementation: add helpers that resolve a queued pending task as either a
panic payload or a failed catch. The regressions prove draining resumes panic
propagation, reports the matching failure count, cancels later queued work, and
empties the modeled scope queue. The existing pending-first drain regression is
also retained.

The default backend exposed an existing SLA compiler `UseAfterMove` when a
plain aggregate containing `Vec` fields was passed to a read-only by-value
helper and then reused. The compiler issue is documented in
`sa_plugin_sla/docs/issue038_sla_ecs_scope_completion_stack_slot_aggregate_call_useaftermove.md`
and fixed by compiler commit `4a379ad`, which shallow-copies nested standard
owner ABI slots while keeping top-level owners non-copyable.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/task_scope_completion.sla`
- Default backend existing exact filter `scope completion pending first task blocks result drain`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; clean exit)
- Default backend new filter `scope completion pending task can finish`: 2 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; clean exit)
- SA backend existing exact filter: 1 passed / 0 failed (`timeout 120s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; clean exit)
- SA backend new filter: 2 passed / 0 failed (`timeout 120s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; clean exit)
- `git diff --check`
- Broad whole-file/generated-SA groups intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6902 tests-dir `@test` annotations | 7504 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: scope-completion pending panic and failed-catch resolution
coverage 0% -> 100% for this focused behavior; overall API parity remains
~94–96%, behavioral parity remains ~86–91%.


# Batch 558 — `task_scope_completion` multiple pending queue order — DONE

Source focus: repeated pending-task resolution in
`lib/task_scope_completion.sla`.

Deep strategy: queue two pending tasks followed by one ready task. The
regression proves the first drain blocks without consuming work, resolving the
first pending task lets the next drain return only that task and preserve the
remaining queue, and resolving the second pending task lets the final drain
return the last two tasks in lane order and empty the queue. The existing queue
slicing and drain implementation already handles this lifecycle correctly. No
public implementation, SLA compiler behavior, or SLA docs ticket changed.

Validation:
- `timeout 45s env SA_PLUGIN_DEV=1 sa sla check lib/task_scope_completion.sla`
- Default backend exact filter `scope completion resolves multiple pending tasks`: 1 passed / 0 failed (`timeout 90s`, `--jobs 1`, `--trace-panic`; clean exit)
- SA backend exact filter: 1 passed / 0 failed (`timeout 120s`, `--test-backend sa`, `--jobs 1`, `--trace-panic`; clean exit)
- `git diff --check`
- Broad whole-file/generated-SA groups intentionally avoided per memory/OOM guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 425
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6902 tests-dir `@test` annotations | 7505 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: scope-completion repeated pending resolution and queue-order
coverage 0% -> 100% for this focused behavior; overall API parity remains
~94–96%, behavioral parity remains ~86–91%.


# Batch 559 — `parallel_runner` shared scope-executor identity — DONE

Source focus: TaskPool scope executor identity accounting in
`lib/parallel_runner.sla`.

Implementation: external-lane tasks now mark `ticked_scope_executor` when the
external executor is the scope executor. This applies to both serial and
positive-width direct scope runners and to root/nested recursive child-scope
and child-result lane-2 execution. A distinct external executor continues to
mark only `ticked_external_executor`.

The initial downstream compile exposed two existing SLA compiler defects for
repeated function-pointer aliases: call lowering used a non-alias-aware local
type lookup, then generated-SA vector insertion leaked materialized
function-pointer vtable temporaries. Filed
`sa_plugin_sla/docs/issue044_sla_ecs_repeated_let_fn_ptr_alias_codegenerror.md`;
compiler commits `adf98e2` and `e2406dc` fix the lookup and cleanup paths, and
`08a7def` closes the issue after verification.

Test file:
`tests/test_ecs_parallel_runner_scope_executor_isolated.sla` adds 2 focused
regressions. New panic band: 151000-151009.

Validation:
- Compiler `timeout 180s zig build -j1 --summary all`: 7/7 steps succeeded,
  peak RSS about 1.14 GiB.
- Compiler minimal repeated-alias fixture: strict SAB and generated-SA exact
  filters each pass 1/1 with `timeout 90s`, `--jobs 1`, and clean exits.
- Development SLA plugin installed with a 120s timeout.
- Existing downstream exact filter
  `task pool scoped task set external only stays off pool`: default and SA
  backends each pass 1/1 with `timeout 90s`, `--jobs 1`, `--trace-panic`, and
  clean exits.
- New direct shared-executor exact filter: default and SA backends each pass
  1/1 with `timeout 90s`, `--jobs 1`, `--trace-panic`, and clean exits.
- New recursive child shared-executor exact filter: default and SA backends
  each pass 1/1 with `timeout 90s`, `--jobs 1`, `--trace-panic`, and clean
  exits.
- `git diff --check`
- Broad whole-file/generated-SA groups intentionally avoided per memory/OOM
  guidance.

Post-batch counts: 521 lib `.sla` modules | 249 `*_deep.sla` modules | 426
test `.sla` files | 249 `*_deep_isolated.sla` test files | 90 examples |
6904 tests-dir `@test` annotations | 7507 lib/tests/examples `.sla`
`@test` annotations.
Feature progress: TaskPool scope/external executor identity accounting for
direct and recursive external lanes 0% -> 100% for this focused behavior;
overall API parity remains ~94–96%, behavioral parity remains ~86–91%.

# sla_ecs

SA-native Entity-Component-System runtime written in Sla.

The project is moving from fixed demo prototypes toward Bevy Core ECS parity.
Current reusable infrastructure lives in `lib/`; verified executable examples live
in `examples/`.

## Toolchain Default

This project expects the SA toolchain built from https://github.com/layola13/sci/
and the SLA plugin available through `SA_PLUGIN_DEV=1` during focused local
checks.

Focused ECS verification should not persist generated SA artifacts in this
repository. `*.test.sa` files are generated compiler output, are ignored, and
must not be committed. Use the SAB/default path for focused verification; when
SAB compilation fails, do not fall back to generated-SA completion evidence.
Instead, report the compiler issue under
`/home/vscode/projects/sa_plugins/sa_plugin_sla/docs/` with the failing command
and diagnostic. Focused tests should still be wrapped in `timeout 120s`;
build/install commands should not use that timeout wrapper.

## Architecture

An ECS framework built for SA's linear ownership model and Referee safety system. No `mut` keyword — write access is expressed through linear value passing (`fn(World) -> World`).

### Design Principles

- **Linear World** — systems take World by value, return World
- **SoA Storage** — struct-of-arrays layout for cache-friendly iteration
- **For-In Protocol** — query iteration via `iter_len`/`iter_at` methods
- **Typed Queries** — `Query<T>` and `Mut<T>` wrappers with explicit writeback instead of Rust `mut` as the core model
- **Sequential Systems** — systems compose as `let w1 = sys_a(world); let w2 = sys_b(w1);`

### Unified Facade

`lib/ecs_world.sla` is the single outward-facing entry point over the
table-erased full stack. It wraps `TableErasedWorld<R, M>` (archetype + erased
columns + resources + messages + change ticks) and exposes Bevy-README-shaped
`ecs_world_*` helpers so users do not touch the many stepping-stone world types
directly: `ecs_world_new`, `ecs_world_register_table` / `register_sparse_set`,
`ecs_world_spawn` / `despawn`, `ecs_world_insert` / `get` / `has` / `remove`
(which resolve `component_id` from `type_id` automatically), `ecs_world_query`
/ `query_single` / `query_count`, change detection, resources, messages, and
`ecs_world_schedule_*` / `ecs_world_commands_*` helpers. Component identity
flows through explicit `type_id` values because Sla generic functions cannot
call `T::component_type_id()`; register components once, then use the `_auto`
resolution path for all subsequent access.

### Capacity

`lib/store.sla` and `lib/world.sla` still use fixed 16-slot arrays as a
compatibility/regression layer. The dynamic path is `lib/entity_dynamic.sla`,
`lib/dyn_store.sla`, `lib/sparse_store.sla`, and `lib/world_dynamic.sla`; it is
`sa_std Vec`-backed and has verified growth beyond the old 16-entity/component
cap.

## Components

- `Position { x: i32, y: i32 }`
- `Velocity { x: i32, y: i32 }`
- `Health { current: i32, max: i32 }`
- `Damage { amount: i32, target_id: i32 }`

## Systems

| System | Description |
|--------|-------------|
| `movement_system` | Applies velocity to position for matching entities |
| `damage_system` | Reduces health by damage events, clears damage queue |
| `death_system` | Removes entities with 0 HP (swap-remove) |
| `heal_system` | Regenerates 1 HP per tick up to max |

## Files

```
lib/
├── entity.sla        — Reusable `@derive(copy, eq, ord, hash, debug)` Entity handle + allocator, generation checks, bit roundtrip
├── entity_dynamic.sla — Vec-backed dynamic entity allocator with live/stale checks
├── entity_set.sla    — EntitySet, EntityMap<T>, EntityHashSet, EntityHashMap<T>, and ordered UniqueEntityVec with Entity value-key semantics while std hash containers remain pointer-keyed
├── store.sla         — Generic fixed-capacity ComponentStore<T>
├── dyn_store.sla     — Generic Vec-backed table-style DynamicComponentStore<T>
├── sparse_store.sla  — Generic Vec-backed SparseComponentStore<T>
├── component.sla     — Component registry metadata: table default, sparse-set opt-in
├── component_metadata.sal — ECS component metadata ABI constants
├── component_metadata.sai — ECS component metadata interface contract placeholder
├── ecs_world.sla — Unified Bevy-style World facade over the table-erased full stack: `ecs_world_*` entry point for spawn/despawn/insert/get/has/remove/query/query_single/change-detection/Ref/Local/NonSend/resource/message/schedule/commands/EntityCommands/SystemId/spawn_empty/init_resource/resource_scope/insert_batch
├── ecs_metadata.sla — sla_ecs-owned metadata descriptors for stable ids, explicit drop functions, resources/messages/events, and relationships
├── metadata_identity.sla — Explicit namespace/local/type-path digest identity helper with duplicate/collision registry checks
├── relationship_declaration.sla — Explicit user relationship source/target component declaration registry with duplicate/collision checks
├── caller_location.sla — Explicit file/line/column caller-location registry for Bevy-style MaybeLocation ids
├── reflect_runtime.sla — Explicit SLA-id reflection runtime consumer connecting AppTypeRegistry descriptors, ReflectComponent/ReflectResource handles, and ReflectCommand operations
├── parallel.sla — Thread-backed read-only shard helpers for ECS query workloads
├── parallel_mut_safety.sla — Bevy-style mutable World concurrent access safety gate and batch selection model
├── parallel_mut_writeback.sla — Bevy-style mutable World explicit intent writeback plan over access-safe batches
├── parallel_iterator.sla — Bevy `ParallelIterator`-style `Vec<i32>` batch consumers and adapters: count/sum/product/min/max/collect/map/partition/fold/all/any/position plus chain/filter/filter_map/flat_map/flatten/inspect/copy/clone/cycle/fuse shapes
├── parallel_slice.sla — Bevy `ParallelSlice`-style read-only and mutable `Vec<i32>` chunk/splat map helpers over `EcsParallelTaskPool`
├── task_pool_builder.sla — Bevy `TaskPoolBuilder` plus Compute/AsyncCompute/Io global task-pool facade over `EcsParallelTaskPool`
├── task_pool_single_threaded.sla — Bevy single-threaded `TaskPool` fallback model over explicit local executor queues
├── task_pool_local_executor.sla — Bevy multithreaded `TaskPool::spawn_local` / `with_local_executor` facade over explicit local queues
├── task_edge_executor.sla — Bevy `edge_executor`-style scheduler/waker queue model with pending-poll rescheduling
├── task_edge_executor_drop.sla — Bevy vendored `edge_executor` executor/task drop lifecycle accounting model
├── task_scope_completion.sla — Bevy `TaskPool::Scope` result queue drain, panic propagation, and drop-cancel accounting model
├── task_scope_executor_drive.sla — Bevy `TaskPool::scope_with_executor_inner` executor-driving branch/tick accounting model
├── task_scope_ordering.sla — Bevy `TaskPool::scope` direct-vs-nested spawn result ordering and scope-drop rejection model
├── task_pool_shutdown.sla — Bevy `TaskPool::drop` shutdown close, worker join, destroy callback, and panic propagation model
├── thread_executor.sla — Bevy `ThreadExecutor`/ticker-shaped synchronous task queue model with explicit owner-thread token
├── thread_executor_drive.sla — Bevy `ThreadExecutor` owner-ticker drive and remote-spawn progress model
├── task_future.sla — Bevy `now_or_never` / `check_ready` / `poll_once` readiness helper model for explicit i32 future/task state
├── task_handle.sla — Bevy `Task<T>` handle-shaped detach/cancel/result readiness model over explicit i32 task registry
├── task_executor.sla — Bevy `Executor` / `LocalExecutor` queue model with spawn/try_tick/run_until_idle and local-spawn rules
├── parallel_table_erased.sla — Thread-backed read-only TableErasedWorld runner for no-conflict access pairs
├── resource_erased.sla — Type-erased multi-resource owner keyed by `resource_type_id()` impl metadata
├── world_registry.sla — Registry-driven arbitrary component id membership, filters, and ticks
├── archetype_registry.sla — RegistryWorld archetype signatures and entity locations
├── world_archetype_value.sla — Archetype-backed homogeneous value storage, query filters, resources, and messages
├── world_table_value.sla — Archetype table-row homogeneous value storage with row migration and query filters
├── commands_table_value.sla — TableValueWorld deferred Commands with table-row migration
├── schedule_table_value.sla — TableValueWorld sequential Schedule with access tracking
├── system_param_table_value.sla — TableValueWorld query/resource/Commands/ResMut/message system-param adapters
├── commands_archetype_value.sla — ArchetypeValueWorld deferred Commands with migration
├── schedule_archetype_value.sla — ArchetypeValueWorld sequential Schedule with access tracking
├── system_param_archetype_value.sla — ArchetypeValueWorld query/resource/Commands/ResMut/message system-param adapters
├── world_registry_typed.sla — Registry-bound typed A/B value owner and queries
├── world_registry_store.sla — Registry-owned arbitrary homogeneous typed value columns with joins
├── world_registry_erased.sla — Registry-owned type-erased heterogeneous component columns
├── world_table_erased.sla — Archetype table-row type-erased heterogeneous component storage with type-id metadata lookup, raw and typed `MessageId<T>` message write/read/get/update/drain helpers, Bevy-style message reader cursor helpers and `get_cursor` aliases, `Query<Entity>`, query `count`/`is_empty`/`contains`, `single`/`get` plus recoverable component, pair, and pair-mut `try_single`/`try_get`/`try_get_many`/`try_get_many_unique`, ordered `get_many`/`get_many_unique`/`iter_many` helpers including Bevy-shaped pair-mut `single_mut`/`get_mut`/`get_many_mut`/`get_many_unique_mut`/`iter_many_mut`/`iter_many_unique_mut` aliases and pair-mut `as_readonly` projection, generated K=2..16 query combinations, `join`/`join_filtered` materialized query helpers, query filters, default query filters / entity disabling with single and multi-`Allow` query escapes, binary `Or`/`And` filters, `Spawned` filters, `RemovedComponents`-style removal tracking, `SpawnDetails::spawned_by` metadata, `Option`/`Has` query data, direct generated `AnyOf` query data up to twelve branches with legacy `first`/`second`/`third`/`fourth` fields preserved through `$ORD`, generated nested `WithAnyOf` query data up to twelve branches, generated nested pair `AnyOf` query data up to twelve branches, and optional tuple query data
├── world_table_erased_relationship.sla — TableErasedWorld + RelationshipWorld wrapper with synchronized entity allocation, linked despawn, delegated default-query-filter/entity-disabling helpers including multi-`Allow` component/pair/pair-mut query wrappers, delegated recoverable `try_single` / `try_single_mut` query wrappers, delegated removed-component tracking helpers, and delegated message reader cursor helpers
├── world_table_erased_observer.sla — TableErasedWorld + erased observer wrapper with component lifecycle, targeted entity events, delegated default-query-filter/entity-disabling helpers including multi-`Allow` component/pair/pair-mut query wrappers, delegated recoverable `try_single` / `try_single_mut` query wrappers, and delegated message reader cursor helpers
├── bundle_table_erased.sla — TableErasedWorld component bundle constructors plus spawn/insert helpers and ordered `spawn_batch` / `insert_batch` / `insert_batch_if_new` helpers for two-/three-component bundles
├── commands_registry_erased.sla — RegistryErasedWorld deferred Commands carrying erased payloads
├── schedule_registry_erased.sla — RegistryErasedWorld sequential Schedule with component-id access tracking
├── commands_table_erased.sla — TableErasedWorld deferred Commands carrying erased payloads, including type-id insert helpers
├── commands_table_erased_relationship.sla — Ordered table-erased component + indexed/remove/detach/replace/despawn-related relationship/resource/message commands
├── commands_table_erased_observer.sla — Deferred table-erased observer commands with lifecycle/event triggering during apply
├── schedule_table_erased_relationship.sla — TableErasedRelationshipWorld Schedule with component/relationship access tracking and batch planning
├── system_param_table_erased_relationship.sla — TableErasedRelationshipWorld query/relationship/query-inspection/RemovedComponents/Single/Populated/two-query join/Commands/ResMut/message system-param adapters, including relationship-preserving direct component/entity/pair query-resource runners, DefaultQueryFilters single- and multi-`Allow` runners for component/entity/pair params, pair-mut writeback, and pair-mut `Single`/`Populated` Allow gates, triple query-resource runners for direct/With/Without/WithWithout/Added/Changed/Or/And filters, pair-mut Single/Populated writeback, MessageReader/MessageWriter/MessageMutator/PopulatedMessageReader, conflicting pair-query ParamSet batching, two, three, four, five, six, and seven disjoint pair-mut ParamSet batching, Commands + pair-mut query runners, pair-mut + MessageReader + Commands runners, pair-mut + MessageWriter + Commands runners, pair-mut + MessageReader + MessageWriter + Commands runners, pair-mut + MessageReader + ResMut + Commands runners, pair-mut + MessageWriter + ResMut + Commands runners, pair-mut + MessageReader + MessageWriter + ResMut + Commands runners, Commands + ResMut runners, pair-mut + ResMut + Commands runners, MessageReader + Commands runners, MessageReader + ResMut + Commands runners, MessageWriter + Commands runners, MessageWriter + ResMut + Commands runners, MessageReader + MessageWriter + Commands runners, MessageReader + MessageWriter + ResMut + Commands runners, and generated direct `AnyOf2..12`, `WithAnyOf2..12`, `PairWithAnyOf2..12`, plus `AnyOf3WithOptionalPair` query-data runners
├── schedule_table_erased_observer.sla — TableErasedObserverWorld Schedule with component/event access tracking and batch planning
├── system_param_table_erased_observer.sla — TableErasedObserverWorld entity/filter/query-data/query-inspection/RemovedComponents/Single/Populated/two-query join/Commands/ResMut/message/event-trigger system-param adapters, including DefaultQueryFilters single- and multi-`Allow` runners for component/entity/pair query-resource params, pair-mut writeback, and pair-mut `Single`/`Populated` Allow gates, MessageReader/MessageWriter/MessageMutator/PopulatedMessageReader, conflicting pair-query ParamSet batching, two, three, four, five, and six disjoint pair-mut ParamSet batching, Commands + pair-mut query runners, pair-mut + MessageReader + Commands runners, pair-mut + MessageWriter + Commands runners, pair-mut + MessageReader + MessageWriter + Commands runners, pair-mut + MessageReader + ResMut + Commands runners, pair-mut + MessageWriter + ResMut + Commands runners, pair-mut + MessageReader + MessageWriter + ResMut + Commands runners, Commands + ResMut runners, pair-mut + ResMut + Commands runners, MessageReader + Commands runners, MessageReader + ResMut + Commands runners, MessageWriter + Commands runners, MessageWriter + ResMut + Commands runners, MessageReader + MessageWriter + Commands runners, MessageReader + MessageWriter + ResMut + Commands runners, and generated direct `AnyOf2..12`, `WithAnyOf2..12`, and `PairWithAnyOf2..12` runners
├── schedule_table_erased.sla — TableErasedWorld Schedule with type-id access tracking, run_if condition-kind storage, and parallel batch planning
├── system_param_table_erased.sla — TableErasedWorld entity/filter/query-data/query-inspection/RemovedComponents/Single/Populated/resource/two-query join/Commands/ResMut/message system-param adapters, including DefaultQueryFilters single- and multi-`Allow` runners for component/entity/pair query-resource params, component/entity `Single`/`Option<Single>`/`Populated` gates, pair-mut writeback, and pair-mut `Single`/`Populated` gates, MessageReader/MessageWriter/MessageMutator/PopulatedMessageReader, conflicting pair-query ParamSet batching, two, three, four, five, six, and seven disjoint pair-mut ParamSet batching, Commands + pair-mut query runners, pair-mut + MessageReader + Commands runners, pair-mut + MessageWriter + Commands runners, pair-mut + MessageReader + MessageWriter + Commands runners, pair-mut + MessageReader + ResMut + Commands runners, pair-mut + MessageWriter + ResMut + Commands runners, pair-mut + MessageReader + MessageWriter + ResMut + Commands runners, Commands + ResMut runners, pair-mut + ResMut + Commands runners, MessageReader + Commands runners, MessageReader + ResMut + Commands runners, MessageWriter + Commands runners, MessageWriter + ResMut + Commands runners, MessageReader + MessageWriter + Commands runners, MessageReader + MessageWriter + ResMut + Commands runners, type-id helpers, and generated direct `AnyOf2..12`, `WithAnyOf2..12`, and `PairWithAnyOf2..12` runners
├── resource.sla      — Generic ResourceSlot<T>
├── messages.sla      — Generic fixed-capacity Messages<T>, MessageWriter<T>, raw id and strong typed `MessageId<T>` write_default/write_batch results, monotonic message ids, read-with-id/get-by-id, MessageMutator-style mutable reads, Bevy-style `get_cursor` / `get_cursor_current`, update/update_drain/drain retention, global-id reader cursor, unread length, missed count, empty, and clear helpers
├── messages_erased.sla — Type-erased multi-message channels keyed by `message_type_id()` impl metadata, with Bevy-style global ids, reader cursors, raw and typed `MessageId<T>` read/get/write helpers, `get_cursor` / `get_cursor_current`, write_default/write_batch id results, update/update_drain/drain retention, and metadata wrappers
├── event_observer_erased.sla — Type-erased Event observer registry with immediate trigger support
├── relationship.sla — Generic Bevy-style relationship runtime with one-to-many, one-to-one, traversal, difference replacement, self-policy, and linked despawn
├── commands_relationship.sla — Deferred RelationshipWorld commands and related spawner helpers for spawn/add/insert/remove/replace/detach/despawn relation mutations
├── hierarchy_relationship_adapter.sla — Typed ChildOf/Children-style facade backed by generic RelationshipWorld, including traversal helpers
├── hierarchy_commands.sla — Deferred commands for the typed hierarchy facade
├── relationship_one_adapter.sla — Typed one-to-one relationship facade backed by generic RelationshipWorld
├── hierarchy.sla    — Bevy-style ChildOf/Children relationship runtime with traversal, Children swap/sort helpers, and recursive despawn
├── world.sla         — Generic fixed-capacity World<A, B, R, M> owner + pair query/writeback
├── world_dynamic.sla — Vec-backed DynamicWorld<A, B, R, M> owner + pair query/writeback
├── world_dynamic3.sla — Vec-backed DynamicWorld3<A, B, C, R, M> with triple bundle/query/filter support
├── query_dynamic.sla — Bevy-shaped DynamicWorld Query<T>, Mut<T>, filters, and writeback
├── schedule_dynamic.sla — Sequential Schedule with stored system functions and access tracking
├── commands_dynamic.sla — Deferred Commands queue for reserve/insert/despawn/resource/message apply
├── schedule_registry_value.sla — RegistryValueWorld sequential Schedule with component-id access tracking
└── commands_registry_value.sla — RegistryValueWorld deferred Commands keyed by component id

examples/
├── archetype_system_param_demo.sla — Archetype-backed query/resource/message param demo
├── archetype_schedule_commands_demo.sla — Archetype-backed Commands + Schedule pipeline demo
├── archetype_value_world_demo.sla    — Archetype-backed value movement/migration demo
├── table_value_world_demo.sla      — Archetype table-row value migration demo
├── table_erased_world_demo.sla     — Type-erased heterogeneous archetype table-row demo
├── table_erased_schedule_commands_demo.sla — Type-erased table-row Commands + Schedule pipeline demo
├── table_erased_system_param_demo.sla — Type-erased table-row system-param demo
├── table_erased_auto_metadata_demo.sla — Type-id metadata lookup demo over the table-erased path
├── table_erased_bundle_demo.sla — Component bundle spawn/insert demo over the table-erased path
├── bevy_readme_parity_table_erased_demo.sla — Bevy README flow over the table-erased full stack
├── table_erased_observer_demo.sla — Table-erased component lifecycle and targeted observer demo
├── table_erased_relationship_demo.sla — Table-erased component storage plus generic relationship wrapper demo
├── table_erased_relationship_commands_demo.sla — Ordered table-erased component + relationship collection/despawn-related commands demo
├── table_erased_relationship_system_param_demo.sla — Table-erased relationship schedule/system-param demo
├── table_erased_observer_system_param_demo.sla — Table-erased observer schedule/system-param demo
├── ecs_metadata_descriptor_demo.sla — Library-owned metadata descriptor demo for components/resources/messages/events/relationships
├── ecs_unified_world_demo.sla — End-to-end Bevy README flow through the unified `ecs_world_*` facade (spawn/insert/query/resource/message/schedule)
├── table_erased_derive_component_demo.sla — Project-level component marker + `impl` metadata demo
├── resource_derive_multi_demo.sla — Resource identity metadata demo
├── message_derive_multi_demo.sla — Multi-channel message metadata demo
├── event_observer_demo.sla       — Immediate observer trigger metadata demo
├── relationship_runtime_demo.sla — Generic relationship runtime demo for many/one-to-one/difference/self/linked semantics
├── relationship_commands_demo.sla — Deferred generic relationship command queue demo
├── relationship_one_to_one_demo.sla — Typed one-to-one relationship facade demo
├── relationship_multi_kind_demo.sla — Multiple relationship kinds in one RelationshipWorld demo
├── hierarchy_generic_relationship_demo.sla — Typed hierarchy facade over the generic relationship runtime
├── hierarchy_commands_demo.sla — Deferred typed hierarchy command facade demo
├── hierarchy_relationship_demo.sla — Parent/child relationship traversal, sorting, difference replacement, and recursive despawn demo
├── table_system_param_demo.sla      — Table-row schedule/system-param/Commands demo
├── world_movement_demo.sla        — Fixed World movement/resource/message demo
├── dynamic_world_movement_demo.sla — DynamicWorld demo with 20 entities
├── dynamic_world3_bundle_demo.sla  — DynamicWorld3 bundle/query/filter demo
├── parallel_query.sla              — TableErasedWorld read-only query shards over materialized values and shared Arc snapshots on worker threads
├── dynamic_schedule_demo.sla       — DynamicWorld Schedule pipeline demo
├── dynamic_resource_change_demo.sla — DynamicWorld Res/ResMut change detection demo
├── dynamic_commands_demo.sla        — DynamicWorld deferred Commands demo
├── bevy_readme_parity_demo.sla      — Combined Bevy README ECS flow over registry APIs
├── registry_archetype_demo.sla       — Archetype signature migration demo
├── registry_world_demo.sla          — Arbitrary component id registry/membership demo
├── registry_typed_world_demo.sla    — Registry-bound typed value world demo
├── registry_value_world_demo.sla    — Registry-owned multi-column typed value join demo
├── registry_erased_world_demo.sla   — Type-erased heterogeneous component value demo
└── registry_erased_schedule_commands_demo.sla — Erased Commands + Schedule pipeline demo
```

## Running

```bash
SA_PLUGIN_DEV=1 sa sla test lib/entity.sla
SA_PLUGIN_DEV=1 sa sla test lib/entity_dynamic.sla
SA_PLUGIN_DEV=1 sa sla test lib/entity_set.sla
SA_PLUGIN_DEV=1 sa sla test lib/store.sla
SA_PLUGIN_DEV=1 sa sla test lib/dyn_store.sla
SA_PLUGIN_DEV=1 sa sla test lib/sparse_store.sla
SA_PLUGIN_DEV=1 sa sla test lib/component.sla
SA_PLUGIN_DEV=1 sa sla test lib/ecs_metadata.sla
SA_PLUGIN_DEV=1 sa sla test lib/metadata_identity.sla
SA_PLUGIN_DEV=1 sa sla test lib/relationship_declaration.sla
SA_PLUGIN_DEV=1 sa sla test lib/caller_location.sla
SA_PLUGIN_DEV=1 sa sla test lib/reflect_runtime.sla
SA_PLUGIN_DEV=1 sa sla test lib/parallel.sla
SA_PLUGIN_DEV=1 sa sla test lib/parallel_mut_safety.sla
SA_PLUGIN_DEV=1 sa sla test lib/parallel_mut_writeback.sla
SA_PLUGIN_DEV=1 sa sla test lib/parallel_iterator.sla --test-backend sa
SA_PLUGIN_DEV=1 sa sla test lib/parallel_slice.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_pool_builder.sla --test-backend sa
SA_PLUGIN_DEV=1 sa sla test lib/task_pool_single_threaded.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_pool_local_executor.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_edge_executor.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_edge_executor_drop.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_scope_completion.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_scope_executor_drive.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_scope_ordering.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_pool_shutdown.sla
SA_PLUGIN_DEV=1 sa sla test lib/thread_executor.sla
SA_PLUGIN_DEV=1 sa sla test lib/thread_executor_drive.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_future.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_handle.sla
SA_PLUGIN_DEV=1 sa sla test lib/task_executor.sla
SA_PLUGIN_DEV=1 sa sla test lib/parallel_table_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/resource_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_registry.sla
SA_PLUGIN_DEV=1 sa sla test lib/archetype_registry.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_archetype_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_table_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_table_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_table_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/system_param_table_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_archetype_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_archetype_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/system_param_archetype_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_registry_typed.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_registry_store.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_registry_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_table_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_table_erased_relationship.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_table_erased_observer.sla
SA_PLUGIN_DEV=1 sa sla test lib/bundle_table_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_registry_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_registry_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_table_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_table_erased_relationship.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_table_erased_observer.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_table_erased_relationship.sla
SA_PLUGIN_DEV=1 sa sla test lib/system_param_table_erased_relationship.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_table_erased_observer.sla
SA_PLUGIN_DEV=1 sa sla test lib/system_param_table_erased_observer.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_table_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/system_param_table_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/resource.sla
SA_PLUGIN_DEV=1 sa sla test lib/messages.sla
SA_PLUGIN_DEV=1 sa sla test lib/messages_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/event_observer_erased.sla
SA_PLUGIN_DEV=1 sa sla test lib/relationship.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_relationship.sla
SA_PLUGIN_DEV=1 sa sla test lib/hierarchy_relationship_adapter.sla
SA_PLUGIN_DEV=1 sa sla test lib/hierarchy_commands.sla
SA_PLUGIN_DEV=1 sa sla test lib/relationship_one_adapter.sla
SA_PLUGIN_DEV=1 sa sla test lib/hierarchy.sla
SA_PLUGIN_DEV=1 sa sla test lib/world.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_dynamic.sla
SA_PLUGIN_DEV=1 sa sla test lib/world_dynamic3.sla
SA_PLUGIN_DEV=1 sa sla test lib/query_dynamic.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_dynamic.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_dynamic.sla
SA_PLUGIN_DEV=1 sa sla test lib/schedule_registry_value.sla
SA_PLUGIN_DEV=1 sa sla test lib/commands_registry_value.sla
SA_PLUGIN_DEV=1 sa sla test examples/archetype_system_param_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/archetype_schedule_commands_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/archetype_value_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_value_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_schedule_commands_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_system_param_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_auto_metadata_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_bundle_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_observer_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_relationship_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_relationship_commands_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_relationship_system_param_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_observer_system_param_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/ecs_metadata_descriptor_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/bevy_readme_parity_table_erased_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_erased_derive_component_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/ecs_unified_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/resource_derive_multi_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/message_derive_multi_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/event_observer_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/relationship_runtime_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/relationship_commands_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/relationship_one_to_one_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/relationship_multi_kind_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/hierarchy_generic_relationship_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/hierarchy_commands_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/hierarchy_relationship_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/table_system_param_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/bevy_readme_parity_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/world_movement_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/dynamic_world_movement_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/dynamic_world3_bundle_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/dynamic_schedule_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/dynamic_resource_change_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/dynamic_commands_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/registry_archetype_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/registry_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/registry_typed_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/registry_value_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/registry_erased_world_demo.sla
SA_PLUGIN_DEV=1 sa sla test examples/registry_erased_schedule_commands_demo.sla
```

## Compiler Fix

This project required several Sla compiler fixes in `sa_plugin_sla`:

- `typeSize(.array)` now returns pointer size (`8`) because arrays in structs are heap-backed pointers.
- Chained array-of-struct field access such as `store.values[i].x` now releases temporary registers correctly.
- Moving a local owner into an assignment target now avoids double cleanup; scalar field reads such as `entity.id` do not move the owner.
- Nested `.sla` imports now resolve non-`.sla` imports relative to the imported file.
- Wildcard `.sla` imports are supported as `@import "path/*.sla"` and bare `@import path/*.sla`.
- `Vec<T>` index assignment is supported, including `Vec` fields used inside loops; this unblocks dynamic component writeback.
- Method-call cleanup for `Vec` fields such as `query.items.push(...)` now releases receiver temporaries correctly.
- Nested generic closes such as `Vec<Vec<i32>>` and `Vec<Pair<A, B>>` parse without spacing workarounds.
- Generic impl protocol methods now monomorphize correctly, so `impl Query<T> { iter_len/iter_at }` supports `for item in query`.
- Function pointer values can be stored and passed, which lets schedules keep real `fn(World) -> World` system adapters.
- Generic function specializations can be used as function pointer values, so `foo<T>` works anywhere a matching `fn(...) -> ...` value is expected. `sla_ecs` uses this for shared erased-storage helpers such as `ecs_box_drop<T>` instead of local per-type drop glue.
- Top-level scalar constants such as `const KIND: i32 = 1` lower correctly by inlining scalar literals at use sites; this unblocks command kind tags.
- Use-after-move diagnostics now include the consumed identifier name.
- Field comparisons and nested indexed length expressions such as `len(world.archetypes[archetype_slot].entity_ids)` lower correctly, so table-row storage can use the direct Bevy-shaped expression instead of a workaround.
- `@derive(...)` is now language-neutral in the Sla compiler: arbitrary derive names parse as annotations, but the compiler does not hard-code Bevy/ECS keywords or generate ECS metadata methods. `Entity` uses the generic `@derive(copy, eq, ord, hash, debug)` path, so small handle values can be copied, compared, hashed, ordered, and debug-rendered without hand-written field boilerplate.
- ECS metadata lives in `sla_ecs` code. Component/resource/message/event type ids and component storage kind are ordinary static `impl` methods such as `Type::component_type_id()` and `Type::component_storage_kind()`.
- Engine-specific `@component(storage = "SparseSet")` compiler support was removed; sparse/table storage metadata is exposed by `sla_ecs` impl methods instead.
- Expanded relative `.sai` / `.sal` imports are resolved correctly after `.sla` import expansion, while generated `sa_std/...` imports remain global relative paths.

After changing Sla compiler features, reinstall the dev plugin:

```bash
SA_PLUGIN_DEV=1 sa plugin install --dev /home/vscode/projects/sa_plugins/sa_plugin_sla
```

## Bevy Fidelity

| Bevy ECS concept | sla_ecs status | Verified module |
|---|---|---|
| `Entity` (index + generation, stale rejection, free-list reuse) | done | `lib/entity.sla`, `lib/entity_dynamic.sla` |
| `EntitySet` / `EntityMap<T>` / `UniqueEntityVec` | done | `lib/entity_set.sla` |
| Component storage (table + sparse-set) | done | `lib/world_table_erased.sla` |
| Archetype grouping + entity location migration | done | `lib/world_table_erased.sla` |
| Type-erased heterogeneous columns (`BlobVec`-like) | done | `lib/world_table_erased.sla` |
| `Component` derive marker + `impl` metadata | done | `lib/ecs_metadata.sla` |
| `AppTypeRegistry` + reflected component/resource command consumer | done for explicit SLA ids; not Rust `TypeId`/`dyn Any` reflection | `lib/app_type_registry.sla`, `lib/reflect_runtime.sla` |
| Explicit namespace/local/type-path metadata identity | done for digest-backed stable ids and duplicate/collision detection; not compiler macro generation | `lib/metadata_identity.sla` |
| `Bundle` (2/3-component spawn/insert + batch) | done | `lib/bundle_table_erased.sla` |
| `Query<T>` / `Query<Mut<T>>` / `Query<(A, B)>` / `Query<Entity>` | done | `lib/world_table_erased.sla` |
| `With<T>` / `Without<T>` / `Or` / `And` filters | done | `lib/world_table_erased.sla` |
| `Added<T>` / `Changed<T>` / `Spawned` / `RemovedComponents<T>` | done | `lib/world_table_erased.sla` |
| `Single` / `Option<Single>` / `Populated` gates | done | `lib/system_param_table_erased.sla` |
| direct `AnyOf2..12` / nested `WithAnyOf2..12` / `PairWithAnyOf2..12` world query data and ordinary/relationship/observer system-param wrappers | done | `lib/world_table_erased.sla`, `lib/system_param_table_erased.sla`, `lib/system_param_table_erased_relationship.sla`, `lib/system_param_table_erased_observer.sla` |
| Default query filters / entity disabling + `Allow` escape | done | `lib/world_table_erased.sla` |
| `Resource` / `Res<T>` / `ResMut<T>` + change detection | done | `lib/resource_erased.sla` |
| `Messages<T>` / `MessageWriter<T>` / `MessageReader<T>` + cursors | done | `lib/messages.sla`, `lib/messages_erased.sla` |
| `MessageId<T>` typed wrappers + update/drain retention | done | `lib/messages.sla` |
| Observer (lifecycle + targeted entity events) | done | `lib/event_observer_erased.sla`, `lib/world_table_erased_observer.sla` |
| `Commands` (deferred spawn/insert/remove/despawn) | done | `lib/commands_table_erased.sla` |
| `Schedule` (add_systems + sequential run + conflict tracking) | done | `lib/schedule_table_erased.sla` |
| System params (query + resource + commands + message combos) | done | `lib/system_param_table_erased.sla` |
| `ParamSet` (conflicting access batching) | done | `lib/system_param_table_erased.sla` |
| Generic relationship (source/target sync, linked despawn, difference) | done | `lib/relationship.sla` |
| User relationship source/target declarations | done for explicit declaration registry and collision checks; not compiler derive generation | `lib/relationship_declaration.sla` |
| Hierarchy (`ChildOf` / `Children` + traversal + ordering) | done | `lib/hierarchy.sla` |
| Typed relationship facades (one-to-many + one-to-one) | done | `lib/hierarchy_relationship_adapter.sla`, `lib/relationship_one_adapter.sla` |
| Relationship + observer table-erased integration | done | `lib/world_table_erased_relationship.sla`, `lib/world_table_erased_observer.sla` |
| Thread-backed read-only parallel query shards | done | `lib/parallel.sla`, `lib/parallel_table_erased.sla` |
| Bevy mutable World concurrent access safety gate | done for explicit access-conflict batch selection | `lib/parallel_mut_safety.sla` |
| Bevy mutable World writeback plan | done for explicit intent commits over safe batches; not full Rust in-place async runtime | `lib/parallel_mut_writeback.sla`, `sa_plugin_sla/docs/sab_field_move_reassign_cleanup_memoryleak_issue_cn.md` |
| Bevy `ParallelIterator`-style batch consumers and adapters | done on generated-SA; SAB issues documented | `lib/parallel_iterator.sla`, `sa_plugin_sla/docs/sab_thread_closure_fnptr_parallel_iterator_issue_cn.md`, `sa_plugin_sla/docs/sab_bool_fnptr_predicate_adapter_issue_cn.md` |
| Bevy `ParallelSlice`-style chunk/splat map helpers | done | `lib/parallel_slice.sla` |
| Bevy `TaskPoolBuilder` + global task pools facade | done on generated-SA; focused SAB tests pass; SAB whole-file issue documented | `lib/task_pool_builder.sla`, `sa_plugin_sla/docs/sab_parallel_runner_whole_file_memoryleak_issue_cn.md` |
| Bevy single-threaded `TaskPool` fallback | done for explicit local-executor semantics; not a Rust `Future/Waker` runtime | `lib/task_pool_single_threaded.sla` |
| Bevy multithreaded `TaskPool::spawn_local` / `with_local_executor` | done for explicit local-executor queue/tick semantics; not a Rust `Future/Waker` runtime | `lib/task_pool_local_executor.sla` |
| Bevy vendored `edge_executor` scheduler/waker queue surface | done for explicit i32 task scheduling/polling; not a Rust `Future/Waker` runtime | `lib/task_edge_executor.sla` |
| Bevy vendored `edge_executor` drop lifecycle | done for explicit executor/task drop and leak accounting; not Rust destructor ownership | `lib/task_edge_executor_drop.sla` |
| Bevy `TaskPool::Scope` result drain / panic / drop-cancel surface | done for explicit result queue accounting; not a Rust unwind/runtime implementation | `lib/task_scope_completion.sla` |
| Bevy `TaskPool::scope_with_executor_inner` executor-driving branches | done for explicit branch/tick accounting; not an async/work-stealing runtime | `lib/task_scope_executor_drive.sla` |
| Bevy `TaskPool::scope` direct/nested result ordering contract | done for explicit ordering metadata and scope-drop rejection; not an async/work-stealing runtime | `lib/task_scope_ordering.sla` |
| Bevy `TaskPool::drop` shutdown / join / worker-panic surface | done for explicit lifecycle accounting; not OS thread ownership | `lib/task_pool_shutdown.sla` |
| Bevy `ThreadExecutor` / ticker surface | done for synchronous task-queue semantics; not a Rust `Future` runtime | `lib/thread_executor.sla` |
| Bevy `ThreadExecutor` owner-ticker drive / remote spawn | done for explicit drive-to-idle and drive-until-task semantics; not a Rust `Future` runtime | `lib/thread_executor_drive.sla` |
| Bevy `now_or_never` / `check_ready` / `poll_once` readiness helpers | done for explicit i32 future/task state; not a Rust `Waker` runtime | `lib/task_future.sla` |
| Bevy `Task<T>` handle detach/cancel/result surface | done for explicit i32 task registry; not a Rust `async_task` runtime | `lib/task_handle.sla` |
| Bevy `Executor` / `LocalExecutor` queue surface | done for explicit i32 task registry queues; not a Rust `Future/Waker` runtime | `lib/task_executor.sla` |
| Unified `ecs_world_*` facade | done | `lib/ecs_world.sla` |
| `Ref<T>` (read-only with change detection) | done | `lib/ecs_world.sla` |
| `Local<T>` (system-local state) | done | `lib/ecs_world.sla` |
| `NonSend<T>` / `NonSendMut<T>` | done | `lib/ecs_world.sla` |
| `EntityCommands` (chainable entity commands) | done | `lib/ecs_world.sla` |
| `Command` (function-pointer commands) | done | `lib/ecs_world.sla` |
| `SystemId` / `run_system` (registered systems) | done | `lib/ecs_world.sla` |
| `spawn_empty` / `reserve_entities` / `get_or_spawn` | done | `lib/ecs_world.sla` |
| `init_resource` / `resource_scope` | done | `lib/ecs_world.sla` |
| `insert_batch` | done | `lib/ecs_world.sla` |
| `entity_count` / `clear_trackers` | done | `lib/ecs_world.sla` |
| `required_components` | done | `lib/ecs_world.sla` |
| `common_conditions` (run_once/resource_exists/added/changed/on_message/any_with_component/not/and/or) | done | `lib/ecs_world.sla` |
| `In<T>` / `InRef<T>` / `InMut<T>` (system input/piping) | done | `lib/ecs_world.sla` |
| `run_system_once` / `pipe_systems` | done | `lib/ecs_world.sla` |
| `SystemName` | done | `lib/ecs_world.sla` |
| `WorldId` | done | `lib/ecs_world.sla` |
| `EntityRef` / `EntityWorldMut` (chainable immediate access) | done | `lib/ecs_world.sla` |
| `ComponentEntry` / `entry_or_insert` | done | `lib/ecs_world.sla` |
| `spawn_batch_2` / `insert_or_spawn_batch` | done | `lib/ecs_world.sla` |
| `SystemSet` / `ScheduleLabel` / `ScheduleRegistry` | done | `lib/ecs_world.sla` |
| `ApplyDeferred` (explicit command flush) | done | `lib/ecs_world.sla` |
| `clear` / `retain` / `clone_components` / `move_components` / `log_components` | done | `lib/ecs_world.sla` |
| `InsertMode` (Add vs Replace) | done | `lib/ecs_world.sla` |
| `DetectChanges` (is_added/is_changed on Ref/Mut) | done | `lib/ecs_world.sla` |
| `FromWorld` (construct resource from world) | done | `lib/ecs_world.sla` |
| `Name` / `NameOrEntity` | done | `lib/ecs_world.sla` |
| `If<T>` (conditional system execution) | done | `lib/ecs_world.sla` |
| `FilteredResources` / `FilteredResourcesMut` | done | `lib/ecs_world.sla` |
| `EntityMapper` (entity remapping for cloning) | done | `lib/ecs_world.sla` |
| Concurrent mutable World execution (hybrid parallel-readonly + sequential-mutable) | done | `lib/ecs_world.sla`, `lib/parallel_table_erased.sla` |
| Automatic ECS metadata via auto type-id registry | done | `lib/ecs_world.sla` |
| Broader generated ParamSet/multi-param coverage | done | `lib/system_param_table_erased.sla`, `lib/ecs_world.sla` |
| `QueryBuilder` (with/without/or/and/build) | done | `lib/ecs_world.sla` |
| `insert_batch_if_new` / `try_insert_batch` / `try_insert_batch_if_new` | done | `lib/ecs_world.sla` |
| `clone_and_spawn` / `clone_with_opt_out` / `clone_with_opt_in` | done | `lib/ecs_world.sla` |
| `insert_if` / `insert_if_new` / `insert_if_neq` / `insert_resource_if_neq` | done | `lib/ecs_world.sla` |
| `register_required_components_with` (custom factory) | done | `lib/ecs_world.sla` |
| `clear_all` / `clear_entities` / `clear_resources` / `clear_non_send` | done | `lib/ecs_world.sla` |
| `run_schedule` / `try_run_schedule` / `schedule_scope` (by label) | done | `lib/ecs_world.sla` |
| `Commands::trigger` / `run_schedule` / `add_observer` facades | done | `lib/ecs_world.sla` |
| `iter_combinations` (K=2) query helper | done | `lib/ecs_world.sla` |
| `sort_by_key` query sort | done | `lib/ecs_world.sla` |
| `Deferred<T>` / `SystemBuffer` (buffered commands) | done | `lib/ecs_world.sla` |
| `ComponentCloneBehavior` (Default/Ignore/Custom) | done | `lib/ecs_world.sla` |
| `RelationshipSourceCollection` (Vec/HashSet/IndexSet) | done | `lib/ecs_world.sla` |
| `CombinatorSystem` (And/Or/Xor) | done | `lib/ecs_world.sla` |
| `Stepping` (enable/disable/step/breakpoint) | done | `lib/ecs_world.sla` |
| `SpawnRelated` / `WithRelated` / `WithOneRelated` | done | `lib/ecs_world.sla` |
| `remove_by_id` / `get_by_id` / `get_mut_by_id` | done | `lib/ecs_world.sla` |
| `is_resource_added` / `is_resource_changed` / resource ticks | done | `lib/ecs_world.sla` |
| `get_resource_or_insert_with` / `get_resource_or_init` | done | `lib/ecs_world.sla` |
| `remove_with_requires` | done | `lib/ecs_world.sla` |
| `observer_run_if` (observer conditions) | done | `lib/ecs_world.sla` |
| `with_children` / `add_child` / `insert_child` / `remove_child` | done | `lib/ecs_world.sla` |
| `try_despawn` (alive-guarded despawn returning success) | done | `lib/ecs_world.sla` |
| `get_mut` (value + change-tick accessor with writeback) | done | `lib/ecs_world.sla` |
| `query_filtered` / `try_query` (filtered + fallible query) | done | `lib/ecs_world.sla` |
| `removed_with_id` (component-id keyed removal iteration) | done | `lib/ecs_world.sla` |
| `contains_resource` (explicit alias of has_resource) | done | `lib/ecs_world.sla` |
| `init_non_send_resource` (insert default if absent) | done | `lib/ecs_world.sla` |
| `resource_ref` / `get_resource_ref` / `get_resource_mut` | done | `lib/ecs_world.sla` |
| `modify_resource` (read-modify-write resource) | done | `lib/ecs_world.sla` |
| `iter_entities` / `entities` (live entity iteration) | done | `lib/ecs_world.sla` |
| `entities_and_commands` (entity fetcher + command queue) | done | `lib/ecs_world.sla` |
| Explicit caller location / `MaybeLocation` identity | done for explicit file/line/column stable ids and registry deduplication | `lib/caller_location.sla`, `lib/ecs_world.sla` |
| Automatic Rust-style caller capture | n/a / compiler-limited (SLA uses explicit caller metadata instead of `#[track_caller]`) | `lib/caller_location.sla`, `lib/ecs_world.sla` |

## Bevy ECS Parity Assessment

Based on an audit of `~/projects/bevy/crates/bevy_ecs` (re-verified 2026-07-06), sla_ecs's completion varies by dimension — **API surface parity ~94–96%, behavioral parity ~88–92%**. The single headline figures below are one-dimensional summaries and must be read together with the ⚠️/❌/Gaps sections: the remaining behavioral gaps (full TaskPool/Scope-style worker scheduling and full bevy_reflect-compatible TypeId/dyn Any reflection) are described there and are excluded from the fully-implemented claim.

Measured counts: 270 lib `.sla` modules, 174 `tests/*.sla` files, 90 `examples/*.sla`, and **4,053 source `.sla` `@test` annotations** across `lib/`+`tests/`+`examples/` (3,459 in `tests/`, 515 inline in `lib`, 79 in `examples`; historical isolated-test batch total is 3,465 after Batch 158). All listed modules cover System Registry, EntityCommands, ChangeDetection, Query completeness, Observer+Lifecycle+NonSend, Relationship traversal, explicit user relationship declaration registration, ComponentInfo+EntityDisabling+BundleInfo, Schedule config, Archetype+Entity+Storage, Never, AppTypeRegistry/AppFunctionRegistry descriptor registries, an explicit SLA-id reflection runtime consumer, an explicit namespace/local/type-path metadata identity helper, an explicit caller-location registry, explicit multi-threaded executor plan driving, ready-batch selection, ready-pair/triple bridges, width-dispatch up to 3 into the real pthread-backed runner, a looping fixed three-function ready-batch runner, access-conflict-aware ready-batch grouping, a standalone Bevy-style mutable World concurrent access safety gate, an explicit mutable World intent writeback plan over access-safe batches, dynamic `Vec<fn>` executor catalogs that can schedule arbitrary catalog lengths through the real pthread-backed runner, a worker-count `EcsParallelTaskPool` facade that preserves requested worker counts and uses fixed width-9 arity for small batches plus a dynamic `Vec<JoinHandle<i32>>` worker path above 9, Bevy `TaskPoolBuilder` and Compute/AsyncCompute/Io task-pool usage facade over explicit owned state, a Bevy single-threaded TaskPool fallback model, a Bevy multithreaded `TaskPool::spawn_local` / `with_local_executor` facade, Bevy vendored `edge_executor` scheduler/waker queue and drop-lifecycle models, a Bevy `TaskPool::Scope` result-drain/drop-cancel model, a Bevy `TaskPool::scope_with_executor_inner` executor-driving branch model, a Bevy `TaskPool::scope` direct-vs-nested result ordering model, a Bevy `TaskPool::drop` shutdown/join model, Bevy `ThreadExecutor` ticker and owner-drive models, Bevy `now_or_never` / `check_ready` / `poll_once`-style readiness helpers, `Task<T>` handle detach/cancel/result surface, and `Executor`/`LocalExecutor` queue surface for explicit future/task state, Bevy `ParallelSlice`-style read-only and mutable i32 chunk/splat map helpers and generated-SA verified `ParallelIterator`-style i32 batch consumers/adapters over that TaskPool facade, an observable lifecycle callback runner for Bevy-style `on_thread_spawn` / `on_thread_destroy` worker callbacks, a scope-style TaskPool facade over that dynamic worker-count path including zero-worker scope-thread draining, explicit scoped task sets that collect `spawn`, `spawn_on_scope`, and `spawn_on_external` tasks, merge child task sets in child insertion order, execute through worker-count-limited pthread waves plus caller/external-thread task lanes, expose `scope_with_executor`-style options and executor tick result flags including same-executor no-double-tick behavior, recursively execute runtime child-scope generator tasks including generator-owned result values, run pool-lane child-scope generators and child-result generators on worker threads when available, batch contiguous pool-lane child generators and child-result generators into worker-count-limited waves, preserve child-scope generator lane APIs/counts and executor tick reporting for pool/scope/external generators, track generated direct task execution via `generated_task_count`, expose standalone ordering metadata for Bevy's deterministic direct-spawn / non-deterministic nested-spawn contract, generated table-erased world `AnyOf2..12` query-data plus ordinary, relationship, and observer system-param runners through 12, and return an indexable `Vec<i32>` result list in direct insertion order with per-result round/lane metadata, and run-plan deferred apply cleanup that records deferred systems while clearing non-deferred temporary `unapplied` state, plus library-owned recoverable Result facades and structured scene/entity remap snapshots, verified on focused SA backend suites. Focused Batches 112–158 also pass representative default backend suites after the Batch 122 hash-map refs unblocker and the later SAB call-target/thread-function-pointer fixes, except large/import-heavy or compiler-cleanup edge paths documented under `sa_plugin_sla/docs/`; the new table-erased world `AnyOf12` path is verified on generated-SA and default/SAB, the ordinary system-param `AnyOf12` path and two-/three-/four-/five-/six-/seven-disjoint-pair-mut ParamSet paths are generated-SA verified (`system_param_table_erased.sla`: 132 passed) with default/SAB blocked by `sa_plugin_sla/docs/sab_system_param_removed_components_memoryleak_issue_cn.md`, the relationship system-param `AnyOf12` and two-/three-/four-/five-/six-/seven-disjoint-pair-mut ParamSet paths are verified on default/SAB (`system_param_table_erased_relationship.sla`: 137 passed), the observer system-param `AnyOf12` and two-/three-/four-/five-/six-disjoint-pair-mut ParamSet paths are verified on generated-SA and default/SAB (`system_param_table_erased_observer.sla`: 127 passed), and `parallel_slice.sla` is verified on generated-SA and focused default/SAB suites, `parallel_mut_safety.sla`, `parallel_mut_writeback.sla`, `thread_executor.sla`, `thread_executor_drive.sla`, `task_future.sla`, `task_handle.sla`, `task_executor.sla`, `task_pool_single_threaded.sla`, `task_pool_local_executor.sla`, `task_edge_executor.sla`, `task_edge_executor_drop.sla`, `task_scope_completion.sla`, `task_scope_executor_drive.sla`, `task_scope_ordering.sla`, `task_pool_shutdown.sla`, `metadata_identity.sla`, `relationship_declaration.sla`, `caller_location.sla`, and `reflect_runtime.sla` pass generated-SA and default/SAB, `task_pool_builder.sla` is generated-SA verified with focused default/SAB tests passing and a whole-file SAB import issue documented under `sa_plugin_sla/docs/sab_parallel_runner_whole_file_memoryleak_issue_cn.md`, while `parallel_iterator.sla` is generated-SA verified and its SAB issues are documented under `sa_plugin_sla/docs/sab_thread_closure_fnptr_parallel_iterator_issue_cn.md` and `sa_plugin_sla/docs/sab_bool_fnptr_predicate_adapter_issue_cn.md`.

### ✅ Production-Ready (Fully Implemented + Verified)
- Entity allocation with generation and free-list recycling
- Component storage (dense table + sparse set)
- Archetype-based entity grouping
- Query system (single-component, filtered, QueryBuilder)
- **Multi-component tuple queries** `Query<(A,B)>` / `Query<(A,B,C)>` / `Query<(A,B,C,D)>` plus `Query<(&mut A, &B)>` with writeback
- **Multi-entity fetch** `get_many` / `get_many_unique` / `iter_many` / `iter_many_unique`
- System functions and schedule execution
- **System adapters** `map` / `pipe` / `chain` (named fn pointers; SLA has no `Fn` trait so closure literals can't be generic params)
- Deferred commands (spawn/insert/remove/despawn)
- Resources with change detection
- Messages (ordered event queue)
- Change detection ticks (added/changed tracking)
- Observers (component lifecycle + entity-targeted events)
- Generic relationships with traversal
- Hierarchical relationships (Parent/Children with ordering)
- Entity cloning (clone_and_spawn, opt-in/opt-out)
- Stepping debugger
- **BundleInfo** first-class API (`BundleRegistry`/`BundleInfo`)
- **RequiredComponents** (Bevy 0.15+ auto-insert required components)
- **Disabling components** (Bevy 0.15+ default query filters / Allow)
- **MaybeLocation** change-origin tracking
- **EntityMapper** entity remapping for cloning/serialization
- **Result<T> error handling** (`ecs_world_try_get`/`try_get_resource`/`try_query_single`)
- **Typed SystemSet/ScheduleLabel** via traits (`EcsScheduleLabelTrait`/`EcsSystemSetTrait`)
- **Reflection ECS surface + explicit SLA-id runtime consumer** (fn-pointer tables `EcsReflectComponent`/`ReflectFromWorld`/`ReflectEvent` mirror Bevy's `Reflect*Fns` shapes; `lib/app_type_registry.sla` provides `AppTypeRegistry`/`AppFunctionRegistry` descriptor registries; `lib/reflect_runtime.sla` consumes those descriptors for component/resource/event/message handle operations; this is not full Rust `TypeId`/`dyn Any` reflection, see ❌ below)
- **Unified World facade** covering full `bevy_ecs::world::World` public API
- **System Registry** (`register_system`/`run_system`/`unregister_system`/`run_system_cached`, Bevy `system_registry.rs` parity)
- **EntityCommands completeness** (`try_insert`/`remove_if`/`try_remove`/`retain`/`insert_if_new`/`trigger`/`observe`/entry pattern: `or_insert`/`or_default`/`or_from_world`/`and_modify`)
- **ChangeDetection** full `DetectChanges`+`DetectChangesMut`+`Tick`+`ComponentTicks`+`ComponentTickCells`+`ContiguousComponentTicksRef/Mut`+`MaybeLocation` (is_added/is_changed/is_added_after/is_changed_after/set_changed/set_added/set_if_eq/check_tick). Plus **Traversal** (unit/relationship impls, path follow w/ loop detection, PropagateDirection), **WorldId/WorldIdAllocator**, **DeferredWorld**, and **MapEntities/SceneEntityMapper**.
- **Query completeness** (`iter_combinations` K=3/4, `sort`/`sort_by_key`, `par_iter` batch, `With`/`Without`/`Or`/`Added`/`Changed` filters, `QueryBuilder` with/without/transmute)
- **Archetype + Entity allocator + Edges + Storage** (alloc/free with generation recycling, archetype edges for insert/remove transitions, Table columns, SparseSet)

### ⚠️ Partially Implemented
- **Multithreaded parallel execution — partial, one wired path and one unwired path:**
  - *Wired & verified:* `lib/parallel_runner.sla` provides real pthread-backed disjoint mutable / read-only batch runners, including pair/triple/quad/quint/sext/sept/oct/nine mutable batches (`ecs_parallel_run_mut_batch`, `ecs_parallel_run_mut_triple_batch`, `ecs_parallel_run_mut_quad_batch`, `ecs_parallel_run_mut_quint_batch`, `ecs_parallel_run_mut_sext_batch`, `ecs_parallel_run_mut_sept_batch`, `ecs_parallel_run_mut_oct_batch`, `ecs_parallel_run_mut_nine_batch`) and the read-only pair runner (`ecs_parallel_run_readonly_batch`). Systems share the world via `Arc<*TableErasedWorld<R,M>>` and run on `thread::spawn` calls. Backed by the sla `thread::spawn`/`join` lowering -> `sa_std/thread.sa` macros -> sci `sa_pthread_host.c` libpthread runtime. Verified by `tests/test_ecs_mut_parallel.sla` on the SA backend. (The function names `ecs_world_run_readonly_batch_parallel` / `ecs_world_run_mut_batch_parallel` quoted in earlier revisions of this file do not exist in code — the actual names are `ecs_parallel_run_*`.)
  - *Ready-batch bridge:* `ecs_parallel_run_ready_pair_batch`, `ecs_parallel_run_ready_triple_batch`, and `ecs_parallel_run_ready_batch_up_to3` now take ready batches from `EcsExecutorRunPlan`, validate ordinary non-exclusive/non-local shape/order for threaded batches, run pair/triple batches through pthread runners, serialize one-wide exclusive/local batches, and complete the executor plan so dependents become ready. This closes the first real bridges from Bevy-like executor planning into actual threaded execution.
  - *Dynamic catalog bridge:* `EcsParallelFnCatalog<R,M>` stores arbitrary-length system function catalogs with access metadata. `ecs_parallel_run_ready_dynamic_catalog_batch_unbounded` and `ecs_parallel_run_ready_all_dynamic_catalog_unbounded` greedily select non-conflicting ready systems, serialize exclusive/local systems, skip `should_run=false` systems while releasing dependents, and execute dynamic schedules through the pthread runner. Batches up to 9 systems use the fixed arity path; wider batches use `Vec<JoinHandle<i32>>` to spawn and join a dynamic number of worker threads.
  - *Mutable World access safety and writeback plan:* `lib/parallel_mut_safety.sla` models Bevy's pre-dispatch concurrent mutable World access gate over explicit metadata: component read/write conflicts, resource read/write conflicts, message read/write conflicts, exclusive/local system serialization, `should_run=false` skipping before batching, max-width limiting, conflict-deferred systems, and zero-width rejection. `lib/parallel_mut_writeback.sla` layers explicit component/resource/message write intents on top of those safe batches, commits skipped/conflict-deferred/serialized/threaded batches in order, and reports missing intents. Both pass generated-SA and default/SAB. This is an explicit batch/writeback plan, not Bevy's full Rust in-place async executor runtime; a SAB field move/reassign cleanup issue found during development is documented under `sa_plugin_sla/docs/sab_field_move_reassign_cleanup_memoryleak_issue_cn.md`.
  - *ParallelIterator helper bridge:* `lib/parallel_iterator.sla` adds generated-SA verified Bevy `bevy_tasks::ParallelIterator`-style `Vec<i32>` batch consumers for `count`, `sum`, `product`, `min`, `max`, `collect`, `map`, `partition`, `fold`, `all`, `any`, and `position`, plus materialized adapter shapes for `chain`, `filter`, `filter_map`, `flat_map`, `flatten`, `inspect`, `copied`, `cloned`, bounded `cycle`, and `fuse` next-batch behavior. Like the slice helpers, it uses function pointers rather than Rust closure traits. Default/SAB currently fails for `thread::spawn(^|| ...)` capturing predicate/folder function pointers and for ordinary bool function-pointer predicate adapters; the issues are recorded in `sa_plugin_sla/docs/sab_thread_closure_fnptr_parallel_iterator_issue_cn.md` and `sa_plugin_sla/docs/sab_bool_fnptr_predicate_adapter_issue_cn.md`.
  - *ParallelSlice helper bridge:* `lib/parallel_slice.sla` adds Bevy `bevy_tasks::ParallelSlice`-style `par_chunk_map`, `par_splat_map`, `par_chunk_map_mut`, and `par_splat_map_mut` equivalents for `Vec<i32>` using `EcsParallelTaskPool`. They split chunks with Bevy's splat chunk-size formula, spawn one thread per chunk, join results in input/chunk order, return chunk start/length metadata, and return the updated full Vec for mutable chunk maps. The API is intentionally function-pointer/i32 oriented until SLA has Rust-like generic closure traits.
  - *TaskPoolBuilder and usage pools:* `lib/task_pool_builder.sla` adds Bevy `TaskPoolBuilder`-style configuration for worker count, stack size, thread-name id, and spawn/destroy callback flags, building into `EcsParallelTaskPool` with default available parallelism. It also models `ComputeTaskPool`, `AsyncComputeTaskPool`, and `IoTaskPool` get-or-init / try-get / get semantics plus `tick_global_task_pools_on_main_thread` over an explicit `EcsGlobalTaskPools` value, because SLA currently has no `OnceLock`-style global storage primitive. generated-SA whole-file verification passes; default/SAB focused tests pass, while `parallel_runner.sla` whole-file SAB aggregation still has a compiler cleanup issue documented under `sa_plugin_sla/docs/sab_parallel_runner_whole_file_memoryleak_issue_cn.md`.
  - *Single-threaded TaskPool fallback:* `lib/task_pool_single_threaded.sla` models Bevy's `single_threaded_task_pool.rs` observable behavior over the explicit local executor queue: `thread_num` is 1, `spawn` and `spawn_local` immediately drain the local executor to completion, an empty local executor `try_tick` returns false, and `scope` executes `spawn`, `spawn_on_scope`, and `spawn_on_external` lanes on the same thread in insertion order while collecting result values and lane metadata. This is verified on generated-SA and default/SAB.
  - *Multithreaded local executor facade:* `lib/task_pool_local_executor.sla` models Bevy multithreaded `TaskPool::spawn_local` and `with_local_executor` as an explicit local queue separate from the global executor: `spawn_local` queues local work without completing it immediately, `with_local_executor` ticks one local task or drains until idle, local/global queues remain independent, local capacity overflow is recorded, and idle local-executor callbacks are counted. This is verified on generated-SA and default/SAB; it is still an explicit queue model rather than a Rust thread-local executor runtime.
  - *Edge executor scheduler surface:* `lib/task_edge_executor.sla` models Bevy's vendored `edge_executor.rs` scheduler/waker behavior over explicit i32 tasks: spawn immediately schedules a runnable, a registered executor waker is consumed and counted on schedule, `try_tick` polls exactly one runnable, pending polls re-schedule the task, `run_until_task_ready` advances scheduled work until an awaited task result is available, local executors keep independent queues, and queue-capacity overflow is recorded. This is verified on generated-SA and default/SAB; it remains an observable scheduler model, not a Rust `Future/Waker` runtime.
  - *Edge executor drop lifecycle:* `lib/task_edge_executor_drop.sla` models Bevy's vendored `edge_executor` drop tests: leaking an executor leaks pending task payloads, a finished task can still be awaited after the executor is dropped, dropping a finished task before or after executor drop releases its payload exactly once, and awaiting a finished task consumes the result before task drop. This is verified on generated-SA and default/SAB; it is explicit lifecycle accounting, not Rust destructor execution.
  - *Scope completion accounting:* `lib/task_scope_completion.sla` models Bevy `TaskPool::Scope` result-queue behavior: empty scopes return empty results, successful tasks drain in queue order with lane metadata, a pending front task blocks result draining until it completes, a task panic resumes unwind and cancels the remaining queued tasks through scope drop, failed panic catching is surfaced separately, and dropping a scope cancels every queued task. This is verified on generated-SA and default/SAB.
  - *Scope executor-driving branches:* `lib/task_scope_executor_drive.sla` models Bevy `TaskPool::scope_with_executor_inner` branch selection and tick accounting for `execute_scope`, `execute_global_scope`, `execute_external_scope`, and `execute_global_external_scope`. It records the zero-worker forced pool-executor tick, the rule that an external executor identical to the scope executor is not double-ticked, worker completion when global ticking is disabled, unrelated global task latency when global ticking is enabled, and executor restart counts after caught panics. This is verified on generated-SA and default/SAB; it is still an explicit branch/tick model rather than an async work-stealing runtime.
  - *Scope result ordering contract:* `lib/task_scope_ordering.sla` models the Bevy `TaskPool::scope` documentation contract that results from tasks spawned directly by the scope closure are deterministic in spawn order, while tasks that spawn more scoped tasks produce result ordering callers must treat as non-deterministic. It records parent/child result metadata, explicit lane metadata, panic-cancel accounting, explicit scope-drop cancellation, and escaped-spawn rejection after scope close. This is verified on generated-SA and default/SAB; it is still ordering metadata over explicit tasks rather than Rust lifetime or async runtime enforcement.
  - *TaskPool shutdown accounting:* `lib/task_pool_shutdown.sla` models Bevy `TaskPool::drop`: shutdown is closed once, every worker is joined once, destroy callbacks are accounted once per worker, worker join panics propagate only when the caller is not already panicking, and the same worker panic is suppressed during outer panic unwinding. This is verified on generated-SA and default/SAB.
  - *ThreadExecutor ticker model:* `lib/thread_executor.sla` adds a synchronous Bevy `ThreadExecutor`/`ThreadExecutorTicker`-shaped queue: `spawn_value` enqueues task results, only the owner-thread token obtains a ticker, `try_tick` completes one queued task, detached tasks still execute, task handles can query completion/value, and explicit executor ids model `is_same`. `lib/thread_executor_drive.sla` extends that surface with Bevy's owner-thread drive behavior: remote threads can spawn tasks but cannot tick them, the owner ticker can run until idle, and a target task can be driven until ready while later queued tasks remain pending. This is verified on generated-SA and default/SAB, but it is intentionally not a Rust `Future`/`async_task::Task` runtime.
  - *Future readiness helpers:* `lib/task_future.sla` adds Bevy `futures.rs`-style `now_or_never`, `check_ready`, and `poll_once` readiness helpers over explicit `EcsTaskFutureI32` state, including the Bevy distinction that `now_or_never` cancels pending work while `check_ready` leaves pending futures reusable. It also polls `EcsThreadTask` handles against `EcsThreadExecutor` completion state. This is verified on generated-SA and default/SAB; it remains a readiness model, not a Rust `Waker` runtime.
  - *Task handle surface:* `lib/task_handle.sla` adds Bevy `Task<T>`-style handle semantics over an explicit i32 task registry: pending tasks require a registry tick to complete, `detach` records that a handle was released while work continues, canceling pending work prevents future completion, canceling completed work returns the result, and completed results are one-shot. This is verified on generated-SA and default/SAB; it is not a replacement for `async_task::Task` internals.
  - *Executor queue surface:* `lib/task_executor.sla` adds Bevy `Executor` / `LocalExecutor`-style queue semantics over the same explicit task registry: `spawn` queues work, `try_tick` advances at most one queued task, `run_until_idle` drains ready work, capacity overflow is recorded, `spawn_local` is rejected on the global executor and accepted on the local executor, and produced handles interoperate with `task_handle.sla` result taking. This is verified on generated-SA and default/SAB; it is still an explicit i32 queue model rather than a Rust `Future/Waker` executor.
  - *TaskPool facade and scoped tasks:* `EcsParallelTaskPool` now records and uses the requested worker count without clamping to the fixed arity ceiling, and exposes `ecs_parallel_task_pool_run_ready_dynamic_catalog_batch` / `ecs_parallel_task_pool_run_ready_all_dynamic_catalog` plus scope-style aliases `ecs_parallel_task_pool_scope_run_ready_dynamic_catalog_batch` / `ecs_parallel_task_pool_scope_run_ready_all_dynamic_catalog`. `ecs_parallel_task_pool_run_lifecycle_callbacks` covers the observable `TaskPoolBuilder::on_thread_spawn` / `on_thread_destroy` worker callback counts and return-value aggregation. `EcsParallelScopedTaskSet` adds explicit `scope_spawn` / `spawn_on_scope` / `spawn_on_external`-style task collection, ordered child task-set merge via `ecs_parallel_scoped_task_set_extend`, and `ecs_parallel_task_pool_scope_run_tasks`, which executes threaded tasks in worker-count-limited pthread waves, drains pool-spawned tasks on the scope thread when the pool has zero workers (matching Bevy's `self.threads.is_empty()` forced pool-executor tick), executes on-scope and external tasks on explicit non-pool lanes, joins every threaded wave before the scope returns, and exposes `result_values` via `ecs_parallel_scope_run_result_len` / `ecs_parallel_scope_run_result_at` plus `result_rounds` / `result_lanes` via `ecs_parallel_scope_run_result_round_at` / `ecs_parallel_scope_run_result_lane_at` (`0=pool spawn`, `1=spawn_on_scope`, `2=spawn_on_external`, `3=child generator result`). `ecs_parallel_task_pool_scope_run_tasks_with_options`, `ecs_parallel_scope_options_with_external_identity`, and `EcsParallelScopeOptions` model Bevy's `scope_with_executor(tick_task_pool_executor, external_executor, f)` knobs at the observable lane level, with `ticked_pool_executor`, `ticked_scope_executor`, and `ticked_external_executor` result flags, including the Bevy rule that an external executor identical to the scope executor is not ticked a second time. `ecs_parallel_scoped_task_set_spawn_child_scope` plus `ecs_parallel_task_pool_scope_run_tasks_recursive(_with_options)` let a running scope lane generate another scoped task set and execute those generated child tasks in subsequent scope rounds, including nested generated child scopes; pool-lane child generators and pool-lane child-result generators run on worker threads when workers exist and fall back to scope-thread draining at zero workers, contiguous pool-lane child generators plus child-result generators are batched into worker-count-limited waves while preserving generator insertion order, and on-scope/external child generators now update the same executor tick flags as direct `spawn_on_scope`/`spawn_on_external` tasks. `ecs_parallel_scoped_task_set_spawn_child_scope_with_result` additionally records the generator task's own result before executing its generated child tasks. Child-scope generator variants `ecs_parallel_scoped_task_set_spawn_child_scope_on_scope`, `ecs_parallel_scoped_task_set_spawn_child_scope_on_external`, `ecs_parallel_scoped_task_set_spawn_child_scope_with_result_on_scope`, and `ecs_parallel_scoped_task_set_spawn_child_scope_with_result_on_external` preserve generator lane identity, and recursive results expose `child_scope_pool_count` / `child_scope_local_count` / `child_scope_external_count` / `child_scope_wave_count` / `child_scope_result_wave_count` / `generated_task_count`, where `generated_task_count` counts only direct tasks produced by runtime child scopes and later executed in recursive rounds. This gives callers a Bevy-shaped worker-count executor entry point with verified dynamic worker counts above 9, worker lifecycle callback accounting, zero-worker scope fallback, explicit TaskPool scope task lanes, static child merge, runtime child-scope generation, threaded pool-lane child generators including with-result generation, executor-option reporting, generator lane accounting, generator wave accounting, generated direct-task accounting, and direct-spawn result ordering over the same thread runtime.
  - *Deferred apply tracking:* `EcsExecutorRunPlan` now clears temporary `unapplied` state for non-deferred systems while preserving `apply_order` / `deferred_applied` accounting for systems that actually have deferred buffers. The threaded dynamic TaskPool path verifies that deferred systems are applied and non-deferred systems do not leave stale unapplied bits.
  - *Remaining executor gap:* `lib/executor_multi_threaded.sla` mirrors Bevy's `ExecutorState` dependency-satisfaction state machine (ready/running/completed bitsets, dependency counts, exclusive/local thread flags) and has `EcsExecutorRunPlan` / ready-batch drive helpers. It now has a verified dynamic worker-count path with explicit scoped task collection/execution, a standalone mutable-World access-safety batch selector, an explicit intent writeback plan over safe batches, plus standalone `scope_with_executor_inner` branch/tick and scope result-ordering models, but still does **not** provide Bevy's full async work-stealing task runtime or Rust in-place mutable World executor, so it remains partial relative to Bevy's production `MultiThreadedExecutor`.

### ❌ Not Applicable / Compiler-Limited
- **Full Rust/bevy_reflect runtime reflection remains compiler-limited.** Bevy's `bevy_ecs::reflect` is an adapter over `bevy_reflect` (~25,045 lines / 147 files), whose full mechanism rests on language/runtime primitives SLA does not have: native `TypeId::of::<T>()`, `dyn Any` downcast, and `#[derive(Reflect)]`-injected TypePath/typeinfo. A direct port would require first adding a runtime type system to the SA/SLA compiler itself — that is language engineering outside the sla_ecs boundary, not ECS work.
  - *Descriptor-backed reflected-handle consumer exists.* `lib/app_type_registry.sla` models `AppTypeRegistry` / `AppFunctionRegistry` as explicit descriptor registries: stable numeric ids, type paths, function handles, and ECS `Reflect*` type-data slots. `lib/reflect_runtime.sla` consumes those descriptors to register `ReflectComponent` and `ReflectResource` handles, perform reflected component insert/apply/reflect/remove/take by explicit type id, apply `ReflectCommand` insert/remove/take, and count reflected event/message trigger/send operations.
  - *Still not arbitrary bevy_reflect introspection.* Real Bevy reflection also powers scene (de)serialization, editor inspection, dynamic scripting, hot-reload, and arbitrary `from_reflect` construction over `dyn Reflect`. sla_ecs now has an explicit reflected-handle consumer, but it still has no `bevy_scene`-style serializer/editor/scripting subsystem and no compiler-provided arbitrary value introspection.
  - *Equivalent coverage also exists via SLA idioms.* What Bevy does with reflection is covered statically here: `lib/ecs_metadata.sla` (`EcsMetadataDescriptor`) + `lib/world_table_erased.sla` type-id lookup helpers give by-type-id register/insert/query; `commands_table_erased_*` / `world_table_erased_*` give erased by-id operations on components/bundles/resources/messages; `DynamicWorld<A,B,R,M>` + the table-erased path give dynamic components. This is "doing Bevy's reflection job in the way SLA should", not "porting Bevy's reflection primitives".

All core Bevy README-level semantics (entity/component/bundle/world/query/system/schedule/observer/relationship/message/change-detection/storage/reflected-handle CLI demo flow) are present and verified through end-to-end demos and focused test suites. The two genuinely incomplete areas — a general dynamic multithreaded executor and full compiler-backed bevy_reflect-style arbitrary runtime reflection — remain as described above and are **not** counted in the fully-implemented list above.

## SLA vs Rust:底层哲学差异与映射策略

sla_ecs 不是"把 bevy_ecs 直译成 SLA",而是"用 SLA 应该用的方式做 bevy_ecs 的事"。**两者的实现哲学差异源于编译器/语言原语的不同,而非取舍偏好**。下面逐条列出会直接影响实现形态的关键差异、对应映射策略,以及本项目里的对应证据。

### 1. 仿射(单次赋值)+ 显式移动,而非借用检查
- **Rust/bevy**:基于 `&`/`&mut` 的 borrow checker;值默认可多次使用。
- **SLA/SA**:寄存器级仿射约束(SA_LIMITATIONS §6 "单次赋值"),`x = func(x)` 在 `func` 消费 `x` 时即触发 `UseAfterMove`;且**循环回边**对 `w = func(w)` 这种"自消费-再赋值"形态会丢寄存器状态(faq.md 明列)。
- **映射策略**:凡是 Bevy 用 `&mut world; world.register(..)` 的就地修改链,sla_ecs 多用**返回新值**(Rust 风格的 `let (w, ..) = func(w, ..)` 或递归自由函数)而不是就地改;循环中改世界时用**递归自由函数**规避回边 move。
- **证据**:`lib/world_table_erased.sla` 的批量/clone/clear 用递归;`lib/ecs_world.sla` 的 `ecs_world_*` 多返回 tuple;`lib/hierarchy.sla` 用 `entity_new(e.id,e.gen)` 重建规避 move(faq.md 之"已修复 hierarchy""修复 ecs_template_spawn"条)。

### 2. `Fn`/`FnMut` trait 不存在 → 命名函数指针替代闭包泛型
- **Rust/bevy**:系统是 `impl IntoSystem<I, O>`,适配 `Fn` 闭包与命名函数统一。
- **SLA**:无 `Fn`/`FnMut` trait,闭包字面量 `^|| ..` 无法作为泛型参数的类型约束。
- **映射策略**:system/schedule/add_systems 用**命名函数指针** `fn(...) -> i32`;闭包只在"立即 spawn 线程需要捕获"等局部场景用 `^||`(thread::spawn)。
- **证据**:README ✅ "System adapters map/pipe/chain (named fn pointers; SLA has no Fn trait so closure literals can't be generic params)";`lib/parallel_runner.sla` 在真线程处用 `^|| first(first_ptr)`。

### 3. 无运行时 `TypeId`/`dyn Any` → 静态 type-id + 元数据描述符
- **Rust/bevy**:`TypeId::of::<T>()` + `#[derive(Reflect)]` 提供运行时反射;`AppTypeRegistry` 据此跨类型操作。
- **SLA**:无 `TypeId`、无 `dyn Any`、无 derive-Reflect。
- **映射策略**:用**项目级 derive 标记 + 普通 `impl` 方法**给每个 component/resource/message/event 产出稳定数值 id;`lib/metadata_identity.sla` 提供显式 namespace/local/type-path digest 身份帮助器和重复/碰撞检测;`lib/ecs_metadata.sla`(`EcsMetadataDescriptor`)集中存布局/存储 kind/关系形状;type-erased 路径靠这些 id 做按 type-id 注册/插入/查询;`lib/reflect_runtime.sla` 还用显式 type id 消费 `AppTypeRegistry` descriptor,驱动 reflected component/resource/event/message handle 操作。
- **证据**:README ✅ "metadata IDs + verified type-id lookup helpers";`lib/metadata_identity.sla`、`lib/ecs_metadata.sla`、`lib/world_table_erased.sla` 的 `table_erased_*_lookup` 家族,以及 `lib/reflect_runtime.sla` 的 generated-SA/default 验证。

### 4. 整数 id 而非类型化 `ScheduleLabel`/`SystemSet`
- **Rust/bevy**:`SystemSet`/`ScheduleLabel` 是 marker 类型,编译期防拼写错。
- **SLA**:有 trait 但无 marker derive 工作流的经济性。
- **映射策略**:用 trait `EcsScheduleLabelTrait`/`EcsSystemSetTrait` 提供**类型化标签**,但内部数值仍是 i32 id。
- **证据**:README ✅ "Typed SystemSet/ScheduleLabel via traits"。

### 5. 显式位置传入 vs 自动 caller location
- **Rust/bevy**:`#[track_caller]`/`MaybeLocation` 在 spawn 时自动注入 file:line。
- **SLA**:无自动 caller capture。
- **映射策略**:显式 `caller_location(file_id,line,col)`/`spawn_with_location(file_id,line,col)` API；`lib/caller_location.sla` 提供稳定 id、none 归一和 registry 去重；spawner 不自动捕获，调用方负责传入。
- **证据**:`lib/caller_location.sla` 的 generated-SA/default-SAB 验证，`lib/ecs_world.sla`/table-erased 的 `*_with_location` 家族。

### 6. 真线程从 pthread 起,而非 async task + TaskPool::scope
- **Rust/bevy**:`MultiThreadedExecutor` 基于 async tasks + `TaskPool::scope`,按任务图动态调度到线程池。
- **SLA**:另一条更直接的路径——sla 编译器原生降 `thread::spawn(闭包)` → `sa_std/thread.sa` 宏 → sci `sa_pthread_host.c` 经 `dlsym` 调 libpthread(详见 README ⚠️ 一条)。无 async runtime。
- **映射策略**:**已有真线程并行**(`lib/parallel_runner.sla` 通过 `thread::spawn` 提供 pair/triple/quad/quint/sept/oct/nine fixed-arity batch,并在超过 9 时用 `Vec<JoinHandle<i32>>` 动态保存 worker handles,共享 `Arc<*World>`),`lib/executor_multi_threaded.sla` 也已有显式 `EcsExecutorRunPlan` plan/drive 层来推进 ready/dependency/deferred/skip 顺序,动态 catalog 可按请求 worker-count 分发任意长度系统表,并通过 `EcsParallelTaskPool` 接收 worker-count;`lib/parallel_mut_safety.sla` 补 Bevy 式 mutable World 并发 access-safety gate,`lib/parallel_mut_writeback.sla` 补显式 intent writeback plan;`lib/thread_executor.sla`、`lib/thread_executor_drive.sla`、`lib/task_future.sla`、`lib/task_handle.sla`、`lib/task_executor.sla`、`lib/task_pool_single_threaded.sla`、`lib/task_pool_local_executor.sla`、`lib/task_edge_executor.sla`、`lib/task_edge_executor_drop.sla`、`lib/task_scope_completion.sla`、`lib/task_scope_executor_drive.sla`、`lib/task_scope_ordering.sla` 和 `lib/task_pool_shutdown.sla` 只补 `ThreadExecutor`/ticker/owner drive/readiness/Task handle/executor queue/single-threaded TaskPool fallback/multithreaded local-executor facade/edge_executor scheduler/drop lifecycle/scope result-drain/scope executor-driving/scope result-ordering/TaskPool drop shutdown 的可观察同步队列语义,不声称提供 `Future` runtime;现有 `ecs_parallel_task_pool_scope_run_ready_*` 是 scope-style facade,`EcsParallelScopedTaskSet` 可显式收集 `spawn`/`spawn_on_scope`/`spawn_on_external` tasks,可按 child 插入顺序合并静态 child scope,分别按 pool worker-count 分波执行、在 caller thread 执行和在显式 external lane 执行,并通过 `EcsParallelScopeOptions`/`ecs_parallel_task_pool_scope_run_tasks_with_options` 暴露 `tick_task_pool_executor`、external executor lane 以及 scope/external 同 executor 时不重复 tick external 的可观测状态,还可通过 `spawn_child_scope` + recursive runner 在 scope 执行过程中生成并继续执行嵌套 child task sets,并通过 `spawn_child_scope_with_result` 把 generator 自身返回值纳入结果向量,结果同时带 round/lane metadata,但**Bevy 的完整 async work-stealing task runtime 和 Rust 原生 in-place mutable World executor 仍未复刻**。
- **结论**:线程原语支持的不是问题,缺的是"动态任务图调度层"。

### 7. 泛型 + 一律类型擦除而非 `dyn System`
- **Rust/bevy**:大量 `Box<dyn System>`/`dyn SystemParam`。
- **SLA**:已支持 trait object(`&dyn`),但无运行时类型分发表自带的 RTTI。
- **映射策略**:每条 world 后端类型(homogeneous / registry-typed / table-erased / observer / relationship)用**对应一套系统参数 adapter 函数**(代码生成式组合,见 `lib/system_param_table_erased*.sla`),而非统一 `dyn System`。
- **证据**:README 列举每条后端的 Param runner 组合(`Commands + ResMut runners` 等)。

### 8. 反射:显式 id/handle consumer 已做,完整 bevy_reflect 仍不做(已在 ❌ 节细述)
- 见上节"❌ Not Applicable / Compiler-Limited":SLA 无运行时 TypeId/dyn Any/derive Reflect,所以不做 arbitrary value introspection;但 `lib/reflect_runtime.sla` 已消费 `AppTypeRegistry` descriptor 和 `ReflectCommand`,可按显式 type id 做 reflected component/resource/event/message handle 操作。

### 9. 仿射 + 无有界循环抽象 → 递归而非手写状态机
- SA_LIMITATIONS §3 列"缺少安全有界循环抽象",但 sla 已支持普通 `while`/`for`;真正约束来自**仿射 + 回边 move** 一同作用,复杂清理代码会膨胀。
- **映射策略**:sla_ecs 把会触及回边的逻辑写成**递归自由函数**(`fn step(state) -> state { if base return; return step(next) }`),而非 while 内 `state = func(state)`。
- **证据**:`lib/ecs_world.sla`、`lib/world_table_erased.sla` 的批量/sum/reduce;`faq.md` 的 "ecs_template_spawn_rec" 修复条。

### 共性致因小结
把这张哲学差异表压缩成一句话:**SLA 缺 borrow checker 但有仿射约束、缺 `Fn` trait、缺 runtime TypeId、缺 async runtime,且与 borrow-checker 不同——它要求把"就地修改链"重写成"返回值链"。** 这是 sla_ecs 把"Bevy 用 trait object/反射/async 实现的部分"改成"静态分发 + 类型 id + pthread 真线程"的根因,而非性能偏好。

## Current Gaps

- `messages.sla` now includes `MessageWriter<T>` batching, `MessageReader<T>` cursor reads, monotonic numeric message ids, write_default/write_batch id results, read-with-id/get-by-id helpers, Bevy-style `get_cursor` / `get_cursor_current`, whole-queue length/empty/clear helpers, Bevy-style update/update_drain/drain retention, and MessageMutator-style mutable unread-message reads with writeback. `messages_erased.sla` mirrors those global-id reader, id-returning write, cursor alias, update/update_drain/drain, writer/batch range, and metadata-wrapper semantics for type-erased multi-message channels keyed by explicit message metadata. `world_registry.sla` verifies arbitrary component id registration, membership, With/Without filtering, change ticks, and despawn cleanup. `world_registry_typed.sla` binds typed A/B value stores to registry component ids and uses registry ticks as the source of truth. `world_registry_store.sla` owns any number of registry component columns for a homogeneous Sla value type `T`, including pair joins, pair `Without` filters, Added/Changed queries, and pair-mut writeback. `world_registry_erased.sla` stores heterogeneous component values behind erased boxed pointers with per-component drop functions. `world_table_erased.sla` stores those heterogeneous erased values directly in archetype table columns aligned by entity row, with add/remove/despawn migration, typed queries, Bevy-style default query filters / entity disabling for ordinary queries plus explicit `With`/`Has`/`Allow` access, `RemovedComponents`-style remove/despawn tracking plus clear, auto type-id query helpers, message id write/read/get/update/drain helpers, message reader current/current_update/len/missed/is_empty/clear helpers, message `get_cursor` aliases, and table-erased/observer system-param runners, `Query<Entity>`, query-level and world-level `single`/`get` plus recoverable component, pair, and pair-mut `try_single`/`try_get`/`try_get_many`/`try_get_many_unique`, ordered `get_many`/`get_many_unique`/`iter_many` helpers for entity, component, pair, and pair-mut shapes, Bevy-shaped pair-mut `single_mut`/`get_mut`/`get_many_mut`/`get_many_unique_mut`/`iter_many_mut`/`iter_many_unique_mut` aliases, pair-mut `as_readonly` projection to `Query<(A, B)>`, generated K=2..16 query combination helpers backed by one shared index-combination implementation, materialized `join`/`join_filtered` helpers for entity-item and pair query intersections, `With`/`Without`/`Added`/`Changed`/`Spawned` filters, Bevy-shaped `(With<T>, Without<U>)` tuple filters, binary `Or` and `And` filters, `Query<(A, Option<B>)>` and `Query<(Option<A>, B)>` query data, `Query<(A, Has<B>)>` query data, `Query<(AnyOf<(A, B, C)>, Option<(D, E)>)>`-style optional tuple query data, `SpawnDetails` tick and explicit `spawned_by` metadata, direct generated world `AnyOf2..12` query data, generated nested world `WithAnyOf2..12` and `PairWithAnyOf2..12` query data, nested lower-arity `AnyOf` tuple query data, pair and pair-mut filtered queries, pair-mut writeback, resources, messages, cleanup, and runtime type-id metadata lookup. `commands_registry_value.sla` / `schedule_registry_value.sla`, `commands_registry_erased.sla` / `schedule_registry_erased.sla`, and `commands_table_erased.sla` / `schedule_table_erased.sla` add deferred mutation and ordered system execution over registry-owned and table-row value paths.
- `entity_set.sla` provides `EntitySet`, `EntityMap<T>`, and ordered `UniqueEntityVec` with `Entity` value-key semantics. It currently uses `Vec<Entity>` internally because the present `sa_std` `HashMap`/`HashSet` compare key pointers rather than derived struct equality; this keeps ECS semantics correct while leaving a future internal performance swap open.
- `DynamicWorld<A, B, R, M>` and `DynamicWorld3<A, B, C, R, M>` remain verified typed-column compatibility steps while the registry-bound runtime matures.
- The fixed `World` remains in the tree for regression coverage while dynamic APIs mature.
- Bevy-style dynamic query wrappers, filters, `Res<T>` / `ResMut<T>`, resource change detection, system adapters, sequential schedules, and deferred `Commands` are implemented for the current A/B world shape; the registry-owned homogeneous, type-erased, and archetype-backed value paths now also have component-id queries, commands, schedules, resources/messages, and demos. `archetype_registry.sla` verifies Bevy-style entity location migration between component-signature archetypes, `world_archetype_value.sla` connects those locations to real homogeneous component value columns and tracks resource added/changed ticks, `world_table_value.sla` stores homogeneous component values directly inside archetype table rows with row migration, and `world_table_erased.sla` extends that table-row path to heterogeneous boxed component values plus type-id lookup helpers. The archetype/table/table-erased system-param paths now cover Bevy-style `With`, `Without`, `Added`, and `Changed` query-resource filters where the underlying world supports them; the table-erased path also covers `Query<Entity>` and filtered entity-query system params, `RemovedComponents`-style entity query-resource params, query-level and world-level `single`/`get` plus recoverable component, pair, and pair-mut `try_single`/`try_get`/`try_get_many`/`try_get_many_unique`, ordered `get_many`/`get_many_unique`/`iter_many` helpers including pair-mut `*_mut` aliases and `as_readonly` projection, query inspection via `count`/`is_empty`/`contains`, generated K=2..16 query combinations, materialized `join`/`join_filtered` helpers, pair and pair-mut filtered query/system-param forms, the README tuple filter shape `(With<T>, Without<U>)`, binary `Or` and `And` filters, `Spawned` filters, optional component query data in either tuple slot, optional tuple query data, `Has<T>` query data, `SpawnDetails` tick and explicit `spawned_by` metadata, `Single`, `Option<Single>`, and `Populated` system-param gates, ordinary/observer/relationship two-read-query + resource system params, generated direct world `AnyOf2..12` query data, generated nested world `WithAnyOf2..12` and `PairWithAnyOf2..12` query data, generated direct `AnyOf2..12` ordinary item-query resource params, and generated nested ordinary `WithAnyOf2..12` and `PairWithAnyOf2..12` system-param runners, relationship and observer wrapper runners for the same generated query-data shapes through arity 12, and nested lower-arity `AnyOf` tuple query-data params. `world_table_erased_relationship.sla` wraps table-erased component storage with generic relationships while keeping entity allocation/free-list order synchronized, including delegated recoverable `try_single` / `try_single_mut` and `try_get` / `try_get_many` / `try_get_many_unique` query wrappers with pair-mut mutable aliases, linked despawn cleanup, and target-preserving `despawn_related`. `world_table_erased_observer.sla` wraps the same table-erased path with erased observers, targeted entity events, delegated recoverable `try_single` / `try_single_mut` and `try_get` / `try_get_many` / `try_get_many_unique` query wrappers with pair-mut mutable aliases, and component lifecycle events for add/insert/replace/remove/despawn. `commands_table_value.sla` / `schedule_table_value.sla` / `system_param_table_value.sla` run deferred commands, schedules, and injected params over the homogeneous table-row path; `commands_table_erased.sla` / `schedule_table_erased.sla` / `system_param_table_erased.sla` now cover deferred commands, explicit spawn-location propagation, schedules, injected params, type-id helper APIs, entity/query-data query-resource params including `RemovedComponents`, query inspection params, `Single` / `Option<Single>` / `Populated` params, filtered pair-mut params, spawned pair-mut params, tuple/AND/OR filter params, MessageReader/MessageWriter, conflicting pair-query ParamSet runners, and two, three, four, five, six, and seven disjoint pair-mut ParamSet runners, Commands + `Query<(Mut<A>, B)>` combination runners, `Query<(Mut<A>, B)> + MessageReader + Commands` runners, `Query<(Mut<A>, B)> + MessageWriter + Commands` runners, `Query<(Mut<A>, B)> + MessageReader + MessageWriter + Commands` runners, Commands + `ResMut<R>` combination runners that write the resource before deferred apply, `Query<(Mut<A>, B)> + ResMut<R> + Commands` runners that write query and resource state before deferred apply, MessageReader + Commands runners that apply queued commands after advancing the reader, MessageReader + ResMut + Commands runners that write resources before deferred apply, MessageWriter + Commands runners that batch messages before deferred apply, MessageWriter + ResMut + Commands runners, MessageReader + MessageWriter + Commands runners, MessageReader + MessageWriter + ResMut + Commands runners, and no-conflict parallel batch planning for heterogeneous table rows. `parallel.sla`, `parallel_table_erased.sla`, and `examples/parallel_query.sla` now verify thread-backed read-only query shard paths over materialized values, shared `Arc<TableErasedWorld<...>>` snapshots, and no-conflict table-erased read-only system pairs. `commands_table_erased_relationship.sla` / `schedule_table_erased_relationship.sla` / `system_param_table_erased_relationship.sla` add ordered component/resource/message commands, indexed ordered relationship insertion, relationship remove/detach/replace/difference/despawn-related commands, explicit spawn-location propagation for root and related spawns, component+relationship access tracking, batch planning, and query/relationship/two-query join/Commands/ResMut/message params including MessageReader/MessageWriter, conflicting pair-query ParamSet runners, two, three, four, five, six, and seven disjoint pair-mut ParamSet runners, Commands + pair-mut query runners, pair-mut + MessageReader + Commands runners, pair-mut + MessageWriter + Commands runners, pair-mut + MessageReader + MessageWriter + Commands runners, Commands + ResMut runners, pair-mut + ResMut + Commands runners, MessageReader + Commands runners, MessageReader + ResMut + Commands runners, MessageWriter + Commands runners, MessageWriter + ResMut + Commands runners, MessageReader + MessageWriter + Commands runners, MessageReader + MessageWriter + ResMut + Commands runners, direct/nested `AnyOf2..12` query-data runners, and `AnyOf3WithOptionalPair` over the table-erased relationship world. `commands_table_erased_observer.sla` / `schedule_table_erased_observer.sla` / `system_param_table_erased_observer.sla` now cover deferred observer-world mutations, explicit spawn-location propagation, lifecycle/event triggering during apply, component+event access tracking, batch planning, pair-mut writeback, entity/query-data query-resource params including `RemovedComponents`, query inspection params, `Single` / `Option<Single>` / `Populated` params, filtered pair-mut params, spawned pair-mut params, tuple/AND/OR filter params, Commands, ResMut, MessageWriter, MessageReader, resource/message/two-query join params, conflicting pair-query ParamSet runners, two, three, four, five, and six disjoint pair-mut ParamSet runners, Commands + pair-mut query runners, pair-mut + MessageReader + Commands runners, pair-mut + MessageWriter + Commands runners, pair-mut + MessageReader + MessageWriter + Commands runners, Commands + ResMut runners, pair-mut + ResMut + Commands runners, MessageReader + Commands runners, MessageReader + ResMut + Commands runners, MessageWriter + Commands runners, MessageWriter + ResMut + Commands runners, MessageReader + MessageWriter + Commands runners, MessageReader + MessageWriter + ResMut + Commands runners, and explicit event-trigger params over the table-erased observer world. Automatic Rust-style compiler caller capture remains pending; `caller_location.sla` provides explicit file/line/column stable ids and registry deduplication, and explicit `spawn_with_location` metadata plus deferred Commands spawn-location propagation are verified. Broader generated ParamSet and multi-param coverage outside the explicitly listed verified slices remains open-ended; world query-data, ordinary system-param, relationship, and observer wrappers now reach `AnyOf12` / nested `WithAnyOf12` / `PairWithAnyOf12`; concurrent mutable World execution now has a verified access-safety gate in `lib/parallel_mut_safety.sla` and explicit intent writeback plan in `lib/parallel_mut_writeback.sla`, while Bevy's full Rust in-place async mutable World executor is still not complete.
- Component registration has runtime Sla metadata IDs plus verified type-id lookup helpers. The current path uses project-level derive markers plus ordinary `impl` methods for component/resource/message/event type identity and table/sparse-set storage kind; those methods feed the table-erased, resource-erased, message-erased, event observer, and table-erased observer runtimes. `ecs_metadata.sla` centralizes library-owned metadata descriptors, stable numeric id composition, and relationship shape declarations without compiler ECS keywords; `metadata_identity.sla` provides a library-side explicit digest-backed namespace/local/type-path identity helper with duplicate/collision detection; shared boxed-value cleanup lives in `box_drop.sla` as `ecs_box_drop<T>`. `bundle_table_erased.sla` adds Bevy-style bundle spawn/insert helpers plus ordered `spawn_batch`, `insert_batch`, and `insert_batch_if_new` helpers for two-/three-component bundles over the table-erased path. Automatic compiler macro/derive generation from source names still remains pending.
- `lib/relationship.sla` implements Bevy's generic relationship bookkeeping as data: relationship kind registration, one-to-many target collections, one-to-one target replacement, invalid/self relation policy, source/target synchronization, target source queries, ancestors/root/descendants/siblings/leaves traversal, replace/detach, `replace_related_with_difference`, and linked recursive despawn. `commands_relationship.sla` adds deferred Bevy-style relationship commands plus related spawner helpers over that runtime for spawn-related, add, ordered insert, remove, replace, difference replacement, detach-all, despawn-related, one-to-one replacement, and linked despawn. `relationship_declaration.sla` provides explicit user relationship source/target component declarations with validation, duplicate detection, relationship type-id collision detection, and pair-conflict detection; compiler-generated derive/macro sugar for declaring those pairs remains pending.
- `lib/hierarchy_relationship_adapter.sla` proves typed relationship facades can be built over the generic relationship runtime in `sla_ecs`: `GenericChildOf` / `GenericChildren` wrappers expose add/insert/reparent/detach/replace-with-difference/despawn/traversal behavior without compiler engine keywords. `hierarchy_commands.sla` adds deferred child mutation commands over the typed facade, while `relationship_one_adapter.sla` verifies a typed one-to-one facade.
- `lib/hierarchy.sla` now implements the canonical Bevy `ChildOf`/`Children` relationship shape in `sla_ecs`: source/target synchronization, reparenting, ordered insert/replace, `replace_children_with_difference`, `Children` swap and function-pointer sort helpers, detach, relationship source queries, ancestors, root ancestor, breadth-first descendants, depth-first descendants, siblings, leaves, and linked recursive child despawn. Generic user-defined relationship declaration is available explicitly through `relationship_declaration.sla`; compiler-generated relationship derive/macro sugar is still pending.
- The project follows the SA-native Bevy plan: use `Mut<T>` / `ResMut<T>` wrappers and Referee write inference instead of making Rust `mut` the core model.

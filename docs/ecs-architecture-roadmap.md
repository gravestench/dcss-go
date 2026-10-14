# ECS architecture assessment and roadmap

This is the implementation strategy for the ongoing faithful DCSS-to-Go port. It supplements [port-inventory.md](port-inventory.md), which tracks gameplay and content coverage. The Go port works from local `main` and uses Akara `v0.1.4`; the C++ reference is pinned at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Human readability contract

The port should be digestible to a developer reading one file at a time.
Handwritten Go lines have a hard maximum of 120 characters and should stay
near 80 when practical. Put each populated field of a multi-field struct
literal on its own line. Give validation, calculation, mutation, and event
emission separate visual space; avoid code cuddling and long compound
conditions that hide the reason for a failure. Comments explain ownership,
invariants, source-specific order, and surprising rules, with pinned C++
source references where helpful. They should not repeat what the next line
already says. The repository's `AGENTS.md` carries this standard into each
implementation slice. Existing long lines will be reflowed in coherent
readability passes; every new or changed handwritten line must meet it now.

## Decision

Use Akara as the source of truth for **mutable, independently addressable game entities** and run their repeatable behavior in systems. Keep dense terrain and exploration grids with each level; keep immutable source content in the catalog; keep the terminal, save codec, RNG streams, and turn coordinator outside ECS. An ECS component is warranted when a value varies by entity, must survive turns or saves, or controls which entities a system processes. A system is warranted when a behavior acts on a set of entities or combines components in an ordered turn phase. Neither a static definition nor a one-off calculation needs an entity.

“Pure ECS” for this port means entity behavior and mutable entity state have one Akara-backed path. It does **not** mean representing every wall, source definition, screen cell, random stream, or session clock as a singleton entity. This preserves the previously chosen dynamic-entities-in-ECS / terrain-as-grids boundary.

## Current-state audit

| Area | Current implementation | Assessment and next move |
| --- | --- | --- |
| Actors and character state | `ecs.Actor`, `Position`, `Health`, `Magic`, `Attributes`, `Skills`, `Progression`, `Combatant`, `Durations`, `Regeneration`, and `PlayerControlled` are Akara components. `TurnScheduler` reads `Actor.NextAut`. | **Already ECS.** Keep one live value per actor. Split a component only when a new mechanic needs different membership or lifecycle; do not create a component for every catalog field. |
| Monsters | `ecs.MonsterAI` owns behavior, target, and memory. An ordered Akara AI system chooses monster `Intent`; a source-backed factory creates the fixed rat, quokka, and frilled lizard with live ECS components. | **Decision and fixed-scenario creation use ECS.** Reuse the factory from a future level builder with a caller-owned population RNG stream. Add capability components only for actual differences such as spellcasting or special movement. |
| Movement and stairs | Akara systems read `Intent`, `Position`, and level grids, but use a shared `TurnContext` and fixed floor IDs. | **Partly ECS.** Retain systems, replace fixed stair destination logic with level/branch data, and keep the active-turn context explicit. Grid collision and occupancy remain level services derived from `Position`. |
| Combat and death | Registered Akara systems mutate `Health`, `Combatant`, and `Progression` through injected stores. `playerCombat` reads the live Fighter's components and catalog for attack, delay, and defense projections. The live attacker set uses a source-validated ordinary-bite profile for rat, quokka, and frilled lizard. | **System ownership is explicit; lifecycle coordination remains.** Generalize attack effects from components plus immutable definitions as new monsters arrive. Keep corpse creation and entity removal queued at the post-system barrier. |
| Items and equipment | Floor items, inventory links, equipped slots, quantities, and corpses are entities/components. `pickupSystem` and `quaffSystem` run in Akara; quaff receives its exact stores, RNG, and action context but still hard-codes three potions. | **State is already ECS; behavior is partial.** Keep item definitions in the catalog. Make pickup text derive from the item. Add effect handlers as content is ported; use components for persistent effects, not for each potion identity. |
| Status and regeneration | `Durations.MightAut` and `Regeneration` are components; their systems now receive narrow store dependencies and action context but only support the player. | **Partly ECS.** When a second status needs different application/removal rules, use an optional typed component or a small explicit status model rather than growing one player-only struct indefinitely. |
| Corpses and floor timers | Corpses are ECS entities, but `Game.ageCorpses` scans their store outside the system pipeline. `Game.levelAwaySince` holds floor clocks. | **High-priority behavior move.** Run corpse aging as a system over corpse/item/position components, with the active level and elapsed aut supplied by the turn coordinator. Move away-time metadata to the level/world owner. |
| World, visibility, and generation | `Level` owns terrain, remembered cells, and occupancy; `Game` holds a derived current visibility mask. Population weights are immutable catalog data; no procedural level generation exists. | **Keep grids outside ECS.** Treat `Level` as map service, not a tile entity collection. A level builder produces grids and then requests Akara entity creation. Recompute derived sight instead of persisting it as a component. |
| Saves and views | `Game.Snapshot` and `Restore` manually copy/validate components in one large file; `Game.View` projects component and level state; Bubble Tea renders the view. | **Keep adapters outside ECS.** Split save validation by component/domain and build read-only projections from stores. Maintain one explicit component serialization schema. UI must never mutate stores. |
| Session services | `Game` owns Akara world, catalog, levels, player ID, RNG streams, clock, messages, and an action context. | **Appropriate composition root.** Keep services outside entity stores. Reduce `Game` methods that implement entity behavior; retain orchestration, lifecycle, save, and view entry points. |

## Akara-specific constraints

Akara `World.Update` runs registered systems sequentially in registration order. It has typed component stores and a command buffer, but no separate resource API in the version used here. The current game invokes one update per acting entity: player `Intent` is submitted before the update, while the AI system writes monster `Intent` during it. Preserve deterministic system order and named RNG stream draw order in every conversion. Use a small explicit action context for the active actor, elapsed aut, events, and queued structural effects; do not invent a singleton “game entity” to carry session services. Create or destroy entities only at a clear post-update barrier unless a system's lifecycle contract proves it safe.

## Migration sequence

Each numbered phase contains contiguous problem categories, committed separately, with the relevant gameplay feature added in the same category when practical. It is acceptable for a branch to be temporarily uncompilable during a category; verify before its commit. Do not maintain duplicate old/new execution paths or compatibility adapters solely to make intermediate edits compile.

1. **Action pipeline and system dependencies.** Make `Game.Step` validate commands, choose the active actor, submit player `Intent` or request a monster decision, run ordered systems, commit queued structural changes, and assemble events. Replace `*Game` fields inside quaff, combat, death, duration, and regeneration systems with the exact stores/services they use. Keep the current save and turn behavior. This makes system boundaries visible before more monster and effect rules arrive.
2. **Monster decisions and creation.** Move `chooseMonsterIntent` into an ordered AI system that writes the active monster's `Intent`. Centralize actor/component creation in a monster factory. Use the committed Dungeon population picker from a level builder with a caller-owned RNG stream. Introduce a component only when a monster's mutable ability or behavior differs from the shared ordinary path. Avoid a switch per monster ID. Include the frilled-lizard and later ordinary-monster slices here, after the system seam exists.
3. **Combat, effects, and lifecycle.** Generalize ordinary attacks and defenses without copying catalog stats into components. Model mutable wounds, cooldowns, enchantments, and status durations on affected entities. Separate attack resolution from text projection. Make death, XP attribution, corpse creation, and loot drops consume explicit system outputs and commit together.
4. **Items and status families.** Keep inventory and equipment relations as ECS components. Add item-use handlers grouped by effect semantics, then status systems that query only affected entities. Move from the current three-potion switch when a new effect family is implemented, not as a speculative framework.
5. **Level simulation.** Move corpse aging and other entity timers into systems. Keep per-level clocks, terrain, branch position, and explored grids in level/world owners. Make active-floor scheduling explicit so off-floor entities are not repeatedly given no-op turns. Procedural generation produces a grid first and requests entity placement second.
6. **Save and read-model cleanup.** Refactor the large restore validator into per-domain validators over an explicit component schema. Save only authoritative components and level/session state; rebuild occupancy and visibility on load. Keep `Game.View` a read-only projection and Bubble Tea a pure client of commands and views.
7. **Repeat for remaining domains.** For spells, religion, mutations, forms, shops, traps, clouds, allies, and branch mechanics, first identify mutable per-entity state, then add the smallest component and an ordered system for its behavior. Static rules and committed content remain catalog/pure functions; map-wide data remains grids or world state. Track feature fidelity in `port-inventory.md` separately from ECS migration progress.

Phase 1 progress: quaff, combat, death, duration decay, and regeneration systems now receive their required Akara stores and services rather than holding `*Game`. The Fighter's attack, timing, and defense projections live in `playerCombat`. The action barrier remains coordinated in `Game.runAction`.

Phase 2 progress: the ordered Akara monster-decision system reads the acting monster's `MonsterAI` and `Position`, advances the serializable `ai` stream, and writes its transient `Intent` before movement. `Game.Step` no longer selects monster actions. A focused factory now creates the rat, quokka, and frilled lizard from immutable source definitions with mutable ECS state. Population-driven placement and broader capability composition remain next.

## Slice rule and acceptance checks

Before each implementation slice, write a small ownership note: **which entity owns new mutable state, which system changes it, which immutable definition it reads, and what belongs to a level/session instead**. Add a component only if an actual feature or invariant uses it. Keep each behavior in one path; remove its former `Game` implementation in the same category. A completed slice must show deterministic turn/RNG continuation, save/restore of new authoritative state, correct system order, and no rendering or catalog import dependency in the simulation. Run focused tests during development and full test/vet/build plus review at the category boundary.

The next categories are population-driven placement of supported ordinary monsters and action-barrier cleanup as broader combat and level mechanics arrive.

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
implementation slice. The style check now enforces line length, formatting,
expanded literals and blocks, space around control-flow blocks, separated
error guards, space after multiline raw source fixtures, and space between
calculations and writes to owned state in either order.
Review functions over roughly 100 lines for mixed responsibilities. In
particular, project terrain, player state, entities, and inventory in
separate named steps, and split setup from turn decisions. A syntactic
style check cannot establish that a long function is easy to follow or that
statement groups match the game concepts they represent.

## Decision

Use Akara as the source of truth for **mutable, independently addressable game entities** and run their repeatable behavior in systems. Keep dense terrain and exploration grids with each level; keep immutable source content in the catalog; keep the terminal, save codec, RNG streams, and turn coordinator outside ECS. An ECS component is warranted when a value varies by entity, must survive turns or saves, or controls which entities a system processes. A system is warranted when a behavior acts on a set of entities or combines components in an ordered turn phase. Neither a static definition nor a one-off calculation needs an entity.

“Pure ECS” for this port means entity behavior and mutable entity state have one Akara-backed path. It does **not** mean representing every wall, source definition, screen cell, random stream, or session clock as a singleton entity. This preserves the previously chosen dynamic-entities-in-ECS / terrain-as-grids boundary.

## Current-state audit

| Area | Current implementation | Assessment and next move |
| --- | --- | --- |
| Actors and character state | `ecs.Actor`, `PlayerTurn`, `MonsterEnergy`, `Position`, `Health`, `Magic`, `Attributes`, `Skills`, `SkillTraining`, `Progression` (XP, applied level, and pending stat choice), `Combatant`, `Durations`, `Regeneration`, and `PlayerControlled` are Akara components. `TurnScheduler` grants and spends active-floor monster energy; only the player has a logical turn clock. | **Already ECS.** Keep one live value per actor. Split a component only when a new mechanic needs different membership or lifecycle; do not create a component for every catalog field. |
| Monsters | `ecs.MonsterAI` owns behavior, target, and memory. An ordered Akara AI system chooses monster `Intent`; a source-backed factory creates ten ordinary natural-melee monsters with live ECS components. A return-time system heals and moves those monsters through their component stores. | **Decision, creation, and supported off-level catch-up use ECS.** The level builder uses the factory with caller-owned population and placement RNG streams. Add capability components only for actual differences such as spellcasting or special movement. |
| Movement and stairs | Akara systems read `Intent`, `Position`, and level grids. Each `Level` owns saved links from stair cells to destination cells; travel no longer chooses fixed floor IDs or requires a unique stair glyph. | **Partly ECS.** Keep the active-turn context explicit. Grid collision and occupancy remain level services derived from `Position`; branch identity and generation still need world ownership. |
| Combat and death | Registered Akara systems mutate `Health`, `Combatant`, and `Progression` through injected stores. `playerCombat` reads the live Fighter's components and catalog for attack, delay, and defense projections. The live attacker set uses a source-validated natural-melee profile for rat, quokka, frilled lizard, giant cockroach, worm, jackal, adder, bat, ball python, and endoplasm. | **System ownership is explicit; lifecycle coordination remains.** Generalize attack effects from components plus immutable definitions as new monsters arrive. Keep corpse creation and entity removal queued at the post-system barrier. |
| Items and equipment | Floor items, inventory links, equipped slots, quantities, and corpses are entities/components. `pickupSystem` and `quaffSystem` run in Akara; quaff receives its exact stores, RNG, and action context but still handles four supported potions explicitly. | **State is already ECS; behavior is partial.** Keep item definitions in the catalog. Make pickup text derive from the item. Add effect handlers as content is ported; use components for persistent effects, not for each potion identity. |
| Status and regeneration | `Durations.MightAut`, `Durations.HasteAut`, `Regeneration`, and optional `Poison` are components; their systems receive narrow store dependencies and action context. The adder poison system runs after player regeneration and curing removes the component. Haste shares the player duration owner with might; its action speed is calculated once before systems run. | **Partly ECS.** Add another optional typed component when a new status has a distinct lifecycle. Shared resistances and monster poison rules remain future work. |
| Corpses and floor timers | Corpses are ECS entities. `corpseAgingSystem` owns their item/corpse mutations and removal, while each `Level` owns its away clock. The turn coordinator invokes the system at the post-action 200-aut boundary and on floor return. | **ECS-owned lifecycle.** Preserve this timer barrier when adding other timed floor entities; do not run rot once per acting monster. |
| World, visibility, and generation | `Level` owns terrain, remembered cells, and occupancy; `Game` holds a derived current visibility mask. Population weights are immutable catalog data; `levelgen` builds D:1–2 `layout_basic` geometry as a temporary grid for live play. | **Keep grids outside ECS.** Treat `Level` as map service, not a tile entity collection. The level builder produces grids; the game then requests Akara entity creation. Recompute derived sight instead of persisting it as a component. |
| Saves and views | `Game.Snapshot` and `Restore` manually copy/validate components in one large file; `Game.View` projects component and level state; Bubble Tea renders the view. | **Keep adapters outside ECS.** Split save validation by component/domain and build read-only projections from stores. Maintain one explicit component serialization schema. UI must never mutate stores. |
| Session services | `Game` owns Akara world, catalog, levels, player ID, RNG streams, clock, messages, and an action context. | **Appropriate composition root.** Keep services outside entity stores. Reduce `Game` methods that implement entity behavior; retain orchestration, lifecycle, save, and view entry points. |

## Akara-specific constraints

Akara `World.Update` runs registered systems sequentially in registration order. It has typed component stores and a command buffer, but no separate resource API in the version used here. The current game invokes one update per acting entity: player `Intent` is submitted before the update, while the AI system writes monster `Intent` during it. Preserve deterministic system order and named RNG stream draw order in every conversion. Use a small explicit action context for the active actor, elapsed aut, events, and queued structural effects; do not invent a singleton “game entity” to carry session services. Create or destroy entities only at a clear post-update barrier unless a system's lifecycle contract proves it safe.

## Migration sequence

Each numbered phase contains contiguous problem categories, committed separately, with the relevant gameplay feature added in the same category when practical. It is acceptable for a branch to be temporarily uncompilable during a category; verify before its commit. Do not maintain duplicate old/new execution paths or compatibility adapters solely to make intermediate edits compile.

1. **Action pipeline and system dependencies.** Make `Game.Step` validate commands, choose the active actor, submit player `Intent` or request a monster decision, run ordered systems, commit queued structural changes, and assemble events. Replace `*Game` fields inside quaff, combat, death, duration, and regeneration systems with the exact stores/services they use. Keep the current save and turn behavior. This makes system boundaries visible before more monster and effect rules arrive.
2. **Monster decisions and creation.** Move `chooseMonsterIntent` into an ordered AI system that writes the active monster's `Intent`. Centralize actor/component creation in a monster factory. Use the committed Dungeon population picker from a level builder with a caller-owned RNG stream. Introduce a component only when a monster's mutable ability or behavior differs from the shared ordinary path. Avoid a switch per monster ID. Include the frilled-lizard and later ordinary-monster slices here, after the system seam exists.
3. **Combat, effects, and lifecycle.** Generalize ordinary attacks and defenses without copying catalog stats into components. Model mutable wounds, cooldowns, enchantments, and status durations on affected entities. Separate attack resolution from text projection. Make death, XP attribution, corpse creation, and loot drops consume explicit system outputs and commit together.
4. **Items and status families.** Keep inventory and equipment relations as ECS components. Add item-use handlers grouped by effect semantics, then status systems that query only affected entities. Move from the current four-potion switch when a new effect family is implemented, not as a speculative framework.
5. **Level simulation.** Move corpse aging and other entity timers into systems. Keep per-level clocks, terrain, branch position, and explored grids in level/world owners. Make active-floor scheduling explicit so off-floor entities are not repeatedly given no-op turns. Procedural generation produces a grid first and requests entity placement second.
6. **Save and read-model cleanup.** Refactor the large restore validator into per-domain validators over an explicit component schema. Save only authoritative components and level/session state; rebuild occupancy and visibility on load. Keep `Game.View` a read-only projection and Bubble Tea a pure client of commands and views.
7. **Repeat for remaining domains.** For spells, religion, mutations, forms, shops, traps, clouds, allies, and branch mechanics, first identify mutable per-entity state, then add the smallest component and an ordered system for its behavior. Static rules and committed content remain catalog/pure functions; map-wide data remains grids or world state. Track feature fidelity in `port-inventory.md` separately from ECS migration progress.

Phase 1 progress: quaff, combat, death, duration decay, and regeneration systems now receive their required Akara stores and services rather than holding `*Game`. The Fighter's attack, timing, and defense projections live in `playerCombat`. The action barrier remains coordinated in `Game.runAction`.

Phase 2 progress: the ordered Akara monster-decision system reads the acting monster's `MonsterAI` and `Position`, advances the serializable `ai` stream, and writes its transient `Intent` before movement. `Game.Step` no longer selects monster actions. A focused factory creates ten ordinary natural-melee monsters from immutable source definitions with mutable ECS state. The playable generated map chooses these supported monsters from the committed Dungeon population table and places them through the factory. The population selector owns the `population` RNG stream, the placement policy owns the `placement` stream, and each monster's mutable state lives in Akara. The source D:1–2 monster-count dice now set population choices; jackal choices create linked packs of two to four ECS actors, with the actual initial actor count saved for validation. The full species pool, other monster capabilities, and other level layouts remain next.

Dungeon population ownership: each spawned monster owns `Actor`, `Health`,
`Combatant`, `MonsterAI`, and `Position` components. Jackal followers also own
`BandFollower`, which stores their leader entity. Ordered monster systems
change those components during turns. The immutable catalog supplies Dungeon
weights and monster definitions. The scenario builder chooses kinds and cells;
the level supplies walkability and occupancy. The game owns named layout, count, population, and placement RNG streams
and saves their states. Live D:1–2 counts follow the pinned three-dice rule;
the fixed test fixture still chooses two monsters per floor.

Phase 5 progress: corpse state remains in Akara stores, and a focused aging system owns its decay and removal. The `Level` owns its away clock. `Game.Step` supplies elapsed aut only after all actor actions, preserving the source's 200-aut timer phase and inactive-floor catch-up. The scheduler grants source-rounded energy only to monsters on the player's floor and acts with the highest-energy ready monster first. Inactive monster energy stays frozen. On return to a visited floor, an event-driven system applies the eleven supported monsters' source HP recovery, including the worm’s fast rate and direct movement toward a saved target before ordinary energy grants resume. First entry skips this update. Bat retreat actions are mutable `MonsterAI` state and survive saves; its plain natural hit and two wandering actions share the existing combat and AI systems. The ball python adds one optional player `Constricted` component, with its constrictor entity and escape attempts. The post-action constriction system owns damage and release, while movement uses a pure escape roll. Save validation checks the cross-entity link. Summons, pacification, enchantments, broader ranged behavior, and other monster capabilities still need their source return-time rules.

Level travel progress: each stair cell has an explicit destination level and arrival cell owned by its `Level`. The new Go save schema stores those links, and restore validates linked destinations and explicit unported boundaries. A pure D:1–2 `layout_basic` builder now produces source-shaped terrain and stair pairs. The generated two-floor scenario is now playable, with connected doors, three stair pairs, source monster-count dice, and explicit boundary exits. Other weighted layouts, vaults, deeper floors, and branch travel are next.

Advancement ownership: the death system credits source-derived XP to the player's `Progression` component and tenfold skill XP to `SkillTraining`. An ordered Akara skill system spends from that player-owned pool before the advancement system applies the selected species' source XP thresholds, recalculates supported species HP/MP, gives periodic random stat gains, and records a pending manual stat choice before levels 3, 9, 15, 21, and 27. Combat writes transient practice events to `TurnContext`; the training system owns both recent-practice queues and the named `skill` RNG stream. The terminal submits no-aut training and stat choices through game methods and renders copied views. Immutable XP and species skill thresholds, baseline species HP/MP live in `character`; skill-cost thresholds keep the source's fixed XP aptitude regardless of species. Training, combat, save validation, and the skills screen read the selected species' skill aptitudes from the ECS player identity and committed catalog. Version-12 saves validate skill points, queues, cost level, XP conservation, player turn time, and monster action energy. Live source-sized D:1–2 monster budgets permit natural level-up. Fighter training now divides each XP batch among enabled skills, shuffles first-phase spending, and uses weighted remainder choices with source-sized chunks. Remaining species' starting profiles, full HP/MP growth, training special cases, manuals, targets, and cross-training remain to port.

Playable starts now include Human, Hill Orc, Deep Elf, and Minotaur
Fighters. The four species share ECS player components and Fighter gear; their
selected identity drives attributes, aptitude-reassessed skills, HP/MP, XP,
periodic stat gains, terminal labels, and save validation. Minotaur's innate
horns stay in the immutable species catalog. The combat system projects that
identity and live ECS skills into pure auxiliary and reflexive headbutt rules;
equipment fit reads the same identity. Acquired mutable mutations will need a
player component when ported.

## Slice rule and acceptance checks

Before each implementation slice, write a small ownership note: **which entity owns new mutable state, which system changes it, which immutable definition it reads, and what belongs to a level/session instead**. Add a component only if an actual feature or invariant uses it. Keep each behavior in one path; remove its former `Game` implementation in the same category. A completed slice must show deterministic turn/RNG continuation, save/restore of new authoritative state, correct system order, and no rendering or catalog import dependency in the simulation. Run focused tests during development and full test/vet/build plus review at the category boundary.

The next categories are source-backed level generation and action-barrier cleanup as broader combat and level mechanics arrive.

Adder poison progress: the seventh supported ordinary animal keeps its static bite data in the committed monster catalog. The combat system rolls poison on landed adder bites and attaches optional `Poison` to the player. An ordered Akara status system decays it after regeneration only on player actions; curing removes it. Snapshot, restore, view, and HUD read the same component. Other monsters, resistance, and broader status families remain future slices.

Haste progress: the fourth supported potion uses the committed item catalog and a fixed Dungeon:2 floor placement. `Durations.HasteAut` is owned by the Akara player; quaff and end-turn systems mutate it. `Game.Step` chooses one source-rounded player speed for each accepted action, and melee delay, scheduling, saves, view, and the `Fast` HUD consume that same state.

Monster spell progress: all 285 active source spellbooks and 697 ordered
slots are committed as immutable content, including frequencies and flags.
The importer runs only for an intentional upstream refresh. The decision
system chooses transient `IntentSpell` for endoplasm Freeze and dart slug
Slug Dart from live ECS identity and position. The level owns clear-shot
queries; the ordered spell system projects live fighter defense into a pure
projectile rule before movement or melee. The same ECS energy component pays
the cataloged spell cost, and the named `monster_spell` stream saves selection
and damage draws. Other book behaviors will enter that path as their
targeting and effects are ported.

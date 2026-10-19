# Lua modding guide

The [root README](../README.md) has the quickest launch and wizard examples.
The Lua tree in `internal/modfs/builtin/` is editable production source. Every
file is loaded from the embedded base plus any `--mod-dir` overlays. No C++
importer or generated index is part of the build. Add a new file to add a
definition; replace the same relative path to change a bundled file.

Start with [the feature workflow](#work-through-a-new-mod-feature) when you
have an idea to add. Use [the `ctx` reference](#the-game-context-ctx) when
writing a rule, and [the test section](#test-a-mod) before sharing it. The
sections on [components](#components), [systems](#systems),
[content](#content-files), [vaults](#vault-maps-and-lua-hooks), and
[saves](#saves-and-identity) describe the contracts those features use.

## Choose an owner for a new feature

| Need | Place it in | Why |
| --- | --- | --- |
| Identity, text, fixed stats or weights | `content/<category>/<name>.lua` | A definition is a fact. |
| Eligibility, calculation or one-shot effect | `policy/<area>/<name>.lua` | The caller invokes it. |
| Per-turn behavior or timers | `systems/<name>.lua` | The scheduler invokes it. |
| Mutable data that survives turns or saves | `schemas/<name>.lua` | The ECS owns per-entity state. |
| Shared names, IDs, or enums | `constants/` or `ids/` | Import them at use sites rather than retyping magic values. |
| Vault geometry and directives | `vaults/<family>/<name>.des` | Original map syntax is the source. |
| Dynamic vault directive | `policy/generation/vaults/<family>/<name>.lua` | A named `.des` hook calls this module. |

For example, a new poison monster may need one monster definition if existing
attack flavors already express it. A new poison mechanic needs a focused
policy, a component for its remaining duration, and a system to tick that
duration. Keep a policy's input and output explicit. Do not create one huge
switch over every monster or spell ID; register a focused resolver in the
appropriate effect registry.

## Write readable Lua

Explain the particular rule or data in each file. In a long policy or system,
put comments beside the decision, timing edge, random draw, or component write
that needs context. State why the rule works that way and how it relates to
DCSS when that helps a reader. Avoid a shared header pasted into every file,
and avoid comments that merely repeat a field name. A short static definition
may need only a specific introduction and notes beside its less obvious field
groups.

Prefer lines around 80 characters and keep every line at or below 120.
Break multi-field table instances across lines. Give reusable IDs, enums,
and string tokens names in `ids/` or `constants/`, then import those names
where they are used. Lua tests belong in `_test.lua` files and should import
production schemas and rules instead of copying them into fixtures.

## Scaffolding

```sh
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=weapon --name="moss blade"
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=system --name="moss growth" --namespace=moss
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=vault --name="moss room" --with-hook
go run ./cmd/dcrawl-mod --mod-dir=/path/to/my-mod --kind=vault --name="moss shop" --family=shop
```

Kinds are `artefact`, `branch`, `cloud`, `item`, `weapon`, `unique-item`, `job`,
`monster-beam`, `monster-spellbook`, `monster`, `mutation`, `shop`, `species`,
`spell`, `trap`, `component`, `system`, `policy`, `player-effect`,
`monster-effect`, and `vault`. `player-spell-effect` and
`monster-spell-effect` are aliases for the two effect kinds. Use `--id` to
override a generated identifier. Use `--area` to place a policy under a
specific `policy/<area>/` directory and `--family=shop` for a shop vault.
The wizard creates the right directory and filename, refuses overwrites, and
rejects path traversal. Content starters deliberately leave registration
commented out until their required fields are filled. Compare a nearby bundled
file, then uncomment `register.definition` and run the game or tests. System
starters register a harmless update callback so you can add a query and rule.
For an effect, wire its `resolve` method into the relevant registry. The
wizard only creates files; it does not pretend an unfinished mechanic is live.

DCrawl embeds its Lua rules under `internal/modfs/builtin/`. Add one or more
mod directories by repeating `--mod-dir` in the order they should apply:

```text
dcrawl --mod-dir=/path/to/extra-monsters --mod-dir=/path/to/spell-changes
```

For example, the first directory can contain only
`content/monsters/my_monster.lua`; the second can override the bundled
`content/spells/spell_airstrike.lua`. A file with the same relative
path in a later directory replaces the earlier file. A new path joins the
effective tree.
Each directory can contain just one Lua file; no manifest, copied base tree,
or generated registry is required. The effective tree is loaded once per
game session. Changes on disk take effect when a new session starts.
Lua source lives in `.lua` files in this tree and in test mod directories;
Go source does not contain inline Lua programs.

The embedded tree is the base layer. Each `--mod-dir` adds a sparse layer;
later layers win when paths match. All Lua modules, including `require`
calls and automatically discovered files, read the resolved tree. Save
identity uses the final relative paths and file bytes. Moving a mod directory
without changing its effective Lua files does not change that identity.

| To add | Put the file here | Add another file when |
| --- | --- | --- |
| Monster | `content/monsters/<name>.lua` | It needs a new AI or other behavior. |
| Spell | `content/spells/<name>.lua` | It needs a new resolver under `policy/magic/effects/`. |
| Item | `content/items/<name>.lua` | It needs a new use, combat, or equipment rule. |
| Unique artefact | `content/artefacts/<name>.lua` | Its special properties need a focused rule. |
| Magical staff | `content/items/<name>.lua` | Its proc needs a new rule. |
| Ring or amulet | `content/items/<name>.lua` | It needs a new effect capability. |
| Job | `content/jobs/<name>.lua` | It needs a new starting-gear rule or other behavior. |
| Item class | An item file with a new `class` ID | It needs class-specific rules or UI. |
| Mutation | `content/mutations/<name>.lua` | It needs an effect under `policy/mutations/effects/`. |
| Branch, cloud, trap, or shop | `content/<category>/<name>.lua` | It needs a new selection or effect rule. |
| Monster spellbook or beam | `content/<category>/<name>.lua` | It needs a new resolver. |
| ECS component | `schemas/<name>.lua` | Its behavior needs a system. |
| ECS system | `systems/<name>.lua` | Its state needs a new component. |
| Game policy | `policy/<area>/<name>.lua` | It needs new content or a component. |

A data-only addition takes one file when existing rules already understand
it. A genuinely new mechanic takes a small set of files: its definition,
focused policy or system, and a `_test.lua` file using the production schema.
Completed content and behavior files register themselves when discovered.
There is no central switch to edit for each new monster, spell, item,
component, or system. The loader
rejects duplicate IDs and invalid definitions with their source paths.

Write comments for the next human reader. Give each Lua file its own purpose
and explain each function's reason for existing and how it implements the
rule. A comment that merely repeats the function name or shows a call is not
enough. Systems also need a theory of operation covering their query, timing,
and state changes. Policy files need a concrete usage example. Place comments
beside non-obvious branches and data fields, especially where a DCSS rule or
saved component explains the choice. Keep lines at most 120 columns and aim
for about 80 where the explanation remains clear.

Magical staves use the shared staff weapon profile and wield command. Set
`class` to `OBJ_STAVES`, `slot` to `weapon`, and add a `staff` table with
`school`, `skill_id`, and `message`. Add either `resistance_id` for an
elemental proc or `ac_rolls` for a physical proc. Optional fields are
`damage_numerator`, `damage_denominator`, and `poison_level`. Import spell
school and resistance IDs from `constants.spell_schools` and
`constants.resistance_ids`. A new file with this metadata also gets the
matching spell enhancer, player resistance, wield picker, and save checks.

Jewellery uses `class = OBJ_JEWELLERY` and a `jewellery` table with
`kind = jewellery_kinds.RING` or `jewellery_kinds.AMULET`, imported from
`constants.jewellery_kind`. Add an `effects` map whose keys come from
`constants.jewellery_capabilities`; values are numbers or
`magnitudes.ITEM_PLUS` from `constants.jewellery_magnitudes`. The shared
projection gives an item existing stat, resistance, regeneration, vision,
flight, spirit-shield, and acrobat behavior without an item-ID branch.
Set `pluses = true` when an effect uses `magnitudes.ITEM_PLUS`. The shared
equipment policy provides ring and amulet slots, `P`/`R` input, and save
validation. `REFLECTION` returns the currently supported blocked hostile
missiles and Slug Dart to their shooter. Each projectile or spell effect
declares whether it is reflectable; new effects can opt in using the same
return resolver. Faith piety needs its later religion event domain.

The bundled `init.lua` loads `schemas/`, `content/`, `policy/`, `systems/`,
`generation/`, and `ui/` in that order. Paths within each tree load in sorted
order. A new file under one of these directories is discovered automatically. Put helpers
under `lib/` and load them with `require("lib.helper")`. `require` reads the
effective embedded-plus-overlay tree; it cannot read arbitrary disk files.

## Components

A file such as `my_mod/constants/component.lua` defines a shared name:

```lua
-- Keep this ID in one place so schemas and systems cannot disagree.
local component = {
    TURN_COUNTER = "my_mod.turn_counter",
}

return component
```

A file such as `schemas/turn_counter.lua` may register the component:

```lua
local components = require("my_mod.constants.component")

-- Store one counter per entity so actions and saves see the same value.
local schema = {
    id = components.TURN_COUNTER,
    version = 1,
    fields = {
        count = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
```

IDs must be unique. Field types currently supported by Akara's dynamic
schemas are `bool`, `int64`, `uint64`, `float64`, `string`, and `entity`.
For each scalar type `T`, schemas may also declare `list<T>` and
`map<string,T>`. For example, `list<entity>` holds entity handles and
`map<string,int64>` holds named counters. Collections default to empty tables;
they cannot contain nested collections. Lists require consecutive integer keys
starting at 1, and maps require string keys. Component reads return detached
tables, so call `ctx:set` after editing one.
Integer values passed through Lua must be exactly representable in its
numeric type (absolute value at most 2^53). Entity values are userdata
handles, not numeric IDs. Registered dynamic components are included in saves.

## Systems

A file such as `systems/turn_counter.lua` may register a system:

```lua
local system = {}
local components = require("my_mod.constants.component")

-- Theory of operation: the scheduler visits only entities with the counter.
-- Each action adds one count, and storing it on the entity preserves it in
-- saves. Delta is unused because this example counts actions, not elapsed aut.
-- Example: a matching actor with count 2 has count 3 after its next action.

-- Replace the detached snapshot so the ECS records the new count.
function system.update(ctx, entity, delta)
    local turns = ctx:get(entity, components.TURN_COUNTER)

    ctx:set(entity, components.TURN_COUNTER, {
        count = turns.count + 1,
    })
end

register.system({
    id = "my_mod.count_turns",
    scope = "active",
    after = { "status.poison" },
    query = { components.TURN_COUNTER },
    update = system.update,
})

return system
```

Add `TURN_COUNTER = "my_mod.turn_counter"` to your mod's own
`my_mod/constants/component.lua` module and import it here and in the schema
file. The bundled `constants.component` module contains only bundled IDs; a
sparse mod must not replace that whole module just to add one name.

`scope = "all"` is the default and visits matching entities in Akara's
stable entity order. `scope = "active"` visits the actor taking the current
turn. `query` names registered Lua or host components that must exist. `after` and
`before` name other Lua systems or the current Go systems listed in
`internal/game/systems_registration.go`. Unknown names and cycles fail at
startup. Systems with no dependency between them run by stable system ID,
regardless of file discovery or registration order. Use `after` and `before`
when one system must observe another system's changes. Keep state that must
survive a save in components, not Lua module globals.

The callback receives `ctx`, the entity handle, and `delta`, the elapsed
action time in **aut** (the game's time unit). A normal move usually costs
10 aut; other actions can differ. `ctx:aut()` is the absolute game clock in
aut. Use `delta` for elapsed-time effects and do not assume that every system
call represents one turn.

Bootstrap has a five-second execution deadline and each system callback has
a two-second deadline. A looping or unusually slow Lua file fails with an
error instead of freezing the client.

The runtime also exposes the Go engine's existing components and grid through
`core.*` component names and context methods. Game behavior is moving into
Lua rules while Go retains generic ECS, VFS, save, and terminal services.

## The game context (`ctx`)

`ctx` is the game's capability object for a running Lua rule. Systems receive
it as `update(ctx, entity, delta)`; host-invoked mutable policies receive it
as `run(ctx, input)`. A policy called for a read-only decision receives an
empty context, so design those decisions as pure table-in/table-out rules.
Module loading registers rules; it has no active actor or map context. Put
`ctx` calls inside invoked functions, not at the top level of a Lua file.
The character-menu catalog and some isolated tests run without game services;
calling an unavailable clock, RNG, event, actor, or grid method there raises
an error. Pass ordinary input tables to pure decisions, and exercise
stateful rules in a runtime with those services.

| Lua entry point | Who calls it | Arguments |
| --- | --- | --- |
| `register.system({ update = fn, ... })` | ECS scheduler | `fn(ctx, entity, delta)` |
| `register.policy({ run = fn, ... })` | A named Go host policy call | `fn(ctx, input)`; return a table |
| A method returned by a `policy/` module | Its Lua caller | Whatever that caller passes, often `ctx` first |
| A content or schema file | Startup loader | No `ctx`; register and return a definition |
| A `.des` vault hook | Vault script bridge | A vault-specific `api`, described below |

`ctx` is a normal function argument, never a magic global. A discovered
`policy/` file is *loaded*, but merely returning `effect.apply` does not make
the game call it. Connect the method to its domain registry, as the bundled
potion, spell, mutation, and monster effect files do. A `register.policy`
callback likewise needs a host path that calls that registered policy ID.
Look at the nearest existing file and its caller before choosing an entry
point. The same rule explains why a content definition can load correctly
while a new mechanic still needs a resolver.

Think of `ctx` as access to one running game's state, supplied only while a
rule is being invoked. A content file describes what a thing *is* at startup;
an effect or system uses `ctx` to decide what happens *now*. The scheduler
passes the matching entity to a system as `entity`; `ctx:actor()` is the
creature whose action triggered this update, and `ctx:player()` is the player
even during a monster action. Those handles can be different. Use the
callback's `entity` for the component the system is visiting, and choose
`actor()` or `player()` only when the rule specifically concerns that actor.

The Go engine creates the context and calls Lua. A mod cannot construct a
second game context or keep one for later. Pass the received `ctx` to helper
functions during that same call. A helper that reads only its arguments can
stay pure and need no context. This keeps dependencies visible: a function
with `ctx` may inspect or change the current game; a function without it
cannot silently reach into game state.

`ctx` supplies **engine capabilities**, not every game rule. It can read an
ECS component, draw from a saved random stream, ask the grid about a cell, or
emit a message. It does not have methods such as `ctx:damage_monster()` or
`ctx:cast_spell()`. Those rules live in focused Lua modules under `policy/`
and `systems/`. Import the relevant policy and pass along the same `ctx`:

```lua
local combat = require("policy.combat.player_health")

-- The policy owns the healing restriction; this caller only chooses when
-- to ask it. Both functions observe the same current game invocation.
local function can_restore_health(ctx, player)
    return combat.can_heal(ctx, player)
end
```

This separation is important when extending the game. Add a generic host
capability to Go only when Lua cannot express the operation with the current
ECS, grid, and event services. Put the actual monster, spell, item, or game
policy in Lua, even if several content files call it.

### Follow one rule from entry to state change

Suppose a mod has registered the `my_mod.turn_counter` component from the
[Components](#components) section. Its system's `query` asks the scheduler
for entities carrying that component. The scheduler calls `update` with a
live context and one matching entity. The callback reads a detached snapshot,
changes it, and writes the whole component back:

```lua
local component = require("my_mod.constants.component")

local system = {}

-- This counter belongs to the active actor, so the scheduler visits one
-- matching entity per action rather than every entity in the world.
function system.update(ctx, entity, delta)
    local counter = ctx:get(entity, component.TURN_COUNTER)

    counter.count = counter.count + 1
    ctx:set(entity, component.TURN_COUNTER, counter)
end

register.system({
    id = "my_mod.count_turns",
    scope = "active",
    query = { component.TURN_COUNTER },
    update = system.update,
})

return system
```

The `register.system` call runs while the file loads; it only records the
callback. The `ctx:get` and `ctx:set` calls run later, during an action.
`delta` is available for elapsed-time rules, but this counter counts actions
so it does not use it. For a timer, subtract `delta` from a component field
instead of subtracting one. If the rule should visit *every* matching entity
on each action, use `scope = "all"` and a suitable `query`.

This is the same lifecycle for a focused effect: its file registers or
returns a function at startup, then its caller passes the live `ctx` and
explicit actor or target when the effect occurs. Follow that domain's
existing effect registry to learn its `plan`, `resolve`, or `apply` arguments.
Those method names are domain contracts, not methods on `ctx`.

For example, the test overlay's `SPELL_MOSS_HELPER` resolves to
`policy/combat/monster_spells/moss_helper.lua`. The monster spell registry
loads that path when a spellbook selects the ID. The file returns a local
effect object; its methods receive `ctx` when the cast actually happens:

```lua
local channels = require("constants.message_channels")
local monsters = require("ids.monsters")
local self_target = require("policy.combat.monster_support.self_target")
local spells = require("ids.spells")
local summons = require("policy.magic.effects.summons.common")

local effect = {}

-- Target the caster before the action is spent. The returned plan crosses
-- the ordinary monster-spell intent boundary and reaches resolution.
function effect.plan(ctx, caster, foe, slot)
    return self_target.plan(caster)
end

-- Confirm the saved target before creating the actor. The shared owner
-- attaches its components and puts it on the grid, so this effect only
-- chooses what the spell summons and how to announce a successful cast.
function effect.resolve(ctx, caster, foe, slot, plan)
    self_target.require_caster(plan, caster)

    local creature = summons.spawn(ctx, caster,
        spells.SPELL_MOSS_HELPER, monsters.MONS_RAT, 2, nil)

    if creature then
        ctx:emit(channels.SPELL, "A modded rat answers the call.")
    end
end

return effect
```

The example creates a real summon because the shared creator has the live
`ctx`. It also needs its content definition and a spellbook slot; see the
[three-file overlay](#add-a-monster-spell-or-summon). For a player spell,
potion, mutation, or trap, use that domain's registry and method names instead
of copying the monster-spell interface.

A typical stateful rule reads a component, calculates a result using its
explicit inputs and a named RNG stream if needed, writes the full component
back, then emits a message or transient signal. `ctx:get` returns a copy,
so editing its fields without `ctx:set` silently loses the change. The
engine applies staged additions, removals, movement, and terrain changes at
the action barrier; later callbacks in that action can see their staged
view. Persistent state belongs on components, while `ctx:signal` is only
for communication during the current action. This is why a module-level
Lua variable cannot stand in for a cooldown or a saved status.

Use a colon for every method below: `ctx:get(actor, id)` passes `ctx` as the
first argument. Most methods raise a Lua error for an unknown component,
invalid handle, or invalid coordinates. A missing *valid* component or cell
usually returns `nil` as described below. Errors include the calling Lua
path or system ID, which helps find a bad mod file.

| Invocation | What is safe to use |
| --- | --- |
| Module load and content registration | `register`, `mod`, `require`; there is no active `ctx`. |
| Live system or mutable policy | The context methods below, when that game has the corresponding service. |
| Read-only host policy | The `ctx` argument is an empty table. Use `input` and return a decision. |
| Character menu or isolated rule test | Only supplied services. Other services raise errors. |
| `.des` vault hook | The vault-specific `api`, not the game context. |

Do not probe a missing service by calling it and hoping for `nil`: methods
such as `ctx:random` and `ctx:cell` error when their host service is absent.
Write a pure function for menu decisions, or test a stateful rule with a
fixture that provides the game services it actually needs. The full set of
methods is installed in `internal/script/context.go`; the table below is a
contract for their Lua arguments and results, not permission to use every
method at every entry point.

### Entities and components

An entity is an ECS handle (Lua userdata), not a monster definition or a
numeric ID. The component ID identifies one kind of mutable state on that
entity. Import bundled IDs from `constants.component`; put new IDs in your
own constants module and import them in every file that uses them. The
schemas under `schemas/` show Lua component fields. The engine's `core.*`
components are bound in `internal/game/script_services.go` and their typed
fields are declared in `internal/ecs/components.go`. Exported Go field names
appear in Lua as `snake_case` (for example, `Position.LevelID` becomes
`position.level_id`). Read a nearby production policy or system for the
invariants before writing one. A content definition under `content/` is a
shared catalog fact, not an entity's mutable state.

| Call | Result and use |
| --- | --- |
| `ctx:player()` | Player handle, or `nil` when there is no player. |
| `ctx:actor()` | Handle of the actor taking the current action, or `nil`. This can be a monster. |
| `ctx:create()` | A new live entity handle. Add its components before using it as an actor. |
| `ctx:destroy(entity)` | Queue the entity's destruction. Subsequent context reads treat it as gone. |
| `ctx:id(entity)` | Numeric ID for display or external lookup; do not use it as a component's `entity` value. |
| `ctx:entity(id)` | Live handle for a positive exact numeric ID, or `nil` if it no longer exists. |
| `ctx:has(entity, component_id)` | Whether the registered Lua or host component is present. |
| `ctx:get(entity, component_id)` | Detached field table, or `nil`. Editing it alone changes nothing. |
| `ctx:set(entity, component_id, values)` | Replace an existing component; Lua schema defaults fill omitted fields. |
| `ctx:add(entity, component_id, values)` | Attach an absent component; Lua schema defaults fill omitted fields. |
| `ctx:remove(entity, component_id)` | Remove an existing component. |
| `ctx:query({ id1, id2 })` | Sorted live handles with all listed components. `{}` queries all entities. |

`set` is replacement, not a partial field update. To change one field, get
the component, edit the returned table, and set the *whole* table back:

```lua
local components = require("constants.component")

-- Keep the unchanged health fields rather than resetting them to defaults.
local health = ctx:get(player, components.HEALTH)

if health then
    health.current = math.min(health.max, health.current + 3)
    ctx:set(player, components.HEALTH, health)
end
```

`add`, `remove`, `destroy`, actor movement, and terrain changes are staged at
the action barrier. Later context reads and queries in that action see the
staged state. If a callback fails, its pending structural changes and new
entities are discarded. Do not retain an entity handle in a Lua module global:
module globals are neither per-game persistent state nor saved components.
Store lasting references in an `entity` field on a registered component.

Use `ctx:has` when presence alone matters, and `ctx:get` when fields matter.
An absent registered component returns `nil` from `get`; an unknown component
ID is an error. `ctx:set` requires a present component and `ctx:add` requires
an absent one. This catches accidental duplicate state and misspelled IDs.
`ctx:query` matches *all* listed components, even when some were added earlier
in the same action. It returns handles in stable entity order, so do not use
file discovery order as a gameplay tiebreaker. Avoid scanning every entity
with `ctx:query({})` when a component query can narrow the work.

If a component contains an `entity` field, assign the handle itself, not
`ctx:id(handle)`. `ctx:id` is useful for diagnostics; `ctx:entity(id)` looks up
a live handle when an external numeric ID must be resolved. Check the lookup
result because destroyed entities return `nil`.

### Time, random draws, messages, and signals

| Call | Result and use |
| --- | --- |
| `ctx:aut()` | Absolute game clock in aut. Use the system's `delta` for the elapsed cost of the current action. |
| `ctx:random(stream, bound)` | Integer in `[0, bound)` from a named, saved random stream; `bound` must be positive. |
| `ctx:random_u64(stream)` | High and low 32-bit halves of one draw, for rejection sampling. |
| `ctx:emit(kind, text)` | Append a player-visible turn event. Import a message kind where one exists. |
| `ctx:signal(name, value)` | Publish a transient fact to later rules in this action. `value` cannot be `nil`. |
| `ctx:signals(name)` | Array of published values for this name, or `{}` when none. |

Signals reset before the next action; they do not survive a save. Use them
when one system needs to tell a later system about an event without adding
lasting state. Tables passed to or returned from signals are copied so one
consumer cannot mutate another consumer's value. Use an ECS component when
the fact must survive turns or saves. `math.random` is unavailable; named
streams keep replays and save/restore deterministic. Choose a stable stream
name for a mechanic and import an existing name from `constants.rng_streams`
when appropriate. A file's discovery order must never decide random draws.

For example, a combat resolver can publish `ctx:signal(signal_ids.HIT, target)`
and a later system can read `ctx:signals(signal_ids.HIT)`. Define `HIT` in a
shared ID module owned by your mod and import it in both files. Give the
consumer an explicit `after` dependency on the producer's system ID when
their order matters. A signal
does not schedule a callback on its own; it is a short-lived value for rules
already running in the action. Use `ctx:emit` for text shown to the player,
not as a substitute for a component or signal that another rule must read.

`ctx:random(stream, bound)` draws zero through `bound - 1`. Add one only when
the game rule really wants one through `bound`. To choose a Lua array index,
use `ctx:random(stream, #list) + 1` after checking that the list is nonempty.
Name a stream for the mechanic rather than
for the Lua file, because renaming a file must not alter a saved game's
random sequence. `ctx:random_u64` returns two values, not one Lua integer;
use it only when a rule needs the full draw and handles both halves.

Do not draw randomness while a module loads. Startup may load files in a
different order after an overlay is added, and there is no active game RNG
then. Draw inside the invoked method and use stable IDs or an explicitly
ordered local pool for ties. `pairs()` traversal order is not a gameplay
order; sort keys before using them to choose a random index.

### Levels, terrain, visibility, and actor placement

These methods address a level by integer `level_id` and a cell by integer
`x, y`. A level is terrain and spatial indexing; actors and items remain ECS
entities. Import terrain IDs from `constants.terrain`. Reads of a missing
level or cell return `nil` where noted; writes reject missing or invalid
destinations.

| Call | Result and use |
| --- | --- |
| `ctx:level_size(level_id)` | `width, height`, or `nil, nil` for a missing level. |
| `ctx:level_branch(level_id)` | Branch ID, or `nil` for a missing level. |
| `ctx:cell(level_id, x, y)` | Terrain ID at the cell, or `nil` when missing. Includes staged terrain changes. |
| `ctx:walkable(level_id, x, y)` | Whether an actor can walk on the current or staged terrain. |
| `ctx:actor_at(level_id, x, y)` | Occupying actor handle, or `nil`; includes staged moves. |
| `ctx:stair_at(level_id, x, y)` | Link `{ to_level_id, to_x, to_y, unavailable }`, or `nil`. |
| `ctx:visible(level_id, from_x, from_y, radius, target_x, target_y)` | Whether one target cell is visible. |
| `ctx:visible_cells(level_id, from_x, from_y, radius)` | Array of visible `{ x, y }` cells. |
| `ctx:route_step(level_id, from_x, from_y, to_x, to_y, goal)` | `dx, dy, found`; no route gives `nil, nil, false`. |
| `ctx:projectile_clear(level_id, from_x, from_y, to_x, to_y)` | Whether a projectile path is clear. |
| `ctx:set_cell(level_id, x, y, terrain_id)` | Stage a terrain change. It cannot block an actor or erase a stair link. |
| `ctx:map_cell(level_id, x, y)` | Mark an unseen cell in map memory; `true` if newly mapped, `false` if known. |
| `ctx:place_actor(entity, level_id, x, y)` | Put an unpositioned actor on a valid, unoccupied cell. |
| `ctx:move_actor(entity, level_id, x, y)` | Move a positioned actor to a valid, unoccupied cell. |
| `ctx:remove_actor(entity, level_id)` | Remove a positioned actor from that level's spatial index. |
| `ctx:move_actors(moves)` | Atomically stage simultaneous moves; see the shape below. |

`move_actors` accepts an array of records shaped like
`{ actor = handle, level_id = id, x = x, y = y }`. Destinations must be
walkable and distinct; an occupied destination is valid only when that
occupant is also moving in the batch. Use it for swaps or rotations. Use
`place_actor`, `move_actor`, or `remove_actor` to maintain both the position
component and the level's spatial index. Directly setting `core.position`
does not perform a grid move.

Coordinates are zero-based: the top-left cell is `(0, 0)`, and a level of
size `width, height` contains `x` from `0` through `width - 1` and `y` from
`0` through `height - 1`. Read an actor's `POSITION` component to find its
level and coordinates. Check occupancy and walkability before movement, then
use the grid operation to keep the spatial index consistent. An item entity
does not occupy `actor_at`; use its item and position components through ECS.

```lua
local components = require("constants.component")

-- The grid operation checks occupancy and keeps the spatial index in sync.
local position = ctx:get(actor, components.POSITION)
local next_x = position.x + 1

if ctx:walkable(position.level_id, next_x, position.y)
    and not ctx:actor_at(position.level_id, next_x, position.y) then
    ctx:move_actor(actor, position.level_id, next_x, position.y)
end
```

`route_step` can take the target actor as its last argument so pathfinding
can treat that actor as the goal. Visibility and projectile checks answer
geometry questions; they do not apply damage, decide hostility, or spend
action time. Put those game rules in a policy or system.

### Lua registration and VFS helpers

The global `register` table is for startup registration and catalog lookup.
The global `mod` table exposes the effective layered file tree. These are
available while modules load, unlike the game `ctx`. Definitions and systems
must register before startup freezes the registry; duplicate IDs fail with
source paths. The built-in `init.lua` discovers the usual content trees, so
ordinary new files require no central index edit.

| Call | Purpose |
| --- | --- |
| `register.component(schema)` | Register a versioned ECS schema; see Components above. |
| `register.system(spec)` | Register `{ id, scope, query, before, after, update }`; see Systems above. |
| `register.definition(category, definition)` | Add one content definition with a unique `id`. |
| `register.get(category, id)` | Return a copy of a registered definition; an unknown category or ID is an error. |
| `register.ids(category)` | Return sorted IDs; file discovery order is irrelevant. |
| `register.reference(category, id)` | Record a definition reference for startup validation. |
| `register.validate_references()` | Validate recorded references; the base bootstrap calls this. |
| `register.origin(category, id)` | Return the effective relative source path; an unknown ID is an error. |
| `register.policy({ id = id, run = fn })` | Register a named policy called as `run(ctx, input)` by the host. |
| `register.choice_policy(fn)` | Register the character choice rule described below. |
| `mod.paths(root, suffix)` | Return sorted effective relative paths under a tree; suffix must be `.lua` or `.des`. |
| `mod.read(path)` | Read the effective file bytes at a relative path. |
| `mod.bundled(path)` | Read the original embedded bytes for that path, or `nil`. |
| `mod.load_tree(root)` | Load discoverable modules under a tree; normally called by `init.lua`. |
| `mod.null` | Explicit null sentinel for definition fields whose presence matters. |

`require("policy.moss.growth")` resolves
`policy/moss/growth.lua` in the effective VFS and caches that module. It
cannot read a path outside the mod tree. Avoid calling `mod.load_tree` in
content files: the base bootstrap owns discovery and loading order. A new
helper under `lib/` can be loaded with `require` from any discovered file.
No `io`, `os`, `dofile`, or `loadfile` access is available to Lua rules.

`mod.null` is a distinct, truthy sentinel; Lua's `value or {}` does not turn
it into an empty table. Check `value == mod.null` (or its type) explicitly
before treating an optional content field as a table. Use it only where a
definition schema permits explicit null. A missing field and an explicit
null can mean different things, especially in source-backed content.

### When a context call fails

- **`ctx` is `nil`, or a method is missing:** The code may have run at
  module load, or a read-only policy received an empty context. Move the
  call into a live callback; pass state through `input` for read-only rules.
- **`unknown Lua component`:** Check the imported ID and the matching
  registration under `schemas/`.
- **`use add` or `use set`:** The entity already has the component, or does
  not have it yet. Check `ctx:has` and choose the matching operation.
- **A field edit disappears:** `ctx:get` returned a detached table. Call
  `ctx:set` with the whole edited table.
- **An actor and the grid disagree:** A position component may have been
  edited directly. Use `place_actor`, `move_actor`, or `remove_actor`.
- **A result changes after save/restore:** Check for state kept in a Lua
  module variable or randomness outside a saved named stream. Store lasting
  state in an ECS component.
- **A context service is unavailable:** This entry point has no game clock,
  grid, RNG, or event service. Use an input-only policy or a live fixture.

A Lua callback error discards its pending context writes and reports the
originating Lua path or system ID. Fix the first reported error before
interpreting missing state later in the action. When a mod changes files,
start a new game session to load the new effective tree; the current session
does not hot reload Lua.

## Work through a new mod feature

1. Start with the nearest bundled example and identify its *entry point*.
   Content is registered with `register.definition`; a domain effect may
   also need `registry.add`, `potions.register`, or its domain's equivalent.
   Read the registry's required method names and return values before making
   a new file. A new file is discovered automatically, but discovery alone
   does not call a new policy method.
2. Run the wizard for the content kind. Fill the generated required fields
   and replace its sample values with your own. Add a separate effect file
   only when existing rules cannot already express the behavior. For lasting
   state, add a schema; for recurring updates, add a system that queries it.
3. Put each new ID in one module under your own namespace, then import that
   module at every use site. Import bundled catalog, component, terrain,
   message, and RNG constants from the matching `constants/` or `ids/`
   module. An extra content definition with an ID appears through the
   catalog-backed `ids.*` module once content loading has finished.
4. Launch with `go run ./cmd/dcrawl --mod-dir=/path/to/my-mod`. Startup
   checks duplicate IDs, schema types, cross-references, missing effect
   handlers, and system dependencies. Read the reported effective path and
   field name; fix that one file, then start a new session to reload it.
5. Exercise the feature in game and test the Lua rule through the production
   runtime. Include a case where the rule declines to act and a case where
   it changes state. Test save/restore if it creates or changes a component.
   Inspect the displayed ruleset hash when comparing runs with overlays.

For example, a new potion with a new effect needs
`content/items/<name>.lua` and `policy/potions/effects/<name>.lua`. The item
file declares its catalog facts. The effect file builds a local table with
commented `can_quaff(ctx, player)` and `apply(ctx, player)` methods, registers
that table with `policy.potions`, and returns it. The existing potion command
then invokes those methods and passes the game context. The bundled Curing
effect shows the contract and how it edits `core.health` and poison state.
If the potion also causes a timed condition, give that condition a component
and a system that removes or updates it after the right number of aut. This
keeps behavior in focused files and makes its state visible in saves.

## Content files

Put one definition in one file below `content/<category>/`. The recognized
base categories are `species`, `jobs`, `monsters`, `spells`, `items`,
`mutations`, `branches`, and `monster_spellbooks`, plus `artefacts`, `clouds`,
`monster_beams`, `shops`, and `traps`. The registration API accepts additional
category names for mod-defined catalogs. For example,
`content/monsters/my_moss.lua` can contain:

```lua
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local habitats = require("constants.monster_habitats")
local spellbooks = require("ids.monster_spellbooks")
local my_ids = require("my_mod.ids")

-- A small land monster can reuse the existing melee and population rules.
local definition = {
    id = my_ids.MOSS,
    name = "moss creature",
    status = "defined",
    habitat_id = habitats.LAND,
    spellbook_id = spellbooks.MST_NO_SPELLS,
    average_hp_10x = 25,
    speed = 10,
    hd = 1,
    attacks = {
        {
            type_id = my_ids.BITE,
            flavour_id = my_ids.PLAIN,
            damage = 3,
        },
    },
    energy = {
        move = 10,
        swim = 10,
        attack = 10,
        missile = 10,
        spell = 10,
        special = 10,
        item = 10,
    },
    population = {
        {
            scenario_id = my_ids.DUNGEON_SCENARIO,
            min_depth = 1,
            max_depth = 3,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
```

Here `my_mod/ids.lua` is a small module owned by the mod that returns
`MOSS = "MY_MOD_MOSS"`, `BITE = "AT_BITE"`, `PLAIN = "AF_PLAIN"`, and
`DUNGEON_SCENARIO = "generated-dungeon-basic-v1"`. Import it in every mod
file that uses those identifiers. Existing bundled IDs come from their
`constants.*` or `ids.*` modules instead.

The file is loaded automatically. Its population entry puts the monster into
the generated Dungeon roster without editing a central list. The example
uses the current basic monster behavior and combat rules. Invalid spawn data
fails at startup with the content path and field name.
Bundled population rows live in their monster files too, with a
`source_order` for the original DCSS population draw. It orders those
*nested population rows* explicitly; it does not order Lua file loading,
catalog definitions, systems, or tests. New mod rows need only a
`scenario_id`, depth range, rarity, and curve. They follow the source rows
in stable catalog ID order, regardless of their filenames or load order.

A rule imports `constants.catalog`,
`ids.monsters`, and `policy.catalog` where needed, then reads it with
`catalog.get(categories.MONSTERS, monsters.MY_MOD_MOSS)`. The ID module
reflects added files; no generated index needs editing. A spell,
item, branch, or monster spellbook uses the same form in its directory.
Unique artefacts live in `content/artefacts/` with a stable unique ID and
required base item fields. A new item class needs a named ID in
`ids.object_classes` and the corresponding focused behavior.

Definitions supply facts. A spell with a new effect needs a Lua effect or
system file. Existing engine paths still
support only the domain mechanics already ported, so a registered definition
alone does not make every new behavior playable. Keep each behavior in its
own discoverable `policy/` or `systems/` file.

For a player spell, set `player_scope = scopes.BOOK` or
`player_scope = scopes.INVOKED` in its definition and import
`constants.spell_scopes` as `scopes` in that file. Put its resolver in a
separate file under `policy/magic/effects/` and call
`registry.add(spells.MY_SPELL, { resolve = effect.resolve })`, importing
`ids.spells` and `policy.magic.effects.registry` there. Both files load
automatically. Existing DCSS spell scope is supplied by the committed
source catalog when the definition has no `player_scope` field.

### Add a monster spell or summon

A monster spellbook slot names a spell ID and its frequency and flags. The
spell's content file describes cost, range, and display facts. Neither file
contains the live effect. For `SPELL_MOSS_HELPER`, add its effect at
`policy/combat/monster_spells/moss_helper.lua`; the monster spell registry
finds that path from the ID without a central switch. The effect returns a
local table with commented `plan(ctx, caster, foe, slot)` and
`resolve(ctx, caster, foe, slot, plan)` methods, as shown in the
[`ctx` walkthrough](#follow-one-rule-from-entry-to-state-change).

`plan` runs before the cast is committed. Return `nil` when the spell cannot
currently be used. Otherwise return a typed entity or cell target that can
cross the intent boundary. A foe-centered summon should save the selected
cell in the plan; re-reading a moving foe inside `resolve` would redirect an
already chosen cast. `resolve` runs with the live game context after the
action is committed. Put count, species, and duration draws there using
`ctx:random` or a focused `policy/combat/monster_summons/` helper. Import
spell, monster, component, attitude, and stream IDs at the use site.

The shared creator is
`policy.magic.effects.summons.common.spawn(ctx, owner, spell_id, kind_id,
degree, cap, options)`. It creates and places the Akara actor, saves its
owner, source, attitude, and expiry, then returns the new handle or `nil`
when no cell is available. `owner` is the caster; `cap = nil` means no
per-spell eviction. The optional table may supply an `anchor` position,
an `exact` `{ x, y }` destination, or source-specific `hd`, `heads`,
`hp`, `attitude`, and `expires_aut`. Give any additional lasting rule state
its own schema and attach it to the returned handle. A mod can reuse this
creator without replacing its file or copying actor setup code.

If a new monster uses the spell, its `content/monsters/` definition names a
spellbook, and a `content/monster_spellbooks/` file supplies the slot. The
game accepts that monster into a playable roster only when *every* spell
in its book has a live resolver. Test both a successful cast and a blocked
placement; then save, restore, and take another action to catch lost owner
state or changed RNG order. A sparse `--mod-dir` needs only the new or
overridden files, never a copy of the whole base tree.
The repository's `internal/game/testdata/monster-added-summon/` overlay is
a runnable three-file example: a new spell definition, one book override,
and one focused effect. Its Go integration test launches the normal game
with that overlay and observes the summoned ECS actor.

Put a player mutation in `content/mutations/<name>.lua`. The content tree
registers it automatically, and `ids.mutations` exposes the new ID to other
Lua files. A behavioral mutation also needs a focused file under
`policy/mutations/effects/`; an ordinary scalar mutation can use the shared
effect policy. Make a new definition selectable only after its full
consequence path is implemented and tested. Startup validates that each
active definition has registered behavior.

For a potion, add an item definition under `content/items/` with class
`OBJ_POTIONS` and a focused effect under `policy/potions/effects/`. The
effect imports its ID from `ids.items`, builds a local object with named
`can_quaff(ctx, player, forced)` and `apply(ctx, player)` methods, calls
`potions.register(id, effect)`, and returns that object. The command and
item system call the registered methods. `can_quaff` may return a refusal
string or a second confirmation string; accepting the prompt replays the
command with `forced = true`. Startup refuses an active potion
definition without an effect. A sparse overlay can replace one base effect
file at the same relative path or add a new potion and its effect files.
Several effect files may register distinct capabilities for the same
mutation. A duplicate mutation/capability pair fails at startup. This lets
one mod split a mutation's combat, spell, and turn effects into readable
files without editing a central registry.
Damage reactions use `policy.combat.player_damage_reactions`. A file under
`policy/mutations/effects/damage/` can register a callback with `add_before`
for a pre-HP-loss effect or `add` for an effect after surviving HP damage.
Each phase has its own registration names, so one mutation may participate
in both. The mod loader discovers the effect file automatically.
Kill rewards use `policy.combat.player_kill_effects`. A focused file under
`policy/mutations/effects/kill/` registers one callback by mutation ID.
It runs for a credited, XP-eligible monster death and receives the player,
monster definition, and effective mutation level. Keep any lasting buff in
a Lua ECS component so save/restore preserves it.

The effective tree is sorted by path. A file at the same relative path as a
bundled file replaces it before Lua starts. A new path adds a definition.
Registering the same category and ID from two effective paths fails at
startup and names both paths. Catalogs traverse definitions in stable ID
order, regardless of file name or load order. A rule that needs a different
order declares it within that rule's own data, such as population rows.

## Character definitions and choices

The embedded `content/species/` and `content/jobs/` trees contain one Lua file
per pinned species and job. Each calls `register.definition` with a local
table. Replace a file at
the same path in your mod directory to edit that definition. New files in
either tree load in sorted path order. Duplicate IDs, invalid fields, and
missing required definitions stop startup with an error. The species and job
tables in Lua are the effective definitions used by the game and the
character creation screen. Normal launch reads these committed Lua files;
the committed Lua definitions are edited directly for new development.
Use `mod.null` when a present field intentionally has a null value; omitting
a required field is an error. Newly selectable definitions appear on a
separate modded menu page. They need implemented start mechanics before a
policy can make them playable.

Each selectable source species owns its `description`, `difficulty`, and
`difficulty_priority` in its species file. Each source job owns its
`description`, `menu_group`, and `menu_order` in its job file. Group names
come from `constants.menu_groups`; the menu assembles them from registered
definitions. A new species or job with no group fields appears on the Modded
choices page and uses its name when no description is supplied. To place a
definition in a source group, import the group constant, provide a positive
order unique within that group, and supply a description. A same-path
override can change its menu text or position through that one file. Pinned
groups have fixed screen space: extra entries flow to the Modded page. Removing
both group fields from an override moves that choice to the Modded page too.

Each job file also owns `starting_grants`: a list of item grants with
`kind_id` and positive `quantity`, plus optional `plus`, `charges`, and
`ego`. The effective file is the only fixed-grant source at runtime.
Wanderer uses `mod.null` because its grants are generated during character
creation. To change a job's fixed equipment, replace its job file; a shared
starting-gear table is no longer involved. Special job rules such as
Gladiator ammunition live in discoverable
`policy/character/starting_gear/jobs/` files and can be replaced at the
same path. New jobs with ordinary fixed grants need no special rule file.

The `policy/character_choice.lua` file calls `register.choice_policy` once.
Its function receives copied species and job tables and a boolean indicating
whether the menu is species-first. It returns a restriction string
(`banned`, `restricted`, or `recommended`) and whether the start is currently
playable. The bundled policy preserves the source bans and recommendations.
Every legal selectable source species/job pair starts in the current Dungeon
slice. Many later job abilities remain unavailable and explain that limit in
the client. The game constructor checks the same Lua choice policy before
creating a player. A policy can narrow supported starts; a new job also needs
valid starting rules for the game behavior it introduces.

The committed Lua files are the editable source of truth. The initial C++
import and Lua regeneration programs have been retired. Make content and
behavior changes in their owning Lua files, add `_test.lua` coverage for
rules, and run the Go/Lua tests before sharing the mod.

## Monster weapon gear

Each imported weapon spec lives under `weapon_gear.primary` or
`weapon_gear.secondary` in its owning `content/monsters/` file. A same-path
override changes that monster's gear data and the effective ruleset hash.
Weapon choices import `ids.items`; brand choices import
`constants.weapon_brands`. The source's no-weapon and no-forced-brand values
come from `constants.monster_gear_sentinels`.

The active Dungeon slice has discoverable Goblin and Kobold gear handlers
under `policy/population/gear/handlers/`. Add a handler file that calls
`registry.register(monster_id, handler)` for a new monster with special gear
rules, or replace a bundled handler at the same relative path. The handler
receives the game context and depth and returns an ordinary loadout. The
other imported gear specs are available to Lua but their monsters are not
yet part of the playable population.

## Vault maps and Lua hooks

Vault geometry remains in original `.des` syntax under `vaults/arrival/` or
`vaults/shop/`. A map has `NAME`, tags, optional orientation and directives,
then `MAP` and `ENDMAP`. The `.des` file is the authoritative layout. A mod
may replace an existing `.des` by its exact relative path or add a new one.
Keep terrain, item, monster, marker, and placement instructions in that map
file so a reader can see the whole layout together.

When a source vault needs a calculated directive, add
`policy/generation/vaults/<family>/<name>.lua` with a local `handler` object
and a named method. A `.des` line such as `: vault.run("configure")` calls
`handler.configure(api)`. The API can emit directives; see a bundled handler
and `constants.vault_directives` for the supported operations. The Lua module
is for the hook's decision, not a second copy of the map. The wizard's
`--kind=vault --with-hook` creates the matching pair.

## Test a mod

Use a file ending in `_test.lua` under `tests/`. Import production modules
and schemas instead of recreating their definitions in the test. The bundled
examples live under `internal/script/testdata/lua/tests/`; the Go test
harness in `internal/script/` loads them through the same VFS and runtime as
the game. Each test module returns a table with a named `run(ctx)` method;
the harness provides a fresh ECS world and then applies pending writes.
Import `tests.harness` for assertions. A small test can look like this:

```lua
local components = require("my_mod.constants.component")
local harness = require("tests.harness")

local test = {}

-- Verify the production schema defaults and context writes together.
function test.run(ctx)
    local entity = ctx:create()

    ctx:add(entity, components.TURN_COUNTER, {})

    local counter = ctx:get(entity, components.TURN_COUNTER)
    harness.equal(counter.count, 0, "new counter starts at zero")
end

return test
```

The repository's `TestLuaRules` runner discovers these files in its own
`internal/script/testdata/lua/tests/` fixture tree. It does not currently
discover arbitrary external mod directories. For an external mod, first
launch `go run ./cmd/dcrawl --mod-dir=/path/to/my-mod` to catch startup
registration and validation errors; when contributing a rule to this repo,
put its Lua test in that fixture tree and run
`go test ./internal/script -run TestLuaRules`. Run
`go test ./internal/script ./internal/game` after changing engine behavior,
and `go test ./...` at a broader category boundary. Top-level content
definitions need no `source_order`. Order-sensitive nested records, such as
source population rows, document their order where that behavior is used.

## Saves and identity

The startup screen shows a short effective ruleset hash and whether its Lua
bytes match the bundled ruleset. Saves contain the full hash, per-file hashes,
Lua dialect, schema versions, and dynamic component state. A changed ruleset
is refused by default, with changed paths named in the error. To explicitly
try a save with changed Lua, run with `--allow-ruleset-mismatch`. This does not
migrate changed schemas: their saved records must still validate under the
current definitions. A new schema with no saved instances can be added under
this explicit opt-in. The save also lists every overlay-changed path. Lua
files in an overlay must be regular `.lua` or `.des` files; symlinks and
special files are rejected.

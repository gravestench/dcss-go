# Lua modding guide

The Lua tree in `internal/modfs/builtin/` is editable production source. Lua
paths resolve through the embedded base plus any `--mod-dir` overlays;
discoverable definitions and rules load at startup, while helper modules load
when another module calls `require`. No C++ importer or generated index is
part of the build. Add a new file to add a definition; replace the same
relative path to change a bundled file.

## Find what you need

| If you want to... | Read... |
| --- | --- |
| Understand when Lua runs and what `ctx` means | [The five-minute mental model](#the-five-minute-mental-model) |
| Add a monster, item, spell, or other definition | [Content files](#content-files) and [the feature workflow](#work-through-a-new-mod-feature) |
| Keep new state on an actor | [Components](#components) and [entities and components](#entities-and-components) |
| Make a rule run on actions | [Systems](#systems) and [the `ctx` entry-point table](#the-game-context-ctx) |
| Implement a one-shot effect or decision | [Choose an owner](#choose-an-owner-for-a-new-feature) and [the `ctx` walkthrough](#follow-one-rule-from-entry-to-state-change) |
| Read or change the game from Lua | [The complete `ctx` reference](#the-game-context-ctx) |
| Add a map or generation hook | [Vault maps and Lua hooks](#vault-maps-and-lua-hooks) |
| Add a cloud, trap, or shop | [Clouds, traps, and shops](#clouds-traps-and-shops) |
| Check a mod or understand a failed load | [Test a mod](#test-a-mod) and [context failures](#when-a-context-call-fails) |
| Understand overlays and save compatibility | [Scaffolding](#scaffolding) and [saves and identity](#saves-and-identity) |
| Try a complete live rule with `ctx` | [A first live mod](#a-first-live-mod) |
| Add saved behavior | [A new `ctx` example](#a-complete-new-ctx-example) |
| Understand a callback's arguments and available game services | [Who supplies `ctx`](#who-supplies-ctx) and [the context API](#the-game-context-ctx) |
| Trace a callback from registration to state change | [Trace a callback](#trace-a-callback-before-using-ctx) |
| Find the accepted fields for a content type | [Definition contracts](#definition-contracts) |

The [root README](../README.md) has the shortest launch and wizard examples.
This guide explains the contracts those examples depend on. If a mechanic
already exists, start with a nearby bundled file and follow its registration
and caller. The examples here show how to do that; they are not a promise that
every DCSS mechanic has already been ported.

If this is your first mod, read [what `ctx` is](#ctx-in-one-minute), then
[follow a rule from entry to state change](#follow-one-rule-from-entry-to-state-change).
Those two sections explain when Lua runs and where changing game state lives.

### A mod file's path to the game

The path and the caller determine whether a file *describes* content or
*runs* a rule. This is the first question to answer when a new file loads
successfully but seems to do nothing:

| File | What loading it does | What makes its behavior run |
| --- | --- | --- |
| `content/monsters/moss.lua` | Registers fixed facts for a monster kind. | Population or another rule creates a live monster using that definition. |
| `schemas/moss_spores.lua` | Registers a saved component shape. | A rule attaches that component to an entity with `ctx:add`. |
| `systems/moss_growth.lua` | Registers a query and `update` callback. | The scheduler calls it during an action for matching entities. |
| `policy/potions/effects/moss_tonic.lua` | Loads a module that registers an effect. | The potion command selects its item ID and invokes the registered methods. |
| `policy/combat/monster_spells/moss_breath.lua` | Makes a named effect module available. | A spellbook selects its spell ID; the monster spell registry requires that module. |
| `vaults/arrival/moss_room.des` | Registers authored geometry and directives. | Level generation selects the map and runs any named Lua hooks with a vault `api`. |

The system, effect, and vault examples have callbacks. Only while a callback
runs does it receive a live `ctx` or vault `api`. The engine creates
the game context; your mod neither constructs nor registers it. A definition
may need no new behavior file at all when existing rules already understand
its fields. When it needs a new effect, connect that effect through its
domain's registry and check the exact callback signature there.

## The five-minute mental model

A mod file has one of three jobs: describe a fact, store per-entity state, or
implement a rule. A `content/` file describes a monster, item, or spell at
startup. A `schemas/` file declares the shape of state that can change and
survive a save. A `policy/` or `systems/` file implements behavior when the
game invokes it. The Lua runtime discovers these files; a content definition
does not itself execute a spell or update a status.

The engine passes a live `ctx` argument to invoked rules. It is access to
the *current game*: ECS entities and components, the level grid, saved random
streams, time, messages, and short-lived signals. There is no useful `ctx`
while a file is loading. Do not store `ctx`, an entity handle, or changing
game state in a module-level variable. Put lasting state in a component and
read it with `ctx:get` each time the rule runs.

### A first live mod

This one-file overlay changes an existing scroll without copying the base
mod. Create `/path/to/my-mod/policy/scrolls/effects/torment.lua` with the
following contents, then launch with
`go run ./cmd/crawl --mod-dir=/path/to/my-mod`. The path replaces the
bundled Torment scroll effect; the scroll command remains its caller.

```lua
local area = require("policy.combat.torment_area")
local channels = require("constants.message_channels")
local items = require("ids.items")
local scrolls = require("policy.scrolls")

local effect = {}

-- Torment needs no extra choice prompt because it affects nearby actors.
function effect.prepare()
    return nil
end

-- The scroll command passes the current game and the reader here. The
-- shared area rule applies the HP effect; this file owns only its trigger.
-- Example: reading Torment emits the custom notice before the area effect.
function effect.apply(ctx, reader)
    ctx:emit(channels.READ, "The scroll calls out to the living.")
    area.apply(ctx, reader, channels.READ)
end

scrolls.register(items.SCR_TORMENT, effect)

return effect
```

At startup, the file loads and registers `effect`; no `ctx` exists yet.
When the player reads that scroll, the scroll command calls `apply` with the
live `ctx` and the reader's entity handle. `ctx:emit` adds the notice;
`area.apply` receives the same context and performs the actual rule through
the player and monster health owners. Changing the file on disk requires a
new game session. Use a new path under `policy/scrolls/effects/` and a new
item definition when adding a scroll rather than replacing this one.

This example also shows how to inspect an unfamiliar API: open the bundled
effect, follow its `scrolls.register` call to `policy/scrolls.lua`, then
follow the scroll command that invokes `prepare` and `apply`. The
`ctx` method list below tells you which engine operations are available;
the domain's caller tells you *when* they run and what the other arguments
mean. Both contracts matter for working content.

Three names that often appear together mean different things:

| Name | Meaning | Where it comes from |
| --- | --- | --- |
| `ctx` | Capabilities for the running game, such as ECS and grid access. | The engine passes it to an invoked callback; Lua callers pass it on explicitly. |
| `entity`, `player`, `caster`, or `foe` | A handle for one live actor or item. | The callback's caller or a `ctx` query supplies it. |
| `definition` | Fixed catalog facts shared by every instance of a kind. | A content file registers it; a policy reads it from the catalog. |

For example, a monster definition may specify its kind's hit dice. Two live
monsters of that kind have different HP components. A spell's `foe` is a
handle for one of those actors; `ctx:get(foe, components.HEALTH)` reads that
actor's current HP. The definition cannot answer that question.

### A complete new `ctx` example

The scroll example replaces an existing rule. This example adds a rule to a
sparse mod directory without replacing any bundled file. It records elapsed
player action time in a saved ECS component and displays a notice after each
50 aut. Create these three files under `/path/to/my-mod/`:

```text
my_mod/constants/component.lua
schemas/step_notice.lua
systems/step_notice.lua
```

The ID module gives the schema and the system one shared component name. It is a helper
module: `require` loads it when a discovered file imports it.

```lua
-- my_mod/constants/component.lua
-- One name identifies the saved timer wherever the mod reads or writes it.
local component = {
    STEP_NOTICE = "my_mod.step_notice",
}

return component
```

The schema describes the state that each player instance can save. Loading
this file registers the shape; it does not create a component on its own.

```lua
-- schemas/step_notice.lua
local components = require("my_mod.constants.component")

-- Keep the elapsed time on the player so saves preserve the partial interval.
local schema = {
    id = components.STEP_NOTICE,
    version = 1,
    fields = {
        elapsed_aut = {
            type = "int64",
            default = 0,
        },
    },
}

register.component(schema)

return schema
```

The system registers its callback while loading. The scheduler later calls
`system.update(ctx, entity, delta)` with the current game, the active actor,
and that actor's elapsed action time. An empty query is intentional: the
system has to see the player once *before* its component exists.

```lua
-- systems/step_notice.lua
local channels = require("constants.message_channels")
local components = require("my_mod.constants.component")

local NOTICE_INTERVAL_AUT = 50
local system = {}

-- Theory of operation: only player actions advance this saved timer. The
-- scheduler supplies action time in aut; a component holds the remainder so
-- loading a save does not restart the interval. Monsters cannot advance it.
-- Example: 40 saved aut plus a 10-aut move emits one notice and stores zero.
function system.update(ctx, entity, delta)
    if entity ~= ctx:player() then
        return
    end

    local timer = ctx:get(entity, components.STEP_NOTICE)
    local previous = timer and timer.elapsed_aut or 0
    local total = previous + delta
    local crossed_interval = total >= NOTICE_INTERVAL_AUT
    local next_timer = {
        elapsed_aut = total % NOTICE_INTERVAL_AUT,
    }

    if timer then
        ctx:set(entity, components.STEP_NOTICE, next_timer)
    else
        ctx:add(entity, components.STEP_NOTICE, next_timer)
    end

    if crossed_interval then
        ctx:emit(channels.DURATION, "You feel the passage of time.")
    end
end

register.system({
    id = "my_mod.step_notice_system",
    scope = "active",
    query = {},
    update = system.update,
})

return system
```

Launch with `go run ./cmd/crawl --mod-dir=/path/to/my-mod` and take player
actions totaling 50 aut. The notice appears once on the action that crosses
the interval. A single action longer than one interval still emits one
notice, while the saved timer keeps the remainder. This is a simple policy
choice for the example; a different rule may need to process every interval.

Here `register.component` and `register.system` run at startup, when there
is no game `ctx`. The registered `update` function runs later. The `entity`
argument identifies the actor being updated; `ctx:player()` identifies the
player even on a monster action. `ctx:get` returns a detached component
table, so the callback uses `ctx:set` or `ctx:add` to save its result.
`ctx:emit` displays the notice but does not store the timer. Removing the mod
changes the ruleset identity and leaves a save containing a component whose
schema is absent; see [Saves and identity](#saves-and-identity) before
reopening that save without the mod.

### `ctx` in one minute

`ctx` is an argument supplied by the engine **when a game rule runs**. It is
not a global, a monster, a component, or a definition. A Lua file normally
loads once to register its definition or callback. The callback runs later,
with `ctx` for the current game action. For example:

```text
game action -> engine or domain caller -> your callback(ctx, actor, ...)
                                      -> ctx:get / ctx:random / ctx:move_actor
                                      -> later rules observe the staged change
```

The domain caller supplies the other arguments. A system gets its matching
`entity` and elapsed `delta`; a monster spell gets `caster`, `foe`, `slot`,
and its saved target plan. `ctx` supplies capabilities, while these arguments
identify what this particular invocation is about. Calling `ctx:player()`
inside every effect would accidentally turn monster and ally effects into
player effects. Read the [entry-point table](#the-game-context-ctx) and the
nearest working handler before writing a new callback.

```lua
local components = require("constants.component")

local effect = {}

-- Read the live actor's health when the effect occurs. The returned table
-- is a snapshot; writing it back makes the change visible to later rules.
function effect.heal(ctx, actor, amount)
    local health = ctx:get(actor, components.HEALTH)

    if not health then
        return false
    end

    health.current = math.min(health.max, health.current + amount)
    ctx:set(actor, components.HEALTH, health)

    return true
end

return effect
```

Another Lua rule must call `effect.heal(ctx, actor, amount)` for this helper
to run. Merely putting the file under `policy/` loads the module; it does not
schedule `heal`. The caller supplies the same `ctx` it received, so both
rules see the same game action. Use `ctx:player()` only when the rule means
the player specifically; a monster can be the current actor.

The example isolates the mechanics of `get` and `set`. A real healing
effect must also check the recipient's rules. For player healing, inspect
`policy/potions/effects/heal_wounds.lua`: it checks potion and Death's Door
restrictions before changing HP. For monster healing, inspect
`policy/combat/monster_support/healing.lua`. Use `ctx:set` directly for a
component your rule owns, such as the saved timer in the
[complete new-mod example](#a-complete-new-ctx-example).

The `:` in `ctx:get(actor, id)` is Lua's method-call syntax. It passes `ctx`
as the hidden first argument. `ctx.get(actor, id)` omits that argument and
therefore calls the host method incorrectly. Domain methods such as
`effect.heal(ctx, actor, amount)` are ordinary functions unless their module
defines them with `:`. Copy the call style from the module's definition.

Ask **who calls this function?** before adding a `ctx` parameter. A system's
`update` gets one from the scheduler. A registered host policy gets one from
the Go caller, possibly empty for a read-only decision. A potion, spell, or
monster effect gets one because its Lua caller passes it along. A content or
schema declaration gets none at load time. A vault hook gets a separate
generation `api`. The [entry-point table](#the-game-context-ctx) and
[method reference](#entities-and-components) show the exact contracts.

When adding a feature, follow this path:

1. Find the nearest bundled example and identify who calls it. A file can
   load successfully without its returned function ever being invoked.
2. Add a catalog definition if the feature has an identity or fixed facts.
   Add a schema only if an individual entity needs mutable saved state.
3. Put the rule in a focused policy for an event or effect, or in a system
   for work that repeats on actions. Register it with that domain's existing
   entry point.
4. Inside the invoked function, use the passed `ctx` to read and write live
   state. Pass it to other policies; do not create or cache another context.
5. Add a `_test.lua` case using the production rule and schema, then launch
   with `--mod-dir` to check discovery and integration.

The [complete `ctx` reference](#the-game-context-ctx) lists every method,
argument, return value, and invocation limit. The
[feature walkthrough](#work-through-a-new-mod-feature) covers file placement
and validation. The rest of this guide gives the contracts for each kind of
content currently supported by the game.

### Who supplies `ctx`

You never import `ctx`, register it, or construct it. The Go runtime supplies
the live context when it invokes a Lua entry point. That entry point
may pass the same argument to focused Lua policies. The context is a set of
operations on the *current game*, not a table containing the current monster,
spell, or target. Those arrive as separate arguments. This is why a helper's
signature often begins with `ctx, actor`: it needs both game access and the
identity of the entity to affect.

- **File load or content registration:** no `ctx` exists. Use definition
  tables and imported IDs.
- **ECS system:** the scheduler passes `ctx, entity, delta`. `entity` matched
  the query; `delta` is the action's elapsed aut.
- **Potion, scroll, or player spell:** the command passes `ctx` plus the item
  user or caster and its domain-specific request, intent, definition, or power.
- **Monster spell:** spell selection passes `ctx`, caster, selected foe, and
  spellbook slot; resolution also receives the saved target plan.
- **Cloud or trap:** the exposure or activation owner passes `ctx`, the
  affected actor, and live cloud or trap state.
- **Named `register.policy` callback:** the Go host passes `ctx` and an input
  table. Read-only host calls pass an empty `ctx`; decide from input alone.
- **`.des` vault hook:** it receives a separate generation `api`, not `ctx`.

This table is a quick way to tell which facilities an entry point may use.
The callback's actual arguments still come from its domain caller, as shown
in the examples below.

| Where the code runs | Live ECS and grid | Randomness and messages | What to pass to helpers |
| --- | --- | --- | --- |
| Content, schema, or module load | No game `ctx` | No game RNG or messages | IDs, definitions, and ordinary tables. |
| Invoked game effect or ECS system | The supplied live `ctx` | Use `ctx:random` and `ctx:emit` | Pass the same `ctx` plus the actor or target handle. |
| Read-only `register.policy` decision | Empty `ctx` | Unavailable | Pass the supplied `input` table; return a result table. |
| `.des` generation hook | No game `ctx` | Use the supplied vault `api` | Pass `api` and the hook's explicit arguments. |
| Isolated Lua test | Only services installed by its fixture | Do not assume a clock, player, grid, or event sink | Build the needed fixture or test a pure helper. |

For example, a monster's `content/monsters/` file can register its attack
data at startup. Its combat effect cannot roll or wound anything then. When
combat invokes that effect, it supplies `ctx` and the participating live
entities. The effect reads their components, uses a named random stream, and
asks the health policy to apply damage. This separation is why the same
monster definition can describe many creatures with different current HP.

The first argument has the same name in many files because those files share
engine services, **not** because their callbacks share one signature. For
example, a system's `entity` is selected by its component query. A monster
spell's `foe` is selected by its AI. `ctx:actor()` reports whose action is
underway; it does not replace either argument. `ctx:player()` reports the
player even during a monster action. If a rule concerns the given target,
use that target handle rather than fetching the player.

An ordinary helper gets `ctx` only because its caller passes it along:

```lua
local ward = require("policy.my_mod.ward")

local effect = {}

-- The command owns *when* the effect occurs. The ward policy owns *how*
-- its status changes, so another spell or item can reuse the same rule.
function effect.apply(ctx, reader)
    ward.grant(ctx, reader, 30)
end

return effect
```

The `30` here is a duration in aut, supplied by this example's caller. The
helper must receive `reader` explicitly; `ctx` alone cannot tell it which
entity the scroll was read by. This example is only the method body: a real
scroll effect also needs `prepare`, an item definition or existing item ID,
and `scrolls.register`, as in [the live overlay](#a-first-live-mod).

Inside a callback, ask what kind of fact you need before choosing a method:

1. **Fixed facts about a kind** come from a catalog definition, using an ID
   imported from `ids.*`; `ctx` is not needed to read them.
2. **Changing facts about one live entity** come from `ctx:get(entity, id)`.
   Change the detached result and replace it with `ctx:set`, or use `ctx:add`
   when the component is absent. A saved condition needs a registered schema.
3. **Spatial facts** come from the level methods on `ctx`. Read the actor's
   position component for `level_id`, `x`, and `y`; check terrain and
   occupancy, then use `ctx:move_actor` or another grid operation.
4. **A choice made during play** uses `ctx:random` with a named stream. A
   definition or file-load expression cannot draw from the game's RNG.
5. **A one-action notification** uses `ctx:emit` for player text or
   `ctx:signal` for another rule. Neither stores a lasting condition.

The detailed method tables below state the parameters and return values.
If a helper calls another helper, pass the current `ctx` through unchanged.
Never keep it in a module variable for a later turn. The context's component
and grid writes are staged during the action; later rules see the staged
view, and the runtime applies structural changes at the action barrier.

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
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=weapon --name="moss blade"
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=system --name="moss growth" --namespace=moss
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=vault --name="moss room" --with-hook
go run ./cmd/crawl-mod --mod-dir=/path/to/my-mod --kind=vault --name="moss shop" --family=shop
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

Dungeon Crawl Stone Soup embeds its Lua rules under `internal/modfs/builtin/`. Add one or more
mod directories by repeating `--mod-dir` in the order they should apply:

```text
crawl --mod-dir=/path/to/extra-monsters --mod-dir=/path/to/spell-changes
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

Unique artefacts are separate files under `content/artefacts/`. Set `name`
to the true name and `appearance` to the name seen before identification;
an empty appearance means the same text as `name`. A unique whose two names
match identifies itself automatically, except when its `flags` include
`artefact_flags.UNIDED` from `constants.artefact_flags`. A random artefact
starts unidentified even if the player knows its base item kind. Its
`item.artefact` component stores true name, appearance, and properties;
`item.identification` stores what this player has learned about that
physical item. Call `policy.items.identification.reveal_type(ctx, player, item)`
or `reveal_item(ctx, item, fields)` from an effect that actually
reveals it. Do not add its base kind to the player's `known_types` map:
that would identify other items by accident.

Generated equipment artefacts select weighted names and unidentified
appearances from `content/randart_names/`. Each source key has its own file,
such as `weapon.lua` or `ring_appearance.lua`. To replace one group, copy
that relative path into the overlay and edit its `entries`; to add a group,
place a new Lua definition in that directory. Each entry needs a positive
integer `weight` and a nonempty `text`. Source `@key@` references can name
another group; player, species, branch, and god markers use current game
facts. Keys are lowercase, including source keys that were written with
capital letters. `@god_name@` picks only gods whose source rules allow the
finished item's class, brand, and properties; `@xom_name@` draws from Xom's
short name or weighted long-name list. Boot validation rejects missing
references. The game chooses one
cosmetic seed per artefact and saves the resulting names, so later content
changes do not rename an existing item.

Generated random spellbooks also use this catalog. A themed book draws its
book noun and school wording from `book_name` and the school groups. A
single-level book draws from the starting, easy, moderate, or difficult
`level book` group. Owner-specific groups can name an author, and
`@level@` inserts the spelled-out spell level. `book appearance` supplies
the description seen before identification. A future gift or authored-vault
policy can pass `owner`, `subject`, or `god_id` in an item-generation request.
An empty owner or subject triggers the ordinary random choice; a supplied
subject may contain the same `@marker@` references as catalog phrases.
Replace one group file in an overlay to alter its phrases without changing the Go
engine or other name groups.

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

Read a callback from left to right:

```text
Lua file loads -> registers a definition or callback -> a game action invokes it
    -> the caller supplies ctx and the relevant actor/target handles
    -> the callback reads current state -> computes a result
    -> the callback writes components or grid state -> later rules see the change
```

`ctx` does not identify *which* actor a rule should change. That comes from
the callback's `entity`, `player`, `caster`, or `foe` argument, or from an
explicit `ctx:query`. In a system, `entity` is the actor matched by the
query; `ctx:actor()` is the actor whose action is underway. In a monster
spell, `caster` and `foe` come from spell selection. Do not silently replace
`foe` with `ctx:player()` or an allied monster may attack the player.

| I need to... | Use... | Avoid... |
| --- | --- | --- |
| Read or change this actor's saved state | `ctx:get(actor, id)`, then `ctx:set(actor, id, changed)` | Keeping the returned table in a module variable. |
| Attach a new condition | A registered schema and `ctx:add(actor, id, fields)` | Inventing an undeclared field on an entity. |
| Find every actor with certain state | `ctx:query({ component_a, component_b })` | Assuming a catalog definition is a live actor. |
| Move an actor | `ctx:move_actor(actor, level_id, x, y)` | Setting `core.position` directly. |
| Choose randomly during an action | `ctx:random(stream_id, bound)` | `math.random` or a module-load roll. |
| Pass a fact to a later system in this action | `ctx:signal(name, value)` and `ctx:signals(name)` | Using a signal for state that must survive a save. |
| Show text to the player | `ctx:emit(channel, message)` | Treating a message as a state change. |
| Read a fixed monster or spell fact | `policy.catalog.get(category, id)` | Looking for that fact on every entity instance. |

The table is a route to the API, not a second set of game rules. For exact
arguments, return values, failure cases, and staged-write behavior, use the
method tables below. The Lua method installation lives in
[`internal/script/context.go`](../internal/script/context.go); callback
signatures live with their domain registrations. For example, a new spell
effect should read its effect registry and a nearby effect file before
assuming `resolve` has the same arguments as another domain's resolver.

| Lua entry point | Who calls it | Arguments |
| --- | --- | --- |
| `register.system({ update = fn, ... })` | ECS scheduler | `fn(ctx, entity, delta)` |
| `register.policy({ run = fn, ... })` | A named Go host policy call | `fn(ctx, input)`; return a table |
| A method returned by a `policy/` module | Its Lua caller | Whatever that caller passes, often `ctx` first |
| A content or schema file | Startup loader | No `ctx`; register and return a definition |
| A `.des` vault hook | Vault script bridge | A vault-specific `api`, described below |

The callback signature belongs to its **domain**, while the context methods
come from the engine. The following examples show where to inspect the
domain contract before writing a new handler:

- **Timed ECS behavior:** `systems/player_status.lua` shows how Akara's
  scheduler calls `update(ctx, entity, delta)`.
- **Potion effect:** `policy/potions/effects/curing.lua` shows how the quaff
  command calls `can_quaff(ctx, player, forced)` and `apply(ctx, player)`.
- **Player spell:** `policy/magic/effects/direct/smiting.lua` shows how the
  spell command calls `resolve(ctx, player, intent, spell, power)`.
- **Monster spell:** `policy/combat/monster_spells/smiting.lua` shows how AI
  calls `plan(ctx, caster, foe, slot)` and later
  `resolve(ctx, caster, foe, slot, plan)`.
- **Mutation:** `policy/mutations/effects/icy_defense.lua` shows a handler
  registered by capability. Inspect that capability's argument order.
- **Vault hook:** `policy/generation/vaults/arrival/dpeg_arrival_water_fire.lua`
  shows a named `.des` method called with the generation `api`.

These examples live below `internal/modfs/builtin/`. A handler may ignore an
argument, as Curing ignores `forced` or a particular system ignores `delta`.
Do not copy one domain's method signature into another. Read its registry
and one nearby effect first. In particular, a mutation capability may put
`level` before `ctx`; a `policy/` pathname alone does not establish an
argument order.

### Trace a callback before using `ctx`

The engine installs the context methods in `internal/script/context.go`.
That file explains what `ctx:get`, `ctx:random`, and the grid methods do,
but it cannot tell you when your effect runs. For that, follow the Lua
caller. For example, when adding a monster spell:

1. Find a bundled spell in `policy/combat/monster_spells/` with a similar
   target. Read its `plan` and `resolve` methods and its comments.
2. Find the dispatcher that calls those methods. Check whether `plan` may
   read or change state, which arguments identify the caster and foe, and
   what shape of plan survives the intent boundary.
3. Follow any shared policy it calls, such as a damage or summoning owner.
   Import that policy instead of reimplementing its component invariants.
4. Read the relevant component schema or host component definition before
   constructing a value for `ctx:add` or `ctx:set`.
5. Test the callback through its real dispatcher, including a refusal and a
   successful action. A test that calls `resolve` directly cannot prove that
   the dispatcher selects it or preserves its plan.

The same trace works for items, mutations, clouds, and traps: start at a
working neighboring effect, find the registry and caller, then inspect the
state owner. The callback's name alone does not specify its arguments or
return value. A `ctx` method is a low-level game operation; the domain
caller and Lua policy establish the game rule.

`ctx` is a normal function argument, never a magic global. A discovered
`policy/` file is *loaded*, but merely returning `effect.apply` does not make
the game call it. Connect the method to its domain registry, as the bundled
potion, spell, mutation, and monster effect files do. A `register.policy`
callback likewise needs a host path that calls that registered policy ID.
Look at the nearest existing file and its caller before choosing an entry
point. The same rule explains why a content definition can load correctly
while a new mechanic still needs a resolver.

The argument name is conventional; the important part is who supplies it.
For example, `function effect.apply(ctx, player)` receives the game context
from the potion command, while `player` is the entity being affected. In
`function system.update(ctx, entity, delta)`, `entity` is the entity selected
by the system's query. Neither argument is a content definition. To get that
entity's mutable state, call `ctx:get(entity, component_id)`; to get a
definition's fixed facts, use the catalog. The same monster kind can have
many live entities with different health, positions, and statuses.

When reading an unfamiliar callback, identify four things before using
`ctx`: **who calls it**, **which entity it concerns**, **which component or
catalog definition owns the fact**, and **whether the result must persist**.
The answers determine the API call:

| What the rule needs | Where to get or keep it |
| --- | --- |
| Fixed monster or item facts shared by every instance | Import its ID and call `policy.catalog.get(category, id)`. |
| Current HP, location, equipment, or status | Read with `ctx:get`; replace the component with `ctx:set`. |
| A new per-entity status that survives turns and saves | Declare a `schemas/` component and attach it with `ctx:add`. |
| A fact another system needs during this action only | Publish `ctx:signal` and consume it with `ctx:signals`. |
| Text for the player | Use `ctx:emit`; messages are presentation, not rule state. |
| An action-time random choice | Use a named `ctx:random` stream inside the invoked callback. |
| A terrain or movement change | Use the grid methods on `ctx`, which maintain spatial indexes. |

For example, a monster content file may say its kind has 5 HD. A live
monster has its own HP and position components. A cast first finds the live
caster and target handles; its effect can read the caster's current position
through `ctx:get`, get the kind's fixed spell facts from the catalog, roll
the result with `ctx:random`, and attach a duration component to the target.
The catalog definition never changes when one monster is wounded.

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

If a function does not receive `ctx`, first look for the owner that invokes
it. For example, the monster spell registry passes the live context to an
effect's `plan` and `resolve` methods. A helper called by `resolve` receives
that same argument explicitly. Do not reach for a module global to bridge
the two. If the intended caller is a content definition, it has no live
game context; move the behavior into a policy or system and connect it to
that domain's dispatch path.

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

`policy/combat/torment_area.lua` is a concrete example of sharing an owner.
The Torment scroll's `apply(ctx, reader)` and Symbol of Torment's
`resolve(ctx, caster, foe, slot, plan)` both pass their received context to
`area.apply(ctx, source, channel)`. The area owner queries nearby actors and
routes HP changes through the player or monster health policy. The entry
points decide *when* the rule runs; the shared policy decides *how* it changes
the current game. No callback stores `ctx` for the next action.

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

A group effect uses the same callback contract but queries several actors.
See `policy/combat/monster_battlecries.lua` and its three spell files for a
complete example. `plan(ctx, caster, foe)` inspects positions, allegiance,
and existing boons without changing the world or drawing randomness. It
returns a self-target plan only if a same-genus ally could benefit. Later,
`resolve(ctx, caster, foe, slot, plan)` queries again because the action may
have changed, rolls one duration per recipient from `ctx:random`, and writes
the boon to each recipient through the shared boon policy. The resulting
status belongs to the recipient's ECS component and survives save/restore.
Its cry calls the shared noise policy, which uses `ctx:cell` and `ctx:query`
to update listeners. A modded group effect should follow that pattern when
one action changes several entities: keep the source rule in one focused
policy, use `ctx` for live state, and let existing component owners apply
their own invariants.

A typical stateful rule reads a component, calculates a result using its
explicit inputs and a named RNG stream if needed, writes the full component
back, then emits a message or transient signal. `ctx:get` returns a copy,
so editing its fields without `ctx:set` silently loses the change. The
engine applies staged additions, removals, movement, and terrain changes at
the action barrier; later callbacks in that action can see their staged
view. Persistent state belongs on components, while `ctx:signal` is only
for communication during the current action. This is why a module-level
Lua variable cannot stand in for a cooldown or a saved status.

The context is **not** one transaction covering every kind of effect.
Component and grid writes are queued, and reads through `ctx` see those
queued changes immediately. If a Lua callback fails, the runtime discards
those queued writes and any entities it created. Random draws advance a
saved stream when called; `ctx:emit` calls the message service immediately;
`ctx:signal` publishes to the current action's signal list. Do not assume
that a later Lua error reverses a draw, message, or signal. Validate the
target, required components, and destination before rolling, emitting, or
publishing whenever the rule can still refuse to act. This is especially
important in `plan` and `prepare` methods, which may decline an action.

For example, check `ctx:has(target, components.HEALTH)` and the target's
position first. Only after the action is accepted should `resolve` draw
damage, write health through its owner, and announce the result. This order
keeps a rejected attempt from consuming randomness or displaying an event.

For a direct status effect, follow the gaze files as a concrete example:
`policy/combat/monster_spells/weakening_gaze.lua` plans a visible target,
then its `resolve` calls the player or monster status owner. The player
owner stores `combat.player_weakness` through `ctx:add` or `ctx:set`; its
system ages that component using action aut. The attack policies read it
when calculating melee damage. The spell ID comes from `ids.spells` and the
component ID from `constants.component`; neither is retyped in each caller.
A new effect can reuse this context and ownership pattern while keeping its
own formula and comments in its own file.

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
| `ctx:player()` | Player handle; `nil` if the service has no entity; error if the service is absent. |
| `ctx:actor()` | Acting creature handle; `nil` if the service has no entity; error if the service is absent. |
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

This shows the replacement rule, not a complete healing rule. Check the
player or monster healing policies before changing live HP; use the same
`get`/`set` pattern directly for state owned by your mod. Before changing a
bundled component, find its policy owner and check what else it updates.

`add`, `remove`, `destroy`, actor movement, and terrain changes are staged at
the action barrier. Later context reads and queries in that action see the
staged state. If a callback fails, its pending structural changes and new
entities are discarded. This does not reverse an already drawn random value
or a message already sent to the host. Do not retain an entity handle in a
Lua module global: module globals are neither per-game persistent state nor
saved components.
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

A Lua scenario may supply a `heightmap` on a Shoals level: an array of
integer rows with the same dimensions as `cells`. Each value is the authored
ground elevation, not the current water depth. The engine derives threshold
heights from the initial terrain when this field is absent. The Shoals tide
policy uses these values while the grid keeps the changing floor and water.

| Call | Result and use |
| --- | --- |
| `ctx:level_size(level_id)` | `width, height`, or `nil, nil` for a missing level. |
| `ctx:level_branch(level_id)` | Branch ID, or `nil` for a missing level. |
| `ctx:marker_property(level_id, x, y, key)` | A placed vault marker's named string property, or `nil`. |
| `ctx:shoals_height(level_id, x, y)` | Authored Shoals elevation, or `nil` when absent. Water changes do not alter it. |
| `ctx:shoals_tide_clock(level_id)` | Raw height, velocity, and last update aut; three `nil` values if absent. |
| `ctx:set_shoals_tide_clock(level_id, height, velocity, last_aut)` | Save an advanced Shoals tide clock. |
| `ctx:cell(level_id, x, y)` | Terrain ID at the cell, or `nil` when missing. Includes staged terrain changes. |
| `ctx:walkable(level_id, x, y)` | Whether an actor can walk on the current or staged terrain. |
| `ctx:actor_at(level_id, x, y)` | Occupying actor handle, or `nil`; includes staged moves. |
| `ctx:stair_at(level_id, x, y)` | Link `{ to_level_id, to_x, to_y, unavailable }`, or `nil`. |
| `ctx:visible(level_id, from_x, from_y, radius, target_x, target_y)` | Ordinary sight. |
| `ctx:visible_no_trans(level_id, from_x, from_y, radius, target_x, target_y)` | Clear walls block; actors do not. |
| `ctx:visible_no_trans_with_blocked(level_id, from_x, from_y, radius, target_x, target_y, cells)` | Test sight with an array of extra `{ x, y }` opaque cells; the grid is unchanged. |
| `ctx:visible_cells(level_id, from_x, from_y, radius)` | Array of visible `{ x, y }` cells. |
| `ctx:route_step(level_id, from_x, from_y, to_x, to_y, goal)` | `dx, dy, found`; no route gives `nil, nil, false`. |
| `ctx:projectile_clear(level_id, from_x, from_y, to_x, to_y)` | Physical ray; actors block. |
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
can treat that actor as the goal. Choose `visible` for ordinary sight,
`visible_no_trans` for a rule that cannot see through clear walls, and
`projectile_clear` for a bolt that actors can intercept. For example,
`policy/combat/monster_battlecries.lua` uses `visible_no_trans`: an ally
standing between a chief and its foe should receive the cry, not block it.
These queries only answer geometry; damage, hostility, and action time
belong in a policy or system. `ctx:visible` says that a *cell* is in sight; it
does not say that the player can perceive an invisible actor standing there.
Before naming a monster in a player message, use
`policy.character.senses.player_sees_actor`. This also keeps offscreen combat
from leaking monster identities into the message log. For terrain, clouds,
and other visible world events, use `senses.player_sees_cell(ctx, position)`.
Sample actor sight *before* granting invisibility when the message describes
a creature visibly disappearing.

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
- **`player entity is unavailable` or `active actor is unavailable`:** The
  callback has no corresponding host service, often because an isolated test
  passed a bare ECS context. Supply a game fixture with those services or
  choose a callback that only needs the actor explicitly passed to it.

A Lua callback error discards its pending ECS and grid writes and reports the
originating Lua path or system ID. It does not guarantee rollback for RNG,
messages, or signals. Fix the first reported error before interpreting missing
state later in the action. When a mod changes files,
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
4. Launch with `go run ./cmd/crawl --mod-dir=/path/to/my-mod`. Startup
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

### Find the callback contract for your domain

`ctx` provides engine operations, but it does not decide which callback is
invoked or what `plan`, `apply`, or `trigger` should return. Check these paths
in the bundled tree before implementing a new rule:

- **Player spell:** Definition in `content/spells/`, behavior in
  `policy/magic/effects/`. Inspect `policy.magic.effects.registry` and its
  `resolve(ctx, player, intent, spell, power)` contract.
- **Monster spell:** Definition in `content/spells/`, slot in
  `content/monster_spellbooks/`, behavior in
  `policy/combat/monster_spells/`. Inspect the monster spell registry's
  `plan(ctx, caster, foe, slot)` and
  `resolve(ctx, caster, foe, slot, plan)` contract.
- **Potion or scroll:** Item definition in `content/items/`, behavior in
  `policy/potions/effects/` or `policy/scrolls/effects/`. Inspect
  `policy.potions` or `policy.scrolls` for the applicable methods.
- **Cloud or trap:** Definition in `content/clouds/` or `content/traps/`;
  the definition names its effect module. Inspect the paired effect and
  the exposure or activation owner before writing its callback.
- **Timed state:** Schema in `schemas/`, system in `systems/`. The Akara
  scheduler calls `update(ctx, entity, delta)`.
- **Vault hook:** Map in `vaults/<family>/`, named handler in
  `policy/generation/vaults/<family>/`. The `.des` `vault.run` or
  `vault.veto` hook receives generation `api`, not `ctx`.

The paths are entry points, not a promise that every callback has identical
arguments. For example, a scroll's `prepare` method can request input before
`apply`, and a player spell's `intent` is different from a monster spell's
saved `plan`. Read one nearby working effect and its dispatcher. Keep a rule
that several definitions share in a focused policy module and have their
individual effect files call it with the received `ctx`.

The common effect contracts currently used by those dispatchers are:

- **Potion:** `can_quaff(ctx, player, forced)` may return a refusal string
  and then a confirmation string. If it accepts, `apply(ctx, player)` runs
  during action resolution.
- **Scroll:** `prepare(ctx, player, request)` returns `nil` to proceed or a
  decision table to stop or prompt. `apply(ctx, player, request)` runs during
  action resolution.
- **Player spell:** optional `prepare(ctx, player, spell, dx, dy, input)` may
  reject the cast. `resolve(ctx, player, intent, spell, power, aut)` applies
  the committed cast.
- **Monster spell:** `plan(ctx, caster, foe, slot)` returns `nil` to decline
  or an entity or cell plan saved with the intent. Then
  `resolve(ctx, caster, foe, slot, plan)` applies the committed cast.
- **Cloud exposure:** `apply(ctx, actor, state, elapsed_aut, cloud_entity,
  definition)` returns damage dealt, or `nil`/`0` for no damage.
- **Trap activation:** `trigger(ctx, trap_entity, actor, trap_state)` returns
  true to consume the trap; false or `nil` leaves it for the charge rule.
- **Timed system:** `update(ctx, entity, delta)` updates or removes the
  queried component; the scheduler does not use a return value.

The names after `ctx` are not interchangeable. For a cloud, `state` is the
live cloud component, while `definition` is the fixed catalog entry. For a
trap, `trap_entity` is the trap's ECS handle and `actor` is whoever entered
its cell. For a monster spell, `plan` is a saved target choice; recompute
eligibility during `resolve`, but do not silently aim at a different foe.
Potion and scroll checks run before the action is committed, so a refusal
must not consume an item or change persistent state. Read the cited command
and an adjacent bundled effect for a domain's exact request and plan fields.

## Content files

### Definition contracts

The examples in this guide show the shape of common additions, but each
category has its own accepted fields and cross-reference checks. Before
writing a new definition, open a nearby bundled file in the same directory
and the corresponding validator or consuming policy below. The validator
checks required fields, ranges, and references; the Lua consumer shows how
the game uses the accepted fields. The nearby content file shows how to name
and import its IDs. A file that registers successfully can still need a
separate behavior file, as described under each feature type.

| Content you are adding | Bundled examples | Field and reference contract |
| --- | --- | --- |
| Species or job | `content/species/`, `content/jobs/` | [`species.go`](../internal/content/species.go), [`job.go`](../internal/content/job.go) |
| Monster or spellbook | `content/monsters/`, `content/monster_spellbooks/` | [`monster.go`](../internal/content/monster.go), [`monster_spellbook.go`](../internal/content/monster_spellbook.go) |
| Monster beam profile | `content/monster_beams/` | A nearby beam definition and `policy/combat/monster_beams.lua` for its resolution path |
| Item, weapon, or artefact | `content/items/`, `content/artefacts/` | [`item.go`](../internal/content/item.go), the relevant Lua policy under `policy/inventory/` or `policy/item_generation/` |
| Player spell | `content/spells/` | [`spell.go`](../internal/content/spell.go), then its effect registry under `policy/magic/effects/` |
| Branch | `content/branches/` | [`branch.go`](../internal/content/branch.go) and the generation policy that consumes its fields |
| Mutation | `content/mutations/` | Its nearby Lua definition and `policy/mutations/effects/registry.lua` for any new capability |
| Cloud, trap, or shop | `content/clouds/`, `content/traps/`, `content/shops/` | Their Lua `policy/<category>/catalog.lua` and effect or stock policy |

If an existing category's field is unclear, search for the field name in its
consumer policy. That tells you whether it is display data, generation data,
or a live rule input. For a new category owned wholly by a mod, use
`register.definition(category, definition)` and a focused policy that reads
it through `register.get`; registering a new catalog does not create a
command, scheduler hook, or UI screen automatically.

Put one definition in one file below `content/<category>/`. The recognized
base categories are `species`, `jobs`, `monsters`, `spells`, `items`,
`mutations`, `branches`, and `monster_spellbooks`, plus `artefacts`, `clouds`,
`monster_beams`, `shops`, and `traps`. The registration API accepts additional
category names for mod-defined catalogs. For example,
`content/monsters/my_moss.lua` can contain:

```lua
local categories = require("constants.catalog")
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
}

register.definition(categories.MONSTERS, definition)

return definition
```

Here `my_mod/ids.lua` is a small module owned by the mod that returns
`MOSS = "MY_MOD_MOSS"`, `BITE = "AT_BITE"`, `PLAIN = "AF_PLAIN"`, and
`MOSS_POPULATION = "MY_MOD_MOSS_POPULATION"`. Import it in every mod
file that uses those identifiers. Existing bundled IDs come from their
`constants.*` or `ids.*` modules instead.

The monster file is loaded automatically. It describes the creature, while
`content/populations/` decides where ambient generation may choose it.
Add a separate file such as `content/populations/moss_in_lair.lua`:

```lua
local branches = require("ids.branches")
local categories = require("constants.catalog")
local curves = require("constants.population_curves")
local my_ids = require("my_mod.ids")

-- Lair's ambient picker reads this row at each local depth. The monster
-- definition stays independent so vaults may also place it directly.
local definition = {
    id = my_ids.MOSS_POPULATION,
    branch_id = branches.BRANCH_LAIR,
    rows = {
        {
            monster_id = my_ids.MOSS,
            min_depth = 1,
            max_depth = 3,
            rarity = 1000,
            curve = curves.FLAT,
        },
    },
}

register.definition(categories.POPULATIONS, definition)

return definition
```

The catalog combines independent population files for a branch in stable ID
order, retaining row order inside each file. A same-path overlay replaces
that file; a new path adds rows. `NO_MONSTER` rows consume a draw without
creating an actor. Every row needs a local depth range, rarity, and curve;
the startup validator checks monster IDs and spell coverage before that
branch can spawn it. File discovery order does not affect a seed.

### Add an ordinary branch

An ordinary branch definition belongs in `content/branches/` and needs a
unique numeric ID, a parent branch, an entry depth range within that parent,
a local depth, and source entry/exit feature IDs. The per-run Lua schedule
chooses one parent depth and stores it in the save. It places a pending
entrance when the branch has a weighted primary layout, or a labelled
unavailable entrance until that layout is ported. Its stable level ID is
`numeric_id * 100 + local_depth`;
Dungeon keeps IDs 1–15. Put ambient rows in a separate
`content/populations/<branch>.lua` file as above. Add weighted branch layouts
under `vaults/layout/` and named Lua carving hooks under
`policy/generation/layouts/` when a layout needs a script. The shared
generation policy chooses layouts, vaults, stairs, and population using the
branch ID and local depth, then the Go world saves the connected floor.
Portals and rootless destinations need their own travel policy; a finite
depth range alone does not make them ordinary branches.

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

The spellbook file declares its *own* ID and imports IDs it refers to. For
example, `content/monster_spellbooks/mst_moss_helper.lua` can contain:

```lua
-- This book gives the moss creature one natural summon cast. The effect
-- lives in its spell policy, so the book only decides when to offer it.
local categories = require("constants.catalog")
local flags = require("constants.monster_spell_flags")
local spells = require("ids.spells")

local definition = {
    id = "MST_MOSS_HELPER",
    slots = {
        {
            spell_id = spells.SPELL_MOSS_HELPER,
            frequency = 18,
            flags = {
                flags.NATURAL,
            },
        },
    },
}

register.definition(categories.MONSTER_SPELLBOOKS, definition)

return definition
```

In the monster's own file, import `ids.monster_spellbooks` and set
`spellbook_id = spellbooks.MST_MOSS_HELPER`. The `ids.*` modules resolve
references against the effective bundled and overlay catalogs, so a new
spell or book can live in a separate file without editing a central ID
list. Unknown references fail at startup after content registration; file
discovery order does not determine a spell choice or random draw.

`plan` runs before the cast is committed. Return `nil` when the spell cannot
currently be used. Otherwise return a typed entity or cell target that can
cross the intent boundary. A foe-centered summon should save the selected
cell in the plan; re-reading a moving foe inside `resolve` would redirect an
already chosen cast. `resolve` runs with the live game context after the
action is committed. Put count, species, and duration draws there using
`ctx:random` or a focused `policy/combat/monster_summons/` helper. Import
spell, monster, component, attitude, and stream IDs at the use site.
The spell intent stores the selected enemy as `foe_entity` independently of
the target plan. A self spell may plan the caster, and a cloud may plan a cell;
both still receive the original `foe` argument in `resolve`. Never infer the
foe from `plan.entity`, and use `ctx:player()` only for rules that specifically
concern the player.

For a spell that runs several existing effects as one action, see
`policy/combat/monster_serpent_breath.lua` and its four small effect files.
The coordinator plans one target, receives the same `ctx` in `resolve`, then
calls each head effect with an explicit plan. The selected `foe` remains the
same handle; each head keeps its own damage and cloud logic. This is a useful
pattern when a new spell combines existing rules: put ordering and stopping
conditions in one policy, and leave the individual effects with their
existing owners.

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

For a spell that strikes a visible actor without a projectile, inspect
`policy/combat/monster_spells/smiting.lua` and
`policy/combat/monster_direct.lua`. Its `plan` receives `ctx`, caster, and
foe, and returns a typed entity plan only when that actor is in sight and
range. Its `resolve` checks the saved target handle, rolls on the
`monster_spell` stream, sends attributed damage through the correct health
owner, and emits the cast message. Airstrike, Waterstrike, and Resonance
Strike use the same target contract but keep their different damage rules
in their own files. Use this pattern for a new direct strike; use the beam
family when a ray can hit an intervening actor or reflect. The direct helper
only supplies target and HP services, so it does not choose your spell's
formula, elemental resistance, or special effects.

For a projectile monster spell, also add a definition at
`content/monster_beams/<spell-name>.lua`. It supplies the source zap ID,
damage dice, accuracy, beam flavour, and whether the ray penetrates actors.
Its matching `policy/combat/monster_spells/<spell-name>.lua` returns the
effect object and calls `policy.combat.monster_beams.plan` and `.resolve`.
See `fire_breath.lua` in both directories for the smallest complete ray.
Set `natural_power = true` when the source attack uses ordinary monster HD,
so Aura of Brilliance does not strengthen it; magical beams use spell HD.
For a caster-specific power exception, call
`policy.combat.monster_beams.power.with_multiplier(profile, numerator,
denominator)` on the effective profile. This preserves a mod's base-profile
override and applies the fraction after calculating power. Cold Breath and
Searing Breath show the two source examples. Use an existing beam flavour
when its resistance and contact rules match; a genuinely new flavour needs
a focused Lua contact rule as well as a profile.

For a ray that also leaves clouds, give its spell definition the `cloud`
flag and implement an `after_endpoint(ctx, caster, profile, plan, endpoint)`
method on the returned effect object. The beam owner calls it after contact
resolution. `endpoint` contains `level_id`, `x`, `y`, and a `path` array of
traversed `{ x, y }` cells. A landed cloud ray stops at the first actor it
hits, even if its beam profile says `can_beam = true`; the endpoint and path
already reflect that stop. Use `policy.clouds.placement` for individual path
cells and `policy.clouds.area` for an endpoint field. Both write saved ECS
clouds with source attribution. `flaming_cloud.lua` under
`policy/combat/monster_spells/` demonstrates both operations; its matching
beam profile and spell definition show the other two files needed.

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

## Clouds, traps, and shops

These catalogs have different ways of turning fixed definitions into live
gameplay. A definition file loads at startup; the corresponding rule runs
later with a game `ctx` only when the game reaches that feature.

For a **cloud**, add one file under `content/clouds/` and name an effect
module in its `effect` field. `content/clouds/poison.lua` and
`policy/clouds/effects/poison.lua` are the paired example. The definition
owns name, color, opacity, spread, and damage metadata. The effect module
returns an `apply` function. The cloud exposure owner calls
`apply(ctx, actor, state, elapsed_aut, cloud_entity, definition)` when an
actor occupies that cloud; `state` is the placed cloud's saved state, and
`definition` is its fixed catalog entry. The effect may use `ctx` to apply
poison or another rule and return the damage amount, or `nil` for none.
The field and placement policies own cloud duration, location, and source
attribution. Reuse them rather than storing those facts in a Lua global.

For a **trap**, add a definition under `content/traps/` with an `effect`
module path. `content/traps/alarm.lua` and
`policy/traps/effects/alarm.lua` show the pair. On entry to a trap cell, the
activation owner calls `trigger(ctx, trap, actor, site)`. Here `trap` is the
live trap entity, `actor` is the creature that entered, and `site` is its
saved trap state, including coordinates and charges. Return true when the
effect consumed the trap; the activation owner destroys it. A one-shot
definition can also consume its own charge before the effect runs. Read the
activation policy before adding a new trap to understand visibility and
movement timing.

For a **shop**, add a definition under `content/shops/`. A normal shop type
is data only: `content/shops/general.lua` supplies its display name,
identification behavior, generation weight, and weighted item classes.
The shared shop generation, stock, pricing, wallet, and purchase policies
turn that definition into placed shops and saved inventory. Add a focused
policy under `policy/shops/` only when the new shop needs a genuinely new
rule; do not copy the full purchase flow into each shop type. Shop placement
can also come from a `vaults/shop/` `.des` map and its optional hook, which
uses the generation `api` described below, not a game `ctx`.

All three categories validate their effective definitions at startup. A
missing cloud or trap effect path fails before play; a malformed shop weight
fails before stock generation. Import their IDs from `ids.clouds`,
`ids.traps`, or `ids.shops` at use sites, and read the corresponding catalog
validator if you need the exact accepted fields.

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

### Melee brand effects

Weapon brand IDs come from `constants.weapon_brands`. A brand's effect on
a monster defender lives at
`policy/combat/monster_target_brands/<brand-name>.lua`, such as
`policy/combat/monster_target_brands/flaming.lua`. The same file runs when
the attacker is the player, a monster, a summon, or a player illusion.
The separate `policy/combat/brands/<brand-name>.lua` file handles attacks
against the player, whose health and conditions have different owners.
To replace one effect in a mod, copy just that relative file path into
your mod directory. The later mod layer wins for that file.

Each monster-target effect returns a local table with an `apply(ctx, hit,
brands)` method. `hit.attacker` and `hit.defender` are ECS handles;
`hit.definition` is the defender's current monster profile, including
any saved illusion values; `hit.damage_done` is the ordinary strike's
damage; `hit.health` is the defender's current health; and
`hit.player_credit` says whether a kill belongs to the player's side.
Use `brands.damage(ctx, hit, amount)` for extra HP loss and
`brands.negative(ctx, hit, amount)` for resistible negative energy.
The former updates `hit.health` and sends kill credit exactly once.
`brands.subject(ctx, hit)` names the actual wielder in a message.
The dispatcher calls `apply` only after a landed melee hit. A file can
set `requires_damage = true` when zero ordinary damage suppresses it, or
`after_death = true` when its effect may run after the physical hit kills
the target. Keep independent rolls in source order within the effect file.

For example, a mod can copy `flaming.lua` to its own matching path and
change the fire bonus while retaining the normal player and monster melee
callers. For a rule test in this repository, add
`internal/script/testdata/lua/tests/<name>_test.lua`, import the production
brand policy and a shared fixture, and avoid duplicating its component
schema.

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

### Dungeon layouts

The effective `vaults/layout/*.des` files are also a live catalog. All 21
source Dungeon definitions are committed: 17 have a positive Dungeon weight,
and four remain registered with weight zero. To add a layout, create
`vaults/layout/<name>.des` with `NAME`, `DEPTH`, `WEIGHT`, and
`TAGS: layout layout_type_<family>`. A calculated layout declares a named
`: vault.run("<method>")` hook and a same-named module under
`policy/generation/layouts/`. Use `MAP` and `ENDMAP` even when the hook
builds the whole grid. The module returns a local table with that method;
see `layout_rooms` for an example.

An authored layout keeps its terrain under `MAP` and needs no run hook.
The layout owner places it through the ordinary vault operation engine,
then completes connected stairs. The two `layout_pan_divisions_*` maps
show this path: they request weighted helpers by `SUBVAULT` tag, while
each helper lives in its own `vaults/builder/*.des` file. Source cells
outside a helper's tagged region stay with the parent, even when their
rectangles overlap. This Pan family is executable through the layout
catalog; the Pan game mode still needs its branch generation flow.

The run method receives `api.ctx`, `api.branch`, `api.depth`, and
`api.absolute_depth`. Build the 80×70 grid with
`policy.generation.grid.new(api.ctx)`, carve it, and return a table containing
`builder` and `rows = builder:rows()`. The catalog calls a named
`vault.validate` method if the `.des` file declares one, then places missing
ordinary stairs in a connected region. A failed source validator gets up to
eight draws of the same layout; malformed hooks fail at startup. Import the
shared geometry helpers you use from `policy.generation.layouts` and keep
source-specific choices in your layout module.

Selection reads only effective `.des` depth and branch weight rules. It
sorts IDs before each weighted draw, so discovery order does not change a
seed. On D:1, arrival tags `layout_<family>` request a family and
`nolayout_<family>` veto one; `no_primary_vault` layouts cannot accompany an
arrival. A mod replaces a bundled layout by using the same relative `.des`
and Lua paths, or adds a new pair without editing a central ID table.
Disabled zero-weight definitions remain visible but are not selected.

Some source layouts deliberately put stairs in separate floor regions.
`layout_caves` is an example: its three down-stair bubbles can remain apart
on a nonbottom Orc or Slime floor. The shared stair pass adds a return
landing in each authored bubble and pairs stairs within that region. A mod
layout should author its meaningful stair glyphs in its Lua builder before
returning; the postpass preserves those glyphs and adds only missing pairs.
For a map that must have one contiguous playable region, use the shared
`cell_graph.keep_largest_region` operation before returning the builder.

### Authored vaults

Vault geometry remains in original `.des` syntax under `vaults/arrival/`,
`vaults/shop/`, or `vaults/serial/`. A map has `NAME`, tags, optional
orientation and directives, then `MAP` and `ENDMAP`. A controller with a
post-place hook may omit MAP when it has no cells. The `.des` file is the
authoritative layout. A mod
may replace an existing `.des` by its exact relative path or add a new one.
Keep terrain, item, monster, marker, and placement instructions in that map
file so a reader can see the whole layout together.
The vault catalog also discovers a new `vaults/<family>/` directory without
an engine edit; put its named hook at the matching
`policy/generation/vaults/<family>/<name>.lua` path. Layout maps use the
separate `vaults/layout/` catalog because they carve the base floor.

#### Temple maps and entrances

Temple has two auto-discovered `.des` families with different roles. Put a
whole-floor map in `vaults/temple/<name>.des` with `PLACE: Temple`,
`ORIENT: encompass`, and at least one `temple_altars_N` tag. `N` is the
number of generic `B` altars this map can receive. The source-weighted
selector considers ordinary maps by their advertised count; add
`temple_rare` for a special map that fixes its own count. A map may list
multiple ordinary counts when a named Lua hook changes its layout based on
the selected count. Keep each map's `NAME` stable: a new game saves that ID
before the player visits Temple.

Put a Dungeon entrance in `vaults/temple_entry/<name>.des` with
`TAGS: temple_entry`, an appropriate `ORIENT`, and exactly one final
`KFEAT: O = enter_temple`. Its `O` cell becomes the linked down stair on
the scheduled Dungeon floor. `WEIGHT` controls the source-weighted entry
draw; the fitter retries another entry when a map cannot connect without
overwriting protected stairs. Both families retain authored monsters, items,
terrain, markers, and feature records.

For calculated source directives, add
`policy/generation/vaults/temple/<name>.lua` or
`policy/generation/vaults/temple_entry/<name>.lua` and call its named method
from `: vault.run("method")` in the corresponding `.des`. The hook uses the
same vault `api` described below. `api:player().settings` supplies the
selected altar count under `constants.temple_settings.ALTAR_COUNT`.
Temple's generic `B` altars receive stable god IDs from the saved plan;
do not hardcode a god name into a generic altar or use a module-level draw.
The grid owns the walkable `_` feature, while
`policy/presentation/view.lua` names an altar from its saved god ID using
`constants.god_names`. Worship rules are a separate domain.

The source Dungeon overflow maps live under `vaults/altar/`. The dedicated
`policy.generation.altar.catalog` discovers added or replaced `.des` files
through the same layered path rules. At new game, the Temple plan assigns
each god outside the main Temple to a group and a Dungeon depth from D:3–10.
When that floor is first generated, `policy.generation.altar.placement`
chooses an eligible source map for each group before ordinary extra vaults.
The chosen map ID, placed records, and altar god IDs are saved. File discovery
order does not determine the draw: the catalog sorts map IDs before applying
the source weights and depth rules.

To add a generic overflow map, give it `temple_overflow_generic_N`, where
`N` is its supported altar count. A map can list several counts when its
named Lua hook reshapes its `B` cells to match. For example,
`chequers_temple_overflow_minitemple.des` supports groups of three, four, or
five gods. A map for named gods uses `temple_overflow_N` plus one
`temple_overflow_<god_name>` tag for each supported god. God tag names use
lowercase display names with spaces replaced by underscores; import
`constants.god_names` in a Lua hook instead of duplicating names there.
The map also needs an eligible `DEPTH`, positive source weight, and terrain
that can fit on the floor. If a scheduled group has no eligible map or cannot
be placed, generation reports the error rather than dropping its gods.

The eight generic maps with variable altars use a
`: vault.run("arrange_altars")` hook. Import `constants.vault_settings` in
that Lua file and read `api:setting(settings.OVERFLOW_ALTAR_COUNT)`. The hook
must leave exactly that many `B` altar cells. The placer also accepts fixed
`KFEAT` altars naming a scheduled god; remaining gods fill `B` cells in
coordinate order. Do not roll a god inside the map hook. The saved plan owns
that choice, and restore checks that each scheduled god has exactly one
altar on the generated floor. Keep terrain and keyed content in the `.des`;
put conditional policy in the companion Lua hook.

For branch-dependent monster content, put a named hook at the original
conditional position and emit only the selected `MONS` or `KMONS` directives.
The base maps under `vaults/altar/` show this pattern; the source alternatives
remain nearby as comments. A prefixed name such as `spectral goblin` resolves
to the spectral actor with the goblin species recorded as its base.
Depth-dependent monster hooks emit just the selected `MONS` or `KMONS`
declarations at the original conditional position. A `god:trog` annotation
on a monster becomes an actor-owned god ID; equipment options after `;` use
their source `w:` weights, `ego:` brand, and `ident:` state when created.
When one overflow map serves several gods, read `api:map_tag()` in its
named Lua hook and compare it with imported `constants.vault_tags` values.
The fire temple's handler shows how to keep a source random fallback for
direct map placement while binding a scheduled god to its own altar.

The `builder/arena_*.des` family illustrates maps reserved for another game
mode. Each definition keeps its original `MAP` rows and `arena_*` tag, but
has no Dungeon `DEPTH` rule. `arena_items` and `arena_smoke` call the shared
`policy/generation/vaults/builder/arena.lua` palette hook. A hook may emit
`COLOUR`, `RTILE`, and `FTILE` directives to record cell styles. `ITEM: any`,
`ITEM: any potion`, and `ITEM: any wand` request an ordinary random item,
optionally constrained to a class. The arena game mode has not been ported
yet, so these maps are registered without entering Dungeon's random pool.

`builder/dungeon_decor.des` is a controller with no MAP rows. Its source
`CHANCE` and `DEPTH` make it eligible on deep Dungeon and Depths floors;
its Lua `place_decor` hook asks the shared selector for one map carrying
the `decor` tag. Add that tag to a new `.des` map to join the effective
pool. The child map retains its own depth, weight, layout, and uniqueness
rules, and a geometry failure does not count as a placed decoration.

Omitting `ORIENT` makes a map a floating **minivault**, as in DCSS. An
explicit `ORIENT: float` makes it a regular vault instead. Give an ordinary
minivault a `DEPTH` rule and positive `WEIGHT` to enter the weighted depth
pool. A map with no `DEPTH` stays available to a controller by tag but will
not appear randomly on an unrelated floor. A `CHANCE` declaration selects
through the earlier chance stage, so it is not also weighted as an ordinary
minivault. `TAGS: extra` requests another minivault draw after selection;
source dummy maps can end the stage without placing cells. Numeric ranges
such as `DEPTH: 1-100` use absolute dungeon depth, while `D:4-` uses local
branch depth.

Use `PLACE: D:4` when a minivault belongs to one explicit floor rather than
the weighted `DEPTH` pool. `PLACE: D:$` targets the bottom of the Dungeon
branch, and comma-separated terms may include an exclusion such as
`PLACE: Swamp, !Swamp:$`. The generator makes one weighted `PLACE` choice
after the `CHANCE` stage and before ordinary minivault draws. It attempts
that map once, even if it has `TAGS: extra`; a successful map joins saved
`vault_ids` and blocks later use according to its uniqueness tags. A map
with an explicit `ORIENT` is a regular vault and does not enter this
minivault `PLACE` stage. Other branches' authored maps become active when
their branch generators are ported.

`serial_nicolae_subway` shows a compact controller pattern: its `.des` file
has a `CHANCE` rule and `vault.post_place` hook, while the hook's Lua module
requests three maps by a shared tag. Each station's `.des` file keeps its
`MARKER` destination names beside its MAP. Add a new station by giving it
the family tag and suitable marker destinations; the tagged selector will
discover it without a Go dispatch case. Marker records are saved now, while
transporter movement is a later gameplay slice.

The park family demonstrates nested `.des` maps. A parent declaration such
as `SUBVAULT: H : serial_park_minivault` reserves the `H` region for one
tagged helper. Put each helper in its own `.des` file with the shared tag;
the runtime filters by branch, depth, and layout and then makes a weighted
choice in stable ID order. The parent keeps the source's placement geometry
and receives the helper's terrain and typed effects at that region. The
source park file's `default-depth: D` is written as `DEPTH: D` in each
committed map because these files load independently.

The demonic and undead serials demonstrate a shared Lua setup hook. Each
child's `.des` declares its source tags and weight so the catalog can
select it; `: vault.run("configure")` then adds depth-dependent monster
requests and decorative records at the authored point in directive order.
For source `e.lua_marker` behavior, call `api:record(effects.MARKER, {
glyph = "S", identity = marker_text })` while `S` still exists. The engine
captures those cell positions immediately, so a later `SUBST: S = .` can
change the terrain without losing the marker. Import
`constants.vault_effects` where that record is made. The shared demonic
monster resolver also recognizes the source's `common demon` alias and
draws from the two appropriate demon tiers.

The gnoll camp demonstrates an ordered monster fallback in a `.des` map.
`KMONS: 3 = Grum, gnoll` requests Grum on glyph `3`; if he cannot spawn
because another Grum exists, the same cell gets a gnoll. Commas separate
ordered attempts, while slashes inside an attempt select a weighted
alternative. The original expression and selected attempt remain in the
typed vault record so saving and debugging can explain the result. Its
controller requests four to six pieces with the `serial_gnoll_camp` tag;
adding another tagged `.des` file makes it eligible without editing Go code.
For items, commas mean something different: `KITEM: D = stone q:2, potion of curing`
places both item slots on each `D` cell. A slash inside either
slot draws one alternative. A `:` keyed assignment shares those alternative
choices across matching cells while each cell still owns separate item
records and save origins.

The window serial separates a collection into small, common, and rare pools.
Its Lua controller requests a count from each pool by tag; every window piece
declares its pool and source weight in its own `.des` file. This lets a mod add
one window shape without changing the controller or a central file list.
The controller also requests the separate `serial_glass` pool. That request
currently places no maps because the source glass pieces from
`mini_features.des` are now committed as individual vaults. A map may live in
one source category while joining another controller through a shared tag.
The glass controller requests a common pool and, outside Dis, a rare pool.
Its three common column maps and six rare display maps all have source
`DEPTH` declarations, so they can also enter ordinary weighted minivault
selection. The `due_unseen_surprise` hook keeps its shallow loot case and
deeper unseen-horror alternatives in one readable Lua file. Source monster
specifiers such as `generate_awake` stay in typed records; adding a new
monster case should extend that shared parser rather than make a per-map
name special case.

The sigils family shows a source helper whose output is fixed for every
child map. Each committed `.des` definition carries its own shared tags and
three `TILE`/`FTILE` surface directives, so a new sigil needs only one map
file. The Lua controller stays small: it picks four to six weighted shapes
by the `serial_sigils` tag. Branch and depth restrictions remain visible in
the map file, and the selector filters them before drawing.

The ice family shows a shared Lua hook for behavior that changes by branch.
Each `.des` child calls `: vault.run("ice_setup.configure")` at the exact
point where its source setup applies. The module
`policy/generation/vaults/serial/ice_setup.lua` exposes the `configure`
function, so fifteen maps use one implementation without fifteen forwarding
files. A dotted hook name always resolves a module in the same policy
directory as its map; an undotted name still resolves a method on the
map's own module. The loader validates named methods when it loads the
catalog, so a typo fails with the map's path and line before a game starts.
The ice controller's `has_tag` check lets a layered mod add Ice Cave entry
maps later without changing this base Lua file or consuming a cave chance
draw while the pool is absent.

The forest family shows how a map can belong to a serial and still enter
ordinary minivault selection. Each child declares `DEPTH: D:1-4, Lair`,
the `serial_forest` tag, and four branch/depth `WEIGHT` clauses. Its
`forest_setup.configure` hook emits the vegetation and terrain rules;
the same authored MAP can therefore grow a denser tree mix in Lair. A new
forest piece needs one `.des` file with its own geometry and weight clauses.
The catalog keeps the exact source `NAME` as the stable ID, including the
capital `C` in `infiniplex_forest_clump_C`.

The research serial shows how ten maps can share a source Lua helper without
copying declarations into each `.des` file. Each map calls a named method of
`policy/generation/vaults/serial/research_setup.lua` at its authored hook
position. The method selects its spell school, then the common setup emits
the branch-sensitive caster pool and the `KITEM` request. Its two comma
slots create both a `randbook disc:<school> numspells:<count>` and a
`star_item` at each D glyph. `ident:type` on a vault item marks that placed
instance's type as known. A new themed room can reuse a method for an
existing school; a new school method belongs in the shared setup file.

The column ruins family demonstrates decorative serial pieces and
whole-level presentation. Its `serial_column_ruins.des` controller requests
pillar, portal, fancy, and simple tags from one named Lua post-place method.
The rare pillar mode calls `api:level_tiles(floor_tile, rock_tile)`, which
stores the selected tile names as a typed level record for save and later
rendering. A solid decorative child may declare `no_exits`; placement then
keeps its source terrain without making an artificial corridor. Each child
still needs only one `.des` file and a call to the shared
`column_ruins_setup.configure` hook where the original setup ran.

The aquarium family shows how one controller can share a temporary
generation choice across many independently selectable maps. Its
`serial_aquarium.lua` hook writes `AQUARIUM_POOL_SIZE` to the current
generation context, and each child reads it through `api:setting` in
`aquarium_setup.configure`. This value belongs to this level's generation;
it is not a process global or an ECS component on a live actor. Children
keep the source MAP and use `SUBVAULT` to place smaller bridge pieces.
The helper weights are written beside the bridge shape as
`aquarium_subvault_wall:3 / aquarium_subvault_window:2 / aquarium_subvault_balcony:1`.
To add a new aquarium piece, give its `.des` file the relevant group tag,
call the shared setup hook at the intended directive position, and keep
any local shape decisions in a named Lua hook. The same helper selects the
source ecology from branch and absolute depth. A merged slime's body count
is live actor state in `monster.slime_blob`; mods should attach that
component rather than add another monster catalog row for each size.

When a source vault needs a calculated directive, add
`policy/generation/vaults/<family>/<name>.lua` with a local `handler` object
and a named method. A `.des` line such as `: vault.run("configure")` calls
`handler.configure(api)`. The API can emit directives; see a bundled handler
and `constants.vault_directives` for the supported operations. The Lua module
is for the hook's decision, not a second copy of the map. The wizard's
`--kind=vault --with-hook` creates the matching pair.

The hook receives **`api`, not the game `ctx`**. It runs while a level is
being generated, before the ECS actors for that level exist. Read only the
captured branch, depth, character, and map facts offered below. Put a
random choice in the hook, but keep the vault's authored geometry and
ordinary placement directives in its `.des` file. Every hook method is
named in the `.des` file and assigned to the returned `handler` table:

For example, this shortened map excerpt reserves `?` for one passage.
An actual arrival vault also needs its required stairs and exits.
`SUBST` changes every occurrence of its source glyph, so use a dedicated
placeholder instead of a common terrain glyph such as `x`:

```text
NAME:    moss_passage
TAGS:    arrival
: vault.run("choose_passage")
MAP
xxxxxxx
x..?..x
xxxxxxx
ENDMAP
```

```lua
local directives = require("constants.vault_directives")

local handler = {}

-- Choose whether this reserved passage is open or has a door.
-- The emitted directive takes effect at this hook's place in the .des file.
local function choose_passage(api)
    if api:one_in(2) then
        api:emit(directives.SUBST, "? = .")
    else
        api:emit(directives.SUBST, "? = +")
    end
end

handler.choose_passage = choose_passage

return handler
```

Put `: vault.run("choose_passage")` in the `.des` declaration block, usually
before `MAP`, after any directives it depends on. Put the Lua handler at
`policy/generation/vaults/<family>/<NAME>.lua`; the map's family and `NAME`
select that module. No hook method is invoked merely because its Lua file
loads. `api:emit` inserts a typed DES directive at the hook's source
position; subsequent operations see that change. `api:record` instead
creates a typed placement record that can survive into level and save data.
Import record kinds from `constants.vault_effects` and inspect a bundled
handler such as `giann_forest_graveyard.lua` for its argument shape.

| `vault.run` hook call | Result |
| --- | --- |
| `api:roll(bound)` | Integer from `0` to `bound - 1` on the vault layout stream. |
| `api:one_in(bound)` | Boolean one-in-`bound` chance. |
| `api:coinflip()` | Boolean half chance. |
| `api:random_from(values)` | One element of a nonempty Lua array. |
| `api:random_range(first, last)` | Inclusive integer range. |
| `api:chance(numerator, denominator)` | Boolean fractional chance; certain or impossible cases use no draw. |
| `api:roll_dice(count, sides)` | Sum of `count` independent dice with `sides` faces. |
| `api:subset(values, count)` | `count` array elements selected without replacement. |
| `api:branch_id()`, `api:depth()` | Captured branch ID and local depth, when supplied. |
| `api:absolute_depth()` | Captured absolute depth, or local depth if supplied. |
| `api:depth_fraction()` | Local depth divided by branch bottom; requires both facts. |
| `api:map_tag()` | Captured placement tag, when supplied. |
| `api:player_species()`, `api:player_monster()` | Starting species ID and optional player monster identity. |
| `api:player_name()` | Character name, or `Player` if unavailable. |
| `api:game_started()`, `api:validating()` | Captured started and validation flags. Both are currently false. |
| `api:unique_generated(name)` | Whether supplied unique item history contains this name. |
| `api:random_name()` | Generated name from the layout stream. |
| `api:emit(directive, argument)` | Queue a DES directive; import its kind from `constants.vault_directives`. |
| `api:record(kind, arguments)` | Queue a typed placement effect; import its kind from `constants.vault_effects`. |

Use positive random bounds, nonempty arrays for `random_from`, and a
`subset` count no greater than the array length. Hook randomness uses the
vault layout stream; never call `math.random` or cache random results at
module load. The hook methods receive one ephemeral API per invocation,
just as a gameplay rule receives an ephemeral `ctx`.

The current playable D:1–15 generation supplies species and name, but no
player monster identity or unique item history. Therefore
`api:player_monster()` is `nil`, `api:unique_generated(name)` is `false`,
and `api:game_started()` is `false` in that path. Treat these as optional
facts until a game mode supplies them explicitly. Arrival hooks also lack
captured branch, depth, branch bottom, and map tag: their branch/depth/tag
readers return `nil`, while `api:depth_fraction()` raises an error. Extra
vault and shop hooks receive branch and depth facts; a tagged child shop
also receives its selected map tag. Use a fact only in the hook family
that supplies it.

For source maps that use `: vault.veto("method")`, the named method runs
after placement. For an extra map, returning true rejects that selection
and restores its terrain so other selections can continue. An arrival veto
rejects the generated layout. Its API has
`api:marker_positions(property, value)`, returning `{ x, y }` points whose
raw marker identity contains `property=value`, or `nil`. This is a substring
search, not parsed property equality. `api:has_exit(point)` reports whether
the point is one of the placed exits. During the earlier generation hook,
those two calls are placeholders: marker positions do not exist yet, and
exit checks are deferred. Use them in veto methods, as
`dpeg_arrival_water_fire.lua` does. A CHANCE map can declare
`: vault.post_place("method_name")` in its `.des` file and implement that
method in `policy/generation/vaults/<family>/<name>.lua`. The method receives
`api:roll(bound)`, `api:chance(numerator, denominator)`, `api:one_in(bound)`,
`api:random_range(first, last)`, `api:absolute_depth()`, and
`api:place_maps(tag, count)`. The last method chooses and places tagged child
maps through the same catalog and geometric path as other extras. A
controller with an empty MAP still enters the saved vault history before its
hook runs; this lets its name and uniqueness tags constrain later floors.
`serial_shops` is one example, not a special dispatcher. Ordinary arrival
and shop hooks use their own API facts and do not receive `place_maps`.

Pan unique veto hooks can also call `api:unique_seen(monster_id)`,
`api:has_rune(rune_item_id)`, `api:pan_rune_count()`,
`api:pan_unique_state(monster_id)`,
`api:set_pan_unique_state(monster_id, decision)`, and `api:roll(bound)`.
The first two read saved player components. `pan_rune_count` counts the
four Pan runes, and Ignacio's decision is stored once across later levels.
Import rune item IDs from `constants.runes` and decision values from
`constants.pan_unique_decision`; do not retype their strings in a hook.
Rune pickup removes its floor entity and records its ID in
`character.runes` for save/restore and future branch checks.

Most named monsters keep a claimed ID for the whole run, including after
death. Boris and Natasha are source exceptions. Boris's death records a
saved kill flag and frees his active claim; a newly generated Depths,
Vaults, Tomb, or Crypt floor then offers one replacement chance in six.
Natasha's first two deaths free and immediately reclaim her ID by placing
a new body on distant clear floor. The new actor keeps her item entities
and a `monster.unique_revival` count. Her third death keeps the claim.
These life rules live in Lua death and population policies; a new modded
unique can add its own death hook without changing monster creation.

Intrinsic monster death effects register a focused Lua death hook. The
Ball Lightning and Fulminant Prism hooks call the same blast policy as
their active turns, so a lethal hit and a construct timeout resolve the
same saved charge state. Bloated Husk and Bennu use damage blasts;
Lurking Horror invokes the shared Torment area policy. A reborn Bennu
gets `monster.bennu_revival` with `revives = 1`, which the save validator
checks before allowing the extra actor outside the level's roster budget.
Modded death effects should keep the source actor's final position as an
explicit hook argument because the actor has left the occupancy grid.

Clouds left by dead fire vortices, simulacra, and chaos spawn live in
`policy.combat.monster_death_clouds`. That policy also handles ordinary
summon smoke and source exceptions such as shadow summons. Its `leave`
function receives the same final position on lethal death; `before_expiry`
runs before the shared summon owner removes a timed-out actor. If a new
monster needs a different death cloud, add its species rule there and use
an ID imported from `ids.clouds`. Keep the cloud in the shared placement
owner so terrain, wind, attribution, save, and spread rules still apply.

Monster definitions may declare a `band` with `min`, `max`, and `slots`.
`policy.population.bands` creates the followers and attaches `core.follower`
links plus a durable `monster.band_origin` with the leader and member kinds.
The link ends on leader death or cross-floor movement; the origin remains
so save validation can recognize the surviving actor. Validation checks
members against the leader definition instead of a second monster list.
A band can also name an `origin_component` when later rules must
distinguish its members from ordinary monsters of the same kind.
Pikel's lemures use `monster.pikel_band`: his death or banishment dismisses
marked members across loaded floors, while unrelated lemures remain. An
ordinary leader's death removes its followers' links and leaves them alive.

Generated levels save `vault_ids` in successful placement order, including
an arrival, an empty-map controller, and any child maps it placed. The
single `vault_id` still names the level's primary map for existing level
metadata and vault records. When the next floor is built, Lua reads the saved
ID list through `policy.generation.vaults.used` and looks up tags in the
effective catalog. A map without `allow_dup` cannot repeat during the
run. `luniq` blocks that map again on its current floor even with
`allow_dup`; maps sharing `luniq_*` block one another there. `uniq_*`
groups stay blocked across floors. Failed placement attempts do not
record an ID or consume a uniqueness tag. Keep these tags in the `.des`
definition; do not copy their meaning into a separate mod registry.

### Add a named unique encounter

Put each encounter in its own `vaults/unique/<name>.des` file. The file's
`NAME` must be unique in the effective catalog. A simple named monster
uses the same source map syntax as any other vault:

```text
NAME: uniq_example
DEPTH: D:4-7
TAGS: place_unique transparent overwrite_floor_cell no_exits
MONS: Example
MAP
1
ENDMAP
```

The `1` is the monster slot, not a new terrain type. The
`overwrite_floor_cell` tag asks placement to put this one-cell map on an
existing floor. The `place_unique` tag admits it to the named-encounter
draw after ordinary secondary vaults. Branch, depth, weight, and chance
still come from the same `.des` rules as other vaults. A mod can replace
one bundled definition by supplying the same relative path in a higher
VFS layer, or add a new file with a new `NAME`.

The monster definition should carry the `M_UNIQUE` flag. The player owns a
saved `character.unique_history` component whose `monsters` map records
kind IDs that have already appeared in the run. Once a unique has spawned,
its claim remains after death or travel, so a later vault cannot create a
second copy. Use a named `: vault.run` or `: vault.veto` Lua hook for
conditional source rules; keep the map geometry and ordinary directives in
the `.des` file. Import IDs from `ids.monsters` and other shared ID modules
inside the hook instead of repeating names as strings.

For a unique with followers, put the band on the monster's own definition:

```lua
local monsters = require("ids.monsters")

band = {
    min = 2,
    max = 4,
    slots = {
        {
            monsters.MONS_EXAMPLE_FOLLOWER,
        },
    },
},
```

`min` and `max` count followers, not the leader. Each inner `slots` list is
one follower position; the final slot repeats if the band is larger. A
slot can have weighted choices, with each choice's `id` and `weight` on
separate lines. The content validator checks that every
follower names an active monster. The generic Lua band policy chooses legal
nearby cells, creates ordinary ECS actors, and gives each a saved follower
link. The `.des` request must say `MONS: Example band` to request the band
for an authored vault. Ambient monster placement uses the same definition
when it chooses that leader. Exceptional member rules can be placed in a
named Lua `member_policy` module; Tiamat's draconians are the bundled example.

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
launch `go run ./cmd/crawl --mod-dir=/path/to/my-mod` to catch startup
registration and validation errors; when contributing a rule to this repo,
put its Lua test in that fixture tree and run
`go test ./internal/script -run TestLuaRules`. Run
`go test ./internal/script ./internal/game` after changing engine behavior,
and `go test ./...` at a broader category boundary. Content definitions and
population rows need no `source_order`. When a definition contains multiple
ordered choices, keep that order inside the owning file and explain why it
matters there.

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

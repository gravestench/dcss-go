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
| Change run, rest, or explore behavior | [Automatic movement](#automatic-movement) |

The [root README](../README.md) has the shortest launch and wizard examples.
This guide explains the contracts those examples depend on. If a mechanic
already exists, start with a nearby bundled file and follow its registration
and caller. The examples here show how to do that; they are not a promise that
every DCSS mechanic has already been ported.

If this is your first mod, read [what `ctx` is](#ctx-in-one-minute), then
[follow a rule from entry to state change](#follow-one-rule-from-entry-to-state-change).
Those two sections explain when Lua runs and where changing game state lives.

### Generated names

`policy/names/source.lua` owns Crawl's generated-word spelling. Its
`from_seed(ctx, seed, mode)` method takes an unsigned 32-bit seed and one
mode from `constants.name_modes`: `ORDINARY`, `SCROLL`, or `JIYVA`.
`generate(ctx, stream, mode)` first draws a seed from the named, saved
gameplay stream, then calls `from_seed`. Use `generate` when the caller
does not already own a seed; use `from_seed` to replay one already stored.
The caller must save the finished name or seed. For example:

```lua
local modes = require("constants.name_modes")
local names = require("policy.names.source")
local streams = require("constants.rng_streams")

local owner_name = names.generate(ctx, streams.PAN_LORD,
    modes.ORDINARY)
```

Spelling uses `ctx:subgenerator(seed)`, a temporary PCG object seeded
from the run seed and the supplied name seed. Its `:random(bound)` method
returns a zero-based bounded draw. It does not advance the named gameplay
stream, and its cursor is not saved. Keep that object local to one rule
call; save the outcome, not the object. Scroll appearance indices are
packed into the source's two 0–150 seed bytes and class byte by
`policy/items/appearances.lua`, using `constants.name_seeds`. Jiyva's
second name is rolled at character creation, saved on the player as
`character.jiyva_second_name`, and displayed when the character worships
Jiyva. Vault hooks expose `api:random_name()` for the ordinary mode; they
draw a seed from the layout builder before private spelling. Ordinary shops
store two keeper bytes as `keeper_seed` and pass that seed to `from_seed`;
an explicit DES shop owner takes precedence. Artefact and book fallbacks
draw a fresh seed from `ITEM_GENERATION` for each generated word.

To change all generated spelling, replace only
`policy/names/source.lua` at that relative path in your mod directory.
Keep both public methods and the three modes so scrolls, vault hooks, Pan
lords, shops, and item fallback names remain usable. The
[sparse override example](../internal/script/testdata/generated-name-mod/policy/names/source.lua)
shows the smallest working replacement. To alter one caller's naming
policy instead, override that caller's Lua file and import the shared
name owner there.

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

### Automatic movement

`policy/input/automation.lua` owns shift-run, long rest (`5`), and
autoexplore (`o`). `policy/input/play.lua` delegates those keys to it. The
terminal calls the registered `terminal.automation` policy once to start
and once per repeated action; it then sends each chosen move or wait through
the same game command path used by a manually pressed key. A key interrupts
the repetition before the next action. This state lasts only in the terminal,
so a save does not resume a half-finished route.

The policy receives an `input` table with `phase`, current `state`, and a
`view` made from the player's *observed* map. Cells are row-major and have
`feature`, `state` (0 unknown, 1 remembered, 2 visible), and `walkable`;
unknown cells reveal neither feature nor collision. The view also gives
player position and HP/MP, recovery and dangerous-terrain capabilities,
visible entities with hostility, and visible clouds. This callback has no
live game `ctx`: choose a next command from the supplied snapshot and let
the game execute it. For a mechanic that needs live ECS state, add a separate
read-only presentation policy, as `presentation.automation_capabilities`
does, and project its answer into the observed view. This keeps routing
rules from reading hidden terrain or mutating actors during a timer callback.

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
| God | `content/gods/<name>.lua` | It needs a focused join, leave, or piety behavior rule. |
| Ru sacrifice | `content/ru_sacrifices/<name>.lua` | It needs a price, offer, or acceptance policy. |
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

### Give a monster a natural band

Put a `band` table in that monster's own `content/monsters/<name>.lua` file.
`min` and `max` count **followers**, not the leader. `slots` is a list of
follower pools: each pool contains monster IDs or `{ id, weight }` entries.
The last pool repeats for any remaining followers. Import bundled IDs from
`ids.monsters` where the definition uses them. For example:

```lua
local monsters = require("ids.monsters")

definition.band = {
    min = 2,
    max = 4,
    slots = {
        {
            { id = monsters.MONS_GNOLL, weight = 3 },
            { id = monsters.MONS_GNOLL_SERGEANT, weight = 1 },
        },
    },
}
```

Use `chance_denominator = 3` for a one-in-three leader chance and
`min_depth` for the source absolute-depth gate. For branch-dependent
eligibility, name a function in
`policy/population/bands/conditions.lua` with `condition`; for a special
follower draw, name a module exporting `choose(ctx, level, index, profile)`
with `member_policy`. Give that module an `allows(kind_id)` method so saved
followers remain valid after restore. See the Naga and draconian policies
for examples. The ordinary population owner and god-sourced wrath both
read this same band declaration. God-sourced followers keep the god's
saved identity, while ambient followers remain ordinary monsters.

For a god, import `constants.catalog`, `constants.gods` for bundled IDs,
and `constants.god_piety_modes`. A new god can declare its own stable ID in
its definition file. Define `name`, `starting_piety`, `piety_mode`, and
`temple_eligible`; add `good`, `rejects_innate_caster`, `requires_orc`, or
`requires_love` only when the restriction applies. The effective god
catalog supplies Temple membership and display names through
`policy.religion.names`. The special `GOD_NO_GOD` and `GOD_ECUMENICAL` IDs
are engine sentinels, not god definitions. A same-path mod file replaces a
bundled god's facts; a new path adds a god without editing a central list.
Set `piety_decay_chance` only when this god loses one ordinary piety point
on a periodic one-in-N check. For example, `piety_decay_chance = 17` means
one chance in seventeen; omit the field for gods whose devotion has another
owner, such as Ru's sacrifices or Uskayaw's combat momentum. Ashenzari and
Ru set `god_time_zero_check = true`: their periodic check expels a character
already at zero devotion without rolling random decay. Other alternative
gods return from the source god-time handler before that zero check.
Set `time_module` to a Lua module with `at_god_time(ctx, player)` when a god
has another periodic rule. Ru uses this hook to turn saved sacrifice
progress into offers. The shared clock invokes it after the zero-piety
check and before scheduling the next deadline.

Ru's bundled sacrifices live in `content/ru_sacrifices/`, one file per
definition. A definition declares an ID from `ids.ru_sacrifices`, a `name`,
the source `sacrifice_text` and `milestone_text`, `base_piety`, and either a
`mutation_id` or a `variant_pool` from `constants.ru_variant_pools`.
Optional `skill_id` names a trained skill whose current value affects offer
selection and later acceptance. `offer_rule_module` may name a Lua module
with `eligible(ctx, player)` for a condition specific to that sacrifice.
`price_module` may name a Lua module with
`adjust(ctx, player, selected, amount)` to change its base quote. The
selected argument is a list of mutation IDs; the returned amount is before
Ru's small random blur. Keep such rules in separate commented Lua files so
one declaration stays easy to read.

When Ru's saved progress meets its delay at god time, the offer owner reads
effective definitions in stable ID order, checks eligibility, rolls
variable mutations, and saves three distinct IDs with their selected
mutations and quoted piety in the `religion.ru` component. Inspecting an
outstanding offer does not reroll it. The UI and acceptance path are still
being ported; adding a declaration now makes it eligible for the saved
offer set, but does not yet make a new sacrifice actionable.

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

An `active` system sees both player and monster actions. Its `actor`
argument is the one acting now; `ctx:player()` identifies the separate
player owner. A monster action can still award player XP or defensive
practice. `systems/character_training.lua` and
`systems/character_advancement.lua` therefore reconcile that player's
state after `actor.death` on either kind of action. A player-time effect
such as `systems/religion_jiyva_ecology.lua` instead checks
`actor == ctx:player()` so each monster action does not advance its timer.

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
| `ctx:level_ids()` | Sorted IDs of already created levels. Read inactive floors without generating them. |
| `ctx:level_size(level_id)` | `width, height`, or `nil, nil` for a missing level. |
| `ctx:level_branch(level_id)` | Branch ID, or `nil` for a missing level. |
| `ctx:level_depth(level_id)` | Local branch depth, or `nil` for a missing level. |
| `ctx:marker_property(level_id, x, y, key)` | A placed vault marker's named string property, or `nil`. |
| `ctx:shoals_height(level_id, x, y)` | Authored Shoals elevation, or `nil` when absent. Water changes do not alter it. |
| `ctx:shoals_tide_clock(level_id)` | Raw height, velocity, and last update aut; three `nil` values if absent. |
| `ctx:set_shoals_tide_clock(level_id, height, velocity, last_aut)` | Save an advanced Shoals tide clock. |
| `ctx:cell(level_id, x, y)` | Terrain ID at the cell, or `nil` when missing. Includes staged terrain changes. |
| `ctx:remembered(level_id, x, y)` | Terrain ID in the player's saved map memory, or `nil` when unexplored. |
| `ctx:records_at(level_id, x, y)` | Fresh array of saved vault records at the cell, or an empty array. Each record has `kind`, `source_id`, `identity`, `x`, `y`, `pending`, `overridden`, and typed `arguments`. |
| `ctx:walkable(level_id, x, y)` | Whether an actor can walk on the current or staged terrain. |
| `ctx:actor_at(level_id, x, y)` | Primary actor handle, or `nil`; includes staged moves. The player is primary when sharing a cell. |
| `ctx:actors_at(level_id, x, y)` | Fresh ordered array of all actor handles at that cell, including staged placements and removals. |
| `ctx:stair_at(level_id, x, y)` | Link `{ to_level_id, to_x, to_y, unavailable }`, or `nil`. |
| `ctx:visible(level_id, from_x, from_y, radius, target_x, target_y)` | Ordinary sight. |
| `ctx:visible_no_trans(level_id, from_x, from_y, radius, target_x, target_y)` | Clear walls block; actors do not. |
| `ctx:visible_no_trans_with_blocked(level_id, from_x, from_y, radius, target_x, target_y, cells)` | Test sight with an array of extra `{ x, y }` opaque cells; the grid is unchanged. |
| `ctx:visible_cells(level_id, from_x, from_y, radius)` | Array of visible `{ x, y }` cells. |
| `ctx:route_step(level_id, from_x, from_y, to_x, to_y, goal)` | `dx, dy, found`; no route gives `nil, nil, false`. |
| `ctx:projectile_clear(level_id, from_x, from_y, to_x, to_y)` | Physical ray; actors block. |
| `ctx:set_cell(level_id, x, y, terrain_id)` | Stage a terrain change. It cannot block an actor or erase a stair link. |
| `ctx:set_cell_colour(level_id, x, y, colour_id)` | Stage a named terrain tint; the level saves it and the terminal uses it while the cell is visible. |
| `ctx:map_cell(level_id, x, y)` | Mark an unseen cell in map memory; `true` if newly mapped, `false` if known. |
| `ctx:place_actor(entity, level_id, x, y)` | Put an unpositioned actor on a valid, unoccupied cell. |
| `ctx:move_actor(entity, level_id, x, y)` | Move a positioned actor to a valid, unoccupied cell. |

`records_at` exposes source placement facts without giving a mod a mutable
reference to the level. For example, an altar record's `arguments.god_id`
identifies its assigned god even when its terrain is the generic altar cell.
Changing a returned table does not change the level or a later query.
Overridden source records are omitted; generated Temple assignments remain
available after save and restore. Interpret each record in Lua policy rather
than branching on its identity in Go.
| `ctx:remove_actor(entity, level_id)` | Remove a positioned actor from that level's spatial index. |
| `ctx:move_actors(moves)` | Atomically stage simultaneous moves; see the shape below. |

An optional final `true` on `place_actor` or `move_actor` explicitly permits
sharing a cell. Placement appends the new actor behind the existing primary;
movement makes the mover primary. The grid checks positions and terrain but
does not grant the gameplay permission. A Lua policy must inspect
`ctx:actors_at`, the actors' live components, and the relevant content
traits before requesting sharing. Fedhas' implementation is in
`policy.religion.fedhas.pass_through`; its saved-cell validator accepts
only a player and one eligible stationary plant. A mod that adds a new
sharing rule must also extend that validator so its saves can be restored.

Fedhas' shoot-through passive is separate from cell sharing. The Lua policy
`policy.religion.fedhas.protection` reads the target monster's `MH_PLANT`
holiness, the source actor's live allegiance, and the player's current
worship and penance. A mobile plant can be protected from a friendly shot
even though it cannot be walked through. For example, a modded friendly
vine with `holiness = { "MH_PLANT" }` needs no special projectile flag:
the player and allied monster rays skip its contact, and player-side
clouds spare it. A friendly monster caster must have `ATT_FRIENDLY`:
good-neutral casters do not qualify. Area rays continue past sheltered
plants before choosing their burst cell. Harmful cloud placement checks
the live source actor and allows a cloud if the plant is already immune;
later exposure checks the cloud's saved `kill_category` (`KC_YOU` or
`KC_FRIENDLY`), which remains meaningful after its source dies. A modded
effect that resolves contact outside the shared projectile, beam, blast,
and cloud owners should consult `protection.ignores` before rolling a ray
hit, or `protection.ignores_cloud` for saved cloud exposure.

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
| `register.frozen()` | Return whether startup registration is closed; derived catalog views may be cached after this becomes true. |
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
- **XP evoker:** Miscellaneous item definition in `content/items/` with an
  `evoker` record, and a matching effect in `policy/inventory/evokers/`.
  Inspect `policy.inventory.evokers.effects` for registration and
  `policy.inventory.evokers` for charge and command rules.
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
- **XP evoker:** optional `prepare(ctx, player, dx, dy, forced)` returns a
  refusal string, a `{ confirmation = "..." }` table, or `nil` to proceed.
  `resolve(ctx, player, chosen, aut)` returns a table containing `charge`
  and `practice`. The shared owner adds XP debt only when `charge` is true.
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
| God | `content/gods/` | `content/validation.lua`, `policy/religion/eligibility.lua`, and optional `policy/religion/gods/<name>.lua` |
| Monster or spellbook | `content/monsters/`, `content/monster_spellbooks/` | [`monster.go`](../internal/content/monster.go), [`monster_spellbook.go`](../internal/content/monster_spellbook.go) |
| Monster beam profile | `content/monster_beams/` | A nearby beam definition and `policy/combat/monster_beams.lua` for its resolution path |
| Item, weapon, or artefact | `content/items/`, `content/artefacts/` | [`item.go`](../internal/content/item.go), the relevant Lua policy under `policy/inventory/` or `policy/item_generation/` |
| Player spell | `content/spells/` | [`spell.go`](../internal/content/spell.go), then its effect registry under `policy/magic/effects/` |
| Branch | `content/branches/` | [`branch.go`](../internal/content/branch.go) and the generation policy that consumes its fields |
| Mutation | `content/mutations/` | Its nearby Lua definition and `policy/mutations/effects/registry.lua` for any new capability |
| Cloud, trap, or shop | `content/clouds/`, `content/traps/`, `content/shops/` | Their Lua `policy/<category>/catalog.lua` and effect or stock policy |

### Add an XP evoker

Create `content/items/<name>.lua` in your mod layer and declare a
miscellaneous item with an `evoker` record. The record needs positive
integer `charge_debt` and `max_charges`, plus `aimed = true` if the player
must choose a cell. The bundled `misc_phial_of_floods.lua` is an aimed
example; `misc_condenser_vane.lua` chooses targets automatically. Put the
new item ID in your mod's constants or ID module, then import it at every
use site. A same-path overlay replaces a bundled definition; a new path
adds a new item.

Create `policy/inventory/evokers/<name>.lua` with a local effect table.
Import `policy.inventory.evokers.effects` and call
`effects.add(item_id, effect)` once before returning the table. The game
loads the effective tree and checks that every evoker item has a resolver.
`prepare(ctx, player, dx, dy, forced)` is optional. Return a string to
refuse freely, `{ confirmation = "..." }` to ask the player, or `nil` to
begin the ten-aut action. A confirmation repeats preparation with
`forced = true`; use that flag only to bypass the question, not the other
eligibility checks. If `aimed = true`, the shared command opens the aim
screen and passes the chosen relative `dx` and `dy`.

`resolve(ctx, player, chosen, aut)` implements the committed effect.
`chosen` includes `item_id`, `dx`, and `dy`. Return
`{ charge = true, practice = 1 }` to spend one XP charge and offer one
Evocations practice signal. Return `charge = false` when placement failed
and the source item keeps its charge. The player still spent the action
time. The shared `policy.inventory.evokers` owner stores debt on the
player's `character.xp_evokers` component, so two carried copies of one
subtype display and spend the same charge pool. Credited monster XP
reduces debt only while that subtype is carried; neither an item file nor
an effect should edit debt directly.

Use ordinary cloud, summon, terrain, damage, and monster status owners for
the effect's consequences. Add a schema and an active-floor system for a
new lasting state; the phial's Waterlogged status is an example. Give new
random choices a named RNG stream under `constants/rng_streams.lua` or
reuse `EVOKER` for evoker behavior. Test preflight, charge timing, the
effect on a real actor, and save/restore of any lasting state. The
`xp_evoker` Lua and game tests show the actual command contract.

### God eligibility and piety

The god file owns fixed facts. `policy/religion/eligibility.lua` reads that
resolved definition with the player's live species, mutations, and form.
Call `eligibility.check(ctx, player, god_id, true)` to learn whether the
player can join *now*; `false` ignores temporary form and fee barriers when
asking whether joining could ever be possible. The return value is `nil`
when allowed or a reason string when refused. A god with an exceptional
check can name a `behavior_module`; Gozag's module demonstrates a fee check
that reads the wallet's saved `generated_gold`, which counts floor gold when
a non-Abyss level is first populated. Carried `gold` and `generated_gold`
are deliberately different.

`policy/religion/piety.lua` owns `gain(ctx, player, numerator, denominator,
scale)` and `lose(ctx, player, points)`. The source order repays penance,
handles gift timeout and upper-rank taper, then applies hysteresis and
changes the saved `religion.worship` component. `scale` applies an equipped
amulet of Faith before the final random division. `rank(god_id, points)`
returns the displayed rank; `breakpoint(stars)` accepts one through six.
The owner emits `constants.religion_signals.RANK_CHANGED` and `GIFT_CHECK`
with the player and god IDs. Mod systems can observe those signals for divine
abilities and passives. On each eligible piety candidate, it also asks the
current god's optional `gift_module` to act; altar prayer uses the same
worship owner.

#### Ru sacrifices

Add a file under `content/ru_sacrifices/` to register another Ru offer.
Copy a nearby definition such as `health.lua` or `hand.lua` and give it a
unique stable `id`, a menu `name`, `sacrifice_text`, `milestone_text`, and
`base_piety`. A fixed choice names `mutation_id`; a variable choice names
one of the supported `constants.ru_variant_pools` keys. Import mutation
IDs from `ids.mutations` and register under
`constants.catalog.RU_SACRIFICES`. The file is discovered automatically;
the ability menu also registers each resolved definition automatically.

The `religion.ru` component owns the waiting clock, three offered IDs,
chosen mutation variants, and their quoted prices. God time creates the
whole set once. Looking at the ability menu and declining confirmation
does not reroll it or spend a turn. A confirmed choice grants its lasting
mutation, adds the saved quote plus the current value of any named
`skill_id`, caps Ru piety at six stars, and resets the clock. Rejection
clears the set and lengthens the next wait. These operations live in
`policy/religion/ru/offers.lua`, `resolution.lua`, and
`policy/abilities/ru/sacrifices.lua`.

The same saved component keeps `sacrifice_mutations`, a lifetime count of
mutation grants from accepted Ru choices. An ordinary acceptance adds one;
Arcana adds three even though it is one menu choice. Rejection, rejoining
Ru, and new offer generation preserve the count. Demonspawn silver damage
reads this history from `policy/combat/monster_missile_egos/silver.lua`. The pinned
DCSS source subtracts Ru's count inside its scan of mutation types, so a
positive count suppresses the mutation-based silver bonus for a
Demonspawn; the ordinary minimum silver fragment still applies. A mod
that changes sacrifice acceptance should update the count after applying
all selected mutations and keep it in the player-owned component.

For an exception, add a focused module and name it with
`offer_rule_module`, `price_module`, or `accept_module` on your definition.
The offer module exports `eligible(ctx, player)`; the price module exports
`adjust(ctx, player, selected, amount)`; an acceptance module exports
`apply(ctx, player, previous)` and may export `before(ctx, player)` to
capture state before permanent mutation changes the character. Missing
Hand uses that last hook to compare the old and new magical-power ring
bonus. Store lasting effects in ECS components; module variables are not
saved. Test the rule in a `_test.lua` file with the production catalog and
schemas, including confirmation cancellation and save/restore when you add
new state.

#### Ru active powers

Ru's three command policies live under `policy/abilities/ru/`. Each file
registers one stable ability ID and exports named `available`, `prepare`,
and `resolve` functions. A mod can replace a file at the same relative path
to change its policy. The ability registry supplies the terminal menu and
the normal paid intent; the policy must reject a canceled or impossible
target in `prepare` before time or RNG is spent.

`constants.ru_powers` names the source ranks, costs, durations, and damage
divisors. The `character.exhaustion` component stores the shared cooldown
in aut; `policy.character.exhaustion` checks and ages it. Continuing monster
effects use the existing saved Slow, Paralysis, and Enfeeble components.
Draw Out Power and Apocalypse use the player drain owner for their temporary
maximum-HP cost. A new power should reuse these owners so saves and other
abilities see one authoritative status rather than a private timer.

#### Ru damage retaliation

The two-star Ru passive lives in `policy/religion/ru/retaliation.lua`.
`policy.combat.player_health` registers it with the shared after-HP
reaction list, so ordinary monster melee, ranged attacks, and spells all
reach the same rule after their actual HP loss is known. It reads current
worship and penance; no passive flag is stored on the player. The chance
roll precedes source validation, and the effect strength uses the
monster's current HD. Antimagic, Paralysis, Slow, Blind, and Corona are
written through their existing monster status owners.

To change this passive in a mod, replace its Lua policy at the same
relative path. Keep `retaliation.register()` connected to the shared
reaction owner and preserve a stable reaction ID and order. When adding a
new status branch, put its duration and save behavior in that status's
owner; the Ru policy should choose the effect and supply its rolled
duration. Test the modified policy in a `_test.lua` file against the
production monster catalog and component schemas.

#### Ru attack interference

The one-star passive is in `policy/religion/ru/interference.lua`. Melee,
thrown and launched missiles, and book spells ask it for a decision just
before the attack. It reads live worship, penance, monster allegiance,
visibility, and submerged state. The policy draws from the named religion
RNG stream in source order: block first, then a chance to redirect. The
selected monster may be the attacker itself. A blocked spell still uses a
spell intent, so the ordinary scheduler charges its spell energy.

The `combat.forced_target` component is temporary. It lets the shared
target predicate accept the one monster Ru picked, even if caster and
victim normally belong to the same side. Attack systems remove it after
resolving; spell choice removes it if no targetable spell is found. A mod
that changes this policy should keep that action scope and use the same
monster combat, projectile, and spell owners for the redirected action.
For example, to change Ru's interference odds, replace
`policy/religion/ru/interference.lua` in a mod layer and adjust the draws
inside `choose`; do not change generic Go intent or energy code.

#### Divine gifts

Set `gift_module = "policy.religion.gifts.<name>"` in a god definition to
add a Lua gift rule. The module exports `check(ctx, player, worship)`, which
returns `true` when it grants a gift. It may also export `offering`, `accept`,
and `leave` for temporary access. `policy/religion/gifts.lua` resolves that
module from the effective layered god definition, checks penance and gift
timeout, and owns per-god current and lifetime counters. A successful rule
calls `gifts.record(ctx, player, timeout)` once. The rule itself chooses its
content and uses the religion RNG stream; it should never duplicate the
common piety algorithm.

For permanent spell knowledge, load
`require("policy.character.spell_records")` and call
`records.grant_library(ctx, player, spell_ids)`.
Kikubaaqudgha demonstrates two one-time sets. Vehumet demonstrates an
offer: its `religion.vehumet` component stores current spell IDs, prior
offers, and the next replacement time. `records.offer` tags a normal
`character.spell` record so the spell appears in the memorisation menu.
Completing memorisation makes it permanent library knowledge and calls the
god's `accept`; leaving clears temporary access. Keep the player's saved
component as the authority when adding a new gift type. A modded god can
provide an entirely new gift module and component without editing this
shared dispatcher.

For a physical gift, call
`policy.religion.gifts.items.grant(ctx, player, class_id, god_id)` after
your god's own piety check. It returns the new ECS item or `nil` when the
player's floor cannot hold the gift or acquisition has no usable result.
The helper uses direct acquirement, places the item at the player's feet,
and stores `item.provenance` with `purpose = "god_gift"` and the god ID.
The item request uses `constants.vault_item_quality.GIFT`, which maps to
DCSS's divine gift level. It has different brand and unique-item odds from
the `GOOD` quality used for acquirement scrolls.
Only then call `gifts.record(ctx, player, timeout)`. Sif Muna's module
shows how to count spells in the actual generated book for its timeout;
Trog and Okawaru use `policy.religion.gifts.martial` for their shared
equipment gate while keeping each god's class choice in its own file.
If a mod needs a new gift class, extend the class picker in
`policy/scrolls/acquirement_offers.lua` and its focused subtype policy.

Jiyva's `policy.religion.gifts.jiyva` shows a nonitem gift: it iterates
saved acquired mutation ranks in `data.mutation_enum` order, then uses
`policy.mutations.selection` and `policy.mutations.transition` for new
good or slime mutations. Call `gifts.record` only after a mutation level
was added or removed. A god gift should pass `true` to
`transition.grant_after_protection` so the existing conflict owner
resolves opposing mutations with source divine priority.

Nemelex keeps deck counts and an ordered stack on the player's
`religion.nemelex_decks` component. The gift rule deals counts, then
`policy.religion.cards.state` validates each saved card ID against the
effective `cards` catalog. To add a card, add a file in `content/cards/`
that registers one definition with an ID from `ids.cards` (or a new ID
in the mod's own `ids` module), a display name, an effect module, and
positive integer `deck_weights` keyed by `ids.decks`. Import the new ID
in both the definition and its effect module. The named effect module
exports `apply(ctx, player, request)` and returns an optional prompt.
`ctx` is the same live game context described in
[the context reference](#the-game-context-ctx); the player is an ECS entity,
not a second mutable player table. Weighted selection
traverses the effective card catalog by stable ID, independent of filename
or mod layer load order. Save restore reports a missing mod card ID rather
than replacing a previously sampled card.

The four Lua ability owners implement Draw, Triple Draw, Deal Four, and
Stack Five. They save sampled IDs and the current choice phase on that
same player component before asking the terminal for another input.
The Go client renders the returned selection or confirmation; it does
not choose a card or roll an effect. A drawn card is already spent while
the player aims it. Cancelling aim asks whether to waste that card;
declining the warning returns to the same aim with the same saved tier.
This is why an effect must not sample a second card or reroll its tier.

An effect receives `request.power`, the source Nemelex power calculated
once for the play, and `request.tier` when its module sets `uses_tier = true`.
The tier is an integer from zero through two. It also receives `dealt`,
`punishment`, `dx`, `dy`, `target_id`, and `target_phase` when relevant.
For aimed effects, `policy.religion.cards.effects.targeted.aim` returns
the chosen direction or a `selection` prompt. Check `target_phase` before
applying any pre-aim effect that must happen only once, as Vitriol does.
Use `constants.rng_streams.CARDS` for card-owned draws; pass that stream to
shared status and summon policies when they support it. A new card that
needs a durable timer or actor should write a registered ECS component
through the existing world, combat, or magic owner rather than retaining
state in a Lua module variable.

`systems/religion_upkeep.lua` advances the player-owned god-time clock after
timed actions. The first check is at 200 aut; later checks are 100–300 aut
apart. The saved `religion.worship.next_god_time_aut` belongs to the player,
so changing gods cannot reroll the next check. At each check the current
god's `piety_decay_chance` controls a one-point loss through the normal
hysteresis rule. A mod god can choose its rate in its own definition file;
no scheduler edit is needed. Example: with `piety_decay_chance = 35`, a
successful roll fills the loss buffer first, then a later successful roll
removes piety. A god with no rate consumes no decay roll.

#### Worship transitions and per-god entry rules

`policy/religion/worship.lua` owns `join(ctx, player, god_id, source)` and
`renounce(ctx, player)`. It also exposes `excommunicate(ctx, player)` for
forced loss of devotion. Import `constants.religion_sources` for `ALTAR` or
`ECUMENICAL`, and import god IDs from `constants.gods` when using a bundled
god. A mod-added god supplies its ID in its own definition. The owner checks
live eligibility, leaves the old god, sets the new starting piety, applies a
first-god Monk bonus and good-god transfer, invokes named behavior, and
increments the saved worship count. Renunciation runs the same leave path and
records source `wrath_penance` on `religion.worship`. The later wrath system
will consume that debt. The calling prayer command still owns confirmation
and turn time; invoking `join` directly does not spend a turn.
Voluntary renunciation or conversion can transfer saved devotion between
good gods. Conduct offenses and timed decay call `excommunicate` instead;
forced expulsion clears that temporary bridge before another god can use it.

Each `content/gods/<name>.lua` definition declares `starting_piety` and
`wrath_penance` as nonnegative integers. If a god has an exceptional entry
rule, set `behavior_module` to a Lua module under
`policy/religion/gods/<name>.lua`. That module may export `check` for
eligibility, `prepare` for state needed before bonuses, `monk_bonus`,
`join`, `ecumenical_bonus`, or `leave`. Export only the methods the god
actually uses. The shared owner supplies 35 piety to a first-god Monk and
20 more for an ecumenical altar unless that god provides the matching
exception method. For example, `policy/religion/gods/ru.lua` schedules a
saved sacrifice offer instead of pretending Ru earns ordinary piety;
`gozag.lua` deducts the source service fee from the saved wallet when joining.

Fedhas and Okawaru show two actor-facing entry hooks. Fedhas' `join` ends an
awakened forest on the current floor; its `neutralise` method changes an
eligible hostile plant to good-neutral before that monster chooses an action.
The allegiance lives on the plant's `religion.fedhas_plant` component, so a
save or level change keeps it. `leave` turns plants on every loaded floor
hostile, clears their temporary charm, and allows rejoining to neutralise
them again. Snaplasher vines are excluded from neutralisation, as in source
DCSS. Okawaru's `join` dismisses currently friendly player-owned summons on
the current floor through the common summon cleanup path. A custom god can
use the same `join` and `leave` methods, but
actor state should remain on the affected entity rather than in module locals.

Fedhas' four active powers are separate files in
`policy/abilities/fedhas/`. Each registers one stable ability ID, its live
rank gate, its free targeting check, and its timed resolver. The shared
`policy/religion/fedhas/active_plants.lua` handles actual grid cells and
ECS plant summons. For example, a mod that changes Grow Oklob's price can
override only `policy/abilities/fedhas/grow_oklob.lua`; a mod that changes
which plants Overgrow can raise should override the shared plant policy.
An added summon must remain a catalogued monster and an allowed Fedhas
source for save validation. The resulting actor carries `magic.summon`
and `magic.summon_stats`; terrain changed by Overgrow is saved in the
level grid, so a mod must not keep either effect only in a Lua local.

Jiyva shows a passive whose timing differs from a join hook. Its
`neutralise(ctx, player, slime)` runs before an eligible monster chooses an
action, using source jelly and eye genera from the monster catalog. The
`religion.jiyva_slime` component records both the monster's real side and
whether conversion was attempted. An attempt under penance leaves it hostile;
`penance_ended` clears attempted flags after the final debt point is paid.
`leave` turns only Jiyva-converted slimes hostile and clears their charm.
Conversion and desertion dismiss that slime's summons whose saved side no
longer matches its owner. The common piety owner invokes `penance_ended` on a
god's behavior module when it has that method. A new god can use the same
method for its own actor state.

Jiyva's jelly ecology is split into small Lua owners under
`policy/religion/jiyva/`. `items.lua` decides whether an item can be eaten,
`cells.lua` reads live per-cell `no_jiyva` properties, `targets.lua` gives
good-neutral slimes a visible edible-item destination, and `feeding.lua`
consumes real ECS item stacks before the slime's ordinary action. A meal
can grow max HP and split a species carrying `M_SPLITS`; the saved growth
component preserves that history through restore. The player-time system
`systems/religion_jiyva_ecology.lua` runs `periodic.lua` on Jiyva's saved
random 100–300 aut timer. That policy may spawn jellies on the active floor
or destroy eligible items on an already visited, inactive floor. Off-floor
checks use `ctx:level_ids()` to inspect existing levels; they never generate
a new one. New monster definitions with the source slime genus, new ordinary
item definitions, and new `M_SPLITS` species enter these common rules
without a Go case or a second item allowlist. Override an individual policy
file at the same relative path if its rule should change for a mod.

Jiyva's defensive rank rules live in
`policy/religion/jiyva/defenses.lua`. The methods `active(ctx, player, rank)`,
`hp_bonus`, `mp_bonus`, and `acid_resistance` read the saved
`religion.worship` component each time they are used. Rank zero protects a
current worshipper from adjacent slimy walls; rank one adds HP and MP
regeneration; rank two adds one level of acid resistance, which also gives
the ordinary corrosion rule its protection chance. Penance suspends all of
these benefits. For example, a mod can change Jiyva's rank-one regeneration
by overriding this one Lua policy file and keeping its method signatures.
The shared regeneration, acid, and corrosion owners call those methods;
they do not need copies of the changed numbers.

`policy/world/slime_walls.lua` reads the eight cells beside the acting
entity after its cloud exposure. Each adjacent `DNGN_SLIMY_WALL` can add
acid damage on that action, including a wait. The wall is a terrain cell,
not a separate ECS entity. A monster whose catalog `genus_id` belongs to
Jiyva's slime family, or whose effective acid resistance is fully immune,
is unharmed. Source DCSS also spares a monster outside the player's
no-transparency sight; the wall's dice still roll before that check. To
make a new slime-family monster immune, give its definition
the source slime genus (for example `MONS_JELLY`); the terrain policy then
recognizes it without a monster-name case. The Lua system in
`systems/world_slime_wall_damage.lua` gives player and monster actions
their separate timing while the saved grid and worship component remain
the authoritative state.

Jiyva's five-star heavy-hit response lives in
`policy/religion/jiyva/retaliation.lua`. The shared player-health owner
passes its final, surviving HP loss and the actual attacker to registered
damage reactions. The Jiyva handler checks current worship, penance, and
the fraction of maximum HP lost, then uses the ordinary summon owner to
create one to five friendly slime entities. The four possible monster IDs
live in `constants/jiyva_ejectable_monsters.lua`, shared with save
validation; threshold rules live in the retaliation policy. Its actors
carry `magic.summon` with `source_category = gods`, `source_id = GOD_JIYVA`,
owner, attitude, and expiry; a living damager is kept as their saved target.
To change this passive, override that policy file and keep its
`on_damage(ctx, player, damage, cause, attacker)` contract. The shared
health owner does not need a Jiyva branch. The summon helper accepts an
optional named random stream and a `silent_failure` flag so a passive
whose surrounding cells are blocked does not print a spell-failure message.

Other surviving-hit callbacks follow the same sorted registry. Xom's
`policy/religion/gods/xom_hit.lua` ejects ordinary, saved butterfly
summons when a monster's hit passes its source threshold and chance.
`policy/combat/player_hit_fog.lua` chooses one fog source in order:
Dithmenos's three-star smoke, the equipped cloak of the Thief, then Xom's
colourful smoke. It writes clouds through the shared `policy/clouds/area.lua`
owner. `policy/combat/player_artefact_hit.lua` scans only active worn
artefacts for `ids.artefact_properties.CORRODE` and `SLOW`; corrosion and
Slow remain ordinary saved player statuses. The shared Slow policy applies
source three-halves duration and species or form stasis rules. Named priorities in
`constants/damage_reaction_order.lua` preserve source timing independently
of Lua file discovery. To change one response, override its policy file;
keep its `on_damage(ctx, player, damage, cause, attacker)` callback contract
and the source ordering of random draws and state changes.

Jiyva's six-star capstone shows the other kind of god callback.
`piety.gain` saves the new rank before calling `rank_gained(ctx, player,
old_rank, new_rank)` on the god's behavior module. Jiyva records the spent
reward in `religion.worship.one_time_abilities`, keyed by its god ID, then
opens any Slime:5 seals on the current floor. The generic
`world.enter_level` policy checks saved rewards after later stair travel,
so earning the capstone before Slime:5 opens that floor on arrival. The
Royal Jelly death and Jiyva's reward both call `policy/world/slime_seals.lua`
to change the same ECS seal markers and terrain cells. A modded god can
implement `rank_gained` for its own threshold effect and store any
one-time history in the worship component.

`policy/religion/gods/zin.lua` taxes untithed carried gold on joining and
floor gold on pickup. Its `mark_seen` method records whether each gold entity
was first seen while worshipping Zin. That item state survives save and
conversion: a pile seen before joining still pays a cash tithe, but gives no
piety. Gold from acquirement carries an `acquired` flag from item generation
and uses Zin's capped piety formula. `character.wallet` keeps paid
`donations` and the fractional `tithe_base` between piles, so ten single
pieces owe the same one-piece tithe as a ten-piece stack. A mod introducing
another gold source should put its source facts on `item.gold_tithe` and let
the wallet pickup path invoke Zin; it should not duplicate tithe arithmetic.
Import `constants.zin_tithe_state` for an exempt or late-donation pile.
For a new god with a gold rule, export `gold_pickup(ctx, player, entity,
quantity)` from its named behavior module. The wallet validates the floor
pile and destroys it after this method returns the credited amount.

The order matters: `prepare` runs after the new god is set; the Monk bonus
and good-god transfer run next; `join` follows; then the ecumenical bonus is
applied. A named `leave` runs after the shared owner has cleared current
worship and recorded penance. `constants.religion_signals.LEFT` and `JOINED`
announce that transition. God-specific state that must survive a save belongs
in its own component schema. The bundled Ashenzari, Ru, Xom, and
Yredelemnul components illustrate this. Their pending rewards remain saved
until those god systems are ported; the current engine does not yet resolve
all divine abilities, gifts, passives, and wrath effects.

Trog's `policy/religion/gods/trog.lua` illustrates a temporary training
restriction. It exports `forbids_training(ctx, player, skill_id)`, which the
shared `policy/character/skill_availability.lua` asks when it calculates
training controls, XP weights, direct skill experience, and the skills
screen. `data.skill_order.is_magic(skill_id)` supplies the source magic
group; Gnoll Distributed Training is Trog's source exception. A modded god
may supply the same optional method through its `behavior_module`. Keep a
temporary god restriction out of permanent mutation-skill rules: leaving
the god must not erase learned points or the player's saved choices.

Trog's three powers show how to add a complete god ability family without
a Go command case. Files under `policy/abilities/trog/` register Berserk,
Trog's Hand, and Brothers in Arms through `policy.abilities.registry`.
Each file owns its rank, free preparation, failure tuple, effect, and piety
cost. `policy.abilities.god_costs` supplies the common worship gate and
cost arithmetic; the power calls it only after its own effect commits.
The existing `policy.character.rage` owns Berserk, so changing the god
ability never requires a second rage component.
The ability command normally rejects invocations while confused. A power
whose source explicitly permits it sets `confusion_ok = true` in its
registry entry; Elyvilon's Purification does this so it can cure confusion.
Deliberate Trog Berserk ignores Clarity, while involuntary rage still checks it.
The Berserk module asks for confirmation when the player wields a
launcher or other non-melee item.

Trog's Hand writes `religion.trog_hand` on the player. Its separate Lua
system ages that timer before HP regeneration, and the regeneration and
willpower owners read the same component. Brothers in Arms selects from
`policy.religion.trog.brothers_roster`, spawns one ordinary ECS monster
with a `magic.summon` source of Trog, and gives it a saved berserk timer.
The monster's own action clock ends both Berserk and its summoning; a
world-time `expires_aut` would drift when monster and player speeds differ.
For this Trog source, `expires_aut = 0` denotes that source-specific
clock. The summon expiry system and save validator recognize it by the
stable Trog source ID and require a live frenzy on restore.
The roster is imported by save validation as well as selection. To change
this power in a mod, override its ability or roster file by relative path;
do not add a second list of allowed monster names. Trog's behavior module
exports `leave` and `on_penance` to clear the Hand and dismiss temporary
god summons. The piety owner calls `on_penance` once when an offense
first creates debt, after recording that debt. Another god can supply the
same optional hook for its own temporary gifts.

Elyvilon's four Lua ability files under `policy/abilities/elyvilon/`
illustrate a patron whose powers share several existing owners. Purification
uses `policy.religion.elyvilon.cleansing` to remove player ailments and
recalculate HP after drain; Heal Self changes the ordinary health component;
Heal Other asks `policy.religion.elyvilon.pacification` to examine the
monster catalog class and store a neutral ECS marker. Pacification grants
the same credited XP as a kill through `policy.character.experience_award`,
but the marker prevents that monster from paying XP again if it later dies.
`policy.ai.pacified_departure` reads that same marker during monster
decisions, finds a reachable floor exit through the shared grid service,
and uses the ordinary move intent. Once the monster reaches a stair, gate,
teleport trap, or shaft, the post-movement system removes it with its
carried gear. Mods that add a new exit should expose it as a travel feature
or a trap type recognized by this policy. A new pacification effect must
award nonlethal XP once and set the marker; the AI owner then routes it.
The shared conversion also releases actor-owned temporary terrain through
`policy.world.temporary_terrain`; expiry and monster death use that same
restore operation. A spell that makes temporary terrain should call
`temporary_terrain.place` with its real source actor. If the caster later
dies or becomes peaceful, only that caster's markers are removed. Pikel's
marked lemures and Kirke's marked hogs use their existing death-release
owners at pacification too; custom linked monsters should keep their
release behavior in one owner and invoke it from each departure trigger.
Dowan and Duvessa illustrate a coupled unique rule:
`policy.monsters.elven_twins` finds the living partner by original class.
The pacification owner converts it without another RNG roll or heal.
The partner receives its own once-only XP marker, which the ordinary save
path retains.
Player attacks should report a monster contact through
`policy.combat.player_contact` before resolving accuracy or resistance.
That entry point records religious conduct while the target is still
peaceful, then clears its active peace flag and angers the same-floor twin.
The marker remains as once-only XP history: a false `pacified` field means
the actor is hostile again and must not take the pacified exit route.
For example, a new offensive evoker should call
`player_contact.report(ctx, target, definition)` for each contacted monster,
even if its later damage roll is zero. Dowan and Duvessa also demonstrate
`policy.monsters.elven_twins` as the owner of a saved pair relationship:
death, Abyss banishment, and Arena separation call its grief operation;
the ordinary monster spellbook and status owners read that saved state.
Mods adding a linked pair should put the durable relation on ECS actors and
connect every separation path through one owner. The survivor's saved
`can_climb` field is read by `policy.world.stair_followers` when an ordinary
stair action is accepted. That owner tags eligible actors before monster
decisions; `world.stairs` places them after the player reaches the linked
floor and clears the action-only mark. For example, a modded friendly actor
with live AI, energy, and ordinary-floor habitat can follow a connected
stair with the same ECS identity and inventory. A new body class that
cannot use stairs should be added to the eligibility owner's exclusion
rule. A new portal needs its own commit path after accepted travel and
may reuse the shared follower wave when its source rules match. Branches
tagged `no_x_level_travel` do not take ordinary followers, apart from the source
Pandemonium exception. The owner reads `ctx:level_branch`, `ctx:stair_at`,
`ctx:actor_at`, and `ctx:walkable` from the shared context rather than
keeping a second map or actor registry in Lua.
Transporters are the existing within-floor example: both travel modes
read `policy.world.follower_wave` and `policy.world.follower_eligibility`.
The travel mode names come from `constants.follower_travel`. A transporter
can carry a summon or zombified actor that a stair rejects, while the
same connected wave and source order choose nearby candidates. A modded
travel feature should reuse that wave if it has the same source follower
semantics, then perform its own movement after the player arrives.
Divine Vigour stores an amount and timer in `religion.elyvilon_vigour`.
The normal HP and MP formulas read that amount, so later training or level
changes still produce the correct maxima. The god's `behavior_module`
clears this status on penance or departure. For a modded god with a lasting
resource effect, follow that owner pattern: save one timer and make all
derived resource readers consult it instead of directly editing a maximum
once and hoping later recalculations preserve it.

#### Prayer, renunciation, and the HUD

The source stair keys (`<` and `>`) request prayer when the player stands on
an altar. `policy/input/play.lua` selects the command, and
`policy/commands/entries_religion.lua` calls
`policy/religion/prayer.lua:prepare`. That policy reads the altar's saved
`god_id` through `ctx:records_at(level_id, x, y)`. It returns a free
confirmation carrying the altar ID; only an accepted answer creates a timed
prayer intent. `systems/religion_prayer.lua` then calls `prayer.resolve`,
which rechecks the record and calls `worship.join`. The terminal supplies
keys and prompts; it does not decide which god will accept the player.

An ecumenical altar stays unidentified until the player accepts. Its chosen
god comes from the named religion RNG stream over stable god IDs. The
resolver updates both worship and the altar's saved typed record. A mod that
replaces prayer policy should preserve that single accepted-choice boundary
and use `ctx:replace_record_string` to change the saved record, rather than
only changing a displayed name. A refusal or cancelled prompt spends no
turn and leaves RNG and altar identity untouched.

`ids.abilities.RENOUNCE_RELIGION` is registered by
`policy/abilities/renounce_religion.lua`. It appears in the ordinary `a`
ability menu only while a god is worshipped. Its two confirmation IDs bind
both source prompts to the same live god; accepting the second prompt spends
one turn and calls `worship.renounce`. Mods may replace the ability module at
the same relative path. To add a separate divine ability, register its own
ID and focused module through `policy.abilities.registry` rather than
putting more cases in renunciation.

`policy/presentation/religion.lua` reads `religion.worship` for god name,
six-position piety, and current penance. Xom has one moving star rather than
the ordinary cumulative stars. It uses the effective god catalog, so a
modded god's name and piety mode reach the HUD through its definition.
Gozag's no-piety mode intentionally has no stars. The terminal places patron
and stars beside the species on the second HUD line, following source DCSS;
the Go view renders Lua values without a second god-name table.

If an existing category's field is unclear, search for the field name in its
consumer policy. That tells you whether it is display data, generation data,
or a live rule input. For a new category owned wholly by a mod, use
`register.definition(category, definition)` and a focused policy that reads
it through `register.get`; registering a new catalog does not create a
command, scheduler hook, or UI screen automatically.

### One-time divine weapon choices

The Shining One, Kikubaaqudgha, and Lugonu register their weapon capstones
under `policy/abilities/weapon_blessing/`. Each file supplies its god ID,
ability ID, brand, wording, ranged-weapon rule, and optional `after` effect
to `policy.abilities.weapon_blessing.define`. That shared Lua owner offers a
free carried-item menu, stores the selected Akara entity in
`religion.weapon_bless_choice`, asks for a free confirmation, and verifies
the same item and current worship before the timed action. The item policy
then changes its base kind, brand, and enchantment on that entity. Mods can
replace a single god file at the same relative path, or register another
definition with a new ability ID without editing a Go switch.

Kiku's `policy/abilities/kikubaaqudgha/forbidden_knowledge.lua` is a
separate menu row. It reads the five source spell IDs from `ids.spells`,
filters them through the live permanent-usability rules, and grants the
surviving library records only after confirmation. Both Kiku choices write
`religion.worship.one_time_abilities[GOD_KIKUBAAQUDGHA]`, so changing gods
cannot permit a second choice. No Grasping hides weapon blessings but leaves
Forbidden Knowledge available. A new one-time god power should use the same
durable worship history key and validate pending choices on restore.

Kiku's recurring powers show how to split an ability from the actor state it
creates. `policy/abilities/kikubaaqudgha/torment.lua` pays the source cost
and calls the shared Torment area with the `KIKU_INVOKED` source tag. The
area and resistance owners then decide who is hit, including Kiku's partial
self shield. `unearth_wretches.lua` handles the invocation and delegates
body selection and placement to
`policy/religion/kikubaaqudgha/wretches.lua`. That policy reads the effective
branch population catalog, so a new natural, corpse-bearing monster can join
the eligible pool through its own content and population files. Its live
actor gets `religion.kiku_wretch`; the matching schema saves remaining life,
and the system ages it on the active floor. The death owner sees that marker
to suppress XP and guarantee a corpse. It deliberately does not add
`magic.summon`, because summon expiry destroys bodies instead of leaving
corpses. A mod replacing the wretch policy should preserve this marker and
the death contract, or supply an equivalent saved lifecycle and restore
validation. Numeric rank, cost, radius, and clock values live in
`constants.kikubaaqudgha` and are imported where used.

TSO's holy word uses `policy.combat.holy_word` for living target selection,
damage, daze, and blood cleansing. Kiku's brand calls the normal Torment
area with `constants.torment_sources.KIKU_BLESSING`, which suppresses Kiku's
usual passive shield just for that source action. Its blood spread uses the
saved level `cell_blood` and `set_cell_blood` grid methods; these are
properties of floor cells, independent of terrain IDs and vault colours.

Put one definition in one file below `content/<category>/`. The recognized
base categories are `species`, `jobs`, `monsters`, `spells`, `items`,
`mutations`, `branches`, `gods`, and `monster_spellbooks`, plus `artefacts`, `clouds`,
`monster_beams`, `shops`, and `traps`. The registration API accepts additional
category names for mod-defined catalogs. For example,
`content/monsters/my_moss.lua` can contain:

```lua
local categories = require("constants.catalog")
local habitats = require("constants.monster_habitats")
local attacks = require("constants.monster_attack_types")
local flavours = require("constants.attack_flavours")
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
            type_id = attacks.BITE,
            flavour_id = flavours.PLAIN,
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
`MOSS = "MY_MOD_MOSS"` and
`MOSS_POPULATION = "MY_MOD_MOSS_POPULATION"`. Import it in every mod
file that uses those identifiers. Existing bundled attack types and flavours
come from `constants.monster_attack_types` and
`constants.attack_flavours`; other bundled IDs come from their matching
`constants.*` or `ids.*` modules.

A catalog monster describes traits shared by every instance. If one actor
can change its own colour, attack, resistance, or other durable trait,
register a component under `schemas/`, attach it when that actor is made,
and project it at the relevant combat and presentation reads. The bundled
ugly thing shows this pattern in `schemas/monster_ugly_thing.lua` and
`policy/monsters/ugly_thing.lua`. Its profile is stored on the ECS actor,
so mutation and save/restore use the same state. Avoid changing a catalog
table to represent one creature's mutation; that would change every
creature of its kind.

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
Dungeon keeps IDs 1–15. Keep the result below
`constants.abyss.LEVEL_ID` because the high range belongs to permanent
special regions; the branch allocator rejects a collision. Put ambient
rows in a separate
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

For a monster that continuously surrounds itself with a cloud, import
`constants.monster_flags` in its definition and add `flags.FIRE_RING`,
`flags.THUNDER_RING`, or `flags.MIASMA_RING` to its `flags` list. Alternatively,
set `cloud_ring_id` to a value imported from
`constants.monster_cloud_rings` when the monster needs another cloud type.
`policy/combat/monster_cloud_ring.lua` resolves that immutable definition
when the monster spawns and after each action. It places ordinary saved ECS
clouds; do not add a separate timer or cloud list to the monster definition.
The ring constants map the source enchantment names to cloud IDs in one place.

`policy/combat/opportunity_attacks.lua` handles a player stepping away from
an adjacent monster. It checks the monster's content attack, saved energy,
statuses, allegiance, and visibility before drawing the one-in-three chance.
The strike runs through ordinary monster melee while the player is still in
the old cell. If you add a melee brand or flavour that moves either actor,
read `hit.player_moving`: an opportunity strike must not trample, ensnare,
constrict, banish, or blink the moving player. The policy refunds up to ten
attack-energy points, leaving slow attacks with their extra cost.

For a player-book spell, add its registered ID to a fixed book's
`generation.spells` list in `content/items/book_*.lua`. The effective
layered books then give it BOOK scope and make it eligible for Wanderer,
Djinni, and random-book selection. `policy/magic/player_book_catalog.lua`
builds that pool from the effective catalog, in source numeric-ID order
followed by unnumbered mod spells in ID order. Membership is cached only
after registration closes. Removing the last book
reference removes that eligibility. A modded book with a misspelled spell
ID fails when the pool is read.

For a directly invoked spell that is not in a book, set
`player_scope = scopes.INVOKED` in its definition and import
`constants.spell_scopes` as `scopes` there. An explicit `player_scope`
overrides automatic scope classification, but declaring BOOK alone does
not put the spell into a book. Put the spell's resolver in a separate file
under `policy/magic/effects/` and call
`registry.add(spells.MY_SPELL, { resolve = effect.resolve })`, importing
`ids.spells` and `policy.magic.effects.registry` there. Both files load
automatically. Book and invoked spells without resolvers appear in effect
coverage diagnostics.

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

Divine kill recovery is a separate reaction after death conduct and mutation
kill effects. A god definition may set `kill_recovery_module` to a Lua path,
such as `policy.religion.kill_recovery.makhleb`. That module returns a local
table with `amounts(ctx, victim, definition)`, which returns the HP and MP
amounts to award. The shared `policy.religion.kill_recovery` owner checks
player credit, XP, object status, penance, and piety, then clamps those
amounts to the saved pools. The victim entity is still alive for policy
queries at that point. For example, a modded patron that grants two MP on
eligible kills can return `0, 2`; it needs no change to the death system.
Keep its formula in a separate policy file so another mod layer can replace
that file alone. The death owner suppresses XP and recovery for formerly
neutral victims unless they are frenzied; if Devour on Kill and a god both
restore HP on one death, the player sees one health message.

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

A vault can also generate clouds over time with a fog machine marker in its
`.des` file. The original map syntax remains the authoring interface:

```text
MARKER: f = lua:fog_machine { cloud_type = "thin mist", \
    pow_max = 5, delay_min = 10, delay_max = 150, size = 5 }
```

The marker lives at each `f` map cell. `pow_max`, a fixed `size` or
`size_min`/`size_max`, and a fixed `delay` or `delay_min`/`delay_max` are
required. Optional fields are `cloud_type`, `walk_dist`, `pow_min`,
`pow_rolls`, `spread_rate`, `start_clouds`, `excl_rad`, and size or spread
buildup amount/time pairs. Use the source cloud names resolved by
`constants/fog_clouds.lua`; add a registered cloud definition and name
mapping before inventing a new name. The marker reader rejects expressions
and unknown fields. The Lua world policy creates a saved
`world.fog_machine` entity for each marker. It resets the clock and emits
`start_clouds` on level entry, counts down in aut while that floor is active,
and places later clouds through the same cloud owner as spells. Restoring a
save preserves the clock and does not repeat the entry burst. For a new fog
rule, edit `policy/world/fog_machines.lua`; the `.des` file only selects its
existing parameters.

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

### Temporary portal handlers

One-floor temporary portals register a small Lua handler under
`policy/world/portals/handlers/`. The layered VFS loads effective files
by path, then the catalog selects a handler by the terrain feature under
the player. Each file returns a table with a stable `id`, a `features`
array, and `prepare(ctx, request)`, `is_marker(record)`, and
`materialize(ctx, level, record)` functions. The optional
`validate_level(ctx, level)` checks required source markers before any
portal is populated. `request` contains `position`, `downstairs`,
`forced`, and `target_id`; the last two support a gate that asks for
confirmation. A handler should forward to its domain's travel and gate
owners, as `handlers/trove.lua` does. The catalog rejects a second file
that claims an existing feature or source marker. Replace an existing
handler by its exact relative path in a higher VFS layer.

Keep `is_marker` free of side effects. Population resolves the marker
owner first, then calls `materialize` only when earlier nonportal marker
owners have declined that record. This preserves source record order and
prevents a competing marker from creating an untracked gate.

Adding a new portal domain still requires its terrain IDs, saved Akara
state, generation policy, and save validator. The handler is the one
registration point for stair commands and source marker materialization;
no new command or population `if` branch is needed. Pan and Hell are
persistent branch travel and keep their separate owners.

The Bazaar map corpus is separate from ordinary shop maps. A portal entry
belongs under `vaults/bzr_entry/` with a `bzr_entry` tag; a whole-floor
market belongs under `vaults/bazaar/` with `DEPTH: Bazaar` and a source
weight. The source maps use named Lua hooks under
`policy/generation/vaults/bzr_entry/` and
`policy/generation/vaults/bazaar/`. A map's own hook handles a calculated
choice, while `bazaar/shared.lua` installs the common arrival arch, exit,
and tileset. The 55 bundled maps show both authored MAP blocks and one
procedural cavern. A source entrance can place a timed or permanent Bazaar
arch. A timed arch has a saved `world.bazaar_portal` ECS clock and becomes a
stone arch when global action time reaches its deadline, even if the player
is elsewhere. Entering spends the arch, generates one weighted Bazaar map,
and stores the return cell in the player's `character.bazaar_visit`
component. The market's shops use Bazaar pricing and stock depth; leaving
retires the floor and its stock. A keyed `any shop / T` choice uses the
original DES `T` glyph as a blue fountain if the shop is not selected.
`policy/world/bazaar/` owns these live rules. A `.des` hook configures a map
during generation and receives `api`, never the live `ctx`.

The Sewer uses the same layered vault directories. Add a Dungeon entrance
under `vaults/sewer_entry/` with `DEPTH: D:3-6`, `TAGS: chance_sewer
uniq_sewer no_monster_gen`, and a source chance. Put its map-specific
instructions and `vault.run("shared.portal")` in the `.des` file; the named
hook is defined in `policy/generation/vaults/sewer_entry/shared.lua`. The
hook draws the drain's 600–800-turn lifetime once, emits its keyed feature,
and leaves a timed marker that population turns into `world.sewer_portal`.
The marker's fixed draw and the ECS deadline must agree in a saved game.
`systems/world_sewer_portals.lua` owns the source discovery text, periodic
rust warnings, final warning, and collapse; the next notice and final
warning flag live on that same ECS component so reloading does not restart
the sound sequence. Source timing and distance bands are named in
`constants/sewer.lua` for map hooks and runtime rules to share.
See the bundled entrance files for the full geometry and source directives.

Add a destination under `vaults/sewer/` with `DEPTH: Sewer`, a source
`WEIGHT`, an encompassing `MAP`, and at least one exit. The shared
`vault.run("shared.setup")` hook maps the source `<` glyph to the Sewer
return exit. A separate named Lua hook can emit map-specific keyed monsters,
items, or terrain at its source position. The effective catalog discovers
new maps by directory and chooses among positive weights in stable ID
order. A sparse mod can therefore add one map without copying the 19
built-ins; `internal/script/testdata/sewer-vault-mod/` is a minimal example.
The live `policy/world/sewer/` rules own entry, expiry, and return, while
the generic Go portal transaction stages and retires the temporary floor.
An authored Lua portal may pass `layout_id` to
`world.generate_sewer_level` to request one eligible map; ordinary drains
omit it and use the source weighted draw. Invalid IDs fail generation
before the portal is spent.
An active visitor carries `character.sewer_visit`, which saves the exact
outside drain cell. Use the ordinary vault record and population APIs for
new Sewer content; a new content type belongs in its relevant shared owner
instead of a new Sewer-specific Go branch.

An Ossuary follows the same portal path with its own content directories.
Put Dungeon entrances in `vaults/ossuary_entry/` with `DEPTH: D:4-8`,
`TAGS: uniq_ossuary no_monster_gen chance_ossuary`, and a `CHANCE` value.
Place `: vault.run("shared.portal")` where the gate should be configured.
That method lives in `policy/generation/vaults/ossuary_entry/shared.lua` and
receives the vault `api`. It draws one 600–800-turn lifetime, emits the
`enter_ossuary` feature and a fixed timed marker, and applies sand styling.
Population turns that marker into a `world.ossuary_portal` component when
the Dungeon floor is placed. The component saves its source record index,
creation time, deadline, next sound notice, and spent state. It starts at
floor placement, before the player finds or steps on the gate.

Put whole-floor destinations in `vaults/ossuary/` with `DEPTH: Ossuary`, a
positive `WEIGHT`, an encompassing `MAP`, and a return `<` glyph. The
`: vault.run("shared.setup")` method from
`policy/generation/vaults/ossuary/shared.lua` turns `<` into the live return
gate after the map's substitutions. Map-specific `: vault.run` methods use
the matching Lua module in that directory. Keep the handler body in its
Lua file for now; the roadmap has a TODO to support placing it in the DES.
The runtime calls each hook at its authored directive position. Hook
`api:emit` inserts a DES directive; `api:record` stores a typed effect at a
source glyph. The `ossuary_boxes_badplayer` map illustrates a later event:
its hook records each `:` trigger and `a`/`b` wall, while the live callback
in `policy/world/vault_trigger_callbacks/ossuary_boxes.lua` opens the wall
group. `world.vault_trigger` components save the group ID and complete wall
record links; restore rejects partial wall openings or forged links.

The effective catalog discovers new Ossuary maps by path and sorts eligible
IDs before the weighted draw. A mod can therefore add just
`vaults/ossuary/my_gallery.des`; it need not copy the bundled maps. It can
replace one bundled hook by providing the same relative Lua path. See
`internal/script/testdata/ossuary-vault-mod/` for both operations. The
generic portal transaction stages the selected floor, then spends the
outside gate and stores its exact cell on `character.ossuary_visit`. A
blocked return leaves that visit and floor intact. The timer, return, and
save rules live under `policy/world/ossuary/`,
`systems/world_ossuary_portals.lua`, and `policy/save/ossuary_*.lua`.

### Bailey gates and themed maps

Bailey is a one-floor portal branch reached from D:7–10. Its committed
entrances are individual `.des` files under `vaults/bailey_entry/`. Each
uses the source `uniq_bailey chance_bailey` tags, `CHANCE: 1000`, and a
named `: vault.run("shared.entry_1")`-style hook at the source directive
position. The hook in `policy/generation/vaults/bailey_entry/shared.lua`
draws the axe or polearm theme first, then one 600–800-turn lifetime. Its
`lua:timed_marker` declaration stores both values. Population creates a
`world.bailey_portal` ECS component at the placed cell; the clock starts
when the entrance floor is created, including before the player enters it.
Global action time can close the gate while its Dungeon floor is inactive.
The closed feature is a walkable `stone_arch`.

Destinations live in `vaults/bailey/`. The source `bailey.des` is a mapless
dispatcher with `vault.post_place("dispatch.run")`. Do not give it a `MAP`:
`policy/generation/bailey/level.lua` runs its hook as a controller before
asking the geometry fitter to place one child. To add a new axe layout,
create a single file such as `vaults/bailey/my_fort.des` in a mod layer:

```text
NAME: my_fort
DEPTH: Bailey
WEIGHT: 10
TAGS: bailey_axe no_monster_gen
ORIENT: encompass
KFEAT: < = exit_bailey
MAP
xxxxx
x...x
x.<.x
x...x
xxxxx
ENDMAP
```

Use `bailey_polearm` for the other theme. A positive weight and matching
tag put the map into the effective catalog without changing Go code or
editing the dispatcher. Candidate IDs are sorted before weighting, so file
enumeration order cannot alter a seeded draw. A map must have a usable
`exit_bailey` arch; the player arrives there and uses the upstairs command
to return to the exact saved entrance cell. The generic portal transaction
stages the floor before spending the gate and retires the floor, its actors,
and its items on return. If the outside cell is occupied, return waits and
costs no time.

Keep map-local decisions in named Lua hooks under
`policy/generation/vaults/bailey/` and call them from the `.des` file at
their authored position. A hook receives the same vault `api` documented in
the vault hook section: `api:emit` adds a DES directive, `api:record` stores
a typed effect, and `api:roll` draws from the layout stream. A mod can
replace a bundled hook by supplying its exact relative Lua path; it can
also add just one `.des` file. The runnable
`internal/script/testdata/bailey-vault-mod/` example demonstrates both.
Keep any new hook functions commented with the reason for their records
and the stage at which they run. Avoid a second persistent Lua global for
the theme: the marker, gate component, visit component, and saved floor are
the source of truth. The `character.bailey_visit` component stores the
outside coordinate, selected child ID, and theme. The gate's saved
`closure_reason` is `entry` or `expiry` after it closes; both leave the
same stone arch terrain. Restore checks those
against the marker, deadline, selected tag, dispatcher history, and exit.
The gate and travel rules live under `policy/world/bailey/`, its timer in
`systems/world_bailey_portals.lua`, and integrity rules under
`policy/save/bailey_*.lua`.

### Ice Cave gates and destination maps

Ice Cave is a one-floor timed portal branch. Its 15 committed entrances
live under `vaults/ice_cave_entry/`, and its 11 whole-floor destinations
live under `vaults/ice_cave/`. A source entrance has
`uniq_icecv chance_icecave` tags, `CHANCE: 500`, its own `DEPTH` and
`WEIGHT`, and a named Lua hook at the source decision site. The shared
entrance hook draws exactly one 600–800-turn lifetime and decides `hard`
from the **outside branch and depth**: D:11–13, Lair, and Orc are easy;
D:14–15, Elf, Swamp, Shoals, Snake, and Spider are hard. That bit is
stored in the marker and `world.ice_cave_portal` ECS component. Entering
the cave never redraws it or looks at the player's current depth.

To add a destination, put one `.des` file at a new path such as
`vaults/ice_cave/my_ice_gallery.des` in your mod directory:

```text
NAME: my_ice_gallery
DEPTH: IceCv
WEIGHT: 20
TAGS: no_item_gen no_monster_gen
ORIENT: encompass
KFEAT: < = exit_ice_cave
MAP
xxxxx
x...x
x.<.x
x...x
xxxxx
ENDMAP
```

The effective catalog adds a positive-weight map to the IceCv pool, sorts
candidate IDs, and draws by weight. The map must fit the 80×70 level and
provide a live `exit_ice_cave` feature. The player arrives at that exit;
the upstairs command returns to the saved outside cell. A blocked outside
cell refuses return without spending time. The generic portal transaction
stages the whole floor and its actors before spending the gate, so a bad
map or hook leaves the saved gate and RNG unchanged. A zero-weight map is
excluded, including from explicit `layout_id` requests. A file at the
same relative path as a bundled map replaces only that map; see the
`internal/game/testdata/ice-cave-*` mod fixtures for runnable examples.

Use a named source-position hook when difficulty changes a map's content.
For `: vault.run("my_ice_gallery.decorate")`, add
`policy/generation/vaults/ice_cave/my_ice_gallery.lua`:

```lua
-- This map chooses its keyed guardian from the entrance's saved bit.
local directives = require("constants.vault_directives")
local difficulty = require("policy.generation.vaults.ice_cave.difficulty")

local gallery = {}

-- The same map stays easy or hard across save and restore.
function gallery.decorate(api)
    if difficulty.hard(api) then
        api:emit(directives.KMONS, "G = ice dragon")
    else
        api:emit(directives.KMONS, "G = rime drake")
    end
end

return gallery
```

The hook's `api` is the vault placement context: `api:emit` inserts a DES
directive at that exact site; `api:record` preserves a typed effect;
`api:roll` and `api:coinflip` use the staged generation stream; and
`api:setting("ice_cave_hard")` reads the saved gate choice supplied by
the floor generator. Do not store a visit bit in a Lua module variable.
The `ctx` used later by world policies and systems is the live game context:
it reads and writes ECS components and level cells, emits messages, and
queries the game clock. It is not available to DES hooks. The general
vault hook and runtime-context sections describe their full methods.

The visitor's `character.ice_cave_visit` component carries the exact
outside level and coordinate, selected map ID, and hard bit. Its outside
gate changes to `expired_portal` and keeps `closure_reason = "entry"`;
natural timeout uses `"expiry"`. Global player action time continues the
clock on an inactive floor. The Lua system gives the source frost warning,
five crackling bands, final warning, and Silence-aware hearing. Restore
compares the marker, ECS clock, terrain cell, active visit, and selected
floor. The owners are `policy/world/ice_cave/`,
`systems/world_ice_cave_portals.lua`, and `policy/save/ice_cave_*.lua`.
The [Ice Cave snapshot index](level-snapshots/ice-cave/index.txt) shows
both variants of all 11 source maps and their test return coordinates.

### Volcano entrances, maps, and terrain events

Volcano uses the same layered vault paths. The base game commits 11
entrances under `vaults/volcano_entry/` and 23 definitions under
`vaults/volcano/`: 14 whole-floor destinations and nine tagged helpers.
An entrance has `uniq_volcano chance_volcano`, `CHANCE: 500`, and a named
`volcano_entry/shared.lua` hook. That hook draws **one** 600–800-turn
lifetime when the source map is placed. `world.volcano_portal` saves the
fixed draw, creation time, deadline, exact cell, and closure reason. The
clock continues on an inactive outside floor. An accepted last-turn entry
finishes before expiry; natural expiry changes the outside cell to
`expired_portal`.

To add a weighted destination, create one file at a new relative path in
your mod directory, for example `vaults/volcano/my_volcano_foyer.des`:

```text
NAME: my_volcano_foyer
DEPTH: Volcano
WEIGHT: 20
TAGS: no_item_gen no_monster_gen
ORIENT: encompass
KFEAT: < = exit_volcano
MAP
xxxxx
x...x
x.<.x
x...x
xxxxx
ENDMAP
```

The effective catalog sorts stable `NAME` IDs before a weighted draw.
Positive weight and a live `exit_volcano` arch are required. A helper
tagged `volcano_grotto_subvault`, `volcano_lake_subvault`, or
`volcano_tomb_subvault` belongs to a parent `SUBVAULT` request and never
enters the whole-floor draw. Add a new helper file in the same directory
with that tag. Replacing a bundled map uses the **same relative path**;
`vaults/volcano/volcano_pools.des` replaces only that map. A zero-weight
replacement disables explicit selection as well as ordinary selection.
The `internal/game/testdata/volcano-*` fixtures exercise each case.

The `.des` file keeps the source MAP and directive order. At a source
script site, `: vault.run("my_foyer.decorate")` loads
`policy/generation/vaults/volcano/my_foyer.lua` through the layered VFS.
The hook receives the placement `api`, **not** the live game `ctx`.
`api:emit` inserts an ordinary DES directive at that point. Use a
multiline `api:record` call to anchor a typed marker to a glyph **before**
later `SUBST` can erase it:

```lua
local effects = require("constants.vault_effects")
local volcano = require("constants.volcano")

api:record(effects.MARKER, {
    glyph = "M",
    identity = volcano.COLLAPSE_MARKER,
})
```
This distinction matters for Volcano's cave and overflow scripts. Their
source-position Lua hooks currently live in named `.lua` files; a future
cleanup may move those hooks into the DES files while keeping the same
behavior. No Lua script is embedded in Go code.

After population, live rules receive `ctx` as described in
[the game context reference](#the-game-context-ctx). The visitor's
`character.volcano_visit` component holds the exact outside level and
coordinate plus the selected source map ID. Every `<` and `I` return
arch uses that one pointer. `policy/world/volcano/travel.lua` decides
entry and return, the generic staged transaction owns rollback, and
`policy/save/volcano_*.lua` checks the marker, gate, visitor, map, and
grid before restore. A blocked outside cell refuses return without cost.

Two source maps animate their terrain. `volcano_caves` has one
`world.volcano_collapse` component with a 50–200-aut countdown and the
remaining doorway record indices and positions. Each firing chooses one
doorway; if the player occupies it, the doorway remains eligible.
Otherwise it becomes a stone wall and emits grey smoke. `volcano_overflow`
has one `world.volcano_overflow` component: a 200–400-aut countdown,
phase 0–9, immutable group indices and positions, and the indices that
actually turned into lava. Phases 2/4/6 pour lava into A/B/C groups;
7/8/9 harden those groups in reverse order. The player's current cell
never changes under them. These schemas describe mutable saved state;
the DES records and level grid remain the source and terrain owners.

The [Volcano snapshot index](level-snapshots/volcano/index.txt) shows all
14 staged source floors, chosen helper IDs, and **every** return arch's
exact outside connection. The snapshots use a Dungeon:1 test gate so the
map shapes are easy to compare; natural entrance eligibility is Lair and
Orc. The source `no_cloud_gen` property remains in typed vault records.
Legacy Crawl uses it specifically to suppress ambient smoke or mist from
lava and water. The port has no ambient terrain-cloud producer yet, so
there is currently no such effect to suppress; authored fog machines and
other explicit clouds remain active.

### Treasure Trove entrances, tolls, and reward rooms

Treasure Trove keeps its 14 source entrances in `vaults/trove_entry/` and
its 21 whole-floor reward rooms in `vaults/trove/`. Each definition is one
replaceable `.des` file. MAP rows and ordinary directives retain the source
format. `: vault.run(...)` and `: vault.veto(...)` call readable Lua files
under `policy/generation/vaults/trove_entry/` or
`policy/generation/vaults/trove/`. Each hook receives the placement `api`.
Use `api:emit` for a DES directive and `api:record` for a typed effect.
The hook does not receive live `ctx` or directly change the player. The
existing TODO to move hooks back into DES applies here too. No Lua is
embedded in Go.

To add an entrance, create a file under `vaults/trove_entry/` with a unique
`NAME`, an eligible `DEPTH`, a `CHANCE`, and one `O` in its MAP. Call
`: vault.run("shared.portal")` before MAP. The hook gives `O` the
`enter_trove` feature and an empty typed `price` marker with identity
`trove:toll`. Population requires one marker and one Akara gate; an
entrance with a missing or malformed marker cannot become a free gate.

To add a reward room, create a positive-weight file such as
`vaults/trove/my_gallery.des` in your mod directory:

```text
NAME: my_gallery
DEPTH: Trove
WEIGHT: 20
TAGS: no_item_gen no_monster_gen allow_dup
ORIENT: encompass
KFEAT: < = exit_trove
ITEM: acquire weapon / any useful weapon good_item
MAP
xxxxx
x...x
x.<.x
x...x
xxxxx
ENDMAP
```

Positive-weight effective `NAME`s enter a sorted weighted draw. Every
walkable `<` returns through the one saved outside cell. A zero-weight
replacement removes a room from selection. Replace a bundled map by
using its exact relative path in a higher VFS layer; a new path adds a
room. Trove's six source veto hooks show how a map can ask the narrow
placement API about live player skills before it is selected.

Population rolls a toll **once** on the saved `trove_toll` stream, after
placing the entrance and before play. The source marker's canonical
price string agrees with `world.trove_portal`, which owns price, spent
state, receipt, and chosen destination. The default price owner is
`policy/world/trove/toll.lua`; a mod can replace that Lua file while
retaining its `roll`, `valid`, and `encode` contract. Item prices name an
item ID, quantity, minimum plus, and optional ego and artefact. A rune
price proves saved rune progress without consuming the rune. The
no-piety route lowers current piety to 15 after accepted entry; conversion
to Ashenzari after finding the gate blocks that route. Import shared
item, species, god, and component IDs where they are used.

To add a price kind, put one Lua module at
`policy/world/trove/prices/<kind>.lua` in the mod directory. It returns an
object with `id`, `valid(price)`, `name(gate)`, `match(ctx, player, gate)`,
`commit(ctx, player, gate, accepted)`, and `valid_receipt(gate)`. Optional
`describe(gate)` and `offer(gate)` supply inspection and confirmation text.
The module uses the saved gate fields (`item_id`, `quantity`,
`minimum_plus`, `ego_id`, `artefact_name`, `source_rune_index`) for its
own price meaning. Its `commit` returns `{ kind, item_id, quantity }` as
the saved receipt; `valid_receipt` checks it against the original price.
Replace `policy/world/trove/toll.lua` to include that kind in the roll pool.
The payment, save, and Go engine files discover the kind automatically.
See `internal/script/testdata/trove-price-mod/policy/world/trove/prices/gold.lua`
for a small working example that spends from the real wallet owner.

The default source shop option reads only stock from shops whose entrance
appears in the player's saved map memory. `ctx:remembered(level_id, x, y)`
returns the remembered terrain ID or `nil` for an unexplored cell. This
keeps an undiscovered shop from influencing a Trove's rolled price.

Downstairs first presents a free confirmation tied to that gate's entity
ID. The confirmed command rechecks the marker and live resource, then
stages and populates a complete reward floor. Only after staging succeeds
does `policy/world/trove/payment.lua` debit the resource and
`policy/world/trove/travel.lua` save the exact return address in
`character.trove_visit`. Save validation joins the marker, Akara gate,
receipt, room, and visit without rerolling the price or destination. The
[Trove snapshot index](level-snapshots/trove/index.txt) shows all 21
reward floors as text for visual review.

These content categories validate their effective definitions at startup. A
missing cloud or trap effect path fails before play; a malformed shop weight
fails before stock generation. Import their IDs from `ids.clouds`,
`ids.traps`, or `ids.shops` at use sites, and read the corresponding catalog
validator if you need the exact accepted fields.

### Wizard Lab gates and source rooms

Wizard Labs use eleven entrance maps under `vaults/wizlab_entry/` and fifteen
whole-floor destination maps under `vaults/wizlab/`. The bundled files retain
the original DCSS `.des` MAP rows. Each entrance's `O` becomes a timed gate;
the source 600–800-turn countdown begins when the outside floor is populated.
The portal may expire while the player is elsewhere. Entry saves the exact
outside level and gate coordinate, and every authored `<` in the selected lab
returns there. An occupied return cell refuses travel until it is clear.

To add a lab, place one `.des` file under `vaults/wizlab/` in a higher mod
layer. Give it a unique `NAME`, `DEPTH: WizLab`, a positive source weight,
an `ORIENT: encompass` whole-floor map, and at least one `<` exit. The
effective catalog sorts candidate IDs before drawing by weight, so adding a
file does not make selection depend on filesystem order. To replace one
bundled lab, use its exact relative path. To remove a lab from ordinary
selection while keeping its definition available, give it zero weight.
Entrance maps use the regular `.des` branch/depth and chance grammar;
Vaults gets one special five-percent gate attempt rather than a second
ordinary room draw. `mu_enter_wizlab_7` has no Vaults weight.

For source-position Lua, keep the MAP and static declarations in `.des`.
A line such as `: vault.run("wizlab_wucad.site_1")` calls a named method in
`policy/generation/vaults/wizlab/wizlab_wucad.lua` at that precise point in
the source operation sequence. The hook's `api` can emit a directive or a
typed marker. Use `api:record` for a marker that must stay attached to a
cell before a later `SUBST` erases its glyph; Zonguldrok's `M`, `D`, and `L`
callbacks demonstrate this. See the general [vault hook contract](#vault-maps-and-lua-hooks)
and [context reference](#the-game-context-ctx) for the difference between
placement `api` and runtime `ctx`. The planned DES-local hook consolidation
remains a TODO; executable Lua currently lives in separate Lua files.

Live callbacks belong to small event owners under
`policy/world/wizlab/events/handlers/`, matched by marker identity through
the effective VFS. A handler creates an Akara component from real transformed
marker positions. A focused system or monster-death hook runs the rule;
the corresponding save validator checks the component against its source
markers and changed terrain. The bundled examples cover Doroklohe's
three-phase wall collapse, Wucad's shared numbered messages and monks,
Borgnjor's guarded lost-soul summons, and Zonguldrok's grave waves, door,
and one-shot lich. Add a new handler file for a new lab behavior. Keep its
constants with the rule and give it a dedicated component only when it has
mutable state; do not add its behavior to a central lab-name switch.
Zonguldrok's permanent grave actors also have event provenance: they do not
spend an initial Dungeon roster slot, and the saved encounter death count
bounds the extra XP that those actors can grant.
Each source event clock must be unique on its placed floor. Population checks
this before portal entry commits, so a duplicate marker in a replacement map
leaves the outside gate intact and reports the owning lab.

The [Wizard Lab snapshot index](level-snapshots/wizlab/index.txt) opens all
fifteen generated 80×70 floors and lists every return arch with its exact
outside test gate. Regenerate it with the environment command in the
[snapshot guide](level-snapshots/README.md). Run the Lua event test and the
integrated map/travel tests when editing a lab:

```sh
go test ./internal/script -run 'TestLuaRules/wizlab' -count=1
go test ./internal/game -run 'TestWizlab' -count=1
```

## Desolation of Salt maps and rules

The Desolation of Salt is a one-floor timed portal branch. Its source content
is split into nine entrance maps in `vaults/desolation_entry/`, 54 ruin helpers
in `vaults/desolation_ruin/`, and three complete floors in
`vaults/desolation/`. Each committed `.des` file retains its original MAP
rows. The Lua owner under `policy/generation/desolation/` makes one weighted
floor choice; the source `SUBVAULT` directives choose ruins from the effective
`desolation_ruin` tag pool. Sorting candidate IDs makes the draw independent
of file enumeration order.

To add a ruin, add a single `.des` file under `vaults/desolation_ruin/` with a
unique `NAME`, `TAGS: desolation_ruin`, and a MAP that fits the authored
12-cell ruin slots. It does not need a depth declaration: the parent
Desolation floor chooses it by tag. A larger helper cannot fit the source
slots and will fail placement. To add a complete floor, add one `.des` under
`vaults/desolation/` with `DEPTH: Desolation`, `ORIENT: encompass`, at least one
`KFEAT: < = exit_desolation`, and a MAP that fits the 80×70 canvas. Source
weights live in `WEIGHT` directives. Use the exact bundled relative path to
replace a map in an overlay.

Entrance files carry `DEPTH: Elf, !Elf:$, Vaults, !Vaults:$` and the
`chance_desolation` and `vaults_desolation` tags. The former gives an ordinary
five-percent chance in Elf; Vaults uses one special room draw after Wizard
Lab's draw, so a successful Desolation roll replaces that choice. The Lua
hook `: vault.run("shared.portal")` draws the 600–800-turn lifetime, attaches
the timed marker to `O`, and gives that cell the live entry feature. Its
saved ECS clock begins when that outside floor is populated, keeps running
while the player is elsewhere, and replaces the gate with `expired_portal`
when it ends. Every source exit returns to the precise outside gate cell.

Named hooks in `policy/generation/vaults/desolation_entry/`,
`desolation_ruin/`, and `desolation/` port source script statements at their
original DES positions. A hook receives a placement `api` for emitting DES
directives or typed effects; gameplay systems receive the live `ctx` described
in [the context reference](#the-game-context-ctx). The ruin setup hook adds
monster slots and sparse reward substitutions. Floor hooks describe the
salt border and ruined-idol display name; the temple hook may shuffle three
source groups. Salt fog machines stay as DES markers and run through the
shared fog ECS system. Source hooks remain separate Lua files for now;
the DES comments mark the planned consolidation.

The slug entrance shows how to port a source `dgn.delayed_decay` call:
its hook emits a real `never_decay` corpse item plus a typed
`DELAYED_DECAY` record on the same keyed glyph. The generic Lua system
reads that source record when the player sees the authored cell, clears
the corpse's saved preservation flag, and lets ordinary corpse aging take
over. A `FEATURE_NAME` hook stores the source feature alias and local name;
generation resolves the alias and placed bounds, and the read-only cell
view exposes the name without changing terrain collision or its glyph.

The [Desolation snapshot index](level-snapshots/desolation/index.txt) opens
all three generated floors and lists each return arch and its exact outside
test gate. Regenerate them with the command in the
[snapshot guide](level-snapshots/README.md). Run the source and live travel
tests after editing this domain:

```sh
go test ./internal/script -run 'TestLuaRules/desolation' -count=1
go test ./internal/game -run 'TestDesolation' -count=1
```

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

Wanderer is deliberately different from fixed-grant jobs. Its
`policy/character/wanderer.lua` owner selects roles and stats, then calls
`wanderer_gifts.lua` for strong, decent, and extra gifts and
`wanderer_spells.lua` for magic gifts. Those decisions use the named
`constants.rng_streams.WANDERER` stream so an added gift draw does not shift
unrelated character creation. The wand and concealment-scroll groups are
chosen once earlier by `policy/item_generation/item_sets.lua` and saved on
the player. Gift policies call `item_sets.choice(ctx, player, set_id)`;
they must not choose another member of the set locally. A mod replacing a
Wanderer gift policy should keep its grant shape (`kind_id`, `quantity`,
`plus`, `ego`, `charges`) and return spells by registered ID. The normal
starting-gear and spell-record owners then create and save those results.
Wanderer derives player-book eligibility from the effective item catalog,
so adding a registered spell to a book's `generation.spells` list makes it
eligible for the appropriate gift school. Source spells use numeric IDs for
their candidate order; a new mod spell without one sorts after them by ID.

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

### Demonspawn facets and future traits

Demonspawn ancestry is selected once during character creation. Every
facet is one discoverable file under `content/demonspawn_facets/`. A facet
declares a stable ID, one tier from `constants.demonspawn_facets`, three
ordered mutation IDs imported from `ids.mutations`, and three timing
windows from the same facet constants. Body facets also name a slot from
`constants.armour_slots`. The selector will not choose two body facets
for the same slot. `elemental` and `cloud_producing` are optional flags;
the selector rejects a group containing two facets with either flag.

For example, to add a three-rank body facet, place one file at
`content/demonspawn_facets/my_claws.lua` in your mod directory. Import
`constants.catalog`, `constants.demonspawn_facets`, `ids.mutations`, and
`constants.armour_slots`; build a local `definition` table with `id`,
`tier`, `mutations`, `windows`, and `body_slot`; then call
`register.definition(categories.DEMONSPAWN_FACETS, definition)` and
return it. [This file](../internal/script/testdata/demonspawn-facet-mod/content/demonspawn_facets/test_claws.lua)
is a runnable example. Each facet's requested ranks, and the total
ranks across a selected set, must fit their mutations' `max_level`.
Impossible mod definitions fail at character creation. A file at the
same relative path as a bundled
facet replaces that one definition. IDs are stable across saves, so
changing an existing ID creates a different facet rather than renaming
its saved records.

`policy/character/demonspawn.lua` validates the effective catalog,
selects one body, one scale, two secondary, and one final facet. One in
ten starts chooses three distinct body slots instead of a scale. The
owner orders each facet's grants within its timing windows, assigns
distinct levels from XL2 to XL27, and writes one
`character.demonspawn_trait` ECS entity per grant. The entity stores its
player owner, facet ID, rank, mutation ID, level, and whether it has been
granted. It is future player state, so save/restore keeps it. The named
`character.demonspawn_ancestry` component records the highest XL the
player has reached. Ru can lower the current XL without lowering that
history, so restore can verify every grant flag against it. The named
`constants.rng_streams.DEMONSPAWN` stream isolates these draws from other
content. File load order cannot change the candidate order; registered
IDs sort before the selector samples a tier.

Level gains call `demonspawn.grant_level(ctx, player, level)` before HP
and MP formulas. The mutation transition owner applies the rank and the
saved `granted` flag prevents a second grant after level loss and regain.
Other rules should call `demonspawn.has(ctx, player, mutation_id)` to ask
about a future trait. Ru uses that API to withhold Frail when a future
Robust facet is scheduled. Do not check only current mutation levels for
that rule; Robust may not arrive until much later. Restore validation
checks the saved schedule's facet shapes, slot conflicts, ranks, levels,
and attained mutation grants.

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

## Orb run and escape

The same-path override rule also applies to the Orb run. The saved player
component `character.endgame` records whether the character is exploring,
escaping with the Orb, or finished. `policy/character/endgame.lua` owns the
Orb pickup and Dungeon exit transitions, while
`policy/character/orb_run.lua` selects periodic defenders. A mod can override
either policy at the same relative path. An Orb is a real floor item with
the catalog ID `ids.items.ORB_ZOT`; picking it up consumes that entity and
changes the saved phase instead of adding an inventory stack. The terminal
uses the generic `session.outcome` policy to distinguish a win from leaving
without the Orb. If a mod changes these transitions, keep its player phase
schema, save validator, and outcome policy consistent so a restored game can
resume the same run.

## Vault maps and Lua hooks


The map declarations (`NAME`, `DEPTH`, `WEIGHT`, `TAGS`, `MAP`, and the
placement directives) follow DCSS DES syntax. The `: vault.run(...)`,
`: vault.veto(...)`, and related named hooks are **Crawl Go extensions**.
Legacy DCSS allows executable Lua directly in a `.des` file; this engine
keeps executable Lua in modules under `policy/generation/` and resolves a
named hook to one of those modules. A source `.des` file with its original
inline Lua cannot be dropped in unchanged. Port its script into a Lua
module and replace that script site with the matching named hook.

For example, `vaults/layout/layout_cave_pools.des` contains
`: vault.run("layout_cave_pools")`. The DES parser records this declaration;
there is no global `vault.run` Lua function to call yourself. When the
layout selector chooses that map, the layout catalog invokes the hook
resolver. Because the map is in the `layout` family, the resolver loads
`policy/generation/layouts/layout_cave_pools.lua` and calls its exported
`layout_cave_pools(api)` method. That method returns the painted rows and
generation metadata; the catalog then completes connected stairs.

The implementation path is short: `policy/generation/vaults/des.lua` parses
the `: vault.run(...)` line into a named operation;
`policy/generation/vaults/hooks.lua` resolves its module and method and
checks that the method exists. The chosen layout calls the resolver from
`policy/generation/layouts/catalog.lua`. Ordinary placed vaults run their
named hooks through the same resolver in the vault placement path. These
paths are relative to the embedded mod root (`internal/modfs/builtin/` in
this repository), so a layered mod can replace a handler at the same path.
The `.des` line declares when to call a method; the actual Lua function is
assigned to the table returned by that module. To locate or add a hook, use
this map from the `.des` file's family and hook argument:

| `.des` family and argument | Lua module | Function to export |
| --- | --- | --- |
| `layout/layout_cave_pools.des`, `layout_cave_pools` | `policy/generation/layouts/layout_cave_pools.lua` | `layout_cave_pools(api)` |
| `arrival/dpeg_arrival_water_fire.des`, `choose_water_fire_layout` | `policy/generation/vaults/arrival/dpeg_arrival_water_fire.lua` | `choose_water_fire_layout(api)` |
| `coc_end/coc_grunt.des`, `shared.serpent_of_hell` | `policy/generation/vaults/coc_end/shared.lua` | `serpent_of_hell(api)` |

These are paths inside the mod root. The first path segment of a dotted
argument selects a different module in the same family; the second names its
method. `hooks.validate` reports a missing module or method before placement,
and `hooks.run` calls the selected function when the map reaches that hook.
The `api` is the vault generation context described below, not the game
`ctx`; it provides bounded random draws and typed map operations.

A procedural map can leave `MAP` empty and put `procedural_map` in its
`TAGS`. Its named run hook calls `api:resize(width, height, fill)` to create
the local cell matrix, then `api:set_cell` to paint it. Subsequent emitted
directives operate on those cells at the hook's position. The bundled
`vaults/variable/special_room.des` is a complete example: its hook builds a
variable rectangle, emits `SUBVAULT: O : special_room`, and a weighted
`vaults/builder/special_room_*.des` helper fills that region. The engine
places the result through the same path as an authored map, including
monster population, saved parent and helper IDs, and sparse mod overrides.
Use this pattern when a map's dimensions or geometry depend on a generation
draw; a fixed map should keep its cells in `MAP`.

For Hell, source entrance maps live under `vaults/hell_entry/`. They carry
`chance_enter_hell`, `DEPTH: Depths`, and a keyed `enter_hell` feature.
The ordinary chance stage discovers them by tag and selects one eligible
map by source weight. `vaults/hell_entry/hell_entry.des` is the one-cell
`fallback_enter_hell` map if a selected entrance cannot fit. The live
`DNGN_ENTER_HELL` cell invokes `policy/world/hell/travel.lua`, which opens
the persistent Vestibule and remembers the outside return gate. This travel
policy is distinct from a generation hook: a `.des` hook configures a map
while it is built; the world policy acts when the player uses its gate.

After travel lands on any Dis, Gehenna, Cocytus, or Tartarus floor,
`policy/world/hell/effects.lua` runs the source Hell arrival draw. Its
protected, quiet, and loud paths use the player's saved origin and the
`hell_effect` RNG stream. The prose is in `data/hell_effect_messages.lua`,
so a mod can replace that file without changing punishment odds. The
policy applies temporary bad mutations, HP drain, and stat loss through
their existing state owners. A generation hook cannot cause an arrival
effect: it has no live player `ctx`, and the effect must recur on revisits.

The four ordinary Hell branches discover maps in `vaults/dis/`,
`vaults/geh/`, `vaults/coc/`, and `vaults/tar/`. They also share
`vaults/hells/`; Gehenna's maze helpers live in `vaults/geh_lava_maze/`.
The matching Lua generation hooks are under
`policy/generation/vaults/<family>/<map_name>.lua`. A source map whose
static dimensions exceed the ordinary 40×35 Hell grid remains in the
catalog but is skipped before the weighted map draw. Travel through the
four Vestibule gates belongs to `policy/world/hell/travel.lua`, while
live marker callbacks belong to `policy/world/vault_trigger_callbacks/`.

The seventh floors use the `dis_end`, `geh_end`, `coc_end`, and `tar_end`
families. Each branch chooses one weighted controller map, and a controller
may place tagged child maps after it fits. For example,
`vaults/coc_end/coc_grunt.des` declares
`: vault.run("shared.serpent_of_hell")`; the resolver calls
`serpent_of_hell(api)` in
`policy/generation/vaults/coc_end/shared.lua`. That hook reads the single
saved Hell branch chosen for the Serpent and emits a monster directive only
on its home floor. The choice is made before generation and survives saves;
loading the four end families in a different order does not change it.
Generation hooks only configure the map. A delayed event, such as the
iron statue that awakens after Dispater dies, is recorded as a saved marker
and handled by `policy/world/vault_trigger_callbacks/dis.lua` during play.

| DES declaration | When its Lua method runs |
| --- | --- |
| `: vault.run("method")` | At that line's position among the map's directives; it may emit more typed directives. |
| `: vault.validate("method")` | After layout build, before stairs; for a placed vault, after DES substitutions and before terrain projection. End layouts also validate on restore. |
| `: vault.veto("method")` | After a candidate map is placed; a true result rejects that candidate. |
| `: vault.post_place("method")` | After a selected controller is placed; it may place tagged child maps. |

For an ordinary vault, `: vault.run("configure")` in
`vaults/arrival/example.des` resolves to the `configure(api)` method in
`policy/generation/vaults/arrival/example.lua`. A reference such as
`vault.run("shared.configure")` loads `shared.lua` in the same family.
The method name is a declaration, not executable DES Lua. Define that method
on the local table returned by the Lua module. The generation `api` exists
only during map selection and placement; it is not the live game `ctx`.
Use `api:emit` to insert a DES directive at the declaration's position or
`api:record` to create a typed placement record. A hook that needs to act
later, after the player moves, must record a persistent effect and leave its
live behavior to a system.

On an end map, `api:run_choice(key)` reads a choice saved on the player
before generation, and `api:unique_seen(monster_id)` reads its saved unique
history. Neither method rolls or changes that history. A mod that needs a
run-wide random decision should make and save it in a live policy before
selecting the map, then let its hook read the result. This prevents map
load order and rejected placement attempts from changing the decision.

When the original DES script computes a value before intervening directives
and uses it later, split it into two named hooks at those positions. The
first calls `api:remember(name, value)`; the second calls
`api:recall(name)`. That memory belongs only to this placement attempt. It
does not enter the save and cannot leak into another vault. The Swamp hydra
murder den uses this to roll its head count before substitutions, then emit
its monster declaration after the static plant declaration.

A map's `vault.post_place` method can also call `api:recall(name)` for a
value remembered by an earlier `vault.run` in that same map. The Orc
community town hall rolls its house count before the map's substitutions,
then places that many child houses after the town hall fits. The value is
discarded with the placement attempt; it is not a persistent game setting.

Zot gives three concrete lookup examples. A Depths-side file under
`vaults/zot_entry/` calls `vault.run("shared.entry_setup")`, so the resolver
loads `policy/generation/vaults/zot_entry/shared.lua` and calls its
`entry_setup(api)` method. `vaults/zot/grunt_zot_stairs_overgrown.des` calls
`vault.run("configure_trigger")`, which resolves to the same-named module
under `policy/generation/vaults/zot/`. That generation hook writes typed
markers; `policy/world/zot_overgrown.lua` and the saved
`world.zot_overgrown` ECS component own the later LOS and turn behavior.
The `vault.validate("orb_exit")` declaration in
`vaults/layout/hall_of_Zot.des` resolves to
`policy/generation/layouts/hall_of_Zot.lua` and checks the final Orb map.
These are ordinary relative paths inside the effective mod layer. Replacing
one module at the same relative path replaces that hook without editing the
engine or another vault file.

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

A layout with `PLACE: Vaults:$` (or another branch floor) wins that exact
floor before the ordinary `DEPTH` weighted draw. It is not part of the
ordinary layout pool on other floors. This is how an end-level map owns its
fixed location without a branch-specific Go switch.

Some branches also name one required end layout in their content definition.
Zot names `hall_of_Zot`, because that map owns the Orb. An added
`PLACE: Zot:$` layout cannot displace it, and giving the effective Hall
weight zero closes Zot:5. To change that contract deliberately, override
the branch content definition as well as supplying the replacement layout.

An authored layout keeps its terrain under `MAP` and needs no run hook.
The layout owner places it through the ordinary vault operation engine,
then completes connected stairs. The two `layout_pan_divisions_*` maps
show this path: they request weighted helpers by `SUBVAULT` tag, while
each helper lives in its own `vaults/builder/*.des` file. Source cells
outside a helper's tagged region stay with the parent, even when their
rectangles overlap. The layout catalog can select these two ordinary
Pandemonium layouts; the Pan region generator also selects its primary
Pan map and optional supporting maps from the effective `.des` catalog.

The run method receives `api.ctx`, `api.branch`, `api.depth`, and
`api.absolute_depth`, plus `api.width` and `api.height` for this floor's
builder extent. Build the grid with
`policy.generation.grid.new(api.ctx, api.width, api.height)`, carve it, and return a table containing
`builder` and `rows = builder:rows()`. The catalog calls a named
`vault.validate` method if the `.des` file declares one, then places missing
ordinary stairs in a connected region. A failed source validator gets up to
64 draws of the same layout. Positive-weight Dungeon hooks are checked at
startup; a hook from another branch is checked when that layout runs.
Import the shared geometry helpers from `policy.generation.layouts` and keep
source-specific choices in your layout module.

Layouts that surround an authored primary can declare
`TAGS: requires_primary_vault` and a named `vault.veto("veto")` method.
The generator selects and places the branch's primary map first, then
passes its live builder as `api.builder` and its inclusive footprint as
`api.primary_vault = { x1, y1, x2, y2 }` to the run hook. The veto method
receives the same `api` before carving and returns true to reject that
layout choice. Draw only outside the primary cells; the shared stair pass
also reserves them. `layout_geoelf_castle.des` and its matching Lua module
show this contract on Elf:3. Ordinary layouts receive no preplaced builder
and should create one through `grid.new` as above.

`api.map_parameters` is a list of generation mode names supplied by the
floor owner. It currently contains `"central"` when a centred primary
requested a compatible layout, or `"layout"` otherwise. The Halls family
reads it through its invocation-local runtime. Treat this as floor context,
not persistent state: a saved map contains the resulting terrain and typed
records, not a live hook object. A layout that paints source terrain such
as shallow water returns a `SOURCE_FEATURE` record with `base_glyph` set to
the collision glyph initially painted on the builder. The generation owner
retires every earlier spatial record when a later authored map takes its
cell, including monster and item spawns. This applies even if both maps
render the same placeholder glyph. The retired record stays in saved map
history with `overridden = true`, but population gives it no effect.

For a cellular map, `policy.generation.layouts.subdivision` partitions the
grid, `cell_graph.edges` finds shared borders, and `cellular_groups.new`
tracks cardinal and diagonal neighbors without global state. The bundled
Cellular Growth and Gridlike hooks show two uses: one spreads wall groups;
the other weights room, corridor, and wall tiles before painting branch
variants. Gridlike's weighted room materials live in
`policy/generation/layouts/gridlike_materials.lua`. Override that path to
change the pairs, or add a separate layout to use a different tiler.

The weighted delve layouts use `policy/generation/layouts/delve.lua` to
grow winding floor from a frontier of diggable walls. Each map owns its
parameters and finishing rules: `layout_twisted_cross.lua` gives Depths
four distinct arms, `layout_twisted_circle.lua` reserves Zot rooms before
carving passages, `layout_spider_delve.lua` draws Spider's neighbor and
connection settings, and `layout_cocytus_delve.lua` keeps a dry stair route
separate from water and teleport-restricted side floor. Their `.des` files
declare branch weights and name the Lua methods. Put branch-specific
carving policy in the layout module, not in the shared selector.
`delve_shapes.lua` supplies geometric painters used by those hooks.

If a procedural layout places keyed effects or monsters, return typed
`records` beside `builder`. Gridlike's fill module shows how source plant
glyphs become ECS monster records and how keyed terrain properties survive
Go save/restore. Use the shared effect IDs from `constants.vault_effects`
and stable monster IDs from `ids.monsters` at the point of use.

For Shoals layouts, return a `heightmap` beside `builder` and `rows`.
It is an 80×70 array of integer elevation rows. The level saves these
values separately from visible terrain so rising and falling tides can
change water without losing the underlying coast. The bundled
`layout_shoals.des` declares `vault.run("layout_shoals.generate")`;
`policy/generation/layouts/layout_shoals.lua` builds the array and grid.
If a mod omits the heightmap, the engine derives threshold elevations from
its initial terrain, then applies placed vault terrain and keyed `FHEIGHT`
and `KPROP: ... = no_tide` declarations. This keeps authored rune huts safe
from tides even when a mod provides its own Shoals layout.

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

### Vaults primary layouts and rooms

Vaults:1–4 use eleven primary layouts in `vaults/layout/layout_vaults_*.des`.
Each map's named hook in `policy/generation/layouts/` paints its broad
motif. The shared `policy/generation/layouts/vaults/build.lua` then inserts
rooms before the ordinary stair and secondary-vault passes. A primary hook
returns its builder, typed room records, room IDs, and protected cells;
those IDs and records travel through population and save/restore. Vaults:5
uses the committed `vaults_vault` whole-level `PLACE: Vaults:$` map and its
four selected quadrant helpers. Its named validator requires one silver rune
record and one rune helper both when generated and when restored from a save.

To add a Vaults room, create one `vaults/vaults_room/<name>.des` file with a
unique `NAME`, an eligible `DEPTH`, source-style `MAP`, and one of the tags
`vaults_room`, `vaults_empty`, or `vaults_hard`. The room picker discovers
the file, sorts candidates by ID, and applies its effective DES weight.
The standard and hard pools have per-floor limits; an ineligible room or a
failed fit does not replace an already placed room. Keep fixed terrain and
entity directives in the `.des` file. If the room needs a calculated choice,
declare a named hook and put its Lua handler under
`policy/generation/vaults/vaults_room/<name>.lua`. The same hook naming and
`api` rules described below apply.

The branch definition sets `end_layout_required`, and
`policy/generation/floor_availability.lua` admits the final floor only when
the effective layout catalog has a positive-weight explicit `PLACE` map for
it. A same-path mod override can replace that map and its named hook. The
save validator calls the end map's `vault.validate` hook against its saved
helper IDs and typed records, so the hook must also check the composition a
modder wants to preserve.

Slime:5 is an authored whole-floor example. Its complete source geometry
is in `vaults/layout/slime_pit.des`; `: vault.run("mark")` calls `mark(api)`
in `policy/generation/layouts/slime_pit.lua` at that directive's position.
That method emits typed markers for the Royal Jelly and each inner clear
stone wall. `: vault.validate("validate")` calls the same module's
`validate(input)` after generation and on restore to require one source
Royal Jelly and one real slimy rune. Generation turns the wall markers into
saved `world.slime_seal` components. The Royal Jelly's death callback is a
separate gameplay rule at `policy/combat/monster_death/slime_pit.lua`; it
receives the live game `ctx` and calls `policy/world/slime_seals.lua` to
open those walls. Jiyva's one-time six-star reward uses that same owner;
`world.enter_level` applies it if the reward predates this floor. The `.des`
hook receives the generation `api` and does not have access to live actors.
Restore checks every seal marker against the effective authored `n` cell, so a
saved marker and component cannot both disappear unnoticed. To replace
this floor, override `vaults/layout/slime_pit.des` at the same relative path;
keep its stable `NAME` and the source rune and guardian records, or the
validator will reject the map. Override its Lua handler path too if the
replacement needs different marker logic. A sparse override test lives in
`internal/script/testdata/slime-end-mod/`.

To protect map cells from Jiyva, add a source-format property directive
such as `KPROP: O = no_jiyva` to the `.des` file. `O` refers to every
matching `MAP` cell after its map transform. The live jelly policies read
the resulting typed records, so the same cell blocks item pursuit,
feeding, active-floor spawning, and off-floor eating. The constant is
`constants.vault_properties.NO_JIYVA`; use that import in Lua instead of
repeating the string. Slime:5 is the one special case: after all its saved
clear-stone seals open, only properties sourced from `slime_pit` cease to
block Jiyva. A `no_jiyva` property from another map, such as Aquarium,
continues to protect its own cell. A mod can add this directive to any
ordinary vault without writing a hook.

The other Slime maps live in two auto-discovered directories. Add a
`vaults/slime_entry/<name>.des` file with `TAGS: slime_entry`, a positive
`WEIGHT`, and exactly one `KFEAT: O = enter_slime_pits` for an additional
Lair-to-Slime gate. The scheduled entrance selector sorts effective IDs,
draws by weight, and makes that keyed `O` cell the pending branch stair;
if no authored map fits, it retains a single-stair fallback. See
`internal/script/testdata/slime-entry-mod/` for a sparse example.
Put ordinary Slime maps in `vaults/slime/` with source-style
`DEPTH: Slime, !Slime:$`. Maps without explicit `ORIENT` join the
minivault draw; explicitly oriented maps join the branch-family regular
draw before minivaults. Both use the same DES substitutions, entity
records, protected-cell fitting, and save history. The final floor still
belongs exclusively to `slime_pit`.

Snake Pit uses the same effective vault owners. Add an authored Lair gate
under `vaults/snake_entry/<name>.des` with `TAGS: snake_entry` and exactly
one `KFEAT: O = enter_snake_pit`. The scheduled entrance selector tries
source-weighted entries in stable ID order and links the placed `O` cell to
Snake:1. If none fits, it leaves one ordinary branch stair. The eight
bundled entries include the source's small dummy entry; a sparse example
that adds a ninth entry is in `internal/script/testdata/snake-vault-mod/`.

Put ordinary Snake maps under `vaults/snake/`. Give each file an explicit
`DEPTH: Snake` or a narrower source range: the original `snake.des` sets
`default-depth: Snake` once for the rest of that file, but separately
loaded mod files have no shared default. Maps without `ORIENT` join the
minivault draw; oriented maps join the regular branch-family draw. Source
scripts become `: vault.run("configure")` at their original declaration
position with a same-named Lua file under
`policy/generation/vaults/snake/`. That hook receives a generation `api`
with local depth, branch bottom, absolute depth, source RNG methods, and
`api:emit`. Its choices are resolved before terrain and entities are
placed. The nine `snake_end` files still own Snake:4's mandatory ending;
ordinary Snake maps can also fit around it when their source rules allow.

Spider uses the same entry, ordinary, helper, and end owners. The eleven
`vaults/spider_entry/` maps compete for the scheduled Lair entrance, each
with a keyed `KFEAT: O = enter_spider_nest`. The 66 ordinary Spider maps
live in `vaults/spider/`; the 17 jumping definitions are in that directory
too, but the `nico_jumpspide` helper tag confines their child maps to the
jumping parent's `SUBVAULT` choice. Spider:4 still selects one of the nine
mandatory `vaults/spider_end/` maps. To add an entry, ordinary map, or
jumping helper, add a `.des` file to the corresponding family and give it a
unique `NAME`. Use `DEPTH: Spider` or a narrower source range; separate
files do not inherit another file's `default-depth` setting. Put any source
script choice in a named hook under `policy/generation/vaults/spider_entry/`
or `policy/generation/vaults/spider/` and call it at the intended point in
the `.des` declaration block.

For example, `vaults/spider/spiders_nest_spider_trap.des` declares
`: vault.run("configure")`. Its method in
`policy/generation/vaults/spider/spiders_nest_spider_trap.lua` records two
marker identities before `SUBST` changes their source glyphs. Population
then creates one saved ECS trigger entity per marker. The generic
`systems/world_vault_triggers.lua` system observes player movement, finds a
trigger at the entered cell, calls the named method in
`policy/world/vault_trigger_callbacks/`, and consumes the trigger. The
Spider callback warns at one marker and spawns awake redbacks around the
other. The map hook decides *where* an effect belongs; the callback handles
*what happens* when the player reaches it.
The source warning also requests a `crawl.more()` acknowledgment. The
current terminal client displays its message without a blocking prompt;
message acknowledgment is a separate UI behavior still to port.

Lair's 13 source entrances live in `vaults/lair_entry/`. Add a gate there
with `TAGS: lair_entry` and exactly one keyed
`KFEAT: O = enter_lair`. The scheduled Dungeon floor draws one weighted
gate, preserves its keyed stair in the save, and gives Lair:1 a reciprocal
exit. The dummy source entry remains a valid one-cell candidate. Lair's
ordinary rooms live in `vaults/lair/`; a modded room with `DEPTH: Lair`
joins the regular pool automatically. `wad_woods_*.des` demonstrates a
shared `woods.populate` hook: fixed vegetation, grass, and fog remain in
DES, while `policy/generation/vaults/lair/woods.lua` chooses monsters from
branch and absolute depth. A hook emits only the varying directives at its
authored position. See `internal/script/testdata/lair-vault-mod/` for a
sparse layer adding a Lair gate, room, and ending together.

Orc follows the same three-stage pattern. Add a Dungeon gate to
`vaults/orc_entry/` with `TAGS: orc_entry` and exactly one
`KFEAT: O = enter_orcish_mines`; add ordinary rooms under `vaults/orc/`
with `DEPTH: Orc`; add Orc:2 endings under `vaults/orc_end/` with
`PLACE: Orc:$`. The source file used `default-depth: Orc`, but each split
file declares its own depth so discovery order cannot change eligibility.
See `internal/script/testdata/orc-vault-mod/` for one sparse addition to
each stage. The source one-cell entry dummy remains a weighted candidate.

Swamp and Shoals complete the source Lair entrance families. Put a new
Swamp gate in `vaults/swamp_entry/<name>.des` with
`TAGS: swamp_entry` and one `KFEAT: O = enter_swamp`. Shoals uses
`vaults/shoals_entry/`, `TAGS: shoals_entry`, and
`KFEAT: O = enter_shoals`. The scheduled selector makes a source-weighted
draw from the effective family, fits the map around protected cells, and
links the final keyed O cell. A sparse mod can add files to either family;
see `internal/script/testdata/water-entry-mod/` for both examples.

Depths uses the same scheduled branch-entry owner at D:15. All eight
source maps live in `vaults/depths_entry/` and carry
`TAGS: depths_entry uniq_depths_entry chance_depths_entry no_monster_gen`,
`PLACE: D:$`, an explicit positive `WEIGHT`, `ORIENT: float`, and one
`KFEAT: O = enter_depths`. These declarations are written in every split
file because the original `depths_entry(e)` Lua helper supplied them at
parse time. The map and its keyed O cell remain authoritative; the
generator links that cell to Depths:1 and saves the selected map ID. To
add a gate, put one new `.des` file at the same relative family path.
`internal/script/testdata/depths-entry-mod/` shows a complete example.
The grave entrance also illustrates a local feature-name hook: its
`.des` file declares `vault.run("rename_gravestone")`, whose Lua method
lives in the same-named file under
`policy/generation/vaults/depths_entry/`.

Depths also has a separate whole-floor family under
`vaults/depths_encompass/`. Five maps have positive weights on Depths:2–3;
two have an explicit `PLACE: Depths:$` rule. The generation owner tries an
eligible encompassing map before an ordinary layout. Its `ORIENT: encompass`
MAP owns the floor, so ordinary secondary vaults are skipped. The shared
`uniq_d_encompass` tag permits only one such map in a run; later floors use
the ordinary layout path. A mod can add a map by creating
`vaults/depths_encompass/<name>.des` with a unique `NAME`, a Depths `DEPTH`
or `PLACE`, a positive effective `WEIGHT`, `ORIENT: encompass`, and the
shared uniqueness tag. A same-path file replaces a bundled map. The
`internal/script/testdata/depths-encompass-mod/` fixture demonstrates both.

These maps keep their original MAP syntax and static directives. Put any
calculated behavior in
`policy/generation/vaults/depths_encompass/<name>.lua` and declare it at
the intended point in the DES file with `: vault.run("method")`. A dotted
method such as `shared.profane_setup` instead loads `shared.lua` in that
family. Tagged `SUBVAULT` children are separate `.des` files, so a mod can
add another Profane temple or replace one Crystal Crosses arm without
copying the encompassing parent. The final Profane Halls gate uses the
child's keyed `enter_zot` feature for the scheduled branch link. The Lua
hooks receive the generation `api` described above; use
`api:branch_entry(ids.branches.BRANCH_ZOT)` for schedule-dependent choices.

The ten bundled Swamp entrances retain their source `MARKER` declarations
for fog machines. Population turns each marker into a saved ECS fog entity,
so a modded Swamp gate can use the same marker syntax without a new system.
The Shoals `elwin_shoals_entry_rooms.des` map also demonstrates
`: vault.validate("has_exit")`: after water substitutions, its named Lua
method checks that the branch stair can reach an edge of the map. A false
result rejects that map variant before any of its cells enter the level.

To make another one-shot movement marker, record a `MARKER` effect in a
generation hook with `glyph` and an `identity` of the form
`vault_trigger:<module>.<method>`. Place the glyph in the map. Define
`<method>(ctx, state)` on the table returned by
`policy/world/vault_trigger_callbacks/<module>.lua`. The `state` is the
saved `WORLD_VAULT_TRIGGER` component: `level_id`, `x`, `y`, `vault_id`,
`record_index`, `callback_module`, and `callback_method`. Read live actors
and terrain through `ctx`; store any continuing state in a component. The
generic system runs after movement and before traps, only for the player,
then destroys the trigger entity. Other `MARKER` identities are not treated
as callbacks. See the Spider trap module and callback for a complete pair.

If a callback creates a permanent monster after level population, give it
saved origin state so restore can distinguish it from the level's random
roster. The Lady of the Lake example uses `world.vault_spawn`, whose schema
and save policy tie the avatar to the source entrance and target markers.
That source-specific validator also prevents a saved avatar from claiming a
different map. A new callback with a different spawn rule needs a matching
origin and validation rule; simply calling `factory.spawn` creates a live
actor but does not establish its save provenance.

### Branch floor primary vaults

A branch floor with one required authored map declares a `primary_vaults`
entry in its `content/branches/` file. Each entry names its local `depth`
and vault `family`; `allow_dummy = true` permits a weighted choice that
leaves the procedural floor intact. Lair, Orc, Snake, Swamp, Spider, and
Shoals declare one final-floor entry. Elf declares three entries, for its
border check, Hall of Blades, and final hall. The fourteen Lair, sixteen
Orc, nine Snake, eleven Swamp, nine Spider, and 26 Shoals source
definitions live in matching `vaults/` subdirectories. Every file keeps
its `NAME`, final-floor `PLACE` when it is a selectable ending, and its
authored directives and MAP rows. Shoals also has four mapless controllers
that select child maps through source tags.

The primary selector discovers all effective files in the declared family,
sorts candidates by `NAME`, and makes a weighted draw before optional
CHANCE, PLACE, and minivault stages. A geometric floor redraw keeps that
same selected ending; it does not reroll the weighted pool. If no positive
weight primary map exists, that floor's stair is unavailable rather than
substituting an ordinary floor.

To add an ending, put one source-format `.des` file at
`vaults/<family>/<name>.des` with a unique `NAME`, positive effective
`WEIGHT`, and exact final-floor `PLACE` such as `Swamp:$`. A rune branch
also needs one real rune request matching its declared rune; Lair:5 has no
rune; neither does Orc:2. A same-path overlay replaces
a bundled map; a new filename adds a weighted candidate. If the map needs
a computed choice, put a named hook at
`policy/generation/vaults/<family>/<name>.lua` and reference its method
from `: vault.run("method")` at the intended source position. Swamp's
standard ending uses this for its one-in-eleven guardian choice. Every
Spider ending calls `shared.loot` to add the source reward requests; the
handler is at `policy/generation/vaults/spider_end/shared.lua`. A placed
map's `: vault.validate("method")` receives `api.cells`, the final DES
matrix before it touches the level grid. Return `true` to accept or `false`
to redraw the map; Snake Hunt uses this to keep its rune connected.

A mapless Shoals-style ending can instead declare
`: vault.post_place("assemble")` and `: vault.validate("require_rune")`.
Its `assemble(api)` method receives a controller API with
`api:place_maps(tag, count)`, `api:one_in(n)`, and
`api:random_range(first, last)`. `place_maps` selects from all effective
DES files with that tag, including files added by sparse mods, and returns
the number that fit. Check that return value for required children; an
error beginning `end vault could not fit on base layout:` asks generation
to redraw the floor while keeping the selected controller. Put the child
tags in `constants.vault_tags` and import them where used. For example,
`shoals_end_simple.des` names `assemble`, which is defined in
`policy/generation/vaults/shoals_end/shoals_end_simple.lua` and delegates
the shared probabilities to `shoals_end/finale.lua`.

For a mapless controller, the validation method receives the composed
`vault_ids` and either live `records` or saved `vault_records`. Check the
real rune's owning child ID and matching tag. The same method runs after
generation and during restore, so the rule cannot drift between them.
An authored full-map ending may own its rune directly or place a rune
helper through `SUBVAULT`. The helper must carry one of the parent's
declared `SUBVAULT` tags and appear in saved placement history. For
example, `shoals_end_hellmonk_storm_palace.des` reserves its `D` region
for the `storm_palace_rune` tag; one of the matching child `.des` maps
owns the rune record. A false-rune item may use the source `mimic`
modifier on `KITEM`; population then adds
the saved `vault.item_mimic` component. Pickup reveals the illusion
without granting rune progress.

Five Lair:5 endings are tagged `lair_end_small`. Their authored MAP has
`: vault.post_place("small_end.pair")`, whose method lives in
`policy/generation/vaults/lair_end/small_end.lua`. The controller chooses
one other fitting map with the same tag from the effective catalog, records
both IDs, and rejects a floor with no fitting partner. Restore checks that
the saved primary has exactly one distinct small-ending partner. A mod can
add another candidate with `PLACE: Lair:$` and
`TAGS: lair_end_small`, or add an ordinary weighted Lair ending without
that tag. The hook receives the controller `api`, not the game `ctx`.

Orc's `grunt_orc_gardens.des` is a mapless ending that places four
`grunt_orc_garden` helpers. Its Lua controller passes one theme, a unique
shop choice, and the first helper's boss role through the optional
`api:place_maps(tag, count, { settings = ... })` table. Each child reads
its own values with `api:setting(name)`; settings are copied for every
placement and do not enter another map's context. A child may use
`allow_dup`, so four placements can share one DES `NAME` while keeping
their own typed records. The mapful Orc community ending adds two big
houses and four to six small houses after its town hall. Both endings
validate those child counts on restore.

`pubby_orc_utopia.des` demonstrates a scheduled branch gate in an ending.
Its named Lua hook imports `ids.branches` and asks
`api:branch_entry(branches.BRANCH_ELF)` before
emitting the `enter_elven_halls` feature. The floor then moves the one
scheduled Elf stair link to that authored cell. Do not infer the gate from
the current hardcoded branch depth; a mod may change the schedule.

Elf uses the same hook lookup on three different primary floors. The Elf
branch definition selects one `elf_arrival` map on Elf:1, one `elf_blades`
map on Elf:2, and one `elf_end` map on Elf:3. Add a file under the matching
`vaults/<family>/` directory with `PLACE: Elf:1`, `PLACE: Elf:2`, or
`PLACE: Elf:$` to join that floor's weighted choice. The Elf:1 dummy is a
real choice: it leaves the procedural floor and its ordinary return stair.
Other arrival maps may author a `{` landing, which becomes the scheduled
return to Orc. The Hall of Blades maps request tagged `elf_blade_entry`
helpers through `SUBVAULT`; an added helper needs that tag and its own DES
file, but no registration list.

For a concrete Elf hook, `vaults/elf_blades/nicolae_elf_blades_crystal_corner.des`
declares `: vault.run("shared.hall_of_blades_monsters")`. The resolver loads
`policy/generation/vaults/elf_blades/shared.lua` and calls its
`hall_of_blades_monsters(api)` method at that exact declaration position.
The shared method emits the source monster slots and two separately chosen
dancing weapons; the `.des` file still owns the map and its ordinary
directives. A method named without `shared.`, such as
`: vault.run("configure")`, resolves to a method in the Lua file named
after that map's `NAME`. For example, the crystal corner's `configure(api)`
method lives in `policy/generation/vaults/elf_blades/nicolae_elf_blades_crystal_corner.lua`.
The original DCSS inline script is retained as nearby DES comments to
explain why the hook is at that position; comments do not execute. See the
vault hook table above for the timing of `run`, `validate`, and
`post_place`, and the hook API table below for the available random draws
and directive methods.

The successful primary map becomes the floor's primary vault ID and remains in
`vault_ids`. Its typed rune record is historical: picking up the ECS item
does not erase it. Restore checks the selected map's family and `PLACE`
rule, that ID in history, and exactly one matching rune record owned by the
selected map, its declared `SUBVAULT` child, or the selected controller's
validated child. Changing a
saved map's relative path or removing its
definition changes the ruleset and cannot silently rewrite that floor.


### Authored vaults

Vault geometry remains in DCSS DES map syntax under `vaults/arrival/`,
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

The ordinary Shoals family is an example of this split. Its 74 `.des`
files live under `vaults/shoals/`; computed choices live under
`policy/generation/vaults/shoals/`. For example,
`nicolae_shoals_island_circles.des` calls
`vault.run("configure_stairs")`, whose method in the same-named Lua module
emits the depth-dependent stair substitution. A sparse mod can add
`vaults/shoals/my_atoll.des` and, if needed,
`policy/generation/vaults/shoals/my_atoll.lua`; the effective catalog and
the hook resolver discover both by path and `NAME`. The
`internal/script/testdata/shoals-vault-mod/` fixture shows the complete
pair. The map remains authoritative for terrain and static directives;
the hook handles only choices that need generation facts or randomness.
The storm-palace finale's `BORDER_FILL` record makes exterior terrain open
sea after the other vaults are placed. The connector records a surviving
walkable route from each required stair to the finale, so this final fill
does not strand the player or drown later authored cells.

The ordinary Swamp family works the same way. Its 107 source definitions
live under `vaults/swamp/`; 104 own a `MAP`, while three mapless controllers
use `vault.post_place("assemble")` to choose child maps by tag. To add an
ordinary Swamp encounter, put a uniquely named `.des` file in
`vaults/swamp/` with `DEPTH: Swamp`, an authored `WEIGHT`, and a `MAP`. An
explicit `ORIENT: float` enters the branch's regular weighted selection;
omitting `ORIENT` makes it a minivault. Use `PLACE` only when the map needs a
specific floor rule. If a calculated choice is necessary, add a same-named
Lua module under `policy/generation/vaults/swamp/` and call its method from
the `.des` file. The sparse `internal/script/testdata/swamp-vault-mod/`
fixture shows a complete added map and hook.

Swamp's `grunt_lady_of_the_lake` shows where generation ends and gameplay
begins. Its `vault.run("configure_trigger")` hook records marker intent at
the O, `:`, and K glyphs. Once the map is oriented, the population path
materializes saved `world.vault_trigger` ECS components. Entering an O or
`:` cell calls `policy/world/vault_trigger_callbacks/lady_of_lake.lua`;
the callback reads the saved K target and attempts one awake avatar spawn.
Keep a later player action in a gameplay callback and persist its mutable
state in a component. A generation hook receives `api` and cannot use the
live game `ctx`.

Some source instructions remain typed level data while their visible effect
is being ported. Swamp's delayed corpse decay and the dead-mangrove feature
name are retained in vault records. Authored hydra head counts are saved on
ECS actors, but their full attack and display behavior still needs the
monster-domain implementation. A coloured draconian role keeps its base ID
in the saved actor override; additive base traits also need that domain.

#### Named transporters

Keep transporter geometry in the `.des` map. Assign one marker glyph to the
outbound portal and another to its landing, then give both the same
level-local name:

```text
MARKER: E = lua:transp_loc("my_portal")
MARKER: F = lua:transp_dest_loc("my_portal")
MAP
E..F
ENDMAP
```

The generation pass pairs markers after *all* vaults on the level are placed.
This lets separate serial pieces link to one another. Several outbound
markers may share a name and landing, but each name needs exactly one
destination marker. Missing, duplicate, and unused destinations are map
errors. Name the marker calls exactly as shown; the `lua:` prefix is part of
the DES marker syntax, while the game implements their behavior in
`policy/generation/transporters.lua` and `policy/world/transporters.lua`.
There is no inline Lua script to copy into a new map.

The resolver paints `DNGN_TRANSPORTER` at each source and
`DNGN_TRANSPORTER_LANDING` at its destination. Pressing either stair key while
standing on the source attempts a one-way trip. A blocked landing refuses
the command; a successful trip costs one movement action, may bring nearby
followers, leaves a short translocation cloud, and records the discovered
destination in the player's saved component. A mod that changes this policy
can override the corresponding Lua file by relative path. Its marker names
and saved link argument keys are imported from `constants.transporter`.

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
`policy.religion.names`. Worship rules are a separate domain.

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
`policy.religion.names` in a Lua hook instead of duplicating names there.
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

A vault monster can carry its own spellbook without changing its species
catalog file. For example:

```text
MONS: statue hp:12 hd:3 spells:throw_flame.53.magical
```

This places a statue with 12 HP, 3 hit dice, and one Throw Flame slot
offered at source frequency 53. Separate slots within a `spells:` value
with semicolons; the equipment separator is parsed
after spell tags. Repeating `spells:` offers alternative complete books and
chooses one at placement time. The chosen source text stays in the saved
vault record and actor component, so restoring a game cannot redraw a
different book. `spells:.` suppresses the species' normal spellbook. Spell
names must resolve through `ids.spells`, and each spell needs a Lua monster
effect with `plan` and `resolve`; an unknown name, frequency, or casting
flag fails with the `.des` source location. The available flag names follow
`constants.monster_spell_flags`, including `magical`, `natural`, `wizard`,
`priest`, `vocal`, `emergency`, and range flags.

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

An authored monster can carry a source `perm_ench:` modifier, for example
`MONS: rat perm_ench:corona`. The vault parser records the source name, and
population attaches both a live ECS status and a permanent marker to that
monster. Ordinary AI, vision, and combat rules read the live status; its
clock skips only the authored effect. Import the names from
`constants.vault_monster_enchantments` in Lua code. The supported source
names are `blind`, `confusion`, `corona`, `corrosion`, `dumb`, `mad`, `mute`,
`paralysis`, and `slow`; `dumb` follows paralysis and `mad` follows
confusion. The Elf defective-weapon vault retains source `corrosion` as a
permanent status; its full equipment penalty is still a gameplay gap. A magical
dispel removes the marker along with any status it removes, so a later
temporary application still has a normal lifetime. The actor's marker is
saved and checked against its selected `.des` expression on restore.

Vault hostiles normally start asleep. Add `generate_awake` to a `MONS:` or
`KMONS:` term to start that actor wandering, or use `TAGS: generate_awake` to
apply it to the whole map. Friendly and neutral actors start awake. The
`patrolling` term or map tag gives an actor a saved anchor at its spawn cell;
its idle AI chooses nearby cells and returns to that area after losing a foe.
Charm retires that anchor so an ally can follow the player, and a monster
leaving its floor loses the old anchor for the same reason.
The player can wake a sleeper by being seen, making audible noise, or hurting
it. These are live ECS behavior and patrol records, so a mod does not need a
second system just to make the source modifiers work.

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
| `api:pan_rune_count()` | Saved count of the five Pan runes; Pan region generation must supply it. |
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
| `api:remember(name, value)`, `api:recall(name)` | Carry a source script value between hooks in one map placement; recall errors if the first hook did not run. |
| `api:map_size()` | Return local width and height; an empty-MAP child gets its parent region's size. |
| `api:resize(width, height, glyph)` | Resize a procedural map's local matrix, filling new cells with one glyph; its final dimensions are used for placement. |
| `api:cell(x, y)` | Read the current zero-based local glyph, including earlier substitutions and hook edits. |
| `api:set_cell(x, y, glyph)` | Paint one zero-based local cell; out-of-bounds positions raise an error. |
| `api:run_choice(key)` | Read a saved player choice supplied to generation; return `nil` when unset. |
| `api:unique_seen(monster_id)` | Check whether the player already generated this unique monster. |
| `api:has_tag(tag)` | Check a tag on the current DES map. |
| `api:has_placed_tag(tag)` | Check whether an earlier successful child map in this composition carried the tag. |

The bundled `vaults/layout/vaults_vault.des` is a whole-level example.
Its `PLACE: Vaults:$` selects the last Vaults floor. Its Lua hook chooses
one prize quadrant and three ordinary quadrants, then the DES `SUBVAULT`
operations place individually discovered files from `vaults/vaults_end/`.
A new quadrant needs its own `.des` file, a suitable
`vaults_end_quadrant` or `vaults_end_quadrant_prize` tag, an `O` rune slot,
and `shared.loot` and `shared.rune` hook declarations. Keep its 27-by-23
source geometry in `MAP`; the shared rune hook uses `api:has_tag` for the
current quadrant and `api:has_placed_tag` to avoid a second real rune.

An empty `MAP` can be useful for a `SUBVAULT` helper whose shape comes
from its parent's placeholder region. Give that helper a named `vault.run`
method, read `api:map_size()`, and paint with `api:set_cell`. The coordinates
are local to the helper and start at zero. A child can inspect earlier
successful child tags with `api:has_placed_tag`; the game keeps this history
for one generation call, so it does not depend on file load order or a Lua
global. A failed helper fit never claims a name or tag. The selected helper
IDs and protected cells pass through the authored layout result for level
population and saves.

For a `vault.post_place` controller, `api:place_maps(tag, count)` draws
tagged children through the ordinary fitter. `api:place_tag_at(tag, x, y)`
draws one tagged child with its center fixed at the given whole-level
coordinates; it rejects a missing or unfittable child and records its
history through the same path. Tartarus's `tar_grunt` controller uses this
for Ereshkigal's chamber before placing its other decoration maps.

`SUBVAULT` may name several placeholder glyphs before the colon, as in
`SUBVAULT: ErH : nico_lavamaze_diaghalf`. The engine treats those glyphs
as one region for choosing and fitting a helper. This is how Gehenna's
authored lava maze joins an angled set of cells into one sub-vault. A
single-glyph declaration uses the same fitter.

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
five Pan runes, and Ignacio's decision is stored once across later levels.
Import rune item IDs from `constants.runes` and decision values from
`constants.pan_unique_decision`; do not retype their strings in a hook.
Rune pickup removes its floor entity and records its ID in
`character.runes` for save/restore and future branch checks.

### Pandemonium map files

The 141 active source Pan definitions are individual committed files under
`vaults/pan_entry/` and `vaults/pan/`. They retain their source `MAP` rows.
The one source-tagged `removed` controller is omitted because its intended
double-vault guarantee did not work. `pan_mini_dummy_balancer.des` is an
active weighted placeholder, so it belongs in the catalog but has no
traversable map to place. A mod can add another Pan map as one `.des` file
in the appropriate family; a same-path file in a later VFS layer replaces
the built-in definition.

Shared source script behavior lives in
`policy/generation/vaults/pan/shared.lua`; an individual map's behavior
lives beside it in a Lua module named for that map. A line such as
`: vault.run("shared.rune_p_lord")` calls the shared method at that point
among DES directives. The source script is retained in nearby comments
for explanation, while only the named hook executes. A Pan hook may read
`api:has_rune(rune_item_id)` and `api:pan_rune_count()` only when the Pan
generator supplies saved player rune facts. The count includes the demonic
rune and the four named lord runes. The five fixed rune/lure maps also read
`api:map_tag()`; their controller request tag decides whether O contains
the real demonic rune or a decoy. Do not infer that choice from file order.
For example, `lemuel_hellion_island.des` keeps its O cell and calls the
shared fixed-rune hook. That hook emits the item declaration; normal vault
population creates the floor entity, and normal pickup adds the item ID to
the saved `character.runes` component. Transit removes unclaimed floor
items with the old region while preserving collected rune progress.

`policy/generation/pan/region.lua` chooses the next region from the
effective Pan catalog. It uses the saved visit count and prior vault IDs,
not directory order, to make unique maps eligible or ineligible. The active
region is one level at Pan:1; a transit retires that level and its entities,
then installs a freshly generated one. `policy/world/pan/travel.lua` decides
what each source portal does. The game records the original entry cell once,
so a normal exit can find a free landing near that cell. An Abyss exit also
records the original return site for later Abyss escape. The saved Pan state
keeps the visit count, retired map IDs, active level ID, and return site;
restoring it does not regenerate the map or reroll its actors. A random
Pandemonium lord's generated name, colour, body, and spells live on its
`monster.pan_lord` component. To change those rolls, override
`policy/population/pan_lord.lua`; changing the static monster catalog row
alone does not alter an existing lord. Combat messages and the terminal
read the saved actor name, while the saved colour overrides the catalog's
base tint. Catalog monsters and clouds retain their source colour IDs too.
For `ETC_RANDOM`, `presentation.entity` marks the cell as animated; the
terminal requests a new nonblack IRGB colour from a UI-only random source
on each redraw, and `presentation.entity_color` maps that draw to a colour.
An idle redraw timer runs only while an animated cell is visible. A mod
changing this palette should edit `policy/presentation/colors.lua` and
`policy/presentation/view.lua`. Import the marker from
`constants.element_colours` in Lua code; do not draw from the saved
gameplay RNG.

Combat reads the lord's rolled spell slots through
`policy/combat/monster_spellbook.lua`, including when a Pain brand asks
whether those spells contain Necromancy. Its `MST_GHOST` identity has no
static spellbook catalog row, so a mod should update the saved lord profile
to change its spells.

`policy/combat/trample.lua` owns the generated lord's physical shove and
final follow. Its source size contest and terrain checks run during melee
contact. The combat coordinator calls its follow method after reactions, so
a dead or displaced attacker does not move into the defender's old cell.
Forced player movement also interrupts Passwall and activates an entered
trap. A mod changing this attack should keep the push and follow phases
separate and leave durable statuses to their ECS component owners.

After DES terrain and KFEAT choices are resolved, the Pan generator
converts source upstairs and escape hatches into transit portals, matching
the original branch's final terrain pass. Mod maps can therefore use the
original stair glyphs without creating ordinary stair links on Pan:1.

For a new Pan map, add `vaults/pan/<name>.des` with the appropriate `DEPTH`,
`WEIGHT`, and source group tags. If the map needs calculated directives, add
`policy/generation/vaults/pan/<name>.lua` and name its method in the `.des`
file with `: vault.run("method")`. A same-path file in a later mod layer
replaces either file independently. The hook receives the generation `api`,
not a live game `ctx`; persistent behavior belongs in a saved component and
a Lua system or policy. New maps join their weighted group through catalog
discovery, without an engine registry edit.

Generation hooks can attach an `ENTRY_MESSAGE` record for a lord realm or
rune site. The record is level data, so a future entry or a restored game
does not rerun map generation just to display a message. Pigsty's source
monster-death script instead becomes two typed marker records and a live
Lua death hook: its actor's saved vault origin locates the swineherd, and
the gate marker locates the grate after rotation.

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

## Add or replace a Gauntlet map

Gauntlet keeps its source `.des` maps in four layered directories:
`vaults/gauntlet_entry/` for timed gates,
`vaults/gauntlet/` for complete parent floors,
`vaults/gauntlet_arena/` for encounter chambers, and
`vaults/gauntlet_exit/` for minotaur rooms. Add one file with a new `NAME`
to extend a category. Use the same relative path in a higher `--mod-dir`
layer to replace an existing file. The game discovers these files through
the effective VFS and sorts eligible IDs before a seeded choice. Builds do
not run a source importer.

A parent `.des` owns visible geometry and its `SUBVAULT` sites. A named
Lua hook under `policy/generation/vaults/gauntlet/` may emit these
directives at the `: vault.run("name")` site. The generic nested-vault
API passes three values to the selected child's hook:

* `api:subvault_tag()` returns the exact tag selected by the parent, such
  as `gauntlet_arena_77_first`. Use it to distinguish chamber size and tier.
* `api:subvault_ordinal()` is the parent's station number for this helper.
  The arena hook uses it to name transporter endpoints on both sides.
* `api:subvault_setting("extra_items")` reads an optional value passed by
  that one `SUBVAULT` call. It does not persist between arenas or floors.

For example, a parent hook can call
`api:emit(directives.SUBVAULT, "a:gauntlet_arena_first", {
    extra_items = "fg|* / .",
})`. The production helper in
`policy/generation/vaults/gauntlet/shared.lua` supplies `shared.arena` so
a new parent can name a glyph, tier tag, and optional prize pattern without
reimplementing station numbers. Keep all script statements in a readable
Lua file for now; the paired `.des` contains a TODO to consolidate these
hooks into the map later. Lua remains outside Go source.

`api:emit` queues a directive until the current hook returns. When a later
choice depends on which helpers the first directives selected, place two
`: vault.run(...)` lines in the `.des`: an `opening` hook that emits those
helpers and a `finish` hook that draws the choice. The engine applies the
opening directives between the two calls. The four conditional bundled
parents show this pattern. A single hook would draw too early.

A replacement arena should retain its entry `P` and return `Q` marker
sites. A replacement exit needs exactly one live boss-room return arch,
normally declared with `KFEAT: < = exit_gauntlet`, and a viable minotaur
room. The parent map's own `<` arches do not count toward this requirement.
Generation checks named transporter sources and destinations
as a complete graph; save restore checks their exact cells and resolved
coordinates again. A malformed overlay fails before the staged level is
installed. Gauntlet rewards with `no_pickup` are protected from monsters,
while the player can still take them. The gate's duration is drawn when the
outside map is populated, and world time continues while that floor is
inactive. Long-range teleportation and Passage of Golubria are sealed
inside Gauntlet, but blinking remains legal.

For a visual check, run
`CRAWL_GAUNTLET_SNAPSHOT_DIR=/path/to/output go test ./internal/game -run TestGauntletAllParentLayoutsPopulate`.
The test writes an 80 by 70 text floor and a source-to-landing transporter
index for every parent map.

### Crypt branch maps and live markers

Crypt uses the ordinary branch schedule and three layered vault directories:
`vaults/crypt_entry/` for its Vaults-side gates, `vaults/crypt/` for its
Crypt:1 arrival and supplemental rooms, and `vaults/crypt_end/` for one
mandatory Crypt:3 ending. The bundled corpus has 13, 38, and eight maps in
those directories. Each `.des` file contains one original MAP block. Adding
`vaults/crypt/my_memorial.des` to a mod contributes one map to the eligible
pool; using a bundled relative path replaces just that file. The map's
`DEPTH`, tags, chance, and weight determine when the Lua generator may select
it. File names and directory enumeration order do not affect a seeded draw.

Keep conditional map decisions at their source position in a named hook. For
example, `: vault.run("choose_tomb_gate")` in
`vaults/crypt_end/quadcrypt_mu.des` calls the exported method in
`policy/generation/vaults/crypt_end/quadcrypt_mu.lua`. The method receives
the placement `api`, not a live `ctx`: `api:emit` inserts a directive before
later DES operations, `api:roll`, `api:coinflip`, and `api:one_in` consume the
saved layout stream, and `api:record` creates a typed placed effect. Keep
dependent rolls in separate calls if an intervening directive changes the
map. A hook module is an ordinary layered Lua path, so a sparse mod may
replace only that hook. Hook modules should return a local table whose
commented methods explain the map choice and its effect.

One Crypt:3 ending is mandatory. If it includes an authored
`KFEAT: <glyph> = enter_tomb`, generation binds the scheduled Tomb link to
that final oriented glyph. An ending without that feature receives one
connected gate, using a fitting `tomb_entry` map when possible. This avoids
an extra stair when a map already owns the entrance. The link enters the
complete three-floor Tomb route described below.

Crypt also illustrates a live marker. `grunt_crypt_arrival_guarded_gate.des`
and `david_glass_crypt.des` call hooks that record a
`vault_trigger:crypt.*` callback and its wall group. The final oriented
record coordinates become a saved `world.vault_trigger` ECS entity. The
`player_los` event checks the player's visible cells after a committed move;
the callback changes the listed cells and consumes its trigger once. Put a
new live callback in `policy/world/vault_trigger_callbacks/<name>.lua`,
return a local table of named methods, and record a marker naming one of
those methods. Group IDs and record indexes connect trigger and target
cells through save/restore; Lua module variables must not hold visit state.
The live callback receives `ctx`, which supplies saved ECS components,
terrain queries and writes, visibility, messages, and RNG. See the
[game context guide](#the-game-context-ctx) and
[vault hook guide](#vault-maps-and-lua-hooks) for the full API boundary.

The [Crypt snapshot index](level-snapshots/crypt/index.txt) shows a
Vaults-side entrance, Crypt:1–3, and all eight possible endings. To write
fresh examples from the current ruleset, run
`CRAWL_CRYPT_SNAPSHOT_DIR=/path/to/output go test ./internal/game -run '^TestCrypt'`.

### Tomb maps and named one-way hatches

Tomb uses the original source MAP format in 31 active, individually layered
`.des` files. Ten `vaults/tomb_entry/` files are eligible at the scheduled
Crypt:3 gate. `vaults/tomb_1/tomb_1.des`, `vaults/tomb_2/tomb_2.des`, and
`vaults/tomb_3/tomb_3.des` own the full floor grids. Their `SUBVAULT` lines
select from four helper directories: `tomb_1_centre`,
`tomb_1_hall_stairs`, `tomb_2_ambush`, and `tomb_3_rune`. Adding one `.des`
file with the matching source tag contributes one choice to its helper
pool. Replacing an existing relative path changes only that map. The four
old-save compatibility maps in the original `tomb.des` are intentionally
excluded from this new save format.

Tomb's escape hatches are **one-way**. A named Lua hook records
`hatch_name` on a stair glyph and `hatch_dest_name` on the target landing.
Both use a route name from `ids/tomb_hatches.lua`. The engine resolves
their final coordinates after `SHUFFLE`, `SUBST`, nested helper placement,
and rotation. Several source hatches can share one name; each name needs
one destination marker, and a landing can have several names. The landing
may be ordinary floor, so it needs no reciprocal stair. A missing or
duplicate destination, a blocked landing, or a link outside the authored
branch rejects generation before the player's Crypt gate is spent.

For example, a new Tomb:2 ambush helper belongs at
`vaults/tomb_2_ambush/my_ambush.des` with
`TAGS: tomb_2_ambush unrand`. Its `R` landing should call the shared
`dest_tomb2_entry` and `dest_tomb1_hall_exit_1` methods at the source
position before `R` becomes floor. Its chosen return stair should call
`name_tomb2_exit_ambush` before the candidate `S` glyphs are substituted.
Those methods live in `policy/generation/tomb/hatch_markers.lua`; the
family-local `hatches.lua` exposes them to `vault.run`. Study a bundled
ambush file before editing because placement masks any helper cell outside
the parent `B` region. The source guardian-set counts are local to one
three-floor build; do not put changing counters in module globals.

The Lua bundle builder at `policy/generation/tomb/level.lua` builds all
three maps on first entry so every named destination exists before travel.
Go stages and populates them in one command checkpoint, then saves their
terrain, actors, rune, and links. The `api` in a map hook is the temporary
vault placement API (`api:emit`, `api:record`, and layout RNG methods). It is
not the live game `ctx`; the builder receives `ctx` and passes its saved RNG
streams into placement. Modders adding a source monster or rune rule put a
named Lua method at the corresponding DES line, with a comment explaining
the choice. The [Tomb snapshot index](level-snapshots/tomb/index.txt) shows
the actual three floors and their connected one-way links. Regenerate it
with `CRAWL_TOMB_SNAPSHOT_DIR=/absolute/output go test ./internal/game -run '^TestTombBranchStagesCompleteRoute$'`.

## Add or replace an Abyss map

The Abyss is a moving 80×70 view over a procedural world, rather than a
stack of persistent floors. A branch depth from Abyss:1 through Abyss:7
controls monsters, vault weights, exits, and rune eligibility. A separate
morph clock changes exposed terrain as turns pass. The generated map and
clock are saved together, so loading a game does not reroll terrain.

The bundled source maps live as individual files in `vaults/abyss/`.
Depths-side portal entrances live in `vaults/abyss_entry/`. Their
`CHANCE` and `chance_enter_abyss` tags join the ordinary DES chance stage;
the keyed `enter_abyss` feature becomes a live arch. A player on that arch
uses the down-stair command to enter the Abyss, and the outside cell becomes
the return site. To add a room, create
`vaults/abyss/my_ruined_shrine.des` with its own `NAME`, `DEPTH`,
`WEIGHT`, `TAGS`, directives, and `MAP` block.
Use `ORIENT: float` for an ordinary Abyss room. Without an `ORIENT`
directive, the source DES parser marks it as a minivault, which uses a
different draw and does not enter the ordinary Abyss furniture pool.
The effective catalog finds the file by path; no registry list or Go
change is needed. Use a new `NAME` for an addition, or the same relative
path to replace a bundled map. A `TAGS: abyss_rune` map joins the rune
pool; `TAGS: abyss_exit` joins the exit pool. Weighted mapless dummy
definitions deliberately spend a draw
without placing terrain. Normal Abyss furniture uses the ordinary depth
and weight rules and a six-map stop limit. Keep the source map syntax in
the `.des` file so the map remains readable beside the original game.

An executable `:` line in a map calls a named method with
`vault.run("method_name")`; a veto calls `vault.veto`. Put that method in
`policy/generation/vaults/abyss/<same_name>.lua`, or the matching
`abyss_entry/` path. The runtime loads that Lua through the same layered
VFS as the `.des`, so either file can be overridden independently. The
hook receives the temporary placement `api`, which can emit a directive,
read placement-local choices, or draw from the placement RNG. It is not
the live world `ctx`. Keep each method as a named function on a returned
local handler table, and explain why the source map needs it. Existing
bundled hooks remain in separate Lua files; a future cleanup may move
them into their paired DES files. Lua source must never be embedded in Go.

The runtime first samples terrain in `policy/generation/abyss/`, then
fits weighted DES maps. On entry, `proto.lua` paints a sanitized,
distance-faded impression of the departure floor over unprotected cells;
authored vault cells keep their shape. It then places exits, stairs, and
a depth-eligible rune. It projects the authored cells onto typed terrain
and keeps a source record for every occupied map cell, including plain
floor. A later window shift preserves a touched map whole. Keyed item
and monster directives materialize through the ordinary ECS factories.
Pending source effects
remain typed records. When the player approaches an edge, the
`policy/world/abyss/shift.lua` rule carries the radius-ten neighborhood
and any touched vault to the center. A map that cannot fit intact causes
the proposed shift to fail before terrain or RNG state is committed.

`policy/world/abyss.lua` owns first entry, reentry, descent, teleport,
and escape. It saves the outside return cell on each new banishment.
An Abyssal Knight starts in a pocket window with an exit underfoot and a
nearby Lugonu altar. Ordinary exit features return to the saved outside
site; downward Abyssal stairs generate a fresh window one depth deeper.
Credited XP can place another exit or stair. `policy/world/abyss/rune.lua`
keeps the Abyssal rune unique after pickup. Once collected, the rune also
raises ordinary exit odds to the source's maximum effective depth; save
validation rejects a second floor copy. `policy/world/abyss/transit.lua`
parks eligible monsters in an inert ECS reserve while a window changes,
then tries to return them on a later window. Their health, AI, and gear
stay on the same ECS entities. The reserve is engine storage, not a map
that a player or mod vault should address directly.

For a gameplay rule change, override one named Lua policy in
`policy/generation/abyss/` or `policy/world/abyss/`. For a new authored
encounter, add a `.des` file and only add a hook when a static directive
cannot express the behavior. A test for a rule belongs in a `_test.lua`
file and should import the production constants and policy. The
[Abyss text snapshots](level-snapshots/abyss/index.txt) show a playable
first window, shifted window, depth-seven rune, and XP exit with map IDs
and travel destinations. Each text file marks whether those destinations
and the rune are reachable from the player. Regenerate them with
`CRAWL_ABYSS_SNAPSHOT_DIR=/absolute/output go test ./internal/game -run '^TestAbyssTextSnapshots$'`.

## Add or change a god's conduct

Conduct is the reaction to an action, such as killing a monster, casting a
spell, exploring, or drinking a known Haste potion. The ordinary piety and
penance numbers are stored in the player's `religion.worship` component.
The action owner reports a named fact to `policy.religion.conduct`; the
current god's rule module decides whether that fact matters. Keep the
action producer beside the action. A god module should never scan the
world each turn to guess whether an action happened.

To replace a bundled god's rules, create the same relative path in your
overlay, for example
`policy/religion/conduct/zin.lua`. To add a god, register one
`content/gods/<name>.lua` definition with `conduct_module` set to the
dotted path of its rule file. See the bundled Zin definition and rule for
the required identity fields and the rule table shape. A god may omit
`conduct_module` when it has no conduct responses. The winning layered
file is validated at boot; misspelled event IDs, absent modules, negative
factors, and malformed fields fail before a game starts.

Import `constants.religion_conduct` wherever an event is declared or
reported. The constants are stable IDs; filenames, directory traversal,
and registration order do not assign event IDs or affect seeded rolls.
Each rule file returns one local table. Assign named methods to that table
when a god needs an exception, and describe why the exception exists in a
comment. The following is the shape of a small, hypothetical rule file:

```lua
local kinds = require("constants.religion_conduct")

local patron = {}

-- This patron only values kills with actual player credit.
local function eligible(_, _, event)
    return event.credit ~= false
end

patron.likes = {
    [kinds.KILL_DEMON] = {
        description = "you kill demons",
        bonus = -4,
        denom_bonus = 18,
        xl_denom = 2,
        filter = eligible,
    },
}

return patron
```

For a like, `bonus`, `denom_bonus`, and `xl_denom` are integer source-curve
parameters. The conduct owner begins with `denom_bonus + event.level`,
subtracts `floor(player XL / xl_denom)` when the divisor is positive,
then offers `max(0, denominator + bonus) / max(1, denominator)` piety.
The piety owner handles Faith, penance debt, gift timeout, upper taper,
hysteresis, rank changes, and named religion RNG. A `special` method may
return changed numerator and denominator plus optional response text.
Keep exceptional math with the god, as Okawaru and Cheibriados do.

For a dislike, provide nonnegative integer `loss_factor` and
`penance_factor`. Each multiplies `event.level`; optional integer
`penance_offset` adjusts the latter. `forgiveness` text pardons an act
reported with `known = false` before piety or RNG changes. Optional
`filter(ctx, player, event)` excludes a victim; `before` may return false
to stop a response, as Uskayaw does while pooling hit damage. The owner
evaluates a dislike before a like when a god has both for the same event.

The action owner calls `conduct.record(ctx, event)` synchronously while
its target still exists. Every event needs `id`, nonnegative integer
`level`, and boolean `known`. A kill may also provide `victim`, `credit`,
`was_neutral`, `no_reward`, and structured monster traits. `credit = false`
prevents ordinary like piety but still lets a god object to a forbidden
kill. A damage event carries the actual HP lost, maximum HP, and victim XP.
For a new player attack, call `policy.religion.conduct.attack.report` at
the actual target contact before hit, resistance, or death changes the
actor. It reads allegiance, holy status, and player sight from live ECS.
Do not infer an attack from damage alone: a miss can still be an offense,
while persistent terrain and constriction damage are not fresh attack
events. Toxic Radiance is a useful timing example: its cast pulse reports
an attack, but later poison ticks do not.
The contamination owner reports Zin's first severe glow as an unknown
zero-severity event, then reports controlled additions while already glowing
with the new contamination tier. The Abyss banishment owner reports a
separate event only for a player-credited, rewardable hostile target. If a
mod adds another way to change either state, call those owners instead of
writing their saved components directly. Do not save a victim entity ID in
a Lua module global or postpone a death event until after the actor is
removed.

`ctx` is the current action's game context, not global state. Use
`ctx:player()` for the ECS player entity; `ctx:get`, `ctx:set`, `ctx:has`,
`ctx:add`, and `ctx:remove` for saved components; `ctx:random(stream, n)`
for a zero-based draw from a named saved stream; `ctx:emit(channel, text)`
for a message; `ctx:aut()` for the current absolute game time; and
`ctx:signal(name, value)` for later ordered systems.
The floor APIs, including `ctx:level_branch(level_id)`, read the current
world. Save any new per-turn conduct counter in a schema under `schemas/`,
as `religion.uskayaw_momentum` does. A Lua module local may hold immutable
rules and helper functions, but never a current game's mutable counters.

Add an `_test.lua` beside the Lua rule tests and import the production
component and event IDs. The test harness loads the effective VFS and
runtime. The conduct tests show godless actions, unknown-act forgiveness,
kill classification, first-sight persistence, item knownness, and
Uskayaw's pooled damage. For a new action producer, also test one real
turn through the action system. A mod overlay can replace one god module
without changing unrelated seeded draws or descriptions: the
`presentation.religion` policy derives its conduct lists from the same
resolved rule module, sorted by stable event ID.

## Add or replace a Xom action

Xom's action engine lives in `policy/religion/xom/`. Its source event IDs
are named in `ids/xom_events.lua`, and each built-in event has one definition
under `content/xom_events/`. The selector first decides whether an action
is good or bad, then checks event gates in explicit numeric priority order.
An early successful gate prevents later gates from spending RNG. The order
is gameplay policy; directory names and file load order do not set it.

To replace a built-in action, put a Lua file at the **same relative path**
in your mod directory, such as `content/xom_events/bad_noise.lua`. Give it
the existing event ID and an `effect_module` that returns a table with
`apply(ctx, player, event_id, severity, request)`. A replacement may change
the effect and badness. Its built-in selection gate still uses the source
priority; replace `policy/religion/xom/selection_bad.lua` or
`selection_good.lua` only if you need a different built-in eligibility rule.
The action owner calls the effective effect module before changing Xom's
interest or mood.

To **add** an event, give its definition a new stable ID, `side` (`"good"`
or `"bad"`), `effect_module`, positive integer `selection_stage`, and
`selector_module`. A bad event also needs `badness_10x` or the supported
dynamic badness rule. The selector module returns a table with
`eligible(ctx, player, worship, severity, tension, stream)`; return true
when this action can occur. Use `ctx:random(stream, bound)` for chance
checks, and only draw after any earlier eligibility checks that the rule
requires. `ctx` is the current game's context, `player` is its ECS entity,
`worship` is the current `religion.worship` component for bad events,
`severity` is Xom's current mood magnitude, and `tension` measures nearby
danger. The `stream` is the saved RNG stream chosen by ordinary worship or
Divine Wrath. A good event receives `nil` for `worship` because the good
selector does not need the harmful-state checks. Read fresh components
through `ctx:get` if the mod's good action needs worship state.

Stages 10 through 190 contain source good gates in steps of ten; stages
10 through 150 contain source bad gates. A custom stage 15 runs after the
first built-in gate and before the second. At a shared stage, the built-in
gate runs first, then added events by stable ID. Keep IDs in a mod-owned
`ids/` module and import them in definitions, selectors, and tests. The
fixture in `internal/script/testdata/xom-event-mod/` shows both an added
event and a same-path replacement. Its test checks the effective catalog,
source draw boundary, and ID tie order. Keep mutable durations on saved
ECS components, as Xom's cloud trail and stair repulsion do; Lua module
locals may hold functions and immutable definitions only.

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

## Spell-list abilities and long selections

Sif Muna's powers under `policy/abilities/sif_muna/` show how to add an
ability that uses existing spell records. `spells.choose(ctx, player,
spell_id, known_only, title)` reads `character.spell` ECS entries and returns
either a validated spell or a free selection prompt. Use `known_only = true`
for a memorized spell and `false` for a library spell with a registered
effect. The generic ability command carries the returned ID as `spell_id`;
the terminal pages long lists and sends that stable ID back. A label is
display text and must never be used as a lookup key.

Divine Exegesis asks for a cell after selecting a spell whose flags require
aiming. It then calls the ordinary cast preflight and effect owners with a
library allowance and an Invocations power bonus. A new spell-list ability
should follow that flow instead of making a second spell effect table.
Channel Magic illustrates a timed god effect: the ability starts a saved
player component, an ordered Lua system ages it once per player action, and
the god behavior clears it immediately on departure or penance. Validate
saved timed state in `policy/save/status.lua` so invalid worship and timers
cannot silently resume.

## Temporary terrain and melee conversion powers

Jiyva's Oozemancy illustrates a power that changes the grid without
embedding new terrain logic in Go. `policy/religion/jiyva/oozemancy.lua`
selects eligible, visible cells. `policy/world/temporary_terrain.lua`
creates one saved ECS marker per changed cell; that marker stores the old
feature, new feature, expiry, source actor, and source ability ID. The
existing slimy wall rule then handles acid exposure. A modded terrain power
should use this owner and a distinct stable source ID so its cleanup does
not restore unrelated temporary terrain.

Slimify shows where to intercept a melee rule. Its focused Jiyva owner
checks target eligibility and chooses a replacement body. The shared
fixed-form polymorph owner updates the live monster entity, including its
gear and HP; Jiyva's allegiance marker records the resulting side. The
melee coordinator calls this owner only after a successful primary contact
and returns before ordinary damage, brands, and auxiliary hits. A new
conversion power should keep its timer in a player component, its monster
state in an entity component, and its source order in that contact path.

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

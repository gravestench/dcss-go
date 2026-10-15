# Lua mods: discoverable files

DCrawl embeds its Lua rules under `internal/modfs/builtin/`. Run with
`--mod-dir=/path/to/mod` to replace a bundled file with a file at the same
relative path, or to add a file. The effective tree is loaded once per game
session. Changes to files on disk take effect when a new session starts.
The mod directory can contain just one Lua file; no manifest, copied base
tree, or generated registry is required.
Lua source lives in `.lua` files in this tree and in test mod directories;
Go source does not contain inline Lua programs.

This is a two-layer virtual filesystem. The embedded tree is the base layer.
The directory passed to `--mod-dir` is the user layer. Its files win when the
relative paths match, and its new paths join the effective tree. All Lua
modules, including `require` calls, read that one effective tree. An overlay
does not need to repeat the rest of the base game.

| To add | Put the file here | Add another file when |
| --- | --- | --- |
| Monster | `content/monsters/<name>.lua` | It needs a new AI or other behavior. |
| Spell | `content/spells/<name>.lua` | It needs a new resolver under `policy/magic/effects/`. |
| Item or unique item | `content/items/<name>.lua` | It needs a new use, combat, or equipment rule. |
| Item class | An item file with a new `class` ID | It needs class-specific rules or UI. |
| Mutation | `content/mutations/<name>.lua` | It needs an effect under `policy/mutations/effects/`. |
| ECS component | `schemas/<name>.lua` | Its behavior needs a system. |
| ECS system | `systems/<name>.lua` | Its state needs a new component. |
| Game policy | `policy/<area>/<name>.lua` | It needs new content or a component. |

A data-only addition takes one file when existing rules already understand
it. A genuinely new mechanic takes a small set of files: its definition,
focused policy or system, and a `_test.lua` file using the production schema.
Each file registers itself when discovered. There is no central switch to
edit for each new monster, spell, item, component, or system. The loader
rejects duplicate IDs and invalid definitions with their source paths.

The bundled `init.lua` loads `schemas/`, `content/`, `policy/`, `systems/`,
`generation/`, and `ui/` in that order. Paths within each tree load in sorted
order. A new file under one of these directories is discovered automatically. Put helpers
under `lib/` and load them with `require("lib.helper")`. `require` reads the
effective embedded-plus-overlay tree; it cannot read arbitrary disk files.

## Components

A file such as `schemas/turn_counter.lua` may register a component:

```lua
local schema = {
    id = "my_mod.turn_counter",
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
Integer values passed through Lua must be exactly representable in its
numeric type (absolute value at most 2^53). Entity values are userdata
handles, not numeric IDs. Registered dynamic components are included in saves.

## Systems

A file such as `systems/turn_counter.lua` may register a system:

```lua
local system = {}

function system.update(ctx, entity, delta)
    local turns = ctx:get(entity, "my_mod.turn_counter")

    ctx:set(entity, "my_mod.turn_counter", {
        count = turns.count + 1,
    })
end

register.system({
    id = "my_mod.count_turns",
    scope = "active",
    after = { "status.poison" },
    query = { "my_mod.turn_counter" },
    update = system.update,
})

return system
```

`scope = "all"` is the default and visits matching entities in Akara's
stable entity order. `scope = "active"` visits the actor taking the current
turn. `query` names Lua-registered components that must exist. `after` and
`before` name other Lua systems or the current Go systems listed in
`internal/game/systems_registration.go`. Unknown names and cycles fail at
startup. Keep state that must survive a save in components, not Lua module
globals.

The callback receives `ctx`, the entity handle, and the update duration in
nanoseconds. These context methods are available now:

- `ctx:get(entity, id)` returns a table of field values or `nil`.
- `ctx:has(entity, id)` checks whether a Lua component exists.
- `ctx:set(entity, id, values)` replaces a component, filling omitted fields
  from schema defaults.
- `ctx:add(entity, id, values)` queues component attachment until the end of
  the game update. `ctx:remove(entity, id)` queues removal at the same barrier.
- `ctx:actor()` returns the current actor handle or `nil`.
- `ctx:random(stream, bound)` draws an integer in `[0, bound)` from a named
  saved RNG stream. `math.random` is unavailable.
- `ctx:emit(kind, text)` adds a turn event.

Bootstrap has a five-second execution deadline and each system callback has
a two-second deadline. A looping or unusually slow Lua file fails with an
error instead of freezing the client.

The runtime also exposes the Go engine's existing components and grid through
`core.*` component names and context methods. Game behavior is moving into
Lua rules while Go retains generic ECS, VFS, save, and terminal services.

## Content files

Put one definition in one file below `content/<category>/`. The recognized
base categories are `species`, `jobs`, `monsters`, `spells`, `items`,
`mutations`, `branches`, and `monster_spellbooks`. The registration API accepts additional
category names for mod-defined catalogs. For example,
`content/monsters/my_moss.lua` can contain:

```lua
local categories = require("constants.catalog")

local definition = {
    id = "MY_MOD_MOSS",
    name = "moss creature",
    status = "defined",
    habitat_id = "HT_LAND",
    spellbook_id = "MST_NO_SPELLS",
    average_hp_10x = 25,
    speed = 10,
    hd = 1,
    attacks = {
        {
            type_id = "AT_BITE",
            flavour_id = "AF_PLAIN",
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
            scenario_id = "generated-dungeon-basic-v1",
            min_depth = 1,
            max_depth = 3,
            rarity = 1000,
            curve = "FLAT",
        },
    },
}

register.definition(categories.MONSTERS, definition)

return definition
```

The file is loaded automatically. Its population entry puts the monster into
the generated Dungeon roster without editing a central list. The example
uses the current basic monster behavior and combat rules. Invalid spawn data
fails at startup with the content path and field name.

A rule imports `constants.catalog`,
`ids.monsters`, and `policy.catalog` where needed, then reads it with
`catalog.get(categories.MONSTERS, monsters.MY_MOD_MOSS)`. The ID module
reflects added files; no generated index needs editing. A spell,
item, branch, or monster spellbook uses the same form in its directory.
Unique items are item definitions with a stable unique ID and the required
item fields. A new item class appears in `ids.object_classes`.

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

Put a player mutation in `content/mutations/<name>.lua`. The content tree
registers it automatically, and `ids.mutations` exposes the new ID to other
Lua files. A behavioral mutation also needs a focused file under
`policy/mutations/effects/`; an ordinary scalar mutation can use the shared
effect policy. The mutation rules are being ported as one domain, so new
definitions should not be made selectable until their effect is implemented.

The effective tree is sorted by path. A file at the same relative path as a
bundled file replaces it before Lua starts. A new path adds a definition.
Registering the same category and ID from two effective paths fails at
startup and names both paths. Generated base filenames contain an order
prefix, which preserves source ordering for selection rules.

## Character definitions and choices

The embedded `content/species/` and `content/jobs/` trees contain one Lua file
per pinned species and job. Each calls `register.definition` with a local
table. Replace a file at
the same path in your mod directory to edit that definition. New files in
either tree load in sorted path order. Duplicate IDs, invalid fields, and
missing required definitions stop startup with an error. The species and job
tables in Lua are the effective definitions used by the game and the
character creation screen. Go's typed catalog is a projection for domains
that have not yet moved to Lua; it is rebuilt from the effective files.
Use `mod.null` when a present field intentionally has a null value; omitting
a required field is an error. Newly selectable definitions appear on a
separate modded menu page. They need implemented start mechanics before a
policy can make them playable.

The `policy/character_choice.lua` file calls `register.choice_policy` once.
Its function receives copied species and job tables and a boolean indicating
whether the menu is species-first. It returns a restriction string
(`banned`, `restricted`, or `recommended`) and whether the start is currently
playable. The bundled policy preserves the source bans and recommendations.
Only Human, Hill Orc, Deep Elf, and Minotaur Fighters have complete starts
today; other source options remain visible and explain that they are not yet
available. The game constructor checks the same Lua policy before creating a
player. A policy can narrow supported starts; adding a new playable start
also requires its gameplay rules and equipment behavior to be implemented.

`python3 scripts/generate_lua_character.py --check` compares the committed
character Lua files with the pinned importer artifacts. Run the generator
without `--check` only for an intentional upstream refresh, then review and
commit its output. Normal builds and game launches do not run the generator.
`python3 scripts/export-catalog-lua.py --check` checks the other committed
content files. The JSON importer artifacts are offline refresh inputs and
are not loaded by Lua at game startup.

## Saves and identity

The startup screen shows a short effective ruleset hash and whether its Lua
bytes match the bundled ruleset. Saves contain the full hash, per-file hashes,
Lua dialect, schema versions, and dynamic component state. A changed ruleset
is refused by default, with changed paths named in the error. To explicitly
try a save with changed Lua, run with `--allow-ruleset-mismatch`. This does not
migrate changed schemas: their saved records must still validate under the
current definitions. A new schema with no saved instances can be added under
this explicit opt-in. The save also lists every overlay-changed path. Lua
files in an overlay must be regular files ending in `.lua`; symlinks and
special files are rejected.

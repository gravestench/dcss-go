# Lua mods: current runtime API

DCrawl embeds its Lua rules under `internal/modfs/builtin/`. Run with
`--mod-dir=/path/to/mod` to replace a bundled file with a file at the same
relative path, or to add a file. The effective tree is loaded once per game
session. Changes to files on disk take effect when a new session starts.
Lua source lives in `.lua` files in this tree and in test mod directories;
Go source does not contain inline Lua programs.

The bundled `init.lua` loads `schemas/`, `content/`, `policy/`, `systems/`,
`generation/`, and `ui/` in that order. Paths within each tree load in sorted order. A new
file under one of these directories is discovered automatically. Put helpers
under `lib/` and load them with `require("lib.helper")`. `require` reads the
effective embedded-plus-overlay tree; it cannot read arbitrary disk files.

## Components

A file such as `schemas/turn_counter.lua` may register a component:

```lua
register.component{
    id = "my_mod.turn_counter",
    version = 1,
    fields = {
        count = {
            type = "int64",
            default = 0,
        },
    },
}
```

IDs must be unique. Field types currently supported by Akara's dynamic
schemas are `bool`, `int64`, `uint64`, `float64`, `string`, and `entity`.
Integer values passed through Lua must be exactly representable in its
numeric type (absolute value at most 2^53). Entity values are userdata
handles, not numeric IDs. Registered dynamic components are included in saves.

## Systems

A file such as `systems/turn_counter.lua` may register a system:

```lua
register.system{
    id = "my_mod.count_turns",
    scope = "active",
    after = { "status.poison" },
    query = { "my_mod.turn_counter" },
    update = function(ctx, entity, delta)
        local turns = ctx:get(entity, "my_mod.turn_counter")

        ctx:set(entity, "my_mod.turn_counter", {
            count = turns.count + 1,
        })
    end,
}
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

Component CRUD currently reaches Lua-registered dynamic components. The
existing Go-defined components, grids, most content domains, and command
handlers still use their Go APIs. Later domain migrations will expose the
reusable host services those Lua rules require.

## Character definitions and choices

The embedded `content/species/` and `content/jobs/` trees contain one Lua file
per pinned species and job. Each calls `register.species{...}` or
`register.job{...}` with the full source-traced definition. Replace a file at
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

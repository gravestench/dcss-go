# DCrawl Go port inventory

The reference is DCSS commit
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f` in
`/Users/dylanknuth/src/crawl`. The port is a playable D:1–2 slice, not a
complete DCSS game.

## Where rules live

The bundled game rules are real Lua files under `internal/modfs/builtin`.
Go provides Akara storage, the turn runner, grid and visibility services,
named RNG streams, save encoding, the Lua VM, and terminal drawing. Lua owns
the implemented character, item, combat, monster, generation, command, save
semantics, and presentation policies. The implemented entity systems are
registered in `internal/modfs/builtin/systems`.

Species and jobs are registered from their individual files under
`content/species` and `content/jobs`. Gameplay reads those same registered
tables, so an overlay of a definition changes the menu and game rules
together. Other imported content is committed under `data`; the Lua
`policy/catalog.lua` indexes active IDs. No normal build or game launch
reads the C++ checkout or runs an importer. The matching JSON artifacts under
`internal/content/generated` remain source-traced import and Go projection
data. `scripts/export-catalog-lua.py` refreshes the eleven aggregate Lua
catalogs deliberately when upstream content changes.

An optional mod directory replaces bundled Lua files by relative path and
may add files. Effective file bytes determine the ruleset hash recorded by
saves. Lua may register systems, policies, species, jobs, and Akara component
schemas. The runtime exposes one generic component and grid context rather
than a handler API for each game domain.

## Playable coverage

| Domain | Implemented now | Main Lua location |
| --- | --- | --- |
| Character | Human, Hill Orc, Deep Elf, and Minotaur Fighters; weapon choice, starting gear, attributes, skills, HP/MP, training, XP, level gains, stat choice | `policy/character`, `systems/character_*` |
| Dungeon | Seeded basic-layout D:1–2, rooms, corridors, doors, paired stairs, source-sized population, fixed test scenario | `policy/generation`, `policy/population`, `systems/world_*` |
| Dynamic actors | Twelve ordinary early monsters, jackal bands, source HP/speed, decisions, energy, attacks, carried weapons and missiles; item and spell capability dispatch without monster-ID handlers | `policy/ai`, `policy/population`, `policy/monster_energy.lua`, `systems/monster_*` |
| Combat | Fighter melee and headbutts; player fire/throw with eight launcher types, penetrating javelins, monster shields, launcher fire/frost/vorpal, and missile poison/curare/dispersal; monster natural/weapon/ranged hits, Lua effect modules for Freeze, Slug Dart, sling bullets, stones, and poisoned darts, AC/EV, constriction, kills, XP, and corpses | `policy/combat`, `policy/death.lua`, `systems/attack_*`, `systems/actor_death.lua` |
| Items and status | Pickup/drop, wielding, armour delays, quaffing curing/heal wounds/might/haste, ammunition stacks and landing, poison, curare slow, trapping nets, regeneration, and duration decay | `policy/inventory`, `policy/potions.lua`, `systems/item_*`, `systems/player_status.lua`, `systems/monster_*` |
| Client | Full-terminal 79×24 minimum, expanding dungeon view, DCSS-shaped startup and game screens, inventory, skills, help, fire/throw targeting, direction prompts, and unavailable-feature notices | `policy/presentation`, `internal/terminal` |
| Persistence | Version-12 JSON saves, named RNG state, terrain and ECS state, Lua schemas, ruleset hash, semantic restore validation | `policy/save`, `internal/game/save*.go`, `internal/save` |

Core Akara components remain typed Go stores where the generic engine must
read them; Lua systems and policies change their authoritative values through
the same context used by Lua-defined components. Dense terrain, exploration,
and occupancy remain level grids.

## Committed source content

The import artifacts account for 43 species, 31 jobs, 700 active non-alias
monster IDs, 403 spell identities, 285 monster spellbooks, 408 concrete item
identities, 38 branches, ordered Dungeon population rows, monster weapon
loadouts, starting grants, and console presentation metadata. Import tools
under `cmd/import*` are for reviewed upstream refreshes. Content coverage
does not imply that its behavior is playable.

The pinned C++ source anchors for live behavior are `newgame.cc`,
`ng-setup.cc`, `player.cc`, `skills.cc`, `item-use.cc`, `potion.cc`,
`melee-attack.cc`, `mon-act.cc`, `mon-death.cc`, `timed-effects.cc`,
`dgn-layouts.cc`, and the branch, monster, item, spell, species, job, and
population definition files. Generated modules record their exact source
paths and revision. Source-specific Lua rules cite the relevant C++ paths
and preserve unusual roll order.

## Remaining full-game work

Only four species/job combinations and twelve early monster kinds can play
through the current D:1–2 slice. The many imported species, jobs, monsters,
spells, items, and branches still need behavior, generation, and UI flows.
Major missing domains include player spellcasting and learning, religion,
mutations and forms, full monster abilities, vaults and Lua vault scripts,
more layouts and branches, traps, clouds, shops, runes, endgame, and the
complete item and equipment system. Native C++ saves, tiles, and network
client compatibility are outside this Go port.

For each new domain, add its complete Lua definition and policy slice,
register systems where Akara state changes, then extend Go only for reusable
engine primitives. Replace any old rule path in the same pass; do not keep
compatibility adapters. Keep generated content checked in and refresh it
explicitly.

## Running the slice

`go run ./cmd/dcrawl -seed 1 -save dcrawl-save.json` starts the terminal
client. Choose Dungeon Crawl, one of the four playable Fighter species, a
weapon, and a name. Use the in-game `?` help for commands. Unsupported
choices remain visible and explain that their gameplay is unavailable
without spending a turn.

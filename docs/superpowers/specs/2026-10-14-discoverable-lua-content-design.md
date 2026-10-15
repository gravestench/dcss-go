# Discoverable Lua content and layered mods

## Outcome

A mod author can add a monster, spell, item type, unique item, component,
system, or policy by placing a small Lua file in the documented directory.
The game discovers it at launch without editing an index, Go switch, or
generated aggregate. A user mod directory may contain one file or many. A
file at the same relative path replaces the bundled file; a new path adds a
definition. The exact effective bytes remain hashed for vanilla detection
and save compatibility.

## One registration path

The generic Go Lua host exposes `register.definition(category, definition)`
for immutable content tables. It stores the copied table, origin path, and
category/ID pair. Lua owns category validation and game rules. The existing
`register.get`, `register.ids`, and `register.origin` read every category.
The species and job specific host registration functions are removed after
their files use the generic function. A duplicate ID from two effective
paths fails at boot with both paths named. A same-path replacement produces
one effective file and therefore one definition.

The first full conversion covers `species`, `jobs`, `monsters`, `spells`,
`items`, `branches`, and `monster_spellbooks`. Each shipped definition becomes
one file below `content/<category>/`. `init.lua` loads `content` in sorted
relative-path order, so mod-added files join the same path as bundled ones.
`policy.catalog` reads the registry directly. No second Lua aggregate is
queried for these categories. The remaining aggregate import categories
(population rows, presentation, starting gear, vocabulary, and item identity
tables) receive the same treatment when their owning rules are converted;
they are not a separate mod API to extend indefinitely.

## File contract

Each definition file builds one local table, calls `register.definition`,
and returns the table. It carries source provenance only in adjacent Lua
comments. A content file may require common ID modules and pure helpers.
Registration files must not depend on another category's load order; Lua
validation runs after all definitions have registered. A spell definition
describes static facts; its effect module and any ECS system live in their
own discoverable policy/system files. A unique item is an ordinary registered
item definition with a unique identity and may have an effect module. Game
specific behavior stays in Lua; Go only supplies generic ECS, grid, RNG,
VFS, and terminal capabilities.

Shared identifiers are imported where used from `ids.spells`,
`ids.monsters`, `ids.items`, `ids.species`, `ids.jobs`, `ids.skills`, and
`constants.*`. Catalog ID modules build from registered content, making the
content declaration authoritative. A missing ID fails with a useful error
at boot or in a Lua rule test. Behavior never repeats an ID string merely to
look up or compare a definition. Narrative text may remain literal.

## Validation and tests

Lua category validators inspect registered definitions and cross-references
after discovery. They report the definition origin, field, and bad value.
Shared `_test.lua` cases run in the production Lua VM with production schemas
and a small fixture harness. Go tests cover VFS merge/hash, host bridge,
save encoding, and terminal mechanics. Rule tests cover registered content,
effects, systems, and override behavior in Lua. No test copies component
schemas or catalog declarations.

## Migration and verification

Convert complete categories, not one content record at a time. A deliberate
import tool writes the per-definition Lua files from the pinned C++ import
artifacts, and those generated files are committed. Normal builds do not
read C++ or regenerate content. Keep the JSON artifacts solely for offline
import verification while removing their runtime catalog role. Verify a
single-file mod-added monster and spell, a same-path override, duplicate-ID
failure, effective ruleset hash, save rejection on changed rules, and normal
gameplay using the registered definitions. Measure startup time after the
split and optimize the loader only if the concrete measurement requires it.

## Readability

Modules use a local table, named functions, registration with those function
references, and a final return. Multi-field tables put fields on separate
lines. Handwritten lines are at most 120 characters and prefer 80. Shared
IDs and common timing values are imported at the use site. Source locations
are comments beside declarations, not runtime fields.

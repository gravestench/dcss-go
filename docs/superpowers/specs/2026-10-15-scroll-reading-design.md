# Source-backed scroll reading

## Intent

Make all 19 active scroll types in the pinned DCSS source readable in the Go
port. A player can select a scroll, satisfy any target prompt, and see its
effect, discovery, consumption, timing, and cancellation behavior. A mod can
add a scroll and its effect by adding files, with no Go item-ID switch. This
continues the user's Lua-first, whole-domain port: source definitions and
rules are committed Lua, generic ECS and UI services remain in Go, and code
stays easy to read.

The reference is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, chiefly
`item-use.cc:2820-3810` plus the effect implementations it calls.

## Scope

The active scroll IDs are identify, teleportation, fear, noise, summoning,
enchant weapon, enchant armour, torment, immolation, blinking, magic mapping,
fog, acquirement, brand weapon, vulnerability, silence, amnesia, poison, and
butterflies. Removed source scrolls remain inactive and have no runtime
effect module. This slice includes the support each active effect needs;
an effect is not counted as implemented if it only prints a placeholder.

The existing saved appearance and type-knowledge component remains the sole
source of item discovery. Reading a scroll identifies its type at the source
point in the action. Known and unknown readings may differ in what can be
cancelled without losing a turn or item. Type discovery updates every copy.

## Architecture

`policy/scrolls.lua` owns a registry keyed by the imported item IDs. Each
active scroll effect lives in its own `policy/scrolls/effects/<name>.lua`
file and returns an object with named `prepare` and `apply` methods.
`prepare` reports whether reading is possible, what selection is required,
and whether a cancelled selection spends time. `apply` performs only the
effect's rules and returns its outcome. The registry validates one effect
per active scroll in the effective catalog during startup. A mod adds a
definition and effect file under the existing layered VFS; a same-path
overlay replaces just that rule.

`policy/commands/read.lua` validates the actor, carried item, class, known
usefulness checks, reading restrictions, and selected target. It produces a
generic `core.intent` decision. `systems/item_read.lua` calls the registered
effect, reveals type, updates or destroys the stack, and emits messages.
The command and system do not branch on all scroll IDs. The existing
numeric `command_prepare.lua` dispatch chain is replaced in this slice by
a Lua command registry: each command file registers its own named kind,
while the central policy keeps only shared actor and turn restrictions.
This makes a new command file sufficient to add an intent handler.
Shared mechanics such as selecting enchantable equipment, applying a radius status, or
placing a cloud belong in focused Lua helpers used by the effect files.

Go extends the generic command envelope with `target_id` for an item,
spell, or offer choice, `dx/dy` for a map cell, and `cancelled`. It does
not implement scroll rules. A first `read` command with a missing target
returns a validated, no-time selection request from Lua. The terminal shows the
relevant inventory, spell, map, or acquirement selector and submits the
same command with the selection. Selection does not create a second turn.
The prompt carries only visible item text; an unknown scroll may disclose
its effect after the player starts reading, as in the source. Cancelling
submits a cancellation flag so Lua chooses the source-specific time and
item cost. Acquirement generates offers once and saves them on the scroll
entity, following the source's persistent choice list. Reopening the
prompt and restoring a save show the same offers. Save files are written
at turn boundaries; no half-read action is serialized.

## Effect families

- **Item choice:** identify, enchant weapon, enchant armour, and brand
  weapon select eligible items, respect source caps, and update per-item
  knowledge.
- **Translocation and mapping:** teleportation, blinking, and magic
  mapping use source restrictions, timing, valid destinations, and saved
  map knowledge.
- **Area actors:** fear, torment, immolation, vulnerability, and silence
  apply source resistance and duration rules to actors in range.
- **Clouds and noise:** fog, poison, and noise use source cloud placement,
  duration, resistance, and acoustic propagation.
- **Summons:** summoning and butterflies use saved ECS summon ownership,
  placement, expiry, and allegiance.
- **Other choice:** amnesia forgets a selected spell; acquirement generates
  source-backed item choices and grants the chosen item.

The source's exact scroll `make_name` labels are a separate visual parity
gap recorded in `docs/port-inventory.md`. This slice uses the saved labels
already implemented and does not change their generator.

## State and invariants

The scroll stack stays in Akara's item store. New lasting effects use small
saved Lua components on the player, monster, level, or summoned entity as
appropriate. Terrain and exploration remain dense level grids. All new
component fields have save validators; invalid targets cannot mutate state
or consume a scroll. A known cancellable scroll with no valid selection
returns without spending time or consuming an item. An unknown scroll
follows its source-specific post-reveal cancellation rule.

The effect registry never stores per-game mutable state. Random rolls use
named context streams. Effect files import IDs and constants where used.
Definitions carry no embedded C++ provenance fields; source locations are
comments. Handwritten Lua and Go use expanded multi-field literals and a
120-character maximum line length, preferring 80 characters.

## Verification

Lua `_test.lua` tests use production schemas, definitions, policies, and
systems through the existing harness. Whole-turn Go tests cover all 19
active scroll IDs, representative selection and cancellation paths, item
discovery across copies, save and restore of lasting effects, and a sparse
mod-added scroll. Terminal tests cover the `r` command, readable names,
selection prompts, cancellation, and turn cost. Run one full repository
suite after the whole slice, plus vet, build, style, and ruleset drift
checks before committing one contiguous scroll-reading category.

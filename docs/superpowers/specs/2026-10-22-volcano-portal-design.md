# Volcano Portal Design

## Intent

Port Volcano as one complete, playable DCSS portal domain. A character can
find an authored, temporary entrance, enter any source destination layout,
face its monsters and timed eruption hazards, collect its loot, and leave
through an authored exit. Generation choices, gate time, hazard phases, and
the outside return site survive save and restore. Sparse mods can add or
replace maps without changing Go code. This is a faithful gameplay and
content port on the existing Lua-first engine, not a new C++-format adapter.

The user prefers complete domain slices, readable Lua with comments explaining
why and how, committed generated content, Akara ECS for dynamic state, grid
terrain, no inline Lua in Go, one category commit, and text floor snapshots.
Those constraints apply to every part of this slice.

## Chosen approach

Port all source maps and their live hazards together. A map-only import would
make the dramatic layouts selectable but leave their defining danger inert.
Building a generic event framework first would add indirection before its
second user exists. Instead, reuse the existing timed portal transaction,
vault placement, Akara fog machines, cloud fields, and group marker concepts;
add focused Volcano Lua state for the two unique terrain events. Any reusable
behavior discovered during implementation belongs in its existing owner,
with Volcano policy calling it through a small documented interface.

## Committed source corpus

The pinned `crawl-ref/source/dat/des/portals/volcano.des` contains 34 active
`NAME` definitions: 11 entrances, 14 weighted whole-floor destinations,
and nine tagged sub-vaults. Commit each as an individually replaceable `.des`
file under `vaults/volcano_entry/` or `vaults/volcano/`; nested helpers stay
in the destination family with their source tags. Preserve each `MAP` block
byte-for-byte, plus static depth, weight, tags, orientation, directives,
and their order. Builds and normal tests use these committed assets only.
One-time source extraction is outside the runtime and is not committed.

The source's shared and map-local Lua becomes well-commented modules under
`policy/generation/vaults/{volcano_entry,volcano}/`. Retain a hook call at
each source position. The substantial hook body has local functions, a
module table whose methods are assigned explicitly, and a final return.
The original source script may remain beside the hook as a DES comment,
with the established future consolidation note for DES-local Lua.
No executable Lua is embedded in Go. Source provenance is a comment,
not a declaration field.

The shared entrance hook gives each source map one `O` archway, a once-drawn
600–800-turn marker, `uniq_volcano chance_volcano`, chance 500, volcanic
wall and floor colour and tile directives, and the expired-portal floor.
Selection metadata must be static in DES because selection precedes the
hook. The shared destination setup owns themed loot, exit arches, alarm
traps, terrain substitutions, and the blocked-tunnel feature name. Named
Lua owns fiery guardian pools, equipment, map-specific random choices,
and the source's special loot lists. Common item and monster IDs are
imported from production ID modules where used.

## Selection, placement, and content

Only source-eligible branch depths may select an entrance. Use the existing
chance, source weight, uniqueness, and fit rules. Choose a destination from
all positive-weight effective top-level Volcano maps by stable ID and
source weight. An optional requested ID is accepted only if it is eligible;
it exists for full-corpus verification and mod tests. Nested sub-vaults
are chosen by their source tags and weights through the normal `SUBVAULT`
owner. A modded `.des` file joins or replaces the effective pool without
load-order-dependent seeds or a Go content switch.

One destination encompasses one temporary 80×70 level. Preserve all
authored terrain, exits, altar identities, items, monster requests,
equipment, traps, markers, colour, and level properties as typed records
through placement, Akara population, and save. The player arrives at a safe
authored exit. Every authored `<` and `I` return arch stays live; multi-exit
maps must not lose a connection. Unsupported wider item or monster effects
remain explicitly typed with inventory notes until their own gameplay
domain is ported; no source record is silently discarded.

## Entrance clock and travel

Reuse the generic staged Lua portal transaction. The entrance's Akara
component owns its source marker, exact cell, creation action time,
600–800-turn duration, deadline, notice cadence, spent state, and closure
reason. Global player action time closes it even when the outside floor is
inactive; entering on its last valid turn commits before expiry. Lua emits
the source oppressive-heat discovery, slow-to-rapid rumbling bands, final
quieting, and lava-sealed tunnel messages through the existing hearing and
Silence rules. A scheduled inaudible notice still advances its saved clock.

The visitor component records the exact outside level and cell plus the
chosen destination ID. Entry spends the gate while staging and installing
the Volcano floor. Return uses that cell and retires the temporary floor
and its actors, items, fog machines, and hazard state. An occupied outside
cell refuses return without spending time or mutating the visit. A failed
layout, hook, population, or landing leaves gate, player, entities, RNG,
and levels unchanged.

## Eruptions and terrain events

The existing fog-machine and cloud-field owners create the source flame,
smoke, steam, and rain clouds. Extend the fog owner only where Volcano
exposes a real missing generic behavior: synchronized chained emitters
share one saved trigger clock, and named listener callbacks deliver the
large and small eruption warnings at the source trigger time. Listener
code lives in Lua and uses player visibility and the 12-cell proximity
rule. The source's `no_cloud_gen` level property must affect ordinary cloud
placement rather than remaining a decorative record.

`volcano_caves` has a separate saved countdown and a group of authored `M`
doorway markers. Each 50–200-aut firing picks one remaining marker. If the
player occupies that cell, emit the source rumble and leave it available;
otherwise change it to a light-red stone wall, add the source grey smoke,
emit the visible or distant message, and consume that marker. The source
group is exhausted only when every eligible doorway closes. Keep its
timing and chosen marker in Lua/Akara state, not mutable module globals.

`volcano_overflow` has one saved 200–400-aut countdown, phase 0–9, and
authored A/B/C marker groups. Phases 1, 3, and 5 warn; phases 2, 4, and 6
convert the respective group to lava; phases 7, 8, and 9 harden the groups
in reverse order. The player's occupied cell is never converted, matching
the source callback. Source warnings accompany each phase. Terrain remains
in the grid; the ECS state records only the changing phase, timer, and
source record links. Leaving and restoring cannot replay a phase or reroll
its timer.

Hazard clocks advance only for the active Volcano floor on accepted player
action time. The outside entrance clock remains global. The system must
define ordering against movement, cloud damage, and return so last-turn
events are deterministic. Fog emissions use the saved fog RNG stream;
Volcano events use a named stream so a save restores their next draw.

## Save, client, and mod contract

Add distinct Volcano entrance and exit terrain IDs, source colours, and
terminal glyphs. Save validation joins each realized entrance marker to
exactly one ECS gate and checks duration, deadline, grid cell, and closure
reason. A visitor must point to one source destination, one spent outside
gate, and its exact return site. Validate cave and overflow hazard state
against the selected source map, record indices, phase, countdown, and
current terrain. Reject extra, missing, or foreign state. Existing ruleset
hash handling remains unchanged.

Document source paths, hook API, gate and hazard components, map metadata,
mod addition and same-path replacement examples, and the distinction
between Volcano-specific policy and reusable engine owners. Update the
port inventory with exact implemented behavior and remaining gameplay
gaps. The text snapshot index must show all 14 top-level layouts, their
selected nested helper IDs, every return exit, and the outside gate.

## Verification

- Audit all 34 committed definitions, source `MAP` digests, hook references,
  entry eligibility, destination weights, and the nested helper pools.
- Place and populate all 11 entrances and all 14 destinations through
  production Lua paths; exercise every tagged helper through its parent.
- Exercise fog and chained emitters, cave collapses, all nine overflow
  phases, occupied-cell protection, cloud effects, and source messages.
- Enter, save, restore, expire on an inactive outside floor, return,
  reject forged state, and verify failed staging leaves state unchanged.
- Test a sparse added map, same-path replacement, zero-weight exclusion,
  broken hook, and an impossible map fit using the layered VFS.
- Export all 14 source destination terrain snapshots with a connection
  index. Run focused Lua, Go game, terrain, and terminal checks. Do not
  claim repo-wide tests passed if the known exhaustive suite times out.

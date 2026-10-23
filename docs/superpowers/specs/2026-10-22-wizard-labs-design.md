# Wizard Labs Domain Design

## Intent

Port Wizard Labs as one complete, playable DCSS portal domain on the
Lua-first Go engine. A character can discover a temporary magical portal,
enter any of the fifteen authored labs, face its defining live events,
collect its loot, and leave through an authored return arch. All choices,
timers, actors, terrain changes, and the outside return site survive the Go
save format. The maps and rules remain individually replaceable by layered
Lua mods.

This slice follows the user's established constraints: source `.des` MAP
rows remain intact; executable source Lua is ported to readable, separate
Lua modules at the original hook sites for now; no Lua is embedded in Go;
dynamic state belongs to Akara components; terrain remains in level grids;
and normal builds use committed content without consulting the C++ source.
Every Lua function explains why and how it operates. Each file has its own
comments, lines stay under 120 characters, and multi-field tables are
expanded. Text snapshots show each generated floor and its exact connection
back to the entrance.

## Approaches considered

A map-only import would make the labs selectable but leave their defining
event scripts inert. A general translation layer for the old C++ `dlua`
callbacks would also preserve source structure at the expense of the
modding model and reader clarity. The chosen approach ports all fifteen
labs and their live event rules into focused Lua owners in one domain pass.
It reuses existing portal staging, timed gate, fog, transporter, summon,
vault marker, and save owners where their behavior already fits. Lab-only
state gets lab-specific Lua schemas and policies. This is my implementation
choice under the user's standing instruction to take my recommendations and
continue without another approval round.

## Source corpus and selection

The pinned source is
`crawl-ref/source/dat/des/portals/wizlab.des`. It contains 26 active `NAME`
definitions: eleven ordinary entrance maps and fifteen whole-floor
destinations. Commit each definition as its own `.des` file under
`vaults/wizlab_entry/` or `vaults/wizlab/`. Preserve source MAP bytes,
static directives, tags, source weights, orientation, authored monsters,
equipment, items, traps, markers, and their order. Extracting these files
is a deliberate development action; its importer is not part of normal
builds or committed runtime content.

The source entrance helper gives every map one `O` portal, a 600–800-turn
timer, `uniq_wizlab`, `chance_wizlab`, and no ambient item or monster
generation. Ordinary entrances are eligible in Depths, Elf, Crypt, and
Vaults except the Vaults end floor, using the source five-percent chance.
`mu_enter_wizlab_7` has zero Vaults weight. Vaults' room generator makes
its source five-percent special attempt instead of giving ordinary room
draws a second chance at the portal. Use existing source-weight and
uniqueness rules, and keep every eligibility fact in Lua/DES rather than
adding a Go content table.

The fifteen destinations are whole-floor WizLab maps. A stable-ID weighted
draw chooses among all effective eligible top-level definitions. An
optional requested ID exists only for full-corpus verification and sparse
mod tests. Map selection does not depend on file load order. Each chosen
map uses the source `wizlab_setup` effects: encompass orientation, no
ambient item or monster generation, and `<` as an exit. All authored exits
remain live; every one points to the exact saved outside gate. A source
lab's introductory message and milestone fire only on first entry.

## Source-position Lua and placed content

Replace source shared and map-local executable scripts with named Lua
modules under `policy/generation/vaults/wizlab_entry/` and
`policy/generation/vaults/wizlab/`. Keep a hook at each original script
position in its `.des` file, with the source body as a readable comment
where useful. The existing TODO to consolidate layout hooks into DES later
also applies here. A hook receives the narrow placement API; it emits DES
directives or typed records, not mutable module-level game state.

Resolve source random lists, shuffles, substitutions, equipment, fixed
artefacts, colours, transporters, fog machines, door descriptions, and
feature names through the existing catalogs and placement systems.
Shared item, monster, terrain, spell, and component IDs are imported at
their use sites. Do not silently discard unsupported records: keep their
typed source intent, then connect their gameplay effect in the relevant
domain owner. Any genuinely legacy faulty source directive may be
corrected with a comment explaining the intended effect.

The Roulette of Golubria's paired transporter markers use the existing
saved transporter owner. Lehudib's entry and exit transporter pairs use
the same owner. Map-specific fog machines and clouds use the current Akara
fog and cloud systems. Wucad's veto-destroy markers and Cigotuvi's fleshy
doors use their authored properties in interaction and presentation.

## Timed entrance and travel

One Akara gate is created from each realized source-position `O` marker.
It owns level, coordinate, source map and record identity, creation time,
one 600–800-turn draw, deadline, notice cadence, spent state, and closure
reason. Global player action time advances its deadline even when the
outside floor is inactive. Entry on the final valid turn succeeds before
expiry; later entry refuses. The Lua timer policy emits the source
crackling discovery and fading messages, respecting the shared hearing
and Silence rules. A closed portal becomes the source expired feature.

Entry uses the generic staged Lua portal transaction. Stage and populate
the entire destination before spending the gate. The visit component saves
the exact outside level and cell plus the selected lab ID. Returning retires
the temporary floor and its entities, event state, fog machines, and other
owned effects. An occupied outside return cell refuses safely. A failed
hook, map, population step, or landing changes neither player nor gate,
RNG, levels, or saved entities.

The current command and population paths list temporary portal domains one
by one. This slice moves their registration to Lua-discovered handler files
with stable IDs and feature/marker ownership, then migrates the existing
temporary portals in one pass. Navigation and population call the resulting
sorted handler catalog. A new temporary domain adds its own handler
instead of growing a central `if` chain; source portal policy remains in
its own module. Pan and Hell travel remain with their persistent branch
owners. The catalog rejects duplicate feature or marker ownership.

## Live lab events

Port the four source callback families into readable Lua policies. Event
state is saved in Akara, and terrain mutations are made through the grid.
No callback stores gameplay state in a Lua module global.

- **Doroklohe:** its authored countdown has two audible or silent warnings,
  then lowers exactly the `wall_drop` marker group to floor and places short
  black-smoke clouds. Save its phase and next firing time so restore cannot
  replay the collapse.
- **Zonguldrok:** grave markers drive the source visible and background
  chance draws, escalating zombie/wight/vampire/warrior waves and counters.
  Spawned actors retain the source ownership mark. Their deaths open the
  hidden door when the source grave-to-kill condition is met, release the
  `no_tele_into` mask, and can awaken the named ancient lich once. Save
  grave consumption, counters, door state, and lich state.
- **Wucad Mu:** one-shot shadow messages respect Silence. Its countdown
  attempts up to three short-lived monks near the player using source
  species weights and terrain checks. Wucad Mu's death saves a permanent
  suppression flag, stops future monks and messages, and emits the source
  final text. Existing summon ownership handles monk expiry.
- **Borgnjor:** on eligible monster deaths, the source one-in-five chance
  tries one nearby lost soul. Souls spawned by this callback are marked so
  their own deaths do not recur. The summon owner handles their source
  short lifetime.

Source event ordering is deterministic relative to player action time,
monster death, visibility, cloud effects, and portal return. Draws use
named saved RNG streams; the next outcome after restore matches continued
play. Author-authored monster abilities outside these lab callbacks remain
owned by their respective combat domains, with any remaining fidelity gap
recorded in the port inventory.

## Save, client, and mod contract

Add distinct Wizard Labs entrance and exit feature IDs and terminal glyphs.
Inspection names the magical portal and its current state. Save validation
joins every realized entrance marker to exactly one gate, checks its timer,
deadline, feature, closure, and source ID, and joins any active visit to one
spent outside gate and one source destination floor. Lab event validators
compare phase, counters, active marker groups, changed grid cells, and
source record identities. Reject missing, duplicate, foreign, or altered
state before play resumes. Existing effective-ruleset hashes continue to
protect modded saves.

The modding guide explains the map and hook directories, placement API,
timer and visit fields, event state ownership, same-path replacement, and
sparse new map addition. A new lab map or hook can be added without editing
Go or a central ID switch. The port inventory states exactly which source
behaviors are live and which other gameplay domains still affect fidelity.

## Verification

- Audit all 26 committed definitions against source MAP digests and
  metadata, plus every source-position hook and callback registration.
- Place and populate all fifteen destinations through the production path;
  inspect text snapshots for terrain, typed effects, exits, and outside
  connections.
- Exercise entrance chance and Vaults' special attempt, deadline edges,
  inactive-floor expiry, messages, staged rollback, multi-exit return,
  and visit/save reciprocity.
- Exercise every callback family before and after save/restore, including
  the silent warning, death reentry guards, actor expiry, marker
  consumption, and deterministic next draw.
- Exercise sparse mod addition, same-path replacement, zero-weight
  exclusion, malformed hook/marker rejection, and a complete normal
  terminal entry/return flow.
- Run focused Lua and integrated Go checks once the whole slice is in
  place, then check formatting and commit the domain in one product commit.

# Abyss domain design

## Intent

Replace the fixed Abyss test floor with the source game's complete,
changeable Abyss. Banishment, Abyssal Knight starts, a Pan exit, Abyssal
stairs, ordinary exits, the abyssal rune, monsters, and authored vaults must
share one saved world. A player can move through an Abyss that changes around
them, recover the rune, escape to the saved outside site, and resume the
same state after a save. Mods add or replace one DES map or Lua rule by path.

The pinned references are `crawl-ref/source/abyss.cc`, `abyss.h`, and
`dat/des/branches/abyss.des`. The source DES contains 100 definitions:
97 MAP blocks and three mapless weighted dummies. Keep each active MAP block
byte-identical in an individual committed `.des` file. Translate embedded
scripts to readable source-position Lua hooks. The original DES text remains
the map language; no build invokes an importer and no Go file contains Lua
source.

## Runtime ownership

One mutable Abyss level owns an 80×70 dense terrain grid, exploration, and
placed vault records. Its saved Abyss state owns branch depth 1–7, the
separate continuous procedural morph depth, source world coordinate and
phase, terrain seed, shift counter, selected map IDs, per-cell next sample
change points, the borrowed non-Abyss floor identity and layout, the exit
XP counter, the spawned-exit flag, the minimum reached branch depth, and
pending transiting entities. Save the sample queue explicitly; restore it
without consuming a new random draw. Akara owns actors, items, statuses,
and banishment origin. Lua owns terrain sampling, feature and vault draws,
monster selection, depth progression, and the policies for entering,
shifting, descending, and escaping. A reusable Go grid transaction applies
Lua's validated terrain and coordinate plan to the level and ECS entities
atomically. The transaction has no Abyss map or monster ID switch.

The current level ID 1000 remains the Abyss storage identity. Changing
depth or region replaces that level's generated region rather than
accumulating seven persistent floors. The level's saved local depth changes
with the source state. Ordinary branch links never point into this mutable
region. Banishment origin stays on the player; an Abyss exit uses the saved
outside site and the shared safe-landing rule.

## Terrain, movement, and entities

Initial entry follows source generation order: generate an area and place
vaults, then apply the proto-Abyss feature overlay. The overlay can replace
nearby vault terrain. An Abyssal Knight starts in the pocket Abyss with a reachable exit and
nearby Lugonu altar; the pocket-start flag gives that exit an explicit D:1
destination without requiring a banishment component. Ordinary banishment
does not create that guaranteed exit and returns to its saved departure. A new region
uses the source's Wastes, Worley, Rivers, RoilingChaos, and borrowed-level
layout samplers, feature chances, weighted extra maps, and a depth-qualified
monster population. The first visit and later
teleports create a new region. Each spent action advances the source phase
and morphs eligible terrain. Approaching the map edge shifts the preserved
area around the player to the centre, retains whole protected vaults and
their local entities, discards out-of-range cells, and generates new edges.
The player and any surviving actors, items, clouds, and markers move by one
consistent coordinate delta; discarded dynamic entities leave ECS storage
or enter the explicit transit queue according to source behavior.

The shifted region must remain traversable around the player. It must not
replace the player's cell with harmful terrain, split a protected vault,
strand a live entity inside solid terrain, or duplicate a rune or unique
monster. Exploration and source feature ownership move with preserved
cells; freshly generated cells start unseen. Saved RNG streams and Abyss
state make a turn replay identically after restore.

## Depth, exits, and rune

Abyssal stairs descend at branch depths 1–6, capped at seven; a descent
generates a fresh region. Time advances procedural morph depth and phase,
which change terrain sampling without changing branch depth. Monster XP
reduces the exit XP counter; when it reaches the source threshold, an exit
or downward stair can appear. Banishment and the source's forced-descent
teleport rule can also change branch depth.

Ordinary exits occur with source depth and rune-dependent chances and can
use an `abyss_exit` map. An exit returns the player to the latest saved
outside departure with a safe landing. The rune can appear from an
`abyss_rune` map or the source fallback at eligible depths, with the
source increasing chance and the one-rune-on-floor invariant. The rune is
an ordinary saved item; after pickup it cannot be generated again.

The first nine source MAPs are outside `enter_abyss` vaults for Depths or
legacy deep Dungeon; they join the ordinary branch-entry path. They are
never selected as interior Abyss furniture. The remaining source catalog
has furniture, rune, and exit selection roles. Mapless dummies retain the
source chance of selecting no map. Source
weights, depth restrictions, uniqueness, transforms, keyed monsters/items,
and script operation order use the effective layered DES catalog. Every
source-position hook has a named Lua function with comments explaining
why and how. New maps from an overlay join their role by tags and path,
without a Go or Lua central ID switch. A malformed overlay fails the
current action without changing terrain, ECS, RNG, or the saved origin.

## Save, presentation, and verification

The save validator checks the mutable grid size, branch and morph depth,
phase, exit XP counter and flags, sampler queue, borrowed layout identity, player position,
outside origin, live feature/actor coordinates, unique rune state, protected
vault records, and transit ownership. Restore never redraws a region.
The existing full-terminal client renders the final grid and Abyss depth;
ordinary stair and exit commands explain their action through the current
message policy. The status screen and travel labels use `Abyss:N`.

Test every active DES definition through the production parser and
placement path, compare all 97 MAP blocks with the pinned source, and
exercise both branches of every conditional source hook. Integration
tests cover banishment, the pocket Abyssal Knight start and D:1 exit,
a shift while standing in a vault, depth 1–7 travel, exit and rune maps, rune pickup, monster and item
transit, save/restore replay, sparse mod addition/replacement, and failed
generation rollback. Commit text snapshots showing a proto area, a shifted
area with connections, a rune region, and an exit region. Keep Lua
functions commented, lines at most 120 characters, and multi-field tables
expanded. Use one contiguous Abyss implementation commit on `main` and
push it to the user's fork after whole-domain verification.

## Approaches considered

The selected design follows source Crawl's bounded moving window: one
saved Abyss level changes while the surrounding world coordinate advances.
It matches source traversal and avoids accumulating abandoned floors.
An unbounded persistent tile world would simplify some spatial references
but change memory, discovery, and encounter behavior. Replacing the whole
grid on every move would discard source-preserved vaults and nearby actors.
Retaining the current fixed floor would leave the central Abyss mechanics
unimplemented.

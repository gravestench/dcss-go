# Hell Branches Design

## Purpose

Make the pinned DCSS Hell playable in the Go engine: enter from an
authored gate, traverse the Vestibule and its four subbranches, collect
their runes, and return to the exact gate used to enter. Keep the source
`.des` maps and port their executable decisions into named Lua hooks.
The player must not lose a saved floor or redraw a map by revisiting it.

## Source and scope

The pinned source is `crawl-ref/source/dat/des/branches/hell.des`,
`dis.des`, `geh.des`, `coc.des`, `tar.des`, and the shared `hells.des`.
Together the first five files declare 242 named maps. `hell.des` has 60:
entry maps, one mandatory Vestibule map, and its five tagged sub-vault
families. Existing branch definitions, populations, and some procedural
layouts provide starting catalog data; they do not make these floors
playable yet. The remaining Hell-specific maps and rules belong to this
domain, including the four branch bottoms and their rune and boss content.

The source's saved branch metadata remains in `content/branches`. Runtime
builds read only committed Go and Lua assets; the C++ checkout is a reference
for deliberate development, never a build dependency. As with other vault
families, one `.des` file owns each map's geometry and static directives.
Named Lua handlers replace source inline script at the same declaration
position. Helper code is shared only when maps share a real source rule.

## Ownership and travel

The Lua Hell travel policy decides what a Hell gate means. The Go kernel
stages a new level, validates the destination, moves the player through
the existing ECS and grid transaction, and saves the travel state. A saved
Hell return site records the ordinary-world level and cell of the most
recent entry. Reentering the Vestibule through another gate updates that
site; the Vestibule's exit always returns to the most recent one, matching
source `stairs.cc`. The Vestibule level and all four branch floors persist.

The four source entrance features in the Vestibule lead to branch depth
one. Each Hell subbranch's exit feature returns directly to the Vestibule
from any depth; ordinary down stairs descend within that branch. These
features are distinct typed terrain IDs, so the client can show their
source names and Lua can route travel without parsing vault records.
Hell's top-level entrance is placed through the source `hell_entry` family
on Depths floors. The pinned source also mentions D:21- inside a legacy
version guard; the current map declarations select Depths only. A source
fallback keeps a one-cell gate available when a larger entrance cannot fit.
Map selection is stable under file discovery order
and records the same unique-vault history as other branches.

The Vestibule is a required authored `PLACE: Hell` primary map. Its five
`SUBVAULT` groups insert Dis, Tartarus, Cocytus, Gehenna, and Geryon
pieces. Source shuffle, keyed features, monsters, and substitutions remain
in the `.des` operations. Hook decisions use the generation API's saved RNG
stream, never a Lua module global. Geryon is one placed live ECS actor.

Subbranch floors use source layout eligibility. Non-bottom floors use the
source compact Hell size and one down stair; branch bottoms use required
authored end maps with their source bosses and rune placement. The source
does not require a direct parent-floor up stair at every depth: an exit
returns to the Vestibule. Save validation proves the return site, branch
depths, exits, and the four rune sites. No generic branch scheduler entry
is fabricated for rootless Hell.

## Lua and content

Create mod-discovered map families for Hell entries, Vestibule pieces,
each subbranch's ordinary vaults, and each end map. Port source helpers
such as entry tiers, lava and water spawn substitutions, and end-map
setup to small, commented Lua modules. The `.des` parser must reject any
remaining executable source Lua; every executable site gets a named hook.
Unimplemented source directives or feature effects must be represented as
typed records with explicit behavior or an explicit remaining gap, never
silently dropped. The four rune IDs and monster definitions come from
the existing Lua catalogs and are imported at use sites.

Hell's level-entry effects belong to the Lua travel action, following the
source `stairs.cc` call after arrival on a Hell subbranch floor. Dynamic
actors, status, and any timed effects use
Akara components; terrain remains in the dense grid. This system must not
retain game state in a Lua module variable. Rules that are not yet faithful
must be called out in the port inventory rather than approximated without
evidence.

## Verification

- Catalog tests count source-backed map definitions and validate every
  named hook through the effective layered VFS.
- Seeded generation tests inspect all five Vestibule sub-vault groups,
  reachability, branch entrances, branch bottom maps, bosses, and runes.
- Travel tests enter Hell from two ordinary-world gates, verify the latest
  return site, descend each subbranch, and exit directly to the Vestibule.
- Save and restore tests preserve all generated floors, the return site,
  selected map identities, ECS actors, and rune pickup state.
- Failure tests prove malformed hooks, missing primary maps, invalid Hell
  exits, and failed generation leave the old floor and travel state intact.
- Run focused Lua and Go tests at domain boundaries, then one integrated
  verification before a category-sized commit to `main` and push.

## Delivery categories

1. Source Hell gates, Vestibule map and tagged pieces, typed features, and
   persistent entry/return travel.
2. Dis, Gehenna, Cocytus, and Tartarus floor catalogs, compact generation,
   exits, and ordinary map content.
3. Four source end-map families, bosses, runes, Hell effects, and full
   replay/save verification.

These are implementation categories for coherent commits. The completion
claim requires all three categories and the verification above.

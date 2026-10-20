# Source-backed unique placement

## Intent and boundary

Dungeon Crawl's named monsters should enter the Go game through the same
authored unique-placement rules as the pinned DCSS source. A modder should
be able to add or replace one unique `.des` file without editing a Go switch
or a central vault list. This slice covers all 80 definitions in
`dat/des/builder/uniques.des`, the selection stage, source bands, and saved
run-wide uniqueness. The C++ source remains read-only; committed Lua and
`.des` files are the runtime authority.

## Map data

Each source NAME becomes one `vaults/unique/<name>.des`. Preserve DEPTH,
WEIGHT, CHANCE, TAGS, MONS, ITEM, terrain directives, and MAP rows in their
authored order. Expand the 69 source `place_unique` helper calls into their
equivalent `MONS`, tags, and one-cell MAP in each file. Do not embed inline
Lua. Crazy Yiuf's cottage retains its MAP and moves its conditional source
directives to named, commented Lua hooks. The six source Pan vetoes move to
named handlers; rune and once-per-run state come from the level context.

## Generation and ownership

Run the unique stage after secondary vaults and before ordinary population,
matching source order. A selector uses the shared vault catalog, branch and
depth predicates, source weight, map-use history, and live unique history.
Every attempt follows the source's one-in-A loop (initial A=2), available
count gate (B=5), dummy outcomes, and steepening after three successes.
Failed geometry and dummy choices do not spawn a unique. Successful maps
use ordinary vault placement, origin records, protected cells, and save
validation. RNG comes from existing named level streams.

The unique history owner records monster kind IDs across generated floors
and survives death and save/restore. It blocks another ordinary unique
placement even if the earlier actor is gone. Source exceptions such as
Boris regeneration and Pan lord rules are explicit policies, not random
catalog fallbacks. The current Dungeon generator uses this stage now;
other branch generators will call the same owner when those branches land.

## Bands

The source `... band` monster request resolves to the named leader plus a
band request. Band membership and size are Lua data/rules traced to the
source, not additional monster catalog identities. The population owner
places followers as ordinary Akara actors near the leader, with follower
links and independent saves. The same band policy serves vault and ambient
leaders where the source calls for bands. Source variations in membership
and size remain local to the band policy; missing or blocked cells reduce
the group rather than duplicate an actor.

## Modding and verification

Document `.des` authoring, unique tags, named hooks, band ownership, and
saved uniqueness in the modding guide. Tests compare the 80 IDs and source
MAP rows, exercise weighted dummy and real selections, unique history
across levels and restore, source band examples, Crazy Yiuf and Pan veto
hooks, and a generated Dungeon floor. Run the focused Lua and Go generation
and save suites before the single category commit is pushed to `main`.

# Pandemonium domain

## Purpose

Make Pandemonium a playable, source-shaped part of the same run. A portal on
an eligible Depths floor enters Pan; transit gates replace the current Pan
region; exits return to the saved entry site or lead through the Abyss. Pan
lords, their runes, ordinary demonic-rune sites, population, and every active
source map belong to this domain. Repeated transit, rune pickup, escape, and
save/restore must all use live game state.

The pinned source is `crawl-ref/source/dat/des/branches/pan.des` at the
repository's documented C++ revision. It contains 142 named map definitions,
of which 141 are active; `pan_demonic_rune_highlights` is source-tagged
`removed` because its double-vault guarantee never worked. Import the 141
active maps and document that one intentional omission.
The maps include entry, exit, lord, ordinary rune, serial, and extra sites. Their
geometry and ordinary directives remain in individual committed `.des`
files. Source inline Lua becomes readable named modules under the embedded
mod tree; executable Lua does not remain in `.des` or Go strings.

## Ownership and runtime

Lua owns Pan's floor sequence, portal stack, map selection, unique-lord
history, rune policy, and travel rules. Akara components hold persistent
player and actor state. A saved session record holds the Pan region number
and return site because those describe the run rather than one entity. The
current Pan region has one level ID and is replaced on transit. The old
region's entities and level data are discarded; a save retains only the
current region and the counter. This mirrors the source's one-depth,
successive-region branch without accumulating unreachable floors.

Go provides generic operations needed by Lua: replace a level atomically,
retire its entities, and expose portal feature/link facts. Go does not choose
Pan maps, lord identities, exit probabilities, or messages. All new map and
rule files participate in the layered VFS by relative path, with no central
file list or source importer required at build time.

## Source map selection

Import all 141 active source definitions, not only those selected in a test seed.
The effective DES catalog remains authoritative. Lua distinguishes the
source entry pool, the mandatory Pan primary pool, tagged unique-lord realms,
ordinary and demonic-rune primaries, and optional extras. A selected Pan
region always receives a primary map, as in the source. The source's
`levels_seen` pressure toward unseen unique lords, four named realm tags,
once-per-run uniqueness, and rune/decoy choices use saved history and named
RNG streams. Optional maps may add exits, Abyss gates, items, monsters, and
typed pending effects through the existing placement and ECS paths.

The existing procedural Pan layouts and committed Pan population rows are
used by this branch. No C++ files are read at normal build or launch. Map
selection sorts stable IDs before weighted draws so file discovery order does
not affect a seed. A mod may add a map by path or override one at the same
path; startup validates every active named hook and content reference.

## Travel and save contract

An entry portal records the exact originating level and cell. A Pan exit
returns to that site using the normal safe-landing rule and clears the stack
entry. A transit gate makes a new Pan region without pushing another return
site. An exit-through-Abyss goes to the Abyss while retaining the intended
source return semantics. At most one active Pan region exists in a save.
The saved region counter, selected map IDs, unique-lord decisions, rune
progress, portal origin, RNG states, entities, and terrain are validated on
restore without rerolling generation.

Missing or malformed return data is an explicit save error. Transit must not
silently reuse the previous region or duplicate its items. A failed portal
action must leave the previous floor and random state intact. Existing
Dungeon, Depths, Zot, and Abyss travel retain their behavior.

## Client and verification

The ASCII client shows the source portal and Pan entry/region messages,
identifies transit versus exit gates, and keeps the full-terminal layout.
Unavailable effects in imported vaults remain typed records with honest
pending reasons until their gameplay consumer is implemented; those records
must not suppress Pan selection or discard map geometry.

Verification exercises every imported active map's parser and hook path, all
primary categories, and one generated run entering Pan, crossing two
transit gates, collecting a rune, saving mid-region, and exiting. Assertions
cover old-region entity retirement, return placement, unique-lord history,
seed independence from file discovery order, and a sparse mod-added Pan map.

# Ordinary Branch Travel Design

## Purpose and scope

Dungeon Crawl's ordinary branch entrances must lead to persistent branch
floors, return to the exact parent stair, and select the source branch's
terrain, vaults, and monsters. This replaces the generated game's assumption
that every pending stair leads to the next Dungeon depth. The first playable
integration targets Lair and Orc because their branch catalogs and working
layout pools already exist. The same runtime contract applies to the other
ordinary branches as their required layouts and content become executable.
Portals, the Abyss, Hell entry, Pandemonium, and timed side branches retain
their distinct travel policies.

This is a Lua policy and Go ownership change, not a new Go branch switch.
Lua owns eligibility, entry scheduling, floor generation, monster pools, and
branch text. Go owns level grids, entities, stair links, atomic installation,
and saves. Existing `.des` and Lua files remain the source for map and vault
selection. No game build reads the C++ checkout.

## Stable identities and topology

An ordinary floor's numeric level ID is `numeric_id * 100 + local_depth`,
using the committed branch catalog's numeric ID. Dungeon keeps IDs 1–15.
The existing Abyss ID 1000 remains reserved; ordinary local depths start at
one, so the formula does not collide with it. The generated save validates
the mapping against the effective branch catalog. Branch IDs, local depths,
and parent branch IDs are explicit in Lua generation input and level records;
callers never infer a branch from an integer range.

At new-game creation, Lua chooses the finite ordinary entrance depths from
the catalog in stable branch-ID order. Its choices are saved as the run's
branch schedule. Source mutually exclusive Lair branch pairs are selected
once: Swamp or Shoals, and Snake or Spider. A chosen entrance is placed when
its parent floor is generated, not by scanning a later level and rerolling.
The schedule and chosen pairs survive save/restore unchanged. Source branch
records whose entry range is negative, whose parent is `NUM_BRANCHES`, whose
depth is zero, or whose flags include `no_x_level_travel` are outside this
ordinary schedule. This excludes Ziggurats despite their finite entrance
range; their portal policy remains separate.

Every entrance is a distinct pending stair whose destination is the target
branch's first floor ID. Source entry and exit feature IDs remain typed
level records for presentation and future feature policy. The Go grid may use
its existing generic linked-stair terrain; the source identity is not lost.
An unsupported branch keeps its visible entry and gives an explicit
unavailable explanation until its layout and population domains are ready.

## Floor generation and travel

Lua's generated-floor policy accepts an explicit destination branch and
local depth. It uses the existing layout catalog, extra-vault selector,
unique map history, and terrain decoder with that branch's source depth and
absolute depth. Dungeon:1 still places an arrival; branch floors do not.
Source branch-only layouts can now enter the normal selector when their
branch is active. The selected stair, not a generic first exit, determines
the landing.

The stair postpass takes a floor profile: Dungeon uses its existing three
ordinary up and down pairs; a branch entry floor has one return up stair;
an interior branch floor has three ordinary up and down pairs; a branch
bottom has no newly invented down stair. Authored exits are preserved.
When a branch entrance is used, the child return stair links to that exact
parent cell. On deeper branch travel, matching pending exits are paired as
the current Dungeon implementation does. Multiple branch frontiers may
exist at once, and a floor that has not been visited has no generated grid.

Go installs the new level and patches parent links as one transaction. It
checks the selected link, destination ID, branch metadata, reciprocal
coordinates, destination walkability, and protected cell conflicts before
the player moves or population begins. Failed Lua generation or malformed
mod output leaves the old level and links unchanged. Returning to an
existing floor never regenerates it or rerolls population.

## Branch monster population

All active source rows in `mon-pick-data.h` become committed Lua catalog
data keyed by branch ID. A deliberate source refresh may regenerate them;
ordinary builds use only the committed files. Rows retain source min/max
local depth, rarity, curve, and monster ID, including duplicate rows. Lua
imports the shared `ids.monsters` constants and the common curve names at
their use sites. Macro expansions and version guards are resolved during
the one-time import, with no importer left in the game repository.

The population picker receives branch ID and local depth explicitly. It
uses the existing curve math and seeded draw order, then asks the same ECS
factory to create actors. It does not reuse Dungeon rows by treating a
branch level ID as a Dungeon depth. Branch-specific monster budgets and
out-of-depth limits are Lua policy tied to the catalog. Empty eligible
pools produce a named error during validation; they do not silently fall
back to Dungeon monsters.

## Save and compatibility

The Go snapshot stores the branch schedule and existing per-level branch
IDs, stair links, vault-use IDs, terrain, population count, and actors.
The save version increases because older generated saves lack the branch
schedule and cannot prove their frontier links. The Lua save validator
checks each generated level by `(branch_id, local_depth)`, verifies that
the schedule has only legal parent-depth choices and mutual exclusions,
and confirms every nonpending stair's exact reciprocal link. A pending
stair may target any scheduled absent child floor, not just `id + 1`.
No two levels or entries can claim the same numeric floor ID.

The client displays the effective branch abbreviation and local depth
from the level's branch metadata. It uses the saved source feature identity
to label entrance and return messages. Missing mechanics remain visible
with an unavailable explanation, matching the current UI contract.

## Verification

- Lua tests compare the committed source population row totals and sample
  curves for Dungeon, Lair, Orc, and deeper branches; mod overlays can add
  rows without redefining Go branch cases.
- Seeded tests prove entry depths stay within source ranges, Lair pairs are
  mutually exclusive, and file discovery order cannot change a choice.
- Generation tests enter Lair and Orc from scheduled Dungeon floors, descend
  within each branch, return to the exact entrance, and cross other saved
  floors without regeneration.
- Save tests cover two simultaneous frontiers, branch return travel,
  uniqueness history, malformed IDs, forged schedules, broken reciprocal
  links, and a failed mod policy transaction.
- One integrated Go test run and the Lua rule suite follow the whole slice;
  category-sized commits go directly to `main` and are pushed to `origin`.

## Remaining domains

This slice establishes ordinary branch travel. Branches lacking executable
layouts, special generation rules, unique end vaults, runes, or complete
feature effects remain identified in the port inventory and are activated
by their later content slices. This spec does not claim those domains are
finished merely because the branch topology exists.

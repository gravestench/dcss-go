# Entry-time Dungeon terrain design

## Purpose

Dungeon Crawl currently builds fifteen Dungeon grids before play begins so
every stair already knows its destination coordinate. This consumes future
layout, vault, and population-count RNG before the player's first turn. Build
only D:1 and the current Abyss level at startup. Generate D:2–15 on the first
valid descent, using the live RNG state at that moment. A save before descent
must continue to the same floor as an uninterrupted game.

The result remains the basic-layout Dungeon. Later layout families, branch
entrances, and Lair generation are separate content slices. Existing arrival
and supplemental `.des` maps remain eligible at their current depths. Fixed
test scenarios keep their present complete terrain.

## Ownership and stair contract

- Lua owns floor layout, vault selection and placement, population budgets,
  and which cells are paired. Go owns the `Level` grid, occupancy, links,
  exploration, and save encoding. No Go rule chooses a vault or monster.
- A `StairLink` gains an explicit `Pending` state. A pending link has a valid
  next Dungeon level ID, no destination cell, and no unavailable message. An
  unavailable boundary remains distinct. Once linked, both endpoint cells
  and both reciprocal records exist. The save record carries the same state.
- D:1 has its authored arrival, extra vaults, starting curing potion, and
  population at startup. Its down links are pending. D:15 down links retain
  the existing unavailable Depths message until that branch is implemented.
- On first descent, Lua builds the destination floor and pairs all pending
  down stairs on the parent with up stairs on the child. The pairing order is
  deterministic by saved stair coordinate, independent of Lua file discovery.
  Extra source-vault exits remain playable: the policy adds connected
  landings to the child when the parent has more down stairs, or connected
  departures to the parent when the child has more up stairs. Parent additions
  must use live, unoccupied floor cells, avoiding explored cells when possible.
  The policy returns only parent cell/link additions and pending-link
  resolutions, so it never overwrites live terrain or actors.
- Generation, parent link updates, destination population, and the stair move
  happen within one game step. The chosen stair lands at its paired child
  coordinate. Reentry never regenerates or repopulates a floor. Invalid or
  unavailable stairs spend no generation RNG.

## Starting items and saves

- The fixed D:2 heal and haste potions are placed during D:2's first
  population, after its monster and inventory draws. They are not created on
  a floor whose terrain does not exist. D:1 curing remains at startup.
- New saves contain a contiguous generated Dungeon prefix D:1..D:k plus the
  Abyss. Only D:k may have pending links to D:k+1. Generated floors in the
  prefix have positive initial actor counts after their entry completes.
  Fixed scenarios still save all their floors and use only resolved links.
- Restore validates the prefix, geometry, branch IDs, population budgets,
  pending link direction and destination, paired links, valid parent patch
  cells, and absence of actors on nonexistent floors. Save format version
  advances for the explicit pending-link representation. Ruleset hashes still
  protect effective Lua content.

## Verification

Test startup with D:1 and Abyss only; first descents through D:15; source
vault extra stairs in both directions; the three starting potions; return and
reentry; save before and after generation; different pre-descent RNG usage;
unavailable boundary stairs; and corrupt pending-link saves. The generated
game constructor should become substantially faster without a test-only
cache or global Lua state. Run focused generation, population, stair, save,
vault, and terminal checks before the broader package suite.

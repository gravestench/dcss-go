# First-entry Dungeon population design

## Purpose

Dungeon Crawl currently builds and populates all fifteen Dungeon floors
before showing D:1. DCSS populates a new floor when the player first enters
it. Keep the already-paired D:1–15 terrain and stair topology, but defer
monster and authored vault entity creation until first entry. This reduces
startup work and lets later turns consume RNG before a future floor is
populated.

This is a population change. Generating terrain lazily needs a separate
topology design because today's stair links store concrete destination cells.

## Ownership and flow

- `Level` owns whether its initial population has run and the authored
  no-spawn cells needed when it runs. The population budget and initial actor
  count remain level state. Save and restore preserve all three.
- The initial game creates D:1 population and the existing fixed floor
  consumables. D:2–15 start with `initial_actors = 0`; their vault records
  remain pending. The Abyss retains its existing empty population.
- Before a player uses a linked stair into an unpopulated Dungeon floor, Go
  calls the existing Lua `world.populate` policy with that floor's record and
  the actual destination cell as its entry. Go applies the pending Akara
  changes before the stair action. The Lua policy owns all monster, item,
  shop, and vault behavior. Go adds no content-specific dispatch.
- Subsequent entries do not call the policy again. The saved initial actor
  count is positive after successful population even if some actors later
  die. For fixed scenarios, the existing initial population path remains.
- Stair preflight happens only after command preparation says the action is
  valid and spends time. An unavailable stair makes no population draws.

## Save integrity

Generated saves may have an unpopulated floor only when its initial actor
count is zero and its no-spawn cells are valid, unique in-bounds coordinates.
A populated floor retains the existing budget bounds. Restoring before
first entry must leave RNG and pending vault records unchanged; entering
after restore must produce the same entities as uninterrupted play.
The level validation also accepts fully populated snapshots with positive
initial actor counts. Normal ruleset-hash checks still apply to older files.

## Verification

Test a new game, first descent, return, second descent, save before and
after first entry, unavailable boundary stairs, and deterministic continuation
across restore. Verify that authored vault records materialize only once and
that initial actor counts match saved entities. Run the focused generated
Dungeon and save suites, then broader Go/style checks at the slice boundary.

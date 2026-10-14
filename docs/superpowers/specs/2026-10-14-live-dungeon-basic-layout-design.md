# Live Dungeon basic layout

## Goal

Replace the playable fixed 17×9 map with generated `layout_basic` geometry on
Dungeon:1–2. Keep the existing fixed scenario as a deterministic test fixture.
This is a step toward the pinned DCSS Dungeon, not a claim that its other
weighted layouts, vaults, content, or deeper floors have been ported.

## Ownership

`levelgen.BasicDungeon` builds short-lived terrain from the game's named
`layout` RNG stream. `game.Level` owns the resulting grid, doors, exploration,
stair links, and actor occupancy. Akara continues to own the player, monsters,
items, and turn systems. `game` coordinates two generated levels, source count
draws, stair pairing, and initial placement. No C++ files are needed at run
time.

## Live behavior

- Generate 80×70 D:1 and D:2 grids from the run seed. Place the player on the
  first D:1 up stair. Connect each D:1 down stair to its same-index D:2 up
  stair in both directions. D:1 up and D:2 down stairs have explicit boundary
  links; using one explains that destination is not ported and spends no time.
- A closed `+` door blocks actors and sight. Moving toward it opens the whole
  orthogonally connected door group as `'`, spends the normal action time, and
  leaves the actor in place. This follows `movement.cc:1169-1177`,
  `player.cc:7825-7950`, and `terrain.cc:751-785` in the pinned source.
- D:1 and D:2 monster counts use `roll_dice(3, 12)` and `roll_dice(3, 10)`
  respectively (`dungeon.cc:1571-1628`). The current three supported ordinary
  animals are drawn from the committed depth-weighted population catalog.
  Their restricted species pool and placement policy remain explicit port
  limits. Dynamic monsters and corpses remain Akara entities.
- Starting gear is unchanged. The current curing and heal-wounds potions are
  placed on deterministic open floor cells of their respective levels.

## Saves and validation

The Go snapshot stores generated rows, opened doors, all stair links including
boundary messages, initial monster budgets, RNG states, and remembered terrain.
The existing version-8 fixed-scenario records remain readable because new
fields are optional for them. Generated-scenario records require valid budgets
and the exact D:1–2 level shape. XP validation uses saved initial budgets and
remaining live monsters; malformed boundary links are rejected. Restoring a
save never regenerates terrain or consumes the layout RNG stream.

## Checks

Verify deterministic seed behavior, dimensions and three stair pairs, door
blocking/opening/sight and saved state, boundary no-time responses, travel
round trips, source count ranges, and deterministic save continuation. Run the
full Go tests, vet, build, and readability gate at the category boundary.

# Remaining monster spellbooks

This slice adds resolvers for the sixteen spell IDs that were still present
in monster spellbooks without a Lua effect. Each has its own `plan` and
`resolve` module under `policy/combat/monster_spells`. The spellbook selector
and action scheduler still own choosing and spending the cast; effects own
their rules. No central spell switch grew to accommodate the new cases.

The new effects cover terrain changes (Awaken Earth, Call Tide, Corrupt Locale,
Seal Doors), tactical and beam effects (Cantrip, Chaos Breath, Concentrate
Venom, Porkalator, Portal Projectile), autonomous attacks (Doom Howl, Orb of
Destruction), and summoned or recruited actors (Call of Chaos, Create
Tentacles, Druid's Call, Malign Gateway, Sheza's Dance). They reuse existing
terrain grids, combat owners, Akara components, and named Lua policies.
Persisted effects include Doom Howl arrivals and their XP provenance, tide
state, venom, changed forms, called beasts, gateways, and tentacles. The
save-link tests cover casters and targets dying before those effects finish.

## Source parity still to build

The resolvers make these spells executable, but several source behaviors
need later domain work before claiming full DCSS parity:

- **Call Tide:** Shoals heightmaps and tide velocity are not in the Go world
  yet. The current rule floods and restores shoreline cells with a saved
  duration; the Shoals generation and terrain slice should supply the real
  heightmap propagation.
- **Awaken Earth:** the current terrain owner cannot query the original
  vault `veto_destroy` marker. Add that marker to placed vault records before
  allowing this spell to destroy protected rock.
- **Corrupt Locale:** terrain and Abyss servants are placed, but source
  displacement of actors and items and cosmetic color-only effects need the
  corresponding level and presentation rules.
- **Seal Doors:** door and stair links seal and restore, but the source's
  tension comparison is not yet represented in the AI selection rule.
- **Porkalator:** spell-converted hogs return when Kirke dies. Original band
  hogs and deferred restoration on unloaded floors need the band/world slice.
- **Malign Gateway:** severed tentacles lose 20 HP per turn but do not yet
  drift toward an anchor while writhing. The connection pathfinder is a grid
  approximation of source constraints.

These are behavioral follow-ups, not reasons to reintroduce missing-module
fallbacks. Each should extend its focused owner and gain a source-based
regression test when the necessary world data exists.

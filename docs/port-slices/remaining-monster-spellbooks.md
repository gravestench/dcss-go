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

- **Call Tide:** a follow-up now gives Shoals levels a saved heightmap and
  tide clock. Lua advances the source tide velocity and floods connected
  coast cells. The current level generator derives threshold heights from
  terrain unless a scenario supplies a smooth `heightmap`; source Shoals
  island generation, tide immunity, and full entry catch-up remain.
- **Awaken Earth:** a follow-up reads retained vault marker properties and
  honors `veto_destroy="veto"` on protected rock.
- **Corrupt Locale:** a follow-up moves floor items and mobile actors before
  placing solid temporary terrain. Per-cell cosmetic floor and wall colors
  still need a presentation field.
- **Seal Doors:** a follow-up compares source-style player tension before
  and after hypothetical closure and chooses the best player push square.
  Some source perception/status modifiers and habitat-specific push rules
  remain.
- **Porkalator:** Kirke now arrives with a source-sized hog band. Her death
  restores her band and spell-converted hogs across every retained level,
  frees hostile victims, and ends player Pig Form. The Go world keeps
  inactive floors loaded, so restoration is immediate rather than queued.
  Source restoration also copies a larger monster snapshot, including flags
  and enchantments; the port preserves each actor's current ECS effects and
  inventory while restoring its identity, speed, and proportional HP.
- **Malign Gateway:** severed heads now drift their saved anchor and keep
  reconnecting after their portal marker expires. The marker closes when a
  monster vacates its cell, releasing the one-gateway global limit. The
  connector pathfinder still approximates source constrained path selection;
  sanctuary restrictions await the religion domain.

These are behavioral follow-ups, not reasons to reintroduce missing-module
fallbacks. Each should extend its focused owner and gain a source-based
regression test when the necessary world data exists.

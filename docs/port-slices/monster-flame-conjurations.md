# Monster flame conjurations

Marshlight, Holy Flames, and Stoke Flames are live monster spellbook effects.
They use the same typed plans, saved Akara actors and clouds, and Lua combat
owners as the rest of the Go engine.

## Behavior

- Marshlight uses effective monster spell power to create two physical
  foxfires. Their saved owner determines allegiance, their source spell
  identifies the construct action, and their own turns move or hit an enemy.
  Player Foxfire still uses the same creation and contact policy.
- Holy Flames places a ring of holy clouds around its chosen foe. Each cell
  has its own saved duration and attribution. Existing clouds, solid terrain,
  and monster-occupied cells stay intact; Still Winds prevents the cast.
  An adjacent player cell can receive the holy cloud, as in the source.
- Stoke Flames creates one speed-14 creeping inferno with degree-two summon
  expiry. If it dies from damage, actor death invokes a Fire Storm power-100
  explosion, using the committed monster damage profile and lava resistance.
  The source Fire Storm cloud aftermath runs on affected floor cells.

The source sanctuary veto for Holy Flames waits for the religion slice. No
current game action creates sanctuary. Vortices from a natural inferno whose
caster is already gone also wait for the broader ambient-monster explosion
and attribution slice; the current Stoke Flames inferno uses its living
summoner as the owner.

Focused Lua tests cover actor ownership, hit damage, cloud exclusions, and
death explosion. Live spellbook tests cover cast, save/restore, continuing
RNG state, construct action, and actor-death ordering.

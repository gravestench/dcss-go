# Monster instant-area spell slice

## Purpose

Port the remaining monster spells that deal an immediate effect to multiple
cells or actors. Keep the source spell's target shape, damage formula,
resistance, collateral-damage decision, and secondary effects. This slice
builds on the existing Lua spellbook dispatcher, Akara actors, grid, and
named random streams. It does not add a monster-spell switch.

The spell files in this category are Call Down Damnation, Cleansing Flame,
Chain Lightning, Chain of Chaos, Eruption,
Fire Storm, Glaciate, Irradiate, Lee's Rapid Deconstruction, Ozocubu's
Refrigeration, Pyroclastic Surge, Seracfall, and Upheaval. Polar Vortex
and Olgreb's Toxic Radiance have continuing caster state and belong to a
later timed-area category. Call Down Lightning fires one lightning bolt
from the foe's cell and belongs to the direct-target category.

## Ownership

- `policy/combat/monster_area/actors.lua` owns only living actor discovery
  in LOS_NO_TRANS and explosion cells. It returns allies as well as enemies.
- Focused modules under `policy/combat/monster_area/` may own genuinely
  shared geometry or impact rules. They do not select a spell ID or encode
  a table of per-spell exceptions.
- Each `policy/combat/monster_spells/<spell>.lua` owns its plan, saved target
  shape, source formula, secondary effect, and messages. Its plan evaluates
  collateral damage before spending the monster action. Resolve rechecks
  position and occupancy without choosing a new foe.
- Durable effects such as spawned actors, clouds, or terrain changes use
  their existing ECS or level owners. A later pulse needs a saved component
  and system rather than a Lua module variable.
- Shared player spell behavior, where present, should move to an
  actor-neutral policy if that removes duplicated rules without changing
  the player command contract.

## Source rules to preserve

- Ozocubu's Refrigeration uses the `ZAP_REFRIGERATE` four-die cold formula
  at LOS_NO_TRANS range, reduces each target's die size according to its
  adjacent nonconjured actors, applies AC and cold resistance, and exposes
  cold-blooded survivors. It may hit the caster's allies. The monster AI
  weighs that collateral damage before casting.
- Cleansing Flame is a radius-two holy explosion centered on its caster,
  with two dice whose sides are `5 + floor(5 * spell_hd / 12)` in the
  monster cast. Holy resistance and the source's ally weighting matter.
- Irradiate selects surrounding cells, applies AC to its magic damage,
  and contaminates or mutates surviving victims. A damage-only copy would
  leave its main secondary effect absent.
- Call Down Damnation uses `ZAP_CALL_DOWN_DAMNATION`, a radius-one
  explosion and source monster dice `3d15`.
- Fire Storm has a radius of two or three, selected by the source spell
  power roll, and uses lava-flavoured damage. The fixed radius-one beam
  explosion helper must not silently reduce it.
- The other spells have distinct cell selection and impacts. Trace each
  from `mon-cast.cc` into its source helper and zap data before writing its
  handler. Do not approximate a cone, chained jump, wall fragmentation,
  or terrain-derived strike with a radius blast.

## Verification

Add `_test.lua` cases that import the production spell modules and IDs.
Exercise target-plan refusal, ally safety, obstructed geometry, a hit and
resistance or immunity, secondary effects, and saved state where a spell
creates any. Include a live spellbook cast through the Go game harness for
at least one representative of each target shape. Run the Lua suite after
the category is integrated, then the relevant game tests. Commit this
category once its full listed scope is implemented and verified.

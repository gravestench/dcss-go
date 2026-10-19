# Monster forest and plant spells

## Intent and boundary

Make the remaining forest and plant group in the committed monster
spellbooks executable: Awaken Forest, Awaken Vines, Wall of Brambles,
Grasping Roots, and Sporulate. This is one domain slice because
their casts create or command vegetation, restrain actors, or produce
plantlike creatures whose behavior continues after the cast. A resolver
that merely creates a visual effect does not complete the slice.

The existing spellbook dispatcher continues loading one named Lua effect
file per spell. The effects own cast eligibility, target plans, source
rolls, and messages. Focused Lua policies own vegetation, root restraint,
and spore behavior after a cast. Go remains the generic ECS, grid, RNG,
save, and rendering kernel. The player Summon Forest and Fastroot paths
share owners where the same state or invariant is involved; they must not
gain parallel monster-only implementations.

## Game behavior

- **Awaken Forest:** cast only when an enemy can be reached by a tree and
  no forest is already awake on that level. A saved caster condition makes
  visible trees strike unaligned nearby actors on later caster actions.
  Damage, hit/armour, messages, expiry, caster death, and level transitions
  follow the pinned DCSS forest rules. The tree cells remain terrain.
- **Awaken Vines:** select source-valid tree-adjacent cells that see the
  chosen foe, spread vines apart, and observe the caster's three-vine
  limit. Vines and any connecting segments are ECS actors with saved
  caster references and the source's constriction behavior. They disappear
  when the caster's vine condition ends, the caster dies, or line of sight
  to their awakener is lost.
- **Wall of Brambles:** preflight a useful wall, then create a defensive or
  escape-blocking arc of briar-patch ECS actors. Save each short lifetime.
  Patches block movement and trigger the source thorn interaction on
  contact; an impossible wall does not consume an action or random draws.
- **Grasping Roots:** apply the source duration and actual constriction to
  the selected foe. The existing root owner gains actor-neutral handling,
  including player and monster victims, escape, damage, expiry, and save.
- **Sporulate:** create a short-lived ballistomycete spore with source HD
  scaling and caster allegiance. Its movement, explosion, and cleanup are
  live behavior, not a dormant summoned actor.

## Ownership and persistence

Mutable caster conditions, vegetation actors, root restraints,
and spore state belong in Akara components. Dense terrain stays in the
level grid. Caster and victim handles survive the Go save format and are
validated at restore. Existing summon and temporary-terrain owners handle
their normal lifetimes; do not add a second expiry clock for the same
thing. Actor death and level deactivation release dependent vines and
forest effects through their owning Lua policies.

Each module has its own why/how comments, every function is commented,
and each system has a theory of operation. Import shared IDs from their
production modules. Keep lines at or below 120 columns and prefer 80.
No inline Lua appears in Go tests. Mods can replace one spell, condition,
or actor policy at its relative path without a central spell switch.

## Verification

Lua `_test.lua` files import the production IDs and schemas. They cover
read-only preflight, target commitment, caster allegiance, geometry,
source roll bounds/order, save-shaped component values, ongoing turns,
release on death or expiry, and player/monster victims. Live Go tests cast
the five spells from sparse spellbook overlays on their eligible maps,
save mid-effect, restore, and compare later actions and RNG state. Test
the shared player Fastroot and Summon Forest paths for regressions. Run
the full Lua suite once at the category boundary, the focused Go game
tests, build and style checks, then whole-category review before one
implementation commit and a fast-forward merge to local `main`.

# Reflected hostile projectiles in Lua

## Intent

Finish the live return effect of the amulet of reflection across every
blockable hostile ranged attack that the Go port currently resolves:
thrown stones, poisoned darts, sling bullets, and Slug Dart. A blocked
attack from any of these routes should return toward its shooter when
the player wears a reflector. The shield bonus already comes from the
item's Lua capability. This slice must not add an item-ID branch.

This is the complete reflection category for the current D:1-2 ranged
roster. Later beam, artefact, monster-reflector, and armour-ego domains
must enter through the same reflection policy when their attacks are
implemented. Do not claim those absent domains are playable here.

## Pinned source

Use DCSS revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
`actor.cc:276-283` defines the reflector gate.
`ranged-attack.cc:154-193` turns a successful shield block into a
reflection while retaining the projectile; `beam.cc:2995-3044` reverses
a beam toward its source. `beam.cc:4785-4830` shows that a shield block
without reflection stops the beam. `ranged-attack.cc:350-369` excludes
penetrating attacks unless an omnireflector is present.

## Ownership

`policy.combat.reflection` owns whether a target can reflect, the return
target's defense projection, return damage attribution, and common
messages. It reads the existing jewellery capability projection. The
incoming ranged route owns its attack numbers and on-hit payload. After
a block, that route resolves the *same* shot against the original
shooter using the shared return target projection. This keeps source
randomness in the relevant attack resolver and avoids a second combat
implementation or a central item/spell switch.

For current monsters, the return target is the shooter at the other end
of the already clear ray. A reflected shot can miss or hit. A returned
Slug Dart beam can also be blocked by the shooter. DCSS does not let a
shooter block its own returned thrown or launched missile
(`attack.cc:1256-1258`). Only a hit damages or applies poison or a
launcher brand. The player is the source of damage for kills,
experience, and downstream hooks. The original player block still
increments shield-block count and practices
Shields. Reflection consumes no extra player turn and never runs after
an ordinary miss or hit.

The current hostile missile effect modules keep their individual
`resolve` functions. The hostile action coordinator calls the same
resolver with the reflected target defense. Slug Dart calls its existing
resolver in the same way. New missile or spell effect files can join by
using that resolver contract; no Go code or ID registration table is
needed.

## Edge rules

- A worn reflector works without a physical shield. Its ten shield
  points can produce the block that triggers the return.
- A non-reflecting shield still blocks normally.
- The return uses current monster EV, AC, and status modifiers. Slug
  Dart also uses the monster's current shield.
- A blocked Slug Dart return ends the trajectory; it does not loop
  indefinitely.
- Poisoned darts apply poison to the monster only after a returned hit.
- Flaming, freezing, and vorpal sling launches apply their existing
  monster-hit effects after a returned hit.
- If the original shooter died or moved before the return, the return
  safely ends. Current actions resolve synchronously, but this makes
  the policy reusable for later beam paths.
- The port's current hostile missile roster contains no penetrating
  missile. The return policy exposes an explicit reflectable property
  so later penetrating attacks can opt out without an ID check.

## Verification

Lua `_test.lua` tests use production item definitions, equipment,
defense, ranged resolvers, and a shared deterministic RNG fixture. They
cover all current hostile projectile types, ordinary blocks, misses,
returned hits, poison and launcher brands, reflector removal, mod-added
reflectors using the named capability, and save/restore of the wearing
state. A focused Go save bridge test is acceptable only for persistence
that the Lua harness cannot invoke. One integrated test pass follows
the category before one commit and a local `main` fast-forward.

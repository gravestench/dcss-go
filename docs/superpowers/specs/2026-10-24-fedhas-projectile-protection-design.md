# Fedhas projectile protection design

## Intent

Complete the source Fedhas passive that lets the worshipper and aligned
allies fire through protected plants. The rule belongs in Lua and reads live
Akara allegiance, worship, and monster catalog traits. It must not depend on
the order in which files were loaded or on a monster's displayed name.

## Source behavior

The pinned source's `god_protects` checks the attacker's alignment with the
target, Fedhas's passive, and the target's plant holiness. Monster attackers
must have the friendly attitude; good-neutral is not enough. Its
`shoot_through_monster` path skips a protected plant entirely during a ray.
The same decision protects against eligible beam, explosion, and cloud
effects. Hostile plants are still valid targets, and penance suspends the
passive. Stationary status is irrelevant to this protection: that condition
belongs only to walking through plants.

## Design

One Lua policy answers whether a source actor's effect should pass through
a target plant. Player rays, allied monster beams, area contacts, and cloud
placement and exposure consult it at their existing resolution points.
Skipping a ray contact preserves the projectile's remaining path and does
not roll accuracy, damage, shield, or conduct against the plant. Area and
cloud effects leave the protected plant's HP and status alone. Area rays
choose their burst center after passing any protected plants. A harmful
cloud may still be placed on a protected plant that is already immune to
its kind. Cloud
exposure reads saved player-side attribution even if its source actor died;
placement reads its current source actor. A ray
originating from a player standing on a plant must not mistake the plant
underfoot for an intervening target.

The rule uses catalog holiness and the existing allegiance policy. It does
not grant protection to an unrelated monster, to a hostile plant, or to an
attacker who is not on the player's side. Existing plant pass-through
movement and saved shared-cell ordering remain unchanged.

## Verification

Lua tests cover the policy's allegiance, penance, and nonstationary cases.
Game integration fires a nonpenetrating projectile through an aligned plant
at a hostile target, then verifies that a hostile plant is contacted instead.
Beam and cloud tests exercise their real Lua resolution entry points.

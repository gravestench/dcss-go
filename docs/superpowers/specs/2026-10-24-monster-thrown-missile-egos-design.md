# Monster-thrown missile egos

## Intent

An equipped monster missile should resolve every ego the committed item
catalog can put on it. A Zot test currently stops before its travel and save
checks because a monster throws a dispersal missile and the decision policy
rejects that ego. The source game resolves the ego after projectile contact.
The Go engine should keep that order and use the existing Lua owners for
player health, conditions, movement, and explosions.

## Rules and boundaries

- A monster may throw catalog missiles with the ordinary, poisoned, curare,
  flame, frost, blinding, frenzy, dispersal, silver, chaos, or exploding ego where
  the item category permits it. Unknown saved egos fail validation before
  the monster spends a shot. A dart keeps its contact-only attack profile;
  its ego no longer has to be poisoned.
- Contact, shield, reflection, and base HP damage remain in the current
  ranged action. A landed ego acts afterward if the target survived, except
  an exploding missile, whose fragment blast is part of impact. A miss or
  block cannot inflict a direct-hit condition. Chaos chooses an ordinary ego
  per contact without changing the saved item.
- Direct flame and frost use the existing elemental brand owner. Poisoned
  missiles use the source chance and dose; curare poisons, deals its source
  asphyxiation dice, and slows a survivor. Blinding and frenzy use the
  source dart resistance chance before applying the player's condition.
  Dispersal needs positive contact damage and chooses the farther of two
  legal nearby cells. Player stasis or missing landing cells leave position
  unchanged. The exact random stream and condition owner are shared with
  equivalent Chaos missile results. Silver uses the source victim-dependent
  bonus damage and its ordinary minimum against other targets.
- An exploding missile creates a radius-one fragment blast at impact with
  source 2d5 damage. It can affect both the player and nearby actors, including
  the thrower. It does not also run an unrelated direct-hit ego. Its explosion
  is generated through the existing Lua explosion/grid services.
- Reflection reuses the same missile identity. On a returned hit, monster
  conditions and extra damage use existing monster-facing projectile effect
  owners; a reflected explosion uses the return impact as its center.
- Place effects in small, documented Lua modules with named functions. A
  shared dispatcher owns validation and ordering, not a long set of content
  cases. Consolidate the duplicate missile ego/brand constant lists to one
  imported source of IDs. No inline Lua in Go and no second Go behavior path.

## Verification

Production Lua rule tests cover each supported ego, misses, blocks,
reflection, resistance, stasis, and a radius-one explosion. A game test
walks the existing Zot route and restores a snapshot; it must not need a
test-only exception for an unsupported missile ego. Keep any occupied-stair
test setup separate from gameplay changes.

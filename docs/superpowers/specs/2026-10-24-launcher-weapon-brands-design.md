# Launcher weapon brands

## Intent

An equipped ranged weapon should use every brand that the pinned DCSS
source permits on launchers. Source-generated and authored launchers must
be playable rather than failing on an unimplemented brand. Player and
monster attacks should share the current Lua contact, resistance, status,
and equipment owners, with no Go gameplay branch.

## Approach

The source has one legality rule for weapon brands and one ranged attack
path that delegates active brands to ordinary weapon-brand behavior.
Use a launcher legality rule before a shot, then call the existing
monster-target or player-target weapon-brand owner after contact. Those
owners already implement the active brands, so new launcher-only adapters
would duplicate combat policy. Speed and Penetration remain in their
delay and projectile-path owners. Protection refreshes a saved, short
player aura through its shared monster-target brand owner. The current
engine uses virtual ordinary arrows and bolts; actual branded launcher
  ammunition needs a later physical-ammo ECS slice. That slice must implement
  source brand suppression using the actual ammunition ego.

## Source rules

- `makeitem.cc:is_weapon_brand_ok` permits Normal, Venom, Protection,
  Speed, Vorpal, Chaos, Holy Wrath, Electrocution, Flaming, Freezing,
  Penetration, and Acid on ranged weapons. Melee-only, removed, debug, and
  unknown brands fail validation before an attack spends a turn.
- When physical ammunition is added, `ranged-attack.cc:apply_damage_brand`
  suppresses Flaming, Freezing, Holy Wrath, Electrocution, Venom, and Chaos
  for a nonordinary missile ego. Vorpal and Acid remain active.
- Brand effects run after a hit. Holy Wrath hurts susceptible undead or
  demonic targets; Electrocution uses the source one-in-four 8–20 shock
  unless electric resistance prevents it; Venom uses its source poison
  chance and dose; Acid splashes and corrodes through the existing acid
  owner. Death and zero-damage gates remain brand-specific. Flaming,
  Freezing, Vorpal, and Chaos retain their current source rules.
- Speed changes launcher attack delay. Protection grants +7 AC for three
  or four turns after a qualifying player hit, adding time up to a five-turn
  cap; the duration ages with player actions and persists in saves.
  Penetration bypasses a shield and continues along the ray where the
  existing projectile path can represent another target.
- Reflection preserves the launcher brand. A returned hit attributes the
  brand to the reflector and uses the same monster-target owner as a player
  shot.

## Boundaries

All policy is in readable, individually commented Lua files under the
embedded mod directory. Use named IDs from the existing constants module.
Keep effect modules focused; no growing switch in the ranged action.
Tests live in `_test.lua` files and import production IDs and policy.
Use one contiguous category commit on `main` and push the fork.

## Verification

Lua rules cover every legal launcher brand, invalid IDs, player and monster
defenders, resistant targets, reflection, and
passive effects. A game test runs a branded launcher turn and verifies
save/restore. Build, style, and diff checks run once for the category.

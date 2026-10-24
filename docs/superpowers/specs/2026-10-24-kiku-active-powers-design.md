# Kikubaaqudgha Active Powers

## Purpose

Complete Kiku's ordinary active abilities as one gameplay slice. The existing
capstone, gifts, and Torment resistance already run through Lua. This slice
adds Unearth Wretches and Torment without creating Go-specific god rules.

## Ability contract

- Unearth Wretches unlocks at the first piety star, costs 3 MP and a generic
  4-point piety cost, and uses the source Invocations failure tuple 40/5/20.
- Torment unlocks at the fifth piety star, costs 4 MP and a generic 8-point
  piety cost, and uses the failure tuple 60/5/20.
- A failed invocation spends its turn but no MP or piety. Both powers disappear
  when Kiku is abandoned, under penance, or under silence.
- Torment uses the existing LOS_NO_TRANS radius-seven effect and the Kiku
  invocation source, including the existing partial shield for the invoker.

## Wretch lifecycle

Unearth Wretches chooses two or more locally appropriate, natural,
corpse-bearing monsters from the active branch population using Necromancy.
Each successful placement creates a real hostile actor near the player, with
one current HP, paralysis, no regeneration, no experience reward, and a
guaranteed corpse. The hostile side suppresses ally attack prompts; these
actors cannot move or attack. An actor that survives dies after 20–29 aut and
passes through the ordinary death and corpse phases. Failed placements do not
cancel successful invocation costs. The player sees the source no-space
message if none could be placed.

The `religion.kiku_wretch` ECS component owns the remaining lifetime; the
ordinary actor and position components own its body and location. This is not
a summoned monster: summoned actors disappear without corpses. Its field
persist in the Go save, and restore rejects impossible values or a wretch
without a real monster body. Local population selection reads the effective
mod catalog, so an added monster needs no handler entry.

## Verification

Lua tests pin availability, costs, formulas, corpse eligibility, placement,
expiry, no XP, and the Torment source. A Go game integration test verifies the
menu and save/restore behavior. Run focused Lua and Go tests, game build, and
changed-file style checks before one category commit and push to `main`.

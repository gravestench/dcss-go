# Sif Muna Active Powers

## Purpose

Complete Sif Muna's three ordinary active powers as one spell-domain slice.
The Go engine already stores known and library spells in ECS records and
dispatches spell effects from Lua. Sif's abilities should use those owners
without a second spell implementation.

## Source behavior

- Channel Magic unlocks at one star, costs a rolled two-point piety amount,
  and uses the Invocations failure tuple 60/4/25. A successful invocation
  grants a 4-plus-Invocations-based channel duration. Each ordinary player
  action restores 3–5 MP per ten aut, scaled and rounded for its actual delay.
- Forget Spell unlocks at three stars, costs a rolled eight-point piety
  amount, and lets the player select and confirm one memorized spell. A
  cancelled or invalid choice is free. It removes that spell's known slot
  through the existing spell-record owner while retaining library knowledge.
- Divine Exegesis unlocks at four stars, costs a rolled twelve-point piety
  amount, and lets the player choose an available library spell (including a
  spell already memorized) to cast once without learning it. The selected
  spell still pays its ordinary MP or HP cost, receives an Invocations power
  bonus, and uses its existing effect, targeting, and conduct. Library spells
  above the player's experience level remain selectable and castable. The ability's
  invocation failure replaces ordinary spell failure.
- God abandonment, penance, and silence hide or reject all three powers.
  Channel Magic ends on abandonment or penance. Successful costs apply once;
  a failed invocation consumes time and pays no piety.

## Ownership and interface

Lua ability modules own availability, costs, prompts, and effect selection.
The spell record and effect registries remain the only source of known spell
and spell behavior. Channel duration is a saved ECS player component aged by
an ordered Lua system. The generic ability command carries a selected
`spell_id` into its intent; Go adds no Sif-specific switch.

## Verification

Lua tests cover each power's live ownership, cost, failure, cancellation,
selection, and channel timer. Go game tests cover menu display, ability
commands, save/restore of channel state, and a Divine Exegesis cast through
the existing command bridge. Run focused tests, build, and style checks before
one category commit and push to `main`.

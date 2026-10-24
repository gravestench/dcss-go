# Trog Active Abilities Design

## Goal

Complete Trog's three active powers as one deity slice: Berserk,
Trog's Hand, and Brothers in Arms. Their rules live in separate Lua
files; Go continues to provide generic ECS, time, save, and terminal
services. The effective Lua catalog remains the modding interface.

## Approaches

- Add Trog cases to the generic ability command and status runner. This
  would couple the command owner to another god and make later god
  abilities harder to read.
- Register three focused Lua ability modules and one player-owned Hand
  status, reusing the existing rage and summon owners. This follows the
  Beogh and Lugonu pattern and is the chosen design.

## Source contract

The pinned `ability.cc` and `religion.cc` give Trog powers at piety
ranks one, two, and four. Berserk, Hand, and Brothers have generic
piety costs with bases one, two, and five; none spend MP or train
Invocations. Their failure values are `45 - piety / 2`,
`piety_breakpoint(2) - piety`, and
`piety_breakpoint(5) - piety`, clamped to zero. The ordinary divine
ability failure draw and cost commitment path is already available.

Berserk calls the shared player rage owner after its source eligibility
gate. It must reject undead, stasis, exhaustion, and other conditions
that prevent rage before committing the action. The god power does not
create a separate berserk state.

Trog's Hand increases a saved player timer by
`5 + roll_dice(2, floor((piety / 2) / 3) + 1)` turns, capped at 100
turns. A live Hand grants two willpower pips and 100 units of HP
regeneration, including when ordinary regeneration is inhibited.
It ends on timeout or departure from Trog. Its start, fading, and end
messages follow the source duration owner.

Brothers in Arms uses the source piety jitter to select a power band.
Bears, ogres, trolls, and giants are chosen at the source thresholds of
100, 140, and 180, with their source weights. One ordinary friendly
summon appears near the player with Trog as its saved source. It enters
berserk immediately, and its summon timeout follows the extended
berserk lifetime. Failed placement still spends the successful ability.
Temporary Trog gifts disappear when Trog is abandoned or his penance
begins.

## Ownership and save

`policy/abilities/trog/{berserk,hand,brothers}.lua` register the three
abilities. A `religion.trog_hand` Lua ECS component owns the Hand timer;
one small system decrements it before regeneration. The existing
player resistance and regeneration owners read that component. The
existing `magic.summon` and monster allegiance components own the
Brothers actor and its berserk timer. Restore validates the Hand timer
and god-sourced summon through current schema and save rules. No new
Trog fields enter Go structs.

The Trog behavior module handles Hand and temporary-gift cleanup on
departure. A shared religion transition hook handles the same cleanup
when penance starts, without introducing a Trog case in the command
runner. These paths inspect real ECS source IDs, not display names.

## Verification

Production-schema Lua tests cover rank and penance gates, each failure
formula, cost commitment, no MP use, rage eligibility and shared rage
state, Hand refresh and expiry, regeneration through inhibition, will
bonus, all four summon tiers, source weights and allegiance, blocked
placement, timeout, and departure cleanup. One Game save test resumes
Hand and a Brother after restore. Terminal ability-menu coverage checks
the three names and rank gates. Run focused tests, build, and style
checks once for this category; commit and push one complete slice.

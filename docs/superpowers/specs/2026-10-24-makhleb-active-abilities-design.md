# Makhleb Active Abilities Design

## Intent

Port all four active Makhleb powers together. A player who joins Makhleb
can aim Minor and Major Destruction and call Lesser and Greater Servants.
The Lua rules retain source cost, failure, beam, and demon behavior while
Go continues to own generic ECS, time, saves, and terminal input.

## Approaches

1. Add Makhleb branches to the generic ability and monster command paths.
   This would make those shared owners grow with every patron.
2. Register four focused Lua abilities with one Makhleb roster and one
   destruction selector. Reuse existing beam, summoning, equipment, and
   god cost owners. This is the chosen approach because each source rule
   stays close to the power it serves and modders can replace one file.
3. Build a generic god-power DSL now. The source powers differ enough in
   targeting, failure, and cost timing that such a language would hide
   their behavior before more patrons reveal stable common operations.

## Source behavior

The pinned `religion.cc` unlocks Minor Destruction at two stars, Lesser
Servant at three, Major Destruction at four, and Greater Servant at five.
`ability.cc` supplies fixed HP costs of one, four, six, and ten. Minor
consumes no piety; Lesser draws two or three, Major draws zero or one,
and Greater draws five through eight. The abilities consume no MP. The
existing generic divine failure roll combines Invocations and piety
with each source tuple. Both aimed powers ask for a direction before
spending time. The source draws the failure roll before the aimed power
rolls its power or traces the shot. An unsafe trace can then cancel the
action freely before applying that already-rolled failure.

Minor Destruction chooses Throw Flame, Pain, Stone Arrow, Shock, or acid
breathed at one seventh of the rolled power, at range five clamped to
the player's current vision. Major chooses
Bolt of Fire, Lightning Bolt, Bolt of Magma, Bolt of Draining, or
Corrosive Bolt at current sight range. Power is one or two scaled
Invocations skill units, respectively, plus two separate random draws
bounded by that skill. A tracer protects allies before applying the
failure result or choosing a random effect. The selected zap uses the
ordinary projectile, resistance, and damage owners. Source-accurate
player zap profiles are needed for Breathe Acid, Pain, Bolt of Magma,
and Bolt of Draining; Spit Acid is not a replacement for Breathe Acid.

The servant powers choose uniformly from their separate five-demon
rosters. Each draws a source summon duration degree from two through
six based on `20 + Invocations * 3`. On an invocation failure the chosen
demon appears hostile instead of the power simply fizzling. That result
still spends the HP and piety costs, as the source's hostile ability
flag makes the action successful. Blocked placement still consumes the
successful invocation. A summoned demon carries Makhleb's god source,
owner, attitude, finite expiry, and ordinary generated equipment through
save and restore. Source hostility is chosen before placement and does
not change because the player later changes worship. Both servant
abilities disappear when allies are forbidden. Their degree-two-through-
six abjuration duration uses the existing summon owner's time mapping;
the plan must verify the source clock against that mapping.

## Ownership

Four modules under `policy/abilities/makhleb/` register the powers.
Shared Makhleb Lua data files hold the two demon rosters and the two
destruction choices; each caller imports them by stable ID. The existing
wrath policy imports the rosters rather than keeping duplicate lists.
Generic ability preparation owns HP affordability, targeting, ally-safe
beam tracing, and free refusal.
The common god cost owner rolls and commits costs, extended only where
it lacks fixed HP and source zero-or-one piety. The existing zap and
summon owners carry effects and ECS state. Save validation recognizes
friendly and hostile finite Makhleb summons and their legal roster.
There is no Makhleb Go command switch or parallel actor state.

## Verification

Production-schema Lua tests cover all four ranks, penance, fixed HP
costs, piety costs, failure rolls, aim and tracer refusals, source zap
choice and power, each demon roster, hostility on failure, blocked
placement, and finite expiry. Game tests command all four powers and
restore the two servant attitudes and source. Terminal tests verify
names, rank gates, targeting, and time-free cancellation. Run the
affected ability, beam, and summon groups, the Go build, and style
checks together after the slice. Commit this category once and push
`origin/main`.

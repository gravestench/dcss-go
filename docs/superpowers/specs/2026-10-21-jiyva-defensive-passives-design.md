# Jiyva Defensive Passives Design

## Purpose

Complete Jiyva's three defensive rank passives as one source-traced domain
slice. A current worshipper in good standing ignores adjacent slimy-wall
damage from zero stars, gains HP and MP regeneration from one star, and
resists acid damage and equipment corrosion from two stars. Renunciation
and penance turn these effects off immediately; save/restore reads the
existing worship state rather than copying a second rank flag.

## Source behavior

The pinned `god-passive.cc` grants slime-wall immunity at rank zero, jelly
regeneration at rank one, and corrosion resistance at rank two. `player.cc`
adds `80 + floor(80 * (rank - 1) / 5)` HP regeneration units and
`25 + floor(25 * (rank - 1) / 5)` MP regeneration units. The HP god bonus
survives a natural-regeneration block such as sickness or inhibited
regeneration, but Death's Door still prevents healing in this engine.
The `resist_corrosion` passive contributes one level of player acid
resistance, which also gives the existing corrosion rule its one-in-two
protection check.

The source calls `slime_wall_damage` after cloud exposure on each actor
action. An adjacent eight-neighbor `DNGN_SLIMY_WALL` contributes to the
hazard, but the actor cannot occupy that wall. Players take four dice whose
sides are stochastically rounded from `3 * wall_count * elapsed_aut / 10`;
monsters take two four-sided dice. Jiyva's rank-zero player passive, full
acid immunity, and slime-genus monsters are immune. Source DCSS only hurts
a monster when its cell is visible to the player through no-transparency
line of sight; the damage dice still roll before that check. A visible
monster's burn or melt message names the wall and target. The ordinary acid
resistance and actor-health owners apply the resulting damage. A map's
committed slimy-wall terrain already exists; no new vault format is needed.

## Ownership and flow

`policy/religion/jiyva/defenses.lua` reads the authoritative worship
component and piety rank. Regeneration and player resistance call its
focused queries. `policy/world/slime_walls.lua` owns adjacency, immunity,
and acid-damage calculation for either actor type. One Lua system invokes
that policy at the actor's existing action timing, after cloud exposure
and before status recovery or monster decision. Neither policy stores
mutable module-level game state. The existing regeneration and corrosion
components remain the only saved progress.

## Verification and mod behavior

Lua tests exercise each threshold, penance, abandonment, natural-regen
block, acid and corrosion outcomes, wall count, and actor immunity. A Go
test places a valid slimy-wall cell on a production level, takes real
scheduled actions, and round-trips the resulting worship, terrain, and HP
through the production save path. A modded monster with slime genus or
full acid resistance uses the same policy. No Go switch names Jiyva or a
monster subtype.

## Boundary

Jiyva's mutation gifts, five-star retaliation, active abilities, and wrath
are separate connected categories. This slice implements all three
defensive rank passives, including the terrain damage that makes rank-zero
immunity observable.

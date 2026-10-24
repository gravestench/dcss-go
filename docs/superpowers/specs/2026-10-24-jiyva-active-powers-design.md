# Jiyva Active Powers

## Purpose

Finish Jiyva's two active powers using the Lua owners already present for
slimy walls, temporary terrain, polymorph, and slime allegiance. Both powers
must appear in the normal ability menu and use the source rank, MP, piety,
and invocation failure rules. Their transient state must survive save and
restore and end on abandonment or penance.

## Oozemancy

At rank two, three MP and a rolled eight-point piety cost, Oozemancy turns
eligible visible walls within Chebyshev radius four into temporary slimy
walls. The source rejects activation when already running or when no wall
can change; those rejections are free. An invocation failure
spends one action but no resources. Duration is ten plus a two-roll average
of piety divided by eight, measured in turns, and capped when extended.
Use the existing temporary terrain marker for each cell, with the original
feature and expiry saved. The existing slimy-wall exposure owner handles
acid damage and Jiyva immunity. Penance, departure, and leaving the level
clear only the markers created by this power.

## Slimify

At rank four, five MP and a rolled ten-point piety cost, Slimify grants a
saved player timer. The next eligible non-cleaving successful melee hit
consumes it and replaces ordinary damage with a Jiyva-aligned slime body.
The source excludes insubstantial actors, tentacle segments, other slimes,
and non-natural or non-undead targets. Form selection uses current monster
HD with a small religion-stream perturbation; water constrains the form.
The existing fixed-form polymorph transition retains entity identity,
rebuilds its body, and handles equipment. Jiyva's saved allegiance marker
then makes the creature good neutral. Ineligible or missed hits retain the
timer. Duration ages by actual player aut and ends on penance or departure.

## Verification

Production Lua tests use registered schemas and the same policies as play.
Game tests verify rank gates, free rejection, successful costs, wall
placement and restoration, saved timers, an actual melee conversion, and
save/restore. Terminal menu tests verify both powers are visible. Complete
the category in one commit on `main`, then push it.

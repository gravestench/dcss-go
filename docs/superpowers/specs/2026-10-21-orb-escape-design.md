# Orb pickup, escape, and victory

## Purpose

Finish the ordinary Dungeon Crawl win path using the live Orb item placed by
the Zot:5 Hall. A player with three runes can enter Zot, take the Orb, survive
the return trip, and leave through a D:1 stair to win. Leaving without the Orb
ends the run as a loss after confirmation. This slice must work across saves
and sparse Lua mod layers, not just in a test scenario.

## Source behavior and ownership

The pinned DCSS source's `items.cc:_get_orb` consumes the floor Orb, announces
the pickup, creates loud Orb noise, and starts `CHAPTER_ESCAPING`. The Orb is
not an ordinary inventory stack. `player.cc:player_has_orb` derives possession
from that chapter. `main.cc` requires three runes for a first Zot entry and
asks before leaving the Dungeon without the Orb. `stairs.cc` ends the run as a
win with the Orb or a loss without it. `timed-effects.cc` checks for wandering
monsters every 50 aut, and `mon-place.cc` raises their spawn chance and
substitutes Orb-run defenders after pickup.

Lua owns these rules. A saved `character.endgame` component on the player owns
the phase: `exploring`, `escaping`, `won`, or `left`. The floor Orb entity is
destroyed on pickup; no duplicate carried item is created. Only an authentic
`OBJ_ORBS` item whose ID is `ORB_ZOT` can start the run. The phase survives
save/restore and is validated against the Hall's item state. The Go kernel
exposes a generic terminal outcome to the view and stops advancing a finished
run. It does not choose Orb rules or monster IDs.

## Travel and outcome

The D:1 exit is a distinct terminal stair destination in level and save data;
it is not a fake unavailable link and does not point to a nonexistent level.
An up command on it asks for confirmation if the player lacks the Orb, then
spends an ordinary stair action. With the Orb it needs no confirmation. The
Lua stair system marks `won` or `left`, emits the source escape message, and
does not move the actor to level zero. The terminal client shows distinct win
and loss screens and can return to startup. Subsequent commands cannot
advance either finished run. Saves from a ruleset before this slice retain
their old ruleset hash and follow the engine's explicit mismatch policy; this
slice does not silently rewrite them.

Zot entry checks the saved rune set on the first visit, using the source
threshold of three. A refused entry is free and does not generate Zot:1 or
consume gameplay randomness. Once Zot:1 has been visited, the entrance
remains usable even if rune progress changes through a mod.

## Orb-run pressure

After pickup, each crossed 50-aut boundary performs the source wandering
check. Normal Orb-run rate is 18, giving a `5/rate` chance at each check;
the source slow-orb-run passive uses rate 36 when implemented. No check runs
in the Abyss. A successful check picks a defender through source-weighted
categories: rare Pan lord/unique/seraph/Boris, Orb Guardian, greater demon,
common demon, or Pandemonium branch monster. The source's category weights
and draw order live in Lua, using named monster IDs and the committed Pan
population catalog. The spawn is a permanent hostile actor placed close to
the player on a legal open cell, through the existing Lua monster factory.
The current turn's aut boundary, position, and spawned actor state all survive
a save without a parallel Go monster path.

## Modding and verification

The component, command policy, stair system, spawn policy, and display policy
are separate Lua modules with documented contracts. Sparse mods can override
them by relative path. The modding guide explains the run phase, exit marker,
and how to change spawn policy without editing Go.

Tests drive the real generated Dungeon and Hall item where practical, and
cover pickup, refusing Zot without runes, confirmation, win, loss, save
continuation, stopped terminal turns, and spawn timing and monster selection.
The exact source spawn probabilities are tested as rules, while seeded runs
verify the integrated actor materialization path.

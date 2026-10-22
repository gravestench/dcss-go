# Jiyva Heavy-Hit Slimes Design

## Goal

Port the five-star `spawn_slimes_on_hit` passive as one Lua-owned reaction.
A large, nonlethal hit whose source is an actual monster ejects ordinary
friendly ECS summons. Penance and renunciation disable the effect through
the current saved worship state, without a second passive flag.

## Source behavior

Pinned `ouch.cc:_maybe_spawn_monsters` runs after positive damage has
reduced HP but left the player alive. It requires a monster damager.
`royal_jelly_ejectable_monster` chooses one of acid blob, azure jelly,
rockslime, and quicksilver ooze before testing the damage threshold. One
species is shared by the whole ejection. A hit of at least one-quarter of
maximum HP creates one body; at least one-half requests two or three; at
least three-quarters requests two to five. The source uses integer division
for those thresholds, sets a two-degree summon owned by the player, gives
the living damager as a foe, and prints a blow or blast message only when
at least one summon is actually placed.

## Runtime ownership

The existing player-health owner supplies final HP loss, cause, and attacker
to its sorted reaction registry. `policy/religion/jiyva/retaliation.lua`
registers between deterioration and demonic guardian. It reads Jiyva's
five-star entitlement, rolls on the saved religion stream, and calls the
common summon owner. `magic.summon` stores owner, source, attitude, and
expiry; the existing `magic.summon_haunting` target guides ejected slimes
toward a surviving damager. No Go code names Jiyva or its species.

The generic summon owner accepts a caller-selected stream and silent
placement failure. These are generic controls used by source-driven
passives, not a separate Jiyva summon implementation.

## Verification and limits

Production-schema Lua tests run through `player_health.damage`, not a
replacement summon function. They cover all damage tiers, species choice,
saved ECS metadata, allegiance, foe targeting, rank, penance, departure,
missing attacker, and lethal hits. Existing summon save validation owns
serialization of the same ECS components. Its accepted origins explicitly
include the four Jiyva bodies, their player ownership, and their living
damager target. Beam damage retains Curl eligibility; direct smiting does
not. Xom's butterfly branch in the same C++ helper is a separate god
category.

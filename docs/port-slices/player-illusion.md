# Player illusion

Mara's Summon Illusion creates one player-shaped monster from a visible
player foe. The spell refuses a second living illusion with that player's
name. It also copies a visible enemy monster beside that monster, with one
live copy per source monster. A monster copy neither swaps places with nor
releases restraints from the original. Both branches have a six-degree
lifetime and take ordinary Akara AI and combat turns.

The `magic.player_illusion` component snapshots the player's untransformed
maximum HP, XL, name, species, job, AC, EV, melee damage, weapon brand,
Necromancy skill for Pain,
resistances, sight, and executable ghost spells. The snapshot is independent
of later player equipment changes. Combat reads its saved attack, defense,
and elemental profile instead of the static `MONS_PLAYER_ILLUSION` catalog
placeholder. Haste, Might, invisibility, confusion, paralysis, Berserk, and
Slow are copied when their player duration is active. Save validation checks the
profile and rejects a duplicate named illusion.

Known spells that have an executable monster Lua effect pass the source
ghost selection roll at creation and receive the source `XL + 50` total
frequency. Other spell effects remain for their gameplay domains; they do
not enter a live AI book until their Lua resolver exists. The current player
poison record tracks future damage rather than the source duration, so poison
is not yet copied to this monster status. These two gaps are tracked for the
remaining spell and status domains of the full port.

The saved ghost weapon brand now applies against both player and monster
defenders. The monster-target effect files are shared by the player,
ordinary monsters, summons, and player illusions.

A live Mara cast and save/restore test checks the game boundary. Lua rule
tests check cast gating for both target kinds, actual monster-target melee,
profile combat reads, custom spellbook reads, snapshot capture, and forged
profile rejection.

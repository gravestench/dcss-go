# Monster gaze spell family

## Goal

Port all four gaze IDs in the committed monster books: Confusion Gaze,
Paralysis Gaze, Draining Gaze, and Weakening Gaze. The source is the pinned
`crawl-ref` revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`,
especially `mon-cast.cc`'s gaze logic and `player.cc`/`monster.cc` status
rules. The four effects are separate auto-discovered Lua files and one
focused direct-gaze policy. Go continues to host only ECS and grid services.

## Runtime contract

All four effects require the caster to see its selected foe within the
spell's range. Sight includes target invisibility, the caster's blindness
and see-invisible trait, and backlighting. They use an entity plan, never a
projectile path or a beam
hit roll. Resolution validates the saved target handle before applying
the current status. An intervening actor cannot intercept a gaze.

Confusion Gaze tests willpower using eight times the caster's spell HD,
then checks clarity and extends confusion by five to seven turns. Paralysis Gaze bypasses
willpower and applies two to four turns, subject to existing paralysis and
stasis rules. Draining Gaze uses twelve times spell HD as the source's
`BEAM_DRAIN_MAGIC` enchantment power: it drains player MP or applies
monster antimagic, healing a Ghost Moth only from actual drain. Weakening
Gaze uses the caster's current ordinary HD and adds the source duration
to the player's weakness timer or the monster's weak enchantment. Player
weakness reduces raw melee damage to three quarters while active, including
auxiliary attacks. Monster weakness reduces raw melee damage to two thirds
before player or monster armour. Player revival clears Weak with other
temporary statuses.

All lasting status is stored on the affected ECS entity and ages by aut.
No effect records state in a module local or duplicates a component schema
inside tests. A mod can replace any one effect or its policy by path.

## Verification

Lua tests import production effects, schemas, and status owners. They cover
all four plan/resolve paths, interposed actors, blocked sight, source RNG
bounds, immunity and repeat behavior, and status damage/expiry. A real
spellbook overlay exercises at least one gaze through monster decision,
cast, and save/restore. Verify the family boundary with affected tests,
build, vet, style, review, then one category commit and local main merge.

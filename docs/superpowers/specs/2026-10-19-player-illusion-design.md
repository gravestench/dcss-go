# Player illusion design

## Purpose

Complete Mara's Summon Illusion as a source-shaped opponent, rather than
spawning the static `MONS_PLAYER_ILLUSION` catalog row. The spell must copy
the player's relevant combat identity at cast time, preserve that identity
in Akara state, and keep using it after the player changes equipment or the
game is restored. The work belongs entirely to the Lua rules layer except
for existing generic ECS, grid, and save services.

## Source behavior

The pinned `mon-clone.cc` lets a monster cast on a visible foe. A player may
have one illusion with the same name at a time. The illusion is summoned near
the caster for degree six, is hostile or friendly with the caster, and carries
a player-ghost profile built from the untransformed player. That profile
captures real maximum HP (capped at 400), AC, EV (capped at 60), XL, melee
damage (capped at 50), weapon brand, species, job, name, elemental and special
resistances, sight, and a filtered subset of memorized spells. Only internal
player durations are transferred to monster statuses. The first attack is
the ghost-profile `AT_HIT`, not the static row's five damage.

A monster foe takes the other source branch: the spell copies its current
body beside the original, gives that body the caster's allegiance and a
degree-six lifetime, and records the original entity so no second live copy
can be made from it. Unlike Phantom Mirror, this cast neither swaps cells
nor untangles the original. Conjured bodies, tentacles, and illusions cannot
seed another copy.

The pinned `ghost.cc` chooses known spells with probability based on raw
failure and translates two player-only IDs. It filters `no_ghost` spells and
spells that cannot be monster spells, then distributes `XL + 50` frequency
equally among the selected slots. The cast planner requires direct sight to
the foe; a player illusion already present prevents another cast.

During the incomplete port, only a spell with an executable monster Lua
effect enters the live AI book. New effect files become eligible through the
same selection rule as those later spell domains land. The current player
poison ECS record stores future damage rather than the C++ duration, so a
source-equivalent poison transfer requires that status-domain work.

## Ownership and integration

- A `magic.player_illusion` component owns the saved combat snapshot. The
  existing `core.actor`, `core.health`, `magic.summon`, and `magic.summon_stats`
  own kind, HP, lifetime, and HD. The profile does not point back to mutable
  player state.
- `policy/combat/monster_summons/player_illusion.lua` captures the player
  snapshot and creates the actor through the existing summon owner. Its
  helper policies own ghost melee, resistance, and spell selection rules.
- The existing mirror owner copies monster foes with the source spell's
  different duration and side effects. Its source-entity marker enforces
  the one-copy rule across save/restore.
- Combat and spellbook readers use the saved profile for this one monster
  kind while all ordinary monsters continue to use their catalog profile.
  A Lua mod can replace the profile builder or spell effect by file path.
- Save validation rejects a profile on a non-illusion, an illusion without a
  profile, invalid bounds, duplicate active illusions of the same player,
  malformed spell slots, and a forged summon source.

## Verification

Lua tests cover visibility, duplicate prevention, snapshot independence,
player-derived HP/AC/EV/damage/brand, status conversion, spell selection,
combat use of the profile, and forged save rejection. A live Mara cast and
save/restore test covers the engine boundary. Run category-level Lua/game
tests, build, style, and diff checks before one commit, then merge and push
`main`.

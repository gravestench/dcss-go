# Monster ally-support spells

## Purpose and boundary

Port the four source monster spells Haste Other, Might Other, Invisibility
Other, and Heal Other as a complete target-and-effect family. They occur in
committed books but currently fail the live effect-coverage gate. The pinned
DCSS source is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, chiefly
`mon-cast.cc`'s `_get_allied_target`, `_monster_will_buff`,
`_flavour_benefits_monster`, and `beam.cc`'s beneficial beam effects.
Summons, player-targeted support, and unrelated allied abilities are separate
families.

The port remains Lua-first: four discoverable spell modules call one focused
target policy and the existing actor-owned boon, enchant, and healing owners.
Go continues to provide ECS, terrain, RNG, turn scheduling, save, and UI
services. No monster ID or spell ID dispatch switch is added to Go.

## Source target selection

A caster considers nearby live monsters in no-transparency line of sight.
The player and caster are never candidates. A target must be aligned with
the caster, genuinely allied rather than merely charmed into agreement,
and not source "firewood" (harmless stationary no-threat monster, except
tentacles and the three diagnostic test monsters). A recipient that was
already friendly remains eligible while charmed; the source compares its
real allegiance with the caster's temporary allegiance. Ironbound Convoker,
Amaemon, and Bound Soul can help any genuine
ally. Holy monsters help other holy monsters. Naga-genus casters may help
snake-genus allies. Otherwise caster and target share a monster genus; use
the committed `genus_id` metadata. Existing runtime actor data lacks a
separate base-monster genus for transformed monsters, so that case will be
added with the transformation domain rather than guessed from a display ID.

For Haste, Might, and Invisibility, a target with that enchantment already
active does not benefit. Heal Other considers any missing HP, unlike the
self-heal AI's half-HP threshold. Selection scans stable ECS entity order,
chooses the nearest eligible target strictly closer than the current best,
and rejects a candidate when a wall or earlier actor would intercept its
single-target beneficial beam. A tie retains the first eligible ECS entity.
The spell catalog's `LOS_RADIUS` range supplies the distance cap. Planning
must not mutate state or draw effect RNG; a missing target produces no cast
intent. A selected target crosses the scheduler as an entity plan.

## Effects and persistence

Haste Other and Might Other apply the same saved boon timers and speed/melee
consumers as the self spells. Invisibility Other writes the existing monster
enchant owner, with the same visibility and expiry rules. Heal Other heals
`3 + 2d(caster spell HD / 2)` through the target's existing health owner,
clamped at maximum HP. Beneficial status duration is derived from the
recipient's speed, as source `add_ench` does. Resolution uses the chosen
entity and never silently substitutes the caster, player, or a nearer
monster. It rechecks live target, level, and ray before changing state.

The shared owners remain authoritative across turns, dispel, death,
travel, and save/restore. A ruleset overlay can replace one spell module
without copying the full mod. Messages name the actual affected monster.
Lua files explain why each eligibility and effect rule exists, import shared
IDs where used, keep functions commented, and stay at or below 120 columns.

## Verification

Lua tests import production catalog IDs and policies. They cover each
module's plan and resolve, nearest/tie selection, permanent versus temporary
allegiance, genus and special allied groups, occupied rays, walls, already
active buffs, any-HP-loss healing, source heal roll, effect consumers, and
missing-target no-op behavior. Game integration tests exercise a real
book caster, its selected entity intent, save/restore and next-turn RNG,
and a sparse one-file effect override. Run the full Lua rule suite, targeted
game tests, build, vet, style, and diff checks at the category boundary.
The existing exhaustive `go test ./...` suite has a 10-minute timeout in
an unrelated corpse test; report its result accurately if attempted.

Make one contiguous implementation commit and fast-forward local Go `main`
after review and verification, following the user's standing integration
choice. The port goal remains active after this family lands.

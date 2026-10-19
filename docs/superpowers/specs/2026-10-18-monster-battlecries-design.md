# Monster battlecries design

## Goal and boundary

Port the complete three-spell battlecry family in the committed monster books:
Battlecry, Warning Cry, and Hunting Call. The pinned DCSS rules are
`mon-cast.cc:_battle_cry`, the warning-cry cast and eligibility cases, and
the `spl-data.h` noise declarations at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. Each spell gets its own
auto-discovered Lua effect. No Go spell switch or build-time C++ importer is
added.

## Shared owner

`policy/combat/monster_battlecries.lua` finds recipients and applies a
source cry. Planning is read only and returns the caster entity as a typed
intent target only when there is a visible, valid foe, sound is possible,
and a qualifying ally can benefit. Resolution finds current recipients,
rolls source durations on the saved monster-spell stream, writes Might or
Swift through the existing `combat.monster_boons` component owner, wakes
affected sleepers, emits the visible announcement, and propagates noise
through `policy.world.noise`. Warning Cry has no boon; it is a 25-loudness
alert usable by any non-friendly caster and needs its own `plan` and `resolve`.

Battlecry and Hunting Call target same-genus, aligned, living allies in
no-trans LOS within seven cells. The caster cannot receive its own boon.
The engine exposes `ctx:visible_no_trans` for this geometry: clear walls
block it, while actors between the caster and target do not. This differs
from physical `ctx:projectile_clear`.

Visible announcements name only recipients the player can see, while an
offscreen group still makes noise. An unseen Warning Cry does not name its
caster in the player's message.
Confused, berserk, paralyzed, and petrified recipients cannot benefit.
Sleeping recipients may benefit and wake when the cry disturbs them.
Might already active rejects a Battlecry recipient; Swift or Haste already
active rejects a Hunting Call recipient. A valid visible foe is required.
A silent caster cannot produce either cry. The source duration is
`random_range(12, 20) * speed_to_duration(recipient.speed)`, with stochastic
rounding from `100 / speed` and all draws on `monster_spell`.

## Ownership and verification

The existing boon timer ages the new status on the actor. The existing noise
policy owns hearing and awareness. Cry modules own only their selection,
announcement, and source parameters. They use the same `plan/resolve`
contract as other monster spells and keep all lasting state in ECS.

Lua tests import the actual effects and boon/noise policies. They cover a
qualifying group, different genus, opposite allegiance, ineligible status,
already-buffed ally, blocked sight, silence, duration, warning sound, and
stable typed target. A Go game test forces one real cry in an overlay,
checks saved ally state, and checks save/restore continuation. At the family
boundary run the full Lua suite, affected game tests, build, vet, style,
and diff checks. Document the pattern in the modding guide.

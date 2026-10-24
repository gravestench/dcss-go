# Monster contact holds in Crawl

This slice ports Dungeon Crawl's `AF_CRUSH` and `AF_ENGULF` as Lua contact
rules. Both work after a landed melee contact even when the physical strike
deals no damage. Crush has no initial physical damage; its injury runs in the
constrictor's post-action status phase, including the grab action. Engulf has a two in three application chance and
starts a saved water or ooze hold.

## Ownership

The existing `core.constricted` ECS component now belongs to **any direct
grip victim**, player or monster. It records the constrictor, escape attempts,
and elapsed hold time. The current constrictor's attack profile supplies
damage. This avoids copying catalog damage into saves and releases a grip when
polymorph removes its constricting body. Player-origin direct grips keep their
existing `combat.player_constriction` owner because they also account for
equipment and mutation-based tentacle capacity.

The existing Lua `combat.water_hold` component likewise belongs to the
victim, whichever side it is on. It stores its holder, elapsed time, and
hit-time substance. The hold releases when either participant dies or leaves
adjacency. The existing player mutation and the new monster Engulf contact
use the same status, ticking, silence, and save validation owner.

## Contact and turns

Crush uses the shared normal melee hit roll. A hit starts a grip only when the
attacker sees an adjacent, smaller or equal, constrictible body and has
capacity. Ordinary monsters hold one victim; octopodes can hold eight.
Repeated hits do not reset escape progress. Constriction damage increases
with saved duration, then applies armour and attacker speed. The player's
existing escape contest stays in place; monster victims use the source
monster-against-monster contest.

Engulf rolls its chance before body eligibility, as source melee does. A
successful hold silences breathing victims, prevents player spellcasting and
scroll reading, and applies drowning on the victim's own actions. Water
exposure extinguishes sticky flame on every landed monster Engulf contact,
even when its hold chance fails. A swimmer
or unbreathing player remains held but does not accumulate future drowning
damage. A monster's hold advances duration and damage with separate speed
rounding draws, as the source does.

## Verification

Production Lua rule tests exercise both victim types, zero physical damage,
immunity, duration ticks, and separation. Game tests cover save/restore of a
monster's direct grip and a player's water hold, then advance player time to
check drowning. Existing ball python and player mutation tests protect the
earlier behavior.

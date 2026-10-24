# Monster equipment resistance

## Intent

Monsters should receive the resistance of the gear they actually wear.
This matters for ordinary monster equipment, vault placed items, and mods:
changing an item or removing it must immediately change the monster's
defenses without editing the monster catalog.

## Source behavior and current gap

The pinned source implements `monster::res_fire`, `res_cold`, `res_elec`,
`res_poison`, `res_acid`, and `res_negative_energy` from intrinsic levels
plus permitted equipment. Body armour and shields contribute their
intrinsic flags and egos. Jewellery, wielded elemental staves, and
artefact properties can also
contribute. Source poison resistance differs: a positive intrinsic level
returns early, while gear raises a nonimmune monster to at most one pip.
Wielding the staff of Olgreb gives full poison immunity before temporary
poison vulnerability is considered.
Nonliving monsters retain full negative energy immunity. Fire vulnerability
applies after equipment; source caps fire and cold at three in either
direction and negative energy at three. Steam resistance derives from the
live fire value and worn steam dragon scales.
The source checks steam dragon armour directly, outside the usual
item-use gate. Cigotuvi's Embrace likewise gives miasma immunity from
the worn body item, without a numeric artefact property.
Corrosion protection is boolean for monsters: a ring, acid dragon scales,
Preservation ego, or artefact can raise it to one unless intrinsic acid
resistance is already higher.

The port already applies some of these rules to monster negative energy
drain, but ordinary elemental damage uses catalog levels alone. Poison
also uses intrinsic levels alone. Several spells bypass the live actor
path by calling a definition-only damage helper.

## Design

Add a focused Lua `policy.combat.monster_resistance` owner. Callers pass the
monster's projected profile. The owner reads an `equipment.worn` snapshot
and computes each supported resistance using source order and caps.
Item definitions remain catalog data. The owner's only mutable inputs
are ECS equipment, artefact state, and timed statuses. Body and shield
armour, jewellery,
weapon staves, and artefact properties use existing IDs and policies.
The owner can answer a direct `(ctx, monster, definition, resistance_id)`
query so all combat consumers share the same result.

Route elemental damage, poison application, negative energy drain, and
actor-based cold spells through the owner. Keep the pure damage scaling
arithmetic free; remove definition-only calls where an actor is known.
Existing source special cases such as status projections and nonliving
immunity must survive. Never manufacture ordinary equipment resistance
on monsters whose item-use level forbids gear. Preserve the source's
direct worn-item exceptions. Keep the implementation in readable Lua,
with no inline Lua in Go.

## Verification

Equip real ECS items on gear-capable and gear-incapable monsters. Exercise
each element through its gameplay consumer, including removal, artefacts,
staff, jewellery, poison's one-pip cap, status order, and negative energy
immunity. Check the migrated cold spell paths. Run the focused Lua suite,
Go build, formatting, and diff checks, then commit this one category on
`main` and push.

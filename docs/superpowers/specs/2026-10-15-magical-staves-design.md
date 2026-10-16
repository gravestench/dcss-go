# Magical staves: complete item category

## Intent

Make all seven active DCSS magical staves usable as ordinary wielded items,
with source-backed melee, spell enhancement, resistance, save, and terminal
behavior. Keep the rules in embedded Lua and make an added staff primarily a
new content file, rather than another branch in a central handler.

## Source and data

The pinned source is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
`item-prop.cc:593` gives every magical staff the base staff weapon profile:
5 damage, +5 hit, 12 aut, Staves skill, and medium one-handed fit.
`item-prop.cc:1835-1858` maps each staff to its magic skill.
`melee-attack.cc:2015-2155` supplies the on-hit proc formula and damage
flavours. `player.cc:1276-1708` supplies resistances and spell enhancers.

Each staff content definition gets a `staff` record with its school, magic
skill, damage flavour, AC rule, and message. The common base weapon profile
comes from the existing `WPN_STAFF` definition; no duplicate weapon numbers
go into the seven records. The generic staff policy computes the proc and
applies that record. A mod can add a staff by adding a definition file with
the same record and using the shared policy.
The committed `staff-rules.json` import artifact lets the intentional catalog
exporter reproduce the seven bundled Lua records. A malformed modded staff
fails validation when the effective content catalog loads.

## Behavior

Wield and unwield use the existing weapon command and cost. Staves use Staves
skill for base attack and delay. On a successful contact, a staff may deal
extra damage based on its school skill and Evocations; No Artifice suppresses
the proc. Fire, cold, air, poison, and death use matching resistance; earth
uses triple AC after its 4/3 multiplier; conjuration uses normal AC.
The staff's school enhances spells while the item is wielded and usable by
the current form. Existing player resistance policy supplies fire, cold,
air, poison, and death resistance from the staff's own metadata. The terminal
wield picker and inventory screen include the staff class. Saves preserve
the item and equipped slot through the existing ECS equipment components.

## Verification

Lua `_test.lua` cases use production definitions and policy modules to cover
all seven records, wield selection, equipped save validation, proc arithmetic,
resistance/AC routes, and school matches. The existing engine save tests cover
serialization of the shared ECS item and equipment components. Run focused
tests, then the broader suite and style checks once for the whole category.

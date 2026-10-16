# Jewellery passive and attuned effects from worn Lua items

## Intent

The 24 active rings and amulets already have equipment commands. Their
passive and attuned effects should come from their Lua item definitions
and apply only while the item is effectively worn. A mod can add an item
with an existing capability in one file. A new kind of behavior can add
its own focused Lua policy without an item-ID branch in the engine.

This is one category for passive projections and attunement. Projectile
reflection and faith's religion events are separate complete event slices.
The existing Go code continues to own only generic ECS storage, command
transport, and save serialization.

## Source and current gaps

Pin behavior to DCSS `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
`artefact.cc:346-379` gives the common property mapping for rings;
`player.cc:910-930,1100-1220,1260-1755,1911-2000,2120-2205,3050,
3440,3920,5980-6000,6370-6390,7020-7040` and
`player-equip.cc:1000-1290` define the live consumers and attunement.
`religion.cc:768-800,2395-2405` covers faith.

The current Go port reads ring IDs directly in elemental resistance,
poison resistance, willpower, negative-energy drain, and spirit shield.
Other ring and amulet effects are absent. These direct checks become
capability reads in this category.

## Definition contract

The existing `jewellery` record gains an `effects` map whose keys are
named capability constants and whose values are numbers or the named
`item_plus` magnitude. The map is declared in the same Lua file as the
item. Its generated form is checked in; the source importer reproduces
it only when deliberately refreshed. Source references stay in comments.

A Lua policy projects effects from `core.item`, `core.carried_by`, and
`core.equipped` through `policy.inventory.jewellery.worn`. It returns a
sum by capability or a boolean for event gates. It does not save a second
copy of passive bonuses. It rejects unknown capability keys and invalid
magnitudes when the catalog loads. Source item IDs belong in their own
definitions, not in the consumers.

## Active effect matrix

| Items | Live result |
| --- | --- |
| Protection, evasion, slaying | Add the item's signed plus to AC, EV, or slaying. |
| Strength, intelligence, dexterity | Add the item's signed plus to the named attribute. |
| Protection from fire/cold, poison resistance | Add one pip to the named resistance. |
| Resist corrosion, life protection | Add one pip to acid or negative-energy resistance. |
| Willpower | Add 40 willpower. |
| Fire, ice | Add one fire/cold pip and subtract one opposing pip. |
| See invisible, flight | Enable the existing perception or permanent-flight projection. |
| Magical power | Add nine maximum MP, with current MP adjusted by the existing resource transition. |
| Wizardry | Add one source wizardry unit to spell-failure calculation. |
| Acrobat | Add 15 EV after move or wait for the source action window; do not grant it while caught or constricted. |
| Mana regeneration | Add 40 MP regeneration rate while attuned. |
| Regeneration | Add 80 HP regeneration rate while attuned. |
| Guardian spirit | Share incoming damage with MP through the existing spirit-shield policy. |
| Reflection | Add ten internal shield points. The projectile return event belongs to the ranged-combat slice. |
| Faith | Declare its named capability. Piety gains and removal consequences belong to the religion slice. |

## Attunement and event behavior

Amulets of regeneration and mana regeneration activate immediately when
their corresponding resource is full at equip time. Otherwise they
activate when that resource next becomes full. Their active state is
saved on the item or player through a Lua ECS component, with semantic
restore validation. Removing an amulet clears the state. The attunement
policy owns the transition; regeneration policy only reads it.

Acrobat's action window is saved or derived from the turn action state,
so inspecting the player after a move or wait shows the same EV as combat
would use before the next action. Reflection and faith get source-traced
event policies when their ranged combat and religion domains are ported.

The current Go port has starting religion state but no piety event policy.
Faith is explicitly inventoried as pending, including source-specific
removal penalties. The current ranged combat port resolves blocked shots
without returning a projectile, so reflection's return event is likewise
inventoried as pending. Neither is represented as working gameplay here.

## Verification

Lua `_test.lua` coverage checks each of the 24 active definitions against
the source matrix, including signed plus values and Octopode rings. Tests
exercise equip/unequip, saved attunement, acrobat action windows, and
guardian-spirit damage sharing through production policies. Mod-added
jewellery with an existing capability must affect the same consumers
without changing a central item-ID table. One broad repository test run
follows the complete category, not each file edit.

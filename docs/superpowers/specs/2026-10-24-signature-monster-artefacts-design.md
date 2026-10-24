# Signature monster artefacts design

## Intent

The source always gives Cerebov, Dispater, and Asmodeus their named weapons,
and always gives the Enchantress and Tiamat their named armour. These items
must be real carried ECS items with the existing unique artefact component.
They must be available as loot after death, retain their identity through
save and restore, and claim the same run history as other unrand artefacts.

## Ownership and approach

Each monster owns one readable Lua gear handler under
`policy/population/gear/handlers`. The handler names a catalogued artefact
ID. A shared gear helper derives its base item from that artefact. The
factory uses the existing explicit item generation path to create the item
on the monster, then marks the appropriate weapon or body slot. Authored DES
equipment continues to override ordinary monster gear.

The Enchantress and Tiamat still roll their catalogued weapons before adding
their guaranteed armour. Tiamat's Dragonskin is a cloak; source monster
equipment treats a draconian cloak as its body-armour inventory item. Combat
and save validation use the same monster armour rule.

The artefact catalog's `generation.mode = "none"` excludes these items from
random selection. An explicit request naming the artefact is still legal.
The unique item history and existing duplicate fallback remain the owners
of a repeated request. No Go monster-specific dispatch is added.

## Boundaries

This slice covers the five source-guaranteed unrand items. Chance-based
unique gear, Cerebov's later disarm exception, Geryon's non-artefact horn,
and other monster gear rules remain in their own categories. Source gear
generation happens only for an actual placement; a rejected unique or
occupied cell must not claim an item.

## Verification

Lua tests spawn all five monsters through the production factory, inspect
their carried item and slot, check unique history and death drops, verify
explicit `none` mode generation, and check a rejected placement leaves
history alone. The two armour bosses must also keep their ordinary weapons.
A focused Go integration test saves and restores a named
artefact generated onto a live monster through the same item path.

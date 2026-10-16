# Jewellery equipment: complete put-on and remove intents

## Intent

Make every active ring and amulet usable through DCSS's `P` and `R`
commands. The existing 24 active jewellery definitions become equippable
without item-specific command branches. Jewellery effects remain a separate
whole category, so equipment can be completed and verified against the same
saved ECS relations that later effects will read.

## Source and ownership

The pinned source is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
`item-prop-enum.h:200-266` identifies active rings and amulets;
`item-use.cc:1637-2460` defines selection, slot choice, swapping, and fast
put-on timing. `player-equip.cc` supplies species and mutation constraints.

Lua owns command preparation, slot policy, messages, and validation. The Go
command bridge only carries generic item IDs and stable command kinds. The
existing `core.item`, `core.carried_by`, and `core.equipped` components own
the saved state. Ring slots use stable names `ring_left`, `ring_right`, and
`ring_1` through `ring_8` for Octopodes; amulets use `amulet`.

Every generated active jewellery definition gets metadata saying whether it
is a ring or amulet. The catalog exporter reproduces those fields from a
committed import artifact on deliberate upstream refresh. Removed historical
records remain browseable content but cannot be generated or equipped.

## Behavior

`P` presents unbound jewellery and `R` presents worn jewellery. A free ring
slot is chosen deterministically; if all are full, the player chooses a
ring to replace. That swap removes the old ring in one half-turn, then puts
on the new ring in a saved second half-turn. Amulets replace the current
amulet through the source's delayed equipment flow. The same command path
works for a mod-added ring or amulet with valid metadata. Invalid inventory
ownership, duplicate slots, impossible species slots, and mismatched item
kinds fail before a command mutates state or a save loads.

Six source ring types carry an enchantment value. Their `pluses` metadata
permits that saved value and gives a mod-added enchanted ring the same
identification path. Other jewellery rejects unsupported plus values.

The equipment domain exposes one query for effective worn jewellery. Later
effect modules consume that query instead of repeating item IDs in combat,
spell, and status policies. The terminal inventory marks occupied slots.

## Verification

Lua `_test.lua` cases exercise all 24 active records, both command intents,
full-slot replacement, species constraints, save validation, and terminal
selection. Existing engine tests exercise the generic ECS save and command
bridge. Run the broader suite once at the category boundary.

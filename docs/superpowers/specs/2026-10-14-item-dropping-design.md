# Item dropping for the playable Dungeon slice

## Purpose

Add DCSS's `d` command to the existing Human/Fighter game. A player can
select a carried item by its displayed inventory letter, optionally enter
a quantity, drop it at the current tile, and pick it up again. This grows
the inventory domain without changing the committed item catalog or save
schema.

## Source rules and slice boundary

The pinned source binds `d` to `CMD_DROP` in `cmd-keys.h:44`.
`items.cc:2501-2608` clamps an excessive requested quantity to the stack,
refuses equipped armour and jewellery when `easy_unequip` is off, unwields
an equipped weapon before dropping its whole stack, puts the dropped item
on the current floor, and spends a turn only on success. This slice covers
the carried items available in the Go scenario: weapons, armour, shields,
and potions. It adds whole-stack and partial-stack drops. The Go client
accepts an optional decimal quantity followed by an inventory letter;
zero or cancellation spends no time. The requested quantity is clamped to
the available stack, as in the source.

The existing UI has no armour removal command, so equipped body armour and
shield drop attempts explain that they must be removed first. A carried
weapon can be dropped and becomes unwielded; the existing unarmed attack
path then applies. Picking it up again leaves it carried and unequipped.
Matching stacks merge only when their combined quantity fits in an `int`,
following the overflow guard in `items.cc:1577-1584`. Inscription warnings,
`easy_unequip`, delays, terrain
splash sounds, floor item limits, and `D` repeat-drop remain future work.

## Ownership and turn flow

The terminal owns the `d` selection screen and numeric prefix, using the
same inventory order and letters as inventory and quaff. `Game` checks
ownership, quantity, and equip rules before committing time. The player
places an `IntentDrop` on its Akara entity; an ordered item system records
the intended drop and event. After `World.Update`, `Game` applies the
structural component changes at the existing command barrier: full drops
remove `CarriedBy`, partial drops create a new `Item` entity, and both
place `Position` on the current floor. Compatible floor stacks merge.
`Equipped` is removed when a weapon is fully dropped. No package-global
gameplay state is added.

## Verification

Tests cover full and partial drops, an excessive quantity, refusal of
equipped armour/shield, weapon unwield and unarmed follow-up, floor stack
merging, no-time invalid requests, terminal selection, and save/restore
continuation, including an unequipped weapon carried after pickup. A
successful drop spends 10 aut, lets scheduled monsters act,
and survives the current Go save format. The source-backed item catalog
is unchanged.

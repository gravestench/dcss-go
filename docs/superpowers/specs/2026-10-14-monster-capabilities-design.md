# Monster capability dispatch in Lua

## Purpose

The current D:1–2 monster roster already has melee, equipment, ranged
weapons, and two spell effects, but several Lua modules choose behavior by
monster ID. That creates a new branch for each imported monster and makes
the combat path harder to extend. This category replaces those branches in
one pass. The pinned reference is DCSS
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Boundary

Go continues to own Akara storage, actor scheduling, grid queries, RNG
streams, and save encoding. Lua owns the capability decision and effect.
There is one monster ranged intent resolver and one monster spell intent
resolver. Neither contains a switch over monster IDs. There is no parallel
old resolver or compatibility adapter.

The current playable roster and its source behavior remain the scope of
this category. Imported monsters with unsupported abilities must still be
excluded from generation. This change creates a stable Lua path for adding
them later; it does not claim that all imported monsters are playable.

## Ranged capability

An equipped launcher whose catalog definition has ranged ammunition offers
a launcher action. An equipped missile stack offers a throw action. Selection
uses the existing action odds: launcher 4/5 and missile 1/3, with no adjacent
or blocked shot. The primary weapon takes priority over an alternate-slot
launcher. A monster with a launcher does not attempt a throw when its launcher
roll declines; an alternate launcher moves into the primary slot before firing.
The action carries the item entity. Resolution reads that same item and its
catalog definition; it does not infer behavior from actor identity. The
supported current effects are physical sling bullets, stones, and poisoned
darts, including shield/armour rolls, weapon brands, poison, messages, and
the source's nonconsuming ordinary monster ammo behavior in `throw.cc:950–970`.
Unsupported item/brand combinations fail explicitly.

## Spell capability

A monster spellbook supplies candidate spells and frequencies. The effect
module for a spell decides whether it can target the player, then resolves
the intent. Freeze requires adjacency and bypasses AC/EV. Slug Dart requires
a clear projectile path and uses its shield/EV/AC rolls. Each is a real Lua
file under `policy/combat/monster_spells`. The current one-slot spellbooks
keep their established frequency roll order. Unsupported books or effects
are not silently treated as a different spell.

## Verification

Existing endoplasm, dart slug, goblin sling, and kobold throw integration
tests must retain their deterministic outcomes. Add a behavior test that
equipping a supported ranged item on another Akara monster uses the same
Lua action path, without a new ID handler. Run the full suite, vet, build,
style, catalog check, and whole-branch review once for this category.

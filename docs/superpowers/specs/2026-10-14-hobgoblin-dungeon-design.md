# Hobgoblins in generated Dungeon

Source: pinned `mon-data.h:999-1010`, `mon-pick-data.h:69-71`,
`mon-gear.cc:231-279,987-1037,1710-2168`, and
`mon-util.cc:2345-2535` at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Purpose

The generated D:1–2 population currently excludes hobgoblins even though
their source row has the same high early weight as goblins and kobolds. Their
declarative weapon table and source gear switches have no hobgoblin entry,
so they enter play unarmed with their cataloged natural hit.

## Design

The immutable profile verifies one HD, average HP 5.5, live HP range 3–8,
speed 10, a plain five-damage hit, no spellbook, and source item-use identity.
Akara actor, health, AI, position, energy, and combat components stay in the
existing monster factory. Generated D:1–2 adds the hobgoblin ID to its allowed
source population; the fixed fixture remains unchanged.

The source XP formula adds 30 difficulty points for a monster capable of using
equipment, even when that monster starts without an item. The pure XP input
records this fact and uses the same source integer order and stepdowns. The
same check applies on kills, save restore, and the maximum-XP save bound.

Source item pickup and equipment use during AI turns are outside this slice.
The current Go floor item and monster inventory path is ready for those rules
when they are ported.

## Verification

Tests cover the source profile and XP rule, live generated spawning, and a
save restore round trip. Full Go tests, vet, build, and style checks run once
at the category boundary.

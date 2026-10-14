# Monster inventory lifecycle

Source: pinned `mon-death.cc:2597-2604`, `monster.cc:1166-1260`, and
`mon-gear.cc:1302-1332` at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

## Purpose

Monster equipment must be an actual Akara item entity, carried and equipped
by its monster. The item needs one identity through a save, a kill, a floor
drop, and a later player pickup. The existing item components already express
those relationships; the current save validator and death barrier assume that
only the player carries items.

## Design

The save validator checks monster item links after reading all entity records,
so item order does not matter. This first lifecycle category accepts exactly
one equipped weapon for each live monster, backed by a committed weapon kind.
Player equipment rules and slot conflicts remain player-specific. The restore
loader reconstructs the validated carrier link rather than assigning player
ownership.

The death barrier releases each carried item onto the dying monster's cell
before destroying the actor. It removes carrier and equipment components and
retains the item's entity ID and properties. A corpse, if rolled, is a separate
item entity. Player pickup then uses the existing floor-item path.

This category establishes ownership and persistence. Source weapon selection,
item quality, combat use, and the first live weapon-carrying monster are the
next contiguous category; this one does not claim they are playable yet.

## Verification

Tests save and restore a monster-equipped weapon, reject an invalid holder,
kill the carrier through player combat, and check the original item entity on
the floor and in a later save. Run the Go test, vet, build, and style gates
once after the category is integrated.

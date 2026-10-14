# Jackal Bands in Early Dungeon

## Goal

Admit jackals to the committed D:1–2 population picker as complete packs.
Keep the five existing ordinary animals and the fixed test fixture stable.

## Source behavior

- `mon-data.h:1091–1101` defines a 1-HD, speed-14 jackal with a plain
  3-damage bite, 55 tenths average HP, and ordinary corpse behavior.
- `mon-place.cc:1779,2107` gives a jackal leader one to three jackal
  followers. The `random_var(1,4)` upper bound is exclusive
  (`random-var.cc:18–23,88–105`). A population choice consumes one placement
  attempt, then creates a pack of two to four actors.
- `mon-place.cc:865–913` searches near the leader with offsets in [-3,3]
  and requires an unoccupied, habitable cell in the leader's solid LOS.
  A follower placement may fail without discarding the leader.
- `mon-movetarget.cc:743–806,891–952` remembers the leader and favors a
  wander target within the six-cell herd comfort range. Player pursuit
  overrides this wandering preference.

## Ownership

- The committed monster and population catalogs stay immutable. Jackal
  profile validation gates the shared plain-bite factory and combat rules.
- The level builder chooses the leader from its source-weighted pool and
  delegates pack creation to the monster factory. Actor, health, position,
  AI, and follower-to-leader link are Akara components.
- The AI system reads the follower link only while choosing a wander
  target. If the leader is dead or on another floor, the follower wanders
  independently.
- `Level` records both its population choice count and the actual number
  of initial actors. The latter is saved so restore can validate live
  counts and earned XP after band members die. Older version-8 saves
  without this field use the former count, because they predate bands.

## Verification

Seeded D:1–2 generated play must show two to four jackals per jackal
population choice, save and restore the follower links and initial actor
counts, award each killed jackal source XP, and preserve deterministic
continuation. The fixture's three original animals remain unchanged.

## Deferred behavior

Source bark propagation, displacement between band members, full energy
rules, and unrelated monster bands remain future domains. These are
tracked in `docs/port-inventory.md` rather than hidden behind a generic
compatibility layer.

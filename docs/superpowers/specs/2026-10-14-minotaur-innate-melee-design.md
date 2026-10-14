# Minotaur Fighter innate melee

## Goal

Make Minotaur Fighter playable through the current Dungeon slice. Its innate
horns cause source-shaped headbutt auxiliary attacks, and reflexive headbutt
can retaliate after a monster misses. Character creation, growth, equipment
fit, terminal presentation, save, and restore must use the selected Minotaur
identity. Keep Human, Hill Orc, and Deep Elf behavior intact.

## Source and rules

The pinned source is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

- `species-data.h:578-593` grants `MUT_HORNS` level 2 and
  `MUT_REFLEXIVE_HEADBUTT` level 1 at XL1. Minotaur has 12/5/5 base stats,
  HP +1, MP -1, XP -1, and a Strength or Dexterity gain every fourth XL.
- `melee-attack.cc:965-971,1135-1325,3465-3499` gives a headbutt base
  damage of `5 + 3 * horns`, an XL-scaled 67% trigger, an auxiliary accuracy
  roll, and ordinary stat, Fighting, might, and target AC steps. It follows
  the primary attack if the adjacent target survives, even if the primary
  missed.
- `melee-attack.cc:303-356,3211-3280` triggers Minotaur retaliation only
  after an eligible first monster attack misses or is dodged. Chance is
  `23 + XL` percent. It uses headbutt damage without an accuracy contest,
  and a kill is attributed to the player.
- `mutation.cc:1523-1540` prevents a hard helmet with horns, while a soft
  hat fits. `item-prop.cc:1082-1085` identifies a hard helmet by kind.

## Ownership

Innate horns and reflexive headbutt are immutable species definitions in
the committed catalog. The player identity component selects them; no
second copy is stored in ECS. If later gameplay changes mutation levels,
that mutable state belongs in a player mutation component. The combat system
reads the current player and defender components and calls pure combat rules
for rolls and damage. It applies results to ECS health and emits messages.

The existing player progression and selected-species save validation cover
Minotaur XP, attributes, HP, MP, and skill aptitudes. Equipment fit checks
use the selected species for wearing and restoring headgear. No C++ import
runs during normal builds or play.

## Verification

Test the source start profile and terminal path; deterministic auxiliary and
retaliation rolls including no-trigger, miss, zero damage, and kill; helmet
refusal and soft hat; Minotaur save/restore, including mutation-derived
behavior after load. Verify the full Go suite, vet, build, style gate, and
diff before a single category commit.

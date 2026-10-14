# Dungeon bat and ordinary natural melee

## Goal

Make the source's D:1 bat a real population choice in the current generated
Dungeon. It must have its committed monster stats, ordinary hit attack, high
speed, short retreat after attacks, XP and corpse behavior, and saveable AI.
Use this slice to replace bite-only runtime names with one ordinary natural
melee path. The seven existing animals must retain their behavior.

## Source

Pinned DCSS revision: `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

- `mon-pick-data.h:56-72` gives the bat a flat weight of 1000 on D:1-3.
- `mon-data.h:355-366` gives it HD 1, average HP 3.5, AC 1, EV 14,
  speed 30, a plain one-damage `AT_HIT`, a corpse, no spellbook or item use,
  and `M_BATTY` flight.
- `mon-act.cc:563-571,1890-1903,2228-2242` sends a bat wandering after
  any melee attempt. Its speed 30 yields two subsequent bat actions before
  it seeks the foe again because the attack action itself counts as the first turn. The bat keeps acting through the normal scheduler.
- `attack.cc` and `melee-attack.cc` resolve `AT_HIT` with the same ordinary
  hit, shield, and damage phases as the currently ported plain bites.

## Ownership and behavior

The committed monster catalog owns immutable attacks, speed, flags, HP, and
population weight. Akara owns each bat's actor, health, position, energy,
and AI. The AI component gains a small retreat-action counter because that
value changes on each bat turn and must survive saves. Other monsters keep
the counter at zero. The combat system resolves an ordinary first natural
attack, records the bat's retreat after its attack, and emits a type-correct
verb. The AI system spends the retreat actions wandering and then resumes
seeking. Existing source-shaped HP, XP, corpse, regeneration, catch-up,
population, and save flows accept bat through one source-validated profile.

The current map is floor and wall terrain, so flying crosses no special
tiles in this slice. D:1 features requiring other capabilities (constriction,
monster equipment, spells, or ranged attacks) remain separate categories.

## Verification

Test bat catalog/profile values, D:1 population eligibility and spawning,
ordinary `AT_HIT` accuracy/damage, the correct message, retreat on hit or
miss and its two-action transition, save/restore during retreat, HP/XP and
corpse eligibility, and rejection of impossible saved bat counters. Verify
the full Go suite, vet, build, style gate, and diff before one commit.

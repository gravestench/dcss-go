# Monster mirror clones

Rakshasa's Phantom Mirror now copies one nearby, aligned, ordinary monster.
Its AI checks that an eligible ally is visible; resolution chooses among
the currently eligible allies. Stationary, conjured, unique, summoned, and
enemy actors are excluded. Mara's fake summoning makes up to two copies of
itself at half current and maximum HP. A marked mirror copy cannot repeat
either spell.

The shared Lua mirror owner creates an ordinary Akara summon beside the
source, copies its live speed, base hit dice, HP, bodily timers including
monster poison and active boons,
and independently owned items, then may swap source and copy positions.
Placement failure leaves no partial actor or duplicated gear. A successful
copy frees the original from direct constriction and trapping nets. The
copy's own action energy starts at the normal summon value rather than
reusing a caster's pending turn energy.

The saved `magic.summon_mirror` marker records the source kind and life
scale. Restore validates it against the summon source and derived HD, even
when the original has since died or the copy has been polymorphed. The
existing chaos duplication effect preserves a mirrored summon's marker and
uses the same inventory copier, so its duplicate items are independently
owned too.

`SPELL_SUMMON_ILLUSION` is next in this family: a player target needs a
source-shaped, saved player-ghost combat profile rather than the catalogue's
static `MONS_PLAYER_ILLUSION` defaults. This category does not place Mara
or Rakshasa into the current D:1–2 ambient population.

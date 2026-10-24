# Ru Active Powers Design

## Intent

Complete Ru's three active powers as one playable Lua domain slice. A Ru
worshipper should gain Draw Out Power, Power Leap, and Apocalypse at the
source piety ranks, see their real costs and restrictions, and retain their
effects through save and restore. This follows the already playable sacrifice
offers without placing god-specific dispatch in Go.

The source baseline is the pinned DCSS tree's `ability.cc`, `god-abil.cc`,
and `religion.cc`. The Go engine already has a Lua ability registry, player
damage and movement owners, monster damage, status timers, and Akara-backed
components. The new rules should reuse those owners.

## Approaches

1. **Selected: three focused Lua abilities with shared exhaustion state.**
   Each power owns its preparation and effect. A small character-status owner
   stores exhaustion in an ECS component; the existing ability command path
   supplies the timed intent. This matches the repository's extension model.
2. Put Ru's effects in one large god handler. This would be shorter at first,
   but adding or changing one power would require reading all three and would
   recreate the handler growth the project is trying to avoid.
3. Add a Go ability switch. This would duplicate the Lua registry and prevent
   sparse mods from replacing the power's policy.

## Source behavior and boundaries

- Ru grants Draw Out Power at three stars, Power Leap at four, and Apocalypse
  at five. Live worship, penance, silence, and rank gates are checked before
  an ability appears or resolves. The source definitions have no failure
  chance or piety cost. Draw Out Power costs no MP; Leap costs five MP;
  Apocalypse costs eight MP.
- All three are unavailable while exhausted. A committed Draw Out Power adds
  12–16 turns, Leap 18–25, and Apocalypse 30–49. The timer is saved in an
  ECS component and ages in elapsed aut. Ru exhaustion also blocks a new
  Berserk start, while a Berserk cooldown blocks Ru's powers, because the
  source uses the shared exhausted duration.
- Draw Out Power may be used while confused. It is unavailable when HP and MP
  are full and none of the source ailments it clears are present. It frees
  nets/webs and constriction, ends confusion, Slow, and Petrifying, restores
  HP and MP using the source piety rolls, and applies temporary maximum-HP
  drain with power 30. It then starts exhaustion. Status removal goes through
  the existing status owners so inventory and trap state cannot diverge.
- Power Leap is a targeted range-three action. An invalid or canceled target
  is free. It rejects Fungus-form nervousness and fear/mesmerism movement
  restrictions, occupied or unsafe
  destinations, and cells not visible without a transparent wall. After a
  paid action, a failed constriction escape still consumes the ability.
  Successful movement lands on the selected cell, makes a two-point noise,
  applies barbs movement damage, and rolls source-scaled energy damage
  against adjacent nonfriendly,
  non-projectile monsters. A successful committed use spends five MP and
  starts exhaustion.
- Apocalypse targets visible nonfriendly, non-projectile monsters in line of
  sight. With no targets it asks for confirmation before spending time. Each
  target receives the source damage roll and a source-weighted antimagic,
  paralysis, or Slow effect when eligible. Damage-only outcomes remain
  possible. It applies temporary maximum-HP drain with power 100, spends
  eight MP, and starts exhaustion. Monster effects use their existing saved
  status owners or focused new Lua component schemas where one is missing.
- Source RNG ordering is documented and tested for each power. The UI uses
  the ordinary ability list, target prompt, and confirmation paths. No Lua
  source is placed in Go strings.

## Completion evidence

Production `_test.lua` files exercise rank/penance gates, confusion and
exhaustion, canceled and blocked targets, the paid constriction case, exact
resource costs and rolls, monster status and damage, timer expiry, and a
save/restore continuation. Focused Go game and terminal tests show the
commands are available through the real client. Build, relevant tests, and
the repo style check run at the category boundary. One category commit is
pushed to Go `main` after verification.

Ru's attack interference and damage retaliation form a later combat-reaction
slice. Those passives do not own any of the three active commands.

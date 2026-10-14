# Player haste design

## Intent and scope

Port the potion of haste for the playable Human/Fighter Dungeon run. A carried
haste potion can be quaffed through the existing menu, speeds later accepted
actions, appears as `Fast` in the DCSS-style HUD, decays on player actions,
and survives a save/restore continuation. Put mutable duration on the Akara
player. Keep potion definitions in the committed item catalog and timing rules
in `character` and `combat`.

## Pinned source rules

- `potion.cc:197-224` grants `40 + random2(40)` nominal turns.
- `player.cc:4586-4613` first applies `haste_div`, using randomized rounding
  of two thirds, then adds the result in aut, capped at 40 turns. It says
  `You feel yourself speed up.` for a new effect and
  `You feel as though your hastened speed will last longer.` on refresh.
- `player.cc:1855-1875`, `defines.h:190-191`, and `random.cc:313-321` make a
  normal 10-aut action cost 6 or 7 aut while hasted. The speed is chosen at
  input preparation, before the action applies any new potion effect.
- `player-act.cc:329-335` scales melee delay by that same action speed.
- `item-use.cc:1009-1015,1094-1095` truncates integer division for short
  wield actions: unwield costs three tenths of the chosen speed, while
  wielding costs half. Neither action draws another speed roll.
- `player.cc:4616-4642` decays haste by spent aut, warns when crossing 60
  aut, and removes it with `You feel yourself slow down.` when it starts an
  action with at most 10 aut remaining. A longer action may subtract past
  zero; the Go timer normalizes that transient negative value to 1 aut so it
  remains active for the same final action and stays valid in the save.
- `status.cc:884-907` calls the status light `Fast`.

## Ownership and action flow

`ecs.Durations.HasteAut` owns the live timer; no global or UI-owned haste
state. `quaffSystem` changes the timer and spends one item. `durationSystem`
decays it at the end of the same player action, after the potion effect.
`Game.Step` validates a command first, then chooses one player action speed
for that accepted command. Ordinary actions use it directly; melee delay
uses that same value inside the combat distribution. Scheduling, status decay,
and reported `Spent` all use the resulting aut. Monster deadlines remain
unchanged.

The port's deterministic RNG streams use `potion` for the potion's two
randomized values, `speed` for action speed, and `melee` for attack delay.
No-time commands do not draw. The save already stores duration components and
RNG stream states; old saves without `HasteAut` restore it as zero. Save
validation rejects a haste timer outside its legal range.

The fixed scenario places one haste potion on a reachable Dungeon:2 floor
cell separate from heal wounds. This gives the live terminal client a way to
exercise the new effect until source-derived item generation is ported.

## Verification

Unit tests pin potion duration and messages, action speed draws, combat
distribution at 6 and 7 aut, warning and expiry behavior, and invalid-state
handling. Game tests cover pickup/quaff, same-turn timing, later movement and
melee, monster scheduling, save continuation and legacy default. Terminal
tests cover menu selection and the `Fast` light. Run the full Go suite,
style check, vet, build, and diff check at the category boundary.

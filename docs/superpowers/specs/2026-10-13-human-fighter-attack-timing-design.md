# Human Fighter primary attack timing

## Intent and scope

Make the existing Human/Fighter versus fixed rat encounter spend the source-derived number of auts for a primary melee bump. Currently every action costs 10. Weapon speed, starting weapon skill, and the buckler's shield penalty must determine attack cost, and that cost must drive the scheduler, returned step result, displayed time, and save continuation. Ordinary movement, waiting, pickup, and stairs remain at 10 aut. This is a focused timing slice; haste, finesse, berserk, mutations, later equipment changes, ranged attacks, and other actors remain deferred.

## Ownership and source rules

`combat` owns pure timing math with a bounded roller. `game` projects stored skill points and the committed weapon/buckler properties from ECS and catalog, validates them before a bump, rolls timing from the saved `melee` RNG stream before hit and damage rolls, and passes the resulting cost through `runAction` and `TurnScheduler`. No new ECS or save field is needed.

For an ordinary Human/Fighter, port the applicable path from pinned C++ `player-act.cc:246-331`, `fight.cc:912-956`, `player.cc:5649-5661`, `actor.cc:115-119`, and `random-var.cc:88-220` at revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. A weapon starts at its committed `PWPN_SPEED`, reduced by the weighted `div_rand_round(random_var, 20)` of skill at scale 10, capped by source minimum delay skill. Unarmed starts at 10, reduced by the weighted division of Unarmed Combat at scale 10 by 54. Both add the Human buckler penalty from `PARM_EVASION` and Shields skill at scale 10. Source `random_var` combines these weighted results before `melee-attack.cc` rolls once for the final delay; the scalar `random.cc` overload does not apply. The final normal-speed result is at least 2 auts; the starting options yield narrower values. Preserve C++ integer division, weights, and the single draw before accuracy.

## Behavior and verification

A melee bump validates the target, equipment, and input before consuming a turn. Its one timing draw precedes accuracy and damage; live and loaded games with the same save must continue identically. A shorter or longer attack changes how many rat actions occur before the next player command. The `StepResult.Spent` value and displayed time reflect the actual attack cost. Tests script one combined timing draw for each starting weapon and unarmed, distribution boundaries, and the resulting scheduler order; integrated 79×24 terminal smoke demonstrates a non-10-aut attack and save/load. Normal builds use only committed Go catalogs.

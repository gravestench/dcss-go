# Human Fighter HP and MP Regeneration

## Scope and source

Add ordinary Human/Fighter HP and MP regeneration to the fixed Dungeon. Pin to C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`: `player.cc:1159-1229` gives base HP rate `max(1, maxHP/3)` (with the >20 soft cap) and MP rate `7 + maxMP/2`; `player-reacts.cc:897-952,1026` adds `div_rand_round(rate*actionAut,10)` to each 0–99 fractional counter, then restores one point for each 100 counter units. HP counter advances even at full HP; MP counter advances only below maximum. `random.cc:313-323` rounds one remainder with a bounded roll. The current Human Fighter has maxHP 18 and maxMP 1, so ordinary rates are 6 and 7 counter units per 10 aut. No equipment, mutation, religion, sickness, or spell effects are present in this scenario.

## Ownership and flow

A player ECS regeneration component owns HP and MP fractional counters. New games start at zero; old version-6 saves without the component restore at zero. Restore rejects counters outside 0–99 and non-player ownership. A pure character rule computes one action's new HP, MP, and counters from current values and aut; it uses a dedicated serializable `regeneration` RNG stream only when a division has a remainder. An ECS system applies the result after a player's action effects and duration decay and before monster actions. Monster turns do not regenerate the player. Health and magic still cap at their maxima; reaching full HP does not freeze its counter, while full MP freezes its counter. No HUD layout changes are needed because the existing HP/MP meters read live values.

## Verification

Scripted tests pin the source rates, rounding order for variable-aut attacks, full-HP/full-MP asymmetry, multiple point restoration, and invalid-state rejection. Game tests cover waiting after damage, no monster-turn regeneration, save continuation, legacy defaults, and malformed ownership/ranges. Full Go tests, vet, build, and read-only whole-branch review precede local-main merge.

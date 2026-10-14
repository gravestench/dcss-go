# Source-Rolled HP for the Fixed Rat

## Scope and source

Replace the fixed rat's arbitrary 4 HP with the ordinary monster HP algorithm from pinned C++ revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. `mon-data.h:1994-2004` gives the rat average HP ×10 of 25 and HD 1. `mon-util.cc:2227-2250,2824-2833` rolls its initial and maximum HP: `variance = div_rand_round(avg*33,100)`, `min = avg-variance`, `raw = min+random2avg(variance*2,8)`, then `max(1,div_rand_round(raw,10))`. `random.cc:313-339` defines both random helpers. `mon-place.cc:1147-1148` caps live HP at `MAX_MONSTER_HP` (`defines.h:195`). For the rat, this yields 1–4 HP.

## Ownership and flow

A pure monster HP rule accepts a bounded roller and the catalog's average HP value. It uses a named `monster_hp` RNG stream, saved with the run. `game.NewScenario` rolls once when creating the rat, setting current and maximum HP to the same result. The rest of the fixed rat's catalog-backed attack, speed, position, and AI stay as they are. The existing XP formula continues to award one XP for a rat with any source-possible maximum HP from 1 to 4; it still rejects unsupported monster definitions and malformed save values. Old version-6 saves with the prior 4-HP rat remain valid; no reroll occurs during restore. Saves validate a living rat's maximum HP against the source-possible range.

## Verification

Scripted tests pin the exact sequence and bounds of rounding and eight-draw averaging, plus the 1- and 4-HP extremes. Game tests assert that new rats use the catalog average, deterministic seeds and save continuation preserve their HP and stream, XP remains one, and malformed rat HP is rejected on restore. Full Go tests, vet, build, and one branch review precede the local-main merge. Normal builds use the committed monster catalog only.

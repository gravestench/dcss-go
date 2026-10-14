# Species experience thresholds

## Intent and boundary

Normal Dungeon character creation already reads all committed species, but
progression still calls Human-specific XP functions. Replace that threshold
path with one source-backed calculation parameterized by the selected
species' `XP` aptitude. This prepares the single player progression path for
other species without claiming their starting gear, mutations, HP, MP, or
skill aptitudes are implemented. Human/Fighter behavior and save bytes remain
unchanged.

## Source rule

The pinned `player.cc:3355-3436` computes a historical level curve, subtracts
one, and multiplies by `apt_to_factor(exp_apt - 1)`. In `skills.cc:2043-2049`,
the factor is `1 / exp(log(2) * apt / 4)` and is returned as `float` before the
threshold multiplication. Go must round the factor and product as `float32`
before truncating to an integer. The reference Human aptitude is `1`; Tengu
is `0`, Deep Elf and Minotaur are `-1`, and Demigod is `-2` in the committed
species catalog.

Level 1 needs zero XP, level 27 is the final normal level. Invalid levels,
negative earned XP, and aptitude results that underflow to zero or overflow
Go `int` return errors. `LevelForExperience` returns the
highest attained level. `LevelProgress` uses the selected species' adjacent
thresholds, permits a held applied level while a stat choice is pending, and
returns zero at level 27.

`skills.cc:148-159` defines skill-cost thresholds using `exp_needed(level, 1)
* 13` for every species. Training must keep that fixed reference aptitude;
it must not use the player's XP aptitude.

## Ownership and flow

`character` owns the pure threshold functions with explicit XP aptitude
arguments. The player Akara component owns its selected species ID and XP;
the committed catalog owns the species definition and aptitude. The ordered
advancement system reads the player's species once during construction and
uses its aptitude for level thresholds. The read-only view and save validator
use the same rule. No mutable per-entity component or save schema is added.

## Verification

Check all 27 Human thresholds against the pinned table and compare several
non-Human thresholds against a standalone evaluation of the pinned C++
formula. Check exact threshold boundaries, held-level progress, final-level
progress, invalid inputs, and the species-independent skill-cost threshold.
Run the full Go test suite, vet, build, and readability check at the category
boundary. One contiguous commit is fast-forwarded to local Go `main`.

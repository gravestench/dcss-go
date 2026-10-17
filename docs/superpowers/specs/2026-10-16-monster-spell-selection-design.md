# Source-backed monster spell selection

## Intent and boundary

Monster decisions should read like the pinned DCSS rules and accept every
committed monster spellbook shape. The current Go port commits 285 source
books, but its Lua AI and spell resolver reject any book with more than one
slot. This slice replaces that single-slot assumption with a source-order
selector and a shared slot-validation contract. It does not claim that all
237 spell effects are implemented; live generation remains limited to
monsters whose effects exist. Later effect slices can add one focused Lua
file per spell or shared effect family without changing this selector.

The source is DCSS commit `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`,
especially `mon-cast.cc:_find_spell_prospect` and
`_choose_spell_to_cast`, `mon-spell.h`, and `spl-data.h`. Committed generated
Lua catalogs are authoritative at runtime. Refresh importers remain manual.

## Selection contract

`policy.ai.spell` owns monster spell decisions. A small
`policy.ai.spell_prospect` module accepts a book, monster condition, target
distance, and one random-draw function. It returns the selected slot or
nil, without loading an effect or touching ECS state. The decision policy
then asks that effect whether the target is valid, tries the source's
second targeting attempt where applicable, and returns a spell intent.
The execution system validates that the selected spell belongs to the
monster's effective book and that its Lua effect is still valid for the
target. No independent spellbook interpretation exists in execution.

Normal choice draws one integer in `[0, 199]`. It scans eligible slots in
source order and takes the first slot whose frequency is **greater than or
equal to** the remaining roll, then subtracts a rejected slot's frequency.
This inclusive comparison follows `mon-cast.cc` exactly; changing it to a
conventional half-open weighted interval changes the pinned source's cast
odds. A roll past the total means no cast, including when total weight is
below 200. Eligibility follows source slot flags: emergency only below one
third HP; short range at distances 0–3; long range at distances 4 or more.
Source LOS radius is 7. The port retains its current target-distance metric
(Chebyshev) until the movement/LOS domain handles source distance
consistently.

If a prospect cannot target the foe, the decision policy tries once more,
as `_choose_spell_to_cast` does. The second attempt has the source's
self-enchantment preference coin flip; a preferred self-enchantment uses
weighted selection among spell definitions whose flags include `selfench`.
Fleeing escape preference uses weighted selection among definitions with
the `escape` flag. Selection never rerolls merely because the first
200-point roll chose no spell. Silence filters wizard, priest, and vocal
slots before either normal or preferred selection; natural and magical
abilities remain available. Antimagic, target visibility, and source
action-energy behavior remain in their current owners. A modded spellbook
or spell definition uses these same rules.

The decision returns the selected slot's spell ID and flags. The `core.intent`
schema need only carry the ID if execution can find the matching slot in
the effective book; duplicate spell IDs with different slot flags require
the source slot index in the intent. A unique index is preferred so an
effect can preserve the selected flags for silence, antimagic, breath, and
timing rules. The implementation must validate index and ID together.

## Effect coverage and live roster

Effect modules live under `policy/combat/monster_spells/<spell>.lua` or
return a deliberately shared family module. Every live monster with a
spellbook must have a concrete `can_cast` and `resolve` implementation for
every selectable slot. A startup coverage policy reports missing effect
files and malformed resolver interfaces by monster and spell ID before a
generation scenario admits that monster. It must not convert missing
effects to a skip, generic damage, or no-op. All 285 books are structurally
valid catalog data even while later effects are pending.

The current D:1–2 generated roster must remain playable. The presence of
unimplemented spell effects elsewhere in the source catalog does not stop
launch, because those monsters are not in the active roster. A future
Dungeon-depth slice expands the roster only after the relevant effect
coverage is green. This dependency is explicit in the port inventory.

## Verification

Lua `_test.lua` tests import the production catalog, selector, spell IDs,
and flag constants. They cover multiple slots, order and exact 200-point
boundaries, no-cast weight, all condition flags, self-enchantment and escape
weighted choice, retry after an invalid target, duplicate IDs/slot index,
and a sparse mod overlay. Integrated Go tests cover an existing single-slot
monster, a multi-slot monster with implemented effects, deterministic RNG
continuation through save/restore, and a failed coverage report for a
missing effect. Verify the category once with focused tests, build, vet,
style, and diff checks, then make one implementation commit and merge it
into local `main`.

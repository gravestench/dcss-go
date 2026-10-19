# Monster shapeshifter design

## Purpose

Make naturally generated ordinary and glowing shapeshifters, plus monsters
changed into shifters by Chaos, use the same durable identity and turn rule.
A player should meet a monster already wearing another form, see it change
again during combat, and still get a save that resumes that behavior. This
slice preserves DCSS gameplay and keeps the policy in discoverable Lua files.

## Source behavior and boundary

DCSS attaches a permanent ordinary or glowing shapeshifter enchantment when
the monster is placed, immediately changes its starting form, and keeps that
enchantment through later polymorphs. Chaos can attach either enchantment to
another eligible natural monster and immediately change it. The ordinary
rate is based on live HD; the glowing rate is one in four eligible status
actions. Sleep, paralysis, petrification, and stair transit suppress a turn's
attempt. A successful change preserves original identity and proportional
HP, drops incompatible carried gear, and resets action energy.

`mon-poly.cc` draws a habitat-compatible species uniformly, rejects illegal
or too-distant power forms, and gradually relaxes the power range after
repeated misses. The committed Lua monster catalog supplies the candidate
set. Its stable ID traversal makes seeded games independent of file names or
load order. This does not require the C++ checkout during play or builds.

## Ownership

- A new `combat.monster_shapeshifter` ECS component records the permanent
  ordinary or glowing variant and original monster ID. It is the only
  authority for ongoing form changes.
- `policy/monsters/shapeshifter.lua` owns placement initialization, Chaos
  conversion, eligibility, candidate selection, and turn timing. It calls
  the existing monster body transition in `polymorph.lua`; that transition
  remains the owner of HP, energy, inventory, and original-form linkage.
- An active Lua system ticks shifters before monster decisions. The existing
  Chaos status component retains only its timed agility rule. Ordinary
  Polymorph and Porkalator keep their own target-selection policies.
- `factory.spawn` initializes either natural shifter species after the actor
  enters its level. Authored vault and ambient population use that factory.

## Save and mod contract

The shape component stores named monster IDs. Save validation requires a
living actor, legal variant, and matching original lineage, including when
the actor currently wears a different form. A mod may add a monster form via
its individual content file; candidate selection reads the effective Lua
catalog without a generated JSON intermediary. Old `combat.monster_chaos`
shifter flags are removed in the same change, with no parallel behavior path.

## Verification

Focused `_test.lua` cases exercise both natural variants, Chaos conversion,
rate gates, incapacitation, candidate exclusions, and a later change of form.
A live Go test covers placement, save/restore, and continuation. Run the Lua
rule suite, relevant Go monster tests, package compilation, style, and diff
checks before the category commit and merge to `main`.

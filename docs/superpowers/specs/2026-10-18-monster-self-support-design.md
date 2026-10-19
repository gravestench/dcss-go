# Monster self-support spells

## Purpose

The pinned DCSS source (`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`)
gives monsters tactical self buffs, healing, and protective auras. All 13
spell IDs in this slice occur in committed monster spellbooks, but none has
the `plan` and `resolve` module required by the live caster. The present
coverage gate therefore keeps every monster whose book uses them out of
generated rosters. This slice makes those spells real, saved gameplay rules
and permits those books to pass coverage when their other effects are live.

The IDs are Might, Invisibility, Haste, Minor Healing, Major Healing,
Repel Missiles, Berserker Rage, Sprint, Trog's Hand, Injury Mirror,
Woodweal, Still Winds, and Aura of Brilliance. Ally-targeted Haste Other,
Might Other, Invisibility Other, and Heal Other belong to the adjacent ally
support slice; summons belong to the summon slice. This boundary follows
the spell's target and state owner, not the broad `selfench` flag in spell
metadata, which also marks summons and movement spells.

## Ownership and interfaces

Each spell has one discoverable Lua module in
`policy/combat/monster_spells/<spell>.lua` with the existing
`plan(ctx, caster, foe, slot)` and
`resolve(ctx, caster, foe, slot, plan)` interface. Planning checks source
eligibility without changing world state. Resolution applies the chosen
spell to the caster and spends the selected book slot through the existing
typed intent path. The plan identifies a self target; it never substitutes
the player or an arbitrary nearby actor. The current book, AI selector,
intent, and coverage contracts remain the only cast path.

Shared mechanics live in focused Lua policies: self eligibility and
duration, healing, speed and melee damage projections, visibility, incoming
missile defense, damage reflection, cloud suppression, and brilliance aura.
An effect module calls only the policies it needs. It must not add a
spell-ID switch to Go or to a central Lua dispatcher. Go remains the Akara,
grid, RNG, save, and terminal kernel.

The existing `magic.monster_enchant` record already owns invisibility and
its expiry. The current Chaos boon record owns Haste and Might projections,
but those effects are not exclusive to Chaos. Move their common timers and
consumers to a clearly named monster boon owner, migrate the Chaos producer
in the same change, and remove the redundant Chaos-only path. Existing
monster enchant and boon state remains in Akara. Other effects receive
small saved components grouped by shared lifecycle: defensive protection,
Trog's Hand regeneration and will, Injury Mirror plus its recast clock,
and auras. Do not use module globals for duration, cooldown, allegiance,
or source attribution. Bump schema/save versions deliberately if fields
change; the Go save format may evolve without C++ save compatibility.

## Source behavior

Haste, Might, and Invisibility use `mon-cast.cc` self-enchantment
eligibility: an already active enchantment is not a useful cast, and a
friendly nonsummoned monster with no foe does not keep buffing itself.
Their `beam.cc` effects respect stationary or stasis restrictions where
applicable. Source `mon-ench.cc` determines duration from monster speed,
with beneficial enchantments using the fixed speed modifier rather than
ordinary HD throttling. Haste changes action speed; Might changes melee
damage; Invisibility changes the visibility and targeting decisions that
read monster state. Chaos effects must use those same projections.

Minor Healing is viable for ordinary AI when HP is at most half maximum and heals
`3 + 2d(spell_hd / 2)` through the source healing beam. Major Healing is
viable at the same HP threshold and heals
`50 + random2avg(spell_hd * 10, 2)`, bounded by maximum HP. Woodweal
requires adjacent trees or a Shambling Mangrove and heals
`35 + random2(spell_hd * 3)` without changing terrain. An ineligible
caster does not spend a self-heal slot. Draw order and named RNG streams
must be deterministic across save/restore.

Sprint adds Swift only while absent and changes movement energy, not spell
or attack energy. Berserker Rage uses the existing frenzy/allegiance owner
for its source restrictions, speed and damage effects, duration, fatigue,
and behavior. Trog's Hand grants both regeneration and strong will for its
one source duration and consumes the regeneration and willpower rules while
active. Repel Missiles changes incoming missile hit calculation until
dispelled or the actor leaves play; source `ENCH_REPEL_MISSILES` does not age
with monster actions. Injury Mirror reflects eligible incoming damage to the
attacker, observes its source recast clock, and cannot recursively reflect
the returned damage.

Still Winds deletes clouds across the current level when cast and blocks
ordinary new cloud placement while its caster enchantment is active; vortex
and ink remain permitted. Expiry restores ordinary cloud generation without
resurrecting the removed clouds. Aura of Brilliance requires an eligible
ally and live foe; its projection benefits nearby allied spellcasters and
expires through the same turn flow. These auras are actor-owned status,
not permanent level mutations. Their reach and exclusions follow pinned
`mon-cast.cc` and `mon-ench.cc` rather than a generic friendly-radius rule.

## Failure and persistence rules

A failed plan never creates an intent, spends time, emits a cast message,
or consumes a spell-effect RNG draw. A selected valid cast spends its normal
monster action even when an effect is resisted or capped, following the
source case. Damage and healing use the existing HP, death, and attribution
owners. Dispel, death, banishment, level travel, and save/restore must leave
no orphan timer or aura. A restored actor resumes with the same remaining
duration, target eligibility, and RNG stream state; no Lua file-load order
changes a seeded result. Unknown or corrupt saved state fails validation
with the component and actor identified.

## Verification

Lua `_test.lua` files import production IDs, schemas, and policies. They
exercise every spell's plan, successful resolution, inactive/already-active
status behavior, duration expiry, and the consumer that makes the status
matter. Focused tests check source roll boundaries and action timing for
healing, speed, repulsion, mirror, and auras. Integrated Go tests use real
book casters to prove selected slots resolve, save/restore continues with
the same RNG and status, and a sparse overlay can replace one effect file.
The coverage test must find all 13 modules and reject a removed resolver.

Run the full Lua rule suite, relevant Go game tests, build, vet, style, and
diff checks once at the category boundary. Record an exhaustive-suite
timeout honestly. Make one contiguous implementation commit and fast-forward
local `main` after verification. Update the port inventory and roadmap with
the exact new playable book coverage; do not claim that every source
monster or every other spell family is now playable.

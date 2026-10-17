# Source monster beam spells

## Purpose and scope

The committed monster books contain 226 distinct spell IDs, but the live
monster effect registry currently implements only Freeze, Slug Dart, Petrify,
and a shared hex handler. This slice ports the 44 committed book spells
listed below from the beam setup cases of pinned DCSS
`mon-cast.cc:_setup_mons_cast`
(commit `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`). Each effect must
resolve from a monster caster to an actor, cell, or beam destination as the
source does. A spell without implemented damage, status, terrain, cloud,
explosion, and targeting behavior remains outside the live roster.

This is one complete source effect family, not 44 unrelated handlers. Its
shared mechanics are trajectory, beam contact order, hit and shield checks,
AC/resistance adjustment, explosion/cloud placement, and combat messages.
Unique effect rules stay in the individual spell's Lua module. The family
includes the 44 IDs in the appendix; the remaining monster spells are
separate families (self enchantments, summons, directed effects, breath
special cases, terrain changes, and monster-only abilities).

## Architecture

`policy/combat/monster_beams` is an actor-neutral Lua kernel for source beam
behavior. It uses existing Go grid, line tracing, RNG, and Akara component
operations; Go gains no spell-ID switch. Each production spell has one
discoverable `policy/combat/monster_spells/<id>.lua` module with a readable
source profile and any specific effect hook. Shared beam formulas and state
changes live in focused Lua helpers. The 44 effect files do not call the
player-casting modules, which assume a player caster and monster target.

The existing `policy/combat/monster_spells.effect(id)` loader stays the
single dispatch path. All monster effects migrate in one pass to
`plan(ctx, caster, foe, slot)` and
`resolve(ctx, caster, foe, slot, plan)`. Planning returns nil when source
targeting or tracer viability rejects the cast; it may consume source RNG
but cannot change world state. Its returned target entity or level cell is
recorded in named fields of `core.intent`, so resolution does not repeat
target selection or consume a second target roll. The current Freeze,
Slug Dart, Petrify, and hex modules move to this contract in the same
change, with no old-interface adapter. Failed plans use the existing
source two-attempt monster selection. The decision and resolver share one
effect module and retain the selected book slot in `core.intent`.
That intent is temporary within an action. Saves occur at turn boundaries;
save/restore checks compare resulting world state and RNG continuation.

The current system targets the player. The beam contract must carry a
generic caster and target entity internally so monster allies, summons,
reflections, and future friendly spellcasters use the same kernel. The
initial game integration may keep the player as the active foe; no rule may
hardcode player health into the shared kernel. The intent's target fields
must distinguish an entity from an empty cell and use typed coordinates,
not a serialized Lua table. Effects that create clouds or terrain use the
existing saved world stores. All output that changes gameplay is
represented in ECS or level state and survives save/restore.

## Source data and fidelity

A deliberate importer reads the pinned `spl-zap.cc` mapping,
`zap-data.h` definitions, and relevant `mon-cast.cc` setup rules to emit
committed Lua source profiles. Range and casting noise remain in the
existing committed spell definitions; the beam profile stores zap hit
loudness and target shape without repeating those declarations.
The generated Lua is checked in; build, test, and runtime never read C++.
Source provenance belongs in comments next to declarations. The importer
must fail on an unknown calculator, flavor, or source override rather than
emit a generic damage effect. Handwritten Lua implements behavior that a
profile cannot express plainly. A generated profile declares its own
canonical spell ID, as other content files do; effects import that ID from
`ids.spells` where used. Common flags, elements, and message channels come
from named constants.

The source distinction between a beam, a bolt, an explosion, a cloud, a
digging ray, and a status ray is retained. Reflecting or blocking a beam,
penetration, multi-target contact order, friendly-fire tracing, noise, and
source attribution must be explicit in the source profile or effect hook.
No member of this family may be mapped to a generic hit point subtraction
to satisfy coverage. If the current engine lacks a required primitive,
implement that generic primitive in this slice before enabling the spell.

## Completion and verification

Coverage preflight must accept every one of the 44 modules and reject a
missing or malformed module by ID. Lua `_test.lua` tests import production
profiles and exercise each effect's plan/resolve contract, then source
fixtures check family mechanics at representative boundary values and
target shapes. Go integration tests exercise a multi-spell monster with a
beam, block/reflection, cloud or terrain result, and save/restore RNG
continuation. A source spell whose target behavior needs a not-yet-ported
world subsystem stays registered but cannot enter a live roster until that
subsystem is implemented and tested. Documentation must distinguish
registered effects from playable monsters.

Run focused Lua and Go tests while implementing. At the family boundary,
run the full Lua suite, targeted game tests, build, vet, style, and diff
checks. The exhaustive character-start game test currently exceeds the
10-minute package timeout; report its result separately rather than
claiming `go test ./...` passed.

## Source spell IDs

The 44 beam-setup cases selected from
`mon-cast.cc:_setup_mons_cast` and the 285 committed monster books are:

```text
SPELL_BLINKBOLT              SPELL_BOLT_OF_COLD
SPELL_BOLT_OF_DRAINING        SPELL_BOLT_OF_FIRE
SPELL_BOLT_OF_MAGMA           SPELL_CORROSIVE_BOLT
SPELL_CRYSTAL_BOLT            SPELL_DIG
SPELL_DISPEL_UNDEAD_RANGE     SPELL_ELECTRICAL_BOLT
SPELL_ENERGY_BOLT             SPELL_FIREBALL
SPELL_FLASH_FREEZE            SPELL_FORCE_LANCE
SPELL_FREEZING_CLOUD          SPELL_GHOSTLY_FIREBALL
SPELL_HARPOON_SHOT            SPELL_HOLY_BREATH
SPELL_HURL_DAMNATION          SPELL_HURL_SLUDGE
SPELL_IRON_SHOT               SPELL_LEHUDIBS_CRYSTAL_SPEAR
SPELL_LIGHTNING_BOLT          SPELL_MAGIC_DART
SPELL_MIASMA_BREATH           SPELL_NOXIOUS_CLOUD
SPELL_POISONOUS_CLOUD         SPELL_POISON_ARROW
SPELL_PRIMAL_WAVE             SPELL_QUICKSILVER_BOLT
SPELL_SLEEP                  SPELL_SPIT_ACID
SPELL_SPIT_LAVA               SPELL_SPIT_POISON
SPELL_STEAM_BALL              SPELL_STICKY_FLAME_RANGE
SPELL_STONE_ARROW             SPELL_STUNNING_BURST
SPELL_THORN_VOLLEY            SPELL_THROW_FLAME
SPELL_THROW_FROST             SPELL_THROW_ICICLE
SPELL_THROW_PIE               SPELL_VENOM_BOLT
```

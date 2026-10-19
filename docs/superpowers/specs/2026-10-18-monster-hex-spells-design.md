# Source monster hex and enchantment spells

## Purpose and boundary

The pinned DCSS source (`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`)
routes targeted monster hexes through `mon-cast.cc:_hex_logic` and
`beam.cc` enchantment effects. The committed monster books contain 15
members of that family whose effects are still absent. `SPELL_SAP_MAGIC`
uses `_fire_simple_beam` with the same targeted enchantment mechanics.
This slice makes all 16 live with source behavior, not a fallback hit or
an inert status. Sleep and Petrify already exist; shared rules should serve
them where their source behavior matches. Petrify gains a source zap
profile so its existing effect uses the same power calculation.

The 16 IDs are Agony, Agony Range, Banishment, Confuse, Corona, Dimension
Anchor, Drain Magic, Mindburst, Pain, Paralyse, Polymorph, Sentinel Mark,
Slow, Strip Willpower, Virulence, and Sap Magic. Hibernation and Teleport
Other are in the source `_hex_logic` table but absent from the committed
monster books, so they are outside the playable roster of this slice.

## Ownership and execution

One discoverable `policy/combat/monster_spells/<id>.lua` module owns each
spell's source-specific effect. `policy/combat/monster_hexes` owns the
common entity targeting, line of fire, caster power, willpower checks,
and hit/resistance order. Each module implements the existing
`plan(ctx, caster, foe, slot)` and
`resolve(ctx, caster, foe, slot, plan)` contract. Planning is free of
world mutation; resolution uses its typed target plan and the original
book slot. A mod overrides or adds an effect by placing a file at the
same relative path; no central spell-ID switch is introduced.

The existing deliberate monster-beam importer reads `spl-zap.cc`,
`zap-data.h`, and the relevant `mon-cast.cc` cases into committed,
individually named Lua profiles in `content/monster_beams`. This reuses
the source zap catalog and its ID constants instead of making a second
catalog for the same data. Runtime and build use only the committed
profiles. A profile
contains source power factor, zap flavor, damage or duration calculator,
and any source targeting condition; fixed spell content stays in the
existing spell catalog. Provenance is a nearby comment, not data.

Shared effects operate on an actor. Player and monster implementations
may differ where DCSS does, but both write saved Akara components. Reuse
existing owners for confusion, paralysis, slowing, lowered willpower,
polymorph, monster antimagic, player MP, sentinel mark, and Abyss
banishment. Add focused saved components and turn consumers for anchor,
poison vulnerability, and Sap Magic where no active owner exists. These
statuses must affect teleport, poison, and spellcasting as appropriate;
their timers tick in the existing turn flow. No Lua module global holds
mutable run state.

## Source behavior and failures

The source eligibility predicates apply before casting: Agony and Pain
require a torment-vulnerable foe; Corona avoids an already backlit foe;
Polymorph requires a viable form target; Strip Willpower avoids a foe
whose willpower is already lowered; Virulence excludes full poison
immunity. The source willpower check and its RNG order remain distinct
from target eligibility. Sap Magic uses its separate power factor.
Defenses, immunity, or a failed willpower check produce the appropriate
source effect or resist result and still spend the monster cast. An
obstructed line, wrong level, friendly contact, or invalid target rejects
the plan before a cast is selected. Banishment moves the actor without
kill credit; Drain Magic only drains available MP and restores a ghost
moth's health where the source does. Damage and lasting effects survive
save/restore, including RNG continuation.

## Completion

A coverage test loads all 16 effects and their production profiles and
rejects a missing one. Lua tests exercise each real effect, the common
willpower and planning rules, source viability predicates, status
expiry, and the rules those statuses inhibit. Go integration covers a
book caster in a real game, at least one resisted and one successful
spell, save/restore, and a sparse layer override. Importer verification
checks the committed profiles against the pinned source on demand. Run
the broad Lua suite, relevant Go tests, build, vet, style, and diff checks
once at the category boundary, then make one category commit and merge it
into local `main`.

## Source spell IDs

```text
SPELL_AGONY             SPELL_AGONY_RANGE
SPELL_BANISHMENT        SPELL_CONFUSE
SPELL_CORONA            SPELL_DIMENSION_ANCHOR
SPELL_DRAIN_MAGIC       SPELL_MINDBURST
SPELL_PAIN              SPELL_PARALYSE
SPELL_PETRIFY           SPELL_POLYMORPH
SPELL_SENTINEL_MARK
SPELL_SLOW              SPELL_STRIP_WILLPOWER
SPELL_VIRULENCE         SPELL_SAP_MAGIC
```

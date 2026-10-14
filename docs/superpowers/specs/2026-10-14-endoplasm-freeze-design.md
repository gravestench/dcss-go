# Endoplasm Freeze on generated Dungeon floors

## Goal and source

Admit the D:1–2 endoplasm to the playable generated roster with its
ordinary hit and natural Freeze spell. Keep the fixed scenario roster
unchanged. The pinned source is
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`:

- `mon-pick-data.h:72` gives endoplasms flat weight 1000 on D:1–4.
- `mon-data.h:3661-3670` gives HD 1, average HP 6, AC 1, EV 3,
  speed 10, an ordinary 3-damage hit, spellbook `MST_ENDOPLASM`,
  no corpse, and no skeleton.
- `mon-spell.h:1843-1847` gives one natural `SPELL_FREEZE` slot with
  frequency 70. `mon-cast.cc:3752-3789` filters out Freeze when the foe
  is not adjacent, then selects it when a 200-point draw is at most 70
  (71 of 200 draws).
- `mon-cast.cc:1079-1127,1160-1182,4429-4458` gives HD-1 Freeze
  power 6, and `spl-damage.cc:860-863` deals 1d5 cold damage. The
  current four playable Fighters have no cold resistance in their
  starting state, so damage is unchanged after resistance adjustment.
- `mon-act.cc:1519-1545` tries spells before movement or melee when
  the foe is near. Casting spends the spell energy from `mon-data.h`.

## Ownership and flow

A checked-in source-traced spellbook artifact records the immutable
endoplasm slot. The existing monster definition remains the source for
HP, attack, speed, and action energy. The live endoplasm needs no new
mutable component: identity, health, position, energy, and target memory
already live in Akara. Its decision system emits a transient `IntentSpell`
with the selected spell ID when the player is visible and adjacent.
One ordered spell system resolves the intent before movement and melee.
The scheduler spends cataloged spell energy. Its spell selection and
damage draws use a named serializable stream so save continuation is
deterministic.

The pure Freeze rule rolls 1d5 for this pinned HD-1 caster. It does not
borrow melee AC, shield, or dodge rolls. A cast emits a visible freeze
message and credits a lethal hit to the monster. The death system handles
player death; killing an endoplasm awards source XP but never creates a
corpse. Save validation accepts its normal ECS actor state and rejects
unsupported spell IDs or malformed links.

## Verification

Tests cover committed source values, generated D:1–2 selection, HD-1 HP
range, spell probability boundaries, adjacent and nonadjacent decisions,
cast damage and spell energy, ordinary melee fallback, XP without a corpse,
and deterministic save continuation. Run category-wide tests, vet, build,
style, and diff checks before one commit and fast-forward local Go `main`.

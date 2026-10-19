# Monster conjured constructs design

## Purpose

Make Battlesphere, Conjure Ball Lightning, and Spellforged Servitor from
committed monster spellbooks playable. These are one slice because each cast
creates an autonomous spell actor and each already has a player-side Lua
policy. The implementation extends those owners for monster casters rather
than creating a parallel monster-only combat path.

## Source behavior

- Battlesphere is one owner-bound actor with a finite charge and duration.
  Tengu Conjurers summon it with monster spell power capped at 200. A later
  conjuration cast aims it at a visible unaligned actor and triggers its
  `2d(5 + HD)` shot. The owner does not cast a second sphere while one lives.
  Player recasts recharge their existing sphere. Creation rolls HD from
  `1 + div_rand_round(power, 11)`; a recast does not change that HD.
- Conjure Ball Lightning creates three short-lived balls. The caster's
  effective spell HD determines power and each ball's HD. A ball approaches
  enemies and explodes once when near an enemy, killed, or expired. Its
  electrical explosion follows the existing ball-lightning construct rules.
- Spellforged Servitor summons one actor for degree-four abjuration.
  Frederick's effective spell HD gives power `6 * spell HD`; initialization
  rolls HD `9 + div_rand_round(power, 14)` and HP `60 + 7d5`. The servitor
  receives source-priority spells its monster caster knows and whose monster
  effect modules can plan and resolve a cast, with frequency proportional
  to spell level. This temporary runtime guard keeps currently unported
  monster spells out of its book. Its book is frozen at summon time.

## Ownership and flow

The three monster effect files own only plan and cast setup. The existing
Lua summon policies own actor creation and later construct behavior.
Summon, position, health, energy, and specific construct state remain saved
Akara components. Player and monster casts choose their own named RNG
stream; shared construct code never assumes a player owner.

The monster spell system emits a successful-cast signal. The battlesphere
system observes player and monster conjurations after their effects resolve
and triggers the owner's sphere. It does not mirror Battlesphere or
Spellforged Servitor themselves. A failed or vetoed cast emits no signal.

A monster-owned servitor uses a saved ordered spell list and per-slot
frequencies on its existing `magic.summon_servitor` component. The monster
spellbook owner projects those saved fields into the same book interface as
catalog spellbooks. Generic monster AI and spell execution then choose and
resolve its casts; no global spell switch or special Go action path is added.
The existing player servitor decision remains until player spell coverage
can support its full source spell priority list.

## Verification

Focused Lua tests check each cast's source count and power, allegiance,
spellbook snapshot, sphere triggering, ball explosion, and RNG stream.
Live game tests cast each source spell from a sparse spellbook fixture,
exercise the construct's next action, and compare save/restore continuation.
At the category boundary run the relevant game and Lua tests, full Lua rule
suite, Go build, style check, and a source-diff review.

Living Spells remain in the walking-tome slice: their custom spell actors
also need Iceblast and tome-specific death behavior. Malign Gateway stays
with portal and tentacle terrain rules.

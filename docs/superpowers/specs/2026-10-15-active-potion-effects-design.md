# Active potion effects in Lua

## Goal and boundary

Make every one of the 17 active potion kinds in the pinned DCSS
`potion.cc` usable through the existing quaff command. A potion must have a
source-backed effect, preflight rule, turn cost, consumption rule, message,
and save continuation. The current client names potion types openly; item
type identification is a separate inventory-wide domain and this slice does
not pretend to implement unknown-potion behavior.

The embedded Lua game owns the effect rules. Go continues to own ECS storage,
generic command execution, saves, and terminal drawing. A sparse overlay can
replace one potion effect or add an effect for a modded potion without editing
a central switch.

## Source roster and registration

The active source roster is curing, heal wounds, haste, might, brilliance,
attraction, flight, cancellation, ambrosia, invisibility, degeneration,
experience, magic, berserk rage, mutation, resistance, and lignification.
The committed `content/items` declarations remain the canonical IDs and
names. Source provenance belongs in comments beside rules, not in runtime
data fields.

`policy.potions` becomes a small registry. Each file under
`policy/potions/effects/` builds and returns one readable effect object and
registers it by an imported `ids.items` constant. The object exposes
`can_quaff` and `apply`; shared helpers live in focused policy modules.
Startup validates duplicate IDs, active-content coverage, and malformed
handlers. The existing `policy/potions/mutation.lua` and four inline effects
move to the same contract. No Go potion-ID dispatch or giant Lua switch is
introduced.

The command preflights common drink and form restrictions, then calls the
effect's preflight rule. That rule may return a refusal or a confirmation
prompt; the latter replays the command with its generic forced flag after
the player accepts. Rejection spends no turn and consumes no item. A
successful command creates the current ECS quaff intent. The item system
calls the effect and consumes one quantity once, after successful
resolution. An effect that is allowed but partially resisted still consumes
the potion, matching `PotionEffect::quaff`.

## Effect families and owned state

Healing and resource effects cover curing, heal wounds, magic, and
experience. Curing removes poison and confusion as well as healing when
allowed. Magic respects HP Casting. Experience grants source levels and
skill experience through the existing advancement/training owners, with a
saved pending skill choice if player input is required.

Timed buffs cover haste, might, brilliance, attraction, flight,
invisibility, ambrosia, and resistance. Each lasting effect uses an Akara
player component or an existing durable status owner. Its turn decay and
gameplay consumers read the same state; the UI projects that state. A buff
is not considered implemented merely because a duration icon appears.

Transformations and volatile effects cover berserk rage, lignification,
mutation, cancellation, and degeneration. They reuse the existing Lua rage,
form, mutation, stat-loss, and status rules. Tree form must enforce its
movement, equipment, defense, and cancellation rules. Cancellation removes
the source set of cancelable effects and reduces contamination, which needs
a saved player state owner. Degeneration applies three stat-loss rolls.

Source religion conduct and god passives are recorded as integration points
for the religion slice, since worship mechanics do not yet exist. This
slice does not add fake piety changes or a Go compatibility hook. Potion
effects must otherwise work for every currently playable species and form;
unsupported source interactions are listed explicitly in the port inventory.

## UI, saves, and mod behavior

The existing `q` inventory flow lists every carried potion. A rejected
known potion explains why and leaves time and quantity unchanged. Effects
that need confirmation or a skill choice use Lua input/presentation policy
and generic terminal screens, without a Go potion-specific switch.

New status components, pending choices, and contamination are saved and
validated by Lua save policy. Restore continues timed effects and pending
choices exactly. A modded effect file replaces its base file through the
resolved layered ruleset; both `require` and auto-discovery see the winning
bytes. The ruleset hash distinguishes a changed potion rule. A modded potion
definition with no effect fails at boot rather than becoming a silent inert
item.

## Verification

Source-vector Lua tests cover each active effect, refusal and consumption
ordering, duration extension, and RNG draw order. Whole-game tests cover
the quaff transaction, combat/AI consequences of timed buffs, save/restore,
and terminal prompts. An active-roster coverage test rejects missing effect
files. Tests use `_test.lua` fixtures that import production IDs and schemas
instead of redeclaring them. Run one integrated Go suite and style gate at
the end of the category, then make one commit and fast-forward local `main`.

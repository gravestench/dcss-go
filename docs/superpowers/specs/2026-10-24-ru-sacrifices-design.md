# Ru sacrifices design

## Intent

Make Ru's defining bargain playable in the Lua game rules. A worshipper
receives three source-shaped offers, can inspect and accept one or reject
the set, and keeps the consequences through save and restore. Modders can
add or replace an offer without editing the Go engine or a central switch.

## Source and current state

The pinned `sacrifice-data.h` defines seventeen sacrifices. The pinned
`god-abil.cc` chooses valid mutation variants, computes their piety,
selects three distinct offers near Ru's piety cap, applies permanent
mutations and skill/equipment consequences, and resets the offer timer.
`religion.cc` checks the saved timer at god time. Player kills add one
progress on a coin flip while Ru has fewer than 200 piety points;
exploration already
has its separate one-in-one-hundred progress rule.

The Go port currently initializes and saves Ru's counters and empty lists,
but has no offer generation or sacrifice commands. Existing mutation,
skill, equipment, piety, ability, and god-time owners must be reused.

## Ownership and design

Each sacrifice is a Lua content definition under `content/ru_sacrifices/`.
The definition declares its ID, label, mutation or variant pool, base
piety, sacrificed skill, and a focused rule module. All seventeen source
definitions are committed and auto-discovered; load order has no gameplay
meaning. A sparse mod adds one file for a new sacrifice or replaces the
same relative path for an existing one. The effective definition supplies
offer eligibility and acceptance behavior, so no central ID switch grows.

One saved `religion.ru` ECS record holds progress, delay, rejection penalty,
offered IDs, their rolled mutation choices and quoted base piety. IDs and
mutation choices are stable strings from imported Lua ID modules; empty
lists mean no offer. The offer owner sorts candidate IDs before source
ordered selection so file discovery does not perturb seeds. It validates
the candidate pool before spending offer-selection RNG and commits all
three offers together. Quoted piety excludes any skill-derived part that
can change before acceptance, matching the source's saved quote.

The god-time owner calls Ru's named Lua time module after its ordinary
zero-piety check. A credited XP kill advances progress with the source
coin flip below 200 piety; an uncredited, summoned, formerly neutral,
or no-XP kill cannot. When progress reaches the saved delay and there is
no outstanding offer, god time generates a set of three. It never silently
rerolls an existing offer. Monk and ecumenical starts still use the saved
9999 progress shortcut.

Each offered sacrifice appears in the ordinary ability menu. Accept and
reject use the existing confirmation flow. Acceptance applies the selected
permanent mutation or three Arcana mutations, removes sacrificed skill
training, resolves affected equipment, grants source piety up to Ru's
six-star cap, clears all offers, and resets the timer. Rejection clears
all offers and extends the next delay, with the saved penalty accumulating
as in source. Cancellation changes no state or RNG. Other abilities may
remain usable while offers are outstanding.

## Implementation boundaries

The Lua policy must not duplicate mutation schemas, item definitions, or
skill formulas. It reads those owners and stores only Ru-specific state.
Static source constants get names in Lua modules. Every behavior function
explains why and how it acts. No inline Lua enters Go. Source provenance
belongs in comments, not runtime content fields.

## Verification

Lua tests cover all seventeen offer registrations, deterministic selection
independent of file order, variant validity, cap-aware three-offer choice,
source RNG order, kill/exploration/god-time progress, acceptance and
rejection, cancellation, skill/equipment consequences, six-star cap, and
save/restore. Integrated game tests exercise the actual ability menu and
command flow. The build and style checks run once after the category.

# Religion worship and piety

## Goal and scope

Make worship a live, saved player domain rather than a pair of fields fixed at
character creation. A player can pray at every generated altar, join or leave
any source god they are eligible to worship, and see their god and piety in the
terminal. The domain owner also exposes one piety operation for later conduct,
gifts, abilities, and wrath rules. Those later effects remain separate slices;
this slice must not pretend they occur merely because the piety total changes.

The pinned DCSS source is `crawl-ref` at `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
`god-prayer.cc`, `religion.cc`, and `god-conduct.cc` are the source of rules.
The current Go game already saves altar identity on vault records and uses Lua
for action preparation and dynamic ECS components. The new work builds on
those owners. No C++ runtime or content importer is involved.

## Ownership and mod surface

`religion.worship` is one Lua-defined ECS component on the player. It owns
current god, piety, piety hysteresis, gift timeout, per-god penance,
per-god worship counts, and highest piety reached. It also owns the temporary
good-god transfer state and the minimum Ignis piety needed when rejoining.
Use homogeneous `map<string,int64>` for per-god values; initialize them empty
and use a missing key as zero. God's permanent or timed effects belong to
separate components owned by their god module rather than an open-ended
property bag on `religion.worship`.

`character_origin` keeps only creation facts. Starting jobs still pick their
source god and starting piety, but `character.start` writes those choices into
`religion.worship` at creation. No active worship state remains in origin.
This intentionally changes the Go save schema; no old-schema adapter is
required for the private fork. New saves must restore exactly, validate every
god ID and bounded numeric field, and reject impossible states such as a
Forlorn worshipper.

Each source god has a discoverable definition under `content/gods/` for its
stable ID, name, and declarative worship facts. The Lua `policy/religion/`
tree owns eligibility, conversion, piety math, and presentation decisions.
A god with immediate join or leave effects has a same-named module in
`policy/religion/gods/`. A mod can add a definition and, when needed, its
behavior file under those directories; it does not edit a large central
switch. Existing code imports source god IDs from `constants.gods` at use
sites. A modded god owns its new ID in its own definition module. Content
definitions are traversed in stable ID order, so a file rename cannot alter
a seeded draw. Mutable consequences live in components or saved level records.

## Altar interaction and command flow

The terminal maps both source stair keys (`<` and `>`) to the altar action
when the player stands on an altar, as `main.cc::_can_take_stairs` does.
On other terrain they retain their existing stair and shop behavior. The
command enters the existing Lua preparation path. A generic context query returns typed level
records at the player's coordinates; the prayer policy reads the altar's
saved `god_id`. This query is independent of religion and usable by other
systems. The Go bridge does not map god IDs or choose divine effects.

On the player's own altar it reports an offered prayer without altering worship. A candidate
altar presents source-style information and requires explicit confirmation
before converting. Refusal spends no time and changes no state. Invalid
species, mutation, form, or Gozag fee conditions are reported before
confirmation. A successful conversion spends a source prayer turn and runs
leave then join effects in order. A confirmed ecumenical altar resolves a
single eligible god using the game RNG, changes that altar's persisted
identity, and applies its source entry bonus. Declining keeps the mystery.
The UI must not display a god that the player has not yet accepted.

Renouncing worship uses a separate explicit confirmation and the same leave
path as conversion. A player with no god receives a free message. The prior
god's wrath and lingering effects must be represented as saved state and
executed by later god systems, rather than silently discarded.

## Source rules and state transitions

Eligibility covers all active source gods: Forlorn; good gods versus undead
or demonic state and Lich form; innate casters versus Sif Muna, Vehumet, and
Kikubaaqudgha; Beogh's orc restriction; Gozag's fee; No Love versus the
five gods that require followers; and Zin's transformation restriction.
Restrictions distinguish permanent inability from temporary form or fee
rejection. Lua uses existing species, mutation, form, holiness, and wallet
components rather than caching a second copy of those facts.

Join state follows source defaults: ordinary gods begin at 15 piety,
Xom at 100 with its two-draw gift timeout, Ashenzari and Ru use their
source starting values and setup, and Ignis cannot reset its spent piety by
leaving and rejoining. Starting-job exceptions preserve their current
source-derived values. Monk and ecumenical bonuses, good-god piety transfer,
Gozag's service fee, and god-specific immediate join/leave effects are
handled by god modules. The common transition enforces order; each module
owns its own exceptional behavior.

The piety owner implements source breakpoints (30, 50, 75, 100, 120, 160),
the 200 cap, Ru's 160 cap, Xom's separate rank behavior, loss hysteresis,
gift timeout reduction, and per-god maximum history. Random draws use a
named religion stream and are made in source order. Rank changes emit
signals for god ability, passive, and gift systems; absent downstream
handlers are explicit pending coverage in the port inventory. Piety never
silently awards a generic substitute effect.

## UI and tests

The DCSS-like sidebar shows current god, piety stars, and penance where
appropriate. The altar name already appears in map inspection; prayer
uses that same saved identity. The terminal fills the available viewport
while honoring its minimum size, as it does today.

Lua `_test.lua` coverage uses production schemas and ID modules. Test every
god's registration and default state, all eligibility families, the
ordinary/own/other/ecumenical altar paths, confirmation refusal, join/leave
ordering, source piety breakpoints and hysteresis, and deterministic RNG
across save/restore. Go integration tests exercise actual terminal command
routing, an altar from a generated floor, and saved ECS/altar state. Run the
focused script and game tests once at the category boundary, then the
repository's style and broader verification. Do not add inline Lua fixtures
to Go tests.

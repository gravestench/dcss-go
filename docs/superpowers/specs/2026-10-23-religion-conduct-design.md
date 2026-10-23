# Religion conduct design

## Purpose

The worship slice stores devotion, but ordinary play does not yet give gods
their source reactions to kills, exploration, spells, attacks, and other acts.
This slice makes conduct a complete domain across the 26 active gods. It
follows the pinned `crawl-ref` source's `conduct-type.h`, `god-conduct.cc`,
`religion.cc`, and the producer sites that call `did_god_conduct`. The original
source remains a reference; the committed Lua rules are the runtime authority.

Conduct is one contiguous problem category. God abilities, gifts, passive
effects, and wrath are separate categories whose handlers consume the same
saved worship state. The port inventory must distinguish a working conduct
reaction from a pending downstream gift or wrath effect.

## Ownership

`policy/religion/conduct.lua` owns validation, current-patron routing,
source-order reaction evaluation, piety scaling, penance, and messages. It
does not identify monsters from their display names. Producers report a
stable event ID from `constants/religion_conduct.lua` with typed facts such
as severity, whether the player knew, victim entity, and credit. The owner
reads the live ECS actor and the resolved monster catalog before the victim
is destroyed. An event is resolved immediately so no transient entity ID
needs to survive a save or another system phase.

Each god's responses live in a focused `policy/religion/conduct/<god>.lua`
module named by that god's content definition. A source god with no
response has no empty handler. Modules return a local table with named
methods and per-event rules. The common owner supplies reusable source
arithmetic; god modules express only their actual preferences, exceptions,
and messages. A layered mod can replace the god definition and module by
relative path or introduce a new pair. Discovery order never chooses a
response or consumes RNG. No Go content-ID switch or inline Lua is added.

`religion.worship` keeps piety, hysteresis, and penance. Any additional
per-turn or per-god counter that must persist is a Lua-defined component,
not a module global. The same player state passes through save/restore.
The conduct owner calls the existing piety owner for gain and loss, and
adds a source-faithful `offend` operation there for scaled loss, penance,
and excommunication. A zero-piety offense uses the worship leave path.

## Source rules

The source's 35 actionable conduct kinds become named constants. The response
matrix covers every active god, including gods with an empty peeve or like
set. The source's kill reward formula uses victim holiness, experience
level, player experience level, and the god's special response. It must not
use player XP reward as a substitute for monster experience level. A
friendly victim cannot grant kill piety. No-reward and summoned victims
follow source restrictions. A holy attack's former neutrality or no-reward
status matters; an ordinary hostile holy monster is not automatically a
sin against good gods.

The shared response code applies dislike before like, preserving the
source order. It honors unknown-act forgiveness, nonnegative severity,
source piety/penance factors, penance offsets, Faith scaling, loss
hysteresis, and exact chance rounding on the religion RNG stream.
Special cases stay in the owning god module: Trog's distributed-training
exemption; Zin's glow lecture; Jiyva's slime and Abyss exclusions;
Cheibriados's speed comparison; Ashenzari and Ru's exploration progress;
Uskayaw's transient hurt-foe value; Okawaru's difficulty calculation;
and Beogh's heretic and allied-orc rules. Each exception must be
source-traced in that module's comments.

Combat, death, spells, item use, exploration, monster visibility, and
character training produce conduct only where their source-equivalent
action already exists in the Go game. Producers classify from structured
content and ECS state, not English names. A later domain that adds an
action adds its producer at that action's owner. The conduct owner itself
has no huge content switch and no fake event for an unimplemented action.

## Validation and presentation

At boot, a named module must exist, return a table, and contain only known
event IDs and well-formed response fields. Errors cite the winning content
definition or rule path. The god-description UI uses the same response
metadata for likes and dislikes, so help text cannot drift from gameplay.
The modding guide documents the event shape, registration, source math,
save ownership, module path, and how to add a new producer.

## Verification

Lua `_test.lua` files use the production constants, catalog, and test
harness. A matrix test compares the bundled 26 gods' response keys and
factors with a source-traced fixture. Focused tests cover each unusual
response, event order, unknown-act forgiveness, Faith, penance,
excommunication, no-god, save/restore, and a sparse overlay god. Game
integration tests drive a kill, spell, and exploration through real turn
owners, and verify the resulting piety and RNG survive replay. Verify
the category once with the relevant Lua and Go packages, full build,
and style check before one contiguous conduct commit and push to `main`.

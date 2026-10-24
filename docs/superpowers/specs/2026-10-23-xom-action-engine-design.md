# Xom Action Engine Design

## Intent

Port Xom's action engine from the pinned DCSS source into the embedded Lua
ruleset. Xom worship and Xom wrath must use the same engine. The current
wrath handler raises an error; a successful slice replaces that gap with
source-shaped action selection, effects, mood changes, and saved state.

The port remains Dungeon Crawl. Lua owns game policy and effects, while Go
continues to provide reusable entity, grid, RNG, save, and terminal services.
The game must remain understandable to a reader who has never read the C++.

## Scope

- Implement the source Xom action selector, including its ordered chance
  checks, niceness, severity, tension, suppression, and no-action outcomes.
- Implement every real event in `xom_event_type` from the pinned source.
  Events must use live game mechanics, not messages or pending records that
  claim an effect occurred.
- Share those actions between ordinary Xom worship and divine retribution.
- Implement per-action Xom mood drift, boredom, interest, and stimulation.
- Preserve temporary Xom effects and their expiration through save/restore.
- Keep action IDs, messages, and source constants in named Lua modules.
- Make event definitions replaceable through the layered mod filesystem.

This slice does not port every separate source hook that *stimulates* Xom,
such as every unusual death, item destruction, or new-level event. The
stimulation owner will be callable by those later action domains, and the
events that the Go port already executes will feed it in this slice.

## Architecture

`ids.xom_events` names the source events. Each `content/xom_events/*.lua`
file registers one event's metadata, including its Lua effect module and
badness. The file path is the mod replacement unit. The effective catalog
uses sorted IDs, so directory load order cannot change a seeded game.

Selection has a separate, explicitly ordered Lua policy. That order is a
game rule: source Xom tries early checks before later ones. It is not a
content-file load order. Related effects can share a small policy module
(for example, teleportation), but each event resolves through its own
definition. Modded events may supply a selector module and a numeric
selection stage; ties sort by stable ID. A mod can also replace the whole
selection policy when it needs behavior the data form cannot express.

One Xom owner reads worship, piety, interest, penance, and player position.
It chooses an event, resolves its effect module, and then applies the
source post-action interest and piety changes. No action module edits the
shared Xom clock. Effects call existing Lua owners for spells, summons,
mutations, status, clouds, items, terrain, and travel. A missing generic
mechanic is added in its actual owner instead of hidden in Xom policy.

## State and timing

The existing player `religion.worship` component owns piety and interest
(`gift_timeout`). Ecumenical Xom stimulation applies immediately after
conversion, removing the old pending placeholder component. Any stair
repulsion, cloud trail, banishment return, or other timed
effect is an explicit component or level record with save validation.

The player reaction system calls Xom once for each completed player action
while worshipping Xom, matching the source's per-action tick. The action
selector can also be called directly by Nemelex's Divine Wrath and later
ordinary timed wrath. The two entry points choose their own RNG stream and
do not add a second behavior path. Events resolve before the source
post-action mood update.

## Fidelity and tests

- Source action priority, thresholds, draw order, monster eligibility, and
  effect parameters are explained beside the relevant Lua function.
- Fixed-draw Lua tests pin good and bad selection, suppression, one event
  in every effect family, post-action mood, and failure rollback.
- A catalog test proves all source event IDs have valid effective Lua
  definitions and effect modules, including mod replacements.
- Game tests exercise ordinary Xom action timing, wrath via a card,
  save/restore of lasting effects, and a small seeded transcript.
- Final verification runs focused Lua and game suites, both command builds,
  diff checks, and the repository style check. Broader tests run once at
  this category boundary, with timeouts reported separately from failures.

## Considered approaches

One giant Lua switch would mirror `xom.cc` but create the same cognitive
load and make one-event mods awkward. A Go action dispatcher would violate
the Lua-first ownership boundary. The chosen design keeps source selection
order visible in one policy while letting each effect and definition stay
focused and replaceable.

## Builder decisions

The user previously delegated implementation choices and asked work to
continue without repeated approvals. The implementation plan may refine
module boundaries while preserving these guarantees. No source-line
references belong in content definitions; comments explain the reason and
mechanics in ordinary language.

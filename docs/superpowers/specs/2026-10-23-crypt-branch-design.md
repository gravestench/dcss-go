# Crypt branch design

## Intent

Make Crypt a complete, playable three-floor branch using the pinned DCSS
`crypt.des` corpus. A scheduled Vaults entrance should use an authored
Crypt gate; Crypt:1 should admit its optional arrival maps, all eligible
floors should admit the full ordinary vault pool, and
Crypt:3 should choose one source ending. The selected map, actors, items,
Tomb gate, and one-shot map events must remain correct through save and
restore. Crypt is one content and gameplay slice, rather than a succession
of individual vault ports.

## Source and scope

The behavioral source is `crawl-ref/source/dat/des/branches/crypt.des` at
the pinned revision in the port inventory. It has 59 named definitions:
13 Vaults-side entry choices, three Crypt:1 arrival maps, 35 ordinary
maps, and eight Crypt:3 endings. Commit one `.des` file per definition;
keep every MAP block byte-identical. The SHA-256 of the sorted
`name SHA-256(MAP block)` manifest, joined without a trailing newline, is
`553295c86138bbd1985ba1f126dedc3d5f40c297d937add780be59931c19e400`.
Disposable local extraction tools are not runtime or repository inputs.

Port source script statements to readable, commented Lua hooks at their
authored positions. The original DES map format remains authoritative.
Source `crypt_entry` directives provide the entry tag, first-floor monster,
and keyed Crypt stair. Source conditional monster sets, Crypt loot, terrain
substitutions, delayed decay, feature names, fog, and scripted map events
are part of this slice. No Lua source belongs in Go strings.

Crypt branch generation and travel are in scope. Tomb's three floors,
special stair topology, and golden rune are a separate subsequent slice.
Crypt:3 still places its scheduled Tomb gate: an authored gate wins where
the chosen ending provides one, and the standard scheduled gate is the
fallback otherwise. A player may see Tomb as unavailable until that
subsequent slice lands. Unrelated monster spell, religion, and item
mechanics keep their existing domain owners.

## Architecture

* The layered DES catalog discovers `crypt_entry`, `crypt`, and
  `crypt_end` families. Source tags and depths determine eligibility;
  stable NAME ordering prevents filesystem iteration from changing draws.
  A sparse mod can add a map or replace one relative path.
* The existing branch schedule chooses the Vaults floor. The generic
  branch-entry fitter draws a source-weighted `crypt_entry` map and binds
  its keyed gate to the scheduled link. Generic Crypt generation places
  eligible optional arrivals and ordinary maps. A mandatory primary choice draws one
  of eight `crypt_end` maps on Crypt:3 and preserves its ID in level state.
* Crypt hooks are grouped by the rule they own: entry setup, ending
  themes and loot, local map substitutions, and event setup. Source
  choices use the layout RNG at their original operation positions.
  A hook emits operations; when a later draw depends on an earlier
  placement, separate source-position hooks give the engine time to
  apply the earlier operations.
* Existing Akara actor, item, trap, and vault-origin owners materialize
  authored content. One-shot player-LOS sarcophagus and grate events use
  saved vault-trigger entities and named Lua callbacks. Their current
  terrain is the authoritative result; restore does not rerun the event.
  The fog machine uses the current cloud owner.

## Behavior and invariants

The source's dummy entry remains weighted and can intentionally place
only the keyed stair. Every selected entry has exactly one live Crypt
gate. Crypt:1 arrival maps remain Crypt-only extras and cannot enter the
Vaults-side entry draw. Every Crypt:3 floor has exactly one ending and
one scheduled Tomb gate. A keyed Tomb gate on an ending must not create a
second generic gate. A failed source map cannot spend a stair, consume a
scheduled link, or leave partially populated state.

The guarded Crypt arrival wakes its sealed occupants once on player LOS;
the glass Crypt's one-shot marker drops its linked grates. Event groups
are tied to the source vault record and final transformed coordinates,
not map-global Lua variables. Saves retain the selected entry/end IDs,
placed entities, gate links, trigger armed state, and changed terrain.
Restore validates the same ruleset hash and the source-linked records.

## Verification

Compare all 59 committed MAP blocks with the pinned source. Exercise all
entry, arrival, ordinary, and end maps through the production DES loader;
generate each ending and sample entrance choice through the live builder.
Test both outcomes of conditional hooks, source choice order, authored
versus fallback Tomb gates, one-shot LOS triggers, save/restore before and
after a trigger, and malformed sparse overlays with rollback. Commit text
snapshots of representative Crypt:1–3 floors, their branch links, chosen
vault IDs, and keyed feature positions. Run focused Lua and Go integration
tests, build, formatting, and source comparison at the slice boundary.

## Approaches considered

The selected approach extends the generic branch-entry, extra-vault,
primary-vault, and trigger paths already used by other branches. A
Crypt-specific Go generator would put game rules in the kernel and break
the mod extension contract. Importing only the eight endings would make
the branch look complete while omitting most of its source content.

## Boundaries

This is the full Crypt map, travel, and map-event slice. Generic kernel
changes are allowed only when the existing Lua and ECS interfaces cannot
express a reusable capability. Tomb generation and its stair topology
follow as their own coherent slice.

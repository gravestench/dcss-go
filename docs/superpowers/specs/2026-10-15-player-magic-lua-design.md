# Player magic in Lua: design

## Intent and scope

Port the complete player spell domain from the pinned DCSS source into the
embedded mod tree. A character must be able to learn, select, aim, cast, and
forget every spell the source allows a player to memorise. The same effect
registry must cover player uses of spell IDs through items and abilities.
Ordinary spell behavior must be extendable by adding or replacing Lua files,
without editing or recompiling Go.

This is one domain conversion, not a collection of narrow spell handlers.
There must be no Go spell-ID switch, parallel Go cast resolver, Lua embedded
in Go strings, or temporary compatibility adapter. Generic ECS, grids, RNG,
saves, and terminal mechanics remain in Go. All source-derived rules and
content are committed Lua files; normal builds do not read C++ sources.

The pinned source at `crawl-ref/source` has 403 spell identities: 109 unique
active spells in extant player books, 16 other player-use IDs, 190 monster-only
spells, 86 removed spells, one debug-only identity, and the `NO_SPELL`
sentinel. `spl-book.cc` defines
`is_player_spell` and the memorisation candidate set. Monster-only and
removed IDs must never become player-castable merely because an effect module
exists. The 16 additional IDs may be invoked by their appropriate item or
ability; they do not all become memorisable.

## Runtime ownership

Lua owns player spell knowledge, memorisation, casting policy, effect
registration, effects, status and summon rules, and all user-facing magic
text. Akara stores durable per-player spell records as entities with a
Lua-defined `character.spell` component: owner handle, spell ID, library
availability, known slot, letter slot, and any scheduled innate level. One record per
owner and spell ID avoids opaque encoded lists and makes knowledge changes
queryable. A separate Lua component on the player records last cast spell
and an in-progress memorisation delay. These components replace the mutable
spell strings in `character.origin`; its other fields are unaffected by this
domain. Save validation rejects duplicate, malformed, unknown, or
unowned spell records, impossible known or letter slots, and invalid delays. Existing
Go-format saves either migrate explicitly or fail with a clear version or
ruleset mismatch; they must not silently reinterpret the old state.

Character creation populates these components in the same Lua start
transaction for all species and jobs. Level advancement grants scheduled
Djinni spells at the source levels without rerolling the saved schedule.
Books, gifts, forgetting, and later content change spell records through one
Lua knowledge API. The library and known lists remain distinct. A spell may
be in both; a scheduled spell need not yet be known.

## Learning and casting flow

`spl-book.cc`, `player.cc`, `spl-util.cc`, `spl-cast.cc`, `spl-miscast.cc`, and
`delay.cc` are the source for the common rules. Learning checks species and
other restrictions, library access, already-known and maximum-known limits,
experience level, and available spell levels. Total spell levels are source
XP level minus one plus Spellcasting skill at the source scale, capped at 99;
known spell levels are subtracted. Memorisation consumes a delay equal to
spell difficulty and can be interrupted. Cancellation before commitment
does not create knowledge or consume the wrong resources.

Casting has three distinct results:

- **Abort:** preflight or target choice cancels without spending a turn or MP.
- **Failure:** the attempt spends its turn and resources, applies source
  failure and miscast consequences, and does not run the effect.
- **Success:** the attempt spends its turn and resources, resolves the effect,
  trains skills, and emits source messages and noise.

The Lua cast policy checks known spell, general casting restrictions,
spell-specific usefulness, range, target, resource cost, and warnings before
committing. It preserves DCSS's order of MP/HP payment, failure roll,
effect resolution, refund on abort, practice, noise, and turn commitment.
All random draws use named host streams, with source-specific order recorded
in comments and parity fixtures. Power, failure, range, cost, spell level,
noise, and the true displayed failure rate have focused Lua modules. In
particular, preserve the integer polynomial and rounding in
`spl-cast.cc:346-415`; power caps and zap caps are separate.

The command path uses one player cast intent and the existing generic Lua
policy and ECS system pipeline. The terminal conveys selected spell and
target information; Lua decides legality, cost, range, and effects. `z`
casts with the DCSS spell chooser, `Z` forces target attempts, `M` opens
memorisation, and the spell list, letter assignments, recast, cancellation,
and prompts follow the source-shaped full-terminal client. The UI shows an
explanation when a feature outside this domain remains unavailable.

## Effects and supporting state

Every one of the 125 player-use IDs has an explicit Lua effect registration
or an explicit source-backed redirection to another effect. Boot validation
fails when a required effect is absent. The registry is keyed by IDs in Lua;
adding or overriding an effect requires only a Lua file. Small focused effect
modules are grouped by actual mechanic: zap/projectile, direct damage and
area effects, clouds, summons and persistent constructs, movement,
translocation, buffs and debuffs, forms, necromancy, and terrain changes.
Spell schools remain catalog metadata, not a giant dispatch switch.

The domain includes the reusable Lua status, summon, cloud, and form state
needed by these effects. Mutable dynamic actors and effects use ECS
components; dense terrain and exploration stay on grids. When an effect
requires a generic host operation absent today, add that operation to the
Go kernel without encoding a spell ID or game rule there. Shared line of
sight and projectile geometry may use current kernel services. The
monster-only Freeze and Slug Dart path remains valid, but common primitives
may be reused by both callers without wrapping the old implementation.

The current ASCII-only terrain grid loses source feature identity. Dig and
other terrain spells cannot distinguish diggable rock from permanent walls
through `#`. Convert the grid to stable feature IDs with Lua-defined feature
properties before registering those effects. Render glyphs from the feature
catalog. Do not infer terrain semantics from displayed characters or add a
spell-specific terrain adapter.

Source spell-to-zap mappings are directional and can contain duplicates;
`spl-zap.cc` must not be treated as a one-to-one player spell list. The
player effect registry must also exclude monster-only cases such as
Glaciate and unsafe zap fallbacks such as Drain Life.

## Content, overlays, and readability

The existing source-traced `data/spells.lua` and player-book spell set are
runtime catalog inputs. Any additional generated mappings or effect
parameters are committed under the embedded mod tree with source revision
and path comments. Import scripts are optional developer refresh tools.
Every registered player effect lives in an actual `.lua` file. A same-path
mod overlay replaces it; a new registration may add a spell and effect.
The ruleset checksum continues to identify the exact effective Lua tree.

Keep Lua modules focused and comments useful to a reader locating a source
rule. Prefer 80-character lines, never exceed 120, split multi-field table
literals, and separate validation, calculation, mutation, and emission.
Avoid a central hundreds-of-cases resolver or a table of effect functions
embedded in one huge file.

## Verification

Build a source-derived coverage manifest for all 125 player-use IDs and
assert that each resolves to one effect, while all 190 monster-only, 86
removed, and the debug ID are rejected for player casting. Test learning
legality and delays across species/jobs, source spell-level and MP formulas,
representative effect mechanics in every family, abort/failure/success RNG
and resource order, UI selection and cancellation, overlay replacement, and
save/restore mid-delay and with persistent effects. Use source trace fixtures
for edge cases and deterministic replay. Run category-focused tests during
implementation and the full suite, vet, build, style, importer check, and
diff check once at the category boundary. Commit the entire category as one
coherent change, then merge into local Go `main` after review and verification.

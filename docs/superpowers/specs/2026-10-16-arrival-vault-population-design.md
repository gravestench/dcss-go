# Source-backed arrival-vault population

## Intent and boundary

Every valid monster and item declaration in the committed D:1 arrival
vaults should produce its source-selected game object, including declarations
emitted by a Lua vault handler. Dynamic objects belong to Akara ECS. Vault
authors and modders should edit a `.des` file or an individual content file,
without adding a Go switch or copying an identity into several registries.

This slice covers the complete arrival-vault `MONS`, `KMONS`, `ITEM`, and
`KITEM` expression family and the implicit map glyphs that request monsters
or items. It makes the selected object playable through the existing generic
actor, item, combat, and inventory rules. Monster abilities, spell effects,
and item effects that those rules do not yet implement remain work for their
own full-domain slices. Terrain, marker, colour-tile, and shop interactions
are separate categories. An absent special ability does not turn an otherwise
valid vault monster or item into a pending level record.

The baseline is local Go `main` at `fe9b0e1`, with 339 committed arrival
definitions, 337 selectable arrivals, and 36 named Lua handlers. The source
reference is DCSS commit `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`
under `/Users/dylanknuth/src/crawl/crawl-ref/source`. The relevant source
paths are `mapdef.cc` (`parse_mons_spec`, `parse_single_spec`,
`parse_item_spec`, `pick_monster`, and `pick_item`) and `dungeon.cc`
(`dgn_place_monster` and `dgn_place_item`). The committed `.des` files remain
authoritative at runtime. Import tools run only for deliberate refreshes.

## Expression ownership

Focused Lua modules under `policy/generation/vaults` parse source
declarations into typed choices, then resolve and select them at the point
where the existing placement pipeline knows the chosen glyph, depth, and
source order. The parser owns grammar; catalog lookup owns names; population
owns ECS construction. The current partial `weighted_identity` helper is
replaced by this one route. Neither Go nor a parallel adapter parses the
vault expression language.

The route handles comma-separated slots, slash-separated weighted choices,
`nothing`, explicit `0` random-monster choices, and the source distinction
between a shared keyed `:` choice and an independently chosen `=` choice.
For the pinned arrival family it supports monster colour, attitude, spell
override, equipment after `;`, and item quantity and placement modifiers.
Implicit random monster, out-of-depth monster, random item, good item, and
superb item glyphs use the same resolver. The parser recognizes source
modifiers by name and rejects unknown or malformed modifiers; a source
expression is never treated as a literal catalog name after parsing fails.

Choice weights and slot order follow `mapdef.cc`. Selection uses the
session's named RNG streams and remains deterministic for a Go seed. The
distribution and source draw order are tested; matching the C++ generator's
bit-for-bit seed sequence is not required. A shared choice is drawn once for
its keyed declaration. A per-cell choice is drawn in map traversal order.
`nothing` consumes its choice without creating an entity. Choices requested
by Lua handlers enter the same ordered operation stream as DES declarations.

Static DES expressions are validated when the effective vault catalog
loads. Handler-produced expressions are validated when their branch runs;
tests force every branch in the 36 bundled handlers. A diagnostic names the
effective mod path, vault ID, source line or hook, directive, and expression.
Sparse overlays use the effective DES bytes and effective content catalog.

## Content resolution and random generation

The resolver uses content definitions registered from individual Lua files.
An ordinary name resolves to a stable monster or item ID; any exceptional
source spelling or generated variant is declared beside its owning content
definition or in a focused variant policy. Shared IDs and enums are imported
where used. Source provenance remains a comment beside declarations, never
a required runtime field in a content definition.

Generated monster variants such as zombies and skeletons retain their base
species and variant state on the ECS actor. Corpse and skeleton item specs
create the existing item and `core.corpse` components with the named source
monster. Gold, stones, and other stackable items retain source quantity.
Monster equipment clauses create carried and equipped item entities through
the same item rules used elsewhere. Colour and attitude modifiers become
saved actor state and affect rendering and allegiance. A spell override is
saved as actor state and consumed by monster casting where that capability
exists; an explicit empty override removes the ordinary spellbook.

Random choices draw from Lua-owned, source-backed depth and item-generation
policies. The arrival family needs Dungeon depth, `place:D:1`, ordinary and
out-of-depth monsters, and ordinary, good, and superb item classes. Required
weights or classes are committed Lua content or data, with importers reserved
for upstream refresh. No new source file is read during build or play. Empty
eligible pools and unknown names fail with the source location, rather than
becoming silent pending records.

## ECS and save lifecycle

Population creates monsters and items through reusable Lua factories after
the level grid exists and before ordinary random population. The ordinary
D:1 roster remains a selection rule for ambient spawns, not a whitelist for
authored vault entities. The monster factory accepts every active catalog
definition with a valid spawn profile. It derives baseline HP, speed,
attacks, energy, and content-defined gear without monster-ID branches;
focused capability modules retain special behavior. The item factory applies
the current item schema, stacks, corpse variant, and equipment rules.

Each created entity carries a small Lua-defined vault-origin component:
level, vault ID, placement-record index, occurrence, and original spawn
coordinates. The level record retains the source glyph, directive, original
expression, and coordinates, plus typed arguments for the chosen stable ID
and modifiers; it is marked materialized. A `nothing` result records its
resolved absence and is not considered pending. When a choice intentionally
creates several objects, occurrences distinguish them without requiring a
duplicate level record.

Save validation checks a vault-origin entity against its level record,
resolved identity, saved spawn coordinates, and occurrence. It
checks actor and item components using the ordinary content rules. Vault
monsters count separately from the ambient population budget. Restore uses
the saved ECS entities and records; it never evaluates an expression or
spawns those entities again. Old saves with no vault fields remain readable
under the existing ruleset policy. Corrupt, duplicate, or dangling origins
are rejected. Version 18 remains the format; the new origin component and
record arguments are optional for saves without authored vault entities.

## Failure and extension behavior

Generation fails with a source-addressed diagnostic for an invalid choice,
empty random pool, impossible required placement, or invalid equipment.
An explicit source `nothing` and a source-defined no-spawn result remain
normal outcomes. Placement does not silently fall back to a different
monster or item. A mod can add a vault and content definition through the
layered VFS without editing the base catalog or Go code; its new expression
is validated by the same resolver.

## Verification

Production Lua schemas and catalogs are imported by `_test.lua` tests;
tests do not redeclare them. A table-driven expression suite covers every
authored static declaration and each handler-emitted branch in the 339 DES
files. It checks all source modifiers, weighted boundaries, `:` versus `=`,
slot order, implicit glyphs, random pools, `nothing`, aliases, and malformed
mod inputs. Tests compare parser outcomes with pinned `mapdef.cc` examples.

For every one of the 337 selectable arrivals, deterministic placement
tests assert that each selected monster or item has an ECS entity or an
explicit no-spawn outcome. Integrated tests force examples with monster
equipment, attitude, spell override, corpse variant, stack quantity,
random/out-of-depth identity, and mod-added content. They check client
symbols, pickup or actor interaction, save/restore equality, no duplicate
spawns, and rejection of corrupted origins. The pinned DES importer check,
Go build, vet, style check, and full Go suite close the category.

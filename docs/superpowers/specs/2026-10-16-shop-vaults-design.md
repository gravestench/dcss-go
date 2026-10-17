# Source-backed shop vaults

## Intent and scope

Port the complete pinned shop-vault family while retaining `.des` as its map
format. The family is 69 named definitions in
`crawl-ref/source/dat/des/builder/shops.des` and one in
`crawl-ref/source/dat/des/builder/alphashops.des` at revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. The source files have
SHA-256 hashes `4c5268cca221223c4c3ce8be64caec3f78cfd29327e5bfc0af544383b172132b`
and `235b3fbfa6adf9ac4ec9696894580cfff90afa1a9dd2de5c3680e0f9ddfb9965`.
Every definition is available through the layered mod tree, including helper
maps and maps whose branches are not yet playable. Normal build, launch, and
restore use committed generated files, never the C++ checkout.

This slice makes each shop vault representable, placeable, and saveable. In
the playable D:1–2 game, source eligibility and chance determine shop vault
placement. A dedicated fixed shop scenario remains for predictable UI tests.
Deeper branch generation can call the same selector when those branches
exist. No source shop script is discarded or run through a general DCSS Lua
compatibility environment. Effects not yet implemented stay as typed saved
records, with source location and a specific pending reason. An evidenced
legacy source fault may instead be recorded as an explicit correction.

## Import and discovery

Extend `internal/vaultimport` from its arrival-specific source list to a
small family configuration: source file hashes, output directory, source
ordering, script port recipes, and expected name count. Preserve the arrival
import bytes and CLI behavior. A deliberate refresh splits the shop sources
into `vaults/shop/<name>.des`, one definition per file. Each output retains
ordered DES directives, map rows, source tags, orientation, depth, chance,
weight, and comments giving the pinned source line. The importer checks all
70 names exactly once, rejects duplicate names and unknown directives, and
checks committed bytes without rewriting them. A mod can add or replace one
shop `.des` file by relative path.

The parser and catalog load `vaults/arrival` and `vaults/shop` through the
same effective-file API. Vault IDs remain unique across families. The family
is inferred from the path; it is not a field a mod author must repeat.
`DEPTH` and `CHANCE` become parsed selection data, not ignored prose.
Their syntax covers branch names, depth ranges, branch-bottom exclusions,
and branch-specific chance rows used by these two source files. The empty
`serial_shops` map is a valid post-placement controller. Malformed syntax
reports path, line, and vault name. An added mod vault follows the same
validation and ruleset-hash behavior as bundled content.

The two shared source Lua preludes become focused Lua modules for shop count,
shop-or-temple substitution, alphabetic item lists, and names. Source `:`
lines and eight per-vault `{{...}}` blocks become named hooks at their
original declaration position. Original script text remains as nonexecuting
DES comments next to each hook. The ported handlers use named local
functions assigned to a local handler object that is returned. A sparse mod
may override a handler file independently. The importer pins each rewritten
script span by hash and rejects changed upstream script bytes for review.

## Selection and map placement

Lua chooses vaults by source tags, depth, chance, and weight in stable source
order using a named saved stream. The `serial_shops` controller applies its
source chance for the branch, normally requests one shop map, and sometimes
requests two to five. On supported deeper levels it can also request a
bazaar entry according to the source condition. Generic `extra` shop maps
are eligible through the same extra-vault placement route; untagged helper
maps are selected only by their parent or an explicit test/developer request.
The current unconditional D:2 shop insertion is removed when this route is
live. The fixed shop scenario remains unchanged.

An extra-vault placement fits a transformed source map into the existing
dense grid without overwriting stairs, the player entry, occupied authored
cells, or another shop. It preserves source door, wall, water, terrain,
monster, item, marker, trap, mask, colour, tile, and helper-vault intents.
Any new map geometry is connected to walkable Dungeon terrain. Bounded
deterministic retries handle a valid vault that does not fit at a sampled
location; malformed directives fail with source context. Multiple shop
vaults may share a level, and their records keep distinct source IDs.

## Shop specification and materialization

The keyed `KFEAT` shop expression is parsed in Lua into a typed shop
specification. It supports all active source shop types, `any shop`, weighted
alternatives, `name:`, `type:`, `suffix:`, `count:`, `greed:`, `use_all`, and
the optional item list after `;`. The source `count:` limit of 20 applies to
authored specs. `greed:0` is valid and still yields the source minimum
one-gold quote. The parser distinguishes a shop feature from a normal
terrain feature before terrain decoding.

Authored item choices use the existing item catalog and source-shaped item
generation; they retain weights, quantity, quality, enchantment, ego,
artefact, manual, randbook, and class requests present in this family.
Extend the focused item-spec modules rather than adding a switch in Go or
one giant shop resolver. Resolve random choices once during generation.
The Lua shop generator receives those typed choices, creates original Akara
item entities, and attaches `shop.stock`; it does not copy floor items or
keep stock in a parallel table. If an adjacent item mechanic cannot yet be
played, its authored intent stays in a typed saved record with an explicit
reason until that mechanic lands. Never silently replace it with a generic
item or drop it.

The existing arrival vault and shop runtime remain the only paths for their
respective state. Placement records identify shop cells and their source
specs; population materialization calls `policy.shops.generation.place`.
Terrain becomes `DNGN_ENTER_SHOP`, and the shop entity stores its type,
stock, name, greed, and cell. Revisit, purchase, and terminal rendering use
the existing shop policies. A shop map may include several shop cells.

## Persistence and validation

The final chosen vault IDs, transformed cells, typed placement records,
shop entities, item entities, and named RNG states persist. Restore never
rerolls a vault, shop kind, inventory choice, or script hook. Validate that
every materialized shop record has one shop entity on entrance terrain,
that its stock ownership is exclusive, and that every saved vault ID exists
in the effective ruleset. Ruleset mismatch follows the existing explicit
restore policy. Bump the experimental save version only if the record shape
changes. The source map and handler files both contribute to the ruleset
hash.

## Verification

Importer tests prove all 70 committed files reproduce the pinned sources,
all rewritten script spans have handlers, and one-file overlays can add or
replace a shop vault. Lua `_test.lua` tests cover DES parsing, depth/chance
eligibility, source shop spec modifiers, source script decisions, serial
shop count, extra-vault fitting, and multi-shop placement. Integrated Go
tests cover generated D:1–2 placement across fixed seeds, purchasing from
an authored shop, save/restore continuation, and a mod-added shop vault.
After the whole category, run focused suites, build, vet, style, diff, and
the broad game package. Make one implementation commit for the shop-vault
category and merge verified work into local `main`.

This slice does not add a second runtime item catalog, a Go vault-ID switch,
an old DCSS Lua API shim, or a build-time source import.

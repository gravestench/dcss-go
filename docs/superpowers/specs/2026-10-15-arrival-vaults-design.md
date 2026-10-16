# Source-backed Dungeon arrival vaults

## Intent and scope

Port the pinned DCSS D:1 arrival vault family into the Lua-first Go game.
Keep the original `.des` map format as the authoring format for vaults.
Every vault in the four upstream `dat/des/arrival/*.des` files must be
available through the same layered mod tree as other game content. The
source revision is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
There are 339 named definitions: 337 have the source `arrival` tag and
are top-level candidates; two are helper vaults selected by a parent.
This distinction comes from the source, not a port-specific eligibility
list.

All 339 definitions can be placed. Terrain, stairs, map transforms, and
placement intent must survive. Gameplay effects whose systems have not
yet been ported become typed, saved pending records. They are visible to
the appropriate future system and must never disappear silently. A source
entry may be repaired or omitted only when a specific upstream legacy
fault is documented with evidence. Ordinary builds and game launches use
committed `.des` and Lua files; they do not read the C++ checkout or run an
importer.

## Content import and ownership

A deliberate importer reads the four pinned `.des` files and emits one
`vaults/arrival/<vault-id>.des` file per source `NAME`. This splits the
upstream collection files for one-vault mod replacement while retaining
their DES syntax, ordered declarations, map rows, tags, orientation,
weight, and helper references. The four source files have no shared
executable prelude. Source locations and the path of a ported script
handler are comments beside the vault, not runtime fields. The importer
rejects duplicate names, malformed maps, unknown directives, and source
revision drift. An import audit maps every output back to its exact source
range and records any evidenced legacy corrections.

The pinned files use `NAME`, `TAGS`, `ORIENT`, `WEIGHT`, `MAP`, `CLEAR`,
`SUBST`, `NSUBST`, `SHUFFLE`, `KFEAT`, `KMONS`, `KITEM`, `KMASK`, `KPROP`,
`MONS`, `ITEM`, `COLOUR`, `FTILE`, `RTILE`, `TILE`, `MARKER`, and `SUBVAULT`.
The importer must account for each directive. It also traces the 35
vaults with `:` Lua lines, one additional vault with a `{{...}}` Lua
map-shaping block, and the one `veto` block to their ported Lua
handlers. Source script text remains visible as nonexecuting provenance
comments in the corresponding `.des` file. A short DES `:` hook at the
source position calls the corresponding named Lua handler method. That
method is the only executable implementation of the source rule. The
pinned files have no `CHANCE`, `DEPTH`, or `PLACE` declarations; those
need not be invented for this family.

The layered virtual filesystem accepts `.des` alongside `.lua`, hashes
their effective bytes together, and exposes sorted DES paths and file reads
to Lua. A focused Lua parser reads effective `vaults/arrival/*.des` files
and registers their definitions in a `VAULTS` content category. A mod can
add one `.des` file or replace one at the same relative path. The parser
rejects duplicate vault names across distinct effective paths with both
origins in the error. Validation runs against the effective layered tree,
so a sparse mod may also replace a vault's Lua handler alone. Shared
terrain, item, monster, marker, and directive identities come from focused
`constants` or `ids` modules imported where used.

Executable DES `:` lines accept only literal calls to a named method on
the same vault's Lua handler. The parser evaluates each hook in order,
amid the surrounding DES declarations. A handler may emit typed DES
operations at that point, choose one branch of source declarations, or
record a placement effect. It cannot rewrite earlier operations. For
example, the crop-circle source wraps two `SUBST` declarations in a
`crawl.one_chance_in(5)` branch. The port retains the branch as comments
and replaces the whole branch with one hook; the handler draws once and
emits exactly the chosen `SUBST` operation at that position. Parsing both
`SUBST` lines before calling the handler would change the vault.

An added mod DES file uses the same hook syntax and a matching Lua
handler. Arbitrary inline Lua, raw `{{...}}` blocks, and raw
`veto {{...}}` bodies are rejected
with an actionable error. The source veto becomes a named handler hook
at the veto stage, with its original body retained as comments. The
bundled importer replaces source script blocks only after their handlers
have been ported and checked. No script is silently discarded by the DES
parser.

The 36 arrival definitions containing source Lua receive focused
`policy/generation/vaults/arrival/<vault-id>.lua` handlers. These are
readable production Lua modules: named local functions, one local handler
object, assigned methods, and a returned object. They use the port's
vault context directly. The source script and its line locations remain
traceable in DES comments and importer checks. There is no embedded Lua
in Go or general old-API compatibility layer. The importer reports a
changed source script for explicit handler review during a future refresh.

## Lua generation flow

`policy.generation.vaults` owns selection, transforms, and placement.
Selection uses the source arrival tag, orientation, and weight in stable
source order. The two untagged helpers are selected only by their parent.
The chosen DES definition and handler are resolved from the effective
ruleset; no Go switch or bundled manifest names individual vaults.

The placement pipeline walks ordered DES declarations and handler hooks
as one operation stream. Hooks may insert operations or make choices at
their source position; the pipeline then applies `SUBST`, `NSUBST`,
`SHUFFLE`, keyed features, masks, colours, tiles, items, monsters,
markers, and helper-vault composition. It preserves source order where
RNG or a script can change later operations.
Random draws use named session streams and are deterministic for a seed.
Orientation and map glyphs become typed terrain and placement records.
Source entry connectors are joined to the surrounding generated Dungeon;
the source `{` arrival stair sets the player entry when present. Multiple
stairs and exit hatches retain distinct coordinates and links.

The D:1 generator places the selected arrival as part of level construction
before surrounding rooms and corridors are finalized. It keeps the existing
80×70 dense grid and builds D:2 with matching stair destinations. A
placement attempt that cannot fit or connect is retried with a bounded,
deterministic alternative placement. A genuine malformed source map fails
with vault ID, source path, and operation; it is not silently removed from
selection. Final terrain, entry, stairs, and walkable connections are
validated before the game starts.

## Dynamic content and pending effects

The Go kernel owns the dense terrain grid, stair links, and a small typed
level annotation store. Lua owns vault policy and returns placement records
for items, monsters, traps, altars, fountains, markers, and script effects.
Where current systems can materialize an item or monster, they create an
Akara entity with the source identity and position. No persistent dynamic
entity lives only in an unsaved Lua module table.

When an effect lacks a gameplay system, the level keeps a typed pending
record with its source identity, location, arguments, and activation hook.
The record remains through save and restore and has an explicit unavailable
interaction where applicable. Later domain slices consume these records
without reimporting vaults. The client renders terrain and placed objects
with available symbols; missing art or behavior never changes the stored
identity. Save validation rejects malformed annotations and unknown
locations, while allowing old saves without vault fields to load under
their existing ruleset policy.

## Verification and extension contract

Importer tests compare all 339 names, ordered directives, map rows, tags,
weights, script links, and source anchors with the pinned files. For
script-controlled directives, they compare each possible emitted branch
and its position in the operation stream. Virtual filesystem tests
confirm `.des` overlay, hash, and save identity behavior.
Lua `_test.lua` files exercise production schemas and selection/transform
code, including every directive family, all 36 handlers, the two helper
vaults, and mod additions and replacements. Integrated tests force each
of the 337 top-level vaults through placement with deterministic seeds.
They validate terrain bounds and stair connectivity and compare placement
records before and after save.
They also verify that pending records survive and that a changed mod file
changes the effective ruleset identity.

Handwritten Go and Lua stay below 120 columns, preferably near 80. Large
declarations use one field per line. Each Lua module has a focused purpose;
the implementation must avoid a growing vault-ID dispatch table. The
split `.des` files are committed generated sources. Refresh tools run only
on deliberate upstream updates.

This slice makes every arrival vault representable and placeable. It does
not claim that unported shops, traps, altars, clouds, or other item and
monster effects already have full gameplay behavior. Their typed pending
records are the explicit handoff to those upcoming whole-domain slices.

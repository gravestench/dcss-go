# Source-backed traps

## Intent and boundary

The Go port needs traps that are understandable and extensible from Lua. A
modder should be able to add a trap definition and its effect without changing
Go code or a central ID switch. The pinned DCSS source at
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f` defines the rules in
`trap-type.h`, `traps.cc`, `trap-def.h`, `dungeon-feature-type.h`, and the
vault parser. This slice covers the ten active trap types in that revision:
teleport, permanent teleport, alarm, net, Zot, shaft, Golubria passage,
pressure plate, web, and dispersal. The nine version-34 legacy types that
`is_removed_trap` rejects are not playable traps.

The current D:1–2 game must preserve seeded turns, full-terminal display,
layered mods, ECS state, and round-trip Go saves. A vault's authored trap
must become an active in-game trap instead of a pending feature record.
Unknown or malformed trap content must fail with its effective mod path or
vault source location. The C++ checkout is used only for deliberate source
refreshes and verification, never during a normal build or game.

## Chosen structure

There are three workable ownership models. Putting trap types directly in
the Go terrain enum would keep rendering simple but would add game rules to
the kernel. Storing every trap as an opaque level record would avoid entity
creation but would create another mutable-state path beside Akara. The chosen
model uses a discoverable Lua definition and effect file for each active
type, with a saved Akara trap entity carrying its position, charges,
visibility, and source origin. The dense grid stays the owner of underlying
terrain and exploration. A trap entity can coexist with actors and items on
its floor cell.

`content/traps/<id>.lua` registers one immutable definition with the source
ID, display name, glyph, generation eligibility, and activation policy.
`policy/traps/effects/<id>.lua` supplies its executable effect. Shared Lua
policy handles placement, visibility, dispatch, and save validation. The
loader discovers new files through the existing layered VFS; there is no
central trap manifest or Go switch. A mod may replace one effect file or add
a new trap definition plus effect. The ruleset hash includes those files.

The trap component records `kind_id`, `level_id`, `x`, `y`, `charges`,
`revealed`, and optional source-record identity. The position is also exposed
through the existing `core.position` component so generic spatial queries
and save validation can find it. Trap entities do not enter the actor
occupancy index. A destroyed trap removes its components/entity and restores
the cell's remembered floor feature when applicable. It never destroys an
item or actor sharing that position.

## Placement and activation

Vault `KFEAT`/map-glyph trap expressions resolve through the effective trap
catalog. Weighted alternatives are rolled exactly once during generation.
`^` requests a regular trap from the source's eligible set. Explicit source
features preserve their exact identity, including permanent teleport, web,
and shaft. Source paths and coordinates remain on the entity's origin so a
bad definition names the vault location. `no_trap_gen` prevents ambient
placed traps for that vault, while explicit authored traps remain.

The pinned source's ordinary random hazard is a separate malevolence check
for newly visible cells (`traps.cc:1075–1248`, `view.cc`):
`trap_rate_for_place` determines the rate, then an eligible
teleport/shaft/alarm effect is selected without placing a persistent trap.
The check runs after a player move exposes new cells. Failed movement,
waiting, and re-seeing mapped cells do not reroll it. Eligibility follows
branch/depth rules; on the current D:1–2 slice it cannot roll alarm.

A placed trap activates when an actor actually enters its cell. The source
line-of-sight and translocation rules apply. An effect may move the actor;
the dispatcher prevents accidental recursive reactivation unless the source
explicitly permits it. Charges and destruction are updated atomically with
the turn. Monsters use the source avoidance rules where their intelligence,
allegiance, and branch origin are known. Missing required actor data fails
at the content boundary rather than silently skipping an effect.

The ten effects live in focused Lua modules. Teleport and dispersal reuse the
existing movement policies; shaft uses world travel; Golubria uses saved
passage links; net and web use the held state; alarm uses the world noise and
marking policies; pressure plates dispatch position events to vault markers;
Zot uses the pinned weighted effect table and existing status, summons, and
terrain capabilities. Any generic engine operation those effects need must
be exposed as a small reusable service rather than a trap-specific Go
handler. Legacy source traps have an explicit invalid/removed outcome and
never become active entities.

## Display, persistence, and validation

Lua presentation overlays the source `^` glyph on a revealed trap without
replacing its underlying terrain. Hidden traps draw as ordinary terrain;
exploration remembers a revealed trap and forgets a destroyed one. The
description/help path uses the same registered definition, so a modded trap
has one name. Trigger messages follow source wording where the effect is
implemented; an unknown effect never becomes a silent no-op.

The save codec persists trap entities, their source origins, one-shot charge
state, passage lifetime, and any held/mark effects they cause. Restore rejects duplicate
active traps on one cell, out-of-bounds or blocked positions, unknown kinds,
invalid charges, mismatched position fields, and dangling passage or vault
references before play resumes. Restoring a level does not reroll placement,
malevolence, or the effect table. Save version changes only if the Go snapshot
shape requires it; dynamic Lua components remain schema-versioned.

## Verification and completion

Lua `_test.lua` tests import production definitions and policies. They cover
all ten active IDs, removed-ID rejection, vault alternatives, depth limits,
charges, actor/visibility gates, effect draw boundaries, and mod additions.
Integrated Go tests cover authored arrival traps, player and monster entry,
held-state release, travel/teleport effects, UI glyphs, save/restore, ruleset
hash changes, and deterministic continuation after restore. Run the relevant
Lua and Go suites, source consistency checks, build, vet, style, and diff
checks after the entire trap category is implemented. Make one implementation
commit for the contiguous category, then merge it into local `main`.

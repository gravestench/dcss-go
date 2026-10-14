# Lua-first ECS architecture roadmap

The Go port's end goal is a faithful, extensible DCSS whose game-specific
behavior is written and registered in Lua. This roadmap supersedes the
previous Go-rule migration sequence. The design contract is in
[the Lua-first runtime spec](superpowers/specs/2026-10-14-lua-first-mod-runtime-design.md).
The pinned C++ reference is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
The default Lua rules remain source-traced to that revision. The primary Go
branch is `main`; the unfinished early melee-brand branch is preserved as WIP
and does not define the new architecture.

## Target boundary

Go owns the reusable kernel: Akara world and runtime component storage,
deterministic system scheduling, entity lifecycle barriers, dense grid and
spatial services, named RNG streams, save codec, Lua VM and virtual filesystem,
terminal I/O and drawing primitives. It should have no growing switch over
DCSS species, jobs, monsters, brands, spells, items, or branches.

Lua owns game definitions and rules: component schemas, ECS systems, character
creation and advancement, item use, combat effects, monster decisions, map
generation, branch policy, commands, keymaps, and screen policy. Registered
behavior reads and changes authoritative Akara state through a narrow host
API. Static source content is committed as Lua modules; developer importers
regenerate it only for intentional upstream refreshes.

The bundled Lua tree is embedded in the executable. One optional overlay
folder replaces matching relative paths and adds new files. The effective
path-and-byte SHA-256 manifest identifies the exact ruleset. Exact bundled
bytes count as vanilla even when copied into an overlay. Saves record the
effective hash and dynamic schema versions; changed rules require an explicit
opt-in or migration on restore.

## Current implemented slice

The playable Go slice includes four Fighter species, a source-shaped terminal,
D:1-2 terrain and population, Akara actors/items/status, basic melee,
projectile and spell intents, equipment, training, XP, and Go saves. Source
content is committed as Lua gameplay data and source-traced JSON import
artifacts. No normal build uses the C++ checkout. Implemented gameplay rules
now execute from the embedded Lua tree; Go owns generic engine services.

Akara v0.1.4 already has `RegisterSchema` and dynamic component stores. Lua
can register new schema-backed components without a Go type declaration.
Dense terrain and visibility stay grid services rather than tile entities.
Mutable state on actors and items remains in Akara, whether the schema was
originally Go-defined or Lua-defined.

The Lua runtime registers all 43 species and 31 jobs from per-definition
files. Character choice, four playable Fighter starts, combat, equipment,
statuses, monster behavior, generated floors, save semantics, and screen
policy use Lua. Other aggregate source content is committed as generated
Lua modules. One generic typed-store context exposes authoritative Akara
state to those rules. The
[one-pass conversion contract](superpowers/specs/2026-10-14-one-pass-lua-gameplay-design.md)
sets the boundary for this implementation.

## Conversion coverage

The implemented parts of categories 2–6 moved in one sweep. These categories
are an audit checklist for future work, not adapter milestones. Category 7
extends the game beyond the present D:1–2 slice.

1. **Mod runtime foundation.** Embed the Lua tree, resolve one overlay by
   relative path, hash the effective files, bootstrap a per-game Lua VM,
   register Lua component schemas and ordered systems with Akara, and persist
   dynamic component state and ruleset identity. A real game action must run
   an overlay-defined system before this phase is complete.
2. **Character domain.** Species/job catalogs, choice policy, and four
   playable Fighter starts now live in Lua. Add remaining starts as complete
   rules with their equipment, spell, and religion needs. Keep generated
   definitions committed as small Lua modules.
3. **Item and status domain.** Playable item use, equipment policy, poison,
   haste, might, curing, regeneration, and timed statuses use Lua systems.
   Add more items and effects as complete Lua rule slices. Akara components
   remain authoritative through creation, decay, removal, and saves.
4. **Attack intent domain.** Implemented melee, launched, thrown, and spell
   intents use Lua capability, resolution, and effect modules. The Go kernel
   has no monster-ID or brand-ID effect switch. Expand the complete effect
   families before admitting more monsters to generated floors.
5. **Monster and world domain.** Existing monster decisions, inventories,
   spawns, generated population, level layouts, and travel use Lua. Add
   further branches, vaults, and generation in Lua. Go continues to provide
   grids, occupancy, pathfinding, visibility, and transactional movement.
6. **Client and policy domain.** Current command policy, messages, screen
   layout, and unavailable-feature handling use Lua. Expand keymaps and
   screens there while Go keeps Bubble Tea/Lip Gloss terminal mechanics.
   Preserve the full-terminal DCSS presentation and minimum 79×24 layout.
7. **Remaining DCSS domains.** Add religion, mutations, forms, allies,
   shops, traps, clouds, runes, endgame, and full branch/content coverage as
   whole Lua domain slices. Extend the Go kernel only for reusable capability
   primitives that cannot be expressed cleanly through the existing API.

## Slice checks

At the integrated conversion boundary, verify deterministic turn and RNG
continuation, round-trip saves of authoritative state, exact ruleset
identity, stable system order, and source-shaped behavior for the supported
features. Use representative whole-flow tests plus focused tests for unusual
source rules. Run full Go test, vet, build, style, and diff checks after the
broad sweep. Review the whole branch before merging to local `main`. Update
[the port inventory](port-inventory.md) with precise playable coverage.

## Readability contract

A modder should find a rule from its Lua registration and change it without
tracing a Go content dispatcher. Keep domain files small enough to read in
one sitting. Use names that reveal game concepts, separate validation,
calculation, mutation, and event emission, and cite pinned C++ source for
unusual rules and roll order. Handwritten Go lines have a hard 120-character
limit and prefer 80. Multi-field literals use one populated field per line;
Lua tables follow the same spirit. Comments explain ownership and invariants,
not obvious statements. `AGENTS.md` carries the repository-wide style rules.

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

## Current state at the pivot

The playable Go slice includes four Fighter species, a source-shaped terminal,
D:1-2 terrain and population, Akara actors/items/status, basic melee,
projectile and spell intents, equipment, training, XP, and Go saves. Source
content is committed mainly as JSON under `internal/content/generated`; each
normal build uses that committed content without the C++ checkout. Gameplay
behavior is still mostly Go. The current `combatSystem` and monster decision
system are becoming difficult to extend because they route by content IDs.
Those rules should move to Lua as whole intent and domain slices rather than
accumulating more Go cases.

Akara v0.1.4 already has `RegisterSchema` and dynamic component stores. Lua
can register new schema-backed components without a Go type declaration.
Dense terrain and visibility stay grid services rather than tile entities.
Mutable state on actors and items remains in Akara, whether the schema was
originally Go-defined or Lua-defined.

The Lua runtime foundation is complete. The first character category now
commits all 43 species and 31 job definitions as embedded Lua files and moves
choice bans, recommendations, and current start support into a Lua policy.
The terminal and game project the effective Lua catalog. Starting gear,
attributes, skills, HP/MP, XP, and advancement are still Go rules for the
four playable Fighter starts. Their Lua migration belongs with the full
item, spell, and religion capabilities needed by the other jobs.

## Migration sequence

Each numbered phase is a coherent category. A phase can temporarily break
compilation on its branch while the old path is replaced. Commit when the
category works, rather than making one commit per monster or one effect. Keep
one authoritative execution path per migrated behavior.

1. **Mod runtime foundation.** Embed the Lua tree, resolve one overlay by
   relative path, hash the effective files, bootstrap a per-game Lua VM,
   register Lua component schemas and ordered systems with Akara, and persist
   dynamic component state and ruleset identity. A real game action must run
   an overlay-defined system before this phase is complete.
2. **Character domain.** Start with the full species/job catalogs and choice
   policy as one content category. Then move complete start construction,
   equipment, attributes, skills, HP/MP, XP, and advancement policy as a
   coherent rules category once item, spell, and religion services exist.
   Keep source-generated definitions committed as small Lua modules and
   remove each corresponding Go rule path when its domain is fully migrated.
3. **Item and status domain.** Move all currently playable item use,
   equipment policy, poison, haste, might, curing, regeneration, and timed
   status behavior to Lua systems. Akara components remain authoritative;
   status creation, decay, removal, and save continuation use one path.
4. **Attack intent domain.** Move all implemented melee, launched, thrown,
   and spell intent behavior into Lua capability, resolution, and effect
   modules. Shared hit geometry and dice primitives may remain Go services.
   No monster-ID or brand-ID switch remains in the Go kernel. Complete
   reachable early humanoid effects and their world consequences before
   admitting those monsters to generated floors.
5. **Monster and world domain.** Move monster decisions, inventories, spawn
   policy, generated population, level layouts, branch travel, vaults, and
   map generation to Lua registrations. Go continues to provide grids,
   occupancy, pathfinding, visibility, and transactional movement services.
6. **Client and policy domain.** Move game command policy, keymaps, messages,
   screen layout decisions, and unported-feature handling into Lua while Go
   keeps Bubble Tea/Lip Gloss terminal mechanics. Preserve the full-terminal
   DCSS presentation and minimum 79×24 layout.
7. **Remaining DCSS domains.** Add religion, mutations, forms, allies,
   shops, traps, clouds, runes, endgame, and full branch/content coverage as
   whole Lua domain slices. Extend the Go kernel only for reusable capability
   primitives that cannot be expressed cleanly through the existing API.

## Slice checks

At each category boundary, verify deterministic turn and RNG continuation,
round-trip saves of new authoritative state, exact ruleset identity, stable
system order, and source-shaped behavior for the supported features. Use
representative whole-flow tests plus focused tests for unusual source rules.
Run full Go test, vet, build, style, and diff checks once at the coherent
category boundary. Review the whole branch before merging to local `main`.
Update [the port inventory](port-inventory.md) with precise playable coverage.

## Readability contract

A modder should find a rule from its Lua registration and change it without
tracing a Go content dispatcher. Keep domain files small enough to read in
one sitting. Use names that reveal game concepts, separate validation,
calculation, mutation, and event emission, and cite pinned C++ source for
unusual rules and roll order. Handwritten Go lines have a hard 120-character
limit and prefer 80. Multi-field literals use one populated field per line;
Lua tables follow the same spirit. Comments explain ownership and invariants,
not obvious statements. `AGENTS.md` carries the repository-wide style rules.

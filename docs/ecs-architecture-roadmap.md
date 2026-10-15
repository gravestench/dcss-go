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

Akara has `RegisterSchema` and dynamic component stores. Lua
can register new schema-backed components without a Go type declaration.
Dense terrain and visibility stay grid services rather than tile entities.
Mutable state on actors and items remains in Akara, whether the schema was
originally Go-defined or Lua-defined.
Lua component schemas support homogeneous lists and string-keyed maps of
the six scalar field types. Akara validates and copies collection values at
store boundaries; the Lua bridge enforces dense list and typed map shapes,
and the save codec restores typed elements and validates entity references.
This allows branch clocks and other keyed game state to have one ECS owner.

The Lua runtime registers all 43 species and 31 jobs from per-definition
files. Monsters, spells, items, branches, and monster spellbooks now use the
same per-file registration path. Character choice and the pregame menu read
the registered Lua tables directly; normal launch no longer loads the
parallel Go content catalog.
Four playable Fighter starts, combat, equipment, statuses, monster behavior,
generated floors, save semantics, and screen policy use Lua. Remaining
aggregate source content is committed as generated Lua modules. One generic typed-store
context exposes authoritative Akara state to those rules. The
[one-pass conversion contract](superpowers/specs/2026-10-14-one-pass-lua-gameplay-design.md)
sets the boundary for this implementation.

## File-based extension contract

The effective mod tree auto-loads new files under `schemas/`, `content/`,
`policy/`, `systems/`, `generation/`, and `ui/`. Content files register one
definition in `content/<category>/`; registration works for bundled and
overlay files alike. A matching relative path replaces a bundled file. A
different path adds content, and duplicate category/ID pairs fail with both
file origins. The effective source bytes set the vanilla hash and save
identity. There is no central list to edit when adding a definition.

Treat this as an extension contract, not just a way to package the port.
Any new content or behavior must become discoverable by placement in its
domain directory. A mod should never need to edit a central ID table, Go
switch, or bundled manifest. A user can supply a directory containing only
one new file. The same loader and validation run for bundled and user files.
The runtime validates the complete effective content tree before gameplay
policy runs, so a new file may refer to another file loaded later.

Static definition and executable behavior are separate. A new monster file
makes the monster available to Lua catalogs and shared ID imports. Spawn
data may live in that definition; special actions use discoverable Lua files.
A spell needs its effect rule, and an item type needs its interaction rules. This
lets a mod introduce a simple data variant in one file and a new mechanic
with a small set of files, while keeping each file's purpose obvious. See
[modding.md](modding.md) for the exact directory and registration contract.

The next architecture work is to turn the remaining aggregate categories
into per-file content where mod authors would reasonably extend them:
population entries, item identity and starting gear, vault templates, and
presentation data. The generated files stay committed. Import tools run
only during deliberate upstream refreshes. New mechanics must be wired
through Lua discovery and generic engine capabilities, not a Go ID switch.

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
   all 17 active potions, regeneration, and timed statuses use Lua systems.
   Each potion has a discoverable Lua effect. Lasting buffs, tree form, and
   pending skill experience use saved Akara state consumed by live rules.
   Add other item classes as complete Lua rule slices; item identification
   and religious conduct still need their respective domains.
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
7. **Remaining DCSS domains.** Complete the mutation source audit, then add
   religion, unported forms, allies,
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

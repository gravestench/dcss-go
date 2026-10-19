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
API. Ported source content is committed as Lua modules and maintained there.

The bundled Lua tree is embedded in the executable. Ordered optional overlay
folders replace matching relative paths and add new files. The effective
path-and-byte SHA-256 manifest identifies the exact ruleset. Exact bundled
bytes count as vanilla even when copied into an overlay. Saves record the
effective hash and dynamic schema versions; changed rules require an explicit
opt-in or migration on restore.

## Current implemented slice

The playable Go slice includes every legal selectable species/job start, a
source-shaped terminal,
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
All legal selectable starts, combat, equipment, statuses, monster behavior,
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

Arrival vaults now exercise this extension path end to end. Lua parses the
committed `.des` monster and item declarations, resolves IDs through the
effective per-file catalogs, and creates actors, carried gear, corpses, and
floor items as Akara entities. A saved `vault.origin` component identifies
the source record for each live entity. A mod-added monster file is eligible
for a mod-added arrival without a Go switch or central registration edit.
Generation resolves random requests once; restore validates saved entities
and records without rerunning Lua generation.

Static definition and executable behavior are separate. A new monster file
makes the monster available to Lua catalogs and shared ID imports. Spawn
data may live in that definition; special actions use discoverable Lua files.
A spell needs its effect rule, and an item type needs its interaction rules. This
lets a mod introduce a simple data variant in one file and a new mechanic
with a small set of files, while keeping each file's purpose obvious. See
[modding.md](modding.md) for the exact directory and registration contract.

Species and job menu text and ordering now live in their respective content
files. The unused item identity Lua aggregate has been removed; the source
identity artifact remains for import validation. The next ownership work
targets vault templates. All 178 imported monster weapon specs now live in
their owning monster files, and active gear handlers are discoverable Lua
modules. The generated files stay committed.
The initial C++ import tools have been retired. New mechanics must be wired
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
2. **Character domain.** Species/job catalogs, choice policy, and every legal
   selectable start live in Lua. Each job file owns its fixed grants; special
   starting gear rules are discoverable Lua files. Add later job abilities
   as complete rules. Keep generated definitions committed as small Lua
   modules.
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
   runes, endgame, and full branch/content coverage as
   whole Lua domain slices. Extend the Go kernel only for reusable capability
   primitives that cannot be expressed cleanly through the existing API.

The trap domain now uses one Lua file per definition and effect, a saved
Akara entity for each placed trap, and Lua systems for entry, timers, and
malevolence. Pressure-plate marker consumers, the rest of the vault families,
and deeper monster trait parity remain in the adjacent world domains.

The monster beam domain now has 70 committed source profiles and one
discoverable Lua effect per spell. A typed intent retains the chosen actor or
cell, book slot, and direction; the actor-neutral Lua beam rules handle
trajectory, shields, reflection, damage, resistance, clouds, terrain, and
saved statuses. Targeted hexes share that trace but apply their own
willpower, immunity, and persistent actor rules. Monster spell coverage
rejects missing effects before a monster joins the live roster. The 13
self-support spells now use actor-owned Lua statuses for boons, healing,
defenses, and auras. Elemental breath rays use natural monster HD; source
caster exceptions for draconian cold breath and Xtahua's searing breath stay
in their owning Lua effect modules. Fragment rays share source triple-armour
contact handling while keeping their damage and accuracy in separate profiles.
Flaming, Petrifying, and Spectral Cloud place saved ray-cell clouds through
the Lua cloud owner; Flaming and Spectral Cloud also place endpoint fields.
Ink Cloud uses the same owner for its water-only self cast.
Chaos and spells share the same Haste and Might state.
The four ally-targeted support spells now select a genuine allied recipient
through a beam ray and write those same saved boon, enchant, and health
owners. The thirty-nine direct-creature monster summons now use one
actor-neutral Lua creator and focused spell files. Named attitude and
caster-owned Invitation and Brothers state live in saved Akara components.
Eight Blink effects use a shared Lua landing owner and move existing Akara
actors through the grid service. Word of Recall uses a caster-owned Lua
component and active system for its chant and cooldown; no Go spell branch
or Lua module global holds its timer.
Allied monster AI now selects visible enemy actors for spellbook casts. The
spell intent saves that foe separately from its entity, cell, or self plan;
resolution validates the live enemy before applying an effect. Freeze,
Petrify, and Slug Dart use the monster victim's own resistance, status, and
defense, while offscreen and invisible outcomes stay out of player messages.
Other spell families still need actor-target audits before every allied
spellbook can safely cast against monsters. Foe-centered spells carry a cell
through the typed intent so target movement cannot redirect an already
chosen cast. The current Dungeon roster supplies
Shadow Creatures; other branches need their own population owner, and Pan
needs a saved local demon allocation. Constructs, clones, terrain actors,
and remaining monster spell families still need complete rule slices before
wider monster rosters become playable.

The cloud domain now uses discoverable Lua definitions and focused effect
modules for all 34 concrete source kinds. Saved Akara entities represent
cloud cells and temporary terrain; Lua controls placement, exposure,
avoidance, aging, and view metadata. World capabilities for sanctuary,
wind, and terrain-destruction veto remain adjacent integration work.

The shop domain follows the same ownership boundary: Lua definitions supply
the ten active shop types, Lua policies own pricing, stock generation, and
purchase rules, and Akara owns the wallet, shop, stock, and shopping-list
state. Go supplies the grid entrance, save encoding, and terminal canvas.
All 70 source shop vault definitions now use the layered `.des` catalog.
Focused Lua handlers port source scripts, and Lua parses authored stock into
the existing Akara shop policy. Supplemental selection and placement use the
same grid and source-record path as arrival vaults. Deeper branch generation
can reuse these definitions without another shop implementation. Replace the
temporary generic extra-vault frequency with selection from the full source
secondary-vault pool once the remaining families are imported.

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

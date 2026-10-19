# Lua-first game and mod runtime design

## Intent

Make Dungeon Crawl easy to extend without editing or recompiling Go for ordinary
game rules. Lua is the first-class language for registering component schemas,
ECS systems, monsters, items, spells, maps, generation, commands, and game
policy. A complete embedded Lua tree ships with the game. A user may supply an
overlay directory whose files replace embedded files at the same relative path
and whose additional files can define new content. The runtime identifies the
exact effective ruleset and whether it is byte-for-byte the bundled ruleset.

The Go port remains faithful to the pinned DCSS source for its default rules.
Developer-run C++ importers may regenerate committed Lua content during an
intentional source refresh. Normal builds and play never read the C++ checkout.
The terminal client remains full-sized and source-shaped; Lua may define
screen policy and presentation data while Go owns terminal I/O and rendering
primitives.

## Approaches

- Lua definitions with Go effect handlers would make data editable but leave
  every new behavior behind a Go code change. This misses the extension goal.
- Moving the ECS store, scheduling, maps, saves, and terminal backend into Lua
  would make deterministic state and performance harder to maintain.
- **Chosen:** a small Go kernel exposes stable ECS, grid, RNG, event, save,
  rendering, and virtual-file services. Lua owns game-specific registrations
  and behavior. The kernel knows no monster, brand, spell, job, or branch ID.

## Ownership and runtime

`internal/modfs` embeds `internal/modfs/builtin/` as the Lua root and layers
one optional overlay directory on it by relative path. `internal/script` owns
one Lua VM per game session, its module loader, registration API, and bridge
from Lua component declarations to Akara runtime schemas. `internal/game`
becomes a thin session coordinator: it owns the Akara world, level/grid
services, named RNG streams, action queue, and effective ruleset descriptor.
`internal/terminal` owns Bubble Tea/Lip Gloss mechanics and draws a read-only
screen model supplied by Lua presentation policy. Go retains pure algorithms
when they are genuinely generic services, such as pathfinding, visibility,
line tracing, dice primitives, and grid indexing. Game-specific formulas,
chances, restrictions, effects, and messages belong in Lua.

Lua bootstrap has two phases. First, the loader resolves the effective file
tree and runs a declared entrypoint that registers schemas, definitions, and
systems. The host validates unique names, required fields, referenced IDs,
and system ordering, then freezes registration for the run. Second, gameplay
invokes the registered callbacks through a narrow context. A callback can
read or write declared components, query entities, inspect a level, consume a
named RNG stream, emit events, or enqueue structural/spatial commands. It
cannot retain unsaved mutable game state in module globals as an authoritative
source. Persistent state belongs in Akara components or explicit serializable
level/session stores. The runtime executes callbacks serially in deterministic
registration order; game-rule callbacks do not run concurrently.

A Lua component registration supplies a stable namespaced name, schema
version, fields, types, and defaults. Akara `RegisterSchema` already supports
runtime component registration. The Lua bridge validates and converts values
and exposes entity handles without losing 64-bit identity. Component records
and schemas are included in saves. Schema changes require an explicit Lua
migration keyed by prior version; the host does not guess how to reinterpret
old records. Structured values that Akara's current primitive field kinds
cannot represent remain an explicit kernel extension, not an opaque Lua table
hidden from the save system.

A Lua system registration supplies a stable name, query, and ordering
constraints. The host resolves a deterministic acyclic order and registers
Akara system callbacks in that order. Systems can be added by an overlay
without editing Go. Item use, spell cast, status decay, monster decisions,
attack effects, generation, and branch policy are ordinary Lua modules built
on the same public API, not one Go dispatcher with a case per content ID.
There are a few explicit lifecycle barriers for structural changes, so Lua
callbacks cannot invalidate the active query while it is being iterated.

## Lua dialect and host boundary

Use the pure-Go GopherLua runtime at a pinned release for the first
implementation. It implements Lua 5.1 syntax with a small 5.2 extension,
keeps the game build free of a native Lua dependency, and has a documented Go
embedding API. The default mod tree declares this dialect. The host never
passes raw Akara pointers or 64-bit entity IDs as floating-point Lua numbers;
entity handles are validated userdata. Integer component writes are checked
for exact range at the API boundary. If a later runtime supports a newer Lua
dialect, it must preserve the same registration and save contract and identify
its dialect in the ruleset metadata. Scripts cannot import arbitrary Go
packages through the VM.

## Embedded files and overlays

The bundled tree has `init.lua` and domain-organized Lua modules under
`schemas/`, `content/`, `systems/`, `generation/`, and `ui/`. The default
entrypoint loads those trees in that order, with paths sorted within each
tree. A new file in one of those trees is therefore discovered and registered
without editing an index. Helper modules live under `lib/` and load only when
required. The overlay may replace `init.lua` too. Generated source
definitions are committed as small Lua modules under `content/`; handwritten
rules and mod APIs live in separate directories. Namespace IDs let a modder
locate one definition without reading a giant generated catalog. Importers
continue to record pinned C++ revision and source locations in generated
definitions. They run only when a developer requests an upstream refresh.
Lua programs in tests also live in actual `.lua` files under test mod
directories; Go never carries inline Lua source strings.

At startup, the loader inventories embedded and overlay `.lua` paths. A valid
overlay path replaces the embedded bytes at exactly the same relative path.
An overlay-only path is added. The loader rejects traversal, ambiguous case
collisions, symlink escapes, duplicate module identities, and unsupported file
types. `require` resolves only this effective virtual tree. The effective
`init.lua` controls domain order, and the loader sorts each tree by normalized
relative path. Directory enumeration order never affects registration or RNG.
A mod can add a file to a discovered domain tree or require a helper module
from its own file. This initial design supports one overlay directory; multiple
mod packs can later be composed by an explicit ordered manifest without
changing the ruleset-hash format.

For each effective Lua path, the loader computes SHA-256 of the bytes. It then
hashes the sorted sequence of `(relative path, file hash)` pairs to form the
**effective ruleset hash**. The same calculation over embedded files gives
the **bundled hash**. Equal hashes mean the effective Lua files are identical
to the bundled set, even if an overlay contains a byte-identical copy. A
changed or extra file changes the hash. The game exposes the hash, a vanilla
flag, and a readable list of changed/added paths in its startup and save
metadata. This identifies the loaded Lua tree; it is not an anti-cheat claim
about the binary or external environment.

## Saves and determinism

The Go save format records the engine version, effective ruleset hash, Lua
schema names and versions, authoritative Akara state, level/session state,
and named RNG stream states. Loading the exact same ruleset restores normally.
A different ruleset requires an explicit user opt-in or a registered migration;
it never silently reinterprets state. The mismatch report names the saved and
current hashes and changed paths when the saved manifest is available.

Lua does not receive direct wall-clock, process filesystem, network, or
unseeded random APIs during simulation. `math.random` is replaced or removed;
all chance draws use host-named streams. Query and registration traversal
order is stable. Tests prove that save/restore and replay of the same command
sequence produce identical state and events under the same ruleset.

## Migration strategy

Do not add more Go case dispatch for game content while building this seam.
Freeze the current melee-brand branch as WIP. Start the Lua runtime from Go
`main` on an isolated branch. The first implementation category establishes
the effective virtual filesystem, hash reporting, VM/module loader,
Lua-defined schemas and ordered systems on Akara, and save persistence for
their state. It ships with a tiny embedded ruleset and an overlay test that
changes a system, not just a static label. Then migrate **whole domains** into
Lua: character creation and progression;
items/equipment/use; all currently implemented attack intents and effects;
monster decisions and spawning; level generation/branch travel; UI policy.
Each migration removes the Go rule path it replaces in the same category.
No temporary compatibility layer is kept solely to preserve intermediate
compilation. Existing source-traced JSON may remain as importer intermediate
material while generated Lua modules replace it as the runtime authority.

## Acceptance

A modder can add a component, register a system that uses it, define a new
item and spell, override an existing rule file, and add a map generator using
Lua alone. No Go recompilation is needed for the overlay. The game reports
vanilla for exact embedded bytes and modded for any changed or added Lua path.
A save resumes with the same ruleset and refuses silent loading against a
different one. Default Lua reproduces the currently playable DCSS slice with
source-traced behavior and deterministic continuation. The Go kernel contains
no growing switches keyed by game content IDs, and a reader can locate an
ordinary rule from its Lua registration rather than tracing Go dispatchers.

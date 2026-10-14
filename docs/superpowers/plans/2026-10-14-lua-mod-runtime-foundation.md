# Lua mod runtime foundation implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. This plan is one
> coherent runtime category and ends in one commit after integrated tests.

**Goal:** Ship an embedded, overlayable Lua runtime that can register Akara
component schemas and ordered systems, run them in a game, and preserve their
state and exact ruleset identity in saves.

**Architecture:** The effective Lua tree is built from embedded files and one
optional directory. A per-game Lua VM registers schemas and system callbacks
through a small host API. Akara owns dynamic component state; the Go game
session owns the VM, deterministic scheduler, RNG, and save barrier.

**Tech Stack:** Go 1.25, Akara v0.1.4 dynamic schemas, GopherLua v1.1.2,
`embed.FS`, SHA-256, existing Go save codec and Bubble Tea client.

**Spec:** `docs/superpowers/specs/2026-10-14-lua-first-mod-runtime-design.md`.

## Global constraints

- Game rules and content IDs are registered in Lua; the Go kernel does not
  add per-monster, per-item, per-spell, or per-brand dispatch.
- The bundled Lua tree is committed and embedded. An overlay uses identical
  relative paths to replace files and may add new files.
- All Lua source, including test fixtures, lives in `.lua` files in mod
  directories. Go code never contains inline Lua programs.
- Byte-identical overlays count as vanilla; changed or added Lua paths do not.
- Lua simulation state is serializable ECS, level, or session state; module
  globals are not authoritative saved state.
- All integer conversion, entity identity, and schema writes are checked.
- Existing game behavior and named RNG draw order remain unchanged in this
  foundation category.
- Handwritten Go and Lua are organized for human readers, with source and
  ownership comments; Go follows `AGENTS.md` formatting rules.
- Commit the whole foundation as one contiguous category after verification.

## Review focus

- An overlay path with `..`, an absolute path, or a symlink escape cannot load.
- A byte-identical replacement preserves vanilla status and effective hash.
- Additional Lua files register in deterministic path order.
- A Lua system failure reports its file, system name, and current action
  without leaving a partially applied structural command.
- Save/restore with a changed ruleset requires explicit opt-in or migration;
  exact-match dynamic schemas and state resume deterministically.

---

### Task 1: Effective Lua tree and identity

**Files:** create `internal/modfs/load.go`, `hash.go`, `builtin/init.lua`,
`load_test.go`; add command-line overlay setting in `cmd/dcrawl/main.go`.

**Interfaces:** `modfs.Load(overlayDir string) (modfs.Ruleset, error)` returns
an immutable effective file set. `Ruleset.ReadFile(path)` reads resolved
bytes; `Paths()` returns sorted paths; `Hash()`, `BundledHash()`, `Vanilla()`,
and `Changes()` report identity. It is impossible to read an unvalidated path.

- [ ] Test embedded-only load, replaced file, added file, byte-identical
  replacement, invalid paths, symlink escape, case collision, and order.
- [ ] Implement the overlay resolver and canonical path+bytes hash; display
  effective hash and vanilla/modded status at startup.
- [ ] Add a minimal bundled entrypoint that loads domain trees in declared
  order, using the effective virtual tree for `require`.

### Task 2: Lua registration and Akara bridge

**Files:** create `internal/script/runtime.go`, `register.go`,
`components.go`, `systems.go`, `context.go`, and tests; use Akara's existing
`RegisterSchema`, `DynamicStore`, and `SystemFunc`.

**Interfaces:** `script.New(world *akara.World, rules modfs.Ruleset,
services Services) (*Runtime, error)` runs bootstrap and freezes the registry.
`Runtime.Close()` releases the VM. `Runtime.Systems()` returns named system
descriptors with ordering constraints for the game to compose. Lua API: `register.component{...}` and
`register.system{...}` with stable IDs, schema versions, fields, query,
ordering constraints, and update callback. In this foundation slice, `ctx`
exposes CRUD for Lua-registered components, the active actor, named RNG,
event emission, and queued component add/remove. Lua systems supply a query
over those components. Level reads, spatial commands, and access to existing
Go component stores are host API extensions for the whole-domain migrations.
The game validates one acyclic order across current Go and new Lua systems,
then calls Akara `AddSystem` in that order.

- [ ] Test one overlay-defined component and system that update an entity on
  `World.Update`; verify a second system can order after it, duplicate IDs
  fail, cycles fail, invalid field values fail, and query iteration is stable.
- [ ] Implement GopherLua module loading only from `modfs.Ruleset`, with safe
  host-provided entity handles and exact integer validation.
- [ ] Remove wall-clock, process filesystem, network, and unseeded random
  access from the simulation VM. Propagate Lua errors with module and system
  context. Apply structural commands only at the session barrier.

### Task 3: Game and save integration

**Files:** modify `internal/game/game.go`, `scenario.go`, `commands.go`,
`save.go`; create `internal/game/system_order.go`; `internal/save/snapshot.go`; `cmd/dcrawl/main.go`; related tests.

**Interfaces:** game creation and restore receive a `modfs.Ruleset`; the game
owns `script.Runtime`. Save version increases and records ruleset hash,
dialect, schema definitions/versions, and dynamic component records.
Restore validates the effective ruleset before creating or mutating a world.
A separate explicit mismatch option is required for loading changed rules.

- [ ] Test a Lua system that changes a dynamic component through a real game
  action, save/restart/restore continuation, exact ruleset match, mismatch
  refusal, and explicit mismatch path or registered schema migration.
- [ ] Thread the same ruleset through startup, game creation, restore, and
  terminal status. Convert existing Go system registrations into named
  descriptors so Lua systems can order around them; remove any parallel
  unscripted runtime construction path.
- [ ] Validate dynamic records against registered schemas and entity links;
  maintain the existing ECS/level ownership of all current game state.
- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-cache go test ./...`, `go vet ./...`,
  `go build ./...`, `sh scripts/check-go-style.sh`, and `git diff --check`
  once the category is integrated. Request whole-branch review, fix material
  findings, commit one category, and merge into local Go `main`.

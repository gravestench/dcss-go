# One-pass Lua gameplay conversion

## Goal

Convert the implemented Dungeon Crawl gameplay rules and policies into the embedded
Lua mod tree as one integrated change. Avoid a sequence of Go/Lua domain
bridges, duplicate handlers, and commits whose only purpose is to preserve
compilation during migration. The branch may be broken while the conversion
is in progress. Commit when the complete current playable game runs through
Lua-owned policy and the integrated checks pass.

## Ownership

Go remains the reusable engine: Akara world and entity storage, deterministic
turn scheduling, collision and grid operations, pathfinding and visibility,
named RNG streams, save serialization, mod file loading, and terminal input
and drawing primitives. It exposes one schema-aware ECS context to Lua. Core
typed Akara components may remain where Go engine services need them; Lua
defined components carry game-specific state. There is no mirrored state and
no separate API per component or domain. Semantic game invariants are Lua
rules; the engine enforces type safety, entity existence, transaction
barriers, and serialization.

Lua owns the current game's content registrations and behavior: character
creation and advancement, item use and equipment, status effects, combat and
spell outcomes, monster decisions, generation and branch rules, command
policy, and screen policy. Source-specific formulas, content-ID dispatch,
messages, and roll order are in small domain Lua files, not Go switches.
All Lua source lives in actual `.lua` files under the embedded mod tree or
test mod directories. A same-relative-path overlay replaces a bundled file;
effective bytes determine ruleset identity and save compatibility.

## Conversion boundary

Migrate all currently playable handlers before merging this branch. Remove
their Go implementations in the same pass. Do not build compatibility
facades around the old code. Where one gameplay operation crosses engine
services, Lua issues typed commands through the shared context; the Go
kernel applies them at the existing action barrier. Static generated
content is committed as Lua modules and never regenerated during normal
builds. Keep the source revision and source location in generated modules.

Preserve current playable behavior, DCSS-shaped terminal flow, named RNG
draw order, save continuation, and error reporting for missing required
state. Mod-defined systems and components must use the same public API as
the bundled rules. The first broad conversion targets all rules already
implemented in Go; unported DCSS features remain explicit capability gaps
for subsequent full-game work.

## Acceptance

The playable game has no Go game-specific system registrations or content-ID
effect switches. One integrated test run covers the existing game, Lua
overrides, deterministic saves, and malformed rule/state handling. `go test
./...`, `go vet ./...`, `go build ./...`, the repository style check, and a
whole-branch review pass before the single broad conversion commit is
merged to local `main`.

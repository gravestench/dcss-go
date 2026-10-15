# Lua Component Collection Fields Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task by task.

**Goal:** Let Lua mods save homogeneous `list<T>` and `map<string,T>`
component fields for every existing scalar field type.

**Architecture:** Akara owns typed collection validation and defensive
copying. The Go Lua runtime parses collection declarations, converts dense
Lua lists and string-keyed maps, and reconstructs them on reads. Saves use
the existing dynamic-component path with collection values detached from live
state. No nested collections or alternate ECS store is introduced.

**Tech Stack:** Go 1.25, local Akara, GopherLua, existing Go save codec.

**Spec:** Approved user decision for homogeneous `list<T>` and
`map<string,T>` with empty defaults and scalar types `bool`, `int64`,
`uint64`, `float64`, `string`, `entity`; no nested collections yet.

## Global Constraints

- Production Lua remains in `.lua` files under the embedded mod tree.
- Reject sparse/mixed Lua lists, nonstring map keys, wrong value types,
  nonfinite floats, and inexact integers.
- Collections are detached on schema registration, Set, Get, Snapshot,
  migration, command buffering, save, and restore.
- Entity references retain the existing exact-ID and save validation rules.
- Keep Akara changes on a feature branch and avoid a local replace in the
  final Go dependency; use a published GitHub revision after review.
- Keep this category separate from the uncommitted mutation work.

## Review Focus

1. Mutating a supplied default or Set input cannot mutate stored data.
2. Mutating Get/Snapshot output cannot mutate stored data.
3. A sparse Lua table cannot silently truncate a list.
4. Saving and restoring a map of entity IDs preserves typed references and
   rejects dangling references.
5. Two mods declaring the same component with different element types fail
   at registration, even if both collections are empty.

---

### Task 1: Akara collection storage

**Files:** Modify `dynamic_component.go`, `command_buffer.go`; test
`dynamic_component_test.go`, `command_buffer_test.go` in Akara.

**Interfaces:** Add `FieldList`, `FieldMap` and `Field.ElementKind`. Store
lists as `[]any` and maps as `map[string]any`, normalized to the declared
scalar element kind. Empty collections are defaults.

- [ ] Write failing tests for all six element kinds, invalid input,
  defaults, migration, and defensive copies through every store API.
- [ ] Run `go test ./...`; confirm the new tests fail for missing types.
- [ ] Implement normalization and cloning at all ownership boundaries.
- [ ] Run `go test ./...` and `go vet ./...`; expect pass.

### Task 2: Lua schema declarations and conversion

**Files:** Modify `internal/script/register.go`, `components.go`, and
`context.go`; add `internal/script/testdata/lua/tests/component_collections_test.lua`
and a schema under that test mod's `schemas/` directory. The test imports the
schema loaded by the production mod loader.

**Interfaces:** Accept `list<T>` and `map<string,T>` in `type` declarations.
`ctx:add`, `ctx:set`, and `ctx:get` use typed collection values with the
same exact scalar rules as existing fields.

- [ ] Write failing Lua tests for all six types, defaults, replacement,
  sparse-list and wrong-key rejection, and no aliasing.
- [ ] Run the focused Lua test; confirm RED.
- [ ] Implement parsing and conversion without a second component API.
- [ ] Run the focused Lua test and `go test ./internal/script`; expect pass.

### Task 3: Save/restore and dependency integration

**Files:** Modify the Go dynamic-component save/restore codec only where
required; add an integrated game save test; update `docs/modding.md`,
`docs/ecs-architecture-roadmap.md`, `go.mod`, and `go.sum`.

**Interfaces:** Existing save format carries typed collection values and
schema identity; a changed element kind fails restore.

- [ ] Write a failing integrated save/restore test with scalar, list, and
  map fields, including entity references and invalid references.
- [ ] Implement missing codec handling and verify deep copies.
- [ ] Run `go test ./...`, `go vet ./...`, `go build ./...`, style and diff
  checks; resolve failures from this category.
- [ ] Commit Akara and Go changes as their respective collection categories.
  Publish Akara and update Go to its GitHub revision only with authorization.

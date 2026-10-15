# Layered Lua Mod Directories Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Compose the embedded Lua game with ordered sparse mod directories while preserving deterministic loading and ruleset identity.

**Architecture:** `modfs.Load(overlayDirs ...string)` resolves embedded files and ordered overlays into one immutable `Ruleset`. The CLI collects repeated `--mod-dir` values in order. Runtime discovery, `require`, and save validation consume the same resolved ruleset.

**Tech Stack:** Go 1.25, embedded `fs.FS`, existing Lua runtime and Akara game state.

**Spec:** `docs/superpowers/specs/2026-10-15-layered-lua-mods-design.md`

## Global Constraints

- Embedded `internal/modfs/builtin/` is layer zero; the last overlay containing a path wins.
- Overlays are sparse `.lua` trees with no manifest; invalid files and symlinks fail with layer and path context.
- `require` and automatic discovery read only the resolved effective tree.
- `Vanilla` and save identity depend on effective bytes, not directory names or layer count.
- Preserve the user's untracked `dcrawl-save.json`; do not rewrite old saves for this feature.
- Use one commit for this contiguous loader/CLI/documentation category after integrated verification.

## Review Focus

1. Two overlays replace the same path: the last supplied file wins; reverse order changes the result when bytes differ (Task 1).
2. An overlay path differs from an embedded path only by case: fail rather than load both names (Task 1).
3. A sparse overlay adds one file under a discoverable directory: it registers without a manifest or bootstrap edit (Task 3).
4. A `require` of an overridden helper and auto-loaded content both see winning bytes (Task 3).
5. An unchanged byte-identical overlay leaves `Vanilla` true and permits save restoration with the same effective ruleset (Tasks 1 and 3).

---

### Task 1: Resolve ordered layers

**Files:**
- Modify: `internal/modfs/ruleset.go`
- Test: `internal/modfs/ruleset_test.go`
- Modify: `internal/game/save.go`, `internal/game/scenario.go`, `internal/terminal/app.go`.
- Modify: base-only call sites in `internal/game/all_character_starts_test.go`,
  `internal/game/brand_override_test.go`,
  `internal/modfs/early_weapon_brands_test.go`,
  `internal/script/character_catalog_test.go`, and
  `internal/terminal/input_policy_test.go`.

**Interfaces:**
- Consumes: embedded `builtin` tree and existing `applyOverlay` path validation.
- Produces: `func Load(overlayDirs ...string) (Ruleset, error)`; all nonempty arguments are ordered overlay roots.

- [ ] **Step 1: Write failing loader tests.** Add `TestOrderedSparseLayers` asserting two directories add distinct files, the later one replaces a shared file, and reversed order changes the winning bytes and hash. Add `TestLayerCaseCollision` asserting an overlay path that only changes case fails with its directory and path. Add `TestLayerIdentity` asserting two different layer lists with identical effective bytes have identical `Hash`, `Manifest`, `Changes`, and `Vanilla` values. Add `TestInvalidLaterLayer` asserting a symlink or non-Lua file in the second layer reports that layer and relative path.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/modfs -run 'TestOrderedSparseLayers|TestLayerCaseCollision|TestLayerIdentity' -count=1`; expect RED from the one-directory API.
- [ ] **Step 3: Implement** the variadic loader by reading the bundle once, copying it, validating and applying each directory in order, then computing sorted paths and hashes. Reject empty entries; update the listed base-only calls to `Load()` so no empty-directory convention remains. Include the layer root and relative path in validation errors.
- [ ] **Step 4: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/modfs -count=1`; expect PASS.

### Task 2: Accept repeated CLI mod directories

**Files:**
- Modify: `cmd/dcrawl/main.go`
- Create: `cmd/dcrawl/mod_dirs.go`
- Create: `cmd/dcrawl/mod_dirs_test.go`

**Interfaces:**
- Consumes: `modfs.Load(overlayDirs ...string)` from Task 1.
- Produces: `modDirs`, a `flag.Value` that appends each `--mod-dir` argument in arrival order and exposes its values as `[]string`.

- [ ] **Step 1: Write failing `TestRepeatedModDirFlag`.** Parse `--mod-dir first --mod-dir second` with a `flag.FlagSet`; assert `[]string{"first", "second"}`. Assert an empty argument is rejected before loading.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./cmd/dcrawl -run TestRepeatedModDirFlag -count=1`; expect RED.
- [ ] **Step 3: Implement** `modDirs.String()` and `modDirs.Set(value string) error`, register it with `flag.Var`, and call `modfs.Load(modDirs...)`. Keep `main.go` concerned only with startup, not overlay resolution.
- [ ] **Step 4: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./cmd/dcrawl -count=1`; expect PASS.

### Task 3: Verify effective-tree behavior and document it

**Files:**
- Test: `internal/script/discoverable_content_test.go`
- Test: `internal/game/lua_runtime_test.go`
- Modify: `docs/modding.md`

**Interfaces:**
- Consumes: Task 1's resolved `Ruleset` and Task 2's CLI syntax.
- Produces: integration coverage for mod composition and user instructions.

- [ ] **Step 1: Write failing integration tests.** In the script test, compose a sparse layer adding a discoverable definition with another layer overriding a helper used by `require`; assert both take effect from one runtime. In the game test, save under two layers, restore with a different set of directories producing identical effective bytes, and reject a restore with changed winning bytes. Use temporary directories and existing fixture-copy helpers.
- [ ] **Step 2: Run** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./internal/script ./internal/game -run 'TestLayeredDiscoveryAndRequire|TestLayeredRulesetRestore' -count=1`; expect RED.
- [ ] **Step 3: Implement only the missing integration behavior.** No second registration path or per-category dispatcher. Update `docs/modding.md` with repeated flags, ordered precedence, sparse additions, same-path replacement, and effective-byte save identity.
- [ ] **Step 4: Run** the focused tests from Step 2; expect PASS.
- [ ] **Step 5: Verify** `GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./...`, `GOCACHE=/private/tmp/dcrawl-go-build-cache go vet ./...`, `GOCACHE=/private/tmp/dcrawl-go-build-cache go build ./cmd/dcrawl`, and `git diff --check`; all must pass. Review that every spec section has an implementing task.
- [ ] **Step 6: Commit** only this category with `git add` on its files and `git commit -m "feat: support ordered Lua mod layers"`. Keep the separate mutation WIP out of this commit.

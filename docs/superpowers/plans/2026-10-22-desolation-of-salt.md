# Desolation of Salt Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the complete Desolation entrance and one-floor portal domain using the source DES maps and named Lua policy.

**Architecture:** Commit each original MAP as one discoverable DES definition. Lua hooks translate source script effects at their original positions. A domain level policy and temporary portal handler use the existing staged level transaction and ECS save model.

**Tech Stack:** Go, Lua, Akara ECS, existing DES interpreter and layered VFS.

**Spec:** `docs/superpowers/specs/2026-10-22-desolation-of-salt-design.md`

## Global Constraints

* Work on `/Users/dylanknuth/src/dcrawl-go` `main`; push verified commits to the fork.
* Preserve all 66 original MAP blocks byte for byte, and keep source `.des` directives except where source Lua becomes a named hook.
* Put inherited source default depths explicitly in per-map DES; helpers remain tag-only.
* Preserve Vaults room draw order: Wizard Lab first, Desolation second with replacement on success.
* Missing behavior used by authored Desolation content fails acceptance; implement needed generic rules in this slice.
* Put no Lua source string in Go. Do not retain one-time import tools in the repository.
* Every new Lua file and function explains how and why; line length is at most 120 characters, preferably 80.
* Use stable IDs, not load order, for seeded choices. Respect layered VFS replacements and additions.
* Commit the whole Desolation domain as one contiguous category after integrated verification.

## Review Focus

* A DES helper wider than its authored parent slot must fail or select another helper without corrupting the floor.
* A source entrance on Vaults must not draw twice from independent five-percent chance paths.
* A save after entry or expiration must restore the precise outside coordinate and clock state.
* A sparse mod adding one ruin must join the weighted helper pool; replacing one floor must retain its effective ID.
* All three destinations must have a reachable exit after substitutions and helper placement.

---

### Task 1: Commit and load the complete source corpus

**Files:** `internal/modfs/builtin/vaults/desolation_entry/*.des`, `internal/modfs/builtin/vaults/desolation_ruin/*.des`, `internal/modfs/builtin/vaults/desolation/*.des`, `internal/modfs/builtin/policy/generation/vaults/desolation*/`.

**Interfaces:** Existing `vaults.catalog`, `hooks`, and `operations`; new hook methods accept the vault `api`. Each source map retains its NAME and one effective VFS path.

- [x] Extract all 66 MAP blocks into named files with source comments, explicit inherited DEPTH, and named Lua hook calls. Validate MAP SHA-256 against the pinned source.
- [x] Implement common entrance and ruin hook methods, plus per-map variations, using `api:emit` and `api:record`.
- [x] Add catalog/script tests for 9 entrance, 54 ruin, and 3 destination definitions; assert every hook resolves and every source directive can place or has an explicit generic implementation.

### Task 2: Generate all three complete floors

**Files:** `internal/modfs/builtin/policy/generation/desolation/level.lua`, `internal/modfs/builtin/policy/generation/scenario.lua`, terrain IDs and Go terrain features.

**Interfaces:** `level.generate(ctx, input)` returns a staged level; `level.candidates(player)` returns stable weighted destination IDs.

- [x] Add the entry and exit terrain vocabulary and decode/render behavior.
- [x] Select the three whole-floor maps with source weights and insert ruin helpers with `SUBVAULT` at the authored slots.
- [x] Verify all three floor IDs, exit cells, source records, fog machines, monsters, rewards, and connectivity with integrated tests. Commit text snapshots for all three floors.

### Task 3: Run the entrance clock and travel round trip

**Files:** `internal/modfs/builtin/policy/world/desolation/{portal,travel}.lua`, `policy/world/portals/handlers/desolation.lua`, ECS schemas, timer system, generation chance policy, and Go save validation call sites.

**Interfaces:** Portal handler exposes `features`, `prepare`, `is_marker`, `materialize`; travel policy exposes `world.desolation.commit_travel`; generation policy exposes `world.generate_desolation_level`.

- [x] Route source 600–800-turn timed markers into saved ECS clocks and show source wind warnings and expiry.
- [x] Route entry and every exit arch through the generic atomic portal transaction; return to the precise outside cell and retire the temporary floor.
- [x] Apply ordinary source chance in Elf; run Vaults Desolation draw after Wizard Lab and replace its special-room choice on success. Verify branch eligibility and clock behavior over save/restore.

### Task 4: Save, mods, documentation, and integrated verification

**Files:** Domain save validators, `docs/` modding guide and snapshot docs, Go and `_test.lua` tests.

**Interfaces:** Validators inspect effective IDs and installed level state; modders add a file under the matching DES or hook directory.

- [x] Reject malformed active Desolation saves while accepting expired outside gates and legal returned visits.
- [x] Exercise sparse add and replace overlays and seed stability under file ordering.
- [x] Verify each authored monster, item, reward, terrain, and fog expression resolves to live behavior; implement missing generic rules found by these checks.
- [x] Run focused Lua/Go domain suites, relevant portal and vault regression suites, formatting and MAP digest checks; fix any failures.
- [x] Commit the contiguous slice, merge if work was isolated, and push `main`.

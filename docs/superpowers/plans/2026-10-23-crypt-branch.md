# Crypt Branch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship the complete source-backed Crypt branch: 59 maps, Vaults entry, three floors, mandatory Crypt:3 ending, authored or fallback Tomb gate, local map events, saves, and floor snapshots.

**Architecture:** Split pinned `crypt.des` into individually replaceable DES files with unchanged MAP blocks and source-position named Lua hooks. Reuse the branch schedule, entry fitter, regular/extra vault passes, primary-vault selector, Akara actor/item/trigger state, and generated-stair linker. Add only generic capabilities needed for player-LOS triggers and source terrain features.

**Tech Stack:** Go kernel, embedded Lua, Akara ECS, DES map corpus, Lua `_test.lua` files, Go integration tests.

**Spec:** `docs/superpowers/specs/2026-10-23-crypt-branch-design.md`

## Global Constraints

* Use pinned `crawl-ref/source/dat/des/branches/crypt.des` as the source; all 59 MAP blocks remain byte-identical.
* Commit generated DES and Lua content. Do not commit a source importer or run it during builds.
* Lua owns Crypt policy and content; Go gains no Crypt-ID gameplay switch or inline Lua source.
* Keep functions and files commented for human readers, <=120-character lines, and expanded multi-field literals.
* One contiguous Crypt domain commit on `main`, then push. Test once at the category boundary after focused RED/GREEN cycles.

## Review Focus

* A Vaults-side dummy entry must keep its source weight and keyed stair; test the full entrance pool, not only decorated choices.
* An ending with an authored Tomb gate must bind exactly that cell, while an ending without one uses one fallback gate; test both and restore.
* A player-LOS trigger must fire after it becomes visible, exactly once, including after save/restore; test approach, leave, and re-entry.
* A source hook's conditional monster and loot draws must occur after its preceding DES operations; test representative true/false branches and actual placement.
* A malformed overlay missing a gate, duplicating a feature, or breaking a marker group must roll back staged generation and preserve saved state.

---

### Task 1: Authoritative Crypt corpus and family IDs

**Files:** Create `internal/modfs/builtin/vaults/{crypt_entry,crypt,crypt_end}/*.des`; modify `constants/{vault_families,vault_tags,vault_features,terrain}.lua`, `content/terrain_features.lua`, `internal/terrain/feature.go` and terrain rendering where source features are missing; create `internal/script/testdata/lua/tests/crypt_source_catalog_test.lua`.

**Interfaces:** The effective vault catalog infers the family from each directory and loads one NAME per file. `families.CRYPT_ENTRY`, `families.CRYPT`, `families.CRYPT_END`, `tags.CRYPT_ENTRY`, `features.ENTER_CRYPT`, and `features.ENTER_TOMB` name the source-facing selection and feature values. Current terrain projection maps those feature names to typed cells.

- [ ] Write `crypt_source_catalog_test.lua`: assert 13 entry, three Crypt:1 arrival, 35 ordinary, eight ending definitions; parse each through the production DES loader and validate every named hook.
- [ ] Run `go test ./internal/script -run 'TestLuaRules/crypt_source_catalog_test.lua' -count=1`; confirm missing corpus fails.
- [ ] Extract each source definition with a disposable local script, preserving MAP bytes and translating embedded script sites into named Lua hook references. Keep source metadata in the owning file and give each file its own explanatory comments.
- [ ] Add family/tag/terrain IDs and the corresponding typed projection and renderer entries. Verify all 59 source MAP blocks against the pinned source manifest `553295c86138bbd1985ba1f126dedc3d5f40c297d937add780be59931c19e400`.
- [ ] Rerun the focused catalog and terrain tests; confirm they pass.

### Task 2: Entry, Crypt floors, ending, and Tomb link

**Files:** Modify `policy/generation/vaults/branch_entry.lua`, `content/branches/branch_crypt.lua`, `policy/generation/generated.lua`, and existing generic availability/save policies only as needed; create `internal/script/testdata/lua/tests/crypt_generation_test.lua` and `internal/game/crypt_branch_game_test.go`.

**Interfaces:** `entry.candidates(branches.BRANCH_CRYPT, floor)` returns the source-weighted entry pool; `entry.place` supplies the keyed Crypt gate. `branch_crypt.primary_vaults` requires `families.CRYPT_END` at depth 3. `generated.bind_authored_branch_links` recognizes `features.ENTER_TOMB` on a selected ending and binds that record to the scheduled Tomb link.

- [ ] Write failing Lua tests for all 13 entrance candidates, optional Crypt:1 arrival eligibility, 35 ordinary maps' source depths, eight mandatory end candidates, and authored versus fallback Tomb links.
- [ ] Run the focused Lua test; confirm missing families and links fail.
- [ ] Wire Crypt into the generic entry and primary selection paths. Let the regular/extra stages place the 38 non-ending Crypt-floor maps using existing source chance and depth logic. Bind source Tomb gates without duplicating the fallback stair.
- [ ] Write and run Go travel tests from scheduled Vaults entry through Crypt:3 and back, including end ID, branch stair links, authored content, and save/restore. Repair only the generic kernel capability required by the full branch.

### Task 3: Source scripts and saved map events

**Files:** Create focused Lua modules under `policy/generation/vaults/{crypt_entry,crypt,crypt_end}/` and `policy/world/vault_trigger_callbacks/crypt.lua`; modify `policy/world/vault_triggers.lua` and `systems/world_vault_triggers.lua` for a reusable player-LOS event; create `internal/script/testdata/lua/tests/crypt_hooks_test.lua` and `crypt_triggers_test.lua`.

**Interfaces:** Each DES `vault.run` points to a named local hook. Conditional source draws use the existing layout RNG. `vault_trigger:crypt.*` markers materialize through the existing saved `WORLD_VAULT_TRIGGER` schema; the player-LOS event checks the trigger's final level cell through `ctx:visible` and consumes it after successful callback.

- [ ] Write failing Lua tests for source entry setup, end theme and loot branches, delayed decay, special feature names, and all conditional script sites.
- [ ] Run focused hook tests; confirm missing methods or effects fail.
- [ ] Port the source script decisions into commented Lua methods, splitting hooks where an earlier emitted operation must apply before a later draw. Use imported IDs where referenced and no mutable module-global game state.
- [ ] Write failing trigger tests for guarded arrival wakeup and glass-Crypt grate drop, visibility and silence messages, one-shot consumption, transformed coordinates, and save/restore.
- [ ] Add the generic player-LOS trigger event and focused Crypt callbacks; rerun both Lua test files to green.

### Task 4: Integrated coverage, snapshots, and delivery

**Files:** Extend `internal/game/crypt_branch_game_test.go`; create `internal/game/testdata/crypt-*-mod/` sparse overlays and `docs/level-snapshots/crypt/`; update `docs/{modding,port-inventory,ecs-architecture-roadmap}.md`.

**Interfaces:** Go integration tests stage real generated floors and saved Akara entities. Snapshot output uses the existing text floor formatter with selected entry/end IDs and branch links. Sparse VFS overlays add or replace individual Crypt files without a central Go registry.

- [ ] Test all 59 definitions through the production placement path and all eight end maps on live floors. Exercise malformed overlay rollback and saved level/entity validation.
- [ ] Generate and inspect text snapshots for every Crypt:3 ending plus representative Vaults entry, Crypt:1, and Crypt:2 floors; include exact stair links, source IDs, and trigger cells.
- [ ] Update the modding guide with Crypt file placement, source hook and trigger APIs, and the authored Tomb-gate contract. Update coverage inventory and roadmap with remaining Tomb and monster-behavior gaps.
- [ ] Run source MAP comparison, focused Lua and Go tests, `go build ./cmd/crawl`, `gofmt`, `sh scripts/check-go-style.sh`, and `git diff --check`. Fix changed-file violations and report unrelated existing failures accurately.
- [ ] Obtain one whole-domain code review, address Critical and Important findings in this same category, commit once, and push `main`.

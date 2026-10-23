# Tomb Branch Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship Tomb's source-backed three-floor one-way route, ten Crypt-side entry maps, golden rune, saved population, and floor snapshots.

**Architecture:** Split the 31 active source maps into individually replaceable DES files and move source scripts to source-position Lua hooks. A Tomb Lua builder creates all three related levels and resolves named hatch markers after final placement. Extend the generic next-floor installer to stage and populate a multi-level result atomically.

**Tech Stack:** Go kernel, embedded Lua, Akara ECS, DES corpus, Lua `_test.lua` files, Go integration tests.

**Spec:** `docs/superpowers/specs/2026-10-23-tomb-branch-design.md`

## Global Constraints

* Use pinned `crawl-ref/source/dat/des/branches/tomb.des`; all 31 active MAP blocks remain byte-identical.
* Exclude four old-save compatibility maps and the duplicate old-version guardian sets.
* Commit generated DES and Lua content. Do not commit a source importer or run one during builds.
* Lua owns Tomb policy and content; Go gains no Tomb-ID gameplay switch or inline Lua source.
* Every Lua function explains why and how, lines stay <=120 characters, and multi-field literals are expanded.
* One contiguous Tomb implementation commit on `main`, then push. Test/refine at the whole-slice boundary.

## Review Focus

* A Crypt:3 ending with its own gate must not get a second entry map; assert exactly one linked gate for both authored and fallback cases.
* Source marker operations that occur before SUBST must stay anchored to the final transformed cell; assert name-to-coordinate links for every helper choice.
* Several outgoing hatches can share one name and several names can share one landing, but each name has exactly one destination marker; test both source patterns and reject missing, duplicate, or blocked destinations.
* A one-way hatch must not invent a reciprocal stair on its landing; traverse the full source route and check return paths explicitly.
* A bad sparse overlay or population failure must leave the parent stair pending and no staged Tomb levels or entities; assert checkpoint rollback.

---

### Task 1: Active Tomb corpus and source hooks

**Files:** Create `internal/modfs/builtin/vaults/{tomb_entry,tomb_1,tomb_1_centre,tomb_1_hall_stairs,tomb_2,tomb_2_ambush,tomb_3,tomb_3_rune}/*.des` and matching focused Lua modules under `policy/generation/vaults/`; modify `constants/{vault_families,vault_tags,vault_features}.lua` and terrain IDs only where source features are absent; create `internal/script/testdata/lua/tests/tomb_source_catalog_test.lua` and `tomb_hooks_test.lua`.

**Interfaces:** The effective DES catalog identifies family from each directory and NAME from each file. Each source-position `vault.run` resolves to an actual module method through the normal hook loader. Hook APIs emit `KMONS`, `KITEM`, `KFEAT`, `SUBST`, `MARKER`, and source feature-name intents.

- [ ] Add failing Lua tests: 31 active IDs, ten entries, all helper pool counts, every map parse and hook load, representative first/last source operation order.
- [ ] Run focused Lua catalog and hook tests; confirm absent corpus fails.
- [ ] Extract 31 MAP blocks with a disposable local script, one DES file per NAME. Port active source scripts to named methods at the original operation positions; keep selection state on the build context.
- [ ] Compare each committed MAP block byte-for-byte with the pinned source. Exercise every definition through production placement and repair any unsupported directive or feature projection.

### Task 2: Named one-way hatch graph and complete Tomb builder

**Files:** Create `policy/generation/tomb/{hatches,guardian_sets,level}.lua`; modify `policy/generation/scenario.lua`, `policy/generation/generated.lua` or its generic dispatch owner, `content/branches/branch_tomb.lua`, `policy/generation/vaults/branch_entry.lua`, and source ID modules; create `internal/script/testdata/lua/tests/tomb_generation_test.lua` and `tomb_hatches_test.lua`.

**Interfaces:** `tomb.level.generate(ctx, input)` returns `{ levels, parent_links, entry, starting_items }`; every level has `id`, `branch_id`, `local_depth`, decoded `cells`, final `stairs`, `entry_x/y`, `vault_ids`, and `vault_records`. `tomb.hatches.resolve(levels)` matches final `hatch_name` records to final `hatch_dest_name` records and rejects invalid endpoints. Existing scheduled Crypt entry binds the Tomb:1 return stairs.

- [ ] Add failing Lua tests for all ten eligible entry maps, Tomb availability, one selected helper from each pool, guardian-set least-use balancing, golden rune, and the complete named hatch graph.
- [ ] Run focused Lua tests; confirm missing builder/graph fails.
- [ ] Wire Tomb entry selection into the generic branch-entry fitter and make the authored Tomb floor builder selectable from the generic next-floor dispatcher. Finish source hooks and three-level graph resolution in Lua.
- [ ] Rerun Lua tests with every helper option and both source conditional outcomes. Verify invalid overlays report a useful map/name error without a partial result.

### Task 3: Generic multi-level transaction and ECS population

**Files:** Modify `internal/game/{generate_next,populate_script,generation_script}.go` and focused tests under `internal/game/tomb_branch_game_test.go`; modify generic script-level decoding only as needed.

**Interfaces:** `world.generate_next_floor` may return legacy `{ level, parent_links, entry, starting_items }` or `{ levels, parent_links, entry, starting_items }`. The installer validates all new level IDs, depths, destinations, and parent patches before the checkpoint commits. The population owner receives each newly staged floor once with its authored entry and floor records.

- [ ] Add a failing Go test for a generic three-level policy result with nonreciprocal links, invalid destination rollback, and population on each new level.
- [ ] Run the focused Go test; confirm one-level-only decoding fails.
- [ ] Extend the installer generically and preserve the one-level contract. Populate all new levels before travel, using the existing command checkpoint and saved ECS owner.
- [ ] Run focused Go tests for real Crypt:3 to Tomb:1 entry, all Tomb one-way transitions and return routes, rune pickup, save/restore, and bad-overlay rollback.

### Task 4: Text snapshots, documentation, review, and delivery

**Files:** Create `docs/level-snapshots/tomb/`; modify `docs/{modding,port-inventory,ecs-architecture-roadmap}.md` and whole-domain tests as needed.

**Interfaces:** Snapshots use the existing text floor formatter and record selected helper IDs, hatch name/destination links, source features, and the golden rune cell. The modding guide explains adding an individual Tomb entry or helper and the named-hatch contract.

- [ ] Generate and inspect Tomb:1–3 text snapshots, including a connected hatch list and representative source variants. Compare all 31 MAP blocks against the pinned source.
- [ ] Run focused Lua and Go tests, `go build ./cmd/crawl`, `gofmt`, `sh scripts/check-go-style.sh`, and `git diff --check`. Fix changed-file failures and report unrelated existing failures.
- [ ] Obtain one whole-domain review, repair Critical and Important findings in this category, commit once, and push `main`.

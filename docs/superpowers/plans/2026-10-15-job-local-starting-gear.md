# Job-local starting gear implementation plan

> **For agentic workers:** Use superpowers:executing-plans to implement this
> plan. The user wants one commit for this complete content category, with
> integrated verification after the full sweep.

**Goal:** A job's single discoverable Lua definition owns its fixed starting
grants, so mods can add or replace a simple job without editing a shared
gear table.

**Architecture:** Deliberate import refreshes merge the committed jobs and
starting-gear JSON artifacts into per-job Lua files. Runtime character
creation reads only the registered job definition. Lua validates every
effective job's grants after all content is loaded.

**Tech stack:** Go 1.25, Gopher-Lua, embedded Lua mod tree, Python 3 importer.

**Spec:** `docs/superpowers/specs/2026-10-14-discoverable-lua-content-design.md`,
especially its remaining aggregate conversion contract; the character
start behavior contract is in
`docs/superpowers/specs/2026-10-15-all-character-starts-design.md`.

## Global constraints

- Normal game launch reads committed Lua, never the JSON artifacts or C++ tree.
- Every selectable pinned job receives its source-derived grants. Wanderer
  keeps an explicit null fixed-grant marker for its generated gear. The six
  inactive legacy jobs receive an explicit empty grant list.
- Job IDs remain declared by their job file. Source provenance stays in
  comments or the offline JSON artifact, not runtime fields.
- A mod override at the same job path replaces both the job and its grants.
- A new job with a valid `starting_grants` list requires no edit to a shared
  gear registry. Job-specific behavior may use a separate discoverable rule.
- Preserve `dcrawl-save.json`. Commit this whole category once.

## Review focus

1. A selectable job with no imported gear row is an importer error.
2. An unknown or duplicate gear job ID is an importer error.
3. A mod-added job with malformed grants fails at boot with its file origin.
4. An overridden job's grants are used at character creation; bundled grants
   are not consulted.
5. Existing legal starts preserve their fixed inventory and equipment.
6. Wanderer receives its full generated profile at the gear boundary so
   fallback armour and weapon follow its generated attributes.

---

### Task 1: Generate complete job definitions

**Files:** `scripts/generate_lua_character.py`,
`internal/modfs/builtin/content/jobs/*.lua`, and
`scripts/export-catalog-lua.py`.

**Interface:** `generate_lua_character.py --check` compares all emitted
species and job files with committed source. The catalog exporter stops
generating `data/starting_gear.lua`.

- [x] Add generator tests for full active-job coverage, duplicate and unknown
  gear IDs, a revision mismatch, and empty grants for inactive jobs. Use
  synthetic JSON fixtures or a pure merge helper; do not embed Lua in tests.
- [x] Run the tests to confirm the missing merge fails.
- [x] Merge `starting-gear.json` grants into each job record as
  `starting_grants`, omitting offline-only `raw` descriptions. Keep source
  data unchanged. Reject missing active jobs, duplicate/unknown IDs, and
  mismatched revisions.
- [x] Regenerate all 31 committed job modules. Stop generating and remove
  the aggregate `data/starting_gear.lua`.
- [x] Run the character generator `--check` and its tests. The aggregate
  exporter is not a gate for this category: it currently omits later wand
  spell links and would rewrite 11 unrelated item files. That refresh defect
  is separate from job gear.

### Task 2: Make the job definition authoritative at runtime

**Files:** `internal/modfs/builtin/policy/character/starting_gear.lua`,
`internal/modfs/builtin/content/validation.lua`, and
`internal/script/testdata/lua/tests/job_starting_gear_test.lua`.

**Interface:** `job.starting_grants` is a contiguous list of grants with an
existing item kind, positive integer quantity, and optional numeric plus,
charges, and string ego. An explicit `mod.null` marks dynamic grants. The
runtime uses the list or generated grants directly.

- [x] Add a production-VM Lua test asserting all 31 registered jobs have
  lists or the Wanderer dynamic marker; pinned selectable jobs have the
  expected fixture grants; and a
  malformed job's origin appears in boot errors.
- [x] Run focused Lua and Go tests to establish failure.
- [x] Remove the `data.starting_gear` lookup and fallback. Validate grants in
  the effective job catalog after discovery, using the existing catalog and
  item IDs. Preserve current source substitutions and source RNG order.
- [x] Run the focused Lua tests and representative character-start tests.
  A deterministic Wanderer regression caught and fixed an existing call-site
  mismatch that discarded generated attributes before fallback gear choice.

### Task 3: Verify one-file mod behavior and finish the category

**Files:** `internal/script` or `internal/game` overlay fixtures/tests,
`docs/modding.md`, `docs/port-inventory.md`, and
`docs/ecs-architecture-roadmap.md`.

- [x] Add an overlay test that copies a bundled job file, changes its
  `starting_grants`, and proves character creation uses the overlay's item.
  Add a malformed-grant overlay test that checks origin diagnostics.
- [x] Document the job-file contract and remove references to the shared
  starting-gear runtime table.
- [x] Run focused package tests, Lua tests, character exporter checks, vet,
  build, style, and diff checks. The final full `go test ./... -count=1`
  passed after the broad category was complete.
- [ ] Commit all source, generated files, tests, and docs as one category;
  fast-forward local Go `main`, then return to the continuing feature branch.

# Snake Pit End Vault and Rune Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. The user authorized
> coherent category commits on `main` and pushes to `origin/main`. Steps use
> checkbox syntax for tracking.

**Goal:** Generate one of all nine source Snake:4 end vaults with a real,
collectible serpentine rune and durable branch travel.

**Architecture:** The branch definition names an end-vault family. A reusable
Lua selector and placement stage chooses one exact-floor DES map, fits it on
an ordinary branch layout, and protects it from later optional vaults. Named
Lua hooks port source scripts; existing ECS items, terrain, links, and save
code own live play.

**Tech Stack:** Go 1.26, gopher-lua, layered modfs, Akara ECS, DES maps,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-20-snake-end-rune-design.md`

## Global constraints

- Commit all nine source Snake end maps, preserving MAP geometry and source
  directive order. Normal builds and tests do not read the C++ tree.
- No inline executable Lua, Go content-ID switch, second rune store, or
  committed importer. Named Lua hooks live under the embedded mod root.
- Lua modules use small commented functions, a local returned object,
  <=120 character lines, and multiline populated tables.
- Work on `main`; one commit per contiguous implementation category and push
  each category to `origin/main` after its focused verification.
- Exercise focused Lua and game integration tests at category boundaries;
  run style checks and broaden tests only for concrete remaining risks.

## Review focus

1. A non-Snake `PLACE: Snake:$` map is never selected as the mandatory end.
2. A missing or zero-weight end catalog makes Snake:4 unavailable with a
   useful reason, without falling back to an ordinary floor.
3. Failed orientation fits leave no changed terrain, records, or used IDs.
4. Both pools themes materialize their intended terrain and monster requests.
5. Save validation accepts rune pickup but rejects zero or two real historical
   rune records, a removed end map, and wrong stair destinations.

---

### Task 1: Source maps, scripts, and mandatory end placement

**Files:** Create nine `internal/modfs/builtin/vaults/snake_end/<NAME>.des`
files, two hook modules under
`internal/modfs/builtin/policy/generation/vaults/snake_end/`, and one
`policy/generation/vaults/end.lua` module. Modify
`content/branches/branch_snake.lua`, `policy/generation/floor_availability.lua`,
`policy/generation/generated.lua`, `policy/generation/vaults/extra.lua`, and
`policy/generation/vaults/eligibility.lua`. Add Lua tests under
`internal/script/testdata/lua/tests/`.

**Interfaces:**
- `end.candidates(context, definitions)` returns NAME-sorted `{definition,
  weight}` rows from the effective vault catalog whose family matches
  `context.end_vault_family`, whose explicit PLACE matches the branch bottom,
  whose weight is positive, and whose source name is unused.
- `end.choose(random, candidates)` returns one chosen definition or `nil` for
  an empty pool, consuming one cumulative draw only for a nonempty pool.
- `end.place(ctx, builder, context, placed, fit)` tries that chosen map and
  appends it only after successful placement; failed fits cause a bounded
  whole-floor retry in `generated.build_floor`.
- `extra.generate` receives the branch's end family in `context`; it runs
  `end.place` before optional stages and returns its selected ID as primary.

- [ ] Add a failing Lua corpus test: exactly nine effective `snake_end`
  definitions; each has `PLACE: Snake:$`, a distinct ID, source orientation,
  one authored rune request, and an audited MAP dimension and checksum.
- [ ] Add a failing Lua selector test: stable ID order, positive weights,
  family and PLACE filters, one weighted draw, and no ordinary PLACE leak.
- [ ] Add a failing Lua placement test: every selected end map survives
  seeded layout fit; a protected-stair collision redraws; a permanently
  impossible fit errors without publishing a fallback floor.
- [ ] Commit all source MAPs and directives. Convert the `snake_hunt`
  validator and `grunt_snake_rune_pools` theme code into named, commented
  Lua methods at their source positions. Preserve source comments in DES.
- [ ] Implement generic end-vault selection and generation stage. Use
  source-order hook expansion and existing `extra.place` rollback. Make
  the required end map protect all occupied cells before optional extras.
- [ ] Run focused `internal/script` tests, `gofmt` on changed Go (if any),
  `sh scripts/check-go-style.sh`, then commit and push the generation
  category.

### Task 2: Rune materialization, travel, and durable save validation

**Files:** Modify `policy/generation/vaults/specs/` only if source rune
requests need a generic parser fix; modify `policy/save/vaults.lua` and
`policy/generation/floor_availability.lua`. Add Lua `_test.lua` files under
`internal/script/testdata/lua/tests/` and a focused Go integration test in
`internal/game/snake_end_test.go`. Update `docs/modding.md` and
`docs/port-inventory.md`.

**Interfaces:** The generated floor carries its selected end ID as
`vault_id`, the successful map ID in `vault_ids`, and the unchanged typed
`RUNE_SNAKE` placement record in `vault_records`. Existing item pickup owns
`character.runes`; no new rune state API is introduced.

- [ ] Add failing Lua tests for one real rune record after each of all nine
  end maps and for save rejection of missing, duplicate, or wrong-family
  end records. Test both `snake_hunt` path outcomes and pools themes.
- [ ] Add failing Go integration tests for Snake:3 -> Snake:4 -> Snake:3,
  rune pickup, and save/restore before and after pickup; add a fixture with
  wrong saved stair destination.
- [ ] Resolve source mimic behavior to one real rune plus a non-rune good
  item. Reuse the existing item and rune pickup path, and validate the
  historical typed record independently from current floor entities.
- [ ] Validate effective end-map ID, `PLACE`, one real rune, and reciprocal
  travel without rewriting older saved Snake:4 floors.
- [ ] Document modded end-vault family registration, selection, hook paths,
  and restore contract. Run focused Lua and game tests, the style script,
  and a broader suite only for identified integration risks; commit and
  push the rune/save category.

## Completion check

Inspect all nine committed MAP checksums against the pinned source once,
then use the checked-in expectations in ordinary tests. Verify both commits
are on `origin/main`, the working tree is clean, and the focused game and
script tests pass. Leave unrelated unported DCSS domains on the full port
roadmap; completing this slice does not complete the overall port goal.

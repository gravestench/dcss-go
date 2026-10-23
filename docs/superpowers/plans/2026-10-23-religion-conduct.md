# Religion Conduct Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan. Steps use checkbox
> (`- [ ]`) syntax for tracking.

**Goal:** Make all active gods react to source conduct from the gameplay
actions the Go port already resolves.

**Architecture:** An immediate Lua conduct owner routes named events to
focused per-god modules, using live ECS and resolved catalog facts before
actors disappear. Producers live at the action owners. The existing player
worship component stores piety and penance; no module global stores game state.

**Tech Stack:** Go, Akara ECS, embedded Gopher Lua, layered mod VFS.

**Spec:** `docs/superpowers/specs/2026-10-23-religion-conduct-design.md`

## Global Constraints

- Use the pinned `crawl-ref` source for behavior, and commit runtime Lua.
- Work on local `main`; commit the contiguous conduct category once and push
  that commit to `origin/main` after boundary verification.
- Do not put Lua source in Go strings or add a Go switch over god IDs.
- Import shared IDs where used. Keep Lua comments explanatory and lines at
  most 120 characters, preferably near 80.
- Keep gameplay data in ECS or explicit saved stores, never mutable Lua
  module globals. Preserve deterministic RNG and save replay.

## Review Focus

1. An invalid or missing conduct module must fail at boot with its resolved
   VFS origin; Task 2 tests this with an overlay fixture.
2. A friendly or summoned kill must not earn ordinary kill piety; Task 4
   tests each case through actor death.
3. A forgiven unknown act must emit its forgiveness text without spending
   piety or RNG; Task 3 tests this with Zin and Trog.
4. A conduct that reduces piety to zero must leave worship before any
   penance is added; Task 1 tests excommunication and save/restore.
5. A file rename or overlay addition must not shift an unrelated seeded
   conduct roll; Task 6 tests two equivalent VFS trees.

---

### Task 1: Conduct event and piety offense owners

**Files:**
- Create: `internal/modfs/builtin/constants/religion_conduct.lua`
- Create: `internal/modfs/builtin/policy/religion/conduct.lua`
- Modify: `internal/modfs/builtin/policy/religion/piety.lua`
- Test: `internal/script/testdata/lua/tests/religion_conduct_test.lua`

**Interfaces:**
- `conduct.record(ctx, event)` accepts `{id, level, known, victim}` and
  resolves against the current god synchronously.
- `piety.offend(ctx, player, loss, penance)` applies Faith scaling, loss,
  excommunication, and surviving penance in source order.
- `conduct.response(ctx, event, rule)` evaluates validated like/dislike
  metadata. Per-god methods can override unusual source arithmetic.

- [ ] Add a Lua test for no god, invalid event, unknown-act forgiveness,
  Faith rounding, piety hysteresis, penance, and zero-piety leave.
- [ ] Run `go test ./internal/script -run TestLuaRules -count=1`; confirm the
  new Lua test fails for the missing owner.
- [ ] Implement constants and owners with each calculation and state change
  explained in comments. Match source draw gates exactly.
- [ ] Run the focused Lua suite and inspect every failed assertion before
  advancing.

### Task 2: Resolved god module contract

**Files:**
- Modify: `internal/modfs/builtin/content/gods/*.lua` for gods with rules
- Modify: `internal/modfs/builtin/content/validation.lua`
- Create: `internal/script/testdata/religion-conduct-mod/`
- Test: `internal/script/testdata/lua/tests/religion_conduct_modules_test.lua`
- Test: `internal/script/religion_conduct_mod_test.go`

**Interfaces:**
- Optional `definition.conduct_module` names the winning rule module.
- That module returns a table of event rules and optional named methods.
- Validation checks event names, response types, and module existence before
  play; unrelated modded gods may omit a conduct module.

- [ ] Write boot and overlay tests for valid replacement, missing module,
  unknown event, malformed factor, and no-module god.
- [ ] Run the focused mod test and confirm its expected failure.
- [ ] Add contract validation and VFS origin errors; then rerun the test.

### Task 3: Source response matrix for all 26 gods

**Files:**
- Create: `internal/modfs/builtin/policy/religion/conduct/<god>.lua`
  for every god with source likes, peeves, or exceptions.
- Create: `internal/modfs/builtin/policy/religion/conduct/common.lua`
- Test: `internal/script/testdata/lua/tests/religion_conduct_matrix_test.lua`

**Interfaces:**
- Rule files own their source event keys, factors, filters, text, and
  exceptional methods; `common.lua` supplies shared kill curves and good-god
  peeves without burying unique god behavior in a central switch.

- [ ] Build a source-traced matrix test covering all 26 gods, including
  intentional empty sets and representative values for shared responses.
- [ ] Confirm the matrix test fails before adding rules.
- [ ] Implement all source responses, with one explanatory comment for every
  function and theory of operation for each module. Keep exceptional math in
  its god module.
- [ ] Run the Lua matrix and unusual-response tests, refining the data and
  RNG order together.

### Task 4: Combat and death producers

**Files:**
- Modify: `internal/modfs/builtin/policy/combat/melee_actions.lua`
- Modify: `internal/modfs/builtin/systems/actor_death.lua`
- Modify: `internal/modfs/builtin/policy/magic/damage.lua` where it already
  resolves player damage.
- Create: `internal/modfs/builtin/policy/religion/conduct/monster_facts.lua`
- Test: `internal/script/testdata/lua/tests/religion_combat_conduct_test.lua`
- Test: `internal/game/religion_conduct_test.go`

**Interfaces:**
- `monster_facts` classifies source holiness, alliance, threat, speed,
  wizard/priest traits, reward eligibility, and source kill severity from
  structured catalog and live components.
- Producers call `conduct.record` before a victim is destroyed and only for
  actions they can genuinely classify.

- [ ] Write player-kill, friendly/summoned, holy-attack, and Uskayaw-damage
  tests through the real turn path.
- [ ] Confirm they fail for missing conduct events.
- [ ] Add producers and monster facts, then run the focused game and Lua
  tests once for this task.

### Task 5: Spell, item, exploration, sight, and training producers

**Files:**
- Modify: `internal/modfs/builtin/systems/player_spell.lua`
- Modify: `internal/modfs/builtin/policy/world/exploration.lua`
- Modify: relevant existing item-use, visibility, and training owners.
- Create: focused `religion_*_conduct_test.lua` files beside the Lua tests.

**Interfaces:**
- Existing action owners emit source-equivalent event IDs with severity and
  knownness. The conduct owner never infers these from command strings.

- [ ] Add tests for Trog casting/memorising/training, Zin and Cheibriados
  spell transgressions, exploration piety, and sight-based reactions.
- [ ] Confirm they fail before producers are connected.
- [ ] Wire actual successful or attempted actions in source order and rerun
  focused Lua and game tests.

### Task 6: Modding, presentation, replay, and category verification

**Files:**
- Modify: `internal/modfs/builtin/policy/presentation/religion.lua`
- Modify: `docs/modding.md`
- Modify: `docs/port-inventory.md`
- Test: `internal/script/testdata/lua/tests/religion_conduct_presentation_test.lua`
- Test: `internal/game/religion_conduct_test.go`

**Interfaces:**
- Presentation derives likes and dislikes from the same resolved rule
  metadata as gameplay; the guide gives a complete mod and producer example.

- [ ] Test description text, sparse overlay behavior, deterministic order,
  save/replay, and seeded RNG independence from file names.
- [ ] Implement presentation and documentation from the actual API.
- [ ] Run focused Lua and game suites, `go test ./internal/script
  ./internal/game`, `go build ./...`, and `sh scripts/check-go-style.sh`
  at the category boundary. Regenerate and inspect text snapshots if
  visible floor output changes.
- [ ] Inspect `git diff --check`, commit the whole conduct category as one
  commit, push to `origin/main`, and verify `HEAD == origin/main` with a
  clean worktree.

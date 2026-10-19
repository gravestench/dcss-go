# Monster Shapeshifters Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make natural and Chaos-created shapeshifters change forms throughout play and after a save.

**Architecture:** One Lua ECS component owns permanent shape identity. A Lua policy chooses source-like habitat-safe forms and handles timing; a Lua active system runs it before AI. Existing Polymorph owns body replacement.

**Tech Stack:** Go, Akara ECS, embedded Lua, JSON save format.

**Spec:** `docs/superpowers/specs/2026-10-19-monster-shapeshifter-design.md`

## Global Constraints

- Production rules live in Lua files under `internal/modfs/builtin`; no inline Lua in Go.
- Import no content during builds. Use committed Lua monster definitions.
- One owner for shape identity; remove the Chaos shifter flag and its old tick path.
- Every new Lua function explains why and how; lines at most 120 characters.
- Keep file traversal out of RNG decisions; use stable catalog ID order.
- Commit this contiguous category once, then fast-forward and push `main`.

## Review Focus

- A natural shifter spawned by an authored vault starts in a legal other form and restores with its original ID.
- Glowing and ordinary variants use distinct rates, while a starting base shape changes immediately.
- A sleeping, paralysed, petrifying, petrified, or stair-transiting actor retains its form for that action.
- A Chaos conversion of an already polymorphed monster retains its first original identity and changes again later.
- Candidate selection excludes incompatible holiness, habitat, unique, stationary, and non-threatening forms.

---

### Task 1: Durable identity and transition policy

**Files:** Create `schemas/combat_monster_shapeshifter.lua` and `policy/monsters/shapeshifter.lua`; modify `constants/component.lua` and `policy/magic/effects/statuses/polymorph.lua`; test in `internal/script/testdata/lua/tests/monster_shapeshifter_test.lua`.

**Interfaces:** `shapeshifter.attach(ctx, monster, variant)`, `shapeshifter.active(ctx, monster)`, `shapeshifter.tick(ctx, monster)`, and `polymorph.random_shifter(ctx, monster, source, stream)`.

- [ ] Write the Lua test for both variants, original identity, first form, and candidate exclusions; run it red.
- [ ] Add a schema with named variant and original kind ID; implement attach and the uniform habitat-compatible species draw with source power rejection; run the test green.
- [ ] Test and implement saved lineage through a second form, including existing Polymorph and Chaos victims.

### Task 2: Runtime ownership

**Files:** Modify `policy/population/factory.lua`, `policy/combat/monster_target_brands/chaos_effects.lua`, `policy/combat/monster_target_brands/chaos_status.lua`, `schemas/combat_monster_chaos.lua`, and `systems/combat_monster_chaos.lua`; create `systems/monster_shapeshift.lua`.

**Interfaces:** Spawn and Chaos call `shapeshifter.attach`; the new system calls `shapeshifter.tick` before `monster.decision`.

- [ ] Extend the Lua test with natural placement and Chaos conversion, plus incapacitation and timing checks; run red.
- [ ] Wire both entry points to the new owner; remove `shifter` from Chaos status and remove its old tick call; run green.
- [ ] Add one live Go placement/save/restore test in `internal/game/monster_shapeshifter_test.go` and prove continuation.

### Task 3: Integration and category commit

**Files:** Modify `policy/save/monsters.lua`, `docs/port-inventory.md`, and existing tests that used the old Chaos shifter API.

- [ ] Add save validation for component owner, variant, and original lineage; prove invalid state fails restore.
- [ ] Run focused Lua/Go tests, then `go test ./internal/script`, relevant `internal/game` tests, `go test ./... -run '^$'`, gofmt, Lua line length, and diff checks.
- [ ] Review the category diff, commit once, fast-forward local `main`, push `origin main`, and verify local tracking refs match.

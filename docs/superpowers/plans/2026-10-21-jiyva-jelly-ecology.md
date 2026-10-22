# Jiyva Jelly Ecology Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this
> plan natively. The user's requested integration unit is the entire
> category: make one implementation commit after all tasks pass.

**Goal:** Make Jiyva's zero-rank slime ecology work on active and visited
inactive floors, including authored `no_jiyva` cells.

**Architecture:** Lua owns eligibility, targets, feeding, splitting, and
periodic decisions. Existing Akara entities and typed vault records hold
the state. Go exposes only sorted visited level IDs for the off-floor rule.

**Tech Stack:** Go, Akara ECS, embedded Lua, source-format DES, Go JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-21-jiyva-jelly-ecology-design.md`

## Global constraints

- Preserve the pinned DCSS source decisions and named RNG order.
- Use Lua for game policy; add no inline Lua or content-ID switch in Go.
- All new Lua functions need why/how comments; every Lua test is `_test.lua`.
- Use shared IDs and property constants at each site, not repeated strings.
- Finish and verify the category before its single commit and push to main.

## Review focus

- A remembered but inactive floor must not be regenerated to consume items.
- An item on an Aquarium `no_jiyva` cell must remain protected even after
  the unrelated Slime:5 seal opens.
- An artefact, rune, Orb, mimic, stationary net, or special miscellany must
  never be selected as a feeding target or consumed on either level path.
- Partial stack consumption, monster HP, and the next RNG draw must survive
  save/restore without replaying an ecology boundary.
- A disabled or sleeping jelly must not feed or move toward floor items.

---

### Task 1: Live per-cell property and item eligibility

**Files:** `policy/religion/jiyva/cells.lua`,
`policy/religion/jiyva/items.lua`, `constants/vault_properties.lua`,
`policy/world/slime_seals.lua`, and
`tests/religion_jiyva_ecology_test.lua` under the embedded mod tree.

**Interfaces:** `cells.allowed(ctx, level_id, x, y) -> bool` reads effective
`KPROP` records and saved Slime release markers. `items.edible(ctx, entity)
-> bool` uses production item definitions and ECS components.

- [x] Write Lua cases for ordinary, Slime:5, and Aquarium property cells;
      verify red before implementation.
- [x] Write the special-item exclusion table using imported IDs and
      component names; test eligible gold and ordinary stacks.
- [x] Implement the two focused Lua owners and verify their tests.

### Task 2: Active jelly feeding and splitting

**Files:** `policy/religion/jiyva/feeding.lua`,
`systems/monster_decision.lua`, `policy/religion/gods/jiyva.lua`,
and `tests/religion_jiyva_ecology_test.lua`.

**Interfaces:** `feeding.act(ctx, monster) -> bool` consumes an action only
when an awake, unsubmerged, eligible slime eats. It updates exact item
quantities and health, then attempts source splitting via existing actor
creation with explicit cloned lineage and energy state.

- [x] Add tests for action consumption, 1–10 budget, gold, partial stack,
      healing cap, splitting, protection, and incapacity; verify red.
- [x] Implement feeding as one Lua call from the monster decision owner.
- [x] Verify focused Lua tests and save validation for changed entities.

The current engine has no submerged-monster state to query. The feeding
gate covers represented incapacity states; submerged feeding remains a
named gap in `docs/port-inventory.md` until that state is ported.

### Task 3: Neutral slime item pursuit

**Files:** `policy/religion/jiyva/targets.lua`,
`systems/monster_decision.lua`, and
`tests/religion_jiyva_ecology_test.lua`.

**Interfaces:** `targets.item(ctx, monster, position) -> position|nil` reads
the active floor's eligible item entities and source sight. Neutral AI
routes to that position before generic wandering; other allegiances use
their existing target flow.

- [x] Test nearest eligible target, no-Jiyva cells, invisibility/LOS, and
      fallback to ordinary wandering; verify red.
- [x] Implement source target selection and the one decision integration.
- [x] Verify focused Lua target tests.

### Task 4: Periodic and off-floor ecology

**Files:** `schemas/religion_jiyva_ecology.lua`,
`systems/religion_jiyva_ecology.lua`,
`policy/religion/jiyva/periodic.lua`, `internal/script/runtime.go`,
`internal/script/context.go`, `internal/game/script_services.go`,
and `tests/religion_jiyva_ecology_test.lua`.

**Interfaces:** `ctx:level_ids()` returns sorted existing level IDs;
`periodic.tick(ctx, player, due_aut)` handles a source timer firing. The
saved component records the next randomly scheduled 100–300 aut event.

- [x] Add red Lua tests for all legal/illegal spawn cells, independent
      one-in-ten and one-in-25 checks, visited-level rejection, protected
      items, and catch-up/save replay.
- [x] Add the generic sorted level enumeration and the Lua clock owner.
- [x] Implement Jiyva spawn and off-floor consumption without creating a
      level or consuming active-floor items.
- [x] Verify focused Lua tests and a Go save/restore integration test.

### Task 5: Modding guide, broad verification, and integration

**Files:** `docs/modding.md`, `docs/port-inventory.md`,
`internal/game/religion_jiyva_ecology_test.go`, and any touched owners.

- [x] Document how `no_jiyva` is declared, when Slime:5 clears its effect,
      and how modded slime genera and item definitions enter the policy.
- [x] Exercise a generated Slime level and restore the next ecology draw.
- [x] Run focused Lua and game tests, compile all Go packages, check
      changed-file readability and formatting, and run `git diff --check`.
- [ ] Complete `go test ./...` and the repository-wide style script. The
      full game package gave no result after 748 seconds, so the run was
      stopped; the style script reports violations only in older files.
- [ ] Commit one Jiyva ecology category and push `main`.

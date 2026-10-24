# Xom Action Engine Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan. Keep one contiguous Xom domain commit; the user's commit granularity overrides per-task commits.

**Goal:** Replace Xom's erroring wrath stub with source-shaped ordinary and wrath actions for every pinned Xom event.

**Architecture:** A Lua action catalog holds individually replaceable event definitions. A selector owns source chance order; focused Lua modules own effects; one Xom owner applies mood and interest around both worship and wrath entry points.

**Tech Stack:** Embedded Lua, Akara components, layered mod filesystem, Go game tests.

**Spec:** `docs/superpowers/specs/2026-10-23-xom-action-engine-design.md`

## Global Constraints

- Gameplay and Xom policy remain in Lua files, with no inline Lua in Go.
- Source event priority is explicit game logic, independent of file load order.
- All mutable lasting state belongs to saved components or level records.
- Each Lua function explains why and how; lines stay at or below 120 characters, preferably near 80.
- Complete the whole category before the single Xom commit and push to `main`.

## Review Focus

- A mod replaces one Xom event file: its effective effect and badness change without changing another event.
- A mod adds an event at a selection stage: ID ties and seeded order are stable under file renaming.
- A wrath action begins during another command: failure restores the command and RNG instead of partly spending it.
- A lasting Xom effect is saved mid-duration: restore resumes it once, without replaying its initial effect.
- A good or bad selector has no eligible event: it returns no action without an unbounded loop.

---

### Task 1: Catalog and stable action interface

**Files:** Create `internal/modfs/builtin/ids/xom_events.lua`, `content/xom_events/*.lua`, `policy/religion/xom/events.lua`; modify `constants/catalog.lua`; add Lua catalog tests.

**Interfaces:** Each event definition has `id`, `side`, `effect_module`, and badness. `events.get(id)` validates and returns the effective definition and effect. `events.apply(ctx, player, id, severity, request)` calls `effect.apply` with the same arguments. Source event IDs are imported where used.

- [ ] Write a Lua test that enumerates every source real event and checks effective definitions and effect modules.
- [ ] Run it red against the current missing category.
- [ ] Register all source IDs as individual Lua definitions and validate module shape.
- [ ] Add a mod overlay test for replacement and one new event; assert stable sorted IDs.

### Task 2: Selection, niceness, and tension

**Files:** Create `policy/religion/xom/selection.lua` and
`policy/religion/xom/eligibility.lua`; extend the existing
`policy/combat/monster_seal_tension.lua` only for missing source rules; add
Lua tests.

**Interfaces:** `selection.choose(ctx, player, nice, severity, tension,
stream)` returns an event ID or nil. The shared
`monster_seal_tension.current(ctx, player)` returns local tension.
`eligibility` exposes source monster, terrain, form, and branch checks reused
by effects.

- [ ] Write fixed-draw cases for source order, good and bad suppression, severity floor, no-action, and nearby-hostile tension.
- [ ] Run them red, then port the pinned source selection chain and tension formula into named helpers.
- [ ] Verify adding an event by catalog stage does not reorder source stages or depend on path order.

### Task 3: Beneficial effects

**Files:** Create focused `policy/religion/xom/effects/*.lua` modules for divination, spells, allies, monsters, items, mutations, clouds, terrain, combat, and teleportation. Extend the generic effect owners only where a mechanic is actually missing.

**Interfaces:** Every source good event resolves through `events.apply`. Effects use live entity, grid, status, inventory, and travel owners and return their actual result for action narration.

- [ ] Write Lua tests for all 23 good event IDs and representative live effects from each family.
- [ ] Run red, implement their source parameters and target rules, then run the focused cases green.
- [ ] Verify generated allies and items are real saved ECS entities rather than presentation-only records.

### Task 4: Harmful effects

**Files:** Add the remaining `policy/religion/xom/effects/*.lua` modules; add schemas for any timed stair, trail, or travel state; extend generic owners where required.

**Interfaces:** Every source bad event resolves through `events.apply`, with its source badness and safe/unsafe death rule available to the Xom owner.

- [ ] Write Lua tests for all 19 bad event IDs, including banishment, stair repulsion, chaos upgrade, and monster movement.
- [ ] Run red, implement live effects, then run the focused cases green.
- [ ] Verify save/restore and expiry for every new lasting state record.

### Task 5: Xom worship and wrath owner

**Files:** Create `policy/religion/xom/actions.lua`,
`policy/religion/xom/mood.lua`, `policy/religion/xom/stimulation.lua`, and
`systems/xom_reaction.lua`; replace `policy/religion/wrath/xom.lua`.
Remove the inert pending Xom component and add specific saved schemas for
lasting effects as needed.

**Interfaces:** `actions.act(ctx, player, request)` selects and applies one
event, then source mood and interest updates. `mood.drift(ctx, player, stream)`
runs from the completed player action. `stimulation.apply(ctx, player, amount,
kind, options)` handles outside events and the immediate ecumenical reward.

- [ ] Write Lua tests for bored action chance, mood drift, stimulation cap, wrath one-in-ten good chance, and post-action piety reroll.
- [ ] Run red, connect the shared owner to worship and retribution, then run green.
- [ ] Keep ordinary and wrath entry points on the same effect path and choose their requested RNG stream explicitly.

### Task 6: Integrated game verification and category commit

**Files:** Add `internal/game/xom_action_game_test.go`, update `docs/port-inventory.md` and modding guide for event files.

- [ ] Add game checks for Xom action timing, Divine Wrath, seeded transcript, save/restore, and rollback on an invalid action.
- [ ] Run focused Lua and Go checks and both command builds after the related work is assembled.
- [ ] Run `git diff --check` and `sh scripts/check-go-style.sh`; fix new findings.
- [ ] Review the whole Xom diff against the source event list and spec review focus.
- [ ] Commit the contiguous Xom category once, then push `main`.

# Lugonu active abilities implementation plan

> **For agentic workers:** Use the existing Lua-first engine and execute
> this as one coherent Lugonu category. Keep the category in one commit.

**Goal:** Make all six source Lugonu powers playable, saved, and visible
through the ordinary terminal ability flow.

**Architecture:** Focused Lua ability modules call the existing Abyss,
grid, teleport, banishment, piety, and inventory owners. Corruption adds
one saved level-scoped nexus record and a time-driven system. Generic
Go code changes only where the current ECS or grid APIs lack a required
operation.

**Tech stack:** Go, Akara ECS, embedded Lua, Bubble Tea terminal client.

**Spec:** [Lugonu active abilities design](../specs/2026-10-23-lugonu-active-abilities-design.md).

## Global constraints

- Production rules live in Lua files, never inline Go strings.
- Every Lua function has a why/how comment; each system has a theory of
  operation; lines are at most 120 columns.
- Import named IDs where used; keep Lua declarations readable and flat.
- Extend generic owners directly. Do not add a C++ API adapter or a
  second item, level, or monster state model.
- One commit covers the complete Lugonu ability category and is pushed
  to `main` after verification.

## Review focus

- A prompt cancelled at either step leaves time, resources, and saved
  pending choices unchanged or cleared as appropriate.
- Penance or conversion between prompt and action prevents stale use.
- An occupied or protected grid cell is never replaced by solid
  corruption terrain without a valid displacement.
- A corrupted level and all nexus timers survive save/restore exactly.
- A blessed weapon cannot be blessed again after changing gods.

## Task 1: Shared divine ability costs and Lugonu registration

**Files:** `policy/abilities/god_costs.lua`, the Beogh ability modules,
`ids/abilities.lua`, and the Lugonu ability modules.

1. Write Lua tests for source rank, penance, failure draws, and cost
   commitment across Beogh and Lugonu.
2. Move Beogh's generic cost arithmetic into one parameterized owner;
   update Beogh callers and remove the Beogh-only copy.
3. Register six named Lugonu IDs and menus with source ranks and costs.
4. Run the focused Beogh and Lugonu Lua tests.

## Task 2: Abyss travel and spatial powers

**Files:** Lugonu `depart.lua`, `enter.lua`, `bend_space.lua`,
`banish.lua`; existing `world/abyss.lua` and movement or zap owners only
where a generic operation is missing.

1. Test a real Abyssal Knight's Depart and Enter, including saved return
   position, unsafe-fight ice-status confirmation, failure, and restore.
2. Test Bend's player blink and each adjacent monster eligibility path.
3. Test Banish targeting, will resistance, successful monster transit,
   cancellation, and source power and cost.
4. Implement the Lua abilities using the existing ECS and grid owners;
   keep each ability in its own file.

## Task 3: Permanent corruption and nexus time

**Files:** `policy/abilities/lugonu/corrupt.lua`, a corruption schema,
`systems/religion_lugonu_corruption.lua`, save validation, and any
general terrain operation required by the current grid owner.

1. Test source nexus count, durations, protected terrain, wall
   resistance, occupant displacement, and servant spawning.
2. Record nexus positions and duration on the level, preserving them
   through save/restore and rejecting impossible positions or clocks.
3. Apply the initial terrain pass and 300-aut immediate effects, then
   tick remaining effects with normal player time.
4. Verify the resulting floor with a text snapshot that shows changed
   terrain and connections.

## Task 4: Once-only distortion blessing

**Files:** `policy/abilities/lugonu/bless_weapon.lua`, item policy,
generic selection and confirmation paths, and worship save validation.

1. Test only carried, non-artefact melee weapons appear as choices.
2. Test cancellation and selection revalidation across a saved prompt.
3. Apply distortion and two enchant steps to the original item, then
   set the existing one-time worship key.
4. Test leaving and rejoining Lugonu after the blessing.

## Category verification and integration

Run focused Lua rules, affected Go game and terminal tests, then
`go build ./...` and `git diff --check`. Review source-facing messages,
all changed Lua comments, and line lengths. Commit the whole Lugonu
category once and push `main`.

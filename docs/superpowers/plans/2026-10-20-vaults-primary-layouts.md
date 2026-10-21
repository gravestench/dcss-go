# Vaults Primary Layouts Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan natively. The user
> authorized category-sized work on `main`; commit each coherent category
> and push `origin main` as it passes.

**Goal:** Make the complete source primary-layout family populate playable
Vaults:1–4 floors from committed `.des` room content.

**Architecture:** Eleven named Lua layout hooks share geometry and room
placement owners. A sorted Lua room catalog reads original-format DES
files. Existing generation, ECS population, branch links, and saves carry
the resulting floor without a Go rule for Vaults.

**Tech Stack:** Go 1.25, gopher-lua, layered modfs, Akara ECS, `.des` maps,
Bubble Tea terminal.

**Spec:** `docs/superpowers/specs/2026-10-20-vaults-primary-layouts-design.md`

## Global constraints

- Preserve the original `.des` map format; committed files are runtime
  content, with no importer in the game repository or build path.
- All executable gameplay and generation rules live in readable Lua files,
  with named helpers, why/how comments, and no source-order seed coupling.
- Keep the existing branch ID, dense grid, ECS actor, Go save, and terminal
  owners. Do not add a Go Vaults layout switch.
- V:5 requires the separate end-vault category; do not turn it into a
  generic primary layout. Preserve the source branch depth of five.
- Work on `main` and push verified corpus, layout, and branch categories as
  they are completed.

## Review focus

1. A mod file with a duplicate room NAME fails with both paths; source
   order cannot decide which room wins.
2. Each source hook in a room file has a named Lua implementation; a
   missing hook fails during catalog validation.
3. A failed room fit cannot overwrite stairs, the parent entrance, or
   previously placed room records.
4. Every primary motif remains connected after room insertion and stair
   completion, including sparse maze cases.
5. V:4's next stair cannot create a generic V:5 floor; save restore must
   reject a forged resolved link there.

---

### Task 1: Commit and validate the complete Vaults room corpus

**Files:** Create individual `.des` files under
`internal/modfs/builtin/vaults/vaults_room/`; add named hooks under
`policy/generation/vaults/vaults_room/` as needed; add a sorted room
catalog under `policy/generation/layouts/vaults/rooms.lua`; add Lua tests
under `internal/script/testdata/lua/tests/`.

**Interfaces:** `rooms.ids(tag)` yields eligible stable IDs;
`rooms.get(id)` yields the parsed DES definition;
`rooms.choose(ctx, tag, state)` draws by source weight;
`rooms.place(ctx, builder, id, origin, orientation)` uses the existing
DES placement result and returns typed records.

- [ ] Write a source corpus test for all 99 standard, 58 hard, and 93
  empty definitions in the dedicated files, plus tagged rooms elsewhere.
  Resolve hook-added tags before counting; reject missing or duplicated
  IDs and unsupported hooks.
- [x] Deliberately split the three pinned source files into 250 named
  `.des` files. Expand shared source setup into equivalent directives at
  its source position and port the named feature hook. The temporary
  splitter stays outside the repository.
- [ ] Implement room selection, orientation, bounded fit, and existing
  DES placement integration; test room records and occupied-cell vetoes.

### Task 2: Port all 11 primary layout shapes through shared Lua owners

**Files:** Add 11 `.des` files under `vaults/layout/` and named hooks under
`policy/generation/layouts/`; create focused shared modules under
`policy/generation/layouts/vaults/` for paint, geometry, materials,
placement, and connectors. Extend the layout catalog only where a shared
hook result needs room records. Add Lua tests for all 11 IDs.

**Interfaces:** Each named hook accepts the existing layout `api` and
returns `{builder, rows, records}`. The shared builder uses the source
motif parameters and local depth, then inserts tagged rooms through Task
1's catalog before the generic stair pass.

- [ ] Test every layout ID's source weight, tags, depth, motif geometry,
  connected playable region, room pool selection, and saved record IDs.
- [ ] Port the 11 source layouts and their shared wall/room algorithms to
  small Lua functions; do not copy the source global `hypervaults` API.
- [ ] Run the focused Lua layout and room tests; refine failed sparse
  shapes and room placement until the complete family passes.

### Task 3: Open Vaults:1–4 through the ordinary branch topology

**Files:** Modify `policy/generation/generated.lua`, branch generation
availability policy, and `policy/save/generated_levels.lua` as needed;
add focused Go tests in `internal/game/` and update the modding guide and
port inventory.

**Interfaces:** The branch generation policy reports executable depths
without changing the source `branch.depth`. The generic stair installer
and save validator consume that result; V:5 remains a named pending
frontier for the separate end-vault implementation.

- [ ] Test Dungeon→V:1, V:1→V:4, exact reciprocal return, population,
  save/restore, two simultaneous branch frontiers, and a forged V:5 link.
- [ ] Keep V:5 unavailable until its source end-vault owner exists, while
  selecting and placing all 11 primary layouts on V:1–4.
- [ ] Update source-traced modding and inventory docs; run affected Lua
  and game suites sequentially, style and diff checks, commit the whole
  category on `main`, and push `origin main`.

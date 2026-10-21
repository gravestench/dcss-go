# Spider Vault Family Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan in the current session. Its task checkboxes track completion.

**Goal:** Port the 94 missing Spider DES definitions and their Lua
behavior, including the source basket trigger.

**Architecture:** Existing DES catalog and branch-entry owner select
maps. Named Lua modules implement source scripts. Typed marker records
materialize saved ECS trigger entities, and a generic Lua system invokes
their named callback on player movement.

**Tech Stack:** Go, Lua, DES, Akara ECS, layered modfs.

**Spec:** `docs/superpowers/specs/2026-10-20-spider-vault-family-design.md`

## Global Constraints

- Keep source MAP rows and non-script directives in their original order.
- Add inherited `DEPTH: Spider` only to affected `spider.des` maps.
- Put executable Lua in named, commented modules, never inline in Go.
- Preserve source semantics for every conditional branch and draw order.
- Commit this contiguous category on `main` and push `origin/main`.

## Review Focus

1. Spider entry maps must not enter ordinary or helper selection.
2. Jumping helper maps must be selected only by their parent's tag.
3. The selected keyed `O` cell must own the reciprocal Spider link.
4. Source marker callbacks must fire once, after movement, across save.
5. Existing Spider:4 endings must remain mandatory and exclusive.

### Task 1: Source maps and hooks

**Files:** `internal/modfs/builtin/vaults/spider*/*.des`,
`internal/modfs/builtin/policy/generation/vaults/spider/*.lua`,
`internal/script/testdata/lua/tests/spider_vault_family_test.lua`.

- [x] Add a failing catalog and placement test for 11 entries, 66 ordinary
  maps, and 17 jumping definitions; run it to confirm the missing count.
- [x] Commit every new definition as a separate DES file and port source
  inline Lua to named handlers, with one shared jumping setup helper.
- [x] Compare new MAP rows and ordered gameplay directives to source;
  exercise all hooks and map placements through production Lua.

### Task 2: Entry and mod integration

**Files:** `policy/generation/vaults/branch_entry.lua`,
`internal/game/spider_vault_family_test.go`,
`internal/script/testdata/spider-vault-mod/`.

- [x] Add Spider family, tag, and keyed feature constants and a declarative
  source-entry specification. Confirm the test fails before implementation.
- [x] Exercise source-weighted candidates, fit retry, keyed stair,
  reciprocal travel, save/restore, and sparse mod additions.

### Task 3: Trigger behavior

**Files:** `schemas/world_vault_trigger.lua`,
`policy/world/vault_triggers.lua`, `systems/world_vault_triggers.lua`,
`policy/generation/vaults/spider/spiders_nest_spider_trap.lua`,
`policy/world/vault_trigger_callbacks/spider_nest.lua`,
`policy/population/vaults.lua`.

- [x] Add a failing Lua test for marker materialization, one-shot
  movement dispatch, warning text, redback spawn cells, and save state.
- [x] Implement one generic ECS vault-trigger owner and the Spider
  callback using existing monster factory and source IDs.
- [x] Run focused Lua and Go integration tests until they pass.

### Task 4: Integrated verification and delivery

**Files:** `docs/modding.md`, `docs/port-inventory.md`, this plan.

- [x] Update the modding guide's hook and marker contract and inventory.
- [x] Run relevant Lua, Go, compile, source-audit, and style checks once
  across the finished category; fix any concrete failures.
- [x] Review the complete category, commit once, push `origin/main`, and
  verify the worktree is clean.

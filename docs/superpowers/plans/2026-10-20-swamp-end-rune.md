# Swamp End Vault and Decaying Rune Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. Steps use checkbox
> syntax for tracking. The user authorized contiguous commits on `main` and
> pushes to `origin/main`.

**Goal:** Port all eleven Swamp:4 end maps and one collectible decaying rune.

**Architecture:** Keep source DES maps as runtime content, port their Lua
script sites to named hooks, and reuse the generic mandatory end-vault,
item, branch-travel, and save paths.

**Tech Stack:** Go, gopher-lua, layered modfs, Akara ECS, DES, Bubble Tea.

**Spec:** `docs/superpowers/specs/2026-10-20-swamp-end-rune-design.md`

## Global constraints

- Do not commit importers or require the C++ tree during a build or test.
- Keep each MAP row byte-for-byte equal to the pinned source.
- Put gameplay decisions in readable Lua files with function and why/how
  comments; keep lines within 120 columns.
- Reuse generic end-vault placement and ECS rune pickup rather than adding
  branch-specific Go switches.
- Commit and push one coherent implementation category after integrated
  verification, as the user requested.

## Review focus

1. Every source `PLACE: Swamp:$` definition participates in the weighted
   pool and a non-family optional map cannot replace the mandatory ending.
2. Source one-in-eleven decisions emit their directives at the original
   position, including the alternate rune guardian branch.
3. Zero or two resolved runes reject a map; selection stays pinned when
   generation redraws the base floor.
4. Missing or malformed end content seals generation or fails clearly.
5. Save restore rejects an extra rune record from an unselected source and
   a rune record owned by the wrong historical map.

---

### Task 1: Source family and hooks

**Files:** Create eleven `internal/modfs/builtin/vaults/swamp_end/*.des`
files and four named Lua hook files under
`internal/modfs/builtin/policy/generation/vaults/swamp_end/`.
Modify `internal/modfs/builtin/content/branches/branch_swamp.lua`.

- [ ] Extract exact end blocks from pinned `swamp.des`; audit MAP bytes once.
- [ ] Replace the four inline script sites with named hooks that preserve
      their original operation positions and source probabilities.
- [ ] Add a Lua corpus test for all eleven effective definitions, source
      dimensions, checksums, and explicit end PLACE rules.
- [ ] Add a Lua placement test exercising transforms, records, and one real
      decaying rune for each authored map over representative seeds.

### Task 2: Live play, mods, and documentation

**Files:** Add focused tests under `internal/game/` and
`internal/script/testdata/`; update `docs/modding.md` and
`docs/port-inventory.md`.

- [ ] Travel from Lair through Swamp:4 using generated stair links and check
      the selected end identity, rune entity, and exact return landing.
- [ ] Pick up the rune, round-trip a Go save, and reject forged end-map and
      rune-history records.
- [ ] Add one sparse VFS mod map and assert it enters the Swamp end pool.
- [ ] Run focused Lua and game integration tests, source MAP audit, and
      `git diff --check`; inspect failures and fix within this category.
- [ ] Commit the coherent slice, push `origin/main`, and leave the full
      DCSS port goal active for remaining branches and domains.

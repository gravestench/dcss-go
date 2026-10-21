# Spider End Vault and Gossamer Rune Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native implementation. Steps use checkbox
> syntax for tracking. The user authorized contiguous commits on `main` and
> pushes to `origin/main`.

**Goal:** Port all nine Spider:4 source endings and one collectible gossamer rune.

**Architecture:** Keep exact source MAPs in DES, translate the source Lua
sites into named policy modules, and reuse the generic required ending,
Akara item pickup, travel, and save paths.

**Tech Stack:** Go, gopher-lua, layered modfs, Akara ECS, DES, Bubble Tea.

**Spec:** `docs/superpowers/specs/2026-10-20-spider-end-rune-design.md`

## Global constraints

- Commit source content as individual DES files; importers stay outside repo.
- Preserve MAP bytes, script-site order, and one real gossamer rune per map.
- Keep Lua functions focused and commented, with lines no longer than 120.
- Add no Spider-specific Go placement or save switch.
- Verify the integrated slice, then commit and push it as one category.

## Review focus

1. Exact MAP bytes and all nine end candidates are retained.
2. Three-way theme and density choices reproduce source draw order.
3. Shared loot emits three independent item requests per map.
4. Spectre suffixes resolve through the same derived monster as spectral names.
5. Save history rejects a forged Spider map or rune owner.

---

### Task 1: Source definitions and hooks

**Files:** `vaults/spider_end/*.des`,
`policy/generation/vaults/spider_end/*.lua`, `content/branches/branch_spider.lua`.

- [ ] Copy nine source ending blocks and audit MAP rows byte for byte.
- [ ] Replace conditional, loot, and feature-name script sites with named hooks.
- [ ] Declare Spider's required end family and source out-of-depth cap.
- [ ] Check corpus dimensions, hashes, all candidates, and one rune per fit.

### Task 2: Integration and documentation

**Files:** `internal/game/spider_end_test.go`,
`internal/script/testdata/spider-end-mod/`, `docs/modding.md`,
`docs/port-inventory.md`.

- [ ] Support the source `spectre` suffix in generic monster resolution.
- [ ] Travel to Spider:4 and verify reciprocal stairs, rune pickup, and saves.
- [ ] Add one sparse mod map and verify it joins weighted selection.
- [ ] Run focused Lua and Go suites and diff/style checks; fix any failures.
- [ ] Commit the category and push `origin/main`.

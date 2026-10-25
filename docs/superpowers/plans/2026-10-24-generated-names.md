# Generated Names Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans natively. The
> user authorized the recommended method and one category commit.

**Goal:** Replace generated-name approximations with the source's three
`make_name` modes and private seeded spelling stream.

**Architecture:** A reusable Go local PCG primitive exposes bounded draws
to Lua; one Lua policy owns all name spelling and callers use it by mode.
Existing owners continue to save completed names or appearance seeds.

**Tech Stack:** Go, GopherLua, Lua, Akara ECS.

**Spec:** `docs/superpowers/specs/2026-10-24-generated-names-design.md`

## Global constraints

- One commit for this complete category, then push `main`.
- No inline Lua in Go. Gameplay name policy stays in Lua files.
- Lines at most 120 columns; comments explain source rules and why.
- No C++ checkout or importer at build/runtime.

## Review focus

- Bound-one RNG draws consume no private word; compare against the source.
- Rejection sampling at a large bound returns an unbiased value.
- Scroll seeds map to distinct source words and survive restore.
- Jiyva names stay within eight characters and never contain a space.
- Vault hooks use the same name policy without changing map load order.

## Task 1: Private name stream

**Files:** `internal/script/source_rng.go`, `internal/script/context.go`,
`internal/script/runtime.go`, `internal/game/script_services.go`,
`internal/script/source_rng_test.go`.

- [x] Add failing Go vectors for PCG initialization, bounded draws,
  bound-one behavior, and independent streams.
- [x] Implement a short-lived PCG stream in Go and expose a Lua context
  method that creates it from the session seed and a 32-bit name seed.
- [x] Verify the direct Go vectors and Lua binding.

## Task 2: Shared Lua name owner

**Files:** `internal/modfs/builtin/policy/names/source.lua`,
`internal/modfs/builtin/constants/name_modes.lua`, Lua `_test.lua` files.

- [x] Add failing known-seed tests for ordinary, scroll, and Jiyva names,
  plus source phonetic edge conditions.
- [x] Port the source algorithm into short, commented Lua functions using
  the local PCG stream. Keep the name tables in one production module.
- [x] Verify source examples and sparse mod override behavior.

## Task 3: Source callers

**Files:** `policy/items/appearances.lua`, `policy/population/pan_lord.lua`,
`policy/generation/vaults/operations.lua`, Jiyva name initialization,
artefact and book fallback owners, and focused tests.

- [x] Add failing caller tests for scroll labels, Pan lord names, vault
  hook names, ordinary shops, artefact fallbacks, and Jiyva's second name.
- [x] Route direct source `make_name` uses through the shared policy and
  keep their existing saved-state ownership.
- [x] Verify save/restore and deterministic next-draw behavior.

## Task 4: Category verification

- [x] Run focused Lua/Go tests covering every changed caller and build
  `cmd/crawl`; run `gofmt`, changed-file style, and `git diff --check`.
- [x] Update `docs/modding.md` and `docs/port-inventory.md` with the API
  and exact remaining random-name limitations.
- [x] Commit the contiguous category once and push it to `origin/main`.

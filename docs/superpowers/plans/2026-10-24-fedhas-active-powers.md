# Fedhas Active Powers Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all four source Fedhas active powers playable and persistent.

**Architecture:** Four Lua ability files register source costs and gates. A
focused plant policy owns source placement, HD, lifetime, and Overgrow
terrain selection; the existing ECS summon and grid APIs own persistence.

**Tech Stack:** Go, Akara ECS, embedded Lua, production Lua test harness.

**Spec:** `docs/superpowers/specs/2026-10-24-fedhas-active-powers-design.md`

## Global Constraints

- Port from pinned `crawl-ref` source, without inline Lua in Go.
- Comment each Lua function with why and how; keep lines under 120 columns.
- Commit and push the whole Fedhas category on `main` as authorized.

## Review Focus

- Invalid aim, occupied cell, no nearby briar cell: free rejection.
- Penance and insufficient MP: unavailable or free rejection.
- Vault veto and permanent rock: never destroyed by Overgrow.
- Summons: correct god source, allegiance, finite duration, and save.
- Source RNG: one failure check and source weighted Overgrow selection.

## Task 1: Rules and actors

**Files:** Add `policy/abilities/fedhas/*.lua` and
`policy/religion/fedhas/active_plants.lua`; modify `ids/abilities.lua`;
add `internal/script/testdata/lua/tests/religion_fedhas_active_powers_test.lua`.

**Interfaces:** Register the four source IDs in `policy.abilities.registry`.
The plant policy provides named cell eligibility and effect functions
used by the ability modules.

- [x] Write a Lua rule test for ranks, gates, summons, and terrain.
- [x] Run `go test ./internal/script -run 'TestLuaRules/religion_fedhas_active_powers_test'` and observe a missing ability failure.
- [x] Implement the named abilities and plant policy.
- [x] Run the focused Lua rule and refine until green.

## Task 2: Game path and documentation

**Files:** Add `internal/game/religion_fedhas_active_powers_test.go`;
modify `docs/port-inventory.md` and `docs/modding.md` if relevant.

- [x] Write command and save/restore integration tests and observe failure.
- [x] Resolve any game bridge or validation gap exposed by the test.
- [x] Run the focused Lua and Go tests, `go build ./cmd/crawl`, and style check.
- [x] Review the combined diff, commit the category, and push `main`.

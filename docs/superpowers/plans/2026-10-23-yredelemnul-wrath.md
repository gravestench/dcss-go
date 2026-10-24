# Yredelemnul Wrath Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task.
> This domain is committed once after integrated verification.

**Goal:** Complete the Yredelemnul undead wrath branch and its saved ECS
ownership.

**Architecture:** Read the effective Lua Dungeon population to choose
zombie bases. Use the existing `magic.summon` and
`magic.summon_undead` records for hostile servants. Identify permanent
friendly god gifts from those same source and expiry fields for soul
reclaim; the summon owner dismisses them.

**Tech Stack:** Lua policies and content, Akara dynamic ECS, Go game
save tests.

**Spec:** `docs/superpowers/specs/2026-10-23-yredelemnul-wrath-design.md`

## Global constraints

- Keep gameplay policy in Lua files and committed content in the embedded
  mod tree. Do not add inline Lua to Go.
- Name shared IDs through existing constants and catalog modules.
- Comment every new function with its source relationship and rationale.
- Keep lines at most 120 columns and prefer 80.
- Commit the integrated Yredelemnul category once, then push `main`.

## Review focus

- A follower with no eligible permanent undead gift falls through to
  servant attempts without consuming an extra branch draw.
- A skeleton result never uses a base with `M_NO_SKELETON`.
- A blocked level cannot hang retrying servant placement forever.
- A save restores god-owned derived undead with its base and allegiance.
- The population choice remains stable under file load order changes.

## Tasks

### Task 1: Source-backed undead ownership

- [x] Add an effective-Dungeon zombie-base picker under
  `policy/population/` using the existing population catalog, source
  eligibility filters, and the level-based depth rule.
- [x] Extend the necromancy summon owner only where a god-owned derived
  undead needs the same saved base, HP, and HD as a spell-owned one.
- [x] Validate permanent friendly Yredelemnul gifts and hostile derived
  undead on save without relaxing unrelated source checks.

### Task 2: Complete Yredelemnul wrath

- [x] Replace the two explicit errors in
  `policy/religion/wrath/yredelemnul.lua` with soul reclaim and zombie
  placement, preserving source branch and attempt order.
- [x] Add production-schema Lua scenarios for reclaim, fallback,
  zombie and skeleton selection, and blocked placement.
- [x] Add a focused game save/restore scenario for a god-owned derived
  undead.

### Task 3: Integrated verification and publication

- [x] Run focused Lua and Go game tests, `go build ./...`, whitespace and
  changed-file line checks. Update the card plan and port inventory.
- [x] Commit this category once and push `origin/main`.

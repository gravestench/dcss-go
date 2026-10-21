# Pandemonium Domain Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the full source Pandemonium map family and repeated portal travel playable in the Go engine.

**Architecture:** Lua owns source DES map choice, shared map hooks, portal travel, and saved Pan policy. Go adds only generic level replacement and portal facts to its grid/save kernel. Akara owns every live item and monster in the current region.

**Tech Stack:** Go, Akara ECS, committed DES and Lua in the layered mod tree, Bubble Tea terminal, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-21-pandemonium-domain-design.md`

## Global Constraints

- Work from the current Go `main`. Commit and push each complete contiguous
  category: source content and hooks, region generation, then portal travel.
- Import all 141 active Pan definitions from the pinned source as separately replaceable committed `.des` files; omit the one source-tagged `removed` fault.
- Port inline source Lua into documented named `.lua` handlers; no executable Lua in DES or Go strings.
- Keep source-specific policy in Lua and durable state in Akara or explicit session records.
- Keep source MAP rows intact; do not create a generation-time C++ dependency or commit an importer.
- Give each Lua function a why/how comment and keep handwritten lines within 120 characters.

## Review Focus

- A failed Pan portal leaves floor, return site, RNG, and entity identities unchanged.
- Two transits create two new regions and retire the previous region's entities, including its rune.
- A save in the second region restores its map, lord history, return site, and next region draw.
- A Pan exit reaches a safe cell near its original portal without creating a reciprocal Pan stair.
- An overlay adding one Pan map joins the correct weighted pool without changing the base files' discovery-order semantics.

---

### Task 1: Commit the complete source map family and Lua hook contracts

**Files:** `internal/modfs/builtin/vaults/pan/*.des`, `vaults/pan_entry/*.des`, `policy/generation/vaults/pan/*.lua`, `policy/generation/vaults/pan_entry/*.lua`, relevant shared constants/IDs, source map audit tests.

**Interfaces:** Existing DES parser and `vault.run`, `vault.veto`, `vault.validate`, `vault.post_place` handler signatures. Each source `NAME` stays a stable catalog ID.

- [ ] Write a source inventory test asserting all 141 active names, map rows, script positions, and family assignments against committed manifests.
- [ ] Split the pinned `pan.des` into individually named files, retaining MAP bytes and ordinary directives; do this with temporary tooling outside the repository.
- [ ] Translate the repeated source script functions into focused Lua handlers and replace each executable site with a named hook plus explanatory source comments.
- [ ] Exercise every map through parser, hook validation, and appropriate placement path; resolve unsupported directives as typed records with a specific pending reason.

### Task 2: Pan level selection and state

**Files:** `policy/generation/pan/*.lua`, Pan population integration, `policy/generation/vaults/primary.lua`, saved Pan session schema/policy, integrated Pan generation tests.

**Interfaces:** `pan.generate(ctx, region, history)` returns one current level plan and stable selected vault IDs. `pan.next_region(ctx, state)` advances only after a successful plan.

- [ ] Write failing tests for every primary group, the source unseen-lord pressure, rune/decoy selection, and stable sorted draws.
- [ ] Select one mandatory primary per region using the imported effective catalog, then place optional maps and population through existing shared owners.
- [ ] Persist region count and map/unique history; validate them without regenerating the floor on restore.
- [ ] Run source-map placement and deterministic save/restore tests at this domain boundary.

### Task 3: Portal travel and level replacement

**Files:** `policy/world/pan/*.lua`, command and world-stair policies, generic Go level replacement service and save fields, terminal input/presentation, integrated travel tests.

**Interfaces:** Lua records a saved portal origin, requests generic replacement of the one Pan level ID, and moves the player through source entry/transit/exit features. Go publishes only the resulting level and ECS lifecycle operation.

- [ ] Write failing travel tests for entry, transit twice, exit, Abyss exit, unsafe return cell, failed generation rollback, and save in a later region.
- [ ] Add generic atomic level replacement and entity retirement; keep rules and branch decisions in Lua.
- [ ] Wire portal feature commands, source messages, client symbols, and the saved return site.
- [ ] Verify old Pan items and monsters cannot survive into the next region or reappear after restore.

### Task 4: Whole-domain verification and guide

**Files:** `docs/modding.md`, `docs/port-inventory.md`, Pan overlays and tests.

- [ ] Add an overlay test with one new Pan map and a same-path hook override.
- [ ] Explain Pan map families, shared hooks, region state, and portal API in the modding guide.
- [ ] Run relevant Lua, generation, game, terminal, save, style, and compile checks once at the category boundary; investigate substantive failures.
- [ ] Review the complete domain against the spec, commit each remaining
  contiguous category, and push `main`.

## Current verification and remaining parity

The source map import, weighted selection, Lua hooks, region replacement,
portal commands, safe exit, Abyss return, and saved lord profile are on
`main`. The ring's eight cloud types now use the saved ECS cloud owner.
Targeted game and Lua integration tests pass for these paths. A full
repository test attempt with a four-minute timeout reached the unrelated
Wanderer gift and item-generation suites before their packages finished;
Pan-focused tests and compilation of every package passed separately.

The generated lord's non-brand melee flavours now reach live player and
monster targets through the ordinary saved combat owners. Its source-style
name and source colour choice are saved on the actor and projected into
combat messages and terminal views. The remaining appearance gap is the
animated `ETC_RANDOM` terminal tint. Trample now separates defender movement
from the attacker's final follow and checks dangerous terrain, expiring
flight, holds, traps, and Passwall. Source player-moving suppression awaits
the opportunity-attack scheduler. An authored Hellion Island rune now runs
from its DES placement through pickup, repeated transit, restore, and exit;
an uncollected authored rune is also retired with its old region. Pain brand
uses the same live spellbook owner as casting for a Pan lord's dynamic
`MST_GHOST` slots. Remaining Pan checks include the other authored rune
families and animated colour cycling. The existing replay test also compares
the complete next-region save after restore.

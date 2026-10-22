# Bazaar Portal Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans for native execution. The user authorized
> category-sized commits on `main` and pushes as work proceeds.

**Goal:** Make all 55 source Bazaar maps usable in a saved, playable
one-floor portal with source timed entries and ordinary shops.

**Architecture:** The layered `.des` catalog owns maps, named Lua hooks
own generated directives and travel policy, Go provides generic level
staging and save storage, and the existing Lua shop owner fills and sells
stock. No Bazaar content switch belongs in the Go kernel.

**Tech Stack:** Embedded Lua, DES, Akara ECS, generic Go level services,
Bubble Tea terminal, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-21-bazaar-portal-design.md`

## Global constraints

- Preserve all 55 source map identities and 54 authored MAP blocks. Keep
  original `.des` declarations except for ported inline Lua sites.
- Lua files and functions carry explanatory comments. Lines stay within
  120 characters; multi-field declarations are broken over lines.
- Generated source is committed; the C++ checkout is read-only evidence.
- Keep the Bazaar maps and their playable portal together in one commit;
  a selectable entrance must never lead to an unfinished destination.
  Test the completed category, then push it to `origin main`.

## Review focus

1. Timed entries cannot vanish while the player is already inside.
2. A failed Bazaar build leaves the entrance and shop stock unchanged.
3. A modded map joins the weighted pool independently of file order.
4. Exiting and re-entering cannot regenerate stock or duplicate gold.
5. Restore rejects a forged map ID, timer, or return site.

## Work

### Category 1: Complete source map and hook corpus

- [x] Add failing Lua tests that enumerate 13 entrance IDs and 42 Bazaar
      layout IDs, compare 54 authored MAP blocks to pinned source evidence, and run
      production DES parsing and hook validation for every definition.
- [x] Split the source file into 55 individually named `.des` files. Port
      its utility Lua into focused named hooks, preserving directive order
      and source semantics for conditional substitutions and shop setup.
- [x] Generate each Bazaar layout through the existing vault placement
      path; resolve keyed shops, authored actors, terrain, and entry/exit.
- [x] Run the Bazaar Lua suite and relevant vault placement checks. Keep
      this corpus with the portal runtime in the Bazaar domain commit.

### Category 2: Portal timing, travel, and persistence

- [x] Add Lua and Go tests for source entries and layouts, timer expiry,
      stage rollback, one-way entry, exact return, and save tampering.
- [x] Add generic portal state and feature support to Go only where grid,
      level staging, or save encoding needs it. Keep duration selection,
      map selection, travel decisions, and messages in Lua policy.
- [x] Wire the `bzr_entry` tag request to the normal vault selector. Create
      one selected Bazaar floor, materialize its existing shop definitions,
      and make its exit return to the saved origin without rerolling.
- [x] Implement Bazaar-scoped shop bargain and source stock-quality rules
      in Lua; test quoted and purchased prices in a live game.
- [x] Update the modding guide, port inventory, and client messages.
      Run focused integrated tests, all-package compile, changed-file style
      and diff checks; review, commit the Bazaar category, and push `main`.

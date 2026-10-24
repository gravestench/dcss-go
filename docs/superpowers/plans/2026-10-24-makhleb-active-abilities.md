# Makhleb Active Abilities Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make all four source-backed Makhleb powers available, functional, and saveable as one patron domain.

**Architecture:** Lua ability modules own the patron rules and call shared HP, beam, summon, and cost owners. One Makhleb roster serves abilities, wrath, and validation. Generic owners gain only reusable operations; Go remains unaware of Makhleb names.

**Tech Stack:** Lua rules and `_test.lua` harness, Akara ECS runtime in Go, Bubble Tea terminal, Go save format.

**Spec:** `docs/superpowers/specs/2026-10-24-makhleb-active-abilities-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `main`; commit the full patron category once and push `origin/main`.
- No inline Lua in Go, no Go patron switch, and no duplicated static monster or zap names.
- Every Lua function needs a comment explaining why and how; use readable expanded tables and at most 120 columns.
- Gameplay must match the pinned `/Users/dylanknuth/src/crawl/crawl-ref/source` behavior where this plan names values.
- New tests live in `_test.lua` and import the same production schemas and IDs.

## Review Focus

- An unaffordable HP cost is rejected before time and leaves HP unchanged (Task 1).
- An unsafe traced ray declines without spending HP, piety, or time even after drawing the source failure roll (Task 2).
- A failed servant appears hostile and pays its source costs; blocked placement does not invent an actor (Task 3).
- A saved hostile servant with a finite duration is distinct from a permanent wrath servant (Task 4).
- A forbidden-ally character cannot select either servant power, even with enough rank (Task 3).

---

### Task 1: Shared divine ability primitives and Makhleb roster

**Files:** Modify `policy/abilities/god_costs.lua`, `ids/abilities.lua`, `policy/religion/wrath/makhleb.lua`; create `policy/religion/makhleb/roster.lua`, `policy/religion/makhleb/destruction.lua`, and matching `_test.lua` files under `internal/script/testdata/lua/tests/`.

**Interfaces:** `costs.enough_health(ctx, player, amount)` and `costs.spend_health(ctx, player, amount)` reject lethal fixed HP costs and commit only on success. `roster.lesser`, `roster.greater`, and `roster.contains(kind_id, tier)` share source order. `destruction.minor` and `.major` give the exact five source zaps. Four IDs use `ABIL_MAKHLEB_*` source strings.

- [ ] Add failing Lua tests for HP affordability, payment, costs 2–3/0–1/5–8, and roster identity shared with wrath.
- [ ] Implement and run focused tests.
- [ ] Verify neither data file duplicates an item, spell, or monster string already present in an ID module.

### Task 2: Aimed destruction and ally-safe trace

**Files:** Create `policy/abilities/makhleb/minor_destruction.lua`, `major_destruction.lua`, a small shared aim/power module, and source zap profiles under `policy/magic/effects/zaps/`; modify the projectile or trajectory owner only to expose reusable ally-safe preview. Add matching `_test.lua` files.

**Interfaces:** Each module registers `available`, `prepare`, `range`, and `resolve` with the ability registry. Aim is clamped to current vision. Preview traces the same path the eventual zap will use, refuses allies freely, and commits no effect. Failure roll occurs before power/tracer rolls; its result applies after safe trace. Source profile specs cover Breathe Acid, Pain, Bolt of Magma, and Bolt of Draining in addition to existing five choices.

- [ ] Add failing Lua tests for ranks 2/4, aim cancellation, vision clamp, allied trace refusal, RNG/cost order, each five-choice zap, and power scaling.
- [ ] Implement the profile and projectile contact behavior from `zap-data.h`, including contact side effects where present; run focused tests.
- [ ] Check that the profile called Breathe Acid has the source player cap and dice, not the existing Spit Acid profile.

### Task 3: Both servant powers and source failure hostility

**Files:** Create `policy/abilities/makhleb/lesser_servant.lua`, `greater_servant.lua`, and a small shared summon module with `_test.lua`; reuse `policy/magic/effects/summons/common.lua` and `policy/population/factory.lua`.

**Interfaces:** Each ability registers the source rank, HP and piety costs, and failure tuple. Shared summon logic chooses uniformly from the requested roster, draws degree `min(2 + floor(random2(20 + skill(SK_INVOCATIONS,3)) / 4), 6)`, creates a Makhleb-sourced, player-owned finite summon with attitude from the failure result, equips it, and emits the source messages. Existing player abjuration mapping governs expiry.

- [ ] Add failing Lua tests for ranks 3/5, forbidden allies, both complete rosters, friendly and failed-hostile attitudes, degree mapping, blocked placement, messages, costs, and expiry.
- [ ] Implement and run focused tests.
- [ ] Compare the existing player abjuration duration mapping with the source summon clock; correct the shared owner if a real discrepancy is found.

### Task 4: Save, command flow, and integrated verification

**Files:** Modify `policy/save/summons.lua` and save `_test.lua` files; add game and terminal integration tests under the existing Go test packages.

**Interfaces:** The save validator accepts a legal Makhleb roster actor with source category GODS, player owner, either friendly or hostile attitude, and a future finite expiry. Permanent hostile wrath actors keep their existing separate validation. Forged owner, monster, source, attitude, or expired clock fails restore.

- [ ] Add failing save and command tests for all four abilities, paid hostile failure, aim cancellation, menu rank gating, and round trip of both summon attitudes.
- [ ] Implement validation and run affected Lua groups plus focused Go integration tests and `go build ./...`.
- [ ] Run `git diff --check`, a line-length scan on new Lua, and `gofmt -l` on changed Go files. Commit one Makhleb domain commit and push `origin/main`.

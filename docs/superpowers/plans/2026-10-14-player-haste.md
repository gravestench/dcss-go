# Player Haste Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [x]`) syntax for tracking.

**Goal:** Make source-backed potion haste playable, timed, saved, and visible.

**Architecture:** Extend the player's ECS duration component. Keep source
arithmetic in `character`, melee delay distribution in `combat`, and action
coordination in `Game.Step` without a compatibility timing layer.

**Tech Stack:** Go, Akara ECS, Bubble Tea terminal client, JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-14-player-haste-design.md`

## Global Constraints

- Use the pinned C++ source revision recorded in the content catalog.
- Keep handwritten Go under 120 columns and group multiline data entries.
- Commit this contiguous gameplay category once, after full verification.
- Preserve the untracked `dcrawl-save.json` in the main checkout.

## Review Focus

- A quaff's own turn must use pre-quaff speed.
- A failed command must not consume a speed draw.
- The melee distribution must use the same 6 or 7 aut speed as the action.
- Short wield actions must truncate the chosen speed without another draw.
- The 60-aut warning may consume one extra 10-aut decrement.
- Old saves must default to no haste without resetting other RNG streams.

## Task 1: Pure haste timing rules

- [x] Write failing `character` tests for potion duration, cap, refresh text,
  6/7 action time, warning, expiry, and invalid inputs.
- [x] Run the focused tests and confirm failure from missing behavior.
- [x] Implement `HastePotionDuration`, `PlayerActionTime`, and `DecayHaste`
  in `internal/character/haste.go`, using `character.Roller`.
- [x] Run focused tests and confirm green.

## Task 2: Melee delay at chosen action speed

- [x] Write failing `combat` tests for `PlayerAttackDelay(r, in, timeTaken)`
  at 6, 7, and 10 aut, including input validation.
- [x] Confirm red, then update `internal/combat/delay.go` to compose source
  delay weights with randomized speed scaling.
- [x] Update normal-speed call sites to pass 10 and run focused tests.

## Task 3: ECS action flow and floor item

- [x] Write failing `game` tests for a carried haste potion, self-turn cost,
  later movement and melee, monster deadline order, and finite expiry.
- [x] Confirm red, then add `HasteAut` to `ecs.Durations`, quaff and duration
  systems, and one action-speed decision after accepted command validation.
- [x] Place one separate Dungeon:2 floor potion in fixed and generated
  scenarios and update scenario assertions as needed.

## Task 4: Save, presentation, and inventory

- [x] Write failing save continuation, legacy default, bad duration, and
  terminal `Fast` light/menu tests.
- [x] Confirm red, then validate saved haste and project it into `View` and
  the terminal HUD. Keep existing snapshot component copying.
- [x] Update `docs/port-inventory.md` and `docs/ecs-architecture-roadmap.md`.

## Task 5: Category verification and integration

- [x] Run `go test ./...`, `go vet ./...`, `go build ./...`,
  `sh scripts/check-go-style.sh`, and `git diff --check`.
- [x] Review the diff for source fidelity and readable grouping.
- [x] Commit the category and fast-forward local `main` under the user's
  standing integration choice; repeat full tests and style check there.

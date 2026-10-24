# Divine Kill Recovery Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Port source kill recovery for Makhleb, Vehumet, and The Shining One.

**Architecture:** Keep credit and XP with the Lua actor-death owner. Run
conduct before the mutation and divine reactions. Each god definition
names its own recovery formula module; the shared owner handles eligibility,
timing, and resource writes.

**Tech Stack:** Embedded Lua, Akara ECS components, Go Lua-rule harness.

**Spec:** `docs/superpowers/specs/2026-10-24-divine-kill-recovery-design.md`

## Global Constraints

- Keep production policy in embedded `.lua` files and limit Go to engine code.
- Comment why source order and eligibility checks matter.
- Prefer 80-character lines and never exceed 120 characters.
- Commit this contiguous category once and push `main` as authorized.

## Review Focus

- An XP-giving conjured actor cannot restore HP or MP.
- Piety earned by the same kill affects the recovery chance.
- Death's Door blocks HP while leaving a valid MP recovery possible.
- Evil identity comes from the conduct classifier, including spell traits.
- Full pools produce no gain message.
- Former neutral victims are unrewarded unless frenzied.
- Mutation and divine HP gains on one death emit one health message.

---

### Task 1: Recovery policy

**Files:** Create `policy/religion/kill_recovery.lua`, three god formula
modules, and a Lua `_test.lua`; reuse monster stats and conduct traits.

- [x] Write cases for each god, non-evil TSO victim, object, penance, and cap.
- [x] Run the focused test red.
- [x] Implement the source formulas and single threshold draw.
- [x] Run the focused test green.

### Task 2: Source order in death

**Files:** Modify `systems/actor_death.lua` and the focused death test.

- [x] Show a same-kill piety threshold case failing before the ordering edit.
- [x] Record conduct before mutation and divine aftermath; keep one XP award.
- [x] Run the focused death tests green.

### Task 3: Verify and integrate

**Files:** Update `docs/port-inventory.md` and `docs/modding.md`.

- [x] Run focused Lua and game tests, build `cmd/crawl`, and check style.
- [x] Review the diff, commit the category, and push `main`.

The category tests and game build passed. The repository-wide Go style
script reports pre-existing violations in unrelated Go files; this slice
changes only Lua and documentation.

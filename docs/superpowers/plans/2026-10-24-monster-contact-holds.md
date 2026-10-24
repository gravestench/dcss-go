# Monster Contact Holds Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this
> plan as one coherent category and run the relevant Lua and game tests.

**Goal:** Port both monster contact holds for player and monster victims.

**Architecture:** Lua contact policies decide application; victim-owned ECS
components store duration and links; Lua active systems handle damage and
release. Go only extends its existing host component and save restoration.

**Tech Stack:** Go, Akara ECS, embedded Lua, Go and Lua tests.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-contact-holds-design.md`

## Global Constraints

- Rules live in Lua files; no inline Lua in Go.
- Each new function explains its reason and operation in comments.
- Lines stay at or under 120 characters, with 80 preferred.
- The complete contact-hold category lands in one commit on `main`.

## Review Focus

- Zero physical damage must still allow either contact effect.
- An immune or oversized victim must not gain a grip.
- A monster victim's grip must survive save/restore.
- A player victim's water hold must survive save/restore and damage on time.
- Death, movement, and polymorph must release invalid holds.

## Tasks

- [x] Add failing production-Lua contact tests for both victim types.
- [x] Share physical grip eligibility and route both flavours through it.
- [x] Generalize direct constriction ticking, movement escape, and save links.
- [x] Generalize water hold, silence, drowning, and save links.
- [x] Add game save/restore and player drowning tests.
- [x] Run relevant tests and style checks, review the category, then commit
  and push `main`.

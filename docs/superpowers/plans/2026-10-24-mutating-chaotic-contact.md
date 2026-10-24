# Mutating and Chaotic Contact Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan as one coherent category. Steps use checkboxes for tracking.

**Goal:** Make Mutate and Chaotic natural contacts work against both actor types.

**Architecture:** Lua contact handlers consume the normal melee hit
envelope. A shared weighted selector supplies source chaos choices to
weapon-brand and natural-contact callers; each caller retains its own
selected-effect formula. Existing mutation and chaos effects own state.

**Tech Stack:** Go, Akara ECS, embedded Lua, production Lua tests.

**Spec:** `docs/superpowers/specs/2026-10-24-mutating-chaotic-contact-design.md`

## Global Constraints

- All rule code lives in Lua files, with no inline Lua in Go.
- Every new function explains why and how in nearby comments.
- Lines stay at or under 120 characters, with 80 preferred.
- Commit the complete category together and push `main`.

## Review Focus

- Chaos eligibility changes the draw bound before consuming randomness.
- Purely absorbed HP loss still permits a positive post-armour contact.
- A zero-damage, missed, blocked, or dodged contact consumes no effect roll.
- Player mutation resistance and monster mutation immunity stay effective.
- Natural chaos's chosen Fire or Holy uses flavour damage, not brand damage.

## Tasks

- [x] Write failing production-Lua tests for Mutate and Chaotic contact.
- [x] Extract one weighted chaos chooser and migrate both weapon paths.
- [x] Add focused Lua contact handlers and dispatch for both flavour IDs.
- [x] Exercise live melee for each victim and protect existing chaos brands.
- [x] Run category tests and style checks, review, commit, and push.

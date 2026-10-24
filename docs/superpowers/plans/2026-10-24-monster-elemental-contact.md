# Monster Elemental Contact Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan as one coherent category. Steps use checkboxes for tracking.

**Goal:** Port Holy, Pure Fire, and Sear monster contacts for both actor types.

**Architecture:** A focused Lua flavour owner uses existing health,
resistance, and fire-vulnerability state. Both monster melee paths pass the
same attack base damage. Fire vortex summons use the normal melee sequence.

**Tech Stack:** Go, Akara ECS, embedded Lua, production Lua tests.

**Spec:** `docs/superpowers/specs/2026-10-24-monster-elemental-contact-design.md`

## Global Constraints

- Rule logic lives in Lua, never inline Go source.
- New functions explain their rationale and operation in comments.
- Lines stay at or under 120 characters, with 80 preferred.
- Commit this complete category together and push `main`.

## Review Focus

- Holy must skip natural and specially resistant undead targets.
- Zero post-armour physical damage still allows Pure Fire but not Sear or Holy;
  later HP absorption does not suppress Sear or Holy.
- Fire vortex self-destruction must follow a landed contact only.
- Sear's player timer caps at 50 turns while monsters retain their own timer.
- Friendly monster secondary kills must credit the player.
- Injury Mirror killing the attacker prevents its later flavour packet.

## Tasks

- [x] Write a failing Lua test for all three effects and both victim types.
- [x] Add source-backed IDs and a focused Lua elemental contact owner.
- [x] Pass attack base damage through both melee hit envelopes and dispatch
  the new owner after landed contacts.
- [x] Route summoned fire vortex contact through the ordinary melee sequence,
  removing its duplicate fire damage path.
- [x] Run focused Lua and game checks, inspect the diff, commit and push.

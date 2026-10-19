# Player Illusion Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement this
> plan as one contiguous category. Verify at the category boundary and make
> one category commit.

**Goal:** Port both Summon Illusion target branches, including a saved
player-derived ghost combat profile and a source-monster copy.

**Architecture:** A Lua component snapshots player identity and combat
numbers onto the summoned Akara actor. Lua policies build the snapshot and
feed it to melee, defense, resistance, and spellbook readers. The ordinary
monster pipeline schedules and resolves its actions.

**Tech Stack:** Lua mod files, Akara ECS, existing Go grid and save runtime.

**Spec:** `docs/superpowers/specs/2026-10-19-player-illusion-design.md`

## Global constraints

- Preserve source DCSS behavior for the implemented character mechanics.
- Keep Lua source in `.lua` files; no inline Lua in Go.
- Keep lines at or below 120 characters and explain how and why functions work.
- Make a single category commit, merge it to `main`, and push the user's fork.

## Tasks

1. Add Lua regression tests for the captured profile, cast gating, and saved
   state. Confirm the tests fail before implementation.
2. Add the saved profile schema and source-derived profile builder. Capture
   untransformed HP/defense, damage and brand, resistances, known spell slots,
   and internal statuses from current ECS player state.
3. Add the Summon Illusion effect and spawn policy. Require direct sight,
   enforce one named player illusion, summon beside the caster, and emit the
   source message. For a monster foe, use the mirror owner with no swap or
   untangle and prevent a second live copy. Use the common summon owner for
   lifetime and attitude.
4. Read the saved profile in player and monster target melee, defense,
   damage resistance, and
   monster spellbook selection. Reuse the existing combat/AI flow.
5. Validate the profile and duplicate rule on save/restore. Add a live Mara
   cast and restore test with a source-shaped player profile.
6. Run focused and broad category checks. Review the diff, make one commit,
   fast-forward `main`, push `origin/main`, and verify both heads match.

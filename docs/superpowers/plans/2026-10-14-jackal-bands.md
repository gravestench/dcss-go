# Jackal Bands Implementation Plan

**Goal:** Source-backed jackal packs in generated D:1–2 play, with ECS
membership, saved continuation, and correct population accounting.

**Source:** `docs/superpowers/specs/2026-10-14-jackal-bands-design.md`

## 1. Actor and pack rules

- Add a validated jackal plain-bite profile and include jackal in the
  population scenario roster while leaving fixed fixtures unchanged.
- Draw one to three followers from a dedicated `bands` stream when a
  jackal is selected. Keep leader placement under the existing population
  and placement streams.
- Place followers within three cells and the leader's solid LOS, up to
  1000 offset attempts each. Use the shared factory for every actor.

## 2. ECS relation and AI

- Add a `BandFollower` component with the leader entity ID and include it
  in save/restore. Validate its kind, role, and possible dead-leader link.
- Make wandering followers prefer source-shaped nearby targets around
  their living leader. Player sight and pursuit remain higher priority.

## 3. Population and save invariant

- Record the actual initial actor count per level after generation.
  Preserve old version-8 saves with an absent count.
- Validate live actor totals against this count and calculate the maximum
  possible earned XP from initial actors minus survivors.
- Reject malformed counts without rejecting legitimate packs or old saves.

## 4. Integrated verification

- Test source follower range, placement limits, fixed fixture continuity,
  generated pack presence, saved continuation, XP, and corpse outcomes.
- Update `docs/port-inventory.md` and the ECS roadmap.
- Run the style checker, full Go tests, vet, build, and `git diff --check`
  once at the category boundary. Request a whole-branch review, fix any
  important findings, then make one feature commit and merge to local main.

# Ru Attack Interference Implementation Plan

**Goal:** Port Ru's one-star attack interference across all monster
attack paths in one contiguous category commit.

**Spec:** `docs/superpowers/specs/2026-10-24-ru-attack-interference-design.md`

**Architecture:** A Lua Ru policy makes the source-order decision;
ordinary combat owners execute the blocked or redirected action. A
short-lived forced-target component scopes same-side targeting to the
one action, and a generic interrupted intent preserves spell cost.

## Task 1: Source decision and target ownership

- Add named Ru roll bounds and outcomes to shared Lua constants.
- Extract the existing Ru radius order into a shared Lua helper.
- Add the forced-target Lua component and an exact-target check in the
  shared target predicate, including self-targeting when source selection
  picks the attacker.
- Implement the Ru interference policy with commented eligibility,
  source roll order, spatial selection, and messages.
- Pin this behavior in one production-schema `_test.lua` file.

## Task 2: Attack integration

- Apply the policy to monster melee, missile, and spell attacks before
  their hit or spell-specific target rolls.
- Let forced melee strikes reuse the existing monster-versus-monster
  sequence.
- Extend monster ranged contact to use monster defense and health for a
  redirected shot, retaining projectile-specific coatings and brands.
- Let spell choice plan against the redirected actor. An interrupted
  spell intent spends spell energy without executing an effect.
- Clear the action-scoped target on every normal completion and
  no-spell planning path.

## Task 3: Integrated verification and release

- Exercise all three attack families in Go game tests, with blocked and
  redirected outcomes, energy use, and save/restore.
- Run the adjacent Lua and Go tests once at the category boundary,
  build `cmd/crawl`, run `scripts/check-go-style.sh`, and check the diff.
- Update `docs/modding.md` and `docs/port-inventory.md`.
- Commit the verified category once on `main` and push the fork.

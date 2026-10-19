# Walking tomes and living spells implementation plan

**Goal:** All four walking tomes summon spell actors that cast once and die.

**Architecture:** A saved Lua component projects an ordinary monster spell
slot. Each tome content file declares its living spell. Iceblast uses a
monster beam profile.

**Spec:** `docs/superpowers/specs/2026-10-19-walking-tomes-living-spells-design.md`

## Work

1. Add a failing Lua rule test for the four tome mappings, independent
   summons, saved HD, cap, and custom spellbook projection.
2. Implement the living spell component, summon policy, and tome effect file.
3. Add the source Iceblast monster beam profile and resolver; test blast
   targeting, damage, and friendly-fire refusal.
4. Dismiss living spells after completed casts; prove an unsuccessful plan
   leaves the actor alive for a later turn.
5. Add live cast/save/restore tests with sparse tome fixtures. Update the
   port inventory and slice documentation.
6. Review against pinned source. Run the Lua suite, focused live tests,
   `go build ./...`, style and diff checks. Commit the category once, fast
   forward local `main`, push `origin/main`, and verify matching heads.

# Mutant Beast Facets Implementation Plan

**Goal:** Make each saved mutant beast form control its live source rules.

**Spec:** `docs/superpowers/specs/2026-10-24-mutant-beast-facets-design.md`

## Tasks

- [x] Add one Lua `_test.lua` domain suite for the projected attack sequence,
  natural form generation, resistance, AC, speed, and Fire/Shock slots; run
  the failing tests first.
- [x] Project saved form into generic monster profile and HD policy. Roll
  unauthored forms in the population owner.
- [x] Expose Fire/Shock slots through the ordinary monster spellbook and
  ensure Bat uses the current AI movement rule.
- [x] Carry source authored HP scaling, partial DES forms, Sting poison and
  reach, and Fire Breath cooldown through live play and save validation.
- [x] Verify focused and neighboring suites, build, style baseline, and
  diff; request source review, then commit and push one category.

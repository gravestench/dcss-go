# Source monster hex spells implementation plan

**Goal:** Make the 16 missing committed-book targeted hex and
enchantment spells playable with source behavior in one category commit.

**Spec:** `docs/superpowers/specs/2026-10-18-monster-hex-spells-design.md`

**Source:** DCSS `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`,
especially `mon-cast.cc:_hex_logic`, `spl-zap.cc`, `zap-data.h`, and
`beam.cc` player/monster enchantment cases.

**Constraints:** Production rules in discoverable Lua files; mutable
actor state in saved components; committed source profiles; no spell-ID
dispatcher or Go gameplay fork. Keep source-specific rules named and
readable. Test related changes as a broad slice, then make one commit.

## File map

- `scripts/import-monster-beams.py` deliberately refreshes strict source
  zap profiles from the pinned C++ checkout; no runtime/build dependency.
- `internal/modfs/builtin/content/monster_beams/*.lua` gains 17
  committed, source-traced profiles in the existing zap catalog:
  16 new effects and Petrify for its already live effect.
- `internal/modfs/builtin/policy/combat/monster_hexes/*.lua` owns target
  viability, willpower, damage, and shared duration/actor delivery.
- `internal/modfs/builtin/policy/combat/monster_spells/*.lua` contains one
  readable plan/resolve module per spell.
- Existing `schemas`, `systems`, `policy/magic`, `policy/world`, and
  `policy/character` owners carry status effects through turns and saves.
- `internal/script/testdata/lua/tests/monster_hex_*_test.lua` exercises
  production modules with shared test fixtures; `internal/game` tests
  prove the real turn and save flow.

## Work

### 1. Source profiles and coverage

- [ ] Write failing importer/coverage tests for exactly the 17 source
  IDs, spell-to-zap mappings, power factors, and unsupported source
  calculators. Reuse production ID/constants modules in Lua tests.
- [ ] Implement a strict deliberate importer and commit its generated
  Lua. A profile check must reproduce all 17 files byte for byte.

### 2. Shared hex path

- [ ] Write failing tests for entity planning, blocked or friendly line,
  source viability, distinct willpower rolls, and spell slot retention.
- [ ] Implement the actor-neutral hex kernel, extract source shared
  resistance from the current player-only helper, and keep Sleep and
  Petrify behavior intact. Do not change the existing typed intent
  interface or add an adapter.

### 3. Complete effect family

- [ ] Write failing tests for each production effect's observable
  result, including immunity and already-active states. Group tests by
  damage, control, movement, and magic state rather than by boilerplate.
- [ ] Implement all 16 effect modules, reusing existing status and
  Abyss owners. Add saved actor components and actual turn consumers
  for anchor, poison vulnerability, and Sap Magic. Source-specific
  player and monster outcomes belong in named policies, not a broad
  switch in the kernel.
- [ ] Test the interaction of anchor with teleport, Virulence with
  poison, Sap Magic with casting, Drain Magic with MP and ghost moth
  healing, and Banishment with kill credit and restore.

### 4. Integration and one category commit

- [ ] Add real-game integration tests for a multi-slot caster, resist
  and successful outcomes, save/restore RNG continuation, and sparse
  mod override. Observe expected red failures before completing code.
- [ ] Run full Lua rules suite; focused and broad relevant Go tests;
  `go build ./...`; `go vet ./...`; importer check; style and diff checks.
  Record any known exhaustive suite timeout instead of claiming it ran.
- [ ] Review all 16 profiles and effects against source outcomes, fix
  findings, commit the family once, and fast-forward local `main`.

## Review focus

1. A failed plan spends no cast and never mutates game state.
2. A willpower resist spends a cast but applies no lasting effect.
3. No actor status can be saved without its consuming turn rule.
4. Damage, banishment, and Drain Magic preserve combat attribution.
5. Mod overrides use the same effect path and validation as built-ins.

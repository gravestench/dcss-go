# Artefact discovery implementation plan

**Goal:** Show artefact true names and properties only when that physical
item is known, while preserving ordinary shared-kind identification.

**Architecture:** `policy.items.identification` remains the one discovery
owner. It derives the fixed self-identifying exception from immutable Lua
content. Identify and shop flows use its existing APIs; ECS components
persist mutable discovery state.

**Spec:** `docs/superpowers/specs/2026-10-19-artefact-discovery-design.md`

## Constraints

- Keep gameplay rules in embedded Lua. Do not add Go content switches.
- Import no C++ content at build time. Read the committed Lua definitions.
- Use named IDs, comments that explain why and how, and 120-character lines.
- Keep the entire discovery category in one implementation commit, then
  fast-forward and push `main`.

## Review focus

- A known ordinary jewellery kind does not reveal a randart ring's name.
- Two artefacts on the same base kind retain independent discovery.
- An `unided` fixed artefact stays unknown even if both names are equal.
- A fully identified artefact has matching type, plus, and property state.
- Saved `known_type` is accepted for artefacts but not arbitrary mundane gear.

## Task 1: Source-backed discovery state

**Files:** `policy/items/identification.lua`,
`policy/item_generation/artefacts/names.lua`,
`constants/artefact_flags.lua`,
`content/artefacts/unrand_octopus_king_ring.lua`,
`internal/script/testdata/lua/tests/artefact_discovery_test.lua`.

- [x] Write failing cases for the fixed, random, and `unided` source rules.
- [x] Derive self-identifying fixed artefacts from definition names and
  flags. Make `identification.known` use instance state for all other
  artefacts.
- [x] Make type and full-property reveals update only the target artefact.
- [x] Use the source non-descript fallback without disclosing ring or
  amulet subtypes until the name database is ported.
- [x] Permit valid saved artefact type knowledge without opening mundane gear.

## Task 2: Existing interaction flows

**Files:** `policy/shops/identification.lua`,
`policy/scrolls/effects/identify.lua`, test above.

- [x] Prove Identify reveals all three fields and shop stock reveals an
  artefact without changing other copies.
- [x] Route shop stock through the existing identification policy with an
  artefact-aware type flag; retain the existing Identify flow.

## Task 3: Persistence and integration

**Files:** `internal/game/item_artefact_discovery_test.go`,
`docs/port-inventory.md`.

- [x] Add one live save/restore test for hidden and revealed artefact names.
- [x] Run focused Lua and Go tests, all Lua rules, relevant Go item tests,
  package compilation, style, and diff checks.
- [x] Review and commit the category once, fast-forward `main`, push
  `origin main`, and verify both refs match with a clean checkout.

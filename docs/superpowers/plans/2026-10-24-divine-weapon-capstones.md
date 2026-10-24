# Divine Weapon Capstones Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan natively. The user
> authorized one category-sized commit directly on `main` and a push after
> the integrated category passes its focused checks.

**Goal:** Make all three source god weapon blessings and Kiku's alternative
spell capstone playable through the Lua ability action.

**Architecture:** One Lua owner handles item choice and irreversible item
mutation; per-god Lua modules own their source effects. Akara stores the
pending choice and worship history. Go retains generic command and save
plumbing only.

**Tech Stack:** Go, gopher-lua, Akara ECS, committed Lua content.

**Spec:** `docs/superpowers/specs/2026-10-24-divine-weapon-capstones-design.md`

## Global constraints

- Use only embedded Lua files for game rules; no inline Lua in Go.
- Keep each Lua function commented with why and how, and lines <=120 chars.
- Import shared item, ability, god, brand, and component IDs at use sites.
- Replace the Lugonu-only path; do not keep a compatibility adapter.
- Commit the complete category once, then push `origin main`.

## Review focus

1. A saved choice cannot brand another item after the selected one is
   dropped, consumed, or moved to another holder.
2. Kiku's spell choice and pain blessing cannot both be used, including
   after renouncing and rejoining.
3. No Grasping blocks weapon blessings but not Kiku's spell alternative.
4. TSO's holy word uses current actor resistance; Kiku's pain-brand
   Torment deliberately suppresses Kiku's usual shield during that action.
   Neither effect can be reduced to a visual message.
5. A blessed weapon can be rebranded by a different god, including the
   exact blessed/demonic base conversion and ranged restriction.

---

### Task 1: Shared saved choice and ability registration

**Files:** Replace `schemas/religion_lugonu_bless_choice.lua` with
`schemas/religion_weapon_bless_choice.lua`; create
`policy/abilities/weapon_blessing.lua`; add IDs to `ids/abilities.lua` and
`constants/component.lua`; modify `policy/command_prepare.lua` and
`policy/save/player.lua`; create policy `_test.lua` cases.

- [x] Write failing tests for all three menu entries, free item selection,
  confirmation, cancellation, no-grasping, and stale saved choices.
- [x] Implement one shared pending choice and ability registration contract;
  migrate Lugonu and remove its old choice schema and handler path.
- [x] Run Lua and focused Lugonu game tests.

### Task 2: Weapon conversion and one-time history

**Files:** Add focused `policy/abilities/weapon_blessing/item.lua` and
per-god definition modules; modify item provenance and identification only
where the source rule requires it.

- [x] Test all three blessed/demonic base pairs in both directions,
  ordinary/ranged/artefact eligibility, source enchant cap, and equipped
  entity identity.
- [x] Commit brand, conversion, enchantment, and worship one-time flag in
  one successful timed action; preserve item attribution through save.
- [x] Run Lua item cases and game save/restore cases.

### Task 3: God-specific source effects

**Files:** Add TSO and Kiku effect modules under
`policy/abilities/weapon_blessing/`; add reusable holy-word area policy,
and use the existing Torment area owner. Add only the saved status or grid
property state needed to make the source effects live.

- [x] Test holy-word damage, daze, and blood cleanup for TSO; test
  the pain-brand shield exception and independent blood draws for Kiku.
- [x] Implement the effects through current combat, status, terrain,
  message, and RNG owners, with source order after item mutation.
- [x] Run Lua effect and game interaction cases.

### Task 4: Kiku's mutually exclusive spell gift

**Files:** Add `policy/abilities/kikubaaqudgha/forbidden_knowledge.lua`;
reuse spell-library and usability policy; add focused `_test.lua` cases.

- [x] Test full usable spell list, no-usable abort, free confirmation,
  save/restore, and both directions of capstone exclusion.
- [x] Grant the source five spells and spend the Kiku one-time flag only
  after confirmed commitment.
- [x] Run Lua and game ability integration cases.

### Task 5: Integrated boundary

**Files:** Update `docs/port-inventory.md`, `docs/modding.md`, and game
integration tests; remove the old Lugonu-only files after callers migrate.

- [x] Verify complete terminal selection, cancellation, commitment,
  equipped item state, and restore for each god and Kiku alternative.
- [x] Run focused Go/Lua suites, `go build ./...`, `gofmt`,
  `sh scripts/check-go-style.sh`, and `git diff --check`.
- [x] Commit the contiguous capstone category and push `origin main`.

# Lua Jewellery Passive Effects Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan task by task. Checkboxes track progress.

**Goal:** Give every active jewellery definition source-backed Lua
capabilities and implement passive, attuned, and acrobat effects.

**Architecture:** Each item declares named effect capabilities. A Lua
projection sums effectively worn items; focused combat, character, and
magic policies consume it. Attunement and the acrobat action window use
saved Lua ECS components. Go stays generic.

**Tech Stack:** Go 1.25, embedded Lua, Akara ECS, the existing catalog and command bridge.

**Spec:** `docs/superpowers/specs/2026-10-15-jewellery-effects-design.md`

## Global Constraints

- Implement all 24 active items as one contiguous category and commit once after integrated verification.
- Keep production policy in Lua files and all new gameplay tests in `_test.lua` files.
- Commit generated Lua sources; run the importer only for deliberate source refreshes.
- Keep source citations in comments, capability names in shared constants, and changed code within 120 columns.
- Preserve the user's untracked `dcrawl-save.json`.

## Review Focus

1. Octopode's extra ring slots contribute once each; an unusable slot contributes nothing when future forms block it.
2. Signed ring plus values work for both positive and negative enchantments.
3. A mod-added item with an existing capability affects consumers without an item-ID edit.
4. Attunement cannot be forged or orphaned by save restore, and removal stops the bonus.
5. Acrobat acts through live move/wait events. Faith and projectile
   reflection remain pending their complete event domains.

---

### Task 1: Declare and validate source-backed capabilities

**Files:**
- Create: `internal/modfs/builtin/constants/jewellery_capabilities.lua`
- Create: `internal/modfs/builtin/constants/jewellery_magnitudes.lua`
- Modify: `scripts/export-catalog-lua.py`
- Modify: the 24 active `internal/modfs/builtin/content/items/*.lua` jewellery definitions
- Modify: `internal/modfs/builtin/content/validation.lua`
- Create: `internal/script/testdata/lua/tests/jewellery_effect_catalog_test.lua`

**Interfaces:**
- Each definition's `jewellery.effects` maps one capability to a number or `item_plus`.
- `content.validation` rejects unknown capabilities and wrong magnitude
  types on active items; removed items have no live effects.

- [x] Test the 24-item matrix and invalid definitions in Lua. Run a
  separate mod overlay test.
- [x] Add the shared names and exporter mapping from pinned source references; regenerate the committed item files.
- [x] Run the focused Lua test and `python3 scripts/export-catalog-lua.py --check`; both pass.

### Task 2: Project worn effects and connect stat consumers

**Files:**
- Create: `internal/modfs/builtin/policy/inventory/jewellery_effects.lua`
- Modify: `internal/modfs/builtin/policy/character/attributes.lua`
- Modify: `internal/modfs/builtin/policy/character/formulas.lua`
- Modify: `internal/modfs/builtin/policy/combat/fighter.lua`
- Modify: `internal/modfs/builtin/policy/combat/player_slay.lua`
- Modify: `internal/modfs/builtin/policy/combat/player_resistance.lua`
- Modify: `internal/modfs/builtin/policy/combat/flight.lua`
- Modify: `internal/modfs/builtin/policy/character/senses.lua`
- Modify: `internal/modfs/builtin/policy/magic/damage.lua`
- Modify: `internal/modfs/builtin/policy/magic/failure.lua`
- Modify: `internal/modfs/builtin/policy/combat/monster_drain.lua`
- Create: `internal/script/testdata/lua/tests/jewellery_passives_test.lua`

**Interfaces:**
- `jewellery_effects.sum(ctx, player, capability)` returns the signed sum from effectively worn jewellery.
- `jewellery_effects.has(ctx, player, capability)` is `sum(...) > 0` for boolean capabilities.

- [x] Test the full item matrix, live consumer routes, stacking, negative pluses, Octopode slots, and mod-added content.
- [x] Implement the projection with `policy.inventory.jewellery.worn`; remove ring/amulet item-ID checks from consumers.
- [x] Apply source formulas at their owner policies, including maximum-MP resource updates after equipment changes.
- [x] Run the focused Lua tests and the script package after the passive group is wired.

### Task 3: Implement attunement, guardian spirit, and acrobat

**Files:**
- Create: focused Lua schemas and policies under `internal/modfs/builtin/schemas/` and `policy/jewellery/`
- Modify: `internal/modfs/builtin/policy/inventory/equipment.lua`
- Modify: `internal/modfs/builtin/systems/item_jewellery.lua`
- Modify: `internal/modfs/builtin/policy/character/regeneration.lua`
- Modify: `internal/modfs/builtin/policy/combat/spirit_shield.lua`
- Modify: command action and movement policies that own the acrobat window
- Modify: `internal/modfs/builtin/policy/save/equipment.lua`
- Create: `internal/script/testdata/lua/tests/jewellery_amulets_test.lua`

**Interfaces:**
- Equipment completion/removal updates saved attunement and acrobat state.
- A successful move or explicit wait records the acrobat window before monster response.
- Spirit shield reads the guardian-spirit capability through the shared projection.

- [x] Test amulet behavior, equip/remove, attunement, save restore, and
  a mod-defined equivalent capability.
- [x] Implement focused transition and action policies without an
  item-ID switch.
- [x] Run the focused amulet tests and script package after the group is wired.

### Task 4: Integrated category verification and commit

**Files:**
- Modify: `docs/modding.md`, `docs/port-inventory.md`

- [x] Confirm every active item has its source effect and no direct
  item-ID consumer remains outside definitions or tests.
- [x] Record faith piety events and blocked-projectile return as pending
  religion and ranged-combat work.
- [x] Run full Go tests, vet, build, exporter check, style check, and
  `git diff --check` at the category boundary.
- [x] Recheck the sole concurrent-suite failure in isolation: the
  all-character-start test passed in 353 seconds after a population
  context timeout in the concurrent run. Other packages passed.
- [ ] Review the staged diff and commit the one category as `feat: implement Lua jewellery effects`.
- [ ] Fast-forward local `main`, return to the active branch, and leave `dcrawl-save.json` untouched.

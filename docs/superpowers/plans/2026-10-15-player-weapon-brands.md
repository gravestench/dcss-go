# Player Melee Weapon Brands Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans
> to implement this plan task-by-task. The implementation is one contiguous
> gameplay category and receives one commit after integrated verification.

**Goal:** Make every generated player melee weapon brand affect gameplay in
Lua, including durable statuses, timing, AC, distortion, and spectral ally.

**Architecture:** A dynamic Lua dispatcher loads a per-brand module from the
effective mod tree. Existing combat helpers own generic damage and status
rules; Akara components own persistent effects and the spectral companion.
The player attack path has one brand call after base damage. The forced chaos
brand belongs to this category despite its zero ordinary generation weight.

**Tech Stack:** Go 1.25, embedded Lua, Akara ECS, source-traced catalogs.

**Spec:** `docs/superpowers/specs/2026-10-15-player-weapon-brands-design.md`

## Constraints

- Keep all game rules in Lua files under `internal/modfs/builtin`.
- Use named IDs and imported constants at use sites.
- Do not add a Go brand switch, compatibility adapter, or second rule path.
- Keep multi-field tables expanded and lines within 120 characters.
- Preserve the untracked `dcrawl-save.json` and paused C++ branch.
- Verify once at the integrated category boundary, with focused red/green
  checks while implementing.

## Task 1: Attack boundary and per-brand modules

**Files:** `policy/combat/melee_actions.lua`,
`policy/combat/player_brands.lua`, `policy/combat/player_brands/*.lua`,
`constants/weapon_brands.lua`, and Lua `_test.lua` tests.

- [ ] Add a catalog-driven failing test that requires a player module for
  every positive-weight melee brand; verify it fails before implementation.
- [ ] Add a whole-turn failing test where a flaming melee weapon deals and
  reports bonus damage; verify the current unbranded path fails.
- [ ] Pass weapon brand and source weapon identity through `fighter.attack`.
  Invoke the Lua dispatcher once after base damage, before post-hit effects.
  Preserve source zero-damage and already-dead gates.
- [ ] Implement normal, vorpal, flaming, freezing, electrocution, holy wrath,
  venom, vampirism, pain, draining, antimagic, distortion, and chaos modules with
  source roll order. Reuse shared production damage/status helpers.
- [ ] Verify focused Lua and whole-turn tests before proceeding.

## Task 2: Continuous speed and protection

**Files:** `policy/combat/delay.lua`, `policy/combat/fighter.lua`,
`policy/combat/player_brands/{speed,protection}.lua`, and whole-turn tests.

- [ ] Add failing tests for faster player melee and +5 AC with a protection
  weapon, including unequipping and save continuation.
- [ ] Read the wielded brand in the existing delay and defense policies;
  import named brand IDs where used. Keep their hit modules source-inert.
- [ ] Run focused timing, defense, save, and Lua rule tests.

## Task 3: Spectral ally and state transitions

**Files:** `policy/combat/player_brands/spectral.lua`, a Lua component schema,
spectral decision/system files, `policy/combat/melee_actions.lua`,
`policy/world/abyss.lua`, save validators, and whole-turn tests.

- [ ] Add failing whole-turn tests for spectral placement, immediate ally
  strike, reuse/replacement, normal-AI exclusion, and save/restore.
- [ ] Add failing distortion tests for monster blink and Abyss banishment
  without kill XP, including save/restore.
- [ ] Implement spectral as a saved allied actor with an explicit component,
  one focused Lua system, and a copied weapon. Implement monster banishment
  through a saved level transition, not a fake kill.
- [ ] Verify focused combat and save tests.

## Task 4: Integrated verification and commit

- [ ] Test same-path Lua override, hash change, and changed hit result.
- [ ] Run `GOWORK=off GOCACHE=/private/tmp/dcrawl-go-build-cache go test ./... -count=1 -timeout 30m`.
- [ ] Run `go vet ./...`, `go build ./cmd/dcrawl`, `sh scripts/check-go-style.sh`,
  content importer/exporter `--check`, and `git diff --check`.
- [ ] Update `docs/port-inventory.md` with actual verified coverage.
- [ ] Commit the complete category on the feature branch, fast-forward
  local Go `main`, and return to the feature branch.

## Review-driven acceptance cases

- A banished, netted monster restores in a generated Dungeon and its original
  population budget remains valid.
- A banished jackal follower no longer keeps an invalid cross-level link.
- Ordinary chaos clones restore in generated Dungeons; summoned clones keep
  their expiry; slowed clones keep their speed state and equipped items copy.
- Killing a chaos clone preserves its extra earned XP through save validation.
- Damage to a spectral ally shares nonlethal damage with its player owner.

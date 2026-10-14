# Rat Melee Defense Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the fixed rat bite with source-backed accuracy, Fighter EV, shield blocking, armour, and damage for the playable scenario.

**Architecture:** `internal/combat` performs source-traced integer calculations on value inputs using a bounded roller. `game` assembles those inputs from ECS and committed catalogs, owns HP and combat messages, and stores only mutable per-round shield blocks in `ecs.Combatant`.

**Tech Stack:** Go, Akara ECS, committed item/monster catalogs, SplitMix64 named RNG streams, Go JSON saves.

**Spec:** `docs/superpowers/specs/2026-10-13-rat-melee-defense-design.md`

## Global Constraints

- The pinned C++ reference is revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`; ordinary Go builds and tests cannot require it.
- Only `MONS_RAT` `AT_BITE`/`AF_PLAIN` versus an awake, unmodified Human/Fighter is in scope.
- Keep pure formulas outside `game`; keep ECS, catalogs, messages, and HP writes owned by `game`.
- Version-5 saves reject explicitly once the combat component becomes schema 6.

## Review Focus

- A source field changes unexpectedly: scenario construction rejects unsupported rat attack/HD and never substitutes fixture damage.
- An unarmed Fighter has no weapon entity: defense still reads body armour and shield and resolves the rat bite.
- A shield blocks a would-be dodge: block takes precedence, matching C++ phase order.
- Zero damage after AC: report an armour absorption outcome without removing HP or falsely claiming a damaging hit.
- Save/load between turns: the named melee RNG stream and shield-block count continue deterministically.

---

### Task 1: Pure Fighter defense and rat bite rules

**Files:** Create `internal/combat/rat.go`, `internal/combat/rat_test.go`.

**Interfaces:** `type Roller interface { Intn(string, int) (int, error) }`; `type FighterDefense struct { Strength, Dexterity, ArmourSkill, ShieldsSkill, BodyAC, BodyEV, BodyPlus, ShieldAC, ShieldEV, ShieldPlus, ShieldBlocks int }`; `func ProjectFighter(FighterDefense) (Defense, error)` where `Defense` carries `EV`, `AC`, `ShieldClass`, `GDR`, `ShieldBlocks`; `func RatBite(Roller, RatAttack, Defense) (Outcome, error)` where `RatAttack` has `HD`, `Damage`, `TypeID`, `FlavourID`, and `Outcome` carries kind, damage, and updated shield-block count.

- [ ] Write table tests for Human/Fighter scale mail and buckler baseline (`EV 5`, `AC 6`, `ShieldClass 9`), plus invalid negative input.
- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-melee-cache go test ./internal/combat` and observe failure.
- [ ] Implement the pinned player integer formulas from `player.cc:1926-2100`, `2117-2190`, `5616-5661`, `5747-5766`, and `5970-6084`; use `math.Sqrt` only for `GDR` as `player.cc:6100-6113` does.
- [ ] Write scripted-roller tests for EV dodge, 5% automatic miss/hit, shield block before dodge, armour absorption, and damaging hit; assert roll bounds/call order.
- [ ] Implement ordinary bite resolution using `attack.cc:289-312, 1138-1171, 1208-1291`, `melee-attack.cc:750-790,3542-3547`, `fight.cc:134-145`, `actor.cc:336-382`, and `random.cc:330-339`.
- [ ] Run focused tests; commit this source rule category.

### Task 2: ECS combat and save integration

**Files:** Modify `internal/ecs/components.go`, `internal/game/{combat,scenario,commands,save,view}.go`, `internal/save/snapshot.go`, their focused tests, and `docs/port-inventory.md`.

**Interfaces:** `Combatant{ShieldBlocks int}` replaces `BaseDamage`. `game.combatSystem` uses `ProjectFighter` and `RatBite`; existing player bump remains the fixture formula until the next slice.

- [ ] Write game tests for the rat's cataloged HD/attack, visible combat messages for dodge/block/absorb/hit, turn cost on each outcome, and unarmed starts; write save tests for combat state, RNG continuation, version-5 rejection, and negative shield blocks.
- [ ] Run focused game/save tests and observe red.
- [ ] Make the rat path consume committed catalog fields and current equipped item/skill/attribute components. Reset shield blocks at player action start, apply outcome to HP, and keep the existing player bump path working from the player fixture definition.
- [ ] Change save version to 6 and validate/restore combat state without `BaseDamage`; update existing version assertions and expected fixtures.
- [ ] Run focused game/save tests and commit this integration category.

### Task 3: Integrated verification and documentation

**Files:** `docs/port-inventory.md` and any bug-fix tests/source from integrated verification.

- [ ] Run `GOCACHE=/private/tmp/dcrawl-go-melee-cache go test ./...`, `go vet ./...`, and `go build ./...` with the same writable cache.
- [ ] Run a short 79×24 PTY start, rat engagement, save, and load; record observed outcomes.
- [ ] Update the port inventory with exact supported ordinary bite mechanics and deferred combat behaviors; commit documentation or fixes.
- [ ] Request a fresh read-only whole-branch review and resolve any Critical/Important finding, then repeat the integrated checks before local merge.

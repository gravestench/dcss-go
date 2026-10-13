# Human/Fighter Starting Profile Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Human/Fighter starting HP fixture with source-backed skills, HP, and MP, then display and save the full starting profile.

**Architecture:** `character` computes a pure starting profile from committed catalogs and the chosen weapon. `game` installs the result on Akara ECS components after creating gear; view, terminal, and save code consume copies of those components. The fixed Dungeon scenario and combat fixture remain intact.

**Tech Stack:** Go, Akara ECS, Bubble Tea v2, Lip Gloss v2, JSON save v4.

**Spec:** `docs/superpowers/specs/2026-10-13-human-fighter-start-profile-design.md`

## Global Constraints

- Reference pinned DCSS source revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`, `TAG_MAJOR_VERSION=34`.
- Gameplay and ordinary Go builds/tests consume committed catalogs only; they never run an importer or require the C++ checkout.
- Human/Fighter is the only playable pair; its six existing weapon choices, gear, fixed two-floor map, rat, and base-damage-4 fixture stay intact.
- Expected start: Str 16, Int 8, Dex 12; Fighting/Shields/Armour level 3 with 301 points each; selected weapon skill level 2 with 151 points; HP 18/18; MP 1/1.
- Skills are stable `SK_*` IDs with no shared mutable backing storage; character-specific ECS components belong only to the player.
- Save version 4 rejects version 3 and corrupt data atomically. Do not alter the user's untracked `dcrawl-save.json`.
- Use focused tests per contiguous category and the complete suite after integration, per the user's explicit preference.

## Review Focus

1. Unarmed and each armed choice must resolve `SK_WEAPON` to the correct skill without creating a phantom weapon; Task 1 tests every option.
2. An item-kind with missing or invalid weapon-skill metadata must fail with context; Task 1 tests the skill-resolution helper with malformed metadata.
3. A snapshot skill slice must not alias live ECS state, and restore must not retain caller-owned slices; Task 4 tests both directions.
4. Duplicate, reordered, or non-player skill records and a non-player Magic pool must be rejected before swapping the live game; Task 4 tests each form.
5. A valid damaged player and depleted MP must retain current values through save/load, while out-of-range MP fails; Task 4 tests both cases.

---

### Task 1: Resolve Fighter skills and Human points

**Files:** Create `internal/character/starting_skills.go`, `internal/character/starting_skills_test.go`; read existing `internal/content/job.go`, `internal/character/weapon.go`.

**Interfaces:** Consume `content.Catalog`, `content.JobDef.Skills`, `content.SpeciesDef.Aptitudes`, `content.ItemDef.WeaponSkill`, `ValidateWeaponChoice`. Produce `type Skill struct { ID string; Level int; Points int }` and `func StartingSkills(c content.Catalog, speciesID, jobID, weaponID string) ([]Skill, error)`.

- [ ] **Step 1: Write failing tests.** `TestStartingSkillsHumanFighterWeapons` iterates all six legal choices and asserts exactly three fixed grants plus the correct fourth `SK_*` skill at level 2; points are 301/301/301/151, and returned slices do not alias. `TestStartingSkillsRejectsUnsupportedChoice` covers another pair and an illegal choice. `TestResolveChosenWeaponSkillRejectsBadKind` calls the private resolver with an empty or unknown `WeaponSkill` and checks a contextual error.
- [ ] **Step 2: Run red.** `go test ./internal/character -run 'TestStartingSkills' -count=1` fails for the missing API.
- [ ] **Step 3: Implement.** Use a private `resolveChosenWeaponSkill(kind content.ItemDef, species content.SpeciesDef) (string, error)` for armed choices, or `SK_UNARMED_COMBAT` for unarmed; validate supported pair and aptitude; implement the source's Human `skill_exp_needed(level)+1` point calculation from `skills.cc:2047-2083` for the supported levels, and retain source grant order. No ECS dependency or package-level mutable table.
- [ ] **Step 4: Run green.** The focused command passes.
- [ ] **Step 5: Commit.** `feat: calculate Human Fighter starting skills`.

### Task 2: Derive the pure starting profile and vitals

**Files:** Create `internal/character/start_profile.go`, `internal/character/start_profile_test.go`; use existing `internal/character/stats.go`.

**Interfaces:** Consume `StartingSkills` and `BaseStatSum`. Produce `type StartProfile struct { Attributes Attributes; Skills []Skill; MaxHP int; MaxMP int }` and `func BuildStartProfile(c content.Catalog, speciesID, jobID, weaponID string) (StartProfile, error)`.

- [ ] **Step 1: Write failing tests.** `TestBuildStartProfileHumanFighter` asserts 16/8/12, HP 18, MP 1 and the chosen skill for armed and unarmed starts. `TestBuildStartProfileRejectsBadChoice` asserts a contextual error and zero result. The test checks the returned skill slice can be changed without mutating the catalog or a later result.
- [ ] **Step 2: Run red.** `go test ./internal/character -run 'TestBuildStartProfile' -count=1` fails for the missing API.
- [ ] **Step 3: Implement.** Apply the pinned `ng-setup.cc`, `jobs.cc`, `skills.cc`, and `player.cc:get_real_hp/get_real_mp` level-one Human/Fighter branches with the source's integer division order. Keep HP and MP formulas as named private helpers; reject unsupported species/job instead of generalizing incomplete mutation or equipment effects.
- [ ] **Step 4: Run green.** The focused command passes.
- [ ] **Step 5: Commit.** `feat: derive source-backed Fighter starting vitals`.

### Task 3: Own skills and MP on the ECS player

**Files:** Modify `internal/ecs/components.go`, `internal/ecs/stores.go`, `internal/game/scenario.go`, `internal/game/view.go`; create `internal/game/start_profile_test.go`; adjust existing scenario tests that assume HP 20.

**Interfaces:** Consume `character.BuildStartProfile`. Produce `ecs.Skills{Entries []character.Skill}`, `ecs.Magic{Current, Max int}`, corresponding Akara stores, and `game.View` fields `PlayerMP`, `PlayerMaxMP`, `Skills []character.Skill`.

- [ ] **Step 1: Write failing tests.** `TestScenarioInstallsStartingProfile` checks all six choices, HP 18/18, MP 1/1, skill entries, unchanged gear, and aut 0. `TestScenarioDamageKeepsMaxHP` checks current HP falls while max stays 18. `TestViewCopiesSkills` mutates a returned view and verifies a fresh view is unchanged.
- [ ] **Step 2: Run red.** `go test ./internal/game -run 'TestScenarioInstallsStartingProfile|TestScenarioDamageKeepsMaxHP|TestViewCopiesSkills' -count=1` fails.
- [ ] **Step 3: Implement.** Register player-only `Skills` and `Magic` stores, compute the profile after `createStartingGear`, set Health and Magic to full, and expose cloned skills in `View`. Keep monsters' existing Health and combat behavior.
- [ ] **Step 4: Run green.** The focused command and `go test ./internal/ecs ./internal/game` pass.
- [ ] **Step 5: Commit.** `feat: store starting profile on the player entity`.

### Task 4: Persist and validate save version 4

**Files:** Modify `internal/save/snapshot.go`, `internal/game/save.go`, `internal/save/codec_test.go`, `internal/game/save_test.go`; create `internal/game/start_profile_save_test.go`.

**Interfaces:** Consume `ecs.Skills`, `ecs.Magic`, and `character.BuildStartProfile`. Produce v4 `save.EntityRecord.Skills *ecs.Skills` and `.Magic *ecs.Magic`, deep copied by `Game.Snapshot` and `Restore`.

- [ ] **Step 1: Write failing tests.** `TestStartProfileSaveRoundTrip` preserves selected weapon, all skills/points, HP current/max, MP current/max, and seeded continuation. `TestSaveProfileSlicesDoNotAlias` mutates a snapshot and an input snapshot after restore; neither changes the live game. `TestRestoreRejectsInvalidStartProfile` table-tests duplicate/reordered/unknown skill IDs, altered points/levels, missing player components, character components on a monster or item, negative or over-max MP, and v3 rejection; failed load leaves the original game unchanged.
- [ ] **Step 2: Run red.** `go test ./internal/save ./internal/game -run 'TestStartProfileSaveRoundTrip|TestSaveProfileSlicesDoNotAlias|TestRestoreRejectsInvalidStartProfile' -count=1` fails.
- [ ] **Step 3: Implement.** Bump `save.Version` to 4; deep-copy skill entries, compare the player's no-training skills against a fresh `BuildStartProfile`, enforce player-only component ownership and MP bounds, and populate the stores only after record validation. Keep `Restore` separate and atomic. Update old version expectations.
- [ ] **Step 4: Run green.** The focused command and `go test ./internal/save ./internal/game` pass.
- [ ] **Step 5: Commit.** `feat: save and validate Fighter skills and MP`.

### Task 5: Show the profile in the terminal

**Files:** Modify `internal/terminal/render.go`, `internal/terminal/model.go`, `internal/terminal/render_test.go`, `internal/terminal/model_test.go`; add focused tests in `internal/terminal/start_test.go` if pregame input needs coverage.

**Interfaces:** Consume the `game.View` profile fields. Produce `MP:1/1` on the status line and a `c` character-information toggle that shows readable stable skill names and levels without spending auts.

- [ ] **Step 1: Write failing tests.** `TestRenderShowsStartingMP` checks HP 18/18 and MP 1/1. `TestCharacterInfoShowsSkillsWithoutTurn` checks all four grants, the chosen weapon skill, `c` toggle behavior, and no aut change. `TestLoadV4BeforeWeaponChoice` checks a valid v4 save bypasses the menu and a v3 save is rejected without constructing a game.
- [ ] **Step 2: Run red.** `go test ./internal/terminal -run 'TestRenderShowsStartingMP|TestCharacterInfoShowsSkillsWithoutTurn|TestLoadV4BeforeWeaponChoice' -count=1` fails.
- [ ] **Step 3: Implement.** Render pools and an information pane from view copies; keep presentation names in a small pure formatter and leave creation math in `character`.
- [ ] **Step 4: Run green.** `go test ./internal/terminal -count=1` passes.
- [ ] **Step 5: Commit.** `feat: display starting skills and magic`.

### Task 6: Integrated verification and port inventory

**Files:** Modify `docs/port-inventory.md` and tests only if integrated verification exposes a concrete gap.

**Interfaces:** Confirm the source-backed Human/Fighter start is truthful end to end; leave other starts, skill training, spells, full combat, and generation explicitly unported.

- [ ] **Step 1: Update inventory.** Record HP 18/18, MP 1/1, source skill levels/points, v4 save, character view, and remaining fixture combat damage.
- [ ] **Step 2: Verify.** Run `go test ./... -count=1`, `go vet ./...`, `git diff --check`, and `go build ./cmd/dcrawl` in a temporary Go-only copy without the C++ checkout; check the user's untracked save remains untouched.
- [ ] **Step 3: Exercise the terminal.** Confirm armed and unarmed start, `c` view, v4 save/load, and valid damaged-HP persistence through the executable.
- [ ] **Step 4: Refine concrete failures.** If an integrated check fails, write a focused regression test, fix it, and rerun the relevant checks.
- [ ] **Step 5: Commit.** `docs: record source-backed Fighter start status`.

After Task 6, request one fresh whole-branch review focused on the five Review Focus cases. Fix confirmed Critical/Important findings in a single pass with regression tests, record Minor findings, run the full suite once, and use the branch-finishing workflow. Do not infer that this completes the broader DCSS port.

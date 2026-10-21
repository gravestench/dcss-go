# Hell Entry and Return Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans. Work through the
> checks below in order and commit this contiguous travel category once its
> integrated tests pass. The user's one-category-per-commit instruction takes
> precedence over per-task commits.

**Goal:** Make source Hell gates enter a persistent authored Vestibule and
return to the most recently used outside gate, including across saves.

**Architecture:** Lua owns portal direction, destination, and messages.
The Go session stores one validated Hell return record and stages an
unseen Vestibule through the existing level transaction. Distinct grid
features identify gates; no source vault record is consulted during travel.

**Tech Stack:** Go, embedded Lua, Akara ECS, typed terrain grids, Go saves.

**Spec:** `docs/superpowers/specs/2026-10-21-hell-branches-design.md`

## Global constraints

- Preserve source `.des` geometry and the five tagged Vestibule wings.
- Keep mutable travel state in the Go session save, never a Lua module global.
- Use Lua files for all game decisions and source messages.
- Leave Pan behavior intact while the command kernel gains Hell travel.
- One commit for the entire entry/return category, then push `main`.

## Review focus

1. A rejected generated Vestibule must roll back RNG, actors, and level.
2. Reentering from a second gate must change the return site, not regenerate
   the Vestibule or erase its actors.
3. An occupied outside gate must find a safe nearby return cell.
4. A malformed saved return site must fail restore before play resumes.
5. Directionally wrong gate commands must spend no time.

## Task 1: Build the source Vestibule as a staged level

**Files:**
- Create `internal/modfs/builtin/policy/generation/hell/vestibule.lua`
- Modify `internal/modfs/builtin/policy/generation/scenario.lua`
- Test `internal/script/testdata/lua/tests/hell_vestibule_test.lua`

**Interface:** Register `world.generate_hell_vestibule`, accepting prior
vault IDs and returning `{ level = <normal level record> }`. Its level ID is
`branch_levels.id(BRANCH_VESTIBULE, 1)`; it executes the required
`vestibule_of_hell_subvaulted` layout and selects a source return arch as
entry. The level uses the shared terrain decoder and population path.

- [x] Add a Lua test asserting all five wings, live branch gate terrain,
      at least one `DNGN_EXIT_HELL`, and a walkable entry.
- [x] Run the focused Lua test and observe the absent policy fail.
- [x] Implement generation and run the same test to green.

## Task 2: Choose travel in Lua and persist the return site

**Files:**
- Create `internal/modfs/builtin/policy/world/hell/travel.lua`
- Modify `internal/modfs/builtin/policy/commands/navigation.lua`
- Modify `internal/modfs/builtin/policy/commands/entries_navigation.lua`
- Modify `internal/game/command_script.go`, `internal/game/commands.go`
- Create `internal/game/hell_portal.go`, `internal/game/hell_state.go`
- Modify `internal/game/game.go`, `internal/save/snapshot.go`,
  `internal/game/save.go`, `internal/game/save_restore_levels.go`
- Test `internal/game/hell_travel_game_test.go`

**Interface:** `command.prepare` receives `hell_state` and returns a portal
plan with domain `hell`. Lua decides enter, revisit, and exit. Go prepares
and commits either a Pan or Hell portal through one transport interface.
`save.HellStateRecord` stores the Vestibule entry and latest outside gate.
The Go transaction validates a staged floor before moving the player.

- [x] Add Go command tests for first entry, second-gate reentry, exit to
      latest gate, occupied-gate landing, save/restore, wrong direction,
      and rollback after failed generation.
- [x] Run the focused Go tests and observe Hell commands fail.
- [x] Implement Lua planning, staged Go travel, and save validation.
- [x] Run focused Go tests and existing Pan portal tests to green.

## Task 3: Make authored outside gates appear in play

**Files:**
- Modify `internal/modfs/builtin/policy/generation/vaults/extra.lua`
- Modify `internal/modfs/builtin/policy/generation/generated.lua`
- Test `internal/script/testdata/lua/tests/hell_entry_generation_test.lua`
- Test `internal/game/hell_travel_game_test.go`
- Update `docs/port-inventory.md` and `docs/modding.md`

**Interface:** Eligible Depths floors select from effective
`vaults/hell_entry/*.des` with source chance and uniqueness rules, including
the fallback entrance when no earlier gate exists. Candidate order is by
stable vault ID, never discovery order. The projected `enter_hell` cell is
the same feature used by Task 2's command policy.

- [x] Add seeded generation and overlay tests for ordinary and fallback
      gates, with one live command through a generated gate.
- [x] Run the focused tests and observe missing gates fail.
- [x] Reuse the existing source chance stage and fix nested mapless child
      placement discovered by the generated Depths test.
- [x] Run focused and integrated generation/travel/save verification.
- [x] Run `gofmt`, `git diff --check`, and the repository style checker.
- [x] Review the category, commit it once, and push `main`.

The style checker still reports older issues in untouched Go files. Newly
added Hell code was formatted and reviewed against its output.

## Subsequent categories

The four subbranch floor catalogs, exits, bosses, runes, and Hell entry
effects remain required by the parent spec. Their completion is not implied
by this plan or its entry/return commit.

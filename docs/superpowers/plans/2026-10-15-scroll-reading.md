# Scroll Reading Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use
> superpowers:executing-plans to implement this plan task-by-task. Steps use
> checkbox (`- [ ]`) syntax for tracking. Make one commit after the complete
> scroll-reading category and integrated verification.

**Goal:** Make all 19 active source scrolls readable, discoverable, and
mod-extensible through Lua effect files.

**Architecture:** Each scroll effect registers one Lua module. A shared read
command returns a selection request when needed, then one Akara intent
resolves the effect. Go carries only generic selection data and draws the
Lua-directed terminal menus. The command dispatch itself becomes a Lua
registry so adding read does not enlarge the numeric branch chain.

**Tech Stack:** Go 1.25, Akara ECS, embedded Lua, Bubble Tea/Lip Gloss,
the current versioned Go save.

**Spec:** `docs/superpowers/specs/2026-10-15-scroll-reading-design.md`

## Global Constraints

- Work in `/Users/dylanknuth/src/dcrawl-go` on `codex/lua-player-magic`.
- The reference is DCSS `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Include all 19 active source scrolls in this category; do not register
  placeholder effects.
- Put gameplay, eligibility, and presentation decisions in real Lua files;
  Go adds only generic command, ECS, and terminal services.
- Use the effective layered catalog and committed Lua definitions; no C++
  checkout or importer runs during normal build or play.
- Import IDs and constants at use sites. Use expanded multi-field literals,
  preferably 80-character lines and never over 120 in handwritten code.
- Preserve `dcrawl-save.json`; do not touch the paused C++ refactor.
- One integrated verification run and one commit for the complete category.

## Review Focus

1. A known cancellable scroll with no valid target must leave time, stack,
   and discovery unchanged (Tasks 1, 2).
2. An unknown scroll that reveals a target choice must follow its source
   cancellation cost without leaking a free identification (Tasks 1, 2).
3. Restoring during a lasting effect must preserve its duration and target
   ownership, then expire it once (Tasks 3-5).
4. A mod-added scroll with its own effect file must load, read, and change
   the ruleset hash; a missing effect must fail at boot (Tasks 1, 6).
5. A terminal target menu must show visible names and submit exactly one
   read action after selection (Task 6).

---

## Task 1: Generic read lifecycle and registries

**Files:** Modify `internal/game/commands.go`,
`internal/game/command_script.go`, `internal/ecs/components.go`,
`internal/modfs/builtin/constants/intent.lua`,
`internal/modfs/builtin/policy/input/commands.lua`,
`internal/modfs/builtin/policy/command_prepare.lua`,
`internal/modfs/builtin/init.lua`, and the command files
under `policy/commands`. Add `policy/commands/registry.lua`,
`policy/commands/read.lua`, `policy/scrolls.lua`, and
`systems/item_read.lua`. Add `internal/game/scroll_read_test.go` and Lua
`tests/scroll_read_test.lua`.

**Interfaces:** `commands.register(kind, prepare)` accepts a unique named
command kind. `scrolls.register(id, effect)`, `scrolls.get(id)`, and
`scrolls.validate()` use the effective item catalog. Effect modules expose
`prepare(ctx, player, request)` and `apply(ctx, player, request)` methods.
The read command carries primary `item_id`, optional string `target_id`,
`dx`, `dy`, and `cancelled`. A Lua decision may return a `selection`
record with `kind`, `title`, and options containing `id` and `label`;
Go validates and returns a typed request without spending time. A
resolved read uses
`intent.READ` and one `item.read` system. Acquirement saves its generated
offers on the scroll entity so prompts remain stable across cancel and
restore.

- [ ] Write failing tests for read command dispatch, invalid item, known
  cancellation, unknown cancellation, and a Lua selection request; prove
  the new handler is discovered without adding another central branch.
- [ ] Extract existing command handlers from the numeric branch chain into
  command modules registered by named kind; keep common actor and turn
  restrictions in `command_prepare.lua`.
- [ ] Add the generic selection fields to Go's command/result and ECS
  intent envelope, with typed validation of Lua decisions. Save
  acquirement offers on the scroll and verify identical offers after
  restore.
- [ ] Add scroll effect registration, active-catalog completeness checks,
  and the read command/system transaction. Test with one real effect from
  Task 2 before treating the lifecycle as complete.

## Task 2: Item-choice scrolls

**Files:** Add `policy/scrolls/effects/identify.lua`,
`enchant_weapon.lua`, `enchant_armour.lua`, `brand_weapon.lua`, and focused
helpers under `policy/scrolls/items`. Add Lua
`tests/scroll_item_choice_test.lua` and Go
`internal/game/scroll_item_choice_test.go`.

**Interfaces:** Item selection uses `target_id` holding an entity ID;
eligibility helpers
read the same ECS item and identification components as wielding and
presentation. Effects update the selected physical item and its knowledge;
identify additionally reveals the selected type to the player.

- [ ] Write failing tests for all four scroll IDs, source eligible and
  ineligible targets, known cancellation, unknown discovery, enchantment
  caps, and a brand result surviving save and restore.
- [ ] Implement the four effect files against `item-use.cc:2820-3040,
  3650-3710`, reusing current item validation and brand constants.
- [ ] Run focused Lua and Go item-choice tests; resolve only concrete
  failures before moving to the next family.

## Task 3: Translocation and map knowledge

**Files:** Add `teleportation.lua`, `blinking.lua`, `magic_mapping.lua`
under `policy/scrolls/effects`, plus a saved teleport delay and map
knowledge representation only where existing state cannot express the
source behavior. Add Lua `tests/scroll_translocation_test.lua` and Go
`internal/game/scroll_translocation_test.go`.

**Interfaces:** Reuse `ctx:move_actor`, current no-tele rules, and dense
level exploration. A requested blink destination is carried by `dx/dy`;
the read command validates it before spending a turn when known.

- [ ] Write failing tests for all three scroll IDs, blocked teleport,
  destination validity, delayed teleport after save and restore, and
  revealed map cells surviving a level transition.
- [ ] Implement the three effects from `item-use.cc:3110-3145,
  3530-3569,3600-3612` and their called source functions.
- [ ] Run focused Lua and Go translocation tests.

## Task 4: Area actor effects

**Files:** Add `fear.lua`, `torment.lua`, `immolation.lua`,
`vulnerability.lua`, and `silence.lua` under `policy/scrolls/effects`.
Add focused saved status schemas or helpers only for state the current
monster/player status modules do not own. Add Lua
`tests/scroll_area_effects_test.lua` and Go
`internal/game/scroll_area_effects_test.go`.

**Interfaces:** Reuse current monster fear AI, inner-flame explosions,
silence radius, willpower, resistance, and damage policies. Effect files
select targets from the active level without a scroll-ID switch.

- [ ] Write failing tests for all five IDs, immunity and resistance,
  hostile and friendly targets, expiry, and save/restore of lasting
  statuses.
- [ ] Implement source effects from `item-use.cc:3170-3408,
  3570-3652,3710-3720` and the corresponding called source functions.
- [ ] Run focused Lua and Go area-effect tests.

## Task 5: Clouds, noise, and summons

**Files:** Add `fog.lua`, `poison.lua`, `noise.lua`, `summoning.lua`, and
`butterflies.lua` under `policy/scrolls/effects`. Reuse or extend the
existing cloud, noise, and summon policies in their own directories.
Add Lua `tests/scroll_world_effects_test.lua` and Go
`internal/game/scroll_world_effects_test.go`.

**Interfaces:** Clouds are saved location-bound entities; summons use the
current owner/expiry component and AI allegiance; noise uses the existing
propagation service. Effects return source cancellation outcomes when no
valid placement exists.

- [ ] Write failing tests for all five IDs, blocked cloud placement,
  source cloud duration, noise waking a monster, summon allegiance and
  expiry, and save/restore.
- [ ] Implement the five effects from `item-use.cc:3570-3602,
  3640-3652` and the called cloud/summon functions.
- [ ] Run focused Lua and Go world-effect tests.

## Task 6: Amnesia, acquirement, terminal, and integration

**Files:** Add `amnesia.lua` and `acquirement.lua` under
`policy/scrolls/effects`, with source-backed choice helpers. Extend
`policy/input/items.lua`, `policy/input/play.lua`,
`policy/presentation/modals.lua`, `internal/terminal/app.go`,
`internal/terminal/play_input.go`, and `internal/terminal/modals.go` with
a Lua-directed read selection flow. Add Lua `tests/scroll_choice_test.lua`,
Go `internal/game/scroll_choice_test.go`, and terminal
`internal/terminal/read_test.go`.

**Interfaces:** Amnesia uses `target_id` holding a spell ID;
acquirement returns stable
choices between prompt and commit, then grants the selected item. Terminal
selection handles item, spell, map, and acquirement prompts through one
generic path and passes only selected IDs or coordinates to Go.

- [ ] Write failing tests for both IDs, legal and illegal selections,
  stable acquirement offers, unknown scroll cancellation, and `r` menu
  behavior without hidden item-name leakage.
- [ ] Implement amnesia and acquirement from `item-use.cc:3550-3569,
  3719-3760` and called source functions; do not use placeholder gifts.
- [ ] Complete the terminal selector and source read messages. Test all
  prompt types and both known and unknown cancellation.
- [ ] Add a sparse mod fixture with an extra scroll and effect; verify
  startup failure if its effect file is removed.
- [ ] Assert registry coverage for exactly the 19 active built-in scroll
  IDs and run the focused Lua, game, terminal, and save tests.
- [ ] Run `GOWORK=off GOCACHE=/private/tmp/dcrawl-go-build-cache go test
  ./... -count=1 -timeout 30m`, `go vet ./...`, a client build, style,
  and `git diff --check` once at the category boundary.
- [ ] Update `docs/port-inventory.md`, commit one scroll-reading category,
  fast-forward local `main`, and return to `codex/lua-player-magic`.

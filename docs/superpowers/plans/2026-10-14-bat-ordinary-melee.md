# Dungeon bat and ordinary natural melee implementation plan

> **For agentic workers:** Use superpowers:executing-plans for native
> implementation. Track each step below before the category commit.

**Goal:** Make bats source-backed D:1 monsters and generalize the current
ordinary bite path to plain natural hits without changing existing animals.

**Architecture:** Static bat capabilities come from the committed catalog.
An ECS AI counter owns post-attack retreat; the combat system applies attack
results and the AI system decides each later action. Pure combat and XP rules
receive projections, not copies of mutable game state.

**Tech stack:** Go, Akara ECS, committed DCSS content, Go snapshot codec.

**Spec:** `docs/superpowers/specs/2026-10-14-bat-ordinary-melee-design.md`

## Global constraints

- Source reference is `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
- Generated content is committed; importers do not run during builds or play.
- No duplicate old/new combat path or compatibility layer.
- Go lines have a 120-column maximum; prefer 80 columns and spaced groups.
- Multi-field struct literals use one field per line.

## Review focus

- A bat attack that misses still begins retreat.
- Retreat cannot cause an attack on the player while the bat is wandering.
- A saved bat with one retreat action resumes the same next decision.
- A non-bat save cannot carry a bat retreat counter.
- Adding bat to population does not alter legacy fixed-scenario rosters.

## Tasks

1. Write failing source-backed tests for bat HP bounds, XP, catalog profile,
   and generated D:1 eligibility. Add bat to the supported population after
   validating its immutable definition. Rename bite-only runtime APIs and
   profiles to ordinary natural melee in the same change; keep no aliases.
2. Write failing pure combat tests for `AT_HIT` using the existing hit,
   shield, damage, and AC sequence. Widen the ordinary attack input and
   result messages to support a plain hit without changing bite rolls.
3. Write failing AI/system tests for retreat after both hit and miss, two
   subsequent bat decisions, and saved mid-retreat continuation. Add the
   counter to `ecs.MonsterAI`, set it on attack, use it in decision making,
   and validate it on restore.
4. Add integration tests for bat spawning, source speed, combat death XP,
   corpse eligibility, and terminal rendering. Update the port inventory
   and ECS roadmap to state the new boundary precisely.
5. Run `go test ./...`, `go vet ./...`, `go build ./...`,
   `sh scripts/check-go-style.sh`, and `git diff --check`. Get read-only
   review, fix findings, commit this category once, and fast-forward local
   Go `main` under the user's standing integration preference.

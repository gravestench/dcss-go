# Lua Terminal Input Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move all current terminal key and menu policy from Go to embedded Lua in one contiguous conversion.

**Architecture:** One Lua input policy dispatches to focused screen modules and returns a next-state record plus an optional host effect. Go validates and applies this result using reusable terminal and game lifecycle operations. Remove the original Go key switches in the same pass.

**Tech Stack:** Go, Bubble Tea, Akara, gopher-lua, embedded mod files.

**Spec:** `docs/superpowers/specs/2026-10-15-lua-terminal-input-design.md`

## Global constraints

- No inline Lua in Go and no parallel Go keymap.
- Keep DCSS key behavior and full-terminal rendering intact.
- Use one category commit after the integrated gate.
- Keep handwritten lines at or below 120 characters, preferably 80.

## Review focus

- Unknown keys on each screen keep their current notice and spend no game time.
- Malformed mod policy output changes no game or terminal state.
- Menu letter selection follows the visible page, not the full list index.
- Equipment delays accept only their current interrupt/save controls.
- Mods can replace one screen's key policy by relative path, changing hash and behavior.

### Task 1: Input state and host boundary

**Files:** `internal/terminal/app.go`, `internal/terminal/play_input.go`,
`internal/terminal/input_*.go`, `internal/script/policy.go`, and
`internal/modfs/builtin/policy/input.lua`.

- [x] Define the policy input and output records for current AppModel state and game view.
- [x] Validate next-state fields and effect requests before applying either.
- [x] Add a same-path Lua override test and malformed-output rollback tests.

### Task 2: Pregame screens

**Files:** `internal/terminal/pregame.go`, `internal/terminal/input_pregame.go`,
and `policy/input/pregame.lua`.

- [x] Move startup, species, background, weapon, and name key decisions to Lua.
- [x] Keep Go only for starting/loading games and generic state application.
- [x] Cover page letters, focus movement, name editing, disabled choices, and help return.

### Task 3: Play and menus

**Files:** `internal/terminal/*_input.go`, `internal/terminal/keys.go`, and
`policy/input/*.lua`.

- [x] Move movement and game command keymap to Lua and delete `CommandForKey`.
- [x] Move item, equipment, targeting, skills, stat, modal, confirmation, and death key decisions to Lua.
- [x] Keep Go game command execution, save I/O, drawing and Bubble Tea lifecycle mechanics.
- [x] Cover a representative key and unavailable response from every screen.

### Task 4: Integrated gate

**Files:** changed Go and Lua files, `docs/port-inventory.md`.

- [x] Run terminal and game tests, `go test ./... -count=1`, vet, build, style, catalog and diff checks.
- [x] Review the whole category for leftover Go key switches or duplicate routes.
- [x] Commit once and fast-forward local Go `main`.

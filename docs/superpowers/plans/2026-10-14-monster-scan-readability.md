# Monster Table Scanner Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Separate the monster table scanner's preprocessing, table traversal, and row decoding without changing imported monsters.

**Architecture:** `parseRows` remains the entry point. One helper builds active tag-34 table text and source positions. A scanner owns the source and line lookup; methods parse normal aggregate rows, removed `AXED_MON` rows, and `DUMMY` placeholders.

**Tech Stack:** Go, `sourceparse.Tag34NumberedLines`, existing monster importer tests.

**Spec:** `AGENTS.md` readability rules and the committed source-backed monster catalog contract.

## Global Constraints

- Preserve scanner error text and source line numbers.
- Preserve `AXED_MON` and `DUMMY` behavior and 27-field aggregate padding.
- Preserve generated `monsters.json` bytes.
- Keep the local `main` checkout's untracked save file untouched.

## Review Focus

- Unsupported directives inside the table must still fail with their source line.
- Macro continuation lines must still keep correct offsets.
- A missing table terminator must still report the same source line.
- An invalid aggregate ID must still fail after field-count validation.
- `DUMMY` placeholders must still be omitted from returned rows.

---

### Task 1: Split monster table parsing stages

**Files:**
- Modify: `internal/content/monsterimport/scan.go`
- Test: `internal/content/monsterimport/scan_test.go`

**Interfaces:**
- `activeMonsterTable(path string, data []byte) (string, []int, []sourceparse.Line, error)` prepares active source.
- `monsterRowScanner` owns `path`, `source`, `starts`, and numbered lines.
- Scanner methods own line lookup, aggregate rows, removed rows, and placeholders.
- `parseRows` sequences preparation and traversal.

- [x] Run focused tests and record monster artifact hash.
- [x] Extract helpers in the original validation order.
- [x] Run `gofmt` and focused tests.
- [x] Run full tests, vet, build, style check, importer artifact check, and diff check.
- [x] Obtain independent review; commit and fast-forward local `main`.

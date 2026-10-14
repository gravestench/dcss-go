# Boolean Condition Readability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make crowded condition chains scannable without changing behavior.

**Architecture:** Extend the existing Go AST readability checker to report
three or more `&&` or `||` operators on one line of an `if` condition. Reflow
existing conditions so each clause has its own line, retaining grouping and
operator order. Leave source fixture strings and generated artifacts intact.

**Tech Stack:** Go AST, gofmt, Go tests.

**Spec:** `AGENTS.md` code readability rules and the user's feedback.

## Global Constraints

- Preserve all boolean expressions, evaluation order, and behavior.
- Keep handwritten Go lines at or below 120 columns; prefer 80.
- Make one commit for this condition-readability category.

## Review Focus

- Parenthesized subexpressions retain their meaning.
- Short-circuit behavior and error checks stay in the same order.
- Fixture strings remain byte-for-byte unchanged.
- The checker reports a crowded condition once per line.
- The checker accepts a multiline version of the same condition.

---

### Task 1: Flag crowded `if` conditions

**Files:** `scripts/check-go-readability.go`,
`scripts/check-go-readability_test.go`

- [x] Add a test with a four-clause `if` on one line and a multiline twin.
- [x] Implement AST token-line counting for `&&` and `||` in `if` conditions.
- [x] Run the checker tests and inspect the reported violations.

### Task 2: Reflow existing conditions

**Files:** Handwritten Go files reported by the checker.

- [x] Put conditions on separate lines while preserving parentheses and order.
- [x] Run gofmt, the full style check, tests, vet, and build once for the category.
- [x] Review the diff and commit the condition-readability category.

# Cross-Actor Experience Implementation Plan

> **For agentic workers:** Execute natively. The user approved the
> recommended workflow and one contiguous category per commit.

**Goal:** Reconcile credited player XP in the same action, regardless of
which actor was active when the death occurred.

**Spec:** `docs/superpowers/specs/2026-10-24-cross-actor-experience-design.md`

## Tasks

- [x] Reproduce the failing Jiyva-to-Slime save after the reserved-ID fix.
- [x] Make player training and advancement run after any active actor's
  death phase, always targeting `ctx:player()`.
- [x] Verify the Jiyva restore, ordinary kill XP and stat choice tests,
  representative no-XP turns, build, and changed-file style.
- [x] Commit the full XP reconciliation category and push `main`.

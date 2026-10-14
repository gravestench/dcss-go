# Spell Catalog Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Commit a complete, source-traced tag-34 spell catalog usable without the C++ checkout.

**Spec:** `docs/superpowers/specs/2026-10-13-spell-catalog-design.md`

## Task 1 — Schema and source parser

- Add failing synthetic parser tests for numbered enum identities, alias exclusion, multiline descriptor fields, axed macro rows, and removed-set agreement.
- Implement a narrow spell importer using `sourceparse.Tag34NumberedLines`; reject ambiguous source rather than guessing. Record source paths, SHA256 hashes, and line numbers.

## Task 2 — Committed artifact and catalog

- Add strict artifact validation and defensive catalog accessors. Generate and commit the pinned artifact; use a byte-for-byte check mode for intentional refreshes.
- Embed and load the artifact in `LoadDefault`, preserving source-revision consistency and making runtime independent of the C++ tree. Update the port inventory.

## Task 3 — Verification and integration

- Test representative ordinary, monster-only, and removed spells, full identity coverage, malformed artifacts, and deterministic regeneration.
- Run full Go tests, vet, build, and read-only whole-branch review; fix Important/Critical findings; commit this content category and fast-forward merge to local Go main.

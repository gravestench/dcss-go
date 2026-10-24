# Broodmother Spider Contact Implementation Plan

> **For agentic workers:** Use superpowers:executing-plans to implement
> this plan as one cohesive category. Steps use checkboxes for tracking.

**Goal:** Make Broodmother's source Spider bite summon one durable spider.

**Architecture:** Share the weighted spider roster between the existing
spell and a focused natural-contact policy. Common summon creation owns
Akara state and placement. Save validation recognizes native monster
provenance and rejects forged offspring.

**Tech Stack:** Go, Akara ECS, embedded Lua, production Lua tests.

**Spec:** `docs/superpowers/specs/2026-10-24-broodmother-spider-contact-design.md`

## Global Constraints

- Keep all rules in Lua files; no inline Lua in Go.
- Explain why and how near every new function.
- Keep lines at or below 120 characters, with 80 preferred.
- Commit and push one complete category to `main`.

## Review Focus

- A bite without post-armour damage cannot summon or draw a chance.
- A blocked placement must create no hidden summon or success message.
- A monster victim and player victim use the same wound anchor rule.
- Save validation must reject forged monster-origin species.
- Existing Summon Spiders must retain the exact source roster.

## Tasks

- [x] Write failing production-Lua tests for contact, roster, and saves.
- [x] Extract shared spider pool and migrate the spell resolver.
- [x] Add `AF_SPIDER` contact through the common summon owner.
- [x] Validate native summon provenance and cover live melee routing.
- [x] Run relevant tests and style checks, review, commit, and push.

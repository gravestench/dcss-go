# Monster Melee Afflictions Implementation Plan

**Goal:** Apply source monster contact Confuse, Barbs, Rage,
Vulnerability, and Poison Paralysis through their existing saved owners.

**Scope:** Lua combat policy, necessary status-owner corrections, focused
Lua tests, and the port inventory. No new Go rule branches.

## Tasks

1. Add named flavour IDs and a readable affliction policy module.
2. Add player and monster regression tests before behavior changes;
   establish the expected failures.
3. Route each effect through the production status owner, preserving
   source chance and resistance draw order.
4. Exercise direct policy and live melee paths, inspect related save and
   game tests, and review the diff for readable Lua and no unowned state.
5. Commit and push the complete affliction category.

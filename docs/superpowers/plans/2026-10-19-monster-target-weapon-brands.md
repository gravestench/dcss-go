# Monster-target weapon brands implementation plan

**Goal:** Resolve every currently supported monster-target melee brand for
player, monster, summon, and player-illusion attackers through one set of
per-brand Lua policies.

**Design:** `docs/superpowers/specs/2026-10-19-monster-target-weapon-brands-design.md`

1. Add focused Lua tests that show ordinary monster and special summon
   attacks currently omit brand effects and that the brand damage owner
   must not grant player kill credit to hostile attacks.
2. Rename the monster-defender brand policy and its module directory.
   Update production and test imports in one pass; keep each brand effect
   in its own file.
3. Make the brand hit envelope attacker-neutral. Correct messages, kill
   credit, Pain skill, and Vampirism healing while preserving existing
   player attack behavior and source roll order.
4. Wire the shared dispatcher into ordinary monster-target melee and every
   strike of special summoned melee. Feed the saved illusion brand when it
   has no carried weapon.
5. Add rule and live-game tests for important brand families, resistance,
   status persistence, combat dispatch, and save/restore.
6. Run focused tests, a broader package check, build, formatting, style,
   and diff checks. Review the category, make one commit, fast-forward
   `main`, push `origin/main`, and verify remote and local heads match.

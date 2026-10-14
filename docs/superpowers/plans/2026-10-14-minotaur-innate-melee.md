# Minotaur innate melee implementation plan

1. Write source-value tests for Minotaur Fighter attributes, skills, HP/MP,
   level growth, and the terminal start/restore route. Enable the species in
   the existing supported Fighter path.
2. Add pure headbutt rules in `internal/combat`. Trace source roll order for
   the trigger, accuracy, damage, might, and target AC. Project immutable
   horns and the live player stats/skills into a narrow input.
3. Integrate auxiliary headbutt after the primary attack while the target
   lives. Integrate reflexive retaliation on eligible monster misses and
   award player XP/corpses if it kills the attacker.
4. Enforce horn/headgear fit both at wear time and when restoring a saved
   equipped item or delayed wear. Add deterministic behavior and save tests.
5. Update the current port inventory, run full category verification, ask
   for read-only review, fix findings, commit once, and fast-forward local
   Go `main`.

# Hobgoblin Dungeon implementation plan

1. Write failing source profile, XP rule, generated population, and save tests.
2. Extend the pure ordinary-monster XP calculation for source equipment-user
   difficulty and its slow-speed exception.
3. Add the source-backed hobgoblin profile and enable it in generated Dungeon
   population, reusing Akara monster creation and turn systems.
4. Update the inventory, run category verification and review, then commit and
   merge to local Go `main`.

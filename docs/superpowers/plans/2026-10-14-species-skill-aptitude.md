# Species skill aptitude implementation plan

1. Add source oracle tests and replace Human-only skill point, level, and
   scaled-level helpers with aptitude-taking equivalents. Keep source `float`
   and truncation behavior explicit.
2. Thread the player's ECS species through skill training, combat projection,
   the copied view, terminal skills menu, and baseline Fighting HP formula.
   Remove hardcoded Human lookups where those boundaries read aptitude.
3. Validate saved skill points and levels using the saved species' aptitudes.
   Preserve current Human/Fighter start and its established save format.
4. Update the port inventory and ECS roadmap. Run the full Go verification
   suite, review the category, commit it once, and fast-forward local main.

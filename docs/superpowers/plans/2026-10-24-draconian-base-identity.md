# Draconian base identity implementation

1. Write failing Lua tests for default and authored draconian job colors,
   untransformed and polymorphed corpses, and stale-color save rejection.
2. Add a documented, source-backed color policy and a typed Lua ECS component;
   attach and update it in the spawn and polymorph owners.
3. Keep polymorph roster lineage separate from corpse lineage. Update death,
   shapeshifter, and save validators to read each field for its purpose.
4. Verify affected Lua rules, game snapshot and restore, build, formatting,
   and the complete diff. Commit this category and push `main`.

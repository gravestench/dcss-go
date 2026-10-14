# Heal-wounds implementation plan

1. Add failing pure-rule tests for source `random2avg(28, 3)` bounds, truncation, cap, and invalid input.
2. Add an end-to-end Dungeon:2 pickup/quaff test, full-HP no-time test, and save-continuation test.
3. Implement the character rule and preflight/effect through existing ECS item and quaff flow. Place one floor potion in the fixed second floor.
4. Run focused tests, then the broad Go suite/vet/build, diff check, and read-only whole-branch review. Commit the contiguous gameplay category and merge local `main`.

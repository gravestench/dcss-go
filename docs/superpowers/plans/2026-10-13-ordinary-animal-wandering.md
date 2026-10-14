# Ordinary animal wandering implementation plan

1. Add tests that a hidden quokka wanders with an in-range floor target, redraws only on the `ai` stream, refreshes source-range memory when seeing the player, and stops blind pursuit after expiry. Verify save continuation and legacy AI records.
2. Add a deadline to ECS AI and source-shaped wander target selection. Reuse the existing movement choice for seeking and wandering. Validate the saved target/deadline, retaining version-6 compatibility.
3. Update the inventory. Run focused tests, then the integrated test/vet/build gate, whole-branch review, one category commit, and fast-forward local Go main.

# Monster awareness implementation plan

1. Add tests for a quokka behind opaque terrain, sight acquisition, pursuit of only the last visible tile, and save continuation. Keep existing adjacent rat attack behavior.
2. Store behavior and remembered coordinates in the ECS AI component, starting new animals unaware. Compute LOS from the monster at each decision. Preserve legacy `chase` saves and validate AI state on restore.
3. Update the port inventory with the exact implemented AI boundary. Run focused tests, then the full test/vet/build gate; review the whole branch and commit this category before merging to local Go main.

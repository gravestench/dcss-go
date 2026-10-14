# Fixed animal pathfinding implementation plan

1. Add a fixed-map test for a seeking quokka at the right side of the central wall reaching the gap toward a left-side remembered target; test occupied-cell avoidance and unreachable targets.
2. Implement deterministic eight-direction route selection as a Level-owned query. Use it when a target is unseen or the direct movement choices fail, retaining immediate adjacent melee behavior.
3. Update the inventory, run focused and full tests/vet/build, obtain whole-branch review, and commit/merge this category.

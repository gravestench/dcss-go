# Monster inventory lifecycle implementation plan

1. Write failing game tests for monster-carried item save restore, invalid
   links, and an equipped item surviving the monster's death as a floor item.
2. Validate monster carrier relationships after all saved actors and items
   are registered; keep player equipment checks separate.
3. Restore any validated carrier and release carried items at the monster
   death barrier before destroying the actor.
4. Update the inventory and ECS roadmap, run category verification and review,
   then commit and merge the lifecycle category to local Go `main`.

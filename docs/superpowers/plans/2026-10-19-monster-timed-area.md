# Monster timed-area implementation plan

1. Register saved monster aura state and identify the common actor-neutral
   vortex behavior. Add focused Lua tests for the shared behavior before
   changing implementation.
2. Implement Toxic Radiance's source target decision, immediate pulse,
   ongoing poison and damage, and expiration in its named spell module and
   tick owner. Test player and monster targets, allies, and duration.
3. Implement Polar Vortex's decision, saved cast and cooldown, shared wind
   tick, flight, and expiry. Test geometry and phase changes without
   duplicating the player vortex implementation.
4. Add live spellbook and save/restore coverage for both spells. Run the
   full Lua rule suite and focused Go game tests after integration, inspect
   formatting and diff, request code review, then commit and merge locally.

Use the standing approved native execution and local merge workflow.

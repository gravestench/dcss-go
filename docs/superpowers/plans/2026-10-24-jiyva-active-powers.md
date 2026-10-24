# Jiyva Active Powers Implementation Plan

1. Add two stable ability IDs and Lua modules under `policy/abilities/jiyva/`.
   Register the source rank, MP, piety, and failure tuples. Test both menu
   entries and rejection paths before implementing their effects.
2. Add a focused `policy/religion/jiyva/oozemancy.lua` owner. Reuse grid
   visibility and `policy/world/temporary_terrain.lua`; keep the feature
   eligibility table local and source explained. Track a player duration in
   a registered component, expire it in an ordered player-action system,
   and clean only Oozemancy markers on leave, penance, and floor exit.
3. Add a focused `policy/religion/jiyva/slimify.lua` owner. Reuse the
   fixed-form polymorph and Jiyva allegiance owners. Hook it into the
   successful primary player melee contact before ordinary damage and
   follow-up effects; preserve the timer on an ineligible contact.
4. Save and validate both timers through production schemas. Add Lua
   and game tests for effects, costs, ownership, expiry, and restore.
5. Document the power family and modding extension path. Run focused
   tests, build, style and staged diff checks, then commit and push one
   category commit.

# Implement source-backed unique placement

1. Port all 80 source NAME definitions to individual committed `.des`
   files. Convert inline source Lua to named Lua hooks and keep every MAP
   row exact. Prove catalog discovery and source ID parity.
2. Add a unique selection owner beside the existing chance and minivault
   stages. Carry the source loop, weights, dummy outcomes, existing map-use
   rules, protected-cell placement, and deterministic RNG through generation.
3. Add run-wide monster uniqueness as saved game state. Apply it during
   authored and ambient population, with the source's explicit exceptions.
4. Resolve source band names to leaders and implement unique band sizes,
   membership, placement, follower links, and save validation through Lua
   ECS policies. Reuse the policy for existing Kirke behavior.
5. Implement the Yiuf cottage and Pan veto hooks with direct, commented
   Lua methods. Add modding guide coverage for unique files and state.
6. Verify ID and MAP parity, meaningful seeded generation and restore
   tests, source band examples, and affected Go packages. Commit coherent
   categories directly on `main` and push each as it passes verification:
   the source vault catalog and selector, follower bands, then exceptional
   veto and respawn rules. The latter categories remain open after the
   first commit.

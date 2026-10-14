# Live Dungeon basic layout implementation

1. Extend `Level`, visibility, save stair records, and movement so closed
   doors and explicit unavailable stair destinations have one validated path.
2. Build D:1–2 from the committed Go generator on a named RNG stream; pair
   stairs, choose entry and floor item cells, and retain fixed test scenarios.
3. Draw source monster counts and populate supported Akara actors. Save the
   initial budgets and validate generated-run snapshots without weakening
   fixed-scenario validation.
4. Start the terminal client with the generated scenario. Add focused tests for
   live topology, interaction, and save continuation; then run category-wide
   verification and review before one commit and local-main integration.

# One-pass Lua gameplay conversion plan

1. Inventory every live Go system, command resolver, content-ID switch, and
   game-specific policy function. Mark the engine services Lua requires.
2. Finish one generic ECS context for both core Akara components and Lua
   schemas. Apply all structural changes at the same action barrier; discard
   them on callback failure. Validate primitive field types and entity
   handles there. Keep semantic rules in Lua.
3. Convert the existing playable game in one working-tree sweep: character,
   inventory/equipment/status, combat/spells, monster AI, generation/world,
   and command/client policy. Add Lua files under the embedded tree; remove
   Go behavior paths as each area is replaced. Do not commit partial
   compatibility layers.
4. Convert static content needed by those rules into committed Lua modules
   with source provenance. Importers remain intentional refresh tools.
5. Repair integration and source-fidelity failures after the broad edit.
   Test actual Lua files, mod overlays, save continuation, and roll order.
6. Run the full Go suite, vet, build, style and diff checks. Request a
   read-only whole-branch review, fix substantive findings, then make one
   broad conversion commit and merge it to local `main`.

# Jewellery equipment implementation plan

1. Trace active jewellery, slot rules, and action timing in the pinned DCSS
   source. Add Lua tests that load the production catalog and fail for the
   missing put-on/remove behavior.
2. Add committed, source-traced jewellery metadata for every active ring
   and amulet. Make the deliberate catalog exporter reproduce it. Validate
   effective mod layers at catalog load.
3. Add Lua equipment preparation and resolution for the whole put-on/remove
   intent family. Use the existing item and equipped ECS components and one
   generic path for bundled and mod-added jewellery.
4. Wire `P` and `R` through Lua input, presentation, command dispatch, and
   the narrow Go command-kind bridge. Include slot display in inventory and
   reject impossible equipment at save validation.
5. Test all active records and slot cases in `_test.lua`, run focused and
   full integration checks, then commit one contiguous category and
   fast-forward local `main`.

## Review focus

- The 24 active records work without a central item ID switch.
- Jewellery rules live in Lua; Go only transports stable command kinds.
- Ring slots remain unique in saves and Octopodes get their source slots.
- A new valid mod jewellery file follows the same equipment path.

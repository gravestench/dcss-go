# Magical staves implementation plan

1. Add Lua tests that load all seven production definitions, check the shared
   staff profile and metadata, and exercise the deterministic proc formula.
2. Add a `staff` record to each active staff definition and keep the catalog
   exporter reproducible from a committed source-traced staff-rules artifact.
   Resolve base melee properties through `WPN_STAFF` in the generic equipment
   and fighter paths. Validate the records at catalog load.
3. Add a focused Lua staff policy to resolve each on-hit proc, damage flavour,
   AC, and message. Call it from player melee after base damage, without
   changing weapon-brand dispatch or adding a Go item switch.
4. Apply the wielded staff's school and resistance from its metadata; keep
   the source's additive multi-school and three-level spell power cap.
   Include staves in the terminal wield picker and inventory modal.
5. Test wield, melee, spell power, resistance, and equipped save validation
   across the category. Use the existing engine save tests for serialization
   of the shared ECS components. Update port inventory. Run package tests,
   full suite, vet, build, style checker, and diff checks at the category
   boundary. Commit once and fast-forward local `main` after verification.

## Review focus

- Staves must not inherit weapon enchantment or brands.
- A melded staff must grant neither resistance nor spell enhancement.
- No Artifice must suppress only the magical proc, not ordinary staff melee.
- Earth and conjuration must use their different AC rules.
- Adding a staff in a sparse mod must use the same generic path.

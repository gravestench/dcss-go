# Hill Orc Fighter implementation plan

1. Add source-value tests for the Hill Orc Fighter profile and adjust the
   existing unsupported-choice tests. Implement starting skill reassessment
   and species baseline MP projection.
2. Pass a chosen `PlayerDef` into the live game constructor and use it in the
   shared scenario builder. Add a terminal selection test and make the
   species menu, weapon aptitude display, welcome text, and HUD read the
   selected identity.
3. Generalize save validation to reconstruct supported player starts from
   saved identity. Replace Human-specific barding checks and names where the
   same rule applies to Hill Orc. Add a Hill Orc round-trip save test.
4. Format, verify the category, request read-only code review, fix findings,
   commit once, and fast-forward local Go `main`.

# Maurice theft implementation plan

1. Add `_test.lua` cases using the production catalogs, item components,
   wallet, and melee entry point; confirm they fail before implementation.
2. Implement a focused `AF_STEAL` policy, sharing the existing inventory
   value and copy rules rather than adding a Go switch.
3. Add a wallet theft debit and dispatch the flavour after live contact.
4. Verify Lua cases, monster inventory save validation and Go game tests;
   update the port inventory, review, commit and push the category.

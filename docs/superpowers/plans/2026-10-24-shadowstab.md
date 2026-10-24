# Shadowstab implementation plan

1. Add a Lua `_test.lua` for the source phases, including live player and
   monster melee contacts, then confirm it fails before implementation.
2. Add the shared Shadowstab attack ID and a focused Lua policy that reads
   defender perception and sleep directly from existing owners.
3. Route forced contact and raw pre-armour damage through melee; route the
   post-hit invisibility loss through the flavour dispatcher.
4. Update the port inventory, run focused Lua and Go tests, review the diff,
   commit this category, and push `main`.

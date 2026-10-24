# Signature monster artefacts implementation plan

1. Add Lua tests for explicit source-guaranteed unrand generation and all
   five real factory spawns. Confirm the tests fail on the current path.
2. Keep random unique selection restricted to random-mode artefacts while
   allowing a catalogued explicit unique, including `mode = "none"`.
3. Add one gear handler per source owner and a shared factory materializer
   for unique weapon and body slots. Preserve ordinary and DES gear paths.
4. Test death drops, history, duplicate requests, and save/restore. Update
   the port inventory, review the category, commit, and push to `main`.

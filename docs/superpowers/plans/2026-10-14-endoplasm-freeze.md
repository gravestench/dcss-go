# Endoplasm Freeze implementation plan

**Goal:** Play source endoplasms in generated D:1–2, including natural
Freeze, source turn costs, XP, and no-corpse death.

**Architecture:** Keep immutable spell slots in a committed content
artifact. The existing ECS monster components remain authoritative;
spell choice is a transient intent and an ordered spell system resolves it.
Do not introduce a generic spell-effect framework before a second spell
requires one.

1. Commit a source-traced endoplasm spellbook row and validate its spell
   ID against the already committed spell catalog.
2. Extend the ordinary natural-monster profile for an endoplasm's spellbook
   and no-corpse outcome. Admit it to generated population, retaining
   the fixed roster. Test HP, XP, and population selection.
3. Add `IntentSpell` and cataloged spell energy. Choose Freeze before
   melee or movement only when the player is visible and adjacent; use
   the pinned 71-of-200 selection boundary.
4. Add a pure HD-1 Freeze damage roll and a focused spell system. Test
   damage, event, death, energy, and ordinary melee fallback.
5. Test save/restore continuation for spell RNG and monster state. Update
   the port inventory and ECS roadmap, obtain read-only review, run full
   test/vet/build/style/diff gates, commit the category, and fast-forward
   local Go `main`.

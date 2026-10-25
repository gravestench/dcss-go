# Discoverable god wrath and alignment

## Intent

The Lua retribution owner still contains a central handler table, a passive
god exclusion table, and an alignment copy. Adding a god's wrath currently
requires editing that owner. Move those declarations to each god's content
file so a sparse mod can add or replace a god and its punishment by path.

## Chosen approach

A central dispatcher table is easy to scan but duplicates the content
catalog and makes every mod change a shared file. Naming a `wrath_module`
in each god definition follows the existing `behavior_module`,
`conduct_module`, and `gift_module` pattern. A missing module means that
god has no active retribution. The definition also owns its `good`, `evil`,
and `chaotic` alignment flags. The resolved catalog drives both retribution
and Xom's god protection rule. The old static alignment map is removed.

The 26 pinned source gods retain their source enum order for existing
Wrath-card draws and ordinary timed wrath. New mod gods append in sorted ID
order, never filesystem load order. A mod can override a source god's
definition or add one new definition and one new handler module. Validation
rejects a missing or malformed named handler at boot.

## Verification

Source god definitions preserve the 21 retribution handlers and five
passive entries. A sparse layered mod adds a god and its handler, then
checks that ordinary timed wrath and a Wrath-card draw can select it.
Alignment tests cover source flags and a mod-added good god. Existing
religion tests and save/restore remain in scope for this domain. A
mod-added good god also starts its XP timeout when a later conversion
makes its existing penance active.

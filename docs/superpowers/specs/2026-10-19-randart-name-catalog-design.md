# Random artefact name catalog design

## Purpose

Generated artefacts currently use a private syllable name and a generic
unidentified appearance. DCSS has a weighted name database with weapon,
armour, jewellery, appearance, and book groups. This slice commits its
source phrases as discoverable Lua content and uses the relevant groups for
generated equipment. The item still saves its chosen true name and
appearance, so mod changes cannot rename an existing item mid-run.

## Content ownership

Each source database key becomes one Lua file under
`content/randart_names/`. It registers an ID equal to the source lookup key
normalized to lowercase, as the source database parser does,
and an ordered array of weighted phrases. This makes an overlay able to
replace one group by matching its path, or add a new group by adding a file.
The one-time conversion tool is not retained in the repo. Runtime and build
do not read the C++ tree. The effective VFS hashes every Lua definition.

The catalog validates positive integer weights and known `@key@` references
at boot. A missing key is an error for content references, while the source
hardcoded substitutions are handled by Lua policy. Entries are selected by
weight in declared order. File loading order does not enter selection.

## Naming flow

The item-generation stream supplies one saved cosmetic seed. A private
generator derived from that seed selects all name parts, so adding a name
does not change later item rolls. Weapon and armour true names use a source
database phrase half the time, jewellery one fifth of the time; otherwise
they use the existing source-shaped syllable name. Source name phrases may
refer to player name/species, branches, or gods. Those substitutions use
current catalog and player facts. A god marker checks the finished item's
type, brand, and properties against the source god suitability rules. Xom's
long names use a separate committed weighted list. In isolated tests without a live player,
player markers use an explicit generic identity. Unknown appearances use the
appropriate weighted class appearance group and retain only the item shape.
Book groups are committed for future book-title policy; this slice keeps the
existing random-book title behavior.

## Verification

Tests cover the imported group count, source weights and phrase expansion,
mod replacement by relative path, deterministic cosmetic seed behavior,
weapon/armour/jewellery appearance lookup, and save persistence. Run the
full Lua rules suite and related Go tests at the category boundary, then
commit, fast-forward `main`, and push.

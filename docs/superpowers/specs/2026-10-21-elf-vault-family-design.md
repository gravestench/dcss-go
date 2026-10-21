# Elf vault family

## Purpose

Port the complete pinned `elf.des` family as one coherent branch category.
The 115 source definitions comprise 16 Elf:1 PLACE choices, 55 ordinary
rooms and helpers, 19 Hall of Blades entry helpers, four Elf:2 Hall of
Blades primaries, and 21 Elf:3 endings. The source border check, Hall of
Blades, and final loot hall must be reachable, selectable, and saved.

## Authored content

Commit one `.des` file per source `NAME` under `vaults/elf_arrival/`,
`vaults/elf/`, `vaults/elf_blade_entry/`, `vaults/elf_blades/`, or
`vaults/elf_end/`. Keep MAP rows and static declarations intact. Source
Lua becomes named, commented Lua methods under the matching policy family;
its original script remains as adjacent DES comments. The six shared
source helper functions become focused shared Lua methods rather than
copied implementations in every ending. One-off import and audit tools
stay outside the repository.

## Floor flow

Elf:1 draws one source PLACE choice before optional maps. Its weighted
dummy leaves the procedural floor and reciprocal up stair intact. A
mapless `elven_spread` choice places one `misc_elf_vault` child. A map with
an authored `{` uses that landing for the branch's parent link, so its
border guard appears where the source intended. Elf:2 draws exactly one
of the four Hall of Blades maps and fits its tagged blade-entry SUBVAULT.
Elf:3 draws exactly one of the 21 endings before ordinary extras. These
are one floor-primary selection mechanism with branch data naming the
family per depth; Lair and other already ported endings use that same
mechanism. Failed fixed fits redraw a base floor without rerolling the
selected primary. Elf has no rune.

## Script and entity behavior

Shared Hall of Blades policy selects two distinct weapon bases and two
distinct egos, then emits source dancing-weapon declarations. The final
hall shared policy emits its standard monster roster, keyed defenders,
and loot substitutions at each source declaration site. Conditional
scripts preserve their draw and directive order. Every authored monster,
item, shop, statue, feature, and marker enters the existing typed level
record path; live effects that are still pending remain visible in the
port inventory rather than being silently discarded.

## Verification

An out-of-repo source audit compares all 115 names, MAP rows, static
directives, and script sites. Lua tests load and place every map through
the production catalog, check the Elf:1/2/3 weighted pools, Hall of
Blades helper resolution, shared hook emissions, and saved primary
history. Go tests travel Orc:2 to Elf:1 and through Elf:3, then restore
the result. A sparse mod adds an Elf room and ending without a Go roster.
Review the complete category and commit it once on `main` before pushing.

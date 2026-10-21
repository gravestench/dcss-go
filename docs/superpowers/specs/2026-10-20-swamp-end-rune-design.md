# Swamp End Vault and Decaying Rune Design

## Purpose

Make every generated Swamp:4 a source-authored ending. The pinned DCSS
`branches/swamp.des` defines eleven exact `PLACE: Swamp:$` maps. All eleven
remain individually selectable through the effective layered DES catalog.
One chosen map owns its authored terrain, monsters, marker intent, and one
real decaying rune. The player can collect that rune and travel back to
Swamp:3; save and restore preserve both current rune progress and historical
map identity.

## Architecture

Reuse the mandatory end-vault selector, placement stage, retry policy, and
save validator used by Snake:4. `branch_swamp.lua` names `swamp_end` as its
required end family. Weighted selection uses stable NAME order and keeps the
same choice across geometric floor redraws. Optional vault passes run only
after the ending fits and cannot overwrite its protected cells. A missing
family seals the Swamp:4 stair rather than generating an ordinary floor.

Commit each source map as `vaults/swamp_end/<NAME>.des`, preserving source
MAP rows and directive order. The source's three one-in-eleven conditional
sites become named `vault.run` methods in the matching family modules. The
byrel decay block becomes a named hook that records delayed corpse decay.
No inline executable Lua or build-time C++ importer enters the repository.
The existing generic DES parser and typed vault records handle the other
source directives, including marker and presentation intent.

## Runes and saves

Source substitutions may leave several candidate rune glyphs, but exactly
one resolved `RUNE_SWAMP` item record must survive each successful ending.
The generic end validator rejects zero or multiple runes before publishing
that map. Save validation requires exactly one real historical decaying rune
record from the selected primary end map; pickup may remove its live item.
The generic item and `character.runes` paths own collection.

## Verification

A committed corpus test pins all eleven source map dimensions and checksums
without accessing C++ during normal builds. Lua tests fit all eleven maps
through the production transform and placement path, exercise conditional
hook outcomes and reject malformed rune selection. A Go integration test
travels through the real branch schedule to Swamp:4, finds one collectible
rune, checks reciprocal stairs, round-trips a save after pickup, and rejects
a corrupted end identity or rune history. A sparse mod adds one extra
Swamp end map without a Go switch or registry edit.

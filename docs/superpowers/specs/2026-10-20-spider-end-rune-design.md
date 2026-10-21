# Spider End Vault and Gossamer Rune Design

## Purpose

Make Spider:4 use one of the nine pinned DCSS `PLACE: Spider:$` endings.
The selected map owns its terrain, authored entities, and one collectible
gossamer rune. The map and rune history survive save and restore. Sparse
mods can add another end map by placing one DES file in the same family.

## Design

Use the existing mandatory end-vault selector and save validator. The Spider
branch names `spider_end` as a required family and caps out-of-depth monster
requests at source depth seven. Every source MAP row stays byte-identical in
one committed DES file. Port the four conditional source script sites to
named Lua methods. A shared Lua module emits the source's three loot requests
at the original site in every map. The tomb's feature-name script becomes a
typed name record. No build or runtime step depends on the C++ checkout.

The weighted draw sorts by stable map NAME and survives geometric retries.
Every successful placement must resolve exactly one `RUNE_SPIDER` request.
Rune pickup uses the generic Akara item and player rune paths. A Spider
ending can put an ambrosia potion on the same cell, so pickup may require
more than one action. Restore verifies selected map identity and historical
rune ownership through the shared branch end save rule.

## Verification

Pin nine source MAP dimensions and checksums, then fit every map through the
production DES path across several independent random streams. Check the
weighted candidate count, a sparse mod addition, and live Dungeon to Lair
to Spider:4 travel, reciprocal stairs, rune pickup, and save rejection for
forged end identity or rune history. Check the C++ source MAP bytes once
during import; normal tests read only committed Lua and DES content.

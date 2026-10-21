# Depths entrance family

## Purpose

Replace the provisional D:15 stair to Depths with one of the eight source
`depths.des` entrance maps. Every map must enter the effective layered DES
catalog, keep its source geometry and directives, and use the scheduled
Depths link for reciprocal travel and save/restore.

## Authored content

Commit one `.des` file per source `NAME` under `vaults/depths_entry/`.
Preserve MAP rows and per-map declarations. The source `depths_entry(e)`
helper contributes the same static tags, `PLACE: D:$`, weight, orientation,
and keyed `enter_depths` feature to each file. Keep its original invocation
as a comment at that point. The one source feature-name script becomes a
named Lua hook in the matching module. No runtime importer or C++ source
dependency enters the game build.

## Selection and level flow

The existing branch-entry owner draws by effective source weight and fits
the map before optional vaults. It recognizes the `depths_entry` family and
its keyed feature. If a candidate cannot fit, another candidate can be
tried; only a placed map claims uniqueness or saves records. D:15 retains
one scheduled Depths link, using the final keyed coordinate when authored.
The child Depths:1 returns to exactly that coordinate. The floor and link
survive the Go save format. A sparse mod can add a ninth map or replace one
without changing the selector.

## Verification

An out-of-repo audit compares all eight source names, MAP rows, retained
static declarations, and script sites. Lua tests place every map, check the
eight weighted candidates and keyed gate, and verify a mod-added candidate.
A Go test travels D:15 to Depths:1, returns, and round-trips a save. Focused
generation regressions, all-package compilation, formatting, and diff
checks gate one category commit to `main` and a push to the user's fork.

# Shared Actor Cells Design

## Purpose

Fedhas permits a worshiper to stand on a stationary plant or fungus. The
current Go level index stores only one actor per cell. This prevents a
source-faithful Grow Oklob or Ballistomycete aimed at the player and prevents
walking through eligible plants. The same spatial limitation would obstruct
future mechanics that legitimately share a cell.

## Ownership and rules

The Go level owns an ordered collection of actor handles at each cell. The
position component remains the authoritative location for each actor. A cell
normally admits one actor. An explicit shared placement or move can admit a
second; the grid does not decide *which* actors may share. Lua policy makes
that decision before requesting a shared operation.

`actor_at` retains a deterministic primary actor for existing callers.
`actors_at` exposes all actors, in deterministic order, to policies that need
to distinguish the player and a plant on the same square. When the player
shares a cell, the player is primary so targeting and rendering still see
the player. The plant remains indexed and visible to explicit enumeration.

The Lua transaction's staged occupancy must reflect earlier actions in the
same turn, including removal from a shared cell. Region replacement and
atomic actor permutations preserve the full collection. Restoring a save
rebuilds the index in player-first order, then validates shared cells through
Lua policy. A corrupt save cannot introduce unrelated overlaps.

## Fedhas behavior

Lua checks the current worship passive, the monster's plant holiness and
stationary flag, the vine exceptions, and the hostile Oklob exception.
Eligible plants admit the player's move. Growth aimed at the player's own
cell places the new plant beneath the player. Other occupied destinations
retain the current collision behavior. Moving into a plant costs 1.5 times
the ordinary move and reports the source-style message on entry.

## Verification

Exercise placement, movement, removal, staged reads, rollback, region
replacement, restore, and rejected unrelated overlaps. Exercise Fedhas
self-growth, overgrowth, passage, and loss of eligibility after leaving or
entering penance. Build the CLI and run focused Go and Lua tests at the slice
boundary.

# Beogh active abilities implementation plan

**Goal:** Make Smiting, Recall, Give Item, and Resurrection playable through
Lua abilities, ECS state, terminal prompts, and save/restore.

**Design:**
[Beogh active abilities spec](../specs/2026-10-23-beogh-active-abilities-design.md).

The ability modules own source rules. Existing spell, inventory, corpse,
monster, and grid owners handle generic operations. The Go command bridge
passes selected entity IDs without Beogh-specific code.

## Source costs and command fields

1. Declare stable Beogh ability IDs.
2. Read rank, penance, MP, Invocations, and piety from existing components.
3. Carry selected target and item IDs through the generic command intent.
4. Test rank gates, failure draws, and cost commitment.

## Smiting

1. Register the two-star menu entry in Lua.
2. Preflight a visible cell at source range seven.
3. Use the existing Smiting spell effect at source power.
4. Charge three MP and source piety only after a successful invocation.
5. Test targeting, failure, and empty-cell use.

## Recall

1. Save a queue of living, friendly Beogh gift entities on the player.
2. Rank candidates by source HD plus ten-sided draw in stable entity order.
3. Advance one queue across player turns and move off-level companions
   through the grid owner to a nearby habitable cell.
4. Offer Stop Recall while the queue is active; clean up on death or
   departure from Beogh.
5. Test order, cross-floor movement, timing, death, stop, and restore.

## Give Item

1. Offer visible named followers, then qualifying player items.
2. Save the first choice while the second free prompt is open.
3. Recheck item fit and ownership at the timed action.
4. Transfer the existing item entity, drop replaced equipment, and
   record the follower's one lifetime gift category.
5. Test cancellation, incompatibility, transfer, repeat gifts, and save.

## Resurrection

1. Add a saved identity record to each ordinary orc corpse.
2. Preserve HP, HD, name, gift history, and dropped gear IDs.
3. Select and confirm a corpse on the player's cell, then find an
   adjacent habitable landing cell.
4. Restore the orc as a Beogh companion through the monster factory,
   reclaim gear still at the corpse, consume the body, and pay 28 piety.
5. Validate saved corpse and resurrected actor origin; test blocked
   placement, prompts, and restore.

## Category verification

Run the focused Lua rules and game integration tests, the affected Go
packages, `go build ./...`, and `git diff --check`. Review the changed
Lua for explanatory comments and lines over 120 columns. Commit this
one contiguous Beogh ability category and push `main`.

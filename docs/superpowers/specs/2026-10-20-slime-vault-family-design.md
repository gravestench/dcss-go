# Slime Entrance and Ordinary Vault Family Design

## Purpose

Complete the non-finale content from the pinned source `slime.des`. Ten
`slime_entry` definitions own the scheduled Lair entrance to Slime; the
other eighteen definitions may be selected on their source Slime depths.
`slime_pit` remains the already committed whole-floor Slime:5 ending.

## Source files and selection

Commit each source definition as its own DES file under `vaults/slime_entry`
or `vaults/slime`. Keep every source MAP row and gameplay directive in the
source format. Add an individual explanatory file comment without changing
the authored definition. No importer or C++ runtime dependency is shipped.

The effective layered VFS discovers every file. Source minivaults use the
existing depth-qualified draw. An explicitly oriented map uses one
branch-family regular-vault draw before minivaults fill the floor; both
paths use the same DES placement and population policies. `!Slime:$` keeps
them off Slime:5. A branch entry selector chooses from
all effective `slime_entry` maps in stable ID order, honors source weights,
and retries failed protected-stair fits without repeating a rejected map.
The source `KFEAT: O = enter_slime_pits` cell becomes the actual pending
branch stair. If no map fits, source Crawl's single-stair fallback remains.
This shares one branch-entry placement owner with Temple.

## State and extension

The selected entrance map and its typed records join the parent Lair
level's saved vault history. Save/restore preserves the stair link and map
identity. A sparse mod can add or replace an entry or ordinary map by path;
no Go registration edit or filename ordering dependency is needed.

Tests check all 28 source definitions, source MAP fidelity, candidate
selection, a live scheduled Lair entry, and a sparse mod addition. Any
source directive whose gameplay consumer is not yet implemented remains
typed data and is identified in the port inventory rather than discarded.
Stair travel searches nearby connected floor when an actor has occupied a
saved landing, keeping reciprocal links fixed and preventing a blocked
return from rejecting the player's action.

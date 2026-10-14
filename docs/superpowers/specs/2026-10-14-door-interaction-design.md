# Explicit door interaction in the playable Dungeon

## Source behavior and scope

The pinned console binds `O` to open and `C` to close in `cmd-keys.h:77,85`.
`movement.cc:388-556` chooses the only adjacent door automatically when
`easy_door` is enabled (its default), otherwise asks for a direction. Invalid
targets and an occupied visible doorway cost no time. `player.cc:7825-8171`
changes every four-connected identical door cell and charges a turn on
success. Closing pushes floor items to adjacent solid floor outside the door
group; it refuses without time if any item has nowhere to go. An unseen
creature blocking closure still consumes a turn and gives no free detection.

The Go slice supports the current `+` closed and `'` open terrain. A command
uses the existing 10-aut ordinary turn. It does not introduce sealed, runed,
broken, or clear doors, stealth noise, inscriptions, or new terrain kinds.
Those source behaviors remain future domains.

## Ownership and flow

`Level` owns connected door groups and terrain/remembered-cell changes.
`Game` checks a requested direction or the default adjacent choice before
spending time. An ordered Akara door system performs the terrain change and,
for closing, moves floor-item `Position` components to valid adjacent cells.
It draws from a named, saved door RNG stream only when choosing among push
targets. Player and monster positions stay in the level occupancy index.

The terminal uses the same movement direction keys after `O` or `C` when
several neighboring doors qualify. Escape cancels without a turn. A single
neighboring door acts immediately; zero neighboring doors shows the source
style no-time message. The game API also accepts an explicit direction, so
terminal behavior is not the only way to use the command.

## Verification

Tests cover a single door, multiple adjacent choices, connected groups,
wrong or nonadjacent targets, player and monster blockers, item pushing and
jamming, turn cost, terminal direction/cancel flow, and save/restore after
closing. Integrated tests, vet, build, style, and review precede one
door-interaction category commit and a local main fast-forward.

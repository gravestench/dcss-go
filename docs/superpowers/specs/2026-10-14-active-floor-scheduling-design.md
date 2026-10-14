# Active-floor turn scheduling

## Goal and source

Only actors on the player's current floor receive ordinary turns. Crawl
updates a returned level in one pass (`files.cc:2185-2186`,
`timed-effects.cc:680-755`); it does not run absent monsters through normal
decisions every time the player acts elsewhere. The Go port already applies
its supported corpse-aging catch-up on return. This slice removes the
remaining off-floor no-op monster turns and prevents a backlog on arrival.

## Ownership and behavior

Akara `Actor.NextAut` remains each actor's mutable deadline, and `Position`
determines floor membership. `TurnScheduler` selects only actors with a
position on the active floor. `Game` coordinates stair travel and level
activation; `Level.awaySinceAut` records departure for supported timed
effects. The monster-decision system rejects an off-floor actor if called
outside the scheduler contract.

Inactive deadlines remain unchanged. On first entry or return, activation
applies the existing corpse catch-up and raises any destination monster
deadline earlier than the current clock to that clock. This gives each
monster at most its normal action opportunity during the arrival turn. Full
source `update_monster` return-time healing, movement, and enchantment
catch-up remains a later monster-behavior category.

## Saves and checks

The version-8 schema is unchanged. Restore permits an inactive actor's
deadline to precede the save clock and still requires every active actor's
deadline to be current or future. The next unpaused active turn must belong
to the player. Save continuation must preserve frozen deadlines and the same
first return action. Tests cover inactivity, return without a turn backlog,
active-clock rejection, and deterministic restore. Run the full Go suite,
vet, build, and readability gate before committing the category.

# Monster Stair Followers Design

## Intent

Ordinary up and down stairs should bring source-eligible monsters with the
player. This includes allies and pursuers, the linked Dowan/Duvessa rule,
and the survivor's saved climb allowance. Keep every gameplay decision in
Lua. Akara owns the temporary follower mark and each actor's durable state;
Go continues to own grid movement and action scheduling.

## Approaches

Selecting monsters only after the player changes floors is simple, but
monster decisions can move them between command acceptance and travel.
Moving actors during command preparation would mutate state before the
destination has been validated. The chosen approach tags candidates in
the accepted action-start policy, suppresses their normal decision for
that action, and transfers them in the existing `world.stairs` system.
It preserves the source's tag-before-delay order within the Go engine's
single-action travel model.

## Source behavior

The pinned source tags live, active, mobile monsters whose energy is at
least 50 and which can inhabit ordinary floor. Friendly followers can
chain through nearby followers up to radius five unless a hostile actor
is adjacent to the player. Hostile followers must be adjacent and already
seeking the player. The source takes at most 18 real followers. A tagged
actor does not move during the stair delay. Ordinary summons, stationary
bodies, most zombified classes, tentacles, and specific immobile or
special monsters cannot use stairs. Branches with no cross-level travel
do not carry ordinary followers.

Dowan and Duvessa transfer together while both are alive and eligible.
If only one remains, it can transfer only after its grief state sets
`can_climb`. This rule applies to a polymorphed twin by original identity.
The receiving floor places followers near the player without replacing
their ECS identity, carried gear, HP, statuses, or other saved state.

## Ownership and event flow

`policy.world.stair_followers` coordinates candidate selection, pair
adjustment, and temporary marks. Its focused eligibility and placement
modules own their respective rules. The public API is
`tag(ctx, player, origin)` and
`transfer(ctx, player, origin, destination_level_id, x, y)`.
`command.action_start` calls `tag` only for an accepted ordinary linked
stair intent. A new `world.stair_follower` bool marker identifies actors
whose next decision should be skipped. `world.stairs` transfers marked
actors after placing the player and clears all markers on both successful
travel and an aborted stair action. The Go command bridge passes a generic
`stair_travel` flag to action start; it does not classify monster types.

The follower owner uses the committed branch catalog's
`no_x_level_travel` flag, with Pandemonium's source exception. It uses
the ordinary monster catalog, AI, energy, status, and position components
to decide eligibility. A destination with no free connected cell leaves
that follower on the old floor and emits an explanation rather than
corrupting occupancy; a saved transit queue is a later travel domain.
This edge differs from the source's deferred transit list but preserves
the player action and actor state.

## Boundary

This category covers both ordinary stair directions and generated
destinations. Portal arches, Abyss feature stairs, transporters, and
forced travel use different existing commit paths and are excluded here.
The source's religious companion exception in disconnected branches
will belong to the portal/follower domain because that gameplay owner is
not yet represented. No C++ save compatibility is needed.

## Verification

Lua `_test.lua` cases cover eligible pursuer and ally selection, radius
and cap, suppression of an intervening decision, stationary/summoned/
incapacitated exclusions, twin pairing and lone-grief allowance, branch
restrictions, and a crowded destination. Full Go game tests descend and
ascend with a live follower and save and restore its identity and carried
gear. The category ends with a build, focused suites, style and format
checks, one commit, and a verified push to `main`.

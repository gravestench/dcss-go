# Vault Monster Spawn Behavior Design

## Purpose

Make source `.des` monster `generate_awake` and `patrolling` directives affect
live actors. An ordinary hostile vault monster starts asleep, an explicitly
awake monster starts wandering, and a patrol remains near its authored anchor.
The design keeps changing state on Akara actors and game rules in Lua.

## Source behavior and scope

The pinned C++ source sets a vault monster to `BEH_SLEEP` unless
`generate_awake` is present. Friendly and neutral authored monsters instead
start awake. A map-level `generate_awake` tag applies to all its monsters.
`patrolling` is an independent flag whose anchor is the placed monster cell.
The four source statue monsters (orange, obsidian, ice, and Roxanne) cannot
start asleep, even without an awake directive.
Generic monster creation outside vault generation keeps its present awake
default: source `mgen_data` also defaults to an awake hostile role. This slice
does not change the player-facing terminal layout.

## Runtime ownership

`core.ai.behavior` gains `sleep`; the existing Go AI store already saves this
string. The Lua monster decision rule spends a turn waiting while asleep,
uses the shared stealth/perception contest when the player is visible, and
switches to pursuit when it wakes. Audible noise and damage can wake it too.
The existing player stab policy reads the same AI role.

Patrol state uses a Lua ECS component holding the anchor level and cell. The
Lua wander rule asks a focused patrol policy for a reachable target near the
anchor. On losing a foe the actor resumes patrolling; if no candidate exists,
it waits or heads toward its anchor. The source flag and anchor survive a save.
No separate copy of the patrol state lives in a Go struct or module global.

## Placement and saves

The DES parser already retains both modifiers. Placement also records the
map-level awake tag. Materialization passes the selected flags into the
monster factory. The factory sets the initial AI role and attaches the patrol
component after it creates the actor. Restore accepts a sleeping role only
with no remembered target. A patrol component must belong to a live authored
actor and keep its original spawn cell as anchor.

## Verification

Lua tests follow `.des` selection through placement, materialization, AI,
noise, damage, and save validation. They check default sleep, explicit and
map-level awake flags, patrol movement staying near the anchor, and a forged
patrol record. Relevant game and script tests run before the category commit.

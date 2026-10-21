# Vault Fog Machine Gameplay Design

## Purpose

Make every committed `lua:fog_machine { ... }` vault marker an active,
durable source of clouds. The original `.des` file remains authoritative for
the marker cell and parameters. Lua implements the behavior with the port's
cloud catalog and ECS world state. Normal play and saves use only committed
Lua and `.des` files.

The source marker is a triggerable object: it places initial clouds when a
level is entered, then counts down in aut while that level is active. Its
parameters can choose cloud kind, random-walk origin, area size, power,
delay, spread, exclusion radius, and gradual size or spread buildup. The
machine does not occupy its map cell as an actor. Existing cloud entities
own every generated cloud and its damage, opacity, spread, attribution, and
decay.

## Authored input and validation

The vault record keeps the complete marker expression after DES line
continuations are joined. A focused Lua reader accepts the source's
`fog_machine` call with one flat parameter table. It parses only that
table's scalar values; it does not install the old
`FogMachine` class or execute inline Lua from Go. Bad parameter types,
negative timing, unsupported cloud names, or malformed expressions fail
with the source vault and marker location. The original API's unused
`buildup_amnt` and `buildup_time` fields in one source vault remain inert,
as they are in the pinned source implementation.

The reader supplies source defaults: thin mist, walk distance zero, power
minimum one, three power rolls, spread override minus one, one entry cloud,
and one-cell exclusion radius. `pow_max`, a size or size range, and a delay
or delay range are required. Cloud names resolve through one shared Lua
mapping to registered cloud IDs; no content ID is retyped at call sites.

## Ownership and timing

One Lua-defined `world.fog_machine` component stores each machine's
authored coordinates, cloud ID, parameters, current countdown, and buildup
time. Materialization creates one ECS entity for each surviving fog marker
and marks its vault record realized. A restore validator checks the entity
against its source marker, prevents duplicates or orphan machines, and
validates timing and derived fields. Saved RNG state plus countdown and
buildup state make continued play deterministic.

The turn hook receives the level before and after an action. It advances
machines on the prior active level by that action's aut. If the player enters
another level, it resets each destination machine's countdown and emits its
`start_clouds` burst. Initial game creation does the same once for the
starting floor. Loading a save does not synthesize an entry event. Inactive
machines and their clocks stay frozen; the existing cloud owner handles its
own off-level state.

Each crossed delay boundary emits an area cloud, up to the source
triggerer's bounded repeat limit for one action. The countdown consumes
and redraws each delay as in the source triggerer. Buildup time advances
with action aut
before the emission. Each emission chooses size and power from the source
ranges and rolls on a named fog RNG stream. A random walk may move the
emission center to nearby nonsolid cells. Area placement expands through
the terrain grid independently of player visibility, since a machine can
operate outside sight. It places cloud entities through the existing
`policy.clouds.placement` owner.

## Verification and modding

Lua tests use real committed fog-marker maps and hook-produced markers. They
cover all supported parameter shapes, defaults, malformed definitions,
countdown boundaries, buildup, random walks, offscreen area placement,
entry versus restore behavior, and shared cloud catalog names. An integrated
game test forces a source map with a fog machine, observes an entry burst
and timed continuation, then saves and restores without duplicating either
the machine or its clouds. A mod may add or replace a `.des` file at the
same relative path. The modding guide documents the marker table and the
fact that the engine's Lua policy owns its runtime state.

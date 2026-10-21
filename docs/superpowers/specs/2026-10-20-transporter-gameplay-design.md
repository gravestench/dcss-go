# Transporter Gameplay Design

## Purpose

Make the committed source-format `.des` transporter maps playable. A player
standing on a transporter can press either stair key and arrive at its named
landing site on the same floor. All linked arrival, overflow, Temple, and
serial-subway maps use one rule. The map should display the source feature,
and a save should restore the same connection without rerunning generation.

This is a complete transporter mechanic, not a special case for the two D:1
tutorial maps. It preserves the existing split: terrain belongs to the level
grid, the static link to saved vault records, and action policy to Lua.

## Source semantics

The pinned DCSS source's `transp_loc(name)` and
`transp_dest_loc(name)` markers identify a source cell and its destination.
Destination names must be unique on a level; several source cells may point
to the same destination. A source without a destination, duplicate
destination, or unused destination is an authored-map error. The pairing
happens after all maps on that level have been placed, so the subway's
three separately authored stations can link to one another.

The source paints a transporter at each source and a landing site at each
destination. The portal is one-way, though `<` and `>` both activate it.
Uninhabitable or blocked landings reject the action. An occupant can move to
a nearby habitable free cell; if it cannot, the transporter refuses passage.
Eligible nearby monsters can follow after a successful player move. The
player receives the source message and spends a movement action only when
passage succeeds. The source also leaves short translocation-energy cloud
and learns an unknown transporter destination; these use the existing cloud
and saved knowledge owners, rather than a new global cache.

## Chosen structure

An independent Go transporter-link table would duplicate the saved vault
records. ECS entities would make immutable level topology look like actors.
Instead, Lua resolves the named marker records into source and destination
coordinates during the final level decode. It paints the two grid features
and stores each source link as typed arguments on its retained marker record.
The existing generic marker-property query exposes the destination to Lua.
The names and property keys live in shared Lua constants.

`policy.generation.transporters` pairs records and paints terrain.
`policy.world.transporters` owns activation and any follower relocation.
`policy.commands.navigation` accepts either stair command on the feature;
`systems.world_stairs` executes the move. The Go terrain catalog only adds
the two feature IDs and their console glyphs. No Go content-ID switch or
transporter-specific command is introduced.

## Persistence and validation

The existing save already carries the terrain grid, vault records, and
actor positions. A Lua save validator checks each live source marker's
name, target coordinates, matching destination marker, and painted terrain.
It rejects forged links, duplicates, and stale terrain. Derived player
knowledge belongs in saved character or level state if it changes play or
display; it must not be inferred solely from whether a transporter was used
in this process. The ruleset hash still identifies modified Lua or DES files.

## Verification

Lua tests exercise marker pairing across separate vault maps, duplicate and
missing names, both stair keys, occupied and blocked landings, follower
eligibility, and save validation. An integrated game test enters an authored
transporter and confirms the position, terrain, event, action cost, and
save/restore path. The full affected Lua and game tests run at the category
boundary, followed by style and diff checks. Documentation explains the
source marker syntax and the runtime contract for modders.

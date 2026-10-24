# Fedhas Active Powers

## Intent

Port the four active Fedhas invocations from the pinned DCSS source so a
player can use them through the ordinary ability menu and command. Keep
the rules in readable Lua and dynamic plants in the existing ECS world.

## Design

- The ability registry exposes Wall of Briars at two stars, Grow
  Ballistomycete at three, Overgrow at four, and Grow Oklob at five.
- Use the source MP, generic piety, failure, and range tuples. A free
  targeting cancellation or invalid target does not spend a turn.
- Wall of Briars fills eligible adjacent cells with friendly timed briar
  actors. The two Grow powers summon their named plant at a selected
  habitable, empty cell within range two. Plant summons use source
  Invocations scaling for HD and abjuration duration.
- Overgrow aims at one destroyable feature. It also affects eligible
  visible neighboring features, replaces each with its source floor, and
  creates one of the five source plants there. Preserve vault destruction
  vetoes and leave permanent rock untouched.
- A summoned plant is a real saved ECS actor with its owner, god source,
  duration, and allegiance. Terrain changes are permanent saved grid edits.
- The current level index permits one actor per cell. Source Fedhas can
  share a cell with a stationary plant and walk through it; that requires
  a separate spatial-occupancy change and remains a known follow-up.
- Each power has its own small Lua ability module. A focused Fedhas plant
  owner shares cell selection and spawning without a giant dispatch table.

## Verification

Lua rules tests cover registration and ranks, resource and target gates,
plant placement, terrain changes, and save validation. A Go game test
checks command timing and restore across a summoned plant and Overgrow.

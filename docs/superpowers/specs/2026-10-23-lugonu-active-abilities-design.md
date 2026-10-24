# Lugonu active abilities design

## Intent

Port Lugonu's complete active power set as one playable domain. The six
source abilities are Depart the Abyss, Bend Space, Banish, Corrupt, Enter
the Abyss, and the once-per-run distortion weapon blessing. A Lugonu
worshipper should be able to progress from an Abyssal Knight start to
each power without encountering a menu stub. The game stays Lua-first:
Go exposes generic ECS, grid, save, and terminal operations, while these
rules live in embedded Lua files.

This is a single gameplay category and one implementation commit. The
existing Abyss, translocation, banishment, item, piety, and corruption
owners remain the source of generic behavior. Lugonu policy supplies
the god-specific gates, costs, and choices.

## Approaches

The selected approach extends the existing Lua owners and has each new
ability call the relevant owner. This keeps the source rules visible in
small named modules and avoids a second branch engine. A large Lugonu
resolver would centralize code but make every power harder to read and
extend. Porting the C++ ability dispatcher as a compatibility layer
would recreate the coupling the project is removing.

## Shared ability contract

- Rank gates follow `religion.cc`: one star for Depart, two for Bend,
  three for Banish, four for Corrupt, five for Enter, and a sixth-star
  once-only blessing.
- Penance and patron changes remove the powers immediately. All prompts
  are free; a successful invocation consumes one ordinary player action.
- The source three-roll Invocations failure calculation is shared with
  other divine abilities. A failed invocation spends the turn but does
  not spend MP, HP, or piety.
- Depart costs 1 MP and 10-15 piety; Bend costs 1 MP and 2 HP; Banish
  costs 4 MP and 3-4 piety; Corrupt costs 7 MP, 5 HP, and 10-15 piety;
  Enter costs 10 MP and 28-42 piety, then reduces HP by the source
  averaged draw.
- Each power rechecks live worship, resources, location, and selected
  entities at its timed resolution boundary. Cancellation leaves those
  resources and the clock alone.
- A generic, god-parameterized Lua cost owner replaces the Beogh-only
  copy. Its callers supply their own rank, failure tuple, and cost.

## World and combat powers

Depart is offered only within the Abyss and uses the existing Abyss exit
transition. It returns to the saved outside site, including the pocket
start's D:1 destination. Enter is offered only outside the Abyss and
uses the existing `abyss.enter` transaction, preserving a return site
and the generated Abyss state. Before Depart, Bend, or Enter moves the
player, the source warns in an unsafe fight if the move would break Icy
Armour or Frozen Ramparts. This is a movement-status confirmation, not
a generic teleport or stasis gate.

Bend Space invokes an uncontrolled player blink and then gives each
nearby hostile, teleportable monster an independent coin-flip blink.
Nearby allies and anchored or immobile monsters stay in place. Grid
movement and cloud effects belong to the existing movement owners.

Banish is aimed at a visible hostile target within current vision. The
player cannot target themself. The source power is 68 plus scaled
Invocations, and the existing banishment zap's will check decides
whether a contacted target moves to the Abyss. A miss still commits an
attempt and pays the invocation cost after the successful ability roll.

Corrupt is unavailable in the Abyss and on a level already carrying a
Lugonu corruption nexus. A successful cast places a guaranteed nexus
at the player and source-random auxiliary nexuses, permanently changes
eligible terrain according to distance, protects stairs and other
uncorruptible features, and displaces actors and items before solid
changes. Nexuses retain duration in saved level state; elapsed player
time produces neutral Abyssal servants and eventually expires the
effect. Source color and tile flavor can be represented by terminal
cell styling, but terrain and servant behavior cannot be replaced with
messages or placeholder records.

## Distortion blessing

The sixth-star capstone offers real carried melee weapons. Artefacts
and ranged weapons are excluded. The player chooses an item, confirms
the choice, and receives a distortion brand plus two enchantment steps.
The existing item entity retains its inventory identity. A successful
blessing records `religion.worship.one_time_abilities[GOD_LUGONU]`, so
leaving and rejoining Lugonu never grants another use. Cancellation or
an invalid item does not mark the capstone spent.

## Ownership, saves, and tests

Lugonu ability files own selection and god policy. Existing ECS actor
and item components own living entities and equipment. The dense grid
owns terrain. One level-scoped corruption record owns nexus positions,
remaining duration, and save validation; its tick system runs during
normal time advancement. The worship component already owns the
once-only capstone map.

Focused Lua tests cover every power's gates, cancellation, success and
failure, resource charges, target resistance, and changed grid or item
state. Go game integration tests cover real command prompts, turn cost,
and save/restore for Abyss travel, corruption clocks, and the blessing.
Terminal tests confirm the generic selection and confirmation screens
display the Lua choices. Verification runs the affected Lua and Go
packages and `go build ./...` once the category is integrated.

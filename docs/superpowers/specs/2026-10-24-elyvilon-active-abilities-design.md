# Elyvilon Active Abilities Design

## Intent

Port all four active Elyvilon powers from the pinned DCSS source as one
coherent Lua patron domain. A player should discover them through the
ordinary ability menu, use them through the generic command bridge, and
save or restore every lasting effect. Modders should be able to replace a
power without editing Go code or a patron switch.

## Source contract

`religion.cc` grants Purification at one star, Heal Other at two, Heal
Self at three, and Divine Vigour at five. `ability.cc` defines their MP,
piety, and Invocations failure tuples. The abilities cost two MP and two
piety, two MP and two piety, two MP and three piety, and zero MP and six
piety respectively. Purification works while confused; the other three
do not. A failed invocation spends its turn but does not pay MP or piety.

Purification is available only when at least one curable ailment is present.
It clears sickness, poison, confusion, slow, petrification, weakness,
temporary stat loss, and HP drain. The current port has no live sickness
or temporary stat-loss producers; the owner will recognize those states
when introduced and clear all currently represented source ailments now.

Heal Self requires missing HP and is unavailable during Death's Door. On
success its healing is `pow + 2d(pow) - 2`, where `pow` is capped at 50 and
starts at `10 + skill_rdiv(Invocations, 1, 3)`.

Heal Other targets a visible cell without requiring a projectile path. An
empty cell commits the action so invisible monster locations are not leaked.
A friendly or neutral monster is healed. A hostile target can be pacified
only when its intelligence, holiness, mobility, wakefulness, and source
species limits permit it. The pacification check uses the monster class's
average HP, class intelligence and holiness, and the source biased two-roll
distribution. Successful pacification changes real allegiance to neutral,
records the nonlethal defeat, and then heals the target. A failed chance
leaves it hostile and still consumes a successful invocation. A target that
is categorically ineligible aborts for free after targeting and failure
precomputation, as in source.

Divine Vigour records an amount and remaining duration on the player. The
amount is `1 + skill_rdiv(Invocations, 1, 3)`; the duration is
`40 + skill_rdiv(Invocations, 5, 2)` turns. Each amount adds five percent
to max HP and max MP at the same stage as source percentage modifiers.
Invoking it scales current HP and MP proportionally to their new maxima.
Expiry, penance, and departure remove the bonus and recalculate both maxima.
The ability cannot be recast while active.

## Design and alternatives

The chosen approach uses four small Lua ability modules and focused state
owners. Generic ability dispatch, resource formulas, monster allegiance,
timed player effects, and save validation gain reusable operations only.
This keeps each power's rule beside its name and its lasting state beside
the consumers that read it.

Embedding Elyvilon cases in the command runner would duplicate patron
logic across menus, turns, and saves. Giving the powers Go handlers would
make mod replacement difficult. Both conflict with the Lua-first engine.

## Boundaries

The slice includes the four active abilities, ability menu and terminal
targeting, HP/MP derivation, pacified actor ownership, timed expiry,
departure and penance cleanup, semantic save validation, modding guidance,
and focused Lua and Go integration coverage. Other Elyvilon passives,
ordinary wrath, and unimplemented source ailments remain their own domains.

The Lua modules import shared IDs instead of repeating static names. Every
function and non-obvious algorithm explains why and how. Lines stay within
120 columns, with 80 preferred. No inline Lua is added to Go.

# Ru Attack Interference Design

## Intent

Port Ru's one-star aura as one combat behavior across monster melee,
missile, and spell actions. A visible hostile monster about to attack the
player may lose its action or redirect it to another monster. The rule
belongs in Lua, while the Go kernel continues to store generic intents
and dynamic ECS state.

## Source behavior

The source checks the passive, the attacker's allegiance, no-trans
visibility from the player, firewood, submerged state, and projectile
identity. A qualified attack draws `random2(100)` and then
`div_rand_round(piety, 16)`. A draw below the rounded chance blocks the
attack. Otherwise a second rounded half-chance selects redirection. The
second rounding draw occurs only after the block test fails.

A blocked melee or missile action spends the attack without contact. A
blocked spell spends spell energy and emits the source's casting, prayer,
or attack message. Melee redirection reservoir-selects an eligible
adjacent monster, including the attacker itself. Missiles and spells choose
from monsters in the player's normal sight radius. Candidates may belong
to the attacker's
side, but cannot be friendly, firewood, or projectile bodies. A
redirection without a candidate leaves the player as the target.

For spells, source selection happens after a usable spellbook is found
but before the final spell and target are chosen. The redirect target
must therefore be passed into Lua spell planning, rather than swapping
the victim after a player-specific spell has resolved.

## Ownership

`policy/religion/ru/interference.lua` owns eligibility, source-order
rolls, candidate collection, and messages. Melee and missile action
owners call it at their attack boundary. Spell choice calls it before
effect planning. The existing spatial ordering rule used for Ru's
Apocalypse becomes a shared Lua helper so candidate order is stable
independent of ECS storage or mod file loading order.

An action-scoped Lua ECS component records a forced monster target for
the attacker's current action. The shared target predicate accepts only
that exact entity as an override. The component is removed when the
action finishes or spell planning fails; it does not alter allegiance.
An interrupted spell is represented by a generic interrupted intent,
which still charges spell energy. No Ru decision enters Go code.

Monster-targeted missiles use the existing Lua projectile formulas and
the monster defense and health owners. Their base hit, shield, armour,
poison, brand, and post-hit behavior must follow the same
projectile-specific path as shots against the player. Spell effects use
their existing actor-target resolution; target eligibility is explicit
at the shared target boundary, avoiding a separate Ru spell resolver.

## Verification

Lua `_test.lua` cases pin rank, penance, visibility, allegiance, source
RNG draw order, block, redirection, no candidate fallback, candidate
ordering, and excluded bodies. Integrated Go tests exercise each of
melee, missile, and spell attacks through ordinary turns, including
spell energy consumption and save/restore continuation. Build `crawl`,
run the affected Lua and Go suites, and check changed-file style.

# Elven Twin Lifecycle Design

## Intent

Port the linked Dowan and Duvessa behavior that surrounds pacification:
attacking a peaceful twin angers both; death or banishment of one gives
the survivor its source grief response. Keep the rules in Lua and save
every durable change on the Akara actor.

## Source behavior and boundaries

The pinned source identifies each twin by original class after polymorph.
The lookup visits monsters on the current floor. A player attack makes a
pacified target hostile and calls the pair reaction, so its peaceful
partner also becomes hostile. The earlier nonlethal XP remains credited;
subsequent pacification or death cannot grant it a second time.
If a neutral twin departs before its partner has been converted, the
living hostile sibling follows into peace without a grief response.

When one twin dies, is banished, or leaves for Okawaru's Arena, an
already good-neutral survivor does not receive a grief change. An
otherwise living survivor becomes eligible to follow stairs, receives
a separation speech state, and gains a permanent power change.
Unpolymorphed Dowan replaces spell slots 1, 2, and 4 with Stone Arrow,
Throw Icicle, and Blink. Dowan gains permanent Haste. Duvessa gains
permanent Berserk with its normal health, melee, and speed effects.
Polymorphed bodies keep their current spells. An unseen or temporarily
ineligible survivor records a pending power change and activates it when
it sees the player and can act. Source flavour text is emitted when
visible; exact original speech-key lookup is future presentation work.

## Ownership and approach

The existing `policy.monsters.elven_twins` owns pair identity and grief.
It stores one focused `monster.elven_twin` component with pending and
energized state plus the cause of separation. The death-hook registry,
Abyss transit owner, and Arena travel owner call the same grief operation;
no monster-specific
Go switch is added. The active monster decision checks a pending reaction
before choosing a normal action. The shared monster spellbook reader
projects Dowan's upgraded slots without mutating catalog definitions.

Player attack contact is the shared moment for a hostility transition.
A focused combat contact owner calls the existing religious conduct
classifier while the target is still neutral, then asks pacification to
anger the target and its twin. Every production offensive call site
uses that owner. This preserves conduct ordering and includes misses.
The pacification marker's boolean records current peacefulness; its
presence still means nonlethal XP was already paid. Departure and save
validation read the boolean rather than only component presence.

Source `INFINITE_DURATION` is 30000. The existing monster Berserk and
Haste timer owners treat that named value as permanent, and normal
dispel rules can still end the effects. The twin component stores the
one-time grief transition; ordinary status owners retain their effects.

## Alternatives considered

Hooking only monster HP loss would miss failed attacks and harmless
contacts. Adding special cases in Go would split game rules across
engines. A general Lua contact coordinator and ECS grief state fit the
project's Lua-first ownership model and source event order.

## Verification

Lua `_test.lua` cases cover a missed player attack on two peaceful twins,
once-only XP across anger and reconversion, same-floor original-class
lookup, Dowan's upgraded spells and permanent Haste, Duvessa's permanent
Berserk, deferred activation, and death, banishment, and Duel separation.
Go save tests cover pacification history across restore; Lua schema
validation covers grief. Run the focused Lua and
game suites, `go build ./...`, Go style gate, format, and diff checks
before one category commit and push to `main`.

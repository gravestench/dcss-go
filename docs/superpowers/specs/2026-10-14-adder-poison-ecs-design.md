# Adder poison and player-owned status

## Intent and boundary

Make the Dungeon:1–2 adder a fully playable population choice, including its
poison bite, lasting poison damage, curing potion interaction, status display,
death, corpse, experience, and deterministic save continuation. This is the
first persistent hostile effect in the Go port. It establishes one readable
Akara path for an effect applied by an attack and updated by action time.

The current playable character is Human/Fighter with no poison resistance,
nonliving form, slow-poison passive, or damage shaving. Those rules are not
simulated until their owning domains are implemented. The adder does not use
items or spells and has one bite; existing ordinary animal movement applies
on the generated land terrain.

## Pinned source behavior

Reference: `crawl-ref/source` at
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.

- `mon-data.h:4398–4407`: adder has HD 2, average HP ×10 of 110, speed 13,
  one `AT_BITE` for 4 base damage with `AF_POISON`, and an ordinary corpse.
- `melee-attack.cc:2521–2526,2340–2371`: after a landed bite, poison triggers
  with probability 1/3. A normal poison attack rolls an inclusive amount
  from `2*HD` to `4*HD` and adds that many poison points.
- `player.cc:4141–4190,4204–4339`: poison is stored in thousandths of a
  point. After each player action, source poison duration is converted to
  remaining aut, elapsed aut is subtracted, and the inverse gives the new
  duration. Damage is the drop in whole poison points. The rate is bounded
  between 0.1 and 5 HP/aut and normally removes 20% per 10 aut. Below one
  poison point, the status ends. Human/Fighter has no resistance modifier.
- `player-reacts.cc:1015–1031`: regeneration precedes poison damage.
- `potion.cc:75–134` and `player.cc:7815–7823`: curing is usable for poison
  even at full HP, still draws its ordinary healing roll, and clears poison.
- `mon-util.cc:2345–2535`: ordinary no-spell/no-equipment XP uses actual
  rolled maximum HP and the source's HD, speed, and modifier arithmetic.

## Ownership and flow

`ecs.Poison` is an optional component on the affected actor. It owns the
remaining scaled amount and the source monster ID for saveable attribution.
No `Game` field or global duration mirrors it. The existing immutable adder
definition supplies bite damage, flavour, speed, and corpse properties.

The existing ordinary-bite combat path accepts the adder's poison flavour
without creating a second combat implementation. A hit performs the normal
damage and practice flow, then rolls the source 1-in-3 flavour chance and
inclusive amount on the saved melee RNG stream. The combat system adds or
increases the player's Poison component and emits the poison notice. A
focused poison system runs after regeneration on player-action updates,
calculates source decay and damage from elapsed aut, changes Health, removes
the component when the amount falls below 1000, and emits recovery or sickness
messages. The quaff system clears Poison on curing, including at full HP,
while keeping the existing source healing draw. The terminal reads only the
copied game view.

Adder eligibility is validated against committed catalog fields. The same
ordinary monster factory and population picker create its live ECS actor;
the source-backed XP and corpse paths accept its death. Existing fixed
fixture scenarios retain their current members; generated and population
scenarios add the adder to their supported set.

## Persistence and verification

Version 11 Go saves include optional Poison on the player and the melee RNG
state. Restore rejects scaled amounts outside 1,000–2,147,483,647, a source ID
other than `MONS_ADDER`, and Poison on non-player entities; it preserves the
exact remaining amount. The source profile validates the adder's immutable
combat and HP inputs before spawn and restore. Older Go schemas remain
rejected as before.

Pure poison-rule tests pin the minimum, ordinary, and maximum rate regions,
fractional action aut, damage truncation, and clear-below-one behavior.
Gameplay tests cover bite application, regeneration-before-poison order,
curing at full HP, lethal poison, adder death/XP/corpse, and deterministic
continuation after restore. The generated population table can select adder
without a special fixture-only path. Run full Go tests, vet, build, style,
diff checks, and read-only review before the category commit reaches `main`.

## Deferred capability families

Ball python constriction, bat flight and batty movement, humanoid equipment,
endoplasm and dart slug spells, other resistances, and deeper-floor monsters
remain separate capability slices. The poison component and end-of-action
system can later apply to other actors, but this slice validates only the
current player path rather than fabricating unimplemented monster reactions.

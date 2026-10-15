# Player melee weapon brands

## Intent

Complete the 15 positive-weight melee brands in the committed weapon catalog
and the Chaos Knight's forced chaos brand. A branded weapon must affect the
current turn, later turns, and saves through the same Lua and Akara path as
other gameplay.
The implementation should be easy to extend: each brand owns one Lua module,
and replacing that module in a sparse mod layer changes its behavior.

## Scope and source

The source is pinned DCSS revision `e60ba3568b0c26447ad36ec5c7b963eb04b2778f`.
`attack.cc:471-570,1320-1630` defines brand eligibility, rolls, damage,
drain, antimagic, and distortion. `melee-attack.cc:642-676` schedules a
spectral weapon after the player's attack. `fineff.cc:758-843` places or
reuses the spectral ally. `fight.cc:955` and the existing Lua delay policy
define speed's timing. The generated item catalog is the authority for which
brand IDs a weapon can carry; the source tables do not need rebuilding at
runtime.

Chaos selects a source-weighted brand on contact. Selecting chaos again
chooses a source-weighted eligible monster enchantment or transformation.
This slice does not add new monster species, weapon kinds, branches, or UI
commands. It does make all existing generated melee brands playable. Brand
weapon enchantment, identification, artefact conduct, and unrand-specific
overrides belong to their item and religion domains.

## Resolution and ownership

The primary player strike computes contact, base damage, and the usual
combat message. It then calls `policy.combat.player_brands` with the weapon
brand and a hit record. The dispatcher validates the brand, loads
`policy.combat.player_brands.<name>`, and invokes its named method. It has
no brand-ID effect switch. Modules share only focused roll, resistance,
health, poison, and movement helpers already used by production Lua.

The hit record contains attacker and defender entities, the defender's
catalog definition, the actual base damage dealt, and current health. A
module may damage or move the defender, heal the attacker, or update an
Akara component. The caller then handles death, mutation callbacks, and
auxiliary attacks using the resulting live state. Brand damage never creates
a second kill, and a banished defender is not struck again by auxiliary
attacks. Zero base damage and pre-killed targets follow the source gates.

Speed modifies melee action delay, and protection modifies player AC while
wielded. These policies read the equipped item through the existing ECS
query. The corresponding brand effect modules stay empty because the change
is already active before contact.

## Durable effects

Venom uses saved monster poison. Draining uses saved monster drain and
negative-energy resistance. Antimagic uses the existing saved monster spell
disruption status. Distortion can deal warp damage, blink, or move the
monster to the Abyss without awarding a kill. Its destination and origin
remain valid through save and restore. Holy wrath checks the defender's
holiness, pain reads player Necromancy skill, and vampirism heals only when
the target is susceptible and the player can heal.

Spectral creates or reuses an allied Akara actor with a copy of the wielded
weapon. Its component records ownership and the source weapon identity. It
strikes the surviving target after the player's primary attack, appears on
an adjacent legal cell, and expires or is replaced according to the pinned
source. The ally is saved and cannot gain an unrelated independent turn
through ordinary monster AI. The implementation uses a separate Lua system
for spectral behavior rather than adding spectral cases to the general
monster decision switch. Damage dealt to the spectral ally shares half with
its owner without taking the player below 1 HP, matching `monster.cc`.

## Acceptance

- Every positive-weight generated melee brand and the Chaos Knight's forced
  chaos brand have loadable Lua modules.
- Whole-turn tests observe one representative of each effect family,
  including immunity, zero damage, lethal base damage, and a surviving hit.
- Speed changes action cost; protection changes AC while equipped.
- Poison, drain, antimagic, distortion banishment, and spectral actor state
  survive save and restore.
- A same-path overlay of one player brand module changes that hit and the
  effective ruleset hash without changing Go.
- Run the full suite, vet, build, style, and catalog checks at the integrated
  category boundary; commit this category once and advance local Go `main`.

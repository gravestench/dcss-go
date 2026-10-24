# Mutating and chaotic monster contacts

## Intent

Complete `AF_MUTATE` and `AF_CHAOTIC` for both player and monster victims.
Mnoleg, Chaos Spawn, eldritch tentacles, and apocalypse crabs already carry
these source attack definitions. A landed contact must use the live victim's
body and status, rather than a static catalog-only outcome. No new ECS status
or Go rule is needed; the existing Lua mutation and chaos owners already
hold the durable effects.

## Approaches

One approach copies a second weighted chaos table into the attack-flavour
dispatcher. That would let weapon chaos and natural chaos disagree when
eligibility changes. The selected approach moves the source weighted choice
to a shared Lua policy used by both existing weapon-brand paths and the new
natural-contact path. The selected outcome then runs the corresponding
flavour rule. Direct Mutate contact calls the existing malmutation owner.

Theft, Shadowstab, and Spider remain separate full domains: inventory
transfer, pre-hit stealth, and summon placement. Their code does not belong
inside the mutation/chaos choice policy.

## Mutation

A landed, post-armour damaging `AF_MUTATE` contact gets one chance in four.
The player uses the existing random malmutation transition and its mutation
resistance. A monster uses the current projected definition and the existing
monster malmutation rule: impossible bodies reject it; ugly things reroll,
and ordinary mutable monsters gain saved Wretched. The melee RNG stream owns
the contact chance; mutation selection retains its own mutation stream.

## Chaos

After a post-armour damaging contact, `AF_CHAOTIC` builds the source's eleven
outcomes in source order and draws once from eligible weights. Fire and Cold
exclude native fiery and icy bodies; Venom excludes undead and nonliving;
Drain and Vampiric require natural or plant bodies, with summons excluded
from Vampiric; Holy requires holy-energy vulnerability; Antimagic requires a
susceptible caster; Confuse excludes Clarity. Other outcomes stay eligible.

The selected ordinary outcome applies its named natural attack flavour, not
the similar weapon brand formula. If Chaos selects itself, the existing
player or monster chaos effect table selects its inner effect. All effects
use the same saved ECS state and actor health owners as spells and brands.
An attack whose physical packet passes armour but is later absorbed still
gets its contact choice, as source melee does. No choice occurs on a miss,
block, dodge, or zero post-armour physical packet.

Weapon chaos and natural chaos share only the weighted choice. Their
selected-effect formulas remain distinct because the original game uses
weapon brands for one and attack flavours for the other.

## Verification

Production Lua tests use real catalog actors and components to pin the
one-in-four mutation gate, both mutation victims, chaos eligibility and
weight totals, ordinary versus inner chaos outcomes, and live melee
dispatch. Existing weapon-chaos tests protect the shared chooser. A full
category commit goes directly to `main` and is pushed to the fork.

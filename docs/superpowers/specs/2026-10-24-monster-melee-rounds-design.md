# Monster melee rounds

## Intent

A monster spends one melee action on its complete source attack sequence.
The present resolver uses only attack slot one against either a player or
another monster, leaving later catalog attacks inert. Mutant beast facets
cannot become faithful until the ordinary sequence exists.

## Approaches

Repeating the current public action once per slot would rerun one-action
effects and omit the source's stop checks. Duplicating a special mutant
beast attack path would leave every other multiattack monster broken. The
chosen approach gives the combat domain one actor-aware attack sequence
owner and separates each existing contact resolver from its round loop.
Both defender kinds use the same slot list and termination conditions.

## Source behavior

`fight.cc` attempts four catalog slots in order, spending melee energy
once. Empty slots do nothing. It stops if the attacker dies or the
defender dies, moves from its original cell, or is banished. A hydra or
Serpent of Hell attempts one first-slot bite for each saved head, then
slots two through four. Source `mons_attack_spec` maps the extra head
attempts back to slot one. A hydra that loses its target can choose an
adjacent enemy for its remaining heads; other monsters stop. A non-vault
hydra starts with four to eight heads and the Lernaean hydra with 27.
Authored head counts remain authoritative and saved.

Derived undead borrow the corpse base's attack slots, reduce damage to
four fifths, and replace most flavours with their undead body's flavour.
An unrelated DES base annotation does not grant hydra attacks. A dual
wielder uses its primary weapon on the first contact and alternates with
its active offhand on later contacts.

The player constriction path must invoke AT_CONSTRICT once at its real
slot without an extra grab after the round. Monster-to-monster holds
still need their own saved relationship and periodic damage policy.
Vine attacks and summoned player illusions keep
their existing special resolvers for one action, because those profiles
do not have a catalog multiattack sequence.
The saved hold's later damage reads the slot that actually constricts;
an Anaconda's first-slot hold must not use its second-slot bite damage.
Source AT_RANDOM and AT_CHERUB choose a type for each attempted contact,
so a Cherub's second slot can use its held weapon when it rolls AT_HIT.

## Boundaries

`policy.combat.monster_attack_sequence` maps saved head state and the
projected monster definition to ordered contacts. The existing
`policy.combat.melee_actions` resolves each contact, checking live ECS
health and positions between contacts. `policy.population.factory`
initializes ordinary head state; the existing component and save path
keep it. No Go gameplay switch or duplicate melee resolver is added.

## Verification

Use real Lua catalog definitions and Akara components. Assert Ettin's
two attacks, a single-attack monster's unchanged count, authored and
rolled hydra head counts, Lernaean count, a killed or displaced defender
stopping a round, and the second-slot constriction being attempted once.
Check the player and monster-target paths, one-action energy semantics,
offhand selection, save/restore of head state, affected Lua tests, Go
build, style, and a
fresh source review before one category commit on `main` and push.

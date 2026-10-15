# Lua character starts for every selectable species and job

## Intent

Character creation should accept every species/job pair that the pinned DCSS
choice rules allow. A started character should have the source-defined initial
attributes, skills, inventory, equipment, HP/MP, and durable starting state.
The client should keep unavailable later abilities visible with a clear
explanation. A successful start alone must not be described as completed
spellcasting, religion, mutation, or full species gameplay.

The checked-in Lua definitions are authoritative during play. Content
importers remain optional tools for an intentional upstream refresh. Normal
launch, save, and restore must not read the C++ checkout or regenerate Lua.

## Ownership and scope

Go creates the player entity, identity, position, and turn clock, then calls
one `character.start` Lua policy. That policy owns the whole starting
transaction: species and job rules, chosen or fixed weapon, all starting
items, substitutions, starting skill points, training state, HP/MP, spell
knowledge, religion, and innate state. The current separate Go invocation of
`character.starting_gear` is removed in the same pass. Go retains generic ECS
stores, the grid, named RNG services, save encoding, and terminal rendering.

The existing Lua choice policy remains the one source of legal and banned
pairs. Its `playable` result becomes true for every legal selectable pair;
the Fighter-only list is deleted. `character.supported_start` and the menu's
batch projection must agree with that policy without another ID whitelist.
The character menu shows all choices. A job with `WCHOICE_NONE` skips the
weapon screen and enters name confirmation with no selected weapon. Jobs with
a choice use the existing Lua weapon option rules and validate the selection.

Go adds no job, species, weapon, item, or spell ID switch. Lua rules may use
small named modules by responsibility, and Lua-defined components hold
starting state that Akara's generic engine does not need to interpret yet.
The conversion removes old paths; it does not add fallback adapters.

## Source fidelity

The pinned source is DCSS revision
`e60ba3568b0c26447ad36ec5c7b963eb04b2778f`. The starting flow traces
`newgame.cc`, `ng-restr.cc`, `ng-setup.cc`, `ng-init.cc`, `jobs.cc`,
`ng-wanderer.cc`, `player.cc`, and the species/job data files.

The Lua start policy follows source order where randomness matters:
species and job stats, basic mutations, job-specific adjustments, chosen
weapon and source-ordered grants, gear substitution and useless-item
filtering, starting spells or library, starting skill reassessment, training
queues, then HP/MP. It uses the existing named RNG service. Job grants in
`data.starting_gear` remain committed source-derived data. Dynamic starting
state must save and restore through Lua component schemas.

No-choice jobs with `SK_WEAPON` resolve that placeholder from their fixed
starting weapon. Other jobs use the chosen weapon. A character without a
Fighting grant still has a valid zero-level Fighting entry for the HP
formula. Starting skills whose species aptitude is forbidden follow the
source's reassessment behavior rather than causing an error.

## Verification

An audit test enumerates every selectable species/job pair from the effective
Lua catalogs and choice policy. Every legal pair must start without a Go ID
exception; every banned pair remains blocked. It checks a source-traced set
of representative difficult starts: Fighter, a caster with no weapon choice,
a fixed-weapon job, Felid or another gear-restricted species, a god-linked
job, Djinni innate casting, and Wanderer randomness. It verifies identity,
stats, skills, gear, durable Lua components, and save/restore. The test uses
one integrated gate after the whole category is implemented.

The implementation is one category commit on an isolated refactor branch,
then a fast-forward into local Go `main`. Preserve the untracked local save.

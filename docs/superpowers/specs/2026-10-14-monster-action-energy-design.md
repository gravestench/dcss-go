# Monster action energy design

## Purpose and source

A faithful DCSS turn cannot be represented by one deadline per monster.
The pinned source gives each monster energy once for a player action, then
lets ready monsters act in descending energy order until they fall below 80.
See `crawl-ref/source/mon-act.cc:1311-1319,2325-2366`,
`monster.cc:5165-5186,5452-5514`, `mon-util.cc:2834`, and
`random.cc:313-322`. The seven currently live ordinary animals use this
same turn rule. Their static speed and action costs already exist in the
committed monster catalog.

## Ownership

The player entity owns `PlayerTurn.NextAut`, its next logical action time.
Each live monster owns `MonsterEnergy.Points`, initially 70. These are
separate Akara components because they have different lifecycles and rules.
`Actor` retains source kind and speed, but no scheduling deadline. The
session owns `currentAut`, a named `monster_energy` RNG stream, and the
turn coordinator. A level owns terrain and active-floor membership through
entity positions. The catalog owns immutable move, swim, and attack costs.

## Turn flow

An accepted player action runs once and advances `PlayerTurn.NextAut` by its
chosen aut cost. A level-up stat prompt pauses before monster energy is
granted, preserving the existing action barrier. Once the action resumes,
only living monsters on the player's current floor gain
`max(1, div_rand_round(speed * playerAut, 10))` energy, in entity order.
The random rounding draws `Intn("monster_energy", 10)` only when there is a
remainder. The stream is saved with the run.

The turn coordinator repeatedly selects the ready monster with the most
energy (`>= 80`). Equal-energy ties use lower entity ID for deterministic
Go behavior. Ordered Akara systems decide and execute one monster intent.
The final intent after movement may be melee. Its catalog cost is deducted:
move uses `energy.move`, melee uses `energy.attack`, and waiting uses
`min(energy.move, energy.swim)`, matching the source's ordinary no-move
cost. A monster can act more than once during one player turn. The session
clock advances to the player's next action only after this phase.

Inactive floors neither gain nor spend energy. Returning applies the
existing off-level catch-up once, then grants ordinary energy for the
arrival action. The current seven animals have no active speed enchantments,
water travel, missiles, spells, or special actions; those costs join this
single path when their capabilities are ported.

## Save and validation

Go save version 12 writes `player_turn` only for the player and
`monster_energy` only for monsters. Version 11 is rejected rather than
maintained through a compatibility execution path. Restore validates that
monsters have nonnegative energy, and a save with a living player has no
ready monster (`energy < 80`). A terminal save may contain ready monsters
because player death stops the action queue. The player has a nonnegative
next aut, and the player clock matches the session clock except during a
pending stat prompt. Items have neither component. These checks preserve
deterministic continuation after save and load.

## Verification

Pure rule tests pin source rounding and costs. Game tests cover rat, worm,
and jackal cadence; a long player attack; energy queue order; haste;
active-floor freezing; pending stat choice; and save roundtrip/tampering.
The category ends with full Go tests, vet, build, style, diff checks, and
read-only review. Handwritten Go follows `AGENTS.md` readability rules.

# Monster Melee Afflictions

## Intent

Make every active monster attack using `AF_CONFUSE`, `AF_BARBS`,
`AF_RAGE`, `AF_VULN`, or `AF_POISON_PARALYSE` apply its source effect to
player and monster victims. These are post-contact status effects, not
weapon brands. The attack flavour catalog remains data and Lua owns the
rules. Existing Akara components own all durable outcomes.

## Source rules

- Ordinary flavours run after a confirmed hit with positive physical
  damage. They do not trigger on a miss, block, or a zero-damage hit.
- Confuse rolls one chance in three, then uses `1 + random2(3 + HD)` as
  strength. A spore attack first reduces the attacking spore monster's HD;
  an unbreathing defender prevents that special effect and confusion.
  Player Clarity and monster Clarity still block the resulting status.
- Barbs lodge on a damaging hit. The existing wound owner handles player
  and monster durations, movement damage, immunity, and save state.
- Rage rolls one chance in three, then asks the victim's existing Berserk
  owner whether its live body and statuses permit the transformation.
  Involuntary player Rage checks worn artefact Clarity as well as mutations.
- Vulnerability rolls one chance in three. Player lowered will adds 20–39
  turns up to a 40-turn cap; monster lowered will uses its existing
  enchantment owner and skips invulnerable willpower.
- Poison Paralysis checks poison immunity before any chance roll. The
  poisoning chance is one in three with an HD-scaled dose. Independently,
  one chance in six attempts paralysis, otherwise the attack attempts
  slowing. Positive poison resistance rejects either control attempt two
  times in three. Paralysis lasts one to three turns and uses the normal
  player or monster status owner. A monster's Slow uses that same one to
  three turn power as its duration. Intrinsic Formicid stasis rejects
  monster control before the willpower contest.

## Ownership and verification

A focused Lua module maps each of these source flavours to existing
player and monster status owners. The main monster flavour dispatcher
only names the five handlers. Add Lua tests using production schemas for
player and monster victims, immunity, RNG ordering, zero-damage hits,
and live contact. Verify related script and game tests together, then
commit and push one category to Go `main` under the user's standing
integration instruction.

# Ru Damage Retaliation Design

## Intent

Port Ru's two-star damage retaliation as a complete passive rule. A
surviving player who loses HP to a monster may impair that monster. The
effect depends on the actual damage, Ru piety, and the monster's current
hit dice. Modders should find the rule in one Lua policy and its shared
status owners, with no Ru branch in Go combat code.

## Ownership and source behavior

The existing player-health policy owns actual HP loss and calls ordered
Lua damage reactions. Ru registers one after-HP reaction immediately
after deterioration. It reads live Ru worship, penance, and rank each
time; changing gods or losing the two-star passive ends the effect
without a second state flag.

The source first rolls a one-in-`div_rand_round(800, piety)` chance, then
checks that the damaged player has a valid living monster source. A
successful attempt computes `max(0, random2(div_rand_round(piety * 10,
32)) + damage - 2 * monster_HD)`. In descending order, power above 50
applies antimagic if susceptible, above 35 paralysis, above 25 slow,
above 10 blindness if the species permits it, and positive power corona.
An unsupported higher branch falls through to the next lower one.

All duration rolls and status writes use the existing Lua monster
antimagic, paralysis, slow, blindness, and corona owners. Reapplication
extends the saved duration as the source monster enchantment does. The
rule draws from the religion RNG stream so a save resumes the same
sequence. No new ECS component or Go dispatcher is needed.

The pinned source suppresses this effect when Ru itself is the acting
god. The current Go damage context has no acting-god provenance. This
slice covers ordinary player damage from monsters and excludes self and
environmental sources; the shared damage context must gain acting-god
provenance before god-caused monster damage can be attributed exactly.

## Alternatives considered

- A Ru branch in Go player damage would hide game policy in the engine.
- A separate retaliation component would duplicate live worship and
  penance state and could outlive Ru.
- An ordered Lua reaction reuses the existing damage boundary and status
  owners. This is the chosen design.

## Verification

Focused `_test.lua` cases pin rank and penance gates, chance and power
draws, all five effect outcomes, immune fallthrough, dead/missing source,
and saved status continuation. A game test exercises a real HP-loss
action, save/restore, and next-turn timer aging. Run the Ru and adjacent
damage-reaction tests, build `cmd/crawl`, and check changed-file style.

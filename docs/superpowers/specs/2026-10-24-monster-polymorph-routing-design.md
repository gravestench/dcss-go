# Monster Polymorph Routing Design

## Intent

Source DCSS routes a requested monster polymorph through the live body's
special behavior before choosing a destination. A shapeshifter reverts to its
permanent variant, an ugly thing changes its own traits, and a merged slime
usually divides so each resulting body changes separately. The current Go
policy already handles ugly things but changes a shapeshifter or merged slime
as one ordinary actor. This slice makes all polymorph callers share the same
source-shaped route.

## Constraints

- Keep monster gameplay in readable, commented Lua; Go remains the generic
  ECS, save, RNG, and grid host. No inline Lua in Go.
- Keep each live slime body as one ECS entity and retain the existing split
  component and save rules. A forced split preserves health and ownership.
- A shifter's retained polymorph marker may name its current kind after
  reversion or a later return to the original species. Save validation
  accepts this only with a valid durable shifter identity.
- Make source order independent of file load order; draw from named streams.
- Work directly on Go `main`, as requested, and push one verified commit for
  the complete category.

## Approach

Add one public `polymorph.monster(ctx, target, source, stream, power)` route.
Call it from the player spell, monster hex, and chaos shape effect. The
relative power routes retain their distinct candidate selection. The route
checks ugly traits first, then an active shapeshifter, then merged slimes,
then the ordinary weighted candidate set. Direct Polymorph and Malmutate
force an ugly thing's trait change without the natural one-in-nine chance
or adjacent energy requirement. A shapeshifter reverts to the
variant in its durable component; a forced slime split uses the already
implemented `slime_lifecycle` owner with a distinct placement mode. The split
does not spend a natural action or obey its usual one-in-two chance, but
consumes that coin-flip draw as the C++ condition does. A shifter's fixed
destination must pass species and current-cell habitat validation. Slime
requests always use the same-power
candidate picker, even when the caller requests less or more power. On each
offspring the route repeats the four-in-five split roll, stopping once the
body has one blob, is blocked, or eleven divisions were attempted. All
surviving bodies then receive a form change.

The source's `monster::polymorph` and `slime_creature_polymorph` in
`monster.cc` and `mon-abil.cc` define this route. The current `mon-poly.cc`
weighted set and random shifter selection remain the existing choice policy;
their exact candidate and RNG parity is a separate selection category.

## Verification

Use a Lua `_test.lua` rule test with production schemas and shared grid
fixture. Check permanent shifter reversion, forced division and independent
forms, blocked division still changing the original, and no natural action
cost for forced division. Check source coin-flip consumption, ugly shifter
precedence, forced ugly mutation, reversion legality, and relative slime
routing. Check save restore with a shifter back in its original kind. Run
the affected Lua and Go integration tests, build, line length and diff
checks. Record a small text floor snapshot.

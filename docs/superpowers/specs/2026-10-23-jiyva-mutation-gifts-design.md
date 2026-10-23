# Jiyva mutation gifts

## Goal

Port Jiyva's complete mutation gift cycle from the pinned DCSS source.
The gift changes saved player mutation entities through the existing Lua
mutation transition owner. It does not create a second mutation ledger.

## Source behavior

An eligible worshipper has at least 75 piety, rolls above 50 on a piety
draw, passes a one-in-four chance, has no gift timeout, and can safely
mutate. Jiyva first considers each acquired mutation level in source
mutation order. Each good or neutral level has a one-in-four removal
chance; each bad level has a one-in-two chance. Innate and temporary
levels are excluded from this deletion pass.

Jiyva then tries to grant four levels. Each attempt chooses a good
mutation with weight six or a slime mutation with weight four, selects
one concrete mutation through the production catalog, and grants that
same mutation repeatedly until capped, blocked, or all four levels have
been spent. Good selection retries for an eligible mutation; slime
selection makes one draw per outer attempt even if it is capped. The
outer loop is bounded at 500 attempts. Divine gifts
bypass ordinary mutation resistance and resolve conflicts as a god gift.
All four spent grant levels or any successful deletion records a 45 plus
random2avg(30, 2) timeout and increments the shared gift counters.
Partial grants without a deletion record no gift. Messages follow the
source attempt and failure paths.

## Ownership and verification

The Jiyva god definition names one Lua gift module. It uses the
existing mutation catalog, source ordered enum, record owner, selection
policy, transition owner, and shared religion gift counters. Add a Lua
test using production schemas for gates, deletion, four-level grant,
timeout, and repeated check suppression. Run focused Lua and game tests,
Go build, and changed-file style checks at the category boundary.

Nemelex cards are a separate deck domain because playable card state
and draw actions do not yet exist in the Go engine.

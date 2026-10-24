# Beogh active abilities design

## Goal

Port all four active Beogh abilities as one playable Dungeon Crawl domain:
Smiting, Recall Orcish Followers, Give Item to Named Follower, and
Resurrection. The preceding Beogh follower component remains the single
source of gift identity and real allegiance.

## Ownership

Lua registers the four abilities and owns their rank gates, targeting,
failure rolls, costs, and effects. The existing Go command bridge carries
generic selected item and target fields; it gains no Beogh branches. Akara
stores the recall queue on the player, gift history on the orc, and the
resurrection record on a corpse item. The level grid owns placement and
movement. Menus ask for a follower, item, or corpse using shared selection
metadata rather than guessing a default choice.

## Source behavior

- At two stars, Smiting costs three MP and three or four piety, uses the
  registered Smiting spell effect, and has source failure chance
  `40 - Invocations * 5 - piety / 20` with the source three-roll failure
  curve. Its power is `12 + skill_bump(Invocations, 6)`.
- At four stars, Recall costs two MP and no piety. It queues living Beogh
  companions from the current and other eligible levels in descending
  `experience_level + random2(10)` order. It moves one near the player at
  a time, waiting `3 + random2(4)` aut after a successful recall. Stop
  Recall is shown while the queue is active. A companion already within
  two cells receives follow orders without teleporting.
- At five stars, Give Item offers a named orcish follower in sight, then
  an eligible inventory weapon, body armour, or shield. A follower may
  receive one gift total; the category records which kind it received. Item ownership,
  equipment slot and dropped replacement remain ordinary ECS item state.
- At six stars, Resurrection costs 28 piety, selects an orc corpse on the player's cell,
  checks a free habitable adjacent cell, and restores the saved orc as a
  Beogh companion at full HP. The source corpse retains the orc's identity
  and relevant combat state. It is consumed only after placement succeeds.
- Every ability requires current Beogh worship and no Beogh penance.
  Failure and accepted use spend an action; cancellation and invalid
  selections do not. MP and piety costs follow the source commitment
  boundary and are saved with the player's existing components.

## Verification

Lua rule tests cover ranks, penance, cancellation, source roll order,
targeting, inventory transfer, recall ordering and timing, and corpse
resurrection. Game integration tests cover terminal selection, one full
ability action, and save/restore during recall and after a gifted or
resurrected follower. Corrupt saved references must fail validation.

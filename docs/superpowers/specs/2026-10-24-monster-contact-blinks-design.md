# Monster Contact Blinks

## Intent

Port both source contact blink flavours, `AF_BLINK` and
`AF_BLINK_WITH`, for player and monster victims. A confirmed damaging
contact may schedule movement, but the attacker's remaining contact
slots finish before anyone moves. No Lua module global stores pending
work; the melee round carries a short local event list.

## Source behavior

- Blink rolls one chance in three; Blink With flips a coin and succeeds
  on the source's `random2(2) == 1` result. Neither
  schedules during departure movement.
- Repeated identical blink events merge within one round. At resolution,
  dead or teleport-restricted actors do not move.
- Blink moves the attacker to an ordinary legal blink cell. Blink With
  moves that attacker first, then tries one free, habitable cell adjacent
  to the attacker's new position for its original defender. If no such
  cell exists, the defender stays put.
- The pair's second landing uses reservoir sampling over all eligible
  adjacent cells, as in the source final effect.
- Existing displacement owners perform habitat, player landing,
  constriction, net, and origin-cloud handling. Contact draws use the
  melee RNG stream.

## Verification

Lua tests exercise both chances, the departure gate, delayed resolution,
duplicate merging, stasis, an isolated attacker landing, partner placement,
and a no-room partner. A live multi-contact round proves the first blink
does not skip later attacks. Related displacement and game tests run at
the category boundary, then this slice is committed and pushed to Go
`main` under the user's standing instruction.

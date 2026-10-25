# Experience Reconciliation After Any Actor Action

## Problem

The death system can credit the player with XP during a monster action,
including allied kills. Training and level advancement follow death in the
system order, but both return immediately unless the acting entity is the
player. This leaves the saved player with enough XP for a higher level while
still at level one. A restored Jiyva-to-Slime run now reaches the end floor
and exposes the mismatch after 903 credited XP.

## Design

The player remains the sole owner of skill training and character level.
After any active actor's death phase, the training and advancement systems
read the live player and reconcile any newly credited XP or defensive
practice from an incoming attack. They do not
train or level the acting monster. Existing ordering stays `actor.death`,
`character.training`, `character.advancement`, and later duration effects.
With no new XP these policies retain their existing no-op behavior.

A manual stat choice still pauses subsequent advancement; the command
boundary presents that choice before accepting another player action.
When a monster action earns the level, the prompt may be pending at the
completed turn clock, and choosing it spends no additional time.
The save validator continues to require player level and total XP to agree
when no choice is pending.

## Verification

The Jiyva-to-Slime scenario must save and restore after allied XP on
Slime:5. Focused training and level-up tests guard player actions. A
scenario with no XP should preserve its progression state.

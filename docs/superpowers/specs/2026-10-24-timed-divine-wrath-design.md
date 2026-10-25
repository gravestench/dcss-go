# Ordinary timed divine wrath

## Intent

The port already has source-shaped god retribution handlers for Nemelex's
Divine Wrath card, but former gods with active penance never retaliate during
ordinary play. Add the source's XP-fed, god-time-driven wrath queue through
Lua, using the same handlers and saved worship state.

## Source rules

At credited XP application, if any god has active penance, subtract the
award from the wrath XP counter. Each crossing below zero queues one future
retribution and adds a fresh threshold of roughly 1/200 of the current
level's XP span, rounded using the religion RNG stream and clamped to one.
At each god-time firing, spend at most one queued count. Sample an eligible
god with probability `eligible_count / 20`, then choose uniformly among the
eligible gods and invoke its existing retribution handler. Piety maintenance
follows this check. The current non-good god may be angry; a former good god
is active only when it hates the current patron. Gods with passive XP
penance, unavailable gods, and declined Wrath-card entries are not eligible.
Nemelex is eligible and forces a draw from the existing Lua Punishment deck.
If no god is currently eligible, XP does not build new queue entries; a
god-time firing still spends one already queued entry. Paying off the last
active penance clears both counters, as in the source penance transition.
When conversion awakens an older good god's wrath, it seeds the XP timeout
after the new patron joins. A god just left is excluded from that check.
Drawing a Wrath card from a god with zero penance cannot erase other saved
wrath debt.

## Ownership and integration

`religion.worship` owns the two new saved integer fields. A focused Lua
wrath timer owns XP accumulation and god-time queue consumption. The
existing retribution module exposes active god selection and dispatches
the effects. The shared credited monster XP owner calls the timer once;
the god-time owner calls it before piety decay. Worship conversion can
start a newly active good god's timer. Nemelex retribution draws from the
existing Punishment card catalog. Current Wrath card behavior keeps its
own sampling path.

Tests use the production component schema and Lua modules. A game-level
save/restore test verifies that a queued event persists and is spent on the
same later turn after restoration. No Go rule or inline Lua is added.

# Walking tomes and living spells

The four source walking tomes share one cast slot, Conjure Living Spells.
Their species determines the actor's later spell: an earthen tome gives
Petrify, a crystal tome gives Lehudib's Crystal Spear, a divine tome gives
Smiting, and a frostbound tome gives Iceblast.
Each tome declares that spell in its own Lua content file; additional tomes
can provide their own choice without changing a central mapping table.

The cast attempts two or three adjacent, degree-one living spells with
the caster's effective spell HD. A tome with six aligned living spells
declines another cast. The shared summon cap also preserves the newly
created actor when a forced cast must evict an older one. Each actor saves
its chosen spell ID on
`magic.summon_living_spell`, and `monster_spellbook.for_actor` projects it
as a frequency-200 magical slot. Ordinary monster AI plans and executes
that slot. A completed cast reduces the actor to zero HP; the death phase
removes it. An actor whose target cannot be planned remains alive to try
again later. Restore validates the summon source, actor kind, hit dice,
and chosen spell ID without requiring its tome to still be alive.

Iceblast now has its own source `ZAP_ICEBLAST` monster beam profile. It
uses normal monster spell power and the existing radius-one cold explosion
rules, including allied blast avoidance and resistance. Seracfall keeps
its separate, stronger simulacrum-powered profile.

Focused Lua tests cover the four species mappings, saved slot projection,
cap, source Iceblast dice and target planning, successful one-shot dismissal,
and malformed save state. A live game test casts from a tome and continues
the living spell's action identically after save/restore. Walking tomes
are not yet placed by the active D:1-2 population roster.

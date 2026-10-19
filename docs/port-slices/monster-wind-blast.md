# Monster Wind Blast

Wind Blast now resolves from committed monster spellbooks through Lua. The
source tactical check offers the spell only against a foe within three cells
when an allied actor does not stand on the aim ray. The cast retains that
aimed cell, so a later foe move cannot silently redirect the blast.

The gale checks a 45-degree cone out to four or five cells. It pushes
actors farthest first, with distance determined by spell power, body size,
and distance from the caster. Blocked actors try another cell at the same
outward distance. A failed push collides with its obstruction and applies
the source two-dice impact after armour. Moved monsters lose action energy;
forced player movement interrupts equipment, passwall, and blood rituals.
Mountain Boots resist displacement, and the player's current form and
terrain safety determine how far and where the wind can push them.

The same gale moves existing cloud entities farthest first. Their duration,
source attribution, and special state stay on those entities. Collision
damage and landing traps run after actor and cloud movement, following the
source pass order. Both the focused Lua rules and a live cast with
save/restore exercise this implementation.

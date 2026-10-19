# Monster instant afflictions

Malmutate and Entropic Weave now resolve from committed monster spellbooks
through the ordinary Lua monster intent. Their actor changes use existing
Akara components, so an action, save, and restore preserve the same state.

Malmutate is a non-damaging enchantment ray. The beam owner checks range,
intervening actors, walls, blocks, and reflection. Its source effect has no
willpower save. A mutable monster gains or extends Wretched through
`policy/monsters/malmutation.lua`; a player uses the acquired-mutation owner.
Undead, nonliving bodies, tentacle segments, and Chaos Spawn are excluded
before the caster commits a target. Abominations are mutable but reroll only
their tile in source; that visual effect awaits per-actor appearance state.
Ugly things also remain valid targets, but currently receive no state change.
The source rerolls their attack type, colour-dependent elemental flavour,
magenta damage bonus, and resistance. These per-actor traits are unmodeled
both at spawn and on Malmutate. That gameplay gap predates this spell and
needs a saved ugly-thing trait owner before mutation can be faithful.

Entropic Weave is a direct, sight-limited spell. It performs an equipment
corrosion attempt with the defender's rCorr protection, then writes the
player or monster corrosion timer through its existing owner. It does not
roll acid splash damage. Acid contact continues to roll its separate splash
chance before sharing the player equipment-corrosion rule.
Both actors read worn preservation, acid dragon armour, and other active
rCorr equipment when making the source one-in-two protection roll.

Porkalator belongs to a later Kirke lifecycle slice: its monster targets
remain hogs until Kirke's death action restores their original body. The
present monster polymorph marker cannot represent that event by itself.

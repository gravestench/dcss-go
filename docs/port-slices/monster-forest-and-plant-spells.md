# Monster forest and plant spells

The five source monster spellbook entries for Awaken Forest, Grasping Roots,
Awaken Vines, Wall of Brambles, and Sporulate now have named Lua effects.
Their preflight checks preserve the selected foe without spending random
draws for an impossible cast. The existing ECS summon, restraint, HP, grid,
and save owners handle the common work.

Awaken Forest stores its timer on the caster. Each later caster action reads
the current tree grid, checks enemy allegiance and visibility, and resolves
tree strikes through the shared damage owners. Grasping Roots uses the same
root restraint policy as player Fastroot, now with a saved actor source and
player and monster victim paths.

Awaken Vines creates up to three caster-owned heads in source-valid cells
beside trees. Each head saves its anchor and target; visible connector actors
link movement back to the anchor, and a head can constrict, lash, and pull a
victim. The caster's timed condition, head sight, death, and ordinary summon
expiry release the vines. Wall of Brambles places real short-lived briar
actors in a defensive or distant arc. Observed foe movement, rather than
distance alone, chooses the wall's purpose. Briar contact can retaliate with
armour-checked thorns.

Sporulate creates a short-lived spore with source-derived HD. Contact, lethal
damage, and lifetime expiry share one guarded explosion. The radius-one
blast damages neighboring actors and can confuse a living, breathing player
after positive damage.

Focused Lua rule tests cover eligibility, source-owned state, geometry,
physical continuation, grips, expiry, and damage. Live Go tests cast all five
from sparse spellbook overlays, save and restore the conditions, compare a
later action and RNG continuation, and exercise player confusion from a
spore explosion.

The original source also suppresses forest strikes inside a god-created
sanctuary. Religion and sanctuary creation are not ported yet, so there is
currently no sanctuary state for this forest policy to consult. That rule
belongs in the future religion slice when sanctuary can exist in play.

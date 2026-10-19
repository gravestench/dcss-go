-- Avatar Song uses the same player-facing song as a siren, then keeps a
-- caster-owned effect that pulls the audience and calls drowned souls.
local songs = require("policy.combat.monster_songs")

local effect = {}

-- Avatar songs remain available against a berserker because their later
-- pull and summon work can still matter even when enchantment cannot.
function effect.plan(ctx, caster, foe)
    return songs.plan(ctx, caster, foe, true)
end

-- The target plan identifies the original player foe; ongoing effects
-- belong to the caster and tick on its subsequent actions.
function effect.resolve(ctx, caster, foe, _, plan)
    songs.resolve(ctx, caster, foe, plan, true)
end

return effect

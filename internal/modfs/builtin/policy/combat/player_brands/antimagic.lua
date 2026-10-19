local enfeeble = require("policy.magic.effects.statuses.enfeeble")

local brand = {
    requires_damage = true,
}

-- Example: brand.apply(ctx, hit) with hit.damage_done = 3 -> passes strength 24 to antimagic status
-- Apply antimagic to the defender's spell state after the physical hit resolves.
function brand.apply(ctx, hit)
    -- Source: attack.cc passes damage dealt times eight.
    enfeeble.apply_antimagic(ctx, hit.defender, hit.definition,
        hit.damage_done * 8)
end

return brand

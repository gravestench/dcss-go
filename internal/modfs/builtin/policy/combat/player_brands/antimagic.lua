local enfeeble = require("policy.magic.effects.statuses.enfeeble")

local brand = {
    requires_damage = true,
}

function brand.apply(ctx, hit)
    -- Source: attack.cc:1543-1545 passes damage dealt times eight.
    enfeeble.apply_antimagic(ctx, hit.defender, hit.definition,
        hit.damage_done * 8)
end

return brand

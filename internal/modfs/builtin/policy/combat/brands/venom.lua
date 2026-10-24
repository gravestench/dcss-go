local roll = require("policy.combat.roll")
local poison = require("policy.combat.player_poison")

local brand = {}

-- Example: brand.apply(ctx, hit, brands) rolls the one-in-four skip before
-- scaling poison dose from damage, preserving melee-stream order.
function brand.apply(ctx, hit, brands)
    if roll.melee(ctx, 4) == 0 then
        return
    end

    local base = roll.melee(ctx, 8)
    local bonus = roll.melee(ctx, math.floor(hit.damage_done * 3 / 2))

    poison.deliver(ctx, 6 + base + bonus, hit.source_id)
end

return brand

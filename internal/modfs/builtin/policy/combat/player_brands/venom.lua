local poison = require("policy.combat.monster_poison")
local roll = require("policy.combat.roll")

local brand = {}

function brand.apply(ctx, hit)
    -- Source: attack.cc:1320-1350. Poison can apply on a zero-damage hit.
    if roll.melee(ctx, 4) == 0 then
        return
    end

    local base = roll.melee(ctx, 8)
    local bonus = roll.melee(ctx, math.floor(hit.damage_done * 3 / 2))
    local levels = 6 + base + bonus

    poison.apply(ctx, hit.defender, hit.definition, levels, hit.attacker)
end

return brand

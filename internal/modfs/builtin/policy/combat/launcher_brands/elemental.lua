local damage = require("policy.magic.damage")
local roll = require("policy.combat.roll")

local elemental = {}

-- Example: with fully element-immune defender,
-- elemental.apply(ctx, missile, defender, dealt, resistance_id, verb) -> 0 bonus damage
-- Roll brand damage from dealt missile damage, then apply the defender's elemental resistance.
function elemental.apply(ctx, missile, defender, dealt, resistance_id, verb)
    -- Source: attack.cc. Brand damage is rolled after ordinary damage.
    local raw = 1 + math.floor(roll.melee(ctx, dealt) / 2)
    local bonus = damage.elemental(raw, defender, resistance_id)

    if bonus == 0 then
        return 0
    end

    local message = "The " .. missile.name .. " " .. verb ..
        " the " .. defender.name .. "."

    return bonus, message
end

return elemental

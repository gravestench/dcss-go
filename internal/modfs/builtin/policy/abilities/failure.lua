local component = require("constants.component")

local failure = {}

-- Source: ability.cc uses 50 - experience level for both demonic powers.
function failure.roll(ctx, player, base)
    local progression = ctx:get(player, component.PROGRESSION)
    local chance = math.max(0, (base or 50) - progression.level)

    return ctx:random("mutation", 100) < chance
end

return failure

local capabilities = require("constants.mutation_capabilities")
local effects = require("policy.mutations.effects.registry")

local experience_limit = {}

-- Source: player-act.cc:get_max_xl; RU_SAC_XP_LEVELS is one.
function experience_limit.max_level(ctx, player)
    local penalty = effects.sum(ctx, player,
        capabilities.MAX_LEVEL_PENALTY)

    return math.max(1, 27 - penalty)
end

return experience_limit

-- Example: A horror penalty of two reduces spell power by the policy's centi-scale factor.
local component = require("constants.component")

local horror = {}

-- Read the current horror component as a spell-power penalty without changing its threat state.
function horror.penalty(ctx, player)
    local state = ctx:get(player, component.HORROR)

    return state and state.penalty or 0
end

-- Source: spl-cast.cc:calc_spell_power; each horror level reduces power.
function horror.spell_power(centis, penalty)
    local divisor = 10 + math.floor(penalty * 3 / 2)

    return math.floor(centis * 10 / divisor)
end

return horror

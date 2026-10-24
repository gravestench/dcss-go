-- A failing mod effect mutates ECS and RNG before raising an error.
local component = require("constants.component")
local streams = require("constants.rng_streams")

local effect = {}

-- Fail late so a partial turn would visibly corrupt worship and RNG state.
function effect.apply(ctx, player)
    local worship = ctx:get(player, component.RELIGION_WORSHIP)

    worship.piety = 77
    ctx:set(player, component.RELIGION_WORSHIP, worship)
    ctx:random(streams.RELIGION, 7)
    error("broken Xom mod effect")
end

return effect

-- Source: traps.cc:zot_effects[2].
local contamination = require("policy.magic.contamination")
local streams = require("constants.rng_streams")

local effect = {}

-- Average two trap draws before updating a capped contamination component.
-- Example: effect.apply(ctx, player) adds residual magical contamination.
function effect.apply(ctx, player)
    local first = ctx:random(streams.TRAPS, 13000)
    local second = ctx:random(streams.TRAPS, 13000)
    local amount = 7000 + math.floor((first + second) / 2)
    contamination.change(ctx, player, amount, false)

    ctx:emit("trap", "You are contaminated with residual magic.")
end

return effect

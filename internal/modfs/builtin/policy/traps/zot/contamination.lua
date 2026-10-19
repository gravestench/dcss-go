-- Source: traps.cc:zot_effects[2].
local ids = require("policy.magic.effects.zaps.ids")
local streams = require("constants.rng_streams")

local effect = {}

-- Average two trap draws before updating a capped contamination component.
-- Example: effect.apply(ctx, player) adds residual magical contamination.
function effect.apply(ctx, player)
    local first = ctx:random(streams.TRAPS, 13000)
    local second = ctx:random(streams.TRAPS, 13000)
    local amount = 7000 + math.floor((first + second) / 2)
    local state = ctx:get(player, ids.component.CONTAMINATION)

    if state then
        state.amount = math.min(250000, state.amount + amount)
        ctx:set(player, ids.component.CONTAMINATION, state)
    else
        ctx:add(player, ids.component.CONTAMINATION, {
            amount = amount,
        })
    end

    ctx:emit("trap", "You are contaminated with residual magic.")
end

return effect

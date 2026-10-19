-- Source: traps.cc:zot_effects[3].
local component = require("constants.component")
local streams = require("constants.rng_streams")

local effect = {}

-- Keep the longer of old and new paralysis durations instead of shortening an existing trap effect.
-- Example: effect.apply(ctx, player) extends the player's paralysis state.
function effect.apply(ctx, player)
    local duration = (2 + ctx:random(streams.TRAPS, 4)) * 10
    local state = ctx:get(player, component.PLAYER_PARALYSIS)

    if state then
        state.remaining_aut = math.max(state.remaining_aut, duration)
        ctx:set(player, component.PLAYER_PARALYSIS, state)
    else
        ctx:add(player, component.PLAYER_PARALYSIS, {
            remaining_aut = duration,
        })
    end

    ctx:emit("trap", "You suddenly lose the ability to move!")
end

return effect

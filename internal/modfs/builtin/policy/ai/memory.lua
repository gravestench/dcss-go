local common = require("policy.ai.common")

local memory = {}

function memory.update(ctx, state, position, player, player_visible)
    if player_visible then
        local roll = ctx:random("ai", 301)
        state.behavior = "seek"
        state.target_x = player.x
        state.target_y = player.y
        state.memory_until_aut = ctx:aut() + 250 + roll
    elseif state.behavior == "seek" then
        if state.memory_until_aut == 0 then
            state.memory_until_aut = ctx:aut() + 250
        end

        if ctx:aut() >= state.memory_until_aut then
            common.forget(state)
        end
    elseif state.behavior ~= "wander" then
        state.behavior = "wander"
        state.target_x = 0
        state.target_y = 0
    end

    if position.x == state.target_x and position.y == state.target_y then
        common.forget(state)
    end
end

return memory

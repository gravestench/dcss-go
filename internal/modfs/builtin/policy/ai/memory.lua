local common = require("policy.ai.common")
local behaviors = require("constants.ai_behaviors")

local memory = {}

-- Target memory is updated here before route selection consumes the remembered position.
-- Example: memory.update(ctx, state, position, player, false) forgets a target after its deadline.
function memory.update(ctx, state, position, player, player_visible)
    if player_visible then
        local roll = ctx:random("ai", 301)
        state.behavior = behaviors.SEEK
        state.target_x = player.x
        state.target_y = player.y
        state.memory_until_aut = ctx:aut() + 250 + roll
    elseif state.behavior == behaviors.SEEK then
        if state.memory_until_aut == 0 then
            state.memory_until_aut = ctx:aut() + 250
        end

        if ctx:aut() >= state.memory_until_aut then
            common.forget(state)
        end
    elseif state.behavior ~= behaviors.WANDER then
        state.behavior = behaviors.WANDER
        state.target_x = 0
        state.target_y = 0
    end

    if position.x == state.target_x and position.y == state.target_y then
        common.forget(state)
    end
end

return memory

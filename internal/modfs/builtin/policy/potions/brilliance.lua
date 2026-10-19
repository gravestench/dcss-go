local component = require("constants.component")

local brilliance = {}

-- Brilliance duration is extended and ticked through the same status component.
function brilliance.active(ctx, player)
    local state = ctx:get(player, component.POTION_BRILLIANCE)

    return state ~= nil and state.remaining_aut > 0
end

-- Extend the existing Brilliance timer so repeat drinks do not stack components.
function brilliance.extend(ctx, player, turns)
    local state = ctx:get(player, component.POTION_BRILLIANCE)
    local added = turns * 10

    if state then
        state.remaining_aut = math.min(800,
            state.remaining_aut + added)
        ctx:set(player, component.POTION_BRILLIANCE, state)
    else
        ctx:add(player, component.POTION_BRILLIANCE, {
            remaining_aut = math.min(800, added),
        })
    end
end

-- Consume elapsed aut from the saved status so spell bonuses end on the same action clock.
-- Example: elapsed aut removes Brilliance when its remaining duration reaches zero.
function brilliance.tick(ctx, player, aut)
    local state = ctx:get(player, component.POTION_BRILLIANCE)

    if not state or aut == 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.POTION_BRILLIANCE)
        ctx:emit("duration", "You feel less clever.")
    else
        ctx:set(player, component.POTION_BRILLIANCE, state)
    end
end

return brilliance

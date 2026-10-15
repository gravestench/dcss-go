local component = require("constants.component")

local resistance = {}

function resistance.active(ctx, player)
    local state = ctx:get(player, component.POTION_RESISTANCE)

    return state ~= nil and state.remaining_aut > 0
end

function resistance.extend(ctx, player, turns)
    local state = ctx:get(player, component.POTION_RESISTANCE)
    local added = turns * 10

    if state then
        state.remaining_aut = state.remaining_aut + added
        ctx:set(player, component.POTION_RESISTANCE, state)
    else
        ctx:add(player, component.POTION_RESISTANCE, {
            remaining_aut = added,
        })
    end
end

function resistance.tick(ctx, player, aut)
    local state = ctx:get(player, component.POTION_RESISTANCE)

    if not state or aut == 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)

    if state.remaining_aut == 0 then
        ctx:remove(player, component.POTION_RESISTANCE)
        ctx:emit("duration", "You feel less protected.")
    else
        ctx:set(player, component.POTION_RESISTANCE, state)
    end
end

return resistance

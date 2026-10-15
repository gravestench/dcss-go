local component = require("constants.component")

local agility = {}
local EV_BONUS = 5

function agility.active(ctx, player)
    local state = ctx:get(player, component.AGILITY)

    return state and state.remaining_aut > 0 or false
end

function agility.evasion_bonus(ctx, player)
    if agility.active(ctx, player) then
        return EV_BONUS
    end

    return 0
end

-- Source: player.cc:player::be_agile uses the same 35+random2(power)
-- duration shape as Might, capped at 80 turns.
function agility.apply(ctx, player, power, stream)
    local state = ctx:get(player, component.AGILITY)
    local previous = state and state.remaining_aut or 0
    local added = 35 + ctx:random(stream, power)
    local remaining = math.min(800, previous + added * 10)

    if state then
        state.remaining_aut = remaining
        ctx:set(player, component.AGILITY, state)
    else
        ctx:add(player, component.AGILITY, {
            remaining_aut = remaining,
        })
    end

    if previous > 0 then
        return "You feel more agile all of a sudden."
    end

    return "You feel agile all of a sudden."
end

function agility.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local state = ctx:get(player, component.AGILITY)

    if not state or state.remaining_aut <= 0 then
        return
    end

    state.remaining_aut = math.max(0, state.remaining_aut - aut)
    ctx:set(player, component.AGILITY, state)

    if state.remaining_aut == 0 then
        ctx:emit("duration", "You feel a little less agile now.")
    end
end

return agility

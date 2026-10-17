local component = require("constants.component")

local sleep = {}

-- Source: player.cc:player::awaken grants three to five turns of immunity.
function sleep.awaken(ctx, player)
    local state = ctx:get(player, component.PLAYER_SLEEP)

    if not state or state.remaining_aut <= 0 then
        return false
    end

    state.remaining_aut = 0
    state.immunity_aut = 30 + 10 * ctx:random("monster_spell", 3)
    ctx:set(player, component.PLAYER_SLEEP, state)
    ctx:emit("duration", "You wake up.")

    return true
end

function sleep.tick(ctx, player, aut)
    if aut <= 0 then
        return
    end

    local state = ctx:get(player, component.PLAYER_SLEEP)

    if not state then
        return
    end

    if state.remaining_aut > 0 then
        if aut >= state.remaining_aut then
            sleep.awaken(ctx, player)
        else
            state.remaining_aut = state.remaining_aut - aut
            ctx:set(player, component.PLAYER_SLEEP, state)
        end

        return
    end

    state.immunity_aut = math.max(0, state.immunity_aut - aut)

    if state.immunity_aut == 0 then
        ctx:remove(player, component.PLAYER_SLEEP)
    else
        ctx:set(player, component.PLAYER_SLEEP, state)
    end
end

return sleep

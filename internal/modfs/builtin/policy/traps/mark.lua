-- Source: player.cc:player::sentinel_mark(true).
local component = require("constants.component")
local streams = require("constants.rng_streams")

local mark = {}

function mark.apply(ctx, player)
    local state = ctx:get(player, component.TRAP_MARK)

    if state then
        state.remaining_aut = math.min(1800,
            state.remaining_aut + (20 + ctx:random(streams.TRAPS, 21)) * 10)
        ctx:set(player, component.TRAP_MARK, state)
        ctx:emit("trap", "The mark upon you grows brighter.")

        return
    end

    ctx:add(player, component.TRAP_MARK, {
        remaining_aut = (25 + ctx:random(streams.TRAPS, 16)) * 10,
    })
    ctx:emit("trap", "A sentinel's mark forms upon you.")
end

function mark.tick(ctx, player, aut)
    local state = ctx:get(player, component.TRAP_MARK)

    if not state or aut <= 0 then
        return
    end

    state.remaining_aut = state.remaining_aut - aut

    if state.remaining_aut <= 0 then
        ctx:remove(player, component.TRAP_MARK)
        ctx:emit("trap", "The sentinel's mark upon you fades away.")
    else
        ctx:set(player, component.TRAP_MARK, state)
    end
end

return mark
